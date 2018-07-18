pragma solidity ^0.4.21;


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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
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
    address public fundWallet;
    
    // the admin of the crowdsale
    address public admin;

    // Exchange rate:  1 eth = 10,000 TAUR
    uint256 public rate = 10000;

    // Amount of wei raised
    uint256 public amountRaised;

    // Crowdsale Status
    bool public crowdsaleOpen;

    // Crowdsale Cap
    uint256 public cap;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  /**
   * @param _token - Address of the token being sold
   * @param _fundWallet - THe wallet where ether will be collected
   */
    function Crowdsale(ERC20 _token, address _fundWallet) public {
        require(_token != address(0));
        require(_fundWallet != address(0));

        fundWallet = _fundWallet;
        admin = msg.sender;
        token = _token;
        crowdsaleOpen = true;
        cap = 20000 * 1 ether;
    }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
    function () external payable {
        buyTokens();
    }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   */
    function buyTokens() public payable {

        // do necessary checks
        require(crowdsaleOpen);
        require(msg.sender != address(0));
        require(msg.value != 0);
        require(amountRaised.add(msg.value) <= cap);
        
        // calculate token amount to be created
        uint256 tokens = (msg.value).mul(rate);

        // update state
        amountRaised = amountRaised.add(msg.value);

        // transfer tokens to buyer
        token.transfer(msg.sender, tokens);

        // transfer eth to fund wallet
        fundWallet.transfer(msg.value);

        emit TokenPurchase (msg.sender, msg.value, tokens);
    }

    function lockRemainingTokens() onlyAdmin public {
        token.transfer(admin, token.balanceOf(address(this)));
    }

    function setRate(uint256 _newRate) onlyAdmin public {
        rate = _newRate;    
    }
    
    function setFundWallet(address _fundWallet) onlyAdmin public {
        require(_fundWallet != address(0));
        fundWallet = _fundWallet; 
    }

    function setCrowdsaleOpen(bool _crowdsaleOpen) onlyAdmin public {
        crowdsaleOpen = _crowdsaleOpen;
    }

    function getEtherRaised() view public returns (uint256){
        return amountRaised / 1 ether;
    }

    function capReached() public view returns (bool) {
        return amountRaised >= cap;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }  

}