/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// File: contracts\UniswapV2MarketPriceBSC.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

contract PowerContract {
    bytes32 internal constant projectHash =
        keccak256(abi.encodePacked("202106081754"));

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

contract UniswapV2MarketPriceBSC is PowerContract {
    enum PriceSource {
        NONE, /// 0: normal config could not be NONE
        FIXED_USD, /// 1: implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER_BNB, /// 2: get price by dex pair锛?such as   TOKEN/BNB
        REPORTER_USD /// 3: get price by dex pair锛?such as TOKEN/USDT銆乀OKEN/BUSD
    }

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenConfig object for each supported asset, passed in the constructor.
    struct TokenConfig {
        string symbol;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
        address uniswapMarket;
        bool isPrice1FromUniswap; // if (isPrice1FromUniswap)
    }

    struct PriceInfo {
        string symbol;
        uint256 price; // with 6 decimal
    }

    TokenConfig[] public tokenConfigArray;

    uint256 public constant bnbBaseUnit = 1e18;

    uint256 public constant usdtBaseUnit = 1e18;

    constructor() public {}

    function isStringEqual(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function addTokenConfig(
        string memory _symbol,
        uint256 _baseUint,
        PriceSource _priceSource,
        uint256 _fixedPrice,
        address _uniswapMarket,
        bool _isPrice1FromUniswap
    ) public onlyOwner {
        for (uint256 i = 0; i < tokenConfigArray.length; i++) {
            string memory symbol = tokenConfigArray[i].symbol;
            if (isStringEqual(_symbol, symbol)) {
                revert("token config exists");
            }
        }

        TokenConfig memory config =
            TokenConfig({
                symbol: _symbol,
                baseUnit: _baseUint,
                priceSource: _priceSource,
                fixedPrice: _fixedPrice,
                uniswapMarket: _uniswapMarket,
                isPrice1FromUniswap: _isPrice1FromUniswap
            });

        tokenConfigArray.push(config);
    }

    function batchAddTokenConfig(
        string[] memory symbolArray,
        uint256[] memory baseUintArray,
        PriceSource[] memory priceSourceArray,
        uint256[] memory fixedPriceArray,
        address[] memory uniswapMarketArray,
        bool[] memory isPrice1FromUniswapArray
    ) public onlyOwner {
        for (uint256 i = 0; i < symbolArray.length; i++) {
            addTokenConfig(
                symbolArray[i],
                baseUintArray[i],
                priceSourceArray[i],
                fixedPriceArray[i],
                uniswapMarketArray[i],
                isPrice1FromUniswapArray[i]
            );
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
    function getTokenConfigBySymbol(string memory _symbol)
        public
        view
        returns (TokenConfig memory)
    {
        for (uint256 i = 0; i < tokenConfigArray.length; i++) {
            string memory symbol = tokenConfigArray[i].symbol;

            if (isStringEqual(_symbol, symbol)) {
                TokenConfig memory config =
                    TokenConfig({
                        symbol: tokenConfigArray[i].symbol,
                        baseUnit: tokenConfigArray[i].baseUnit,
                        priceSource: tokenConfigArray[i].priceSource,
                        fixedPrice: tokenConfigArray[i].fixedPrice,
                        uniswapMarket: tokenConfigArray[i].uniswapMarket,
                        isPrice1FromUniswap: tokenConfigArray[i]
                            .isPrice1FromUniswap
                    });

                return config;
            }
        }
        revert("token config not found");
    }

    function getAllPrice() public view returns (PriceInfo[] memory) {
        PriceInfo[] memory priceInfoArray =
            new PriceInfo[](tokenConfigArray.length);

        string memory symbol;
        for (uint256 i = 0; i < tokenConfigArray.length; i++) {
            symbol = tokenConfigArray[i].symbol;
            uint256 price = getPrice(symbol);
            priceInfoArray[i].symbol = symbol;
            priceInfoArray[i].price = price;
        }
        return priceInfoArray;
    }

    // get market USD price from dex  with 6 decimal
    // for web only , not for lend contract
    function getPrice(string memory symbol) public view returns (uint256) {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);
        uint256 marketPrice = 0;
        if (config.priceSource == PriceSource.FIXED_USD) {
            // Fixed price
            marketPrice = config.fixedPrice;
        } else if (config.priceSource == PriceSource.REPORTER_USD) {
            // For USD
            marketPrice = fetchPriceByUsdtPair(config);
        }
        else if (config.priceSource == PriceSource.REPORTER_BNB) {
            uint bnbPrice =  fetchPriceByUsdtPair(getTokenConfigBySymbol('BNB'));

            marketPrice = fetchPriceByBnbPair(config, bnbPrice);
        }
        return marketPrice;
    }

    /// @dev Overflow proof multiplication
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }

    function fetchPriceByUsdtPair(TokenConfig memory config)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 marketPrice = 0;
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(config.uniswapMarket).getReserves();
        if (config.isPrice1FromUniswap) {
            if (reserve1 != 0) {
                // price = (reserve0 / usdtBaseUnit) / (reserve1 / config.baseUnit) * 1e6;
                // price = reserve0 * config.baseUnit * 1e6 / usdtBaseUnit / reserve1;
                // reserve0 is USDT, reserve1 is underlying Token
                marketPrice =
                    mul(mul(reserve0, config.baseUnit), 1e6) /
                    usdtBaseUnit /
                    reserve1;
            }
        } else {
            if (reserve0 != 0) {
                // price = (reserve1 / usdtBaseUnit) / (reserve0 / config.baseUnit) * 1e6;
                // price = reserve1 * config.baseUnit * 1e6 / usdtBaseUnit / reserve0;
                // reserve1 is USDT, reserve0 is underlying Token
                marketPrice =
                    mul(mul(reserve1, config.baseUnit), 1e6) /
                    usdtBaseUnit /
                    reserve0;
            }
        }
        return marketPrice;
    }

        // fetch Token/BNB market price as USD with 6 decimal 
    function fetchPriceByBnbPair(TokenConfig memory config, uint bnbPrice) internal view virtual returns (uint) {
        uint marketPrice = 0;
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(config.uniswapMarket).getReserves();
        if(config.isPrice1FromUniswap){ 
            if(reserve1 != 0){
                // price = (reserve0 / bnbBaseUnit) / (reserve1 / config.baseUnit) * bnbPrice; 
                // reserve0 is WBNB, reserve1 is token  // Multiply before divide bigNumber
                marketPrice = mul(mul(reserve0, config.baseUnit), bnbPrice) / bnbBaseUnit / reserve1;
            }
        }else{
            if(reserve0 != 0){
                // price = (reserve1 / bnbBaseUnit) / (reserve0 / config.baseUnit) * bnbPrice; 
                // reserve1 is WBNB, reserve0 is token
                marketPrice = mul(mul(reserve1, config.baseUnit), bnbPrice) / bnbBaseUnit / reserve0;
            }
        }
        return marketPrice;
    }
}