//SourceUnit: Token1.sol

pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
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
    require(c / a == b, "SafeMath mul error");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath div error");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath sub error");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath add error");

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath mod error");
    return a % b;
  }
}

contract ITRC20 {
  function transfer(address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function balanceOf(address who) public view returns (uint256);

  function allowance(address owner, address spender) public view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Auth {

  address internal admin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(
    address _admin
  ) internal {
    admin = _admin;
  }

  modifier onlyAdmin() {
    require(isAdmin(), '401');
    _;
  }

  function _transferOwnership(address _newOwner) onlyAdmin internal {
    require(_newOwner != address(0x0));
    admin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function isAdmin() public view returns (bool) {
    return msg.sender == admin;
  }
}
contract BlackList is Auth {

  function getBlackListStatus(address _maker) external constant returns (bool) {
    return isBlackListed[_maker];
  }

  mapping (address => bool) public isBlackListed;

  function addBlackList (address _evilUser) public onlyAdmin {
    isBlackListed[_evilUser] = true;
    emit AddedBlackList(_evilUser);
  }

  function removeBlackList (address _clearedUser) public onlyAdmin {
    isBlackListed[_clearedUser] = false;
    emit RemovedBlackList(_clearedUser);
  }

  event AddedBlackList(address indexed _user);

  event RemovedBlackList(address indexed _user);

}
contract MDEToken is ITRC20, Auth, BlackList {
  using SafeMath for uint256;

  string public constant name = 'MDE Token';
  string public constant symbol = 'MDE';
  uint8 public constant decimals = 6;
  uint256 public _totalSupply = 100000000 * (10 ** uint256(decimals));

  mapping (address => uint256) internal _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  constructor(address _admin) public Auth(_admin) {
    _balances[address(this)] = _totalSupply;
    emit Transfer(address(0x0), address(this), _totalSupply);
  }

  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(!isBlackListed[msg.sender]);
    _transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(!isBlackListed[from]);
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }


  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  function _transfer(address from, address to, uint256 value) internal {
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    if (to == address(0x0)) {
      _totalSupply = _totalSupply.sub(value);
    }
    emit Transfer(from, to, value);
  }


  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));

    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _burn(address _account, uint256 _amount) internal {
    require(_account != address(0), 'TRC20: burn from the zero address');

    _balances[_account] = _balances[_account].sub(_amount);
    _totalSupply = _totalSupply.sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  function burn(uint _amount) public {
    _burn(msg.sender, _amount);
  }

  function transferOwnership(address _a) public {
    _transferOwnership(_a);
  }

  function provideToken(address _contract, uint256 _amount) public onlyAdmin returns (bool) {
    _transfer(address(this), _contract, _amount);
    return true;
  }
}