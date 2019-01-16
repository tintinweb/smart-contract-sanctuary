pragma solidity 0.4.25;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

interface TokenInterface {
     function totalSupply() external constant returns (uint);
     function balanceOf(address tokenOwner) external constant returns (uint balance);
     function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
     function transfer(address to, uint tokens) external returns (bool success);
     function approve(address spender, uint tokens) external returns (bool success);
     function transferFrom(address from, address to, uint tokens) external returns (bool success);
     function burn(uint256 _value) external;
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     event Burn(address indexed burner, uint256 value);
}

 contract FeedCrowdsale is Ownable{
  using SafeMath for uint256;
 
  // The token being sold
  TokenInterface public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;


  // how many token units a buyer gets per wei
  uint256 public ratePerWei = 11905;

  // amount of raised money in wei
  uint256 public weiRaised;
  
  uint256 public weiRaisedInPreICO;

  uint256 TOKENS_SOLD;

  bool isCrowdsalePaused = false;
  
  uint256 decimals = 18;
  
  uint256 step1Contributions = 0;
  uint256 step2Contributions = 0;
  uint256 step3Contributions = 0;
  uint256 step4Contributions = 0;
  uint256 step5Contributions = 0;
  uint256 step6Contributions = 0;
  uint256 step7Contributions = 0;
  uint256 step8Contributions = 0;
  
  
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(address _wallet, address _tokenAddress) public 
  {
    require(_wallet != 0x0);
    owner = _wallet;
    token = TokenInterface(_tokenAddress);
  }
  
  
   // fallback function can be used to buy tokens
   function () public  payable {
     buyTokens(msg.sender);
    }
    
    function calculateTokens(uint etherAmount) public returns (uint tokenAmount) {
        
        if (etherAmount >= 0.05 ether && etherAmount < 0.09 ether)
        {
            //step 1 
            require(step1Contributions<1000);
            tokenAmount = uint(1000).mul(uint(10)** decimals);
            step1Contributions = step1Contributions.add(1);
        }
        else if (etherAmount>=0.09 ether && etherAmount < 0.24 ether )
        {
            //step 2
            require(step2Contributions<1000);
            tokenAmount = uint(2000).mul(uint(10)** decimals);
            step2Contributions = step2Contributions.add(1);
            
        }
        else if (etherAmount>=0.24 ether && etherAmount<0.46 ether )
        {
            //step 3 
            require(step3Contributions<1000);
            tokenAmount = uint(6000).mul(uint(10)** decimals);
            step3Contributions = step3Contributions.add(1);
        
        }
        else if (etherAmount>=0.46 ether && etherAmount<0.90 ether)
        {
            //step 4 
            require(step4Contributions<1000);
            tokenAmount = uint(13000).mul(uint(10)** decimals);
            step4Contributions = step4Contributions.add(1);
        
        }
        else if (etherAmount>=0.90 ether && etherAmount<2.26 ether)
        {
            //step 5 
            require(step5Contributions<1000);
            tokenAmount = uint(25000).mul(uint(10)** decimals);
            step5Contributions = step5Contributions.add(1);
        
        }
        else if (etherAmount>=2.26 ether && etherAmount<4.49 ether)
        {
            //step 6 
            require(step6Contributions<1000);
            tokenAmount = uint(60000).mul(uint(10)** decimals);
            step6Contributions = step6Contributions.add(1);
        
        }
        else if (etherAmount>=4.49 ether && etherAmount<8.99 ether)
        {
            //step 7 
            require(step7Contributions<1000);
            tokenAmount = uint(130000).mul(uint(10)** decimals);
            step7Contributions = step7Contributions.add(1);
        
        }
        else if (etherAmount>=8.99 ether && etherAmount<=10 ether)
        {
            //step 8
            require(step8Contributions<1000);
            tokenAmount = uint(200000).mul(uint(10)** decimals);
            step8Contributions = step8Contributions.add(1);
        
        }
        else 
        {
            revert();
        }
    }
  // low level token purchase function
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(isCrowdsalePaused == false);
    require(msg.value>0);
    
    uint256 weiAmount = msg.value;
    
    // calculate token amount to be created
    uint256 tokens = calculateTokens(weiAmount);
    
    // update state
    weiRaised = weiRaised.add(weiAmount);
    token.transfer(beneficiary,tokens);
    
    emit TokenPurchase(owner, beneficiary, weiAmount, tokens);
    TOKENS_SOLD = TOKENS_SOLD.add(tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  function forwardFunds() internal {
    owner.transfer(msg.value);
  }

 
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
    
    /**
    * function to change the rate of tokens
    * can only be called by owner wallet
    **/
    function setPriceRate(uint256 newPrice) public onlyOwner {
        ratePerWei = newPrice;
    }
    
     /**
     * function to pause the crowdsale 
     * can only be called from owner wallet
     **/
     
    function pauseCrowdsale() public onlyOwner {
        isCrowdsalePaused = true;
    }

    /**
     * function to resume the crowdsale if it is paused
     * can only be called from owner wallet
     **/ 
    function resumeCrowdsale() public onlyOwner {
        isCrowdsalePaused = false;
    }
    
     function getUnsoldTokensBack() public onlyOwner
     {
        uint contractTokenBalance = token.balanceOf(address(this));
        require(contractTokenBalance>0);
        token.transfer(owner,contractTokenBalance);
     }
}