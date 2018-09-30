pragma solidity ^0.4.23;


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
    function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
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
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
        msg.sender,
        _beneficiary,
        weiAmount,
        tokens
        );

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        // optional override
    }

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
     * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        // optional override
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
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
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
contract owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
		}

	}

contract Killable is owned {
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}

contract ERC20_ICO is owned, Killable {
    /// The token we are selling
    ERC20 public token;

    /// the UNIX timestamp start date of the crowdsale
    uint256 public startsAt = 1541030400;

    /// the UNIX timestamp end date of the crowdsale
    uint256 public endsAt = 1543536000;

    /// the price of token
    uint256 public TokenPerETH = 3333;

    /// Has this crowdsale been finalized
    bool public finalized = false;

    /// the number of tokens already sold through this contract
    uint256 public tokensSold = 0;

    /// the number of ETH raised through this contract
    uint256 public weiRaised = 0;

    /// How many distinct addresses have invested
    uint256 public investorCount = 0;

    /// How much Token minimum sale.
    uint256 public Soft_Cap = 3000000000000000000000;

    /// How much Token maximum sale.
    uint256 public Hard_Cap = 12000000000000000000000;

    /// How much ETH each address has invested to this crowdsale
    mapping (address => uint256) public investedAmountOf;

    /// list of investor
    address[] public investorlist;

    /// A new investment was made
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount);
    /// Crowdsale Start time has been changed
    event StartsAtChanged(uint256 startsAt);
    /// Crowdsale end time has been changed
    event EndsAtChanged(uint256 endsAt);
    /// Calculated new price
    event RateChanged(uint256 oldValue, uint256 newValue);
    
    constructor (address _token) public {
        token = ERC20(_token);
    }

    function investInternal(address receiver) private {
        require(!finalized);
        require(startsAt <= now && endsAt > now);
        require(tokensSold <= Hard_Cap);
        require(msg.value >= 10000000000000000);

        if(investedAmountOf[receiver] == 0) {
            // A new investor
            investorCount++;
            investorlist.push(receiver) -1;
        }

        // Update investor
        uint256 tokensAmount = msg.value * TokenPerETH;
        investedAmountOf[receiver] += msg.value;
        // Update totals
        tokensSold += tokensAmount;
        weiRaised += msg.value;

        // Tell us invest was success
        emit Invested(receiver, msg.value, tokensAmount);

        if (msg.value >= 100000000000000000 && msg.value < 10000000000000000000 ) {
            // 0.1-10 ETH 20% Bonus
            tokensAmount = tokensAmount * 120 / 100;
        }
        if (msg.value >= 10000000000000000000 && msg.value < 30000000000000000000) {
            // 10-30 ETH 30% Bonus
            tokensAmount = tokensAmount * 130 / 100;
        }
        if (msg.value >= 30000000000000000000) {
            // 30 ETh and more 40% Bonus
            tokensAmount = tokensAmount * 140 / 100;
        }

        token.transfer(receiver, tokensAmount);

        // Transfer Fund to owner&#39;s address
        owner.transfer(address(this).balance);

    }

    function () public payable {
        investInternal(msg.sender);
    }

    function setStartsAt(uint256 time) onlyOwner public {
        require(!finalized);
        startsAt = time;
        emit StartsAtChanged(startsAt);
    }
    function setEndsAt(uint256 time) onlyOwner public {
        require(!finalized);
        endsAt = time;
        emit EndsAtChanged(endsAt);
    }
    function setRate(uint256 value) onlyOwner public {
        require(!finalized);
        require(value > 0);
        emit RateChanged(TokenPerETH, value);
        TokenPerETH = value;
    }

    function finalize() public onlyOwner {
        // Finalized Pre ICO crowdsele.
        finalized = true;
        uint256 tokensAmount = token.balanceOf(this);
        token.transfer(owner, tokensAmount);
    }
}