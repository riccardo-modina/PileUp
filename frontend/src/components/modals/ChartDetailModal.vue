<script setup>
import { ref, watch, onMounted, onUnmounted } from 'vue'
import { XMarkIcon } from '@heroicons/vue/24/outline'
import { getMonthlyStats } from '../../apicalls/apiCalls'
import MonthlyNetChart from '../cards/charts/types/MonthlyNetChart.vue'
import CumulativeExpIncChart from '../cards/charts/types/CumulativeExpIncChart.vue'

const props = defineProps({
  show: Boolean,
  year: { type: String, required: true },
  month: { type: Number, default: null },
  detail: { type: String, default: 'month' }
})

const emit = defineEmits(['close'])

const loading = ref(false)
const financeData = ref({
  income: [],
  spending: [],
  monthlyIncome: 0,
  monthlyExpense: 0
})

const fetchData = async () => {
  if (!props.show) return
  loading.value = true
  try {
    const res = await getMonthlyStats(props.year, props.month, { detail: props.detail })
    financeData.value = res
  } catch (err) {
    console.error("Error loading detailed stats:", err)
  } finally {
    loading.value = false
  }
}

watch(() => props.show, (newVal) => {
  if (newVal) {
    fetchData()
    document.body.style.overflow = 'hidden'
  } else {
    document.body.style.overflow = ''
  }
})

onMounted(() => {
  if (props.show) document.body.style.overflow = 'hidden'
})

onUnmounted(() => {
  document.body.style.overflow = ''
})
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="show" class="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-10">
        <!-- Backdrop -->
        <div 
          class="absolute inset-0 bg-gray-900/80 backdrop-blur-md transition-opacity" 
          @click="emit('close')"
        ></div>

        <!-- Modal Card -->
        <Transition name="scale">
          <div 
            class="relative w-full max-w-6xl h-[80vh] bg-white rounded-[2.5rem] shadow-2xl overflow-hidden z-10 border border-gray-100 flex flex-col"
            @click.stop
          >
            <!-- Header -->
            <div class="flex justify-between items-center px-8 py-6 border-b border-gray-50">
              <div>
                <h3 class="text-2xl font-black text-gray-800 tracking-tight">Dettaglio Storico</h3>
                <p class="text-sm text-gray-500">Visualizzazione dettagliata mese per mese</p>
              </div>
              <button 
                @click="emit('close')"
                class="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-full transition-all"
              >
                <XMarkIcon class="h-8 w-8" />
              </button>
            </div>

            <!-- Content -->
            <div class="flex-1 overflow-y-auto p-8">
              <div v-if="loading" class="h-full flex items-center justify-center">
                <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
              </div>
              <div v-else class="space-y-12">
                <section class="h-96">
                   <MonthlyNetChart 
                    :income="financeData.income" 
                    :spending="financeData.spending"
                    :year="props.year"
                    :month="props.month"
                    title="CashFlow Storico (Dettaglio Mensile)"
                   />
                </section>
                <section class="h-96">
                  <CumulativeExpIncChart 
                    :income="financeData.income" 
                    :spending="financeData.spending"
                    :year="props.year"
                    :month="props.month"
                    title="Cumulativo Storico"
                  />
                </section>
              </div>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}

.scale-enter-active, .scale-leave-active {
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.scale-enter-from, .scale-leave-to {
  transform: scale(0.95) translateY(20px);
  opacity: 0;
}
</style>
