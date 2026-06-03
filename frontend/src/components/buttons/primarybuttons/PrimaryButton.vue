<script setup>
import BaseButton from '@/components/buttons/BaseButton.vue';
import { ref } from 'vue';

const baseBtnRef = ref(null);
defineExpose({
  focus: () => baseBtnRef.value?.focus()
});
</script>

<template>
  <BaseButton
    ref="baseBtnRef"
    class="bg-primary
           md:hover:bg-primary-hover text-white transition-all
           rounded-md group py-[6px] px-3 items-center justify-center"
  >
    <slot />
  </BaseButton>
</template>
