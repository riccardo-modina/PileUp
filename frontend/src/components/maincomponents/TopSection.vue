<script setup>
import AddButton from '@/components/buttons/primarybuttons/AddButton.vue';
import TimeFrameSelector from '@/components/formcomponents/timeframe/TimeFrameSelector.vue';
import { useSettingsStore } from '../../stores/settings'

const settings = useSettingsStore();

defineProps({
    title: String,
    showTimeFrameButton: Boolean,
    showAddButton: Boolean,
})

const emit = defineEmits(['timeFrameButtonToggled'])

function timeFrameButtonToggled(isOpen) {
    emit('timeFrameButtonToggled', isOpen)
}

function updateTimeframe(newTimeframe, source) {

    if (source === 'monthYear') {
        settings.dataPeriod = newTimeframe.month.toString().padStart(2, '0')+ '/' +newTimeframe.year  ;
        return;
    }
    settings.dataPeriod = newTimeframe;
}
</script>

<template>
    <div class="flex flex-col w-full">
        <section class="md:min-h-[70px] min-h-24 flex items-center md:justify-between ">
            <div class="md:flex-row flex flex-col items-center w-full h-full px-4 justify-center gap-2.5 md:justify-between md:gap-0 ">
                <!-- Titolo a sinistra -->
                <h1 class=" text-2xl font-bold text-text px-6 py-2">{{ title }}</h1>

                <!-- Container a destra -->
                <div class="flex space-x-4">
                    <AddButton
                        v-if="showAddButton"
                        :to="{ path: '/addmodifytransaction', query: { new: '1' } }"
                        class="hidden md:block"
                        />
                    <div
                        v-if="showTimeFrameButton" 
                        class="flex space-x-2"
                        >
                        <TimeFrameSelector 
                            @timeFrameUpdate="(timeFrame, source) => updateTimeframe(timeFrame, source)"
                            @buttonToggled = "(isOpen) => timeFrameButtonToggled(isOpen)"
                            :dataPeriod="settings.dataPeriod.toString()"
                            />
                    </div>
                </div>
            </div>
        </section>
    </div>
</template>
