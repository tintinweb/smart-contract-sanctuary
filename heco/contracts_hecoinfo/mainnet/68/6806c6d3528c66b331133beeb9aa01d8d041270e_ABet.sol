/**
 *Submitted for verification at hecoinfo.com on 2022-05-17
*/

pragma solidity >=0.6.0 <0.9.0;

// interface Token {
//   function balanceOf(address _owner) public returns (uint256 );
//   function transfer(address _to, uint256 _value) public ;
//   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
// }


contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call1");
    }
}

// File: openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

// File: openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol


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

// File: openzeppelin-solidity-2.3.0/contracts/token/ERC20/IERC20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity-2.3.0/contracts/token/ERC20/ERC20.sol




/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: openzeppelin-solidity-2.3.0/contracts/math/Math.sol


/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/SafeToken.sol


interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    // function safeTransferETH(address to, uint256 value) internal {
    //     (bool success, ) = to.call.value(value)(new bytes(0));
    //     require(success, "!safeTransferETH");
    // }
}

// File: contracts/PToken.sol







contract PToken is ERC20, Ownable {
    using SafeToken for address;
    using SafeMath for uint256;

    string public name = "";
    string public symbol = "";
    uint8 public decimals = 18;

    event Mint(address sender, address account, uint amount);
    event Burn(address sender, address account, uint amount);

    constructor(string memory _symbol) public {
        name = _symbol;
        symbol = _symbol;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
        emit Mint(msg.sender, account, amount);
    }

    function burn(address account, uint256 value) public onlyOwner {
        _burn(account, value);
        emit Burn(msg.sender, account, value);
    }
}

// File: contracts/PTokenFactory.sol


contract PTokenFactory {

    function genPToken(string memory _symbol) public returns(address) {
        return address(new PToken(_symbol));
    }
}






/**
 * @dev Collection of functions related to the address type,
 */
// library Address {
//     /**
//      * @dev Returns true if `account` is a contract.
//      *
//      * This test is non-exhaustive, and there may be false-negatives: during the
//      * execution of a contract's constructor, its address will be reported as
//      * not containing a contract.
//      *
//      * > It is unsafe to assume that an address for which this function returns
//      * false is an externally-owned account (EOA) and not a contract.
//      */
//     function isContract(address account) internal view returns (bool) {
//         // This method relies in extcodesize, which returns 0 for contracts in
//         // construction, since the code is only stored at the end of the
//         // constructor execution.

//         uint256 size;
//         // solhint-disable-next-line no-inline-assembly
//         assembly { size := extcodesize(account) }
//         return size > 0;
//     }
// }

// /**
//  * @title SafeERC20
//  * @dev Wrappers around ERC20 operations that throw on failure (when the token
//  * contract returns false). Tokens that return no value (and instead revert or
//  * throw on failure) are also supported, non-reverting calls are assumed to be
//  * successful.
//  * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
//  * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
//  */
// library SafeERC20 {
//     using SafeMath for uint256;
//     using Address for address;

//     function safeTransfer(IERC20 token, address to, uint256 value) internal {
//         callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
//     }

//     function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
//         callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
//     }

//     function safeApprove(IERC20 token, address spender, uint256 value) internal {
//         // safeApprove should only be called when setting an initial allowance,
//         // or when resetting it to zero. To increase and decrease it, use
//         // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
//         // solhint-disable-next-line max-line-length
//         require((value == 0) || (token.allowance(address(this), spender) == 0),
//             "SafeERC20: approve from non-zero to non-zero allowance"
//         );
//         callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
//     }

//     function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).add(value);
//         callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).sub(value);
//         callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     /**
//      * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
//      * on the return value: the return value is optional (but if data is returned, it must not be false).
//      * @param token The token targeted by the call.
//      * @param data The call data (encoded using abi.encode or one of its variants).
//      */
//     function callOptionalReturn(IERC20 token, bytes memory data) private {
//         // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
//         // we're implementing it ourselves.

//         // A Solidity high level call has three parts:
//         //  1. The target address is checked to verify it contains contract code
//         //  2. The call itself is made, and success asserted
//         //  3. The return value is decoded, which in turn checks the size of the returned data.
//         // solhint-disable-next-line max-line-length
//         require(address(token).isContract(), "SafeERC20: call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = address(token).call(data);
//         require(success, "SafeERC20: low-level call failed");

