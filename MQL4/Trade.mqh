/*
    Copyright 2025, code4fx
    https://www.code4fx.com

*/
#property copyright "Copyright 2025, code4fx"
#property link      "https://www.code4fx.com"
#property version   "1.00"
#property strict

#include <Object.mqh>

struct MqlTradeResult {
    ulong order;
    double volume;
    double price; //price where the trade was opened (same as PositionInfo price)
};

class CTrade : public CObject {

protected:
    MqlTradeResult m_result;      // result data
    ulong m_magic;                // expert magic number
    ulong m_deviation;            // deviation default

public:
    CTrade(void) {}
    ~CTrade(void) {}
    //--- methods of access to protected data

    void Result(MqlTradeResult &result) const;
    ulong ResultOrder(void) const { return(m_result.order); }
    double ResultVolume(void) const { return(m_result.volume); }
    double ResultPrice(void) const { return(m_result.price); }

    //--- trade methods

    void SetExpertMagicNumber(const ulong magic) { m_magic = magic; }
    void SetDeviationInPoints(const ulong deviation) { m_deviation = deviation; }

    //--- methods for working with positions
    bool PositionOpen(const string symbol,const int order_type,const double volume,
                       const double price,const double sl,const double tp,const string comment="");
    bool PositionModify(const ulong ticket,const double sl,const double tp);
    bool PositionClose(const ulong ticket,const ulong deviation=ULONG_MAX);

protected:
    void ClearStructures(void);
};

void CTrade::Result(MqlTradeResult &result) const {
    result.order = m_result.order;
    result.volume = m_result.volume;
    result.price = m_result.price;
}

bool CTrade::PositionOpen(const string symbol,const int order_type,const double volume,
                          double price,const double sl,const double tp,const string comment) {
    ClearStructures();
   
    bool result = false;
    int ticket = -1;
    
    if(order_type != OP_BUY && order_type != OP_SELL) {
        return result;
    }
    
    ticket = OrderSend(symbol, order_type, volume, price, (int)m_deviation, sl, tp, comment, (int)m_magic);
    
    if (ticket > 0) {
        m_result.order = ticket;
        bool check = OrderSelect(ticket, SELECT_BY_TICKET);
        m_result.price = OrderOpenPrice();
        m_result.volume = OrderLots();
        result = true;  
    }
    
    return result;
}

bool CTrade::PositionModify(const ulong ticket,const double sl,const double tp) {

    return false;
}


bool CTrade::PositionClose(const ulong ticket, const ulong deviation) {

    return false;
}

//+------------------------------------------------------------------+
//| Clear structures m_request,m_result and m_check_result           |
//+------------------------------------------------------------------+
void CTrade::ClearStructures(void) {
    ZeroMemory(m_result);
}

//+------------------------------------------------------------------+
