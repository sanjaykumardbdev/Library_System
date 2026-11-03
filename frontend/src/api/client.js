import axios from 'axios';

const api = axios.create({
  withCredentials: true,
  xsrfCookieName: 'XSRF-TOKEN',
  xsrfHeaderName: 'X-XSRF-TOKEN',
});

export async function refreshCsrfToken() {
  const response = await api.get('/api/auth/csrf');
  api.defaults.headers.common['X-XSRF-TOKEN'] = response.data.token;
}

export function getErrorMessage(error, fallback = 'The request could not be completed.') {
  const response = error.response;
  const detail = response?.data?.detail
    || response?.data?.message
    || response?.data?.title
    || (typeof response?.data === 'string' ? response.data : null);
  if (detail) return detail;
  if (response?.status === 401) return 'Your sign-in has expired. Please sign in again.';
  if (response?.status === 403 && error.config?.url?.includes('/api/me/loans')) {
    return 'Borrowing requires a signed-in Student or Professional account linked to an active library membership. Sign in with the correct account type or ask library staff to link or activate your membership.';
  }
  if (response?.status === 403 && error.config?.url?.includes('/api/auth/forgot-password')) {
    return 'Password reset is available without signing in. Refresh the page and submit again; contact library support if the problem continues.';
  }
  if (response?.status === 403) return 'Your signed-in account does not have permission for this action. Contact a library administrator if you believe access is incorrect.';
  if (response?.status === 404) return 'The requested information could not be found.';
  if (response?.status === 409) return 'This action conflicts with the current record status. Refresh and try again.';
  if (!response) return 'Unable to reach the library service. Check your connection and try again.';
  return fallback;
}

export default api;