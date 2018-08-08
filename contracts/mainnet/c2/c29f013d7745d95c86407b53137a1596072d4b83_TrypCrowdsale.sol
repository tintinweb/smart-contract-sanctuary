pragma solidity 0.4.21;

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
/////////////////////////////////////////////////////////////////
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
//////////////////////////////////////////////////////

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 public totalSupply_;

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
///////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////
	contract TrypCrowdsale is StandardToken, Ownable {
	
    using SafeMath for uint256;

	string public name = "the Tryp"; 
	string public symbol = "Tryp";
	uint public decimals = 0;  // We don&#39;t want fractional tokens 
	uint256 public constant INITIAL_SUPPLY = 1000000;

  // The token being sold

	StandardToken public token = this;

  // Addresses where funds are collected

	address private constant prizewallet = (0x6eFd9391Db718dEff494C2199CD83E0EFc8102f6);
	address private constant prize2wallet = (0x426570e5b796A2845C700B4b49058E097f7dCb54);
	address private constant adminwallet = (0xe7d718cc663784480EBB62A672180fbB68f89424);

  // How many token units a buyer gets per wei

    uint256 public weiPerToken = 16000000000000000;

  // Amount of wei raised

	uint256 public weiRaised;
    uint256 public remainingSupply_;
 
  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


	
    function TrypCrowdsale () public payable {
		
		totalSupply_ = INITIAL_SUPPLY;
		remainingSupply_ = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
			
	}


  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */

    function () external payable {
        buyTokens(msg.sender);
    }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be sent
        uint256 tokens = _getTokenAmount(weiAmount);
        require(tokens <= remainingSupply_);

    // update state
        weiRaised = weiRaised.add(weiAmount);

        _deliverTokens(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _forwardFunds();

    }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  // Set cost of token in Eth.  Set rate in ETH * 1000 ie: 0.015 eth = setrate 15

    function setRate (uint256 _ethPriceToday) public onlyOwner {

        require(_ethPriceToday != 0);
        weiPerToken = _ethPriceToday.mul(1e18).div(1000);
    }    

  /**
   * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
        
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {

        token.transfer(_beneficiary, _tokenAmount);
        remainingSupply_ = remainingSupply_.sub(_tokenAmount);
    }

  // administrative use to correct any token transaction errors
  
    function deliverTokensAdmin(address _beneficiary, uint256 _tokenAmount) public onlyOwner {

        token.transfer(_beneficiary, _tokenAmount);
        remainingSupply_ = remainingSupply_.sub(_tokenAmount);
    }


  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
   
   // token meant to be sold in whole numbers.  Round down to nearest whole to avoid fractional purchases

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
		uint256 _tokens = _weiAmount.div(weiPerToken);
        return (_tokens);
    }
    
   
  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
    function _forwardFunds() internal {

    	uint256 total_eth = (msg.value);
    	uint256 prize_pool = total_eth.mul(50).div(100);
    	uint256 prize_pool_sec = total_eth.mul(10).div(100);
    	uint256 admin_pool = total_eth.sub(prize_pool).sub(prize_pool_sec);

    	require(prizewallet == (0x6eFd9391Db718dEff494C2199CD83E0EFc8102f6));
    	prizewallet.transfer(prize_pool);
	    require(prize2wallet == (0x426570e5b796A2845C700B4b49058E097f7dCb54));
    	prize2wallet.transfer(prize_pool_sec);
	    require(adminwallet == (0xe7d718cc663784480EBB62A672180fbB68f89424));
    	adminwallet.transfer(admin_pool);
    }


    // Function to remove any ethereum that gets stuck in contract (most likely from under or over payment)   
    function withdraw() public onlyOwner {
         uint bal = address(this).balance;
         address(owner).transfer(bal);
    }

}