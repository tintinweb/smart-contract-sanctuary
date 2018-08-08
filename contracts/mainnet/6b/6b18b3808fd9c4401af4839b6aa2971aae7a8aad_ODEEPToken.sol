/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/OpenZeppelin/openzeppelin-solidity
 *
 * The ODEEP token contract bases on the ERC20 standard token contracts 
 * Company Optimum Consulting - Courbevoie
 * */
 
pragma solidity ^0.4.21;

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

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/OpenZeppelin/openzeppelin-solidity
 */
contract Pausable is Ownable {

  uint public endDate;

  /**
   * @dev modifier to allow actions only when the contract IS not paused
   */
  modifier whenNotPaused() {
    require(now >= endDate);
    _;
  }

}

contract StandardToken is ERC20, BasicToken, Pausable {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  }
 
/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256  _value)
        public onlyOwner
    {
        require(_value > 0);
		require(balances[msg.sender] >= _value);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
    }
    event Burn(address indexed burner, uint256  indexed value);
} 
   
contract ODEEPToken is StandardToken , BurnableToken  {
    using SafeMath for uint256;
    string public constant name = "ODEEP";
    string public constant symbol = "ODEEP";
    uint8 public constant decimals = 18;	
	
	// wallets address for allocation	
	address public Bounties_Wallet = 0x70F48becd584115E8FF298eA72D5EFE199526655; // 5% : Bounty
	address public Team_Wallet = 0xd3186A1e1ECe80F2E1811904bfBF876e6ea27A41; // 8% : Equity & Team
	address public OEM_Wallet = 0x4fD0e4E8EFDf55D2C1B41d504A2977a9f8453714; // 10% : Community Builting, Biz Dev
	address public LA_wallet = 0xA0AaFDbDD5bE0d5f1A5f980331DEf9b5e106e587; //8% : Legal & advisors
    
	address public tokenWallet = 0x81cb9078e3c19842B201e2cCFC4B0f111d693D47;    
	uint256 public constant INITIAL_SUPPLY = 100000000 ether;	
		
	/// Base exchange rate is set to 1 ETH = 560 ODEEP.
	uint256 tokenRate = 560; 
		
    function ODEEPToken() public {
        totalSupply_ = INITIAL_SUPPLY;
		
		// InitialDistribution
		// 31% ---> 31000000
		balances[Bounties_Wallet] = INITIAL_SUPPLY.mul(5).div(100) ;
		balances[Team_Wallet] = INITIAL_SUPPLY.mul(8).div(100);
		balances[OEM_Wallet] = INITIAL_SUPPLY.mul(10).div(100) ;
		balances[LA_wallet] = INITIAL_SUPPLY.mul(8).div(100) ;
		
		// 69% ---> 69000000
        balances[tokenWallet] = INITIAL_SUPPLY.mul(69).div(100);
		
        endDate = _endDate;
				
        emit Transfer(0x0, Bounties_Wallet, balances[Bounties_Wallet]);
        emit Transfer(0x0, Team_Wallet, balances[Team_Wallet]);
		emit Transfer(0x0, OEM_Wallet, balances[OEM_Wallet]);
        emit Transfer(0x0, LA_wallet, balances[LA_wallet]);
				
		emit Transfer(0x0, tokenWallet, balances[tokenWallet]);
    }

	/**
	******** DATE PReICO - ICO */
    uint public constant startDate = 1526292000; /// Start Pre-sale - Monday 14 May 2018 12:00:00
    uint public constant endPreICO = 1528883999;/// Close Pre-Sale - Wednesday 13 June 2018 11:59:59
	
	/// HOT sale start time
    uint constant preSale30 = startDate ; /// Start Pre-sale 30% - Monday 14 May 2018 12:00:00
    uint constant preSale20 = 1527156000; /// Start Pre-sale 20% - Thursday 24 May 2018 12:00:00
    uint constant preSale15 = 1528020000; /// Start Pre-sale 15% - Sunday 3 June 2018 12:00:00
			
    uint public constant startICO = 1528884000; /// Start Main Sale - Wednesday 13 June 2018 12:00:00
    uint public constant _endDate = 1532340000; /// Close Main Sale - Monday 23 July 2018 12:00:00 

    struct Stat {
        uint currentFundraiser;
        uint btcAmount;
        uint ethAmount;
        uint txCounter;
    }    
    Stat public stat;    
	
	/// Maximum tokens to be allocated on the sale (69% of the hard cap)
    uint public constant preIcoCap = 5000000 ether;
    uint public constant IcoCap = 64000000 ether;

	/// token caps for each round
	uint256[3] private StepCaps = [
        1250000 ether, 	/// 25% 
        1750000 ether, 	/// 35%
        2000000 ether 	/// 40%
    ];	
	uint8[3] private StepDiscount = [30, 20, 15];
		
    /**
     * @dev modifier to allow actions only when Pre-ICO end date is now
     */
    modifier isFinished() {
        require(now >= endDate);
        _;
    }
	
	/// @return the index of the current discount by date.
    function currentStepIndexByDate() internal view returns (uint8 roundNum) {
        require(now <= endPreICO); 
        if(now > preSale15) return 2;
        if(now > preSale20) return 1;
        if(now > preSale30) return 0;
        else return 0;
    }
	
	/// @return integer representing the index of the current sale round
    function currentStepIndexAll() internal view returns (uint8 roundNum) {
        roundNum = currentStepIndexByDate();
        /// round determined by conjunction of both time and total sold tokens
        while(roundNum < 2 && StepCaps[roundNum]<= 0) {
            roundNum++;
        }
    }
	
	/// @dev Returns is Pre-Sale.
    function isPreSale() internal view returns (bool) {
        if (now >= startDate && now < endPreICO && preIcoCap.sub(stat.currentFundraiser) > 0) {
            return true;
        } else {
            return false;
        }
    }

	/// @dev Returns is Main Sale.
    function isMainSale() internal view returns (bool) {
        if (now >= startICO && now < endDate) {
            return true;
        } else {
            return false;
        }
    }
	
    /// @notice Buy tokens from contract by sending ether
    function () payable public {
        if (msg.value < 0.001 ether || (!isPreSale() && !isMainSale())) revert();
        buyTokens();
    }	
	
	/// @dev Compute the amount of ODEEP token that can be purchased.
    /// @param ethAmount Amount of Ether to purchase ODEEP.
	function computeTokenAmountAll(uint256 ethAmount) internal returns (uint256) {
        uint256 tokenBase = ethAmount.mul(tokenRate);
		uint8 roundNum = currentStepIndexAll();
		uint256 tokens = tokenBase.mul(100)/(100 - (StepDiscount[roundNum]));				
		if (roundNum == 2 && (StepCaps[0] > 0 || StepCaps[1] > 0))
		{
			/// All unsold pre-sale tokens are made available at the last pre-sale period (3% discount rate)
			StepCaps[2] = StepCaps[2] + StepCaps[0] + StepCaps[1];
			StepCaps[0] = 0;
			StepCaps[1] = 0;
		}				
		uint256 balancePreIco = StepCaps[roundNum];		
		
		if (balancePreIco == 0 && roundNum == 2) {
		} else {
			/// If tokens available on the pre-sale run out with the order, next pre-sale discount is applied to the remaining ETH
			if (balancePreIco < tokens) {			
				uint256 toEthCaps = (balancePreIco.mul((100 - (StepDiscount[roundNum]))).div(100)).div(tokenRate);			
				uint256 toReturnEth = ethAmount - toEthCaps ;
				tokens= balancePreIco;
				StepCaps[roundNum]=StepCaps[roundNum]-balancePreIco;		
				tokens = tokens + computeTokenAmountAll(toReturnEth);			
			} else {
				StepCaps[roundNum] = StepCaps[roundNum] - tokens;
			}	
		}		
		return tokens ;
    }
	
    /// @notice Buy tokens from contract by sending ether
    function buyTokens() internal {		
		/// only accept a minimum amount of ETH?
        require(msg.value >= 0.001 ether);
        uint256 tokens ;
		uint256 xAmount = msg.value;
		uint256 toReturnEth;
		uint256 toTokensReturn;
		uint256 balanceIco ;
		
		if(isPreSale()){	
			balanceIco = preIcoCap.sub(stat.currentFundraiser);
			tokens =computeTokenAmountAll(xAmount);
			if (balanceIco < tokens) {	
				uint8 roundNum = currentStepIndexAll();
				toTokensReturn = tokens.sub(balanceIco);	 
				toReturnEth = (toTokensReturn.mul((100 - (StepDiscount[roundNum]))).div(100)).div(tokenRate);			
			}			
		} else if (isMainSale()) {
			balanceIco = IcoCap.add(preIcoCap);
 			balanceIco = balanceIco.sub(stat.currentFundraiser);	
			tokens = xAmount.mul(tokenRate);
			if (balanceIco < tokens) {
				toTokensReturn = tokens.sub(balanceIco);
				toReturnEth = toTokensReturn.mul(tokenRate);
			}			
		} else {
            revert();
        }
		if (tokens > 0 )
		{
			if (balanceIco < tokens) {	
				/// return  ETH
				msg.sender.transfer(toReturnEth);
				_EnvoisTokens(balanceIco, xAmount - toReturnEth);
			} else {
				_EnvoisTokens(tokens, xAmount);
			}
		} else {
            revert();
		}
    }

	/// @dev issue tokens for a single buyer
	/// @dev Issue token based on Ether received.
    /// @param _amount the amount of tokens to send
	/// @param _ethers the amount of ether it will receive
    function _EnvoisTokens(uint _amount, uint _ethers) internal {
		/// sends tokens ODEEP to the buyer
        sendTokens(msg.sender, _amount);
        stat.currentFundraiser += _amount;
		/// sends ether to the seller
        tokenWallet.transfer(_ethers);
        stat.ethAmount += _ethers;
        stat.txCounter += 1;
    }
    
	/// @dev issue tokens for a single buyer
	/// @dev Issue token based on Ether received.
    /// @param _to address to send to
	/// @param _amount the amount of tokens to send
    function sendTokens(address _to, uint _amount) internal {
        require(_amount <= balances[tokenWallet]);
        balances[tokenWallet] -= _amount;
        balances[_to] += _amount;
        emit Transfer(tokenWallet, _to, _amount);
    }

	/// @dev issue tokens for a single buyer
    /// @param _to address to send to
	/// @param _amount the amount of tokens to send
	/// @param _btcAmount the amount of BitCoin
    function _sendTokensManually(address _to, uint _amount, uint _btcAmount) public onlyOwner {
        require(_to != address(0));
        sendTokens(_to, _amount);
        stat.currentFundraiser += _amount;
        stat.btcAmount += _btcAmount;
        stat.txCounter += 1;
    }
	
	/// @dev modify Base exchange rate.
	/// @param newTokenRate the new rate. 
    function setTokenRate(uint newTokenRate) public onlyOwner {
        tokenRate = newTokenRate;
    }
	
	/// @dev Returns the current rate.
	function getTokenRate() public constant returns (uint) {
        return (tokenRate);
    }      
	
	/// @dev Returns the current Cap preIco.
	/// @param _roundNum the caps 
	function getCapTab(uint _roundNum) public view returns (uint) {			
		return (StepCaps[_roundNum]);
    }
	
	/// @dev modify Base exchange rate.
	/// @param _roundNum pre-sale round
	/// @param _value initialize the number of tokens for the indicated pre-sale round
    function setCapTab(uint _roundNum,uint _value) public onlyOwner {
        require(_value > 0);
		StepCaps[_roundNum] = _value;
    }	
}