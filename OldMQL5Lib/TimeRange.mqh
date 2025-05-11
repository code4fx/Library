//+------------------------------------------------------------------+
//|                                                   TimesRange.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

input group "//=== TIME RANGE"
input bool InpEnableTR = false;
input int InpStartHours = 0; // Start hour
input int InpStartMinutes = 0; // Start minutes
input int InpFinishHours = 23; // Finish hours
input int InpFinishMinutes = 59; // Finish minutes

class CTimeRange {
    private:
        bool enable_TR;
        bool UseStartFinish;
        int StartMinutes;
        int FinishMinutes;
        
    public:
        CTimeRange() {}
        CTimeRange(bool eTR, int sH, int sM, int fH, int fM) {
            enable_TR = eTR;
            initialize(sH, sM, fH, fM);
        }
        ~CTimeRange() {}
        bool initialize(int, int, int, int);
        int timeToMinutes(datetime);
        bool insideTimeRange(datetime);
        
};

bool CTimeRange::initialize(int startHours_,
                             int startMinutes_,
                             int finishHours_,
                             int finishMinutes_) {
                     
    if (startHours_ < 0 || startHours_ > 23) {
        Print("Invalid start hours, select 0-23");
        return false;
    }
    
    if ( startMinutes_ < 0 || startMinutes_ > 59 ) {
        Print ( "Invalid start minutes, select 0-59" ) ;
        return false;
    }
    
    if ( finishHours_ < 0 || finishHours_ > 23 ) {
        Print ( "Invalid finish hours, select 0-23" ); 
        return false;
    }
    
    if ( finishMinutes_ < 0 || finishMinutes_ > 59 ) {
        Print( "Invalid finish minutes, select 0-59" );
        return false;
    }
    
    StartMinutes = (startHours_ * 60 + startMinutes_) ;
    FinishMinutes = (finishHours_ * 60 + finishMinutes_) ;
    UseStartFinish = (StartMinutes != FinishMinutes) ;
    return true;
}

int CTimeRange::timeToMinutes(datetime time) {
    MqlDateTime mtime;
    TimeToStruct (time, mtime);
    return (mtime.hour * 60 + mtime.min);
}

bool CTimeRange::insideTimeRange(datetime now) {
      
    if (!UseStartFinish || !enable_TR) 
        return true;
        
    int nowMinutes = timeToMinutes(now);
    
    return ((StartMinutes <= nowMinutes && nowMinutes < FinishMinutes) ||
            ((StartMinutes > FinishMinutes ) &&
             (nowMinutes > StartMinutes || nowMinutes < FinishMinutes)));
}