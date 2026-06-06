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
  flat: {
    type: Boolean,
    default: false
  },
  valueSizeClass: {
    type: String,
    default: "text-3xl 2xl:text-4xl"
  },
  centered: {
    type: Boolean,
    default: false
  }
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
      props.flat ? '' : 'shadow-sm border border-gray-100',
      props.centered ? 'items-center justify-center text-center' : 'justify-between',
      'group relative flex flex-col p-4 sm:p-5 rounded-2xl transition-all duration-300 overflow-hidden min-h-[110px] sm:min-h-[120px]'
    ]"
  >
    <!-- Header: Title and Action/Icon -->
    <div :class="[props.centered ? 'flex flex-col items-center gap-2 w-full' : 'flex justify-between items-start w-full', 'z-10']">
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
    <div :class="[props.centered ? 'justify-center w-full mt-2 sm:mt-3' : 'mt-auto', 'flex items-center gap-1 z-10']">
      <span v-if="sign" class="text-xl font-medium text-gray-400">{{ sign }}</span>
      <div class="flex items-baseline gap-1"> 
        <span :class="[valueSizeClass, 'font-bold text-gray-900 tracking-tight']">
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