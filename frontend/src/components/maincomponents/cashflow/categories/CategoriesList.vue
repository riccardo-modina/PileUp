<script setup>
const props = defineProps(['categoriesByType', 'typeLabels']);
const emit = defineEmits(['edit', 'delete', 'create']);
</script>

<template>
  <div class="flex flex-col gap-8 p-4">
    <div v-for="(cats, type) in categoriesByType" :key="type" class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div class="bg-gray-50 px-6 py-3 border-b border-gray-100 flex justify-between items-center">
        <h3 class="text-sm font-bold uppercase tracking-wider text-gray-500">{{ typeLabels[type] }}</h3>
        <span class="text-xs font-medium px-2 py-1 bg-gray-200 text-gray-600 rounded-full">{{ cats.length }}</span>
      </div>
      <div class="divide-y divide-gray-50">
        <div v-if="cats.length === 0" class="px-6 py-8 text-center text-gray-400 italic">
          Nessuna categoria definita per questo tipo.
        </div>
        <div v-for="cat in cats" :key="cat.id" class="px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors group">
          <div class="flex items-center gap-4">
            <div :style="{ backgroundColor: cat.color }" class="w-4 h-4 rounded-full shadow-sm"></div>
            <div>
              <span class="font-medium text-gray-700">{{ cat.nome }}</span>
              <span v-if="cat.is_system" class="ml-2 text-[10px] uppercase font-bold text-gray-400 bg-gray-100 px-1.5 py-0.5 rounded">Sistema</span>
            </div>
          </div>
          <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
            <button 
              v-if="!cat.is_system"
              @click="$emit('edit', cat)" 
              class="p-2 text-gray-400 hover:text-primary hover:bg-primary/10 rounded-lg transition-colors"
              title="Modifica"
            >
              <i class="pi pi-pencil" />
            </button>
            <button 
              v-if="!cat.is_system"
              @click="$emit('delete', cat)" 
              class="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors"
              title="Elimina"
            >
              <i class="pi pi-trash" />
            </button>
          </div>
        </div>
      </div>
    </div>
    
    <div class="flex justify-center mt-4">
      <button 
          @click="$emit('create')" 
          class="flex items-center gap-2 px-6 py-3 bg-primary text-white rounded-xl shadow-lg hover:bg-primary-dark transition-all transform hover:cursor-pointer hover:scale-105 active:scale-95 font-semibold"
      >
          <i class="pi pi-plus" />
          Nuova Categoria
      </button>
    </div>
  </div>
</template>
