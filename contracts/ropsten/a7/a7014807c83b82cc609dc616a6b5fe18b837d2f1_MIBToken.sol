pragma solidity ^0.4.24;

contract DMIBLog {
    event MIBLog(bytes4 indexed sig, address indexed sender, uint _value) anonymous;

    modifier mlog {
        emit MIBLog(msg.sig, msg.sender, msg.value);
        _;
    }
}

contract Ownable {
    address public owner;

    event OwnerLog(address indexed previousOwner, address indexed newOwner, bytes4 sig);

    constructor() public { 
        owner = msg.sender; 
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner  public {
        require(newOwner != address(0));
        emit OwnerLog(owner, newOwner, msg.sig);
        owner = newOwner;
    }
}

contract MIBStop is Ownable, DMIBLog {

    bool public stopped;

    modifier stoppable {
        require (!stopped);
        _;
    }

    function stop() onlyOwner mlog public {
        stopped = true;
    }
    function start() onlyOwner mlog public {
        stopped = false;
    }
}

library SafeMath {
    
    /**
     * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) internal returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

  
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MIBTokenbase is ERC20, MIBStop {
    using SafeMath for uint256;
    
    /* Actual balances of token holders */
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;    

    
    function transfer(address to, uint256 value) public returns (bool) {
        balances[to] = balances[to].add(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        
        emit Transfer(msg.sender, to, value);

        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if(allowed[from][msg.sender] != value) return false;
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
      }
      
    function approve(address spender, uint256 value) internal returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;        
    }      

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
}


contract MIBToken is MIBTokenbase {
    uint256 public _totalsupply;
    string public constant name = "Mobile Integrated Blockchain";
    string public constant symbol = "MIB";
    uint public constant decimals = 18;

    event Burn(address indexed from, uint256 value);  

    constructor (uint256 _initsupply) public {
		_totalsupply = _initsupply.mul(1 * 1e18);
        balances[msg.sender] = balances[msg.sender].add(_totalsupply);
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalsupply;
    }
    
    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }

    function transfer(address to, uint256 value) stoppable public returns (bool) {
        require(to != address(0));
        return super.transfer(to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) stoppable public returns (bool) {
        require(to != address(0));
        return super.transferFrom(from, to, value);
    }
   
    function approve (address _spender, uint256 _currentValue, uint256 _newValue) stoppable public returns (bool success) {
        if (allowance (msg.sender, _spender) == _currentValue)
          return super.approve (_spender, _newValue);
        else return false;
    }

    function burn(uint256 value) public {
        balances[msg.sender] = balances[msg.sender].sub(value);
        _totalsupply = _totalsupply.sub(value);
        emit Burn(msg.sender, value);
    }
    
    function burnFrom(address who, uint256 value) onlyOwner public payable returns (bool success) {
        balances[who] = balances[who].sub(value);
        balances[msg.sender] = balances[msg.sender].add(value);

        emit Burn(who, value);
        return true;
    }
}