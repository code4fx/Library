//+------------------------------------------------------------------+
//|                                              GobalDictionary.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

enum enum_capital_type {
  Account_Balance,
  Account_Equity,
  Account_Margin,
};

enum enum_lot_type {
  Standard,
  Mini,
  Micro,
};

enum enum_pos_sizing {
  Auto,
  Manual,
};

enum enum_custom_metric {
  None,
  Normalized_Profit_Factor,
  System_Quality_Number,
  R_Multiple_Expectancy,
  CAGR_Mean_Drawdown,
  Coefficient_Correlation,
};

string timeframeToString(int tf) {

   string response = "";

    switch(tf) {
      case PERIOD_CURRENT:
         response += "CURRENT";
         break;
      case PERIOD_M1:
         response += "M1";
         break;
      case PERIOD_M5:
         response += "M5";
         break;
      case PERIOD_M15:
         response += "M15";
         break;
      case PERIOD_M30:
         response += "M30";
         break;
      case PERIOD_H1:
         response += "H1";
         break;
      case PERIOD_H4:
         response += "H4";
         break;
      case PERIOD_D1:
         response += "D1";
         break;
      case PERIOD_W1:
         response += "W1";
         break;
      case PERIOD_MN1:
         response += "MN1";
         break;
   };
      
   return response;
}

int stringToTimeframe(string tf) {

   int response = 0;
   
   if(tf == "CURRENT") {
      response = PERIOD_CURRENT;
   }
   else if(tf == "M1") {
      response = PERIOD_M1;
   }
   else if(tf == "M5") {
      response = PERIOD_M5;
   }
   else if(tf == "M15") {
      response = PERIOD_M15;
   }
   else if(tf == "M30") {
      response = PERIOD_M30;
   }
   else if(tf == "H1") {
      response = PERIOD_H1;
   }
   else if(tf == "H4") {
      response = PERIOD_H4;
   }
   else if(tf == "D1") {
      response = PERIOD_D1;
   }
   else if(tf == "W1") {
      response = PERIOD_W1;
   }
   else if(tf == "MN1") {
      response = PERIOD_MN1;
   }
   
   return response;
}

string booleanToString(bool flag) {
   
   string str = "";
   
   if(flag) {
      str += "true";   
   }
   else {
      str += "false";
   }
   
   return str;
}

bool stringToBoolean(string str) {
   
   bool flag;
   
   if(str == "true") {
      flag = true;   
   }
   else {
      flag = false;
   }
   
   return flag;
}

string symbolCorrection(string symbol) {

   string currPair = Symbol();
   string finalSymbol = symbol;
   string currArr[] = {"AUD","CAD","CHF","EUR","GBP","JPY","NZD","USD","ZAR"};
   
   if(StringLen(currPair) > 6) {
      for(int i = 0; i < 9; i++) {
         StringReplace(currPair, currArr[i], "");
      }
      finalSymbol += currPair;
   }
   
   return finalSymbol;
}

double validateLotSize(string symbol, double ls) {
  
  double size = ls;
  
  if(ls < SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN)) {
     size = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
  }
  else if(ls > SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX)) {
    size = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
  }

  return size;
}

double validateStopLevel(string symbol, double stoploss_points) {
  
  double sl = stoploss_points;
  
  if(stoploss_points < (double)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)) {
    sl = (double)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
  }
  
  return sl;
}

void drawVline(int shift, color c) {

   bool drawn = false, modified = false;
      
   datetime currentTime = iTime(Symbol(), PERIOD_CURRENT, shift);
   int time = (int)currentTime;
      
   drawn = ObjectCreate(ChartID(), "openCandleVS"+(string)time, OBJ_VLINE, 0, currentTime, 0);
   modified = ObjectSetInteger(ChartID(), "openCandleVS"+(string)time, OBJPROP_COLOR, c);
   modified = ObjectSetInteger(ChartID(), "openCandleVS"+(string)time, OBJPROP_STYLE, STYLE_DOT);
}

void drawHline(double price, color c) {
  
  bool drawn = false, modified = false;
  
  drawn = ObjectCreate(ChartID(), "openCandleHS"+(string)price, OBJ_HLINE, 0, 0, price);
  modified = ObjectSetInteger(ChartID(), "openCandleHS"+(string)price, OBJPROP_COLOR, c);
}

