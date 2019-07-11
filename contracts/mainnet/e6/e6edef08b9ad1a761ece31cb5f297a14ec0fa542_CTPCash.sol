/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

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

contract CTPCash is ERC20 {
    
    using SafeMath for uint256; 
    address owner = msg.sender; 

    mapping (address => uint256) balances; 
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;

    string public constant name = "CTPCash";
    string public constant symbol = "cc";
    uint public constant decimals = 2;
    
    uint256 public totalSupply = 1000000000000000e2;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenFunds(address target, bool frozen);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

     function CTPCash() public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0) && newOwner != owner) {
             owner = newOwner;   
        }
    }

    function freeze(address[] addresses,bool locked) onlyOwner public {
        
        require(addresses.length <= 255);
        
        for (uint i = 0; i < addresses.length; i++) {
            freezeAccount(addresses[i], locked);
        }
    }
    
    function freezeAccount(address target, bool B) private {
        frozenAccount[target] = B;
        FrozenFunds(target, B);
    }

    function balanceOf(address _owner) constant public returns (uint256) {
	    return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        require(!frozenAccount[msg.sender]);                     
        require(!frozenAccount[_to]);                      
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
  
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        require(!frozenAccount[_from]);                     
        require(!frozenAccount[_to]);      
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

    function withdraw() onlyOwner public {
        uint256 etherBalance = this.balance;
        address owner = msg.sender;
        owner.transfer(etherBalance);
    }
}