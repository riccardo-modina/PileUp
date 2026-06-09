<script setup>
import { computed } from 'vue';
import { RouterLink } from 'vue-router';

const props = defineProps({
  income: { type: Number, required: true },
  expense: { type: Number, required: true }
})

const net = computed(() => props.income - props.expense);

const netSign = computed(() => {
  if (net.value > 0) return "+";
  if (net.value < 0) return "-";
  return "";
});

const netColorClass = computed(() => {
  if (net.value < 0) return 'text-negative';
  return 'text-gray-800';
});

const formatCurrency = (value) => {
  return new Intl.NumberFormat("it-IT", { 
    style: "currency", 
    currency: "EUR",
    maximumFractionDigits: 2 
  }).format(value);
};

const formattedNet = computed(() => formatCurrency(net.value));
const formattedIncome = computed(() => formatCurrency(props.income));
const formattedExpense = computed(() => formatCurrency(props.expense));
</script>

<template>
  <div class="bg-white/80 backdrop-blur-xl rounded-[32px] border border-white/50 p-6 md:p-8 shadow-[0_8px_30px_rgb(0,0,0,0.04)] flex flex-col items-center w-full relative overflow-hidden transition-all duration-500 hover:shadow-[0_8px_40px_rgb(0,0,0,0.08)]">
    <!-- Netto Totale Centrato -->
    <div class="relative z-10 flex flex-col items-center justify-center p-4 md:p-8 rounded-[32px] md:col-span-2 w-full transition-all duration-500 hover:scale-[1.01]">
      <h2 class="text-xs md:text-sm font-bold text-gray-400 uppercase tracking-[0.2em] mb-2 md:mb-4">
        Netto
      </h2>
      
      <div class="flex items-baseline justify-center w-full overflow-hidden">
        <span 
          :class="[
            'text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-semibold text-center tracking-tighter break-all leading-none transition-colors duration-500',
            netColorClass
          ]"
        >
          {{ formattedNet }}
        </span>
      </div>
    </div>

    <!-- Divider -->
    <div class="w-full max-w-md h-px bg-gradient-to-r from-transparent via-gray-200 to-transparent mb-5 md:mb-10"></div>

    <!-- Entrate & Uscite (Side by side) -->
    <div class="grid grid-cols-2 gap-2.5 md:gap-8 w-full max-w-3xl z-10">
      
      <!-- Entrate Column -->
      <div class="flex flex-col items-center p-3 md:p-6 rounded-3xl transition-all duration-500 hover:bg-success/[0.03] group border border-transparent hover:border-success/10 w-full">
        <div class="flex items-center gap-1.5 md:gap-2 mb-1.5 md:mb-3 text-success/80">
          <i class="pi pi-sign-in text-sm md:text-lg transition-transform duration-500 group-hover:rotate-3" />
          <h3 class="text-[10px] md:text-sm font-bold uppercase tracking-widest">Entrate</h3>
        </div>
        
        <span class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-semibold text-gray-800 tracking-tight mb-2.5 md:mb-5 transition-transform duration-300 group-hover:-translate-y-0.5">
          {{ formattedIncome }}
        </span>

        <RouterLink 
          :to="{ path: '/cashflow/income', state: { periodTotal: formattedIncome } }"
          class="flex items-center gap-1.5 md:gap-2 px-3 py-1.5 md:px-4 md:py-2 rounded-xl bg-success/10 text-success hover:bg-success hover:text-white transition-all duration-300 shadow-sm hover:shadow-md hover:-translate-y-0.5"
        >
          <span class="text-[9px] md:text-[11px] font-extrabold uppercase tracking-wider">Dettagli</span>
          <i class="pi pi-arrow-right text-[8px] md:text-[10px] opacity-70 transition-transform duration-300 group-hover:translate-x-1" />
        </RouterLink>
      </div>

      <!-- Uscite Column -->
      <div class="flex flex-col items-center p-3 md:p-6 rounded-3xl transition-all duration-500 hover:bg-negative/[0.03] group border border-transparent hover:border-negative/10 w-full">
        <div class="flex items-center gap-1.5 md:gap-2 mb-1.5 md:mb-3 text-negative/80">
          <i class="pi pi-sign-out text-sm md:text-lg transition-transform duration-500 group-hover:-rotate-3" />
          <h3 class="text-[10px] md:text-sm font-bold uppercase tracking-widest">Uscite</h3>
        </div>
        
        <span class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-semibold text-gray-800 tracking-tight mb-2.5 md:mb-5 transition-transform duration-300 group-hover:-translate-y-0.5">
          {{ formattedExpense }}
        </span>

        <RouterLink 
          :to="{ path: '/cashflow/expenses', state: { periodTotal: formattedExpense } }"
          class="flex items-center gap-1.5 md:gap-2 px-3 py-1.5 md:px-4 md:py-2 rounded-xl bg-negative/10 text-negative hover:bg-negative hover:text-white transition-all duration-300 shadow-sm hover:shadow-md hover:-translate-y-0.5"
        >
          <span class="text-[9px] md:text-[11px] font-extrabold uppercase tracking-wider">Dettagli</span>
          <i class="pi pi-arrow-right text-[8px] md:text-[10px] opacity-70 transition-transform duration-300 group-hover:translate-x-1" />
        </RouterLink>
      </div>

    </div>
  </div>
</template>

<style scoped>
</style>
