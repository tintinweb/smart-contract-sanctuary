/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

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
pragma solidity ^0.5.16;


// import "../PriceOracle.sol";
// import "../CErc20.sol";
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface CErc20 {
    function underlying() external view returns (address);
}

contract DefiBoxPriceOracle is Ownable{

    mapping(address => uint) prices;

    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    /// @dev Describe how the USD price should be determined for an asset.
    struct TokenConfig {
        address cToken;
        address underlying;
        uint256 baseUnit;
        uint256 priceDecimals;
        address chainLinkMarket;
        bool isChainLink;
    }

    TokenConfig[] public tokenConfigs;

    function addTokenConfig(address _cToken, address _underlying, uint256 _baseUnit, uint256 _priceDecimals, address _chainLinkMarket, bool _isChainLink) 
        external onlyOwner returns(bool) {
        require(_cToken != address(0), "invaild config");
        for (uint256 i = 0; i < tokenConfigs.length; i++) {
            TokenConfig memory tokenConfig = tokenConfigs[i];
            require(tokenConfig.cToken != _cToken, "exisiting config");
        }
        tokenConfigs.push(TokenConfig({
            cToken: _cToken,
            underlying: _underlying,
            baseUnit: _baseUnit,
            priceDecimals: _priceDecimals,
            chainLinkMarket: _chainLinkMarket,
            isChainLink: _isChainLink
        }));
        return true;
    }

    function setTokenConfig(TokenConfig calldata config, uint i) external onlyOwner returns (bool) {
        require(i < tokenConfigs.length, "token config not found");
        require(config.cToken != address(0), "invaild config");
        TokenConfig storage tokenConfig = tokenConfigs[i];
        tokenConfig.cToken = config.cToken;
        tokenConfig.underlying = config.underlying;
        tokenConfig.baseUnit = config.baseUnit;
        tokenConfig.priceDecimals = config.priceDecimals;
        tokenConfig.chainLinkMarket = config.chainLinkMarket;
        tokenConfig.isChainLink = config.isChainLink;
        return true;
    }

    function getCTokenIndex(address cToken) internal view returns (uint) {
        for (uint256 index = 0; index < tokenConfigs.length; index++) {
            TokenConfig memory tokenConfig = tokenConfigs[index];
            if (tokenConfig.cToken == cToken) return index;
        }
        return uint(-1);
    }

    function getUnderlyingIndex(address underlying) internal view returns (uint) {
        for (uint256 index = 0; index < tokenConfigs.length; index++) {
            TokenConfig memory tokenConfig = tokenConfigs[index];
            if (tokenConfig.underlying == underlying) return index;
        }
        return uint(-1);
    }

    /**
     * @notice Get the i-th config, according to the order they were passed in originally
     * @param i The index of the config to get
     * @return The config object
     */
    function getTokenConfig(uint i) public view returns (TokenConfig memory) {
        require(i < tokenConfigs.length, "token config not found");
        return tokenConfigs[i];
    }

    /**
     * @notice Get the config for the cToken
     * @dev If a config for the cToken is not found, falls back to searching for the underlying.
     * @param cToken The address of the cToken of the config to get
     * @return The config object
     */
    function getTokenConfigByCToken(address cToken) public view returns (TokenConfig memory) {
        uint index = getCTokenIndex(cToken);
        if (index != uint(-1)) {
            return getTokenConfig(index);
        }

        return getTokenConfigByUnderlying(CErc20(cToken).underlying());
    }

    /**
     * @notice Get the config for an underlying asset
     * @param underlying The address of the underlying asset of the config to get
     * @return The config object
     */
    function getTokenConfigByUnderlying(address underlying) public view returns (TokenConfig memory) {
        uint index = getUnderlyingIndex(underlying);
        if (index != uint(-1)) {
            return getTokenConfig(index);
        }

        revert("token config not found");
    }

    function getUnderlyingPrice(address cToken) public view returns (uint) {
        TokenConfig memory config = getTokenConfigByCToken(cToken);
        uint price;
        uint priceDecimals;
        if (config.isChainLink) {
            price = getChainLinkPrice(config.chainLinkMarket);
            priceDecimals = getChainLinkDecimals(config.chainLinkMarket);
        } else {
            address asset = address(CErc20(cToken).underlying());
            price = prices[asset];
            priceDecimals = config.priceDecimals;
        }
        // Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
        // Since the prices in this view have ? decimals, we must scale them by 1e(36 - ? - baseUnit)
        return mul((1e36 / (10 ** priceDecimals)), price) / config.baseUnit;
    }

    function getChainLinkPrice(address _aggregator) public view returns (uint)  {
        AggregatorV3Interface ref = AggregatorV3Interface(_aggregator);
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ref.latestRoundData();
        return uint(price);
    }

    function getChainLinkDecimals(address _aggregator) public view returns (uint8)  {
        AggregatorV3Interface aggregator = AggregatorV3Interface(_aggregator);
        return aggregator.decimals();
    }

    function getChainLinkLatestRoundData(address _aggregator) public view returns (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound)  {
        AggregatorV3Interface ref = AggregatorV3Interface(_aggregator);
        (
            roundID, 
            price,
            startedAt,
            timeStamp,
            answeredInRound
        ) = ref.latestRoundData();
    }

    function setUnderlyingPrice(address cToken, uint underlyingPriceMantissa) public onlyOwner {
        address asset = address(CErc20(cToken).underlying());
        emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        prices[asset] = underlyingPriceMantissa;
    }

    function setDirectPrice(address asset, uint price) public onlyOwner {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}