//--------------------------------------------------------------------
// userindicator.mq4 
// ������������ ��� ������������� � �������� ������� � �������� MQL4.
//--------------------------------------------------------------------
#property indicator_chart_window    // �����. �������� � �������� ����
#property indicator_buffers 2       // ���������� �������
#property indicator_color1 Blue     // ���� ������ �����
#property indicator_color2 Red      // ���� ������ �����

double Buf_0[],Buf_1[];             // �������� ������������ ��������
//--------------------------------------------------------------------
int init()                          // ����������� ������� init()
  {
//--------------------------------------------------------------------
   SetIndexBuffer(0,Buf_0);         // ���������� ������� ������
   SetIndexStyle (0,DRAW_LINE,STYLE_DOT,1);// ����� �����
//--------------------------------------------------------------------
   SetIndexBuffer(1,Buf_1);         // ���������� ������� ������
   SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,1);// ����� �����
//--------------------------------------------------------------------
   return;                          // ����� �� ����. �-�� init()
  }
//--------------------------------------------------------------------
int start()                         // ����������� ������� start()
  {
   int i,                           // ������ ����
       Counted_bars;                // ���������� ������������ ����� 
//--------------------------------------------------------------------
   Counted_bars=IndicatorCounted(); // ���������� ������������ ����� 
   i=Bars-Counted_bars-1;           // ������ ������� ��������������
   while(i>=0)                      // ���� �� ������������� �����
     {
      // Get index of hourly bar
      int indexInOneHourBuffer = iBarShift(NULL,PERIOD_H1, 
         iTime(NULL, 0, i));
      double emaSlow = iMA(Symbol(), PERIOD_H1, 34, // TODO : make this a parameter
         0, MODE_EMA, PRICE_CLOSE,indexInOneHourBuffer);
      double emaFast = iMA(NULL, PERIOD_H1, 8, // TODO : make this a parameter
         0, MODE_EMA, PRICE_CLOSE, indexInOneHourBuffer);         
      Buf_0[i]=emaSlow;             // �������� 0 ������ �� i-�� ����
      Buf_1[i]=emaFast;              // �������� 1 ������ �� i-�� ����
      i--;                          // ������ ������� ���������� ����
     }
//--------------------------------------------------------------------
   return;                          // ����� �� ����. �-�� start()
  }
//--------------------------------------------------------------------