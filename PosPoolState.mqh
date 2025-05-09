//###<Experts/Template_System/Template_System.mq5>
//+------------------------------------------------------------------+
//|                                                TradeObserver.mqh |
//|                                                 Copyright 2023,. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022,."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <Library/ErrorDescriptions.mqh>
#include <Library/Utilities.mqh>

/**
 * CPosPoolState - tracks changes of the Positons Order Pool.
 * @stateChange: returns state of pool and  details of the
 * recent position responsible for the state changes.
 * @getLastDealEntry: returns deal entry state which tells us whether
 * this deal is for an entry or exit position. 
*/
//+------------------------------------------------------------------+
//|                                                TradeObserver.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

enum ENUM_ORDER_DATA
{
    position_ticket,
    position_magicNumber,
    position_type,
    position_stoploss,
    position_takeProfit,
    position_symbol,
    
    position_last,
    position_limit = position_takeProfit,
};

struct STradeObserverData {
    int count;
    double trades[][position_last];
};

enum ENUM_CHANGE_TYPE
{    
    CHANGE_TYPE_ticket,
    CHANGE_TYPE_magicNumber,
    CHANGE_TYPE_type,
    CHANGE_TYPE_stoploss,
    CHANGE_TYPE_takeProfit,
    
    CHANGE_TYPE_NEW,
    CHANGE_TYPE_CLOSED,
};

struct SChangeLine {
    ENUM_CHANGE_TYPE changeType;
    double currentData[position_last];
    double previousData[position_last];
};

class CPosPoolState {
   
private:
    long m_magic_number;

protected:
   
	STradeObserverData mPreviousData;
	SChangeLine mChanges[];

	void AddChange(ENUM_CHANGE_TYPE type, double &current[], double &previous[]);
	void LineCopy(double &line[], double &trades[][], int ptr);
	void Fill (STradeObserverData &data);
   

public:

	CPosPoolState();
	~CPosPoolState();
	bool StateChange(SChangeLine &changes[], int &size);
	int GetChanges(SChangeLine &changes[]);
	void SetMagicNumber(long magicnum) { m_magic_number = magicnum; }
};

CPosPoolState::CPosPoolState() {
	Fill(mPreviousData);
}


CPosPoolState::~CPosPoolState() {}
//+------------------------------------------------------------------+

void CPosPoolState::Fill(STradeObserverData &data) {
    data.count = PositionsTotal();
    ArrayResize(data.trades, data.count);
    for (int i = 0; i < data.count; i++) {
        data.trades[i][position_ticket] = 0;
        ulong ticket = PositionGetTicket(i);
        if (!PositionSelectByTicket(ticket)) continue;
        if (PositionGetInteger(POSITION_MAGIC) != m_magic_number) continue;
        data.trades[i][position_ticket] = (double)ticket;
        data.trades[i][position_magicNumber] = (double)PositionGetInteger(POSITION_MAGIC);
        data.trades[i][position_type] = (double)PositionGetInteger(POSITION_TYPE);
        data.trades[i][position_stoploss] = PositionGetDouble(POSITION_SL);
        data.trades[i][position_takeProfit] = PositionGetDouble(POSITION_SL);
        data.trades[i][position_symbol] = (double)StringToBase10(PositionGetString(POSITION_SYMBOL));
    }
    if (data.count > 0)
    	ArraySort(data.trades);
}

bool CPosPoolState::StateChange(SChangeLine &changes[], int &size) {

    STradeObserverData currentData;
    Fill(currentData);
    bool changed = false;

    // Reset the changes list before each scan
    ArrayResize(mChanges, 0);

    // Define separate pointers to iterate through each array
    int currentPtr = 0;
    int previousPtr = 0;

    // Define arrays to hold the data for each line
    double currentLine[position_last];
    double previousLine[position_last];
    
    while (currentPtr < currentData.count || previousPtr < mPreviousData.count) {
    	if (previousPtr >= mPreviousData.count ||
    		(currentPtr < currentData.count &&
    		 currentData.trades[currentPtr][position_ticket] < mPreviousData.trades[previousPtr][position_ticket])) {
    		LineCopy(currentLine, currentData.trades, currentPtr);
    		AddChange(CHANGE_TYPE_NEW, currentLine, currentLine);
    		changed = true;
    		currentPtr++;
    	}
    	else if (currentPtr >= currentData.count ||
    			 mPreviousData.trades[previousPtr][position_ticket] < currentData.trades[currentPtr][position_ticket]) {
    		LineCopy(previousLine, mPreviousData.trades, previousPtr);
    		AddChange(CHANGE_TYPE_CLOSED, previousLine, previousLine);
    		changed = true;
    		previousPtr++;
    	}
    	else {
    		for (int j = 0; j < position_limit; j++) {
			    // Only going as far as type, add or change in €
			
			    // An extra bool so we don't linecopy more than once
			    bool lineChanged = false;
			
			    // Compare every element of the trade (those that do change)
			    if (currentData.trades[currentPtr][j] != mPreviousData.trades[previousPtr][j]) {
			        if (!lineChanged) {
			            // Copy both lines if there has been a change
			            LineCopy(currentLine, currentData.trades, currentPtr);
			            LineCopy(previousLine, mPreviousData.trades, previousPtr);
			            lineChanged = true;
			        }
			        AddChange((ENUM_CHANGE_TYPE)j, currentLine, previousLine);
			        changed = true;
			    }
			}
			
			// After all columns test increment both pointers
			currentPtr++;
			previousPtr++;

    	}
    }
    
    mPreviousData = currentData;
    
    size = GetChanges(changes);
    
    return changed;
}

// Save a line of old and new data to the change array
void CPosPoolState::AddChange(ENUM_CHANGE_TYPE type, double &current[], double &previous[]) {
    int count = ArraySize(mChanges);
    ArrayResize(mChanges, count + 1, 10);
    mChanges[count].changeType = type;
    ArrayCopy(mChanges[count].currentData, current);
    ArrayCopy(mChanges[count].previousData, previous);
}

int CPosPoolState::GetChanges(SChangeLine &changes[]) {
    ArrayCopy(changes, mChanges);
   	int size = ArraySize(changes);
    return size;
}

// Copy from the 2D array to 1D
void CPosPoolState::LineCopy(double &line[], double &trades[][], int ptr) {
    for (int i = 0; i < position_last; i++) {
        line[i] = trades[ptr][i];
    }
}
