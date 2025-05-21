//+------------------------------------------------------------------+
//|                                                 PositionInfo.mqh |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Object.mqh>
//+------------------------------------------------------------------+
//| Class CPositionInfo.                                             |
//| Appointment: Class for access to position info.                  |
//|              Derives from class CObject.                         |
//+------------------------------------------------------------------+
class CPositionInfo : public CObject
  {
protected:

public:
                     CPositionInfo(void) {}
                    ~CPositionInfo(void) {}
   //--- fast access methods to the integer position propertyes
   int               Ticket(void) const;
   datetime          Time(void) const;
   ENUM_ORDER_TYPE   PositionType(void) const;
   long              Magic(void) const;
   //--- fast access methods to the double position propertyes
   double            Volume(void) const;
   double            PriceOpen(void) const;
   double            StopLoss(void) const;
   double            TakeProfit(void) const;

   double            Profit(void) const;
   //--- fast access methods to the string position propertyes
   string            Symbol(void) const;
   string            Comment(void) const;
   //--- info methods

   //--- methods for select position
   bool              SelectByTicket(const ulong ticket);
   bool              SelectByIndex(const int index);
   //---
  };

//+------------------------------------------------------------------+
//| Get the property value "POSITION_TICKET"                         |
//+------------------------------------------------------------------+
int CPositionInfo::Ticket(void) const
  {
   return(OrderTicket());
  }
//+------------------------------------------------------------------+
//| Get the property value "POSITION_TIME"                           |
//+------------------------------------------------------------------+
datetime CPositionInfo::Time(void) const
  {
   return(OrderOpenTime());
  }
//+------------------------------------------------------------------+
//| Get the property value "POSITION_TYPE"                           |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE CPositionInfo::PositionType(void) const
  {
   return((ENUM_ORDER_TYPE)OrderType());
  }
//+------------------------------------------------------------------+
//| Get the property value "POSITION_MAGIC"                          |
//+------------------------------------------------------------------+
long CPositionInfo::Magic(void) const
  {
   return(OrderMagicNumber());
  }
//+------------------------------------------------------------------+
//| Get the property value "POSITION_VOLUME"                         |
//+------------------------------------------------------------------+
double CPositionInfo::Volume(void) const
  {
   return(OrderLots());
  }
//+------------------------------------------------------------------+
//| Get the property value "POSITION_PRICE_OPEN"                     |
//+------------------------------------------------------------------+
double CPositionInfo::PriceOpen(void) const
  {
   return(OrderOpenPrice());
  }
//+------------------------------------------------------------------+
//| Get the property value "POSITION_SL"                             |
//+------------------------------------------------------------------+
double CPositionInfo::StopLoss(void) const
  {
   return(OrderStopLoss());
  }
//+------------------------------------------------------------------+
//| Get the property value "POSITION_TP"                             |
//+------------------------------------------------------------------+
double CPositionInfo::TakeProfit(void) const
  {
   return(OrderTakeProfit());
  }
//+------------------------------------------------------------------+
//| Get the property value "POSITION_PROFIT"                         |
//+------------------------------------------------------------------+
double CPositionInfo::Profit(void) const
  {
   return(OrderProfit());
  }
//+------------------------------------------------------------------+
//| Get the property value "POSITION_SYMBOL"                         |
//+------------------------------------------------------------------+
string CPositionInfo::Symbol(void) const
  {
   return(OrderSymbol());
  }
//+------------------------------------------------------------------+
//| Get the property value "POSITION_COMMENT"                        |
//+------------------------------------------------------------------+
string CPositionInfo::Comment(void) const
  {
   return(OrderComment());
  }
//+------------------------------------------------------------------+
//| Access functions PositionSelectByTicket(...)                     |
//+------------------------------------------------------------------+
bool CPositionInfo::SelectByTicket(const ulong ticket)
  {
   return(OrderSelect((int)ticket, SELECT_BY_TICKET));
  }
//+------------------------------------------------------------------+
//| Select a position on the index                                   |
//+------------------------------------------------------------------+
bool CPositionInfo::SelectByIndex(const int index)
  {
   ulong ticket= OrderSelect(index, SELECT_BY_POS) ? OrderTicket() : -1;
   return(ticket>0);
  }
