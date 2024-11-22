//###<Experts/Template_System/Template_System.mq5>

//+------------------------------------------------------------------+
//|                                                     CStrategy.mqh |
//|                                                Copyright 2022, . |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, ."
#property link      "https://www.mql5.com"

#include <System_Templates/ErrorDescriptions.mqh>
#include <System_Templates/KVArgsList.mqh>

enum ENUM_EXIT_MODE {
    EXIT_ALL, //Exit All
    FIFO, //FIFO
    LIFO, //LIFO
};

/**
 * CStrategy - Base class for all strategies
 * Allows for strategies to be easily switched during
 * run-time using polymorphism.
 * Allows for different instances of strategies to exist
 * e.g strategy indicator handle per symbol.
 * Strategies may declare their own handles for their
 * respective indicators
*/

class CStrategy {
    protected:
        string symbol_;
        ENUM_TIMEFRAMES timeframe_;
        bool init_status_;
        
    public:
        void setSymbol(string symbol) { symbol_ = symbol; }
        void setTimeframe(ENUM_TIMEFRAMES timeframe) { timeframe_ = timeframe; }
        string getSymbol() { return symbol_; }
        ENUM_TIMEFRAMES getTimeFrame() { return timeframe_; }
         
        virtual bool initStrategy(string symbol, ENUM_TIMEFRAMES timeframe, KVArgsList *args) = 0; 
        virtual int entrySignal(double &sl, double &tp) = 0;
        virtual int exitSignal(ENUM_EXIT_MODE &mode) = 0;
        virtual double getTrailStop(ENUM_POSITION_TYPE type) { return 0; };
        virtual int entryManager() { return 0; };
        virtual int exitManager() { return 0; };
        
        void setInitStatus(bool init_result) { init_status_ = init_result; }
        bool getInitStatus() { return init_status_; }
        virtual CStrategy* clone() = 0;
};