//         if (returndata.length > 0) { // Return data is optional
//             // solhint-disable-next-line max-line-length
//             require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
//         }
//     }
// }

// contract AStakingRewards is ReentrancyGuard, Ownable{
//     /* conifg */
//     IERC20 public rewardsToken = IERC20(address(0xa87E9c5Fc509F9eaF538A8c11EeeeA98c4C548f4)); // hfil
//     address public capitalAddress;
//     uint256 public stakeRatio = 50; // %
//     uint256 public voteRedeemRatio = 60; // % 可配置 

//     using SafeMath for uint256;
//     using SafeERC20 for IERC20;
//     using Address for address;
    
//     event Staked(address indexed user, uint256 amount);
//     event Redeem(address indexed user, uint256 amount);
    
//     event GetReward(address indexed user, uint256 reward);
//     event NodeReward(uint256 reward);
//     event PoolReward(address indexed user, uint256 reward);
    
//     event GetCapital(address indexed user, uint256 reward);
//     event NodeCapital(uint256 reward);
//     event PoolCapital(address indexed user, uint256 reward);
 
//     IERC20 public stakingToken;
//     uint256 public _allStakeAmount; // private 当前总质押数量
//     uint256 public totalA; // 总募集数量
//     uint256 public poolStatus = 1;
//     mapping (address => uint256) public dayConverts; // 今日募集的数据
//     uint256 public raiseDays = 0; //募集的天数
//     bool public isMiners = false;

//     mapping (address => User) public users;
//     address[] public addresses;
//     uint256[] public compenAmount; //补偿金额 
//     uint256 public dayTotalReward = 0;
//     uint256 public dayEachReward = 0;
//     uint256 public dayTotalCapital = 0;
//     uint256 public dayEachCapital = 0;
    
//     struct User{
//         // address uA;
//         uint256 stakeBalance;
//         uint256 rewardBalance;
//         uint256 totalReward;
//         uint256 capitalBalance;
// 		bool isVaild;
//         uint8 voteType;
//     }
    
//     constructor(
//         address _stakingToken,
//         uint256 _totalA,
//         bool _isMiners,
//         address capitalAddress
//     ) public {
//         stakingToken = IERC20(_stakingToken);
//         totalA = _totalA;
//         isMiners = _isMiners;
//         capitalAddress = capitalAddress;
//         // stakingToken = IERC20(address(0x7319Ef304662365ff577698EA375BBAD844dBB48));
//         // totalA = 100000;
//         // poolStatus = 1;
//         // isMiners = true;
//         // capitalAddress = 0x67cd742Ec21323C7B6A51d0d0463C1a743aC3B57;
//     }
//     function convertStake(address userAddress, uint256 amount) public nonReentrant  {//onlyOwner
//         doStake(userAddress, amount, 1);
//     }
//     function stake(uint256 amount) external nonReentrant {
//         doStake(msg.sender, amount, 2);
//     }
//     function doStake(address userAddress, uint256 amount, uint8 source) private {
//         // userAddress = tx.origin
//         require(poolStatus >= 2 && poolStatus <= 5, 'do not stake');
//         require(amount > 0, "Cannot stake 0");
//         // require(msg.sender.isContract(), "is");
//         _allStakeAmount = _allStakeAmount.add(amount);
        
//         User storage user = users[userAddress];
//         if (user.isVaild){
//             user.stakeBalance = user.stakeBalance.add(amount);
//         } else {
//             user.stakeBalance = amount;
//             // user.rewardBalance = 0;
//             // user.totalReward = 0;
//             user.isVaild = true;
//             addresses.push(userAddress);
//         }
//         if (isMiners && source == 1) {dayConverts[userAddress] = dayConverts[userAddress].add(amount);}
//         stakingToken.safeTransferFrom(msg.sender, address(this), amount);
//         emit Staked(userAddress, amount);
//     }
//     function redeem(uint256 amount) public nonReentrant {
//         require(poolStatus == 2 || poolStatus == 3, 'do not redeem');
//         require(amount > 0, "Cannot redeem 0");
//         _allStakeAmount = _allStakeAmount.sub(amount);
//         User storage user = users[msg.sender];
//         user.stakeBalance = user.stakeBalance.sub(amount);
//         stakingToken.safeTransfer(msg.sender, amount);
//         emit Redeem(msg.sender, amount);
//     }

