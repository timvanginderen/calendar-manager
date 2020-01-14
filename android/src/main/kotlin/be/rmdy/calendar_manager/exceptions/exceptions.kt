package be.rmdy.calendar_manager.exceptions

import be.rmdy.calendar_manager.ErrorCode

class CalendarManagerException(val code: ErrorCode, override val message: String? = null, val details: Any? = null) : Exception()

class NotImplementedMethodException : Exception() 