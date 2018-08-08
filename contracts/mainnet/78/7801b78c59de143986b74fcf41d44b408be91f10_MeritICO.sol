pragma solidity ^0.4.18;

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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

pragma solidity ^0.4.18;

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

contract Haltable is Ownable {
	bool public halted;

	modifier stopInEmergency {
		require(!halted);
		_;
	}

	modifier onlyInEmergency {
		require(halted);
		_;
	}

	// called by the owner on emergency, triggers stopped state
	function halt() public onlyOwner {
		halted = true;
	}

	// called by the owner on end of emergency, returns to normal state
	function unhalt() public onlyOwner onlyInEmergency {
		halted = false;
	}
}


pragma solidity ^0.4.18;

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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

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

pragma solidity ^0.4.18;

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
    totalSupply_ = totalSupply_.add(_amount);
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
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}


/**
 * Merit token
 */
contract MeritToken is CappedToken {
	event NewCap(uint256 value);

	string public constant name = "Merit Token"; // solium-disable-line uppercase
	string public constant symbol = "MERIT"; // solium-disable-line uppercase
	uint8 public constant decimals = 18; // solium-disable-line uppercase
	bool public tokensReleased;

	function MeritToken(uint256 _cap) public CappedToken(_cap * 10**uint256(decimals)) { }

    modifier released {
        require(mintingFinished);
        _;
    }
    
    modifier notReleased {
        require(!mintingFinished);
        _;
    }
    
    // only allow these functions once the token is released (minting is done)
    // basically the zeppelin &#39;Pausable&#39; token but using my token release flag
    // Only allow our token to be usable once the minting phase is over
    function transfer(address _to, uint256 _value) public released returns (bool) {
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public released returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public released returns (bool) {
        return super.approve(_spender, _value);
    }
    
    function increaseApproval(address _spender, uint _addedValue) public released returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public released returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
    
    // for our token, the balance will always be zero if we&#39;re still minting them
	// once we&#39;re done minting, the tokens will be effectively released to their owners
    function balanceOf(address _owner) public view released returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    // lets us see the pre-allocated balance, since we&#39;re just letting the token keep track of all of the allocations
    // instead of going through another complete allocation step for all users
    function actualBalanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }
    
    // revoke a user&#39;s tokens if they have been banned for violating the TOS.
    // Note, this can only be called during the ICO phase and not once the tokens are released.
    function revoke(address _owner) public onlyOwner notReleased returns (uint256 balance) {
        // the balance should never ben greater than our total supply, so don&#39;t worry about checking
        balance = balances[_owner];
        balances[_owner] = 0;
        totalSupply_ = totalSupply_.sub(balance);
    }
  }


