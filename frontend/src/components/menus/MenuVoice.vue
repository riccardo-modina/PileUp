<script setup>
import { computed } from 'vue'
import { useRoute, RouterLink } from 'vue-router' 
import BaseButton from '../buttons/BaseButton.vue'
import { useDeviceDetection } from '@/composables/useScreenDetection';

const props = defineProps({
  menuVoice: String,
  route: String,
  icon: String, // PrimeIcon class name (e.g., 'pi-home')
  iconSolid: String,
  voices: {
    type: Array,
    default: () => []
  }
})

const { isDesktop } = useDeviceDetection();


const route = useRoute()

const isActive = computed(() => {
  if (props.voices.length > 0) {
    return props.voices.some(v => route.path.startsWith(v.route))
  }
  if (props.route === "/") {
    return route.path === "/";
  }
  return route.path && route.path.startsWith(props.route);
});

</script>

<template>
  <BaseButton
    v-if="isDesktop"
    :as="voices.length > 0 ? 'div' : (props.route ? RouterLink : 'button')"
    :to="(voices.length === 0 && props.route) ? props.route : null"
    class="flex flex-col items-center justify-center md:gap-2
            md:w-full md:px-3 py-2 rounded transition duration-200 ease-in-out cursor-pointer relative group"
  >
    <div class="flex relative">
      <i 
        :class="[
          'pi hidden md:block text-xl transform transition-colors duration-200',
          isActive ? (props.iconSolid || props.icon) : props.icon,
          isActive ? 'text-primary-light' : 'text-gray-600',
          'group-hover:text-primary-light'
        ]"
      ></i>
      <i 
        v-if="voices.length > 0" 
        class="pi pi-chevron-right block absolute -right-6 top-1 text-[10px] text-gray-400 group-hover:text-primary transition-transform" 
      ></i>
    </div>
    <div :class="[isActive ? 'text-[10px] md:text-xs text-text font-semibold' : 'text-[10px] md:text-xs text-gray-600', 'group-hover:text-text group-hover:font-semibold transition-all uppercase tracking-wider']">
      {{ props.menuVoice }}
    </div>
  </BaseButton>


  <!-- mobile -->
  <BaseButton
    v-else
    :as="voices.length > 0 ? 'div' : (props.route ? RouterLink : 'button')"
    :to="(voices.length === 0 && props.route) ? props.route : null"
    class=" flex flex-col items-center justify-center cursor-pointer relative"
  >
    <div class="flex relative mb-0.5">
      <i 
        :class="['pi text-xl', 
          isActive ? (props.iconSolid || props.icon) : props.icon,
          isActive ? 'text-primary-light' : 'text-gray-600'
        ]"
      ></i>
    </div>
    <div :class="['text-[8px] text-center whitespace-nowrap uppercase tracking-wide', 
      isActive ? 'text-text font-semibold' : 'text-gray-600'
    ]">
      {{ props.menuVoice }}
    </div>
  </BaseButton>
</template>