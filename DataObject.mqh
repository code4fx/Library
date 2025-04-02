//###<Template_System.mq5>
//+------------------------------------------------------------------+
//|                                              TradeCDataObject.mqh |
//|                                                Copyright 2022, . |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, ."
#property link      "https://www.mql5.com"

#include <Object.mqh>
#include <Library/Utilities.mqh>

// For simplicity sake, true encapsulation has been relaxed.

// This class acts as buffer or blob/chunk used to interact with
// this program's internal database data structure.


class CDataObject : public CObject {

public:

	ulong position_id;//open

	ulong symbol;//open
	int position_type;//open
	int close_reason; //close
 
	datetime entry_time;//open
	double entry_price;//open
	
	datetime exit_time;//close
	double exit_price;//close
	
	int entry_spread;//open

	double order_duration; //close
	
	int year;//open
	int month;//open
	int day_of_week;//open 
	int open_hour;//open
	int minute;//open
	
	double pre_entry_price;//open
	datetime pre_entry_time;//open
 
	double highest_point_price; //every tick
	datetime highest_point_time; //every tick
	double lowest_point_price; //every tick
	datetime lowest_point_time; //every tick
	
	double highest_equity;//every tick
	double lowest_equity;//every tick

	double lot_size;//open
	double take_profit;//open
	double initial_stoploss;//open (stoploss)
	double final_stoploss;//every tick (trailed stoploss)
	
	double commission;//close
	double swap;//close
	
	double r_multiple;//close
	double profit;//close
	double net_profit;//close
	double relative_profit;//close
	
	bool position_closed;//close
	   
	CDataObject();
	CDataObject(CDataObject &obj) { CopyObject(obj); }
	void operator=(CDataObject &obj) { CopyObject(obj); }
	string ToPrint();
	string ToCSV(char seperator);

private:
    void CopyObject(CDataObject &obj);
    void AddToCSVObj(string &obj, string val, string sep);
    void AddToStrObj(string &obj, string keyVal);
    template <typename T> string StrKeyVal(string key, T val);
    template <typename T> string ToString(T var, int digits=5);
    template <typename T> void Copy(T &to, T from);
};

CDataObject::CDataObject() {

	position_id = NULL;

    symbol = NULL;
	position_type = NULL;
	close_reason = NULL;

	entry_time = NULL;
	entry_price = NULL;
	
	exit_price = NULL;
	exit_time = NULL;
	
	entry_spread = NULL;
	order_duration = NULL;
	
	year = NULL;
	month = NULL;
	day_of_week = NULL;
	open_hour = NULL;
	minute = NULL;
	
	pre_entry_price = NULL;
	pre_entry_time = NULL;
	 
	highest_point_price = NULL;
	highest_point_time = NULL;
	lowest_point_price = NULL;
	lowest_point_time = NULL;
	
	highest_equity = NULL;
	lowest_equity = NULL;

	lot_size = NULL;
	initial_stoploss = NULL;
	take_profit = NULL;
	final_stoploss = NULL;
	
	commission = NULL;
	swap = NULL;
	
	r_multiple = NULL;
	profit = NULL;
	net_profit = NULL;
	relative_profit = NULL;
	
	position_closed = false;
}
	
