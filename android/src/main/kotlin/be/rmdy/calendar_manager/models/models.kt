@file:UseSerializers(DateSerializer::class)
package be.rmdy.calendar_manager.models

import be.rmdy.calendar_manager.serializers.DateSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import java.util.*



@Serializable
class Event(
        val title: String,
        val startDate: Date,
        val endDate: Date,
        val location: String?,
        val description: String?
)

@Serializable
class Calendar(val id: String,
               val name: String)