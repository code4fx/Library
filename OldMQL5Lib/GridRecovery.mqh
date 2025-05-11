//+------------------------------------------------------------------+
//|                                                       Trader.mqh |
//|                                                Copyright 2022, . |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, ."
#property link      "https://www.mql5.com"

#include "ErrorDescriptions.mqh"
#include <Trade/Trade.mqh>
#include "KVArgsList.mqh"

enum ENUM_REC_DIRECTION {
    OPPOSITE, //Opposite
    SAME, //Same
    DYNAMIC, //Dynamic
};

input group "//=== Grid Recovery"


input double InpMartgaleMult = 1; //Recovery Factor
input double InpGridFactor = 1; //Gap Size Factor
input ENUM_REC_DIRECTION InpDirection = 0;//Trade Direction

struct SOrderInfo {
    ulong mOrderTicket;
    bool mClosed;
};

class CGridRecovery {

    private:
        string symbol_;
        double ac_price;
        
        double ask;
        double bid;
        
        ulong int_pos_id_;
        ENUM_POSITION_TYPE direction_;
        SOrderInfo order_pool[];
        
        CTrade* trader_;
         
    public:
        CGridRecovery() {}
        CGridRecovery(int magic_num, string symbol) {}
        ~CGridRecovery() {delete trader_;}
        bool initGridRecovery(string symbol, long magic_no);
        
        void setInitOrder(ulong order_id, ENUM_POSITION_TYPE direction_);
        bool activateGR();
};

void CGridRecovery::setInitOrder(ulong order_id, ENUM_POSITION_TYPE direction) {
     int_pos_id_ = order_id;
     direction_ = direction;
}

bool CGridRecovery::activateGR() {
    
    return true;
}

bool CGridRecovery::initGridRecovery(string symbol, long magic_no) {

    
    return true;
}

