/*      .=====================================.
       /               Keops v2                \
      |               by Edorenta               |
       \          Range Pyramidal Bot          /
        '====================================='
*/

#property copyright     "Paul de Renty (Edorenta @ ForexFactory.com)"
#property link          "edorenta@gmail.com (mp me on FF rather than by email)"
#property description   "Keops v2 : deep range incremental trading"
#property version       "2.4"
string version =        "2.4";
#property strict
#include <stdlib.mqh>

//        o-----------------------o
//        |   EXTERNAL SETTINGS   |
//        o-----------------------o

extern string __0__ = "---------------------------------------------------------------------------------------------------------"; //[------------   GENERAL SETTINGS   ------------]

extern bool one_trade_per_bar = true;        //Only One Trade Per Bar
extern bool use_long = true;                 //Enable Longs
extern bool use_short = true;                //Enable Shorts

extern string __1__ = "---------------------------------------------------------------------------------------------------------"; //[------------   ENTRY SETTINGS   ------------]

enum entm   {rnd_ent                         //Coin Flip Entry [CE0]
            ,rsi_ent                         //RSI Extremes Entry [CE1]
            ,adx_ent                         //ADX DI Entry [CE2]
            ,};
extern entm entry_mode = rnd_ent;            //Entry Mode [Custom Entry]

extern double flip_fqc = 100;                //Probability of First Entry per Tick % [CE0]
extern int rsi_p = 12;                       //RSI Lookback [CE1]
extern int rsi_xtm = 28;                     //RSI Extremes Condition /100 [CE1]
extern int adx_p = 20;                       //ADX Lookback [CE2]
       int adxma_p = 25;                     //ADXMA Lookback [CE2]
       ENUM_MA_METHOD adxma_type = MODE_SMA; //ADXMA type [CE2]

extern string __2__ = "---------------------------------------------------------------------------------------------------------"; //[------------   TREND FILTER SETTINGS   ------------]

extern bool use_filter = true;                //Enable Trend Filter
extern bool use_filter_in_cycle = false;      //Enable Trend Filter In Cycle
extern bool filter_closes_cycle = false;      //Filter Closes Cycle

enum fltrm  {sdev_filter                     //SDEV / ATR Volatility Filter [CF0]
            ,hilo_filter                     //HiLo Volatility [CF1]
            ,adxma_filter                    //ADXMA Volatility Filter [CF2]
            ,adx_filter                      //ADX DI+/- Trend Filter [CF3]
            ,rsi_filter                      //RSI Trend Filter [CF4]
            ,ma_slope_filter                 //MA Slope Trend Filter [CF5]
            ,ma_lvl_filter                   //MA to Price Trend Filter [CF6]
            ,};
extern fltrm filter_mode = adxma_filter;            //Trend Filter Mode [Custom Filter]

extern int sdev_filter_p = 40;                      //SDEV/ATR Filter Lookback [CF0]
extern int sdev_filter_xtm = 25;                    //SDEV/ATR Threshold Factor % [CF0]
extern int hilo_filter_p = 40;                      //High/Low Channel Lookback [CF1]
extern int hilo_filter_shift = 5;                   //High/Low Channel Shift [CF1]
extern int adx_filter_p = 40;                       //ADX Lookback [CF2-3]
extern int adxma_filter_p = 15;                     //ADXMA Filter Lookback [CF2]
extern ENUM_MA_METHOD adxma_filter_type = MODE_SMA; //ADXMA Filter Type [CF2]
extern int rsi_filter_p = 50;                       //RSI Filter Lookback [CF2-4]
extern int rsi_filter_xtm = 46;                     //RSI Filter Extremes [CF2-4]
extern int ma_filter_p = 60;                        //MA Filter Lookback [CF5-6]
extern ENUM_MA_METHOD ma_filter_type = MODE_LWMA;   //MA Filter Type [CF5-6]

extern string __3__ = "---------------------------------------------------------------------------------------------------------"; //[------------   STEP SETTINGS   ------------]

enum stpm   {fixed_step                      //Fixed Step (Points) [CS0]
            ,pair_pct_step                   //Pair /10000 Step [CS1]
            ,hilo_pct_step                   //High-Low % Step [CS2]         
            ,atr_step                        //Pure ATR Step [CS3]
            ,sdev_step                       //Pure Standard Dev Step [CS4]
            ,hybrid_step                     //Above Hybrid Step [CS5]
            ,};
extern stpm step_mode = hybrid_step;         //Step Mode [Custom Step]

extern double step_pts = 20;                 //Step in Points [CS0]
extern double step_pct = 8;                  //Relative Step /10000 [CS1]
extern int hilo_p = 50;                      //High/Low Lookback [CS2]
extern double hilo_xtor = 0.33;              //Step as HiLo% [CS2]
extern int atr_p = 10;                       //ATR Lookback [CS3]
extern int sdev_p = 20;                      //SDEV Lookback [CS4]
extern double atr_x = 1;                     //Vol Step Width Multiplier [CS3-4-5]
extern double step_x2 = 1.02;                //Step Width Increase Factor [CS3-4-5]

extern string __4__ = "---------------------------------------------------------------------------------------------------------"; //[------------   TARGET SETTINGS   ------------]

extern double tp_evol_xtor = 1.015;          //TP/Step Increase Factor (1 = Static)

enum tgtm   {fixed_m_tgt                     //Fixed (€/$) [CT0]
            ,fixed_pct_tgt                   //Fixed K%(on init) [CT1]
            ,dynamic_pct_tqt                 //Dynamic K% [CT2]
            ,};     
extern tgtm tgt_mode = dynamic_pct_tqt;      //Target Calculation Mode [Custom Target]
enum bem    {use_be_target                   //TP at Breakeven + Target
            ,use_average                     //TP at average Target/BE
            ,use_be                          //TP at Breakeven
            ,no_be                           //Classic TP
            ,};
extern bem breakeven_mode = use_be;          //B-E Min Profit Lock-in

extern double b_money = 1.5;                 //Base Money [Static Money (€/$)]
extern double b_money_risk = 0.04;           //Base Risk Money [Dynamic Money %K]

extern string __5__ = "---------------------------------------------------------------------------------------------------------"; //[------------   SCALE SETTINGS   ------------]

enum mm     {classic                         //Classic [MM0]
            ,mart                            //Martingale [MM1]
            ,scale                           //Scale-in Loss [MM2]
            ,};
extern mm mm_mode = mart;                    //Money Management Mode [Custom MM]

extern int mm_step = 1;                      //MM Trades Step
extern int mm_step_start = 4;                //MM Step Starting Trade
extern int mm_step_end = 20;                 //MM Step Ending Trade
extern double xtor = 1.6;                    //Martingale Target Multiplier [MM1]
extern double increment = 100;               //Scaler Target Increment % [MM2]

extern string __6__ = "---------------------------------------------------------------------------------------------------------"; //[------------   RISK SETTINGS   ------------]

extern double max_xtor = 60;                 //Max Multiplier [MM1]
extern double max_increment = 1000;          //Max Increment % [MM2]

extern int max_trades = 10;                   //Max Recovery Trades
extern bool use_hard_acc_stop = false;       //Enable Hard Account Stops
extern double emergency_acc_stop_pc = 25;    //Hard Account Drawdown Stop (%K)
extern double emergency_acc_stop = 500;      //Hard Account Drawdown Stop (€/$)
extern bool use_hard_ea_stop = true;         //Enable Hard EA Stops
extern double emergency_ea_stop_pc = 25;     //Hard EA Drawdown Stop (%K)
extern double emergency_ea_stop = 500;       //Hard EA Drawdown Stop (€/$)

extern bool negative_margin = false;         //Allow Negative Margin

extern double daily_profit_pc = 5;           //Stop After Daily Profit (%K)
extern double daily_loss_pc = 5;             //Stop After Daily Loss (%K)

extern string __7__ = "---------------------------------------------------------------------------------------------------------"; //[------------   BROKER & TIME SETTINGS   ------------]

