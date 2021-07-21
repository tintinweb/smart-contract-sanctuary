/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;



// Part: Context

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: EnumerableBytes32Set

/**
 * @dev Library for managing loan sets
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * Include with `using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;`.
 *
 */
library EnumerableBytes32Set {

    struct Bytes32Set {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) index;
        bytes32[] values;
    }

    /**
     * @dev Add an address value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return addBytes32(set, value);
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (!contains(set, value)){
            set.index[value] = set.values.push(value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes an address value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return removeBytes32(set, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (contains(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set.values[lastIndex];

                // Move the last value to the index where the deleted value is
                set.values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted value
            delete set.index[value];

            // Delete the old entry for the moved value
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function containsAddress(Bytes32Set storage set, address addrvalue)
        internal
        view
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return set.index[value] != 0;
    }

    /**
     * @dev Returns an array with all values in the set. O(N).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(Bytes32Set storage set, uint256 start, uint256 count)
        internal
        view
        returns (bytes32[] memory output)
    {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        end = set.values.length < end ? set.values.length : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new bytes32[](end-start);
        for (uint256 i = start; i < end; i++) {
            output[i-start] = set.values[i];
        }
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(Bytes32Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return set.values[index];
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function getAddress(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (address)
    {
        bytes32 value = set.values[index];
        address addrvalue;
        assembly {
            addrvalue := value
        }
        return addrvalue;
    }
}

// Part: IERC20

contract IERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Part: IWeth

interface IWeth {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

// Part: LenderInterestStruct

contract LenderInterestStruct {
    struct LenderInterest {
        uint256 principalTotal;     // total borrowed amount outstanding of asset
        uint256 owedPerDay;         // interest owed per day for all loans of asset
        uint256 owedTotal;          // total interest owed for all loans of asset (assuming they go to full term)
        uint256 paidTotal;          // total interest paid so far for asset
        uint256 updatedTimestamp;   // last update
    }
}

// Part: LoanInterestStruct

contract LoanInterestStruct {
    struct LoanInterest {
        uint256 owedPerDay;         // interest owed per day for loan
        uint256 depositTotal;       // total escrowed interest for loan
        uint256 updatedTimestamp;   // last update
    }
}

// Part: LoanParamsStruct

contract LoanParamsStruct {
    struct LoanParams {
        bytes32 id;                 // id of loan params object
        bool active;                // if false, this object has been disabled by the owner and can't be used for future loans
        address owner;              // owner of this object
        address loanToken;          // the token being loaned
        address collateralToken;    // the required collateral token
        uint256 minInitialMargin;   // the minimum allowed initial margin
        uint256 maintenanceMargin;  // an unhealthy loan when current margin is at or below this value
        uint256 maxLoanTerm;        // the maximum term for new loans (0 means there's no max term)
    }
}

// Part: LoanStruct

contract LoanStruct {
    struct Loan {
        bytes32 id;                 // id of the loan
        bytes32 loanParamsId;       // the linked loan params id
        bytes32 pendingTradesId;    // the linked pending trades id
        uint256 principal;          // total borrowed amount outstanding
        uint256 collateral;         // total collateral escrowed for the loan
        uint256 startTimestamp;     // loan start time
        uint256 endTimestamp;       // for active loans, this is the expected loan end time, for in-active loans, is the actual (past) end time
        uint256 startMargin;        // initial margin when the loan opened
        uint256 startRate;          // reference rate when the loan opened for converting collateralToken to loanToken
        address borrower;           // borrower of this loan
        address lender;             // lender of this loan
        bool active;                // if false, the loan has been fully closed
    }
}

// Part: OrderStruct

contract OrderStruct {
    struct Order {
        uint256 lockedAmount;           // escrowed amount waiting for a counterparty
        uint256 interestRate;           // interest rate defined by the creator of this order
        uint256 minLoanTerm;            // minimum loan term allowed
        uint256 maxLoanTerm;            // maximum loan term allowed
        uint256 createdTimestamp;       // timestamp when this order was created
        uint256 expirationTimestamp;    // timestamp when this order expires
    }
}

// Part: ReentrancyGuard

contract ReentrancyGuard {

    /// @dev Constant for unlocked guard state - non-zero to prevent extra gas costs.
    /// See: https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1056
    uint256 internal constant REENTRANCY_GUARD_FREE = 1;

    /// @dev Constant for locked guard state
    uint256 internal constant REENTRANCY_GUARD_LOCKED = 2;

    /**
    * @dev We use a single lock for the whole contract.
    */
    uint256 internal reentrancyLock = REENTRANCY_GUARD_FREE;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * If you mark a function `nonReentrant`, you should also
    * mark it `external`. Calling one `nonReentrant` function from
    * another is not supported. Instead, you can implement a
    * `private` function doing the actual work, and an `external`
    * wrapper marked as `nonReentrant`.
    */
    modifier nonReentrant() {
        require(reentrancyLock == REENTRANCY_GUARD_FREE, "nonReentrant");
        reentrancyLock = REENTRANCY_GUARD_LOCKED;
        _;
        reentrancyLock = REENTRANCY_GUARD_FREE;
    }

}

