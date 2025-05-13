/*
    Copyright 2025, code4fx
    https://www.code4fx.com
*/
#property copyright "Copyright 2025, code4fx"
#property link      "https://www.code4fx.com"
#property version   "1.00"
#property strict

#ifdef __MQL5__
   #include "MQL5/Trade.mqh"
#endif

#ifdef __MQL4__
   #include "MQL4/Trade.mqh"
#endif



struct MqlCustomTradeData {
    ulong position_id;
    string symbol;
	 int position_type;

    datetime entry_time;
	 double entry_price;

    int entry_spread;

    double pre_entry_price;
	 datetime pre_entry_time;

    double volume;
	 double takeprofit;
	 double stoploss;
	
	string FormatType(int type) {
	   string str = "";
	   switch(type) {
         case ORDER_TYPE_BUY:
            str="buy";
            break;
         case ORDER_TYPE_SELL:
            str="sell";
            break;
         default:
            str="unknown position type "+(string)type;
     }
     return str;
	}

    string toString() {
        string str = "";
        string sep = ", ";
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

        str += IntegerToString(position_id);
        str += sep;
        str += symbol;
        str += sep;
        str += FormatType(position_type);
        str += sep;
        str += DoubleToString(pre_entry_price, digits);
        str += sep;
        str += TimeToString(pre_entry_time, TIME_MINUTES|TIME_SECONDS);
        str += sep;   
        str += DoubleToString(entry_price, digits);
        str += sep;
        str += TimeToString(entry_time, TIME_MINUTES|TIME_SECONDS);
        str += sep;   
        str += IntegerToString(entry_spread);
        str += sep;
        str += DoubleToString(volume, 2);
        str += sep;
        str += DoubleToString(takeprofit, digits);
        str += sep;
        str += DoubleToString(stoploss, digits);

        return str;
    }
};

class CTrader : public CTrade {

protected:
    int m_init_result;
    MqlCustomTradeData m_custom_data;

public:
    CTrader() { SetInitResult(INIT_FAILED); };
    ~CTrader() {};
    void Init(int magic_no);
    int GetInitResult() { return m_init_result; }
    void SetInitResult(int result) { m_init_result = result; }

    bool Buy(const string symbol, 
            double price, 
            const double volume,
            const double sl,
            const double tp,
            bool fill_custom_data);
    
    bool Sell(const string symbol, 
            double price, 
            const double volume,
            const double sl,
            const double tp,
            bool fill_custom_data);
    
    void CustomTradeData(MqlCustomTradeData &custom_data);
    
};

void CTrader::Init(int magic_no) {
    SetExpertMagicNumber(magic_no);
    SetInitResult(INIT_SUCCEEDED);
}

void  CTrader::CustomTradeData(MqlCustomTradeData &custom_data) {
    
    custom_data.position_id = m_custom_data.position_id;
    custom_data.position_type = m_custom_data.position_type;
    custom_data.symbol = m_custom_data.symbol;
    custom_data.pre_entry_price = m_custom_data.pre_entry_price;
    custom_data.pre_entry_time = m_custom_data.pre_entry_time;
    custom_data.entry_spread = m_custom_data.entry_spread;
    custom_data.entry_price = m_custom_data.entry_price;
    custom_data.entry_time = m_custom_data.entry_time;
    custom_data.volume = m_custom_data.volume;
    custom_data.stoploss = m_custom_data.stoploss;
    custom_data.takeprofit = m_custom_data.takeprofit; 
}

bool CTrader::Buy(const string symbol, 
            double price, 
            const double volume,
            const double sl,
            const double tp,
            bool fill_custom_data=false) {

    bool success = false;
    const int order_type = 0;
    MqlTick tick_data;
    MqlTradeResult result;

    //Clear custom trade data structure
    ZeroMemory(m_custom_data);

    //Populate tick_data struct
    SymbolInfoTick(symbol, tick_data);

    //Capture pre-trade data
    m_custom_data.pre_entry_price = tick_data.ask;
    m_custom_data.pre_entry_time = tick_data.time;
    m_custom_data.entry_spread = (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);

    success = PositionOpen(symbol, (ENUM_ORDER_TYPE)order_type, volume, price, sl, tp);

    if (success) Result(result);

    //If trade opening was successful, capture data
    if (success && fill_custom_data) {
        
        m_custom_data.position_id = result.order;

        m_custom_data.symbol = symbol;
        m_custom_data.position_type = order_type;

        m_custom_data.entry_price = result.price;
        m_custom_data.entry_time = GetOpenTime((int)result.order);

        m_custom_data.volume = result.volume;
        m_custom_data.stoploss = sl;
        m_custom_data.takeprofit = tp;
    }

    return (success);
}

bool CTrader::Sell(const string symbol, 
            double price, 
            const double volume,
            const double sl,
            const double tp,
            bool fill_custom_data=false) {

    bool success = false;
    const int order_type = 1;
    MqlTick tick_data;
    MqlTradeResult result;

    //Clear custom trade data structure
    ZeroMemory(m_custom_data);

    if (fill_custom_data) {

        //Populate tick_data struct
        SymbolInfoTick(symbol, tick_data);

        //Capture pre-trade data
        m_custom_data.pre_entry_price = tick_data.ask;
        m_custom_data.pre_entry_time = tick_data.time;
        m_custom_data.entry_spread = (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
    }

    success = PositionOpen(symbol, (ENUM_ORDER_TYPE)order_type, volume, price, sl, tp);

    if (success) Result(result);

    //If trade opening was successful, capture data
    if (success && fill_custom_data) {
        
        m_custom_data.position_id = result.order;

        m_custom_data.symbol = symbol;
        m_custom_data.position_type = order_type;

        m_custom_data.entry_price = result.price;
        m_custom_data.entry_time = GetOpenTime((int)result.order);

        m_custom_data.volume = result.volume;
        m_custom_data.stoploss = sl;
        m_custom_data.takeprofit = tp;
    }

    return (success);
}
