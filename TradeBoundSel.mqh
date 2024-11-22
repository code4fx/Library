//+------------------------------------------------------------------+
//|                                              TradeConditions.mqh |
//|                                                Copyright 2022, . |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, ."
#property link      "https://www.mql5.com"
#include <System_Templates/ErrorDescriptions.mqh>

// Sets conditions to block trades based on
// Time
// Number of trades
// Spread
// Events 
// etc.



input group "//=== TRADE BOUNDS"

sinput string tbdefaults; //--- DEFAULTS ---

input int InpMaxTrades = 1; //Max Trades (Infinite = -1)
input int InpMaxSpread = -1; //Max Spread (Infinite = -1)
input string InpTime = "00:00-23:59"; //Trading Time (HH:MM-HH:MM) [24hr]

sinput string tbpersymbol; //--- PER SYMBOL ---
sinput string tbformat; //--- Format: AAA->{DD; DD; HH:MM-HH:MM}, ...
sinput string tbexample; //--- E.g. EUR*** => USD->{1; 38; 00:00-23:59}, JPY->...

input string InpAUDtb = ""; //AUD*** =>
input string InpCADtb = ""; //CAD*** =>
input string InpCHFtb = ""; //CHF*** =>
input string InpEURtb = ""; //EUR*** =>
input string InpGBPtb = ""; //GBP*** =>
input string InpNZDtb = ""; //NZD*** =>
input string InpUSDtb = ""; //USD*** =>

struct BoundStruct {
  string symbol;
  int start_hour;
  int start_min;
  int end_hour;
  int end_min;
  int max_trades;
  int max_spread;
  int group_exit;
  
};

class CTradeBoundSel {
    private:
        int max_trades_;
        int max_spread_;
        int start_hour_;
        int start_minutes_;
        int end_hour_;
        int end_minutes_;
        
        BoundStruct symbol_details[];
        int sdArrSize;
        
        string symbol_postfix_;
          
    public:
        CTradeBoundSel() {}
        CTradeBoundSel(int max_trades,
                            int max_spread,
                            string time,
                            string AUD_,
                            string CAD_,
                            string CHF_,
                            string EUR_,
                            string GBP_,
                            string NZD_,
                            string USD_) {
            initTradeBoundSel(max_trades, max_spread, time,
                            AUD_, CAD_, CHF_, EUR_,
                            GBP_, NZD_, USD_);
        }
        ~CTradeBoundSel() { ArrayFree(symbol_details); }
        
        bool initTradeBoundSel(int max_trades,
                                int max_spread,
                                string time,
                                string AUD_,
                                string CAD_,
                                string CHF_,
                                string EUR_,
                                string GBP_,
                                string NZD_,
                                string USD_) {
                                
            bool result = true;
            
            sdArrSize = 0;
            max_spread_ = max_spread; 
            max_trades_ = max_trades;
            timeInpValidation(time, start_hour_, start_minutes_, end_hour_, end_minutes_);
            
            result = result && parseSelectorInp("AUD", AUD_);
            result = result && parseSelectorInp("CAD", CAD_);
            result = result && parseSelectorInp("CHF", CHF_);
            result = result && parseSelectorInp("EUR", EUR_);
            result = result && parseSelectorInp("GBP", GBP_);
            result = result && parseSelectorInp("NZD", NZD_);
            result = result && parseSelectorInp("USD", USD_);
            
            return result;
        }
        
        bool timeInpValidation(string str, 
                                int &start_hours, 
                                int &start_minutes,
                                int &end_hours,
                                int &end_minutes);
        bool intInpValidation(string text, int min, int max, int &value);
        bool parseSelectorInp(string base, string str);
        bool parseValues(string in, string &quote, string &max_trades, string &max_spread, string &time); //
        bool symbolValidation(string base, string quotes, string &symbol);
        bool procSymbolInputs(string symbol);
        void stringTrim(string &str) { 
            StringTrimRight(str);StringTrimLeft(str);StringReplace(str, " ", "");
        }
        BoundStruct getSymbolParams(string symbol, bool &success);
};

BoundStruct CTradeBoundSel::getSymbolParams(string symbol, bool &success) {

    if (!procSymbolInputs(symbol))
        success = false;
    else
        success = true;
    
    for (int i = 0; i < sdArrSize; i++) {
        if (StringFind(symbol_details[i].symbol, symbol) != -1) {
            return symbol_details[i];
        }
    }
    
    BoundStruct new_details;
    
    new_details.symbol = symbol;
    new_details.max_trades = max_trades_;
    new_details.max_spread = max_spread_;
    new_details.start_hour = start_hour_;
    new_details.start_min = start_minutes_;
    new_details.end_hour = end_hour_;
    new_details.end_min = end_minutes_;
    
    return new_details;
}

