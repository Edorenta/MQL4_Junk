/*      .=====================================.
       /               DS Light                \
      |               by Edorenta               |
       \          Signature Algorithms         /
        '====================================='
*/

#property copyright     "Signature Algoritms™"
#property description   "Custom RSI Based Algorithm"
#property version       "0.3"
string    version =     "0.3";
#property strict
#include <stdlib.mqh>

/*
      .-----------------------.
      |    EXTERNAL INPUTS    |
      '-----------------------'
*/

extern string __0__ = "---------------------------------------------------------------------------------------------------------"; //[------------   GENERAL SETTINGS   ------------]

extern bool one_trade_per_bar = true; //Trade on Close Only
extern bool use_long = true; //Enable Longs
extern bool use_short = true; //Enable Shorts
extern string acc_currency = "EUR"; //Account Currency [ISO Code]

extern string __1__ = "---------------------------------------------------------------------------------------------------------"; //[------------   ENTRY SETTINGS   ------------]

extern ENUM_APPLIED_PRICE rsi_price_mode = 0; //Applied RSI Price Type
extern int rsi_p = 39; //RSI Lookback [Candles]
extern int rsi_xtm1 = 61; //RSI+ Threshold
extern int rsi_xtm2 = 39; //RSI- Threshold
extern bool r_exit = true; //Exit on Opposite Signal

extern string __2__ = "---------------------------------------------------------------------------------------------------------"; //[------------   FILTER SETTINGS   ------------]

extern bool use_minmax_filter = true; //Enable Min-Max Filter
extern bool use_sdev_filter = true; //Enable SDEV Vol Filter

extern int minmax_p = 20; //MinMax Lookback [Candles]
extern int sdev_filter_p = 21; //SDEV Filter Lookback [Candles]
extern double sdev_filter_xtm1 = 0.000797; //SDEV+ Threshold
extern double sdev_filter_xtm2 = 0.000064; //SDEV- Threshold

extern string __3__ = "---------------------------------------------------------------------------------------------------------"; //[------------   S/L SETTINGS   ------------]

extern bool enable_trail = false; //Enable Trailing Stops
extern double sl_pips = 100; //Stoploss [Pips]
extern double tp_pips = 100; //Takeprofit [Pips]
extern double ts_pips = 100; //Trailing-Stop [Pips; if enabled]

extern string __4__ = "---------------------------------------------------------------------------------------------------------"; //[------------   LOTSIZE SETTINGS   ------------]

extern double daily_expectancy = 250; //Daily Expectancy [Points]
extern double daily_growth_target = 1; //Daily Account Growth Target [%]
extern double str_pair_allocation = 10; //Pair Strategy Allocation [%]
//extern double b_lot = 0.1;                              //Lot Size => Automatically Calculated

extern string __5__ = "---------------------------------------------------------------------------------------------------------"; //[------------   BROKER SETTINGS   ------------]

extern int max_spread = 15; //Max Spread [Points]
extern int magic_id = 101; //Orders Identifier [Magic]
extern int slippage = 15; //Max Slippage [Points; if not Market Exec]

int current_bar = 0;

/*
      .-----------------------.
      |    ON INIT FUNCTION   |
      '-----------------------'
      
      >> Init variables & plot objects
       
*/

int OnInit() {
    return (INIT_SUCCEEDED);
}

/*
      .-----------------------.
      |   ON DEINIT FUNCTION  |
      '-----------------------'
      
      >> Unload & delete graphical objects
       
*/

/*
int OnDeinit(){
   return(0);
}
*/

/*
      .-----------------------.
      |    ON TICK FUNCTION   |
      '-----------------------'
       
      >> Logic Loop
*/
void OnTick() {

    if (current_bar != Bars) {
        if (one_trade_per_bar == true) current_bar = Bars;
        Comment(trading_authorized());

        int nb_longs = trade_counter(1);
        int nb_shorts = trade_counter(2);
        int nb_trades = nb_longs + nb_shorts;

        entry_logic();

        if (nb_longs != 0) {
            manage_long();
        }

        if (nb_shorts != 0) {
            manage_short();
        }
    }
}

//        o-----------------------o
//        |      ENTRY LOGIC      |
//        o-----------------------o

