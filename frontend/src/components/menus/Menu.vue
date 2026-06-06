<script setup>
import { ref, watch, onUnmounted, onMounted } from 'vue'

import MenuVoice from './MenuVoice.vue'
import { useSettingsStore } from '../../stores/settings'
import { useAuth } from '../../composables/useAuth'

const sidebarRef = ref(null)
const menuButtonRef = ref(null)

const { logout } = useAuth()

const handleLogout = () => {
  logout()
}

const menuOptions = ref([
  { name: 'Dashboard', route: '/', icon: 'pi-home', iconSolid: 'pi-home' },
  { 
    name: 'CashFlow', 
    route: '/cashflow', 
    icon: 'pi-chart-bar', 
    iconSolid: 'pi-chart-bar',
    voices: [
      { name: 'Confronto', route: '/notfound', icon: 'pi-chart-scatter', iconSolid: 'pi-chart-line' },
      { name: 'Conti', route: '/notfound', icon: 'pi-building-columns', iconSolid: 'pi-credit-card' },
      { name: 'Categorie', route: '/cashflow/categories', icon: 'pi-tags', iconSolid: 'pi-tags' },
    ]
  },
  { name: 'Investimenti', route: '/notfound', icon: 'pi-chart-line', iconSolid: 'pi-chart-bar' },
  { name: 'Budget', route: '/notfound', icon: 'pi-wallet', iconSolid: 'pi-chart-line' }
])

const settings = useSettingsStore();
const defaultMenuOpen = settings.defaultMenuOpen;
const isHoverHomeIcon = ref(false)
const isHoverCloseMenuOnMobileIcon = ref(false)
const isOpen = ref(false) // Mobile sidebar

// --- SIDEBAR SUBMENU LOGIC ---
const activeSubMenu = ref(null) 
const isSubMenuVisible = ref(false)

// --- BOTTOM SHEET SUBMENU LOGIC (MOBILE) ---
const isMobileBottomSheetOpen = ref(false)
const activeMobileBottomMenu = ref(null)

// Sidebar click handling (Desktop and Mobile Hamburger)
const handleSidebarVoiceClick = (item) => {
  if (item.voices && item.voices.length > 0) {
    activeSubMenu.value = item
    isSubMenuVisible.value = true
  } else {
    closeSubMenu()
    if (!defaultMenuOpen) isOpen.value = false 
  }
}

// BOTTOM NAV click handling (Mobile fixed at bottom)
const handleBottomNavClick = (item) => {
  if (item.voices && item.voices.length > 0) {
    // If the same menu is already open, close it, otherwise open it
    if (isMobileBottomSheetOpen.value && activeMobileBottomMenu.value?.name === item.name) {
      closeBottomSheet()
    } else {
      activeMobileBottomMenu.value = item
      isMobileBottomSheetOpen.value = true
    }
  } else {
    // Normal navigation
    closeBottomSheet()
  }
}

const closeSubMenu = () => {
  isSubMenuVisible.value = false
  setTimeout(() => {
    activeSubMenu.value = null
  }, 300) 
}

const closeBottomSheet = () => {
  isMobileBottomSheetOpen.value = false
  setTimeout(() => {
    activeMobileBottomMenu.value = null
  }, 300)
}


const toggleMenu = () => {
  isOpen.value = !isOpen.value
  // If I open the sidebar, I close the bottom sheet to avoid confusion
  if(isOpen.value) closeBottomSheet()
}

watch(isOpen, (val) => {
  if (val) document.body.classList.add('overflow-hidden')
  else document.body.classList.remove('overflow-hidden')
})

onUnmounted(() => {
  document.body.classList.remove('overflow-hidden')
  window.removeEventListener('click', handleClickOutside)
})

const handleClickOutside = (event) => {
  if (isOpen.value && !settings.defaultMenuOpen) {
    // If sidebarRef doesn't exist or the click is outside the sidebar
    const isOutsideSidebar = !sidebarRef.value || !sidebarRef.value.contains(event.target)
    // If menuButtonRef doesn't exist or the click is outside the button (to avoid conflicts with toggleMenu)
    const isOutsideButton = !menuButtonRef.value || !menuButtonRef.value.contains(event.target)
    
    if (isOutsideSidebar && isOutsideButton) {
      isOpen.value = false
      closeSubMenu()
    }
  }
}

