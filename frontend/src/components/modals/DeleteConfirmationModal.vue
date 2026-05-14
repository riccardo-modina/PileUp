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
        <div class="fixed inset-0 z-[9999] flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" @click="$emit('close')"></div>
        <div class="relative bg-white rounded-lg shadow-xl p-6 w-full max-w-md z-10 transform transition-all">
            <h3 class="text-lg font-semibold mb-2 text-gray-900">{{ title }}</h3>
            
            <div class="text-sm text-gray-600 mb-6 leading-relaxed">
                <template v-if="message">
                    {{ message }}
                </template>
                <template v-else>
                    Sei sicuro di voler eliminare il movimento 
                    <span class="font-medium text-gray-900">{{ itemTitle }}</span> 
                    del 
                    <span class="font-medium text-gray-900">{{ date }}</span> 
                    di importo 
                    <span class="font-medium text-gray-900">€ {{ formatAmount(amount) }}</span>?
                </template>
            </div>
            
            <div class="flex flex-col-reverse sm:flex-row justify-end gap-3">
                <BaseButton as="button" class="w-full sm:w-auto px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-md transition-colors" @click="$emit('close')">
                    Annulla
                </BaseButton>
                <BaseButton as="button" class="w-full sm:w-auto px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-md transition-colors" @click="$emit('confirm')">
                    Elimina
                </BaseButton>
            </div>
        </div>
    </div>
    </Teleport>
</template>
