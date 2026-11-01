const MONEYCONTROL_SEARCH =
  'https://api.moneycontrol.com/swiftapi/v1/mutualfunds/get-mf-list?&str=';
const MONEYCONTROL_NAV =
  'https://api.moneycontrol.com/swiftapi/v1/mutualfunds/graph-nav?&isin=';
const rowsElement = document.getElementById('fund-rows');
const searchElement = document.getElementById('search');
const houseFilterElement = document.getElementById('house-filter');
const refreshButton = document.getElementById('refresh');
const noticeElement = document.getElementById('notice');
const emptyElement = document.getElementById('empty');
const moneyFormat = new Intl.NumberFormat('en-IN', {
  minimumFractionDigits: 2,
  maximumFractionDigits: 4
});
const dateFormat = new Intl.DateTimeFormat('en-IN', {
  day: '2-digit',
  month: 'short',
  year: 'numeric',
  timeZone: 'UTC'
});

let funds = [];
let snapshotAsOf = '';
let refreshing = false;

function normalized(value) {
  return value
    .toLocaleLowerCase('en')
    .replace(/\bdir\b/g, 'direct')
    .replace(/\bgr\b/g, 'growth')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
    .split(/\s+/)
    .filter(Boolean);
}

function showNotice(message, tone = '') {
  noticeElement.textContent = message;
  noticeElement.className = `notice${tone ? ` ${tone}` : ''}`;
}

function formatDate(value) {
  if (!value) return 'Date unavailable';
  const parsed = new Date(`${value}T00:00:00Z`);
  return Number.isNaN(parsed.getTime()) ? value : dateFormat.format(parsed);
}

function createCell(className, text) {
  const cell = document.createElement('td');
  if (className) cell.className = className;
  cell.textContent = text;
  return cell;
}

function render() {
  const query = searchElement.value.trim().toLocaleLowerCase('en');
  const selectedHouse = houseFilterElement.value;
  const filtered = funds.filter((fund) => {
    const matchesText = `${fund.house} ${fund.name}`.toLocaleLowerCase('en').includes(query);
    return matchesText && (!selectedHouse || fund.house === selectedHouse);
  });

  rowsElement.replaceChildren();
  for (const fund of filtered) {
    const row = document.createElement('tr');
    row.append(createCell('house', fund.house));
    row.append(createCell('scheme', fund.name));

    const navCell = document.createElement('td');
    const navValue = document.createElement('span');
    navValue.className = 'nav-value';
    navValue.textContent =
      typeof fund.nav === 'number' ? moneyFormat.format(fund.nav) : 'Not available';
    navCell.append(navValue);

    const details = document.createElement('span');
    details.className = `as-of${fund.error ? ' row-status failed' : ' row-status'}`;
    details.textContent = `${formatDate(fund.asOf || snapshotAsOf)} · ${
      fund.source || 'Workbook snapshot'
    }${fund.error ? ` · ${fund.error}` : ''}`;
    navCell.append(details);
    row.append(navCell);
    rowsElement.append(row);
  }

  emptyElement.hidden = filtered.length !== 0;
  document.getElementById('house-count').textContent =
    new Set(funds.map((fund) => fund.house)).size.toString();
  document.getElementById('scheme-count').textContent = funds.length.toString();
  const liveCount = funds.filter((fund) => fund.source === 'Moneycontrol').length;
  document.getElementById('nav-count').textContent =
    liveCount === funds.length ? 'Live' : `${liveCount}/${funds.length} live`;
}

function collectCandidates(value, output = []) {
  if (Array.isArray(value)) {
    for (const item of value) collectCandidates(item, output);
  } else if (value && typeof value === 'object') {
    if (typeof value.schemeName === 'string' && typeof value.isin === 'string') {
      output.push(value);
    }
    for (const nested of Object.values(value)) collectCandidates(nested, output);
  }
  return output;
}

function matchScore(fund, candidate) {
  const schemeTokens = new Set(normalized(fund.name));
  const candidateTokens = new Set(normalized(candidate.schemeName));
  const schemeMatch =
    [...schemeTokens].filter((token) => candidateTokens.has(token)).length /
    Math.max(schemeTokens.size, 1);
  const houseTokens = new Set(normalized(fund.house));
  const houseMatch =
    [...houseTokens].filter((token) => candidateTokens.has(token)).length /
    Math.max(houseTokens.size, 1);
  const candidateName = normalized(candidate.schemeName);
  const isDirect = normalized(fund.name).includes('direct');
  const candidateIsDirect = candidateName.includes('direct');
  const isGrowth = normalized(fund.name).includes('growth');
  const candidateHasDividend = candidateName.some((token) =>
    ['dividend', 'idcw', 'payout', 'reinvestment'].includes(token)
  );

  if (isDirect !== candidateIsDirect || (isGrowth && candidateHasDividend)) return 0;
  return schemeMatch * 0.85 + houseMatch * 0.15;
}

