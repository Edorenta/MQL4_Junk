/*         
          o=======================================o
         //                                       \\
         O                  KEOPS                  O
        ||               by Edorenta               ||
        ||             (Paul de Renty)             ||
        ||           edorenta@gmail.com            ||
         O           __________________            O
         \\                                       //
          o=======================================o
          
         ____________________________________________
         T                                          T
         T           INTRO & EXT. INPUTS            T
         T__________________________________________T
*/

#property copyright     "Paul de Renty (Edorenta @ ForexFactory.com)"
#property link          "edorenta@gmail.com (mp me on FF rather than by email)"
#property description   "Keops' Pyramid; Step-in, Scale-in, Burn!"
#property version       "0.3"
string    version =     "0.3";
#property strict
#include <stdlib.mqh>

string pyramid = "\n" 
+  "                     __.__         \n"
+  "                 __|____|__        \n"
+  "             __|____|____|__       \n"
+  "         __|____|____|____|__      \n"
+  "     __|____|____|____|____|__     \n"
+  " __|____|____|____|____|____|__    \n"
+  "|____|____|____|____|____|____|    \n";

extern string __1__ = "General Settings";

extern int magic = 101;                      //Magic Number
extern int slippage = 15;                    //Execution SLippage

extern bool use_long = true;                 //Enable Longs
extern bool use_short = true;                //Enable Shorts

enum stpm   {fixed_step                      //Fixed Step (Points) [CS0]
            ,pair_pct_step                   //Pair /10000 Step [CS1]
            ,hilo_pct_step                   //High-Low % Step [CS2]         
            ,atr_step                        //Pure ATR Step [CS3]
            ,sdev_step                       //Pure Standard Dev Step [CS4]
            ,hybrid_step                     //Above Hybrid Step [CS5]
            ,};
extern stpm step_mode = hybrid_step;         //Step Mode [Custom Step]

extern double step_pts = 20;                 //Step in Points [CS0]
extern double step_pct = 20;                 //Relative Step /10000 [CS1]
extern int hilo_p = 50;                      //High/Low Lookback [CS2]
extern double hilo_xtor = 0.25;              //Step as HiLo% [CS2]
extern int atr_p = 7;                        //ATR Lookback [CS3]
extern int sdev_p = 30;                      //SDEV Lookback [CS4]
extern double atr_x = 1;                     //Step Width Multiplier [CS3-4-5]
   
extern double tp_evol_xtor = 1.025;          //TP Increase Factor (1 = Static)

enum tgtm   {fixed_m_tgt                     //Fixed $$ [CT0]
            ,fixed_pct_tgt                   //Fixed K%(on init) [CT1]
            ,dynamic_pct_tqt                 //Dynamic K% [CT2]
            ,};     
extern tgtm tgt_mode = dynamic_pct_tqt;      //Target Calculation Mode [Custom Target]

extern double b_money = 1;                   //Base Money [Static Money $$]
extern double b_money_risk = 0.02;           //Base Risk Money [Dynamic Money %K $$]

enum mm     {classic                         //Classic [MM0]
            ,mart                            //Martingale [MM1]
            ,scale                           //Scale-in Loss [MM2]
            ,};
extern mm mm_mode = mart;                    //Money Management Mode [Custom MM]

extern double xtor = 1.6;                    //Martingale Target Multiplier [MM1]
extern double max_xtor = 30;                 //Max Multiplier [MM1]
extern double increment = 100;               //Scaler Target Increment % [MM2]
extern double max_increment = 1000;          //Max Increment % [MM2]

extern int max_trades = 7;                   //Max Recovery Trades
extern double emergency_stop_pc = 10;        //Hard Drawdown Stop (%K)
extern bool negative_margin = false;         //Allow Negative Margin

extern double daily_profit_pc = 5;           //Stop After Daily Profit (%K)
extern double daily_loss_pc = 5;             //Stop After Daily Loss (%K)
extern bool one_trade_per_bar = true;        //Only One Trade Per Bar
enum entm   {rnd_ent                         //Coin Flip Entry [CE0]
            ,rsi_ent                         //RSI Extremes Entry [CE1]
            ,adx_ent                         //ADX DI Entry [CE2]
            ,};
extern entm entry_mode = rnd_ent;            //Entry Mode [Custom Entry]

