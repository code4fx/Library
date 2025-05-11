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

    datetime GetOpenTime(int ticket);

    bool Buy(const string symbol, 
            double price, 
            const double volume,
            const double sl,
            const double tp);
};

void CTrader::Init(int magic_no) {
    SetExpertMagicNumber(magic_no);
    SetInitResult(INIT_SUCCEEDED);
}

datetime CTrader::GetOpenTime(int ticket) {
#ifdef __MQL4__
    if (OrderSelect(ticket, SELECT_BY_TICKET)) {
        return ((datetime)OrderOpenTime());
    }
    return NULL;
#endif
#ifdef __MQL5__
    if (PositionSelectByTicket(ticket)) {
      return ((datetime)PositionGetInteger(POSITION_TIME));
    }
    return NULL;
#endif 

}

bool CTrader::Buy(const string symbol, 
            double price, 
            const double volume,
            const double sl,
            const double tp) {

    bool success = false;
    MqlTick tick_data;
    MqlTradeResult result;

    //Clear custom trade data structure
    ZeroMemory(m_custom_data);

    //Populate tick_data struct
    SymbolInfoTick(symbol, tick_data);

    m_custom_data.pre_entry_price = tick_data.ask;
    m_custom_data.pre_entry_time = tick_data.time;
    m_custom_data.entry_spread = (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);

    success = PositionOpen(symbol, 0, volume, price, sl, tp);

    if (success) {
        Result(result);
        m_custom_data.position_id = result.order;

        m_custom_data.symbol = symbol;
        m_custom_data.position_type = 0;

        m_custom_data.entry_price = result.price;
        m_custom_data.entry_time = GetOpenTime((int)result.order);

        m_custom_data.volume = result.volume;
        m_custom_data.stoploss = sl;
        m_custom_data.takeprofit = tp;
    }

    return (success);
}