void CDataObject::CopyObject(CDataObject &obj) {

	Copy(position_id, obj.position_id);

   Copy(symbol, obj.symbol);
	Copy(position_type, obj.position_type);
	Copy(close_reason, obj.close_reason);

	Copy(entry_time, obj.entry_time);
	Copy(entry_price, obj.entry_price);
	
	Copy(exit_price, obj.exit_price);
	Copy(exit_time, obj.exit_time);
	
	Copy(entry_spread, obj.entry_spread);
	Copy(order_duration, obj.order_duration);
	
	Copy(year, obj.year);
	Copy(month, obj.month);
	Copy(day_of_week, obj.day_of_week);
	Copy(open_hour, obj.open_hour);
	Copy(minute, obj.minute);
	
	Copy(pre_entry_price, obj.pre_entry_price);
	Copy(pre_entry_time, obj.pre_entry_time);
	 
	Copy(highest_point_price, obj.highest_point_price);
	Copy(highest_point_time, obj.highest_point_time);
	Copy(lowest_point_price, obj.lowest_point_price);
	Copy(lowest_point_time, obj.lowest_point_time);
	
	Copy(highest_equity, obj.highest_equity);
	Copy(lowest_equity, obj.lowest_equity);

	Copy(lot_size, obj.lot_size);
	Copy(initial_stoploss, obj.initial_stoploss);
	Copy(take_profit, obj.take_profit);
	Copy(final_stoploss, obj.final_stoploss);
	
	Copy(commission, obj.commission);
	Copy(swap, obj.swap);
	
	Copy(r_multiple, obj.r_multiple);
	Copy(profit, obj.profit);
	Copy(net_profit, obj.net_profit);
	Copy(relative_profit, obj.relative_profit);
	
	Copy(position_closed, obj.position_closed);
}
	
string CDataObject::ToPrint() {

    string str = "";
    
    AddToStrObj(str, StrKeyVal("position_id", position_id));
    
    AddToStrObj(str, StrKeyVal("symbol", Base10ToString(symbol)));
    AddToStrObj(str, StrKeyVal("position_type", position_type));
    AddToStrObj(str, StrKeyVal("close_reason", close_reason));
    
    AddToStrObj(str, StrKeyVal("entry_price", entry_price));
    AddToStrObj(str, StrKeyVal("entry_time", entry_time));
    
    AddToStrObj(str, StrKeyVal("exit_price", exit_price));
    AddToStrObj(str, StrKeyVal("exit_time", exit_time));
    
    AddToStrObj(str, StrKeyVal("entry_spread", entry_spread));
    AddToStrObj(str, StrKeyVal("order_duration", order_duration));
    
    AddToStrObj(str, StrKeyVal("year", year));
    AddToStrObj(str, StrKeyVal("month", month));
    AddToStrObj(str, StrKeyVal("day_of_week", day_of_week));
    AddToStrObj(str, StrKeyVal("open_hour", open_hour));
    AddToStrObj(str, StrKeyVal("minute", minute));
    
    AddToStrObj(str, StrKeyVal("pre_entry_price", pre_entry_price));
    AddToStrObj(str, StrKeyVal("pre_entry_time", pre_entry_time));
    
    AddToStrObj(str, StrKeyVal("highest_point_price", highest_point_price));
    AddToStrObj(str, StrKeyVal("highest_point_time", highest_point_time));
    AddToStrObj(str, StrKeyVal("lowest_point_price", lowest_point_price));
    AddToStrObj(str, StrKeyVal("lowest_point_time", lowest_point_time));
    
    AddToStrObj(str, StrKeyVal("highest_equity", highest_equity));
    AddToStrObj(str, StrKeyVal("lowest_equity", lowest_equity));
     
    AddToStrObj(str, StrKeyVal("lot_size", lot_size));
    AddToStrObj(str, StrKeyVal("initial_stoploss", initial_stoploss));
    AddToStrObj(str, StrKeyVal("take_profit", take_profit));
    AddToStrObj(str, StrKeyVal("final_stoploss", final_stoploss));
    
    AddToStrObj(str, StrKeyVal("commission", highest_equity));
    AddToStrObj(str, StrKeyVal("swap", lowest_equity));
    
    AddToStrObj(str, StrKeyVal("r_multiple", r_multiple));
    AddToStrObj(str, StrKeyVal("profit", profit));
    AddToStrObj(str, StrKeyVal("net_profit", net_profit));
    AddToStrObj(str, StrKeyVal("relative_profit", relative_profit));
    
    AddToStrObj(str, StrKeyVal("position_closed", position_closed));
    
    return str;
}