void drawVline(datetime dtime, color c) {

   bool drawn = false, modified = false;
      
   datetime currentTime = dtime;
   int time = (int)currentTime;
      
   drawn = ObjectCreate(ChartID(), "openCandleVS"+(string)time, OBJ_VLINE, 0, currentTime, 0);
   modified = ObjectSetInteger(ChartID(), "openCandleVS"+(string)time, OBJPROP_COLOR, c);
}

double convDatetimeToHours(datetime dt) {
  
  MqlDateTime dtime;
  
  TimeToStruct(dt, dtime);
  
  double day_hours = (dtime.day - 1) * 24;
  double hours = dtime.hour;
  double minute_hours = dtime.min / 60.0;
  
  return day_hours + hours + minute_hours;
}

double convDatetimeToYears(datetime dt) {
  
  MqlDateTime dtime;
  
  TimeToStruct(dt, dtime);
  
  double years = dtime.year - 1970;
  double year_months = (double)dtime.mon / 12.0;
  
  return NormalizeDouble((years + year_months), 3);
}

string symbols_arr[] = {
  "AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD",
  "CADCHF","CADJPY",
  "CHFJPY",
  "EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD","EURUSD",
  "GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD",
  "NZDCAD","NZDCHF","NZDJPY","NZDUSD",
  "USDCAD","USDCHF","USDJPY"
};

struct enum_strategy_parameters {
  string indicator_name;
  bool indicator_toggle;
  ENUM_TIMEFRAMES indicator_timeframe;
};

//+------------------------------------------------------------------+
//|Only Major and Minor pairs supported                              |
//+------------------------------------------------------------------+
double getCurrencyPrice(string strcurr) {
  
   string currArr[] = {"AUD","CAD","CHF","EUR","GBP","JPY","NZD","USD"};

   double result = 0.0;
   double price = 0.0;
   int i = 0;

   for(; i < 9; i++) {
      if(currArr[i] == strcurr)
         break;
   }
      
   switch(i) {
   case 0:
      result = midPrice("AUDUSD");
      break;
   case 1: {
      price = midPrice("USDCAD");
      if(price > 0) result = 1 / price;
   }  break;
   case 2: {
     price = midPrice("USDCHF");
     if(price > 0) result = 1 / price;
   } break;
   case 3:
      result = midPrice("EURUSD");
      break;
   case 4:
      result = midPrice("GBPUSD");
      break;
   case 5: {
      price = midPrice("USDJPY");
      if(price > 0) result = 1 / price;
   } break;
   case 6:
      result = midPrice("NZDUSD");
      break;
   case 7:
      result = 1;
      break;
   }

   return result;
}

double midPrice(string symbol) {

  string symbl = symbolCorrection(symbol);  

  if(SymbolSelect(symbl, true)) {
    double bid = SymbolInfoDouble(symbl, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbl, SYMBOL_ASK);
    
    return ((bid + ask) / 2);
  }
  else {
    return 0.0;
  }
}

double rateConversion(double price, string currency_from, string currency_to) {
  
  //double conv_to = getCurrencyPrice(currency_to);
  //double conv_from = getCurrencyPrice(currency_from);
  
  double conv_to = 1/getCurrencyPrice(currency_to);
  double conv_from = getCurrencyPrice(currency_from);
  
  //Print("AUD: "+conv_from);
  //Print("EUR: "+conv_to);
  
  double multiplier = conv_from * conv_to; 
  
  return price * multiplier;
}

//+------------------------------------------------------------------+
//| Converts a string to a base-10 number                            |
//+------------------------------------------------------------------+
ulong StringToBase10(const string &s) {
    ulong base10_number = 0;
    for (int i = 0; i < StringLen(s); i++) {
        base10_number = base10_number * 256 + StringGetCharacter(s, i);
    }
    return base10_number;
}

//+------------------------------------------------------------------+
//| Converts a base-10 number back to a string                       |
//+------------------------------------------------------------------+
string Base10ToString(ulong n) {
    string result = "";
    while (n > 0) {
        char c = (char)(n % 256);
        result = StringFormat("%c", c) + result;
        n /= 256;
    }
    return result;
}
