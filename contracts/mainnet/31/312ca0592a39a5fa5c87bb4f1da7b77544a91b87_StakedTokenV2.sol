/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// Sources flattened with hardhat v2.1.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
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
}


// File contracts/DownstreamCaller.sol

// contracts/DownstreamCaller.sol

pragma solidity 0.6.10;

contract DownstreamCaller is Ownable {
    struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }

    event TransactionFailed(address indexed destination, uint256 index, bytes data);

    // Stable ordering is not guaranteed.
    Transaction[] public transactions;

    /**
     * Call all downstream transactions
     */
    function executeTransactions() external onlyOwner {
        for (uint256 i = 0; i < transactions.length; i++) {
            Transaction storage t = transactions[i];
            if (t.enabled) {
                bool result = externalCall(t.destination, t.data);
                if (!result) {
                    emit TransactionFailed(t.destination, i, t.data);
                    revert("Transaction Failed");
                }
            }
        }
    }


    /**
     * @notice Adds a transaction that gets called for a downstream receiver of token distributions
     * @param destination Address of contract destination
     * @param data Transaction data payload
     * @return index of the newly added transaction
     */
    function addTransaction(address destination, bytes memory data) external onlyOwner returns(uint256) {
        require(destination != address(0x0));
        require(data.length != 0);
        uint txIndex = transactions.length;
        transactions.push(Transaction({ enabled: true, destination: destination, data: data }));
        return txIndex;
    }

    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint256 index) external onlyOwner {
        require(index < transactions.length, "index out of bounds");

        if (index < transactions.length - 1) {
            transactions[index] = transactions[transactions.length - 1];
        }

        transactions.pop();
    }

    /**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */
    function setTransactionEnabled(uint256 index, bool enabled) external onlyOwner {
        require(index < transactions.length, "index must be in range of stored tx list");
        transactions[index].enabled = enabled;
    }

    /**
     * @return Number of transactions, both enabled and disabled, in transactions list.
     */
    function transactionsSize() external view returns (uint256) {
        return transactions.length;
    }

    /**
     * @dev wrapper to call the encoded transactions on downstream consumers.
     * @param destination Address of destination contract.
     * @param data The encoded data payload.
     * @return True on success
     */
    function externalCall(address destination, bytes memory data) internal returns (bool) {
        bool result;
        assembly {
            // solhint-disable-line no-inline-assembly
            // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let outputAddress := mload(0x40)

            // First 32 bytes are the padded length of data, so exclude that
            let dataAddress := add(data, 32)

            result := call(
                // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB)
                // + callValueTransferGas (9000) + callNewAccountGas
                // (25000, in case the destination address does not exist and needs creating)
                sub(gas(), 34710),
                destination,
                0, // transfer value in wei
                dataAddress,
                mload(data), // Size of the input, in bytes. Stored in position 0 of the array.
                outputAddress,
                0 // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}


// File contracts/mocks/Mock.sol

// contracts/StakedToken.sol

pragma solidity 0.6.10;

contract Mock {
    event FunctionCalled(string instanceName, string functionName, address caller);
    event FunctionArguments(uint256[] uintVals, int256[] intVals);
    event ReturnValueInt256(int256 val);
    event ReturnValueUInt256(uint256 val);
}


// File contracts/mocks/MockDownstream.sol

// contracts/StakedToken.sol

pragma solidity 0.6.10;

contract MockDownstream is Mock {
    function updateNoArg() external returns (bool) {
        emit FunctionCalled("MockDownstream", "updateNoArg", msg.sender);
        uint256[] memory uintVals = new uint256[](0);
        int256[] memory intVals = new int256[](0);
        emit FunctionArguments(uintVals, intVals);
        return true;
    }

    function updateOneArg(uint256 u) external {
        emit FunctionCalled("MockDownstream", "updateOneArg", msg.sender);

        uint256[] memory uintVals = new uint256[](1);
        uintVals[0] = u;
        int256[] memory intVals = new int256[](0);
        emit FunctionArguments(uintVals, intVals);
    }

    function updateTwoArgs(uint256 u, int256 i) external {
        emit FunctionCalled("MockDownstream", "updateTwoArgs", msg.sender);

        uint256[] memory uintVals = new uint256[](1);
        uintVals[0] = u;
        int256[] memory intVals = new int256[](1);
        intVals[0] = i;
        emit FunctionArguments(uintVals, intVals);
    }

    function reverts() external {
        emit FunctionCalled("MockDownstream", "reverts", msg.sender);

        uint256[] memory uintVals = new uint256[](0);
        int256[] memory intVals = new int256[](0);
        emit FunctionArguments(uintVals, intVals);

        require(false, "reverted");
    }
}


// File @openzeppelin/contracts-ethereum-package/contracts/[email protected]

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


// File @openzeppelin/contracts-ethereum-package/contracts/GSN/[email protected]

pragma solidity ^0.6.0;

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


// File @openzeppelin/contracts-ethereum-package/contracts/access/[email protected]

pragma solidity ^0.6.0;


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


// File @openzeppelin/contracts-ethereum-package/contracts/utils/[email protected]

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {


        _paused = false;

    }


    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}


// File @openzeppelin/contracts-ethereum-package/contracts/math/[email protected]

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


// File @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/[email protected]

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/StakedToken.sol

// contracts/StakedToken.sol

pragma solidity 0.6.10;






contract StakedToken is IERC20, Initializable, OwnableUpgradeSafe, PausableUpgradeSafe  {
    using SafeMath for uint256;

    /**
     * @dev Emitted when supply controller is changed
     */
    event LogSupplyControllerUpdated(address supplyController);
    /**
     * @dev Emitted when token distribution happens
     */
    event LogTokenDistribution(uint256 oldTotalSupply, uint256 supplyChange, bool positive, uint256 newTotalSupply);
    /**
     * @dev Emitted if total supply exceeds maximum expected supply
     */
    event WarningMaxExpectedSupplyExceeded(uint256 totalSupply, uint256 totalShares);


    address public supplyController;

    uint256 private MAX_UINT256;

    // Defines the multiplier applied to shares to arrive at the underlying balance
    uint256 private _maxExpectedSupply;

    uint256 private _sharesPerToken;
    uint256 private _totalSupply;
    uint256 private _totalShares;

    mapping(address => uint256) private _shareBalances;
    //Denominated in tokens not shares, to align with user expectations
    mapping(address => mapping(address => uint256)) private _allowedTokens;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public isBlacklisted;
    /**
     * @dev Emitted when account blacklist status changes
     */
    event Blacklisted(address indexed account, bool isBlacklisted);

    DownstreamCaller public downstreamCaller;

    modifier onlySupplyController() {
        require(msg.sender == supplyController);
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    /**
     * Set the address that can mint, burn and rebase
     *
     * @param name_ Name of the token
     * @param symbol_ Symbol of the token
     * @param decimals_ Decimal places of the token - purely for display purposes
     * @param maxExpectedSupply_ Maximum possilbe supply of the token.
                                Value should be chosen such that it could never be realistically exceeded based on the underlying token.
                                Not binding, can be exceeded in reality, with the risk of losing precision in a reward distribution event
     * @param initialSupply_ Inital supply of the token, sent to the creator of the token
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 maxExpectedSupply_,
        uint256 initialSupply_
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        supplyController = msg.sender;

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        MAX_UINT256 = ~uint256(0);

        // Maximise precision by picking the largest possible sharesPerToken value
        // It is crucial to pick a maxSupply value that will never be exceeded
        _sharesPerToken = MAX_UINT256.div(maxExpectedSupply_);

        _maxExpectedSupply = maxExpectedSupply_;
        _totalSupply = initialSupply_;
        _totalShares = initialSupply_.mul(_sharesPerToken);
        _shareBalances[msg.sender] = _totalShares;

        downstreamCaller = new DownstreamCaller();

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    /**
     * Set the address that can mint, burn and rebase
     *
     * @param supplyController_ Address of the new supply controller
     */
    function setSupplyController(address supplyController_) external onlyOwner {
        require(supplyController_ != address(0x0), "invalid address");
        supplyController = supplyController_;
        emit LogSupplyControllerUpdated(supplyController);
    }

    /**
     * Distribute a supply increase or decrease to all token holders proportionally
     *
     * @param supplyChange_ Increase of supply in token units
     * @return The updated total supply
     */
    function distributeTokens(uint256 supplyChange_, bool positive) external onlySupplyController returns (uint256) {
        uint256 newTotalSupply;
        if (positive) {
            newTotalSupply = _totalSupply.add(supplyChange_);
        } else {
            newTotalSupply = _totalSupply.sub(supplyChange_);
        }

        require(newTotalSupply > 0, "rebase cannot make supply 0");

        _sharesPerToken = _totalShares.div(newTotalSupply);

        // Set correct total supply in case of mismatch caused by integer division
        newTotalSupply = _totalShares.div(_sharesPerToken);

        emit LogTokenDistribution(_totalSupply, supplyChange_, positive, newTotalSupply);

        _totalSupply = newTotalSupply;

        if (_totalSupply > _maxExpectedSupply) {
            emit WarningMaxExpectedSupplyExceeded(_totalSupply, _totalShares);
        }

        // Call downstream transactions
        downstreamCaller.executeTransactions();

        return _totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * Set the name of the token
     * @param name_ the new name of the token.
     */
    function setName(string calldata name_) external onlyOwner {
        _name = name_;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * Set the symbol of the token
     * @param symbol_ the new symbol of the token.
     */
    function setSymbol(string calldata symbol_) external onlyOwner {
        _symbol = symbol_;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @return The total supply of the underlying token
     */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return The total supply in shares
     */
    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) external override view returns (uint256) {
        return _shareBalances[who].div(_sharesPerToken);
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address in shares.
     */
    function sharesOf(address who) external view returns (uint256) {
        return _shareBalances[who];
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value) external override validRecipient(to) whenNotPaused returns (bool) {
        require(!isBlacklisted[msg.sender], "from blacklisted");
        require(!isBlacklisted[to], "to blacklisted");

        uint256 shareValue = value.mul(_sharesPerToken);
        _shareBalances[msg.sender] = _shareBalances[msg.sender].sub(
            shareValue,
            "transfer amount exceed account balance"
        );
        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) external override view returns (uint256) {
        return _allowedTokens[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) whenNotPaused returns (bool) {
        require(!isBlacklisted[from], "from blacklisted");
        require(!isBlacklisted[to], "to blacklisted");

        _allowedTokens[from][msg.sender] = _allowedTokens[from][msg.sender].sub(
            value,
            "transfer amount exceeds allowance"
        );

        uint256 shareValue = value.mul(_sharesPerToken);
        _shareBalances[from] = _shareBalances[from].sub(shareValue, "transfer amount exceeds account balance");
        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        require(!isBlacklisted[msg.sender], "owner blacklisted");
        require(!isBlacklisted[spender], "spender blacklisted");
        require(spender != address(0x0), "invalid address");

        _allowedTokens[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        require(!isBlacklisted[msg.sender], "owner blacklisted");
        require(!isBlacklisted[spender], "spender blacklisted");
        require(spender != address(0x0), "invalid address");

        _allowedTokens[msg.sender][spender] = _allowedTokens[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedTokens[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        require(!isBlacklisted[msg.sender], "owner blacklisted");
        require(!isBlacklisted[spender], "spender blacklisted");
        require(spender != address(0x0), "invalid address");

        uint256 oldValue = _allowedTokens[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedTokens[msg.sender][spender] = 0;
        } else {
            _allowedTokens[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedTokens[msg.sender][spender]);
        return true;
    }

    /** Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply, keeping the tokens per shares constant
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount) external onlySupplyController validRecipient(account) {
        require(!isBlacklisted[account], "account blacklisted");
        require(account != address(0x0), "invalid address");

        _totalSupply = _totalSupply.add(amount);
        uint256 shareAmount = amount.mul(_sharesPerToken);
        _totalShares = _totalShares.add(shareAmount);
        _shareBalances[account] = _shareBalances[account].add(shareAmount);
        emit Transfer(address(0), account, amount);

        if (_totalSupply > _maxExpectedSupply) {
            emit WarningMaxExpectedSupplyExceeded(_totalSupply, _totalShares);
        }
    }

    /**
     * Destroys `amount` tokens from `supplyController` account, reducing the
     * total supply while keeping the tokens per shares ratio constant
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function burn(uint256 amount) external onlySupplyController {
        uint256 shareAmount = amount.mul(_sharesPerToken);
        _shareBalances[supplyController] = _shareBalances[supplyController].sub(shareAmount, "burn amount exceeds balance");
        _totalShares = _totalShares.sub(shareAmount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(supplyController, address(0), amount);
    }


    // Downstream transactions

    /**
     * @return Address of the downstream caller contract
     */
    function downstreamCallerAddress() external view returns (address) {
        return address(downstreamCaller);
    }

    /**
     * @param _downstreamCaller Address of the new downstream caller contract
     */
    function setDownstreamCaller(DownstreamCaller _downstreamCaller) external onlyOwner {
        downstreamCaller = _downstreamCaller;
    }

    /**
     * @notice Adds a transaction that gets called for a downstream receiver of token distributions
     * @param destination Address of contract destination
     * @param data Transaction data payload
     * @return index of the newly added transaction
     */
    function addTransaction(address destination, bytes memory data) external onlySupplyController returns(uint256) {
        return downstreamCaller.addTransaction(destination, data);
    }

    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint256 index) external onlySupplyController {
        downstreamCaller.removeTransaction(index);
    }

    /**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */
    function setTransactionEnabled(uint256 index, bool enabled) external onlySupplyController {
        downstreamCaller.setTransactionEnabled(index, enabled);
    }

    /**
     * @return Number of transactions, both enabled and disabled, in transactions list.
     */
    function transactionsSize() external view returns (uint256) {
        return downstreamCaller.transactionsSize();
    }


    /**
     * @dev Triggers stopped state.
     */
    function pause() external onlySupplyController {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     */
    function unpause() external onlySupplyController {
        _unpause();
    }

    /**
     * @dev Set blacklisted status for the account.
     * @param account address to set blacklist flag for
     * @param _isBlacklisted blacklist flag value
     *
     * Requirements:
     *
     * - `msg.sender` should be owner.
     */
    function setBlacklisted(address account, bool _isBlacklisted) external onlySupplyController {
        isBlacklisted[account] = _isBlacklisted;
        emit Blacklisted(account, _isBlacklisted);
    }
}


// File contracts/mocks/StakedTokenMockV2.sol

// contracts/StakedToken.sol

pragma solidity 0.6.10;

contract StakedTokenMockV2 is StakedToken  {

    bool private newVar;

    function v2() external pure returns (string memory) {
        return "hi";
    }
}


// File contracts/StakedTokenV2.sol

// contracts/StakedToken.sol

pragma solidity 0.6.10;






contract StakedTokenV2 is IERC20, Initializable, OwnableUpgradeSafe, PausableUpgradeSafe  {
    using SafeMath for uint256;

    /**
     * @dev Emitted when supply controller is changed
     */
    event LogSupplyControllerUpdated(address supplyController);
    /**
     * @dev Emitted when token distribution happens
     */
    event LogTokenDistribution(uint256 oldTotalSupply, uint256 supplyChange, bool positive, uint256 newTotalSupply);
    /**
     * @dev Emitted if total supply exceeds maximum expected supply
     */
    event WarningMaxExpectedSupplyExceeded(uint256 totalSupply, uint256 totalShares);


    address public supplyController;

    uint256 private MAX_UINT256;

    // Defines the multiplier applied to shares to arrive at the underlying balance
    uint256 private _maxExpectedSupply;

    uint256 private _sharesPerToken;
    uint256 private _totalSupply;
    uint256 private _totalShares;

    mapping(address => uint256) private _shareBalances;
    //Denominated in tokens not shares, to align with user expectations
    mapping(address => mapping(address => uint256)) private _allowedTokens;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public isBlacklisted;
    /**
     * @dev Emitted when account blacklist status changes
     */
    event Blacklisted(address indexed account, bool isBlacklisted);

    DownstreamCaller public downstreamCaller;

    modifier onlySupplyController() {
        require(msg.sender == supplyController);
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    /**
     * Set the address that can mint, burn and rebase
     *
     * @param name_ Name of the token
     * @param symbol_ Symbol of the token
     * @param decimals_ Decimal places of the token - purely for display purposes
     * @param maxExpectedSupply_ Maximum possilbe supply of the token.
                                Value should be chosen such that it could never be realistically exceeded based on the underlying token.
                                Not binding, can be exceeded in reality, with the risk of losing precision in a reward distribution event
     * @param initialSupply_ Inital supply of the token, sent to the creator of the token
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 maxExpectedSupply_,
        uint256 initialSupply_
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        supplyController = msg.sender;

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        MAX_UINT256 = ~uint256(0);

        // Maximise precision by picking the largest possible sharesPerToken value
        // It is crucial to pick a maxSupply value that will never be exceeded
        _sharesPerToken = MAX_UINT256.div(maxExpectedSupply_);

        _maxExpectedSupply = maxExpectedSupply_;
        _totalSupply = initialSupply_;
        _totalShares = initialSupply_.mul(_sharesPerToken);
        _shareBalances[msg.sender] = _totalShares;

        downstreamCaller = new DownstreamCaller();

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    /**
     * Set the address that can mint, burn and rebase
     *
     * @param supplyController_ Address of the new supply controller
     */
    function setSupplyController(address supplyController_) external onlyOwner {
        require(supplyController_ != address(0x0), "invalid address");
        supplyController = supplyController_;
        emit LogSupplyControllerUpdated(supplyController);
    }

    /**
     * Distribute a supply increase or decrease to all token holders proportionally
     *
     * @param supplyChange_ Increase of supply in token units
     * @return The updated total supply
     */
    function distributeTokens(uint256 supplyChange_, bool positive) external onlySupplyController returns (uint256) {
        uint256 newTotalSupply;
        if (positive) {
            newTotalSupply = _totalSupply.add(supplyChange_);
        } else {
            newTotalSupply = _totalSupply.sub(supplyChange_);
        }

        require(newTotalSupply > 0, "rebase cannot make supply 0");

        _sharesPerToken = _totalShares.div(newTotalSupply);

        // Set correct total supply in case of mismatch caused by integer division
        newTotalSupply = _totalShares.div(_sharesPerToken);

        emit LogTokenDistribution(_totalSupply, supplyChange_, positive, newTotalSupply);

        _totalSupply = newTotalSupply;

        if (_totalSupply > _maxExpectedSupply) {
            emit WarningMaxExpectedSupplyExceeded(_totalSupply, _totalShares);
        }

        // Call downstream transactions
        downstreamCaller.executeTransactions();

        return _totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * Set the name of the token
     * @param name_ the new name of the token.
     */
    function setName(string calldata name_) external onlyOwner {
        _name = name_;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * Set the symbol of the token
     * @param symbol_ the new symbol of the token.
     */
    function setSymbol(string calldata symbol_) external onlyOwner {
        _symbol = symbol_;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @return The total supply of the underlying token
     */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return The total supply in shares
     */
    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) external override view returns (uint256) {
        return _shareBalances[who].div(_sharesPerToken);
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address in shares.
     */
    function sharesOf(address who) external view returns (uint256) {
        return _shareBalances[who];
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value) external override validRecipient(to) whenNotPaused returns (bool) {
        // require(!isBlacklisted[msg.sender], "from blacklisted");
        require(!isBlacklisted[to], "to blacklisted");

        uint256 shareValue = value.mul(_sharesPerToken);
        _shareBalances[msg.sender] = _shareBalances[msg.sender].sub(
            shareValue,
            "transfer amount exceed account balance"
        );
        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) external override view returns (uint256) {
        return _allowedTokens[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) whenNotPaused returns (bool) {
        require(!isBlacklisted[from], "from blacklisted");
        require(!isBlacklisted[to], "to blacklisted");

        _allowedTokens[from][msg.sender] = _allowedTokens[from][msg.sender].sub(
            value,
            "transfer amount exceeds allowance"
        );

        uint256 shareValue = value.mul(_sharesPerToken);
        _shareBalances[from] = _shareBalances[from].sub(shareValue, "transfer amount exceeds account balance");
        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        require(!isBlacklisted[msg.sender], "owner blacklisted");
        require(!isBlacklisted[spender], "spender blacklisted");
        require(spender != address(0x0), "invalid address");

        _allowedTokens[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        require(!isBlacklisted[msg.sender], "owner blacklisted");
        require(!isBlacklisted[spender], "spender blacklisted");
        require(spender != address(0x0), "invalid address");

        _allowedTokens[msg.sender][spender] = _allowedTokens[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedTokens[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        require(!isBlacklisted[msg.sender], "owner blacklisted");
        require(!isBlacklisted[spender], "spender blacklisted");
        require(spender != address(0x0), "invalid address");

        uint256 oldValue = _allowedTokens[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedTokens[msg.sender][spender] = 0;
        } else {
            _allowedTokens[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedTokens[msg.sender][spender]);
        return true;
    }

    /** Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply, keeping the tokens per shares constant
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount) external onlySupplyController validRecipient(account) {
        require(!isBlacklisted[account], "account blacklisted");
        require(account != address(0x0), "invalid address");

        _totalSupply = _totalSupply.add(amount);
        uint256 shareAmount = amount.mul(_sharesPerToken);
        _totalShares = _totalShares.add(shareAmount);
        _shareBalances[account] = _shareBalances[account].add(shareAmount);
        emit Transfer(address(0), account, amount);

        if (_totalSupply > _maxExpectedSupply) {
            emit WarningMaxExpectedSupplyExceeded(_totalSupply, _totalShares);
        }
    }

    /**
     * Destroys `amount` tokens from `supplyController` account, reducing the
     * total supply while keeping the tokens per shares ratio constant
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function burn(uint256 amount) external onlySupplyController {
        uint256 shareAmount = amount.mul(_sharesPerToken);
        _shareBalances[supplyController] = _shareBalances[supplyController].sub(shareAmount, "burn amount exceeds balance");
        _totalShares = _totalShares.sub(shareAmount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(supplyController, address(0), amount);
    }


    // Downstream transactions

    /**
     * @return Address of the downstream caller contract
     */
    function downstreamCallerAddress() external view returns (address) {
        return address(downstreamCaller);
    }

    /**
     * @param _downstreamCaller Address of the new downstream caller contract
     */
    function setDownstreamCaller(DownstreamCaller _downstreamCaller) external onlyOwner {
        downstreamCaller = _downstreamCaller;
    }

    /**
     * @notice Adds a transaction that gets called for a downstream receiver of token distributions
     * @param destination Address of contract destination
     * @param data Transaction data payload
     * @return index of the newly added transaction
     */
    function addTransaction(address destination, bytes memory data) external onlySupplyController returns(uint256) {
        return downstreamCaller.addTransaction(destination, data);
    }

    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint256 index) external onlySupplyController {
        downstreamCaller.removeTransaction(index);
    }

    /**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */
    function setTransactionEnabled(uint256 index, bool enabled) external onlySupplyController {
        downstreamCaller.setTransactionEnabled(index, enabled);
    }

    /**
     * @return Number of transactions, both enabled and disabled, in transactions list.
     */
    function transactionsSize() external view returns (uint256) {
        return downstreamCaller.transactionsSize();
    }


    /**
     * @dev Triggers stopped state.
     */
    function pause() external onlySupplyController {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     */
    function unpause() external onlySupplyController {
        _unpause();
    }

    /**
     * @dev Set blacklisted status for the account.
     * @param account address to set blacklist flag for
     * @param _isBlacklisted blacklist flag value
     *
     * Requirements:
     *
     * - `msg.sender` should be owner.
     */
    function setBlacklisted(address account, bool _isBlacklisted) external onlySupplyController {
        isBlacklisted[account] = _isBlacklisted;
        emit Blacklisted(account, _isBlacklisted);
    }
}


// File contracts/Wrapper.sol

// // contracts/Wrapper.sol
//
// pragma solidity >=0.6.0 <0.8.0;

// import "@openzeppelin/contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
// import "./StakedToken.sol";

// contract Wrapper is ERC20Upgradeable {
//     using SafeMathUpgradeable for uint256;

//     StakedToken token;

//     function initialize(address _token, string name, string symbol) public initializer {
//         __ERC20_init(name, symbol);

//         token = StakedToken(token);
//         _setupDecimals(token.decimals());
//     }

//     function balance() public view returns (uint256) {
//         return token.balanceOf(address(this));
//     }

//     function deposit(uint256 _amount) public {
//         unit256 _before = balance();

//         require(token.transferFrom(msg.sender, address(this), _amount));

//         unit256 _after = balance();
//         // Recompute amount in case of deflationary token
//         _amount = _after.sub(_before);

//         unit256 shares = 0;
//         if ( totalSupply() == 0) {
//             shares = _amount;
//         } else {
//             shares = _amount.mul(totalSupply()).div(_before);
//         }

//         _mint(msg.sender, shares);
//     }

//     function withdraw(unit256 _shares) public {
//         uint256 _amountToRedeem = _shares.mul(balance()).div(totalSupply());
//         _burn(msg.sender, _shares);

//         token.transfer(msg.sender, _amountToRedeem);
//     }
// }