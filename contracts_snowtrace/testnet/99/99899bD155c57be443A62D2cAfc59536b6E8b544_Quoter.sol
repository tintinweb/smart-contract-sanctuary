// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

/// @title PollenDAO Quoter
/// @author Jaime Delgado
/// @notice module to get price of assets
/// @dev This contract function's can be called only by the admin

import "../../PollenDAOStorage.sol";
import "./QuoterModuleStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Quoter is PollenDAOStorage, QuoterModuleStorage {
    uint256 private constant RATE_DECIMALS = 18;

    /// @dev emit event when a price feed is added
    event PriceFeedAdded(
        address indexed asset,
        address feed,
        RateBase rateBase
    );

    /// @dev emits an event when a price feed is removed
    event PriceFeedRemoved(address indexed asset, RateBase rateBase);

    /*****************
    EXTERNAL FUNCTIONS
    *****************/

    /// @notice add a feed for a rateBase and asset
    /// @param rateBase base currency for the price
    /// @param asset asset to be priced
    /// @param feed address of the chainlink feed
    function addPriceFeed(
        address,
        RateBase rateBase,
        address asset,
        address feed
    ) external onlyAdmin {
        _addPriceFeed(rateBase, asset, feed);
    }

    /// @notice add feeds for assets
    /// @param rateBase base currency for the price
    /// @param asset asset to be priced
    /// @param feed address of the chainlink feed
    function addPriceFeeds(
        address,
        RateBase[] memory rateBase,
        address[] memory asset,
        address[] memory feed
    ) external onlyAdmin {
        for (uint256 i = 0; i < asset.length; i++) {
            _addPriceFeed(rateBase[i], asset[i], feed[i]);
        }
    }

    /// @notice remove a feed
    /// @param rateBase base currency for the price
    /// @param asset asset to be priced
    function removePriceFeed(
        address,
        RateBase rateBase,
        address asset
    ) external onlyAdmin {
        QuoterStorage storage qs = getQuoterStorage();
        require(
            qs.priceFeeds[rateBase][asset] != address(0),
            "Quoter: feed not found"
        );
        qs.priceFeeds[rateBase][asset] = address(0);
        emit PriceFeedRemoved(asset, rateBase);
    }

    /*************
    VIEW FUNCTIONS
    *************/

    ///@notice getter for priceFeed address
    ///@param rateBase the base for the quote (USD, ETH)
    ///@param asset asset
    function getFeed(
        address,
        RateBase rateBase,
        address asset
    ) external view returns (address) {
        QuoterStorage storage qs = getQuoterStorage();
        return qs.priceFeeds[rateBase][asset];
    }

    /// @notice get a price for an asset
    /// @param rateBase base currency for the price
    /// @param asset asset to be priced
    function quotePrice(
        address,
        RateBase rateBase,
        address asset
    ) public view returns (uint256 rate, uint256 updatedAt) {
        QuoterStorage storage qs = getQuoterStorage();
        address feed = qs.priceFeeds[rateBase][asset];
        require(feed != address(0), "Quoter: asset doen't have feed");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feed);
        uint8 decimals = priceFeed.decimals();
        (, int256 answer, , uint256 _updatedAt, ) = priceFeed.latestRoundData();
        updatedAt = _updatedAt;
        rate = decimals == RATE_DECIMALS
            ? uint256(answer)
            : uint256(answer) * (10**uint256(RATE_DECIMALS - decimals));

        return (rate, _updatedAt);
    }

    /// @notice add a feed for a rateBase and asset
    /// @param rateBase base currency for the price
    /// @param asset asset to be priced
    /// @param feed address of the chainlink feed
    function _addPriceFeed(
        RateBase rateBase,
        address asset,
        address feed
    ) internal {
        require(asset != address(0), "Quoter: asset cannot be zero address");
        require(feed != address(0), "Quoter: feed cannot be zero address");
        QuoterStorage storage qs = getQuoterStorage();
        qs.priceFeeds[rateBase][asset] = feed;
        emit PriceFeedAdded(asset, feed, rateBase);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

/// @title Quoter staorage contract
/// @author Jaime Delgado
/// @notice define the base storage required by the quoter module
/// @dev This contract must be inherited by modules that require access to variables defined here

contract PollenDAOStorage {
    bytes32 internal constant POLLENDAO_STORAGE_SLOT =
        keccak256("PollenDAO.storage");

    struct DAOStorage {
        // Mapping for registered modules (the mapping should always be the first element
        // ...if modified, the fallback must be modified as well)
        mapping(address => bool) isRegisteredModule;
        // mapping for proposalId => voterAddress => numVotes
        mapping(uint256 => mapping(address => uint256)) numVotes;
        // Module adddress by name
        mapping(string => address) moduleByName;
        // system admin
        address admin;
        // Pollen token
        address pollenToken;
    }

    modifier onlyAdmin() {
        DAOStorage storage ds = getPollenDAOStorage();
        require(msg.sender == ds.admin, "PollenDAO: admin access required");
        _;
    }

    /* solhint-disable no-inline-assembly */
    function getPollenDAOStorage()
        internal
        pure
        returns (DAOStorage storage ms)
    {
        bytes32 slot = POLLENDAO_STORAGE_SLOT;
        assembly {
            ms.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

/// @title Quoter storage contract
/// @author Jaime Delgado
/// @notice define the storage required by the quoter module
/// @dev This contract must be inherited by modules that require access to variables defined here

contract QuoterModuleStorage {
    bytes32 private constant QUOTER_STORAGE_SLOT =
        keccak256("PollenDAO.quoter.storage");

    enum RateBase {
        Usd,
        Eth
    }

    struct QuoterStorage {
        // Maps RateBase and asset to priceFeed
        mapping(RateBase => mapping(address => address)) priceFeeds;
    }

    /* solhint-disable no-inline-assembly */
    function getQuoterStorage()
        internal
        pure
        returns (QuoterStorage storage ms)
    {
        bytes32 slot = QUOTER_STORAGE_SLOT;
        assembly {
            ms.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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