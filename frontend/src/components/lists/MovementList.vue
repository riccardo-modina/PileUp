<script setup>
import BaseButton from '@/components/buttons/BaseButton.vue';
import { formatAmount } from '@/helpers/dateUtils';

const props = defineProps({
    movements: {
        type: Array,
        default: () => []
    }
})

const emit = defineEmits(['modify', 'delete'])

</script>

<template>
    <ul class="flex flex-col divide-y">
        <li v-for="mv in movements" :key="mv.id || mv" class="py-3 flex flex-col md:flex-row md:items-center justify-between gap-3 md:gap-0">
            <!-- Left side: Info -->
            <div class="flex flex-col md:flex-row md:items-center md:gap-4">
                <div class="flex items-center justify-between md:justify-start gap-2">
                    <div class="text-sm text-gray-600">{{ mv.date }}</div>
                    <!-- Mobile only amount, visible on small screens if we want, but let's keep it consistent -->
                </div>
                
                <div class="flex flex-col md:flex-row md:items-center md:gap-4">
                    <div class="text-sm font-medium">{{ mv.title }}</div>
                    <div class="text-sm text-gray-500">{{ mv.category }}</div>
                </div>
            </div>

            <!-- Right side: Amount & Actions -->
            <div class="flex items-center justify-between md:justify-end gap-3 w-full md:w-auto mt-2 md:mt-0">
                <div class="text-sm font-semibold md:mr-4">€ {{ formatAmount(mv.amount) }}</div>
                
                <div class="flex gap-2">
                    <BaseButton as="button" class="px-3 py-1 bg-yellow-100 text-yellow-800 text-xs md:text-sm" @click="$emit('modify', mv)">Modifica</BaseButton>
                    <BaseButton as="button" class="px-3 py-1 bg-red-100 text-red-800 text-xs md:text-sm" @click="$emit('delete', mv)">Elimina</BaseButton>
                </div>
            </div>
        </li>
    </ul>
</template>
