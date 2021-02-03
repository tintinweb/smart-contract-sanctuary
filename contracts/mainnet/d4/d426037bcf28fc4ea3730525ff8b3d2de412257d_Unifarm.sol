/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/math/SafeMath.sol
pragma solidity >=0.6.0 <=0.8.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}


pragma solidity >=0.6.0 <=0.8.0;

// File: contracts/Unifarm.sol

contract Admin is Ownable {
    struct tokenInfo {
        bool isExist;
        uint8 decimal;
        uint256 userStakeLimit;
        uint256 maxStake;
    }

    address[] public tokens;
    mapping(address => address[]) public tokensSequenceList;
    mapping(address => tokenInfo) public tokenDetails;
    mapping(address => mapping(address => uint256)) public tokenDailyDistribution;
    mapping(address => mapping(address => bool)) public tokenBlockedStatus;
    uint256[] public intervalDays = [1, 8, 15, 22, 29, 36];
    uint256 public stakeDuration = 90 days;

    event TokenDetails(
        address indexed tokenAddress,
        uint256 userStakeimit,
        uint256 totalStakeLimit,
        uint256 Time
    );

    function addToken(
        address tokenAddress,
        uint256 userMaxStake,
        uint256 totalStake,
        uint8 decimal
    ) public onlyOwner returns (bool) {
        if (tokenDetails[tokenAddress].isExist == false)
            tokens.push(tokenAddress);

        tokenDetails[tokenAddress].isExist = true;
        tokenDetails[tokenAddress].decimal = decimal;
        tokenDetails[tokenAddress].userStakeLimit = userMaxStake;
        tokenDetails[tokenAddress].maxStake = totalStake;

        emit TokenDetails(
            tokenAddress,
            userMaxStake,
            totalStake,
            block.timestamp
        );
        return true;
    }

    function setDailyDistribution(
        address[] memory stakedToken,
        address[] memory rewardToken,
        uint256[] memory dailyDistribution
    ) public onlyOwner {
        require(
            stakedToken.length == rewardToken.length &&
                rewardToken.length == dailyDistribution.length,
            "Invalid Input"
        );

        for (uint8 i = 0; i < stakedToken.length; i++) {
            require(
                tokenDetails[stakedToken[i]].isExist == true &&
                    tokenDetails[rewardToken[i]].isExist == true,
                "Token not exist"
            );
            tokenDailyDistribution[stakedToken[i]][
                rewardToken[i]
            ] = dailyDistribution[i];
        }
    }

    function updateSequence(
        address stakedToken,
        address[] memory rewardTokenSequence
    ) public onlyOwner {
        tokensSequenceList[stakedToken] = new address[](0);

        for (uint8 i = 0; i < rewardTokenSequence.length; i++) {
            require(
                rewardTokenSequence.length <= tokens.length,
                " Invalid Index"
            );
            require(
                tokenDetails[rewardTokenSequence[i]].isExist == true,
                "Token Not Exist"
            );
            tokensSequenceList[stakedToken].push(rewardTokenSequence[i]);
        }
    }

    function updateToken(
        address tokenAddress,
        uint256 userMaxStake,
        uint256 totalStake
    ) public onlyOwner {
        require(tokenDetails[tokenAddress].isExist == true, "Token Not Exist");
        tokenDetails[tokenAddress].userStakeLimit = userMaxStake;
        tokenDetails[tokenAddress].maxStake = totalStake;
        emit TokenDetails(
            tokenAddress,
            userMaxStake,
            totalStake,
            block.timestamp
        );
    }

    function updateStakeDuration(uint256 durationTime) public onlyOwner {
        stakeDuration = durationTime;
    }

    function updateIntervalDays(uint256[] memory _interval) public onlyOwner {
        intervalDays = new uint256[](0);

        for (uint8 i = 0; i < _interval.length; i++) {
            require(stakeDuration > _interval[i], "Invalid Interval Day");
            intervalDays.push(_interval[i]);
        }
    }

    function changeTokenBlockedStatus(
        address stakedToken,
        address rewardToken,
        bool status
    ) public onlyOwner {
        require(
            tokenDetails[stakedToken].isExist == true &&
                tokenDetails[rewardToken].isExist == true,
            "Token not exist"
        );
        tokenBlockedStatus[stakedToken][rewardToken] = status;
        emit TokenDetails(
            stakedToken,
            tokenDetails[stakedToken].userStakeLimit,
            tokenDetails[stakedToken].maxStake,
            block.timestamp
        );
    }

    function safeWithdraw(address tokenAddress, uint256 amount)
        public
        onlyOwner
    {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Insufficient Balance"
        );
        IERC20(tokenAddress).transfer(owner(), amount);
    }
}

pragma solidity >=0.6.0 <=0.8.0;

/**
 * @title Unifarm Contract
 * @author OroPocket
 */

