pragma solidity ^0.4.13;

contract ProofOfPerformancePublisher{

    struct ProofOfPerfBlockState {
      uint32 date;
      bytes32 index_name;
      bytes32 obfuscatedRawDataHash;
      bytes32 obfuscatedDerivativeDataHash;
      bytes32 previousProofOfPerfBlockHash;
    }

    address public owner;
    bytes32 public name;      

    uint32 dateInit;                  

    bool isAlive;

    mapping(bytes32 => ProofOfPerfBlockState) private blockStates;

    mapping(address=>bool) public delegatinglist;

    modifier onlyAuthorized(){
        require(isdelegatinglisted(msg.sender));
        _;
    }

 
    event newProofOfPerfBlockHiddenRecord(uint32 _date, bytes32 _index_name, bytes32 _proofOfPerfBlockHash, bytes32 _obfuscatedRawDataHash, bytes32 _obfuscatedDerivativeDataHash, bytes32 _previousProofOfPerfBlockHash);
    event newProofOfPerfBlockRevealedRecord(uint32 _date, bytes32 _index_name, bytes32 _proofOfPerfBlockHash, bytes32 _outputDataHash, bytes32 _rawDataHash, bytes16 _rawDataSecret, bytes32 _derivativeDataHash, bytes16 _derivativeDataSecret, bytes32 _previousProofOfPerfBlockHash);
   
    event Authorized(address authorized, uint timestamp);
    event Revoked(address authorized, uint timestamp);
 
    constructor(bytes32 _name) public{
        owner = msg.sender;
        delegatinglist[owner] = true;
        name = _name;
    }

    function authorize(address authorized) public onlyAuthorized {
        delegatinglist[authorized] = true;
        emit Authorized(authorized, now);
    }

    // also if not in the list..
    function revoke(address authorized) public onlyAuthorized {
        delegatinglist[authorized] = false;
        emit Revoked(authorized, now);
    }

    function authorizeMany(address[50] authorized) public onlyAuthorized {
        for(uint i = 0; i < authorized.length; i++) {
            authorize(authorized[i]);
        }
    }

    function isdelegatinglisted(address authorized) public view returns(bool) {
      return delegatinglist[authorized];
    }

    // to improve add a CRUX consensys mapping management to be able to find them all
    function getProofOfPerfBlockStateState(bytes32 _proofOfPerfBlockHash)
      public
      onlyAuthorized
      constant
      returns(uint32,bytes32,bytes32,bytes32,bytes32)
    {
      return(
        blockStates[_proofOfPerfBlockHash].date,
        blockStates[_proofOfPerfBlockHash].index_name,
        blockStates[_proofOfPerfBlockHash].obfuscatedRawDataHash,
        blockStates[_proofOfPerfBlockHash].obfuscatedDerivativeDataHash,
        blockStates[_proofOfPerfBlockHash].previousProofOfPerfBlockHash);
    }

    function hashDataBlock(string jsonBlock) public pure returns(bytes32) {
      return(sha256(abi.encodePacked(jsonBlock)));
    }

    function obfuscatedHashDataBlock(string jsonBlock,string secret) public pure returns(bytes32) {
      return(sha256(abi.encodePacked(jsonBlock,secret)));
    }

    function addProofOfPerfBlock(uint32 _date, bytes32 _index_name, bytes32 _obfuscatedRawDataHash, bytes32 _obfuscatedDerivativeDataHash, bytes32 _previousProofOfPerfBlockHash) public onlyAuthorized {
        //H(n) = hash(concat(h1,h2,h3,h4,H(n-1))
        bytes32 _proofOfPerfBlockHash = sha256(abi.encodePacked(_obfuscatedRawDataHash,_obfuscatedDerivativeDataHash,_previousProofOfPerfBlockHash));
        ProofOfPerfBlockState memory blockState = ProofOfPerfBlockState({date:_date, index_name: _index_name, obfuscatedRawDataHash:_obfuscatedRawDataHash, obfuscatedDerivativeDataHash:_obfuscatedDerivativeDataHash, previousProofOfPerfBlockHash:_previousProofOfPerfBlockHash});
        blockStates[_proofOfPerfBlockHash] = blockState;
        emit newProofOfPerfBlockHiddenRecord(_date, _index_name, _proofOfPerfBlockHash,_obfuscatedRawDataHash,_obfuscatedDerivativeDataHash,_previousProofOfPerfBlockHash);
    }

    function revealProofOfPerfBlock(uint32 _date, bytes32 _index_name, bytes32 _rawDataHash, bytes16 _rawDataSecret, bytes32 _derivativeDataHash, bytes16 _derivativeDataSecret, bytes32 _previousProofOfPerfBlockHash, bytes32 _outputDataHash) public {
        bytes32 _obfuscatedRawDataHash=sha256(abi.encodePacked(_rawDataHash,_rawDataSecret));
        bytes32 _obfuscatedDerivativeDataHash=sha256(abi.encodePacked(_derivativeDataHash,_derivativeDataSecret));
        bytes32 _proofOfPerfBlockHash = sha256(abi.encodePacked(_obfuscatedRawDataHash,_obfuscatedDerivativeDataHash,_previousProofOfPerfBlockHash));
        ProofOfPerfBlockState memory blockState =  blockStates[_proofOfPerfBlockHash];
        require(_obfuscatedRawDataHash == blockState.obfuscatedRawDataHash);
        require(_obfuscatedDerivativeDataHash == blockState.obfuscatedDerivativeDataHash);
        deleteBlockState(_proofOfPerfBlockHash);
        emit newProofOfPerfBlockRevealedRecord(_date,_index_name,_proofOfPerfBlockHash, _outputDataHash,_rawDataHash,_rawDataSecret,_derivativeDataHash,_derivativeDataSecret,_previousProofOfPerfBlockHash);
    }

    function deleteBlockState(bytes32 _proofOfPerfBlockHash) public onlyAuthorized {
        //bytes32 recomputedHash = sha256(abi.encodePacked(date,positions,secretPath));
        delete blockStates[_proofOfPerfBlockHash];
    }

}

