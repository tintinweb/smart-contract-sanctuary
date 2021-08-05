/**
 *Submitted for verification at Etherscan.io on 2020-11-18
*/

pragma solidity 0.6.0;

// t.me/SmashFinance


library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Ownable {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract SMASH is Ownable {
  using SafeMath for uint256;

  string public constant name = "SmashFinance";
  string public constant symbol = "SMASH" ;
  uint256 public constant decimals = 18;
  uint256 private constant _maximumSupply = 1500 * 18 ** decimals;
  uint256 public _stakingBurnTotal = 0;
  uint256 public _totalSupply;

 
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);


  mapping(address => uint256) public _balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor() public override {
    _owner = msg.sender;
    _totalSupply = _maximumSupply;
    _balanceOf[msg.sender] = _maximumSupply;
    emit Transfer(address(0x0), msg.sender, _maximumSupply);
  }

  function totalSupply () public view returns (uint256) {
    return _totalSupply; 
  }

  function balanceOf (address who) public view returns (uint256) {
    return _balanceOf[who];
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
    _balanceOf[_from] = _balanceOf[_from].sub(_value);
    _balanceOf[_to] = _balanceOf[_to].add(_value);
    emit Transfer(_from, _to, _value);
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_balanceOf[msg.sender] >= _value);
    _transfer(msg.sender, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0));
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }
}