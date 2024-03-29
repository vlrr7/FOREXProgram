//+------------------------------------------------------------------+
//|                                            MACDCrosshoverMTF.mq4 |
//|                                                    Valère Bardon |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "vlrr"
#property link      ""
#property version   "1.00"
#property strict

/* DESCRIPTION DU PROGRAMME
Le programme suit une stratégie extrêmement simple qui suit la tendance générale de la paire de devise choisie. Les indictaurs utilisés sont
3 moyennes mobiles (20, 50, 100), le MACD (Moving average convergence/divergence) et le ATR (Average true range). Les moyennes mobiles sont utilisées
pour obtenir la tendance de la paire de devise (expliqué plus en détail de le fichier 'StrategyLogic.mqh' dans 'getTrend()'). Le MACD, lui, donne les signaux
d'achat et de vente. Lorsque l'histogramme croise la ligne 0 de bas en haut, c'est un signal d'achat (gain de momemtum haussier), et lorsqu'il la croise de
haut en bas, c'est signal de vente (gain de momemtum baissier. Si la tendance est haussière, on achète lorsqu'il y a un signal d'achat, et lorsque la tendance
est baissère, on vend lorsqu'il y a un signal de vente. Le ATR sert pour définir les stoploss, puisqu'il calcule la volatilité d'une bougie. On calcule donc
le stoploss en multipliant cette valeur par 3 ou par 1 (dépendamment de la valeur de l'ATR, expliqué plus en détail dans 'OrderTaking.mqh' 'takeOrder()'),
et on l'ajoute ou le soustrait au prix d'achat ou de vente de la position afin d'obtenir un stoploss qui ne se fera pas toucher par une trop grande volatilité.
Le take profit est ensuite calculé en multipliant le nombre de pips (unité de mesure de base du FOREX, correspond principalement à 0,0001$ ou 0,01$) risqué
avec le stop loss par 2, d'où un risk/reward ratio de 2. Ainsi, en principe, le programme risque à chaque position de gagner deux fois plus qu'il risque.
Cependant, ce n'est jamais exact puisque le broker (l'application qui passe les ordres) ne peut pas gérer des nombres infiniment précis, et il y a donc des
nombre arrondis. Le programme est capable de quitter les positions tout seul, dès que le prix touche le stop loss ou le take profit.
*/




//+------------------------------------------------------------------+
//| Constantes                                                       |
//+------------------------------------------------------------------+
#define MAGIC_NUMBER 20222023

#define TYPE_BULLISH                0
#define TYPE_BEARISH                1
#define T_UPTREND                   2
#define T_DOWNTREND                 3
#define T_NOTREND                   4

const int si = 1;
input double risk_management_percentage = 2; // Pourcentage risqué du compte par ordre

//+------------------------------------------------------------------+
//| Fichiers importés                                                |
//+------------------------------------------------------------------+
#include "newBar.mqh" // Fonction qui vérifie si une nouvelle bougie a été créée
#include "StrategyLogic.mqh" // Fichier qui contient les deux principales fonctions pour la logique de la stratégie
#include "OrderTaking.mqh" // Fichier qui contient les fonctions pour passer des ordres


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("INIT !");
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("DEINIT !");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
  // Exécuter le code de la stratégie seulement lorsqu'une nouvelle bougie est formée
   if(newBar())
      OnBar();
      
  }

//+------------------------------------------------------------------+
//| Main Function                                                    |
//+------------------------------------------------------------------+
void OnBar()
  {
   switch(getTrend())
     {
      case T_UPTREND :
         if(getMACDCrosshover() == TYPE_BULLISH) // Si la tendance est haussière et il y a un signal d'achat, acheter
            takeOrder(TYPE_BULLISH);
         break;
      case T_DOWNTREND :
         if(getMACDCrosshover() == TYPE_BEARISH) // Si la tendance est baissière et il y a un signal de vente, vendre
            takeOrder(TYPE_BEARISH);
         break;
      default:
         break;
     }
  }

//+------------------------------------------------------------------+
