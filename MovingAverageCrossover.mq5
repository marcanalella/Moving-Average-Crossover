//+------------------------------------------------------------------+
//|                                       MovingAverageCrossover.mq5 |
//|                                                  Mario Canalella |
//|                               https://mariocanalella.netlify.app |
//+------------------------------------------------------------------+
#property copyright "Mario Canalella"
#property link      "https://mariocanalella.netlify.app"
#property version   "1.00"

input group "Moving Averages Settings";
input int maFastPeriod = 10;  // Fast SMA period
input int maSlowPeriod = 50;  // Slow SMA period
input ENUM_TIMEFRAMES timeFrame = PERIOD_M15;  // Time frame

input group "Money Management Settings";
input double lotSize = 0.1;    // Lot size
input double stopLoss = 50;    // Stop loss in points -> 0 = NO STOP
input double takeProfit = 100; // Take profit in points -> 0 = NO TP

input group "EA Settings";
input double magicNumber = 1;  // Magic Number

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
double fastMA[];
double slowMA[];
int fastMaHandle;
int slowMaHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   ArraySetAsSeries(fastMA, true);
   ArraySetAsSeries(slowMA, true);

   fastMaHandle = iMA(Symbol(), timeFrame, maFastPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if (fastMaHandle < 0) {
      Print("The creation of fast-iMA has failed: Runtime error =", GetLastError());
      return (INIT_FAILED);
   }

   slowMaHandle = iMA(Symbol(), timeFrame, maSlowPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if (slowMaHandle < 0) {
      Print("The creation of slow-iMA has failed: Runtime error =", GetLastError());
      return (INIT_FAILED);
   }

   Print("Moving Average Crossover EA Initialized");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Print("Moving Average Crossover EA Deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

   CopyBuffer(fastMaHandle, 0, 0, 3, fastMA);
   CopyBuffer(slowMaHandle, 0, 0, 3, slowMA);

   if (fastMA[1] > slowMA[1] && fastMA[2] <= slowMA[2]) {
      openTrade(ORDER_TYPE_BUY);
   } else if (fastMA[1] < slowMA[1] && fastMA[2] >= slowMA[2]) {
      openTrade(ORDER_TYPE_SELL);
   }
}

//+------------------------------------------------------------------+
//| Open Trade                                                       |
//+------------------------------------------------------------------+
void openTrade(int orderType) {

   if(getOpenPositions() < 1) {
      MqlTradeRequest request;
      ZeroMemory(request);

      request.action = TRADE_ACTION_DEAL;
      double price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(Symbol(), SYMBOL_ASK) : SymbolInfoDouble(Symbol(), SYMBOL_BID);
      request.price = price;
      request.sl = (orderType == ORDER_TYPE_BUY) ? price - stopLoss * Point() : price + stopLoss * Point();
      request.tp = (orderType == ORDER_TYPE_BUY) ? price + takeProfit * Point() : price - takeProfit * Point();
      request.type = orderType;
      request.type_filling = ORDER_FILLING_IOC;
      request.symbol = Symbol();
      request.volume = lotSize;
      request.comment = "OPEN BY Moving Average Crossover EA";
      request.magic = magicNumber;
      Print("Opening trade...");
      // Open the trade
      MqlTradeResult result;
      if(!OrderSend(request, result)) {
         Print("Failed to open trade: ", GetLastError());
      } else {
         Print("OrderSend: ",result.comment," - reply code: ",result.retcode);
      }
      Sleep(1000);
      ZeroMemory(result);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getOpenPositions() {

   int countPosition = 0;

   int totalPositions = PositionsTotal();
   if(totalPositions == 0) {
      return 0;
   }

   for(int i = 0; i < totalPositions; i++) {
      if(PositionSelectByTicket(PositionGetTicket(i))) {
         int positionMagic = (int)PositionGetInteger(POSITION_MAGIC); // Get the magic number of the order
         string symbol = PositionGetSymbol(i);
         if(positionMagic == magicNumber && symbol == Symbol()) { // Check if it matches the desired magic number
            countPosition++;
         }
      }
   }
   return countPosition;
}
//+------------------------------------------------------------------+
