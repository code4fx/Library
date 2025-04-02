//###<Template_System.mq5>
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
#include <Library/DataObject.mqh>

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
    string m_symbol;
    int m_sl_manager;
    int m_tp_manager;
    int m_ts_toggle;
    
    int m_loss_evasion;
    
    double m_bid;
    double m_ask;
    
    bool m_init_status;
    
    int m_draw;
    
    CTrade* m_trader;

public:
    CExitManager(int magic_number, string symbol, int loss_evasion, int sl_manager, int tp_manager, int ts_togg) {
        InitExitManager(magic_number, symbol, loss_evasion, sl_manager, tp_manager, ts_togg);
    }
    ~CExitManager() { delete m_trader; }
    void SetInitStatus(bool init_result) { m_init_status = init_result; }
    bool GetInitStatus() { return m_init_status; }
    int GetTSStatus() { return m_ts_toggle; }
    int GetSLManage() { return m_sl_manager; }
    void SetAsk(double ask) { m_ask = ask; }
    void SetBid(double bid) { m_bid = bid; }
    double GetBid() { return m_bid; }
    double GetAsk() { return m_ask; }
    bool InitExitManager(int magic_no, string symbol, int loss_av, int sl_manager, int tp_manager, int ts_togg);
    void ExitManager(CList *list);
    
    double GetSL(double sl);
    double GetTP(double tp);
    
    void LossEvasion(ulong pos_id, int type, double sl, double tp);
    void StopLossExit(ulong pos_id, int type, double sl);
    void TakeProfitExit(ulong pos_id, int type, double tp);
    
    void Draw(ulong pos_id, string exit_type, double val, color clr=clrGray);
    void Redraw(ulong pos_id, string exit_type, double val);
    void Erase(ulong pos_id, string exit_type);
    bool ChartFind(long &chart_id);
    bool CbjectFind(string obj_name);
};

bool CExitManager::InitExitManager(int magic_number, string symbol, int loss_evasion, int sl_manager, int tp_manager,
                                    int ts_toggle) {
    
    m_symbol = symbol;
    m_loss_evasion = loss_evasion;
    m_sl_manager = sl_manager;
    m_tp_manager = tp_manager;
    m_ts_toggle = ts_toggle;
    
    m_trader = new CTrade();
    m_trader.SetExpertMagicNumber(magic_number);
    
    SetInitStatus(true);
    return true;
}

void CExitManager::ExitManager(CList *list) {

    SetAsk(SymbolInfoDouble(m_symbol, SYMBOL_ASK));
    SetBid(SymbolInfoDouble(m_symbol, SYMBOL_BID));
    
    for (CDataObject *curr = list.GetFirstNode(); curr != NULL; curr = list.GetNextNode()) {
        TakeProfitExit(curr.position_id, curr.position_type, curr.take_profit);
        LossEvasion(curr.position_id, curr.position_type, curr.final_stoploss, curr.take_profit);
    }
}

void CExitManager::LossEvasion(ulong pos_id, int type, double new_sl, double tp) {

    if (m_sl_manager == SERVER_SIDE) {
    
        bool selected = PositionSelectByTicket(pos_id);
        double curr_sl = PositionGetDouble(POSITION_SL);
        double curr_tp = PositionGetDouble(POSITION_TP);
        double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        long stop_level = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
        
        if (new_sl > 0 && selected &&  curr_sl != new_sl) {
            if (type == POSITION_TYPE_BUY) {
                if (new_sl < GetBid() + (stop_level * point))
                    m_trader.PositionModify(pos_id, new_sl, tp);
            }
            else if (type == POSITION_TYPE_SELL) {
                if (new_sl > GetAsk() + (stop_level * point))
                    m_trader.PositionModify(pos_id, new_sl, tp);
            }
        }
    }
    else {
        switch (m_loss_evasion) {
            case STOPLOSS: {
                StopLossExit(pos_id, type, new_sl);
            } break;
            case GRIDREC: {
                
            } break;
        }
    }
}

void CExitManager::StopLossExit(ulong pos_id, int type, double sl) {

    if (m_sl_manager == SERVER_SIDE || sl <= 0)
        return;
    
    switch(type) {
        case POSITION_TYPE_BUY: {
            if (GetBid() <= sl) {
                m_trader.PositionClose(pos_id);
            }
        } break;
        case POSITION_TYPE_SELL: {
            if (GetAsk() >= sl) {
                m_trader.PositionClose(pos_id);
            }
        } break;
    }
}

void CExitManager::TakeProfitExit(ulong pos_id, int type, double tp) {

    if (m_tp_manager == SERVER_SIDE || tp <= 0)
        return;
        
    switch(type) {
        case POSITION_TYPE_BUY: {
            if (GetBid() >= tp) {
                m_trader.PositionClose(pos_id);
            }
        } break;
        case POSITION_TYPE_SELL: {
            if (GetAsk() <= tp) {
                m_trader.PositionClose(pos_id);
            }
        } break;
    }
}

void CExitManager::Draw(ulong pos_id, string exit_type, double val, color clr=clrGray) {

    if (GetSLManage() == SERVER_SIDE || val <= 0)
        return;

    long chart_id = 0;
    
    if (!ChartFind(chart_id))
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

void CExitManager::Redraw(ulong pos_id, string exit_type, double val) {

    if (GetSLManage() == SERVER_SIDE || val <= 0)
        return;
        
    long chart_id;
    
    if (!ChartFind(chart_id))
        return;
    
    string obj_name; 
    StringConcatenate(obj_name, IntegerToString(pos_id), "_", exit_type);
    
    if (ObjectFind(chart_id, obj_name) < 0)
        return;
    
    ObjectMove(chart_id, obj_name, 0, 0, val);
}

void CExitManager::Erase(ulong pos_id, string exit_type) {

    if (GetSLManage() == SERVER_SIDE)
        return;
    
    long chart_id;
    
    if (!ChartFind(chart_id))
        return;

    string obj_name; 
    StringConcatenate(obj_name, IntegerToString(pos_id), "_", exit_type);
    
    if (ObjectFind(chart_id, obj_name) < 0)
        return;
        
    ObjectDelete(chart_id, obj_name);
}

bool CExitManager::ChartFind(long &id) {
    for (long curr = ChartFirst(); curr != -1; curr = ChartNext(curr)) {
        if (ChartSymbol(curr) == m_symbol) {
            id = curr;
            return true;
        }
    }
    return false;
}

double CExitManager::GetSL(double sl) {
    if (m_sl_manager == SERVER_SIDE)
        return sl;
    return 0;
}

double CExitManager::GetTP(double tp) {
    if (m_tp_manager == SERVER_SIDE)
        return tp;
    return 0;
}
