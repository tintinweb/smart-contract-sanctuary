/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function transfer(address _to, uint _value) external returns (bool);
    function decimals() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint256);
}

struct MyTokenImbalanceData {
    int  totalBuyUnitsImbalance;
    uint lastRateUpdateBlock;
}

  // bps - basic rate steps. one step is 1 / 10000 of the rate.
struct StepFunction {
    int[] x; // quantity for each step. Quantity of each step includes previous steps.
    int[] y; // rate change per quantity step  in bps.
}

struct RatesTokenData {
    bool listed;  // was added to reserve
    bool enabled; // whether trade is enabled

    uint index;  // index in tokenList
    // position in the compact data
    uint arrayIndex;
    uint fieldIndex;
    uint baseRate;
    StepFunction buyRateQtyStepFunction; // in bps. higher quantity - bigger the rate.
    StepFunction sellRateQtyStepFunction;// in bps. higher the qua
    
    uint slippageBpsUnit;
}

abstract contract  IConversionRate {
    
    mapping(address => RatesTokenData) public tokenData;
    mapping(address => MyTokenImbalanceData) public tokenImbalanceData;
    mapping(address => uint) public tokenMaxTotalImbalance;
    function recordImbalance(address token,int buyAmount,uint256 rateUpdateBlock,uint256 currentBlock) virtual external;
    function getRate(address token, uint256 currentBlockNumber, bool buy, uint256 qty) virtual external view returns(uint256);
    function getListedTokens() virtual external view returns(address[] memory);
    function getQuota(address token, bool isBuy) virtual external view returns (int quota);
    function maxGasPrice() virtual external view returns (uint);
    function getFeedRate(address token, bool buy) virtual public view returns (uint);
    function getRateUpdateBlock(address token) virtual public view returns(uint);
   
}


