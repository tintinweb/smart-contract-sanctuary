/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity ^0.4.13;

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract IERC20 {
    function balanceOf(
        address whom
    )
    external
    view
    returns (uint);


    function transfer(
        address _to,
        uint256 _value
    )
    external
    returns (bool);


    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    external
    returns (bool);



    function approve(
        address _spender,
        uint256 _value
    )
    public
    returns (bool);



    function decimals()
    external
    view
    returns (uint);


    function symbol()
    external
    view
    returns (string);


    function name()
    external
    view
    returns (string);


    function freezeTransfers()
    external;


    function unfreezeTransfers()
    external;
}

contract IStructuredStorage {

    function setProxyLogicContractAndDeployer(address _proxyLogicContract, address _deployer) external;
    function setProxyLogicContract(address _proxyLogicContract) external;

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns(uint);
    function getString(bytes32 _key) external view returns(string);
    function getAddress(bytes32 _key) external view returns(address);
    function getBytes(bytes32 _key) external view returns(bytes);
    function getBool(bytes32 _key) external view returns(bool);
    function getInt(bytes32 _key) external view returns(int);
    function getBytes32(bytes32 _key) external view returns(bytes32);

    // *** Getter Methods For Arrays ***
    function getBytes32Array(bytes32 _key) external view returns (bytes32[]);
    function getAddressArray(bytes32 _key) external view returns (address[]);
    function getUintArray(bytes32 _key) external view returns (uint[]);
    function getIntArray(bytes32 _key) external view returns (int[]);
    function getBoolArray(bytes32 _key) external view returns (bool[]);

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string _value) external;
    function setAddress(bytes32 _key, address _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // *** Setter Methods For Arrays ***
    function setBytes32Array(bytes32 _key, bytes32[] _value) external;
    function setAddressArray(bytes32 _key, address[] _value) external;
    function setUintArray(bytes32 _key, uint[] _value) external;
    function setIntArray(bytes32 _key, int[] _value) external;
    function setBoolArray(bytes32 _key, bool[] _value) external;

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteAddress(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
}

contract ITwoKeyEventSourceEvents {
    // This 2 functions will be always in the interface since we need them very often
    function ethereumOf(address me) public view returns (address);
    function plasmaOf(address me) public view returns (address);

    function created(
        address _campaign,
        address _owner,
        address _moderator
    )
    external;

    function rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    )
    external;

    function acquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    )
    external;

    function donationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    )
    external;

    function priceUpdated(
        bytes32 _currency,
        uint newRate,
        uint _timestamp,
        address _updater
    )
    external;

    function userRegistered(
        string _name,
        address _address,
        string _fullName,
        string _email,
        string _username_walletName
    )
    external;

    function cpcCampaignCreated(
        address proxyCPC,
        address contractor
    )
    external;


    function emitHandleChangedEvent(
        address _userPlasmaAddress,
        string _newHandle
    )
    public;


}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
}

contract ITwoKeySingletoneRegistryFetchAddress {
    function getContractProxyAddress(string _contractName) public view returns (address);
    function getNonUpgradableContractAddress(string contractName) public view returns (address);
    function getLatestCampaignApprovedVersion(string campaignType) public view returns (string);
}

interface ITwoKeySingletonesRegistry {

    /**
    * @dev This event will be emitted every time a new proxy is created
    * @param proxy representing the address of the proxy created
    */
    event ProxyCreated(address proxy);


    /**
    * @dev This event will be emitted every time a new implementation is registered
    * @param version representing the version name of the registered implementation
    * @param implementation representing the address of the registered implementation
    * @param contractName is the name of the contract we added new version
    */
    event VersionAdded(string version, address implementation, string contractName);

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string _contractName, string version, address implementation) public;

    /**
    * @dev Tells the address of the implementation for a given version
    * @param _contractName is the name of the contract we're querying
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string _contractName, string version) public view returns (address);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] path) external view returns (uint[] memory amounts);
}

contract IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external;
}

contract ITwoKeyExchangeRateContractStorage is IStructuredStorage {

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    require(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    require(c >= _a);
    return c;
  }
}

contract ITwoKeySingletonUtils {

    address public TWO_KEY_SINGLETON_REGISTRY;

    // Modifier to restrict method calls only to maintainers
    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
        require(ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
        _;
    }

    /**
     * @notice Function to get any singleton contract proxy address from TwoKeySingletonRegistry contract
     * @param contractName is the name of the contract we're looking for
     */
    function getAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getContractProxyAddress(contractName);
    }

    function getNonUpgradableContractAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getNonUpgradableContractAddress(contractName);
    }
}

