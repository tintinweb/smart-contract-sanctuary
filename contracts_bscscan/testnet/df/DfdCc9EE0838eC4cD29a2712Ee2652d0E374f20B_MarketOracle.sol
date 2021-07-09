pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./interfaces/IOracle.sol";
import "./lib/Select.sol";

/**
 * @title Market Oracle
 *
 * @notice Provides a value onchain that's aggregated from a whitelisted set of
 *         providers.
 */
contract MarketOracle is OwnableUpgradeSafe, IOracle {
    using SafeMath for uint256;

    struct Report {
        uint256 timestamp;
        uint256 payload;
    }

    // Addresses of providers authorized to push reports.
    address[] public providers;

    // Reports indexed by provider address. Report[0].timestamp > 0
    // indicates provider existence.
    mapping (address => Report[2]) public providerReports;

    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);
    event ReportTimestampOutOfRange(address provider);
    event ProviderReportPushed(address indexed provider, uint256 payload, uint256 timestamp);

    // The number of seconds after which the report is deemed expired.
    uint256 public reportExpirationTimeSec;

    // The number of seconds since reporting that has to pass before a report
    // is usable.
    uint256 public reportDelaySec;

    // The minimum number of providers with valid reports to consider the
    // aggregate report valid.
    uint256 public minimumProviders = 1;

    // Timestamp of 1 is used to mark uninitialized and invalidated data.
    // This is needed so that timestamp of 1 is always considered expired.
    uint256 private constant MAX_REPORT_EXPIRATION_TIME = 520 weeks;

    /**
    * @param reportExpirationTimeSec_ The number of seconds after which the
    *                                 report is deemed expired.
    * @param reportDelaySec_ The number of seconds since reporting that has to
    *                        pass before a report is usable
    * @param minimumProviders_ The minimum number of providers with valid
    *                          reports to consider the aggregate report valid.
    */
    function initialize(uint256 reportExpirationTimeSec_,
        uint256 reportDelaySec_,
        uint256 minimumProviders_)  public initializer {
        __Ownable_init();
        require(reportExpirationTimeSec_ <= MAX_REPORT_EXPIRATION_TIME);
        require(minimumProviders_ > 0);
        reportExpirationTimeSec = reportExpirationTimeSec_;
        reportDelaySec = reportDelaySec_;
        minimumProviders = minimumProviders_;
    }

    /**
    * @notice Sets the report expiration period.
    * @param reportExpirationTimeSec_ The number of seconds after which the
    *        report is deemed expired.
    */
    function setReportExpirationTimeSec(uint256 reportExpirationTimeSec_)
    external
    onlyOwner
    {
        require(reportExpirationTimeSec_ <= MAX_REPORT_EXPIRATION_TIME);
        reportExpirationTimeSec = reportExpirationTimeSec_;
    }

    /**
    * @notice Sets the time period since reporting that has to pass before a
    *         report is usable.
    * @param reportDelaySec_ The new delay period in seconds.
    */
    function setReportDelaySec(uint256 reportDelaySec_)
    external
    onlyOwner
    {
        reportDelaySec = reportDelaySec_;
    }

    /**
    * @notice Sets the minimum number of providers with valid reports to
    *         consider the aggregate report valid.
    * @param minimumProviders_ The new minimum number of providers.
    */
    function setMinimumProviders(uint256 minimumProviders_)
    external
    onlyOwner
    {
        require(minimumProviders_ > 0);
        minimumProviders = minimumProviders_;
    }

    /**
     * @notice Pushes a report for the calling provider.
     * @param payload is expected to be 18 decimal fixed point number.
     */
    function pushReport(uint256 payload) external
    {
        address providerAddress = msg.sender;
        Report[2] storage reports = providerReports[providerAddress];
        uint256[2] memory timestamps = [reports[0].timestamp, reports[1].timestamp];

        require(timestamps[0] > 0);

        uint8 index_recent = timestamps[0] >= timestamps[1] ? 0 : 1;
        uint8 index_past = 1 - index_recent;

        // Check that the push is not too soon after the last one.
        require(timestamps[index_recent].add(reportDelaySec) <= now);

        reports[index_past].timestamp = now;
        reports[index_past].payload = payload;

        emit ProviderReportPushed(providerAddress, payload, now);
    }

    /**
    * @notice Invalidates the reports of the calling provider.
    */
    function purgeReports() external
    {
        address providerAddress = msg.sender;
        require (providerReports[providerAddress][0].timestamp > 0);
        providerReports[providerAddress][0].timestamp=1;
        providerReports[providerAddress][1].timestamp=1;
    }

    /**
    * @notice Computes Market of provider reports whose timestamps are in the
    *         valid timestamp range.
    * @return AggregatedValue: Market of providers reported values.
    *         valid: Boolean indicating an aggregated value was computed successfully.
    */
    function getData()
    external
    override
    returns (uint256, bool)
    {
        uint256 reportsCount = providers.length;
        uint256[] memory validReports = new uint256[](reportsCount);
        uint256 size = 0;
        uint256 minValidTimestamp =  now.sub(reportExpirationTimeSec);
        uint256 maxValidTimestamp =  now.sub(reportDelaySec);

        for (uint256 i = 0; i < reportsCount; i++) {
            address providerAddress = providers[i];
            Report[2] memory reports = providerReports[providerAddress];

            uint8 index_recent = reports[0].timestamp >= reports[1].timestamp ? 0 : 1;
            uint8 index_past = 1 - index_recent;
            uint256 reportTimestampRecent = reports[index_recent].timestamp;
            if (reportTimestampRecent > maxValidTimestamp) {
                // Recent report is too recent.
                uint256 reportTimestampPast = providerReports[providerAddress][index_past].timestamp;
                if (reportTimestampPast < minValidTimestamp) {
                    // Past report is too old.
                    emit ReportTimestampOutOfRange(providerAddress);
                } else if (reportTimestampPast > maxValidTimestamp) {
                    // Past report is too recent.
                    emit ReportTimestampOutOfRange(providerAddress);
                } else {
                    // Using past report.
                    validReports[size++] = providerReports[providerAddress][index_past].payload;
                }
            } else {
                // Recent report is not too recent.
                if (reportTimestampRecent < minValidTimestamp) {
                    // Recent report is too old.
                    emit ReportTimestampOutOfRange(providerAddress);
                } else {
                    // Using recent report.
                    validReports[size++] = providerReports[providerAddress][index_recent].payload;
                }
            }
        }

        if (size < minimumProviders) {
            return (0, false);
        }

        return (Select.computeMedian(validReports, size), true);
    }

    /**
     * @notice Authorizes a provider.
     * @param provider Address of the provider.
     */
    function addProvider(address provider)
    external
    onlyOwner
    {
        require(providerReports[provider][0].timestamp == 0);
        providers.push(provider);
        providerReports[provider][0].timestamp = 1;
        emit ProviderAdded(provider);
    }

    /**
     * @notice Revokes provider authorization.
     * @param provider Address of the provider.
     */
    function removeProvider(address provider)
    external
    onlyOwner
    {
        delete providerReports[provider];
        for (uint256 i = 0; i < providers.length; i++) {
            if (providers[i] == provider) {
                if (i + 1  != providers.length) {
                    providers[i] = providers[providers.length-1];
                }
                providers.pop();
                emit ProviderRemoved(provider);
                break;
            }
        }
    }

    /**
     * @return The number of authorized providers.
     */
    function providersSize()
    external
    view
    returns (uint256)
    {
        return providers.length;
    }
}

pragma solidity 0.6.12;

interface IOracle {
    function getData() external returns (uint256, bool);
}

pragma solidity ^0.6.12;
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title Select
 * @dev Median Selection Library
 */
library Select {
    using SafeMath for uint256;

    /**
     * @dev Sorts the input array up to the denoted size, and returns the median.
     * @param array Input array to compute its median.
     * @param size Number of elements in array to compute the median for.
     * @return Median of array.
     */
    function computeMedian(uint256[] memory array, uint256 size)
        internal
        pure
        returns (uint256)
    {
        require(size > 0 && array.length >= size);
        for (uint256 i = 1; i < size; i++) {
            for (uint256 j = i; j > 0 && array[j-1]  > array[j]; j--) {
                uint256 tmp = array[j];
                array[j] = array[j-1];
                array[j-1] = tmp;
            }
        }
        if (size % 2 == 1) {
            return array[size / 2];
        } else {
            return array[size / 2].add(array[size / 2 - 1]) / 2;
        }
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

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

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

/**
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}