contract MeritICO is Ownable, Haltable {
	using SafeMath for uint256;

	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
		
	// token
	MeritToken public token;
	address public reserveVault;
	address public restrictedVault;
	//address public fundWallet;

	enum Stage 		{ None, Closed, PrivateSale, PreSale, Round1, Round2, Round3, Round4, Allocating, Done }
	Stage public currentStage;

	uint256 public tokenCap;
	uint256 public icoCap;
	uint256 public marketingCap;
	uint256 public teamCap;
	uint256 public reserveCap;

    // number of tokens per ether, kept with 3 decimals (so divide by 1000)
	uint public exchangeRate;
	uint public bonusRate;
	uint256 public currentSaleCap;

	uint256 public weiRaised;
	uint256 public baseTokensAllocated;
	uint256 public bonusTokensAllocated;
	bool public saleAllocated;
	
	struct Contribution {
	    uint256 base;
	    uint256 bonus;
	}
	// current base and bonus balances for each contributor
	mapping (address => Contribution) contributionBalance;

	// map of any address that has been banned from participating in the ICO, for violations of TOS
	mapping (address => bool) blacklist;

	modifier saleActive {
		require(currentStage > Stage.Closed && currentStage < Stage.Allocating);
		_;
	}

	modifier saleAllocatable {
		require(currentStage > Stage.Closed && currentStage <= Stage.Allocating);
		_;
	}
	
	modifier saleNotDone {
		require(currentStage != Stage.Done);
		_;
	}

	modifier saleAllocating {
		require (currentStage == Stage.Allocating);
		_;
	}
	
	modifier saleClosed {
	    require (currentStage == Stage.Closed);
	    _;
	}
	
	modifier saleDone {
	    require (currentStage == Stage.Done);
	    _;
	}

	// _token is the address of an already deployed MeritToken contract
	//
	// team tokens go into a restricted access vault
	// reserve tokens go into a reserve vault
	// any bonus or referral tokens come out of the marketing pool
	// any base purchased tokens come out of the ICO pool
	// all percentages are based off of the cap in the passed in token
	//
	// anything left over in the marketing or ico pool is burned
	//
	function MeritICO() public {
		//fundWallet = _fundWallet;
		currentStage = Stage.Closed;
	}

	function updateToken(address _token) external onlyOwner saleNotDone {
		require(_token != address(0));
		
	    token = MeritToken(_token); 
	    
	    tokenCap = token.cap();
	    
	    require(MeritToken(_token).owner() == address(this));
	}

	function updateCaps(uint256 _icoPercent, uint256 _marketingPercent, uint256 _teamPercent, uint256 _reservePercent) external onlyOwner saleNotDone {
		require(_icoPercent + _marketingPercent + _teamPercent + _reservePercent == 100);

		uint256 max = tokenCap;
        
		marketingCap = max.mul(_marketingPercent).div(100);
		icoCap = max.mul(_icoPercent).div(100);
		teamCap = max.mul(_teamPercent).div(100);
		reserveCap = max.mul(_reservePercent).div(100);

		require (marketingCap + icoCap + teamCap + reserveCap == max);
	}

	function setStage(Stage _stage) public onlyOwner saleNotDone {
		// don&#39;t allow you to set the stage to done unless the tokens have been released
		require (_stage != Stage.Done || saleAllocated == true);
		currentStage = _stage;
	}

	function startAllocation() public onlyOwner saleActive {
		require (!saleAllocated);
		currentStage = Stage.Allocating;
	}
    
	// set how many tokens per wei, kept with 3 decimals
	function updateExchangeRate(uint _rateTimes1000) public onlyOwner saleNotDone {
		exchangeRate = _rateTimes1000;
	}

	// bonus rate percentage (value 0 to 100)
	// cap is the cumulative cap at this point in time
	function updateICO(uint _bonusRate, uint256 _cap, Stage _stage) external onlyOwner saleNotDone {
		require (_bonusRate <= 100);
		require(_cap <= icoCap);
		require(_stage != Stage.None);
		
		bonusRate = _bonusRate;
		currentSaleCap = _cap;	
		currentStage = _stage;
	}
	
	function updateVaults(address _reserve, address _restricted) external onlyOwner saleNotDone {
		require(_reserve != address(0));
		require(_restricted != address(0));
		
		reserveVault = _reserve;
		restrictedVault = _restricted;
		
	    require(Ownable(_reserve).owner() == address(this));
	    require(Ownable(_restricted).owner() == address(this));
	}
	
	function updateReserveVault(address _reserve) external onlyOwner saleNotDone {
		require(_reserve != address(0));

		reserveVault = _reserve;

	    require(Ownable(_reserve).owner() == address(this));
	}
	
	function updateRestrictedVault(address _restricted) external onlyOwner saleNotDone {
		require(_restricted != address(0));
		
		restrictedVault = _restricted;
		
	    require(Ownable(_restricted).owner() == address(this));
	}
	
	//function updateFundWallet(address _wallet) external onlyOwner saleNotDone {
	//	require(_wallet != address(0));
	//	require(fundWallet != _wallet);
	//  fundWallet = _wallet;
	//}

	function bookkeep(address _beneficiary, uint256 _base, uint256 _bonus) internal returns(bool) {
		uint256 newBase = baseTokensAllocated.add(_base);
		uint256 newBonus = bonusTokensAllocated.add(_bonus);

		if (newBase > currentSaleCap || newBonus > marketingCap) {
			return false;
		}

		baseTokensAllocated = newBase;
		bonusTokensAllocated = newBonus;

		Contribution storage c = contributionBalance[_beneficiary];
		c.base = c.base.add(_base);
		c.bonus = c.bonus.add(_bonus);

		return true;
	}
    
	function computeTokens(uint256 _weiAmount, uint _bonusRate) external view returns (uint256 base, uint256 bonus) {
		base = _weiAmount.mul(exchangeRate).div(1000);
		bonus = base.mul(_bonusRate).div(100);
	}
    
	// can only &#39;buy&#39; tokens while the sale is active. 
	function () public payable saleActive stopInEmergency {
	    revert();
	    
		//buyTokens(msg.sender);
	}

	//function buyTokens(address _beneficiary) public payable saleActive stopInEmergency {
		//require(msg.value != 0);
		//require(_beneficiary != 0x0);
		//require(blacklist[_beneficiary] == false);

		//uint256 weiAmount = msg.value;
		//uint256 baseTokens = weiAmount.mul(exchangeRate).div(1000);
		//uint256 bonusTokens = baseTokens.mul(bonusRate).div(100);
		
		//require (bookkeep(_beneficiary, baseTokens, bonusTokens));

        //uint256 total = baseTokens.add(bonusTokens);
        
		//weiRaised = weiRaised.add(weiAmount);

        //TokenPurchase(msg.sender, _beneficiary, weiAmount, total);
        
		//fundWallet.transfer(weiAmount);
		//token.mint(_beneficiary, total);
	//}

	// function to purchase tokens for someone, from an external funding source.  This function 
	// assumes that the external source has been verified.  bonus amount is passed in, so we can 
	// handle an edge case where someone externally purchased tokens when the bonus should be different
	// than it currnetly is set to.
	function buyTokensFor(address _beneficiary, uint256 _baseTokens, uint _bonusTokens) external onlyOwner saleAllocatable {
		require(_beneficiary != 0x0);
		require(_baseTokens != 0 || _bonusTokens != 0);
		require(blacklist[_beneficiary] == false);
		
        require(bookkeep(_beneficiary, _baseTokens, _bonusTokens));

        uint256 total = _baseTokens.add(_bonusTokens);

        TokenPurchase(msg.sender, _beneficiary, 0, total);
        
		token.mint(_beneficiary, total);
	}
    
	// same as above, but strictly for allocating tokens out of the bonus pool
	function giftTokens(address _beneficiary, uint256 _giftAmount) external onlyOwner saleAllocatable {
		require(_beneficiary != 0x0);
		require(_giftAmount != 0);
		require(blacklist[_beneficiary] == false);

        require(bookkeep(_beneficiary, 0, _giftAmount));
        
        TokenPurchase(msg.sender, _beneficiary, 0, _giftAmount);
        
		token.mint(_beneficiary, _giftAmount);
	}
	function balanceOf(address _beneficiary) public view returns(uint256, uint256) {
		require(_beneficiary != address(0));

        Contribution storage c = contributionBalance[_beneficiary];
		return (c.base, c.bonus);
	}

	
	// ban/prevent a user from participating in the ICO for violations of TOS, and deallocate any tokens they have allocated
	// if any refunds are necessary, they are handled offline
	function ban(address _owner) external onlyOwner saleAllocatable returns (uint256 total) {
	    require(_owner != address(0));
	    require(!blacklist[_owner]);
	    
	    uint256 base;
	    uint256 bonus;
	    
	    (base, bonus) = balanceOf(_owner);
	    
	    delete contributionBalance[_owner];
	    
		baseTokensAllocated = baseTokensAllocated.sub(base);
		bonusTokensAllocated = bonusTokensAllocated.sub(bonus);
		
	    blacklist[_owner] = true;

	    total = token.revoke(_owner);
	}

    // unbans a user that was banned with the above function.  does NOT reallocate their tokens
	function unban(address _beneficiary) external onlyOwner saleAllocatable {
	    require(_beneficiary != address(0));
	    require(blacklist[_beneficiary] == true);

        delete blacklist[_beneficiary];
	}
	
	// release any other tokens needed and mark us as allocated
	function releaseTokens() external onlyOwner saleAllocating {
		require(reserveVault != address(0));
		require(restrictedVault != address(0));
		require(saleAllocated == false);

		saleAllocated = true;
		
        // allocate the team and reserve tokens to our vaults		
	    token.mint(reserveVault, reserveCap); 
		token.mint(restrictedVault, teamCap); 
	}

	
	// end the ICO, tokens won&#39;t show up in anyone&#39;s wallets until this function is called.
	// once this is called, nothing works on the ICO any longer
	function endICO() external onlyOwner saleAllocating {
	    require(saleAllocated);
	    
	    currentStage = Stage.Done;
	    
        // this will release all allocated tokens to their owners
	    token.finishMinting();  
	    
	    // now transfer all these objects back to our owner, which we know to be a trusted account
	    token.transferOwnership(owner);
	    Ownable(reserveVault).transferOwnership(owner);
	    Ownable(restrictedVault).transferOwnership(owner);
	}
	
	function giveBack() public onlyOwner {
	    if (address(token) != address(0))
	        token.transferOwnership(owner);
        if (reserveVault != address(0))
	        Ownable(reserveVault).transferOwnership(owner);
        if (restrictedVault != address(0))
	        Ownable(restrictedVault).transferOwnership(owner);
	}
}