contract UpgradeabilityStorage {
    // Versions registry
    ITwoKeySingletonesRegistry internal registry;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

contract Upgradeable is UpgradeabilityStorage {
    /**
     * @dev Validates the caller is the versions registry.
     * @param sender representing the address deploying the initial behavior of the contract
     */
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}

contract TwoKeyExchangeRateContract is Upgradeable, ITwoKeySingletonUtils {

    /**
     * Storage keys are stored on the top. Here they are in order to avoid any typos
     */
    string constant _currencyName2rate = "currencyName2rate";
    string constant _pairToOracleAddress = "pairToOracleAddress";
    string constant _twoKeyEventSource = "TwoKeyEventSource";

    using SafeMath for uint;
    bool initialized;

    ITwoKeyExchangeRateContractStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Function which will be called immediately after contract deployment
     * @param _twoKeySingletonesRegistry is the address of TWO_KEY_SINGLETON_REGISTRY contract
     * @param _proxyStorage is the address of proxy storage contract
     */
    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _proxyStorage
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyExchangeRateContractStorage(_proxyStorage);

        initialized = true;
    }


    /**
     * @notice Backend calls to update rates
     * @dev only twoKeyMaintainer address will be eligible to update it
     * @param _currency is the bytes32 (hex) representation of currency shortcut string
     * @param _baseToTargetRate is the rate between base and target currency
     */
    function setFiatCurrencyDetails(
        bytes32 _currency,
        uint _baseToTargetRate
    )
    public
    onlyMaintainer
    {
        storeFiatCurrencyDetails(_currency, _baseToTargetRate);
        address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource);
        ITwoKeyEventSourceEvents(twoKeyEventSource).priceUpdated(_currency, _baseToTargetRate, block.timestamp, msg.sender);
    }

    /**
     * @notice Function to update multiple rates at once
     * @param _currencies is the array of currencies
     * @dev Only maintainer can call this
     */
    function setMultipleFiatCurrencyDetails(
        bytes32[] _currencies,
        uint[] _baseToTargetRates
    )
    public
    onlyMaintainer
    {
        uint numberOfFiats = _currencies.length; //either _isETHGreaterThanCurrencies.length
        //There's no need for validation of input, because only we can call this and that costs gas
        for(uint i=0; i<numberOfFiats; i++) {
            storeFiatCurrencyDetails(_currencies[i], _baseToTargetRates[i]);
            address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource);
            ITwoKeyEventSourceEvents(twoKeyEventSource).priceUpdated(_currencies[i], _baseToTargetRates[i], block.timestamp, msg.sender);
        }
    }

    /**
     * @notice Function to store details about currency
     * @param _currency is the bytes32 (hex) representation of currency shortcut string
     * @param _baseToTargetRate is the rate between base and target currency
     */
    function storeFiatCurrencyDetails(
        bytes32 _currency,
        uint _baseToTargetRate
    )
    internal
    {
        bytes32 hashKey = keccak256(_currencyName2rate, _currency);
        PROXY_STORAGE_CONTRACT.setUint(hashKey, _baseToTargetRate);
    }


    /**
     * @notice Function to set ChainLink oracle addresses
     * @param  priceFeeds is the array of price feeds ChainLink contract addresses
     * @param  hexedPairs is the array of pairs hexed
     */
    function storeChainLinkOracleAddresses(
        bytes32 [] hexedPairs,
        address [] priceFeeds
    )
    public
    onlyMaintainer
    {
        uint i;

        for(i = 0; i < priceFeeds.length; i++) {
            PROXY_STORAGE_CONTRACT.setAddress(
                keccak256(_pairToOracleAddress, hexedPairs[i]),
                priceFeeds[i]
            );
        }
    }


    /**
     * @notice Function getter for base to target rate
     * @param base_target is the name of the currency
     */
    function getBaseToTargetRate(
        string base_target
    )
    public
    view
    returns (uint)
    {
        bytes32 hexedBaseTarget = stringToBytes32(base_target);
        return getBaseToTargetRateInternal(hexedBaseTarget);
    }


    function getBaseToTargetRateInternal(
        bytes32 baseTarget
    )
    internal
    view
    returns (uint)
    {
        address oracleAddress = PROXY_STORAGE_CONTRACT.getAddress(keccak256(_pairToOracleAddress, baseTarget));
        int latestPrice = getLatestPrice(oracleAddress);
        uint8 decimalsPrecision = getDecimalsReturnPrecision(oracleAddress);
        uint maxDecimals = 18;
        return uint(latestPrice) * (10**(maxDecimals.sub(decimalsPrecision))); //do sub instead of -
    }


    /**
     * @notice Helper calculation function
     */
    function exchangeCurrencies(
        string base_target,
        uint base_amount
    )
    public
    view
    returns (uint)
    {
        return getBaseToTargetRate(base_target).mul(base_amount);
    }



    function getFiatToStableQuotes(
        uint amountInFiatWei,
        string fiatCurrency,
        bytes32 [] stableCoinPairs //Pairs stable coin - ETh
    )
    public
    view
    returns (uint[])
    {
        uint len = stableCoinPairs.length;

        uint [] memory pairs = new uint[](len);

        uint i;

        // We have rate 1 DAI = X USD => 1 USD = 1/X DAI
        // We need to compute N dai = Y usd
        for(i = 0; i < len; i++) {
            // This represents us how much USD is 1 stable coin unit worth
            // Example: 1 DAI = rate = 0.99 $
            // 1 * DAI = 0.99 * USD
            // 1 USD = 1 * DAI / 0.99
            // 15 USD = 15 / 0.99

            // get rate against ETH (1 STABLE  = rate ETH)
            uint stableEthRate = getBaseToTargetRateInternal(stableCoinPairs[i]);

            // This is the ETH/USD rate
            uint eth_usd = getBaseToTargetRateInternal(stringToBytes32("USD"));

            uint rate =  stableEthRate.mul(eth_usd).div(10**18);

            pairs[i] = amountInFiatWei.mul(10**18).div(rate);
        }

        return pairs;
    }

    /**
     * @notice          Function to fetch 2KEY against DAI rate from uniswap
     */
    function get2KeyDaiRate()
    public
    view
    returns (uint)
    {
        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        address [] memory path = new address[](2);

        path[0] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        path[1] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI");

        uint[] memory amountsOut = new uint[](2);

        amountsOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(
            10**18,
            path
        );

        return amountsOut[1];
    }

    function getStableCoinToUSDQuota(
        address stableCoinAddress
    )
    public
    view
    returns (uint)
    {
        // Take the symbol of the token
        string memory tokenSymbol = IERC20(stableCoinAddress).symbol();
        // Check that this symbol is matching address stored in our codebase so we are sure that it's real asset
        if(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(tokenSymbol) == stableCoinAddress) {
            // Chainlink provides us with the rates from StableCoin -> ETH, and along with that we have ETH -> USD quota

            // Generate pair against ETH (Example: Symbol = DAI ==> result = 'DAI-ETH'
            string memory tokenSymbolToCurrency = concatenateStrings(tokenSymbol, "-ETH");

            // get rate against ETH (1 STABLE  = rate ETH)
            uint stableEthRate = getBaseToTargetRateInternal(stringToBytes32(tokenSymbolToCurrency));

            // This is the ETH/USD rate
            uint eth_usd = getBaseToTargetRateInternal(stringToBytes32("USD"));

            return stableEthRate.mul(eth_usd).div(10**18);
        }
        // If stable coin is not matched, return 0 as quota
        return 0;
    }

    /**
     * @notice          Function to fetch the latest token price from ChainLink oracle
     * @param           oracleAddress is the address of oracle we fetch price from
     */
    function getLatestPrice(
        address oracleAddress
    ) public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(oracleAddress).latestRoundData();
        return price;
    }


    /**
     * @notice          Function to fetch on how many decimals is the response
     * @param           oracleAddress is the address of the oracle from which we take price
     */
    function getDecimalsReturnPrecision(
        address oracleAddress
    )
    public
    view
    returns (uint8)
    {
        return AggregatorV3Interface(oracleAddress).decimals();
    }

    /**
     * @notice          Function to fetch address of the oracle for the specific pair
     * @param           pair is the name of the pair for which we store oracles
     */
    function getChainLinkOracleAddress(
        string memory pair
    )
    public
    view
    returns (address)
    {
        bytes32 hexedPair = stringToBytes32(pair);
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_pairToOracleAddress, hexedPair));
    }




    /**
     * @notice Helper method to convert string to bytes32
     * @dev If string.length > 32 then the rest after 32nd char will be deleted
     * @return result
     */
    function stringToBytes32(
        string memory source
    )
    internal
    returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }


    function concatenateStrings(
        string a,
        string b
    )
    internal
    pure
    returns (string)
    {
        return string(abi.encodePacked(a,b));
    }
}