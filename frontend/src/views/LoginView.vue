<script setup>
import { ref, computed } from 'vue';
import { useAuth } from '../composables/useAuth';
import Title from '../components/Title.vue';
import ShowHideButton from '../components/buttons/ShowHideButton.vue';

const username = ref('');
const password = ref('');
const showPassword = ref(false);

const { login, authError } = useAuth();

const passwordFieldType = computed(() => showPassword.value ? 'text' : 'password');

const handleLogin = () => {
  login(username.value, password.value);
};

const togglePasswordVisibility = () => {
  showPassword.value = !showPassword.value;
};

const isFormValid = computed(() => {
  return username.value.length > 0 && password.value.length > 0;
});

</script>

<template>
  <div class="flex flex-col min-h-screen bg-background">
    <div class="flex-grow flex justify-center items-center p-6 transition-all duration-300">
      <div class="w-full max-w-md">
        <div class="bg-card-background rounded-3xl shadow-2xl p-8 border border-menuborder hover:border-primary/20 transition-all duration-300 animate-fade-in-up">
          
          <div class="text-center mb-8 flex flex-col items-center">
            <Title title="PiggyPath" class="text-5xl mb-2 animate-tracking-in" />
            <p class="text-center text-sm leading-relaxed text-primary-light font-bold font-sans animate-fade-in-delayed">Segui il tuo denaro, Costruisci il tuo futuro</p>
            <h2 class="text-xl font-bold uppercase text-text tracking-widest font-sans mt-4 animate-fade-in-delayed">
              Accedi
            </h2>
          </div>

          <form @submit.prevent="handleLogin" class="space-y-6 animate-fade-in-delayed-more">
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
              <label for="password" class="block text-text font-semibold text-xs uppercase tracking-wider mb-1 font-sans">Password</label>
              <div class="relative">
                <input
                  :type="passwordFieldType"
                  id="password"
                  v-model="password"
                  placeholder="Password"
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
              :disabled="!isFormValid"
              :class="!isFormValid ? 'bg-primary-light/50 text-text/40 cursor-not-allowed' : 'bg-primary hover:bg-primary-hover active:scale-[0.98] text-white cursor-pointer shadow-md shadow-primary/10'"
              class="w-full py-3.5 rounded-xl font-bold transition-all flex justify-center items-center gap-2 font-sans"
            >
              <span>Accedi</span>
            </button>

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