extern bool ECN_orders = false;              //ECN Order Execution
extern int max_spread = 30;                  //Max Spread (Points)
extern bool use_max_spread_in_cycle = false; //Enable Max Spread In Cycle
extern int magic = 101;                      //Magic Number
extern int slippage = 15;                    //Execution Slippage

extern bool use_local_time = true;                 //Use Local Time (no = Server Time) [NOT YET]
extern string trade_start_time = "0:00";           //Trade From [NOT YET]
extern string trade_stop_time = "23:59";           //Trade To [NOT YET]
extern string weekdays_to_trade = "1,2,3,4,5,6,7"; //Weekdays to Trade


extern string __8__ = "---------------------------------------------------------------------------------------------------------"; //[------------   GUI SETTINGS   ------------]

extern bool use_buttons = false;                    //Show Buttons
extern bool show_gui = false;                       //Show The EA GUI
extern color color1 = LightGray;                    //EA's name color
extern color color2 = DarkOrange;                   //EA's balance & info color
extern color color3 = Turquoise;                    //EA's profit color
extern color color4 = Magenta;                      //EA's loss color

extern string __9__ = "---------------------------------------------------------------------------------------------------------"; //[------------   OTHER   ------------]

extern int nb_pass = 10;                            //Pass numbers for Random Entries

extern string _____ = "COMING SOON";

//Data count variables initialization

      double max_acc_dd = 0;
      double max_acc_dd_pc = 0;
      double max_dd = 0;
      double max_dd_pc = 0;
      double max_acc_runup = 0;
      double max_acc_runup_pc = 0;
      double max_runup = 0;
      double max_runup_pc = 0;
      int max_chain_win = 0;
      int max_chain_loss = 0;
      int max_histo_spread = 0;
      double target_long = 0;
      double target_short = 0;
      bool ongoing_long = false;
      bool ongoing_short = false;
      bool enter_long, enter_short;
      double starting_equity = 0;
      int current_bar = 0;
      bool trade_on_button = true;
/*
      string pyramid = "\n" 
      +  "                     __.__         \n"
      +  "                 __|____|__        \n"
      +  "             __|____|____|__       \n"
      +  "         __|____|____|____|__      \n"
      +  "     __|____|____|____|____|__     \n"
      +  " __|____|____|____|____|____|__    \n"
      +  "|____|____|____|____|____|____|    \n";
*/
      string button1_name = "close_all_button";
      string button1_txt = "CLOSE ALL";
      string button2_name = "close_long_button";
      string button2_txt = "CLOSE BUY";
      string button3_name = "close_short_button";
      string button3_txt = "CLOSE SELL";
      string button4_name = "activate_button";
      string button4_txt1 = "DISABLE";
      string button4_txt2 = "ENABLE";
//        o-----------------------o
//        |    ON INIT TRIGGERS   |
//        o-----------------------o

int OnInit() {

    starting_equity = AccountEquity();
    if (show_gui) {
        HUD();
    }
    EA_name();

    if (use_buttons == true) {
        create_close_all_button();
        create_close_long_button();
        create_close_short_button();
        create_activate_button();
    }
    RefreshRates();
    WindowRedraw();
    return (INIT_SUCCEEDED);
}

//        o-----------------------o
//        |   ON DEINIT TRIGGERS  |
//        o-----------------------o

int OnDeinit() {
    return (0);
}

//        o-----------------------o
//        |   ON EVENT TRIGGERS   |
//        o-----------------------o

void OnChartEvent(const int id, // Event identifier  
    const long & lparam, // Event parameter of long type
        const double & dparam, // Event parameter of double type
            const string & sparam) { // Event parameter of string type

    if (id == CHARTEVENT_OBJECT_CLICK) {
        if (sparam == button1_name) { // Close button has been pressed
            close_all();
            ObjectSetInteger(0, button1_name, OBJPROP_STATE, false);
        }
        if (sparam == button2_name) { // Close button has been pressed
            close_long();
            ObjectSetInteger(0, button2_name, OBJPROP_STATE, false);
        }
        if (sparam == button3_name) { // Close button has been pressed
            close_short();
            ObjectSetInteger(0, button3_name, OBJPROP_STATE, false);
        }
        if (sparam == button4_name) { // Close button has been pressed
            //         Comment("Trading Authorized : ", trade_on_button);
            if (ObjectGetInteger(0, button4_name, OBJPROP_STATE) == true) {
                ObjectSetString(0, button4_name, OBJPROP_TEXT, button4_txt1);
                ObjectSetInteger(0, button4_name, OBJPROP_COLOR, Black);
                ObjectSetInteger(0, button4_name, OBJPROP_BGCOLOR, color3);
                ObjectSetInteger(0, button4_name, OBJPROP_BORDER_COLOR, color4);
                trade_on_button = true;
            }
            if (ObjectGetInteger(0, button4_name, OBJPROP_STATE) == false) {
                ObjectSetString(0, button4_name, OBJPROP_TEXT, button4_txt2);
                ObjectSetInteger(0, button4_name, OBJPROP_COLOR, Black);
                ObjectSetInteger(0, button4_name, OBJPROP_BGCOLOR, color2);
                ObjectSetInteger(0, button4_name, OBJPROP_BORDER_COLOR, color4);
                trade_on_button = false;
            }
        }
    }
}

//        o-----------------------o
//        |    ONTICK TRIGGERS    |
//        o-----------------------o

void OnTick() {

    if (show_gui) {
        GUI();
    }
    check_if_close();

    if (current_bar != Bars) {
        if (trading_authorized() == true) {
            int nb_longs = trades_info(1);
            int nb_shorts = trades_info(2);
            int nb_trades = nb_longs + nb_shorts;

            if (nb_longs == 0) {
                first_trade(1);
            }

            if (nb_shorts == 0) {
                first_trade(2);
            }

            if (nb_longs != 0 && enter_long == true) {
                if (ECN_orders == true) {
                    spam_long_ECN();
                } else {
                    spam_long();
                }
            }

            if (nb_shorts != 0 && enter_short == true) {
                if (ECN_orders == true) {
                    spam_short_ECN();
                } else {
                    spam_short();
                }
            }
        }
        if (one_trade_per_bar == true) current_bar = Bars;
    }
    //   Comment("Trading Authorized : ", trading_authorized());
    // Comment(pyramid);
}

//        o-----------------------o
//        |    EMERGENCY CUTS     |
//        o-----------------------o

void check_if_close() {
    //   Comment(data_counter(15) / AccountBalance());
    if (filter_closes_cycle == true && filter_off() == false) close_all();
    if (filter_closes_cycle == true && enter_long == false) close_long();
    if (filter_closes_cycle == true && enter_short == false) close_short();

    if (negative_margin == false && AccountFreeMargin() <= 0) close_all();

    if (use_hard_acc_stop) {
        if ((AccountEquity() - AccountBalance()) / AccountBalance() < -emergency_acc_stop_pc / 100) close_all();
        if ((AccountEquity() - AccountBalance()) < -emergency_acc_stop) close_all();
    }
    if (use_hard_ea_stop) {
        if ((data_counter(15) / AccountBalance()) < -emergency_ea_stop_pc / 100) {
            close_all();
        }
        if ((data_counter(15)) < -emergency_ea_stop) {
            close_all();
        }
    }
}

void close_all() {

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (OrderType() == OP_BUY) {
                OrderClose(OrderTicket(), OrderLots(), Bid, slippage, Turquoise);
            }
            if (OrderType() == OP_SELL) {
                OrderClose(OrderTicket(), OrderLots(), Ask, slippage, Magenta);
            }
        }
    }
}
void close_long() {

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (OrderType() == OP_BUY) {
                OrderClose(OrderTicket(), OrderLots(), Bid, slippage, Turquoise);
            }
        }
    }
}
void close_short() {

        for (int i = OrdersTotal() - 1; i >= 0; i--) {
            OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
                if (OrderType() == OP_SELL) {
                    OrderClose(OrderTicket(), OrderLots(), Ask, slippage, Magenta);
                }
            }
        }
    }
    //        o-----------------------o
    //        |      FIRST TRADE      |
    //        o-----------------------o

