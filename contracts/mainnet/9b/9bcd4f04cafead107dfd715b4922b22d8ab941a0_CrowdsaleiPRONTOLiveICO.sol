pragma solidity ^0.4.18;


// CONTRACT USED TO TEST THE ICO CONTRACT







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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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



contract IprontoToken is StandardToken {

  // Setting Token Name to Mango
  string public constant name = "iPRONTO";

  // Setting Token Symbol to MGO
  string public constant symbol = "IPR";

  // Setting Token Decimals to 18
  uint8 public constant decimals = 18;

  // Setting Token Decimals to 45 Million
  uint256 public constant INITIAL_SUPPLY = 45000000 * (1 ether / 1 wei);

  address public owner;

  // Flags address for KYC verrified.
  mapping (address => bool) public validKyc;

  function IprontoToken() public{
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // Approving an address to tranfer tokens
  function approveKyc(address[] _addrs)
        public
        onlyOwner
        returns (bool)
    {
        uint len = _addrs.length;
        while (len-- > 0) {
            validKyc[_addrs[len]] = true;
        }
        return true;
    }

  function isValidKyc(address _addr) public constant returns (bool){
    return validKyc[_addr];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(isValidKyc(msg.sender));
    return super.approve(_spender, _value);
  }

  function() public{
    throw;
  }
}


contract CrowdsaleiPRONTOLiveICO{
  using SafeMath for uint256;
  address public owner;

  // The token being sold
  IprontoToken public token;

  // rate for one token in wei
  uint256 public rate = 500; // 1 ether
  uint256 public discountRatePreIco = 588; // 1 ether
  uint256 public discountRateIco = 555; // 1 ether

  // funds raised in Wei
  uint256 public weiRaised;

  // Funds pool
  // Setting funds pool for PROMOTORS_POOL, PRIVATE_SALE_POOL, PRE_ICO_POOL and ICO_POOL
  uint256 public constant PROMOTORS_POOL = 18000000 * (1 ether / 1 wei);
  uint256 public constant PRIVATE_SALE_POOL = 3600000 * (1 ether / 1 wei);
  uint256 public constant PRE_ICO_POOL = 6300000 * (1 ether / 1 wei);
  uint256 public constant ICO_POOL = 17100000 * (1 ether / 1 wei);

  // Initilising tracking variables for Funds pool
  uint256 public promotorSale = 0;
  uint256 public privateSale = 0;
  uint256 public preicoSale = 0;
  uint256 public icoSale = 0;

  // Solidity event to notify the dashboard app about transfer
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  // Contract constructor
  function CrowdsaleiPRONTOLiveICO() public{
    token = createTokenContract();
    owner = msg.sender;
  }

  // Creates ERC20 standard token
  function createTokenContract() internal returns (IprontoToken) {
    return new IprontoToken();
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // @return true if the transaction can buy tokens
  function validPurchase(uint256 weiAmount, address beneficiary) internal view returns (bool) {
    bool nonZeroPurchase = weiAmount != 0;
    bool validAddress = beneficiary != address(0);
    return nonZeroPurchase && validAddress;
  }

  // Getter function to see all funds pool balances.
  function availableTokenBalance(uint256 token_needed, uint8 mode)  internal view returns (bool){

    if (mode == 1) { // promotorSale
      return ((promotorSale + token_needed) <= PROMOTORS_POOL );
    }
    else if (mode == 2) { // Closed Group
      return ((privateSale + token_needed) <= PRIVATE_SALE_POOL);
    }
    else if (mode == 3) { // preicoSale
      return ((preicoSale + token_needed) <= PRE_ICO_POOL);
    }
    else if (mode == 4) { // icoSale
      return ((icoSale + token_needed) <= ICO_POOL);
    }
    else {
      return false;
    }
  }

  // fallback function can be used to buy tokens
  function () public payable {
    throw;
  }

  // Token transfer
  function transferToken(address beneficiary, uint256 tokens, uint8 mode) onlyOwner public {
    // Checking for valid purchase
    require(validPurchase(tokens, beneficiary));
    require(availableTokenBalance(tokens, mode));
    // Execute token purchase
    if(mode == 1){
      promotorSale = promotorSale.add(tokens);
    } else if(mode == 2) {
      privateSale = privateSale.add(tokens);
    } else if(mode == 3) {
      preicoSale = preicoSale.add(tokens);
    } else if(mode == 4) {
      icoSale = icoSale.add(tokens);
    } else {
      throw;
    }
    token.transfer(beneficiary, tokens);
    TokenPurchase(beneficiary, beneficiary, tokens, tokens);
  }

  // Function to get balance of an address
  function balanceOf(address _addr) public view returns (uint256 balance) {
    return token.balanceOf(_addr);
  }

  function setTokenPrice(uint256 _rate,uint256 _discountRatePreIco,uint256 _discountRateIco) onlyOwner public returns (bool){
    rate = _rate; // 1 ether
    discountRatePreIco = _discountRatePreIco; // 1 ether
    discountRateIco = _discountRateIco; // 1 ether
    return true;
  }
}