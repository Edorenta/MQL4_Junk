/*         
          o=======================================o
         //                                       \\ 
         O              SideKick 1.2               O
        ||               by Edorenta               ||
        ||             (Paul de Renty)             ||                    
        ||           edorenta@gmail.com            ||
         O           __________________            O
         \\                                       //
          o=======================================o                                                               

*/
#property copyright     "Paul de Renty (Edorenta @ ForexFactory.com)"
#property link          "edorenta@gmail.com (mp me on FF rather than by email)"
#property description   ""
#property description   "Don't forget to optimize before use, you can"
#property description   "tweak the indicators and TP/SL set"
#property description   "to adapt to any pair and timeframe."
 
//--- show input parameters

string version = "Alpha 2";

extern int     magic_b1       = 1001; //Magic Buy Middle Kick
extern int     magic_s1       = 1002; //Magic Sell Middle Kick
extern int     magic_b2       = 1003; //Magic Buy Side Kick
extern int     magic_s2       = 1004; //Magic Sell Side Kick

extern double  lots        = 0.01;//Base Lots

extern bool hard_stop = false;    //Use Hard Stops

extern double SL = 200;           //Hard SL Pips
extern double TP = 100;           //Hard TP Pips
extern double TS = 100;           //Hard TS if != 0

extern bool r_exit = false;        //Exit if trend initiates

enum mm_mode       {classic       //Classic
                   ,mart          //Martingale
                   ,r_mart        //Reversed Mart
                   ,scale_in_p    //Scale-in Profit
                   ,scale_in_l    //Scale-in Loss
                   ,};
extern mm_mode mm = mart;         //Money-Management Type
extern double  multiplier  = 2;   //Martingale Multiplier
extern double  increment   = 0.01;//Scale-in Increment
extern int     max_nb      = 10;  //Max MM Level

extern int     max_trades_total = 6;  //Max Account Authorized Trades
extern int     max_trades_here = 3;   //Max Pair Authorized Trades
extern int     max_spread     = 10;   //Max spread in Points
extern int     countdown   = 4;       //Loss to reverse Position
extern bool    middle_kick = true;    //Enable Middle Kick
extern bool    side_kick = true;      //Enable Side Kick
extern double env_p = 25;             //Enveloppe filter Period
extern double env_d = 0.04;           //Enveloppe filter Deviation
extern ENUM_MA_METHOD env_mode = MODE_SMA; //Enveloppe MA Mode

extern double ma_p = 25;                  //Mid MA period (by default = enveloppe)
extern ENUM_MA_METHOD ma_mode = MODE_SMA; //MID MA type (by default = enveloppe)

extern bool show_popup = true;    //Show ea's name

int            last_bar    = 0;