extern double flip_fqc = 50;                 //Probability of First Entry per Tick % [CE0]
extern int rsi_p = 12;                       //RSI Periods [CE1]
extern int rsi_xtm = 28;                     //RSI Extremes Condition /100 [CE1]
extern int adx_p = 20;                       //ADX Periods [CE2]
       int adxma_p = 25;                     //ADXMA Periods [CE2]
       ENUM_MA_METHOD adxma_type = MODE_SMA; //ADXMA type [CE2]

       bool ongoing_long = false;
       bool ongoing_short = false;
       
       double starting_equity = 0;
       int current_bar = 0;   
       
//        o-----------------------o
//        |    ON INIT TRIGGERS   |
//        o-----------------------o

int OnInit(){
   starting_equity = AccountEquity();
   EA_name();
   return(INIT_SUCCEEDED);
}

//        o-----------------------o
//        |   ON DEINIT TRIGGERS  |
//        o-----------------------o

/*
int OnDeinit(){
   return(0);
}
*/

//        o-----------------------o
//        |    ONTICK TRIGGERS    |
//        o-----------------------o

void OnTick(){

   check_if_close();
   
   if (current_bar != Bars && trading_authorized()==true) {
      int nb_longs = trades_info(1);
      int nb_shorts = trades_info(2);
      int nb_trades = trades_info(3);
      
      if(nb_trades == 0){
         first_trade();
      }
      
      if(nb_longs != 0){
         spam_long();
      }
      
      if(nb_shorts != 0){
         spam_short();
      }
      if (one_trade_per_bar==true)current_bar = Bars;
   }

    Comment(pyramid);
}

//        o-----------------------o
//        |    EMERGENCY CUTS     |
//        o-----------------------o

void check_if_close(){

   if(negative_margin==false && AccountFreeMargin()<=0) close_all();
   if((AccountEquity() - AccountBalance()) / AccountBalance() < - emergency_stop_pc/100) close_all();
   
}

void close_all(){

   for(int i=OrdersTotal()-1; i>=0; i--){
      OrderSelect(i,SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber() == magic){
         if(OrderType()==OP_BUY){
            OrderClose(OrderTicket(),OrderLots(),Bid,slippage,Turquoise);
         }
         if(OrderType()==OP_SELL){
            OrderClose(OrderTicket(),OrderLots(),Ask,slippage,Magenta);
         }
      }
   }
}

//        o-----------------------o
//        |      FIRST TRADE      |
//        o-----------------------o

void first_trade(){

   bool enter_long = false, enter_short = false;
   double last, spread;
   
   if (entry_mode==adx_ent){
      double DIP=iADX(Symbol(),0,adx_p,PRICE_CLOSE,MODE_PLUSDI,0);
      double DIM=iADX(Symbol(),0,adx_p,PRICE_CLOSE,MODE_MINUSDI,0);
      double PDIP=iADX(Symbol(),0,adx_p,PRICE_CLOSE,MODE_PLUSDI,1);
      double PDIM=iADX(Symbol(),0,adx_p,PRICE_CLOSE,MODE_MINUSDI,1);
   // double ADX=iADX(Symbol(),0,adx_p,PRICE_CLOSE,MODE_MAIN,0);
   // double PADX=iADX(Symbol(),0,adx_p,PRICE_CLOSE,MODE_MAIN,1);
   // double ADXMA=iCustom(Symbol(),0,"ADX+ADXMA",adx_p,adxma_p,adxma_type,1,0);
   // double PADXMA=iCustom(Symbol(),0,"ADX+ADXMA",adx_p,adxma_p,adxma_type,1,1);
      if(DIP>DIM && DIP>PDIP) enter_long = true;
      if(DIP<DIM && DIM>PDIM) enter_short = true;   
   }
   
   if(entry_mode==rsi_ent){
      double RSI = iRSI(Symbol(),0,rsi_p,PRICE_CLOSE,0);
      double PRSI = iRSI(Symbol(),0,rsi_p,PRICE_CLOSE,1);
      if(RSI>PRSI && RSI<(0+rsi_xtm)) enter_long = true;
      if(RSI<PRSI && RSI<(100-rsi_xtm)) enter_short = true;
   }
   
   if(entry_mode==rnd_ent){
      int random_number = ((MathRand()*100)/32768); //between 0 and 25 => buy; between 75 and 100 => sell
      if(random_number<0+(flip_fqc/2)) enter_long = true;
      if(random_number>100-(flip_fqc/2)) enter_short = true;
   }   

   if(enter_long && use_long)BUY();
   if(enter_short && use_short)SELL();
}