string CDataObject::ToCSV(char seperator) {

	string str = "";
	string sep = (string)seperator;

    AddToCSVObj(str, ToString(position_id), sep);
    
    AddToCSVObj(str, Base10ToString(symbol), sep);
    
    AddToCSVObj(str, ToString(position_type), sep);
    AddToCSVObj(str, ToString(close_reason), sep);
    
    AddToCSVObj(str, ToString(entry_price), sep);
    AddToCSVObj(str, ToString(entry_time), sep);
    
    AddToCSVObj(str, ToString(exit_time), sep);
	AddToCSVObj(str, ToString(exit_price), sep);
	
	AddToCSVObj(str, ToString(entry_spread), sep);
    
    AddToCSVObj(str, ToString(order_duration), sep);
    
    AddToCSVObj(str, ToString(year), sep);
    AddToCSVObj(str, ToString(month), sep);
    AddToCSVObj(str, ToString(day_of_week), sep);
    AddToCSVObj(str, ToString(open_hour), sep);
    AddToCSVObj(str, ToString(minute), sep);
    
	AddToCSVObj(str, ToString(pre_entry_price), sep);
	AddToCSVObj(str, ToString(pre_entry_time), sep);
	
	AddToCSVObj(str, ToString(highest_point_price), sep);
	AddToCSVObj(str, ToString(highest_point_time), sep);
	AddToCSVObj(str, ToString(lowest_point_price), sep); 
	AddToCSVObj(str, ToString(lowest_point_time), sep);
	 
	AddToCSVObj(str, ToString(highest_equity), sep); 
	AddToCSVObj(str, ToString(lowest_equity), sep);
	
	AddToCSVObj(str, ToString(lot_size), sep); 
	AddToCSVObj(str, ToString(initial_stoploss), sep);
	AddToCSVObj(str, ToString(take_profit), sep);
	AddToCSVObj(str, ToString(final_stoploss), sep);
	 
    AddToCSVObj(str, ToString(commission), sep); 
	AddToCSVObj(str, ToString(swap), sep);
	
	AddToCSVObj(str, ToString(r_multiple), sep); 
	AddToCSVObj(str, ToString(profit), sep);
    AddToCSVObj(str, ToString(net_profit), sep); 
	AddToCSVObj(str, ToString(relative_profit), sep);
	
	AddToCSVObj(str, ToString(position_closed), sep);

	return str;
}

template <typename T>
void CDataObject::Copy(T &to, T from) {
    if (from != NULL)
        to = from;
}

template <typename T>
string CDataObject::ToString(T var, int digits=5) {

    if (typename(var) == "int")
        return IntegerToString((int)var);
    
    if (typename(var) == "ulong")
        return IntegerToString((long)var);
    
    if (typename(var) == "double")
        return DoubleToString((double)var, digits);
    
    if (typename(var) == "datetime")
        return TimeToString((datetime)var);
    
    if (typename(var) == "enum ENUM_DEAL_REASON")
        return (string)((ENUM_DEAL_REASON)var);
    
    if (typename() == "enum ENUM_POSITION_TYPE")
        return (string)((ENUM_POSITION_TYPE)var);
    
    return (string)var;
}

template <typename T>
string CDataObject::StrKeyVal(string key, T val) {
    return (key + ": " + ToString(val));
}

void CDataObject::AddToStrObj(string &obj, string keyVal) {
    string str = "{";
    StringReplace(obj, "{", "");
    StringReplace(obj, "}", "");
    if (obj != "")
        obj += ", ";
    obj += keyVal;
    str += obj + "}";
    obj = str;
}

void CDataObject::AddToCSVObj(string &obj, string val, string sep) {
    StringTrimLeft(obj);
    StringTrimRight(obj);
    if (obj != "")
        obj += sep;
    obj += val;
    obj += "\r\n";
}