int start(){

  if (((!IsOptimization()) && !IsTesting() && (!IsVisualMode())) || (show_popup && IsTesting() && (!IsOptimization()))) {
      Popup();
      }

   if (last_bar == Bars) return(0);
   last_bar = Bars;
   double spread = (Ask-Bid)/Point;
//--- Check if trade is open on this pair

   bool trade = false;
   int total,op_ec,i;
      string symbol;
      total = OrdersTotal();
      for(i=0;i<total;i++){
         OrderSelect(i,SELECT_BY_POS);
         if(OrderSymbol() == Symbol())op_ec++;
      }

   if(op_ec<max_trades_here && spread<max_spread) trade = true; //Abort! A Position For This Pair is Already Open

//--- Now start

double         last         = NormalizeDouble((Bid+Ask)/2,Digits);
double         lots_long   = 0,                    lots_short  = 0;

//------------------------//
// ---money management--- //
//------------------------//

double min_lots = MarketInfo(NULL,MODE_MINLOT);
double max_lots = MarketInfo(NULL,MODE_MAXLOT);
double max_invest = (AccountFreeMargin()*(AccountLeverage()))/MarketInfo(NULL,MODE_LOTSIZE);
double WinCount_b1 = 0, LossCount_b1 = 0, WinCount_s1 = 0, LossCount_s1 = 0, WinCount_b2 = 0, LossCount_b2 = 0, WinCount_s2 = 0, LossCount_s2 = 0;
double m_lots_b1 = lots, m_lots_s1 = lots, m_lots_b2 = lots, m_lots_s2 = lots;

     for (i = 0; i < OrdersHistoryTotal(); i++) 
	  {
	  //--- long loss counter
         if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
         if (OrderMagicNumber() == magic_b1 && OrderSymbol() == Symbol() && OrderProfit()>0)
          { WinCount_b1++; LossCount_b1=0;}
         if (OrderMagicNumber() == magic_b1 && OrderSymbol() == Symbol() && OrderProfit()<0) 
		    { LossCount_b1++; WinCount_b1=0;}
         if (WinCount_b1>=max_nb||LossCount_b1>=max_nb){ LossCount_b1 = 0; WinCount_b1 = 0 ;}
	  //--- short loss counter         
         if (OrderMagicNumber() == magic_s1 && OrderSymbol() == Symbol() && OrderProfit()>0)
          { WinCount_s1++; LossCount_s1=0;}
         if (OrderMagicNumber() == magic_s1 && OrderSymbol() == Symbol() && OrderProfit()<0) 
		    { LossCount_s1++; WinCount_s1=0;}
         if (WinCount_s1>=max_nb||LossCount_s1>=max_nb){ LossCount_s1 = 0; WinCount_s1 = 0 ;};
	  //--- long loss counter 2
         if (OrderMagicNumber() == magic_b2 && OrderSymbol() == Symbol() && OrderProfit()>0)
          { WinCount_b2++; LossCount_b2=0;}
         if (OrderMagicNumber() == magic_b2 && OrderSymbol() == Symbol() && OrderProfit()<0) 
		    { LossCount_b2++; WinCount_b2=0;}
         if (WinCount_b2>=max_nb||LossCount_b2>=max_nb){ LossCount_b2 = 0; WinCount_b2 = 0 ;}
	  //--- short loss counter 2  
         if (OrderMagicNumber() == magic_s2 && OrderSymbol() == Symbol() && OrderProfit()>0)
          { WinCount_s2++; LossCount_s2=0;}
         if (OrderMagicNumber() == magic_s2 && OrderSymbol() == Symbol() && OrderProfit()<0) 
		    { LossCount_s2++; WinCount_s2=0;}
         if (WinCount_s2>=max_nb||LossCount_s2>=max_nb){ LossCount_s2 = 0; WinCount_s2 = 0 ;};
     }
//---Martingale
switch(mm){
   case mart:
      if((OrdersHistoryTotal()!=0)){ m_lots_b1=NormalizeDouble(lots*(MathPow(multiplier,(LossCount_b1+1))),Digits);
                                     m_lots_s1=NormalizeDouble(lots*(MathPow(multiplier,(LossCount_s1+1))),Digits);
                                     m_lots_b2=NormalizeDouble(lots*(MathPow(multiplier,(LossCount_b2+1))),Digits);
                                     m_lots_s2=NormalizeDouble(lots*(MathPow(multiplier,(LossCount_s2+1))),Digits);}
   break;
//---Reversed Martingale
   case r_mart:
      if((OrdersHistoryTotal()!=0)){ m_lots_b1=NormalizeDouble(lots*(MathPow(multiplier,(WinCount_b1+1))),Digits);
                                     m_lots_s1=NormalizeDouble(lots*(MathPow(multiplier,(WinCount_s1+1))),Digits);
                                     m_lots_b2=NormalizeDouble(lots*(MathPow(multiplier,(WinCount_b2+1))),Digits);
                                     m_lots_s2=NormalizeDouble(lots*(MathPow(multiplier,(WinCount_s2+1))),Digits);}
   break;
//---Scale after loss (Fixed)
   case scale_in_p:
      if((OrdersHistoryTotal()!=0)){ m_lots_b1=lots+(increment*WinCount_b1);
                                     m_lots_s1=lots+(increment*WinCount_s1);
                                     m_lots_b2=lots+(increment*WinCount_b2);
                                     m_lots_s2=lots+(increment*WinCount_s2);}
   break;
//---Scale after win (Fixed)
   case scale_in_l:
      if((OrdersHistoryTotal()!=0)){ m_lots_b1=lots+(increment*LossCount_b1);
                                     m_lots_s1=lots+(increment*LossCount_s1);
                                     m_lots_b2=lots+(increment*LossCount_b2);
                                     m_lots_s2=lots+(increment*LossCount_s2);}                   
   break;
}           
               
      if(m_lots_b1<min_lots) m_lots_b1 = min_lots;
      if(m_lots_b1>=max_invest) m_lots_b1 = max_invest/2;
      
      if(m_lots_s1<min_lots) m_lots_s1 = min_lots;
      if(m_lots_s1>=max_invest) m_lots_s1 = max_invest/2;

      if(m_lots_b2<min_lots) m_lots_b2 = min_lots;
      if(m_lots_b2>=max_invest) m_lots_b2 = max_invest/2;
      
      if(m_lots_s2<min_lots) m_lots_s2 = min_lots;
      if(m_lots_s2>=max_invest) m_lots_s2 = max_invest/2;
        
//------------------//
//  ---strategy---  //
//------------------//

bool outter_range = false;
bool in_middle = false, from_top = false, from_bot = false, to_top=false,to_bot=false;
bool go_long = false, go_short = false, go_both=false;
int cycle_buy = 0, cycle_sell = 0;

//--- Indicators mapping

      double MID = iMA(Symbol(),0,ma_p,ma_mode,0,PRICE_WEIGHTED,0);
      double PMID = iMA(Symbol(),0,ma_p,ma_mode,0,PRICE_WEIGHTED,1);

      double ENV1 = iEnvelopes(Symbol(),0,env_p,env_mode,0,PRICE_WEIGHTED,env_d,MODE_UPPER,0);
      double ENV2 = iEnvelopes(Symbol(),0,env_p,env_mode,0,PRICE_WEIGHTED,env_d,MODE_LOWER,0);
      double PENV1 = iEnvelopes(Symbol(),0,env_p,env_mode,0,PRICE_WEIGHTED,env_d,MODE_UPPER,1);
      double PENV2 = iEnvelopes(Symbol(),0,env_p,env_mode,0,PRICE_WEIGHTED,env_d,MODE_LOWER,1);
      
      double slope;
      if(MID==0 || PMID ==0) slope =1; else slope = MID/PMID;
      
if(LossCount_s1>countdown||LossCount_s2>countdown) cycle_sell= -1;
if(LossCount_b1>countdown||LossCount_b2>countdown) cycle_buy = -1;


  Print(trade,side_kick,middle_kick,cycle_buy,cycle_sell);
  
/*      if (slope>1) m_lots_b = m_lots_b*2;
      if (slope<1) m_lots_s = m_lots_s*2; */
      
            
//--- Verify conditions

       if ((last>ENV1)||(last<ENV2)) outter_range = true;

       if (Close[1]>ENV1||Close[0]<ENV1 && Close[1]>ENV1) from_top = true;
       if (Close[1]<ENV2||Close[0]>ENV2 && Close[1]<ENV2) from_bot = true;
       
       if (last>ENV1 && Close[1]<ENV1) to_top = true;
       if (last<ENV2 && Close[1]>ENV2) to_bot = true;
 
       if (last==MID || last>MID && Close[1]<MID || last<MID && Close[1]>MID ||
           Close[0]>MID && Close[1]<MID || Close[0]<MID && Close[1]>MID) in_middle = true;  
  
//--- Trade if conditions match

double stoploss_s1, stoploss_b1, takeprofit_s1, takeprofit_b1, stoploss_s2, stoploss_b2, takeprofit_s2, takeprofit_b2;
      
if (hard_stop==false){stoploss_b1 = NormalizeDouble(Ask-(MID-ENV2),Digits);
                      stoploss_s1 = NormalizeDouble(Bid+(ENV1-MID),Digits); 
                      takeprofit_b1 = NormalizeDouble(Ask+(ENV1-MID),Digits);   
                      takeprofit_s1 = NormalizeDouble(Bid-(MID-ENV2),Digits);  
                      stoploss_b2 = NormalizeDouble(Ask-(ENV1-MID),Digits);
                      stoploss_s2 = NormalizeDouble(Bid+(ENV1-MID),Digits); 
                      takeprofit_b2 = NormalizeDouble(Ask+(ENV1-ENV2),Digits);   
                      takeprofit_s2 = NormalizeDouble(Bid-(ENV1-ENV2),Digits);
                      };
                      

      if (hard_stop==true) {stoploss_b1 = NormalizeDouble(Ask-(SL*Point),Digits);
                      stoploss_s1 = NormalizeDouble(Bid+(SL*Point),Digits); 
                      takeprofit_b1 = NormalizeDouble(Ask+(TP*Point),Digits);   
                      takeprofit_s1 = NormalizeDouble(Bid-(TP*Point),Digits);
                      stoploss_b2 = NormalizeDouble(Ask-(SL*Point),Digits);
                      stoploss_s2 = NormalizeDouble(Bid+(SL*Point),Digits); 
                      takeprofit_b2 = NormalizeDouble(Ask+(TP*Point),Digits);   
                      takeprofit_s2 = NormalizeDouble(Bid-(TP*Point),Digits);
                     }; 
      
         if (OrdersTotal() < max_trades_total && trade){
            if(side_kick==true){
               if (from_bot){
                  if(cycle_buy==0){OrderSend(Symbol(), OP_BUY, m_lots_b2 ,Ask, 0, stoploss_b2,takeprofit_b2, "SideKick - From Bot", magic_b2,0,Turquoise);};
                  if(cycle_buy==-1){OrderSend(Symbol(), OP_BUY, m_lots_s2 ,Ask, 0, stoploss_b2,takeprofit_b2, "SideKick - From Bot", magic_b2,0,Turquoise);};
                  Print(LossCount_b2,LossCount_b1);
               }
               if(from_top){
                  if(cycle_sell==0){OrderSend(Symbol(), OP_SELL, m_lots_s2 ,Bid, 0, stoploss_s2,takeprofit_s2, "SideKick - From Top", magic_s2,0,Magenta);};          
                  if(cycle_sell==-1){OrderSend(Symbol(), OP_SELL, m_lots_b2 ,Bid, 0, stoploss_s2,takeprofit_s2, "SideKick - From Top", magic_s2,0,Magenta);};           
                  Print(LossCount_s2,LossCount_s1);
               }
               if(to_top){
                  if(cycle_buy==0){OrderSend(Symbol(), OP_BUY, m_lots_b2 ,Ask, 0, stoploss_b2,takeprofit_b2, "SideKick - Cross Top", magic_b2,0,Turquoise);};
                  if(cycle_buy==-1){OrderSend(Symbol(), OP_BUY, m_lots_s2 ,Ask, 0, stoploss_b2,takeprofit_b2, "SideKick - Cross Top", magic_b2,0,Turquoise);};
                  Print(LossCount_b2,LossCount_b1);
               }
               if(to_bot){
                  if(cycle_sell==0){OrderSend(Symbol(), OP_SELL, m_lots_s2 ,Ask, 0, stoploss_s2,takeprofit_s2, "SideKick - Cross Bot", magic_s2,0,Turquoise);};
                  if(cycle_sell==-1){OrderSend(Symbol(), OP_SELL, m_lots_b2 ,Ask, 0, stoploss_s2,takeprofit_s2, "SideKick - Cross Bot", magic_s2,0,Turquoise);};
                  Print(LossCount_s2,LossCount_s1);
               }
            }
            if(middle_kick==true){
               if(in_middle){
                  if(cycle_buy==0){OrderSend(Symbol(), OP_BUY, m_lots_b1 ,Ask, 0, stoploss_b1,takeprofit_b1, "SideKick - Mid long swing", magic_b1,0,Turquoise);};
                  if(cycle_sell==0){OrderSend(Symbol(), OP_SELL, m_lots_s1 ,Bid, 0, stoploss_s1,takeprofit_s1, "SideKick - Mid short swing", magic_s1,0,Magenta);};          
                  if(cycle_buy==-1){OrderSend(Symbol(), OP_BUY, m_lots_s1 ,Ask, 0, stoploss_b1,takeprofit_b1, "SideKick - Mid long swing", magic_b1,0,Turquoise);};
                  if(cycle_sell==-1){OrderSend(Symbol(), OP_SELL, m_lots_b1 ,Bid, 0, stoploss_s1,takeprofit_s1, "SideKick - Mid short swing", magic_s1,0,Magenta);};           
               }
            }
         }
/*       ________________________________________________
         T                                              T
         T                 CLOSE RULES                  T
         T______________________________________________T
*/
  
  for(int cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL &&   
         OrderSymbol()==Symbol() &&
         (OrderMagicNumber()==magic_b1||OrderMagicNumber()==magic_s1||OrderMagicNumber()==magic_b2||OrderMagicNumber()==magic_s2)
         )  
        {
        //--- Close long
         if(OrderType()==OP_BUY)  
           {
              if(r_exit && last<=ENV2)
              {
                   OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,Turquoise);
              }
            if(TS>0)  
              {                 
               if(Bid-OrderOpenPrice()>Point*TS)
                 {
                  if(OrderStopLoss()<Bid-Point*TS)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*Point,OrderTakeProfit(),0,Turquoise);
                     return(0);
                    }
                 }
              }
           }
        //--- Close Short
         else 
           {
              if(r_exit && last>=ENV1)
              {
                 OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,Magenta);
              }
            if(TS>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*TS))
                 {
                  if((OrderStopLoss()>(Ask+Point*TS)) || (OrderStopLoss()==0))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TS,OrderTakeProfit(),0,Magenta);
                     return(0);
                    }
                 }
              }
           }
        }
     }
   return(0);
}
void Popup() {
   string name = version + "aaa";
   if (ObjectFind(name) == -1) {
      ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
      ObjectSet(name, OBJPROP_CORNER, 1);
      ObjectSet(name, OBJPROP_XDISTANCE, 10);
      ObjectSet(name, OBJPROP_YDISTANCE, 8);
   }
   ObjectSetText(name, "SideKick 1.2", 25, "Century Gothic", Orange);
}