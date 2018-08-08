pragma solidity ^0.4.19;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

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
    owner = newOwner;
  }
}

contract Pausable is Ownable {
    
  uint public constant startPreICO = 1521072000; // 15&#39;th March
  uint public constant endPreICO = startPreICO + 31 days;

  uint public constant startICOStage1 = 1526342400; // 15&#39;th May
  uint public constant endICOStage1 = startICOStage1 + 3 days;

  uint public constant startICOStage2 = 1526688000; // 19&#39;th May
  uint public constant endICOStage2 = startICOStage2 + 5 days;

  uint public constant startICOStage3 = 1527206400; // 25&#39;th May
  uint public constant endICOStage3 = endICOStage2 + 6 days;

  uint public constant startICOStage4 = 1527811200; // 1&#39;st June
  uint public constant endICOStage4 = startICOStage4 + 7 days;

  uint public constant startICOStage5 = 1528502400;
  uint public endICOStage5 = startICOStage5 + 11 days;

  /**
   * @dev modifier to allow actions only when the contract IS not paused
   */
  modifier whenNotPaused() {
    require(now < startPreICO || now > endICOStage5);
    _;
  }

}

contract StandardToken is Token, Pausable {
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
    Transfer(msg.sender, _to, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

  /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
  function burn(uint256 _value) public {
      require(_value > 0);
      require(_value <= balances[msg.sender]);

      address burner = msg.sender;
      balances[burner] = balances[burner].sub(_value);
      totalSupply = totalSupply.sub(_value);
      Burn(burner, _value);
  }
}

contract MBEToken is BurnableToken {
  string public constant name = "MoBee";
  string public constant symbol = "MBE";
  uint8 public constant decimals = 18;
  address public tokenWallet;
  address public founderWallet;
  address public bountyWallet;
  address public multisig = 0xA74246dC71c0849acCd564976b3093B0B2a522C3;
  uint public currentFundrise = 0;
  uint public raisedEthers = 0;

  uint public constant INITIAL_SUPPLY = 20000000 ether;
  
  uint256 constant THOUSAND = 1000;
  uint256 constant TEN_THOUSAND = 10000;
  uint public tokenRate = THOUSAND.div(9); // tokens per 1 ether ( 1 ETH / 0.009 ETH = 111.11 MBE )
  uint public tokenRate30 = tokenRate.mul(100).div(70); // tokens per 1 ether with 30% discount
  uint public tokenRate20 = tokenRate.mul(100).div(80); // tokens per 1 ether with 20% discount
  uint public tokenRate15 = tokenRate.mul(100).div(85); // tokens per 1 ether with 15% discount
  uint public tokenRate10 = tokenRate.mul(100).div(90); // tokens per 1 ether with 10% discount
  uint public tokenRate5 = tokenRate.mul(100).div(95); // tokens per 1 ether with 5% discount

  /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
  function MBEToken(address tokenOwner, address founder, address bounty) public {
    totalSupply = INITIAL_SUPPLY;
    balances[tokenOwner] += INITIAL_SUPPLY / 100 * 85;
    balances[founder] += INITIAL_SUPPLY / 100 * 10;
    balances[bounty] += INITIAL_SUPPLY / 100 * 5;
    tokenWallet = tokenOwner;
    founderWallet = founder;
    bountyWallet = bounty;
    Transfer(0x0, tokenOwner, balances[tokenOwner]);
    Transfer(0x0, founder, balances[founder]);
    Transfer(0x0, bounty, balances[bounty]);
  }
  
  function setupTokenRate(uint newTokenRate) public onlyOwner {
    tokenRate = newTokenRate;
    tokenRate30 = tokenRate.mul(100).div(70); // tokens per 1 ether with 30% discount
    tokenRate20 = tokenRate.mul(100).div(80); // tokens per 1 ether with 20% discount
    tokenRate15 = tokenRate.mul(100).div(85); // tokens per 1 ether with 15% discount
    tokenRate10 = tokenRate.mul(100).div(90); // tokens per 1 ether with 10% discount
    tokenRate5 = tokenRate.mul(100).div(95); // tokens per 1 ether with 5% discount
  }
  
  function setupFinal(uint finalDate) public onlyOwner returns(bool) {
    endICOStage5 = finalDate;
    return true;
  }

  function sellManually(address _to, uint amount) public onlyOwner returns(bool) {
    uint tokens = calcTokens(amount);
    uint256 balance = balanceOf(tokenWallet);
    if (balance < tokens) {
      sendTokens(_to, balance);
    } else {
      sendTokens(_to, tokens);
    }
    return true;
  }

  function () payable public {
    if (!isTokenSale()) revert();
    buyTokens(msg.value);
  }
  
  function isTokenSale() public view returns (bool) {
    if (now >= startPreICO && now < endICOStage5) {
      return true;
    } else {
      return false;
    }
  }

  function buyTokens(uint amount) internal {
    uint tokens = calcTokens(amount);  
    safeSend(tokens);
  }
  
  function calcTokens(uint amount) public view returns(uint) {
    uint rate = extraRate(amount, tokenRate);
    uint tokens = amount.mul(rate);
    if (now >= startPreICO && now < endPreICO) {
      rate = extraRate(amount, tokenRate30);
      tokens = amount.mul(rate);
      return tokens;
    } else if (now >= startICOStage1 && now < endICOStage1) {
      rate = extraRate(amount, tokenRate20);
      tokens = amount.mul(rate);
      return tokens;
    } else if (now >= startICOStage2 && now < endICOStage2) {
      rate = extraRate(amount, tokenRate15);
      tokens = amount.mul(rate);
      return tokens;
    } else if (now >= startICOStage3 && now < endICOStage3) {
      rate = extraRate(amount, tokenRate10);
      tokens = amount.mul(rate);
      return tokens;
    } else if (now >= startICOStage4 && now < endICOStage4) {
      rate = extraRate(amount, tokenRate5);
      tokens = amount.mul(rate);
      return tokens;
    } else if (now >= startICOStage5 && now < endICOStage5) {
      return tokens;
    }
  }

  function extraRate(uint amount, uint rate) public pure returns (uint) {
    return ( ( rate * 10 ** 20 ) / ( 100 - extraDiscount(amount) ) ) / ( 10 ** 18 );
  }

  function extraDiscount(uint amount) public pure returns(uint) {
    if ( 3 ether <= amount && amount <= 5 ether ) {
      return 5;
    } else if ( 5 ether < amount && amount <= 10 ether ) {
      return 7;
    } else if ( 10 ether < amount && amount <= 20 ether ) {
      return 10;
    } else if ( 20 ether < amount ) {
      return 15;
    }
    return 0;
  }

  function safeSend(uint tokens) private {
    uint256 balance = balanceOf(tokenWallet);
    if (balance < tokens) {
      uint toReturn = tokenRate.mul(tokens.sub(balance));
      sendTokens(msg.sender, balance);
      msg.sender.transfer(toReturn);
      multisig.transfer(msg.value.sub(toReturn));
      raisedEthers += msg.value.sub(toReturn);
    } else {
      sendTokens(msg.sender, tokens);
      multisig.transfer(msg.value);
      raisedEthers += msg.value;
    }
  }

  function sendTokens(address _to, uint tokens) private {
    balances[tokenWallet] = balances[tokenWallet].sub(tokens);
    balances[_to] += tokens;
    Transfer(tokenWallet, _to, tokens);
    currentFundrise += tokens;
  }
}