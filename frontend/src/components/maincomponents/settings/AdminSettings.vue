<script setup>
import { ref, onMounted } from 'vue';
import { getGlobalSettings, updateRegistrationGlobalSettings } from '../../../apicalls/apiCalls';

const allowRegistration = ref(true);
const inviteCode = ref('');
const loading = ref(true);
const saving = ref(false);
const errorMsg = ref(null);
const successMsg = ref(null);

onMounted(async () => {
    try {
        const settings = await getGlobalSettings();
        allowRegistration.value = settings.allow_registration;
        inviteCode.value = settings.registration_invite_code || '';
    } catch (e) {
        errorMsg.value = "Impossibile caricare le impostazioni (sei amministratore?)";
        console.error(e);
    } finally {
        loading.value = false;
    }
});

const saveSettings = async () => {
    saving.value = true;
    errorMsg.value = null;
    successMsg.value = null;
    try {
        const settings = await updateRegistrationGlobalSettings({
            allow_registration: allowRegistration.value,
            registration_invite_code: inviteCode.value
        });
        allowRegistration.value = settings.allow_registration;
        inviteCode.value = settings.registration_invite_code || '';
        successMsg.value = "Impostazioni salvate con successo.";
    } catch (e) {
        errorMsg.value = "Errore durante il salvataggio.";
        console.error(e);
    } finally {
        saving.value = false;
    }
};
</script>

<template>
    <div class="max-w-2xl mx-auto py-6">
        <div class="bg-white rounded-3xl border border-gray-100 p-6 sm:p-8 shadow-sm">
            <h1 class="text-base sm:text-lg font-bold mb-6 sm:mb-8 text-gray-900 border-b pb-6 border-gray-100 uppercase tracking-widest">
                Impostazioni Sistema
            </h1>
            
            <div v-if="loading" class="flex justify-center py-12">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
            
            <div v-else-if="errorMsg && !saving" class="p-4 bg-red-50 text-red-600 rounded-xl mb-6 font-medium text-xs">
                {{ errorMsg }}
            </div>
            
            <div v-else class="space-y-6">
                <!-- Registration Toggle -->
                <div class="flex flex-col sm:flex-row sm:items-center justify-between p-5 bg-gray-50/50 border border-gray-100 rounded-2xl gap-4">
                    <div class="flex-1">
                        <h3 class="text-xs font-bold uppercase tracking-wider text-gray-900">Registrazioni Pubbliche</h3>
                        <p class="text-[11px] text-gray-400 font-medium mt-1 leading-relaxed">Permetti a nuovi utenti di creare un account autonomamente.</p>
                    </div>
                    <label class="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" v-model="allowRegistration" class="sr-only peer" :disabled="saving">
                        <div class="w-14 h-7 bg-gray-300 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-6 after:w-6 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                </div>

                <!-- Invite Code -->
                <div class="p-5 bg-gray-50/50 border border-gray-100 rounded-2xl space-y-4">
                    <div>
                        <h3 class="text-xs font-bold uppercase tracking-wider text-gray-900">Codice d'Invito</h3>
                        <p class="text-[11px] text-gray-400 font-medium mt-1 leading-relaxed">
                            Parola segreta richiesta durante la registrazione (lascia vuoto per disabilitare il codice).
                        </p>
                    </div>
                    <input
                        type="text"
                        v-model="inviteCode"
                        placeholder="Es: segreto_2026"
                        class="w-full px-4 py-3 rounded-xl border border-gray-200 bg-white text-xs text-gray-900 focus:outline-none focus:ring-2 focus:ring-primary-light/50 focus:border-primary-light transition-all"
                    />
                </div>

                <!-- Actions -->
                <div class="pt-6 flex flex-col sm:flex-row justify-end gap-3 border-t border-gray-100">
                    <router-link to="/settings" class="w-full sm:w-auto order-2 sm:order-1">
                        <button
                            class="w-full px-6 py-3 bg-gray-100 text-gray-700 text-xs font-bold uppercase tracking-wider rounded-xl hover:bg-gray-200 transition-all duration-200 cursor-pointer"
                        >
                            Annulla
                        </button>
                    </router-link>
                    <button 
                        @click="saveSettings" 
                        :disabled="saving"
                        class="w-full sm:w-auto order-1 sm:order-2 px-8 py-3 bg-primary text-white text-xs font-bold uppercase tracking-widest rounded-xl hover:bg-primary-hover shadow-md shadow-primary/10 transition-all duration-200 disabled:opacity-50 cursor-pointer"
                    >
                        {{ saving ? 'Salvataggio...' : 'Salva Impostazioni' }}
                    </button>
                </div>

                <!-- Messages -->
                <div v-if="successMsg" class="mt-4 p-4 bg-green-50 text-green-700 border border-green-100 rounded-xl font-medium text-xs animate-fade-in">
                    {{ successMsg }}
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
@keyframes fade-in {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
}
.animate-fade-in {
    animation: fade-in 0.3s ease-out;
}
</style>
