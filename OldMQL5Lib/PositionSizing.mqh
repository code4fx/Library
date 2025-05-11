//+------------------------------------------------------------------+
//|                                              CPositionSizing.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "ErrorDescriptions.mqh"

enum enum_lot_sizing_mode {
    MANUAL, //Manual
    AUTO, //Auto
};

enum enum_percent_of {
    BALANCE, //Balance
    EQUITY, //Equity
    MARGIN, //Margin (Margin Call Limit)
};

input group "//=== POSITION SIZING"
input enum_lot_sizing_mode InpMode = AUTO; //Lot Sizing Mode
input enum_percent_of InpRiskBase = BALANCE; //Risk Basis
input double InpPercentage = 1.00; //Risk Percentage (%)
input double InpManualLots = 0.01; //Manual Lot Size (Micro Lots)

class CPositionSizing {
    private:
        string m_symbol;
        double m_manual_lots;
        int m_lt_mode;
        int m_risk_base;
        double m_risk_percent;
      
        bool m_init_status;
    
    protected:
        double GetPointValue();
    
    public: 
         CPositionSizing() {}
         CPositionSizing(string symbol, int lt_mode, int risk_base, double risk_percent, double manual_lots);
        ~CPositionSizing() {}
        
        // Getters
        string GetSymbol() { return m_symbol; }
        double GetManualLots() { return m_manual_lots; }
        int GetLtMode() { return m_lt_mode; }
        int GetRiskBase() { return m_risk_base; }
        double GetRiskPercent() { return m_risk_percent; }
        
        // Setters
        void SetSymbol(string value) {
            bool is_custom;
            if (SymbolExist(value, is_custom)) {
                m_symbol = value;
            } else {
                SetInitStatus(false);
                print_init_error("Invalid symbol.", __FUNCTION__);
            }
             
        }
        void SetManualLots(double value) {
            m_manual_lots = NormalizeDouble(value, 2);  
        }
        void SetLtMode(int value) { m_lt_mode = value; }
        void SetRiskBase(int value) { m_risk_base = value; }
        void SetRiskPercent(double value) {
           if (value >= 0 && value <= 100) {
              m_risk_percent = value;
           } else {
              SetInitStatus(false);
              print_init_error("Invalid risk percentage value.", __FUNCTION__);
           }
        }
        
        bool InitPositionSizing(string symbol, int lt_mode, int risk_base, double risk_percent, double manual_lots);
        
        double CalcRiskAmount(double lot_size, double risk_points);
        double CalcRiskPoints(double lot_size, double risk_amount);
        double CalcLotSize(double risk_amount, double risk_points);
        double GetPositionSize(double risk_size=0);
        double GetRiskAmount();
        double GetStopOutLevel();
        void Display();
        
        
        void SetInitStatus(bool init_result) { m_init_status = init_result; }
        bool GetInitStatus() { return m_init_status; }
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPositionSizing::CPositionSizing(string symbol, int lt_mode, int risk_base, double risk_percent, double manual_lots) {
    InitPositionSizing(symbol, lt_mode, risk_base,  risk_percent, manual_lots);
}

//+------------------------------------------------------------------+
//|Initialize this classes' object
//+------------------------------------------------------------------+
bool CPositionSizing::InitPositionSizing(string symbol, int lt_mode, int risk_base, double risk_percent, double manual_lots) {
    
    SetInitStatus(true);
    
    SetSymbol(symbol);
    SetManualLots(manual_lots);
    SetLtMode(lt_mode);
    SetRiskBase(risk_base);
    SetRiskPercent(risk_percent);
    
    return GetInitStatus();
}

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Calculate the value of 1 point for one lot in base currency
//+------------------------------------------------------------------+
double CPositionSizing::GetPointValue(void) {

    //normally tick size is 1 point.
    double tick_size = SymbolInfoDouble(GetSymbol(), SYMBOL_TRADE_TICK_SIZE);
    
    //tick_value is how much 1 tick is worth in base currency.
    //tick_value changes often.
    double tick_value = SymbolInfoDouble(GetSymbol(), SYMBOL_TRADE_TICK_VALUE);
    
    double point = SymbolInfoDouble(GetSymbol(), SYMBOL_POINT);
    
    //tick_per_point is how many ticks make up 1 point for the current symbol.
    double tick_per_point = tick_size / point;
    
    double point_value = tick_value / tick_per_point;
    
    return  point_value;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CPositionSizing::CalcRiskAmount(double lot_size, double risk_points) {

    double risk_amount = 0.0;
    double point_value = GetPointValue();
    
    if (lot_size <= 0) {
        print_error("Invalid lot size.", __FUNCTION__);
    }
    else {
       risk_amount = point_value *  lot_size * risk_points;
       risk_amount = NormalizeDouble(risk_amount, 2); 
    }
    
    return risk_amount;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CPositionSizing::CalcRiskPoints(double lot_size, double risk_amount) {

    double risk_points = 0.0;
    double point_value =GetPointValue();
    double lot_size_value = point_value * lot_size;
    
    if (lot_size_value <= 0) {
        print_error("Invalid lot size.", __FUNCTION__);
    }
    else {
        risk_points = risk_amount / lot_size_value;
        risk_points = NormalizeDouble(risk_points, 2);
    }
    
    return risk_points; 
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CPositionSizing::CalcLotSize(double risk_amount, double risk_points) {

    double lot_size = 0.0;
    double point_value = GetPointValue();
    double new_point_value = point_value * risk_points;
    
    if (new_point_value <= 0) {
       print_error("Invalid risked points (price - stoploss).", __FUNCTION__);
       Print("Switched to manual lot size.");
       lot_size = GetManualLots();
    }
    else {
       lot_size = risk_amount / new_point_value;
       lot_size = NormalizeDouble(lot_size, 2);
    }
    
    return lot_size;
}

double CPositionSizing::GetRiskAmount(void) {

    double risk_amount = 0;
    
    switch (GetRiskBase()) {
        case BALANCE: {
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            risk_amount = (balance * GetRiskBase()) / 100;
        } break;
        case EQUITY: {
            double equity = AccountInfoDouble(ACCOUNT_EQUITY);
            risk_amount = (equity * GetRiskBase()) / 100;
        } break;
        case MARGIN: {
            double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
            risk_amount = (free_margin * GetRiskBase()) / 100;
        } break;
    }
    
    return risk_amount;
}

double CPositionSizing::GetPositionSize(double points_at_risk) {

    double size = 0;
    
    switch (GetLtMode()) {
        case MANUAL: {
            size = GetManualLots();
        } break;
        case AUTO: {
            if (points_at_risk != 0) {
                double amount_at_risk = GetRiskAmount();
                size = CalcLotSize(amount_at_risk, points_at_risk);  
            }
            else {
                size = GetManualLots();
            }
        } break;
    }
    
    return size;
}

double CPositionSizing::GetStopOutLevel() {

    double stopOut = 0;
    double marginStopOut = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
    ENUM_ACCOUNT_STOPOUT_MODE soMode = 
        (ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if (soMode == ACCOUNT_STOPOUT_MODE_PERCENT) {
        stopOut = equity * marginStopOut/100;
    }
    else {
        stopOut = marginStopOut;
    }
    
    return stopOut;
}

