pragma solidity ^0.4.18;

/** might have used ^0.4.15
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

interface ERC223 {
    function transfer(address _to, uint _value, bytes _data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external constant returns (uint);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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
    require(newOwner != address(0));
    owner = newOwner;
  }
}
contract aToken is Ownable{

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

/** uint256 public constant _totalSupply = 500000000 * 10**18; */
}
contract ERCToken is aToken(&quot;ERCCoin&quot;, &quot;ERC Token&quot;, 18, 500000000), ERC20, ERC223 {
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
        emit TokenTransferRequest(&quot;transfer&quot;,msg.sender, _to, _value);
        if (_value > 0 && 
            _value <= _balanceOf[msg.sender] 
            ){
            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
       emit TokenTransferRequest(&quot;transfer_erc223&quot;,msg.sender, _to, _value);
        if (_value > 0 && 
            _value <= _balanceOf[msg.sender]) {
            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
                _contract.tokenFallback(msg.sender, _value, _data);
           emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
      emit TokenTransferRequest(&quot;transferFrom&quot;,_from, _to, _value);
       if (
            _value > 0 &&
            _balanceOf[_from] >= _value) {
            _balanceOf[_from] =  _balanceOf[_from].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            if (_allowed[_from][msg.sender] >= _value){
                _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
            }
           emit Transfer(_from, _to, _value);
            return true;
        }
        return false;
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