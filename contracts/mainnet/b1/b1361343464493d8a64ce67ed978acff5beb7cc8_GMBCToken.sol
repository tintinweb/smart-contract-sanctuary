pragma solidity ^0.4.21;

// File: source\openzeppelin-solidity\contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// File: source\openzeppelin-solidity\contracts\ownership\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

// File: source\openzeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol

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

// File: source\openzeppelin-solidity\contracts\token\ERC20\BasicToken.sol

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: source\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol

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

// File: source\openzeppelin-solidity\contracts\token\ERC20\StandardToken.sol

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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: source\CappedMintableToken.sol

/**
 * @title Mintable token with an end-of-mint mechanism and token cap
 * Based on openzeppelin-solidity MintableToken & CappedToken
 */
contract CappedMintableToken is StandardToken, Ownable {
  using SafeMath for uint256;

  event Mint(address indexed to, uint256 amount);

  modifier canMint() {
    require(mintEnabled);
    _;
  }

  modifier onlyOwnerOrCrowdsale() {
    require(msg.sender == owner || msg.sender == crowdsale);
    _;
  }

  bool public mintEnabled;
  bool public transferEnabled;
  uint256 public cap;
  address public crowdsale;
  

	function setCrowdsale(address _crowdsale) public onlyOwner {
		crowdsale = _crowdsale;
	}

  function CappedMintableToken(uint256 _cap) public {    
    require(_cap > 0);

    mintEnabled = true;
    transferEnabled = false;
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwnerOrCrowdsale canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    require(_amount > 0);

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(transferEnabled);

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(transferEnabled);

    return super.transferFrom(_from, _to, _value);
  }
  
}

// File: source\GMBCTokenBuyable.sol

contract GMBCTokenBuyable is CappedMintableToken {  
  bool public payableEnabled; // payable function enabled
  uint256 public minPurchase; // minimum purchase in wei

  function () external payable {    
    buyTokens(msg.sender);
  }

  function setPayableEnabled(bool _payableEnabled) onlyOwner external {
    payableEnabled = _payableEnabled;
  }

  function setMinPurchase(uint256 _minPurchase) onlyOwner external {
    minPurchase = _minPurchase;
  }

  function buyTokens(address _beneficiary) public payable {
    require(payableEnabled);

    uint256 weiAmount = msg.value;
    require(_beneficiary != address(0));
    require(weiAmount >= minPurchase);

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);
    mint(_beneficiary, tokens);
  }

  function getTokenAmount(uint256 _weiAmount) public view returns (uint256);

   /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function claimEther(uint256 _weiAmount) external onlyOwner {    
    owner.transfer(_weiAmount);
  }
}

// File: source\openzeppelin-solidity\contracts\ownership\HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0173646c626e4133">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(this.balance);
  }
}

// File: source\GMBCToken.sol

contract GMBCToken is GMBCTokenBuyable {
	using SafeMath for uint256;

	string public constant name = "Gamblica Token";
	string public constant symbol = "GMBC";
	uint8 public constant decimals = 18;

	bool public finalized = false;
	uint8 public bonus = 0;				// bonus value in % (0 - 100)
	uint256 public basePrice = 10000;	// base GMBC per 1 ETH

	/**
	 * GMBCToken
	 * https://gamblica.com 
	 * Official Gamblica Coin (Token)
	 */
	function GMBCToken() public 
		CappedMintableToken( 600000000 * (10 ** uint256(decimals)) ) // 60%, 40% will be minted on finalize
	{}

	/**
	 * Sets current bonus (%)
	 */
	function setBonus(uint8 _bonus) onlyOwnerOrCrowdsale external {		
		require(_bonus >= 0 && _bonus <= 100);
		bonus = _bonus;
	}

	function setBasePrice(uint256 _basePrice) onlyOwner external {
		require(_basePrice > 0);
		basePrice = _basePrice;
	}

	/**
	 * Returns token amount for wei investment
	 */
	function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {		
		require(decimals == 18);
		uint256 gmbc = _weiAmount.mul(basePrice);
		return gmbc.add(gmbc.mul(bonus).div(100));
	}

	/**
		Performs the final stage of the token sale, 
		mints additional 40% of token fund,
		transfers minted tokens to an external fund
		(20% game fund, 10% team, 5% advisory board, 3% bounty, 2% founders)
	*/
	function finalize(address _fund) public onlyOwner returns (bool) {
		require(!finalized);		
		require(_fund != address(0));

		uint256 amount = totalSupply_.mul(4).div(6);	// +40% 

		totalSupply_ = totalSupply_.add(amount);
    	balances[_fund] = balances[_fund].add(amount);
    	emit Mint(_fund, amount);
    	emit Transfer(address(0), _fund, amount);
    
		mintEnabled = false;
		transferEnabled = true;
		finalized = true;

		return true;
	}


	
}