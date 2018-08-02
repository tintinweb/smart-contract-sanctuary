pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param _rate Number of token units a buyer gets per wei
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     */
    constructor(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = (_rate/1*10**18);
        wallet = _wallet;
        token = _token;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;

        require(_beneficiary != address(0));
        require(weiAmount != 0);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase( msg.sender, _beneficiary, weiAmount,tokens);

        _forwardFunds();
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------


    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title EncrybitCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
contract EncrybitCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;
    
    /////////////////////// VARIABLE INITIALIZATION ///////////////////////
    
    uint256 constant startTimeForPreSale = 12;
    uint256 constant endTimeForPreSale = 12;
    
    uint256 constant startTimeForCrowdSale = 12;
    uint256 constant endTimeForCrowdSale = 12;
    
    uint256 public tokensIssued;
    
    // Amount to wei raised
    uint256 public constant tokenForSale = 162000000; // 162 millons token to sell
    
    
    /////////////////////// MODIFIERS ///////////////////////

    // Ensure actions can only happen during Presale
    modifier duringPresale(){
        require(now <= endTimeForPreSale);
        require(now >= startTimeForPreSale);
        _;
    }
    
    // Ensure actions can only happen during CrowdSale
    modifier duringCrowdsale(){
        require(now <= endTimeForCrowdSale);
        require(now >= startTimeForCrowdSale);
        _;
    }
    
    modifier notCloseICO(){
        require(!closed);
        _;
    }
    
     modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }
    
     /////////////////////// EVENTS ///////////////////////

    /**
     * Event for token withdrawal logging
     * @param receiver who receive the tokens
     * @param amount amount of tokens sent
     */
    event TokenDelivered(address indexed receiver, uint256 amount);

    /**
   * Event for token adding by referral program
   * @param beneficiary who got the tokens
   * @param amount amount of tokens added
   */
    event TokenAdded(address indexed beneficiary, uint256 amount);    
    
    ///////////////////////  ///////////////////////

    // Map of all purchaiser&#39;s balances (doesn&#39;t include bounty amounts)
    mapping(address => uint256) public balances;

    // Is a crowdsale closed?
    bool public closed;


    /**
    * Init crowdsale by setting its params
    *
    * @param _rate Number of token units a buyer gets per wei
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    */
    constructor (uint256 _rate, address _wallet, ERC20 _token) Crowdsale(_rate, _wallet, _token) public {
            /*
            1 * 10**18 wei = 20 000 tokens
            1 wei = 0.00000000000002
            */
            
    }
uint256 public  ratef = 20000/1*10**18;
    /**
     * @dev Overrides parent by storing balances instead of issuing tokens right away.
     * @param _beneficiary Token purchaser
     * @param _tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) onlyWallet notCloseICO internal {
        balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
        tokensIssued = tokensIssued.add(_tokenAmount);
    }

    /**
   * @dev Overrides the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
    function _getTokenAmount(uint256 _weiAmount) onlyWallet internal view returns (uint256) {
        uint256  tokenWithoutBonus = _weiAmount.mul(rate);
        uint256  tokenBonus = getRate();
        return tokenWithoutBonus.add(tokenBonus);
    }

    /**
     * @dev Deliver tokens to receiver_ after crowdsale ends.
     */
    function withdrawTokensFor(address receiver_) public onlyOwner {
        _withdrawTokensFor(receiver_);
    }

    /**
     * @dev Withdraw tokens excess on the contract after crowdsale.
     */
    function postCrowdsaleWithdraw(uint256 _tokenAmount) public onlyOwner {
        token.transfer(wallet, _tokenAmount);
    }

    /**
     * @dev Withdraw tokens for receiver_ after crowdsale ends.
     */
    function _withdrawTokensFor(address receiver_) internal {
        require(closed);
        uint256 amount = balances[receiver_];
        require(amount > 0);
        balances[receiver_] = 0;
        emit TokenDelivered(receiver_, amount);
        _deliverTokens(receiver_, amount);
    }
    
     // Returns EBT disbursed per 1 ETH depending on current time
    function getRate() public constant returns (uint price) {
        if (now > (startTimeForPreSale + 5 days)) {
           return 5000; 
        } else if (now > (startTimeForPreSale + 4 days)) {
           return 4000; 
        } else if (now > (startTimeForPreSale + 3 days)) {
           return 3000; 
        }  else if (now > (startTimeForPreSale + 2 days)) {
           return 2000; 
        } else if (now > (startTimeForPreSale + 1 days)) {
           return 1000; 
        } else {
           return 100; 
        }
    }
    
    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) notCloseICO public payable {

        uint256 weiAmount = msg.value;

        require(_beneficiary != address(0));
        require(weiAmount != 0);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        
        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase( msg.sender, _beneficiary, weiAmount,tokens);

        _forwardFunds();
        if(tokenForSale == tokensIssued) closed = true;
    }
    

}

// Minimum and Maximium Ether to purchase