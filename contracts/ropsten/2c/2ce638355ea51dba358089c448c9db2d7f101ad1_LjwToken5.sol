pragma solidity ^0.4.21;

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

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LjwToken5 is ERC20 {

    using SafeMath for uint256;

    address public owner;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    string public name = "LjwToken5";
    string public constant symbol = "LT5";
    uint public constant decimals = 18;
    bool public stopped;
    
    modifier stoppable {
        assert(!stopped);
        _;
    }
    
    uint256 public totalSupply = 500000000*(10**18);


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // 30% for team， 70%  for community
    function LjwToken5(address _teamOwner,address _other) public {
        require(_teamOwner != address(0));
        require(_other != address(0));
        require(_teamOwner != _other);
        owner = msg.sender;
        //balances[msg.sender] = totalSupply;
        balances[_teamOwner] = totalSupply.mul(3).div(10); // 30%
        balances[_other] = totalSupply.mul(7).div(10); //70%
    }

    function stop() onlyOwner public {
        stopped = true;
    }
    function start() onlyOwner public {
        stopped = false;
    }
    
    function transferOwnership(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    //receive eth
    function () public payable {
        address myAddress = this;
        emit Transfer(msg.sender, myAddress, msg.value);
     }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) stoppable  public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, uint256 _amount) stoppable public returns (bool success) {
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        emit Transfer(_from, msg.sender, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) stoppable public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //burn eth
    function burn(address _from,uint256 _amount) onlyOwner public returns (bool) {
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        emit Transfer(_from, address(0), _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender)  constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    //extract eth
    function withdraw() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function kill() onlyOwner public {
       selfdestruct(msg.sender);
    }
    
    function setName(string _name) onlyOwner public  {
        name = _name;
    }

}