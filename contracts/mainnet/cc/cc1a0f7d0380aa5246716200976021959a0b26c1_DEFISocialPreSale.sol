/**
 *Submitted for verification at Etherscan.io on 2020-12-01
*/

pragma solidity ^0.6.7;



/**
 * @title ProofPresale 
 * ProofPresale allows investors to make
 * token purchases and assigns them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet 
 * as they arrive.
 */
 library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function transfer(address, uint) external returns (bool);
}

contract DEFISocialPreSale is Ownable {
  using SafeMath for uint;

  // The token being sold
  //DEFISocial public token;
    address payable public constant token = payable(0x731A30897bF16597c0D5601205019C947BF15c6E);

  // address where funds are collected
  address payable public wallet;

  // amount of raised money in wei
  uint256 public weiRaised;
  

  // cap above which the crowdsale is ended
  uint256 public cap;
  uint256 public tokensLeft;
  uint256 public tokensBought;

  uint256 public minInvestment;

  uint256 public rate;

  bool public isFinalized ;



  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * event for signaling finished crowdsale
   */
  event Finalized();



  /**
   * crowdsale constructor
   * @param _wallet who receives invested ether
   * @param _minInvestment is the minimum amount of ether that can be sent to the contract
   * @param _cap above which the crowdsale is closed
   * @param _rate is the amounts of tokens given for 1 ether
   */ 

  function start(address payable _wallet, uint256 _minInvestment, uint256 _cap, uint256 _rate) public onlyOwner {
    
    require(_wallet != 0x0000000000000000000000000000000000000000);
    require(_minInvestment >= 0);
    require(_cap > 0);
 
    wallet = _wallet;
    rate = _rate;
    minInvestment = _minInvestment;  //minimum investment in wei  (=10 ether)
    cap = _cap * (10**18);  //cap in tokens base units (=295257 tokens)
    tokensBought = 0;
    tokensLeft = cap;
  }

     function tokBought() view public  returns (uint256) {
    return tokensBought;
  }
    function tokLeft() view public  returns (uint256) {
    return tokensLeft;
  }
  

  // fallback function to buy tokens
  receive () external payable {
      if(msg.sender == owner){
          
      }else{
          buyTokens(msg.sender, msg.value);
      }
   
  }
  
    
  
  /**
   * Low level token purchse function
   * @param beneficiary will recieve the tokens.
   */
  function buyTokens(address beneficiary, uint256 amount)  public payable {
    require(beneficiary != 0x0000000000000000000000000000000000000000, "Error");
    require(validPurchase(), "Not a valid purchase");
    require(!isFinalized, "Finalized");
    require(tokensLeft > 0, "No more tokens left");
    


    uint256 weiAmount = amount;
    
    // compute amount of tokens created
    uint256 tokens = weiAmount.mul(rate);

    require(Token(token).transfer(beneficiary, tokens), "Could not transfer tokens.");
    tokensBought = tokensBought.add(tokens);
    tokensLeft = tokensLeft.sub(tokens);
    // update weiRaised
    weiRaised = weiRaised.add(weiAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
    
  }

  // send ether to the fund collection wallet
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // return true if the transaction can buy tokens
  function validPurchase() internal  returns (bool) {

    uint256 weiAmount = weiRaised.add(msg.value);
    bool notSmallAmount = msg.value >= minInvestment;
    bool withinCap = weiAmount.mul(rate) <= tokensLeft;

    return (notSmallAmount && withinCap);
  }

  //allow owner to finalize the presale once the presale is ended
  function end() private onlyOwner {
    require(!isFinalized);
    require(hasEnded());

    Finalized();

    isFinalized = true;
  }



  //return true if crowdsale event has ended
   function hasEnded() view public  returns (bool) {
    bool capReached = (weiRaised.mul(rate) >= cap);
    return capReached;
  }
    


}