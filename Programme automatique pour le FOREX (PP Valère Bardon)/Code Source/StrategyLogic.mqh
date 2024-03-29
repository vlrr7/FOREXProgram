//+------------------------------------------------------------------+
//|                                                StrategyLogic.mqh |
//|                                                    Valère Bardon |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Valère Bardon"
#property link      ""
#property strict

//+------------------------------------------------------------------+
//| Fichier qui comprend la logique de la stratégie                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Fonction principale de la stratégie                              |
//+------------------------------------------------------------------+
// Vérifie si l'histograme du MACD croise la ligne zéro

int getMACDCrosshover()
  {
  
// Déclaration des variables
   double prev_macd_main = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, si + 1);
   double macd_main = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, si);

// Si la valeur de l'histogramme de la bougie antérieure est en dessous de 0,
// mais que celle de la bougie actuelle est au dessus de 0, cela signifie que
// l'histogramme a croisé la ligne 0 par le haut, signifiant un signal pour acheter.
   if(prev_macd_main < 0 && macd_main > 0)
      return TYPE_BULLISH;
   else
      if(prev_macd_main > 0 && macd_main < 0) // Si c'est le contraire, c'est un signal pour vendre
         return TYPE_BEARISH;
      else
         return T_NOTREND; // Sinon, il n'y a aucun signal

  }

//+------------------------------------------------------------------+
//| Trouver la direction de la tendance                              |
//+------------------------------------------------------------------+
/*
Afin d'avoir une plus grande précision, il ne faut pas seulement prendre une position
à chaque fois que l'histogramme croise la ligne de zéro, mais il faut aussi vérifier
que le signal donné par le MACD correspond à la tendance générale du marché, car il ne
faut jamais aller contre la tendance. Ensemble, ces deux fonctions nous permettrons de
prendre des positions un peu plus précises.
*/
int getTrend()
  {
  
// Déclaration des variables (chaque variable est une moyenne mobile)
   double ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE, si);
   double ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE, si);
   double ema200 = iMA(_Symbol, _Period, 100, 0, MODE_EMA, PRICE_CLOSE, si);

   if(ema20 > ema50 && ema50 > ema200) // Pour que la tendance soit haussière, il faut que les moyennes mobiles plus rapides soit en haut de celles plus lentes
      return T_UPTREND;
   else
      if(ema20 < ema50 && ema50 < ema200) // Pour une tendance soit basissère, c'est le contraire
         return T_DOWNTREND;
      else
         return T_NOTREND; // Sinon, on ne retient pas de tendance et on ne prend aucune position
  }

//+------------------------------------------------------------------+
