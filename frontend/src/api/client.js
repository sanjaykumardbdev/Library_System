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
  return error.response?.data?.detail || error.response?.data?.message || fallback;
}

export default api;