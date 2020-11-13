pragma solidity 0.6.10;

library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Lazarus {
  using SafeMath for uint256;

  // standard ERC20 variables. 
  string public name;
  string public symbol;
  uint256 public constant decimals = 18; // the supply 
  // owner of the contract
  uint256 public supply;
  address public owner;

  // events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  // mappings
  mapping(address => uint256) public _balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor(address _owner, string memory _name, string memory _symbol, uint256 _supply) public {
    owner = _owner;
    name = _name;
    symbol = _symbol;
    supply = _supply * 10 ** decimals;
    _balanceOf[owner] = supply;
    emit Transfer(address(0x0), owner, supply);
  }

  function balanceOf (address who) public view returns (uint256) {
    return _balanceOf[who];
  }

  function totalSupply () public view returns (uint256) {
    return supply;
  }

  // ensure the address is valid.
  function _transfer(address _from, address _to, uint256 _value) internal {
    _balanceOf[_from] = _balanceOf[_from].sub(_value);
    _balanceOf[_to] = _balanceOf[_to].add(_value);
    emit Transfer(_from, _to, _value);
  }

  // send tokens
  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_balanceOf[msg.sender] >= _value);
    _transfer(msg.sender, _to, _value);
    return true;
  }

  // approve tokens
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0));
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  // transfer from
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  function increaseAllowance(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
    require(allowance[msg.sender][_spender] > 0);
    allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_value);
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function decreaseAllowance(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
    require(allowance[msg.sender][_spender].sub(_value) >= 0);
    allowance[msg.sender][_spender] = allowance[msg.sender][_spender].sub(_value);
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  // can only burn from the deployer address.
  function burn (uint256 amount) public {
    require(msg.sender == owner);
    require(_balanceOf[msg.sender] >= amount);
    supply = supply.sub(amount);
    _transfer(msg.sender, address(0), amount);

  }

  // transfer ownership to a new address.
  function transferOwnership (address newOwner) public {
    require(msg.sender == owner);
    owner = newOwner;
  }
}