void first_trade(int key) {

    bool enter_long_2 = false, enter_short_2 = false;
    double last, spread;

    if (entry_mode == adx_ent) {
        double DIP = iADX(Symbol(), 0, adx_p, PRICE_CLOSE, MODE_PLUSDI, 0);
        double DIM = iADX(Symbol(), 0, adx_p, PRICE_CLOSE, MODE_MINUSDI, 0);
        double PDIP = iADX(Symbol(), 0, adx_p, PRICE_CLOSE, MODE_PLUSDI, 1);
        double PDIM = iADX(Symbol(), 0, adx_p, PRICE_CLOSE, MODE_MINUSDI, 1);
        // double ADX=iADX(Symbol(),0,adx_p,PRICE_CLOSE,MODE_MAIN,0);
        // double PADX=iADX(Symbol(),0,adx_p,PRICE_CLOSE,MODE_MAIN,1);
        // double ADXMA=iCustom(Symbol(),0,"ADX+ADXMA",adx_p,adxma_p,adxma_type,1,0);
        // double PADXMA=iCustom(Symbol(),0,"ADX+ADXMA",adx_p,adxma_p,adxma_type,1,1);
        if (DIP > DIM && DIP > PDIP) enter_long_2 = true;
        if (DIP < DIM && DIM > PDIM) enter_short_2 = true;
    }

    if (entry_mode == rsi_ent) {
        double RSI = iRSI(Symbol(), 0, rsi_p, PRICE_CLOSE, 0);
        double PRSI = iRSI(Symbol(), 0, rsi_p, PRICE_CLOSE, 1);
        if (RSI > PRSI && RSI < (0 + rsi_xtm)) {
            enter_long_2 = true;
        }
        if (RSI < PRSI && RSI > (100 - rsi_xtm)) {
            enter_short_2 = true;
        }
    }

    if (entry_mode == rnd_ent) {
        int random_number = ((MathRand() * 100) / 32768); //between 0 and 25 => buy; between 75 and 100 => sell
        if (random_number < 0 + (flip_fqc / 2)) {
            enter_long_2 = true;
        }
        if (random_number > 100 - (flip_fqc / 2)) {
            enter_short_2 = true;
        }
        //   Comment(random_number,"    ",flip_fqc,"    ",enter_long,"    ",enter_long_2,"    ",use_long);
    }

    if (key == 1 && enter_long_2 && enter_long && use_long) {
        if (ECN_orders == true) {
            BUY_ECN();
        } else {
            BUY();
        }
    }
    if (key == 2 && enter_short_2 && enter_short && use_short) {
        if (ECN_orders == true) {
            SELL_ECN();
        } else {
            SELL();
        }
    }
}

void BUY() {
    int ticket;
    double TP = NormalizeDouble(TP_long(), Digits);
    ticket = OrderSend(Symbol(), OP_BUY, lotsize_long(), Ask, slippage, 0, Ask + TP, "Keops " + DoubleToStr(lotsize_long(), 2) + " on " + Symbol(), magic, 0, Turquoise);
    if (ticket < 0) {
        Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
    }
}

void BUY_ECN() {

    int ticket;
    double TP = NormalizeDouble(TP_long(), Digits);
    ticket = OrderSend(Symbol(), OP_BUY, lotsize_long(), Ask, slippage, 0, 0, "Keops " + DoubleToStr(lotsize_long(), 2) + " on " + Symbol(), magic, 0, Turquoise);
    if (ticket < 0) {
        Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
    }
    for (int i = 0; i < OrdersTotal(); i++) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
            OrderModify(OrderTicket(), OrderOpenPrice(), 0, Ask + TP, 0, Turquoise);
        }
    }
    //   if(show_gui){calc_target();}
}

void SELL() {
    int ticket;
    double TP = NormalizeDouble(TP_short(), Digits);
    ticket = OrderSend(Symbol(), OP_SELL, lotsize_short(), Bid, slippage, 0, Bid - TP, "Keops " + DoubleToStr(lotsize_short(), 2) + " on " + Symbol(), magic, 0, Magenta);
    if (ticket < 0) {
        Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
    }
}
void SELL_ECN() {
    int ticket;
    double TP = NormalizeDouble(TP_short(), Digits);
    ticket = OrderSend(Symbol(), OP_SELL, lotsize_short(), Bid, slippage, 0, 0, "Keops " + DoubleToStr(lotsize_short(), 2) + " on " + Symbol(), magic, 0, Magenta);
    if (ticket < 0) {
        Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
    }
    for (int i = 0; i < OrdersTotal(); i++) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
            OrderModify(OrderTicket(), OrderOpenPrice(), 0, Bid - TP, 0, Magenta);
        }
    }
    //   if(show_gui){calc_target();}
}

//        o-----------------------o
//        |   SPAM OTHER TRADES   |
//        o-----------------------o

void spam_long_ECN() {
    if (trades_info(3) < max_trades) {
        if (Bid <= (trades_info(4) - STEP())) {
            BUY_ECN();
        }
    }
}

void spam_long() {
    double TP = NormalizeDouble(TP_long(), Digits);
    if (trades_info(3) < max_trades) {
        if (Bid <= (trades_info(4) - STEP())) {
            int ticket = OrderSend(Symbol(), OP_BUY, lotsize_long(), Ask, slippage, 0, 0, "Keops " + DoubleToStr(lotsize_long(), 2) + " on " + Symbol(), magic, 0, Turquoise);
            if (ticket < 0) {
                Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
            }
            for (int i = 0; i < OrdersTotal(); i++) {
                OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
                if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                    OrderModify(OrderTicket(), OrderOpenPrice(), 0, Ask + TP, 0, Turquoise);
                }
            }
        }
    }
}

void spam_short_ECN() {
    if (trades_info(3) < max_trades) {
        if (Ask >= (trades_info(7) + STEP())) {
            SELL_ECN();
        }
    }
}

void spam_short() {
    double TP = NormalizeDouble(TP_short(), Digits);
    if (trades_info(3) < max_trades) {
        if (Ask >= (trades_info(7) + STEP())) {
            int ticket = OrderSend(Symbol(), OP_SELL, lotsize_short(), Bid, slippage, 0, 0, "Keops " + DoubleToStr(lotsize_short(), 2) + " on " + Symbol(), magic, 0, Magenta);
            if (ticket < 0) {
                Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
            }
            for (int i = 0; i < OrdersTotal(); i++) {
                OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
                if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
                    OrderModify(OrderTicket(), OrderOpenPrice(), 0, Bid - TP, 0, Magenta);
                }
            }
        }
    }
}

//        o----------------------o
//        | S/L COUNTER FUNCTION |
//        o----------------------o

double trades_info(int key) {

    double nb_longs = 0, nb_shorts = 0, nb_trades = 0, nb = 0;
    double buy_min = 0, buy_max = 0, sell_min = 0, sell_max = 0;

    for (int i = OrdersTotal(); i >= 0; i--) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (OrderType() == OP_BUY) {
                nb_longs++;
                if (OrderOpenPrice() < buy_min || buy_min == 0) {
                    buy_min = OrderOpenPrice();
                }
                if (OrderOpenPrice() > buy_max || buy_min == 0) {
                    buy_max = OrderOpenPrice();
                }
            }
            if (OrderType() == OP_SELL) {
                nb_shorts++;
                if (OrderOpenPrice() > sell_max || sell_max == 0) {
                    sell_max = OrderOpenPrice();
                }
                if (OrderOpenPrice() < sell_min || sell_min == 0) {
                    sell_min = OrderOpenPrice();
                }
            }
        }
    }

    nb_trades = nb_longs + nb_shorts;

    switch (key) {
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
    return (nb);
}

//        o----------------------o
//        | TARGET CALC FUNCTION |
//        o----------------------o

