//+------------------------------------------------------------------+
//|                                                       Trader.mqh |
//|                                                Copyright 2022, . |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, ."
#property link      "https://www.mql5.com"

#include <System_Templates/ErrorDescriptions.mqh>
#include <Trade/Trade.mqh>
#include <System_Templates/DataObject.mqh>

input group "//=== TRADING"

input int InpMagicNumber = 1201; //Magic Number

class CTrader {

    private:
        string symbol_;
        bool init_status_;
        int magic_number_;

        CTrade* trader_;
        
        double symbol_point;
         
    public:
        CTrader() {}
        CTrader(int magic_number, string symbol) {
            initTrader(magic_number, symbol);
        }
        
        ~CTrader() { delete trader_; }
        bool initTrader(int, string);
        bool sell(double price, double lot_size, double sl, double tp, CDataObject *data);
        bool buy(double price, double lot_size, double sl, double tp, CDataObject *data);
        bool closeSell(long);
        bool closeBuy(long);
        void closeAllBySymbol();
        int positionsCount();
        bool isPositionClosed(ulong position);
        void setInitStatus(bool init_result) { init_status_ = init_result; }
        bool getInitStatus() { return init_status_; }
        bool modifyPosition(long ticket, double sl, double tp);
        long getMagicNumber() { return magic_number_; }
};

bool CTrader::initTrader(int magic_no, string symbol) {

    symbol_ = symbol;
    magic_number_ = magic_no;
    trader_ = new CTrade();

    trader_.SetExpertMagicNumber(magic_no);

    symbol_point = SymbolInfoDouble(symbol_, SYMBOL_POINT);
    
    setInitStatus(true);
    
    return true;
}

bool CTrader::sell(double price, double lot_size, double sl, double tp, CDataObject *data) {  
    
    bool success = true;
    MqlTradeResult results;
    MqlTick tick_info;
    
    if (data) {
        SymbolInfoTick(symbol_, tick_info);
        data.pre_entry_price = tick_info.ask;
        data.pre_entry_time = tick_info.time;
        data.entry_spread = (int)SymbolInfoInteger(symbol_, SYMBOL_SPREAD);
    }
    
    if(!trader_.Sell(lot_size, symbol_, price, sl, tp)) {
        print_error("opening sell trade failed", __FUNCTION__);
        print_error(__FUNCTION__);
        success = false;
    }
    
    if (success) {
        if (data) {
            trader_.Result(results);
            data.lot_size = results.volume;
            data.position_type = POSITION_TYPE_SELL;
            data.entry_price = results.price;
            data.entry_time = tick_info.time;
            data.position_id = results.order;
        }
    }
    
    return success; 
}

bool CTrader::buy(double price, double lot_size, double sl, double tp, CDataObject *data) {

    bool success = true;
    MqlTradeResult results;
    MqlTick tick_info;
    
    if (data) {
        SymbolInfoTick(symbol_, tick_info);
        data.pre_entry_price = tick_info.ask;
        data.pre_entry_time = tick_info.time;
        data.entry_spread = (int)SymbolInfoInteger(symbol_, SYMBOL_SPREAD);
    }

    if(!trader_.Buy(lot_size, symbol_, price, sl, tp)) {
        print_error("opening buy trade failed", __FUNCTION__);
        print_error(__FUNCTION__);
        success = false;   
    }
    
    if (success) {
        if (data) {
            trader_.Result(results);
            data.lot_size = results.volume;
            data.position_type = POSITION_TYPE_BUY;
            data.entry_price = results.price;
            data.entry_time = tick_info.time;
            data.position_id = results.order;
        }
    }
   
    return success;   
}

bool CTrader::modifyPosition(long ticket, double sl, double tp) {
    return false;
}

bool CTrader::closeSell(long ticket) {
    return trader_.PositionClose(ticket, 1);
}
 
bool CTrader::closeBuy(long ticket) {
    return trader_.PositionClose(ticket, 1);
}

void CTrader::closeAllBySymbol() {
    while (trader_.PositionClose(symbol_, 1) == true) {}
}

int CTrader::positionsCount() {

    int allCount = PositionsTotal();
    int posCount = 0;
    
    for (int i = allCount - 1; i >= 0; i--) {
    ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetString(POSITION_SYMBOL) == symbol_ &&
                PositionGetInteger(POSITION_MAGIC) == magic_number_ ) {
                posCount++;
            }
        }
    }
    
    return posCount;
}


//void CTrader::SLManager(BinStruct &array[], int aSize, double ask, double bid) {
//    
//    if (sl_manager_ == SERVER_SIDE)
//        return;
//        
//     for (int i = 0; i < aSize; i++) {
//        if (array[i].position_closed)
//            continue;
//            
//        switch(array[i].position_type) {
//            case POSITION_TYPE_BUY: {
//                if (bid <= array[i].stop_loss) {
//                    closeBuy(array[i].position_id);
//                }
//            } break;
//            case POSITION_TYPE_SELL: {
//                if (ask >= array[i].stop_loss) {
//                    closeSell(array[i].position_id);
//                }
//            } break;
//        }
//    }
//}
//
//void CTrader::TPManager(BinStruct &array[], int aSize, double ask, double bid) {
//    
//    if (tp_manager_ == SERVER_SIDE)
//        return;
//        
//    for (int i = 0; i < aSize; i++) {
//        if (array[i].position_closed)
//            continue;
//            
//        switch(array[i].position_type) {
//            case POSITION_TYPE_BUY: {
//                if (bid >= array[i].take_profit) {
//                    closeBuy(array[i].position_id);
//                }
//            } break;
//            case POSITION_TYPE_SELL: {
//                if (ask <= array[i].take_profit) {
//                    closeSell(array[i].position_id);
//                }
//            } break;
//        }
//    }
//}
//
//void CTrader::SLTPManager(BinStruct &array[], int arrSize) {
//    
//    for (int i = 0; i < arrSize; i++) {
//        if (isPositionClosed(array[i].position_id)) {
//            array[i].position_closed = true;
//        }
//    }
//    
//    double bid = SymbolInfoDouble(symbol_, SYMBOL_BID);
//    double ask = SymbolInfoDouble(symbol_, SYMBOL_ASK);
//    
//    SLManager(array, arrSize, ask, bid);
//    TPManager(array, arrSize, ask, bid);
//}

bool CTrader::isPositionClosed(ulong position) {
    if(PositionSelectByTicket(position))
       return false;
    else
       return true;
}
