<script setup>
import { ref, watch, onMounted, onUnmounted } from 'vue'
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
      <div v-if="show" class="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-10 transition-all duration-300">
        <!-- Backdrop -->
        <div 
          class="absolute inset-0 bg-background/80 backdrop-blur-xl transition-opacity" 
          @click="emit('close')"
        ></div>

        <!-- Modal Card -->
        <Transition name="scale">
          <div 
            class="relative w-full max-w-6xl h-[80vh] bg-card-background rounded-3xl shadow-2xl overflow-hidden z-10 border border-menuborder hover:border-primary/20 flex flex-col transition-all duration-300 animate-fade-in-up"
            @click.stop
          >
            <!-- Header -->
            <div class="flex justify-between items-center px-8 py-6 border-b border-menuborder bg-card-background/50 backdrop-blur-sm z-20">
              <div>
                <h3 class="text-xl font-bold uppercase text-text tracking-widest font-sans animate-tracking-in">Dettaglio Storico</h3>
                <p class="text-sm text-text-light font-sans mt-1 animate-fade-in-delayed">Visualizzazione dettagliata mese per mese</p>
              </div>
              <button 
                @click="emit('close')"
                class="p-2 text-text-light hover:text-text hover:bg-neutral/30 rounded-full transition-all animate-fade-in-delayed"
              >
                <i class="pi pi-times text-2xl" />
              </button>
            </div>

            <!-- Content -->
            <div class="flex-1 overflow-y-auto p-8 bg-background/50">
              <div v-if="loading" class="h-full flex flex-col items-center justify-center font-sans text-text animate-fade-in">
                <i class="pi pi-spin pi-spinner text-5xl text-primary mb-4"></i>
                <p>Caricamento dati...</p>
              </div>
              <div v-else class="space-y-12 animate-fade-in-delayed-more">
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