void entry_logic() {

    double RSI1 = iCustom(Symbol(), 0, "RSI Exp ++", rsi_p, rsi_price_mode, 0, 1);
    double RSI2 = iCustom(Symbol(), 0, "RSI Exp ++", rsi_p, rsi_price_mode, 0, 2);

    if (RSI1 < rsi_xtm2 && RSI2 >= rsi_xtm2) {
        Comment("GO LONG");
        if (trading_authorized() == true && use_long == true && trade_counter(1) < 1) BUY();
        if (trade_counter(3) != 0 && r_exit == true) close_shorts();
    }

    if (RSI1 > rsi_xtm1 && RSI2 <= rsi_xtm1) {
        Comment("GO SHORT");
        if (trading_authorized() == true && use_short == true && trade_counter(2) < 1) SELL();
        if (trade_counter(3) != 0 && r_exit == true) close_longs();
    }
}

//        o-----------------------o
//        |     MANAGE TRADES     |
//        o-----------------------o

void manage_long() {
    if (enable_trail == true) trail_long();
}

void manage_short() {
    if (enable_trail == true) trail_short();
}

//        o-----------------------o
//        |   ORDER MANAGEMENT    |
//        o-----------------------o

void BUY() {
    double tp_points = TP();
    double sl_points = SL();
    double TP = 0, SL = 0;
    if (TP() != 0) TP = Ask + TP();
    else TP = 0;
    if (SL() != 0) SL = Bid - SL();
    else SL = 0;

    int ticket = OrderSend(Symbol(), OP_BUY, lotsize(), Ask, slippage, SL, TP, "Deus Light v0.1 " + DoubleToStr(lotsize(), 2) + " on " + Symbol(), magic_id, 0, Turquoise);
}

void SELL() {
    double tp_points = TP();
    double sl_points = SL();
    double TP = 0, SL = 0;
    if (TP() != 0) TP = Bid - TP();
    if (SL() != 0) SL = Ask + SL();

    int ticket = OrderSend(Symbol(), OP_SELL, lotsize(), Bid, slippage, SL, TP, "Deus Light v0.1 " + DoubleToStr(lotsize(), 2) + " on " + Symbol(), magic_id, 0, Magenta);

}

void trail_long() {
    double TS = NormalizeDouble(TS(), Digits);
    //   Comment("Trailing Stop :"+TS);
    if (TS != 0) {
        for (int i = OrdersTotal() - 1; i >= 0; i--) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic_id && OrderSymbol() == Symbol()) {
                if (OrderType() == OP_BUY) {
                    if (Bid - OrderOpenPrice() > TS && (OrderStopLoss() < Bid - TS || (OrderStopLoss() == 0))) {
                        OrderModify(OrderTicket(), OrderOpenPrice(), Bid - TS, OrderTakeProfit(), 0, Turquoise);
                    }
                }
            }
        }
    }
}

void trail_short() {
    double TS = NormalizeDouble(TS(), Digits);
    //   Comment("Trailing Stop :"+TS);
    if (TS != 0) {
        for (int i = OrdersTotal() - 1; i >= 0; i--) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic_id && OrderSymbol() == Symbol()) {
                if (OrderType() == OP_SELL) {
                    if (OrderOpenPrice() - Ask > TS && (OrderStopLoss() > Ask + TS || (OrderStopLoss() == 0))) {
                        OrderModify(OrderTicket(), OrderOpenPrice(), Ask + TS, OrderTakeProfit(), 0, Magenta);
                    }
                }
            }
        }
    }
}

void close_all() {

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic_id) {
            if (OrderType() == OP_BUY) {
                int ticket = OrderClose(OrderTicket(), OrderLots(), Bid, slippage, Turquoise);
            }
            if (OrderType() == OP_SELL) {
                int ticket = OrderClose(OrderTicket(), OrderLots(), Ask, slippage, Magenta);
            }
        }
    }
}

void close_longs() {

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic_id) {
            if (OrderType() == OP_BUY) {
                int ticket = OrderClose(OrderTicket(), OrderLots(), Bid, slippage, Turquoise);
            }
        }
    }
}
void close_shorts() {

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic_id) {
            if (OrderType() == OP_SELL) {
                int ticket = OrderClose(OrderTicket(), OrderLots(), Ask, slippage, Magenta);
            }
        }
    }
}

//        o----------------------o
//        | S/L COUNTER FUNCTION |
//        o----------------------o

double trade_counter(int key) {

    double nb_longs = 0, nb_shorts = 0, nb_trades = 0, nb = 0;

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic_id) {
            if (OrderType() == OP_BUY) {
                nb_longs++;
            }
            if (OrderType() == OP_SELL) {
                nb_shorts++;
            }
        }
    }
    nb_trades = nb_longs + nb_shorts;
    //   }

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
    }
    return (nb);
}

//        o----------------------o
//        | TARGET CALC FUNCTION |
//        o----------------------o

