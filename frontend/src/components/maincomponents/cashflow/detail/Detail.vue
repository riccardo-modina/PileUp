<script setup>
import ChartSection from '@/components/cards/charts/ChartSection.vue';
import CumulativeLinear from '@/components/cards/charts/types/CumulativeLinear.vue';
import StackedArea from '@/components/cards/charts/types/StackedArea.vue';
import MovementList from '@/components/lists/MovementList.vue';
import DeleteConfirmationModal from '@/components/modals/DeleteConfirmationModal.vue';
import SelectDropdown from '@/components/formcomponents/SelectDropdown.vue';
import BaseButton from '@/components/buttons/BaseButton.vue';
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useFinancialsStore } from '@/stores/financials';

const props = defineProps({
    desc: {
        type: String,
        default: 'Some details'
    },
    serie: {
        type: Array,
        default: () => []
    }, 
    categories: {
    type: Array,
    default: () => []
  },
    hasMore: {
        type: Boolean,
        default: true
    },
    selectedCategory: {
        type: [String, Number],
        default: ''
    },
    unclassifiedCount: {
        type: Number,
        default: 0
    }
})

import { ExclamationTriangleIcon } from '@heroicons/vue/24/outline';

const emit = defineEmits(['delete-movement', 'load-more', 'filter-category']);

const router = useRouter();
const financials = useFinancialsStore();

const showDeleteModal = ref(false);
const selectedMovement = ref(null);

const hasMovements = computed(() => Array.isArray(props.serie) && props.serie.length > 0);

function openDeleteModal(mv) {
    selectedMovement.value = mv;
    showDeleteModal.value = true;
}

function closeDeleteModal() {
    selectedMovement.value = null;
    showDeleteModal.value = false;
}

function confirmDelete() {
    emit('delete-movement', selectedMovement.value);
    closeDeleteModal();
}

function onModify(mv) {
    console.log('Detail.vue - Setting editingMovement in store:', mv);
    // set the editing movement in the store and navigate to the add/modify view
    financials.editingMovement = mv;
    router.push({ name: 'AddModifyTransaction' });
}

function onLoadMore() {
    emit('load-more');
}

function formatAmount(v) {
    if (typeof v === 'number') return v.toFixed(2);
    return v;
}


</script>

<template>
    <div class="flex flex-col h-full gap-4">
        <section>
            <ChartSection
                :leftChart="{ component: CumulativeLinear, props: { serie: serie, categories: categories} }"
                :rightChart="{ component: StackedArea, props: { serie: serie, categories: categories  } }"
                height="h-full md:h-auto lg:h-[400px] 2xl:h-[500px]"
            />
        </section>

        <section class="flex-1 bg-background md:pb-10">
                <div class = "flex flex-col bg-white rounded-[10px] min-h-40 p-4 gap-4 shadow-sm">
                        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
                            <h1 class="text-2xl font-semibold">{{ desc }}</h1>
                            <div class="flex flex-col sm:flex-row gap-3 items-center w-full md:w-auto">
                                <!-- Load All Button at the top -->
                                <BaseButton 
                                    v-if="hasMore" 
                                    as="button" 
                                    class="w-full sm:w-auto px-4 py-2 bg-primary text-white rounded-xl font-bold shadow-lg shadow-primary/10 hover:bg-primary-hover transition-all text-sm" 
                                    @click="$emit('load-all')"
                                >
                                    Carica Tutto
                                </BaseButton>
                                <div v-else-if="hasMovements" class="hidden sm:block text-xs text-green-600 bg-green-50 px-3 py-1 rounded-full border border-green-100 font-medium">
                                    ✓ Dati completi
                                </div>

                                <div class="w-full md:w-64">
                                    <SelectDropdown 
                                        :items="categories" 
                                        :model-value="selectedCategory"
                                        placeholder="Filtra per categoria"
                                        item-label="nome"
                                        :show-color="true"
                                        :filter-system-items="false"
                                        @update:model-value="(val) => $emit('filter-category', val)"
                                    />
                                </div>
                            </div>
                        </div>

                        <!-- Alert for unclassified movements -->
                        <div v-if="unclassifiedCount > 0" class="bg-amber-50 border-l-4 border-amber-400 p-4 mb-2 flex items-start gap-3 rounded-r-md shadow-sm">
                            <ExclamationTriangleIcon class="h-5 w-5 text-amber-500 mt-0.5 flex-shrink-0" />
                            <div>
                                <p class="text-sm text-amber-800 font-medium">
                                    Attenzione: Ci sono {{ unclassifiedCount }} movimenti da classificare.
                                </p>
                                <p class="text-xs text-amber-700 mt-1">
                                    Alcuni movimenti sono associati a categorie o conti temporanei "Da riassociare".
                                </p>
                            </div>
                        </div>

                        <div>
                            <div v-if="!hasMovements" class="text-center text-gray-500 py-6">Nessun movimento</div>

                            <MovementList 
                                v-else 
                                :movements="serie" 
                                @modify="onModify" 
                                @delete="openDeleteModal" 
                            />
                        </div>

                        <div class="mt-4 text-center">
                            <BaseButton v-if="hasMore" as="button" class="w-full px-4 py-3 bg-primary-light/10 text-primary-light border border-primary-light/20 hover:bg-primary-light/20 transition-all rounded-xl font-bold" @click="onLoadMore">Mostra altri movimenti</BaseButton>
                            <div v-else-if="hasMovements" class="w-full text-gray-400 py-4 italic text-xs border-t border-gray-50 mt-4 flex items-center justify-center gap-2">
                                <span class="w-2 h-2 bg-green-500 rounded-full"></span>
                                Hai caricato tutti i movimenti di questo periodo
                            </div>
                        </div>

                        <DeleteConfirmationModal
                            v-if="showDeleteModal"
                            :itemTitle="selectedMovement?.title"
                            :date="selectedMovement?.date"
                            :amount="selectedMovement?.amount"
                            @close="closeDeleteModal"
                            @confirm="confirmDelete"
                        />

                </div>
        </section>

       
    </div>
</template>