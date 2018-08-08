/**
 * Investors relations: <span class="__cf_email__" data-cfemail="80f0e1f2f4eee5f2f3c0e1f2e2e9f4f2e1e7e9eee7aee3ef">[email&#160;protected]</span>
**/

pragma solidity ^0.4.18;

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
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
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Standard
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface OldXRPCToken {
    function transfer(address receiver, uint amount) external;
    function balanceOf(address _owner) external returns (uint256 balance);
    function mint(address wallet, address buyer, uint256 tokenAmount) external;
    function showMyTokenBalance(address addr) external;
}
contract ARBITRAGEToken is ERC20Interface,Ownable {

   using SafeMath for uint256;
    uint256 public totalSupply;
    mapping(address => uint256) tokenBalances;
   
   string public constant name = "ARBITRAGE";
   string public constant symbol = "ARB";
   uint256 public constant decimals = 18;

   uint256 public constant INITIAL_SUPPLY = 10000000;
    address ownerWallet;
   // Owner of account approves the transfer of an amount to another account
   mapping (address => mapping (address => uint256)) allowed;
   event Debug(string message, address addr, uint256 number);

    function ARBITRAGEToken(address wallet) public {
        owner = msg.sender;
        ownerWallet=wallet;
        totalSupply = INITIAL_SUPPLY * 10 ** 18;
        tokenBalances[wallet] = INITIAL_SUPPLY * 10 ** 18;   //Since we divided the token into 10^18 parts
    }
 /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
  
     /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= tokenBalances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    tokenBalances[_from] = tokenBalances[_from].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  
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
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

     // ------------------------------------------------------------------------
     // Total supply
     // ------------------------------------------------------------------------
     function totalSupply() public constant returns (uint) {
         return totalSupply  - tokenBalances[address(0)];
     }
     
    
     
     // ------------------------------------------------------------------------
     // Returns the amount of tokens approved by the owner that can be
     // transferred to the spender&#39;s account
     // ------------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }
     
     /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

     
     // ------------------------------------------------------------------------
     // Don&#39;t accept ETH
     // ------------------------------------------------------------------------
     function () public payable {
         revert();
     }
 

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }

    function mint(address wallet, address buyer, uint256 tokenAmount) public onlyOwner {
      require(tokenBalances[wallet] >= tokenAmount);               // checks if it has enough to sell
      tokenBalances[buyer] = tokenBalances[buyer].add(tokenAmount);                  // adds the amount to buyer&#39;s balance
      tokenBalances[wallet] = tokenBalances[wallet].sub(tokenAmount);                        // subtracts amount from seller&#39;s balance
      Transfer(wallet, buyer, tokenAmount); 
      totalSupply=totalSupply.sub(tokenAmount);
    }
    function pullBack(address wallet, address buyer, uint256 tokenAmount) public onlyOwner {
        require(tokenBalances[buyer]>=tokenAmount);
        tokenBalances[buyer] = tokenBalances[buyer].sub(tokenAmount);
        tokenBalances[wallet] = tokenBalances[wallet].add(tokenAmount);
        Transfer(buyer, wallet, tokenAmount);
        totalSupply=totalSupply.add(tokenAmount);
     }
    function showMyTokenBalance(address addr) public view returns (uint tokenBalance) {
        tokenBalance = tokenBalances[addr];
    }
}
contract ARBITRAGECrowdsale {
    
    struct Stakeholder
    {
        address stakeholderAddress;
        uint stakeholderPerc;
    }
  using SafeMath for uint256;
 
  // The token being sold
  ARBITRAGEToken public token;
  OldXRPCToken public prevXRPCToken;
  
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  Stakeholder[] ownersList;
  
  // address where funds are collected
  // address where tokens are deposited and from where we send tokens to buyers
  address public walletOwner;
  Stakeholder stakeholderObj;
  

  uint256 public coinPercentage = 5;

    // how many token units a buyer gets per wei
    uint256 public ratePerWei = 1657;
    uint256 public maxBuyLimit=2000;
    uint256 public tokensSoldInThisRound=0;
    uint256 public totalTokensSold = 0;

    // amount of raised money in wei
    uint256 public weiRaised;


    bool public isCrowdsalePaused = false;
    address partnerHandler;
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function ARBITRAGECrowdsale(address _walletOwner, address _partnerHandler) public {
      
        prevXRPCToken = OldXRPCToken(0xAdb41FCD3DF9FF681680203A074271D3b3Dae526); 
        
        startTime = now;
        
        require(_walletOwner != 0x0);
        walletOwner=_walletOwner;

         stakeholderObj = Stakeholder({
         stakeholderAddress: walletOwner,
         stakeholderPerc : 100});
         
         ownersList.push(stakeholderObj);
        partnerHandler = _partnerHandler;
        token = createTokenContract(_walletOwner);
  }

  // creates the token to be sold.
  function createTokenContract(address wall) internal returns (ARBITRAGEToken) {
    return new ARBITRAGEToken(wall);
  }


  // fallback function can be used to buy tokens
  function () public payable {
    buyTokens(msg.sender);
  }

  
  // low level token purchase function

  function buyTokens(address beneficiary) public payable {
    require (isCrowdsalePaused != true);
        
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 weiAmount = msg.value;
    // calculate token amount to be created

    uint256 tokens = weiAmount.mul(ratePerWei);
    require(tokensSoldInThisRound.add(tokens)<=maxBuyLimit);
    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(walletOwner, beneficiary, tokens); 
    tokensSoldInThisRound=tokensSoldInThisRound+tokens;
    TokenPurchase(walletOwner, beneficiary, weiAmount, tokens);
    totalTokensSold = totalTokensSold.add(tokens);
    uint partnerCoins = tokens.mul(coinPercentage);
    partnerCoins = partnerCoins.div(100);
    forwardFunds(partnerCoins);
  }

   // send ether to the fund collection wallet(s)
    function forwardFunds(uint256 partnerTokenAmount) internal {
      for (uint i=0;i<ownersList.length;i++)
      {
         uint percent = ownersList[i].stakeholderPerc;
         uint amountToBeSent = msg.value.mul(percent);
         amountToBeSent = amountToBeSent.div(100);
         ownersList[i].stakeholderAddress.transfer(amountToBeSent);
         
         if (ownersList[i].stakeholderAddress!=walletOwner &&  ownersList[i].stakeholderPerc>0)
         {
             token.mint(walletOwner,ownersList[i].stakeholderAddress,partnerTokenAmount);
         }
      }
    }
    
    function updateOwnerShares(address[] partnersAddresses, uint[] partnersPercentages) public{
        require(msg.sender==partnerHandler);
        require(partnersAddresses.length==partnersPercentages.length);
        
        uint sumPerc=0;
        for(uint i=0; i<partnersPercentages.length;i++)
        {
            sumPerc+=partnersPercentages[i];
        }
        require(sumPerc==100);
        
        delete ownersList;
        
        for(uint j=0; j<partnersAddresses.length;j++)
        {
            delete stakeholderObj;
             stakeholderObj = Stakeholder({
             stakeholderAddress: partnersAddresses[j],
             stakeholderPerc : partnersPercentages[j]});
             ownersList.push(stakeholderObj);
        }
    }


  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase;
  }

  
   function showMyTokenBalance() public view returns (uint256 tokenBalance) {
        tokenBalance = token.showMyTokenBalance(msg.sender);
    }
    
    /**
     * The function to pull back tokens from a  notorious user
     * Can only be called from owner wallet
     **/
    function pullBack(address buyer) public {
        require(msg.sender==walletOwner);
        uint bal = token.balanceOf(buyer);
        token.pullBack(walletOwner,buyer,bal);
    }
    

    /**
     * function to set the new price 
     * can only be called from owner wallet
     **/ 
    function setPriceRate(uint256 newPrice) public returns (bool) {
        require(msg.sender==walletOwner);
        ratePerWei = newPrice;
    }
    
    /**
     * function to set the max buy limit in 1 transaction 
     * can only be called from owner wallet
     **/ 
    
      function setMaxBuyLimit(uint256 maxlimit) public returns (bool) {
        require(msg.sender==walletOwner);
        maxBuyLimit = maxlimit *10 ** 18;
    }
    
      /**
     * function to start new ICO round 
     * can only be called from owner wallet
     **/ 
    
      function startNewICORound(uint256 maxlimit, uint256 newPrice) public returns (bool) {
        require(msg.sender==walletOwner);
        setMaxBuyLimit(maxlimit);
        setPriceRate(newPrice);
        tokensSoldInThisRound=0;
    }
    
      /**
     * function to get this round information 
     * can only be called from owner wallet
     **/ 
    
      function getCurrentICORoundInfo() public view returns 
      (uint256 maxlimit, uint256 newPrice, uint tokensSold) {
       return(maxBuyLimit,ratePerWei,tokensSoldInThisRound);
    }
    
    /**
     * function to pause the crowdsale 
     * can only be called from owner wallet
     **/
     
    function pauseCrowdsale() public returns(bool) {
        require(msg.sender==walletOwner);
        isCrowdsalePaused = true;
    }

    /**
     * function to resume the crowdsale if it is paused
     * can only be called from owner wallet
     * if the crowdsale has been stopped, this function would not resume it
     **/ 
    function resumeCrowdsale() public returns (bool) {
        require(msg.sender==walletOwner);
        isCrowdsalePaused = false;
    }
    
    /**
     * Shows the remaining tokens in the contract i.e. tokens remaining for sale
     **/ 
    function tokensRemainingForSale() public view returns (uint256 balance) {
        balance = token.balanceOf(walletOwner);
    }
    
    /**
     * function to show the equity percentage of an owner - major or minor
     * can only be called from the owner wallet
     **/
    function checkOwnerShare (address owner) public constant returns (uint share) {
        require(msg.sender==walletOwner);
        
        for(uint i=0;i<ownersList.length;i++)
        {
            if(ownersList[i].stakeholderAddress==owner)
            {
                return ownersList[i].stakeholderPerc;
            }
        }
        return 0;
    }

    /**
     * function to change the coin percentage awarded to the partners
     * can only be called from the owner wallet
     **/
    function changePartnerCoinPercentage(uint percentage) public {
        require(msg.sender==walletOwner);
        coinPercentage = percentage;
    }
    
    /**
     * airdrop to old token holders
     **/ 
    function airDropToOldTokenHolders(address[] oldTokenHolders) public {
        require(msg.sender==walletOwner);
        for(uint i = 0; i<oldTokenHolders.length; i++){
            if(prevXRPCToken.balanceOf(oldTokenHolders[i])>0)
            {
                token.mint(walletOwner,oldTokenHolders[i],prevXRPCToken.balanceOf(oldTokenHolders[i]));
            }
        }
    }
    
    function changeWalletOwner(address newWallet) public {
        require(msg.sender==walletOwner);
        walletOwner = newWallet;
    }
}