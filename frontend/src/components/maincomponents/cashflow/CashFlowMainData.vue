<script setup>
import { computed } from 'vue';
import { RouterLink } from 'vue-router';
import NumberCard from '../../cards/NumberCard.vue';

const props = defineProps({
  income: { type: Number, required: true },
  expense: { type: Number, required: true }
})

// Computed calculates the value immediatedly and updates when dependencies change, no undefined errors that comes with ref and onmounted
const net = computed(() => {
  return props.income - props.expense;
});

const netSign = computed(() => {
  return net.value > 0 ? "+" : "-"; 
});
</script>

<template>
  <div class="bg-white rounded-3xl border border-gray-100 p-4 sm:p-5 md:p-6 shadow-sm flex flex-col gap-4 sm:gap-5 w-full">
    <!-- Netto (Prominent, Top) -->
    <div class="bg-nett/[0.03] rounded-2xl border border-nett/10 overflow-hidden transition-all hover:bg-nett/[0.05]">
      <NumberCard 
        title="Netto" 
        :value="net"
        color="bg-transparent"
        :sign="netSign"
        iconColor="text-nett"
        class="h-full"
        :flat="true"
        :centered="true"
        valueSizeClass="text-2xl sm:text-3xl"
      />
    </div>

    <!-- Divider (Subtle) -->
    <div class="h-px bg-gray-100/80 w-full"></div>

    <!-- Entrate & Uscite (Stacked on mobile, Side-by-side on PC) -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-5 w-full">
      <!-- Entrate -->
      <div class="bg-success/[0.02] rounded-2xl border border-success/10 overflow-hidden transition-all hover:bg-success/[0.04]">
        <NumberCard 
          title="Entrate" 
          :value="income" 
          color="bg-transparent"
          icon="pi-sign-in"
          iconColor="text-success"
          class="h-full"
          iconBackground="bg-success/10"
          iconContainerClass="hide-icon-custom"
          :flat="true"
          valueSizeClass="text-xl sm:text-2xl"
        >
          <template #action>
            <RouterLink 
              to="/cashflow/income"
              class="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-success/10 text-success hover:bg-success hover:text-white transition-all duration-300 shadow-sm hover:shadow-md group/btn"
            >
              <i class="pi pi-sign-in text-base" />
              <span class="text-[11px] font-bold uppercase tracking-wider hidden sm:inline">Dettagli</span>
              <i class="pi pi-chevron-right text-[9px] opacity-70 group-hover/btn:translate-x-0.5 transition-transform" />
            </RouterLink>
          </template>
        </NumberCard>
      </div>

      <!-- Uscite -->
      <div class="bg-negative/[0.02] rounded-2xl border border-negative/10 overflow-hidden transition-all hover:bg-negative/[0.04]">
        <NumberCard 
          title="Uscite" 
          :value="expense"  
          color="bg-transparent"
          icon="pi-sign-out"
          iconColor="text-negative"
          class="h-full"
          iconBackground="bg-negative/10"
          iconContainerClass="hide-icon-custom"
          :flat="true"
          valueSizeClass="text-xl sm:text-2xl"
        >
          <template #action>
            <RouterLink 
              to="/cashflow/expenses"
              class="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-negative/10 text-negative hover:bg-negative hover:text-white transition-all duration-300 shadow-sm hover:shadow-md group/btn"
            >
              <i class="pi pi-sign-out text-base" />
              <span class="text-[11px] font-bold uppercase tracking-wider hidden sm:inline">Dettagli</span>
              <i class="pi pi-chevron-right text-[9px] opacity-70 group-hover/btn:translate-x-0.5 transition-transform" />
            </RouterLink>
          </template>
        </NumberCard>
      </div>
    </div>
  </div>
</template>

<style scoped>
@media (min-width: 769px) and (max-width: 920px) {
  :deep(.hide-icon-custom) {
    display: none !important;
  }
}



</style>