void BUY(){
   double nb_trades = trades_info(1);
   if (nb_trades ==0) nb_trades = 1;
   double TP = NormalizeDouble(STEP()*pow(tp_evol_xtor,nb_trades),Digits);
   double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;
   if (TP<stoplvl) TP = stoplvl;
   
   OrderSend(Symbol(),OP_BUY,lotsize(),Ask,slippage,0,Ask+TP,"Keops "+DoubleToStr(lotsize(),2)+" on "+Symbol(),magic,0,Turquoise);
   ongoing_long=true;
}

void SELL(){
   double nb_trades = trades_info(2);
   if (nb_trades ==0) nb_trades = 1;
   double TP = NormalizeDouble(STEP()*pow(tp_evol_xtor,nb_trades),Digits);
   double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;
   if (TP<stoplvl) TP = stoplvl;
   
   OrderSend(Symbol(),OP_SELL,lotsize(),Bid,slippage,0,Bid-TP,"Keops "+DoubleToStr(lotsize(),2)+" on "+Symbol(),magic,0,Magenta);
   ongoing_short=true;
}

//        o-----------------------o
//        |   SPAM OTHER TRADES   |
//        o-----------------------o

void spam_long(){
   double nb_trades = trades_info(3);
   if (nb_trades ==0) nb_trades = 1;
   double TP = NormalizeDouble(STEP()*pow(tp_evol_xtor,nb_trades),Digits);
   double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;
   if (TP<stoplvl) TP = stoplvl;
   
   if (ongoing_long == true && trades_info(1)<max_trades){
      if (Bid<= (trades_info(4)-STEP())){
         OrderSend(Symbol(),OP_BUY,lotsize(),Ask,slippage,0,0,"Keops "+DoubleToStr(lotsize(),2)+" on "+Symbol(),magic,0,Turquoise);
         
         for(int i=0;i<OrdersTotal();i++){
            if(OrderMagicNumber()==magic && OrderSymbol()==Symbol()&& OrderType()==OP_BUY){
               OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
               OrderModify(OrderTicket(),OrderOpenPrice(),0,Ask+TP,0,Turquoise);
            }
         }
      }
   }
}

void spam_short(){
   double nb_trades = trades_info(3);
   if (nb_trades ==0) nb_trades = 1;
   double TP = NormalizeDouble(STEP()*pow(tp_evol_xtor,nb_trades),Digits);
   double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;
   if (TP<stoplvl) TP = stoplvl;
   
   if (ongoing_short == true && trades_info(2)<max_trades){
      if (Ask>= (trades_info(7)+STEP())){
         OrderSend(Symbol(),OP_SELL,lotsize(),Bid,slippage,0,0,"Keops "+DoubleToStr(lotsize(),2)+" on "+Symbol(),magic,0,Magenta);
         
         for(int i=0;i<OrdersTotal();i++){
            if(OrderMagicNumber()==magic && OrderSymbol()==Symbol()&& OrderType()==OP_SELL){
               OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
               OrderModify(OrderTicket(),OrderOpenPrice(),0,Bid-TP,0,Magenta);
            }
         }
      }
   }
}

   
//        o----------------------o
//        | S/L COUNTER FUNCTION |
//        o----------------------o

double trades_info(int key){

   double nb_longs = 0, nb_shorts = 0, nb_trades = 0, nb = 0;
   double buy_min = 0, buy_max = 0, sell_min = 0, sell_max = 0;
   
   for(int i=OrdersTotal()-1; i>=0; i--){
      OrderSelect(i,SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber() == magic){
         if(OrderType()==OP_BUY){
            nb_longs++;
            if(OrderOpenPrice()<buy_min || buy_min==0){
               buy_min=OrderOpenPrice();
            }
            if(OrderOpenPrice()>buy_max || buy_min==0){
               buy_max=OrderOpenPrice();
            }
         }
         if(OrderType()==OP_SELL){
            nb_shorts++;
            if(OrderOpenPrice()>sell_max || sell_max==0){
               sell_max=OrderOpenPrice();
            }
            if(OrderOpenPrice()<sell_min || sell_min==0){
               sell_min=OrderOpenPrice();
            }
         }
      }
   }

   nb_trades = nb_longs + nb_shorts;
   
   switch(key){
      case 1:
         nb = nb_longs;
      break;
      case 2:
         nb = nb_shorts;
      break;   
      case 3:
         nb = nb_trades;
      break;
      case 4:
         nb = buy_min;
      break;
      case 5:
         nb = buy_max;
      break;   
      case 6:
         nb = sell_min;
      break;
      case 7:
         nb = sell_max;
      break;
   }
   return(nb);
}