double STEP() {

    double steplvl, pair1, hi_px, lo_px, hilo1, atr1, atr2, atr3, sdev1, sdev2, sdev3;
    int hi_shift, lo_shift;
    double point = 0.00001;

    double freezelvl = MarketInfo(Symbol(), MODE_FREEZELEVEL) * Point;
    double spread = MarketInfo(Symbol(), MODE_SPREAD) * Point;

    if (step_mode == fixed_step) steplvl = step_pts * Point;
    if (step_mode == pair_pct_step || step_mode == hybrid_step) {
        double pair1 = ((step_pct * Bid)) * point;
        steplvl = pair1;
    }
    if (step_mode == hilo_pct_step || step_mode == hybrid_step) {
        hi_shift = iHighest(Symbol(), 0, MODE_HIGH, hilo_p, 0);
        hi_px = iHigh(Symbol(), 0, hi_shift);
        lo_shift = iLowest(Symbol(), 0, MODE_LOW, hilo_p, 0);
        lo_px = iLow(Symbol(), 0, lo_shift);
        hilo1 = (hi_px - lo_px) * hilo_xtor;
        steplvl = NormalizeDouble(hilo1, Digits);
    }
    if (step_mode == atr_step || step_mode == hybrid_step) {
        atr1 = iATR(Symbol(), 0, atr_p, 0);
        atr2 = iATR(Symbol(), 0, 2 * atr_p, 0);
        atr3 = ((atr1 + atr2) / 2) * atr_x;
        steplvl = NormalizeDouble(atr3, Digits);
    }
    if (step_mode == sdev_step || step_mode == hybrid_step) {
        sdev1 = iStdDev(Symbol(), 0, sdev_p, 0, MODE_LWMA, PRICE_CLOSE, 0);
        sdev2 = iStdDev(Symbol(), 0, sdev_p * 2, 0, MODE_LWMA, PRICE_CLOSE, 0);
        sdev3 = ((sdev1 + sdev2) / 2) * atr_x;
        steplvl = NormalizeDouble(sdev3, Digits);
    }
    if (step_mode == hybrid_step) {
        steplvl = NormalizeDouble((hilo1 + 2 * atr3 + 2 * sdev3 * 2 + pair1) / 8, Digits);
    }

    steplvl = steplvl * (pow(step_x2, trades_info(3)));

    if (spread >= (steplvl / 2)) steplvl = spread * 2;
    if (freezelvl >= steplvl) steplvl = freezelvl;

    return (steplvl);
}

//        o----------------------o
//        | TARGET CALC FUNCTION |
//        o----------------------o
double breakeven_long() {

    double avg_px, lots_long, lots_short, price_long, price_short, weight_long, weight_short;

    if (trades_info(3) != 0) {
        lots_long = data_counter(21);
        price_long = data_counter(19);

        if (lots_long != 0) {
            avg_px = NormalizeDouble(price_long / lots_long, Digits); //avg buying price
        }
    }
    return (avg_px);
}

double breakeven_short() {

    double avg_px, lots_long, lots_short, price_long, price_short, weight_long, weight_short;

    if (trades_info(3) != 0) {
        lots_short = data_counter(22);
        price_short = data_counter(20);

        if (lots_short != 0) {
            avg_px = NormalizeDouble(price_short / lots_short, Digits); //avg selling price
        }
    }
    return (avg_px);
}

double TP_long() {

    double BE, tplvl;
    double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
    double spread = Ask - Bid;
    int nb_longs;
    int nb_shorts;

    if (trades_info(1) != 0) {
        nb_longs = trades_info(1);
    }
    if (trades_info(2) != 0) {
        nb_shorts = trades_info(2);
    }

    double nb_trades = trades_info(3);
    double tp_offset = NormalizeDouble(STEP() * pow(tp_evol_xtor, nb_trades), Digits);

    BE = tp_offset;

    if (trades_info(1) != 0) {
        switch (breakeven_mode) {
        case use_average:
            BE = (2 * MathAbs(breakeven_long() - Ask) + tp_offset + spread) / 3;
            break;
        case use_be:
            BE = (breakeven_long() - Ask) + spread;
            break;
        case use_be_target:
            BE = MathAbs(breakeven_long() - Ask) + (tp_offset / nb_longs);
            break;
        case no_be:
            BE = (tp_offset);
            break;
        }
    }
    tplvl = BE;

    if (tplvl < stoplvl) {
        tplvl = stoplvl;
    }

    return (tplvl);
}

double TP_short() {

    double BE, tplvl;
    double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
    double spread = Ask - Bid;
    int nb_longs;
    int nb_shorts;

    if (trades_info(1) != 0) {
        nb_longs = trades_info(1);
    }
    if (trades_info(2) != 0) {
        nb_shorts = trades_info(2);
    }

    double nb_trades = trades_info(3);
    double tp_offset = NormalizeDouble(STEP() * pow(tp_evol_xtor, nb_trades), Digits);

    BE = tp_offset;

    if (trades_info(2) != 0) {
        switch (breakeven_mode) {
        case use_average:
            BE = (2 * MathAbs(Bid - breakeven_short()) + tp_offset + spread) / 3;
            break;
        case use_be:
            BE = (Bid - breakeven_short()) + spread;
            break;
        case use_be_target:
            BE = MathAbs(Bid - breakeven_short()) + (tp_offset / nb_shorts);
            break;
        case no_be:
            BE = (tp_offset);
            break;
        }
    }
    tplvl = BE;

    if (tplvl < stoplvl) {
        tplvl = stoplvl;
    }

    return (tplvl);
}

//        o----------------------o
//        |  LOTS CALC FUNCTION  |
//        o----------------------o

double lotsize_long() {

    int nb_longs = trades_info(1);

    int trade_step = nb_longs;

    if (mm_step > 1) {
        if (nb_longs >= mm_step_start && nb_longs <= mm_step_end) {
            trade_step = MathCeil(nb_longs / mm_step);
        }
    }

    double temp_lots, risk_to_SL, mlots = 0;
    double equity = AccountEquity();
    double margin = AccountFreeMargin();
    double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
    double minlot = MarketInfo(Symbol(), MODE_MINLOT);
    double pip_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    double pip_size = MarketInfo(Symbol(), MODE_TICKSIZE);
    int leverage = AccountLeverage();
    double TP = STEP() * pow(tp_evol_xtor, nb_longs);

    risk_to_SL = TP * (pip_value / pip_size);

    if (TP != 0) {
        switch (tgt_mode) {
        case fixed_m_tgt:
            temp_lots = NormalizeDouble(b_money / (risk_to_SL), 2);
            break;
        case fixed_pct_tgt:
            temp_lots = NormalizeDouble((b_money_risk * starting_equity) / (risk_to_SL * 1000), 2);
            break;
        case dynamic_pct_tqt:
            temp_lots = NormalizeDouble((b_money_risk * equity) / (risk_to_SL * 1000), 2);
            break;
        }
    }

    if (temp_lots < minlot) temp_lots = minlot;
    if (temp_lots > maxlot) temp_lots = maxlot;

    switch (mm_mode) {
    case mart:
        mlots = NormalizeDouble(temp_lots * (MathPow(xtor, (trade_step))), 2);
        if (mlots > temp_lots * max_xtor) mlots = NormalizeDouble(temp_lots * max_xtor, 2);
        break;
    case scale:
        mlots = temp_lots + ((increment / 100) * trade_step) * temp_lots;
        if (mlots > temp_lots * (1 + (max_increment / 100))) mlots = temp_lots * (1 + (max_increment / 100));
        break;
    case classic:
        mlots = temp_lots;
        break;
    }

    if (mlots < minlot) mlots = minlot;
    if (mlots > maxlot) mlots = maxlot;

    return (mlots);
}