//     function getCapital(uint256 amount) public nonReentrant {
//         require(amount > 0, "Cannot getCapital 0");
//         User storage user = users[msg.sender];
//         user.capitalBalance = user.capitalBalance.sub(amount);
//         rewardsToken.safeTransferFrom(capitalAddress, msg.sender, amount);
//         emit GetCapital(msg.sender, amount);
//     }

//     function getReward(uint256 amount) public nonReentrant {
//         require(amount > 0, "Cannot getReward 0");
//         User storage user = users[msg.sender];
//         user.rewardBalance = user.rewardBalance.sub(amount);
//         rewardsToken.safeTransfer(msg.sender, amount);
//         emit GetReward(msg.sender, amount);
//     }

//     function vote(uint8 voteType) public nonReentrant {
//         require(poolStatus == 4, 'do not vote');
//         require(voteType == 1 || voteType == 2, "voteType error");
//         User storage user = users[msg.sender];
//         user.voteType = voteType;
//     }
    
//     function updateStatus(uint8 status) public nonReentrant onlyOwner {
//         require(status > 0 && status < 7, 'status err');
//         if (status == 5) {
//             uint256 allAmount = voteAllAmount(1);
//             if (allAmount*100/totalA < 100-voteRedeemRatio) {
//                 status = 3;
//                 // 重制投票结果
//                 for (uint256 i = 0; i < addresses.length; i++) {
//                     User storage user = users[addresses[i]];
//                     if (user.voteType != 0) { user.voteType = 0; }
//                 }
//             }
//         }
//         poolStatus = status;
//     }
//     function addDayReward(uint256 amount) public nonReentrant onlyOwner {
//         require(poolStatus >= 2 && poolStatus <= 5, 'do not addDayReward');
//         dayTotalReward = dayTotalReward.add(amount);
//     }
//     function addDayCapital(uint256 amount) public nonReentrant onlyOwner {
//         require(poolStatus == 5, 'do not addDayCapital');
//         dayTotalCapital = dayTotalCapital.add(amount);
//     }
//     function dayInitSendReward(uint256 noConvertAmounts) public nonReentrant onlyOwner {
//         require(poolStatus >= 2 && poolStatus <= 5, 'do not sendReward');
//         require(poolStatus == 2 || _allStakeAmount*100/totalA >= stakeRatio, 'stakeRatio low');
//         require(dayTotalReward > 0, 'not send amount');
//         uint256 allAmount = _allStakeAmount;
//         if (poolStatus == 2) { 
//             raiseDays++;
//             allAmount = allAmount.add(noConvertAmounts);
//         } 
//         dayEachReward = dayTotalReward.mul(100000000).div(allAmount);
//         if (poolStatus == 2) { compenAmount.push(dayEachReward); }
//         emit NodeReward(dayTotalReward);
//         dayTotalReward = 0;
        
//         if (poolStatus == 5) { 
//             dayEachCapital = dayTotalCapital.mul(100000000).div(_allStakeAmount);
//             emit NodeCapital(dayTotalCapital);
//             dayTotalCapital = 0;
//         }
//     }
//     function sendReward(uint256 sta, uint256 end) public nonReentrant onlyOwner {
//         require(rewardsToken.balanceOf(address(this)) > 0, 'address not balance');

//         for (uint i = sta; i < end && i < addresses.length; i++) {
//             address userAddress = addresses[i];
//             User storage user = users[userAddress];
//             if (user.isVaild && user.stakeBalance > 0) {
//                 uint256 reward = user.stakeBalance.mul(dayEachReward).div(100000000);
//                 if (isMiners) {
//                     if (poolStatus == 2) {
//                         // 补发收益
//                         uint256 convertAmount = dayConverts[userAddress];
//                         if (convertAmount > 0) {
//                             for (uint256 j = 0; j < raiseDays - 1; j++) {
//                                 uint256 addReward = convertAmount.mul(compenAmount[j]).div(100000000);
//                                 reward = reward.add(addReward);
//                             }
//                         }
//                         delete dayConverts[userAddress];
//                     } else if (poolStatus == 5) {
//                         // 释放本金
//                         uint256 capital = user.stakeBalance.mul(dayEachCapital).div(100000000);
//                         user.capitalBalance = user.capitalBalance.add(capital);
//                         emit PoolCapital(userAddress, capital);
//                     }
//                 }
//                 user.rewardBalance = user.rewardBalance.add(reward);
//                 user.totalReward = user.totalReward.add(reward);
//                 emit PoolReward(userAddress, reward);
//             }
//         }
//     }
//     function dataInfo() public view returns(uint256, uint256, uint256){
//         return (rewardsToken.balanceOf(address(this)), _allStakeAmount*100/totalA, addresses.length);
//     }
//     function voteAllAmount(uint8 voteType) public view returns(uint256){
//         uint256 allAmount = 0;
//         for (uint i = 0; i < addresses.length; i++) {
//             User storage user = users[addresses[i]];
//             if (user.voteType == voteType) {
//                 allAmount = allAmount.add(user.stakeBalance);
//             }
//         }
//         return (allAmount);
//     }
//     // function tokenBalance() public view returns(uint256){
//     //     return (rewardsToken.balanceOf(address(this)));
//     // }
    
