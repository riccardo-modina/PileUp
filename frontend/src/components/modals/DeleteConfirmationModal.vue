<script setup>
import BaseButton from '@/components/buttons/BaseButton.vue';
import { formatAmount } from '@/helpers/dateUtils';

const props = defineProps({
    title: {
        type: String,
        default: 'Conferma eliminazione'
    },
    message: {
        type: String,
        default: ''
    },
    // Optional props for movement-specific display
    itemTitle: {
        type: String,
        default: ''
    },
    date: {
        type: String,
        default: ''
    },
    amount: {
        type: [Number, String],
        default: 0
    }
})

const emit = defineEmits(['close', 'confirm'])

</script>

<template>
    <Teleport to="body">
        <div class="fixed inset-0 z-[9999] flex items-center justify-center p-4 transition-all duration-300">
        <div class="absolute inset-0 bg-background/80 backdrop-blur-xl transition-opacity" @click="$emit('close')"></div>
        <div class="relative bg-card-background rounded-3xl shadow-2xl p-8 w-full max-w-md z-10 border border-menuborder hover:border-primary/20 transition-all duration-300 animate-fade-in-up">
            <h3 class="text-xl font-bold mb-4 text-text font-sans animate-tracking-in tracking-widest uppercase">{{ title }}</h3>
            
            <div class="text-sm text-text-light mb-8 leading-relaxed font-sans animate-fade-in-delayed">
                <template v-if="message">
                    {{ message }}
                </template>
                <template v-else>
                    Sei sicuro di voler eliminare il movimento 
                    <span class="font-bold text-text">{{ itemTitle }}</span> 
                    del 
                    <span class="font-bold text-text">{{ date }}</span> 
                    di importo 
                    <span class="font-bold text-text">€ {{ formatAmount(amount) }}</span>?
                </template>
            </div>
            
            <div class="flex flex-col-reverse sm:flex-row justify-end gap-3 font-sans animate-fade-in-delayed-more">
                <BaseButton as="button" class="w-full sm:w-auto px-5 py-2.5 bg-neutral/30 hover:bg-neutral/50 text-text rounded-xl transition-colors font-bold" @click="$emit('close')">
                    Annulla
                </BaseButton>
                <BaseButton as="button" class="w-full sm:w-auto px-5 py-2.5 bg-red-500 hover:bg-red-600 active:scale-[0.98] shadow-md shadow-red-500/20 text-white rounded-xl transition-all font-bold flex items-center justify-center gap-2" @click="$emit('confirm')">
                    <i class="pi pi-trash text-sm"></i> Elimina
                </BaseButton>
            </div>
        </div>
    </div>
    </Teleport>
</template>
