/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

//SPDX-License-Identifier: none
pragma solidity 0.8.4;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface BEP20{
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract FarmingTest {
    
    using SafeMath for uint;
    
    // Variables
    address private owner;
    address private contractAddr = address(this);
    uint rewardPool = 900000*10**18;
    uint rewardPercent = 1000;
    uint private stakedUsers = 0;
    uint finalTime = 36500 days;
    
    BEP20 lpToken;
    BEP20 rewardToken;
    
    struct UserStake {
        uint[] amount;
        uint[] withdrawnReward;
        uint[] stakedAt;
        uint[] rewardWithdrawnAt;
    }
    
    mapping(address => bool) public stakeStatus;
    mapping(address => uint) public userStakeNum;
    mapping(address => UserStake) userStake;
    
    event Staked(address, uint);
    event Unstaked(address, uint);
    event Received(address, uint);
    
    // Constructor sets address for lpToken and rewardToken
    constructor(address _lpToken, address _rewardToken) {
        lpToken = BEP20(_lpToken);
        rewardToken = BEP20(_rewardToken);
        owner = msg.sender;
    }
    
    // Stake function 
    // Takes LP tokens as input
    // User has to approve this contract from LP token contract to stake
    function stake(uint _amount) public {
        address sender = msg.sender;
        require(_amount > 0, "Cannot stake zero amount");
        require(rewardPool > 0, "Reward pool limit reached");
        require(lpToken.balanceOf(sender) >= _amount, "Insufficient amount of user");
        userStakeNum[sender] += 1;
        userStake[sender].amount.push(_amount);
        userStake[sender].stakedAt.push(block.timestamp);
        userStake[sender].withdrawnReward.push(0);
        userStake[sender].rewardWithdrawnAt.push(0);
        
        if(stakeStatus[sender] == false){
            stakeStatus[sender] = true;
            stakedUsers += 1;
        }
        
        lpToken.transferFrom(sender, contractAddr, _amount);
        emit Staked(sender, _amount);
    }
    
    // Calculation of reward for particular user and index
    function viewReward(address addr, uint index) public view returns (uint reward) {
        if(userStake[addr].amount[index] != 0){
            UserStake storage user = userStake[addr];
            uint end = user.stakedAt[index] + finalTime;
            uint since = user.rewardWithdrawnAt[index] != 0 ? user.rewardWithdrawnAt[index] : user.stakedAt[index];
            uint till = block.timestamp > end ? end : block.timestamp;
            reward = user.amount[index].mul(till.sub(since)).mul(rewardPercent.div(stakedUsers)).div(finalTime).div(100);
        }
        else{
            reward = 0;
        }
        
        return reward;
    }
    
    // Withdraw reward 
    // Reward will be given in form of rewardToken
    // If the reward pool is very less, the leftover reward is sent to the User
    function withdrawReward(uint stakeIndex) public {
        address sender = msg.sender;
        require(stakeStatus[sender] == true, "User has not staked or has unstaked");
        require(userStake[sender].amount[stakeIndex] != 0, "User has not staked or has already unstaked");
        uint rewardAmount = viewReward(sender, stakeIndex);
        require(rewardToken.balanceOf(contractAddr) > rewardAmount, "Not enough reward balance on contract");
        
        if(rewardPool < rewardAmount){
            rewardAmount = rewardPool;
        }
        
        userStake[sender].withdrawnReward[stakeIndex] = rewardAmount;
        userStake[sender].rewardWithdrawnAt[stakeIndex] = block.timestamp;
        rewardPool -= rewardAmount;
        rewardToken.transfer(sender, rewardAmount);
        emit Unstaked(sender, rewardAmount);
    }
    
    // Unstake LP tokens
    // Unstaking will be done according to index value of stake 
    // This will stop generating rewards for that index point stake 
    // Reduces total staked user count if all of the stakes are Unstaked
    // Transfers any leftover reward for that indexed stake
    function unstake(uint index) public {
        address receiver = msg.sender;
        UserStake storage user = userStake[receiver];
        uint stakedLp = user.amount[index];
        uint leftoverReward;
        
        require(stakeStatus[receiver] == true, "User has not staked or has already unstaked");
        require(lpToken.balanceOf(contractAddr) >= stakedLp, "Contract balance for LP token insufficient");
        
        if(viewReward(receiver, index) != 0){
            leftoverReward = viewReward(receiver, index);
            require(rewardToken.balanceOf(contractAddr) >= leftoverReward, "Left over reward balance error on contract");
            rewardToken.transfer(receiver, leftoverReward);
        }
        
        lpToken.transfer(receiver, stakedLp);
        uint len = user.amount.length;
        
        for(uint i = 0; i < len; i++){
            if(user.amount[i] == 0){
                stakedUsers -= 1;
                stakeStatus[receiver] = false;
            }
        }
        userStakeNum[receiver] -= 1;
        delete user.amount[index];
        emit Unstaked(receiver, stakedLp);        
    }
    
    // View user details
    function viewDetails(address addr) public view returns(
    uint[] memory amounts,
    uint[] memory stakedAt,
    uint[] memory rewardWithdrawn,
    uint[] memory rewardWithdrawnAt
    ){
        UserStake storage user = userStake[addr];
        uint len = user.amount.length;
        amounts = new uint[](len);
        stakedAt = new uint[](len);
        rewardWithdrawn = new uint[](len);
        rewardWithdrawnAt = new uint[](len);
        
        for(uint i = 0; i < len; i++){
            amounts[i] = user.amount[i];
            stakedAt[i] = user.stakedAt[i];
            rewardWithdrawn[i] = user.withdrawnReward[i];
            rewardWithdrawnAt[i] = user.rewardWithdrawnAt[i];
        }
        
        return (amounts, stakedAt, rewardWithdrawn, rewardWithdrawnAt);
    }
        
    
    // Show Reward pool that is available 
    function viewRewardPool() public view returns (uint) {
        return rewardPool;
    }
    
    // Show total stakes users on contract
    function showStakedUsers() public view returns (uint){
        return stakedUsers;
    }
    
    // Show owner address
    function getOwner() public view returns(address) {
        return owner;
    }
    
    // Transfer Ownership of this contract 
    // Only owner can call this function
    function ownershipTransferred(address to) public {
        require(msg.sender == owner, "Only owner can call this function");
        owner = to;
    }
    
    // Owner Token withdraw 
    function ownerTokenWithdraw(address tokenAddress, address to, uint amount) public {
        require(msg.sender == owner, "Only owner can call this function");
        BEP20 token = BEP20(tokenAddress);
        token.transfer(to, amount);
    }
    
    // Owner BNB withdraw 
    function ownerBnbWithdraw(address payable to, uint amount) public {
        require(msg.sender == owner, "Only owner can call this function");
        to.transfer(amount);
    }
    
    // Fallback function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
}