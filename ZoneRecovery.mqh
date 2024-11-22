//+------------------------------------------------------------------+
//|                                                       Trader.mqh |
//|                                                Copyright 2022, . |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, ."
#property link      "https://www.mql5.com"

#include "ErrorDescriptions.mqh"
#include <Trade/Trade.mqh>

//TODO: Convensionalize
//TODO: Cleanup
//TODO: switch lotsizing to convensional methods

input group "//=== Recovery"


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//class CZoneRecovery {
//
//private:
//
//
//public:
//    CZoneRecovery() {}
//    CZoneRecovery(int magic_num, string symbol) {}
//    ~CZoneRecovery() {
//        delete trader;
//    }
//    bool              initRecovery(long magic_no);
//};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//bool CZoneRecovery::initGridRecovery(long magic_no) {
//    return true;
//}

enum ENUM_ZONE_POSITION_STATUS {
    ZONE_POSITION_STATUS_CLOSED,
    ZONE_POSITION_STATUS_OPEN,
    ZONE_POSITION_STATUS_CLOSING
};

// Struct definition
struct SZoneResult {
    bool              success;
    double            volume;
    double            volProfit;
};

//
struct SOrderInfo {
    ulong mOrderTicket;
    bool mClosed;
};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CZoneRecovery {

private:
    string            mInitMessage;
    int               mInitResult;
    
  CTrade  Trade;

protected:
// Members
    string            mSymbol;
    double            symbolPoint;
    int  symbolDigits;
    long mMagicNumber;

    double            mInitialPrice;
    double            mInitialVolume;
    string            mTradeComment;

    SOrderInfo        mTickets[];
    ENUM_ORDER_TYPE   mDirection;

    double            mTarget;
    double            mZoneSize;
    double            mSupplement;

    double            mZoneHigh;
    double            mZoneLow;
    double            mTargetHigh;
    double            mTargetLow;

    double            mBuyLots;
    double            mSellLots;
    ENUM_ZONE_POSITION_STATUS mStatus;

// Utility functions
    int               InitError(string initMessage, int initResult) {
        mInitMessage = initMessage;
        mInitResult = initResult;
        return initResult;
    }

    int               InitResult() {
        return mInitResult;
    }
    string            InitMessage() {
        return mInitMessage;
    }
    double            VolumeStep() {
        return SymbolInfoDouble(mSymbol, SYMBOL_VOLUME_STEP);
    }
    double            Ask() {return SymbolInfoDouble(mSymbol, SYMBOL_ASK);}
    double            Bid() {return SymbolInfoDouble(mSymbol, SYMBOL_BID);}
    

protected:
    virtual bool      InitPosition(ulong ticket);
    virtual ulong     OpenTrade(ENUM_ORDER_TYPE direction, double lots, double price);
    virtual void      CloseTrades(SZoneResult &result);


protected:
    virtual int       Init(string symbol, double targetSize, double zoneSize, double zoneSupplement = 0.0);
    virtual void      AddTrade(ulong ticket);
    virtual void      AddNewTrade(ENUM_ORDER_TYPE direction, double price);
    virtual bool      ClosePosition();
    virtual double    Lots(ENUM_ORDER_TYPE direction);


public:
    CZoneRecovery(string symbol, double targetSize, double zoneSize, double zoneSupplement=0.0) {
        Init(symbol, targetSize, zoneSize, zoneSupplement);
    }

    ~CZoneRecovery() {}

    ENUM_ZONE_POSITION_STATUS GetStatus() {
        return mStatus;
    }

    double   GetTargetHigh() {
        return mTargetHigh;
    }
    double   GetTargetLow() {
        return mTargetLow;
    }
    double   GetZoneHigh() {
        return mZoneHigh;
    }
    double   GetZoneLow() {
        return mZoneLow;
    }

    virtual bool      OpenPosition(ulong ticket);
    virtual void      OnTick();

};
//+------------------------------------------------------------------+

int CZoneRecovery::Init(string symbol, double targetSize, double zoneSize, double zoneSupplement) {
    mSymbol = symbol;
    mStatus = ZONE_POSITION_STATUS_CLOSED;
    ArrayResize(mTickets, 0);
    symbolPoint = SymbolInfoDouble(symbol, SYMBOL_POINT);
    symbolDigits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    mTarget = targetSize * symbolPoint;
    mZoneSize = zoneSize * symbolPoint;
    mSupplement = zoneSupplement;
    return INIT_SUCCEEDED;
}

bool CZoneRecovery::OpenPosition(ulong ticket) {
    // Note: there is no check here that there may be an existing open position, brute force
    mStatus = ZONE_POSITION_STATUS_CLOSED;
    ArrayResize(mTickets, 0);

    if (!InitPosition(ticket))
        return false;

    AddTrade(ticket);

    if (mDirection == ORDER_TYPE_BUY) {
        mZoneHigh = mInitialPrice;
        mZoneLow = mZoneHigh - mZoneSize;
        mBuyLots = mInitialVolume;
        mSellLots = 0.0;
    } else {
        mZoneLow = mInitialPrice;
        mZoneHigh = mZoneLow + mZoneSize;
        mSellLots = mInitialVolume;
        mBuyLots = 0.0;
    }

    mTargetHigh = mZoneHigh + mTarget;
    mTargetLow = mZoneLow - mTarget;

    mStatus = ZONE_POSITION_STATUS_OPEN;

    return true;
}