double lotsize_short() {

    int nb_shorts = trades_info(2);

    int trade_step = nb_shorts;

    if (mm_step > 1) {
        if (nb_shorts >= mm_step_start && nb_shorts <= mm_step_end) {
            trade_step = MathCeil(nb_shorts / mm_step);
        }
    }

    double temp_lots, risk_to_SL, mlots = 0;
    double equity = AccountEquity();
    double margin = AccountFreeMargin();
    double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
    double minlot = MarketInfo(Symbol(), MODE_MINLOT);
    double pip_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    double pip_size = MarketInfo(Symbol(), MODE_TICKSIZE);
    int leverage = AccountLeverage();
    double TP = STEP() * pow(tp_evol_xtor, nb_shorts);

    risk_to_SL = TP * (pip_value / pip_size);

    if (TP != 0) {
        switch (tgt_mode) {
        case fixed_m_tgt:
            temp_lots = NormalizeDouble(b_money / (risk_to_SL), 2);
            break;
        case fixed_pct_tgt:
            temp_lots = NormalizeDouble((b_money_risk * starting_equity) / (risk_to_SL * 1000), 2);
            break;
        case dynamic_pct_tqt:
            temp_lots = NormalizeDouble((b_money_risk * equity) / (risk_to_SL * 1000), 2);
            break;
        }
    }

    if (temp_lots < minlot) temp_lots = minlot;
    if (temp_lots > maxlot) temp_lots = maxlot;

    switch (mm_mode) {
    case mart:
        mlots = NormalizeDouble(temp_lots * (MathPow(xtor, (trade_step))), 2);
        if (mlots > temp_lots * max_xtor) mlots = NormalizeDouble(temp_lots * max_xtor, 2);
        break;
    case scale:
        mlots = temp_lots + ((increment / 100) * trade_step) * temp_lots;
        if (mlots > temp_lots * (1 + (max_increment / 100))) mlots = temp_lots * (1 + (max_increment / 100));
        break;
    case classic:
        mlots = temp_lots;
        break;
    }

    if (mlots < minlot) mlots = minlot;
    if (mlots > maxlot) mlots = maxlot;

    return (mlots);
}

void calc_target() {

    double pip_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    double pip_size = MarketInfo(Symbol(), MODE_TICKSIZE);
    double profit_long = data_counter(24);
    double profit_short = data_counter(25);
    double TP_value_long = TP_long() * (pip_value / pip_size);
    double TP_value_short = TP_short() * (pip_value / pip_size);
    double lots_long = data_counter(21);
    double lots_short = data_counter(22);
    double gross_target_long = profit_long + lots_long * TP_value_long;
    double gross_target_short = profit_short + lots_short * TP_value_short;

    target_long = gross_target_long;
    target_short = gross_target_short;

}

//        o----------------------o
//        | TRADE FILTR FUNCTION |
//        o----------------------o

bool trading_authorized() {

    int trade_condition = 1;

    if (trade_today() == false) trade_condition = 0;
    if (spread_okay() == false) trade_condition = 0;
    if (filter_off() == false) trade_condition = 0;
    if (trade_on_button == false) trade_condition = 0;

    if (trade_condition == 1) {
        return (true);
    } else {
        return (false);
    }
}

bool spread_okay() {
    bool spread_filter_off = true;
    if (use_max_spread_in_cycle == true && trades_info(3) > 0 || trades_info(3) == 0) {
        if (MarketInfo(Symbol(), MODE_SPREAD) >= max_spread) {
            spread_filter_off = false;
        }
    }
    return (spread_filter_off);
}

bool filter_off() {

    bool filter_off = true;

    if (use_filter == true) {
        if (filter_mode == sdev_filter) {
            enter_long = true;
            enter_short = true;

            double atr = iATR(Symbol(), 0, sdev_filter_p, 0);
            double sdev = iStdDev(Symbol(), 0, sdev_filter_p, 0, MODE_LWMA, PRICE_CLOSE, 0);

            if (sdev >= NormalizeDouble(atr * (1 + (sdev_filter_xtm / 100)), Digits)) {
                filter_off = false;
            }
        }

        if (filter_mode == hilo_filter) {
            enter_long = true;
            enter_short = true;
            // New Higher High !!!

            int hi_shift = iHighest(Symbol(), 0, MODE_HIGH, hilo_filter_p, 0);
            int phi_shift = iHighest(Symbol(), 0, MODE_HIGH, hilo_filter_p, hilo_filter_shift);
            double hi_px = iHigh(Symbol(), 0, hi_shift);
            double phi_px = iHigh(Symbol(), 0, phi_shift);

            if (hi_shift != phi_shift) {
                filter_off = false;
            }

            // New Lower Low !!!

            int lo_shift = iLowest(Symbol(), 0, MODE_LOW, hilo_filter_p, 0);
            int plo_shift = iLowest(Symbol(), 0, MODE_LOW, hilo_filter_p, hilo_filter_shift);
            double lo_px = iLow(Symbol(), 0, lo_shift);
            double plo_px = iLow(Symbol(), 0, plo_shift);

            if (lo_shift != plo_shift) {
                filter_off = false;
            }
        }
        if (filter_mode == adxma_filter) {
            enter_long = true;
            enter_short = true;

            double ADX = iADX(Symbol(), 0, adx_filter_p, PRICE_CLOSE, MODE_MAIN, 0);
            double PADX = iADX(Symbol(), 0, adx_filter_p, PRICE_CLOSE, MODE_MAIN, 1);
            double ADXMA = iCustom(Symbol(), 0, "ADX+ADXMA", adx_filter_p, adxma_filter_p, adxma_filter_type, 1, 0);
            double PADXMA = iCustom(Symbol(), 0, "ADX+ADXMA", adx_filter_p, adxma_filter_p, adxma_filter_type, 1, 1);

            if (ADX >= PADX && ADX >= ADXMA) {
                filter_off = false;
            }
        }
        if (filter_mode == adx_filter) {
            double DIP = iADX(Symbol(), 0, adx_filter_p, PRICE_CLOSE, MODE_PLUSDI, 0);
            double DIM = iADX(Symbol(), 0, adx_filter_p, PRICE_CLOSE, MODE_MINUSDI, 0);

            if (DIP > DIM) {
                enter_long = true;
                enter_short = false;
            }
            if (DIP < DIM) {
                enter_long = false;
                enter_short = true;
            }
        }
        if (filter_mode == ma_slope_filter) {
            double MA = iMA(Symbol(), 0, ma_filter_p, 0, ma_filter_type, PRICE_CLOSE, 0);
            double PMA = iMA(Symbol(), 0, ma_filter_p, 0, ma_filter_type, PRICE_CLOSE, 1);
            double MA_slope = 1;
            if (PMA > 0) MA_slope = MA / PMA;

            if (MA_slope > 1) {
                enter_long = true;
                enter_short = false;
            }
            if (MA_slope < 1) {
                enter_long = false;
                enter_short = true;
            }
        }
        if (filter_mode == ma_lvl_filter) {
            double MA = iMA(Symbol(), 0, ma_filter_p, 0, ma_filter_type, PRICE_CLOSE, 0);
            double PMA = iMA(Symbol(), 0, ma_filter_p, 0, ma_filter_type, PRICE_CLOSE, 1);

            if (Ask > MA) {
                enter_long = true;
                enter_short = false;
            }
            if (Bid < MA) {
                enter_long = false;
                enter_short = true;
            }
        }
        if (filter_mode == rsi_filter) {
            double RSI = iRSI(Symbol(), 0, rsi_filter_p, PRICE_CLOSE, 0);
            double PRSI = iRSI(Symbol(), 0, rsi_filter_p, PRICE_CLOSE, 1);
            if (RSI > (100 - rsi_filter_xtm)) {
                enter_long = false;
                enter_short = true;
            }
            if (RSI < (0 + rsi_filter_xtm)) {
                enter_long = true;
                enter_short = false;
            }
        }
    }
    if (use_filter == false || (use_filter_in_cycle == false && trades_info(3) != 0)) {
        enter_long = true;
        enter_short = true;
        filter_off = true;
    }
    return (filter_off);
}

bool trade_today() {

    double profit_today = Earnings(0);
    double profit_pct_today = profit_today / (AccountEquity() - profit_today);
    //   Comment("Profit today : " + profit_today + " % : " + profit_pct_today);

    if (profit_today == 0 || profit_pct_today <= daily_profit_pc / 100 || profit_pct_today >= daily_loss_pc / 100) {
        return (true);
    } else {
        return (false);
    }
}

double Earnings(int shift) {
    double aggregated_profit = 0;
    for (int position = 0; position < OrdersHistoryTotal(); position++) {
        if (!(OrderSelect(position, SELECT_BY_POS, MODE_HISTORY))) break;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic)
            if (OrderCloseTime() >= iTime(Symbol(), PERIOD_D1, shift) && OrderCloseTime() < iTime(Symbol(), PERIOD_D1, shift) + 86400) aggregated_profit = aggregated_profit + OrderProfit() + OrderCommission() + OrderSwap();
    }
    return (aggregated_profit);
}