contract Unifarm is Admin {
    // Wrappers over Solidity's arithmetic operations
    using SafeMath for uint256;
    
    // Stores Stake Details
    struct stakeInfo {
        address user;
        address[] tokenAddress;
        bool[] isActive;
        uint256[] stakeId;
        uint256[] stakedAmount;
        uint256[] startTime;
    }

    // Mapping
    mapping(address => stakeInfo) public stakingDetails;
    mapping(address => uint256) public totalStaking;
    mapping(address => mapping(address => uint256)) public tokenRewardsEarned;
    uint256 public constant DAYS = 1 days;
    
    // Events
    event Stake(
        address indexed userAddress,
        address indexed tokenAddress,
        uint256 stakedAmount,
        uint256 Time
    );
    event Claim(
        address indexed userAddress,
        address indexed stakedTokenAddress,
        address indexed tokenAddress,
        uint256 claimRewards,
        uint256 Time
    );
    event UnStake(
        address indexed userAddress,
        address indexed unStakedtokenAddress,
        uint256 unStakedAmount,
        uint256 Time
    );
    
    /**
     * @notice Stake tokens to earn rewards
     * @param tokenAddress Staking token address
     * @param amount Amount of tokens to be staked
     */
    function stake(address tokenAddress, uint256 amount) external {
        // checks 
        require(
            tokenDetails[tokenAddress].isExist == true,
            "STAKE : Token is not Exist"
        );
        require(
            amount <= tokenDetails[tokenAddress].userStakeLimit,
            "STAKE : Amount should be within permit"
        );
        require(
            totalStaking[tokenAddress].add(amount) <=
                tokenDetails[tokenAddress].maxStake,
            "STAKE : Maxlimit exceeds"
        );
        
        // Storing stake details
        stakingDetails[msg.sender].stakeId.push(
            stakingDetails[msg.sender].stakeId.length
        );
        stakingDetails[msg.sender].isActive.push(true);
        stakingDetails[msg.sender].user = msg.sender;
        stakingDetails[msg.sender].tokenAddress.push(tokenAddress);
        stakingDetails[msg.sender].stakedAmount.push(amount);
        stakingDetails[msg.sender].startTime.push(block.timestamp);

        // Update total staking amount
        totalStaking[tokenAddress] = totalStaking[tokenAddress].add(amount);
        
        // Transfer tokens from userf to contract
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        
        // Emit state changes
        emit Stake(msg.sender, tokenAddress, amount, block.timestamp);
    }
    
    /**
     * @notice Claim accumulated rewards
     * @param stakeId Stake ID of the user
     * @param stakedAmount Staked amount of the user
     */
     function claimRewards(uint256 stakeId, uint stakedAmount) internal {
        // Local variables
        uint256 rewardsEarned;
        uint256 interval;
        uint256 noOfDays;
        
        noOfDays = stakingDetails[msg.sender].startTime[stakeId].add(stakeDuration);
        // Interval calculation
        if (noOfDays > block.timestamp) {
            uint256 endOfProfit = block.timestamp;
            interval = endOfProfit.sub(
                stakingDetails[msg.sender].startTime[stakeId]
            );
        } else {
            uint256 endOfProfit = noOfDays;
            interval = endOfProfit.sub(
                stakingDetails[msg.sender].startTime[stakeId]
            );
        }
        
        // Reward calculation
        if (interval >= DAYS) {
            noOfDays = interval.div(DAYS);
            rewardsEarned = noOfDays.mul(
                getOneDayReward(
                    stakedAmount,
                    stakingDetails[msg.sender].tokenAddress[stakeId],
                    stakingDetails[msg.sender].tokenAddress[stakeId]
                )
            );
            sendToken(
                stakingDetails[msg.sender].tokenAddress[stakeId],
                stakingDetails[msg.sender].tokenAddress[stakeId],
                rewardsEarned
            );
            uint8 i = 1;
            while (i < intervalDays.length) {
                if (noOfDays >= intervalDays[i]) {
                    uint256 balDays = (noOfDays.sub(intervalDays[i].sub(1)));

                    address rewardToken =
                        tokensSequenceList[
                            stakingDetails[msg.sender].tokenAddress[stakeId]
                        ][i];

                    if (
                        rewardToken !=
                        stakingDetails[msg.sender].tokenAddress[stakeId] &&
                        tokenBlockedStatus[
                            stakingDetails[msg.sender].tokenAddress[stakeId]
                        ][rewardToken] ==
                        false
                    ) {
                        rewardsEarned = balDays.mul(
                            getOneDayReward(
                                stakedAmount,
                                stakingDetails[msg.sender].tokenAddress[stakeId],
                                rewardToken
                            )
                        );
                        sendToken(
                            stakingDetails[msg.sender].tokenAddress[stakeId],
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
    }
    
    /**
     * @notice Get rewards for one day 
     * @param stakedAmount Stake amount of the user
     * @param stakedToken Staked token address of the user
     * @param rewardToken Reward token address 
     * @return reward One dayh reward for the user
     */
    function getOneDayReward(
        uint256 stakedAmount,
        address stakedToken,
        address rewardToken
    ) public view returns (uint256 reward) {
        // Formula for reward calculation
        reward = (
            stakedAmount.mul(
                tokenDailyDistribution[stakedToken][rewardToken]
            )
        )
            .div(tokenDetails[stakedToken].maxStake);
    }
    
    /**
     * @notice Get rewards for one day 
     * @param stakedToken Stake amount of the user
     * @param tokenAddress Reward token address 
     * @param amount Amount to be transferred as reward
     */
    function sendToken(
        address stakedToken,
        address tokenAddress,
        uint256 amount
    ) internal {
        // Checks
        if (tokenAddress != address(0)) {
            require(
                IERC20(tokenAddress).balanceOf(address(this)) >= amount,
                "SEND : Insufficient Balance"
            );
            // Transfer of rewards
            IERC20(tokenAddress).transfer(msg.sender, amount);
            
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
    function unStake(uint256 stakeId) external returns (bool) {
        // Checks
        require(
            stakingDetails[msg.sender].stakedAmount[stakeId] > 0,
            "CLAIM : Insufficient Staked Amount"
        );
        
        // State updation 
        uint stakedAmount = stakingDetails[msg.sender].stakedAmount[stakeId];
        stakingDetails[msg.sender].stakedAmount[stakeId] = 0;
        stakingDetails[msg.sender].isActive[stakeId] = false;
        
        // Balance check
        require(
            IERC20(stakingDetails[msg.sender].tokenAddress[stakeId])
                .balanceOf(address(this)) >=
                stakedAmount,
            "UNSTAKE : Insufficient Balance"
        );
        
        // Transfer staked token back to user
        IERC20(stakingDetails[msg.sender].tokenAddress[stakeId]).transfer(
            msg.sender,
            stakedAmount
        );
        
        // Claim pending rewards
        claimRewards(stakeId, stakedAmount);

       // Emit state changes
        emit UnStake(
            msg.sender,
            stakingDetails[msg.sender].tokenAddress[stakeId],
            stakedAmount,
            block.timestamp
        );
        return true;
    }
    
    /**
     * @notice View staking details
     * @param _user User address
     */
    function viewStakingDetails(address _user)
        public
        view
        returns (
            address[] memory,
            bool[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            stakingDetails[_user].tokenAddress,
            stakingDetails[_user].isActive,
            stakingDetails[_user].stakeId,
            stakingDetails[_user].stakedAmount,
            stakingDetails[_user].startTime
        );
    }
    
        /**
     * @notice View accumulated rewards for staked tokens
     * @param user Wallet address of th user
     * @param stakeId Stake ID of the user
     * @param rewardTokenAddress Staked token of the user
     * @return availableReward Returns the avilable rewards 
     */
    function viewAvailableRewards(
        address user,
        uint256 stakeId,
        address rewardTokenAddress
    ) public view returns (uint256 availableReward) {
        
        // Checks
        require(
            stakingDetails[user].stakedAmount[stakeId] > 0,
            "CLAIM : Insufficient Staked Amount"
        );
    
        // Local variables
        uint256 rewardsEarned;
        uint256 interval;
        uint256 noOfDays;
        
        noOfDays = stakingDetails[user].startTime[stakeId].add(stakeDuration);
        // Interval calculation
        if (noOfDays > block.timestamp) {
            uint256 endOfProfit = block.timestamp;
            interval = endOfProfit.sub(stakingDetails[user].startTime[stakeId]);
        } else {
            uint256 endOfProfit = noOfDays;
            interval = endOfProfit.sub(stakingDetails[user].startTime[stakeId]);
        }

        if (interval >= DAYS) {
            noOfDays = interval.div(DAYS);
            rewardsEarned = noOfDays.mul(
                getOneDayReward(
                    stakingDetails[user].stakedAmount[stakeId],
                    stakingDetails[user].tokenAddress[stakeId],
                    stakingDetails[user].tokenAddress[stakeId]
                )
            );
            
            if(rewardTokenAddress == stakingDetails[user].tokenAddress[stakeId])
                return rewardsEarned;
                
            else {
                // Reward calculation for given reward token address
                uint8 i = 1;
                while (i < intervalDays.length) {
                    if (noOfDays >= intervalDays[i]) {
                        uint256 balDays = (noOfDays.sub(intervalDays[i].sub(1)));
    
                        address rewardToken =
                            tokensSequenceList[
                                stakingDetails[user].tokenAddress[stakeId]
                            ][i];
    
                        if (
                            rewardToken !=
                            stakingDetails[user].tokenAddress[stakeId] &&
                            tokenBlockedStatus[
                                stakingDetails[user].tokenAddress[stakeId]
                            ][rewardToken] ==
                            false
                        ) {
                            if (rewardToken == rewardTokenAddress) {
                                rewardsEarned = balDays.mul(
                                    getOneDayReward(
                                        stakingDetails[user].stakedAmount[stakeId],
                                        stakingDetails[user].tokenAddress[stakeId],
                                        rewardToken
                                    )
                                );
    
                                return (rewardsEarned);
                            }
                        }
                        i = i + 1; 
                    } else {
                        break;
                    }
                }
            }
        }
    }
}