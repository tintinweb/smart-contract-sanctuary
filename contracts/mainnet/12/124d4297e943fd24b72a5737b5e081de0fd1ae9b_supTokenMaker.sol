pragma solidity 0.4.24;

/** Contact help@concepts.io or visit http://concepts.io for questions about this token contract */

/** 
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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
interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external constant returns (uint);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
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
  constructor () internal{
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
    require(newOwner != address(0) && msg.sender==owner);
    owner = newOwner;
  }
}
contract tokenCreator is Ownable{

    string internal _symbol;
    string internal _name;
    uint8 internal _decimals;
    uint internal _totalSupply = 500000000;
    mapping (address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) internal _allowed;

    constructor(string symbol, string name, uint8 decimals, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = _calcTokens(decimals,totalSupply);
    }

   function _calcTokens(uint256 decimals, uint256 amount) internal pure returns (uint256){
      uint256 c = amount * 10**decimals;
      return c;
   }

    function name() public constant returns (string) {
        return _name;
    }

    function symbol() public constant returns (string) {
        return _symbol;
    }

    function decimals() public constant returns (uint8) {
        return _decimals;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public constant returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}
contract supTokenMaker is tokenCreator("REPLY", "True Reply Research Token", 18, 500000000), ERC20 {
    using SafeMath for uint256;

    event TokenTransferRequest(string method,address from, address backer, uint amount);

    constructor() public {
        _balanceOf[msg.sender] = _totalSupply;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public constant returns (uint) {
        return _balanceOf[_addr];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        emit TokenTransferRequest("transfer",msg.sender, _to, _value);
        require(_value > 0 && _value <= _balanceOf[msg.sender]);

        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        emit TokenTransferRequest("transferFrom",_from, _to, _value);
        require(_to != address(0) && _value <= _balanceOf[_from] && _value <= _allowed[_from][msg.sender] && _value > 0);

        _balanceOf[_from] =  _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint) {
        return _allowed[_owner][_spender];
    }
}