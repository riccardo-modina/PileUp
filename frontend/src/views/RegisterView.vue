<script setup>
import { ref, computed, onMounted } from 'vue';
import { useAuth } from '../composables/useAuth';
import { getGlobalSettings } from '../apicalls/apiCalls';
import Title from '../components/Title.vue';
import ShowHideButton from '../components/buttons/ShowHideButton.vue';

const username = ref('');
const email = ref('');
const password = ref('');
const showPassword = ref(false);
const recoveryKey = ref(null);
const isRegistrationAllowed = ref(true);
const isInitialized = ref(false);
const loadingSettings = ref(true);
const isLoading = ref(false);
const inviteCode = ref('');

const { register, authError } = useAuth();

onMounted(async () => {
    try {
        const settings = await getGlobalSettings();
        isRegistrationAllowed.value = settings.allow_registration;
        isInitialized.value = settings.is_initialized;
    } catch (e) {
        console.error("Errore caricamento impostazioni:", e);
    } finally {
        loadingSettings.value = false;
    }
});

const passwordFieldType = computed(() => showPassword.value ? 'text' : 'password');

const handleRegister = async () => {
  if (isLoading.value) return;
  isLoading.value = true;
  try {
    await register(email.value, username.value, password.value, inviteCode.value);
    recoveryKey.value = sessionStorage.getItem('tempRecoveryKey');
  } catch (e) {
    // Handled in useAuth
  } finally {
    isLoading.value = false;
  }
};

const togglePasswordVisibility = () => {
  showPassword.value = !showPassword.value;
};

const isFormValid = computed(() => {
  const basic = username.value.length > 0 && password.value.length > 0 && email.value.length > 0;
  if (isInitialized.value) {
    return basic && inviteCode.value.length > 0;
  }
  return basic;
});

</script>

