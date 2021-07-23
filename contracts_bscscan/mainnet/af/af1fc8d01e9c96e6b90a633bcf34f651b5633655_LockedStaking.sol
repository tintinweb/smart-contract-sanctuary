/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

/*

$$$$$$$\  $$\                                                                 
$$  __$$\ \__|                                                                
$$ |  $$ |$$\ $$$$$$$\   $$$$$$\  $$$$$$\$$$$\   $$$$$$\   $$$$$$\   $$$$$$$\ 
$$$$$$$\ |$$ |$$  __$$\  \____$$\ $$  _$$  _$$\  \____$$\ $$  __$$\ $$  _____|
$$  __$$\ $$ |$$ |  $$ | $$$$$$$ |$$ / $$ / $$ | $$$$$$$ |$$ |  \__|\$$$$$$\  
$$ |  $$ |$$ |$$ |  $$ |$$  __$$ |$$ | $$ | $$ |$$  __$$ |$$ |       \____$$\ 
$$$$$$$  |$$ |$$ |  $$ |\$$$$$$$ |$$ | $$ | $$ |\$$$$$$$ |$$ |      $$$$$$$  |
\_______/ \__|\__|  \__| \_______|\__| \__| \__| \_______|\__|      \_______/ 
                                                                              
➥ Binamars Game is a Play to Earn NFT RPG developed on the BSC platform.
- Website: https://binamars.com
- Announcements: https://t.me/binamarschannel
- Telegram: https://t.me/binamars
- Twitter: https://twitter.com/Binamarsbsc
- Documents: https://docs.binamars.com

*/

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
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
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "mod: %");
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
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
}

// y = f(x)

// 5 = f(10)
// 185 = f(365)
//y = A^x - X
//y = 1.87255 + 0.2985466*x + 0.001419838*x^2


interface StakingInterface {
    function votingPowerOf(address acc, uint256 until) external view returns(uint256);
}

contract LockedStaking is Ownable, StakingInterface {
    using SafeMath for uint256;
    IERC20 public BMARS;

    bool isClosed = false;

    // quadratic reward curve constants
    // a + b*x + c*x^2
    uint256 public A = 187255; // 1.87255
    uint256 public B = 29854;  // 0.2985466*x
    uint256 public C = 141;    // 0.001419838*x^2

    uint256 public maxDays = 365;
    uint256 public minDays = 6;

    uint256 public totalStaked = 0;
    uint256 public totalRewards = 0;

    uint256 public earlyExit = 0;

    struct StakeInfo {
        uint256 reward;
        uint256 initial;
        uint256 payday;
        uint256 startday;
    }

    mapping (address=>StakeInfo) public stakes;

    constructor(address _BMARS) public {
        BMARS = IERC20(_BMARS);
    }

    function stake(uint256 _amount, uint256 _days) public {
        require(_days > minDays, "less than minimum staking period");
        require(_days < maxDays, "more than maximum staking period");
        require(stakes[msg.sender].payday == 0, "already staked");
        require(_amount > 100, "amount to small");
        require(!isClosed, "staking is closed");

        // calculate reward
        uint256 _reward = calculateReward(_amount, _days);

        // contract must have funds to keep this commitment
        require(BMARS.balanceOf(address(this)) > totalOwedValue().add(_reward).add(_amount), "insufficient contract bal");

        require(BMARS.transferFrom(msg.sender, address(this), _amount), "transfer failed");

        stakes[msg.sender].payday = block.timestamp.add(_days * (1 days));
        stakes[msg.sender].reward = _reward;
        stakes[msg.sender].startday = block.timestamp;
        stakes[msg.sender].initial = _amount;

        // update stats
        totalStaked = totalStaked.add(_amount);
        totalRewards = totalRewards.add(_reward);
    }

    function claim() public {
        require(owedBalance(msg.sender) > 0, "nothing to claim");
        require(block.timestamp > stakes[msg.sender].payday.sub(earlyExit), "too early");

        uint256 owed = stakes[msg.sender].reward.add(stakes[msg.sender].initial);

        // update stats
        totalStaked = totalStaked.sub(stakes[msg.sender].initial);
        totalRewards = totalRewards.sub(stakes[msg.sender].reward);

        stakes[msg.sender].initial = 0;
        stakes[msg.sender].reward = 0;
        stakes[msg.sender].payday = 0;
        stakes[msg.sender].startday = 0;

        require(BMARS.transfer(msg.sender, owed), "transfer failed");
    }

    function calculateReward(uint256 _amount, uint256 _days) public view returns (uint256) {
        uint256 _multiplier = _quadraticRewardCurveY(_days);
        uint256 _AY = _amount.mul(_multiplier);
        return _AY.div(10000000);

    }

    // a + b*x + c*x^2
    function _quadraticRewardCurveY(uint256 _x) public view returns (uint256) {
        uint256 _bx = _x.mul(B);
        uint256 _x2 = _x.mul(_x);
        uint256 _cx2 = C.mul(_x2);
        return A.add(_bx).add(_cx2);
    }

    // helpers:
    function totalOwedValue() public view returns (uint256) {
        return totalStaked.add(totalRewards);
    }

    function owedBalance(address acc) public view returns(uint256) {
        return stakes[acc].initial.add(stakes[acc].reward);
    }

    function votingPowerOf(address acc, uint256 until) external override view returns(uint256) {
        if (stakes[acc].payday > until) {
            return 0;
        }

        return owedBalance(acc);
    }

    // owner functions:
    function setLimits(uint256 _minDays, uint256 _maxDays) public onlyOwner {
        minDays = _minDays;
        maxDays = _maxDays;
    }

    function setCurve(uint256 _A, uint256 _B, uint256 _C) public onlyOwner {
        A = _A;
        B = _B;
        C = _C;
    }

    function setEarlyExit(uint256 _earlyExit) public onlyOwner {
        require(_earlyExit < 2880000, "too big");
        close(true);
        earlyExit = _earlyExit;
    }

    function close(bool closed) public onlyOwner {
        isClosed = closed;
    }

    function ownerReclaim(uint256 _amount) public onlyOwner {
        require(_amount < BMARS.balanceOf(address(this)).sub(totalOwedValue()), "cannot withdraw owed funds");
        BMARS.transfer(msg.sender, _amount);
    }

    function flushBNB() public onlyOwner {
        uint256 bal = address(this).balance.sub(1);
        msg.sender.transfer(bal);
    }

}