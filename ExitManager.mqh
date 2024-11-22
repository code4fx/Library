//+------------------------------------------------------------------+
//|                                                  ExitManager.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Arrays/List.mqh>
#include <System_Templates/DataObject.mqh>

input group "//=== TRADE EXIT SETTINGS"

enum ENUM_SLTP_MANAGEMENT {
    SERVER_SIDE, //Server
    CLIENT_SIDE, //Client
};

enum ENUM_LOSS_EVASION {
    STOPLOSS, //Stop Loss
    GRIDREC, //Grid Recovery
};

enum ENUM_TRAILSTOP {
    ENABLE_TS, //Enable Trail Stop
    DISABLE_TS, //Disable Trail Stop
};

enum ENUM_DRAW {
    SHOW_LINES, //Show Exit Lines
    HIDE_LINES, //Hide Exit Lines
};

input ENUM_LOSS_EVASION InpLossEvasion = 0; //Loss Evasion
input ENUM_SLTP_MANAGEMENT InpSLManage = 0; //SL Management
input ENUM_SLTP_MANAGEMENT InpTPManage = 0; //TP Management
input ENUM_TRAILSTOP InpTSToggle = 0; //TrailStop Toggle
input ENUM_DRAW InpExitLines = 1; //Client Exit Lines

class CExitManager {

private:
    string symbol_;
    int sl_manager_;
    int tp_manager_;
    int ts_toggle_;
    
    int loss_evasion_;
    
    double bid_;
    double ask_;
    
    bool init_status_;
    
    int draw_;
    
    CTrade* trader_;

public:
    CExitManager(int magic_number, string symbol, int loss_evasion, int sl_manager, int tp_manager, int ts_togg) {
        initExitManager(magic_number, symbol, loss_evasion, sl_manager, tp_manager, ts_togg);
    }
    ~CExitManager() { delete trader_; }
    void setInitStatus(bool init_result) { init_status_ = init_result; }
    bool getInitStatus() { return init_status_; }
    int getTSStatus() { return ts_toggle_; }
    int getSLManage() { return sl_manager_; }
    void setAsk(double ask) { ask_ = ask; }
    void setBid(double bid) { bid_ = bid; }
    double getBid() { return bid_; }
    double getAsk() { return ask_; }
    bool initExitManager(int magic_no, string symbol, int loss_av, int sl_manager, int tp_manager, int ts_togg);
    void exitManager(CList *list);
    
    double getSL(double sl);
    double getTP(double tp);
    
    void lossEvasion(ulong pos_id, int type, double sl, double tp);
    void stopLossExit(ulong pos_id, int type, double sl);
    void takeProfitExit(ulong pos_id, int type, double tp);
    
    void draw(ulong pos_id, string exit_type, double val, color clr=clrGray);
    void redraw(ulong pos_id, string exit_type, double val);
    void erase(ulong pos_id, string exit_type);
    bool chartFind(long &chart_id);
    bool objectFind(string obj_name);
};

bool CExitManager::initExitManager(int magic_number, string symbol, int loss_evasion, int sl_manager, int tp_manager,
                                    int ts_toggle) {
    
    symbol_ = symbol;
    loss_evasion_ = loss_evasion;
    sl_manager_ = sl_manager;
    tp_manager_ = tp_manager;
    ts_toggle_ = ts_toggle;
    
    trader_ = new CTrade();
    trader_.SetExpertMagicNumber(magic_number);
    
    setInitStatus(true);
    return true;
}

void CExitManager::exitManager(CList *list) {

    setAsk(SymbolInfoDouble(symbol_, SYMBOL_ASK));
    setBid(SymbolInfoDouble(symbol_, SYMBOL_BID));
    
    for (CDataObject *curr = list.GetFirstNode(); curr != NULL; curr = list.GetNextNode()) {
        takeProfitExit(curr.position_id, curr.position_type, curr.take_profit);
        lossEvasion(curr.position_id, curr.position_type, curr.final_stoploss, curr.take_profit);
    }
}