//        o----------------------o
//        | TARGET CALC FUNCTION |
//        o----------------------o

double STEP(){
   
   double steplvl, pair1, hi_px, lo_px, hilo1, atr1, atr2, atr3, sdev1, sdev2, sdev3;
   int hi_shift, lo_shift;
   
   double freezelvl = MarketInfo(Symbol(),MODE_FREEZELEVEL)*Point;
   double spread = MarketInfo(Symbol(),MODE_SPREAD)*Point;
            
   if(step_mode==fixed_step) steplvl = step_pts*Point;
   if(step_mode==pair_pct_step|| step_mode==hybrid_step){
      double pair1 = ((step_pct*Bid*10))*Point/10;
      steplvl = pair1;
   }
   if(step_mode==hilo_pct_step || step_mode==hybrid_step){
      hi_shift = iHighest(Symbol(),0,MODE_HIGH,hilo_p,0);
      hi_px = iHigh(Symbol(),0,hi_shift);
      lo_shift = iLowest(Symbol(),0,MODE_LOW,hilo_p,0);
      lo_px = iLow(Symbol(),0,lo_shift);
      hilo1 = (hi_px-lo_px)*hilo_xtor;
      steplvl = NormalizeDouble(hilo1,Digits);
   }
   if(step_mode==atr_step || step_mode==hybrid_step){
      atr1 = iATR(Symbol(),0,atr_p,0);
      atr2 = iATR(Symbol(),0,2*atr_p,0);
      atr3 = ((atr1+atr2)/2)*atr_x;
      steplvl = NormalizeDouble(atr3,Digits);
   }
   if(step_mode==sdev_step || step_mode==hybrid_step){
      sdev1 = iStdDev(Symbol(),0,sdev_p,0,MODE_LWMA,PRICE_CLOSE,0);
      sdev2 = iStdDev(Symbol(),0,sdev_p*2,0,MODE_LWMA,PRICE_CLOSE,0);
      sdev3 = ((sdev1+sdev2)/2)*atr_x;
      steplvl = NormalizeDouble(sdev3,Digits);
   }  
   if(step_mode==hybrid_step){
      steplvl = NormalizeDouble((hilo1+2*atr3+2*sdev3*2+pair1)/8,Digits);
   }

   if (spread >= (steplvl/2)) steplvl = spread*2; 
   if (freezelvl >= steplvl) steplvl = freezelvl;

return(steplvl);
}

//        o----------------------o
//        | TARGET CALC FUNCTION |
//        o----------------------o

/*
double TP(){
   double nb_trades = trades_info(3);
   if (nb_trades==0) nb_trades=1;
   double step = STEP();
   double stoplvl = MarketInfo(Symbol(),MODE_STOPLEVEL)*Point;
   double tplvl = NormalizeDouble(step*(pow(tp_evol_xtor,nb_trades)),Digits);
   
   if (stoplvl>tplvl) tplvl=stoplvl;
   
   Comment(tplvl, "   ",step, "   ",nb_trades);
   return(step);
}
*/
//        o----------------------o
//        |  LOTS CALC FUNCTION  |
//        o----------------------o

