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
  if (net.value > 0) return 'text-nett/90';
  if (net.value < 0) return 'text-negative/80';
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
    <!-- Decorative background element for Netto -->
    <div class="absolute top-0 left-0 right-0 h-1/2 bg-gradient-to-b from-gray-50 to-transparent pointer-events-none"></div>

    <!-- Netto (Prominent, Top Center) -->
    <div class="flex flex-col items-center z-10 w-full mb-5 mt-1 md:mb-8 md:mt-2">
      <h3 class="text-[11px] font-bold text-gray-400 uppercase tracking-[0.2em] mb-3">
        Bilancio Netto
      </h3>
      <div class="flex items-baseline gap-1 group">
        <span :class="['text-4xl md:text-5xl lg:text-6xl font-black tracking-tight transition-colors duration-300', netColorClass]">
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
        
        <span class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-extrabold text-gray-800 tracking-tight mb-2.5 md:mb-5 transition-transform duration-300 group-hover:-translate-y-0.5">
          {{ formattedIncome }}
        </span>

        <RouterLink 
          to="/cashflow/income"
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
        
        <span class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-extrabold text-gray-800 tracking-tight mb-2.5 md:mb-5 transition-transform duration-300 group-hover:-translate-y-0.5">
          {{ formattedExpense }}
        </span>

        <RouterLink 
          to="/cashflow/expenses"
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
