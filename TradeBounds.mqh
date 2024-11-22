//+------------------------------------------------------------------+
//|                                              TradeConditions.mqh |
//|                                                Copyright 2022, . |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, ."
#property link      "https://www.mql5.com"
#include "TradeBoundSel.mqh"
// Sets conditions to block trades based on
// Time
// Number of trades
// Spread
// Events 
// etc.

class CTradeBounds {
    private:
        string symbol_;
        bool init_status_;
        int max_trades_;
        int max_spread_;
        int start_hour_;
        int start_minutes_;
        int end_hour_;
        int end_minutes_;
        int total_start_min_;
        int total_end_min_;
        bool use_time_range_;
        int group_exit_;
        
    public:
        CTradeBounds() {}
        CTradeBounds(string symbol,
                        int max_trades,
                        int group_exit,
                        int max_spread,
                        int start_hour,
                        int start_minutes,
                        int end_hour,
                        int end_minutes) {
            initTradeBounds(symbol, max_trades, group_exit,
                            max_spread, start_hour, start_minutes, 
                            end_hour, end_minutes);        
        }
        CTradeBounds(BoundStruct &struc) {
            initTradeBounds(struc.symbol, struc.max_trades, struc.group_exit, 
                            struc.max_spread, struc.start_hour, struc.start_min, 
                            struc.end_hour, struc.end_min);       
        }
        ~CTradeBounds() {}
        
        bool initTradeBounds(string symbol,
                                int max_trades,
                                int group_exit,
                                int max_spread,
                                int start_hour,
                                int start_minutes,
                                int end_hour,
                                int end_minutes) {
                                
            symbol_ = symbol;
            max_trades_ = max_trades;
            group_exit_ = group_exit;
            max_spread_ = max_spread;
            start_hour_ = start_hour;
            start_minutes_ = start_minutes;
            end_hour_ = end_hour;
            end_minutes_ = end_minutes;
            total_start_min_ = (start_hour * 60 + start_minutes);
            total_end_min_ = (end_hour * 60 + end_minutes);
            use_time_range_ = (total_start_min_ != total_end_min_);
            
            setInitStatus(true);
            
            return true;
        }
        
        bool limit(int trade_count);
        bool insideTimeRange(datetime now);
        int timeToMinutes(datetime time);
        int getGroupExitSet() { return group_exit_; }
        bool belowMaxSpread();
        bool belowTradeCount(int count);
        void setInitStatus(bool init_result) { init_status_ = init_result; }
        bool getInitStatus() { return init_status_; }
};

bool CTradeBounds::belowMaxSpread() {
    if (max_spread_ == -1)
        return true;
    int spread = (int)SymbolInfoInteger(symbol_, SYMBOL_SPREAD);
    if (spread <= max_spread_)
        return true;
    return false;
}

bool CTradeBounds::belowTradeCount(int count) {
    if (max_trades_ == -1)
        return true;
    if (count < max_trades_)
        return true;
    return false;
}

bool CTradeBounds::limit(int trade_count) {
    bool limit = true;
    
    limit = limit && insideTimeRange(TimeCurrent());
    limit = limit && belowMaxSpread();
    limit = limit && belowTradeCount(trade_count);
    
    return limit;    
}

int CTradeBounds::timeToMinutes(datetime time) {
    MqlDateTime mtime;
    TimeToStruct (time, mtime);
    return (mtime.hour * 60 + mtime.min);
}


bool CTradeBounds::insideTimeRange(datetime now) {
      
    if (!use_time_range_) 
        return true;
        
    int nowMinutes = timeToMinutes(now);
    
    return ((total_start_min_ <= nowMinutes && nowMinutes < total_end_min_) ||
            ((total_start_min_ > total_end_min_ ) &&
             (nowMinutes > total_start_min_ || nowMinutes < total_end_min_)));
}