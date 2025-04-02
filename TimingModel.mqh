//###<Template_System.mq5>
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
        string m_symbol;
        ENUM_TIMEFRAMES m_timeframe;
        
        string m_lastSymbol;
        bool m_isOpen;
        datetime m_sessionStart;
        datetime m_sessionEnd;
        bool m_init_status;

        datetime m_ArrayTime[], m_LastTime;

    public:
        virtual bool ExecTime() = 0;
        virtual bool InitExecModel(string, ENUM_TIMEFRAMES) { return false; }
        ENUM_TIMEFRAMES GetTimeFrame() { return m_timeframe; }
        
        void InitSessionVariables();
        bool IsMarketOpen();
        
        void SetInitStatus(bool init_result) { m_init_status = init_result; }
        bool GetInitStatus() { return m_init_status; }
};

bool CExecTimer::IsMarketOpen() {
    
    datetime time = TimeCurrent();
    
    if (m_lastSymbol == m_symbol && m_sessionEnd > m_sessionStart) {
        if ((m_isOpen && time >= m_sessionStart && time <= m_sessionEnd) || 
            (!m_isOpen && time > m_sessionStart && time < m_sessionEnd)) 
            return m_isOpen;
    }
    
    m_lastSymbol = m_symbol;
    
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
    
    m_sessionStart = dayStart;
    m_sessionEnd = dayEnd;
    
    for (int session = 0;;session++) {
        if (!SymbolInfoSessionTrade(m_symbol, (ENUM_DAY_OF_WEEK)mtime.day_of_week, session, fromTime, toTime)) {
            m_sessionEnd = dayEnd;
            m_isOpen = false;
            return m_isOpen;
        }
        
        if (seconds < fromTime) {// not inside a session
            m_sessionEnd = dayStart + fromTime;
            m_isOpen = false;
            return m_isOpen;
        }
        
        if (seconds > toTime) { // maybe a later session
            m_sessionStart = dayStart + toTime; 
            continue;
        }
        
        // at this point must be inside a session
        m_sessionStart = dayStart + fromTime;
        m_sessionEnd = dayStart + toTime;
        m_isOpen = true;
        return m_isOpen;
    }
    
    return false;
}

void CExecTimer::InitSessionVariables() {
    m_lastSymbol = "";
    m_isOpen = false;
    m_sessionStart = 0;
    m_sessionEnd = 0;
}

class CTickModel : public CExecTimer{
    public:
        CTickModel() {}
        ~CTickModel() {}
        virtual bool ExecTime();
};

class COPCModel : public CExecTimer {
    private:
        int m_tf_seconds;
        datetime m_last_time;
        int m_execution_timer;
        
        MqlTick m_tick;
        datetime m_next_time;
        
    public:
        COPCModel(string symbol, ENUM_TIMEFRAMES _bar_timeframe) {
            m_last_time = 0;
            if (InitExecModel(symbol, _bar_timeframe))
                SetInitStatus(true);
            else
                SetInitStatus(false);
        }
        ~COPCModel() {}
        bool InitExecModel(string _symbol, ENUM_TIMEFRAMES _bar_timeframe);
        virtual bool ExecTime();
        bool IsNewBar(datetime time);  
};

bool COPCModel::InitExecModel(string symbol, ENUM_TIMEFRAMES bar_timeframe) {
  
    m_symbol = symbol;
    m_timeframe = bar_timeframe;
    
    m_tf_seconds = PeriodSeconds(m_timeframe);
    m_next_time = 0;
    
    InitSessionVariables();
    IsNewBar(TimeCurrent());
    
    return true;
}

bool COPCModel::IsNewBar(datetime curr_time) {
    
    bool result = false;
    
    if (m_last_time != curr_time) {
        m_last_time = curr_time;
        result = true;
    }
    
    return result;
}

bool COPCModel::ExecTime() {
    datetime curr_time = iTime(m_symbol, m_timeframe, 1);

    return IsNewBar(curr_time) && IsMarketOpen();
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
        CTickLvlOPC(string symbol, ENUM_TIMEFRAMES bar_timeframe) {
            if (InitExecModel(symbol, bar_timeframe))
                SetInitStatus(true);
            else
                SetInitStatus(false);
        }
        ~CTickLvlOPC() {}
        bool FirstTFTick(datetime t, ENUM_TIMEFRAMES tf);
        bool IsNewBar();
        virtual bool ExecTime();
};

bool CTickModel::ExecTime() {
    return IsMarketOpen();   
}

//firstTFTick - determines if the tick at time 't' within the timeframe 'tf'
//is appoximately the first tick of the timeframe.
//The function allows the tick to be within the first minute, but not greater.
bool CTickLvlOPC::FirstTFTick(datetime t, ENUM_TIMEFRAMES tf) {

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

bool CTickLvlOPC::IsNewBar() {
    
    SymbolInfoTick(m_symbol, tick);
    
    fst_tick = FirstTFTick(tick.time, m_timeframe);

    if  (!fst_tick) {
        flag = true;
    }
    
    if (flag && fst_tick) {
        flag = false;
        return true;
    }
    
    return false;
}

bool CTickLvlOPC::ExecTime(void) {
    return IsNewBar() && IsMarketOpen();
}

class CTimingModel {
    private:
        CExecTimer *m_exectimer;
    public:
    CTimingModel(string symbol, ENUM_TIMING_MODEL timing_model, ENUM_TIMEFRAMES tf) {
        switch (timing_model) {
            case EVERY_TICK:
                m_exectimer = new CTickModel();
            break;
            case OPEN_OF_CANDLE:
                m_exectimer = new COPCModel(symbol, tf);
            break;
            case TICK_LVL_OPC:
                m_exectimer = new CTickLvlOPC(symbol, tf);
            break;
        }
    }
    ~CTimingModel() { delete m_exectimer; }
    virtual bool ExecTime() { return m_exectimer.ExecTime(); }
    ENUM_TIMEFRAMES GetTimeFrame() { return m_exectimer.GetTimeFrame(); }
    void SetInitStatus(bool init_result) { m_exectimer.SetInitStatus(init_result); }
    bool GetInitStatus() { return m_exectimer.GetInitStatus(); }
};
