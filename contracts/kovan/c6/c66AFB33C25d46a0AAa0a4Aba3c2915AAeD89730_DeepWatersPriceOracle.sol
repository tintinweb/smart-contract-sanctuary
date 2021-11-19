/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Partial interface for a Chainlink Aggregator.
 */
interface AggregatorV3Interface {
    // latestRoundData should raise "No data present"
    // if he do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
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

/**
 * @dev Interface for a DeepWaters price oracle.
 */
interface IDeepWatersPriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
    function getFallbackAssetPrice(address asset) external view returns (uint256);
    function getFallbackAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
}

/**
 * @title DeepWatersPriceOracle
 * @notice Smart contract to get the price of an asset from Chainlink Aggregator
 * It also allows to get and to set a fallback price
 * @author DeepWaters
 */
contract DeepWatersPriceOracle is Ownable, IDeepWatersPriceOracle {
    event SetChainlinkPriceFeeds(address[] assets, address[] _chainlinkPriceFeeds);
    event UpdateFallbackPrices(address priceProvider, address[] assets, uint256[] prices);
    event AddFallbackPriceProvider(address indexed priceProvider);
    event RemoveFallbackPriceProvider(address indexed priceProvider);

    mapping(address => AggregatorV3Interface) private chainlinkPriceFeeds;

    // the address used to identify ETH
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    struct FallbackPrice {
        uint64 timestamp;
        uint256 price;
    }
    
    mapping(address => FallbackPrice) private fallbackPrices;
    mapping(address => bool) private priceProviders;
    
    modifier onlyPriceProvider {
        require(priceProviders[msg.sender], 'Caller is not the price provider');
        _;
    }
    
    constructor() public {
        _addFallbackPriceProvider(msg.sender);
    }

    /**
    * @notice Set Chainlink price feeds for a list of assets
    * @param assets The addresses of the assets
    * @param _chainlinkPriceFeeds The address of the Chainlink price feed of each asset
    */
    function setChainlinkPriceFeeds(address[] calldata assets, address[] calldata _chainlinkPriceFeeds)
        external
        onlyOwner
    {
        require(assets.length == _chainlinkPriceFeeds.length, 'Length parameter inconsistency');
        
        for (uint256 i = 0; i < assets.length; i++) {
            chainlinkPriceFeeds[assets[i]] = AggregatorV3Interface(_chainlinkPriceFeeds[i]);
        }
        
        emit SetChainlinkPriceFeeds(assets, _chainlinkPriceFeeds);
    }

    /**
    * @notice Gets an asset price
    * @param asset The asset address
    */
    function getAssetPrice(address asset) public view returns (uint256) {
        AggregatorV3Interface chainlinkPriceFeed = chainlinkPriceFeeds[asset];

        if (asset == ETH_ADDRESS) {
            return 1 ether;
        } else {
            (, int256 signedPrice, , , ) = chainlinkPriceFeed.latestRoundData();
            return uint256(signedPrice);
        }
    }
    
    /**
    * @notice @notice Gets a list of assets prices by a list of assets addresses
    * @param assets The list of assets addresses
    */
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](assets.length);
        
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getAssetPrice(assets[i]);
        }
        
        return prices;
    }
    
    /**
    * @notice Gets the address of the Chainlink price feed by an asset address
    * @param asset The address of the asset
    * @return address The address of the Chainlink price feed
    */
    function getChainlinkPriceFeed(address asset) external view returns (address) {
        return address(chainlinkPriceFeeds[asset]);
    }

    /**
    * @notice Gets an fallback asset price
    * @param asset The asset address
    */
    function getFallbackAssetPrice(address asset) public view returns (uint256) {
        return uint256(fallbackPrices[asset].price);
    }
    
    /**
    * @notice Gets a list of fallback prices by a list of assets addresses
    * @param assets The list of assets addresses
    */
    function getFallbackAssetsPrices(address[] calldata assets) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](assets.length);
        
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getFallbackAssetPrice(assets[i]);
        }
        
        return prices;
    }

    /**
    * @notice Update a fallback prices
    * @param assets The list of assets addresses
    * @param prices The list of prices
    */
    function updateFallbackPrices(address[] calldata assets, uint256[] calldata prices) external onlyPriceProvider {
        require(assets.length == prices.length, 'Length parameter inconsistency');
        
        for (uint256 i = 0; i < assets.length; i++) {
            fallbackPrices[assets[i]] = FallbackPrice(uint64(block.timestamp), prices[i]);
        }

        emit UpdateFallbackPrices(msg.sender, assets, prices);
    }

    /**
    * @notice Add a address of fallback price provider
    * @param priceProvider The address of fallback price provider
    */
    function addFallbackPriceProvider(address priceProvider) external onlyOwner {
        _addFallbackPriceProvider(priceProvider);
    }
    
    /**
    * @notice Internal function to add a address of fallback price provider
    * @param priceProvider The address of fallback price provider
    */
    function _addFallbackPriceProvider(address priceProvider) internal {
        priceProviders[priceProvider] = true;

        emit AddFallbackPriceProvider(priceProvider);
    }

    /**
    * @notice Remove a address from list fallback price providers
    * @param priceProvider The address of fallback price provider
    */
    function removeFallbackPriceProvider(address priceProvider) external onlyOwner {
        priceProviders[priceProvider] = false;

        emit RemoveFallbackPriceProvider(priceProvider);
    }
}