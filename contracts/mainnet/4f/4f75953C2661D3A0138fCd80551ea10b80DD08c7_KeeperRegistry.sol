/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity 0.7.6;


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

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

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
library SafeMathChainlink {
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
    require(b <= a, "SafeMath: subtraction overflow");
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
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 96 bit integers.
 */
library SafeMath96 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint96 a, uint96 b) internal pure returns (uint96) {
    uint96 c = a + b;
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
  function sub(uint96 a, uint96 b) internal pure returns (uint96) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint96 c = a - b;

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
  function mul(uint96 a, uint96 b) internal pure returns (uint96) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint96 c = a * b;
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
  function div(uint96 a, uint96 b) internal pure returns (uint96) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint96 c = a / b;
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
  function mod(uint96 a, uint96 b) internal pure returns (uint96) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

contract KeeperBase {

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution()
    internal
    view
  {
    require(tx.origin == address(0), "only for simulated backend");
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute()
  {
    preventExecution();
    _;
  }

}

interface KeeperCompatibleInterface {

  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );
  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

interface KeeperRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (
      uint256 id
    );
  function performUpkeep(
    uint256 id,
    bytes calldata performData
  ) external returns (
      bool success
    );
  function cancelUpkeep(
    uint256 id
  ) external;
  function addFunds(
    uint256 id,
    uint96 amount
  ) external;

  function getUpkeep(uint256 id)
    external view returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber
    );
  function getUpkeepCount()
    external view returns (uint256);
  function getCanceledUpkeepList()
    external view returns (uint256[] memory);
  function getKeeperList()
    external view returns (address[] memory);
  function getKeeperInfo(address query)
    external view returns (
      address payee,
      bool active,
      uint96 balance
    );
  function getConfig()
    external view returns (
      uint32 paymentPremiumPPB,
      uint24 checkFrequencyBlocks,
      uint32 checkGasLimit,
      uint24 stalenessSeconds,
      int256 fallbackGasPrice,
      int256 fallbackLinkPrice
    );
}

/**
  * @dev The view methods are not actually marked as view in the implementation
  * but we want them to be easily queried off-chain. Solidity will not compile
  * if we actually inherrit from this interface, so we document it here.
  */
interface KeeperRegistryInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(
    uint256 upkeepId,
    address from
  )
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface KeeperRegistryExecutableInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(
    uint256 upkeepId,
    address from
  )
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

/**
  * @notice Registry for adding work for Chainlink Keepers to perform on client
  * contracts. Clients must support the Upkeep interface.
  */
