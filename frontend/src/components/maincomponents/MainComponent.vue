<script setup>

import Menu from '../../components/menus/Menu.vue';
import TopSection from './TopSection.vue';
import { useSettingsStore } from '../../stores/settings';
import { ref } from 'vue';

// Disable attribute inheritance to prevent events/attributes
// from being applied to the root div of MainComponent
defineOptions({
    inheritAttrs: false
})

defineProps({
    mainComponent: Object,
    // prop for the component object that replaces mainComponent
    mainProps:{
        type: Object,
        default: () => ({})
    },
    //top section props
    showTopSection: {
        type: Boolean,
        default: false
    },
    topSectionTitle: {
        type: String,
        default: ""
    },
    showTimeButton: {
        type: Boolean,
        default: false
    },
    showAddButton: {
        type: Boolean,
        default: false
    },
    listen: {
        type: Object,
        default: () => ({})
    },

})

const settings = useSettingsStore();

const isTimeFrameButtonActive = ref(false)

function timeFrameButtonToggled(isOpen) {
    isTimeFrameButtonActive.value = isOpen 
}

function close() {
    isTimeFrameButtonActive.value = false
}

</script>

<template>
  <div class="flex h-screen text-text relative overflow-hidden">
      
      <!-- Background Color Layer -->
      <div class="absolute inset-0 bg-background z-[-20]"></div>

      <!-- Global Background Elements (Root Level) -->
      <div class="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none z-[-10] bg-gradient-to-br from-indigo-50 via-slate-50 to-blue-50">
      </div>

      <div class="flex z-50 md:backdrop-blur-2xl md:bg-white/60 md:shadow-[6px_0_24px_rgba(0,0,0,0.04)] md:border-r md:border-white/60 md:rounded-r-3xl">
        <Menu />
      </div>

      <div 
        :class="['flex-1 flex flex-col',
                settings.defaultMenuOpen ? 'ml-0' : 'ml-0 md:ml-8']"
      >
          
        <div class="flex-1 flex flex-col w-full overflow-hidden">
            
          <section 
            v-if="showTopSection" 
            class="sticky top-0 z-40 backdrop-blur-sm"
          >
            <TopSection
              :title="topSectionTitle"
              :show-time-frame-button="showTimeButton"
              :show-add-button="showAddButton"
              @timeFrameButtonToggled="(isOpen) => timeFrameButtonToggled(isOpen)"
              class="px-8 py-6"
            />
          </section>

              <!-- opacity when selecting time frame-->
            <transition name="fade">
                  <div
                    v-if="isTimeFrameButtonActive"
                    @click="close"
                    class="fixed inset-0 bg-black/40 z-30"
                  ></div>
            </transition>
            
          <section 
            class="flex-1 px-4 md:px-8 lg:px-12 xl:px-16 2xl:px-24 pb-10 md:mb-0 overflow-y-auto custom-scrollbar z-20"
          >
            <div class="w-full md:h-full max-w-8xl mx-auto pb-15 md:pb-0">
              <component 
                :is="mainComponent"
                v-bind="{ ...mainProps, ...$attrs }" 
                v-on="listen"
              />
            </div>

          </section>
          
        </div>
         
        <!-- Footer removed from here and moved to the Menu sidebar -->
      </div>
</div>
</template>


<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.25s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0.5;
}
</style>
