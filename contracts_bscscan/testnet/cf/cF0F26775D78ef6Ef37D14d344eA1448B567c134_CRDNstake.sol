// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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


contract CRDNstake{
    
    using SafeMath for uint256;
    IERC20 public stakeToken;

    address payable public owner;
    uint256 public maxStakeableToken;
    uint256 public totalStakedToken;
    uint256 public totalUnStakedToken;
    uint256 public totalWithdrawanToken;
    uint256 public totalStakers;
    uint256 public unstakePercentage;
    uint256 public percentDivider;
    uint256 [4] public Duration = [ 3 minutes , 6 minutes , 9 minutes , 18 minutes ];
    uint256 [4] public Bonus = [ 25 , 83 , 150 , 400 ];
    
    struct Stake{
        uint256 withdrawtime;
        uint256 staketime;
        uint256 amount;
        uint256 reward;
        uint256 persecondreward;
        bool withdrawan;
        bool unstaked;
    }
    
    struct User{
        uint256 totalStakedTokenUser;
        uint256 totalWithdrawanTokenUser;
        uint256 totalUnStakedTokenUser;
        uint256 stakeCount;
        bool alreadyExists;
        
    }
    
    mapping (address => User) public Stakers;
    mapping (uint256 => address) public StakersID;
    mapping (address => mapping (uint256 => Stake)) public stakersRecord;
    event STAKE(address Staker, uint256 amount);
    event UNSTAKE(address Staker, uint256 amount);
    event WITHDRAW(address Staker, uint256 amount);

    
    modifier onlyowner(){
        require(owner == msg.sender,"not accessable");
        _;
    }
    
    constructor(address payable _owner,address token){
        owner = _owner;
        stakeToken = IERC20(token);
        maxStakeableToken =  stakeToken.totalSupply();
        unstakePercentage = 950;
        percentDivider = 1000;
    }
    
    function stake(uint256 amount , uint256 timeperiod) public{
        require(timeperiod >=0 && timeperiod <=3 , "Invalid Time Period");
        if(!Stakers[msg.sender].alreadyExists){
            Stakers[msg.sender].alreadyExists = true;
            StakersID[totalStakers] = msg.sender;
            totalStakers++;
        }
        stakeToken.transferFrom(msg.sender,owner,amount);
        uint256 index = Stakers[msg.sender].stakeCount;
        Stakers[msg.sender].totalStakedTokenUser += amount;
        totalStakedToken += amount;
        stakersRecord[msg.sender][index].withdrawtime = block.timestamp + Duration[timeperiod];
        stakersRecord[msg.sender][index].staketime = block.timestamp;
        stakersRecord[msg.sender][index].amount = amount;
        stakersRecord[msg.sender][index].reward = amount.mul(Bonus[timeperiod]).div(percentDivider);
        stakersRecord[msg.sender][index].persecondreward = stakersRecord[msg.sender][index].reward.div(Duration[timeperiod]);
        Stakers[msg.sender].stakeCount++;
        emit STAKE(msg.sender, amount);
    }
    
    function unstake(uint256 index) public{
        require(!stakersRecord[msg.sender][index].withdrawan,"can't unstake already withdrawan");
        require(!stakersRecord[msg.sender][index].unstaked,"already unstaked" );
        stakersRecord[msg.sender][index].unstaked = true;
        stakeToken.transferFrom(owner,msg.sender,(stakersRecord[msg.sender][index].amount).mul(unstakePercentage).div(percentDivider));
        totalUnStakedToken += stakersRecord[msg.sender][index].amount.mul(unstakePercentage).div(percentDivider);
        Stakers[msg.sender].totalUnStakedTokenUser += stakersRecord[msg.sender][index].amount.mul(unstakePercentage).div(percentDivider);
        emit UNSTAKE(msg.sender,stakersRecord[msg.sender][index].amount.mul(unstakePercentage).div(percentDivider));
    }
    
    function withdraw(uint256 index) public{
        require(!stakersRecord[msg.sender][index].withdrawan,"can't unstake already withdrawan");
        require(!stakersRecord[msg.sender][index].unstaked,"already unstaked" );
        stakersRecord[msg.sender][index].withdrawan = true;
        stakeToken.transferFrom(owner,msg.sender,stakersRecord[msg.sender][index].amount);
        stakeToken.transferFrom(owner,msg.sender,stakersRecord[msg.sender][index].reward);
        totalWithdrawanToken += stakersRecord[msg.sender][index].amount;
        totalWithdrawanToken += stakersRecord[msg.sender][index].reward;
        Stakers[msg.sender].totalWithdrawanTokenUser += stakersRecord[msg.sender][index].amount;
        Stakers[msg.sender].totalWithdrawanTokenUser += stakersRecord[msg.sender][index].reward;
        emit WITHDRAW(msg.sender, stakersRecord[msg.sender][index].reward+stakersRecord[msg.sender][index].amount);
    }
    
    function SetUnStakePercentage(uint256 value) external onlyowner {
        unstakePercentage = value;
    }
    function SetMaxStakeableToken(uint256 value) external onlyowner {
        maxStakeableToken = value ;
    }
    function SetDuration(uint256 first, uint256 second, uint256 third, uint256 fourth) external onlyowner {
        Duration[0] = first;
        Duration[1] = second;
        Duration[2] = third;
        Duration[3] = fourth;
    }
    function SetBonus(uint256 first, uint256 second, uint256 third, uint256 fourth) external onlyowner {
        Bonus[0] = first;
        Bonus[1] = second;
        Bonus[2] = third;
        Bonus[3] = fourth;
    }

    function transferFundsBNB(uint256 value) external onlyowner {
        require(value <= address(this).balance," Insufficent Funds ");
        owner.transfer(value);
    }
    function realtimeReward(address user) public view returns(uint256){
        uint256 ret;
        for(uint256 i ; i < Stakers[user].stakeCount ; i++){
            if(!stakersRecord[user][i].withdrawan && !stakersRecord[user][i].unstaked)
            {
                 uint256 val;
                 val =  block.timestamp - stakersRecord[user][i].staketime;
                 if(val < stakersRecord[user][i].reward){
                     val = val.mul(stakersRecord[user][i].persecondreward);
                 ret += val;
                 }else{
                     ret += stakersRecord[user][i].reward;
                 }
                 
            }
        }
        return ret;
    }
    function transferLostAsset(address TokenAddress) external onlyowner {
        IERC20(TokenAddress).transfer(owner,IERC20(TokenAddress).balanceOf(address(this)));
    }
    
    
}

