/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
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
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}
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
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked until 0 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract CocFoundationLock is Ownable {
    using SafeMath for uint256;
    IBEP20 public  coc;
    uint public foundation;
    uint public foundationUnlockTime;

    event Release(address indexed to, uint amount, uint time);
    constructor (address _token) {
        coc = IBEP20(_token);
        foundation = coc.totalSupply().mul(3).div(100);
        foundationUnlockTime = block.timestamp.add(90 days);
    }

    function release(address to, uint amount) public onlyOwner {
        require(block.timestamp >= foundationUnlockTime);
        coc.transfer(to, amount);
        emit Release(to, amount, block.timestamp);
    }
}

contract CocMarketingLock is Ownable {
    using SafeMath for uint256;
    IBEP20 public  coc;
    uint public marketing;
    uint public marketingUnlockTime;
    uint public nextUnlockTime;

    event Release(address indexed to, uint amount, uint time);
    constructor (address _token) {
        coc = IBEP20(_token);
        marketing = coc.totalSupply().mul(3).div(100);
        marketingUnlockTime = block.timestamp.add(180 days);
        nextUnlockTime = marketingUnlockTime;
    }

    function release(address to) public onlyOwner {
        require(block.timestamp >= nextUnlockTime);
        nextUnlockTime = nextUnlockTime.add(30 days);
        coc.transfer(to, marketing.div(12));
        emit Release(to, marketing.div(12), block.timestamp);
    }
}

contract CocEcosystemLock is Ownable {
    using SafeMath for uint256;
    IBEP20 public  coc;
    uint public ecosystem;
    uint public ecosystemUnlockTime;
    uint public nextUnlockTime;

    event Release(address indexed to, uint amount, uint time);
    constructor (address _token) {
        coc = IBEP20(_token);
        ecosystem = coc.totalSupply().mul(4).div(100);
        ecosystemUnlockTime = block.timestamp.add(180 days);
        nextUnlockTime = ecosystemUnlockTime;
    }

    function release(address to) public onlyOwner {
        require(block.timestamp >= nextUnlockTime);
        nextUnlockTime = nextUnlockTime.add(30 days);
        coc.transfer(to, ecosystem.div(12));
        emit Release(to, ecosystem.div(12), block.timestamp);
    }
}

contract CocTeamLock is Ownable {
    using SafeMath for uint256;
    IBEP20 public  coc;
    uint public team;
    uint public teamUnlockTime;
    uint public nextUnlockTime;

    event Release(address indexed to, uint amount, uint time);
    constructor (address _token) {
        coc = IBEP20(_token);
        team = coc.totalSupply().mul(5).div(100);
        teamUnlockTime = block.timestamp.add(365 days);
        nextUnlockTime = teamUnlockTime;
    }

    function release(address to) public onlyOwner {
        require(block.timestamp >= nextUnlockTime);
        nextUnlockTime = nextUnlockTime.add(30 days);
        coc.transfer(to, team.div(12));
        emit Release(to, team.div(12), block.timestamp);
    }
}

contract CocInvestmentLock is Ownable {
    using SafeMath for uint256;
    IBEP20 public  coc;
    uint public investment;
    uint public investmentUnlockTime;
    uint public nextUnlockTime;
    uint public nextUnlockAmount;

    event Release(address indexed to, uint amount, uint time);
    constructor (address _token) {
        coc = IBEP20(_token);
        investment = coc.totalSupply().mul(10).div(100);
        investmentUnlockTime = block.timestamp.add(30 days);
        nextUnlockTime = investmentUnlockTime;
        nextUnlockAmount = investment.div(12);
    }

    function release(address to) public onlyOwner {
        require(block.timestamp >= nextUnlockTime);
        nextUnlockTime = nextUnlockTime.add(30 days);
        coc.transfer(to, nextUnlockAmount);
        emit Release(to, nextUnlockAmount, block.timestamp);
        nextUnlockAmount = investment.div(12);
    }
}

contract CocGameLock is Ownable {
    using SafeMath for uint256;
    IBEP20 public  coc;
    uint public game;
    uint public gameUnlockTime;
    uint public nextUnlockTime;
    uint public nextUnlockAmount;

    event Release(address indexed to, uint amount, uint time);
    constructor (address _token) {
        coc = IBEP20(_token);
        game = coc.totalSupply().mul(60).div(100);
        gameUnlockTime = block.timestamp.add(30 days);
        nextUnlockTime = gameUnlockTime;
        nextUnlockAmount = 100000000 * 10 ** (coc.decimals());
    }

    function release(address to) public onlyOwner {
        require(block.timestamp >= nextUnlockTime);
        nextUnlockTime = nextUnlockTime.add(365 days);
        coc.transfer(to, nextUnlockAmount);
        emit Release(to, nextUnlockAmount, block.timestamp);
    }
}