// Part: SafeMath

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
        require(b != 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two numbers, rounding up and truncating the quotient
    */
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        return divCeil(a, b, "SafeMath: division by zero");
    }

    /**
    * @dev Integer division of two numbers, rounding up and truncating the quotient
    */
    function divCeil(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);

        if (a == 0) {
            return 0;
        }
        uint256 c = ((a - 1) / b) + 1;

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

    function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}

// Part: IWethERC20

contract IWethERC20 is IWeth, IERC20 {}

// Part: Objects

contract Objects is
    LoanStruct,
    LoanParamsStruct,
    OrderStruct,
    LenderInterestStruct,
    LoanInterestStruct
{}

// Part: Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
        require(isOwner(), "unauthorized");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

// Part: Constants

contract Constants {

    uint256 internal constant WEI_PRECISION = 10**18;
    uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

    uint256 internal constant DAYS_IN_A_YEAR = 365;
    uint256 internal constant ONE_MONTH = 2628000; // approx. seconds in a month

    string internal constant LoanDepositValueID = "LoanDepositValue";

    /// @notice address of WrappedEther deployed contract
    //IWethERC20 public constant wethToken = IWethERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // mainnet

    //IWethERC20 public constant wethToken = IWethERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C); // kovan

    //IWethERC20 public constant wethToken = IWethERC20(0x602C71e4DAC47a042Ee7f46E0aee17F94A3bA0B6); // local testnet only

    // IWethERC20 public constant wethToken = IWethERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // bsc (Wrapped BNB)

    IWethERC20 public constant wethToken = IWethERC20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd); // bsc_testnet (Wrapped BNB)

    //IWethERC20 public constant wethToken = IWethERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); // polygon (Wrapped MATIC)
}

// Part: State

