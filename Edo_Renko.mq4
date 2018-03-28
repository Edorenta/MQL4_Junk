/*      .=====================================.
       /              Edo Renko                \
      |               by Edorenta               |
       \          Renko chart creator          /
        '====================================='
*/

#property copyright     "Paul de Renty (Edorenta @ ForexFactory.com)"
#property link          "edorenta@gmail.com (mp me on FF rather than by email)"
#property description   "Dynamic Renko Chart Creator"
#property version       "1.0"
string    version =     "1.0";
#property strict
#include <WinUser32.mqh>
#include <stdlib.mqh>

//+------------------------------------------------------------------+
#import "user32.dll"
    int RegisterWindowMessageA(string lpString); 
//+------------------------------------------------------------------+
#define edo_renko_version "v1.0"

enum box    {fixedbox,        //Fixed Pips
             atrbox,          //ATR Based
             atrmabox,        //Average ATR Based
             hilobox,         //HiLo Based
             hilomabox,       //Average HiLo Based
             hybridbox,       //HiLo ATR Hybrid Based
             hybridmabox      //Hybrid Average
             };
             

extern box boxtype = atrmabox; //Box Type
extern double fixedpips = 0.2; //Size in Pips (Fix'Box)
extern int atr1_ln = 35; //ATR period (ATR'Box)
extern double ATR1x = 0.2; //ATR boxsize multiplier
extern ENUM_TIMEFRAMES atr1_tf = 1; //ATR TimeFrame (ATR'Box)
extern int atrma1_ln = 12; //ATR MA period (ATRMA'Box)
extern ENUM_MA_METHOD atrma1_type = MODE_EMA; //ATR MA Type (ATRMA'Box)
extern int hilo_ln = 35; //HiLo Period (HiLo'Box)
extern ENUM_TIMEFRAMES hilo_tf = 1; //HiLo TimeFrame (HiLo'Box)
extern int hiloma_ln = 12; //HiLo MA Period (HiLoMA'Box)
extern ENUM_MA_METHOD hiloma_type = MODE_EMA; //HiLo MA Type (HiLoMA'Box)
extern double HILO1x = 0.2; //HiLo boxsize multiplier
extern double hybridrate = 1; //ATR wgt versus HiLo wgt (Hybrid'Box)

extern int RenkoBoxOffset = 0;
extern int RenkoTimeFrame = 2; // What time frame to use for the offline renko chart
extern bool ShowWicks = true;
extern bool EmulateOnLineChart = true;
extern bool BuildChartsWhenMarketOffline = true;

// extern bool StrangeSymbolName = false;
//+------------------------------------------------------------------+
int HstHandle = -1, LastFPos = 0, MT4InternalMsg = 0, dg;
string SymbName;
double pt, mt;
double boxsize, atrboxsize, atrmaboxsize, hiloboxsize, hilomaboxsize, hybridboxsize, hybridmaboxsize;

//+------------------------------------------------------------------+

void OnInit() {

    Comment("");

    dg = Digits;
    if (dg == 3 || dg == 5) {
        pt = Point * 10;
        mt = 10;
    } else {
        pt = Point;
        mt = 1;
    }

    if (BuildChartsWhenMarketOffline) {
        // Manually call OnTick() function once so we build offline charts even if the market is closed...
        // This continues to exit properly after the charts have been built so as not to mess anything up.
        OnTick();
    }
    return;
}

void UpdateChartWindow() {
        static int hwnd = 0;

        if (hwnd == 0) {
            hwnd = WindowHandle(SymbName, RenkoTimeFrame);
            if (hwnd != 0) Print("Chart window detected");
        }

        if (EmulateOnLineChart && MT4InternalMsg == 0)
            MT4InternalMsg = RegisterWindowMessageA("MetaTrader4_Internal_Message");

        if (hwnd != 0)
            if (PostMessageA(hwnd, WM_COMMAND, 0x822c, 0) == 0) hwnd = 0;
        if (hwnd != 0 && MT4InternalMsg != 0) PostMessageA(hwnd, MT4InternalMsg, 2, 1);

        return;
    }
    //+------------------------------------------------------------------+
