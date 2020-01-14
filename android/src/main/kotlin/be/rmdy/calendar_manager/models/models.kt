@file:UseSerializers(DateSerializer::class)

package be.rmdy.calendar_manager.models

import be.rmdy.calendar_manager.serializers.DateSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import java.util.*


@Serializable
data class Event(
        val calendarId: String,
        val title: String,
        val startDate: Date,
        val endDate: Date,
        val location: String?,
        val description: String?
)

@Serializable
data class CalendarResult(val id: String,
                          val name: String,
                          val color: Int?,
                          val isReadOnly: Boolean)

@Serializable
data class CreateCalendar(val name: String,
                          val color: Int?,
                          val androidInfo: CreateCalendarAndroidInfo) {
    val id get() = androidInfo.id
}

@Serializable
data class CreateCalendarAndroidInfo(val id: String)