<template>
  <div class="flex flex-col min-h-screen bg-background">
    <div class="flex-grow flex justify-center items-center p-6 transition-all duration-300">
      <div class="w-full max-w-md">
        
        <div v-if="loadingSettings" class="text-center text-text font-sans animate-fade-in flex flex-col items-center justify-center">
          <i class="pi pi-spin pi-spinner text-4xl text-primary mb-4"></i>
          <p>Caricamento...</p>
        </div>

        <div v-else-if="!isRegistrationAllowed" class="bg-card-background rounded-3xl shadow-2xl p-8 border border-menuborder hover:border-primary/20 transition-all duration-300 animate-fade-in-up text-center">
            <Title title="PiggyPath" class="text-5xl mb-2 animate-tracking-in" />
            <h2 class="text-2xl font-bold mt-8 text-red-500 font-sans animate-fade-in-delayed">Registrazioni Chiuse</h2>
            <p class="text-text mt-4 text-sm font-sans animate-fade-in-delayed">Attualmente non è possibile creare nuovi account.</p>
            <router-link to="/login" class="text-primary hover:text-primary-hover hover:underline mt-6 inline-block font-sans animate-fade-in-delayed font-bold transition-colors">Torna al Login</router-link>
        </div>

        <div v-else-if="recoveryKey" class="bg-card-background rounded-3xl shadow-2xl p-8 text-center border-2 border-primary transition-all duration-300 animate-fade-in-up">
            <h2 class="text-3xl font-bold mb-4 text-primary font-sans animate-tracking-in">Registrazione Completata!</h2>
            <p class="text-text mb-4 text-sm font-sans animate-fade-in-delayed leading-relaxed">Questa è la tua <strong>Recovery Key</strong>. Salvala in un posto sicuro, preferibilmente offline (es. su un foglio di carta o un password manager sicuro).</p>
            
            <div class="bg-neutral/30 p-4 rounded-xl text-lg font-mono text-text border border-neutral/50 mb-6 select-all break-words animate-fade-in-delayed-more shadow-inner">
                {{ recoveryKey }}
            </div>

            <p class="text-red-500 font-bold mb-6 text-xs font-sans animate-fade-in-delayed-more bg-red-50 border border-red-200 p-3.5 rounded-xl text-left flex gap-2.5">
                <i class="pi pi-exclamation-triangle text-base mt-0.5"></i>
                <span>ATTENZIONE: I tuoi dati sono protetti da crittografia End-To-End. Se perdi sia la password che questa Recovery Key, i tuoi dati saranno persi per sempre!</span>
            </p>

            <router-link to="/cashflow" class="w-full py-3.5 px-6 bg-primary hover:bg-primary-hover active:scale-[0.98] shadow-md shadow-primary/10 text-white rounded-xl font-bold transition-all flex justify-center items-center gap-2 font-sans animate-fade-in-delayed-more">
                <span>Ho salvato la chiave, vai alla Dashboard</span>
            </router-link>
        </div>

        <div v-else class="bg-card-background rounded-3xl shadow-2xl p-8 border border-menuborder hover:border-primary/20 transition-all duration-300 animate-fade-in-up">
          <div class="text-center mb-8 flex flex-col items-center">
            <Title title="PiggyPath" class="text-5xl mb-2 animate-tracking-in" />
            <p class="text-center text-sm leading-relaxed text-primary-light font-bold font-sans animate-fade-in-delayed">Segui il tuo denaro, Costruisci il tuo futuro</p>
            <h2 class="text-xl font-bold uppercase text-text tracking-widest font-sans mt-4 animate-fade-in-delayed">
              Registrati
            </h2>
          </div>

          <form @submit.prevent="handleRegister" class="space-y-6 animate-fade-in-delayed-more">
            <div class="space-y-1.5">
              <label for="username" class="block text-text font-semibold text-xs uppercase tracking-wider mb-1 font-sans">Username</label>
              <input
                id="username"
                v-model="username"
                type="text"
                placeholder="Username"
                required
                class="w-full px-4 py-3 rounded-xl border border-neutral/30 bg-primary-clear text-text placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all font-sans"
              />
            </div>

            <div class="space-y-1.5">
              <label for="email" class="block text-text font-semibold text-xs uppercase tracking-wider mb-1 font-sans">Email</label>
              <input
                id="email"
                v-model="email"
                type="email"
                placeholder="Email"
                required
                class="w-full px-4 py-3 rounded-xl border border-neutral/30 bg-primary-clear text-text placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all font-sans"
              />
            </div>

            <div class="space-y-1.5">
              <label for="password" class="block text-text font-semibold text-xs uppercase tracking-wider mb-1 font-sans">Password</label>
              <div class="relative">
                <input
                  :type="passwordFieldType"
                  id="password"
                  v-model="password"
                  placeholder="Password (questa cifrerà i tuoi dati)"
                  required
                  class="w-full pl-4 pr-12 py-3 rounded-xl border border-neutral/30 bg-primary-clear text-text placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all font-sans"
                />
                <ShowHideButton 
                  :showPassword="showPassword"
                  @toggle="togglePasswordVisibility"
                />
              </div>
            </div>

            <transition name="fade">
              <div v-if="isInitialized" class="space-y-1.5">
                <label for="inviteCode" class="block text-text font-semibold text-xs uppercase tracking-wider mb-1 font-sans">Codice d'Invito</label>
                <input
                  id="inviteCode"
                  v-model="inviteCode"
                  type="text"
                  placeholder="Inserisci il codice ricevuto dal proprietario"
                  required
                  class="w-full px-4 py-3 rounded-xl border border-neutral/30 bg-primary-clear text-text placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all font-sans"
                />
                <p class="text-xs text-primary-light mt-1 font-sans">La registrazione è riservata. Chiedi il codice al proprietario dell'app.</p>
              </div>
            </transition>

            <button
              type="submit"
              :disabled="!isFormValid || isLoading"
              :class="(!isFormValid || isLoading) ? 'bg-primary-light/50 text-text/40 cursor-not-allowed' : 'bg-primary hover:bg-primary-hover active:scale-[0.98] text-white cursor-pointer shadow-md shadow-primary/10'"
              class="w-full py-3.5 rounded-xl font-bold transition-all flex justify-center items-center gap-2 font-sans"
            >
              <i v-if="isLoading" class="pi pi-spin pi-spinner"></i>
              <span v-else>Registrati</span>
            </button>

            <p class="text-center text-sm text-text mt-4 font-sans">
              Hai già un account? <router-link to="/login" class="text-primary hover:text-primary-hover hover:underline font-bold transition-colors">Accedi</router-link>
            </p>

            <transition name="fade">
              <div v-if="authError" class="bg-red-50 border border-red-200 text-red-600 rounded-xl p-3.5 text-xs font-semibold flex items-center gap-2.5 animate-shake mt-4">
                <i class="pi pi-exclamation-circle text-base"></i>
                <span class="font-sans">{{ authError }}</span>
              </div>
            </transition>
            
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
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
