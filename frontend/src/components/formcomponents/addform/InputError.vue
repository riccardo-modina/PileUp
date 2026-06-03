<script setup>
import { computed } from 'vue'

const props = defineProps({
  message: {
    type: String,
    default: ''
  },
  type: {
    type: String,
    default: 'error', // 'error', 'warning', 'info'
    validator: (value) => ['error', 'warning', 'info'].includes(value)
  },
  animate: {
    type: Boolean,
    default: false
  }
})

const typeClasses = computed(() => {
  switch (props.type) {
    case 'warning':
      return 'text-amber-600'
    case 'info':
      return 'text-blue-600'
    case 'error':
    default:
      return 'text-red-600'
  }
})
</script>

<template>
  <transition name="fade-slide">
    <div v-if="message" :class="['text-[11px] font-bold mt-1 flex items-center gap-1', typeClasses, { 'animate-pulse': animate }]">
      <!-- Error Icon -->
      <svg v-if="type === 'error'" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
      </svg>
      
      <!-- Warning Icon -->
      <svg v-else-if="type === 'warning'" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
      </svg>

      <!-- Info Icon -->
      <svg v-else-if="type === 'info'" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
      </svg>

      <span>{{ message }}</span>
    </div>
  </transition>
</template>

<style scoped>
.fade-slide-enter-active, .fade-slide-leave-active {
  transition: all 0.2s ease-out;
}
.fade-slide-enter-from, .fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-5px);
}
</style>
