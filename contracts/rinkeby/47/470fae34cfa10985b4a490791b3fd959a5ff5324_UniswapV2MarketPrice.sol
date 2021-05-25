/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract UniswapV2MarketPrice  {
    enum PriceSource {
        NONE,     /// 0: normal config could not be NONE
        FIXED_USD, /// 1: implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER_HT, /// 2: implies the price is set by the reporter, not support now
        REPORTER_USDT /// 3:get price by uniswap  TOKEN/USDT
    }

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenConfig object for each supported asset, passed in the constructor.
    struct TokenConfig {
        string  symbol;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
        address uniswapMarket;
        bool isPrice1FromUniswap; // if (isPrice1FromUniswap) 
    }

    struct PriceInfo {
        string  symbol;
        uint    price; // with 6 decimal
    }

    TokenConfig[] public tokenConfigArray;

    bytes32  internal constant projectHash = keccak256(abi.encodePacked("KIKA"));


    /// @notice The number of wei in 1 HT
    uint public constant htBaseUnit = 1e18;

    // ethereum : 1e6;  heco: 1e18
    uint public constant usdtBaseUnit = 1e18;

    constructor() public {
     }

/*
    constructor(
        string[] memory symbolArray,
        uint256[] memory baseUintArray,
        PriceSource[] memory priceSourceArray, 
        uint256[] memory fixedPriceArray,
        address[] memory uniswapMarketArray,
        bool[] memory isPrice1FromUniswapArray) public {

        for (uint i = 0; i < symbolArray.length; i++) {
            string memory _symbol = symbolArray[i];

            TokenConfig memory config = TokenConfig({
            symbol : _symbol,
            baseUnit : baseUintArray[i],
            priceSource: priceSourceArray[i],
            fixedPrice: fixedPriceArray[i],
            uniswapMarket : uniswapMarketArray[i],
            isPrice1FromUniswap : isPrice1FromUniswapArray[i]
            });

           tokenConfigArray.push(config); 
        }
    }*/

    function isStringEqual(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // todo : 仅管理员有权限
    function addTokenConfig(string memory _symbol, uint256 _baseUint, PriceSource  _priceSource,
    uint256 _fixedPrice, address _uniswapMarket, bool _isPrice1FromUniswap) public  {
        
        for(uint i =0; i < tokenConfigArray.length; i++) {
            string memory symbol = tokenConfigArray[i].symbol;
            if(isStringEqual(_symbol,symbol)) {
                revert("token config exists");
            }
        }
        
        TokenConfig memory config = TokenConfig({
            symbol : _symbol,
            baseUnit : _baseUint,
            priceSource: _priceSource,
            fixedPrice: _fixedPrice,
            uniswapMarket : _uniswapMarket,
            isPrice1FromUniswap : _isPrice1FromUniswap
            });
            
        tokenConfigArray.push(config); 
    }

    /**
     * @notice Get the config for symbol
     * @param _symbol The symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbol(string memory _symbol) public view returns (TokenConfig memory) {        
        for(uint i =0; i < tokenConfigArray.length; i++) {
            string memory symbol = tokenConfigArray[i].symbol;

            if(isStringEqual(_symbol,symbol)) {
                 TokenConfig memory config = TokenConfig({
                symbol : tokenConfigArray[i].symbol,
                baseUnit : tokenConfigArray[i].baseUnit,
                priceSource: tokenConfigArray[i].priceSource,
                fixedPrice: tokenConfigArray[i].fixedPrice,
                uniswapMarket : tokenConfigArray[i].uniswapMarket,
                isPrice1FromUniswap : tokenConfigArray[i].isPrice1FromUniswap
               });

               return config;  
            }      
        }
        revert("token config not found");
    }

    function getAllPrice() public view returns (PriceInfo[] memory) {
        PriceInfo[] memory priceInfoArray = new PriceInfo[](tokenConfigArray.length);  

        string memory symbol;
        for(uint256 i = 0; i < tokenConfigArray.length; i++){
            symbol = tokenConfigArray[i].symbol;
            uint256 price =  getPrice(symbol);
            priceInfoArray[i].symbol = symbol;
            priceInfoArray[i].price = price;            
        }       
        return priceInfoArray;
    }

    // get market USD price from dex  with 6 decimal
    // for web only , not for lend contract
    function getPrice(string memory symbol) public view returns (uint) {
        
        TokenConfig memory config = getTokenConfigBySymbol(symbol);
        uint marketPrice = 0;
        if(config.priceSource == PriceSource.FIXED_USD){ // Fixed price
            marketPrice = config.fixedPrice;
        }else if(config.priceSource == PriceSource.REPORTER_USDT){ // For USD
            marketPrice = fetchPriceByUsdtPair(config);
        }
        return marketPrice;
    }


    /// @dev Overflow proof multiplication
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }

    function fetchPriceByUsdtPair(TokenConfig memory config) internal view virtual returns (uint) {
        uint marketPrice = 0;
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(config.uniswapMarket).getReserves();
                if(config.isPrice1FromUniswap){ 
            if(reserve1 != 0){
                // price = (reserve0 / usdtBaseUnit) / (reserve1 / config.baseUnit) * 1e6; 
                // price = reserve0 * config.baseUnit * 1e6 / usdtBaseUnit / reserve1;
                // reserve0 is USDT, reserve1 is underlying Token
                marketPrice = mul(mul(reserve0, config.baseUnit), 1e6) / usdtBaseUnit / reserve1; 
            }
        }else{
            if(reserve0 != 0){
                // price = (reserve1 / usdtBaseUnit) / (reserve0 / config.baseUnit) * 1e6; 
                // price = reserve1 * config.baseUnit * 1e6 / usdtBaseUnit / reserve0;
                // reserve1 is USDT, reserve0 is underlying Token
                marketPrice = mul(mul(reserve1, config.baseUnit), 1e6) / usdtBaseUnit / reserve0; 
            }
        }
        return marketPrice;
    }
}