contract KeeperRegistry is Owned, KeeperBase, ReentrancyGuard, KeeperRegistryExecutableInterface {
  using Address for address;
  using SafeMathChainlink for uint256;
  using SafeMath96 for uint96;

  address constant private ZERO_ADDRESS = address(0);
  bytes4 constant private CHECK_SELECTOR = KeeperCompatibleInterface.checkUpkeep.selector;
  bytes4 constant private PERFORM_SELECTOR = KeeperCompatibleInterface.performUpkeep.selector;
  uint256 constant private CALL_GAS_MAX = 2_500_000;
  uint256 constant private CALL_GAS_MIN = 2_300;
  uint256 constant private CANCELATION_DELAY = 50;
  uint256 constant private CUSHION = 5_000;
  uint256 constant private REGISTRY_GAS_OVERHEAD = 80_000;
  uint256 constant private PPB_BASE = 1_000_000_000;
  uint64 constant private UINT64_MAX = 2**64 - 1;
  uint96 constant private LINK_TOTAL_SUPPLY = 1e27;

  uint256 private s_upkeepCount;
  uint256[] private s_canceledUpkeepList;
  address[] private s_keeperList;
  mapping(uint256 => Upkeep) private s_upkeep;
  mapping(address => KeeperInfo) private s_keeperInfo;
  mapping(address => address) private s_proposedPayee;
  mapping(uint256 => bytes) private s_checkData;
  Config private s_config;
  int256 private s_fallbackGasPrice;  // not in config object for gas savings
  int256 private s_fallbackLinkPrice; // not in config object for gas savings

  LinkTokenInterface public immutable LINK;
  AggregatorV3Interface public immutable LINK_ETH_FEED;
  AggregatorV3Interface public immutable FAST_GAS_FEED;

  struct Upkeep {
    address target;
    uint32 executeGas;
    uint96 balance;
    address admin;
    uint64 maxValidBlocknumber;
    address lastKeeper;
  }

  struct KeeperInfo {
    address payee;
    uint96 balance;
    bool active;
  }

  struct Config {
    uint32 paymentPremiumPPB;
    uint24 blockCountPerTurn;
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
  }

  struct PerformParams {
    address from;
    uint256 id;
    bytes performData;
  }

  event UpkeepRegistered(
    uint256 indexed id,
    uint32 executeGas,
    address admin
  );
  event UpkeepPerformed(
    uint256 indexed id,
    bool indexed success,
    address indexed from,
    uint96 payment,
    bytes performData
  );
  event UpkeepCanceled(
    uint256 indexed id,
    uint64 indexed atBlockHeight
  );
  event FundsAdded(
    uint256 indexed id,
    address indexed from,
    uint96 amount
  );
  event FundsWithdrawn(
    uint256 indexed id,
    uint256 amount,
    address to
  );
  event ConfigSet(
    uint32 paymentPremiumPPB,
    uint24 blockCountPerTurn,
    uint32 checkGasLimit,
    uint24 stalenessSeconds,
    int256 fallbackGasPrice,
    int256 fallbackLinkPrice
  );
  event KeepersUpdated(
    address[] keepers,
    address[] payees
  );
  event PaymentWithdrawn(
    address indexed keeper,
    uint256 indexed amount,
    address indexed to,
    address payee
  );
  event PayeeshipTransferRequested(
    address indexed keeper,
    address indexed from,
    address indexed to
  );
  event PayeeshipTransferred(
    address indexed keeper,
    address indexed from,
    address indexed to
  );

  /**
   * @param link address of the LINK Token
   * @param linkEthFeed address of the LINK/ETH price feed
   * @param fastGasFeed address of the Fast Gas price feed
   * @param paymentPremiumPPB payment premium rate oracles receive on top of
   * being reimbursed for gas, measured in parts per billion
   * @param blockCountPerTurn number of blocks each oracle has during their turn to
   * perform upkeep before it will be the next keeper's turn to submit
   * @param checkGasLimit gas limit when checking for upkeep
   * @param stalenessSeconds number of seconds that is allowed for feed data to
   * be stale before switching to the fallback pricing
   * @param fallbackGasPrice gas price used if the gas price feed is stale
   * @param fallbackLinkPrice LINK price used if the LINK price feed is stale
   */
  constructor(
    address link,
    address linkEthFeed,
    address fastGasFeed,
    uint32 paymentPremiumPPB,
    uint24 blockCountPerTurn,
    uint32 checkGasLimit,
    uint24 stalenessSeconds,
    int256 fallbackGasPrice,
    int256 fallbackLinkPrice
  ) {
    LINK = LinkTokenInterface(link);
    LINK_ETH_FEED = AggregatorV3Interface(linkEthFeed);
    FAST_GAS_FEED = AggregatorV3Interface(fastGasFeed);

    setConfig(
      paymentPremiumPPB,
      blockCountPerTurn,
      checkGasLimit,
      stalenessSeconds,
      fallbackGasPrice,
      fallbackLinkPrice
    );
  }


  // ACTIONS

  /**
   * @notice adds a new upkeep
   * @param target address to peform upkeep on
   * @param gasLimit amount of gas to provide the target contract when
   * performing upkeep
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   */
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  )
    external
    override
    onlyOwner()
    returns (
      uint256 id
    )
  {
    require(target.isContract(), "target is not a contract");
    require(gasLimit >= CALL_GAS_MIN, "min gas is 2300");
    require(gasLimit <= CALL_GAS_MAX, "max gas is 2500000");

    id = s_upkeepCount;
    s_upkeep[id] = Upkeep({
      target: target,
      executeGas: gasLimit,
      balance: 0,
      admin: admin,
      maxValidBlocknumber: UINT64_MAX,
      lastKeeper: address(0)
    });
    s_checkData[id] = checkData;
    s_upkeepCount++;

    emit UpkeepRegistered(id, gasLimit, admin);

    return id;
  }

  /**
   * @notice simulated by keepers via eth_call to see if the upkeep needs to be
   * performed. If it does need to be performed then the call simulates the
   * transaction performing upkeep to make sure it succeeds. It then eturns the
   * success status along with payment information and the perform data payload.
   * @param id identifier of the upkeep to check
   * @param from the address to simulate performing the upkeep from
   */
  function checkUpkeep(
    uint256 id,
    address from
  )
    external
    override
    cannotExecute()
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    )
  {
    Upkeep storage upkeep = s_upkeep[id];
    gasLimit = upkeep.executeGas;
    (gasWei, linkEth) = getFeedData();
    maxLinkPayment = calculatePaymentAmount(gasLimit, gasWei, linkEth);
    require(maxLinkPayment < upkeep.balance, "insufficient funds");

    bytes memory callData = abi.encodeWithSelector(CHECK_SELECTOR, s_checkData[id]);
    (
      bool success,
      bytes memory result
    ) = upkeep.target.call{gas: s_config.checkGasLimit}(callData);
    require(success, "call to check target failed");

    (
      success,
      performData
    ) = abi.decode(result, (bool, bytes));
    require(success, "upkeep not needed");

    success = performUpkeepWithParams(PerformParams({
      from: from,
      id: id,
      performData: performData
    }));
    require(success, "call to perform upkeep failed");

    return (performData, maxLinkPayment, gasLimit, gasWei, linkEth);
  }

  /**
   * @notice executes the upkeep with the perform data returned from
   * checkUpkeep, validates the keeper's permissions, and pays the keeper.
   * @param id identifier of the upkeep to execute the data with.
   * @param performData calldata paramter to be passed to the target upkeep.
   */
  function performUpkeep(
    uint256 id,
    bytes calldata performData
  )
    external
    override
    returns (
      bool success
    )
  {
    return performUpkeepWithParams(PerformParams({
      from: msg.sender,
      id: id,
      performData: performData
    }));
  }

  /**
   * @notice prevent an upkeep from being performed in the future
   * @param id upkeep to be canceled
   */
  function cancelUpkeep(
    uint256 id
  )
    external
    override
  {
    uint64 maxValid = s_upkeep[id].maxValidBlocknumber;
    bool notCanceled = maxValid == UINT64_MAX;
    bool isOwner = msg.sender == owner;
    require(notCanceled || (isOwner && maxValid > block.number), "too late to cancel upkeep");
    require(isOwner|| msg.sender == s_upkeep[id].admin, "only owner or admin");

    uint256 height = block.number;
    if (!isOwner) {
      height = height.add(CANCELATION_DELAY);
    }
    s_upkeep[id].maxValidBlocknumber = uint64(height);
    if (notCanceled) {
      s_canceledUpkeepList.push(id);
    }

    emit UpkeepCanceled(id, uint64(height));
  }

  /**
   * @notice adds LINK funding for an upkeep by tranferring from the sender's
   * LINK balance
   * @param id upkeep to fund
   * @param amount number of LINK to transfer
   */
  function addFunds(
    uint256 id,
    uint96 amount
  )
    external
    override
    validUpkeep(id)
  {
    s_upkeep[id].balance = s_upkeep[id].balance.add(amount);
    LINK.transferFrom(msg.sender, address(this), amount);
    emit FundsAdded(id, msg.sender, amount);
  }

  /**
   * @notice uses LINK's transferAndCall to LINK and add funding to an upkeep
   * @dev safe to cast uint256 to uint96 as total LINK supply is under UINT96MAX
   * @param sender the account which transferred the funds
   * @param amount number of LINK transfer
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  )
    external
  {
    require(msg.sender == address(LINK), "only callable through LINK");
    require(data.length == 32, "data must be 32 bytes");
    uint256 id = abi.decode(data, (uint256));
    validateUpkeep(id);

    s_upkeep[id].balance = s_upkeep[id].balance.add(uint96(amount));

    emit FundsAdded(id, sender, uint96(amount));
  }

  /**
   * @notice removes funding from a cancelled upkeep
   * @param id upkeep to withdraw funds from
   * @param to destination address for sending remaining funds
   */
  function withdrawFunds(
    uint256 id,
    address to
  )
    external
    validateRecipient(to)
  {
    require(s_upkeep[id].admin == msg.sender, "only callable by admin");
    require(s_upkeep[id].maxValidBlocknumber <= block.number, "upkeep must be canceled");

    uint256 amount = s_upkeep[id].balance;
    s_upkeep[id].balance = 0;
    emit FundsWithdrawn(id, amount, to);

    LINK.transfer(to, amount);
  }

  /**
   * @notice recovers LINK funds improperly transfered to the registry
   * @dev In principle this function’s execution cost could exceed block
   * gaslimit. However, in our anticipated deployment, the number of upkeeps and
   * keepers will be low enough to avoid this problem.
   */
  function recoverFunds()
    external
    onlyOwner()
  {
    uint96 locked = 0;
    uint256 max = s_upkeepCount;
    for (uint256 i = 0; i < max; i++) {
      locked = s_upkeep[i].balance.add(locked);
    }
    max = s_keeperList.length;
    for (uint256 i = 0; i < max; i++) {
      address addr = s_keeperList[i];
      locked = s_keeperInfo[addr].balance.add(locked);
    }

    uint256 total = LINK.balanceOf(address(this));
    LINK.transfer(msg.sender, total.sub(locked));
  }

  /**
   * @notice withdraws a keeper's payment, callable only by the keeper's payee
   * @param from keeper address
   * @param to address to send the payment to
   */
  function withdrawPayment(
    address from,
    address to
  )
    external
    validateRecipient(to)
  {
    KeeperInfo memory keeper = s_keeperInfo[from];
    require(keeper.payee == msg.sender, "only callable by payee");

    s_keeperInfo[from].balance = 0;
    emit PaymentWithdrawn(from, keeper.balance, to, msg.sender);

    LINK.transfer(to, keeper.balance);
  }

  /**
   * @notice proposes the safe transfer of a keeper's payee to another address
   * @param keeper address of the keeper to transfer payee role
   * @param proposed address to nominate for next payeeship
   */
  function transferPayeeship(
    address keeper,
    address proposed
  )
    external
  {
    require(s_keeperInfo[keeper].payee == msg.sender, "only callable by payee");
    require(proposed != msg.sender, "cannot transfer to self");

    if (s_proposedPayee[keeper] != proposed) {
      s_proposedPayee[keeper] = proposed;
      emit PayeeshipTransferRequested(keeper, msg.sender, proposed);
    }
  }

  /**
   * @notice accepts the safe transfer of payee role for a keeper
   * @param keeper address to accept the payee role for
   */
  function acceptPayeeship(
    address keeper
  )
    external
  {
    require(s_proposedPayee[keeper] == msg.sender, "only callable by proposed payee");
    address past = s_keeperInfo[keeper].payee;
    s_keeperInfo[keeper].payee = msg.sender;
    s_proposedPayee[keeper] = ZERO_ADDRESS;

    emit PayeeshipTransferred(keeper, past, msg.sender);
  }


  // SETTERS

  /**
   * @notice updates the configuration of the registry
   * @param paymentPremiumPPB payment premium rate oracles receive on top of
   * being reimbursed for gas, measured in parts per billion
   * @param blockCountPerTurn number of blocks an oracle should wait before
   * checking for upkeep
   * @param checkGasLimit gas limit when checking for upkeep
   * @param stalenessSeconds number of seconds that is allowed for feed data to
   * be stale before switching to the fallback pricing
   * @param fallbackGasPrice gas price used if the gas price feed is stale
   * @param fallbackLinkPrice LINK price used if the LINK price feed is stale
   */
  function setConfig(
    uint32 paymentPremiumPPB,
    uint24 blockCountPerTurn,
    uint32 checkGasLimit,
    uint24 stalenessSeconds,
    int256 fallbackGasPrice,
    int256 fallbackLinkPrice
  )
    onlyOwner()
    public
  {
    s_config = Config({
      paymentPremiumPPB: paymentPremiumPPB,
      blockCountPerTurn: blockCountPerTurn,
      checkGasLimit: checkGasLimit,
      stalenessSeconds: stalenessSeconds
    });
    s_fallbackGasPrice = fallbackGasPrice;
    s_fallbackLinkPrice = fallbackLinkPrice;

    emit ConfigSet(
      paymentPremiumPPB,
      blockCountPerTurn,
      checkGasLimit,
      stalenessSeconds,
      fallbackGasPrice,
      fallbackLinkPrice
    );
  }

  /**
   * @notice update the list of keepers allowed to peform upkeep
   * @param keepers list of addresses allowed to perform upkeep
   * @param payees addreses corresponding to keepers who are allowed to
   * move payments which have been acrued
   */
  function setKeepers(
    address[] calldata keepers,
    address[] calldata payees
  )
    external
    onlyOwner()
  {
    for (uint256 i = 0; i < s_keeperList.length; i++) {
      address keeper = s_keeperList[i];
      s_keeperInfo[keeper].active = false;
    }
    for (uint256 i = 0; i < keepers.length; i++) {
      address keeper = keepers[i];
      KeeperInfo storage s_keeper = s_keeperInfo[keeper];
      address oldPayee = s_keeper.payee;
      address newPayee = payees[i];
      require(oldPayee == ZERO_ADDRESS || oldPayee == newPayee, "cannot change payee");
      require(!s_keeper.active, "cannot add keeper twice");
      s_keeper.payee = newPayee;
      s_keeper.active = true;
    }
    s_keeperList = keepers;
    emit KeepersUpdated(keepers, payees);
  }


  // GETTERS

  /**
   * @notice read all of the details about an upkeep
   */
  function getUpkeep(
    uint256 id
  )
    external
    view
    override
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber
    )
  {
    Upkeep memory reg = s_upkeep[id];
    return (
      reg.target,
      reg.executeGas,
      s_checkData[id],
      reg.balance,
      reg.lastKeeper,
      reg.admin,
      reg.maxValidBlocknumber
    );
  }

  /**
   * @notice read the total number of upkeep's registered
   */
  function getUpkeepCount()
    external
    view
    override
    returns (
      uint256
    )
  {
    return s_upkeepCount;
  }

  /**
   * @notice read the current list canceled upkeep IDs
   */
  function getCanceledUpkeepList()
    external
    view
    override
    returns (
      uint256[] memory
    )
  {
    return s_canceledUpkeepList;
  }

  /**
   * @notice read the current list of addresses allowed to perform upkeep
   */
  function getKeeperList()
    external
    view
    override
    returns (
      address[] memory
    )
  {
    return s_keeperList;
  }

  /**
   * @notice read the current info about any keeper address
   */
  function getKeeperInfo(
    address query
  )
    external
    view
    override
    returns (
      address payee,
      bool active,
      uint96 balance
    )
  {
    KeeperInfo memory keeper = s_keeperInfo[query];
    return (keeper.payee, keeper.active, keeper.balance);
  }

  /**
   * @notice read the current configuration of the registry
   */
  function getConfig()
    external
    view
    override
    returns (
      uint32 paymentPremiumPPB,
      uint24 blockCountPerTurn,
      uint32 checkGasLimit,
      uint24 stalenessSeconds,
      int256 fallbackGasPrice,
      int256 fallbackLinkPrice
    )
  {
    Config memory config = s_config;
    return (
      config.paymentPremiumPPB,
      config.blockCountPerTurn,
      config.checkGasLimit,
      config.stalenessSeconds,
      s_fallbackGasPrice,
      s_fallbackLinkPrice
    );
  }


  // PRIVATE

  /**
   * @dev retrieves feed data for fast gas/eth and link/eth prices. if the feed
   * data is stale it uses the configured fallback price. Once a price is picked
   * for gas it takes the min of gas price in the transaction or the fast gas
   * price in order to reduce costs for the upkeep clients.
   */
  function getFeedData()
    private
    view
    returns (
      int256 gasWei,
      int256 linkEth
    )
  {
    uint32 stalenessSeconds = s_config.stalenessSeconds;
    bool staleFallback = stalenessSeconds > 0;
    uint256 timestamp;
    (,gasWei,,timestamp,) = FAST_GAS_FEED.latestRoundData();
    if (staleFallback && stalenessSeconds < block.timestamp - timestamp) {
      gasWei = s_fallbackGasPrice;
    }
    (,linkEth,,timestamp,) = LINK_ETH_FEED.latestRoundData();
    if (staleFallback && stalenessSeconds < block.timestamp - timestamp) {
      linkEth = s_fallbackLinkPrice;
    }
    return (gasWei, linkEth);
  }

  /**
   * @dev calculates LINK paid for gas spent plus a configure premium percentage
   */
  function calculatePaymentAmount(
    uint256 gasLimit,
    int256 gasWei,
    int256 linkEth
  )
    private
    view
    returns (
      uint96 payment
    )
  {
    uint256 weiForGas = uint256(gasWei).mul(gasLimit.add(REGISTRY_GAS_OVERHEAD));
    uint256 premium = PPB_BASE.add(s_config.paymentPremiumPPB);
    uint256 total = weiForGas.mul(1e9).mul(premium).div(uint256(linkEth));
    require(total <= LINK_TOTAL_SUPPLY, "payment greater than all LINK");
    return uint96(total); // LINK_TOTAL_SUPPLY < UINT96_MAX
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available
   */
  function callWithExactGas(
    uint256 gasAmount,
    address target,
    bytes memory data
  )
    private
    returns (
      bool success
    )
  {
    assembly{
      let g := gas()
      // Compute g -= CUSHION and check for underflow
      if lt(g, CUSHION) { revert(0, 0) }
      g := sub(g, CUSHION)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) { revert(0, 0) }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) { revert(0, 0) }
      // call and return whether we succeeded. ignore return data
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  /**
   * @dev calls the Upkeep target with the performData param passed in by the
   * keeper and the exact gas required by the Upkeep
   */
  function performUpkeepWithParams(
    PerformParams memory params
  )
    private
    nonReentrant()
    validUpkeep(params.id)
    returns (
      bool success
    )
  {
    require(s_keeperInfo[params.from].active, "only active keepers");
    Upkeep memory upkeep = s_upkeep[params.id];
    uint256 gasLimit = upkeep.executeGas;
    (int256 gasWei, int256 linkEth) = getFeedData();
    if (gasWei > int256(tx.gasprice)) {
      gasWei = int256(tx.gasprice);
    }
    uint96 payment = calculatePaymentAmount(gasLimit, gasWei, linkEth);
    require(upkeep.balance >= payment, "insufficient payment");
    require(upkeep.lastKeeper != params.from, "keepers must take turns");

    uint256  gasUsed = gasleft();
    bytes memory callData = abi.encodeWithSelector(PERFORM_SELECTOR, params.performData);
    success = callWithExactGas(gasLimit, upkeep.target, callData);
    gasUsed = gasUsed - gasleft();

    payment = calculatePaymentAmount(gasUsed, gasWei, linkEth);
    upkeep.balance = upkeep.balance.sub(payment);
    upkeep.lastKeeper = params.from;
    s_upkeep[params.id] = upkeep;
    uint96 newBalance = s_keeperInfo[params.from].balance.add(payment);
    s_keeperInfo[params.from].balance = newBalance;

    emit UpkeepPerformed(
      params.id,
      success,
      params.from,
      payment,
      params.performData
    );
    return success;
  }

  /**
   * @dev ensures a upkeep is valid
   */
  function validateUpkeep(
    uint256 id
  )
    private
    view
  {
    require(s_upkeep[id].maxValidBlocknumber > block.number, "invalid upkeep id");
  }


  // MODIFIERS

  /**
   * @dev ensures a upkeep is valid
   */
  modifier validUpkeep(
    uint256 id
  ) {
    validateUpkeep(id);
    _;
  }

  /**
   * @dev ensures that burns don't accidentally happen by sending to the zero
   * address
   */
  modifier validateRecipient(
    address to
  ) {
    require(to != address(0), "cannot send to zero address");
    _;
  }

}