bool CTradeBoundSel::parseValues(string in, string &quote, string &max_trades, string &max_spread, string &time) {
    
    string resultArr[], values[];
    
    stringTrim(in);
    
    if (StringReplace(in, "->", ">") == -1) {
        return false;
    }
    
    if (StringSplit(in, (ushort)'>', resultArr) != 2) {
        return false;
    }
    
    quote = resultArr[0];
    
    StringReplace(resultArr[1], "{", "");
    StringReplace(resultArr[1], "}", "");
    
    if (StringSplit(resultArr[1], (ushort)';', values) != 3) {
        return false;
    }
    
    max_trades = values[0];
    max_spread = values[1];
    time = values[2];
    
    return true;
}

bool CTradeBoundSel::parseSelectorInp(string base, string str) {
    
    if(str == "") return true;
    
    string quotesArr[];
    int arrLen = StringSplit(str, (ushort)',', quotesArr);
    
    string quote, max_trades, max_spread, time, symbol;
    int max_spreadInt, max_tradesInt;
    int s_hour, s_min, e_hour, e_min;
    bool result = true;
    
    for (int i = 0; i < arrLen; i++) {
        result = result && parseValues(quotesArr[i], quote, max_trades, max_spread, time);
        result = result && symbolValidation(base, quote, symbol);//
        result = result && intInpValidation(max_spread, 0, 99, max_spreadInt);
        result = result && intInpValidation(max_trades, 0, 99, max_tradesInt);
        result = result && timeInpValidation(time, s_hour, s_min, e_hour, e_min);
        
        if (!result) {
            print_error("unexpected input: "+quotesArr[i], __FUNCTION__);
            return false;
        }
        
        ArrayResize(symbol_details, sdArrSize + 1);
        sdArrSize++;
        symbol_details[sdArrSize-1].symbol = symbol;
        symbol_details[sdArrSize-1].start_hour = s_hour;
        symbol_details[sdArrSize-1].start_min = s_min;
        symbol_details[sdArrSize-1].end_hour = e_hour;
        symbol_details[sdArrSize-1].end_min = e_hour;
        symbol_details[sdArrSize-1].max_spread = max_spreadInt;
        symbol_details[sdArrSize-1].max_trades = max_tradesInt;
    }
    
    return true;
}

bool CTradeBoundSel::timeInpValidation(string str, 
                                            int &start_hours, 
                                            int &start_minutes,
                                            int &end_hours,
                                            int &end_minutes) {
        
    string timeValues[], startParts[], endParts[];
    string startTime, endTime;
    bool c1, c2;
    
    start_hours = 0;
    start_minutes = 0;
    end_hours = 0;
    end_minutes = 0;
    
    stringTrim(str);
    
    if (StringLen(str) != 11 || StringSplit(str, (ushort)'-', timeValues) != 2) {
        return false;
    }
    
    startTime = timeValues[0];
    endTime = timeValues[1];
    
    if ((StringLen(startTime) != 5 || StringSplit(startTime, (ushort)':', startParts) != 2)) {
        return false;
    }
    
    if ((StringLen(endTime) != 5 || StringSplit(endTime, (ushort)':', endParts) != 2)) {
        return false;
    }
    
    c1 = intInpValidation(startParts[0], 0, 23, start_hours);
    c2 = intInpValidation(startParts[1], 0, 59, start_minutes);
    
    if (!c1 || !c2) {
        return false;
    }
    
    c1 = intInpValidation(endParts[0], 0, 23, end_hours);
    c2 = intInpValidation(endParts[1], 0, 59, end_minutes);
    
    if (!c1 || !c2) {
        return false;
    }

    return true;
}

bool CTradeBoundSel::intInpValidation(string text, int min, int max, int &value) {

    value = (int)StringToInteger(text);
    
    if (value < min || value > max)
        return false;
        
    string test = IntegerToString(value);
    
    if (StringLen(text) > StringLen(test)) {
        string zero;
        StringInit(zero, StringLen(text) - StringLen(test), '0');
        test = zero + test;
    }
    
    return (test == text); // Make sure the round trip gives the same result
}

bool CTradeBoundSel::symbolValidation(string base, string quote, string &symbol) {
    
    string temp = base + quote;
    bool result = false;
    symbol = temp;
    
    string forex_symbols[] = {
      "AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD",
      "CADCHF","CADJPY",
      "CHFJPY",
      "EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD","EURUSD",
      "GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD",
      "NZDCAD","NZDCHF","NZDJPY","NZDUSD",
      "USDCAD","USDCHF","USDJPY"
    };
    
    int size = ArraySize(forex_symbols);
    
    for (int i = 0; i < size; i++) {
        if (forex_symbols[i] == temp) {
            return true;
        }
    }
    
    return result;
}

bool CTradeBoundSel::procSymbolInputs(string symbol) {

    bool isCustom;
    if (!SymbolExist(symbol, isCustom)) {
        print_error(symbol+" does not exist", __FUNCTION__);
        return false;
    }
    
    if (!SymbolSelect(symbol, true)) {
        print_error("cannot select "+symbol, __FUNCTION__);
        return false;
    }
    
    return true;    
}



