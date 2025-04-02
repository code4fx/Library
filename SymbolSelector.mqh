//+------------------------------------------------------------------+
//|                                          Signal_Indicator_EA.mq4 |
//|                                    programmed by mojalefa nkwana | 
//|                       email: 5pitcb4qiq@privaterelay.appleid.com |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property link      "https://www.mql5.com"
#property strict
#include <Library/ErrorDescriptions.mqh>

//Only Forex pairs can be traded simultaneously.
//Therefore if a symbol is not forex, then this EA no longer supports multi symbol trading.
//Other Symbols like Indices, Commodities, etc. are only supported through 'Custom Symbol Input' or
//'Use Chart Symbol' by default.

enum ENUM_SYMBOLS_SELECT {
    CHART_PAIR, //Use Chart Symbol
    SELECT_ALL, //Use All Forex Symbols
    USE_SELECTION, //Use Forex Symbol Selector
    USE_CUSTOM, //Use Symbol Input
};

input group "//=== PAIR SELECTION"

input ENUM_SYMBOLS_SELECT InpSelectionMode = 0; //Symbol Selection Mode
input string InpCustomSymbol = ""; //Symbol Input
input string InpSymbolPostfix = ""; //Symbol Postfix (E.g '.ts')
sinput string ssselect; //--- FX SYMBOL SELECTOR ---
sinput string ssexample; //--- E.g. EUR*** => USD, JPY,...
input string InpAUD = ""; //AUD*** =>
input string InpCAD = ""; //CAD*** =>
input string InpCHF = ""; //CHF*** =>
input string InpEUR = ""; //EUR*** =>
input string InpGBP = ""; //GBP*** =>
input string InpNZD = ""; //NZD*** =>
input string InpUSD = ""; //USD*** =>

class CSymbolSelector {

    private:
        bool init_status_;
        string symbol_postfix_;
        
        string symbols_array[];
        
        void AddToArray(string str);
        bool ParseInputToArr(string base,string instr);
        int size;
        
    public:
   
        CSymbolSelector() {}
        CSymbolSelector(ENUM_SYMBOLS_SELECT selection_mode,
                        string symbol,
                        string postfix,
                        string AUD_,
                        string CAD_,
                        string CHF_,
                        string EUR_,
                        string GBP_,
                        string NZD_,
                        string USD_) {
            InitSymbolSelector(selection_mode, symbol, postfix,
                                AUD_, CAD_, CHF_, EUR_, GBP_,
                                  NZD_, USD_);                
        }
        ~CSymbolSelector() {ArrayFree(symbols_array);}
        int GetSize() {return size;}
        bool GetInitStatus() {return init_status_;}
        
        void SetSymbolPostfix(string str);
        bool ProcSymbolInputs(string symbol);
        string GetSymbolPostfix();
        
        int GetSymbolArray(string &arr[]);
        bool InitSymbolSelector(ENUM_SYMBOLS_SELECT selection_mode,
                                string custom_symbol,
                                string postfix,
                                string AUD_,
                                string CAD_,
                                string CHF_,
                                string EUR_,
                                string GBP_,
                                string NZD_,
                                string USD_);
                                     
};

bool CSymbolSelector::InitSymbolSelector(ENUM_SYMBOLS_SELECT selection_mode,
                                        string custom_symbol,
                                        string postfix,
                                        string AUD_,
                                        string CAD_,
                                        string CHF_,
                                        string EUR_,
                                        string GBP_,
                                        string NZD_,
                                        string USD_) {
    
    size = 0;
    bool result = false;
    SetSymbolPostfix(postfix);
    
    switch(selection_mode) {
        case 0: {//use chart symbol
            
            AddToArray(Symbol());
            result = true;
        
        } break;
        case 1: {//use all forex pairs
               
            string forex_symbols[] = {
              "AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD",
              "CADCHF","CADJPY",
              "CHFJPY",
              "EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD","EURUSD",
              "GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD",
              "NZDCAD","NZDCHF","NZDJPY","NZDUSD",
              "USDCAD","USDCHF","USDJPY"
            };
                    
            int lsize = ArraySize(forex_symbols);
            
            result = true;
            
            for(int i = 0; i < lsize; i++) {
                if(!ProcSymbolInputs(forex_symbols[i]+GetSymbolPostfix())) {
                    result = false;
                    break;
                }
                    
                AddToArray(forex_symbols[i]+GetSymbolPostfix());
            }
        } break;
        case 2: {//use selected symbols
        
            if(ParseInputToArr("AUD", AUD_) &&
                ParseInputToArr("CAD", CAD_) &&
                ParseInputToArr("CHF", CHF_) &&
                ParseInputToArr("EUR", EUR_) &&
                ParseInputToArr("GBP", GBP_) &&
                ParseInputToArr("NZD", NZD_) &&
                ParseInputToArr("USD", USD_)) {
                
                if(GetSize() < 1) {
                    print_error("No symbols input", __FUNCTION__);
                    result = false;
                }
                else
                    result = true;
            }
        } break;
        case 3: {//use custom symbol
            if(!ProcSymbolInputs(custom_symbol)) {
                result = false;
                break;
            }
            AddToArray(custom_symbol);
            result = true;
        } break;
    }
    
    init_status_ = result;
    
    return result;
}

void CSymbolSelector::SetSymbolPostfix(string str) {
    
    StringTrimLeft(str);
    StringTrimRight(str);
    StringReplace(str, " ", "");
    StringReplace(str, "'", "");
    symbol_postfix_ = str;

} 

bool CSymbolSelector::ProcSymbolInputs(string symbol) {

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

void CSymbolSelector::AddToArray(string str) {
    ArrayResize(symbols_array, size + 1);
    symbols_array[size++] = str;
}

bool CSymbolSelector::ParseInputToArr(string base, string instr) {

    if(instr == "") return true;
    
   //remove spaces
    StringReplace(instr," ","");
    StringReplace(base," ","");
    
   //seperate by comma
   string local_arr[];
   int lsize = StringSplit(instr, (ushort)',', local_arr);
 
   for(int i = 0; i < lsize; i++) {
      
        if(!ProcSymbolInputs(base+local_arr[i]+GetSymbolPostfix())) {
            return false;
        } 
        
        AddToArray(base+local_arr[i]+GetSymbolPostfix());   
   }
   
   return true;
}
        
int CSymbolSelector::GetSymbolArray(string &arr[]) { 
    ArrayCopy(arr, symbols_array);
    return GetSize();
}

string CSymbolSelector::GetSymbolPostfix() {
   
    return symbol_postfix_;
}
