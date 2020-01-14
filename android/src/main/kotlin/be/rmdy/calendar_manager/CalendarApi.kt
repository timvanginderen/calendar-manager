package be.rmdy.calendar_manager

import be.rmdy.calendar_manager.models.CalendarResult
import be.rmdy.calendar_manager.models.CreateCalendar
import be.rmdy.calendar_manager.models.Event

interface CalendarApi {
    suspend fun deleteCalendar(calendarId: String)
    suspend fun createEvent(event: Event)
    suspend fun requestPermissions(): Boolean
    suspend fun findAllCalendars(): List<CalendarResult>
    suspend fun createCalendar(calendar: CreateCalendar): CalendarResult
}