double TP() {

    double tplvl = 0;
    double freezelvl = MarketInfo(Symbol(), MODE_FREEZELEVEL) * Point;
    double spread = Ask - Bid;
    double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

    if (tp_pips != 0) {
        tplvl = tp_pips * Point * 10;

        double minarray[3];
        minarray[0] = spread * 2;
        minarray[1] = freezelvl;
        minarray[2] = stoplvl;

        double minlvl = minarray[ArrayMaximum(minarray)];
        if (minlvl >= tplvl) tplvl = minlvl;
    }
    return (tplvl);
}

double SL() {

    double sllvl = 0;
    double freezelvl = MarketInfo(Symbol(), MODE_FREEZELEVEL) * Point;
    double spread = Ask - Bid;
    double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

    if (sl_pips != 0) {
        sllvl = sl_pips * Point * 10;

        double minarray[3];
        minarray[0] = spread * 2;
        minarray[1] = freezelvl;
        minarray[2] = stoplvl;

        double minlvl = minarray[ArrayMaximum(minarray)];
        if (minlvl >= sllvl) sllvl = minlvl;
    }
    return (sllvl);
}

double TS() {

    double tslvl = ts_pips * Point * 10;

    return (tslvl);
}

//        o----------------------o
//        |  LOTS CALC FUNCTION  |
//        o----------------------o

double lotsize() {

    //eq*rk(jr)*marko/pt(jr)

    double m_lots = 0;
    double equity = AccountEquity();
    double margin = AccountFreeMargin();
    double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
    double minlot = MarketInfo(Symbol(), MODE_MINLOT);
    double acc_daily_target;
    double str_pair_target, target_loc;

    //double pip_value = MarketInfo(Symbol(),MODE_TICKVALUE);
    //double pip_size = MarketInfo(Symbol(),MODE_TICKSIZE);
    //int leverage = AccountLeverage();

    string suffix = StringSubstr(_Symbol, 6); //Suffix recognition (i.e. "EURUSDm" => "m" from micro)
    string base_currency, quote_currency, hedge_cross;

    base_currency = StringSubstr(_Symbol, 0, 3);
    quote_currency = StringSubstr(_Symbol, 3, 3);

    if (base_cuurency != acc_currency) {
        //      hedge_cross = 
    }
    acc_daily_target = NormalizeDouble(equity * (daily_growth_target / 100), 2);
    target_loc = NormalizeDouble(acc_daily_target * (str_pair_allocation / 100), 2);

    str_pair_target = target_eur *
        m_lots = b_lot;

    if (m_lots < minlot) m_lots = minlot;
    if (m_lots > maxlot) m_lots = maxlot;

    return (m_lots);
}

//        o----------------------o
//        | TRADE FILTR FUNCTION |
//        o----------------------o

bool trading_authorized() {
    int trade_condition = 1;

    if (spread_okay() == false) trade_condition = 0;
    if (filter_off() == false) trade_condition = 0;

    if (trade_condition == 1) {
        return (true);
    } else {
        return (false);
    }
}

bool spread_okay() {
    bool spread_filter_off = true;
    if (trade_counter(3) == 0) {
        if (MarketInfo(Symbol(), MODE_SPREAD) >= max_spread) {
            spread_filter_off = false;
        }
    }
    return (spread_filter_off);
}

bool filter_off() {

    bool filter_off = true;

    if (use_sdev_filter == true) {
        double SDEV1 = iStdDev(Symbol(), 0, sdev_filter_p, 0, MODE_SMA, PRICE_CLOSE, 0); //Current
        double SDEV2 = iStdDev(Symbol(), 0, sdev_filter_p, 0, MODE_SMA, PRICE_CLOSE, 0); //Previous

        if (SDEV1 >= sdev_filter_xtm1 || SDEV1 <= sdev_filter_xtm2) filter_off = false;
    }
    if (use_minmax_filter == true) {
        use_long = false;
        use_short = false;

        double max = MinMax(1);
        double min = MinMax(2);

        if (Close[0] >= max) use_short = true;
        if (Close[0] <= min) use_long = true;
    }

    return (filter_off);
}

double MinMax(int key) {

    int max_shift, min_shift;
    double max_px, min_px;

    max_shift = iHighest(Symbol(), 0, MODE_HIGH, minmax_p, 0);
    max_px = iHigh(Symbol(), 0, minmax_p);
    min_shift = iLowest(Symbol(), 0, MODE_LOW, minmax_p, 0);
    min_px = iLow(Symbol(), 0, minmax_p);

    if (key == 1) return (max_px);
    else return (min_px);
}

/*       ____________________________________________
         T                                          T
         T                 THE END                  T
         T__________________________________________T
*/