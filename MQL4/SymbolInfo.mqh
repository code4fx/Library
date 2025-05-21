//+------------------------------------------------------------------+
//|                                                   SymbolInfo.mqh |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Object.mqh>
//+------------------------------------------------------------------+
//| Class CSymbolInfo.                                               |
//| Appointment: Class for access to symbol info.                    |
//|              Derives from class CObject.                         |
//+------------------------------------------------------------------+
class CSymbolInfo : public CObject
  {
protected:
   string            m_name;                       // symbol name
   MqlTick           m_tick;                       // structure of tick;
   double            m_point;                      // symbol point
   double            m_tick_value;                 // symbol tick value
   double            m_tick_size;                  // symbol tick size
   double            m_swap_short;                 // symbol swap short
   int               m_digits;                     // symbol digits

public:
                     CSymbolInfo(void);
                    ~CSymbolInfo(void);
   //--- methods of access to protected data
   string            Name(void) const { return(m_name); }
   bool              Name(const string name);
   bool              Refresh(void);
   bool              RefreshRates(void);
   //--- fast access methods to the integer symbol propertyes
   bool              Select(void) const;
   bool              Select(const bool select);
   bool              IsSynchronized(void) const;
   //--- volumes
   ulong             Volume(void)     const { return(m_tick.volume); }
   //--- miscellaneous
   datetime          Time(void)           const { return(m_tick.time); }
   int               Spread(void)         const;

   //--- trade levels
   int               StopsLevel(void)  const;
   int               FreezeLevel(void) const;
   //--- fast access methods to the double symbol propertyes
   //--- bid parameters
   double            Bid(void)      const { return(m_tick.bid); }

   //--- ask parameters
   double            Ask(void)      const { return(m_tick.ask); }

   double            MarginLimit(void)     const { return(0.0); }
   double            MarginStop(void)      const { return(0.0); }
   double            MarginStopLimit(void) const { return(0.0); }

   //--- tick parameters
   int               Digits(void)          const { return(m_digits);            }
   double            Point(void)           const { return(m_point);             }
   double            TickValue(void)       const { return(m_tick_value);        }
   double            TickSize(void)        const { return(m_tick_size);         }

   //--- fast access methods to the string symbol propertyes
   string            CurrencyBase(void)   const;

   //--- service methods
   double            NormalizePrice(const double price) const;
   bool              CheckMarketWatch(void);
  };

//+------------------------------------------------------------------+
//| Set name                                                         |
//+------------------------------------------------------------------+
bool CSymbolInfo::Name(const string name)
  {
   string symbol_name=StringLen(name)>0 ? name : _Symbol;
//--- check previous set name
   if(m_name!=symbol_name)
     {
      m_name=symbol_name;
      //---
      if(!CheckMarketWatch())
         return(false);
      //---
      if(!Refresh())
        {
         m_name="";
         Print(__FUNCTION__+": invalid data of symbol '"+symbol_name+"'");
         return(false);
        }
     }
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Refresh cached data                                              |
//+------------------------------------------------------------------+
bool CSymbolInfo::RefreshRates(void)
  {
   return(SymbolInfoTick(m_name, m_tick));
  }
//+------------------------------------------------------------------+
//| Get the property value "SYMBOL_SELECT"                           |
//+------------------------------------------------------------------+
bool CSymbolInfo::Select(void) const
  {
   return((bool)SymbolInfoInteger(m_name,SYMBOL_SELECT));
  }
//+------------------------------------------------------------------+
//| Set the property value "SYMBOL_SELECT"                           |
//+------------------------------------------------------------------+
bool CSymbolInfo::Select(const bool select)
  {
   return(SymbolSelect(m_name,select));
  }
//+------------------------------------------------------------------+
//| Check synchronize symbol                                         |
//+------------------------------------------------------------------+
bool CSymbolInfo::IsSynchronized(void) const
  {
   return(SymbolIsSynchronized(m_name));
  }

//+------------------------------------------------------------------+
//| Get the property value "SYMBOL_SPREAD"                           |
//+------------------------------------------------------------------+
int CSymbolInfo::Spread(void) const
  {
   return((int)SymbolInfoInteger(m_name,SYMBOL_SPREAD));
  }

//+------------------------------------------------------------------+
//| Get the property value "SYMBOL_TRADE_STOPS_LEVEL"                |
//+------------------------------------------------------------------+
int CSymbolInfo::StopsLevel(void) const
  {
   return((int)SymbolInfoInteger(m_name,SYMBOL_TRADE_STOPS_LEVEL));
  }
//+------------------------------------------------------------------+
//| Get the property value "SYMBOL_TRADE_FREEZE_LEVEL"               |
//+------------------------------------------------------------------+
int CSymbolInfo::FreezeLevel(void) const
  {
   return((int)SymbolInfoInteger(m_name,SYMBOL_TRADE_FREEZE_LEVEL));
  }


//+------------------------------------------------------------------+
//| Get the property value "SYMBOL_CURRENCY_BASE"                    |
//+------------------------------------------------------------------+
string CSymbolInfo::CurrencyBase(void) const
  {
   return(SymbolInfoString(m_name,SYMBOL_CURRENCY_BASE));
  }

//+------------------------------------------------------------------+
//| Normalize price                                                  |
//+------------------------------------------------------------------+
double CSymbolInfo::NormalizePrice(const double price) const
  {
   if(m_tick_size!=0)
      return(NormalizeDouble(MathRound(price/m_tick_size)*m_tick_size,m_digits));
//---
   return(NormalizeDouble(price,m_digits));
  }
//+------------------------------------------------------------------+
//| Checks if symbol is selected in the MarketWatch                  |
//| and adds symbol to the MarketWatch, if necessary                 |
//+------------------------------------------------------------------+
bool CSymbolInfo::CheckMarketWatch(void)
  {
//--- check if symbol is selected in the MarketWatch
   if(!Select()) return false;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
