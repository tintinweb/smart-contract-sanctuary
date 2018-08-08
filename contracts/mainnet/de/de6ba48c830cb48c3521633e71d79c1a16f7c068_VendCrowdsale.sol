pragma solidity ^0.4.18;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
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

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
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

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

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
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

contract Vend is MintableToken {
  	string public constant name = "VEND";
  	string public constant symbol = "VEND";
  	uint8 public constant decimals = 18;

  	/**
    * @dev Function to stop minting new tokens.
 	* @return True if the operation was successful.
    */
    function finishMinting() onlyOwner canMint public returns (bool) {
      mintingFinished = true;
      MintFinished();
      return true;
    }

}



contract VendCrowdsale is Crowdsale , Ownable, CappedCrowdsale {

	//stage presale or crowdsale
	enum Stage {PRESALE, PUBLICSALE}

	//stage ICO
	Stage public stage;

	uint256 private constant DECIMALFACTOR = 10**uint256(18);

	uint256 public publicAllocation = 120000000 * DECIMALFACTOR; //60% Public Allocation 
	uint256 public advisorsAllocation = 20000000 * DECIMALFACTOR; // 10% Advisory and Legal Fund Allocation  
	uint256 public marketAllocation = 20000000 * DECIMALFACTOR; //10% Market Place Incentive
	uint256 public founderAllocation = 40000000* DECIMALFACTOR; //20% Founder & Key Employee Allocation

	uint256 public softCap = 9000 ether;
             

	bool public isGoalReached = false;
	// How much ETH each address has invested to this crowdsale
	mapping (address => uint256) public investedAmountOf;
	// How many distinct addresses have invested
	uint256 public investorCount;

	uint256 public minContribAmount = 0.1 ether; // 0.1 ether

	event MinimumGoalReached();
	event Burn (address indexed burner, uint256 value);


	/**

 	* 
 	* @dev VendCrowdsale is a base contract for managing a token crowdsale.
 	* VendCrowdsale have a start and end timestamps, where investors can make
 	* token purchases and the crowdsale will assign them tokens based
 	* on a token per ETH rate. Funds collected are forwarded to a wallet
 	* as they arrive.
 	*/
	function VendCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _cap)
    	Crowdsale (_startTime, _endTime, _rate, _wallet) CappedCrowdsale(_cap * DECIMALFACTOR)
  {
    	stage = Stage.PRESALE;
  }
  	function createTokenContract() internal returns (MintableToken) {
    	return new Vend();
  }

  	// low level token purchase function
  	// @notice buyTokens
  	// @param beneficiary The address of the beneficiary
  	// @return the transaction address and send the event as TokenPurchase

  	function buyTokens(address beneficiary) public payable {

       	require(validPurchase());
       	uint256 weiAmount = msg.value;
       	// calculate token amount to be created
       	uint256 tokens = weiAmount.mul(rate);
       	uint256 timebasedBonus = tokens.mul(getTimebasedBonusRate()).div(100);
       	uint256 volumebasedBonus = tokens.mul(getVolumebasedBonusRate(weiAmount)).div(100);
       	tokens = tokens.add(timebasedBonus);
       	tokens = tokens.add(volumebasedBonus);
		assert (tokens <= publicAllocation);
		   
       	if(investedAmountOf[beneficiary] == 0) {
           // A new investor
           	investorCount++;
        }
        // Update investor
        investedAmountOf[beneficiary] = investedAmountOf[beneficiary].add(weiAmount);
        if (stage == Stage.PRESALE) {
            assert (tokens <= publicAllocation);
            publicAllocation = publicAllocation.sub(tokens);
        } else {
            assert (tokens <= publicAllocation);
            publicAllocation = publicAllocation.sub(tokens);

        }
       forwardFunds();
       weiRaised = weiRaised.add(weiAmount);
       token.mint(beneficiary, tokens);
       TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
       if (!isGoalReached && weiRaised >= softCap) {
             isGoalReached = true;
             MinimumGoalReached();
         }
     }

     // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
       bool minContribution = minContribAmount <= msg.value;
       bool withinPeriod = now >= startTime && now <= endTime;
       bool nonZeroPurchase = msg.value != 0;
       bool Publicsale =publicAllocation !=0;
       return withinPeriod && minContribution && nonZeroPurchase && Publicsale;
    }
   // @return  current time
    function getNow() public constant returns (uint) {
       return (now);
    }
   	// @return time-based bonus rate
    function getTimebasedBonusRate() internal constant returns (uint256) {
       uint256 bonusRate = 0;
         if (stage == Stage.PUBLICSALE) {
       uint256 nowTime = getNow();
       uint256 week1 = startTime + (7 days);
       uint256 week2 = startTime + (14 days);
       uint256 week3 = startTime + (21 days);
       uint256 week4 = startTime + (14 days);

       if (nowTime <= week1) {
           bonusRate = 15;
       }else if (nowTime <= week2) {
           bonusRate = 15;
       }else if (nowTime <= week3) {
           bonusRate = 10;
       } else if (nowTime <= week4) {
           bonusRate = 10;
       }
         }
       return bonusRate;
   }
   	//@return getVolumebasedBonus
    function getVolumebasedBonusRate(uint256 value) internal constant returns (uint256) {
        uint256 bonusRate = 0;
        if (stage == Stage.PRESALE) {
            uint256 volume = value.div(1 ether);
        if (volume >= 70 && volume <= 100 ) {
            bonusRate = 15;
        }else if (volume >= 40 && volume <= 69 ) {
            bonusRate = 10;
        }else if (volume >= 10 && volume <= 39 ) {
            bonusRate = 5;
        }
        }
        return bonusRate;
        }
   	/**
 	*  
 	* @dev change the State from presale to public sale
 	*/
  	function startPublicsale(uint256 _startTime, uint256 _endTime) public onlyOwner {
      	require(_endTime >= _startTime);
      	stage = Stage.PUBLICSALE;
      	//Start Time endTime and price for PUBLICSALE
      	startTime = _startTime;
      	endTime = _endTime;
   }

  	// @return true if the crowdsale has raised enough money to be successful.
  	function isMinimumGoalReached() public constant returns (bool reached) {
        return weiRaised >= softCap;
  	}

     // Change Start and Endtime for Testing Purpose
    function changeEnd(uint256 _endTime) public onlyOwner {
    	require(_endTime!=0);
        endTime = _endTime;
        
    }

    /**
 	*   
 	* @dev change the Current Token price per Ether
 	*/
   	function changeRate(uint256 _rate) public onlyOwner {
     	require(_rate != 0);
      	rate = _rate;

   }
   

    /**
 	* 
 	* @param _to is beneficiary address
 	* 
 	* @param _value  Amount if tokens
 	*   
 	* @dev Allocated tokens transfer to Advisory team
 	*/
    function transferAdvisorsToken(address _to, uint256 _value) onlyOwner {
    	require (
           _to != 0x0 && _value > 0 && advisorsAllocation >= _value
        );
        token.mint(_to, _value);
        advisorsAllocation = advisorsAllocation.sub(_value);
    }

    /**
 	* @param _to is beneficiary address
 	* 
 	* @param _value  Amount if tokens
 	*   
 	* @dev Allocated tokens transfer to  Market Place Incentive team
 	*/
    function transferMarketallocationTokens(address _to, uint256 _value) onlyOwner {
        require (
           _to != 0x0 && _value > 0 && marketAllocation >= _value
        );
        token.mint(_to, _value);
        marketAllocation = marketAllocation.sub(_value);
	}
	

	/**
 	* @param _to is beneficiary address
 	* 
 	* @param _value  Amount if tokens
 	*   
 	* @dev Allocated tokens transfer to 	Founder & Key Employee team
 	*/
	function transferFounderTokens(address _to, uint256 _value) onlyOwner {
        require (
           _to != 0x0 && _value > 0 && founderAllocation >= _value
        );
        token.mint(_to, _value);
        founderAllocation = founderAllocation.sub(_value);
    }

    /**
 	* @param _value no of tokens
	*	   
 	* @dev Burn the tokens
 	*/
	function burnToken(uint256 _value) onlyOwner {
    	require(_value > 0);
     	publicAllocation = publicAllocation.sub(_value);

    	Burn(msg.sender, _value);
	}
}