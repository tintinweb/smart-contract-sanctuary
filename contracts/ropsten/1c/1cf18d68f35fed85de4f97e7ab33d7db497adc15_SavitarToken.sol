pragma solidity ^0.4.21;


contract owned {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }
}

contract SavitarToken is owned {
  using SafeMath for uint256;

  mapping (address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  // Token parameters
  string  public name        = "Savitar Token";
  string  public symbol      = "SAT";
  uint8   public decimals    = 8;
  uint256 public totalSupply = 50000000 * (uint256(10) ** decimals);

  // ICO parameters
  bool    public started             = false;
  uint256 public totalICO            = 8000000 * (uint256(10) ** decimals); // adjusted in reevaluateICO
  uint256 public allowedLastOver     = 500000 * (uint256(10) ** decimals);
  uint256 public token_price_eurcent = 5; // 0.05 EUR / SAT
  uint256 public eth_price_eurcent   = 400 * 100; // adjusted in reevaluateETHPrice

  uint256 public givenICO          = 0;
  uint256 public token_price_wei   = (uint256(10) ** (18-decimals)) * token_price_eurcent / eth_price_eurcent;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor() public {
    // Initially assign all tokens to the contract&#39;s creator.
    balanceOf[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
  }

  function transfer(address to, uint256 value) public returns (bool success) {
    require(balanceOf[msg.sender] >= value);

    balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool success) {
    allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool success) {
    require(value <= balanceOf[from]);
    require(value <= allowance[from][msg.sender]);

    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

  function invest() public payable {
    uint256 equivalent_tokens = msg.value.div(token_price_wei);
    moveTokenICO(msg.sender, equivalent_tokens);
  }

  function investExt(address to, uint256 euros) public onlyOwner {
    uint256 equivalent_tokens = (euros * 100).div(token_price_eurcent);
    moveTokenICO(to, equivalent_tokens);
  }

  function moveTokenICO(address to, uint256 tokens) internal {
    require(started);
    require(balanceOf[owner] >= tokens);
    require(givenICO.add(tokens) <= totalICO.add(allowedLastOver));

    balanceOf[owner] = balanceOf[owner].sub(tokens);
    balanceOf[to] = balanceOf[to].add(tokens);
    givenICO = givenICO.add(tokens);

    if (givenICO >= totalICO) {
      started = false;
    }
  }

  function withdraw() public onlyOwner returns (bool success) {
    owner.transfer(address(this).balance);
    return true;
  }

  function startICO() public onlyOwner returns (bool success) {
    started = true;
    return true;
  }

  function stopICO() public onlyOwner returns (bool success) {
    started = false;
    return true;
  }

  function reevaluateICO(uint256 value) public onlyOwner returns (bool success) {
    totalICO = value * (uint256(10) ** decimals);
    if (givenICO >= totalICO) {
        started = false;
    }
    return true;
  }

  function reevaluateETHPrice(uint256 value) public onlyOwner returns (bool success) {
    eth_price_eurcent = value * 100;
    token_price_wei   = (uint256(10) ** 18) * token_price_eurcent / eth_price_eurcent;
    return true;
  }

}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}