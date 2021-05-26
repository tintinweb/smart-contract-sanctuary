/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract OwnableContract  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract UniswapV2MarketPrice  is OwnableContract {
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

    function isStringEqual(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function addTokenConfig(string memory _symbol, uint256 _baseUint, PriceSource  _priceSource,
    uint256 _fixedPrice, address _uniswapMarket, bool _isPrice1FromUniswap)   public onlyOwner {
        
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


    function batchAddTokenConfig(
        string[] memory symbolArray,
        uint256[] memory baseUintArray,
        PriceSource[] memory priceSourceArray, 
        uint256[] memory fixedPriceArray,
        address[] memory uniswapMarketArray,
        bool[] memory isPrice1FromUniswapArray) public onlyOwner {

        for (uint i = 0; i < symbolArray.length; i++) {
            addTokenConfig(symbolArray[i], baseUintArray[i],priceSourceArray[i], fixedPriceArray[i], uniswapMarketArray[i], isPrice1FromUniswapArray[i]);       
        }
    }

    function tokenConfigLength() external view returns (uint256) {
        return tokenConfigArray.length;
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