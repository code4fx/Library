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
    datetime GetOpenTime(int ticket);

protected:
    void ClearStructures(void);
};

void CTrade::Result(MqlTradeResult &result) const {
    result.order = m_result.order;
    result.volume = m_result.volume;
    result.price = m_result.price;
}

bool CTrade::PositionOpen(const string symbol, const int order_type, const double volume,
                          double price, const double sl, const double tp, const string comment) {
    ClearStructures();
   
    bool success = false;
    int ticket = -1;
    
    if(order_type != OP_BUY && order_type != OP_SELL) {
        return success;
    }
    
    ticket = OrderSend(symbol, order_type, volume, price, (int)m_deviation, sl, tp, comment, (int)m_magic);
    
    if (ticket > 0) {
        m_result.order = ticket;
        bool check = OrderSelect(ticket, SELECT_BY_TICKET);
        m_result.price = OrderOpenPrice();
        m_result.volume = OrderLots();
        success = true;  
    }
    
    return success;
}

bool CTrade::PositionModify(const ulong ticket, const double sl, const double tp) {

    if (!OrderSelect((int)ticket, SELECT_BY_TICKET)) return false;

    ClearStructures();

    string symbol = OrderSymbol();
    int type = OrderType();
    double price = OrderOpenPrice();
    bool success = false;

    if (OrderModify((int)ticket, price, sl, tp, 0)) {
        success = true;
        bool check = OrderSelect((int)ticket, SELECT_BY_TICKET);
        m_result.price = OrderOpenPrice();
        m_result.volume = OrderLots();
    }
    
    return success;
}

bool CTrade::PositionClose(const ulong ticket, const ulong deviation) {

    if (!OrderSelect((int)ticket, SELECT_BY_TICKET)) return false;

    string symbol = OrderSymbol();
    int type = OrderType();
    double volume = OrderLots();
    double price;

    if (type == ORDER_TYPE_BUY) {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
    }
    else if (type == ORDER_TYPE_SELL) {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    }
    else {
        return false;
    }

    if (OrderClose((int)ticket, volume, price, (int)((deviation==ULONG_MAX) ? m_deviation : deviation)))
        return true;

    return false;
}

void CTrade::ClearStructures(void) {
    ZeroMemory(m_result);
}

datetime CTrade::GetOpenTime(int ticket) {
    if (OrderSelect(ticket, SELECT_BY_TICKET)) {
        return ((datetime)OrderOpenTime());
    }
    return NULL;
}
