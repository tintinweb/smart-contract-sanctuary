/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity 0.5.6;

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20 {
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


contract staking{
    using SafeMath for uint256;
    
    
    // Min Stake amount = 100 Tokens
    
    struct User{
        address user;
        // uint stakedAmount;
        // uint StakingTime;
        uint Id;
    }
    
    struct Transaction{
        uint stakingTime;
        uint stakingAmount;
    }
    
    // address[] public StakedUsersArray;
    
    ERC20 public stakingToken;
    ERC20 public rewardToken;
    address[] public stakeholders;
    uint256 public numOfStakeHolders;
    address private owner;
    uint oneDay = 1 days;
    uint oneMinute = 1 minutes;
    
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public rewards;
    
    mapping(address=>Transaction[]) public transactions;
    mapping(address => mapping(uint => User)) public userStakedMap;
    
    event staked(address indexed user,uint indexed Id);
    event unstaked(address indexed user,uint indexed Id);
    
    event Stake(address indexed staker, uint256 _tokens);
    event Unstake(address indexed unstaker, uint256 _tokens);
    event Withdraw(address indexed withdrawer,uint256 _points);
    
    constructor(address _stakingToken, address _rewardToken, address _owner) public{
           stakingToken = ERC20(_stakingToken);
           rewardToken = ERC20(_rewardToken);
           owner = _owner;
    }
    
    modifier onlyOwner() {
        msg.sender == owner;
        _;
    }
    
    // Staking Token 0x3bdF3c6130003F8C04Bd52f32ff623d66EC85AaC
    // Reward Token 0x932d80879422af53096c8a2fbf64385b285cf53f
    // Admin Address 0x662C6Db67995835A202bDd88ad177156B8Ab6Aed
    
    //Stake the Tokens
    function createStake(uint _amount) public {
        //Condition for Staking
        require(stakingToken.balanceOf(msg.sender)>=_amount,"You don't have enough tokens to stake!");
        require(_amount >= 100, "Minnimum Tokens should be 100");
        require(_amount <= stakingToken.allowance(msg.sender, address(this)) , "Token Allowance must be equall or Greater than Amount of Tokens you want to stake");
        
        //Transfering Tokens Using transferFrom
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        transactions[msg.sender].push(Transaction(now,_amount));
        emit Stake(msg.sender, _amount);
    }
    
    //for owner to transfer Tokens into smart contract for users Rewards
    function transferRewardToken(uint _amount) public onlyOwner returns(bool, uint) {
        require(_amount != 0, "Reward Tokens amount is Zero, Please Transfer more");
        rewardToken.transferFrom(msg.sender, address(this), _amount);
        uint tokenLeft = rewardToken.balanceOf(address(this));
        return(true, tokenLeft);
    }
    
    //for calculating the user Reward
    function calReward(address _user) public view returns(uint){
        uint256 rewardOfUser;
            uint stakedAmount = transactions[_user][0].stakingAmount.div(100);
            uint StakingDays = now.sub(transactions[_user][0].stakingTime);
            StakingDays = StakingDays.div(oneMinute);
            rewardOfUser =  StakingDays.mul(stakedAmount);
        return rewardOfUser;
        
    }
    
    
    //TODO 
    // function totalStakedReward() public onlyOwner returns(uint){
        
    // }
    
    //Checks the Total Deposist of User
    function totalDeposited(address _user)public view returns(uint256){
        uint256 totalAmount;
        for(uint256 i=0;i<transactions[_user].length;i++){
            totalAmount = transactions[_user][i].stakingAmount;
        }
        return totalAmount;
    }
    
    //Unstake the users Tokens and REward 
    function unStake() public  {
        require(totalDeposited(msg.sender) >= 0,"You don't have tokens to unstake!");
        
        //tranferring Tokens & Reward to user Address
        stakingToken.transfer(msg.sender,totalDeposited(msg.sender));
        rewardToken.transfer(msg.sender,calReward(msg.sender));
        delete transactions[msg.sender];
        
        emit Unstake(msg.sender,totalDeposited(msg.sender));
        }
        
    //Withdraw the reward to user Address
    function withdrawReward() public {
        require(calReward(msg.sender) >=0 ,"You don't have any reward!");
        
        //tranferring Tokens to user Address
        rewardToken.transfer(msg.sender,calReward(msg.sender));
        for(uint256 i=0;i<transactions[msg.sender].length;i++){
            transactions[msg.sender][i].stakingTime=now;
        }
        emit Withdraw(msg.sender,calReward(msg.sender));
    }
    
}