//###<Template_System.mq5>
//+------------------------------------------------------------------+
//|                                                       Trader.mqh |
//|                                                Copyright 2022, . |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, ."
#property link      "https://www.mql5.com"

#include <Library/ErrorDescriptions.mqh>
#include <Trade/Trade.mqh>
#include <Library/DataObject.mqh>

input group "//=== TRADING"

input int InpMagicNumber = 1201; //Magic Number

class CTrader {

    private:
        string m_symbol;
        bool m_init_status;
        int m_magic_number;

        CTrade* m_trader;
        
        double m_symbol_point;
         
    public:
        CTrader() {}
        CTrader(int magic_number, string symbol) {
            InitTrader(magic_number, symbol);
        }
        
        ~CTrader() { delete m_trader; }
        bool InitTrader(int, string);
        bool Sell(double price, double lot_size, double sl, double tp, CDataObject *data);
        bool Buy(double price, double lot_size, double sl, double tp, CDataObject *data);
        bool CloseSell(long);
        bool CloseBuy(long);
        void CloseAllBySymbol();
        int PositionsCount();
        bool IsPositionClosed(ulong position);
        void SetInitStatus(bool init_result) { m_init_status = init_result; }
        bool GetInitStatus() { return m_init_status; }
        bool ModifyPosition(long ticket, double sl, double tp);
        long GetMagicNumber() { return m_magic_number; }
};

bool CTrader::InitTrader(int magic_no, string symbol) {

    m_symbol = symbol;
    m_magic_number = magic_no;
    m_trader = new CTrade();

    m_trader.SetExpertMagicNumber(magic_no);

    m_symbol_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    
    SetInitStatus(true);
    
    return true;
}

bool CTrader::Sell(double price, double lot_size, double sl, double tp, CDataObject *data) {  
    
    bool success = true;
    MqlTradeResult results;
    MqlTick tick_info;
    
    if (data) {
        SymbolInfoTick(m_symbol, tick_info);
        data.pre_entry_price = tick_info.ask;
        data.pre_entry_time = tick_info.time;
        data.entry_spread = (int)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
    }
    
    if(!m_trader.Sell(lot_size, m_symbol, price, sl, tp)) {
        print_error("opening sell trade failed", __FUNCTION__);
        print_error(__FUNCTION__);
        success = false;
    }
    
    if (success) {
        if (data) {
            m_trader.Result(results);
            data.lot_size = results.volume;
            data.position_type = POSITION_TYPE_SELL;
            data.entry_price = results.price;
            data.entry_time = tick_info.time;
            data.position_id = results.order;
        }
    }
    
    return success; 
}

bool CTrader::Buy(double price, double lot_size, double sl, double tp, CDataObject *data) {

    bool success = true;
    MqlTradeResult results;
    MqlTick tick_info;
    
    if (data) {
        SymbolInfoTick(m_symbol, tick_info);
        data.pre_entry_price = tick_info.ask;
        data.pre_entry_time = tick_info.time;
        data.entry_spread = (int)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
    }

    if(!m_trader.Buy(lot_size, m_symbol, price, sl, tp)) {
        print_error("opening buy trade failed", __FUNCTION__);
        print_error(__FUNCTION__);
        success = false;   
    }
    
    if (success) {
        if (data) {
            m_trader.Result(results);
            data.lot_size = results.volume;
            data.position_type = POSITION_TYPE_BUY;
            data.entry_price = results.price;
            data.entry_time = tick_info.time;
            data.position_id = results.order;
        }
    }
   
    return success;   
}

bool CTrader::ModifyPosition(long ticket, double sl, double tp) {
    return false;
}

bool CTrader::CloseSell(long ticket) {
    return m_trader.PositionClose(ticket, 1);
}
 
bool CTrader::CloseBuy(long ticket) {
    return m_trader.PositionClose(ticket, 1);
}

void CTrader::CloseAllBySymbol() {
    while (m_trader.PositionClose(m_symbol, 1) == true) {}
}

int CTrader::PositionsCount() {

    int allCount = PositionsTotal();
    int posCount = 0;
    
    for (int i = allCount - 1; i >= 0; i--) {
    ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetString(POSITION_SYMBOL) == m_symbol &&
                PositionGetInteger(POSITION_MAGIC) == m_magic_number) {
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
//    double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
//    double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
//    
//    SLManager(array, arrSize, ask, bid);
//    TPManager(array, arrSize, ask, bid);
//}

bool CTrader::IsPositionClosed(ulong position) {
    if(PositionSelectByTicket(position))
       return false;
    else
       return true;
}
