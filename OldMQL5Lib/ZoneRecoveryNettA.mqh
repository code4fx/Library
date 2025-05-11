//+------------------------------------------------------------------+
//|                                               ZoneRecoveryNA.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include "ZoneRecovery.mqh"
#include <System_Templates/PositionSizing.mqh>
#include <Trade/DealInfo.mqh>

//TODO: Make more effecient, especially lotsizing part

class CZoneRecoveryNA : public CZoneRecovery {
protected:
    // To calculate the size of the next trade we must know how much we have lost in the position so far
    double mVolProfit;
    CPositionSizing pos;

private: // functions

protected:
    // These have a modified implementation for netting
    virtual void AddNewTrade(ENUM_ORDER_TYPE direction, double price);
    virtual double Lots(ENUM_ORDER_TYPE direction);
    double CalcSupplement();

public:
    // Constructor
    CZoneRecoveryNA(string symbol, double targetSize, double zoneSize, double zoneSupplement = 0.0)
    : CZoneRecovery(symbol, targetSize, zoneSize, zoneSupplement) {}

    // Destructor
    ~CZoneRecoveryNA() {}
    
    virtual bool OpenPosition (ulong ticket);
    
    
};

bool CZoneRecoveryNA::OpenPosition(ulong ticket) {
    // The only modification needed here is to initialize running profit, and then call the parent method
    mVolProfit = 0.0;
    return CZoneRecovery::OpenPosition(ticket); // Note the :: syntax
}

double CZoneRecoveryNA::Lots(ENUM_ORDER_TYPE direction) {
    // Even after calling the parent class to add a new trade, this function will be used to calculate
    // new trade lots
    double lots = 0.0;
    mSupplement = CalcSupplement();

    double amount = MathAbs(mSupplement / symbolPoint);
    double target = mTarget / symbolPoint;
    lots = pos.calcLotSize(amount, target);
    
    lots = (MathCeil(lots / VolumeStep()) * VolumeStep()) + VolumeStep();
    lots = NormalizeDouble(lots, 2);

    return lots;
}

void CZoneRecoveryNA::AddNewTrade(ENUM_ORDER_TYPE direction, double price) {
    // This changes because we now close existing trades
    SZoneResult result = {true, 0.0, 0.0};
    CloseTrades(result); // An existing function in the parent class

    for (int i = 0; i < 10 && !result.success; i++) {
        Sleep(1000);
        //RefreshRates();
        result.success = true; // Just a placeholder, replace it with your actual logic
        CloseTrades(result);
    }

    mVolProfit += result.volProfit;

    // Just in case - but unlikely
    if (mVolProfit > 0 && result.success) {
        PrintFormat("mVolProfit = %f", mVolProfit);
        ClosePosition();
        mVolProfit = 0.0;
        return;
    }

    // The rest is done by the parent class
    CZoneRecovery::AddNewTrade(direction, price);
}

double  CZoneRecoveryNA::CalcSupplement() {
    double supp = 0;
    double total_commission = 0;
    double total_swap = 0;
    double total_loss = 0;
    int size = ArraySize(mTickets);
    bool selected = false;
    ulong dealId = 0;
    
    for (int i = 0; i < size; i++) {
        selected = HistorySelectByPosition(mTickets[i].mOrderTicket);
        for (int j = 0; j < HistoryDealsTotal() && selected; j++) {
            dealId = HistoryDealGetTicket(j);
            total_commission += HistoryDealGetDouble(dealId, DEAL_COMMISSION);
            total_swap += HistoryDealGetDouble(dealId, DEAL_SWAP);
            total_loss += HistoryDealGetDouble(dealId, DEAL_PROFIT);
        }
    }
    
    supp = total_swap + total_commission;
    supp += total_loss < 0 ? total_loss : 0;
    supp = MathAbs(supp);
    supp = MathCeil(supp);
    supp = supp * symbolPoint;
    supp = NormalizeDouble(supp, symbolDigits);
    
    return (supp);
}

//write code that selects deals from position id
// // Assuming you have a position ID, you can use the PositionGetInteger function to get the deal ID of the position.
// // Then, you can use the HistorySelect function to select deals from the position ID.
// 
// // Example code:
// 
// // Get the deal ID of the position
// ulong positionID = 12345; // Replace with your position ID
// ulong dealID = PositionGetInteger(POSITION_IDENTIFIER, positionID, POSITION_DEAL);
// 
// // Select deals from the position ID
// int totalDeals = HistoryDealsTotal();
// for (int i = 0; i < totalDeals; i++) {
//    ulong selectedDealID = HistoryDealGetInteger(i, DEAL_IDENTIFIER);
//    if (selectedDealID == dealID) {
//       // This deal is from the position ID, you can now use HistoryDealGet* functions to get deal information
//    }
// }
// 

