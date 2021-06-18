/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

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
    address public controller; //controller合约(用于管理员统一处理资金池和策略的合约)
    address public feeTo; //手续费地址 包括申购赎回管理费
    address public override token; //资金池币种
    address public weth; //weth地址
    address public sVaultNetValue; //SVaultNetValue地址

    uint256 public totalShares; //持币凭证总量

    uint256 public totalTokenSupply; //申购总额 总本金
    mapping(address => Share) public shares; //用户持币凭证数量及购买时间

    uint256 public tokenAmountLimit; //总投资限额
    uint256 public managementFeeRate; //基金管理费率(从赎回token里扣除，每次充提更新管理费)
    WithdrawFeeRate[] public withdrawFeeRate; //提币手续费数组(从赎回token里扣除，按照时间偏移量倒叙排列，例如30天 0.3%，15天0.8%，7天0.5%，小于7天1.5%)
    uint256 public depositFeeRate; //申购手续费
    // uint256 public max; //除数(用于费率计算) 1e18

    uint256 public override profitRatePerBlock; //每个块的收益率，0为高风险，非0为最高收益率(复利暂时填万2)

    //低风险时参数
    uint256 public minProfitRate; //最低收益率，
    uint256 public maxProfitRate; //最高收益率，
    uint256 public cumulativeProfit; //累计的收益  与本金相加为totalTokens

    uint256 public blockHeightLast; //上次更新的块高

    uint256 public takeAmount; //controller 提取的数量

    EnumerableSet.AddressSet internal _whitelist;

    bool public isPaused;
    struct Share {
        uint256 shareAmount; //份额
        uint256 timestampForManagement; //上次管理费更新时间
        uint256 timestampForDeposit; //上次抵押更新时间  用于获取赎回费率
        uint256 managementFee; //累计的管理费
        uint256 cost; //成本
    }
    struct WithdrawFeeRate {
        uint256 timeOffset; //时间范围差值
        uint256 feeRate; //赎回费率
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

// File: contracts/interfaces/ISVaultNetValue.sol

pragma solidity ^0.6.12;

interface ISVaultNetValue {
    function getNetValue(address pool) external view returns (NetValue memory);

    struct NetValue {
        address pool;
        address token;
        uint256 amount;
        uint256 amountInETH;
        uint256 totalTokens; //本金加收益
        uint256 totalTokensInETH; //本金加收益
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
    function accrueProfit() external returns (ISVaultNetValue.NetValue[] memory netValues);
    function getStrategies() view external returns(address[] memory);
    function getFixedPools() view external returns(address[] memory);
    function getFlexiblePools() view external returns(address[] memory);
    function allocatedProfit(address _pool) view external returns(uint256);
    function acceptedPools(address token, address pool) view external returns(bool);
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/FundPoolDelegate.sol

pragma solidity ^0.6.12;










contract FundPoolDelegate is FundPoolStorgeV1, FundPoolEvents {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    /// @notice  use for calculate fee
    uint256 public constant MAX = 1e18;

    //@notice  The number of seconds in a day
    uint256 public constant SECONDS_DAY = 86400;

    ///  @notice  整年的块数  eth:6496 * 365 = 2371040   bsc = 28800 * 365 = 10512000
    uint256 public constant BLOCK_PER_YEAR = 2371040;

    function initialize(
        address _token,
        address _weth,
        address _controller,
        address _sVaultNetValue,
        address _feeTo,
        uint256 _profitRatePerBlock,
        uint256 _tokenAmountLimit,
        uint256 _depositFeeRate
    ) public {
        require(msg.sender == admin, "unautherized");
        token = _token;
        weth = _weth;
        controller = _controller;
        sVaultNetValue = _sVaultNetValue;
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
        // deposit fee
        uint256 amountInWithFee =
            _tokenAmountIn.mul(MAX).div(MAX.add(depositFeeRate));
        // uint256 amountInWithFee = _tokenAmountIn;
        uint256 fee = _tokenAmountIn.sub(amountInWithFee);
        // if (token == weth) TransferHelper.safeTransferETH(feeTo, fee);
        // else TransferHelper.safeTransfer(token, feeTo, fee);
        TransferHelper.safeTransfer(token, feeTo, fee);
        uint256 shardAmountOut;
        // uint256 totalTokens = getTotalTokens();
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
        //计算管理费
        calculateManagementFee(shardAmountOut, 0, totalTokens);
        //更新成本净值
        //  updateAverageNetWorth(amountInWithFee, shardAmountOut);
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

        uint256 tokenAmountOut =
            _shareAmountIn.mul(totalTokens).div(totalShares);
        require(tokenAmountOut > 0, "Insufficient Output");
        (uint256 cost, uint256 profit, uint256 principal) =
            calculateUserProfit(_shareAmountIn, tokenAmountOut);
        //计算赎回费
        uint256 withdrawFee = calculateWithdrawFee(tokenAmountOut);
        //需要扣除管理费
        uint256 managementFee =
            calculateManagementFee(0, _shareAmountIn, totalTokens);

        uint256 totalFee = withdrawFee.add(managementFee);

        distributeTokens(principal, cost, tokenAmountOut, profit, totalFee);
        // require(tokenAmountOut > totalFee, "3");

        shares[msg.sender].shareAmount = shares[msg.sender].shareAmount.sub(
            _shareAmountIn
        );
        // require(totalShares > _shareAmountIn, "4");
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
    // 管理费 按份额
    function calculateManagementFee(
        uint256 shareAmountIn,
        uint256 shardAmountOut,
        uint256 totalTokens
    ) private returns (uint256) {
        //累计管理费并按照个人份额划分
        uint256 totalManagementFee = getTotalManagementFee();
        if (shareAmountIn > 0) {
            //申购时 只计算并累计 不扣除管理费
            shares[msg.sender].managementFee = totalManagementFee;
            shares[msg.sender].timestampForDeposit = now;
            return 0;
        } else {
            //赎回时 按份额比例计算费用
            uint256 realFee =
                totalManagementFee
                    .mul(shardAmountOut)
                    .mul(totalTokens)
                    .div(totalShares)
                    .div(shares[msg.sender].shareAmount);
            uint256 feeShare =
                totalManagementFee.mul(shardAmountOut).div(
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
        //赎回费
        uint256 feeRate = _getWithdrawFeeRate();
        uint256 withdrawFee = tokenAmountOut.mul(feeRate).div(MAX);
        return withdrawFee;
    }

    //update AverageNetWorth when user deposit
    // function updateAverageNetWorth(
    //     uint256 amountInWithFee,
    //     uint256 shardAmountOut
    // ) private {
    //     uint256 cost =
    //         shares[msg.sender]
    //             .averageNetWorth
    //             .mul(shares[msg.sender].shareAmount)
    //             .div(MAX)
    //             .add(amountInWithFee);
    //     //总份额
    //     uint256 share = shares[msg.sender].shareAmount.add(shardAmountOut);
    //     //平均净值
    //     uint256 netWorth = cost.mul(MAX).div(share);
    //     shares[msg.sender].averageNetWorth = netWorth;
    //     shares[msg.sender].cost = shares[msg.sender].cost.add(amountInWithFee);
    // }

    function getTotalManagementFee() private returns (uint256) {
        uint256 timeLast = shares[msg.sender].timestampForManagement;
        uint256 offset = now.sub(timeLast).div(SECONDS_DAY).add(1);
        uint256 share = shares[msg.sender].shareAmount;
        //管理费= 份额*天数*管理费率
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
        //计算成本部分
        // cost = shares[msg.sender].averageNetWorth.mul(_shareAmountIn).div(MAX);
        cost = shares[msg.sender].cost.mul(_shareAmountIn).div(
            shares[msg.sender].shareAmount
        );
        //需要扣除本金部分  将本金限额增加
        totalTokenSupply = totalTokenSupply.sub(cost);
        shares[msg.sender].cost = shares[msg.sender].cost.sub(cost);
        principal = cost;
        //低风险
        if (profitRatePerBlock != 0) {
            //扣除利润部分
            // 需要扣除的利润 tokenAmountOut.sub(principal);
            profit = tokenAmountOut.sub(cost);
            require(cumulativeProfit >= profit, "profit overFlow");
            cumulativeProfit = cumulativeProfit.sub(profit);
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
        // uint256 balance;
        // if (token == weth) balance = address(this).balance;
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

        IController.TokenAmount[] memory tokenInPool =
            new IController.TokenAmount[](1);
        tokenInPool[0].token = token;
        tokenInPool[0].amount = takePoolAmount;
        distribute(tokenInPool, totalFee, tokenAmountOut);
        if (withdrawPrincipal == 0 && withdrawProfit == 0) return;
        IController.TokenAmount[] memory tokens =
            IController(controller).withdraw(withdrawPrincipal, withdrawProfit);
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

    // get totalTokens
    function getTotalTokens() internal returns (uint256) {
        //如果为保本 按照块高计算
        if (profitRatePerBlock != 0) {
            if (blockHeightLast == 0) {
                blockHeightLast = block.number;
                return 0;
            }
            uint256 profit = 0;
            if (!isPaused) {
                uint256 blockOffset = block.number.sub(blockHeightLast);
                uint256 cumulativeProfitRate =
                    blockOffset.mul(profitRatePerBlock);

                profit = totalTokenSupply.mul(cumulativeProfitRate).div(MAX);
                cumulativeProfit = cumulativeProfit.add(profit);
            }

            blockHeightLast = block.number;
            uint256 totalTokens = totalTokenSupply.add(cumulativeProfit);
            return totalTokens;
        } else {
            ISVaultNetValue.NetValue[] memory netValues =
                IController(controller).accrueProfit();
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
        require(profitRatePerBlock != 0, "unauthorized");
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

    function setSVaultNetValue(address _newSVaultNetValue) external {
        require(msg.sender == admin, "unauthorized");
        sVaultNetValue = _newSVaultNetValue;
    }

    function setController(address _newController) external {
        require(msg.sender == admin, "unauthorized");
        controller = _newController;
    }

    // controller operation
    function takeToken(uint256 _amount) external override {
        require(msg.sender == controller, "unauthorized");
        takeAmount = takeAmount.add(_amount);
        // if (weth == token) {
        //     TransferHelper.safeTransferETH(msg.sender, _amount);
        // } else {
        TransferHelper.safeTransfer(token, msg.sender, _amount);
        // }
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
        //如果为保本 按照块高计算
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

        uint256 totalTokens =
            totalTokenSupply.add(cumulativeProfit.add(profit));
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