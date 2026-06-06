<script setup>
import { computed } from 'vue';
import ChartCard from './ChartCard.vue';
import { useSettingsStore } from '../../../stores/settings';

const settings = useSettingsStore();

const props = defineProps({
  // riceve oggetti { component: Component, props: Object } dal genitore
  leftChart: { type: Object, required: false },
  rightChart: { type: Object, required: false },
  charts: { type: Array, default: null },
  height: { type: String, default: 'h-80' }
})

const chartsList = computed(() => {
  if (props.charts) return props.charts;
  const list = [];
  if (props.leftChart) list.push(props.leftChart);
  if (props.rightChart) list.push(props.rightChart);
  return list;
});

const gridClass = computed(() => {
  if (settings.chartsLayout === 'stack') {
    return 'flex flex-col h-auto';
  }
  const count = chartsList.value.length;
  if (count === 3) {
    return ['grid grid-cols-1 lg:grid-cols-3', props.height];
  } else if (count === 2) {
    return ['grid grid-cols-1 lg:grid-cols-2', props.height];
  } else {
    return ['grid grid-cols-1', props.height];
  }
});
</script>

<template>
    <div :class="['gap-4 w-full', gridClass]">
        <div 
          v-for="(chartObj, index) in chartsList"
          :key="index"
          :class="[
            'w-full',
            settings.chartsLayout === 'stack' ? 'h-[400px] lg:h-[450px]' : 'h-full min-h-80'
          ]"
        >
            <ChartCard
                :chart="chartObj.component"
                :chartProps="chartObj.props || {}"
                :chartEvents="chartObj.on || {}"
            />
        </div>   
    </div>
</template>