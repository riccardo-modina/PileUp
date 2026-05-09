<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import axiosInstance from '../axios';
import { deriveKeyEncryptionKey, decryptKey } from '../helpers/crypto';

const password = ref('');
const error = ref(null);
const loading = ref(false);
const router = useRouter();

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
            // Successfully unlocked, reload the page or go to the dashboard
            router.go(0); // reload the current route
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
  <div class="fixed inset-0 bg-background flex flex-col justify-center items-center z-50 p-6">
    <div class="bg-card-background rounded-2xl shadow-lg p-8 w-full max-w-md border border-neutral">
      <div class="text-center mb-6">
        <i class="pi pi-lock text-4xl text-primary mb-4"></i>
        <h2 class="text-2xl font-bold text-text">Sblocca la Cassaforte</h2>
        <p class="text-text-light mt-2 text-sm">La tua sessione è attiva, ma la chiave crittografica non è in memoria. Inserisci la tua password per sbloccare i tuoi dati E2EE.</p>
      </div>

      <form @submit.prevent="handleUnlock" class="space-y-6">
        <div>
          <input
            id="vault-password"
            v-model="password"
            type="password"
            placeholder="La tua password"
            required
            class="w-full px-4 py-2 rounded-lg border border-neutral bg-primary-clear text-text focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
          />
        </div>

        <button
          type="submit"
          :disabled="loading || password.length === 0"
          :class="(loading || password.length === 0) ? 'bg-primary-light text-text cursor-not-allowed' : 'bg-primary-light hover:bg-primary text-white cursor-pointer'"
          class="w-full py-3 rounded-lg font-bold transition-colors flex justify-center"
        >
          <span v-if="loading"><i class="pi pi-spin pi-spinner mr-2"></i>Sblocco in corso...</span>
          <span v-else>Sblocca</span>
        </button>

        <p v-if="error" class="text-red-500 mt-3 text-center text-sm font-semibold">{{ error }}</p>
      </form>
    </div>
  </div>
</template>
