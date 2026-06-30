<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import axiosInstance from '../axios';
import { deriveKeyEncryptionKey, decryptKey } from '../helpers/crypto';
import ShowHideButton from './buttons/ShowHideButton.vue';

const emit = defineEmits(['vault-unlocked']);

const password = ref('');
const showPassword = ref(false);
const error = ref(null);
const loading = ref(false);
const router = useRouter();

const passwordFieldType = computed(() => showPassword.value ? 'text' : 'password');

const togglePasswordVisibility = () => {
  showPassword.value = !showPassword.value;
};

const handleUnlock = async () => {
    error.value = null;
    loading.value = true;
    try {
        const userRes = await axiosInstance.get('auth/users/me/');
        const username = userRes.data.username;

        const profileRes = await axiosInstance.get('auth/profile/');
        const encryptedMasterKey = profileRes.data.encrypted_master_key;

        if (!encryptedMasterKey) {
            error.value = "Nessuna chiave crittografica trovata per questo account.";
            return;
        }

        const kek = deriveKeyEncryptionKey(password.value, username);
        const decryptedMasterKey = decryptKey(encryptedMasterKey, kek);

        if (decryptedMasterKey) {
            sessionStorage.setItem('masterKey', decryptedMasterKey);
            // Successfully unlocked, emit event to parent (App.vue)
            emit('vault-unlocked');
        } else {
            error.value = "Password errata. Impossibile decifrare i dati.";
        }
    } catch (err) {
        console.error(err);
        error.value = "Errore di connessione al server.";
    } finally {
        loading.value = false;
    }
};
</script>

<template>
  <div class="fixed inset-0 bg-background/80 backdrop-blur-xl flex flex-col justify-center items-center z-50 p-6 transition-all duration-300">
    <div class="bg-card-background rounded-3xl shadow-2xl p-8 w-full max-w-md border border-menuborder hover:border-primary/20 transition-all duration-300 animate-fade-in-up">
      
      <div class="text-center mb-8 flex flex-col items-center">
        <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary/10 border border-primary/20 mb-4 animate-bounce-subtle">
          <i class="pi pi-lock text-2xl text-primary"></i>
        </div>
        <h2 class="text-xl font-bold uppercase text-text tracking-widest font-sans animate-tracking-in">
          Inserisci la Password
        </h2>
        <p class="text-text-light mt-2 text-sm leading-relaxed font-sans animate-fade-in-delayed">
          La tua sessione è attiva, ma la chiave crittografica non è in memoria. Inserisci la tua password per sbloccare i tuoi dati protetti con crittografia End-To-End (E2EE).
        </p>
      </div>

      <form @submit.prevent="handleUnlock" class="space-y-6 animate-fade-in-delayed-more">
        <div class="space-y-1.5">
          <label for="vault-password" class="block text-text font-semibold text-xs uppercase tracking-wider mb-1 font-sans">Password</label>
          <div class="relative">
            <input
              id="vault-password"
              v-model="password"
              :type="passwordFieldType"
              placeholder="Inserisci la tua password"
              required
              class="w-full pl-4 pr-12 py-3 rounded-xl border border-neutral/30 bg-primary-clear text-text placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all font-sans"
            />
            <ShowHideButton 
              :showPassword="showPassword"
              @toggle="togglePasswordVisibility"
            />
          </div>
        </div>

        <button
          type="submit"
          :disabled="loading || password.length === 0"
          :class="(loading || password.length === 0) ? 'bg-primary-light/50 text-text/40 cursor-not-allowed' : 'bg-primary hover:bg-primary-hover active:scale-[0.98] text-white cursor-pointer shadow-md shadow-primary/10'"
          class="w-full py-3.5 rounded-xl font-bold transition-all flex justify-center items-center gap-2 font-sans"
        >
          <span v-if="loading" class="flex items-center gap-2">
            <i class="pi pi-spin pi-spinner"></i>Sblocco in corso...
          </span>
          <span v-else>Sblocca l'Applicazione</span>
        </button>

        <transition name="fade">
          <div v-if="error" class="bg-red-50 border border-red-200 text-red-600 rounded-xl p-3.5 text-xs font-semibold flex items-center gap-2.5 animate-shake">
            <i class="pi pi-exclamation-circle text-base"></i>
            <span class="font-sans">{{ error }}</span>
          </div>
        </transition>
      </form>
    </div>
  </div>
</template>

<style scoped>
@keyframes bounce-subtle {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-4px); }
}

.animate-bounce-subtle {
  animation: bounce-subtle 3s ease-in-out infinite;
}

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  20%, 60% { transform: translateX(-4px); }
  40%, 80% { transform: translateX(4px); }
}

.animate-shake {
  animation: shake 0.4s ease-in-out;
}

@keyframes tracking-in-expand {
  0% {
    letter-spacing: -0.05em;
    filter: blur(6px);
    opacity: 0;
  }
  100% {
    letter-spacing: 0.1em;
    filter: blur(0);
    opacity: 1;
  }
}

.animate-tracking-in {
  animation: tracking-in-expand 0.8s cubic-bezier(0.25, 1, 0.5, 1) forwards;
}

@keyframes gradient-text {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

.animate-gradient-text {
  animation: gradient-text 8s ease infinite;
}

@keyframes fade-in-up {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in-up {
  animation: fade-in-up 0.7s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

.animate-fade-in-delayed {
  opacity: 0;
  animation: fade-in 0.8s ease forwards;
  animation-delay: 0.25s;
}

.animate-fade-in-delayed-more {
  opacity: 0;
  animation: fade-in 0.8s ease forwards;
  animation-delay: 0.45s;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