onMounted(() => {
  window.addEventListener('click', handleClickOutside)
})
</script>

<template>
  <div class="flex">
    
    <aside 
      v-if="defaultMenuOpen" 
      class="hidden md:flex md:flex-col md:w-30 flex-1 text-gray-800 text-center items-center overflow-hidden relative h-full"
    >
      <nav class="flex-1 w-full relative h-full mt-10">
        
        <div 
          class="absolute inset-0 flex-1 flex-col w-full transition-transform duration-300 ease-in-out h-full"
          :class="isSubMenuVisible ? '-translate-x-full opacity-0' : 'translate-x-0 opacity-100'"
        >
          <ul class="flex flex-col space-y-6 w-full px-2 h-full">
            <RouterLink to="/" class="group">
              <li
                @mouseenter="isHoverHomeIcon = true"
                @mouseleave="isHoverHomeIcon = false" 
                class="flex justify-center hover:cursor-pointer mb-10"
                @click="closeSubMenu"
              >
                  <i 
                    :class="[
                      'pi pi-home hidden md:block text-4xl transform transition-colors !duration-100',
                      isHoverHomeIcon ? 'text-primary' : 'text-gray-500'
                    ]"
                  ></i>
              </li>
            </RouterLink>
            
            <li v-for="item in menuOptions" :key="item.name">
              <MenuVoice
                :menuVoice="item.name"
                :route="item.route"
                :icon="item.icon"
                :iconSolid="item.iconSolid"
                :voices="item.voices"
                @click="() => handleSidebarVoiceClick(item)"
              />
            </li>
            <div class="flex-1 flex flex-col justify-end mb-4 space-y-2">
              <MenuVoice
                menuVoice="Settings"
                route="/settings"
                icon="pi-cog"
                iconSolid="pi-cog"
                @click="closeSubMenu"
              />
              <MenuVoice
                menuVoice="Logout"
                icon="pi-sign-out"
                iconSolid="pi-sign-out"
                @click="handleLogout"
              />
            </div>
          </ul>

        </div>

        <!-- sub menu -->
        <div 
          class="absolute inset-0 flex flex-col w-full transition-transform duration-300 ease-in-out pt-10"
          :class="isSubMenuVisible ? 'translate-x-0 opacity-100' : 'translate-x-full opacity-0'"
        >
            <div class="mb-6 px-4">
              <button 
                @click="closeSubMenu"
                class="flex flex-col items-center justify-center w-full text-gray-500 hover:text-primary transition-colors gap-1"
              >
                <i class="pi pi-chevron-left text-2xl" />
                <span class="text-xs font-bold uppercase tracking-wider">Indietro</span>
              </button>
            </div>

            <h3 class="text-sm font-bold text-gray-400 mb-4 uppercase tracking-widest">{{ activeSubMenu?.name }}</h3>

            <ul class="space-y-4 px-2">
              <li v-for="subItem in activeSubMenu?.voices" :key="subItem.name">
                <MenuVoice
                  :menuVoice="subItem.name"
                  :route="subItem.route"
                  :icon="subItem.icon"
                  :iconSolid="subItem.iconSolid"
                  @click="() => handleSidebarVoiceClick(subItem)"
                />
              </li>
            </ul>
        </div>

      </nav>
    </aside>




    <!-- button to slide the menu out -->
    <button 
      v-if="!isOpen"
      ref="menuButtonRef"
      @click.stop="toggleMenu"
      :class="['hidden absolute left-4 z-40 text-text', defaultMenuOpen ? 'md:hidden' : 'md:block' ]"
      style="top: 8px"
    >
      <i class="pi pi-bars text-2xl cursor-pointer transform hover:scale-110 duration-300" />
    </button>

  
    <!-- slide menu when open (default menu open settings false) -->
    <transition name="slide">
      <aside 
        v-if="isOpen" 
        ref="sidebarRef"
        class="fixed inset-y-0 left-0 w-72 md:w-44 text-gray-800 p-4 z-40 flex flex-col overflow-hidden backdrop-blur-2xl bg-white shadow-[6px_0_24px_rgba(0,0,0,0.04)] border-r border-white/60 rounded-r-3xl"
      >
        <button 
          @click="toggleMenu" 
          class="absolute top-4 right-4 text-white cursor-pointer z-50"
          @mouseenter="isHoverCloseMenuOnMobileIcon = true"
          @mouseleave="isHoverCloseMenuOnMobileIcon = false"
        >
           <transition name="fade" mode="out-in">
              <i 
                :class="[
                  'pi pi-send text-xl transform rotate-180 !duration-100',
                  isHoverCloseMenuOnMobileIcon ? 'text-primary' : 'text-gray-600'
                ]"
              ></i>
          </transition>
        </button>

        <nav class="flex-1 w-full relative mt-16">
           <div 
             class="absolute inset-0 w-full transition-transform duration-300"
             :class="isSubMenuVisible ? '-translate-x-full' : 'translate-x-0'"
           >
              <ul class="flex flex-col space-y-6 text-xl md:space-y-2 md:text-base items-center h-full">
                <li v-for="item in menuOptions" :key="item.name" class="w-full">
                   <MenuVoice
                    :menuVoice="item.name"
                    :route="item.route"
                    :icon="item.icon"
                    :iconSolid="item.iconSolid"
                    :voices="item.voices"
                    @click="() => handleSidebarVoiceClick(item)"
                  />
                </li>
                <div class="flex-1 flex flex-col justify-end w-full space-y-2 mb-4">
                    <MenuVoice
                          menuVoice="Settings"
                          route="/settings"
                          icon="pi-cog"
                          iconSolid="pi-cog"
                           @click="closeSubMenu"
                        />
                </div>
              </ul>
           </div>


           <!-- sub menu on false as default menu open settings -->
           <div 
             class="absolute inset-0 w-full transition-transform duration-300"
             :class="isSubMenuVisible ? 'translate-x-0' : 'translate-x-full'"
           >
               <button @click="closeSubMenu" class="flex items-center text-gray-500 mb-6 cursor-pointer">
                  <i class="pi pi-chevron-left mr-1 ml-5 text-sm" /> <span class="uppercase tracking-wider text-[11px] font-bold">Indietro</span>
               </button>
                <h3 class="text-sm font-bold text-gray-800 mb-6 text-center uppercase tracking-widest">{{ activeSubMenu?.name }}</h3>
               
               <ul class="flex flex-col space-y-6 items-center">
                  <li v-for="subItem in activeSubMenu?.voices" :key="subItem.name" class="w-full">
                    <MenuVoice
                      :menuVoice="subItem.name"
                      :route="subItem.route"
                      :icon="subItem.icon"
                      :iconSolid="subItem.iconSolid"
                      @click="() => handleSidebarVoiceClick(subItem)"
                    />
                  </li>
               </ul>
           </div>
        </nav>
      </aside>
    </transition>





    <!-- MOBILE -->


    <!-- profile mobile -->
    <RouterLink 
      to="/settings"
      class="mt-2 mr-1 md:hidden absolute right-4 z-40 text-text"
      style="top: 8px"
      @click="closeBottomSheet"
    >
      <i class="pi pi-cog text-2xl cursor-pointer transform hover:scale-110 duration-300" />
    </RouterLink>

    <transition name="fade">
      <div
        v-if="isOpen || isMobileBottomSheetOpen"
        @click="() => { if(isOpen) { isOpen = false; closeSubMenu(); } if(isMobileBottomSheetOpen) closeBottomSheet(); }"
        :class="['fixed inset-0 z-30', defaultMenuOpen ? 'md:hidden' : '' ]"
        style="background: rgba(0,0,0,0.28); backdrop-filter: blur(3px);"
      ></div>
    </transition>

    <!-- submenu mobile -->
    <transition name="slide-up">
      <div 
        v-if="isMobileBottomSheetOpen"
        class="fixed bottom-24 left-4 right-4 bg-white rounded-2xl shadow-2xl z-40 p-4 md:hidden border border-gray-100"
      >  
         <div class="flex flex-col">
            <div class="flex justify-end">
              <button @click="closeBottomSheet" class="text-gray-400 hover:text-gray-600">
                  <i class="pi pi-times text-2xl" />
              </button>
            </div>
          
            <!-- Spese / Entrate (top) -->
            <div class="flex justify-around items-center px-4 pb-2 border-b border-gray-50 mb-2">
               <div v-for="subItem in activeMobileBottomMenu?.voices.slice(0, 2)" :key="subItem.name">
                  <MenuVoice
                     :menuVoice="subItem.name"
                     :route="subItem.route"
                     :icon="subItem.icon"
                     :iconSolid="subItem.iconSolid"
                     @click="closeBottomSheet" 
                  />
               </div>
            </div>

            <!-- Categorie (bottom, smaller) -->
            <div v-if="activeMobileBottomMenu?.voices.length > 2" class="flex justify-center py-2 mt-2">
               <div v-for="subItem in activeMobileBottomMenu?.voices.slice(2)" :key="subItem.name">
                  <RouterLink 
                    :to="subItem.route" 
                    class="text-xs font-semibold text-primary bg-primary/5 px-4 py-2 rounded-full border border-primary/10 hover:bg-primary/10 transition-colors"
                    @click="closeBottomSheet"
                  >
                    Gestisci categorie
                  </RouterLink>
               </div>
            </div>
         </div>
      </div>
    </transition>


    <!-- bottom nav mobile -->
    <!-- blur background -->
    <div class="mobile-blur-bg md:hidden fixed bottom-0 left-0 right-0 h-24 z-40"/>

    <!-- bottom nav -->
    <div class="md:hidden z-50 fixed bottom-0 w-full">
        <nav 
          class="m-4 text-gray-800 
                flex justify-between items-center p-2 shadow-lg
                rounded-xl border border-gray-100 z-50 bg-white"
        >
          <div class="flex flex-1 justify-around">
            <div v-for="item in menuOptions.slice(0, 2)" :key="item.name" class="flex flex-col items-center min-w-0">
              <MenuVoice
                :menuVoice="item.name"
                :route="item.route"
                :icon="item.icon"
                :iconSolid="item.iconSolid"
                :voices="item.voices"
                @click="() => handleBottomNavClick(item)"
              />
            </div>
          </div>

          <RouterLink 
            :to="{ path: '/addmodifytransaction', query: { new: '1' } }"
            class="flex-shrink-0 w-14 h-14 -mt-8 flex items-center justify-center rounded-full bg-primary text-white shadow-xl  z-50"
          >
            <i class="pi pi-plus text-3xl" />
          </RouterLink>

          <div class="flex flex-1 justify-around">
            <div v-for="item in menuOptions.slice(2, 4)" :key="item.name" class="flex flex-col items-center min-w-0">
              <MenuVoice
                :menuVoice="item.name"
                :route="item.route"
                :icon="item.icon"
                :iconSolid="item.iconSolid"
                @click="() => handleBottomNavClick(item)"
              />
            </div>
          </div>
        </nav>
      </div>
      
  </div>
</template>

<style>
/* Side sidebar */
.slide-enter-active, .slide-leave-active { transition: transform 0.3s ease; }
.slide-enter-from, .slide-leave-to { transform: translateX(-100%); }

/* Overlay and fades */
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

/* Bottom Sheet sliding up from the bottom */
.slide-up-enter-active, .slide-up-leave-active { 
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1); 
}
.slide-up-enter-from, .slide-up-leave-to { 
  transform: translateY(100%); 
  opacity: 0; 
}
.mobile-blur-bg {
  /* gradient height (modify freely) */
  height: 120px;

  /* transparent background */
  background: transparent;

  /* strong blur behind */
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);

  /* GRADIENT: 0% blur at top → 100% blur at bottom */
  mask-image: linear-gradient(
    to bottom,
    rgba(0, 0, 0, 0) 0%,
    rgba(0, 0, 0, 1) 100%
  );
  -webkit-mask-image: linear-gradient(
    to bottom,
    rgba(0, 0, 0, 0) 0%,
    rgba(0, 0, 0, 1) 100%
  );
}


</style>