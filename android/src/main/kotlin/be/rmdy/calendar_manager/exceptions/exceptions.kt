package be.rmdy.calendar_manager.exceptions

import java.lang.Exception

class CalendarManagerException (val errorCode:String,val errorMessage:String?=null,val errorDetails:Any?=null) : Exception(){

    override val message: String?
        get() = "errorCode='$errorCode', errorMessage=$errorMessage, errorDetails=$errorDetails"
}

class NotImplementedMethodException : Exception() {

}