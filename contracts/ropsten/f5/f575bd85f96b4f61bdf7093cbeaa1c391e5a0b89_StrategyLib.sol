pragma solidity ^0.4.18;

library StrategyLib{
  /*-----------------------------------------------------------------------
  Publish historical performan of some strategy
  *date
  *underPrice,prevUnderPrice: price variation of the day
  *position: position of the day (taken the previous day)
  *stratPrice: strategy price of the day (taken the previous day)
  ------------------------------------------------------------------------*/
  event newRecord(bytes15 indexed name, uint32 indexed date, int256 stratVariation, uint64 prevStratPrice, uint64 stratPrice, uint64 truncatedStratPrice, uint64 prevUnderPrice, uint64 underPrice, int64 position,int8 category);

  /*------------------------------------------------------------------------
  Backtesting functions
  -------------------------------------------------------------------------*/
  function libbatchbacktest(bytes15 name, uint64 strategyInitPrice, uint32[]dates, uint64[] prices, int64[] positions) public returns (uint64) {
       uint64 strategyPrice = strategyInitPrice;
       uint64 truncatedStrategyPrice;
       // the first element of the array is the initial state of the strategy
       for(uint8 i=1; i<dates.length; i++){
           // the position used here is the position taken the previous day
           int256 variation = calculateVariation(prices[i-1], prices[i], positions[i]);
           uint64 prevStratPrice = strategyPrice;
           (strategyPrice,truncatedStrategyPrice) = calculateValue(variation, strategyPrice);
           emit newRecord(name,dates[i],variation, prevStratPrice, strategyPrice, truncatedStrategyPrice, prices[i-1], prices[i], positions[i],0);
           strategyPrice=truncatedStrategyPrice;
       }
       return strategyPrice;
 }


  /*------------------------------------------------------------------------
  Publishing functions
  -------------------------------------------------------------------------*/
  // the position here given is the position for the day matching the date, taken on the previous day close
  function advance(bytes15 name, uint32 date, uint64 udlPreviousPrice, uint64 udlPrice, int64 position, uint64 stratPrice) public returns (uint64) {
    int256 variation = calculateVariation(udlPreviousPrice, udlPrice, position);
    uint64 newStrategyPrice;
    uint64 truncatedNewStrategyPrice;
    (newStrategyPrice,truncatedNewStrategyPrice) = calculateValue(variation,stratPrice);
    emit newRecord(name,date,variation, stratPrice, newStrategyPrice, truncatedNewStrategyPrice, udlPreviousPrice, udlPrice, position, 0);

    return truncatedNewStrategyPrice;
  }

/*------------------------------------------------------------------------
Compute the variation of price of index according to the last position EOD
----Arguments:
      pxPre : price of precedent open dat
      pxCur : price EOD
      lastPosit : last position EOD
----Return:
      (pxCur/pxPre)^(lastPosit)-1
-------------------------------------------------------------------------*/
 function calculateVariation(uint64 pxPre, uint64 pxCur, int64 lastPosit) internal pure returns (int256){
    int256 variation = int256(pxCur) - int256(pxPre);
    // to keep up the precision up to 32 digits
    variation *=  1e32;
    variation /=  pxPre;
    variation *=  int256(lastPosit);
    return variation;
 }

 /*------------------------------------------------------------------------
 Compute the algo value EOD for some index
 ----Arguments:
    variation : the variation of algo index value
    lastValue : last algo value EOD
 ----Return :
    lastValue*(1+variation)
 --------------------------------------------------------------------------*/
 function calculateValue(int256 variation, uint64 lastValue) internal pure returns (uint64,uint64){
    uint64 newStrategyPrice;
    uint64 truncatedNewStrategyPrice;

    int256 delta = int256(lastValue) * variation;
    //1e44 = 1e32*1e12 (precision for digits and position precision)
    delta/=1e44;
    newStrategyPrice=uint64(int256(lastValue) +delta);

    // we only keep 4 digits (when price precision to 12)
    truncatedNewStrategyPrice = newStrategyPrice/1e8;
    truncatedNewStrategyPrice = truncatedNewStrategyPrice*1e8;
    return (newStrategyPrice,truncatedNewStrategyPrice);
 }
}