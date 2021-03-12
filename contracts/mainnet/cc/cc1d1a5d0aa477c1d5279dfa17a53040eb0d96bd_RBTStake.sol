/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: UNLICENSED

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

    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        require(m != 0, "SafeMath: to ceil number shall not be zero");
        return (a + m - 1) / m * m;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract RBTStake is Owned{
    using SafeMath for uint256;
    
    address private saleContract;
    address private tokenAddress;
    
    uint256 public cliffPeriodStarted;
    
    event SaleContractSet(address by, address saleAddress);
    event UserTokensStaked(address by, address user, uint256 tokensPurchased);
    event RewardClaimDateSet(address by, uint256 rewardClaimDate);
    event RewardsClaimed(address by, uint256 rewards);
    
    struct StakedTokens{
        uint256 tokens;
        uint256 stakeDate;
    }
    
    mapping(address => StakedTokens) public purchasedRBT;
    mapping(address => uint256) public rewardRBT;
    
    modifier onlySaleContract{
        require(msg.sender == saleContract, "UnAuthorized");
        _;
    }
    
    modifier isPurchaser{
        require(purchasedRBT[msg.sender].tokens > 0 , "UnAuthorized");
        _;
    }
    
    modifier isClaimable{
        require(block.timestamp >= cliffPeriodStarted, "reward claim date has not reached");
        require(cliffPeriodStarted > 0, "cannot claim reward. cliff period has not started");
        _;
    }
    
    constructor(address _tokenAddress) public{
        tokenAddress = _tokenAddress;
    }
    
    function SetSaleContract(address _saleContract) external onlyOwner{
        require(_saleContract != address(0), "Invalid address");
        require(saleContract == address(0), "address already set");
        
        saleContract = _saleContract;
        
        emit SaleContractSet(msg.sender, _saleContract);
    }
    
    function StakeTokens(address _ofUser, uint256 _tokens) external onlySaleContract returns(bool){
        purchasedRBT[_ofUser].tokens = purchasedRBT[_ofUser].tokens.add(_tokens);
        purchasedRBT[_ofUser].stakeDate = block.timestamp;
        emit UserTokensStaked(msg.sender, _ofUser, _tokens);
        
        return true;
    }
    
    function SetRewardClaimDate() external onlySaleContract returns(bool){
        cliffPeriodStarted = block.timestamp;
        RewardClaimDateSet(msg.sender, cliffPeriodStarted);
        
        return true;
    }
    
    function ClaimReward() external isPurchaser isClaimable {
        uint256 rewards = _calculateReward(cliffPeriodStarted, msg.sender);
        require(rewards > 0, "nothing pending to be claimed");
        require(rewardRBT[msg.sender] == 0, "already claimed");
        
        rewardRBT[msg.sender] = rewards;
        
        IERC20(tokenAddress).transfer(msg.sender, rewards);
        
        emit RewardsClaimed(msg.sender, rewards);
    }
    
    function _calculateReward(uint256 toDate, address _user) internal view returns(uint256) {
        uint256 totalStakeTime = (toDate.sub(purchasedRBT[_user].stakeDate)).div(/*24 hours*/ 1 days); // in days
        uint256 rewardsAvailable = (totalStakeTime.mul(30).mul(purchasedRBT[_user].tokens)).div(365 * 100); // to take percentage div by 100
        return  rewardsAvailable;
    }
    
    function pendingReward(address _user) public view returns(uint256){
        uint256 reward;
        if(block.timestamp > cliffPeriodStarted && cliffPeriodStarted > 0)
            reward =  _calculateReward(cliffPeriodStarted, _user); 
        else
            reward = _calculateReward(block.timestamp, _user);
        return reward.sub(rewardRBT[_user]);
    }
    
    function getBackExtraTokens() external onlyOwner{
        uint256 tokens = IERC20(tokenAddress).balanceOf(address(this));
        require(IERC20(tokenAddress).transfer(owner, tokens), "No tokens in contract");
    }
    
}