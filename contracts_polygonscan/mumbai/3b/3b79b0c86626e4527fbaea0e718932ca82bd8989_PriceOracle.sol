/**
 *Submitted for verification at polygonscan.com on 2021-10-25
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
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
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

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

interface IPriceOracle {
    function getSettlementPrice(
        address underlyingToken,
        address priceToken,
        uint256 settlementDate
    ) external view returns (bool, uint256);

    function getCurrentPrice(address underlyingToken, address priceToken)
        external
        view
        returns (uint256);

    function setSettlementPrice(address underlyingToken, address priceToken)
        external;

    function setSettlementPriceForDate(
        address underlyingToken,
        address priceToken,
        uint256 date
    ) external;

    function get8amWeeklyOrDailyAligned(uint256 _timestamp)
        external
        view
        returns (uint256);
}

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT =
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    event CodeAddressUpdated(address newAddress);

    function _updateCodeAddress(address newAddress) internal {
        require(
            bytes32(PROXY_MEM_SLOT) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(PROXY_MEM_SLOT, newAddress)
        }

        emit CodeAddressUpdated(newAddress);
    }

    function getLogicAddress() public view returns (address logicAddress) {
        assembly {
            // solium-disable-line
            logicAddress := sload(PROXY_MEM_SLOT)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return bytes32(PROXY_MEM_SLOT);
    }
}

/// @title PriceOracle
/// @notice Uses a collection of sub price oracles to fetch settlement price and current price data for the SeriesController
/// @notice The price data is for a given underlying-price token pair and Series expiration date
/// @dev An important assumption of the PriceOracle is that settlement dates are aligned to 8am UTC, and separated either by
/// 1 day or 1 week. The value of the dateOffset state variable determines whether the interval between settlement dates
/// is 1 day or 1 week. We do this because we do not want to fragment liquidity and complicate the UX by
/// allowing for arbitrary settlement dates, so we enforce a specific interval between all Series' settlement dates
/// @dev All prices are normalized to 8 decimal places
contract PriceOracle is IPriceOracle, OwnableUpgradeable, Proxiable {
    /// @dev Stores the price for a given <underlyingToken>-<priceToken>-<settlementDate> triplet
    /// @dev All prices are normalized to 8 decimals
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        internal settlementPrices;

    /// @dev Stores the oracle address to use when looking for the price of a given token
    /// @dev oracles are keyed by the pair of underlyingToken-priceToken, so for a BTCUSD oracle
    /// returning a price of $14_000, the pair would be the addresses corresponding to WBTC and USDC
    mapping(address => mapping(address => address)) internal oracles;

    /// @dev the time length in seconds between successive settlement dates. Must
    /// be either 1 day or 1 week
    uint256 internal dateOffset;

    event SettlementPriceSet(
        address underlyingToken,
        address priceToken,
        uint256 settlementDate,
        uint256 price
    );

    event OracleSet(
        address underlyingToken,
        address priceToken,
        address oracle,
        uint256 earliestSettlementDate
    );

    /// @notice Setup the owner and date time and range for this PriceOracle
    /// @param _dateOffset the time length in seconds between successive settlement dates. MUST
    /// be either 1 day or 1 week. On mainnet networks we always use 1 week, but for testnets in order
    /// to have faster testing iterations we reduce the interval to 1 day
    function initialize(uint256 _dateOffset) external {
        require(
            _dateOffset == 1 days || _dateOffset == 1 weeks,
            "PriceOracle: _dateOffset must align to 1 day or 1 week"
        );

        __Ownable_init();
        dateOffset = _dateOffset;
    }

    /// @notice Stores the current price from the oracle specified by the pair underlyingToken-priceToken
    /// @param underlyingToken Should be equal to the Series' underlyingToken field
    /// @param priceToken Should be equal to the Series' priceToken field
    /// @dev More than a single settlement price may be set, because this function will set all prices for each
    /// prior date until it reaches a settlement date that previously had a price set, or it runs
    /// out of gas
    /// @dev This function should be called each dateOffset as soon as the block.timestamp passes 8am UTC, so that
    /// the current spot price we set is as close to the price at 8am UTC. If we this is called at 8:30am,
    /// for instance, and the 8am UTC price hasn't been set yet, then we're going to set a price that is 30
    /// minutes later than intended. This will be more impactful the more volatile prices are.
    function setSettlementPrice(address underlyingToken, address priceToken)
        external
        override
    {
        require(
            oracles[underlyingToken][priceToken] != address(0x0),
            "no oracle address for this token pair"
        );

        // fetch the current spot price for this pair's oracle, and set all previous
        // settlement dates that have not yet had their price set to that spot price
        uint256 spotPrice = getCurrentPrice(underlyingToken, priceToken);
        uint256 priorAligned8am = get8amWeeklyOrDailyAligned(block.timestamp);
        uint256 currentSettlementPrice = settlementPrices[underlyingToken][
            priceToken
        ][priorAligned8am];

        // keep going back 1 dateOffset until we reach a settlement date that has already been set by a previous
        // call to PriceOracle.setSettlementPrice
        while (currentSettlementPrice == 0) {
            settlementPrices[underlyingToken][priceToken][
                priorAligned8am
            ] = spotPrice;

            emit SettlementPriceSet(
                underlyingToken,
                priceToken,
                priorAligned8am,
                spotPrice
            );

            // go back exactly 1 dateOffset's worth of time to the previous 8am UTC date
            priorAligned8am -= dateOffset;

            // update the currentSettlementPrice so the while loop will eventually break
            currentSettlementPrice = settlementPrices[underlyingToken][
                priceToken
            ][priorAligned8am];
        }
    }

    /// @notice get the settlement price with the given underlyingToken and priceToken,
    /// at the given expirationDate, and whether the price exists
    /// @param underlyingToken Should be equal to the Series' underlyingToken field
    /// @param priceToken Should be equal to the Series' priceToken field
    /// @param settlementDate Should be equal to the expirationDate of the Series we're getting the settlement price for
    /// @return true if the settlement price has been set (i.e. is nonzero), false otherwise
    /// @return the settlement price
    function getSettlementPrice(
        address underlyingToken,
        address priceToken,
        uint256 settlementDate
    ) external view override returns (bool, uint256) {
        require(
            oracles[underlyingToken][priceToken] != address(0x0),
            "no oracle address for this token pair"
        );

        uint256 settlementPrice = settlementPrices[underlyingToken][priceToken][
            settlementDate
        ];

        return (settlementPrice != 0, settlementPrice);
    }

    /// @notice Stores the current price from the oracle specified by the pair underlyingToken-priceToken for the
    /// given settlement date
    /// @param underlyingToken Should be equal to the Markets' underlyingToken field
    /// @param priceToken Should be equal to the Markets' priceToken field
    /// @dev This function exists only to prevent scenarios where the while loop in PriceOracle.setSettlementPrice
    /// consumes too much gas and fails with an Out Of Gas error. Since this function only sets a single date, it
    /// is in no danger of running out of gas
    /// @param date A date aligned to 8am UTC and offset by dateOffset which the settlement price should be set on
    /// @dev This function call will fail if the date is not aligned to 8am UTC, and will be a no-op if a
    /// price at the given date has already been set
    function setSettlementPriceForDate(
        address underlyingToken,
        address priceToken,
        uint256 date
    ) external override {
        require(
            oracles[underlyingToken][priceToken] != address(0x0),
            "no oracle address for this token pair"
        );

        // the given date must be aligned to 8am UTC and the correct offset, otherwise we will end up
        // setting a price on a un-aligned date
        require(
            date == get8amWeeklyOrDailyAligned(date),
            "date is not aligned"
        );

        // the settlement date must be in the past, otherwise any address will be able to set future settlement prices,
        // which we cannot allow
        require(date < block.timestamp, "date must be in the past");

        // we cannot allow gaps in the settlement date prices, otherwise PriceOracle.setSettlementDate will not be
        // able to set the gap settlement price. For example, if time T were to have a price set, T + offset
        // did not, and T + (2 * offset) _did_ have the price set, then PriceOracle.setSettlementDate would never be
        // able to set the price for the T + offset date. In order to prevent this we check to see if the prior
        // dateOffset-aligned date's price has been set, which by induction proves there are no gaps
        require(
            settlementPrices[underlyingToken][priceToken][date - dateOffset] !=
                0,
            "must use the earliest date without a price set"
        );

        // we do not want to overwrite a settlement date that has already had its price set, so we end execution
        // early if we find that to be true
        if (settlementPrices[underlyingToken][priceToken][date] != 0) {
            return;
        }

        // fetch the current spot price for this pair's oracle, and set it as the price for the given date
        uint256 spotPrice = getCurrentPrice(underlyingToken, priceToken);
        settlementPrices[underlyingToken][priceToken][date] = spotPrice;

        emit SettlementPriceSet(underlyingToken, priceToken, date, spotPrice);
    }

    /// @notice Use an oracle keyed by the underlyingToken-priceToken pair to fetch the current price
    /// @param underlyingToken Should be equal to the Series' underlyingToken field
    /// @param priceToken Should be equal to the Series' priceToken field
    function getCurrentPrice(address underlyingToken, address priceToken)
        public
        view
        override
        returns (uint256)
    {
        require(
            oracles[underlyingToken][priceToken] != address(0x0),
            "no oracle address for this token pair"
        );

        (, int256 latestAnswer, , , ) = AggregatorV3Interface(
            oracles[underlyingToken][priceToken]
        ).latestRoundData();
        require(latestAnswer >= 0, "invalid value received from price oracle");

        return uint256(latestAnswer);
    }

    /// @notice Sets the price oracle to use for the given underlyingToken and priceToken pair
    /// @param underlyingToken Should be equal to the Series' underlyingToken field
    /// @param priceToken Should be equal to the Series' priceToken field
    /// @param oracle The address of the price oracle contract
    function addTokenPair(
        address underlyingToken,
        address priceToken,
        address oracle
    ) external onlyOwner {
        require(
            oracles[underlyingToken][priceToken] == address(0x0),
            "PriceOracle: cannot set address for an existing oracle"
        );

        // set the pair's oracle on the PriceOracle
        oracles[underlyingToken][priceToken] = oracle;

        // Get the price and ensure it is valid
        uint256 currentPrice = getCurrentPrice(underlyingToken, priceToken);
        require(
            currentPrice > 0,
            "price oracle must start with a valid price feed"
        );

        // We need to initially set the price on some offset-aligned date prior to the current date, so that
        // in the loop in PriceOracle.setSettlementDate it will eventually stop looping when it finds a
        // non-zero price. If we do not add set this price, then the first call to PriceOracle.setSettlementDate the first
        // is guaranteed to run out of gas because there will never be a non-zero price value. We choose the most recent
        // aligned date because it will result in the least gas used by PriceOracle.setSettlementDate
        uint256 earliestSettlementDate = get8amWeeklyOrDailyAligned(
            block.timestamp
        );
        settlementPrices[underlyingToken][priceToken][
            earliestSettlementDate
        ] = currentPrice;

        emit OracleSet(
            underlyingToken,
            priceToken,
            oracle,
            earliestSettlementDate
        );
    }

    /// @notice update the PriceOracle's logic contract
    /// @param newPriceOracleImpl the address of the new price oracle implementation contract
    function updateImplementation(address newPriceOracleImpl)
        external
        onlyOwner
    {
        require(
            newPriceOracleImpl != address(0x0),
            "PriceOracle: Invalid newPriceOracleImpl"
        );

        // Call the proxiable update
        _updateCodeAddress(newPriceOracleImpl);
    }

    /// @notice Returns the given timestamp date, but aligned to the prior 8am UTC dateOffset in the past
    /// unless the timestamp is exactly 8am UTC, in which case it will return the same
    /// value as the timestamp. If PriceOracle.dateOffset is 1 day then this function
    /// will align on every day at 8am, and if its 1 week it will align on every Friday 8am UTC
    /// @param _timestamp a block time (seconds past epoch)
    /// @return the block time of the prior (or current) 8am UTC date, dateOffset in the past
    function get8amWeeklyOrDailyAligned(uint256 _timestamp)
        public
        view
        override
        returns (uint256)
    {
        uint256 numOffsetsSinceEpochStart = _timestamp / dateOffset;

        // this will get us the timestamp of the Thursday midnight date prior to _timestamp if
        // dateOffset equals 1 week, or it will get us the timestamp of midnight of the previous
        // day if dateOffset equals 1 day. We rely on Solidity's integral rounding in the line above
        uint256 timestampRoundedDown = numOffsetsSinceEpochStart * dateOffset;

        if (dateOffset == 1 days) {
            uint256 eightHoursAligned = timestampRoundedDown + 8 hours;
            if (eightHoursAligned > _timestamp) {
                return eightHoursAligned - 1 days;
            } else {
                return eightHoursAligned;
            }
        } else {
            uint256 fridayEightHoursAligned = timestampRoundedDown +
                (1 days + 8 hours);
            if (fridayEightHoursAligned > _timestamp) {
                return fridayEightHoursAligned - 1 weeks;
            } else {
                return fridayEightHoursAligned;
            }
        }
    }
}