void CExitManager::lossEvasion(ulong pos_id, int type, double new_sl, double tp) {

    if (sl_manager_ == SERVER_SIDE) {
    
        bool selected = PositionSelectByTicket(pos_id);
        double curr_sl = PositionGetDouble(POSITION_SL);
        double curr_tp = PositionGetDouble(POSITION_TP);
        double point = SymbolInfoDouble(symbol_, SYMBOL_POINT);
        long stop_level = SymbolInfoInteger(symbol_, SYMBOL_TRADE_STOPS_LEVEL);
        
        if (new_sl > 0 && selected &&  curr_sl != new_sl) {
            if (type == POSITION_TYPE_BUY) {
                if (new_sl < getBid() + (stop_level * point))
                    trader_.PositionModify(pos_id, new_sl, tp);
            }
            else if (type == POSITION_TYPE_SELL) {
                if (new_sl > getAsk() + (stop_level * point))
                    trader_.PositionModify(pos_id, new_sl, tp);
            }
        }
    }
    else {
        switch (loss_evasion_) {
            case STOPLOSS: {
                stopLossExit(pos_id, type, new_sl);
            } break;
            case GRIDREC: {
                
            } break;
        }
    }
}

void CExitManager::stopLossExit(ulong pos_id, int type, double sl) {

    if (sl_manager_ == SERVER_SIDE || sl <= 0)
        return;
    
    switch(type) {
        case POSITION_TYPE_BUY: {
            if (getBid() <= sl) {
                trader_.PositionClose(pos_id);
            }
        } break;
        case POSITION_TYPE_SELL: {
            if (getAsk() >= sl) {
                trader_.PositionClose(pos_id);
            }
        } break;
    }
}

void CExitManager::takeProfitExit(ulong pos_id, int type, double tp) {

    if (tp_manager_ == SERVER_SIDE || tp <= 0)
        return;
        
    switch(type) {
        case POSITION_TYPE_BUY: {
            if (getBid() >= tp) {
                trader_.PositionClose(pos_id);
            }
        } break;
        case POSITION_TYPE_SELL: {
            if (getAsk() <= tp) {
                trader_.PositionClose(pos_id);
            }
        } break;
    }
}

void CExitManager::draw(ulong pos_id, string exit_type, double val, color clr=clrGray) {

    if (getSLManage() == SERVER_SIDE || val <= 0)
        return;

    long chart_id = 0;
    
    if (!chartFind(chart_id))
        return;
        
    string obj_name; 
    StringConcatenate(obj_name, IntegerToString(pos_id), "_", exit_type);
    
    if (ObjectFind(chart_id, obj_name) > 0) {
        ObjectDelete(chart_id, obj_name);
    }
        
    if (ObjectCreate(chart_id, obj_name, OBJ_HLINE, 0, 0, val)) {
        ObjectSetInteger(chart_id, obj_name, OBJPROP_STYLE, STYLE_DASHDOT);
        ObjectSetInteger(chart_id, obj_name, OBJPROP_COLOR, clr);
    }
    
}

void CExitManager::redraw(ulong pos_id, string exit_type, double val) {

    if (getSLManage() == SERVER_SIDE || val <= 0)
        return;
        
    long chart_id;
    
    if (!chartFind(chart_id))
        return;
    
    string obj_name; 
    StringConcatenate(obj_name, IntegerToString(pos_id), "_", exit_type);
    
    if (ObjectFind(chart_id, obj_name) < 0)
        return;
    
    ObjectMove(chart_id, obj_name, 0, 0, val);
}

void CExitManager::erase(ulong pos_id, string exit_type) {

    if (getSLManage() == SERVER_SIDE)
        return;
    
    long chart_id;
    
    if (!chartFind(chart_id))
        return;

    string obj_name; 
    StringConcatenate(obj_name, IntegerToString(pos_id), "_", exit_type);
    
    if (ObjectFind(chart_id, obj_name) < 0)
        return;
        
    ObjectDelete(chart_id, obj_name);
}

bool CExitManager::chartFind(long &id) {
    for (long curr = ChartFirst(); curr != -1; curr = ChartNext(curr)) {
        if (ChartSymbol(curr) == symbol_) {
            id = curr;
            return true;
        }
    }
    return false;
}

double CExitManager::getSL(double sl) {
    if (sl_manager_ == SERVER_SIDE)
        return sl;
    return 0;
}

double CExitManager::getTP(double tp) {
    if (tp_manager_ == SERVER_SIDE)
        return tp;
    return 0;
}
