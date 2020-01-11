package be.rmdy.calendar_manager.serializers

import kotlinx.serialization.*
import kotlinx.serialization.internal.StringDescriptor
import java.util.*

@Serializer(forClass = Date::class)
object DateSerializer : KSerializer<Date> {

    override val descriptor: SerialDescriptor =
            StringDescriptor.withName("date")

    override fun serialize(encoder: Encoder, obj: Date) {
        encoder.encodeLong(obj.time)
    }

    override fun deserialize(decoder: Decoder): Date {
        return Date(decoder.decodeLong())
    }
}