async function fetchJson(url) {
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetch(url, { signal: controller.signal });
    if (!response.ok) throw new Error(`Moneycontrol HTTP ${response.status}`);
    return await response.json();
  } finally {
    window.clearTimeout(timeout);
  }
}

async function lookupIsin(fund) {
  const url =
    `${MONEYCONTROL_SEARCH}${encodeURIComponent(fund.name)}` +
    '&limit=20&deviceType=W&responseType=json';
  const candidates = collectCandidates(await fetchJson(url))
    .map((candidate) => ({ candidate, score: matchScore(fund, candidate) }))
    .sort((left, right) => right.score - left.score);
  const best = candidates[0];
  const second = candidates[1];
  if (!best || best.score < 0.65) {
    throw new Error('No confident scheme match');
  }
  if (second && best.score - second.score < 0.08) {
    throw new Error('Ambiguous scheme match');
  }
  return best.candidate.isin;
}

function findLatestNav(value) {
  const matches = [];
  function visit(item) {
    if (Array.isArray(item)) {
      for (const child of item) visit(child);
    } else if (item && typeof item === 'object') {
      if (
        typeof item.navDate === 'string' &&
        item.navDate.match(/^\d{4}-\d{2}-\d{2}$/) &&
        Number.isFinite(Number(item.navValue))
      ) {
        matches.push({ date: item.navDate, nav: Number(item.navValue) });
      }
      for (const child of Object.values(item)) visit(child);
    }
  }
  visit(value);
  matches.sort((left, right) => left.date.localeCompare(right.date));
  return matches[matches.length - 1] || null;
}

async function refreshFund(fund) {
  fund.error = '';
  try {
    const isin = await lookupIsin(fund);
    const url =
      `${MONEYCONTROL_NAV}${encodeURIComponent(isin)}` +
      '&dur=1Y&deviceType=W&responseType=json';
    const latest = findLatestNav(await fetchJson(url));
    if (!latest) throw new Error('No NAV returned');
    fund.nav = latest.nav;
    fund.asOf = latest.date;
    fund.source = 'Moneycontrol';
    fund.error = '';
    return true;
  } catch (error) {
    fund.error =
      error.name === 'AbortError'
        ? 'NAV request timed out'
        : error instanceof TypeError
          ? 'Could not reach NAV service (check network/CORS)'
          : error.message;
    return false;
  }
}

async function refreshAll() {
  if (refreshing) return;
  refreshing = true;
  refreshButton.disabled = true;
  refreshButton.textContent = 'Refreshing NAVs…';
  showNotice(
    `Checking ${funds.length} schemes with Moneycontrol. NAV dates may be earlier than today.`,
    'warning'
  );

  let nextIndex = 0;
  let updated = 0;
  const worker = async () => {
    while (nextIndex < funds.length) {
      const currentIndex = nextIndex;
      nextIndex += 1;
      if (await refreshFund(funds[currentIndex])) updated += 1;
      render();
    }
  };

  try {
    await Promise.all(Array.from({ length: 4 }, worker));
    if (updated === funds.length) {
      showNotice(`Updated all ${updated} schemes from Moneycontrol.`);
    } else {
      showNotice(
        `${updated} of ${funds.length} NAVs updated. Unmatched or unavailable schemes are marked in the table; cached workbook values are retained.`,
        'warning'
      );
    }
  } finally {
    refreshing = false;
    refreshButton.disabled = false;
    refreshButton.textContent = 'Refresh latest NAV';
  }
}

async function initialize() {
  try {
    const response = await fetch('./mutual-funds.json');
    if (!response.ok) throw new Error(`Could not load scheme list (HTTP ${response.status})`);
    const data = await response.json();
    if (!Array.isArray(data.schemes) || !data.snapshotAsOf) {
      throw new Error('Scheme list is missing required data');
    }

    snapshotAsOf = data.snapshotAsOf;
    funds = data.schemes.map((fund) => ({
      ...fund,
      asOf: data.snapshotAsOf,
      source: 'Workbook snapshot',
      error: ''
    }));

    const houses = [...new Set(funds.map((fund) => fund.house))].sort((a, b) =>
      a.localeCompare(b)
    );
    for (const house of houses) {
      const option = document.createElement('option');
      option.value = house;
      option.textContent = house;
      houseFilterElement.append(option);
    }

    searchElement.addEventListener('input', render);
    houseFilterElement.addEventListener('change', render);
    refreshButton.addEventListener('click', refreshAll);
    showNotice(`Showing workbook NAV snapshot as of ${formatDate(snapshotAsOf)}.`);
    render();
  } catch (error) {
    showNotice(error.message, 'error');
    refreshButton.disabled = true;
  }
}

initialize();
