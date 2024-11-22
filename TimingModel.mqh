//+------------------------------------------------------------------+
//|                                          Signal_Indicator_EA.mq4 |
//|                                    programmed by mojalefa nkwana | 
//|                       email: 5pitcb4qiq@privaterelay.appleid.com |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property link      "https://www.mql5.com"
#property strict

#define M1 60
#define M5 300
#define M15 900
#define M30 1800
#define H1 3600
#define H4 14400
#define D1 86400
#define W1 604800
#define MN1 2592000
//---

enum ENUM_TIMING_MODEL {
    EVERY_TICK, //Every Tick
    OPEN_OF_CANDLE, //Bar Open
    TICK_LVL_OPC, //1st Tick of Bar
};

input group "//=== TIMING MODEL"

input ENUM_TIMING_MODEL InpTiming = OPEN_OF_CANDLE; //Execution Timer
input ENUM_TIMEFRAMES InpTradeTF = PERIOD_CURRENT; //Trading Timeframe

class CExecTimer {

    protected:
        string symbol_;
        ENUM_TIMEFRAMES timeframe_;
        
        string lastSymbol;
        bool isOpen;
        datetime sessionStart;
        datetime sessionEnd;
        bool init_status_;

        datetime ArrayTime[], LastTime;

    public:
        virtual bool execTime() = 0;
        virtual bool initExecModel(string, ENUM_TIMEFRAMES) { return false; }
        ENUM_TIMEFRAMES getTimeFrame() { return timeframe_; }
        
        void initSessionVariables();
        bool IsMarketOpen();
        
        void setInitStatus(bool init_result) { init_status_ = init_result; }
        bool getInitStatus() { return init_status_; }
};

bool CExecTimer::IsMarketOpen() {
    
    datetime time = TimeCurrent();
    
    if (lastSymbol == symbol_ && sessionEnd > sessionStart) {
        if ((isOpen && time >= sessionStart && time <= sessionEnd) || 
            (!isOpen && time > sessionStart && time < sessionEnd)) 
            return isOpen;
    }
    
    lastSymbol = symbol_;
    
    MqlDateTime mtime;
    TimeToStruct(time, mtime);
    datetime seconds = mtime.hour * 3600 + mtime.min * 60 + mtime.sec;
    
    MqlDateTime mtime2 = mtime;
    mtime.hour = 0;
    mtime.min = 0;
    mtime.sec = 0;
    datetime dayStart = StructToTime(mtime2) ;
    datetime dayEnd = dayStart + 86400;
    
    datetime fromTime; 
    datetime toTime;
    
    sessionStart = dayStart;
    sessionEnd = dayEnd;
    
    for (int session = 0;;session++) {
        if (!SymbolInfoSessionTrade(symbol_, (ENUM_DAY_OF_WEEK)mtime.day_of_week, session, fromTime, toTime)) {
            sessionEnd = dayEnd;
            isOpen = false;
            return isOpen;
        }
        
        if (seconds < fromTime) {// not inside a session
            sessionEnd = dayStart + fromTime;
            isOpen = false;
            return isOpen;
        }
        
        if (seconds > toTime) { // maybe a later session
            sessionStart = dayStart + toTime; 
            continue;
        }
        
        // at this point must be inside a session
        sessionStart = dayStart + fromTime;
        sessionEnd = dayStart + toTime;
        isOpen = true;
        return isOpen;
    }
    
    return false;
}

void CExecTimer::initSessionVariables() {
    lastSymbol = "";
    isOpen = false;
    sessionStart = 0;
    sessionEnd = 0;
}

class CTickModel : public CExecTimer{
    public:
        CTickModel() {}
        ~CTickModel() {}
        virtual bool execTime();
};

class COPCModel : public CExecTimer {
    private:
        int tf_seconds;
        datetime last_time;
        int execution_timer;
        
        MqlTick tick;
        datetime next_time;
        
    public:
        COPCModel(string symbol, ENUM_TIMEFRAMES _bar_timeframe) {
            last_time = 0;
            if (initExecModel(symbol, _bar_timeframe))
                setInitStatus(true);
            else
                setInitStatus(false);
        }
        ~COPCModel() {}
        bool initExecModel(string _symbol, ENUM_TIMEFRAMES _bar_timeframe);
        virtual bool execTime();
        bool isNewBar(datetime time);  
};

bool COPCModel::initExecModel(string symbol, ENUM_TIMEFRAMES _bar_timeframe) {
  
    symbol_ = symbol;
    timeframe_ = _bar_timeframe;
    
    tf_seconds = PeriodSeconds(timeframe_);
    next_time = 0;
    
    initSessionVariables();
    isNewBar(TimeCurrent());
    
    return true;
}

bool COPCModel::isNewBar(datetime curr_time) {
    
    bool result = false;
    
    if (last_time != curr_time) {
        last_time = curr_time;
        result = true;
    }
    
    return result;
}