void OnTick() {
        static double BoxPoints, UpWick, DnWick;
        static double PrevLow, PrevHigh, PrevOpen, PrevClose, CurVolume, CurLow, CurHigh, CurOpen, CurClose;
        static datetime PrevTime;
        boxsize = 0;

        /*       ________________________________________________
                 T                                              T
                 T             BOX SIZE CALCULATION             T
                 T______________________________________________T
        */

        //--- ATR shit

        double ATR1 = iCustom(Symbol(), atr1_tf, "ATR+ATRMA", atr1_ln, atrma1_ln, 0, 0);
        double ATRMA1 = iCustom(Symbol(), atr1_tf, "ATR+ATRMA", atr1_ln, atrma1_ln, 1, 0);

        double PATR1 = iCustom(Symbol(), atr1_tf, "ATR+ATRMA", atr1_ln, atrma1_ln, 0, 1);
        double PATRMA1 = iCustom(Symbol(), atr1_tf, "ATR+ATRMA", atr1_ln, atrma1_ln, 1, 1);

        atrboxsize = ATR1 * ATR1x;
        atrmaboxsize = ATRMA1 * ATR1x;

        //--- HiLo shit && HiLo MA

        double HILO1 = iCustom(Symbol(), hilo_tf, "HiLo+HiLoMA", hilo_ln, hiloma_ln, 0, 0);
        double HILOMA1 = iCustom(Symbol(), hilo_tf, "HiLo+HiLoMA", hilo_ln, hiloma_ln, 1, 0);

        double PHILO1 = iCustom(Symbol(), hilo_tf, "HiLo+HiLoMA", hilo_ln, hiloma_ln, 0, 1);
        double PHILOMA1 = iCustom(Symbol(), hilo_tf, "HiLo+HiLoMA", hilo_ln, hiloma_ln, 1, 1);

        hiloboxsize = HILO1 * HILO1x;
        hilomaboxsize = HILOMA1 * HILO1x;

        //--- Hybrid Box' calculations

        hybridboxsize = (((atrboxsize * hybridrate) + hiloboxsize) / (1 + hybridrate));
        hybridmaboxsize = (((atrmaboxsize * hybridrate) + hilomaboxsize) / (1 + hybridrate));

        if (boxtype == atrbox) boxsize = atrboxsize;
        else if (boxtype == atrmabox) boxsize = atrmaboxsize;
        else if (boxtype == hilobox) boxsize = hiloboxsize;
        else if (boxtype == hilomabox) boxsize = hilomaboxsize;
        else if (boxtype == hybridbox) boxsize = hybridboxsize;
        else if (boxtype == hybridmabox) boxsize = hybridmaboxsize;
        else boxsize = fixedpips * pt;

        //___________________________________________________________________

        if (HstHandle < 0) {
            // Init

            // Error checking    
            if (!IsConnected()) {
                Print("Waiting for connection...");
                return;
            }
            if (!IsDllsAllowed()) {
                Print("Error: Dll calls must be allowed!");
                return;
            }
            if (MathAbs(RenkoBoxOffset) >= boxsize / pt) {
                Print("Error: |RenkoBoxOffset| should be less then RenkoBoxSize!");
                return;
            }
            switch (RenkoTimeFrame) {
            case 1:
            case 5:
            case 15:
            case 30:
            case 60:
            case 240:
            case 1440:
            case 10080:
            case 43200:
            case 0:
                Print("Error: Invald time frame used for offline renko chart (RenkoTimeFrame)!");
                return;
            }

            SymbName = Symbol();

            BoxPoints = NormalizeDouble(boxsize, Digits);
            PrevLow = NormalizeDouble(RenkoBoxOffset * pt + MathFloor(Close[Bars - 1] / BoxPoints) * BoxPoints, Digits);

            DnWick = PrevLow;
            PrevHigh = PrevLow + BoxPoints;
            UpWick = PrevHigh;
            PrevOpen = PrevLow;
            PrevClose = PrevHigh;
            CurVolume = 1;
            PrevTime = Time[Bars - 1];

            // create / open hst file        
            HstHandle = FileOpenHistory(SymbName + RenkoTimeFrame + ".hst", FILE_BIN | FILE_WRITE | FILE_SHARE_WRITE | FILE_SHARE_READ);
            if (HstHandle < 0) {
                Print("Error: can\'t create / open history file: " + ErrorDescription(GetLastError()) + ": " + SymbName + RenkoTimeFrame + ".hst");
                return;
            }
            //

            // write hst file header
            int HstUnused[13];
            FileWriteInteger(HstHandle, 400, LONG_VALUE); // Version
            FileWriteString(HstHandle, "", 64); // Copyright
            FileWriteString(HstHandle, SymbName, 12); // Symbol
            FileWriteInteger(HstHandle, RenkoTimeFrame, LONG_VALUE); // Period
            FileWriteInteger(HstHandle, Digits, LONG_VALUE); // Digits
            FileWriteInteger(HstHandle, 0, LONG_VALUE); // Time Sign
            FileWriteInteger(HstHandle, 0, LONG_VALUE); // Last Sync
            FileWriteArray(HstHandle, HstUnused, 0, 13); // Unused
            //

            // process historical data
            int i = Bars - 2;
            //Print(Symbol() + " " + High[i] + " " + Low[i] + " " + Open[i] + " " + Close[i]);
            //---------------------------------------------------------------------------
            while (i >= 0) {

                CurVolume = CurVolume + Volume[i];

                UpWick = MathMax(UpWick, High[i]);
                DnWick = MathMin(DnWick, Low[i]);

                // update low before high or the revers depending on is closest to prev. bar
                bool UpTrend = High[i] + Low[i] > High[i + 1] + Low[i + 1];

                while (UpTrend && (Low[i] < PrevLow - BoxPoints || CompareDoubles(Low[i], PrevLow - BoxPoints))) {
                    PrevHigh = PrevHigh - BoxPoints;
                    PrevLow = PrevLow - BoxPoints;
                    PrevOpen = PrevHigh;
                    PrevClose = PrevLow;

                    FileWriteInteger(HstHandle, PrevTime, LONG_VALUE);
                    FileWriteDouble(HstHandle, PrevOpen, DOUBLE_VALUE);
                    FileWriteDouble(HstHandle, PrevLow, DOUBLE_VALUE);

                    if (ShowWicks && UpWick > PrevHigh) FileWriteDouble(HstHandle, UpWick, DOUBLE_VALUE);
                    else FileWriteDouble(HstHandle, PrevHigh, DOUBLE_VALUE);

                    FileWriteDouble(HstHandle, PrevClose, DOUBLE_VALUE);
                    FileWriteDouble(HstHandle, CurVolume, DOUBLE_VALUE);

                    UpWick = 0;
                    DnWick = EMPTY_VALUE;
                    CurVolume = 0;
                    CurHigh = PrevLow;
                    CurLow = PrevLow;

                    if (PrevTime < Time[i]) PrevTime = Time[i];
                    else PrevTime++;
                }

                while (High[i] > PrevHigh + BoxPoints || CompareDoubles(High[i], PrevHigh + BoxPoints)) {
                    PrevHigh = PrevHigh + BoxPoints;
                    PrevLow = PrevLow + BoxPoints;
                    PrevOpen = PrevLow;
                    PrevClose = PrevHigh;

                    FileWriteInteger(HstHandle, PrevTime, LONG_VALUE);
                    FileWriteDouble(HstHandle, PrevOpen, DOUBLE_VALUE);

                    if (ShowWicks && DnWick < PrevLow) FileWriteDouble(HstHandle, DnWick, DOUBLE_VALUE);
                    else FileWriteDouble(HstHandle, PrevLow, DOUBLE_VALUE);

                    FileWriteDouble(HstHandle, PrevHigh, DOUBLE_VALUE);
                    FileWriteDouble(HstHandle, PrevClose, DOUBLE_VALUE);
                    FileWriteDouble(HstHandle, CurVolume, DOUBLE_VALUE);

                    UpWick = 0;
                    DnWick = EMPTY_VALUE;
                    CurVolume = 0;
                    CurHigh = PrevHigh;
                    CurLow = PrevHigh;

                    if (PrevTime < Time[i]) PrevTime = Time[i];
                    else PrevTime++;
                }

                while (!UpTrend && (Low[i] < PrevLow - BoxPoints || CompareDoubles(Low[i], PrevLow - BoxPoints))) {
                    PrevHigh = PrevHigh - BoxPoints;
                    PrevLow = PrevLow - BoxPoints;
                    PrevOpen = PrevHigh;
                    PrevClose = PrevLow;

                    FileWriteInteger(HstHandle, PrevTime, LONG_VALUE);
                    FileWriteDouble(HstHandle, PrevOpen, DOUBLE_VALUE);
                    FileWriteDouble(HstHandle, PrevLow, DOUBLE_VALUE);

                    if (ShowWicks && UpWick > PrevHigh) FileWriteDouble(HstHandle, UpWick, DOUBLE_VALUE);
                    else FileWriteDouble(HstHandle, PrevHigh, DOUBLE_VALUE);

                    FileWriteDouble(HstHandle, PrevClose, DOUBLE_VALUE);
                    FileWriteDouble(HstHandle, CurVolume, DOUBLE_VALUE);

                    UpWick = 0;
                    DnWick = EMPTY_VALUE;
                    CurVolume = 0;
                    CurHigh = PrevLow;
                    CurLow = PrevLow;

                    if (PrevTime < Time[i]) PrevTime = Time[i];
                    else PrevTime++;
                }
                i--;
            }

            LastFPos = FileTell(HstHandle); // Remember Last pos in file
            //

            if (Close[0] > MathMax(PrevClose, PrevOpen)) CurOpen = MathMax(PrevClose, PrevOpen);
            else if (Close[0] < MathMin(PrevClose, PrevOpen)) CurOpen = MathMin(PrevClose, PrevOpen);
            else CurOpen = Close[0];

            CurClose = Close[0];

            if (UpWick > PrevHigh) CurHigh = UpWick;
            if (DnWick < PrevLow) CurLow = DnWick;

            FileWriteInteger(HstHandle, PrevTime, LONG_VALUE); // Time
            FileWriteDouble(HstHandle, CurOpen, DOUBLE_VALUE); // Open
            FileWriteDouble(HstHandle, CurLow, DOUBLE_VALUE); // Low
            FileWriteDouble(HstHandle, CurHigh, DOUBLE_VALUE); // High
            FileWriteDouble(HstHandle, CurClose, DOUBLE_VALUE); // Close
            FileWriteDouble(HstHandle, CurVolume, DOUBLE_VALUE); // Volume                
            FileFlush(HstHandle);

            UpdateChartWindow();

            // Show the Renko Comments...
            AddRenkoComment(BoxPoints);

            return;
            // End historical data / Init        
        }
        //----------------------------------------------------------------------------
        // HstHandle not < 0 so we always enter here after history done
        // Begin live data feed

        UpWick = MathMax(UpWick, Bid);
        DnWick = MathMin(DnWick, Bid);

        CurVolume++;
        FileSeek(HstHandle, LastFPos, SEEK_SET);

        //-------------------------------------------------------------------------                       
        // up box                       
        if (Bid > PrevHigh + BoxPoints || CompareDoubles(Bid, PrevHigh + BoxPoints)) {
            PrevHigh = PrevHigh + BoxPoints;
            PrevLow = PrevLow + BoxPoints;
            PrevOpen = PrevLow;
            PrevClose = PrevHigh;

            FileWriteInteger(HstHandle, PrevTime, LONG_VALUE);
            FileWriteDouble(HstHandle, PrevOpen, DOUBLE_VALUE);

            if (ShowWicks && DnWick < PrevLow) FileWriteDouble(HstHandle, DnWick, DOUBLE_VALUE);
            else FileWriteDouble(HstHandle, PrevLow, DOUBLE_VALUE);

            FileWriteDouble(HstHandle, PrevHigh, DOUBLE_VALUE);
            FileWriteDouble(HstHandle, PrevClose, DOUBLE_VALUE);
            FileWriteDouble(HstHandle, CurVolume, DOUBLE_VALUE);
            FileFlush(HstHandle);
            LastFPos = FileTell(HstHandle); // Remeber Last pos in file                                              

            if (PrevTime < TimeCurrent()) PrevTime = TimeCurrent();
            else PrevTime++;

            CurVolume = 0;
            CurHigh = PrevHigh;
            CurLow = PrevHigh;

            UpWick = 0;
            DnWick = EMPTY_VALUE;

            UpdateChartWindow();
        }
        //-------------------------------------------------------------------------                       
        // down box
        else if (Bid < PrevLow - BoxPoints || CompareDoubles(Bid, PrevLow - BoxPoints)) {
            PrevHigh = PrevHigh - BoxPoints;
            PrevLow = PrevLow - BoxPoints;
            PrevOpen = PrevHigh;
            PrevClose = PrevLow;

            FileWriteInteger(HstHandle, PrevTime, LONG_VALUE);
            FileWriteDouble(HstHandle, PrevOpen, DOUBLE_VALUE);
            FileWriteDouble(HstHandle, PrevLow, DOUBLE_VALUE);

            if (ShowWicks && UpWick > PrevHigh) FileWriteDouble(HstHandle, UpWick, DOUBLE_VALUE);
            else FileWriteDouble(HstHandle, PrevHigh, DOUBLE_VALUE);

            FileWriteDouble(HstHandle, PrevClose, DOUBLE_VALUE);
            FileWriteDouble(HstHandle, CurVolume, DOUBLE_VALUE);
            FileFlush(HstHandle);
            LastFPos = FileTell(HstHandle); // Remeber Last pos in file                                              

            if (PrevTime < TimeCurrent()) PrevTime = TimeCurrent();
            else PrevTime++;

            CurVolume = 0;
            CurHigh = PrevLow;
            CurLow = PrevLow;

            UpWick = 0;
            DnWick = EMPTY_VALUE;

            UpdateChartWindow();
        }
        //-------------------------------------------------------------------------                       
        // no box - high/low not hit                
        else {
            if (Bid > CurHigh) CurHigh = Bid;
            if (Bid < CurLow) CurLow = Bid;

            if (PrevHigh <= Bid) CurOpen = PrevHigh;
            else if (PrevLow >= Bid) CurOpen = PrevLow;
            else CurOpen = Bid;

            CurClose = Bid;

            FileWriteInteger(HstHandle, PrevTime, LONG_VALUE); // Time
            FileWriteDouble(HstHandle, CurOpen, DOUBLE_VALUE); // Open
            FileWriteDouble(HstHandle, CurLow, DOUBLE_VALUE); // Low
            FileWriteDouble(HstHandle, CurHigh, DOUBLE_VALUE); // High
            FileWriteDouble(HstHandle, CurClose, DOUBLE_VALUE); // Close
            FileWriteDouble(HstHandle, CurVolume, DOUBLE_VALUE); // Volume                
            FileFlush(HstHandle);

            UpdateChartWindow();
        }

        // Show prett comments on the Renko builder chart...
        AddRenkoComment(BoxPoints);

        return;
    }
    //+------------------------------------------------------------------+
void OnDeinit(const int reason) {
        if (HstHandle >= 0) {
            FileClose(HstHandle);
            HstHandle = -1;
        }
        Comment("");
        return;
    }
    //+------------------------------------------------------------------+
void AddRenkoComment(double BP) {

    string text = "\n ===========================\n";
    text = text + "   EDORENKO LIVE CHART " + edo_renko_version + " (" + DoubleToStr(BP / pt, 1) + " pips)\n";
    text = text + " ===========================\n";

    if (WindowHandle(SymbName, RenkoTimeFrame) == 0) {
        text = text + "   Go to Menu FILE > OPEN OFFLINE\n";
        text = text + "   Select >> " + SymbName + ",M" + RenkoTimeFrame + " <<\n";
        text = text + "   and click OPEN to view chart.";
    } else {
        text = text + "  You can minimize this window\n";
    }
    Comment(text);

}