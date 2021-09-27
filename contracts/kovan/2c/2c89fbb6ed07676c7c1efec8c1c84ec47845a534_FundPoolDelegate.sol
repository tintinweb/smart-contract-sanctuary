/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/interfaces/IFundPool.sol

pragma solidity ^0.6.12;

abstract contract IFundPool {
    function token() external view virtual returns (address);

    function takeToken(uint256 amount) external virtual;

    function getTotalTokensByProfitRate()
        external
        view
        virtual
        returns (
            address,
            uint256,
            uint256
        );

    function profitRatePerBlock() external view virtual returns (uint256);

    function getTokenBalance() external view virtual returns (address, uint256);

    function getTotalTokenSupply()
        external
        view
        virtual
        returns (address, uint256);

    function returnToken(uint256 amount) external virtual;

    function deposit(uint256 amount, string memory channel) external virtual;
    
    function totalShares() external view virtual returns (uint256);
}

// File: contracts/libraries/EnumerableSet.sol

pragma solidity >=0.6.0;

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint256(_at(set._inner, index)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

// File: contracts/FundPoolStorage.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;




contract FundPoolAdminStorage is Ownable {
    address public admin;

    address public implementation;
}

abstract contract FundPoolStorgeV1 is FundPoolAdminStorage, IFundPool {
    address public controller;
    address public feeTo;
    address public override token;
    address public weth;

    uint256 public override totalShares;

    uint256 public totalTokenSupply;
    mapping(address => Share) public shares;

    uint256 public tokenAmountLimit;
    uint256 public managementFeeRate;
    WithdrawFeeRate[] public withdrawFeeRate;
    uint256 public depositFeeRate;

    uint256 public override profitRatePerBlock;

    uint256 public minProfitRate;
    uint256 public maxProfitRate;
    uint256 public cumulativeProfit;

    uint256 public blockHeightLast;

    uint256 public takeAmount;

    EnumerableSet.AddressSet internal _whitelist;

    bool public isPaused;
    struct Share {
        uint256 shareAmount;
        uint256 timestampForManagement;
        uint256 timestampForDeposit;
        uint256 managementFee;
        uint256 cost;
    }
    struct WithdrawFeeRate {
        uint256 timeOffset;
        uint256 feeRate;
    }
}

// File: contracts/FundPoolEvents.sol

pragma solidity ^0.6.12;

contract FundPoolEvents {
    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 shareAmount,
        uint256 fee,
        uint256 totalTokensSupply,
        uint256 totalShares,
        uint256 totalTokens,
        string channel
    );

    event Withdraw(
        address indexed user,
        uint256 shareAmount,
        uint256 amount,
        uint256 withdrawFee,
        uint256 ManagementFee,
        uint256 totalTokensSupply,
        uint256 totalShares,
        uint256 totalTokens,
        uint256 cost
    );

    event TokenAmountLimitChanged(uint256 oldAmount, uint256 newAmount);
    event ManagementFeeRateChanged(uint256 oldFeeRate, uint256 newFeeRate);
    event ProfitRateChanged(uint256 oldProfitRate, uint256 newProfitRate);
    event DepositFeeRateChanged(
        uint256 oldDepositFeeRate,
        uint256 newDepositFeeRate
    );
    event WithdrawFeeRateChanged(uint256 period, uint256 newWithdrawFeeRate);
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IFactory.sol

pragma solidity >=0.5.0;

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// File: contracts/interfaces/IPair.sol

pragma solidity >=0.5.0;

interface IPair {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
}

// File: contracts/PriceView.sol

pragma solidity ^0.6.12;




interface IToken{
    function decimals() view external returns (uint256);
}

contract PriceView {
    using SafeMath for uint256;
    IFactory public factory;
    address public anchorToken;
    address public usdt;
    uint256 constant private one = 1e18;

    constructor(address _anchorToken, address _usdt, IFactory _factory) public {
        anchorToken = _anchorToken;
        usdt = _usdt;
        factory = _factory;
    }

    function getPrice(address token) view external returns (uint256){
        if(token == anchorToken) return one;
        address pair = factory.getPair(token, anchorToken);
        (uint256 reserve0, uint256 reserve1,) = IPair(pair).getReserves();
        (uint256 tokenReserve, uint256 anchorTokenReserve) = token == IPair(pair).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        return one.mul(anchorTokenReserve).div(tokenReserve);
    }

    function getPriceInUSDT(address token) view external returns (uint256){
        uint256 decimals = IToken(token).decimals();
        if(token == usdt) return 10 ** decimals;
        decimals = IToken(anchorToken).decimals();
        uint256 price = 10 ** decimals;
        if(token != anchorToken){
            decimals = IToken(token).decimals();
            address pair = factory.getPair(token, anchorToken);
            (uint256 reserve0, uint256 reserve1,) = IPair(pair).getReserves();
            (uint256 tokenReserve, uint256 anchorTokenReserve) = token == IPair(pair).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
            price = (10 ** decimals).mul(anchorTokenReserve).div(tokenReserve);
        }
        if(anchorToken != usdt){
            address pair = factory.getPair(anchorToken, usdt);
            (uint256 reserve0, uint256 reserve1,) = IPair(pair).getReserves();
            (uint256 anchorTokenReserve, uint256 usdtReserve) = anchorToken == IPair(pair).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
            price = price.mul(usdtReserve).div(anchorTokenReserve);
        }
        return price;
    }
}

// File: contracts/SVaultNetValueStorage.sol

pragma solidity ^0.6.12;



contract AdminStorage is Ownable {
    address public admin;

    address public implementation;
}

contract CommissionPoolStorage is AdminStorage {
    mapping(address => CommissionRate[]) public commissionRatePositive;
    mapping(address => CommissionRate[]) public commissionRateNegative;
    struct CommissionRate {
        uint256 apyScale; //scale by 1e12
        uint256 rate; //scale by 1e6
        bool isAllowance;
    }
    uint256 public commissionAmountInPools;
    mapping(address => uint256) public netValuePershareLast; //scale by 1e18
    uint256 public blockTimestampLast;
    bool public isCommissionPaused;
    uint256 public excessLimitInAmout;
    uint256 public excessLimitInRatio;
}

contract SVaultNetValueStorage is CommissionPoolStorage {
    address public controller;
    PriceView public priceView;
    mapping(address => uint256) public poolWeight;
    uint256 public tokenCount = 1;
    uint256 public poolWeightLimit;
    struct PoolInfo {
        address pool;
        address token;
        uint256 amountInUSD;
        uint256 weight;
        uint256 profitWeight;
        uint256 allocatedProfitInUSD;
        uint256 price;
    }
    struct NetValue {
        address pool;
        address token;
        uint256 amount;
        uint256 amountInUSD;
        uint256 totalTokens;
        uint256 totalTokensInUSD;
    }
    struct TokenPrice {
        address token;
        uint256 price;
    }
}

// File: contracts/interfaces/IController.sol

pragma solidity ^0.6.12;


interface IController {
    struct TokenAmount{
        address token;
        uint256 amount;
    }
    function withdraw(uint256 _amount, uint256 _profitAmount) external returns (TokenAmount[] memory);
    function accrueProfit() external returns (SVaultNetValueStorage.NetValue[] memory netValues);
    function getStrategies() view external returns(address[] memory);
    function getFixedPools() view external returns(address[] memory);
    function getFlexiblePools() view external returns(address[] memory);
    function allocatedProfit(address _pool) view external returns(uint256);
    function acceptedPools(address token, address pool) view external returns(bool);
    function getFixedPoolsLength()view external returns (uint256);
    function getFlexiblePoolsLength() view external returns (uint256);
}

// File: contracts/interfaces/ISVaultNetValue.sol

pragma solidity ^0.6.12;

interface ISVaultNetValue {
    function getNetValue(address pool) external view returns (NetValue memory);

    struct NetValue {
        address pool;
        address token;
        uint256 amount;
        uint256 amountInETH;
        uint256 totalTokens;
        uint256 totalTokensInETH;
    }
 
}

// File: contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File: contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/interfaces/IStrategy.sol

pragma solidity ^0.6.12;

abstract contract IStrategy {
    function earn(address[] memory tokens, uint256[] memory amounts, address[] memory earnTokens, uint256[] memory amountLimits) external virtual;
    function withdraw(address token) external virtual returns (uint256);
    function withdraw(uint256 amount) external virtual returns (address[] memory tokens, uint256[] memory amounts);
    function withdraw(address[] memory tokens, uint256 amount) external virtual returns (uint256, address[] memory, uint256[] memory);
    function withdrawProfit(address token, uint256 amount) external virtual returns (uint256, address[] memory, uint256[] memory);
    function reinvestment(address[] memory pools, address[] memory tokens, uint256[] memory amounts) external virtual;
    function getTokenAmounts() external view virtual returns (address[] memory tokens, uint256[] memory amounts);
    function getTokens() external view virtual returns (address[] memory tokens);
    function getProfitTokens() external view virtual returns (address[] memory tokens);
    function getProfitAmount() view external virtual returns (address[] memory tokens, uint256[] memory amounts, uint256[] memory pendingAmounts);
    function isStrategy() external view virtual returns (bool);
}

// File: contracts/SVaultNetValue.sol

pragma solidity ^0.6.12;





contract SVaultNetValue is SVaultNetValueStorage {
    using SafeMath for uint256;
   //@notice  The number of seconds in a year
    uint256 public constant SECONDS_YEAR = 31536000;

    event PoolWeight(address pool, uint256 weight);

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    function initialize(address _controller, PriceView _priceView) public {
      require(msg.sender == admin, "unautherized");
        controller = _controller;
        priceView = _priceView;
        admin = msg.sender;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "!admin");
        admin = _admin;
    }

    function setPoolWeightLimit (uint256 _poolWeightLimit) public {
        require(msg.sender == admin, "!admin");
        poolWeightLimit = _poolWeightLimit;
    }

    function setPoolWeight(address[] memory pools, uint256[] memory weights) external{
        require(msg.sender == admin, "!admin");
        require(pools.length == weights.length, "Invalid input");
        SVaultNetValue.NetValue[] memory netValues = IController(controller).accrueProfit();
        address[] memory flexiblePools = IController(controller).getFlexiblePools();
        for(uint256 i = 0; i < pools.length; i++){
            require(hasItem(flexiblePools,pools[i]),"Invalid pool");
            require(weights[i] > 0, "Invalid weight");
            poolWeight[pools[i]] = weights[i];
            for(uint j = 0; j < netValues.length; i++){
            if(netValues[j].pool == pools[i])  
              require(netValues[j].amountInUSD.mul(weights[i]) < poolWeightLimit , "overflow");
            }           
            emit PoolWeight(pools[i], weights[i]);
        }
    }

    function removePoolWeight(address pool) external{
        require(msg.sender == admin, "!admin");
        IController(controller).accrueProfit();
        delete poolWeight[pool];
        emit PoolWeight(pool, 0);
    }

    function setTokenCount(uint256 count) external{
        require(msg.sender == admin, "!admin");
        require(count > 0, "Invalid input");
        tokenCount = count;
    }

//    function takeAllowed(IController.ExcessCommission[] memory excessCommission,uint256 commissionAmountInPools,uint256 excessLimitInRatio) public view returns(bool){
//          require(msg.sender == controller, "!controller");
//          uint totalAmount;
//          for(uint256 i = 0; i < excessCommission.length; i++){
//          uint256 price = priceView.getPrice(excessCommission[i].token);
//          totalAmount = totalAmount.add(price.mul(excessCommission[i].amount));
//         }

//         uint256 totalProfit = getProfit();
//         uint excessLimit = totalProfit.mul(excessLimitInRatio).div(1e12);

//         if(totalAmount <= commissionAmountInPools && commissionAmountInPools >= excessLimit && totalAmount <= commissionAmountInPools.sub(excessLimit)) return true;
//         else false;
//    }

    function getNetValue(address pool) view external returns(NetValue memory){
        (NetValue[] memory netValues,)= getNetValuesInView();
        for(uint256 i = 0; i < netValues.length; i++){
            if(netValues[i].pool == pool) return netValues[i];
        }
    }

    function getNetValues() public returns(NetValue[] memory netValues){
       uint256 newCommission;
       (netValues, newCommission)= getNetValuesInView();
        uint256 fixedPoolsLength = IController(controller).getFixedPoolsLength();
        uint256 flexiblePoolsLength = IController(controller).getFlexiblePoolsLength();
    
       for(uint256 i = 0; i < flexiblePoolsLength; i++){
            SVaultNetValue.NetValue memory netValue = netValues[fixedPoolsLength+i];
            uint256 share = IFundPool(netValue.pool).totalShares();
            netValuePershareLast[netValue.pool]= share==0?1e12:netValue.totalTokens.mul(1e12).div(share);
        }
        blockTimestampLast = block.timestamp;
        commissionAmountInPools = newCommission;
    } 
    function getNetValuesInView() view public returns(NetValue[] memory netValues, uint256 newCommission){
        address[] memory fixedPools = IController(controller).getFixedPools();
        address[] memory flexiblePools = IController(controller).getFlexiblePools();         
        TokenPrice[] memory tokenPrices = new TokenPrice[](tokenCount);
        // get all tokens in pool and strategy
        uint256 allTokensInUSD = getAllTokensInUSD(fixedPools, flexiblePools, tokenPrices);
        netValues = new NetValue[](fixedPools.length.add(flexiblePools.length));
        uint256 totalFixedPoolUSD = 0;
        for(uint256 i = 0; i < fixedPools.length; i++){
            netValues[i].pool = fixedPools[i];
            (netValues[i].token, netValues[i].amount, netValues[i].totalTokens) = IFundPool(fixedPools[i]).getTotalTokensByProfitRate();
            uint256 price = getTokenPrice(tokenPrices, netValues[i].token);
            netValues[i].amountInUSD = price.mul(netValues[i].amount);
            netValues[i].totalTokensInUSD = price.mul(netValues[i].totalTokens);
            totalFixedPoolUSD = totalFixedPoolUSD.add(netValues[i].totalTokensInUSD);
        }
        if(allTokensInUSD < totalFixedPoolUSD) return (netValues,commissionAmountInPools);
        allTokensInUSD = allTokensInUSD.sub(totalFixedPoolUSD);
        (PoolInfo[] memory poolInfos, uint256 totalWeight, uint256 totalProfitWeight, uint256 totalAmountInUSD, uint256 totalAllocatedProfitInUSD) = getPoolInfos(flexiblePools, tokenPrices);
        uint256 totalProfitAmountInUSD = 0;
        allTokensInUSD = allTokensInUSD.sub(totalAllocatedProfitInUSD);
        if(allTokensInUSD < totalAmountInUSD){
            totalAmountInUSD = allTokensInUSD;
        }else{
            totalProfitAmountInUSD = allTokensInUSD.sub(totalAmountInUSD);
        }

        for(uint256 i = 0; i < poolInfos.length; i++){
            NetValue memory netValue = netValues[fixedPools.length+i];
            netValue.pool = poolInfos[i].pool;
            netValue.token = poolInfos[i].token;
            netValue.amountInUSD = totalWeight == 0 ? 0 : totalAmountInUSD.mul(poolInfos[i].weight).div(totalWeight);
            uint256 allocatedProfitInUSD = poolInfos[i].allocatedProfitInUSD;
             if(netValue.amountInUSD < poolInfos[i].amountInUSD){
                uint256 lossAmountInUSD = poolInfos[i].amountInUSD.sub(netValue.amountInUSD);
                lossAmountInUSD = lossAmountInUSD > allocatedProfitInUSD ? allocatedProfitInUSD : lossAmountInUSD;
                netValue.amountInUSD = netValue.amountInUSD.add(lossAmountInUSD);
                allocatedProfitInUSD = allocatedProfitInUSD.sub(lossAmountInUSD);
            }
            netValue.totalTokensInUSD = netValue.amountInUSD.add(totalProfitWeight == 0 ? 0 : totalProfitAmountInUSD.mul(poolInfos[i].profitWeight).div(totalProfitWeight)).add(allocatedProfitInUSD);
            netValue.amount =netValue.amountInUSD.div(poolInfos[i].price);
            netValue.totalTokens = netValue.totalTokensInUSD.div(poolInfos[i].price);
        }
        
        //  commision calculalte 
        if(isCommissionPaused)
          (netValues,newCommission) = commissionFixed(fixedPools.length,poolInfos,netValues);
        else newCommission=commissionAmountInPools;
        return (netValues,newCommission);
                 
    }
   function commissionFixed(uint256 fixedPoolLength,PoolInfo[] memory poolInfos,NetValue[] memory netValues)internal view returns(NetValue[] memory,uint256){
       (bool[] memory isPositive,address[] memory pools,uint256[] memory commissions,uint256 newCommission) = calculalteCommission(netValues,fixedPoolLength,poolInfos.length);
         for(uint256 i = 0; i < poolInfos.length; i++){
            NetValue memory netValue = netValues[fixedPoolLength+i];
            for(uint256 j = 0; j < pools.length; j++)
            {
               if( netValue.pool == pools[j]){
                   if(isPositive[j]){
                       netValue.totalTokensInUSD=netValue.totalTokensInUSD.add(commissions[j]);
                       netValue.totalTokens = netValue.totalTokensInUSD.div(poolInfos[i].price);
                   }else{
                       netValue.totalTokensInUSD=netValue.totalTokensInUSD.sub(commissions[j]);
                       netValue.totalTokens = netValue.totalTokensInUSD.div(poolInfos[i].price);
                   }
                } 
            }
         }
         return (netValues,newCommission);
   }
    //get flexible pool weight
    function getPoolInfos(address[] memory flexiblePools, TokenPrice[] memory tokenPrices) view internal returns (PoolInfo[] memory, uint256, uint256, uint256, uint256){
        PoolInfo[] memory poolWeights = new PoolInfo[](flexiblePools.length);
        uint256 totalProfitWeight = 0;
        uint256 totalAmountInUSD = 0;
        uint256 totalAllocatedProfitInUSD = 0;
        uint256 amount = 0;
        for(uint256 i = 0; i < flexiblePools.length; i++){
            poolWeights[i].pool = flexiblePools[i];
            (poolWeights[i].token, amount) = IFundPool(flexiblePools[i]).getTotalTokenSupply();
            poolWeights[i].price = getTokenPrice(tokenPrices, poolWeights[i].token);
            poolWeights[i].amountInUSD = poolWeights[i].price.mul(amount);
            poolWeights[i].weight = poolWeights[i].amountInUSD;
            uint256 profitWeight = poolWeight[poolWeights[i].pool];
            poolWeights[i].profitWeight = poolWeights[i].weight.mul(profitWeight);
            poolWeights[i].allocatedProfitInUSD = IController(controller).allocatedProfit(poolWeights[i].pool).mul(poolWeights[i].price);
            totalAmountInUSD = totalAmountInUSD.add(poolWeights[i].amountInUSD);
            totalProfitWeight = totalProfitWeight.add(poolWeights[i].profitWeight);
            totalAllocatedProfitInUSD = totalAllocatedProfitInUSD.add(poolWeights[i].allocatedProfitInUSD);
        }
        
        return (poolWeights,totalAmountInUSD,totalProfitWeight,totalAmountInUSD,totalAllocatedProfitInUSD);
    }

    function getAllTokensInUSD(address[] memory fixedPools, address[] memory flexiblePools, TokenPrice[] memory tokenPrices) view internal returns(uint256){
        uint256 allTokensInUSD = 0;
        for(uint256 i = 0; i < fixedPools.length; i++){
            (address token, uint256 tokenBalance) = IFundPool(fixedPools[i]).getTokenBalance();
            if(tokenBalance == 0) continue;
            allTokensInUSD = allTokensInUSD.add(getTokenPrice(tokenPrices, token).mul(tokenBalance));
        }
        for(uint256 i = 0; i < flexiblePools.length; i++){
            (address token, uint256 tokenBalance) = IFundPool(flexiblePools[i]).getTokenBalance();
            if(tokenBalance == 0) continue;
            allTokensInUSD = allTokensInUSD.add(getTokenPrice(tokenPrices, token).mul(tokenBalance));
        }
        address[] memory strategies = IController(controller).getStrategies();
        for(uint256 i = 0; i < strategies.length; i++) {
            (address[] memory tokens, uint256[] memory amounts) = IStrategy(strategies[i]).getTokenAmounts();
            for(uint256 j = 0; j < tokens.length; j++){
                if(amounts[j] == 0) continue;
                allTokensInUSD = allTokensInUSD.add(getTokenPrice(tokenPrices, tokens[j]).mul(amounts[j]));
            }
        }
        return allTokensInUSD;
    }

    function getTokenPrice(TokenPrice[] memory tokenPrices, address token) view internal returns (uint256){
        for(uint256 j = 0; j < tokenPrices.length; j++){
            if(tokenPrices[j].token == address(0)){
                tokenPrices[j].token = token;
                tokenPrices[j].price = priceView.getPrice(token);
                return tokenPrices[j].price;
            }else if(token == tokenPrices[j].token){
                return tokenPrices[j].price;
            }
        }
        return priceView.getPrice(token);
    }

    function hasItem(address[] memory _array, address _item) internal pure returns (bool){
        for(uint256 i = 0; i < _array.length; i++){
            if(_array[i] == _item) return true;
        }
        return false;
    }

    function getProfit()view public returns(uint256 totalProfitAmountInUSD){
        NetValue[] memory netValues;
        address[] memory fixedPools = IController(controller).getFixedPools();
        address[] memory flexiblePools = IController(controller).getFlexiblePools();
        uint256 count = fixedPools.length.add(flexiblePools.length);
        TokenPrice[] memory tokenPrices = new TokenPrice[](tokenCount);
        // get all tokens in pool and strategy
        uint256 allTokensInUSD = getAllTokensInUSD(fixedPools, flexiblePools, tokenPrices);
        netValues = new NetValue[](count);
        uint256 totalFixedPoolUSD = 0;
        for(uint256 i = 0; i < fixedPools.length; i++){
            netValues[i].pool = fixedPools[i];
            (netValues[i].token, netValues[i].amount, netValues[i].totalTokens) = IFundPool(fixedPools[i]).getTotalTokensByProfitRate();
            uint256 price = getTokenPrice(tokenPrices, netValues[i].token);
            netValues[i].amountInUSD = price.mul(netValues[i].amount);
            netValues[i].totalTokensInUSD = price.mul(netValues[i].totalTokens);
            totalFixedPoolUSD = totalFixedPoolUSD.add(netValues[i].totalTokensInUSD);
        }
        if(allTokensInUSD < totalFixedPoolUSD) return 0;
        allTokensInUSD = allTokensInUSD.sub(totalFixedPoolUSD);
        (PoolInfo[] memory poolInfos, uint256 totalWeight, uint256 totalProfitWeight, uint256 totalAmountInUSD, uint256 totalAllocatedProfitInUSD) = getPoolInfos(flexiblePools, tokenPrices);
        allTokensInUSD = allTokensInUSD.sub(totalAllocatedProfitInUSD);
        if(allTokensInUSD < totalAmountInUSD){
            totalAmountInUSD = allTokensInUSD;
        }else{
            totalProfitAmountInUSD = allTokensInUSD.sub(totalAmountInUSD);
        }
    }


    // commision pool function
    
    function setCommissionPause(bool _isPaused) external onlyAdmin{
           if(_isPaused)
           {
               getNetValues();
               isCommissionPaused = true;
           }
           else{
               isCommissionPaused = false;
           } 
    }

    function getApys(SVaultNetValue.NetValue[] memory netValues,uint256 fixedPoolsLength,uint256 flexiblePoolsLength) internal view returns( bool[] memory isPositive,address[] memory pools,uint256[] memory apys,uint256[] memory amountInUSD){        
        uint256 timeElapsed = block.timestamp.sub(blockTimestampLast);
        for(uint256 i = 0; i < flexiblePoolsLength; i++){
            SVaultNetValue.NetValue memory netValue = netValues[fixedPoolsLength+i];
            uint256 share = IFundPool(netValue.pool).totalShares();
            uint256 netValuePershare = netValue.totalTokens.mul(1e12).div(share);
            uint256 netValuePershareLast = netValuePershareLast[netValue.pool];
            pools[i]= netValue.pool;
            if(netValuePershare >= netValuePershareLast){
                 uint256 apy = netValuePershare.sub(netValuePershareLast).mul(1e6).mul(SECONDS_YEAR).div(timeElapsed).div(netValuePershareLast);  
                 isPositive[i]=true; 
                 apys[i]= apy;
                 amountInUSD[i]= netValue.amountInUSD;
            }
            else {
                 uint256 apy = netValuePershareLast.sub(netValuePershare).mul(1e6).mul(SECONDS_YEAR).div(timeElapsed).div(netValuePershareLast);      
                 isPositive[i]=false; 
                 apys[i]= apy;
                 amountInUSD[i]= netValue.amountInUSD; 
            }  
        }
    }
    function SetCommissionRate( address pool,
        CommissionRate[] memory _commissionRatePositive,
        CommissionRate[] memory _commissionRateNegative
    ) public onlyAdmin {
        delete commissionRatePositive[pool];     
        for (uint256 i = 0; i < _commissionRatePositive.length; i++) {
            CommissionRate memory c = _commissionRatePositive[i];
            commissionRatePositive[pool].push(c);         
        }
        delete commissionRatePositive[pool];
        for (uint256 i = 0; i < _commissionRateNegative.length; i++) {
            CommissionRate memory c = _commissionRateNegative[i];
            commissionRateNegative[pool].push(c);
        }
    }

    function setExcessLimitInRatio(uint256 _excessLimitInRatio) public onlyAdmin{
        excessLimitInRatio = _excessLimitInRatio;
    }
    
    function calculalteCommission(SVaultNetValue.NetValue[] memory netValues,uint256 fixedPoolsLength,uint256 flexiblePoolsLength) public view 
             returns(bool[] memory, address[] memory, uint256[] memory commissions, uint256 newCommission){
      (bool[] memory isPositive,address[] memory pools,uint256[] memory apys,uint256[] memory amountInUSD) = getApys(netValues,fixedPoolsLength,flexiblePoolsLength);   
      uint256 totalProfit;
      uint256 totalAllowance; 
       for(uint256 i = 0; i < pools.length; i++){
        (bool isAllowance, uint256 accCommision) = culculate(apys[i],isPositive[i],commissionRateNegative[pools[i]],commissionRateNegative[pools[i]],amountInUSD[i]);
            if(isAllowance) 
                     totalAllowance = totalAllowance.add(accCommision);
                else totalProfit = totalProfit.add(accCommision);
       }
       uint256 availableAllowance = totalProfit.add(commissionAmountInPools);
       if (totalAllowance > availableAllowance) {
           for(uint256 i = 0; i < isPositive.length; i++){          
             if(!isPositive[i]){
               commissions[i]=commissions[i].mul(availableAllowance).div(totalAllowance);
               }
            }
            totalAllowance = availableAllowance;
        }
       newCommission = commissionAmountInPools.add(totalProfit).sub(totalAllowance);
       return (isPositive, pools, commissions, newCommission);
    }

   function culculate(uint256 apy,bool isPositive,CommissionRate[] storage cp,CommissionRate[] storage cn,uint256 amountInUSD) internal view returns (bool,uint256){ 
           require(cp.length > 0 && cn.length > 0, "commissionRate unset");
           uint256 accCommision;
          (bool isAllowance,uint256 gear) = sort(cp,cn,apy,isPositive);
           if(isPositive){
                for(uint256 j = gear; j < cp.length; j++){   
                    uint256 commision;   
                    if(isAllowance == cp[j].isAllowance){
                    uint256 minuendApy = j == gear ? apy : cp[j-1].apyScale;
                    uint256 apyScale = minuendApy.sub(cp[j].apyScale);
                    commision= amountInUSD.mul(apyScale).mul(cp[j].rate).div(1e12);
                    accCommision = accCommision.add(commision);  
                    }    
                    
                }   
            }                  
            else{
                for(uint256 j = gear; j < cn.length; j++){
                    uint256 commision;            
                    uint256 minuendApy = j == gear ? apy : cn[j-1].apyScale;
                     uint256 apyScale = minuendApy.sub(cp[j].apyScale);
                    commision = amountInUSD.mul(apyScale).mul(cn[j].rate).div(1e12); 
                    accCommision = accCommision.add(commision);             
                }
            }         
           return(isAllowance,accCommision);

   }


    function sort(CommissionRate[] storage cp,CommissionRate[] storage cn,uint256 apy,bool isPositive)internal view returns(bool isAllowance, uint256 gear){
        if(isPositive){
            for(uint256 j = 0; j < cp.length; j++){
             if(apy > cp[j].apyScale){
               isAllowance=cp[j].isAllowance;
               gear = j; 
               break;
               }
            }
        }
        else {
            for(uint256 j = 0; j < cn.length; j++){
             if(apy > cn[j].apyScale){
               isAllowance=cn[j].isAllowance;
               gear = j; 
               break;
               }
            }
        }    
    }
    // function takeCommission(IController.ExcessCommission[] memory excessCommission) public{
    //       bool allowed =  SVaultNetValue(sVaultNetValue).takeAllowed(excessCommission, commissionAmountInPools, excessLimitInRatio);
    //       if(allowed){
    //             for(uint256 i = 0; i < excessCommission.length; i++){
    //               withdrawCommision(excessCommission[i].token, excessCommission[i].amount);
    //           }
    //       }
    // }

    //  function withdrawCommision( address token,uint256 _amount) onlyStrategistAndOwner internal returns (TokenAmount[] memory) {
    //     require(acceptedPools[token][msg.sender], "Invalid pool");
    //     WithdrawSetting[] memory settings = withdrawSettingInfos[msg.sender].withdrawSettings;
    //     require(settings.length > 0, "Withdraw setting should be set");
    //     uint256 length = settings[0].tokenLimit.length;
    //     uint256 totalAmount = _amount;
    //     uint256 count = withdrawSettingInfos[msg.sender].tokens.length;
    //     address[] memory tokens = new address[](1);
    //     tokens[0] = token;
    //     TokenAmount[] memory tokenAmounts = new TokenAmount[](count);
    //     for (uint256 i = 0; i <= length; i++) {
    //         if(totalAmount == 0) break;
    //         for (uint256 j = 0; j < settings.length; j++) {
    //             uint256 withdrawAmount = i == length || totalAmount <= settings[j].tokenLimit[i]? totalAmount : settings[j].tokenLimit[i];
    //             if(withdrawAmount == 0) continue;
    //             (uint256 amount, address[] memory withdrawTokens, uint256[] memory amounts) = IStrategy(settings[j].strategy).withdraw(tokens, withdrawAmount);
    //             if(amount > 0 ) {
    //                 totalAmount = totalAmount.sub(amount);
    //                 emit Withdraw(settings[j].strategy, msg.sender, tokens[0], amount);
    //             }
    //             AddTokenAmount(tokenAmounts, withdrawTokens, amounts);
    //             if(totalAmount == 0) break;
    //         }
    //     }
    //     if(totalAmount > 0){
    //         for (uint256 j = 0; j < settings.length; j++) {
    //             tokens = IStrategy(settings[j].strategy).getTokens();
    //             if(tokens.length == 1 || !hasItem(tokens, token)) continue;
    //             (tokens[0], tokens[1]) = token == tokens[0] ? (tokens[0], tokens[1]) : (tokens[1], tokens[0]);
    //             (uint256 amount,address[] memory withdrawTokens, uint256[] memory amounts) = IStrategy(settings[j].strategy).withdraw(tokens, totalAmount);
    //             if(amount > 0 ) {
    //                 totalAmount = totalAmount.sub(amount);
    //                 emit Withdraw(settings[j].strategy, msg.sender, tokens[0], amount);
    //             }
    //             AddTokenAmount(tokenAmounts, withdrawTokens, amounts);
    //             if(totalAmount == 0) break;
    //         }

    //         for (uint256 j = 0; j < settings.length; j++) {
    //             if(totalAmount == 0) break;
    //             (uint256 amount,address[] memory withdrawTokens, uint256[] memory amounts) = IStrategy(settings[j].strategy).withdrawProfit(token, totalAmount);
    //             if(amount > 0 ) {
    //                 totalAmount = totalAmount.sub(amount);
    //                 emit Withdraw(settings[j].strategy, msg.sender, tokens[0], amount);
    //             }
    //             AddTokenAmount(tokenAmounts, withdrawTokens, amounts);
    //         }
    //     }
    //     require(totalAmount == 0 , "Insufficient balance");
    //     for(uint256 i = 0; i < tokenAmounts.length; i++){
    //         if(tokenAmounts[i].token == address(0) || tokenAmounts[i].amount == 0) continue;
    //         transferOut(tokenAmounts[i].token, msg.sender, tokenAmounts[i].amount);
    //     }
    //     return tokenAmounts;
    // }
}