double lotsize(){

   int nb_longs = trades_info(1);
   int nb_shorts = trades_info(2);
   int nb_trades = trades_info(3);
   double temp_lots, risk_to_SL, mlots = 0;
   double equity = AccountEquity();
   double margin = AccountFreeMargin();
   double maxlot = MarketInfo(Symbol(),MODE_MAXLOT);
   double minlot = MarketInfo(Symbol(),MODE_MINLOT);
   double pip_value = MarketInfo(Symbol(),MODE_TICKVALUE);
   double pip_size = MarketInfo(Symbol(),MODE_TICKSIZE);
   int leverage = AccountLeverage();
   double TP = STEP()*pow(tp_evol_xtor,nb_trades);
   
   risk_to_SL = TP*(pip_value/pip_size);

   switch(tgt_mode){
      case fixed_m_tgt: 
         if(TP!=0){
            temp_lots = NormalizeDouble(b_money/(risk_to_SL),2);
         }
      break;
      case fixed_pct_tgt:
         if(TP!=0){
            temp_lots = NormalizeDouble((b_money_risk*starting_equity)/(risk_to_SL*1000),2);
         }
      break;
      case dynamic_pct_tqt:
         if(TP!=0){
            temp_lots = NormalizeDouble((b_money_risk*equity)/(risk_to_SL*1000),2);
         }
      break;
   }
   
   if (temp_lots < minlot) temp_lots = minlot;
   if (temp_lots > maxlot) temp_lots = maxlot;
   
   switch(mm_mode){
      case mart:
         mlots=NormalizeDouble(temp_lots*(MathPow(xtor,(nb_trades+1))),2);
         if(mlots>temp_lots*max_xtor) mlots = NormalizeDouble(temp_lots*max_xtor,2);
      break;
      case scale:
         mlots=temp_lots+((increment/100)*nb_trades)*temp_lots;
         if(mlots>temp_lots*(1+(max_increment/100))) mlots = temp_lots*(1+(max_increment/100));
      break;
      case classic:
         mlots=temp_lots;
      break;
   }
   
   if (mlots < minlot) mlots = minlot;
   if (mlots > maxlot) mlots = maxlot;
   
return(mlots);
}

//        o----------------------o
//        | TRADE FILTR FUNCTION |
//        o----------------------o

bool trading_authorized(){
   int trade_condition = 1;
   
   if(trade_today()==false) trade_condition = 0;
   
   if(trade_condition==1){
      return(true);
   }
   else{
      return(false);
   }
}

bool trade_today(){
   
   double profit_today = earnings(0);
   double profit_pct_today = profit_today/(AccountEquity()-profit_today);
//   Comment("Profit today : " + profit_today + " % : " + profit_pct_today);

   if(profit_today==0 || profit_pct_today <= daily_profit_pc/100 || profit_pct_today >= daily_loss_pc/100){
      return(true);
   }
   else{
      return(false);
   }
} 

double earnings(int shift) {
   double aggregated_profit = 0;
   for (int position = 0; position < OrdersHistoryTotal(); position++) {
      if (!(OrderSelect(position, SELECT_BY_POS, MODE_HISTORY))) break;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic)
         if (OrderCloseTime() >= iTime(Symbol(), PERIOD_D1, shift) && OrderCloseTime() < iTime(Symbol(), PERIOD_D1, shift) + 86400) aggregated_profit = aggregated_profit + OrderProfit() + OrderCommission() + OrderSwap();
   }
   return (aggregated_profit);
}

//        o----------------------o
//        |   EA NAME FUNCTION   |
//        o----------------------o

void EA_name() {
   string txt1 = "txt 1";
   if (ObjectFind(txt1) == -1) {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 0);
      ObjectSet(txt1, OBJPROP_XDISTANCE, 27);
      ObjectSet(txt1, OBJPROP_YDISTANCE, 105);
   }
   ObjectSetText(txt1, "KEOPS",25, "Century Gothic", Gold);
   
   txt1 = "txt 2";
   if (ObjectFind(txt1) == -1) {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 0);
      ObjectSet(txt1, OBJPROP_XDISTANCE, 17);
      ObjectSet(txt1, OBJPROP_YDISTANCE, 146);
   }
   ObjectSetText(txt1, "by Edorenta || version " + version, 8, "Arial", Gray);
   
   txt1 = "txt 3";
   if (ObjectFind(txt1) == -1) {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 0);
      ObjectSet(txt1, OBJPROP_XDISTANCE, 10);
      ObjectSet(txt1, OBJPROP_YDISTANCE, 127);
   }
   ObjectSetText(txt1, "_________________", 11, "Arial", Gray);

   txt1 = "txt 4";
   if (ObjectFind(txt1) == -1) {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 0);
      ObjectSet(txt1, OBJPROP_XDISTANCE, 10);
      ObjectSet(txt1, OBJPROP_YDISTANCE, 147);
   }
   ObjectSetText(txt1, "_________________", 11, "Arial", Gray);
}

/*       ____________________________________________
         T                                          T
         T                 THE END                  T
         T__________________________________________T
*/
  