//        o----------------------o
//        |    GET OTHER DATA    |
//        o----------------------o

double data_counter(int key) {

    double count_tot = 0, balance = AccountBalance(), equity = AccountEquity();
    double drawdown = 0, runup = 0, lots = 0, profit = 0;

    switch (key) {

    case (1): //All time wins counter
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0) {
                count_tot++;
            }
        }
        break;

    case (2): //All time loss counter
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0) {
                count_tot++;
            }
        }
        break;

    case (3): //All time profit
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
            count_tot = profit;
        }
        break;

    case (4): //All time lots
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                lots = lots + OrderLots();
            }
            count_tot = lots;
        }
        break;

    case (5): //Chain Loss
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0) {
                count_tot++;
            }
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0) {
                count_tot = 0;
            }
            //         if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit()<0 && count_tot>max_risk_trades) count_tot = 0;
        }
        break;

    case (6): //Chain Win
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0) {
                count_tot++;
            }
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0) {
                count_tot = 0;
            }
            //         if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit()>0 && count_tot>max_risk_trades) count_tot = 0;
        }
        break;

    case (7): //Chart Drawdown % (if equity < balance)
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        if (profit > 0) drawdown = 0;
        else drawdown = NormalizeDouble((profit / balance) * 100, 2);
        count_tot = drawdown;
        break;

    case (8): //Acc Drawdown % (if equity < balance)
        if (equity >= balance) drawdown = 0;
        else drawdown = NormalizeDouble(((equity - balance) * 100) / balance, 2);
        count_tot = drawdown;
        break;

    case (9): //Chart dd money (if equity < balance)
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        if (profit >= 0) drawdown = 0;
        else drawdown = profit;
        count_tot = drawdown;
        break;

    case (10): //Acc dd money (if equiy < balance)
        if (equity >= balance) drawdown = 0;
        else drawdown = equity - balance;
        count_tot = drawdown;
        break;

    case (11): //Chart Runup %
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        if (profit < 0) runup = 0;
        else runup = NormalizeDouble((profit / balance) * 100, 2);
        count_tot = runup;
        break;

    case (12): //Acc Runup %
        if (equity < balance) runup = 0;
        else runup = NormalizeDouble(((equity - balance) * 100) / balance, 2);
        count_tot = runup;
        break;

    case (13): //Chart runup money
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        if (profit < 0) runup = 0;
        else runup = profit;
        count_tot = runup;
        break;

    case (14): //Acc runup money
        if (equity < balance) runup = 0;
        else runup = equity - balance;
        count_tot = runup;
        break;

    case (15): //Current profit here
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        count_tot = profit;
        break;

    case (16): //Current profit acc
        count_tot = AccountProfit();
        break;

    case (17): //Gross profits
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        count_tot = profit;
        break;

    case (18): //Gross loss
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        count_tot = profit;
        break;

    case (19): //(average buying price longs)
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                count_tot = count_tot + OrderLots() * (OrderOpenPrice());
            }
        }
        break;

    case (20): //(average buying price shorts)
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
                count_tot = count_tot + OrderLots() * (OrderOpenPrice());
            }
        }
        break;

    case (21): //Current lots long
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                count_tot = count_tot + OrderLots();
            }
        }
        break;

    case (22): //Current lots short
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
                count_tot = count_tot + OrderLots();
            }
        }
        break;

    case (23): //Current lots all
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                count_tot = count_tot + OrderLots();
            }
        }
        break;

    case (24): //Current profit here Long
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        count_tot = profit;
        break;

    case (25): //Current profit here Short
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        count_tot = profit;
        break;
    }
    return (count_tot);
}

/*       ____________________________________________
         T                                          T
         T                DESIGN GUI                T
         T__________________________________________T
*/

//--- HUD Rectangle
void HUD() {
    ObjectCreate(ChartID(), "HUD", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    //--- set label coordinates
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_XDISTANCE, 0);
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_YDISTANCE, 28);
    //--- set label size
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_XSIZE, 280);
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_YSIZE, 600);
    //--- set background color
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_BGCOLOR, clrBlack);
    //--- set border type
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    //--- set the chart's corner, relative to which point coordinates are defined
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_CORNER, 4);
    //--- set flat border color (in Flat mode)
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_COLOR, clrWhite);
    //--- set flat border line style
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_STYLE, STYLE_SOLID);
    //--- set flat border width
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_WIDTH, 1);
    //--- display in the foreground (false) or background (true)
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_BACK, false);
    //--- enable (true) or disable (false) the mode of moving the label by mouse
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_SELECTED, false);
    //--- hide (true) or display (false) graphical object name in the object list
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_HIDDEN, false);
    //--- set the priority for receiving the event of a mouse click in the chart
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_ZORDER, 0);
}

void create_close_all_button() {
    ObjectCreate(0, button1_name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, button1_name, OBJPROP_XDISTANCE, 290);
    ObjectSetInteger(0, button1_name, OBJPROP_YDISTANCE, 28);
    ObjectSetInteger(0, button1_name, OBJPROP_XSIZE, 140);
    ObjectSetInteger(0, button1_name, OBJPROP_YSIZE, 60);
    ObjectSetString(0, button1_name, OBJPROP_TEXT, button1_txt);
    ObjectSetInteger(0, button1_name, OBJPROP_COLOR, color2);
    ObjectSetInteger(0, button1_name, OBJPROP_BGCOLOR, Black);
    ObjectSetInteger(0, button1_name, OBJPROP_BORDER_COLOR, color2);
    ObjectSetInteger(0, button1_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, button1_name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, button1_name, OBJPROP_STATE, false);
    ObjectSetInteger(0, button1_name, OBJPROP_FONTSIZE, 15);
}

void create_close_long_button() {
    ObjectCreate(0, button2_name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, button2_name, OBJPROP_XDISTANCE, 290);
    ObjectSetInteger(0, button2_name, OBJPROP_YDISTANCE, 94);
    ObjectSetInteger(0, button2_name, OBJPROP_XSIZE, 140);
    ObjectSetInteger(0, button2_name, OBJPROP_YSIZE, 60);
    ObjectSetString(0, button2_name, OBJPROP_TEXT, button2_txt);
    ObjectSetInteger(0, button2_name, OBJPROP_COLOR, color3);
    ObjectSetInteger(0, button2_name, OBJPROP_BGCOLOR, Black);
    ObjectSetInteger(0, button2_name, OBJPROP_BORDER_COLOR, color3);
    ObjectSetInteger(0, button2_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, button2_name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, button2_name, OBJPROP_STATE, false);
    ObjectSetInteger(0, button2_name, OBJPROP_FONTSIZE, 15);
}

void create_close_short_button() {
    ObjectCreate(0, button3_name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, button3_name, OBJPROP_XDISTANCE, 290);
    ObjectSetInteger(0, button3_name, OBJPROP_YDISTANCE, 158);
    ObjectSetInteger(0, button3_name, OBJPROP_XSIZE, 140);
    ObjectSetInteger(0, button3_name, OBJPROP_YSIZE, 60);
    ObjectSetString(0, button3_name, OBJPROP_TEXT, button3_txt);
    ObjectSetInteger(0, button3_name, OBJPROP_COLOR, color4);
    ObjectSetInteger(0, button3_name, OBJPROP_BGCOLOR, Black);
    ObjectSetInteger(0, button3_name, OBJPROP_BORDER_COLOR, color4);
    ObjectSetInteger(0, button3_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, button3_name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, button3_name, OBJPROP_STATE, false);
    ObjectSetInteger(0, button3_name, OBJPROP_FONTSIZE, 15);
}

