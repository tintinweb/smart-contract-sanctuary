pragma solidity ^0.4.20;

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
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TrineChain is ERC20 {
    
    using SafeMath for uint256; 
    address owner = msg.sender; 

    mapping (address => uint256) balances; 
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) locknum; 

    string public constant name = "TrineChain";
    string public constant symbol = "TRCOS";
    uint public constant decimals = 18;
    uint256 _Rate = 10 ** decimals;    
    uint256 public totalSupply = 270000000 * _Rate;
    


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Locked(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

     function TrineChain() public {
        balances[owner] = totalSupply;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0) && newOwner != owner) {
             owner = newOwner;   
        }
    }


    function lock(address _to, uint256 _amount) private returns (bool) {
        require(owner != _to);
        require(_amount > 0);
        require(_amount * _Rate  <= balances[_to]);
        locknum[_to]=_amount * _Rate;
        Locked(_to, _amount * _Rate);
        return true;
    }

    function locked(address[] addresses, uint256[] amounts) onlyOwner public {

        require(addresses.length <= 255);
        require(addresses.length == amounts.length);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            lock(addresses[i], amounts[i]);
        }
    }

    function distr(address _to, uint256 _amount) private returns (bool) {
        require(owner != _to);
        require(_amount > 0);
        require(balances[owner] >= _amount * _Rate);

        balances[owner] = balances[owner].sub(_amount * _Rate);
        balances[_to] = balances[_to].add(_amount * _Rate);
        locknum[_to] += lockcheck(_amount) * _Rate;
        
        Transfer(owner, _to, _amount * _Rate);
        return true;
    }

    function lockcheck(uint256 _amount) internal pure returns (uint256) {
        if(_amount < 3000){
        return _amount * 4/10;
        }
        if(_amount >= 3000 && _amount < 10000){
        return _amount * 5/10;
        }
        if(_amount >= 10000 && _amount < 50000){
        return _amount * 6/10;
        }
        if(_amount >= 50000 && _amount < 500000){
        return _amount * 7/10;
        }
        if(_amount >= 500000){
        return _amount * 8/10;
        }
    }
    
    function distribute(address[] addresses, uint256[] amounts) onlyOwner public {

        require(addresses.length <= 255);
        require(addresses.length == amounts.length);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            distr(addresses[i], amounts[i]);
        }
    }

    function lockedOf(address _owner) constant public returns (uint256) {
        return locknum[_owner];
    }

    function balanceOf(address _owner) constant public returns (uint256) {
	    return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        require(_amount <= balances[msg.sender].sub(locknum[msg.sender]));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= balances[_from].sub(locknum[_from]));
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
}