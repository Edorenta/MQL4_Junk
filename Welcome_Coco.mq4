//+------------------------------------------------------------------+
//|                                                       Test_2.mq4 |
//|                                                         Edorenta |
//|                                                http://algamma.us |
//+------------------------------------------------------------------+

double prev_price = 0;
double last_price = 0;
double lotsize = 0.02;
double multi_sell = 1;
double multi_buy = 1;
double last_buy;
double last_sell;
int nb_buy = 0;
int nb_sell = 0;
int magic_buy = 100;
int magic_sell = 200;
int target;
int max_buy = 32;
int max_sell = 32;

int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   Comment("Target: " + target + "\nProfit buy: " + profit_buy() + "\nProfit sell: " + profit_sell()); 
   bool cond_buy = false;
   bool cond_sell = false;
   
   if (profit_buy() >= target)
      close_buy();
   if (profit_sell() >= target)
      close_sell();
   target = 10*lotsize;
   prev_price = last_price;
   last_price = Close[0];

   if (nb_buy == 0 || (profit_buy() <= -target*(pow(nb_buy+1, 3)))) cond_buy = true;
   if (nb_sell == 0 || (profit_sell() <= -target*(pow(nb_sell+1, 3)))) cond_sell = true;
   
   if ((last_price > prev_price) && (nb_buy <= max_buy) && cond_buy)
      buy();
   if ((last_price < prev_price) && (nb_sell <= max_sell) && cond_sell)
      sell();
}

void buy()
{
   nb_buy++;
   double ask = Ask;
   if (OrderSend(Symbol(),OP_BUY, lotsize*(nb_buy*multi_buy), Ask, 0, 0, 0, "Ordre sur EURUSD", magic_buy, 0, Cyan) == -1)
      Print ("Error Sending Order");
   else
      last_buy = ask;
}

void sell()
{
   nb_sell++;
   double bid = Bid;
   if (OrderSend(Symbol(),OP_SELL, lotsize*(nb_sell*multi_sell), Bid, 0, 0, 0, "Ordre sur EURUSD", magic_sell, 0, Magenta) == -1)
      Print ("Error Sending Order");
   else
      last_sell = bid;
}

void close_buy()
{
   int i;
   
   for (i = 0; i <= OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))continue;
      if (OrderMagicNumber() == magic_buy && OrderSymbol() == Symbol())
         if (OrderClose(OrderTicket(), lotsize, Bid, 0, Magenta) == false)
            Print ("Error Closing Order");
         else
            nb_buy--;
   }
   if (nb_buy != 0)
   {
      Print ("Warning: Order buy close number mismatch");
      nb_buy = 0;
   }
   multi_buy = 1;
}

void close_sell()
{
   int i;

   for (i = 0; i <= OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))continue;
      if (OrderMagicNumber() == magic_sell && OrderSymbol() == Symbol())
         if (OrderClose(OrderTicket(), lotsize, Ask, 0, Cyan) == false)
            Print ("Error Closing Order");
         else
            nb_sell--;
   }
   {
      Print ("Warning: Order sell close number mismatch");
      nb_sell = 0;
   }
   multi_sell = 1;
}

double profit_buy()
{
   int i;
   double profit;
   
   for (i = 0; i <= OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))continue;
      if (OrderMagicNumber() == magic_buy && OrderSymbol() == Symbol())
         profit += OrderProfit() + OrderCommission() + OrderSwap();
   }
   return (profit);
}

double profit_sell()
{
   int i;
   double profit;
   
   for (i = 0; i <= OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))continue;
      if (OrderMagicNumber() == magic_sell && OrderSymbol() == Symbol())
         profit += OrderProfit() + OrderCommission() + OrderSwap();
   }
   return (profit);
}
