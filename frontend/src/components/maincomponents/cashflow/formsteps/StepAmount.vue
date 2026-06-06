<script setup>
import { ref } from 'vue'
import InputError from '@/components/formcomponents/addform/InputError.vue'

const props = defineProps({
  form: {
    type: Object,
    required: true
  },
  activeStep: {
    type: Number,
    required: true
  },
  isCard2Valid: {
    type: Boolean,
    required: true
  },
  displayValue: {
    type: String,
    required: true
  },
  shakeAmount: {
    type: Boolean,
    required: true
  },
  showNumericError: {
    type: Boolean,
    required: true
  },
  showDecimalError: {
    type: Boolean,
    required: true
  },
  showZeroError: {
    type: Boolean,
    required: true
  },
  showLimitError: {
    type: Boolean,
    required: true
  },
  currency: {
    type: String,
    default: '€'
  }
})

const emit = defineEmits([
  'update-active-step',
  'amount-input',
  'amount-focus',
  'amount-blur',
  'amount-enter'
])

const amountInput = ref(null)

function focusInput() {
  amountInput.value?.focus()
}

defineExpose({
  focusInput
})
</script>

<template>
  <div 
    class="flex gap-3 sm:gap-6 relative transition-all duration-300"
    :class="[props.activeStep === 2 ? 'z-30' : 'z-10']"
  >
    
    <!-- Left Column: Badge and Timeline Line -->
    <div class="hidden sm:flex flex-col items-center relative w-6 sm:w-8 flex-shrink-0 z-10">
      <!-- Badge -->
      <div 
        class="w-6 h-6 sm:w-8 sm:h-8 rounded-full flex items-center justify-center text-xs sm:text-sm font-bold transition-all duration-300 border-2 z-20"
        :class="[
          props.isCard2Valid 
            ? 'bg-green-500 text-white border-green-500 shadow-sm' 
            : props.activeStep === 2 
              ? 'bg-primary text-white border-primary shadow-md' 
              : 'bg-white text-gray-400 border-gray-200'
        ]"
      >
        <i v-if="props.isCard2Valid" class="pi pi-check text-xs" />
        <span v-else>2</span>
      </div>
      <!-- Line Segment 2 (Connecting to Step 3) -->
      <div class="w-0.5 bg-gray-100 absolute left-1/2 -translate-x-1/2 top-6 sm:top-8 bottom-[-40px] z-0">
        <div 
          class="w-full bg-primary transition-all duration-500 rounded-full" 
          :style="{ height: props.isCard2Valid ? '100%' : '0%' }"
        ></div>
      </div>
    </div>

    <!-- Right Column: Content -->
    <div 
      class="flex-1 flex flex-col gap-5 transition-all duration-300 p-4 sm:p-5 rounded-2xl border cursor-pointer"
      :class="[
        props.activeStep === 2 
          ? 'bg-primary/5 border-primary/10 opacity-100 scale-[1.005]' 
          : 'bg-transparent border-transparent opacity-60 hover:opacity-85'
      ]"
      @click="emit('update-active-step', 2)"
    >
      <h3 class="text-sm font-bold text-text h-8 flex items-center uppercase tracking-widest">
        <span class="sm:hidden mr-1">2. </span>Importo
      </h3>
      <!-- 3. Importo -->
      <div class="flex flex-col gap-2">
        
        <div class="flex items-center gap-4 px-4 py-3 sm:px-5 sm:py-4.5 border border-gray-200 rounded-xl bg-gray-50/50 focus-within:bg-white focus-within:ring-2 focus-within:ring-primary-light focus-within:border-primary-light transition-all mt-1">
          <span class="text-base sm:text-lg font-bold text-gray-400 select-none tracking-wider">{{ props.currency }}</span>
          <input
            ref="amountInput"
            type="text"
            :value="props.displayValue"
            @input="emit('amount-input', $event)"
            @focus="emit('amount-focus')"
            @blur="emit('amount-blur')"
            @keyup.enter="emit('amount-enter')"
            inputmode="decimal"
            placeholder="0.00"
            autocomplete="off"
            data-1p-ignore="true"
            data-lpignore="true"
            :class="[
              'w-full text-lg sm:text-xl font-bold bg-transparent border-none outline-none focus:ring-0 focus:outline-none p-0 text-text transition-all tracking-wider',
              { 'text-red-600': props.form.amount > 10000000 || props.showZeroError },
              { 'animate-shake': props.shakeAmount }
            ]"
          />
        </div>
        
        <div class="flex flex-col mt-1 border-t border-gray-50 pt-2 gap-1">
          <InputError :message="props.showNumericError ? 'Sono consentiti solo numeri e un separatore decimale' : ''" type="warning" />
          <InputError :message="props.showDecimalError ? 'Massimo 4 cifre decimali consentite' : ''" type="warning" />
          <InputError :message="props.showZeroError ? 'L\'importo deve essere maggiore di zero' : ''" />
          <InputError :message="props.showLimitError ? 'Limite massimo di 10M superato!' : ''" />
          <span class="text-[11px] text-gray-400 font-normal">Max: 10.000.000 {{ props.currency }}</span>
        </div>
      </div>
    </div>

  </div>
</template>
