/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.5.0;

/**
 * The TokenFarm contract does this and that...
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() public view returns (uint8);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract IERC20Mintable {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() public view returns (uint8);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address _to,uint256 _value) public;
    function burn(uint256 _value) public;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TokenFarm {
    using SafeMath for uint256;
	modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
	modifier onlyModerators {
        require(
            Admins[msg.sender]==true,
            "Only owner can call this function."
        );
        _;
    }

    event Stake(uint256 amount, address token,address staker,uint256 stakeTime);
    event Unstake(address token,address staker);

    address public owner;
    string public name = "Clash Farm";
    IERC20Mintable public dappToken;


    struct staker {
        uint256 id;
        mapping(address=> uint256) balance;
        mapping(address=> uint256) lockedUpTill;
        mapping(address=> uint256) timestamp;
        mapping(address=> uint256) startTimestamp;
    }

    struct rate {
        uint256 rate;
        bool exists;
    }

    mapping(address => uint256) public totalStaked;
    address[] public tokenPools;
    mapping(address => staker) public stakers;
    mapping(address => rate) public RatePerCoin;
	mapping (address=>bool) Admins;
    uint256 public minimumDaysLockup=3;
    uint256 public penaltyFee=10;

    constructor(IERC20Mintable _dapptoken, address _spiritclashtoken)
        public
    {
        dappToken = _dapptoken;
        owner = msg.sender;
        Admins[msg.sender]=true;
		setCoinRate(_spiritclashtoken,80000);
    }

    function stakeTokens(uint256 _amount,IERC20 token,uint256 lockupTime) external {
        require(lockupTime>=minimumDaysLockup && lockupTime<366,"lockup time not allowed");
		require(RatePerCoin[address(token)].exists==true,"token doesnt have a rate");
        require(_amount > 0, "amount cannot be 0");
        token.transferFrom(msg.sender, address(this), _amount);

        stakers[msg.sender].balance[address(token)] = stakers[msg.sender].balance[address(token)].add( _amount);
        totalStaked[address(token)] = totalStaked[address(token)].add( _amount);
        stakers[msg.sender].timestamp[address(token)] = block.timestamp;
        stakers[msg.sender].startTimestamp[address(token)] = block.timestamp;
        stakers[msg.sender].lockedUpTill[address(token)]= block.timestamp.add(lockupTime* 1 days);
        emit Stake(_amount,address(token),msg.sender,lockupTime);
    }

    function unstakeToken(IERC20 token) external {
        staker storage stake = stakers[msg.sender];
        uint256 balance = stake.balance[address(token)];

        require(balance > 0, "staking balance cannot be 0");
        
        claimToken(address(token));

        stake.balance[address(token)] = 0;
        totalStaked[address(token)] = totalStaked[address(token)].sub(balance);

        token.transfer(msg.sender, balance);
        emit Unstake(address(token),msg.sender);
    }

    function unstakeTokens() external{
        claimTokens();
        for (uint i=0; i< tokenPools.length; i++){
            uint256 balance = stakers[msg.sender].balance[tokenPools[i]];
            if(balance > 0){
                totalStaked[tokenPools[i]] = totalStaked[tokenPools[i]].sub(balance);
                stakers[msg.sender].balance[tokenPools[i]] = 0;
                IERC20(tokenPools[i]).transfer(msg.sender, balance);
                emit Unstake(address(tokenPools[i]),msg.sender);
            }
        }
    }

	function earned(address token) public view returns(uint256){ 
		return (stakers[msg.sender].balance[token]*
            (RatePerCoin[token].rate)                 
                    /(365 days)
            *(
                block.timestamp.sub(stakers[msg.sender].timestamp[token])
            )
        )/10;
	}

    function timeStaked(address token) public view returns(uint256){
        return block.timestamp.sub(stakers[msg.sender].startTimestamp[token]);
    }

    function claimTokens() public {
        uint256 rewardbal=0;
        uint256 fee =0;
		for (uint i=0; i< tokenPools.length; i++){
            address token = tokenPools[i];
            if(stakers[msg.sender].balance[token]>0){
                uint256 earnings = earned(token);
                if(block.timestamp<stakers[msg.sender].lockedUpTill[token]){
                    fee= fee.add((earnings.div(100).mul(penaltyFee)));
                }
                stakers[msg.sender].timestamp[token]=block.timestamp;
                rewardbal= rewardbal.add(earnings);
            }
        }
        if(fee>0){
            IERC20Mintable(dappToken).mint(owner, fee);
            rewardbal = rewardbal.sub(fee);
        }
        IERC20Mintable(dappToken).mint(msg.sender, rewardbal);
    }
    function claimToken(address token) public {
        require(stakers[msg.sender].balance[token]>0,"you have no balance and cant claim");
        uint256 earnings = earned(token);
        if(block.timestamp < stakers[msg.sender].lockedUpTill[address(token)]){
            uint256 fee = earnings.div(100).mul(penaltyFee);
            earnings = earnings.sub(fee);
            IERC20Mintable(dappToken).mint(owner, fee);
        }
        stakers[msg.sender].timestamp[token]=block.timestamp;
        IERC20Mintable(dappToken).mint(msg.sender, earnings);
    }

    function setMinimumLockup(uint256 _days) external onlyModerators {
        minimumDaysLockup =_days;
    }

    function setPenaltyFee(uint256 _fee) external onlyModerators {
        penaltyFee =_fee;
    }

    function transferOwnership(address _newOwner) external onlyOwner{
        owner=_newOwner;
    }

    function setCoinRate(address coin,uint256 Rate) public onlyModerators {
        RatePerCoin[coin].rate =Rate;
        if(RatePerCoin[coin].exists == false){
            tokenPools.push(coin);
            RatePerCoin[coin].exists = true;
        }
    }

	function setAdmin(address addy,bool value) external onlyOwner{
		Admins[addy]= value;
	}
    function stakingBalance(address token) external view returns(uint256) {
        return stakers[msg.sender].balance[token];
    }
}