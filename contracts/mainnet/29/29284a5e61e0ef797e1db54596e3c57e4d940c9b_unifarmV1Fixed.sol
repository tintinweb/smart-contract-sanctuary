/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// File: @openzeppelin/contracts/GSN/Context.sol --

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

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

// File: @openzeppelin/contracts/utils/Pausable.sol

pragma solidity >=0.6.0 <=0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <=0.8.0;

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
 abstract contract Ownable is Pausable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address ownerAddress) {
        _owner = ownerAddress;
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnershipNew(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

// File: contracts/UnifarmFixed.sol

pragma solidity 0.7.4;

abstract contract OwnableV1 {
    function transferOwnership(address newOwner) external virtual;
    function owner() external virtual returns (address);
}

abstract contract admin1 is OwnableV1 {
   
    
    mapping(address => address[]) public tokensSequenceList;
    mapping(address => mapping(address => uint256)) public tokenDailyDistribution;
    mapping(address => mapping(address => bool)) public tokenBlockedStatus;
    uint256[] public intervalDays; // = [1, 8, 15, 22, 29, 36];
    uint256 public stakeDuration;
    address[] public tokens;
    
    function safeWithdraw(address tokenAddress, uint256 amount) external virtual;
}

abstract contract UnifarmV11 is admin1 {
    // Stores Stake Details
    struct stakeInfo {
        address user;
        bool[] isActive;
        address[] referrer;
        address[] tokenAddress;
        uint256[] stakeId;
        uint256[] stakedAmount;
        uint256[] startTime;
    }

    // Mapping
    mapping(address => stakeInfo) public stakingDetails;
    mapping(address => mapping(address => uint256)) public userTotalStaking;
    mapping(address => uint256) public totalStaking;
    uint256 public DAYS;

    function viewStakingDetails(address _user) external virtual  view returns ( address[] memory, bool[] memory,
            uint256[] memory, uint256[] memory, uint256[] memory);
}

contract unifarmV1Fixed is Ownable {
    
    UnifarmV11 public UniV1;
    
    using SafeMath for uint256;
    uint256 intervalLength = 6;
    
    mapping(address => uint256) public totalUnstaking;
    mapping(address => mapping(uint256 => bool)) public unstakeStatus;
    
    constructor(address V1Address) Ownable(msg.sender)  {
        UniV1 = UnifarmV11(V1Address);
    }
    
    event Claim(address indexed userAddress, address indexed stakedTokenAddress, address indexed tokenAddress,uint256 claimRewards,uint256 Time);
    event UnStake(address indexed userAddress, address indexed unStakedtokenAddress, uint256 unStakedAmount, uint256 Time);
    
    
    function init(address[] memory tokenAddress) external onlyOwner returns(bool) {
        for(uint i =0; i< tokenAddress.length; i++) {
            transferFromContractA(tokenAddress[i]);
        }
        
        return true;
    }
    
    function transferFromContractA(address tokenAddress) internal {
        uint bal = IERC20(tokenAddress).balanceOf(address(UniV1));
        
        if(bal > 0)
            UniV1.safeWithdraw(tokenAddress, bal);
    }
    
    /**
     * @notice Get rewards for one day
     * @param stakedAmount Stake amount of the user
     * @param stakedToken Staked token address of the user
     * @param rewardToken Reward token address
     * @param totalStake Reward token address
     * @return reward One dayh reward for the user
     */
    function getOneDayReward(uint256 stakedAmount,address stakedToken,address rewardToken,uint256 totalStake) public view returns (uint256 reward) {
       
            reward = (stakedAmount.mul(UniV1.tokenDailyDistribution(stakedToken,rewardToken))).div(totalStake);
        
    }
 
    /**
     * @notice Get rewards for one day
     * @param stakedToken Stake amount of the user
     * @param tokenAddress Reward token address
     * @param amount Amount to be transferred as reward
     */
    function sendToken(address stakedToken,address tokenAddress,uint256 amount) internal {
        // Checks
        if (tokenAddress != address(0)) {
            require(
                IERC20(tokenAddress).balanceOf(address(this)) >= amount,
                "SEND : Insufficient Balance"
            );
            // Transfer of rewards
            require(IERC20(tokenAddress).transfer(msg.sender, amount), 
                    "Transfer failed");

             // Emit state changes
            emit Claim(
                msg.sender,
                stakedToken,
                tokenAddress,
                amount,
                block.timestamp
            );
        }
    }

    /**
     * @notice Unstake and claim rewards
     * @param stakeId Stake ID of the user
     */
    function unStake(uint256 stakeId) external  {
        
        (address[] memory tokenAddress,bool[] memory activeStatus, ,
            uint256[] memory stakedAmount,uint256[] memory startTime) = (UniV1.viewStakingDetails(msg.sender));
            
       
       
        // Checks
        require(
            unstakeStatus[msg.sender][stakeId] == false && activeStatus[stakeId] == true,
            "CLAIM : Insufficient Staked Amount"
        );
        
        transferFromContractA(tokenAddress[stakeId]);

        // State updation
        uint totalStaking1 = UniV1.totalStaking(tokenAddress[stakeId]).sub(totalUnstaking[tokenAddress[stakeId]]);
        totalUnstaking[tokenAddress[stakeId]] = totalUnstaking[tokenAddress[stakeId]].add(stakedAmount[stakeId]);
        unstakeStatus[msg.sender][stakeId] = true;
        
        

        // Balance check
        require(
            IERC20(tokenAddress[stakeId]).balanceOf(
                address(this)
            ) >= stakedAmount[stakeId],
            "UNSTAKE : Insufficient Balance"
        );

        // Transfer staked token back to user
            IERC20(tokenAddress[stakeId]).transfer(msg.sender, stakedAmount[stakeId]);

        // Claim pending rewards
            claimRewards(startTime[stakeId], stakedAmount[stakeId], tokenAddress[stakeId], totalStaking1);

        // Emit state changes
        emit UnStake(
            msg.sender,
            tokenAddress[stakeId],
            stakedAmount[stakeId],
            block.timestamp
        );
        
    }
    
     /**
     * @notice Claim accumulated rewards
     * @param stakedAmount Staked amount of the user
     */
    function claimRewards(uint256 stakeTime, uint256 stakedAmount, address stakedToken, uint256 totalStake) internal {
        // Local variables
        uint256 interval;

        interval = stakeTime.add(UniV1.stakeDuration());
        
        // Interval calculation
        if (interval > block.timestamp) {
            uint256 endOfProfit = block.timestamp;
            interval = endOfProfit.sub(stakeTime);
        } else {
            uint256 endOfProfit = stakeTime.add(UniV1.stakeDuration());
            interval = endOfProfit.sub(stakeTime);
        }

        // Reward calculation
        if (interval >= UniV1.DAYS())
            _rewardCalculation(stakedAmount, interval, stakedToken, totalStake);
    }
    
    function _rewardCalculation(uint256 stakedAmount,uint256 interval, address stakedToken,uint256 totalStake) internal {
        uint256 rewardsEarned;
        uint256 noOfDays;
        
        noOfDays = interval.div(UniV1.DAYS());
        rewardsEarned = noOfDays.mul(
            getOneDayReward(
                stakedAmount,
                stakedToken,
                stakedToken,
                totalStake
            )
        );


        //  Rewards Send
        sendToken(
            stakedToken,
            stakedToken,
            rewardsEarned
        );

        uint8 i = 1;
        while (i < intervalLength) { 
            
            if (noOfDays >= UniV1.intervalDays(i)) {
                uint256 balDays = noOfDays.sub((UniV1.intervalDays(i).sub(1)));

                address rewardToken = UniV1.tokensSequenceList(stakedToken,i);
                
                transferFromContractA(rewardToken);


                if ( rewardToken != stakedToken 
                        && UniV1.tokenBlockedStatus(stakedToken,rewardToken) ==  false) {
                    rewardsEarned = balDays.mul(
                        getOneDayReward(
                            stakedAmount,
                            stakedToken,
                            rewardToken,
                            totalStake
                        )
                    );
                    

                    //  Rewards Send
                    sendToken(
                        stakedToken,
                        rewardToken,
                        rewardsEarned
                    );
                }
                i = i + 1;
            } else {
                break;
            }
        }
    }
    
    function updateIntervalLength(uint256 ilength) external onlyOwner returns(bool) {
        intervalLength = ilength;
        return true;
    }
    
    function transferOwnership(address newOwner) public override onlyOwner {
        UniV1.transferOwnership(newOwner);
    }
    
    function safeWithdraw(address tokenAddress, uint256 amount) public onlyOwner {
         
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Insufficient Balance"
        );
        require(
            IERC20(tokenAddress).transfer(owner(), amount) == true,
            "Transfer failed");
    }
    
}