contract State is Constants, Objects, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    address public priceFeeds;                                                              // handles asset reference price lookups
    address public swapsImpl;                                                               // handles asset swaps using dex liquidity

    mapping (bytes4 => address) public logicTargets;                                        // implementations of protocol functions

    mapping (bytes32 => Loan) public loans;                                                 // loanId => Loan
    mapping (bytes32 => LoanParams) public loanParams;                                      // loanParamsId => LoanParams

    mapping (address => mapping (bytes32 => Order)) public lenderOrders;                    // lender => orderParamsId => Order
    mapping (address => mapping (bytes32 => Order)) public borrowerOrders;                  // borrower => orderParamsId => Order

    mapping (bytes32 => mapping (address => bool)) public delegatedManagers;                // loanId => delegated => approved

    // Interest
    mapping (address => mapping (address => LenderInterest)) public lenderInterest;         // lender => loanToken => LenderInterest object
    mapping (bytes32 => LoanInterest) public loanInterest;                                  // loanId => LoanInterest object

    // Internals
    EnumerableBytes32Set.Bytes32Set internal logicTargetsSet;                               // implementations set
    EnumerableBytes32Set.Bytes32Set internal activeLoansSet;                                // active loans set

    mapping (address => EnumerableBytes32Set.Bytes32Set) internal lenderLoanSets;           // lender loans set
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal borrowerLoanSets;         // borrow loans set
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal userLoanParamSets;        // user loan params set

    address public feesController;                                                          // address controlling fee withdrawals

    uint256 public lendingFeePercent = 10 ether; // 10% fee                                 // fee taken from lender interest payments
    mapping (address => uint256) public lendingFeeTokensHeld;                               // total interest fees received and not withdrawn per asset
    mapping (address => uint256) public lendingFeeTokensPaid;                               // total interest fees withdraw per asset (lifetime fees = lendingFeeTokensHeld + lendingFeeTokensPaid)

    uint256 public tradingFeePercent = 0.15 ether; // 0.15% fee                             // fee paid for each trade
    mapping (address => uint256) public tradingFeeTokensHeld;                               // total trading fees received and not withdrawn per asset
    mapping (address => uint256) public tradingFeeTokensPaid;                               // total trading fees withdraw per asset (lifetime fees = tradingFeeTokensHeld + tradingFeeTokensPaid)

    uint256 public borrowingFeePercent = 0.09 ether; // 0.09% fee                           // origination fee paid for each loan
    mapping (address => uint256) public borrowingFeeTokensHeld;                             // total borrowing fees received and not withdrawn per asset
    mapping (address => uint256) public borrowingFeeTokensPaid;                             // total borrowing fees withdraw per asset (lifetime fees = borrowingFeeTokensHeld + borrowingFeeTokensPaid)

    uint256 public protocolTokenHeld;                                                       // current protocol token deposit balance
    uint256 public protocolTokenPaid;                                                       // lifetime total payout of protocol token

    uint256 public affiliateFeePercent = 30 ether; // 30% fee share                         // fee share for affiliate program

    mapping (address => mapping (address => uint256)) public liquidationIncentivePercent;   // percent discount on collateral for liquidators per loanToken and collateralToken

    mapping (address => address) public loanPoolToUnderlying;                               // loanPool => underlying
    mapping (address => address) public underlyingToLoanPool;                               // underlying => loanPool
    EnumerableBytes32Set.Bytes32Set internal loanPoolsSet;                                  // loan pools set

    mapping (address => bool) public supportedTokens;                                       // supported tokens for swaps

    uint256 public maxDisagreement = 5 ether;                                               // % disagreement between swap rate and reference rate

    uint256 public sourceBufferPercent = 5 ether;                                           // used to estimate kyber swap source amount

    uint256 public maxSwapSize = 1500 ether;                                                // maximum supported swap size in ETH


    function _setTarget(
        bytes4 sig,
        address target)
        internal
    {
        logicTargets[sig] = target;

        if (target != address(0)) {
            logicTargetsSet.addBytes32(bytes32(sig));
        } else {
            logicTargetsSet.removeBytes32(bytes32(sig));
        }
    }
}

// File: Protocol.sol

contract bZxProtocol is State {

    function()
        external
        payable
    {
        if (gasleft() <= 2300) {
            return;
        }

        address target = logicTargets[msg.sig];
        require(target != address(0), "target not active");

        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(gas, target, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function replaceContract(
        address target)
        external
        onlyOwner
    {
        (bool success,) = target.delegatecall(abi.encodeWithSignature("initialize(address)", target));
        require(success, "setup failed");
    }

    function setTargets(
        string[] calldata sigsArr,
        address[] calldata targetsArr)
        external
        onlyOwner
    {
        require(sigsArr.length == targetsArr.length, "count mismatch");

        for (uint256 i = 0; i < sigsArr.length; i++) {
            _setTarget(bytes4(keccak256(abi.encodePacked(sigsArr[i]))), targetsArr[i]);
        }
    }

    function getTarget(
        string calldata sig)
        external
        view
        returns (address)
    {
        return logicTargets[bytes4(keccak256(abi.encodePacked(sig)))];
    }
}