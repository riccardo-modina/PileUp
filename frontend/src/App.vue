<script setup>
import { RouterView } from 'vue-router'
import { computed, onMounted, watch, ref } from 'vue'
import { useAuth } from './composables/useAuth'
import UnlockVault from './components/UnlockVault.vue'
import { useSettingsStore } from './stores/settings'

const { authToken } = useAuth()
const settings = useSettingsStore()

onMounted(() => {
  if (authToken.value) {
    settings.fetchSettings()
  }
})

watch(authToken, (newVal) => {
  if (newVal) {
    settings.fetchSettings()
  }
  checkVaultStatus()
})

// Check if the user is logged in (has JWT) but does NOT have the Master Key in memory
const isVaultLocked = ref(false)

const checkVaultStatus = () => {
  const hasToken = !!authToken.value;
  const hasKey = !!sessionStorage.getItem('masterKey');
  isVaultLocked.value = hasToken && !hasKey;
}

onMounted(() => {
  checkVaultStatus()
})

</script>

<template>
  <RouterView />
  
  <UnlockVault v-if="isVaultLocked" @vault-unlocked="checkVaultStatus" />
</template>

<style scoped>
</style>