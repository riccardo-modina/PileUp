import axios from 'axios'

export const axiosEventBus = new EventTarget()

// If VITE_API_URL starts with "/", use it as is (relative path)
// Otherwise add http/https (absolute path)
const apiPath = import.meta.env.VITE_API_URL || 'localhost:8000';

const baseURL = apiPath.startsWith('/')
  ? apiPath
  : `${window.location.protocol}//${apiPath}/`;

const axiosInstance = axios.create({
  baseURL: baseURL.endsWith('/') ? baseURL : `${baseURL}/`, // Ensure trailing slash
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor: attach access token
axiosInstance.interceptors.request.use(config => {
  const token = localStorage.getItem('authToken')
  if (token) {
    config.headers['Authorization'] = `Bearer ${token}`
  }
  return config
})

// Response interceptor: handle 401 and refresh token
axiosInstance.interceptors.response.use(
  response => response,
  async error => {
    const originalRequest = error.config
    if (
      error.response &&
      error.response.status === 401 &&
      !originalRequest._retry &&
      !originalRequest.url.endsWith('auth/jwt/refresh/') &&
      localStorage.getItem('refreshToken')
    ) {
      originalRequest._retry = true
      try {
        const refreshToken = localStorage.getItem('refreshToken')
        const res = await axiosInstance.post('auth/jwt/refresh/', {
          refresh: refreshToken,
        })
        const newAccess = res.data.access
        localStorage.setItem('authToken', newAccess)
        originalRequest.headers['Authorization'] = `Bearer ${newAccess}`
        return axiosInstance(originalRequest)
      } catch (refreshError) {
        // Instead of redirecting, emit an event
        axiosEventBus.dispatchEvent(new Event('auth:logout'))
        return Promise.reject(refreshError)
      }
    }
    return Promise.reject(error)
  }
)

export default axiosInstance