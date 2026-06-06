<script setup>
import SelectDropdown from '@/components/formcomponents/addform/SelectDropdown.vue'
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
  isCard1Valid: {
    type: Boolean,
    required: true
  },
  validationError: {
    type: String,
    required: true
  },
  movementTypes: {
    type: Array,
    required: true
  },
  filteredCategories: {
    type: Array,
    required: true
  },
  categorie: {
    type: Array,
    required: true
  }
})

const emit = defineEmits([
  'update-active-step',
  'set-movement-type',
  'category-select',
  'category-clear',
  'new-category-created',
  'set-validation-error',
  'complete-step1'
])

function handleMovementTypeSelect(typeId) {
  emit('set-movement-type', typeId)
  emit('complete-step1')
}

function handleCategorySelect(cat) {
  emit('category-select', cat)
  emit('complete-step1')
}
</script>

<template>
  <div 
    class="flex gap-3 sm:gap-6 relative transition-all duration-300"
    :class="[props.activeStep === 1 ? 'z-30' : 'z-10']"
  >
    
    <!-- Left Column: Badge and Timeline Line -->
    <div class="hidden sm:flex flex-col items-center relative w-6 sm:w-8 flex-shrink-0 z-10">
      <!-- Badge -->
      <div 
        class="w-6 h-6 sm:w-8 sm:h-8 rounded-full flex items-center justify-center text-xs sm:text-sm font-bold transition-all duration-300 border-2 z-20"
        :class="[
          props.isCard1Valid 
            ? 'bg-green-500 text-white border-green-500 shadow-sm' 
            : props.activeStep === 1 
              ? 'bg-primary text-white border-primary shadow-md' 
              : 'bg-white text-gray-400 border-gray-200'
        ]"
      >
        <i v-if="props.isCard1Valid" class="pi pi-check text-xs" />
        <span v-else>1</span>
      </div>
      <!-- Line Segment 1 (Connecting to Step 2) -->
      <div class="w-0.5 bg-gray-100 absolute left-1/2 -translate-x-1/2 top-6 sm:top-8 bottom-[-40px] z-0">
        <div 
          class="w-full bg-primary transition-all duration-500 rounded-full" 
          :style="{ height: props.isCard1Valid ? '100%' : '0%' }"
        ></div>
      </div>
    </div>

    <!-- Right Column: Content -->
    <div 
      class="flex-1 flex flex-col gap-5 transition-all duration-300 p-4 sm:p-5 rounded-2xl border cursor-pointer"
      :class="[
        props.activeStep === 1 
          ? 'bg-primary/5 border-primary/10 opacity-100 scale-[1.005]' 
          : 'bg-transparent border-transparent opacity-60 hover:opacity-85'
      ]"
      @click="emit('update-active-step', 1)"
    >
      <h3 class="text-sm font-bold text-text h-8 flex items-center uppercase tracking-widest">
        <span class="sm:hidden mr-1">1. </span>Tipo movimento
      </h3>
      
      <!-- 1. Tipo Movimento -->
      <div class="flex flex-col gap-3">
        
        <!-- Mobile: Buttons -->
        <div class="flex gap-1.5 md:hidden mt-1">
          <button 
            v-for="type in props.movementTypes"
            :key="type.id"
            type="button" 
            @click.stop="handleMovementTypeSelect(type.id)"
            :class="[
              'flex-1 py-2 px-1 rounded-xl border transition-all text-xs sm:text-sm font-semibold cursor-pointer flex items-center justify-center gap-1',
              props.form.movementType === type.id 
                ? type.id === 'entrata'
                  ? 'bg-green-50 text-green-700 border-green-200 shadow-sm scale-[1.02]'
                  : type.id === 'uscita'
                    ? 'bg-red-50 text-red-700 border-red-200 shadow-sm scale-[1.02]'
                    : 'bg-indigo-50 text-indigo-700 border-indigo-200 shadow-sm scale-[1.02]'
                : 'bg-white text-gray-500 border-gray-100 hover:bg-gray-50'
            ]"
          >
            <i :class="[
              'pi text-[10px] sm:text-xs',
              type.id === 'entrata' ? 'pi-arrow-down-left' : type.id === 'uscita' ? 'pi-arrow-up-right' : 'pi-sync'
            ]" />
            {{ type.label }}
          </button>
        </div>

        <!-- Desktop: Dropdown -->
        <div class="hidden md:block" @focusin="emit('update-active-step', 1)">
          <SelectDropdown
            :items="props.movementTypes"
            v-model="props.form.movementType"
            itemLabel="label"
            placeholder="Seleziona tipo movimento"
            :searchEnabled="false"
            :clearable="false"
            :showColor="true"
            @select="(val) => handleMovementTypeSelect(val.id)"
          />
        </div>
      </div>

      <!-- Divisore -->
      <div class="h-px bg-gray-100 w-full"></div>

      <!-- 2. Categoria -->
      <div class="flex flex-col gap-3">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
            <i class="pi pi-tag text-sm sm:text-lg" />
          </div>
          <span class="text-xs font-bold text-text uppercase tracking-wider">Categoria</span>
        </div>
        <div class="relative group mt-1" @focusin="emit('update-active-step', 1)">
          <SelectDropdown
            :items="props.filteredCategories"
            v-model="props.form.category"
            itemLabel="nome"
            :showColor="true"
            :placeholder="!props.form.movementType ? 'Scegli prima il tipo di movimento' : 'Seleziona categoria'"
            @select="handleCategorySelect"
            @clear="emit('category-clear')"
            :required="true"
            :allowCreateCategory="true"
            :initialType="props.form.movementType"
            :disabled="!props.form.movementType"
            @item-created="(c) => emit('new-category-created', c)"
          />
          <div v-if="!props.form.movementType" class="absolute inset-0 z-10 cursor-not-allowed" @click.stop="emit('set-validation-error', 'Seleziona prima il tipo di movimento')"></div>
        </div>
        <InputError 
          :message="props.validationError === 'Seleziona prima il tipo di movimento' ? 'Per favore, seleziona prima se è una Spesa, un\'Entrata o un Giroconto' : ''" 
          :animate="true"
        />
        <InputError :message="props.validationError === 'Seleziona una categoria' ? 'Seleziona una categoria' : ''" />
      </div>
    </div>
  </div>
</template>