void create_activate_button() {
    ObjectCreate(0, button4_name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, button4_name, OBJPROP_XDISTANCE, 290);
    ObjectSetInteger(0, button4_name, OBJPROP_YDISTANCE, 222);
    ObjectSetInteger(0, button4_name, OBJPROP_XSIZE, 140);
    ObjectSetInteger(0, button4_name, OBJPROP_YSIZE, 60);
    ObjectSetString(0, button4_name, OBJPROP_TEXT, button4_txt1);
    ObjectSetInteger(0, button4_name, OBJPROP_COLOR, Black);
    ObjectSetInteger(0, button4_name, OBJPROP_BGCOLOR, color2);
    ObjectSetInteger(0, button4_name, OBJPROP_BORDER_COLOR, color2);
    ObjectSetInteger(0, button4_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, button4_name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, button4_name, OBJPROP_STATE, false);
    ObjectSetInteger(0, button4_name, OBJPROP_FONTSIZE, 15);
}

void GUI() {

    int total_wins = data_counter(1);
    int total_loss = data_counter(2);
    int total_trades = total_wins + total_loss;
    int total_opened_trades = trades_info(3);

    double total_profit = data_counter(3);
    double total_volumes = data_counter(4);
    int chain_loss = data_counter(5);
    int chain_win = data_counter(6);

    double chart_dd_pc = data_counter(7);
    double acc_dd_pc = data_counter(8);
    double chart_dd = data_counter(9);
    double acc_dd = data_counter(10);

    double chart_runup_pc = data_counter(11);
    double acc_runup_pc = data_counter(12);
    double chart_runup = data_counter(13);
    double acc_runup = data_counter(14);

    double chart_profit = data_counter(15);
    double acc_profit = data_counter(16);

    double gross_profits = data_counter(17);
    double gross_loss = data_counter(18);

    //pnl vs profit factor
    double profit_factor;
    if (gross_loss != 0 && gross_profits != 0) profit_factor = NormalizeDouble(gross_profits / MathAbs(gross_loss), 2);

    //Total volumes vs Average
    double av_volumes;
    if (total_volumes != 0 && total_trades != 0) av_volumes = NormalizeDouble(total_volumes / total_trades, 2);

    //Total trades vs winrate
    int winrate;
    if (total_trades != 0) winrate = (total_wins * 100 / total_trades);

    //Relative DD vs Max DD %
    if (chart_dd_pc < max_dd_pc) max_dd_pc = chart_dd_pc;
    if (acc_dd_pc < max_acc_dd_pc) max_acc_dd_pc = acc_dd_pc;
    //Relative DD vs Max DD $$
    if (chart_dd < max_dd) max_dd = chart_dd;
    if (acc_dd < max_acc_dd) max_acc_dd = acc_dd;

    //Relative runup vs Max runup %
    if (chart_runup_pc > max_runup_pc) max_runup_pc = chart_runup_pc;
    if (acc_runup_pc > max_acc_runup_pc) max_acc_runup_pc = acc_runup_pc;
    //Relative runup vs Max runup $$
    if (chart_runup > max_runup) max_runup = chart_runup;
    if (acc_runup > max_acc_runup) max_acc_runup = acc_runup;

    //Spread vs Maxspread
    if (MarketInfo(Symbol(), MODE_SPREAD) > max_histo_spread) max_histo_spread = MarketInfo(Symbol(), MODE_SPREAD);

    //Chains vs Max chains
    if (chain_loss > max_chain_loss) max_chain_loss = chain_loss;
    if (chain_win > max_chain_win) max_chain_win = chain_win;

    //--- Currency crypt

    string curr = "none";

    if (AccountCurrency() == "USD") curr = "$";
    if (AccountCurrency() == "JPY") curr = "¥";
    if (AccountCurrency() == "EUR") curr = "€";
    if (AccountCurrency() == "GBP") curr = "£";
    if (AccountCurrency() == "CHF") curr = "CHF";
    if (AccountCurrency() == "AUD") curr = "A$";
    if (AccountCurrency() == "CAD") curr = "C$";
    if (AccountCurrency() == "RUB") curr = "руб";

    if (curr == "none") curr = AccountCurrency();

    //--- Equity / balance / floating

    string txt1, content;
    int content_len = StringLen(content);

    txt1 = version + "50";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 75);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "51";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 108);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 94);
    }
    ObjectSetText(txt1, "Portfolio", 12, "Century Gothic", color1);

    txt1 = version + "52";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 99);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "100";
    if (AccountEquity() >= AccountBalance()) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 117);
        }

        if (chart_profit == 0) ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + curr, 16, "Century Gothic", color3);
        if (chart_profit != 0) ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + curr, 11, "Century Gothic", color3);
    }
    if (AccountEquity() < AccountBalance()) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 117);
        }
        if (chart_profit == 0) ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + curr, 16, "Century Gothic", color4);
        if (chart_profit != 0) ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + curr, 11, "Century Gothic", color4);
    }

    txt1 = version + "101";
    if (chart_profit > 0) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 135);
        }
        ObjectSetText(txt1, "Floating chart P&L : +" + DoubleToStr(chart_profit, 2) + curr, 9, "Century Gothic", color3);
    }
    if (chart_profit < 0) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 135);
        }
        ObjectSetText(txt1, "Floating chart P&L : " + DoubleToStr(chart_profit, 2) + curr, 9, "Century Gothic", color4);
    }
    if (total_opened_trades == 0) ObjectDelete(txt1);

    txt1 = version + "102";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        if (total_opened_trades == 0) ObjectSet(txt1, OBJPROP_YDISTANCE, 152);
        if (total_opened_trades != 0) ObjectSet(txt1, OBJPROP_YDISTANCE, 152);
    }
    if (total_opened_trades == 0) ObjectSetText(txt1, "Balance : " + DoubleToStr(AccountBalance(), 2) + curr, 9, "Century Gothic", color2);
    if (total_opened_trades != 0) ObjectSetText(txt1, "Balance : " + DoubleToStr(AccountBalance(), 2) + curr, 9, "Century Gothic", color2);

    //--- Analytics

    txt1 = version + "53";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 156);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "54";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 108);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 175);
    }
    ObjectSetText(txt1, "Analytics", 12, "Century Gothic", color1);

    txt1 = version + "55";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 180);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "200";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 200);
    }
    if (chart_runup >= 0) {
        ObjectSetText(txt1, "Chart runup : " + DoubleToString(chart_runup_pc, 2) + "% [" + DoubleToString(chart_runup, 2) + curr + "]", 8, "Century Gothic", color3);
    }
    if (chart_dd < 0) {
        ObjectSetText(txt1, "Chart drawdown : " + DoubleToString(chart_dd_pc, 2) + "% [" + DoubleToString(chart_dd, 2) + curr + "]", 8, "Century Gothic", color4);
    }

    txt1 = version + "201";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 212);
    }
    if (acc_runup >= 0) {
        ObjectSetText(txt1, "Acc runup : " + DoubleToString(acc_runup_pc, 2) + "% [" + DoubleToString(acc_runup, 2) + curr + "]", 8, "Century Gothic", color3);
    }
    if (acc_dd < 0) {
        ObjectSetText(txt1, "Acc DD : " + DoubleToString(acc_dd_pc, 2) + "% [" + DoubleToString(acc_dd, 2) + curr + "]", 8, "Century Gothic", color4);
    }

    txt1 = version + "202";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 224);
    }
    ObjectSetText(txt1, "Max chart runup : " + DoubleToString(max_runup_pc, 2) + "% [" + DoubleToString(max_runup, 2) + curr + "]", 8, "Century Gothic", color2);

    txt1 = version + "203";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 236);
    }
    ObjectSetText(txt1, "Max chart drawdon : " + DoubleToString(max_dd_pc, 2) + "% [" + DoubleToString(max_dd, 2) + curr + "]", 8, "Century Gothic", color2);

    txt1 = version + "204";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 248);
    }
    ObjectSetText(txt1, "Max acc runup : " + DoubleToString(max_acc_runup_pc, 2) + "% [" + DoubleToString(max_acc_runup, 2) + curr + "]", 8, "Century Gothic", color2);

    txt1 = version + "205";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 260);
    }
    ObjectSetText(txt1, "Max acc drawdown : " + DoubleToString(max_acc_dd_pc, 2) + "% [" + DoubleToString(max_acc_dd, 2) + curr + "]", 8, "Century Gothic", color2);

    txt1 = version + "206";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 271);
    }
    ObjectSetText(txt1, "Trades won : " + IntegerToString(total_wins, 0) + " II Trades lost : " + IntegerToString(total_loss, 0) + " [" + DoubleToString(winrate, 0) + "% winrate]", 8, "Century Gothic", color2);

    txt1 = version + "207";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 284);
    }
    ObjectSetText(txt1, "W-Chain : " + IntegerToString(chain_win, 0) + " [Max : " + IntegerToString(max_chain_win, 0) + "] II L-Chain : " + IntegerToString(chain_loss, 0) + " [Max : " + IntegerToString(max_chain_loss, 0) + "]", 8, "Century Gothic", color2);

    txt1 = version + "208";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 296);
    }
    ObjectSetText(txt1, "Overall volume traded : " + DoubleToString(total_volumes, 2) + " lots", 8, "Century Gothic", color2);

    txt1 = version + "209";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 308);
    }
    ObjectSetText(txt1, "Average volume /trade : " + DoubleToString(av_volumes, 2) + " lots", 8, "Century Gothic", color2);

    txt1 = version + "210";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 320);
    }
    string expectancy;
    if (total_trades != 0) expectancy = DoubleToStr(total_profit / total_trades, 2);

    if (total_trades != 0 && total_profit / total_trades > 0) {
        ObjectSetText(txt1, "Payoff expectancy /trade : " + expectancy + curr, 8, "Century Gothic", color3);
    }
    if (total_trades != 0 && total_profit / total_trades < 0) {
        ObjectSetText(txt1, "Payoff expectancy /trade : " + expectancy + curr, 8, "Century Gothic", color4);
    }
    if (total_trades == 0) {
        ObjectSetText(txt1, "Payoff expectancy /trade : NA", 8, "Century Gothic", color3);
    }

    txt1 = version + "211";
    if (total_trades != 0 && profit_factor >= 1) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 332);
        }
        ObjectSetText(txt1, "Profit factor : " + DoubleToString(profit_factor, 2), 8, "Century Gothic", color3);
    }
    if (total_trades != 0 && profit_factor < 1) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 332);
        }
        ObjectSetText(txt1, "Profit factor : " + DoubleToString(profit_factor, 2), 8, "Century Gothic", color4);
    }
    if (total_trades == 0) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 332);
        }
        ObjectSetText(txt1, "Profit factor : NA", 8, "Century Gothic", color3);
    }
    //--- Earnings

    txt1 = version + "56";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 335);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "57";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 108);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 354);
    }
    ObjectSetText(txt1, "Earnings", 12, "Century Gothic", color1);

    txt1 = version + "58";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 360);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    double profitx = Earnings(0);
    txt1 = version + "300";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 380);
    }
    ObjectSetText(txt1, "Earnings today : " + DoubleToStr(profitx, 2) + curr, 8, "Century Gothic", color2);

    profitx = Earnings(1);
    txt1 = version + "301";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 392);
    }
    ObjectSetText(txt1, "Earnings yesterday : " + DoubleToStr(profitx, 2) + curr, 8, "Century Gothic", color2);

    profitx = Earnings(2);
    txt1 = version + "302";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 404);
    }
    ObjectSetText(txt1, "Earnings before yesterday : " + DoubleToStr(profitx, 2) + curr, 8, "Century Gothic", color2);

    txt1 = version + "303";
    if (total_profit >= 0) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 416);
        }
        ObjectSetText(txt1, "All time profit : " + DoubleToString(total_profit, 2) + curr, 8, "Century Gothic", color3);
    }
    if (total_profit < 0) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 416);
        }
        ObjectSetText(txt1, "All time loss : " + DoubleToString(total_profit, 2) + curr, 8, "Century Gothic", color4);
    }

    //--- Broker & Account

    txt1 = version + "59";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 419);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "60";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 70);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 438);
    }
    ObjectSetText(txt1, "Broker Information", 12, "Century Gothic", color1);

    txt1 = version + "61";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 443);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "400";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 463);
    }
    ObjectSetText(txt1, "Spread : " + DoubleToString(MarketInfo(Symbol(), MODE_SPREAD), 0) + " pts [Max : " + DoubleToString(max_histo_spread, 0) + " pts]", 8, "Century Gothic", color2);

    txt1 = version + "401";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 475);
    }
    ObjectSetText(txt1, "ID : " + AccountCompany(), 8, "Century Gothic", color2);

    txt1 = version + "402";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 487);
    }
    ObjectSetText(txt1, "Server : " + AccountServer(), 8, "Century Gothic", color2);

    txt1 = version + "403";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 499);
    }
    ObjectSetText(txt1, "Freeze lvl : " + IntegerToString(MarketInfo(Symbol(), MODE_FREEZELEVEL), 0) + " pts II Stop lvl : " + IntegerToString(MarketInfo(Symbol(), MODE_STOPLEVEL), 0) + " pts", 8, "Century Gothic", color2);

    txt1 = version + "404";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 511);
    }
    ObjectSetText(txt1, "L-Swap : " + DoubleToStr(MarketInfo(Symbol(), MODE_SWAPLONG), 2) + curr + "/lot II S-Swap : " + DoubleToStr(MarketInfo(Symbol(), MODE_SWAPSHORT), 2) + curr + "/lot", 8, "Century Gothic", color2);

    txt1 = version + "62";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 514);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "63";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 108);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 533);
    }
    ObjectSetText(txt1, "Account", 12, "Century Gothic", color1);

    txt1 = version + "64";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 538);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "500";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 558);
    }
    ObjectSetText(txt1, "ID : " + AccountName() + " [#" + IntegerToString(AccountNumber(), 0) + "]", 8, "Century Gothic", color2);

    txt1 = version + "501";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 570);
    }
    ObjectSetText(txt1, "Leverage : " + (string) AccountLeverage() + ":1", 8, "Century Gothic", color2);

    txt1 = version + "502";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 582);
    }
    ObjectSetText(txt1, "Currency : " + AccountCurrency() + " [" + curr + "]", 8, "Century Gothic", color2);

    txt1 = version + "503";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 594);
    }
    string enable_or_not;
    if (trade_on_button == false) {
        enable_or_not = "Trading Disabled";
    } else {
        enable_or_not = "Trading Enabled";
    }

    ObjectSetText(txt1, enable_or_not, 8, "Century Gothic", color2);
}