// File: contracts/FundPoolDelegate.sol

pragma solidity ^0.6.12;











contract FundPoolDelegate is FundPoolStorgeV1, FundPoolEvents {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    /// @notice  use for calculate fee
    uint256 public constant MAX = 1e18;

    //@notice  The number of seconds in a day
    uint256 public constant SECONDS_DAY = 86400;

    ///  @notice    eth:6496 * 365 = 2371040   bsc = 28800 * 365 = 10512000
    uint256 public constant BLOCK_PER_YEAR = 2371040;

    function initialize(
        address _token,
        address _weth,
        address _controller,
        address _feeTo,
        uint256 _profitRatePerBlock,
        uint256 _tokenAmountLimit,
        uint256 _depositFeeRate
    ) public {
        require(msg.sender == admin, "unautherized");
        token = _token;
        weth = _weth;
        controller = _controller;
        feeTo = _feeTo;
        profitRatePerBlock = _profitRatePerBlock;
        tokenAmountLimit = _tokenAmountLimit;
        depositFeeRate = _depositFeeRate;
    }

    function deposit(uint256 _tokenAmountIn, string memory _channel)
        external
        override
    {
        require(token != weth, "Invalid token");
        require(_tokenAmountIn > 0, "Insufficient Token");
        require(!isPaused, "deposit paused");
        require(whitelistCheck(), "not in the whitelist");
        uint256 totalTokens = getTotalTokens();
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            _tokenAmountIn
        );
        _deposit(_tokenAmountIn, totalTokens, _channel);
    }

    function depositETH(string memory _channel) external payable {
        require(token == weth, "Invalid token");
        require(msg.value > 0, "Insufficient Token");
        require(!isPaused, "deposit paused");
        require(whitelistCheck(), "not in the whitelist");
        uint256 totalTokens = getTotalTokens();
        IWETH(weth).deposit{value: msg.value}();
        _deposit(msg.value, totalTokens, _channel);
    }

    function _deposit(
        uint256 _tokenAmountIn,
        uint256 totalTokens,
        string memory _channel
    ) private {
        uint256 amountInWithFee = _tokenAmountIn.mul(MAX).div(
            MAX.add(depositFeeRate)
        );
        uint256 fee = _tokenAmountIn.sub(amountInWithFee);
        TransferHelper.safeTransfer(token, feeTo, fee);
        uint256 shardAmountOut;
        if (totalShares == 0) {
            shardAmountOut = amountInWithFee;
        } else {
            shardAmountOut = amountInWithFee.mul(totalShares).div(totalTokens);
        }
        totalTokenSupply = totalTokenSupply.add(amountInWithFee);
        require(
            totalTokenSupply <= tokenAmountLimit,
            "overflow the token limit"
        );

        calculateManagementFee(shardAmountOut, 0, totalTokens);

        shares[msg.sender].cost = shares[msg.sender].cost.add(amountInWithFee);
        shares[msg.sender].shareAmount = shares[msg.sender].shareAmount.add(
            shardAmountOut
        );
        totalShares = totalShares.add(shardAmountOut);
        emit Deposit(
            msg.sender,
            _tokenAmountIn,
            shardAmountOut,
            fee,
            totalTokenSupply,
            totalShares,
            totalTokens,
            _channel
        );
    }

    function withdraw(uint256 _shareAmountIn) external {
        require(_shareAmountIn > 0, "Insufficient Input");
        require(
            _shareAmountIn <= shares[msg.sender].shareAmount,
            "Insufficient Input"
        );
        uint256 totalTokens = getTotalTokens();
        uint256 tokenAmountOut = _shareAmountIn.mul(totalTokens).div(
            totalShares
        );
        require(tokenAmountOut > 0, "Insufficient Output");
        (uint256 cost, uint256 profit, uint256 principal) = calculateUserProfit(
            _shareAmountIn,
            tokenAmountOut
        );
        uint256 withdrawFee = calculateWithdrawFee(tokenAmountOut);
        uint256 managementFee = calculateManagementFee(
            0,
            _shareAmountIn,
            totalTokens
        );
        uint256 totalFee = withdrawFee.add(managementFee);
        distributeTokens(principal, cost, tokenAmountOut, profit, totalFee);

        shares[msg.sender].shareAmount = shares[msg.sender].shareAmount.sub(
            _shareAmountIn
        );
        totalShares = totalShares.sub(_shareAmountIn);

        emit Withdraw(
            msg.sender,
            _shareAmountIn,
            tokenAmountOut.sub(totalFee),
            withdrawFee,
            managementFee,
            totalTokenSupply,
            totalShares,
            totalTokens,
            cost
        );
    }

    // private function
    function calculateManagementFee(
        uint256 shareAmountIn,
        uint256 shardAmountOut,
        uint256 totalTokens
    ) private returns (uint256) {
        uint256 totalManagementFee = getTotalManagementFee();
        if (shareAmountIn > 0) {
            shares[msg.sender].managementFee = totalManagementFee;
            shares[msg.sender].timestampForDeposit = now;
            return 0;
        } else {
            uint256 realFee = totalManagementFee
            .mul(shardAmountOut)
            .mul(totalTokens)
            .div(totalShares)
            .div(shares[msg.sender].shareAmount);
            uint256 feeShare = totalManagementFee.mul(shardAmountOut).div(
                shares[msg.sender].shareAmount
            );
            shares[msg.sender].managementFee = totalManagementFee.sub(feeShare);

            return realFee;
        }
    }

    function calculateWithdrawFee(uint256 tokenAmountOut)
        private
        view
        returns (uint256)
    {
        uint256 feeRate = _getWithdrawFeeRate();
        uint256 withdrawFee = tokenAmountOut.mul(feeRate).div(MAX);
        return withdrawFee;
    }

    function getTotalManagementFee() private returns (uint256) {
        uint256 timeLast = shares[msg.sender].timestampForManagement;
        uint256 offset = now.sub(timeLast).div(SECONDS_DAY).add(1);
        uint256 share = shares[msg.sender].shareAmount;
        uint256 fee = share.mul(offset).mul(managementFeeRate).div(MAX);
        uint256 managementFeeLast = shares[msg.sender].managementFee;
        uint256 totalManagementFee = managementFeeLast.add(fee);
        shares[msg.sender].timestampForManagement = now;
        return totalManagementFee;
    }

    function _getWithdrawFeeRate() private view returns (uint256 _feeRate) {
        uint256 timeLast = shares[msg.sender].timestampForDeposit;
        require(withdrawFeeRate.length > 0, "WithdrawFeeRate should be set");
        uint256 offset = now.sub(timeLast).div(SECONDS_DAY).add(1);
        for (uint256 i = 0; i < withdrawFeeRate.length; i++) {
            if (offset >= withdrawFeeRate[i].timeOffset) {
                _feeRate = withdrawFeeRate[i].feeRate;
            }
        }
    }

    function calculateUserProfit(uint256 _shareAmountIn, uint256 tokenAmountOut)
        private
        returns (
            uint256 cost,
            uint256 profit,
            uint256 principal
        )
    {
        cost = shares[msg.sender].cost.mul(_shareAmountIn).div(
            shares[msg.sender].shareAmount
        );

        totalTokenSupply = totalTokenSupply.sub(cost);
        shares[msg.sender].cost = shares[msg.sender].cost.sub(cost);
        principal = cost;

        if (profitRatePerBlock != 0) {
            profit = tokenAmountOut.sub(cost);
            cumulativeProfit = cumulativeProfit.sub(profit, "profit overFlow");
            return (cost, profit, principal);
        } else {
            profit = tokenAmountOut <= principal
                ? 0
                : tokenAmountOut.sub(principal);
            principal = tokenAmountOut <= cost ? tokenAmountOut : cost;
            return (cost, profit, principal);
        }
    }

    function distributeTokens(
        uint256 principal,
        uint256 cost,
        uint256 tokenAmountOut,
        uint256 profit,
        uint256 totalFee
    ) private {
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 takePoolAmount;
        uint256 withdrawPrincipal;
        uint256 withdrawProfit;

        if (balance >= principal) {
            takePoolAmount = principal;
            withdrawPrincipal = 0;
            withdrawProfit = profit;
        } else {
            takePoolAmount = balance;
            withdrawPrincipal = principal.sub(balance);
            withdrawProfit = profit;
            uint256 withdrawCost = withdrawPrincipal.mul(cost).div(principal);
            takeAmount = takeAmount.sub(withdrawCost);
        }

            IController.TokenAmount[] memory tokenInPool
         = new IController.TokenAmount[](1);
        tokenInPool[0].token = token;
        tokenInPool[0].amount = takePoolAmount;
        distribute(tokenInPool, totalFee, tokenAmountOut);
        if (withdrawPrincipal == 0 && withdrawProfit == 0) return;
        IController.TokenAmount[] memory tokens = IController(controller)
        .withdraw(withdrawPrincipal, withdrawProfit);
        distribute(tokens, totalFee, tokenAmountOut);
    }

    // distribute tokens when user withdraw
    function distribute(
        IController.TokenAmount[] memory tokens,
        uint256 totalFee,
        uint256 tokenAmountOut
    ) private returns (uint256) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].amount == 0 || tokens[i].token == address(0))
                continue;
            uint256 fee = tokens[i].amount.mul(totalFee).div(tokenAmountOut);
            uint256 withdrawAmount = tokens[i].amount.sub(fee);
            address token = tokens[i].token;
            if (token == weth) {
                IWETH(weth).withdraw(tokens[i].amount);
                TransferHelper.safeTransferETH(feeTo, fee);
                TransferHelper.safeTransferETH(msg.sender, withdrawAmount);
            } else {
                TransferHelper.safeTransfer(token, feeTo, fee);
                TransferHelper.safeTransfer(token, msg.sender, withdrawAmount);
            }
        }
    }

    function getTotalTokens() internal returns (uint256) {
        if (profitRatePerBlock != 0) {
            if (blockHeightLast == 0) {
                blockHeightLast = block.number;
                return 0;
            }
            uint256 profit = 0;
            if (!isPaused) {
                uint256 blockOffset = block.number.sub(blockHeightLast);
                uint256 cumulativeProfitRate = blockOffset.mul(
                    profitRatePerBlock
                );

                profit = totalTokenSupply.mul(cumulativeProfitRate).div(MAX);
                cumulativeProfit = cumulativeProfit.add(profit);
            }

            blockHeightLast = block.number;
            uint256 totalTokens = totalTokenSupply.add(cumulativeProfit);
            return totalTokens;
        } else {
            SVaultNetValue.NetValue[] memory netValues = IController(
                controller
            ).accrueProfit();
            for (uint256 i = 0; i < netValues.length; i++) {
                if (netValues[i].pool == address(this))
                    return netValues[i].totalTokens;
            }
        }
    }

    //admin operation
    function setManagementFeeRate(uint256 _newFeeRate) external {
        require(msg.sender == admin, "unauthorized");
        uint256 oldFeeRate = managementFeeRate;
        managementFeeRate = _newFeeRate;
        emit ManagementFeeRateChanged(oldFeeRate, _newFeeRate);
    }

    function setWithdrawFeeRate(WithdrawFeeRate[] memory _withdrawFeeRates)
        external
    {
        require(msg.sender == admin, "unauthorized");
        uint256 length = withdrawFeeRate.length;
        for (uint256 i = 0; i < length; i++) {
            withdrawFeeRate.pop();
        }
        for (uint256 i = 0; i < _withdrawFeeRates.length; i++) {
            WithdrawFeeRate memory w = _withdrawFeeRates[i];
            withdrawFeeRate.push(w);
            emit WithdrawFeeRateChanged(w.timeOffset, w.feeRate);
        }
    }

    function setDepositFeeRate(uint256 _newFeeRate) external {
        require(msg.sender == admin, "unauthorized");
        uint256 oldDepositFeeRate = depositFeeRate;
        depositFeeRate = _newFeeRate;
        emit DepositFeeRateChanged(oldDepositFeeRate, _newFeeRate);
    }

    function setProfitRateRange(uint256 _minProfitRate, uint256 _maxProfitRate)
        external
    {
        require(msg.sender == admin, "unauthorized");
        minProfitRate = _minProfitRate;
        maxProfitRate = _maxProfitRate;
    }

    function setProfitRatePerBlock(uint256 _profitRatePerBlock) external {
        require(msg.sender == admin, "unauthorized");
        require(profitRatePerBlock != 0, "Invalid input");
        uint256 newProfitRate = _profitRatePerBlock.mul(BLOCK_PER_YEAR);
        require(newProfitRate > minProfitRate, "Invalid input");
        require(newProfitRate <= maxProfitRate, "Invalid input");
        getTotalTokens();
        uint256 oldProfitRate = profitRatePerBlock.mul(BLOCK_PER_YEAR);
        profitRatePerBlock = _profitRatePerBlock;
        emit ProfitRateChanged(oldProfitRate, newProfitRate);
    }

    function setFeeto(address _newFeeto) external {
        require(msg.sender == admin, "unauthorized");
        feeTo = _newFeeto;
    }

    function setTokenAmountLimit(uint256 _newTokenAmountLimit) external {
        require(msg.sender == admin, "unauthorized");
        uint256 oldTokenAmountLimit = tokenAmountLimit;
        tokenAmountLimit = _newTokenAmountLimit;
        emit TokenAmountLimitChanged(oldTokenAmountLimit, _newTokenAmountLimit);
    }

    function setController(address _newController) external {
        require(msg.sender == admin, "unauthorized");
        controller = _newController;
    }

    // controller operation
    function takeToken(uint256 _amount) external override {
        require(msg.sender == controller, "unauthorized");
        takeAmount = takeAmount.add(_amount);

        TransferHelper.safeTransfer(token, msg.sender, _amount);
    }

    function returnToken(uint256 amount) external override {
        require(msg.sender == controller, "unauthorized");
        takeAmount = takeAmount.sub(amount);
    }

    //view function
    function getTokenBalance()
        external
        view
        override
        returns (address, uint256)
    {
        return (token, IERC20(token).balanceOf(address(this)));
    }

    function getTotalTokenSupply()
        external
        view
        override
        returns (address, uint256)
    {
        return (token, totalTokenSupply);
    }

    function getTotalTokensByProfitRate()
        public
        view
        override
        returns (
            address,
            uint256,
            uint256
        )
    {
        require(profitRatePerBlock != 0, "Invalid profitRatePerBlock");
        if (blockHeightLast == 0) {
            return (token, totalTokenSupply, 0);
        }
        uint256 profit = 0;
        if (!isPaused) {
            uint256 blockOffset = block.number.sub(blockHeightLast);
            uint256 cumulativeProfitRate = blockOffset.mul(profitRatePerBlock);

            profit = totalTokenSupply.mul(cumulativeProfitRate).div(MAX);
        }

        uint256 totalTokens = totalTokenSupply.add(
            cumulativeProfit.add(profit)
        );
        return (token, totalTokenSupply, totalTokens);
    }

    function getWithdrawFeeRate()
        public
        view
        returns (WithdrawFeeRate[] memory)
    {
        return withdrawFeeRate;
    }

    // whitelist  operation
    function addWhiteAddress(address _contractAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(_contractAddress != address(0), "invalid address");
        return EnumerableSet.add(_whitelist, _contractAddress);
    }

    function delWhiteAddress(address _contractAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(_contractAddress != address(0), "invalid address");
        return EnumerableSet.remove(_whitelist, _contractAddress);
    }

    function getWhitelistLength() public view returns (uint256) {
        return EnumerableSet.length(_whitelist);
    }

    function isWhiteAddress(address _contractAddress)
        public
        view
        returns (bool)
    {
        return EnumerableSet.contains(_whitelist, _contractAddress);
    }

    function getWhiteAddress(uint256 _index)
        public
        view
        onlyOwner
        returns (address)
    {
        require(_index <= getWhitelistLength() - 1, "index out of bounds");
        return EnumerableSet.at(_whitelist, _index);
    }

    function whitelistCheck() private view returns (bool) {
        if (msg.sender != tx.origin) {
            return isWhiteAddress(msg.sender);
        }
        return true;
    }

    //deposit pause    only withdraw（stop the profit in low risk）
    function setPause(bool _isPaused) external {
        require(msg.sender == admin, "unauthorized");
        getTotalTokens();
        isPaused = _isPaused;
    }
}