contract KyberHelper {
    
    struct TokenData {
        address token;
        
        uint256 rateUpdateBlock;

        uint256 baseBuyRate;
        uint256 baseSellRate;
        
        StepFunction buyRateQtyStepFunction;       // in bps. higher quantity - bigger the rate.
        StepFunction sellRateQtyStepFunction;      // in bps. higher the qua
        StepFunction buyRateImbalanceStepFunction; // in BPS. higher reserve imbalance - bigger the rate.
        StepFunction sellRateImbalanceStepFunction;
    }
    
    struct RatesCompactData {
        address token;
        byte buy;
        byte sell;
    }
    
    struct TokenControlInfo {
        address token;
        uint minimalRecordResolution;
        uint maxPerBlockImbalance;
        uint maxTotalImbalance;
    }

    struct KyberTokenImbalanceData {
        int  lastBlockBuyUnitsImbalance;
        uint lastBlock;
        int  totalBuyUnitsImbalance;
        uint lastRateUpdateBlock;
    }
    
    //  coded by 1inch
    struct TokenImbalanceData {
        address token;
        uint256[5] data;
    }
    
    // coded by OneBit
    struct MyImbalanceData {
        address token;
        int totalImbalance;
    }
    
    struct QuotaData {
        address token;
        uint256 buyQuota;
        uint256 sellQuota;
    }
    
    string constant public VERSION = "MyKyberRate v0.1";
    
    function getMyImbalanceData(address conversionRateContract) external view returns (MyImbalanceData[] memory data) {
        address[] memory tokens = IConversionRate(conversionRateContract).getListedTokens();
        data = new MyImbalanceData[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            data[i].token = tokens[i];
            uint rateUpdateBlock = IConversionRate(conversionRateContract).getRateUpdateBlock(tokens[i]);
            (int totalBuyUnitsImbalance, uint lastRateUpdateBlock) = IConversionRate(conversionRateContract).tokenImbalanceData(tokens[i]);
            if(lastRateUpdateBlock == rateUpdateBlock) {
                data[i].totalImbalance = totalBuyUnitsImbalance;
            }
            else {
                 data[i].totalImbalance = 0;
            }
        }
    }
    
    function getQuotaData(address conversionRateContract) external view returns (QuotaData[] memory data) {
        address[] memory tokens = IConversionRate(conversionRateContract).getListedTokens();
        data = new QuotaData[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            data[i].token = tokens[i];
            int buyQuota = IConversionRate(conversionRateContract).getQuota(tokens[i],true);
            int sellQuota = IConversionRate(conversionRateContract).getQuota(tokens[i],false);
            if(buyQuota >=0 ){
                data[i].buyQuota = uint(buyQuota);
            }
            else {
                data[i].buyQuota = 0;
            }
            if(sellQuota >=0 ){
                data[i].sellQuota = uint(sellQuota);
            }
            else {
                data[i].sellQuota = 0;
            }
            
        }
    }
    
    function getTokenControlInfo(address conversionRateContract) external view returns (TokenControlInfo[] memory data) {
        address[] memory tokens = IConversionRate(conversionRateContract).getListedTokens();
        data = new TokenControlInfo[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            uint maxTotalImbalance = IConversionRate(conversionRateContract).tokenMaxTotalImbalance(tokens[i]);
            
            data[i].token = tokens[i];
            uint tokenResolution = getTokenResolution(tokens[i]);
            data[i].minimalRecordResolution = tokenResolution; 
            data[i].maxPerBlockImbalance = maxTotalImbalance/tokenResolution;
            data[i].maxTotalImbalance = maxTotalImbalance/tokenResolution;
        }
    }
    
    function getRatesCompactData(address conversionRateContract) external view returns (RatesCompactData[] memory data) {
          address[] memory tokens = IConversionRate(conversionRateContract).getListedTokens();
          data = new RatesCompactData[](tokens.length);
          for (uint i = 0; i < tokens.length; i++) {              
              data[i].token = tokens[i];
              data[i].buy = 0;
              data[i].sell = 0;
          }
    }
    
    function getStepFunctionData(address conversionRateContract) external view returns (TokenData[] memory data) {
        address[] memory tokens = IConversionRate(conversionRateContract).getListedTokens();
        
        data = new TokenData[](tokens.length);
        
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            data[i].token = tokens[i];
            
            data[i].rateUpdateBlock = IConversionRate(conversionRateContract).getRateUpdateBlock(tokens[i]);
            
            data[i].baseBuyRate = IConversionRate(conversionRateContract).getFeedRate(tokens[i], true);
            data[i].baseSellRate = IConversionRate(conversionRateContract).getFeedRate(tokens[i], false);

            (,,,,,, StepFunction memory buyRateQtyStepFunction, StepFunction memory sellRateQtyStepFunction,)
            = IConversionRate(conversionRateContract).tokenData(token);
            data[i].buyRateQtyStepFunction = buyRateQtyStepFunction;
            data[i].sellRateQtyStepFunction = sellRateQtyStepFunction;
        }
    }
    
    function getTokenImbalanceData(address conversionRateContract) external view returns (TokenImbalanceData[] memory data) {
        address[] memory tokens = IConversionRate(conversionRateContract).getListedTokens();
        data = new TokenImbalanceData[](tokens.length);
        uint currentBlockNumber = block.number;
        for (uint i = 0; i < tokens.length; i++) {
            data[i].token = tokens[i];
            uint tokenResolution = getTokenResolution(tokens[i]);
            (int totalBuyUnitsImbalance, uint lastRateUpdateBlock) = IConversionRate(conversionRateContract).tokenImbalanceData(tokens[i]);
            //uint rateUpdateBlock = IConversionRate(conversionRateContract).getRateUpdateBlock(tokens[i]);
            for (uint j = 0; j < 5; j++) {
                //if(currentBlockNumber%5 == j && lastRateUpdateBlock == rateUpdateBlock) {
                if(currentBlockNumber%5 == j) {
                    totalBuyUnitsImbalance = totalBuyUnitsImbalance/int(tokenResolution);
                    KyberTokenImbalanceData memory kyberTokenImbalanceData = KyberTokenImbalanceData(0,currentBlockNumber,totalBuyUnitsImbalance,lastRateUpdateBlock);
                    data[i].data[j] = encodeTokenImbalanceData(kyberTokenImbalanceData);
                }
                else {
                    data[i].data[j] = 0x1;
                }
                
            }
            
        }
    }
    
    function getTokenResolution(address token) internal view returns (uint) {
        uint tokenDecimal = ERC20(token).decimals();
        if (tokenDecimal > 10) {
            return 10 ** (tokenDecimal-10);
        }
        else {
            return 1;
        }
    }

    uint constant internal POW_2_64 = 2 ** 64;
    function encodeTokenImbalanceData(KyberTokenImbalanceData memory data) public pure returns(uint) {
        // check for overflows
        require(data.lastBlockBuyUnitsImbalance < int(POW_2_64 / 2));
        require(data.lastBlockBuyUnitsImbalance > int(-1 * int(POW_2_64) / 2));
        require(data.lastBlock < POW_2_64);
        require(data.totalBuyUnitsImbalance < int(POW_2_64 / 2));
        require(data.totalBuyUnitsImbalance > int(-1 * int(POW_2_64) / 2));
        require(data.lastRateUpdateBlock < POW_2_64);

        // do encoding
        uint result = uint(data.lastBlockBuyUnitsImbalance) & (POW_2_64 - 1);
        result |= data.lastBlock * POW_2_64;
        result |= (uint(data.totalBuyUnitsImbalance) & (POW_2_64 - 1)) * POW_2_64 * POW_2_64;
        result |= data.lastRateUpdateBlock * POW_2_64 * POW_2_64 * POW_2_64;

        return result;
    }
    
    function decodeTokenImbalanceData(uint input) public pure returns(KyberTokenImbalanceData memory) {
        KyberTokenImbalanceData memory data;

        data.lastBlockBuyUnitsImbalance = int(int64(input & (POW_2_64 - 1)));
        data.lastBlock = uint(uint64((input / POW_2_64) & (POW_2_64 - 1)));
        data.totalBuyUnitsImbalance = int(int64((input / (POW_2_64 * POW_2_64)) & (POW_2_64 - 1)));
        data.lastRateUpdateBlock = uint(uint64((input / (POW_2_64 * POW_2_64 * POW_2_64))));

        return data;
    }
    
}