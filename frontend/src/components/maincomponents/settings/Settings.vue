<script setup>
import { ref, onMounted } from 'vue';
import { Switch } from '@headlessui/vue';
import { getCurrentUser } from '../../../apicalls/apiCalls';
import { useAuth } from '../../../composables/useAuth';
import { useSettingsStore } from '../../../stores/settings';

defineProps({
    defaultMenuOpen: {
        type: Boolean,
        required: true
    }
});

const emit = defineEmits(['update:defaultMenuOpen']); 

const { logout } = useAuth();
const settings = useSettingsStore();

const isAdmin = ref(false);
const loadingAdminSettings = ref(true);

onMounted(async () => {
    try {
        const user = await getCurrentUser();
        isAdmin.value = user.is_staff || user.is_superuser;
    } catch (e) {
        console.error("Failed to load user settings", e);
    } finally {
        loadingAdminSettings.value = false;
    }
});

function toggleMenu(newValue) {
    emit('update:defaultMenuOpen', newValue);
}
</script>

<template>
        <section class="flex-1 h-full pt-10 pb-6">
            <div class="flex flex-col bg-white rounded-3xl border border-gray-100 p-6 md:p-8 shadow-sm gap-6">
                <!-- Menu Settings -->
                <div>
                    <h3 class="text-xs font-bold uppercase tracking-widest text-text mb-4">Menu</h3>
                    <div class="flex justify-between items-center bg-gray-50/50 border border-gray-100 rounded-2xl p-4 md:p-5">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-700">Menu fisso (su desktop)</span>
                         <Switch
                            :modelValue="defaultMenuOpen"
                            @update:modelValue="toggleMenu"
                            :class="[
                                defaultMenuOpen ? 'bg-primary-light' : 'bg-gray-300',
                                'relative inline-flex h-6 w-11 items-center rounded-full transition-colors cursor-pointer'
                            ]"
                            >
                            <span
                                :class="[
                                defaultMenuOpen ? 'translate-x-6' : 'translate-x-1',
                                'inline-block h-4 w-4 transform rounded-full bg-white transition-transform duration-300'
                                ]"
                            />
                        </Switch>
                    </div>
                </div>

                <!-- Grafici Settings -->
                <div class="border-t border-gray-100 pt-6">
                    <h3 class="text-xs font-bold uppercase tracking-widest text-text mb-4">Grafici</h3>
                    <div class="flex justify-between items-center bg-gray-50/50 border border-gray-100 rounded-2xl p-4 md:p-5">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-700">Layout incolonnato (verticale)</span>
                         <Switch
                            :modelValue="settings.chartsLayout === 'stack'"
                            @update:modelValue="(val) => settings.chartsLayout = val ? 'stack' : 'grid'"
                            :class="[
                                settings.chartsLayout === 'stack' ? 'bg-primary-light' : 'bg-gray-300',
                                'relative inline-flex h-6 w-11 items-center rounded-full transition-colors cursor-pointer'
                            ]"
                            >
                            <span
                                :class="[
                                settings.chartsLayout === 'stack' ? 'translate-x-6' : 'translate-x-1',
                                'inline-block h-4 w-4 transform rounded-full bg-white transition-transform duration-300'
                                ]"
                            />
                        </Switch>
                    </div>
                </div>
                
                <!-- Admin Settings -->
                <div v-if="isAdmin && !loadingAdminSettings" class="border-t border-gray-100 pt-6">
                    <h3 class="text-xs font-bold uppercase tracking-widest text-primary-light mb-4">Impostazioni Amministratore</h3>
                    <div class="flex flex-col gap-4 bg-gray-50/50 border border-gray-100 rounded-2xl p-4 md:p-5">
                        <p class="text-xs text-gray-500 font-medium leading-relaxed">
                            In quanto amministratore del sistema, puoi accedere al pannello di controllo per gestire permessi e funzioni globali dell'applicazione.
                        </p>
                        <div>
                            <router-link 
                                :to="'/admin-settings'"
                                class="inline-block px-5 py-2.5 bg-primary text-white text-xs font-bold uppercase tracking-wider rounded-xl hover:bg-primary-hover shadow-md shadow-primary/10 transition-all duration-200"
                            >
                                Apri Pannello Amministratore
                            </router-link>
                        </div>
                    </div>
                </div>

                <!-- Logout -->
                <div class="border-t border-gray-100 pt-6 flex justify-center">
                    <button 
                        @click="logout"
                        class="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-3.5 bg-red-50 text-red-600 text-xs font-bold uppercase tracking-widest rounded-xl cursor-pointer md:hover:bg-red-100 active:scale-95 transition-all duration-200"
                    >
                        <i class="pi pi-sign-out text-base" />
                        Esci dall'account
                    </button>
                </div>

            </div>
        </section>
</template>