bool COPCModel::execTime() {
    datetime curr_time = iTime(symbol_, timeframe_, 1);

    return isNewBar(curr_time) && IsMarketOpen();
}

class CTickLvlOPC : public CExecTimer {
    private:
        MqlTick tick;
        MqlDateTime dt;
        
        bool flag;
        bool fst_tick;
        
        bool x, mdls, zero_d, zero_h, zero_m, zero_s;
        double mins, hrs, days, months;
        
        int seconds;
        
    public:
        CTickLvlOPC(string symbol, ENUM_TIMEFRAMES _bar_timeframe) {
            if (initExecModel(symbol, _bar_timeframe))
                setInitStatus(true);
            else
                setInitStatus(false);
        }
        ~CTickLvlOPC() {}
        bool firstTFTick(datetime t, ENUM_TIMEFRAMES tf);
        bool isNewBar();
        virtual bool execTime();
};

bool CTickModel::execTime() {
    return IsMarketOpen();   
}

//firstTFTick - determines if the tick at time 't' within the timeframe 'tf'
//is appoximately the first tick of the timeframe.
//The function allows the tick to be within the first minute, but not greater.
bool CTickLvlOPC::firstTFTick(datetime t, ENUM_TIMEFRAMES tf) {

    seconds = PeriodSeconds(tf);
    TimeToStruct(t, dt);
    
    switch (seconds) {
        case M1: {
            mins = seconds / M1;
            mdls = (dt.min % (int)mins) == 0;
            zero_s = dt.sec == 0; 
            x = mdls && zero_s;
        }
        break;
        case M5: {
            mins = seconds / M1;
            mdls = dt.min % (int)mins == 0;
            zero_s = dt.sec >= 0; 
            x = mdls && zero_s;
        }  
        break;
        case M15: {
            mins = seconds / M1;
            mdls = dt.min % (int)mins == 0;
            zero_s = dt.sec >= 0; 
            x = mdls && zero_s;
        }
        break;
        case M30: {
            mins = seconds / M1;
            mdls = dt.min % (int)mins == 0;
            zero_s = dt.sec >= 0; 
            x = mdls && zero_s;
        }
        break;
        case H1: {
            hrs = seconds / H1;
            mdls = dt.hour % (int)hrs == 0;
            zero_m = dt.min == 0;
            zero_s = dt.sec >= 0;
            x = mdls && zero_m && zero_s;
        }
        break;
        case H4: {
            hrs = seconds / H1;
            mdls = dt.hour % (int)hrs == 0;
            zero_m = dt.min == 0;
            zero_s = dt.sec >= 0;
            x = mdls && zero_m && zero_s;
        }
        break;
        case D1: {
            days = seconds / D1;
            mdls = (dt.day % (int)days) == 0;
            zero_h = dt.hour == 0;
            zero_m = dt.min == 0;
            zero_s = dt.sec >= 0;
            x = mdls && zero_h && zero_m && zero_s;
        }
        break;
        case MN1: {
            months = seconds / MN1;
            mdls = dt.mon % (int)months == 0;
            zero_d = dt.day == 1;
            zero_h = dt.hour == 0;
            zero_m = dt.min == 0;
            zero_s = dt.sec >= 0;
            x = mdls && zero_d && zero_h && zero_m && zero_s;
        }
        break;
    }
    
    if (x)
        return true;
    else
        return false;
}

bool CTickLvlOPC::isNewBar() {
    
    SymbolInfoTick(symbol_, tick);
    
    fst_tick = firstTFTick(tick.time, timeframe_);

    if  (!fst_tick) {
        flag = true;
    }
    
    if (flag && fst_tick) {
        flag = false;
        return true;
    }
    
    return false;
}

bool CTickLvlOPC::execTime(void) {
    return isNewBar() && IsMarketOpen();
}

class CTimingModel {
    private:
        CExecTimer *exectimer;
    public:
    CTimingModel(string symbol, ENUM_TIMING_MODEL timing_model, ENUM_TIMEFRAMES tf) {
        switch (timing_model) {
            case EVERY_TICK:
                exectimer = new CTickModel();
            break;
            case OPEN_OF_CANDLE:
                exectimer = new COPCModel(symbol, tf);
            break;
            case TICK_LVL_OPC:
                exectimer = new CTickLvlOPC(symbol, tf);
            break;
        }
    }
    ~CTimingModel() { delete exectimer; }
    virtual bool execTime() { return exectimer.execTime(); }
    ENUM_TIMEFRAMES getTimeFrame() { return exectimer.getTimeFrame(); }
    void setInitStatus(bool init_result) { exectimer.setInitStatus(init_result); }
    bool getInitStatus() { return exectimer.getInitStatus(); }
};
