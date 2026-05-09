import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import axiosInstance, { axiosEventBus } from '../axios'
import { generateMasterKey, generateRecoveryKey, deriveKeyEncryptionKey, encryptKey, decryptKey } from '../helpers/crypto'

const authToken = ref(localStorage.getItem('authToken') || null)
const refreshToken = ref(localStorage.getItem('refreshToken') || null)
// const permissions = ref(localStorage.getItem('userPermissions') || null)
const authError = ref(null)

// 🔹 helper function to translate the error into a string
function parseError(err, fallbackMessage = 'Si è verificato un errore.') {
  if (!err.response) {
    return 'Errore di rete, riprova più tardi.'
  }

  const data = err.response.data

  if (typeof data === 'string') {
    return data
  }

  if (data.detail) {
    return data.detail
  }

  // If it's an object with fields (e.g., { email: ["..."], password: ["..."] })
  const firstKey = Object.keys(data)[0]
  if (firstKey) {
    const val = data[firstKey]
    return Array.isArray(val) ? val[0] : val
  }

  return fallbackMessage
}

export function useAuth() {
  const router = useRouter()

  const login = async (username, password, shouldRedirect = true) => {
    try {
      const res = await axiosInstance.post('auth/jwt/create/', {
        username,
        password,
      })
      const access = res.data.access
      const refresh = res.data.refresh
      localStorage.setItem('authToken', access)
      localStorage.setItem('refreshToken', refresh)
      authError.value = null

      // Fetch or generate E2EE Master Key
      try {
        const profileRes = await axiosInstance.get('auth/profile/')
        const profile = profileRes.data
        let encryptedMasterKey = profile.encrypted_master_key

        const kek = deriveKeyEncryptionKey(password, username)

        if (!encryptedMasterKey) {
          // New user or no key yet
          const newMasterKey = generateMasterKey()
          encryptedMasterKey = encryptKey(newMasterKey, kek)

          const recoveryKey = generateRecoveryKey()
          const recoveryKek = deriveKeyEncryptionKey(recoveryKey, username)
          const recoveryEncryptedKey = encryptKey(newMasterKey, recoveryKek)

          await axiosInstance.patch('auth/profile/', {
            encrypted_master_key: encryptedMasterKey,
            recovery_encrypted_master_key: recoveryEncryptedKey
          })

          sessionStorage.setItem('masterKey', newMasterKey)
          sessionStorage.setItem('tempRecoveryKey', recoveryKey)
        } else {
          const decryptedMasterKey = decryptKey(encryptedMasterKey, kek)
          if (decryptedMasterKey) {
            sessionStorage.setItem('masterKey', decryptedMasterKey)
          } else {
            throw new Error("Impossibile decifrare la chiave master. Dati corrotti.")
          }
        }
      } catch (e) {
        console.error("Errore E2EE:", e)
        authError.value = "Errore durante l'inizializzazione della crittografia."
        // Clear tokens since login is effectively failed if E2EE fails
        localStorage.removeItem('authToken')
        localStorage.removeItem('refreshToken')
        return
      }

      // Update reactive variables now that sessionStorage has the key
      authToken.value = access
      refreshToken.value = refresh

      if (shouldRedirect) {
        router.push('/cashflow') // FOR NOW it's this, LATER there will be the FULL DASHBOARD which will have the route /
      }
    } catch (err) {
      if (!authError.value) {
        authError.value = parseError(err, 'Credenziali non valide')
      }
    } finally {
      // try {
      //   const permissionsRes = await axiosInstance.get('api/auth/permissions/')
      //   permissions.value = permissionsRes.data.permissions
      //   localStorage.setItem('userPermissions', JSON.stringify(permissions.value))
      // } catch (err) {
      //   console.error('Failed to fetch permissions:', err)
      // }
    }
  }

  const logout = async () => {
    localStorage.removeItem('authToken')
    localStorage.removeItem('refreshToken')
    sessionStorage.removeItem('masterKey')
    sessionStorage.removeItem('tempRecoveryKey')
    authToken.value = null
    refreshToken.value = null
    router.push('/login')
  }

  // Listen for logout event from axios
  const handleLogoutEvent = () => {
    logout()
  }

  onMounted(() => {
    axiosEventBus.addEventListener('auth:logout', handleLogoutEvent)
  })

  onUnmounted(() => {
    axiosEventBus.removeEventListener('auth:logout', handleLogoutEvent)
  })

  const register = async (email, username, password) => {
    try {
      // 1. Generate E2EE keys
      const newMasterKey = generateMasterKey()
      const kek = deriveKeyEncryptionKey(password, username)
      const encryptedMasterKey = encryptKey(newMasterKey, kek)

      const recoveryKey = generateRecoveryKey()
      const recoveryKek = deriveKeyEncryptionKey(recoveryKey, username)
      const recoveryEncryptedKey = encryptKey(newMasterKey, recoveryKek)

      // 2. Register user with keys
      await axiosInstance.post('auth/register/', {
        username,
        email,
        password,
        encrypted_master_key: encryptedMasterKey,
        recovery_encrypted_master_key: recoveryEncryptedKey
      })

      // Save recovery key to session temporary so Register UI can show it
      sessionStorage.setItem('tempRecoveryKey', recoveryKey)

      // 3. Login without immediate redirect so UI can show recovery key
      await login(username, password, false)
    } catch (err) {
      authError.value = parseError(err, 'Registrazione fallita')
      console.error(err)
      throw err // Rethrow to handle it in the component
    }
  }

  return {
    authToken,
    // permissions,
    authError,
    login,
    logout,
    register
  }
}