pragma solidity ^0.4.24;

contract IERC20 {
    function totalSupply() pure public returns (uint _totalSupply);
    function balanceOf(address _owner) pure public returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) pure public returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


library SafeMathLib {

  function times(uint a, uint b) pure public returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) pure public returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) pure public returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

/**
 * @title Ownable
 * @notice The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract TDX {

    address public owner;
    /**
    * @notice The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @notice Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @notice Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

/**
 * @title Sale
 * @notice The Token Sale contract
 */
contract Sale is TDX {

  using SafeMathLib for uint256;
  using SafeMathLib for uint8;

  IERC20 token;
  address tokenAddressWallet;
  address etherAddressWallet;
  
  uint256 public constant CAP = 15000000 * 10**8;
  uint256 public constant tokensPerPhase = 5000000 * 10**8;
  uint256 public PHASE1_START = 1533254400;
  uint256 public PHASE1_END = 1536451200;
  
  uint256 public PHASE2_START = 1536451200;
  uint256 public PHASE2_END = 1539648000;
  
  uint256 public PHASE3_START = 1539648000;
  uint256 public PHASE3_END = 1543017600;

  // For First phase, price is 1/2,
  // For Second phase, price is 3/4,
  // For Third phase, price is 1
  uint256 usdPerEther = 1000;
  
  //Total Tokens Sold
  uint256 public tokensSold;
  uint256[] public tokensSoldPerPhase;

  bool public initialized = false;

  modifier IsLive() {
    // Check if sale is active
    assert(isSaleLive());
    _;
  }

  constructor(
      address _tokenAddr,
      address _etherAddr,
      address _tokenWalletAddr
      ) public {
      require(_tokenAddr != 0);
      token = IERC20(_tokenAddr);
      etherAddressWallet = _etherAddr;
      tokenAddressWallet = _tokenWalletAddr;
  }

  /**
   * @notice Initializes the Sale
   * Required as we need to Ensure the pre-requirements are met.
   */
  function initialize() public onlyOwner {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() == CAP); // Must have enough tokens allocated
      initialized = true;
  }

  /**
   * @notice Checks if the sale is Live.
   */
  function isSaleLive() public constant returns (bool) {
    return ( 
        initialized == true &&
        getPhase() != 0 &&
        goalReached() == false // Goal must not already be reached
    );
  }

  /**
   * @notice Checks whether the Goal is Reached.
   */
  function goalReached() public constant returns (bool) {
    if (tokensSold >= CAP) {
      token.transfer(tokenAddressWallet, token.balanceOf(this));
      return true;
    }
    return false;
  }
  
  function () public payable {
    sellTokens();
  }

  function sellTokens() payable IsLive {
    require(msg.value > 0);
    uint256 tokens;
    uint8 phase = getPhase();
    
    if (phase == 1) {
        tokens = (((msg.value) / usdPerEther) / 2) / 10 **10;
    } else if (phase == 2) {
        tokens = (((msg.value).times(3) / usdPerEther) / 4) / 10 **10;
    } else if (phase == 3) {
        tokens = ((msg.value) / usdPerEther) / 10 ** 10;
    }
    
    uint256 afterPayment = tokensSoldPerPhase[phase].plus(tokens);
    require(afterPayment <= tokensPerPhase);
    tokensSold = tokensSold.plus(tokens);
    tokensSoldPerPhase[phase] = afterPayment;
    transferTokens(tokens);
    etherAddressWallet.transfer(msg.value);
  }
  
  function getPhase() public constant returns (uint8) {
      if (now >= PHASE1_START && now <= PHASE1_END) {
        return 1;
      } else if (now >= PHASE2_START && now <= PHASE2_END) {
        return 2;
      } else if (now >= PHASE3_START && now <= PHASE3_END) {
        return 3;
      } else if(now >= PHASE3_END) {
          terminateSale();
      } else {
        return 0;
      }
  }
  
   function transferTokens(uint256 tokens) private {
      token.transfer(msg.sender, tokens);
      tokensSold = tokensSold.plus(tokens);
  }

  function tokensAvailable() public constant returns (uint256) {
    return token.balanceOf(this);
  }

  function terminateSale() internal {
    token.transfer(tokenAddressWallet, token.balanceOf(this));
  }

  function terminateTokenSale() public onlyOwner {
      terminateSale();
  }

  function terminateContract() public onlyOwner {
      terminateSale();
      selfdestruct(etherAddressWallet);
  }

}