pragma solidity ^0.4.11;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
  
  /**
   * Based on http://www.codecodex.com/wiki/Calculate_an_integer_square_root
   */
  function sqrt(uint num) internal returns (uint) {
    if (0 == num) { // Avoid zero divide 
      return 0; 
    }   
    uint n = (num / 2) + 1;      // Initial estimate, never low  
    uint n1 = (n + (num / n)) / 2;  
    while (n1 < n) {  
      n = n1;  
      n1 = (n + (num / n)) / 2;  
    }  
    return n;  
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Adshares ICO token
 * 
 * see https://github.com/adshares/ico
 *
 */
contract AdsharesToken is StandardToken {
    using SafeMath for uint;

    // metadata
    string public constant name = "Adshares Token";
    string public constant symbol = "ADST";
    uint public constant decimals = 0;
    
    // crowdsale parameters
    uint public constant tokenCreationMin = 10000000;
    uint public constant tokenPriceMin = 0.0004 ether;
    uint public constant tradeSpreadInvert = 50; // 2%
    uint public constant crowdsaleEndLockTime = 1 weeks;
    uint public constant fundingUnlockPeriod = 1 weeks;
    uint public constant fundingUnlockFractionInvert = 100; // 1 %
    
    // contructor parameters
    uint public crowdsaleStartBlock;
    address public owner1;
    address public owner2;
    address public withdrawAddress; // multi-sig wallet that will receive ether

    
    // contract state
    bool public minFundingReached;
    uint public crowdsaleEndDeclarationTime = 0;
    uint public fundingUnlockTime = 0;  
    uint public unlockedBalance = 0;  
    uint public withdrawnBalance = 0;
    bool public isHalted = false;

    // events
    event LogBuy(address indexed who, uint tokens, uint purchaseValue, uint supplyAfter);
    event LogSell(address indexed who, uint tokens, uint saleValue, uint supplyAfter);
    event LogWithdraw(uint amount);
    event LogCrowdsaleEnd(bool completed);    
    
    /**
     * @dev Checks if funding is active
     */
    modifier fundingActive() {
      // Not yet started
      if (block.number < crowdsaleStartBlock) {
        throw;
      }
      // Already ended
      if (crowdsaleEndDeclarationTime > 0 && block.timestamp > crowdsaleEndDeclarationTime + crowdsaleEndLockTime) {
          throw;
        }
      _;
    }
    
    /**
     * @dev Throws if called by any account other than one of the owners. 
     */
    modifier onlyOwner() {
      if (msg.sender != owner1 && msg.sender != owner2) {
        throw;
      }
      _;
    }
    
    // constructor
    function AdsharesToken (address _owner1, address _owner2, address _withdrawAddress, uint _crowdsaleStartBlock)
    {
        owner1 = _owner1;
        owner2 = _owner2;
        withdrawAddress = _withdrawAddress;
        crowdsaleStartBlock = _crowdsaleStartBlock;
    }
    
    /**
     * Returns not yet unlocked balance
     */
    function getLockedBalance() private constant returns (uint lockedBalance) {
        return this.balance.sub(unlockedBalance);
      }
    
    /**
     * @dev Calculates how many tokens one can buy for specified value
     * @return Amount of tokens one will receive and purchase value without remainder. 
     */
    function getBuyPrice(uint _bidValue) constant returns (uint tokenCount, uint purchaseValue) {

        // Token price formula is twofold. We have flat pricing below tokenCreationMin, 
        // and above that price linarly increases with supply. 

        uint flatTokenCount;
        uint startSupply;
        uint linearBidValue;
        
        if(totalSupply < tokenCreationMin) {
            uint maxFlatTokenCount = _bidValue.div(tokenPriceMin);
            // entire purchase in flat pricing
            if(totalSupply.add(maxFlatTokenCount) <= tokenCreationMin) {
                return (maxFlatTokenCount, maxFlatTokenCount.mul(tokenPriceMin));
            }
            flatTokenCount = tokenCreationMin.sub(totalSupply);
            linearBidValue = _bidValue.sub(flatTokenCount.mul(tokenPriceMin));
            startSupply = tokenCreationMin;
        } else {
            flatTokenCount = 0;
            linearBidValue = _bidValue;
            startSupply = totalSupply;
        }
        
        // Solves quadratic equation to calculate maximum token count that can be purchased
        uint currentPrice = tokenPriceMin.mul(startSupply).div(tokenCreationMin);
        uint delta = (2 * startSupply).mul(2 * startSupply).add(linearBidValue.mul(4 * 1 * 2 * startSupply).div(currentPrice));

        uint linearTokenCount = delta.sqrt().sub(2 * startSupply).div(2);
        uint linearAvgPrice = currentPrice.add((startSupply+linearTokenCount+1).mul(tokenPriceMin).div(tokenCreationMin)).div(2);
        
        // double check to eliminate rounding errors
        linearTokenCount = linearBidValue / linearAvgPrice;
        linearAvgPrice = currentPrice.add((startSupply+linearTokenCount+1).mul(tokenPriceMin).div(tokenCreationMin)).div(2);
        
        purchaseValue = linearTokenCount.mul(linearAvgPrice).add(flatTokenCount.mul(tokenPriceMin));
        return (
            flatTokenCount + linearTokenCount,
            purchaseValue
        );
     }
    
    /**
     * @dev Calculates average token price for sale of specified token count
     * @return Total value received for given sale size. 
     */
    function getSellPrice(uint _askSizeTokens) constant returns (uint saleValue) {
        
        uint flatTokenCount;
        uint linearTokenMin;
        
        if(totalSupply <= tokenCreationMin) {
            return tokenPriceMin * _askSizeTokens;
        }
        if(totalSupply.sub(_askSizeTokens) < tokenCreationMin) {
            flatTokenCount = tokenCreationMin - totalSupply.sub(_askSizeTokens);
            linearTokenMin = tokenCreationMin;
        } else {
            flatTokenCount = 0;
            linearTokenMin = totalSupply.sub(_askSizeTokens);
        }
        uint linearTokenCount = _askSizeTokens - flatTokenCount;
        
        uint minPrice = (linearTokenMin).mul(tokenPriceMin).div(tokenCreationMin);
        uint maxPrice = (totalSupply+1).mul(tokenPriceMin).div(tokenCreationMin);
        
        uint linearAveragePrice = minPrice.add(maxPrice).div(2);
        return linearAveragePrice.mul(linearTokenCount).add(flatTokenCount.mul(tokenPriceMin));
    }
    
    /**
     * Default function called by sending Ether to this address with no arguments.
     * @dev Buy tokens with market order
     */
    function() payable fundingActive
    {
        buyLimit(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }
    
    /**
     * @dev Buy tokens without price limit
     */
    function buy() payable external fundingActive {
        buyLimit(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);    
    }
    
    /**
     * @dev Buy tokens with limit maximum average price
     * @param _maxPrice Maximum price user want to pay for one token
     */
    function buyLimit(uint _maxPrice) payable public fundingActive {
        require(msg.value >= tokenPriceMin);
        assert(!isHalted);
        
        uint boughtTokens;
        uint averagePrice;
        uint purchaseValue;
        
        (boughtTokens, purchaseValue) = getBuyPrice(msg.value);
        if(boughtTokens == 0) { 
            // bid to small, return ether and abort
            msg.sender.transfer(msg.value);
            return; 
        }
        averagePrice = purchaseValue.div(boughtTokens);
        if(averagePrice > _maxPrice) { 
            // price too high, return ether and abort
            msg.sender.transfer(msg.value);
            return; 
        }
        assert(averagePrice >= tokenPriceMin);
        assert(purchaseValue <= msg.value);
        
        totalSupply = totalSupply.add(boughtTokens);
        balances[msg.sender] = balances[msg.sender].add(boughtTokens);
        
        if(!minFundingReached && totalSupply >= tokenCreationMin) {
            minFundingReached = true;
            fundingUnlockTime = block.timestamp;
            // this.balance contains ether sent in this message
            unlockedBalance += this.balance.sub(msg.value).div(tradeSpreadInvert);
        }
        if(minFundingReached) {
            unlockedBalance += purchaseValue.div(tradeSpreadInvert);
        }
        
        LogBuy(msg.sender, boughtTokens, purchaseValue, totalSupply);
        
        if(msg.value > purchaseValue) {
            msg.sender.transfer(msg.value.sub(purchaseValue));
        }
    }
    
    /**
     * @dev Sell tokens without limit on price
     * @param _tokenCount Amount of tokens user wants to sell
     */
    function sell(uint _tokenCount) external fundingActive {
        sellLimit(_tokenCount, 0);
    }
    
    /**
     * @dev Sell tokens with limit on minimum average priceprice
     * @param _tokenCount Amount of tokens user wants to sell
     * @param _minPrice Minimum price user wants to receive for one token
     */
    function sellLimit(uint _tokenCount, uint _minPrice) public fundingActive {
        require(_tokenCount > 0);

        assert(balances[msg.sender] >= _tokenCount);
        
        uint saleValue = getSellPrice(_tokenCount);
        uint averagePrice = saleValue.div(_tokenCount);
        assert(averagePrice >= tokenPriceMin);
        if(minFundingReached) {
            averagePrice -= averagePrice.div(tradeSpreadInvert);
            saleValue -= saleValue.div(tradeSpreadInvert);
        }
        
        if(averagePrice < _minPrice) {
            // price too high, abort
            return;
        }
        // not enough ether for buyback
        assert(saleValue <= this.balance);
          
        totalSupply = totalSupply.sub(_tokenCount);
        balances[msg.sender] = balances[msg.sender].sub(_tokenCount);
        
        LogSell(msg.sender, _tokenCount, saleValue, totalSupply);
        
        msg.sender.transfer(saleValue);
    }   
    
    /**
     * @dev Unlock funds for withdrawal. Only 1% can be unlocked weekly.
     */
    function unlockFunds() external onlyOwner fundingActive {
        assert(minFundingReached);
        assert(block.timestamp >= fundingUnlockTime);
        
        uint unlockedAmount = getLockedBalance().div(fundingUnlockFractionInvert);
        unlockedBalance += unlockedAmount;
        assert(getLockedBalance() > 0);
        
        fundingUnlockTime += fundingUnlockPeriod;
    }
    
    /**
     * @dev Withdraw funds. Only unlocked funds can be withdrawn.
     */
    function withdrawFunds(uint _value) external onlyOwner fundingActive onlyPayloadSize(32) {
        require(_value <= unlockedBalance);
        assert(minFundingReached);
             
        unlockedBalance -= _value;
        withdrawnBalance += _value;
        LogWithdraw(_value);
        
        withdrawAddress.transfer(_value);
    }
    
    /**
     * @dev Declares that crowdsale is about to end. Users have one week to decide if the want to keep token or sell them to contract.
     */
    function declareCrowdsaleEnd() external onlyOwner fundingActive {
        assert(minFundingReached);
        assert(crowdsaleEndDeclarationTime == 0);
        
        crowdsaleEndDeclarationTime = block.timestamp;
        LogCrowdsaleEnd(false);
    }
    
    /**
     * @dev Can be called one week after initial declaration. Withdraws ether and stops trading. Tokens remain in circulation.
     */
    function confirmCrowdsaleEnd() external onlyOwner {
        assert(crowdsaleEndDeclarationTime > 0 && block.timestamp > crowdsaleEndDeclarationTime + crowdsaleEndLockTime);
        
        LogCrowdsaleEnd(true);
        withdrawAddress.transfer(this.balance);
    }
    
    /**
     * @dev Halts crowdsale. Can only be called before minimumFunding is reached. 
     * @dev When contract is halted no one can buy new tokens, but can sell them back to contract.
     * @dev Function will be called if minimum funding target isn&#39;t reached for extended period of time
     */
    function haltCrowdsale() external onlyOwner fundingActive {
        assert(!minFundingReached);
        isHalted = !isHalted;
    }
}