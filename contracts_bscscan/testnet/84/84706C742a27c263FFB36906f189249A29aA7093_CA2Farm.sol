/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// library SafeERC20 {
    

//     function safeTransfer(IERC20 token, address to, uint value) internal {
//         callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
//     }

//     function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
//         callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
//     }

//     function safeApprove(IERC20 token, address spender, uint value) internal {
//         require((value == 0) || (token.allowance(address(this), spender) == 0),
//             "SafeERC20: approve from non-zero to non-zero allowance"
//         );
//         callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
//     }
//     function callOptionalReturn(IERC20 token, bytes memory data) private {
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


// File: @openzeppelin/contracts/math/SafeMath.sol

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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol


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
    constructor() { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol


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
    constructor () {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function mint(address account, uint amount) external;

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

// File: contracts/CurveRewards.sol

contract LPTokenWrapper {
    using SafeMath for uint256;
    // using SafeERC20 for IERC20;

    IERC20 public CA2 = IERC20(0x9b61A0347D44A4369d2b6bd270D083dB7B041d78); //test

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount * 10 ** 6);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        CA2.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        CA2.transfer(msg.sender, amount);
    }
}


contract CA2Farm is LPTokenWrapper, Ownable {
    // using SafeERC20 for IERC20;
    // using Address for address;
    using SafeMath for uint;

    uint public CurrentCounter;
    uint public IdCount;
    uint public StampCounter = 1;
    bool public IsRunning;
    uint public TotalReward = 1000000000000000000000000;
    uint public periodFinish;
    uint public CurrentPhase;
    IERC20 constant public USDT = IERC20(0x1c0C41F4c6567b70B56781D61193aCEfE734d22D); //test
    
    mapping(uint => uint) public PhaseEndTime;
    mapping(address => uint) public UserStakeAmount;
    mapping(uint => uint) public UserStakeAmountId;
    mapping(address => uint) public UserClaimAmount;
    mapping(uint => uint) public PhaseRewardAmount;
    mapping(address => uint) public UserAccount;
    mapping(uint => address) public UserId;
    mapping(uint => uint) public UserCreatedDate;

    event UserStaked(address indexed User, uint indexed Amount, uint indexed CurrentTotal);
    event UserWithdrawed(address indexed User, uint indexed Amount, uint indexed CurrentTotal);
    event RewardClaimed(address indexed User, uint indexed UserClaimedAmount);
    event NewEndTime(uint indexed CurrentPhase, uint indexed EndTime);
    event RewardDistributed(address indexed UserAddress, uint indexed Amount);

    modifier checkUser(){
        if(UserAccount[msg.sender] == 0){
            IdCount = IdCount + 1;
            UserAccount[msg.sender] = IdCount;
            UserId[IdCount] = msg.sender; 
            UserCreatedDate[IdCount] = block.timestamp;
        }
        _;
    }

    modifier checkPhase(){
        if (block.timestamp >= periodFinish) {
            IsRunning = false;
        }
        _;
    }

    function Stake(uint _amount) checkPhase checkUser external{
        require(CurrentPhase > 0, "Wait for owner to start");
        require(IsRunning, "Wait for owner to resume");
        super.stake(_amount);
        if(UserStakeAmount[msg.sender] == 0){
            CurrentCounter++;
        }
        UserStakeAmount[msg.sender] = UserStakeAmount[msg.sender].add(_amount);
        uint userid = UserAccount[msg.sender];
        UserStakeAmountId[userid] = UserStakeAmountId[userid].add(_amount);

        emit UserStaked(msg.sender, _amount, CurrentCounter);

    }

    function Withdraw(uint _amount) checkPhase external{
        require(IsRunning, "Wait for owner to resume");
        require(_amount <= UserStakeAmount[msg.sender], "Insufficient Withdraw Amount");
        super.withdraw(_amount);
        UserStakeAmount[msg.sender] = UserStakeAmount[msg.sender].sub(_amount);
        uint userid = UserAccount[msg.sender];
        UserStakeAmountId[userid] = UserStakeAmountId[userid].sub(_amount);
        if(UserStakeAmount[msg.sender] == 0){
            CurrentCounter--;
        }

        emit UserWithdrawed(msg.sender, _amount, CurrentCounter);
    }

    function Claim() checkPhase external {
        require(UserClaimAmount[msg.sender] > 0, "No Reward To Claim");
        USDT.transfer(msg.sender, UserClaimAmount[msg.sender]);
        emit RewardClaimed(msg.sender, UserClaimAmount[msg.sender]);
        UserClaimAmount[msg.sender] = 0;
    }

    function OwnerStampRecord(uint amount, uint _endTime) external onlyOwner{
        require(block.timestamp >= periodFinish, "Period not end");
        PhaseRewardAmount[CurrentPhase] = TotalReward.mul(10).div(CurrentCounter).div(10); //test
        for(uint i = 0; i < amount; i++){
            if(UserStakeAmountId[StampCounter] != 0){
                UserClaimAmount[UserId[StampCounter]] = UserClaimAmount[UserId[StampCounter]].add(PhaseRewardAmount[CurrentPhase]);
                emit RewardDistributed(UserId[StampCounter], PhaseRewardAmount[CurrentPhase]);
            }
            StampCounter++;
            if(StampCounter > IdCount){
                CurrentPhase++;
                StampCounter = 1;
                PhaseEndTime[CurrentPhase] = _endTime;
                periodFinish = _endTime;
                IsRunning = true; 
                emit NewEndTime(CurrentPhase ,_endTime);
                break;       
            }
        }
    }

    function StartFarm(uint _endTime) external onlyOwner{
        require(CurrentPhase == 0, "Already started");
        PhaseEndTime[CurrentPhase] = _endTime;
        periodFinish = _endTime;
        IsRunning = true; 
        CurrentPhase++;
    }

    function SetTotalReward(uint _rewardAmount) external onlyOwner{
        TotalReward = _rewardAmount;
    }
}