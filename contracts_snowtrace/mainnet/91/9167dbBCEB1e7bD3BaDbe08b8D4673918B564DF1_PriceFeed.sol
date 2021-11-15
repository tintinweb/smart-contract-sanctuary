/**
 *Submitted for verification at snowtrace.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;


// File: contracts/Interfaces/IPriceFeed.sol



interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
   
    // --- Function ---
    function fetchPrice() external returns (uint);
}

// File: contracts/Dependencies/AggregatorV3Interface.sol


// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol



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

// File: contracts/Dependencies/IBand.sol




interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
    external
    view
    returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
    external
    view
    returns (ReferenceData[] memory);
}

// File: contracts/Dependencies/SafeMath.sol





/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Dependencies/BaseMath.sol





contract BaseMath {
    uint constant public DECIMAL_PRECISION = 1e18;
}

// File: contracts/Dependencies/LiquityMath.sol






library LiquityMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division. 
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * -round product up if 19'th mantissa digit >= 5
    * -round product down if 19'th mantissa digit < 5
    *
    * Used only inside the exponentiation, _decPow().
    */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }

    /* 
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    * 
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. 
    * 
    * Called by two functions that represent time in units of minutes:
    * 1) TroveManager._calcDecayedBaseRate
    * 2) CommunityIssuance._getCumulativeIssuanceFraction 
    * 
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    * 
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since: 
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(_price).div(_debt);

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol



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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol



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

// File: contracts/protocol/PriceFeed.sol









/*
* PriceFeed for mainnet deployment, to be connected to Chainlink's live ETH:USD aggregator reference 
* contract, and a wrapper contract TellorCaller, which connects to TellorMaster contract.
*
* The PriceFeed uses Chainlink as primary oracle, and Tellor as fallback. It contains logic for
* switching oracles based on oracle failures, timeouts, and conditions for returning to the primary
* Chainlink oracle.
*/
contract PriceFeed is OwnableUpgradeable, BaseMath, IPriceFeed {
    using SafeMath for uint256;

    string constant public NAME = "PriceFeed";

    AggregatorV3Interface public priceAggregator;  // Mainnet Chainlink aggregator
    IStdReference public bandCaller; // Mainnet band caller
    string public collTokenName;


    // uint constant public ETHUSD_TELLOR_REQ_ID = 1;

    // Use to convert a price answer to an 18-digit precision uint
    uint constant public TARGET_DIGITS = 18;

    // Maximum time period allowed since Chainlink's latest round data timestamp, beyond which Chainlink is considered frozen.
    uint constant public TIMEOUT = 14400;  // 4 hours: 60 * 60 * 4

    // Maximum deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
    uint constant public MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 5e17; // 50%

    /*
    * The maximum relative price difference between two oracle responses allowed in order for the PriceFeed
    * to return to using the Chainlink oracle. 18-digit precision.
    */
    uint constant public MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES = 5e16; // 5%

    // The last good price seen from an oracle by Liquity
    uint public lastGoodPrice;

    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    enum Status {
        chainlinkWorking,
        //        usingTellorChainlinkUntrusted,
        usingBandChainlinkUntrusted,
        bothOraclesUntrusted,
        //        usingTellorChainlinkFrozen,
        usingBandChainlinkFrozen,
        //        usingChainlinkTellorUntrusted
        usingChainlinkBandUntrusted        
    }

    // --- Events ---
    event PriceFeedStatusChanged(Status newStatus);

    // The current status of the PricFeed, which determines the conditions for the next price fetch attempt
    Status public status;

    // --- Dependency setters ---
    
    function setAddresses(
        address _priceAggregatorAddress,
        address _bandCallerAddress,
        string memory _collTokenName
    )
    external
    initializer
    {                
        _addAddresses(_priceAggregatorAddress, _bandCallerAddress, _collTokenName);
        
        if (address(priceAggregator) == address(0) || address(bandCaller) == address(0)) {
            __Ownable_init();
        }  
    }

    function addAddresses(
        address _priceAggregatorAddress,
        address _bandCallerAddress,
        string memory _collTokenName
    ) 
    external 
    onlyOwner 
    {
        _addAddresses(_priceAggregatorAddress, _bandCallerAddress, _collTokenName);

        if (address(priceAggregator) != address(0) && address(bandCaller) != address(0)) {
            renounceOwnership();
        } 
    }
    
    function _addAddresses(
        address _priceAggregatorAddress,
        address _bandCallerAddress,
        string memory _collTokenName
    ) 
    internal 
    {                  
        if (_priceAggregatorAddress != address(0)) {
            priceAggregator = AggregatorV3Interface(_priceAggregatorAddress);
            
            // // Get an initial price from Chainlink to serve as first reference for lastGoodPrice
            ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse();
            ChainlinkResponse memory prevChainlinkResponse = _getPrevChainlinkResponse(chainlinkResponse.roundId, chainlinkResponse.decimals);
            require(!_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse) && !_chainlinkIsFrozen(chainlinkResponse),
                "PriceFeed: Chainlink must be working and current");

            status = Status.chainlinkWorking;

            // Explicitly set initial system status            
            _storeChainlinkPrice(chainlinkResponse);

        }

        if (_bandCallerAddress != address(0)) {
            collTokenName = _collTokenName;
            
            bandCaller = IStdReference(_bandCallerAddress);

            IStdReference.ReferenceData memory bandResponse = _getCurrentBandResponse();
            require(!_bandIsBroken(bandResponse) && !_bandIsFrozen(bandResponse),
                "PriceFeed: Band must be working and current");
            
            if (address(priceAggregator) == address(0)) {
                status = Status.usingBandChainlinkUntrusted;
            }

            _storeBandPrice(bandResponse.rate);
        }
    }

    // --- Functions ---

    /*
    * fetchPrice():
    * Returns the latest price obtained from the Oracle. Called by Liquity functions that require a current price.
    *
    * Also callable by anyone externally.
    *
    * Non-view function - it stores the last good price seen by Liquity.
    *
    * Uses a main oracle (Chainlink) and a fallback oracle (Tellor) in case Chainlink fails. If both fail,
    * it uses the last good price seen by Liquity.
    *
    */
    function fetchPrice() external override returns (uint) {
        // Get current and previous price data from Chainlink, and current price data from Tellor
        ChainlinkResponse memory chainlinkResponse;
        ChainlinkResponse memory prevChainlinkResponse;
        IStdReference.ReferenceData memory bandResponse;
        
        if(address(priceAggregator) != address(0)) {
            chainlinkResponse = _getCurrentChainlinkResponse();
            prevChainlinkResponse = _getPrevChainlinkResponse(chainlinkResponse.roundId, chainlinkResponse.decimals);
        }

        if(address(bandCaller) != address(0)) {
            bandResponse = _getCurrentBandResponse();
        }
        

        // --- CASE 1: System fetched last price from Chainlink  ---
        if (status == Status.chainlinkWorking) {
            // If Chainlink is broken, try Band
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                
                if(_bandIsEmpty()) {
                    return lastGoodPrice;
                }
                
                // If Band is broken then both oracles are untrusted, so return the last good price
                if (_bandIsBroken(bandResponse)) {
                    _changeStatus(Status.bothOraclesUntrusted);
                    return lastGoodPrice;
                }
                /*
                * If Band is only frozen but otherwise returning valid data, return the last good price.
                * Band may need to be tipped to return current data.
                */
                if (_bandIsFrozen(bandResponse)) {
                    _changeStatus(Status.usingBandChainlinkUntrusted);
                    return lastGoodPrice;
                }

                // If Chainlink is broken and Band is working, switch to Band and return current Band price
                _changeStatus(Status.usingBandChainlinkUntrusted);
                return _storeBandPrice(bandResponse.rate);
            }

            // If Chainlink is frozen, try Band
            if (_chainlinkIsFrozen(chainlinkResponse)) {
                
                if(_bandIsEmpty()) {
                    return lastGoodPrice;
                }
                
                // If Band is broken too, remember Band broke, and return last good price
                if (_bandIsBroken(bandResponse)) {
                    _changeStatus(Status.usingChainlinkBandUntrusted);
                    return lastGoodPrice;
                }

                // If Band is frozen or working, remember Chainlink froze, and switch to Band
                _changeStatus(Status.usingBandChainlinkFrozen);

                if (_bandIsFrozen(bandResponse)) {return lastGoodPrice;}

                // If Band is working, use it
                return _storeBandPrice(bandResponse.rate);
            }

            // If Chainlink price has changed by > 50% between two consecutive rounds, compare it to Band's price
            if (_chainlinkPriceChangeAboveMax(chainlinkResponse, prevChainlinkResponse)) {
                if(_bandIsEmpty()) {
                    return lastGoodPrice;
                }
                
                // If Band is broken, both oracles are untrusted, and return last good price
                if (_bandIsBroken(bandResponse)) {
                    _changeStatus(Status.bothOraclesUntrusted);
                    return lastGoodPrice;
                }

                // If Band is frozen, switch to Band and return last good price
                if (_bandIsFrozen(bandResponse)) {
                    _changeStatus(Status.usingBandChainlinkUntrusted);
                    return lastGoodPrice;
                }

                /*
                * If Band is live and both oracles have a similar price, conclude that Chainlink's large price deviation between
                * two consecutive rounds was likely a legitmate market price movement, and so continue using Chainlink
                */
                if (_bothOraclesSimilarPrice(chainlinkResponse, bandResponse.rate)) {
                    return _storeChainlinkPrice(chainlinkResponse);
                }

                // If Band is live but the oracles differ too much in price, conclude that Chainlink's initial price deviation was
                // an oracle failure. Switch to Band, and use Band price
                _changeStatus(Status.usingBandChainlinkUntrusted);
                return _storeBandPrice(bandResponse.rate);
            }

            // If Chainlink is working and Band is broken, remember Band is broken
            if (!_bandIsEmpty() && _bandIsBroken(bandResponse)) {
                _changeStatus(Status.usingChainlinkBandUntrusted);
            }

            // If Chainlink is working, return Chainlink current price (no status change)
            return _storeChainlinkPrice(chainlinkResponse);
        }

        // --- CASE 2: The system fetched last price from Band ---
        if (status == Status.usingBandChainlinkUntrusted) {
            // If both Band and Chainlink are live, unbroken, and reporting similar prices, switch back to Chainlink
            if (_bothOraclesLiveAndUnbrokenAndSimilarPrice(chainlinkResponse, prevChainlinkResponse, bandResponse)) {
                _changeStatus(Status.chainlinkWorking);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            if (_bandIsBroken(bandResponse)) {
                
                if(_chainlinkIsEmpty()) {
                    return lastGoodPrice;
                }
                
                _changeStatus(Status.bothOraclesUntrusted);
                return lastGoodPrice;
            }

            /*
            * If Band is only frozen but otherwise returning valid data, just return the last good price.
            * Band may need to be tipped to return current data.
            */
            if (_bandIsFrozen(bandResponse)) {return lastGoodPrice;}

            // Otherwise, use Band price
            return _storeBandPrice(bandResponse.rate);
        }

        // --- CASE 3: Both oracles were untrusted at the last price fetch ---
        if (status == Status.bothOraclesUntrusted) {
            /*
            * If both oracles are now live, unbroken and similar price, we assume that they are reporting
            * accurately, and so we switch back to Chainlink.
            */
            if (_bothOraclesLiveAndUnbrokenAndSimilarPrice(chainlinkResponse, prevChainlinkResponse, bandResponse)) {
                _changeStatus(Status.chainlinkWorking);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            if (_chainlinkLive(chainlinkResponse, prevChainlinkResponse)) {
                _changeStatus(Status.chainlinkWorking);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            if (_bandLive(bandResponse)) {
                _changeStatus(Status.usingBandChainlinkUntrusted);
                return _storeBandPrice(bandResponse.rate);
            }

            // Otherwise, return the last good price - both oracles are still untrusted (no status change)
            return lastGoodPrice;
        }

        // --- CASE 4: Using Band, and Chainlink is frozen ---
        if (status == Status.usingBandChainlinkFrozen) {
            
            if(_chainlinkIsEmpty()) {
                if (_bandIsBroken(bandResponse)) {
                    return lastGoodPrice;
                }

                if (_bandIsFrozen(bandResponse)) {return lastGoodPrice;}
            }
            
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                // If both Oracles are broken, return last good price
                if (_bandIsBroken(bandResponse)) {
                    _changeStatus(Status.bothOraclesUntrusted);
                    return lastGoodPrice;
                }

                // If Chainlink is broken, remember it and switch to using Band
                _changeStatus(Status.usingBandChainlinkUntrusted);

                if (_bandIsFrozen(bandResponse)) {return lastGoodPrice;}

                // If Band is working, return Band current price
                return _storeBandPrice(bandResponse.rate);
            }

            if (_chainlinkIsFrozen(chainlinkResponse)) {
                // if Chainlink is frozen and Band is broken, remember Band broke, and return last good price
                if (_bandIsBroken(bandResponse)) {
                    _changeStatus(Status.usingChainlinkBandUntrusted);
                    return lastGoodPrice;
                }

                // If both are frozen, just use lastGoodPrice
                if (_bandIsFrozen(bandResponse)) {return lastGoodPrice;}

                // if Chainlink is frozen and Band is working, keep using Band (no status change)
                return _storeBandPrice(bandResponse.rate);
            }

            // if Chainlink is live and Band is broken, remember Band broke, and return Chainlink price
            if (_bandIsBroken(bandResponse)) {
                _changeStatus(Status.usingChainlinkBandUntrusted);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            // If Chainlink is live and Band is frozen, just use last good price (no status change) since we have no basis for comparison
            if (_bandIsFrozen(bandResponse)) {return lastGoodPrice;}

            // If Chainlink is live and Band is working, compare prices. Switch to Chainlink
            // if prices are within 5%, and return Chainlink price.
            if (_bothOraclesSimilarPrice(chainlinkResponse, bandResponse.rate)) {
                _changeStatus(Status.chainlinkWorking);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            // Otherwise if Chainlink is live but price not within 5% of Band, distrust Chainlink, and return Band price
            _changeStatus(Status.usingBandChainlinkUntrusted);
            return _storeBandPrice(bandResponse.rate);
        }

        // --- CASE 5: Using Chainlink, Band is untrusted ---
        if (status == Status.usingChainlinkBandUntrusted) {
            // If Chainlink breaks, now both oracles are untrusted
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                if(_bandIsEmpty()) {
                    return lastGoodPrice;
                }
                
                _changeStatus(Status.bothOraclesUntrusted);
                return lastGoodPrice;
            }

            // If Chainlink is frozen, return last good price (no status change)
            if (_chainlinkIsFrozen(chainlinkResponse)) {
                return lastGoodPrice;
            }

            // If Chainlink and Band are both live, unbroken and similar price, switch back to chainlinkWorking and return Chainlink price
            if (_bothOraclesLiveAndUnbrokenAndSimilarPrice(chainlinkResponse, prevChainlinkResponse, bandResponse)) {
                _changeStatus(Status.chainlinkWorking);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            // If Chainlink is live but deviated >50% from it's previous price and Band is still untrusted, switch
            // to bothOraclesUntrusted and return last good price
            if (_chainlinkPriceChangeAboveMax(chainlinkResponse, prevChainlinkResponse)) {
                
                if(_bandIsEmpty()) {
                    return lastGoodPrice;
                }
                
                _changeStatus(Status.bothOraclesUntrusted);
                return lastGoodPrice;
            }

            // Otherwise if Chainlink is live and deviated <50% from it's previous price and Band is still untrusted,
            // return Chainlink price (no status change)
            return _storeChainlinkPrice(chainlinkResponse);
        }
    }

    // --- Helper functions ---

    /* Chainlink is considered broken if its current or previous round data is in any way bad. We check the previous round
    * for two reasons:
    *
    * 1) It is necessary data for the price deviation check in case 1,
    * and
    * 2) Chainlink is the PriceFeed's preferred primary oracle - having two consecutive valid round responses adds
    * peace of mind when using or returning to Chainlink.
    */
    function _chainlinkIsBroken(ChainlinkResponse memory _currentResponse, ChainlinkResponse memory _prevResponse) internal view returns (bool) {
        return _badChainlinkResponse(_currentResponse) || _badChainlinkResponse(_prevResponse);
    }

    function _badChainlinkResponse(ChainlinkResponse memory _response) internal view returns (bool) {
        // Check for response call reverted
        if (!_response.success) {return true;}
        // Check for an invalid roundId that is 0
        if (_response.roundId == 0) {return true;}
        // Check for an invalid timeStamp that is 0, or in the future
        if (_response.timestamp == 0 || _response.timestamp > block.timestamp) {return true;}
        // Check for non-positive price
        if (_response.answer <= 0) {return true;}

        return false;
    }

    function _chainlinkIsFrozen(ChainlinkResponse memory _response) internal view returns (bool) {
        return block.timestamp.sub(_response.timestamp) > TIMEOUT;
    }

    function _chainlinkIsEmpty() internal view returns (bool) {
        return (address(priceAggregator) == address(0));
    }

    function _chainlinkPriceChangeAboveMax(ChainlinkResponse memory _currentResponse, ChainlinkResponse memory _prevResponse) internal pure returns (bool) {
        uint currentScaledPrice = _scaleChainlinkPriceByDigits(uint256(_currentResponse.answer), _currentResponse.decimals);
        uint prevScaledPrice = _scaleChainlinkPriceByDigits(uint256(_prevResponse.answer), _prevResponse.decimals);

        uint minPrice = LiquityMath._min(currentScaledPrice, prevScaledPrice);
        uint maxPrice = LiquityMath._max(currentScaledPrice, prevScaledPrice);

        /*
        * Use the larger price as the denominator:
        * - If price decreased, the percentage deviation is in relation to the the previous price.
        * - If price increased, the percentage deviation is in relation to the current price.
        */
        uint percentDeviation = maxPrice.sub(minPrice).mul(DECIMAL_PRECISION).div(maxPrice);

        // Return true if price has more than doubled, or more than halved.
        return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
    }

    function _bandIsBroken(IStdReference.ReferenceData memory _response) internal view returns (bool) {
        if (_response.lastUpdatedBase == 0 || _response.lastUpdatedBase > block.timestamp) {return true;}
        if (_response.lastUpdatedQuote == 0 || _response.lastUpdatedQuote > block.timestamp) {return true;}
        if (_response.rate == 0) {return true;}

        return false;
    }

    function _bandIsFrozen(IStdReference.ReferenceData memory _response) internal view returns (bool) {
        if (
            block.timestamp.sub(_response.lastUpdatedBase) > TIMEOUT || 
            block.timestamp.sub(_response.lastUpdatedQuote) > TIMEOUT
        ) 
        {
            return true;
        }

        return false;
    }

    function _bandIsEmpty() internal view returns (bool) {
        return (address(bandCaller) == address(0));
    }

    function _bothOraclesLiveAndUnbrokenAndSimilarPrice
    (
        ChainlinkResponse memory _chainlinkResponse,
        ChainlinkResponse memory _prevChainlinkResponse,
        IStdReference.ReferenceData memory _bandResponse
    )
    internal
    view
    returns (bool)
    {
        // Return false if either oracle is broken or frozen
        if
        (
            _bandIsBroken(_bandResponse) ||
            _bandIsFrozen(_bandResponse) ||
            _chainlinkIsBroken(_chainlinkResponse, _prevChainlinkResponse) ||
            _chainlinkIsFrozen(_chainlinkResponse)
        )
        {
            return false;
        }

        return _bothOraclesSimilarPrice(_chainlinkResponse, _bandResponse.rate);
    }

    function _bandLive(
        IStdReference.ReferenceData memory _bandResponse
    ) internal view returns (bool) {
        if ( 
            _bandIsBroken(_bandResponse) ||
            _bandIsFrozen(_bandResponse)
        ) 
        {
            return false;
        }

        return true;
    }

    function _chainlinkLive(
        ChainlinkResponse memory _chainlinkResponse,
        ChainlinkResponse memory _prevChainlinkResponse
    ) internal view returns (bool) {
        if ( 
            _chainlinkIsBroken(_chainlinkResponse, _prevChainlinkResponse) ||
            _chainlinkIsFrozen(_chainlinkResponse)
        ) 
        {
            return false;
        }

        return true;
    }

    function _bothOraclesSimilarPrice(ChainlinkResponse memory _chainlinkResponse, uint256 _bandPrice) internal pure returns (bool) {
        uint scaledChainlinkPrice = _scaleChainlinkPriceByDigits(uint256(_chainlinkResponse.answer), _chainlinkResponse.decimals);

        // Get the relative price difference between the oracles. Use the lower price as the denominator, i.e. the reference for the calculation.
        uint minPrice = LiquityMath._min(_bandPrice, scaledChainlinkPrice);
        uint maxPrice = LiquityMath._max(_bandPrice, scaledChainlinkPrice);
        uint percentPriceDifference = maxPrice.sub(minPrice).mul(DECIMAL_PRECISION).div(minPrice);

        /*
        * Return true if the relative price difference is <= 3%: if so, we assume both oracles are probably reporting
        * the honest market price, as it is unlikely that both have been broken/hacked and are still in-sync.
        */
        return percentPriceDifference <= MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES;
    }

    function _scaleChainlinkPriceByDigits(uint _price, uint _answerDigits) internal pure returns (uint) {
        /*
        * Convert the price returned by the Chainlink oracle to an 18-digit decimal for use by Liquity.
        * At date of Liquity launch, Chainlink uses an 8-digit price, but we also handle the possibility of
        * future changes.
        *
        */
        uint price;
        if (_answerDigits >= TARGET_DIGITS) {
            // Scale the returned price value down to Liquity's target precision
            price = _price.div(10 ** (_answerDigits - TARGET_DIGITS));
        }
        else if (_answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to Liquity's target precision
            price = _price.mul(10 ** (TARGET_DIGITS - _answerDigits));
        }
        return price;
    }

    function _changeStatus(Status _status) internal {
        status = _status;
        emit PriceFeedStatusChanged(_status);
    }

    function _storePrice(uint _currentPrice) internal {
        lastGoodPrice = _currentPrice;
        emit LastGoodPriceUpdated(_currentPrice);
    }


    function _storeBandPrice(uint256 _bandPrice) internal returns (uint) {
        // price in band response has 18 decimals
        _storePrice(_bandPrice);
        return _bandPrice;
    }

    function _storeChainlinkPrice(ChainlinkResponse memory _chainlinkResponse) internal returns (uint) {
        uint scaledChainlinkPrice = _scaleChainlinkPriceByDigits(uint256(_chainlinkResponse.answer), _chainlinkResponse.decimals);
        _storePrice(scaledChainlinkPrice);

        return scaledChainlinkPrice;
    }

    // --- Oracle response wrapper functions ---

    function _getCurrentBandResponse() internal view returns (IStdReference.ReferenceData memory bandResponse){
        try bandCaller.getReferenceData(collTokenName, "USD") returns
        (
            IStdReference.ReferenceData memory bandRes
        ){
            bandResponse = bandRes;
            return bandResponse;
        }catch{
            return bandResponse;
        }
    }

    function _getCurrentChainlinkResponse() internal view returns (ChainlinkResponse memory chainlinkResponse) {
        // First, try to get current decimal precision:
        try priceAggregator.decimals() returns (uint8 decimals) {
            // If call to Chainlink succeeds, record the current decimal precision
            chainlinkResponse.decimals = decimals;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }

        // Secondly, try to get latest price data:
        try priceAggregator.latestRoundData() returns
        (
            uint80 roundId,
            int256 answer,
            uint256 /* startedAt */,
            uint256 timestamp,
            uint80 /* answeredInRound */
        )
        {
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkResponse.roundId = roundId;
            chainlinkResponse.answer = answer;
            chainlinkResponse.timestamp = timestamp;
            chainlinkResponse.success = true;
            return chainlinkResponse;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }
    }

    function _getPrevChainlinkResponse(uint80 _currentRoundId, uint8 _currentDecimals) internal view returns (ChainlinkResponse memory prevChainlinkResponse) {
        /*
        * NOTE: Chainlink only offers a current decimals() value - there is no way to obtain the decimal precision used in a
        * previous round.  We assume the decimals used in the previous round are the same as the current round.
        */

        // Try to get the price data from the previous round:
        try priceAggregator.getRoundData(_currentRoundId - 1) returns
        (
            uint80 roundId,
            int256 answer,
            uint256 /* startedAt */,
            uint256 timestamp,
            uint80 /* answeredInRound */
        )
        {
            // If call to Chainlink succeeds, return the response and success = true
            prevChainlinkResponse.roundId = roundId;
            prevChainlinkResponse.answer = answer;
            prevChainlinkResponse.timestamp = timestamp;
            prevChainlinkResponse.decimals = _currentDecimals;
            prevChainlinkResponse.success = true;
            return prevChainlinkResponse;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return prevChainlinkResponse;
        }
    }
}