//     function toAsciiString(address x) internal view returns (string memory) {
//         bytes memory s = new bytes(40);
//         for (uint i = 0; i < 20; i++) {
//             bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
//             bytes1 hi = bytes1(uint8(b) / 16);
//             bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
//             s[2*i] = char(hi);
//             s[2*i+1] = char(lo);            
//         }
//         return string(s);
//     }
//     function char(bytes1 b) internal view returns (bytes1 c) {
//         if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
//         else return bytes1(uint8(b) + 0x57);
//     }
// }


interface AStakingRewards  {
    function convertStake(address userAddress, uint256 amount)  external;
    function updateStatus(uint8 status) external;
}

contract ABet is PTokenFactory, Ownable, ReentrancyGuard{
    using SafeToken for address;
    using SafeMath for uint256;
    address public rewardsToken = 0xae3a768f9aB104c69A7CD6041fE16fFa235d1810; // hfil
    event Convert(address indexed user, uint8 index, uint256 amount, string _invate, uint256 curA);
    event ConvertOver(uint8 index);

    struct Period{
        uint8 index;
        address token1;
        address token2;
        address stakeAddress1;
        address stakeAddress2;
        address collect;
        address receiveSuanli;
        uint16 ratio1; // ratio/100
        uint16 ratio2; // ratio/100
        uint256 totalA;
        // uint256 startTime;
        uint256 curA;
        // uint256 destroyA1;
        // uint256 destroyA2;
        uint8 status;
    }
    uint256 public max_index = 0;
    mapping(uint256 => Period) public periods;
    struct Destroy{
        uint256 destroyAmount1;
        uint256 destroyAmount2;
    }
    mapping(uint256 => Destroy) public destroys;
    /**
 * 0:不存在
 * 1:已初始化
 * 2:募集中
 * 3:产出中
 * 4:投票中
 * 5:产出中(已投票)
 * 6:已结束
 * 7:已关闭
*/
    /// write
    function convert(uint8 index, uint256 amount, string calldata _invate) external payable nonReentrant {
        Period storage period = periods[index];
        require(period.status == 2, 'convert is close');
        if (period.curA.add(amount) >= period.totalA) {
            period.status = 3;
            amount = period.totalA.sub(period.curA);
            emit ConvertOver(index);
        }
        period.curA = period.curA.add(amount);
        require(period.curA <= period.totalA, 'more than total amount');
        SafeToken.safeTransferFrom(rewardsToken, msg.sender, period.collect, amount);
        
        AStakingRewards yuntuStake = AStakingRewards(period.stakeAddress1);
        yuntuStake.convertStake(msg.sender, amount.mul(period.ratio1).div(100));
        
        SafeToken.safeTransfer(period.token2, period.receiveSuanli, amount.mul(period.ratio2).div(100));
        
        emit Convert(msg.sender, index, amount, _invate, period.curA);
    }
    
    function allVotesAmount(uint256 index) public view returns(uint256){
        Period memory period = periods[index];
        Destroy storage destroy = destroys[index];
        return(period.totalA.mul(period.ratio1).div(100).sub(destroy.destroyAmount1));
    }
    
    function noConvertAmounts(uint256 index) public view returns(uint256){
        Period memory period = periods[index];
        return(period.totalA.sub(period.curA).mul(period.ratio1).div(100));
    }
    
    function updateStatus(uint8 index, uint8 status) external nonReentrant onlyOwner {
        Period storage period = periods[index];
        require(period.status > 0, 'pool not exist');
        require(status > 0 && status < 8, 'status err');
        period.status = status;
        AStakingRewards yuntuStake1 = AStakingRewards(period.stakeAddress1);
        yuntuStake1.updateStatus(status);
        AStakingRewards yuntuStake2 = AStakingRewards(period.stakeAddress2);
        yuntuStake2.updateStatus(status);
        
        if (status == 3) {
            Destroy storage destroy = destroys[index];
            IERC20 tokenContract1 = IERC20(address(period.token1));
            uint256 balance1 = tokenContract1.balanceOf(address(this));
            if (balance1 > 0) {
                SafeToken.safeTransfer(period.token1, 0x0000000000000000000000000000000000000001, balance1);
                destroy.destroyAmount1 = balance1;
            }
        
            IERC20 tokenContract2 = IERC20(address(period.token2));
            uint256 balance2 = tokenContract2.balanceOf(address(this));
            if (balance2 > 0) {
                SafeToken.safeTransfer(period.token2, 0x0000000000000000000000000000000000000001, balance2);
                destroy.destroyAmount2 = balance2;
            }
        }
        
    }
    
    // function test() external nonReentrant onlyOwner {
    //     // Period storage period = periods[1];
    //     address token1 = 0xA346eE8e36a3683466d3A875122938bF32d2A6f6;
    //     Destroy storage destroy = destroys[1];
    //         IERC20 tokenContract1 = IERC20(address(token1));
    //         uint256 balance1 = tokenContract1.balanceOf(address(this));
    //         if (balance1 > 0) {
    //             SafeToken.safeTransfer(token1, 0x0000000000000000000000000000000000000001, balance1);
    //             destroy.destroyAmount1 = balance1;
    //         }
    // }
    
    constructor() public {
        // uint8 index=1;
        // address token1=0x7319Ef304662365ff577698EA375BBAD844dBB48;
        // address token2=0x72c74F0c5f7E58c7278723da37ccFad9aFc989cb;
        // uint16 ratio1=120;
        // uint16 ratio2=130;
        // uint256 totalA=1e29;
        // // uint256 startTime=2021;
        // Period storage period = periods[index];
        // require(period.index==0, 'period already exists');
        // require(max_index+1==index, 'index error');
        // period.index = index;
        // period.stakeAddress1 = 0xA85783f681BC4Cda9e46193d893F7aCa795d8332;
        // period.stakeAddress2 = 0xf5B375cFC5559c3Dc16bC6CfC645B5d96645945f;
        // period.token1 = token1; //yfil
        // period.token2 = token2; //tfil
        // period.ratio1 = ratio1;
        // period.ratio2 = ratio2;
        // period.collect = 0x753fd3A3965c0fca863b77968EB71baAB2eAf75d;
        // period.receiveSuanli = 0x753fd3A3965c0fca863b77968EB71baAB2eAf75d;
        // period.totalA = totalA;
        // // period.startTime = startTime;
        // period.status = 1;
        // SafeToken.safeApprove(period.token1, period.stakeAddress1, 1e30);
        // max_index=index;
    }
    
    function addPool(uint8 index, address stakeAddress1, address stakeAddress2, address token1, address token2, uint16 ratio1, uint16 ratio2, uint256 totalA, address collect, address receiveSuanli) external onlyOwner {
        Period storage period = periods[index];
        require(period.index==0, 'period already exists');
        require(max_index+1==index, 'index error');
        period.index = index;
        period.stakeAddress1 = stakeAddress1;
        period.stakeAddress2 = stakeAddress2;
        period.token1 = token1; //yfil
        period.token2 = token2; //tfil
        period.ratio1 = ratio1;
        period.ratio2 = ratio2;
        period.collect = collect;
        period.receiveSuanli = receiveSuanli;
        period.totalA = totalA;
        // period.startTime = startTime;
        period.status = 1;
        SafeToken.safeApprove(period.token1, period.stakeAddress1, 1e30);
        max_index=index;
        // period.stakeAddress1 = address(new AStakingRewards(token1, totalA, true, capitalAddress));
        // period.stakeAddress2 = address(new AStakingRewards(token2, totalA, false, capitalAddress));
    }
    
    // function updateCollect(uint8 index, address collect) external onlyOwner {
    //     Period storage period = periods[index];
    //     require(period.status > 0, 'period not exists');
    //     period.collect = collect;
    // }
}