library StrategyLib{
  /*-----------------------------------------------------------------------
  Publish historical performan of some strategy
  *date
  *underPrice,prevUnderPrice: price variation of the day
  *position: position of the day (taken the previous day)
  *stratPrice: strategy price of the day (taken the previous day)
  ------------------------------------------------------------------------*/
  event newRecord(bytes32 indexed name, uint32 indexed date, int256 stratVariation, uint64 prevStratPrice, uint64 stratPrice, uint64 truncatedStratPrice, uint64 prevUnderPrice, uint64 underPrice, int64 position,int category);
  event newBiRecord(bytes32 indexed name,uint32 indexed date,int256 stratVariation, uint64 prevStratPrice, uint64 stratPrice, uint64 truncatedStratPrice, uint64 prevUnderPrice, uint64 underPrice, int64 position, uint64 secondPrevUnderPrice, uint64 secondUnderPrice, int64 secondPosition, int category);
  event succinctBiRecord(uint32 indexed date, uint64 prevStratPrice, uint64 stratPrice, uint64 truncatedStratPrice,int category);
  event succinctBiUnder(uint64 prevUnderPrice, uint64 underPrice, int64 position, uint64 secondPrevUnderPrice, uint64 secondUnderPrice, int64 secondPosition);

  /*------------------------------------------------------------------------
  Backtesting functions
  -------------------------------------------------------------------------*/  
  function libbibatchbacktest(uint64 strategyInitPrice, uint32[] dates, uint64[] prices, uint64[] secondPrices, int64[] positions, int64[] secondPositions) public returns (uint64) {
       uint64 strategyPrice = strategyInitPrice;
       uint64 truncatedStrategyPrice;
       // the first element of the array is the initial state of the strategy
       for(uint8 i=1; i<dates.length; i++){
           // the position used here is the position taken the previous day
           int256 variation = calculateVariation(prices[i-1], prices[i], positions[i]) + calculateVariation(secondPrices[i-1], secondPrices[i], secondPositions[i]);
           uint64 prevStratPrice = strategyPrice;
           (strategyPrice,truncatedStrategyPrice) = calculateValue(variation, strategyPrice);
           //emit newBiRecord(name,dates[i],variation, prevStratPrice, strategyPrice, truncatedStrategyPrice, prices[0][i-1], prices[0][i], positions[0][i], prices[1][i-1], prices[1][i], positions[1][i],-1);           
           //emit succinctBiRecord(dates[i], strategyPrice, prices[i-1], prices[i], positions[i], secondPrices[i-1], secondPrices[i], secondPositions[i],-1);           
           emit succinctBiRecord(dates[i], prevStratPrice, strategyPrice, truncatedStrategyPrice,-1);
           emit succinctBiUnder(prices[i-1], prices[i], positions[i], secondPrices[i-1], secondPrices[i], secondPositions[i]);
           
           strategyPrice=truncatedStrategyPrice;
       }
       return strategyPrice;
 }

  /*------------------------------------------------------------------------
  Backtesting functions
  -------------------------------------------------------------------------*/
  function libbatchbacktest(bytes32 name, uint64 strategyInitPrice, uint32[] dates, uint64[] prices, int64[] positions) public returns (uint64) {
       uint64 strategyPrice = strategyInitPrice;
       uint64 truncatedStrategyPrice;
       // the first element of the array is the initial state of the strategy
       for(uint8 i=1; i<dates.length; i++){
           // the position used here is the position taken the previous day
           int256 variation = calculateVariation(prices[i-1], prices[i], positions[i]);
           uint64 prevStratPrice = strategyPrice;
           (strategyPrice,truncatedStrategyPrice) = calculateValue(variation, strategyPrice);
           emit newRecord(name,dates[i],variation, prevStratPrice, strategyPrice, truncatedStrategyPrice, prices[i-1], prices[i], positions[i],-1);
           strategyPrice=truncatedStrategyPrice;
       }
       return strategyPrice;
 }

  /*------------------------------------------------------------------------
  Publishing functions
  -------------------------------------------------------------------------*/
  // the position here given is the position for the day matching the date, taken on the previous day close
  function advance(bytes32 name, uint32 date, uint64 udlPreviousPrice, uint64 udlPrice, int64 position, uint64 stratPrice) public returns (uint64) {
    int256 variation = calculateVariation(udlPreviousPrice, udlPrice, position);
    uint64 newStrategyPrice;
    uint64 truncatedNewStrategyPrice;
    (newStrategyPrice,truncatedNewStrategyPrice) = calculateValue(variation,stratPrice);
    emit newRecord(name,date,variation, stratPrice, newStrategyPrice, truncatedNewStrategyPrice, udlPreviousPrice, udlPrice, position,1);

    return truncatedNewStrategyPrice;
  }

  function biAdvance(uint32 date, uint64[2] udlPreviousPrice, uint64[2] udlPrice, int64[2] position, uint64 stratPrice) public returns (uint64) {
    int256 variation = calculateVariation(udlPreviousPrice[0], udlPrice[0], position[0])+calculateVariation(udlPreviousPrice[1], udlPrice[1], position[1]);
    uint64 newStrategyPrice;
    uint64 truncatedNewStrategyPrice;
    (newStrategyPrice,truncatedNewStrategyPrice) = calculateValue(variation,stratPrice);
        
    emit succinctBiRecord(date, stratPrice, newStrategyPrice, truncatedNewStrategyPrice, 1);
    emit succinctBiUnder(udlPreviousPrice[0], udlPrice[0], position[0], udlPreviousPrice[1], udlPrice[1], position[1]);

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


 function calculateValue(int256 variation, uint64 lastValue) internal pure returns (uint64,uint64){
    uint64 newStrategyPrice;
    uint64 truncatedNewStrategyPrice;

    int256 delta = int256(lastValue) * variation;
    //1e40 = 1e32*1e8 (precision for digits and position precision)
    delta/=1e40;
    newStrategyPrice=uint64(int256(lastValue) +delta);

    // we only keep 4 digits (when price precision to 8)
    truncatedNewStrategyPrice = newStrategyPrice/1e4;
    truncatedNewStrategyPrice = truncatedNewStrategyPrice*1e4;
    return (newStrategyPrice,truncatedNewStrategyPrice);
 }

 // for precisition 12
 //function calculateValue(int256 variation, uint64 lastValue) internal pure returns (uint64,uint64){
 //   uint64 newStrategyPrice;
 //   uint64 truncatedNewStrategyPrice;
//
 //   int256 delta = int256(lastValue) * variation;
 //   //1e44 = 1e32*1e12 (precision for digits and position precision)
 //   delta/=1e44;
 //   newStrategyPrice=uint64(int256(lastValue) +delta);
//
 //   // we only keep 4 digits (when price precision to 12)
 //   truncatedNewStrategyPrice = newStrategyPrice/1e8;
 //   truncatedNewStrategyPrice = truncatedNewStrategyPrice*1e8;
 //   return (newStrategyPrice,truncatedNewStrategyPrice);
 //}

 function hashPosition(uint32 date, int64 position, bytes16 secretPath) public pure returns(bytes32) {
    return(sha256(abi.encodePacked(date,position,secretPath)));
 }
}