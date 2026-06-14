<script setup>
import { ref } from 'vue'
import DateSelector from '@/components/formcomponents/dateselector/DateSelector.vue'
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
  isCard3Valid: {
    type: Boolean,
    required: true
  },
  validationError: {
    type: String,
    required: true
  },
  titlePlaceholder: {
    type: String,
    required: true
  },
  shakeTitle: {
    type: Boolean,
    required: true
  },
  shakeDescription: {
    type: Boolean,
    required: true
  },
  showFutureWarning: {
    type: Boolean,
    required: true
  },
  conti: {
    type: Array,
    required: true
  }
})

const emit = defineEmits([
  'update-active-step',
  'account-select',
  'account-clear',
  'new-account-created',
  'trigger-shake',
  'complete-step3'
])

const titleInput = ref(null)
const notesInput = ref(null)

function focusTitle() {
  titleInput.value?.focus()
}

function focusNotes() {
  notesInput.value?.focus()
}

defineExpose({
  focusTitle,
  focusNotes
})
</script>

<template>
  <div 
    class="flex gap-3 sm:gap-6 relative transition-all duration-300"
    :class="[props.activeStep === 3 ? 'z-30' : 'z-10']"
  >
    
    <!-- Left Column: Badge and Timeline Line (No line since it's the last step) -->
    <div class="hidden sm:flex flex-col items-center relative w-6 sm:w-8 flex-shrink-0 z-10">
      <!-- Badge -->
      <div 
        class="w-6 h-6 sm:w-8 sm:h-8 rounded-full flex items-center justify-center text-xs sm:text-sm font-bold transition-all duration-300 border-2 z-20"
        :class="[
          props.isCard3Valid 
            ? 'bg-green-500 text-white border-green-500 shadow-sm' 
            : props.activeStep === 3 
              ? 'bg-primary text-white border-primary shadow-md' 
              : 'bg-white text-gray-400 border-gray-200'
        ]"
      >
        <i v-if="props.isCard3Valid" class="pi pi-check text-xs" />
        <span v-else>3</span>
      </div>

    </div>

    <!-- Right Column: Content -->
    <div 
      class="flex-1 flex flex-col gap-5 transition-all duration-300 p-4 sm:p-5 rounded-2xl border cursor-pointer"
      :class="[
        props.activeStep === 3 
          ? 'bg-primary/5 border-primary/10 opacity-100 scale-[1.005]' 
          : 'bg-transparent border-transparent opacity-60 hover:opacity-85'
      ]"
      @click="emit('update-active-step', 3)"
    >
      <h3 class="text-sm font-bold text-text h-8 flex items-center uppercase tracking-widest">
        <span class="sm:hidden mr-1">3. </span>Dettagli movimento
      </h3>
      
      <!-- 4. Descrizione (Titolo) -->
      <div class="flex flex-col gap-3">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
              <i class="pi pi-pencil text-sm sm:text-lg" />
            </div>
            <div class="flex flex-col">
              <span class="text-xs font-bold text-text uppercase tracking-wider">Descrizione</span>
              <span class="text-[11px] text-gray-400 font-normal">Se vuoto, rimarrà il nome della categoria</span>
            </div>
          </div>
          <span :class="['text-[10px] font-normal transition-colors flex-shrink-0', props.form.title.length >= 50 ? 'text-red-500 font-bold' : 'text-gray-400']">
            {{ props.form.title.length }}/50
          </span>
        </div>
        <div class="mt-1 relative" @click.stop>
          <input
              ref="titleInput"
              v-model="props.form.title"
              maxlength="50"
              type="text"
              @focus="emit('update-active-step', 3)"
              @keydown="(e) => { if (props.form.title.length >= 50 && e.key.length === 1) emit('trigger-shake', 'title') }"
              :placeholder="props.titlePlaceholder"
              :class="[
                'w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-light transition-all text-base sm:text-sm bg-gray-50/50 hover:bg-gray-50 focus:bg-white',
                { 'animate-shake border-red-400': props.shakeTitle }
              ]"
          />
          <span v-if="props.form.title.length >= 50" class="text-[10px] text-red-500 mt-1 block">Limite raggiunto!</span>
        </div>
      </div>

      <!-- Divisore -->
      <div class="h-px bg-gray-100 w-full"></div>

      <!-- 5. Data -->
      <div class="flex flex-col gap-3" @click.stop>
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
            <i class="pi pi-calendar text-sm sm:text-lg" />
          </div>
          <div class="flex flex-col">
            <span class="text-xs font-bold text-text uppercase tracking-wider">Data</span>
            <span class="text-xs text-gray-400 font-normal">Seleziona giorno, mese e anno</span>
          </div>
        </div>

        <DateSelector
          v-model="props.form.date"
          @focus="emit('update-active-step', 3)"
        />
        
        <InputError 
          :message="props.showFutureWarning ? 'Non è possibile selezionare una data futura — impostata la data di oggi.' : ''"
          type="error"
          :animate="true"
        />
      </div>

      <!-- Divisore -->
      <div class="h-px bg-gray-100 w-full"></div>

      <!-- 6. Conto -->
      <div class="flex flex-col gap-3" @click.stop>
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
            <i class="pi pi-credit-card text-sm sm:text-lg" />
          </div>
          <span class="text-xs font-bold text-text uppercase tracking-wider">Conto</span>
        </div>
        <div class="mt-1" @focusin="emit('update-active-step', 3)">
          <SelectDropdown
            :items="props.conti"
            v-model="props.form.account"
            itemLabel="nome"
            placeholder="Seleziona conto"
            :showColor="true"
            @select="(acc) => { emit('account-select', acc); emit('complete-step3'); }"
            @clear="emit('account-clear')"
            :required="true"
            :allowCreateAccount="true"
            @item-created="(a) => emit('new-account-created', a)"
          />
        </div>
        <InputError :message="props.validationError === 'Seleziona un conto' ? 'Seleziona un conto' : ''" />
      </div>

      <!-- Divisore -->
      <div class="h-px bg-gray-100 w-full"></div>

      <!-- 7. Note -->
      <div class="flex flex-col gap-3">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                <i class="pi pi-file text-sm sm:text-lg" />
              </div>
            <div class="flex items-baseline gap-1.5">
              <span class="text-xs font-bold text-text uppercase tracking-wider">Note</span>
              <span class="text-xs text-gray-400 font-normal">(opzionale)</span>
            </div>
          </div>
          <span :class="['text-[10px] font-normal transition-colors flex-shrink-0', props.form.description.length >= 200 ? 'text-red-500 font-bold' : 'text-gray-400']">
            {{ props.form.description.length }}/200
          </span>
        </div>
        <div class="mt-1 relative" @click.stop>
          <textarea
              ref="notesInput"
              v-model="props.form.description"
              maxlength="200"
              rows="3"
              @focus="emit('update-active-step', 3)"
              @keydown="(e) => { if (props.form.description.length >= 200 && e.key.length === 1) emit('trigger-shake', 'description') }"
              placeholder="Aggiungi note (opzionale)..."
              :class="[
                  'w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-light transition-all text-base sm:text-sm bg-gray-50/50 hover:bg-gray-50 focus:bg-white',
                  { 'animate-shake border-red-400': props.shakeDescription }
              ]"
          ></textarea>
          <span v-if="props.form.description.length >= 200" class="text-[10px] text-red-500 mt-1 block">Limite raggiunto!</span>
        </div>
      </div>
    </div>

  </div>
</template>
