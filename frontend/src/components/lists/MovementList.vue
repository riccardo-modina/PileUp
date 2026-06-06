<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import BaseButton from '@/components/buttons/BaseButton.vue';
import { formatAmount } from '@/helpers/dateUtils';
import VirtualScroller from 'primevue/virtualscroller';

const props = defineProps({
    movements: {
        type: Array,
        default: () => []
    }
})

const emit = defineEmits(['modify', 'delete'])

const windowWidth = ref(typeof window !== 'undefined' ? window.innerWidth : 1200);

const handleResize = () => {
    windowWidth.value = window.innerWidth;
};

onMounted(() => {
    window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
    window.removeEventListener('resize', handleResize);
});

const itemSize = computed(() => windowWidth.value < 768 ? 105 : 120);

</script>

<template>
    <div class="w-full">
        <VirtualScroller 
            :items="movements" 
            :itemSize="itemSize" 
            class="w-full"
            style="height: 600px"
            :pt="{
                content: 'flex flex-col'
            }"
        >
            <template v-slot:item="{ item: mv, options }">
                <div 
                    :class="[
                        'py-2 md:py-4 px-2',
                        options.index !== 0 ? 'border-t border-gray-50' : ''
                    ]"
                    :style="{ height: itemSize + 'px' }"
                >
                    <!-- DESKTOP LAYOUT -->
                    <div class="hidden md:grid md:grid-cols-[100px_2fr_1fr_120px_100px] md:gap-x-10 items-center w-full max-w-full mx-auto px-10 lg:px-20 h-full">
                        <!-- Date -->
                        <div class="flex justify-center">
                            <div class="text-sm font-medium text-gray-400 bg-gray-100 px-3 py-0.5 rounded text-center">
                                {{ mv.date }}
                            </div>
                        </div>
                        
                        <!-- Title & Category -->
                        <div class="flex flex-col items-start justify-center overflow-hidden gap-1">
                            <div class="text-sm text-gray-800 truncate w-full">
                                {{ mv.title }}
                            </div>
                            <div class="flex items-center gap-3 opacity-60">
                                <span class="w-1.5 h-1.5 rounded-full flex-shrink-0" :style="{ backgroundColor: mv.categoryColor || '#ccc' }"></span>
                                <div class="text-[11px] font-medium text-gray-500 uppercase tracking-wide truncate">
                                    {{ mv.category }}
                                </div>
                            </div>
                        </div>

                        <!-- Spacer -->
                        <div></div>

                        <!-- Amount -->
                        <div 
                            class="text-base whitespace-nowrap text-left"
                            :class="(mv.amount < 0 || mv.tipo === 'uscita') ? 'text-red-600' : 'text-green-600'"
                        >
                            {{ (mv.amount < 0 || mv.tipo === 'uscita') ? '-' : '+' }} € {{ formatAmount(mv.amount) }}
                        </div>
                        
                        <!-- Actions -->
                        <div class="flex items-center justify-start gap-2">
                            <BaseButton 
                                as="button"
                                class="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                @click="$emit('modify', mv)"
                                title="Modifica"
                            >
                                <i class="pi pi-pencil h-5 w-5 flex items-center justify-center" />
                            </BaseButton>
                            <BaseButton 
                                as="button"
                                class="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                @click="$emit('delete', mv)"
                                title="Elimina"
                            >
                                <i class="pi pi-trash h-5 w-5 flex items-center justify-center" />
                            </BaseButton>
                        </div>
                    </div>

                    <!-- MOBILE LAYOUT -->
                    <div class="flex md:hidden flex-col justify-center gap-2 w-full px-4 h-full">
                        <div class="flex items-center justify-between w-full">
                            <div class="text-sm font-medium text-gray-400 bg-gray-100 px-2 py-0.5 rounded">
                                {{ mv.date }}
                            </div>
                            <div class="flex items-center gap-1.5 opacity-60">
                                <span class="w-1.5 h-1.5 rounded-full flex-shrink-0" :style="{ backgroundColor: mv.categoryColor || '#ccc' }"></span>
                                <div class="text-[10px] font-medium text-gray-500 uppercase tracking-wide">
                                    {{ mv.category }}
                                </div>
                            </div>
                        </div>

                        <div class="text-sm font-bold text-gray-800 truncate w-full">
                            {{ mv.title }}
                        </div>

                        <div class="flex items-center justify-between w-full">
                            <div 
                                class="text-sm whitespace-nowrap text-left"
                                :class="(mv.amount < 0 || mv.tipo === 'uscita') ? 'text-red-600' : 'text-green-600'"
                            >
                                {{ (mv.amount < 0 || mv.tipo === 'uscita') ? '-' : '+' }} € {{ formatAmount(mv.amount) }}
                            </div>
                            
                            <div class="flex items-center gap-4">
                                <BaseButton 
                                    as="button"
                                    class="p-1 text-gray-400"
                                    @click="$emit('modify', mv)"
                                >
                                    <i class="pi pi-pencil h-5 w-5 flex items-center justify-center" />
                                </BaseButton>
                                <BaseButton 
                                    as="button"
                                    class="p-1 text-gray-400"
                                    @click="$emit('delete', mv)"
                                >
                                    <i class="pi pi-trash h-5 w-5 flex items-center justify-center" />
                                </BaseButton>
                            </div>
                        </div>
                    </div>
                </div>
            </template>
        </VirtualScroller>
    </div>
</template>
