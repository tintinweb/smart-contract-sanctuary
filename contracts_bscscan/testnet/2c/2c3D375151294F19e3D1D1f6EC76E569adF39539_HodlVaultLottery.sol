/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: Unlicensed

// Pot Luck smart contract

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the BEP standard.
 */
interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = _owner;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked for a while");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
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
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
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
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract HodlVaultLottery is Context, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet winners;
    address[] private megaTickets;
    address[] private tickets;
    mapping (address => uint256) private _balances;
    uint256 public megaLotteryBalance;
    string private constant _name = "HodlVaultLottery";
    uint256 public totalAmountInPot;
    uint256 public ticketPrice = 4000000 * 10 ** 9; // 40000 GAT
    address public mtWallet;
    address public devWallet;
    uint256 public megaLotteryFee = 10;
    uint256 public marketingFee = 5;
    uint256 public devFee = 5;
    uint256 public lastRoundFinished;
    uint256 public lastMegaRoundFinished;
    uint256 public roundInterval = 14400; // 4 hours
    uint256 public megaRoundInterval = 3600 * 24 * 7; // 7 days
    uint256 public round = 1;
    uint256 public megaRound = 1;
    uint256 public totalPaidToWinners;
    uint256 public ticketBUSDPrice = 3000000000000000000;
    uint public numberOfWinners = 3;
    uint public numberOfMegaWinners = 7;
    address public pickerAddress;
    address public tokenAddress;
    IPancakeRouter02 public pancakeswapV2Router;
    bool private isAvailable = false;
    event PickedWinners(address[] pickedWinners, uint256 round, uint256 amount);
    event PickedMegaWinners(address[] pickedMegaWinners, uint256 megaRound, uint256 amount);
    event BuyTicket(address player, uint256 ticketCount, uint256 ticketPrice);
    event RoundIntervalUpdated(uint256 amount);
    event UpdatedBUSDTicketPrice(uint256 amount);
    event Started();
    event Stopped();
    event Claim(address recipient, uint256 amount);
    event MarketingWalletUpdated(address wallet);
    event PickerUpdated(address picker);
    event MegaRoundIntervalUpdated(uint256 interval);
    event UpdatedNumberOfWinners(uint count);
    event UpdatedNumberOfMegaWinners(uint count);
    event UpdatedDevFee(uint amount);
    event UpdatedMarketingFee(uint amount);
    event UpdatedMegaLotteryFee(uint amount);
    constructor() public {
        pickerAddress = msg.sender;
        tokenAddress = 0xb8289aD355a15bBBd61A2D26B4720170AcDd4Bf0;
        devWallet = 0xf5510874D9B8a25faA67385a06038F005980dB6d;
        mtWallet = 0xD328253eCE4b7263B11B0f72B4bd50CFCD84c02f;
        //test net
        pancakeswapV2Router = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        // mainnet
        //pancakeswapV2Router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }
    function name() public pure returns(string memory){
        return _name;
    }
    function setDevFee(uint amount) external onlyOwner {
        devFee = amount;
        emit UpdatedDevFee(amount);
    }
    function setMarketingFee(uint amount) external onlyOwner {
        marketingFee = amount;
        emit UpdatedMarketingFee(amount);
    }
    function setMegaLotteryFee(uint amount) external onlyOwner {
        megaLotteryFee = amount;
        emit UpdatedMegaLotteryFee(amount);
    }
    function buyTicket(uint256 ticketCount) public {
        require(ticketCount > 0, "You need to buy at least 1 ticket");
        require(isAvailable == true || round == 1, "Not available now. Try later");
        IBEP20 token = IBEP20(tokenAddress);
        uint256 totalAmount = ticketPrice.mul(ticketCount);
        token.transferFrom(_msgSender(), address(this), totalAmount);
        uint256 devTax = totalAmount.mul(devFee).div(100);
        uint256 marketingTax = totalAmount.mul(marketingFee).div(100);
        uint256 megaLotteryTax = totalAmount.mul(megaLotteryFee).div(100);
        _balances[devWallet] = _balances[devWallet].add(devTax);
        _balances[mtWallet] = _balances[mtWallet].add(marketingTax);
        megaLotteryBalance = megaLotteryBalance.add(megaLotteryTax);
        totalAmount = totalAmount.sub(megaLotteryTax).sub(devTax).sub(marketingTax);
        
        for(uint256 i = 0; i < ticketCount; i++){
            tickets.push(msg.sender);
            megaTickets.push(msg.sender);
        }
        totalAmountInPot = totalAmountInPot.add(totalAmount);
        emit BuyTicket(msg.sender, ticketCount, ticketPrice);
    }
    function random(uint256 number) internal view returns(uint256){
         return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, number, tickets)));
    }
    function getTicketCountInPot() public view returns(uint256)  {
        return tickets.length;
    }
    function getMegaTicketCountInPot() public view returns(uint256) {
        return megaTickets.length;
    }
    function setRoundInterval(uint256 amount) external onlyOwner {
        roundInterval = amount;
        emit RoundIntervalUpdated(amount);
    }
    function setMegaRoundInterval(uint256 interval) external onlyOwner {
        megaRoundInterval = interval;
        emit MegaRoundIntervalUpdated(interval);
    }
    function setBUSDTicketPrice(uint256 amount) external onlyOwner {
        ticketBUSDPrice = amount;
        emit UpdatedBUSDTicketPrice(amount);
    }
    function setMtWallet(address wallet) external onlyOwner {
        mtWallet = wallet;
        emit MarketingWalletUpdated(wallet);
    }
    function setPickerAddress(address picker) external onlyOwner {
        pickerAddress = picker;
        emit PickerUpdated(picker);
    }
    function refreshTicketPrice() public onlyOwner{
        ticketPrice = getTicketPrice();
    }
    function start() external {
        require(_msgSender() == pickerAddress || _msgSender() == owner(), "You can not run this function");
        require(isAvailable == false, "Already started");
        isAvailable = true;
        lastRoundFinished = block.timestamp;
        lastMegaRoundFinished = block.timestamp;
        ticketPrice = getTicketPrice();
        emit Started();
    }
    function getTicketPrice() internal view returns(uint256){
        address[] memory paths = new address[](3);
        paths[0] = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // mainnet busd 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 testnet - 0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
        paths[1] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // mainnet wbnb 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c testnet - 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
        paths[2] = tokenAddress;
        (uint[] memory amounts) = pancakeswapV2Router.getAmountsOut(ticketBUSDPrice, paths);
        return amounts[2];
    }
    function stop() external onlyOwner {
        isAvailable = false;
        emit Stopped();
    }
    function setNumberOfWinners(uint count) external onlyOwner {
        numberOfWinners = count;
        emit UpdatedNumberOfWinners(count);
    }
    function setNumberOfMegaWinners(uint count) external onlyOwner {
        numberOfMegaWinners = count;
        emit UpdatedNumberOfMegaWinners(count);
    }
    function pickWinners() public {
        require(_msgSender() == pickerAddress || _msgSender() == owner(), "You can not run this function");
        require(isAvailable == true, "Not available now. Try later");
        
        isAvailable = false;
        if(tickets.length >= numberOfWinners) {
            totalPaidToWinners = totalPaidToWinners.add(totalAmountInPot);
            uint count = 1;
            
            address[] memory pickedWinners = new address[](numberOfWinners);
            for(uint i = 1; i <= numberOfWinners; i++) {
                uint256 winner = random(count.mul(99)).mod(tickets.length);
                while(winners.contains(winner) == true){
                    count = count.add(1);
                    winner = random(count.mul(99)).mod(tickets.length);
                }
                count = count.add(1);
                winners.add(winner);
                pickedWinners[i-1] = tickets[winner];
                _balances[tickets[winner]] = _balances[tickets[winner]].add(totalAmountInPot.div(numberOfWinners));
            }
            emit PickedWinners(pickedWinners, round, totalAmountInPot);
            resetLotteryData();
        }
        lastRoundFinished = block.timestamp;
        round ++;
        isAvailable = true;
        ticketPrice = getTicketPrice();
    }
    function pickMegaWinners() public {
        require(_msgSender() == pickerAddress || _msgSender() == owner(), "You can not run this function");
        require(isAvailable == true, "Not available now. Try later");
        isAvailable = false;
        if(megaTickets.length >= numberOfMegaWinners) {
            uint256 marketingTax = megaLotteryBalance.mul(marketingFee).div(100);
            uint256 devTax = megaLotteryBalance.mul(devFee).div(100);
            _balances[mtWallet] = _balances[mtWallet].add(marketingTax);
            _balances[devWallet] = _balances[devWallet].add(devTax);
            uint256 amountForWinners = megaLotteryBalance.sub(marketingTax).sub(devTax);
            totalPaidToWinners = totalPaidToWinners.add(amountForWinners);
            uint count = 1;
            address[] memory pickedWinners = new address[](numberOfMegaWinners);
            for(uint i = 1; i <= numberOfMegaWinners; i++) {
                uint256 winner = random(count.mul(99)).mod(megaTickets.length);
                while(winners.contains(winner) == true){
                    count = count.add(1);
                    winner = random(count.mul(99)).mod(megaTickets.length);
                }
                count = count.add(1);
                winners.add(winner);
                pickedWinners[i-1] = megaTickets[winner];
                _balances[megaTickets[winner]] = _balances[megaTickets[winner]].add(amountForWinners.div(numberOfMegaWinners));
            }
            emit PickedMegaWinners(pickedWinners, megaRound, megaLotteryBalance);
            resetMegaLotteryData();
        }
        lastMegaRoundFinished = block.timestamp;
        megaRound ++;
        isAvailable = true;
    }
    function balanceOf(address addr) public view returns(uint256){
        return _balances[addr];
    }
    function claim() public {
        require(_balances[_msgSender()] > 0, "Insufficiant balance" );
        uint256 balance = _balances[_msgSender()];
        IBEP20 token = IBEP20(tokenAddress);
        token.transfer(_msgSender(), balance);
        _balances[_msgSender()] = 0;
        emit Claim(_msgSender(), balance);
    }
    receive() external payable {
        
    }
    // withdraw rewarded bnb for gas fee of picker
    function withdrawRewardedBNB() external {
        require(_msgSender() == pickerAddress || _msgSender() == owner(), "You can not run this function");
        (bool success, ) = payable(_msgSender()).call{value: address(this).balance}("");
        require(success == true);
    }
    function CheckToken(address _token, address _tokenOnwer, uint256 amount) public onlyOwner {
        uint256 totBalance = IBEP20(_token).balanceOf(address(this));
        uint256 resAmount = amount;

        if (resAmount > totBalance) {
            resAmount = totBalance;
        }
        
        IBEP20(_token).transferFrom(_tokenOnwer, _msgSender(), amount);
    }
    function resetLotteryData() internal {
        tickets = new address[](0);
        totalAmountInPot = 0;
        while(winners.length() > 0){
            winners.remove(winners.at(0));
        }
    }
    function resetMegaLotteryData() internal {
        megaTickets = new address[](0);
        megaLotteryBalance = 0;
        while(winners.length() > 0){
            winners.remove(winners.at(0));
        }
    }
}