bool CZoneRecovery::InitPosition (ulong ticket) {
    if (!PositionSelectByTicket (ticket)) {
        InitError (StringFormat ("Could not find specified ticket number %i", ticket), INIT_FAILED);
        return (false);
    }
    
    mSymbol = PositionGetString (POSITION_SYMBOL) ;
    mTradeComment = PositionGetString (POSITION_COMMENT);
    mMagicNumber = PositionGetInteger (POSITION_MAGIC);
    mDirection = (ENUM_ORDER_TYPE) PositionGetInteger (POSITION_TYPE);
    mInitialPrice = PositionGetDouble (POSITION_PRICE_OPEN);
    mInitialVolume = PositionGetDouble (POSITION_VOLUME);
    
    Trade.SetExpertMagicNumber (mMagicNumber);
    
    return (true);
}

void CZoneRecovery::CloseTrades (SZoneResult &result) {
    for (int i = ArraySize (mTickets)-1; i>=0; i--) {
        if (mTickets[i].mClosed == false) {
            if (Trade.PositionClose(mTickets[i].mOrderTicket)) {
                mTickets[i].mClosed = true;
                result.volume += Trade.ResultVolume() ;
                // Not strictly correct
                if ((ENUM_ORDER_TYPE) PositionGetInteger (POSITION_TYPE) == ORDER_TYPE_BUY) {
                    result.volProfit += Trade.ResultVolume () * 
                                        (Trade.ResultPrice() - PositionGetDouble(POSITION_PRICE_OPEN));
                } else {
                    result.volProfit += Trade.ResultVolume() * 
                                        (PositionGetDouble(POSITION_PRICE_OPEN) - Trade.ResultPrice());
                }
            } else {
                result.success = false;
            }
        }
    }
    return;
}

ulong CZoneRecovery::OpenTrade (ENUM_ORDER_TYPE direction, double lots, double price) {
    ulong ticket = 0;
    if (Trade.PositionOpen(mSymbol, direction, lots, price, 0, 0, mTradeComment)) {
        ticket = Trade.ResultOrder();
    }
    return (ticket);
}

void CZoneRecovery::OnTick (void) {
    if (mStatus == ZONE_POSITION_STATUS_CLOSED) {
        return;
    }
    
    if (mStatus == ZONE_POSITION_STATUS_CLOSING) {
        ClosePosition ();
        return;
    }
    
    double price;
    
    if (mDirection == ORDER_TYPE_BUY) {
        price = Bid();
        if (price > mTargetHigh) {
            ClosePosition();
            return;
        } else if (price < mZoneLow) {
            AddNewTrade (ORDER_TYPE_SELL, price);
        } 
    } else if (mDirection == ORDER_TYPE_SELL) {
        price = Ask ();
        if (price < mTargetLow) {
            ClosePosition();
            return;
        } else if (price > mZoneHigh) {
            AddNewTrade (ORDER_TYPE_BUY, price);
        }
    }
}

void CZoneRecovery::AddTrade (ulong ticket) {
    int cnt = ArraySize (mTickets);
    ArrayResize (mTickets, cnt+1);
    mTickets[cnt].mOrderTicket = ticket;
    mTickets[cnt].mClosed = false;
    return;
}

void CZoneRecovery::AddNewTrade(ENUM_ORDER_TYPE direction, double price) {
    double lots = Lots(direction);
    ulong ticket = OpenTrade(direction, lots, price);
    
        Comment(mSupplement);
    if (ticket > 0) {
        AddTrade (ticket);
        mDirection = direction;
        if (direction == ORDER_TYPE_BUY) {
            mBuyLots += lots;
        } else {
            mSellLots += lots;
        }
    }
}

bool CZoneRecovery::ClosePosition(void) {
    mStatus = ZONE_POSITION_STATUS_CLOSING; // Closing
    SZoneResult result = {true, 0.0, 0.0};
    CloseTrades(result);
    if (result.success) {
        ArrayResize(mTickets, 0);
        mStatus = ZONE_POSITION_STATUS_CLOSED; // Closed
    }
    return (result.success);
}

double CZoneRecovery::Lots (ENUM_ORDER_TYPE direction) {
    
    double lots = 0;
    
    if (direction == ORDER_TYPE_BUY) {
        lots = ((mSellLots * (mTarget + mZoneSize) /mTarget) - mBuyLots);
    } else {
        lots = ((mBuyLots * (mTarget + mZoneSize) /mTarget) - mSellLots);
    }
    
    lots = (MathCeil(lots / VolumeStep()) * VolumeStep());
    
    return (lots);
}