//+------------------------------------------------------------------+
//|                                                  OrderTaking.mqh |
//|                                                    Valère Bardon |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Valère Bardon"
#property link      ""
#property strict

//+---------------------------------------------------------------------------------------------+
//| Fichier qui comprend les fonctions nécessaire pour passer des ordres et bien gérer le risque|
//+---------------------------------------------------------------------------------------------+

// Constantes
const double PIP_VALUE = MarketInfo(_Symbol, MODE_TICKSIZE) * 10; // Valeur d'un pip, c'est la valeur de base pour calculer les profits et pertes afin de gérer le risque
const double LOT_SIZE = MarketInfo(_Symbol, MODE_LOTSIZE); // Valeur de la taille d'un lot (le lot est l'unité de mesure utilisé pour passer des ordres)

// Variable globale
int gTicket; // Une variable globale qui retient la valeur du dernier ordre passé. Non utilisé, mais recommandé de stocker la variable

//+------------------------------------------------------------------+
//| Fonction pour passer des ordres (prendre des positions)          |
//+------------------------------------------------------------------+
void takeOrder(int type)
  {

// Déclaration des variables
   double lot_size;
   int atr_value_mult = 3; // On multipliera plus tard cette valeur par la valeur de l'ATR pour définir un stop loss assez grand, tout en ayant un take profit atteignable avec un risk/reward ratio de 2
   if(getAtr(si) >= 1) // Si la valeur de l'ATR est plus grande que 1, elle est déjà grande et il n'est pas nécessaire de la multiplier par 3
         atr_value_mult = 1;
   if(type == TYPE_BULLISH) // Pour acheter
     {
      double sl = Ask - getAtr(si) * atr_value_mult; // Calcul du stop loss
      double tp = Ask + (Ask - sl) * 2; // Calcule du take profit
      
      int sl_in_pips = int(MathRound((Ask - sl) / PIP_VALUE)); // On trouve le nombre de pips que l'on perderait si notre stop loss est touché, afin de calculer la taille de la position et gérer le risque
      lot_size = getVolume(sl_in_pips, TYPE_BULLISH); // On trouve la taille de la position nécessaire pour ne pas risquer plus de 2% du compte

      gTicket = OrderSend(_Symbol, OP_BUY, lot_size, Ask, 100, sl, tp, "Bullish position", MAGIC_NUMBER); // Passer l'ordre
     }
   else // Pour vendre, le principe est le même
     {
      double sl = Bid + getAtr(si) * atr_value_mult;
      double tp = Bid - (sl - Bid) * 2;
      
      int sl_in_pips = int(MathRound((sl - Bid) / PIP_VALUE));
      lot_size = getVolume(sl_in_pips, TYPE_BEARISH);

      gTicket = OrderSend(_Symbol, OP_SELL, lot_size, Bid, 100, sl, tp, "Bearish position", MAGIC_NUMBER);
     }

  }

//+------------------------------------------------------------------------------+
//| Utilisé pour gérer le risque (seulement risquer 1 ou 2% du compte par ordre) |
//+------------------------------------------------------------------------------+
double getVolume(double sl, int exchange_type) // Exchange rate is Ask for buy and Bid for sell
  {
  
   if(sl == 0) // S'il le stoploss est trop petit, on retourne la valeur minimale que le broker peut accepter pour éviter les erreurs
      return MarketInfo(_Symbol, MODE_MINLOT);

// Initialisation des variables
   double lots;
   double risk_amount = AccountBalance() * (risk_management_percentage / 100); // Argent risqué
   double exchange_rate = 1; // Taux de change. Très important, car la devise du compte n'est pas toujours la même que la devise de cotation

// Calculer le taux de change entre la devise de cotation et la devise du compte (https://www.cashbackforex.com/tools/position-size-calculator/EURGBP)
// La devise de cotation est la deuxième devise dans la paire de devise (ex : JPY dans USDJPY). C'est la devise utilisée pour dans la paire de devise.
   string quote_currency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
   string account_currency = AccountCurrency();
   string exchange_rate_pair = account_currency+quote_currency; // Nous trouvons la paire de devise qui contient la devise du compte et celle de cotation

   if(quote_currency != account_currency) // Si la devise du compte et la même que celle de cotation, aucune conversion n'est requise
     {
      bool reverse_currency_pair = false;
      exchange_rate = MarketInfo(exchange_rate_pair, MODE_ASK);
      if(exchange_rate == 0) // Il faut vérifier que notre paire de devise entre le compte et la cotation existe, sinon il faut changer l'ordre des devises (ex : JPYUSD n'existe pas, mais c'est USDJPY)
        {
         reverse_currency_pair = true;
         exchange_rate_pair = quote_currency+account_currency; // On inverse les devises dans la paire de devise
        }

      if(exchange_type == TYPE_BULLISH) // Dans le cas d'un achat, on prend la valeur du Ask
         exchange_rate = MarketInfo(exchange_rate_pair, MODE_ASK);
      else // Sinon on prend la valeur du Bid
         exchange_rate = MarketInfo(exchange_rate_pair, MODE_BID);

      if(reverse_currency_pair) // Si l'on a du changer l'ordre des devises dans la paire de devise, il faut inverser le taux de change. Sinon, on obtiendra la valeur de (devise du compte / devise de cotation), et non (devise de cotation / devise du compte) comme on le veut pour la formule
         exchange_rate = 1 / exchange_rate;
     }

// FORMULE
   lots = ((risk_amount * exchange_rate) / (sl * PIP_VALUE * LOT_SIZE));

// Il faut bien arrondir la valeur pour que l'ordre puisse passer sans erreur
   double lot_step = MarketInfo(_Symbol, MODE_MINLOT); // Trouver à combien de décimale arrondir
   lots = MathRound(lots / lot_step) * lot_step; // Arrondir

// Il faut vérifier que la taille du lot ne soit pas en dessous de la taille minimale et n'excède pas la valeur maximale définie par le Broker
   if(lots < MarketInfo(_Symbol, MODE_MINLOT))
     {
      Print("Lots traded is too small for your broker.");
      lots = MarketInfo(_Symbol, MODE_MINLOT); // Si la taille du lot est trop petite, la changer pour la valeur minimale acceptée par le Broker
     }
   else
      if(lots > MarketInfo(_Symbol, MODE_MAXLOT))
        {
         Print("Lots traded is too large for your broker.");
         lots = MarketInfo(_Symbol, MODE_MAXLOT); // Si la taille du lot est trop grande, la changer pour la valeur maximale acceptée par le Broker
        }

   return lots;
  }

//+--------------------------------------------------------------------------------------------------------------+
//| Prendre la valeur ATR (Average True Range) de la bougie selectionnée. Le ATR est un indicateur qui permet    |
//| de voir la volatilité, il est donc utile pour trouver des "stoploss" qui ne se feront pas toucher par erreur.|
//+--------------------------------------------------------------------------------------------------------------+
double getAtr(int index)
  {
   double atr_value = iATR(_Symbol, _Period, 14, index);
   return atr_value;
  }

//+------------------------------------------------------------------+