//        o----------------------o
//        |   EA NAME FUNCTION   |
//        o----------------------o

void EA_name() {
    string txt2 = version + "20";
    if (ObjectFind(txt2) == -1) {
        ObjectCreate(txt2, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt2, OBJPROP_CORNER, 0);
        ObjectSet(txt2, OBJPROP_XDISTANCE, 89);
        ObjectSet(txt2, OBJPROP_YDISTANCE, 27);
    }
    ObjectSetText(txt2, "KEOPS", 25, "Century Gothic", color1);

    txt2 = version + "21";
    if (ObjectFind(txt2) == -1) {
        ObjectCreate(txt2, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt2, OBJPROP_CORNER, 0);
        ObjectSet(txt2, OBJPROP_XDISTANCE, 79);
        ObjectSet(txt2, OBJPROP_YDISTANCE, 68);
    }
    ObjectSetText(txt2, "by Edorenta || version " + version, 8, "Arial", Gray);

    txt2 = version + "22";
    if (ObjectFind(txt2) == -1) {
        ObjectCreate(txt2, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt2, OBJPROP_CORNER, 0);
        ObjectSet(txt2, OBJPROP_XDISTANCE, 32);
        ObjectSet(txt2, OBJPROP_YDISTANCE, 51);
    }
    ObjectSetText(txt2, "___________________________", 11, "Arial", Gray);

    /*
       txt2 = version + "23";
       if (ObjectFind(txt2) == -1) {
          ObjectCreate(txt2, OBJ_LABEL, 0, 0, 0);
          ObjectSet(txt2, OBJPROP_CORNER, 0);
          ObjectSet(txt2, OBJPROP_XDISTANCE, 32);
          ObjectSet(txt2, OBJPROP_YDISTANCE, 67);
       }
       ObjectSetText(txt2, "___________________________", 11, "Arial", Gray);

    */
}

/*       ____________________________________________
         T                                          T
         T                 THE END                  T
         T__________________________________________T
*/