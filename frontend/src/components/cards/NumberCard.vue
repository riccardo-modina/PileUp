<script setup>
import { computed } from 'vue'

const props = defineProps({
  title: {
    type: String,
    required: true
  },
  value: {
    type: [String, Number],
    required: true
  },
  icon: String,
  color: {
    type: String,
    default: "bg-white"
  },
  iconColor: {
    type: String,
    default: "text-indigo-600"
  },
  iconBackground: {
    type: String,
    default: "bg-indigo-50"
  },
  iconContainerClass: {
    type: String,
    default: ""
  },
  sign: String,
})

//computed is faster than the template
const formattedCurrency = computed(() => {
  if (typeof props.value === 'number') {
    const formatter = new Intl.NumberFormat("it-IT", { 
      style: "currency", 
      currency: "EUR",
      maximumFractionDigits: 2 
    });

    // formatToParts returns an array of parts
    const parts = formatter.formatToParts(props.value);
    
    // Extract the symbol (e.g., "€")
    const symbol = parts.find(part => part.type === 'currency')?.value;
    
    // Reconstruct the number excluding the symbol and extra spaces
    const number = parts
      .filter(part => part.type !== 'currency' && part.type !== 'literal' && part.type !== 'minusSign')
      .map(part => part.value)
      .join('');

    return { number, symbol };
  }
  
  // Fallback if not a number
  return { number: props.value, symbol: '' };
})
</script>

<template>
  <div 
    :class="[
      color, 
      'group relative flex flex-col justify-between p-6 rounded-2xl shadow-sm border border-gray-100 transition-all duration-300 overflow-hidden min-h-[140px]'
    ]"
  >
    <!-- Header: Title and Action/Icon -->
    <div class="flex justify-between items-start z-10">
      <h3 class="text-xs font-bold text-gray-500 uppercase tracking-widest">
        {{ title }}
      </h3>
      
      <div v-if="$slots.action" class="z-20 -mt-1 -mr-1">
        <slot name="action"></slot>
      </div>
      <div 
        v-else-if="icon"
        :class="[
          'flex items-center justify-center w-11 h-11 rounded-xl shadow-inner transition-colors', 
          iconBackground, 
          iconColor,
          iconContainerClass
        ]"
      >
        <i :class="['pi', icon, 'text-lg']" />
      </div>
    </div>

    <!-- Body: Value -->
    <div class="mt-auto flex items-center gap-1 z-10">
      <span v-if="sign" class="text-xl font-medium text-gray-400">{{ sign }}</span>
      <div class="flex items-baseline gap-1"> 
        <span class="text-3xl 2xl:text-4xl font-bold text-gray-900 tracking-tight">
          {{ formattedCurrency.number }}
        </span>

        <span class="text-xl font-medium text-gray-400">
          {{ formattedCurrency.symbol }}
        </span>
      </div>
    </div>

    <!-- Optional Footer -->
    <div v-if="$slots.footer" class="mt-4 pt-2 border-t border-menuborder/10 z-10">
      <slot name="footer"></slot>
    </div>
  </div>
</template>