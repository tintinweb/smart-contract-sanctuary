/**
 *Submitted for verification at Etherscan.io on 2021-03-06
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

    // These get stored on the blockchain
    // Owner is the person who deployes the contract
    address public owner;
    string public name = "Dapp Token Farm";
    IERC20Mintable public dappToken;

    
    struct staker {
        uint256 id;
        mapping(address=> uint256) balance;
        mapping(address=> uint256) timestamp;
        mapping(address=> uint256) timefeestartstamp; 

    }

    struct rate {
        uint256 rate;
        bool exists;
    }

    // people that have ever staked
    mapping(address => uint256) public totalStaked;
    address[] private tokenPools; 
    mapping(address => staker) stakers;
    mapping(address => rate) public RatePerCoin;
	mapping (address=>bool) Admins;
    uint256 public minimumDaysLockup=3;
    uint256 public penaltyFee=10;
    // This is passing in addresses, I can find them manually
    constructor(IERC20Mintable _dapptoken, address _spiritclashtoken)
        public
    {
        dappToken = _dapptoken;
        owner = msg.sender;
        Admins[msg.sender]=true;
		setCoinRate(_spiritclashtoken,80000);
    }

    // 1. Stakes Tokens(Deposit)
    function stakeTokens(uint256 _amount,IERC20 token) external { // remove payable
        // Require amount greater than 0
		require(RatePerCoin[address(token)].exists==true,"token doesnt have a rate");
        require(_amount > 0, "amount cannot be 0");
        if (stakers[msg.sender].balance[address(token)] > 0) {
            claimToken(address(token));
        }

        // Transfer Mock Dai tokens to this contract for staking
        token.transferFrom(msg.sender, address(this), _amount);

        // Update staking balance
        stakers[msg.sender].balance[address(token)] = stakers[msg.sender].balance[address(token)].add( _amount);
        totalStaked[address(token)] = totalStaked[address(token)].add( _amount);
        stakers[msg.sender].timestamp[address(token)] = block.timestamp;
        stakers[msg.sender].timefeestartstamp[address(token)] = block.timestamp;
    }

    //  Unstaking Tokens(Withdraw)

    function unstakeToken(IERC20 token) external {
        // Fetch staking balance
        uint256 balance = stakers[msg.sender].balance[address(token)];

        // Require amount greater then 0
        require(balance > 0, "staking balance cannot be 0");
        // Check to see if the sender has waited longer then 3 days before withdrawl
        if( (block.timestamp.sub(stakers[msg.sender].timefeestartstamp[address(token)])) < (minimumDaysLockup*24*60*60)){  
            uint256 fee = (balance.mul(100).div(penaltyFee)).div(100);
            token.transfer(owner, fee);
            balance = balance.sub(fee); 
        }
        claimTokens();

        // Reset staking balance
        stakers[msg.sender].balance[address(token)] = 0;
        totalStaked[address(token)] = totalStaked[address(token)].sub(balance);
        //transfer unstaked coins
        token.transfer(msg.sender, balance);
    }

    function unstakeTokens() external{ // this is fine
        
        claimTokens();
        for (uint i=0; i< tokenPools.length; i++){
            uint256 balance = stakers[msg.sender].balance[tokenPools[i]];
            if(balance > 0){
                // Check to see if the sender has waited longer then 3 days before withdrawl
                totalStaked[tokenPools[i]] = totalStaked[tokenPools[i]].sub(balance);
                stakers[msg.sender].balance[tokenPools[i]] = 0;
                if((block.timestamp.sub(stakers[msg.sender].timefeestartstamp[tokenPools[i]])) < (minimumDaysLockup*24*60*60)){
                    uint256 fee = (balance.mul(100).div(penaltyFee)).div(100);
                    balance = balance.sub(fee);
                    IERC20(tokenPools[i]).transfer(owner, fee);
                }
                IERC20(tokenPools[i]).transfer(msg.sender, balance);
            }
        }
    }

	function earned(address token) public view returns(uint256){ // this is fine
        uint256 multiplier =100000000;
		return (stakers[msg.sender].balance[token]* 
            (RatePerCoin[token].rate) * //coin earn rate in percentage so should be divided by 100
                ( 
                    (stakers[msg.sender].balance[token]*multiplier)/(totalStaked[token]) //calculate token share percentage
                )/(365*24*60*60)// 31 536 000
                ///seconds per year
            *(
                block.timestamp.sub(stakers[msg.sender].timestamp[token]) // get time
                
            )
        )/multiplier/10;
	}


    function claimTokens() public { // This function looks good to me.
        uint256 rewardbal=0;
		for (uint i=0; i< tokenPools.length; i++){
            address token = tokenPools[i];
            if(stakers[msg.sender].balance[token]>0){
                uint256 earnings = earned(token);
                stakers[msg.sender].timestamp[token]=block.timestamp;
                rewardbal= rewardbal.add(earnings);
            }
        }
        IERC20Mintable(dappToken).mint(msg.sender, rewardbal);
    }
    function claimToken(address token) public { // For sure an issue
        require(stakers[msg.sender].balance[token]>0,"you have no balance and cant claim");
        uint256 earnings = earned(token);
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

pragma solidity ^0.5.0;

contract ClashPay {
    using SafeMath for uint256;
    string  public name = "Clash Pay";
    string  public symbol = "SCP";
    uint256 public totalSupply = 10000000000000000000;
    uint8   public decimals = 18;
    address public owner;
    address public Tokenfarm;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Burn(
        address indexed burner,
        uint256 value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        owner= msg.sender;
    }
    function setContract(address _contract) external{
        require(msg.sender==owner,"must be owner");
        Tokenfarm=_contract;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(address(0)!= _to,"to burn tokens use the burn function");
        balanceOf[msg.sender] =balanceOf[msg.sender].sub( _value);
        balanceOf[_to] = balanceOf[_to].add( _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(address(0)!= _to,"to burn tokens use the burn function");
        balanceOf[_from] = balanceOf[_from].sub( _value); // msg.sender => _from
        balanceOf[_to] = balanceOf[_to].add( _value);
        allowance[_from][msg.sender] =allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function mint(address _to,uint256 _value) public {
        require(msg.sender==Tokenfarm,"only Tokenfarm contract can mint tokens");
        totalSupply= totalSupply.add( _value);
        balanceOf[_to]=balanceOf[_to].add(_value);
        emit Transfer(address(0),msg.sender,_value);
    }
    function burn(uint256 _value) public{
        balanceOf[msg.sender] =balanceOf[msg.sender].sub( _value);
        emit Burn(msg.sender,_value);
        emit Transfer(msg.sender,address(0),_value);
    }
    function transferOwnership(address _newOwner) external{
        require(msg.sender==owner,"only the owner an call this function");
        owner=_newOwner;

    }

}