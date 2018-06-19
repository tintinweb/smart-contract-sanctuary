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
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

/**
 * @dev XGETokensale contract describes deatils of
 * Exchangeable Gram Equivalent tokensale
 */
contract XGETokensale is Pausable, Destructible {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;    

    // Amount of wei raised
    uint256 public weiRaised;

    /**
     * @dev Price of XGE token in dollars is fixed as 1.995
     * so in order to calculate the right price from this variable
     * we need to divide result by 1000
     */
    uint256 public USDXGE = 1995;

    /**
     * @dev Price of ETH in dollars
     * To save percition we base it onto 10**18
     * and mutiply by 1000 to compensate USGXGE
     */
    uint256 public USDETH = 400 * 10**21;

    /**
     * @dev minimum amount of tokens that can be bought
     */
    uint256 public MIN_AMOUNT = 100 * 10**18;

    /**
     * Whitelist of approved buyers
     */
    mapping(address => uint8) public whitelist;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * Event for adding new beneficeary account to the contract whitelist
     * @param beneficiary who will get the tokens
     */
    event WhitelistAdd(address indexed beneficiary);
    
    /**
     * Event for removing beneficeary account from the contract whitelist
     * @param beneficiary who was gonna get the tokens
     */
    event WhitelistRemove(address indexed beneficiary);

    /**
     * Event for update USD/ETH conversion rate
     * @param oldRate old rate
     * @param newRate new rate
     */
    event USDETHRateUpdate(uint256 oldRate, uint256 newRate);
    
    /**
     * Event for update USD/XGE conversion rate
     * @param oldRate old rate
     * @param newRate new rate
     */
    event USDXGERateUpdate(uint256 oldRate, uint256 newRate);
  
    /**
     * @dev XGETokensale constructor
     * @param _wallet wallet that will hold the main balance
     * @param _token address of deployed XGEToken contract
     */
    function XGETokensale(address _wallet, ERC20 _token) public
    {
        require(_wallet != address(0));
        require(_token != address(0));

        owner = msg.sender;
        wallet = _wallet;
        token = _token;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Function that updates ETH/USD rate
     * Meant too be called only by owner
     */
    function updateUSDETH(uint256 rate) public onlyOwner {
        require(rate > 0);
        USDETHRateUpdate(USDETH, rate * 10**18);
        USDETH = rate * 10**18;
    }

    /**
     * @dev Function that updates ETH/XGE rate
     * Meant too be called only by owner
     */
    function updateUSDXGE(uint256 rate) public onlyOwner {
        require(rate > 0);
        USDETHRateUpdate(USDXGE, rate);
        USDXGE = rate;
    }

    /**
     * @dev Mail method that contains tokensale logic
     */
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != address(0));
        require(whitelist[_beneficiary] != 0);
        require(msg.value != 0);

        uint256 weiAmount = msg.value;
        uint256 rate = USDETH.div(USDXGE);

        uint256 tokens = weiAmount.mul(rate).div(10**18);

        // Revert if amount of tokens less then minimum
        if (tokens < MIN_AMOUNT) {
            revert();
        }

        weiRaised = weiRaised.add(weiAmount);
        token.transferFrom(owner, _beneficiary, tokens);
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        wallet.transfer(weiAmount);
    }

    /**
     * @dev Add buyer to whitelist so it will possbile for him to buy a token
     * @param buyer address to add
     */
    function addToWhitelist(address buyer) public onlyOwner {
        require(buyer != address(0));
        whitelist[buyer] = 1;
        WhitelistAdd(buyer);
    }

    /**
     * @dev Remove buyer fromt whitelist
     * @param buyer address to remove
     */
    function removeFromWhitelist(address buyer) public onlyOwner {
        require(buyer != address(0));
        delete whitelist[buyer];
        WhitelistRemove(buyer);
    }
}