import { ref, computed } from 'vue'
import { onBeforeRouteLeave } from 'vue-router'

export function useFormControls(formRef, originalFormStateRef) {
  const showConfirmModal = ref(false)
  let pendingNavigationNext = null

  // A form is dirty if its serialized state differs from the original state (when prefill settles)
  const isDirty = computed(() => {
    return JSON.stringify(formRef.value) !== originalFormStateRef.value
  })

  // Vue Router guard to intercept navigation if dirty
  onBeforeRouteLeave((to, from, next) => {
    if (isDirty.value) {
      showConfirmModal.value = true
      pendingNavigationNext = next
    } else {
      next()
    }
  })

  function handleConfirmNavigation() {
    showConfirmModal.value = false
    if (pendingNavigationNext) {
      pendingNavigationNext()
      pendingNavigationNext = null
    }
  }

  function handleCancelNavigation() {
    showConfirmModal.value = false
    if (pendingNavigationNext) {
      pendingNavigationNext(false)
      pendingNavigationNext = null
    }
  }

  return {
    isDirty,
    showConfirmModal,
    handleConfirmNavigation,
    handleCancelNavigation
  }
}
