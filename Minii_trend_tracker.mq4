//+------------------------------------------------------------------+
//|                                                        Minii.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// Global variables
//+------------------------------------------------------------------+

enum Sentiment {
	Undefined = 1,
	Bullish = 2,
	Bearish = 3
};

Sentiment CurrentSentiment = Undefined;
extern int Slippage = 5; // TODO : Check slippage should be changed
extern double TakeProfitPoints = 600;
extern bool DoubleConfirmation = true;

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
	UpdateSentiment();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Alert ("Function deinit() triggered at exit");// Alert
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
	UpdateSentiment();
	if(CurrentSentiment == Undefined)
	   return;

	// If there is an open/pending order
	if(OrderSelect(0 // Assumption : There is maximum one open order at any time
		,SELECT_BY_POS) == true)
	{
		//HandleOpenOrder();
		return;
	}

	SendOrderAndHandleErrors(CurrentSentiment == Bullish);
	return;
  }
//+------------------------------------------------------------------+

void UpdateSentiment()
{
	Sentiment previousBarDirectionBased = Undefined; // Used for double confirmation
	if(DoubleConfirmation)
	{
		if(Close[1] > Open[1])
			previousBarDirectionBased = Bullish;
		else
			previousBarDirectionBased = Bearish;
	}

	if (Bid > High[1] && previousBarDirectionBased != Bearish)           
		CurrentSentiment = Bullish;
	else if(Ask < Low[1] && previousBarDirectionBased != Bullish)
		CurrentSentiment = Bearish;
	else
		CurrentSentiment = Undefined;
}

void HandleOpenOrder()
{
	bool isBuy = OrderType() == OP_BUY;
	
	if(CurrentSentiment == Bullish && isBuy)
		return;
	
	if(CurrentSentiment == Bearish && !isBuy)
		return;

	double closePrice = isBuy ? Bid : Ask;
	if(OrderClose(
		OrderTicket(),
		OrderLots(),
		closePrice,
		Slippage,
		Red) == false) 
		Alert("Close order error : ", GetLastError());
}

// TODO : Simplyfy these using https://www.mql5.com/en/code/8232
void SendOrderAndHandleErrors(bool isBuy)
{
   string Symb=Symbol();                        // Symbol
   int Min_Dist=MarketInfo(Symb,MODE_STOPLEVEL);// Min. distance
   double takeProfit;
   double stopLoss;
   double minimumAllowedStopLoss;
   
   if(isBuy)
   {
	takeProfit = Bid + TakeProfitPoints*Point;
      stopLoss = Low[1];
      minimumAllowedStopLoss = Bid - Min_Dist*Point;
      Alert("BUY : stopLoss:", stopLoss, " minimumAllowedStopLoss:", minimumAllowedStopLoss);
      if(stopLoss > minimumAllowedStopLoss)
      {
          Alert("Increased the distance of SL of BUY order from ",stopLoss," to ", minimumAllowedStopLoss);
          stopLoss = minimumAllowedStopLoss;
      }

	
   }
   else
   {
	takeProfit = Ask - TakeProfitPoints*Point;
      stopLoss = High[1];
      minimumAllowedStopLoss = Bid + Min_Dist*Point;
      Alert("SELL : stopLoss:", stopLoss, " minimumAllowedStopLoss:", minimumAllowedStopLoss);
      if(stopLoss < minimumAllowedStopLoss)
      {
          Alert("Increased the distance of SL of SELL order from ",stopLoss," to ", minimumAllowedStopLoss);
          stopLoss = minimumAllowedStopLoss;
      }
   }

//-------------------------------------------------------------------------- 2 --
   while(true)                                  // Cycle that opens an order
     {            
      int ticket=-1;
      Alert("Request was sent to the server to open ", isBuy?"BUY":"SELL", " order. Waiting for reply..");
      if(isBuy)
         ticket=OrderSend(Symb, OP_BUY, 0.01, Ask, Slippage, stopLoss, takeProfit);
      else
         ticket=OrderSend(Symb, OP_SELL, 0.01, Bid, Slippage, stopLoss, takeProfit);
      //-------------------------------------------------------------------- 7 --
      if (ticket > 0)                             // Got it!:)
        {
         Alert ("Opened order successfully. Ticket: ",ticket);
         break;                                 // Exit cycle
        }
      //-------------------------------------------------------------------- 8 --
      int Error=GetLastError();                 // Failed :(
      switch(Error)                             // Overcomable errors
        {
         case 135:Alert("The price has changed. Retrying..");
            RefreshRates();                     // Update data
            continue;                           // At the next iteration
         case 136:Alert("No prices. Waiting for a new tick..");
            while(RefreshRates()==false)        // Up to a new tick
               Sleep(1);                        // Cycle delay
            continue;                           // At the next iteration
         case 146:Alert("Trading subsystem is busy. Retrying..");
            Sleep(500);                         // Simple solution
            RefreshRates();                     // Update data
            continue;                           // At the next iteration
        }
      switch(Error)                             // Critical errors
        {
         case 2 : Alert("Common error.");
            break;                              // Exit 'switch'
         case 5 : Alert("Outdated version of the client terminal.");
            break;                              // Exit 'switch'
         case 64: Alert("The account is blocked.");
            break;                              // Exit 'switch'
         case 133:Alert("Trading forbidden");
            break;                              // Exit 'switch'
         default: Alert("Occurred error ",Error);// Other alternatives   
        }
      break;                                    // Exit cycle
     }
    return;
}
