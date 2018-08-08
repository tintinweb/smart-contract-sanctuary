pragma solidity ^0.4.11;
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract SynToken {
    string public name = "TEST TOKEN";
    string public symbol = "TEST";
    uint256 public decimals = 18;
    
    uint256 public totalSupply;
    address public owner;
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    bool public mintingFinished = false;

    /**
     * @dev Throws if called by any account other than the owner.
     */

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) ;
    
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) ;
    

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

        /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) ;
    
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) returns (bool success);

    function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success);

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount)  public returns (bool);

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public returns (bool);


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public;
}


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract SynTokenCrowdsale {
    using SafeMath for uint256;

    // The token being sold
    SynToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    /*
    Custom vars
   */

    uint256 public cap = 500*10**24;//500milllion SYN
    uint256 public foundationAmount = (2*cap)/3;// 2/3s of cap
    address public tokenWallet = 0x2411350f3bCAFd33a9C162a6672a93575ec151DC;
    uint256 public tokensSold = 0;//for ether raised, call weiRaised and convert to ether
    address public admin = 0x2411350f3bCAFd33a9C162a6672a93575ec151DC;
    uint[] public salesRates = [2000,2250,2500]; 
    address public constant SynTokenAddress = 0x2411350f3bCAFd33a9C162a6672a93575ec151DC;  

    bool public crowdsaleLive = false;
    bool public crowdsaleInit = false;
    bool public appliedPresale = false;

    event NextRate(uint256 _rate);

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function SynTokenCrowdsale() {
    }

    // fallback function can be used to buy tokens
    function () payable {
        buyTokens(msg.sender);
    }

    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

//OVERLOADED/CUSTOM METHODS
  modifier adminOnly{
    if(msg.sender == admin) //    SHOULD THIS BE MSG.SENDER NOT MSG.SEND
    _;
    
  } 


    // low level token purchase function
function buyTokens(address beneficiary) public payable {
require(beneficiary != 0x0);
require(validPurchase());

uint256 weiAmount = msg.value;

// calculate token amount to be created
uint256 tokens = weiAmount.mul(rate);

//revert purchase attempts beyond token supply
require(tokens <= cap - tokensSold); 

// update state
weiRaised = weiRaised.add(weiAmount);
tokensSold = tokensSold.add(tokens);

token.mint(beneficiary, tokens);
TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
forwardFunds();
}
// @return true if the transaction can buy tokens
function validPurchase() internal constant returns (bool) {

bool capNotReached = tokensSold <= cap;   
bool withinPeriod = now >= startTime && now <= endTime;
bool nonZeroPurchase = msg.value != 0;
    if(now >= startTime){
        forwardRemaining();
    }
return (nonZeroPurchase && withinPeriod && capNotReached) ;
}

//forward all remaining tokens to the foundation address
function forwardRemaining() internal {
    require(crowdsaleLive);
require(now > endTime);
uint256 remaining = cap - tokensSold;
require(remaining < cap);
tokensSold += remaining;
token.mint(tokenWallet, remaining);
    token.finishMinting();
    crowdsaleLive = false;
}

function nextRate(uint _rate) adminOnly {
require(now > endTime);
require(salesRates[_rate] < rate );
rate = salesRates[_rate];
}

function setToken(address _tokenAddress){
    token = SynToken(_tokenAddress);
}


function initCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _tokenAddress) adminOnly {
    require(!crowdsaleInit);    
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    crowdsaleInit=true;
}


function applyPresale() adminOnly{

    require(crowdsaleInit);
    require(!appliedPresale);

    token.mint(0x3de1483fda9f3383c422d8713008e5d272aa73ee, 35448897500000000000000);
	token.mint(0xe695e2d9243303dccff5a26731cc0083f3b10c8b, 100000000000000000000000);
	token.mint(0x1bf45eb62434a0dac0de59753e431210d2b33f24, 32500000000000000000000);
	token.mint(0x92009d954ff9efd69708e2dd2166f7e60124ce09, 22500000000000000000000);
	token.mint(0xe579c7b478d40c85871ac5553d488b65be9a9264, 1250000000000000000000);
	token.mint(0xa576e704a1c1d8d7e2fdfdd251b15a3265397121, 2500000000000000000000);
	token.mint(0x9e40c7ee30cefb4327ea2c83869cd161ff5fa71f, 250000000000000000000);
	token.mint(0xcc6b7ed85bf68ee9def96b95f3356a8072a01030, 50008790160000000000000);
	token.mint(0xf406317925ad6a9ea40cdf40cc1c9b0dd65ca10c, 250000000000000000000000);
	token.mint(0x69965bb6487178234ddcc835cb2ceccadd4e1431, 1250000000000000000000);
	token.mint(0xe7558aa60d1135410f03479df94ea439e782d541, 1950000000000000000000);
	token.mint(0x75360cbe8c7cb8174b1b623a6d9aacf952c117e3, 50000000000000000000000);
	token.mint(0x001a1a6ccf3b97b983d709c0d34a0de574b90a19, 2500000000000000000000);
	token.mint(0x56488a1d3dc8bb20b75e8317448f1a1fbadcb999, 2725000000000000000000);
	token.mint(0xf16e0aa06d745026bc80686e492b0f9b0578b5bd, 3200000000000000000000);
	token.mint(0xc046b59484843b2af6ca105afd88a3ab60e9b7cd, 1250000000000000000000);
	token.mint(0x479a8f11ee100a1cc99cd06e67dba639aaec56f7, 12489500000000000000000);
	token.mint(0x9369263b70dec0b65064bd6967e6b01c3a9377ec, 750000000000000000000);
	token.mint(0x89560c2b6b343ad4f6e47b19b9577bfce938ce98, 10000000000000000000000);
	token.mint(0xdcc719cf97c9cbc06e4e8f05ed8d9b2132fe7f31, 12500000000000000000000);
	token.mint(0x5ac855600754de7fc9796add50b82554324424bb, 20362000000000000000000);
	token.mint(0xa1b710593ed03670c9424c941130b3a073a694cc, 3016378887500000000000);
	token.mint(0x8186bda406b950da9690e58199479aa008160709, 150000000000000000000);
	token.mint(0xb87b8dc38f027b1ce89a6519dbeb705bdd251ea5, 2500000000000000000000);
	token.mint(0x294751d928994780f6db76af14e343d4eb9c3a46, 1354326960000000000000000);
	token.mint(0x339d2fbaf46acb13ffc43636c5ae5b81d442e1e2, 124999876147500000000000);
	token.mint(0xdfcf69c8fed25f5150db719bad4efab64f628d31, 10000000000000000000000);
	token.mint(0x0460529cea44e59fb7e45a6cd6ff0b8b17b680c3, 125000000000000000000000);

	tokensSold+=2233427402695000000000000;

	token.mint(tokenWallet, foundationAmount);

	tokensSold = tokensSold + foundationAmount;
	appliedPresale=true;
    }
}