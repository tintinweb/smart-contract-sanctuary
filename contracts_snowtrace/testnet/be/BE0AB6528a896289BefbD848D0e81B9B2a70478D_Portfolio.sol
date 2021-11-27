// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

/// @title Portfolio
/// @notice Portfolio module for Pollen DAO
/// @dev Contains asset management logic

import "../../../interface/IPollen.sol";
import "./PortfolioModuleStorage.sol";
import "../../PollenDAOStorage.sol";
import "../../../lib/PortfolioAssetSet.sol";
import "../quoter/Quoter.sol";
import "../quoter/QuoterModuleStorage.sol";

contract Portfolio is
    PollenDAOStorage,
    PortfolioModuleStorage,
    QuoterModuleStorage
{
    using PortfolioAssetSet for PortfolioAssetSet.AssetSet;
    address internal constant DAO_ADDRESS = address(0); // change this to DAO address
    /***************
    EVENTS
    ***************/

    event AssetAdded(address indexed asset);
    event AssetRemoved(address indexed asset);
    event PortfolioCreated(
        address indexed creator,
        uint256 portfolioId,
        uint256 amount
    );
    event PortfolioClosed(
        address indexed creator,
        uint256 portfolioId,
        uint256 gainOrLossAmount,
        uint256 closingValue
    );
    event PortfolioRebalanced(
        address indexed creator,
        uint256 portfolioId,
        uint256 newAmount,
        uint256 gainOrLossAmount,
        uint256 closingValue
    );

    /*****************
    EXTERNAL FUNCTIONS
    *****************/

    /// @notice adds an asset to the DAO's Asset Set
    /// @dev Only callable by ProxyAdmin
    /// @param asset address of the asset to add
    function addAsset(address, address asset) external onlyAdmin {
        require(asset != address(0), "Portfolio: asset cannot be zero address");
        PortfolioStorage storage ps = getPortfolioStorage();
        require(!ps.assets.contains(asset), "Portfolio: asset already in set");
        ps.assets.add(asset);
        emit AssetAdded(asset);
    }

    /// @notice removes an asset for the DAO's Asset Set
    /// @dev Only callable by ProxyAdmin
    /// @param asset address of the asset to remove
    function removeAsset(address, address asset) external onlyAdmin {
        require(asset != address(0), "Portfolio: asset cannot be zero address");
        require(
            IPollen(asset).balanceOf(address(this)) == 0,
            "Portfolio: asset has balance"
        );
        PortfolioStorage storage ps = getPortfolioStorage();
        require(ps.assets.contains(asset), "Portfolio: asset not in set");
        ps.assets.remove(asset);
        emit AssetRemoved(asset);
    }

    /// @notice allows user to create a portfolio
    /// @param _amount the amount of PLN the user wants to send in
    /// @param _weights array of relative weights of portfolio assets
    function createPortfolio(
        address,
        uint256 _amount,
        uint8[] calldata _weights
    ) external {
        PortfolioStorage storage ps = getPortfolioStorage();
        DAOStorage storage ds = getPollenDAOStorage();
        require(_amount > 0, "Portfolio: initial amount cannot be 0");
        require(
            _weights.length == ps.assets.elements.length,
            "Portfolio: weights array has to equal asset set size"
        );
        require(isValidWeights(_weights));

        uint256[] memory assetAmounts = getPortfolioAmounts(_weights);

        Portfolio memory portfolio = Portfolio({
            assetAmounts: assetAmounts,
            weights: _weights,
            initialValue: _amount,
            open: true
        });

        ps.portfolios[msg.sender][ps.portfolioId] = portfolio;
        ps.portfolioId++;

        IPollen(ds.pollenToken).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        emit PortfolioCreated(msg.sender, ps.portfolioId - 1, _amount);
    }

    /// @notice allows user to close a portfolio
    /// @param portfolioId of the portfolio to close
    function closePortfolio(address, uint256 portfolioId) external {
        PortfolioStorage storage ps = getPortfolioStorage();
        DAOStorage storage ds = getPollenDAOStorage();

        Portfolio storage p = ps.portfolios[msg.sender][portfolioId];

        require(p.open, "Portfolio: portfolio is closed or non-existent");

        (uint256 r, bool isPositive) = getReturns(portfolioId);
        uint256 portfolioReturns;
        uint256 closingValue = p.initialValue;

        if (isPositive && r != 0) {
            // if returns are positive, mint Pollen rewards to portfolio owner and delegators
            portfolioReturns = (r * p.initialValue) / (10**18);
            IPollen(ds.pollenToken).mint(msg.sender, portfolioReturns);
            IPollen(ds.pollenToken).transfer(msg.sender, p.initialValue);
            closingValue += portfolioReturns;
        } else if (!isPositive && r != 0) {
            // if returns are negative, burn Pollen allocated
            portfolioReturns = (r * p.initialValue) / (10**18);
            IPollen(ds.pollenToken).burn(portfolioReturns);
            IPollen(ds.pollenToken).transfer(
                msg.sender,
                p.initialValue - portfolioReturns
            );
            closingValue -= portfolioReturns;
        }

        p.open = false;

        emit PortfolioClosed(
            msg.sender,
            portfolioId,
            portfolioReturns,
            closingValue
        );
    }

    /// @notice allows user to rebalance a portfolio
    /// @dev How the _newAmount argument works
    ///      Consider that the user has 100 PLN allocated and wants to rebalance
    ///      If they want to add 10 PLN, _newAmount must be 110
    ///      If they want to remve 10 PLN, _newAmount must be 90
    /// @param _portfolioId of the portfolio to rebalance
    /// @param _newAmount the new PLN amount the user wants to allocate
    /// @param _newWeights array of relative weights of portfolio assets
    function rebalancePortfolio(
        address,
        uint256 _portfolioId,
        uint256 _newAmount,
        uint8[] calldata _newWeights
    ) external {
        PortfolioStorage storage ps = getPortfolioStorage();
        DAOStorage storage ds = getPollenDAOStorage();
        Portfolio storage p = ps.portfolios[msg.sender][_portfolioId];

        require(_newAmount > 0, "Portfolio: new amount cannot be 0");
        require(
            _newWeights.length == ps.assets.elements.length,
            "Portfolio: weights array has to equal asset set size"
        );
        require(isValidWeights(_newWeights));
        require(p.open, "Portfolio: portfolio is closed or non-existent");

        // Close portfolio
        (uint256 r, bool isPositive) = getReturns(_portfolioId);
        uint256 portfolioReturns;
        uint256 closingValue = p.initialValue;

        if (isPositive && r != 0) {
            // if returns are positive, mint Pollen returns to portfolio owner and delegators
            portfolioReturns = (r * p.initialValue) / (10**18);
            IPollen(ds.pollenToken).mint(msg.sender, portfolioReturns);
            IPollen(ds.pollenToken).transfer(msg.sender, p.initialValue);
            closingValue += portfolioReturns;
        } else if (!isPositive && r != 0) {
            // if returns are negative, burn Pollen allocated
            portfolioReturns = (r * p.initialValue) / (10**18);
            IPollen(ds.pollenToken).burn(portfolioReturns);
            IPollen(ds.pollenToken).transfer(
                msg.sender,
                p.initialValue - portfolioReturns
            );
            closingValue -= portfolioReturns;
        }

        // Reopen portfolio
        uint256[] memory assetAmounts = getPortfolioAmounts(_newWeights);

        Portfolio memory portfolio = Portfolio({
            assetAmounts: assetAmounts,
            weights: _newWeights,
            initialValue: _newAmount,
            open: true
        });

        ps.portfolios[msg.sender][_portfolioId] = portfolio;

        IPollen(ds.pollenToken).transferFrom(
            msg.sender,
            address(this),
            _newAmount
        );

        emit PortfolioRebalanced(
            msg.sender,
            _portfolioId,
            _newAmount,
            portfolioReturns,
            closingValue
        );
    }

    /*************
    VIEW FUNCTIONS
    *************/

    /// @return returns the entire set of whitelisted assets
    function getAssets(address) external view returns (address[] memory) {
        PortfolioStorage storage ps = getPortfolioStorage();

        address[] memory assets = new address[](ps.assets.numWhitelistedAssets);

        for (uint256 i = 0; i < ps.assets.numWhitelistedAssets; i++) {
            if (ps.assets.isWhitelisted[ps.assets.elements[i]])
                assets[i] = ps.assets.elements[i];
        }
        return assets;
    }

    /// @notice returns all non-zero balances of assets in the portfolio
    /// @return balances - a tuple of the asset address and the balance of that asset in the portfolio
    function getAssetBalances(address)
        external
        view
        returns (AssetBalance[] memory)
    {
        PortfolioStorage storage ps = getPortfolioStorage();

        address[] memory _portfolioAssets = ps.assets.elements;
        uint256 _balance;

        // number of assets in the portfolio that has a non-zero balance
        uint256 numAssetsWithBalance;

        for (uint256 i = 0; i < _portfolioAssets.length; i++) {
            if (IPollen(_portfolioAssets[i]).balanceOf(address(this)) > 0)
                numAssetsWithBalance++;
        }

        // create memory array whose size is the number of assets with a balance
        AssetBalance[] memory balances = new AssetBalance[](
            numAssetsWithBalance
        );
        // counter
        uint256 j;

        // populate non-zero balances array to return
        for (uint256 i = 0; i < _portfolioAssets.length; i++) {
            _balance = IPollen(_portfolioAssets[i]).balanceOf(address(this));
            if (_balance > 0) {
                AssetBalance memory assetBalance = AssetBalance({
                    asset: _portfolioAssets[i],
                    balance: _balance
                });
                balances[j] = assetBalance;
                j++;
            }
        }
        return balances;
    }

    /// @param owner address of portfolio creator
    /// @param portfolioId to query
    /// @return returns the portfolio weightings for a given `portfolioId`
    function getPortfolio(
        address,
        address owner,
        uint256 portfolioId
    ) external view returns (Portfolio memory) {
        PortfolioStorage storage ps = getPortfolioStorage();

        return ps.portfolios[owner][portfolioId];
    }

    /****************
    PRIVATE FUNCTIONS
    ****************/

    /// @notice gets portfolio value
    /// @param weights array of relative weights of portfolio assets
    function getPortfolioAmounts(uint8[] memory weights)
        private
        view
        returns (uint256[] memory)
    {
        DAOStorage storage ds = getPollenDAOStorage();
        PortfolioStorage storage ps = getPortfolioStorage();

        uint256[] memory assetAmounts = new uint256[](weights.length);
        Quoter quoter = Quoter(address(this));
        for (uint256 i = 0; i < ps.assets.elements.length; i++) {
            if (!ps.assets.isWhitelisted[ps.assets.elements[i]]) continue;
            (uint256 price, ) = quoter.quotePrice(
                ds.moduleByName["QUOTER"],
                RateBase.Usd,
                ps.assets.elements[i]
            );
            assetAmounts[i] = (uint256(weights[i]) * (10**36)) / (price); // 10**36 maked this value to support 18 decimal points
        }
        return assetAmounts;
    }

    /// @notice gets portfolio value
    /// @param portfolioId array of asset amounts
    /// @return r - gains or losses
    /// @return isPositive - whether or not the portfolio madea profit
    function getReturns(uint256 portfolioId)
        private
        view
        returns (uint256 r, bool isPositive)
    {
        DAOStorage storage ds = getPollenDAOStorage();
        PortfolioStorage storage ps = getPortfolioStorage();
        Portfolio memory p = ps.portfolios[msg.sender][portfolioId];

        uint256 currentValue;
        Quoter quoter = Quoter(address(this));
        for (uint256 i = 0; i < ps.assets.elements.length; i++) {
            if (!ps.assets.isWhitelisted[ps.assets.elements[i]]) continue;
            (uint256 price, ) = quoter.quotePrice(
                ds.moduleByName["QUOTER"],
                RateBase.Usd,
                ps.assets.elements[i]
            );
            currentValue += ((price * p.assetAmounts[i]) / 10**18); // the results is 18 dec points and price is 18 decimal points
        }

        currentValue = currentValue / 100; // weights are in %
        if (currentValue > 10**18) {
            r = currentValue - 10**18; // see math modeling.  Return reduces to this expression
            isPositive = true;
        } else {
            r = 10**18 - currentValue; // see math modeling.  Return reduces to this expression
            isPositive = false;
        }
        return (r, isPositive);
    }

    function isValidWeights(uint8[] memory weights)
        private
        view
        returns (bool)
    {
        PortfolioStorage storage ps = getPortfolioStorage();

        uint256 total;

        for (uint256 i = 0; i < weights.length; i++) {
            if (
                !ps.assets.isWhitelisted[ps.assets.elements[i]] &&
                weights[i] != 0
            ) {
                revert("Portfolio: weight must be 0 for a delisted asset");
            }
            total += weights[i];
        }

        require(total == 100, "Portfolio: asset weights has to add up to 100");

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

/// @title Portfolio
/// @notice Portfolio module for Pollen DAO
/// @dev Contains asset management logic

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPollen is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/// @title PortfolioStorage
/// @notice Storage contract for Portfolio module
/// @dev Defines data types and storage for asset management

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../lib/PortfolioAssetSet.sol";

contract PortfolioModuleStorage {
    bytes32 private constant PORTFOLIO_STORAGE_SLOT =
        keccak256("PollenDAO.portfolio.storage");

    struct AssetBalance {
        address asset;
        uint256 balance;
    }

    struct Portfolio {
        uint256[] assetAmounts;
        uint8[] weights;
        uint256 initialValue;
        bool open;
    }

    struct PortfolioStorage {
        // The set of assets that the DAO can hold
        PortfolioAssetSet.AssetSet assets;
        // portfolioIds
        uint256 portfolioId;
        // mapping owners to portfolioIds to portfolio data
        mapping(address => mapping(uint256 => Portfolio)) portfolios;
    }

    /* solhint-disable no-inline-assembly */
    function getPortfolioStorage()
        internal
        pure
        returns (PortfolioStorage storage ps)
    {
        bytes32 slot = PORTFOLIO_STORAGE_SLOT;
        assembly {
            ps.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
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

pragma solidity 0.8.4;

/// @title PortfolioAssetSet Library
/// @notice Library for representing a set of addresses whitelisted for PollenDAO
library PortfolioAssetSet {
    /// @notice Type for representing a set of addresses
    /// @member elements The elements of the set, contains address 0x0 for deleted elements
    /// @member indexes A mapping of the address to the index in the set, counted from 1 (rather than 0)
    struct AssetSet {
        address[] elements;
        mapping(address => bool) exists;
        mapping(address => bool) isWhitelisted;
        uint256 numWhitelistedAssets;
    }

    /// @notice Add an element to the set (internal)
    /// @param self The set
    /// @param value The element to add
    /// @return False if the element is already in the set or is address 0x0
    function add(AssetSet storage self, address value) internal returns (bool) {
        if (self.isWhitelisted[value]) return false;

        if (!self.exists[value]) {
            self.elements.push(value);
            self.exists[value] = true;
            self.isWhitelisted[value] = true;
        } else {
            self.isWhitelisted[value] = true;
        }

        self.numWhitelistedAssets++;
        return true;
    }

    /// @notice Remove an element from the set (internal)
    /// @param self The set
    /// @param value The element to remove
    /// @return False if the element is not in the set
    function remove(AssetSet storage self, address value)
        internal
        returns (bool)
    {
        if (!self.exists[value] || !self.isWhitelisted[value]) return false;

        self.isWhitelisted[value] = false;

        self.numWhitelistedAssets--;
        return true;
    }

    /// @notice Returns true if an element is in the set (internal view)
    /// @param self The set
    /// @param value The element
    /// @return True if the element is in the set
    function contains(AssetSet storage self, address value)
        internal
        view
        returns (bool)
    {
        return self.exists[value] && self.isWhitelisted[value];
    }
}

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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