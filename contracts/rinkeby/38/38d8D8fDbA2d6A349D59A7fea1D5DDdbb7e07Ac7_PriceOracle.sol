// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./IPriceOracle.sol";
import "../proxy/Proxiable.sol";

/// @title PriceOracle
/// @notice Uses a collection of sub price oracles to fetch settlement price and current price data for the SeriesController
/// @notice The price data is for a given underlying-price token pair and Series expiration date
/// @dev An important assumption of the PriceOracle is that settlement dates are aligned to 8am UTC.
/// We assume this because we do not want to fragment liquidity and complicate the UX by allowing for arbitrary settlement dates
/// so we enforce this when adding new oracle token pairs by aligning the initial earliest settlement date to 8am UTC, and
/// then aligning all subsequent settlement prices for that oracle token pair to an exact 7 day offset
/// Series whose expirations are 8am UTC as well
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
    function initialize() external {
        __Ownable_init();
    }

    /// @notice Stores the current price from the oracle specified by the pair underlyingToken-priceToken
    /// @param underlyingToken Should be equal to the Series' underlyingToken field
    /// @param priceToken Should be equal to the Series' priceToken field
    /// @dev More than a single settlement price may be set, because this function will set all prices for each
    /// prior 8am UTC date until it reaches a settlement date that previously had a price set, or it runs
    /// out of gas
    /// @dev WARNING: setSettlementDate must be called frequently enough that the gap in settlement date
    /// prices does not grow so great that it takes more than the gasLimit's amount of gas to set them all
    /// that haven't had a price set on them prior to the current block timestamp
    function setSettlementPrice(address underlyingToken, address priceToken)
        external
        override
    {
        require(
            oracles[underlyingToken][priceToken] != address(0x0),
            "no oracle address for this token pair"
        );

        // fetch the current spot price for this pair's oracle, and set all previous 8am UTC
        // settlement dates that have not yet had their price set to that spot price
        uint256 spotPrice = getCurrentPrice(underlyingToken, priceToken);
        uint256 prior8am = get8amAlignedDate(block.timestamp);
        uint256 currentSettlementPrice =
            settlementPrices[underlyingToken][priceToken][prior8am];

        // keep going back 1 day until we reach a settlement date that has already been set by a previous
        // call to PriceOracle.setSettlementPrice
        while (currentSettlementPrice == 0) {
            settlementPrices[underlyingToken][priceToken][prior8am] = spotPrice;

            emit SettlementPriceSet(
                underlyingToken,
                priceToken,
                prior8am,
                spotPrice
            );

            // go back exactly 1 day's worth of time to the previous 8am UTC date
            prior8am -= 1 days;

            // update the currentSettlementPrice so the while loop will eventually break
            currentSettlementPrice = settlementPrices[underlyingToken][
                priceToken
            ][prior8am];
        }
    }

    /// @notice get the settlement price with the given underlyingToken and priceToken,
    /// at the given expirationDate, and whether the price exists
    /// @param underlyingToken Should be equal to the Series' underlyingToken field
    /// @param priceToken Should be equal to the Series' priceToken field
    /// @param settlementDate Should be equal to the expirationDate of the series calling this function
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

        uint256 settlementPrice =
            settlementPrices[underlyingToken][priceToken][settlementDate];

        return (settlementPrice != 0, settlementPrice);
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
        (, int256 latestAnswer, , , ) =
            AggregatorV3Interface(oracles[underlyingToken][priceToken])
                .latestRoundData();
        require(latestAnswer >= 0, "invalid value received from price oracle");

        return uint256(latestAnswer);
    }

    /// @notice Sets the price oracle to use for the given underlyingToken and priceToken pair
    /// @dev earliestSettlementDate should be the next Series settlementDate the PriceOracle
    /// sets in PriceOracle.setSettlementSet. To ensure that, the previous 8am UTC
    /// to earliestSettlementDate will be set with a nonzero value, so that PriceOracle.setSettlementPrice
    /// will set all subsequent dates (including earliestSettlementDate) when it is called
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

        uint256 currentPrice = getCurrentPrice(underlyingToken, priceToken);
        // We need to initially set the price on some offset-aligned date prior to the current date, so that
        // in the loop in PriceOracle.setSettlementDate it will eventually stop looping when it finds a
        // non-zero price. If we do not add set this price, then the first call to PriceOracle.setSettlementDate the first
        // is guaranteed to run out of gas because there will never be a non-zero price value. We choose the most recent
        // aligned date because it will result in the least gas used by PriceOracle.setSettlementDate
        uint256 earliestSettlementDate = get8amAlignedDate(block.timestamp);
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

    /// @notice Returns the given timestamp date, but aligned to the prior  8am UTC date
    /// unless the timestamp is exactly 8am UTC, in which case it will return the same
    /// value as the timestamp
    /// @param _timestamp a block time (seconds past epoch)
    /// @return the block time of the prior (or current) 8am UTC date
    function get8amAlignedDate(uint256 _timestamp)
        public
        pure
        override
        returns (uint256)
    {
        uint256 numOffsetsSinceEpochStart = _timestamp / 1 days;

        // this will get us the timestamp of the Thursday midnight date prior to _timestamp
        // (we rely on Solidity rounding in the line above)
        uint256 timestampRoundedDown = numOffsetsSinceEpochStart * 1 days;

        uint256 eightHoursAligned = timestampRoundedDown + 8 hours;
        if (eightHoursAligned > _timestamp) {
            return eightHoursAligned - 1 days;
        } else {
            return eightHoursAligned;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

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

    function get8amAlignedDate(uint256 _timestamp)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}