//+------------------------------------------------------------------+
//|                                                       newBar.mqh |
//|                                                    Valère Bardon |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Valère Bardon"
#property link      ""
#property strict

// Variable globale
datetime gBarTime;

//+------------------------------------------------------------------+
//| Fonction qui regarde si une nouvelle bougie s'est créée          |
//+------------------------------------------------------------------+
/*
Par défaut, le code d'un Expert Advisor (programme pour automatiser les transactions sur le FOREX) est exécuté tous les ticks, 
donc plusieurs fois par seconde, à chaque fois que le prix est mis à jour. Cela permet d'avoir une plus grande précision lors
de l'utilisation de stratégie plus précise. Cependant, dans le cas de ma stratégie, il n'est pas nécessaire de surcharger l'ordinateur
pour qu'il exécute du code aussi rapidement. C'est pourquoi j'exécute le code de la stratégie à chaque fois qu'une nouvelle bougie
est créée, donc à chaque 1h, chaque 4h ou chaque jour, dépendamment du "timeframe" choisi.
*/
bool newBar()
  {
  
   datetime currentBarTime = iTime(_Symbol, _Period, 0); // Prend l'heure à laquelle la dernière bougie à commencer à se former
   if(currentBarTime != gBarTime)  // Si l'heure de la bougie actuelle n'est pas la même que celle dans la variable globale, cela signifie qu'une nouvelle bougie a été créée
     {
      gBarTime = currentBarTime; // Mettre à jour la variable globale gBarTime à l'heure de la bougie actuelle
      return true; // Retourne "true" s'il y a eu une nouvelle bougie
     }
   else
      return false; // Sinon retourne "false"

  }

//+------------------------------------------------------------------+
