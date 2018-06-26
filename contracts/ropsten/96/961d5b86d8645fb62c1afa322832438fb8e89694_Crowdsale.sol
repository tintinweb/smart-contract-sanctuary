pragma solidity ^0.4.23;

contract Control {
    address public owner;
    bool public pause;

    event PAUSED();
    event STARTED();

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier whenPaused {
        require(pause);
        _;
    }

    modifier whenNotPaused {
        require(!pause);
        _;
    }

    function setOwner(address _owner) onlyOwner public {
        owner = _owner;
    }

    function setState(bool _pause) onlyOwner public {
        pause = _pause;
        if (pause) {
            emit PAUSED();
        } else {
            emit STARTED();
        }
    }
    
    constructor() public {
        owner = msg.sender;
    }
}

contract ERC20Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    function symbol() public constant returns (string);
    function decimals() public constant returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Share {
    function onIncome() public payable;
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

contract Crowdsale is Control {
    using SafeMath for uint256;

    // The token being sold
    ERC20Token public token;

    address public tokenFrom;
    function setTokenFrom(address _from) onlyOwner public {
        tokenFrom = _from;
    }

    // Address where funds are collected
    Share public wallet;
    function setWallet(Share _wallet) onlyOwner public {
        wallet = _wallet;
    }

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a DetailedShare token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 public rate;
    function adjustRate(uint256 _rate) onlyOwner public {
        rate = _rate;
    }

    uint256 public weiRaiseLimit;
    
    function setWeiRaiseLimit(uint256 _limit) onlyOwner public {
        weiRaiseLimit = _limit;
    }
    
    // Amount of wei raised
    uint256 public weiRaised;
  
    /**
      * Event for token purchase logging
      * @param purchaser who paid for the tokens
      * @param beneficiary who got the tokens
      * @param value weis paid for purchase
      * @param amount amount of tokens purchased
      */
    event TokenPurchase (
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    modifier onlyAllowed {
        require(weiRaised < weiRaiseLimit);
        _;
    }
  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, Share _wallet, ERC20Token _token, address _tokenFrom, uint256 _ethRaiseLimit) 
  public 
  {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    owner = msg.sender;
    rate = _rate;
    wallet = _wallet;
    token = _token;
    tokenFrom  = _tokenFrom;
    weiRaiseLimit = _ethRaiseLimit * (10 ** 18);
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
  function buyTokens(address _beneficiary) public payable onlyAllowed whenNotPaused {

    uint256 weiAmount = msg.value;
    if (weiAmount > weiRaiseLimit.sub(weiRaised)) {
        weiAmount = weiRaiseLimit.sub(weiRaised);
    }
    
    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);
    
    if (address(wallet) != address(0)) {
        wallet.onIncome.value(weiAmount)();
    }
    
    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );
    
    if(msg.value.sub(weiAmount) > 0) {
        msg.sender.transfer(msg.value.sub(weiAmount));
    }
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transferFrom(tokenFrom, _beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }



  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount / rate;
  }
  
  function withdrawl() public {
      owner.transfer(address(this).balance);
  }
}