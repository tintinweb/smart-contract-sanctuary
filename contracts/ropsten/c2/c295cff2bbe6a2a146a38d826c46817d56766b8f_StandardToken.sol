pragma solidity ^0.4.11;
/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure  returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  
}
contract ERC20Interface {
    function totalSupply() public returns (uint supply);
    function balanceOf( address owner ) public returns (uint value);
    function allowance( address owner, address spender ) public returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool success);
    function transferFrom( address from, address to, uint value) public returns (bool success);
    function approve( address spender, uint value ) public returns (bool success);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract StandardAuth is ERC20Interface {
    address      public  owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract StandardToken is StandardAuth {
    using SafeMath for uint;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) optionPoolMembers; //
    string public name;
    string public symbol;
    uint8 public decimals = 9;
    uint256 public totalSupply;
    uint256 public optionPoolMembersUnlockTime = 1534255200;
    address public optionPool;
    uint256 public optionPoolTotalMax;
    uint256 public optionPoolTotal = 0;
    uint256 public optionPoolMembersAmount = 0;
    
    constructor(uint256 _initialAmount, string _tokenName, string _tokenSymbol, address _tokenOptionPool, uint256 _tokenOptionPoolTotalMax) public  {
        balances[msg.sender] = _initialAmount;               
        totalSupply = _initialAmount;                        
        name = _tokenName;                                   
        symbol = _tokenSymbol;                               
        optionPool = _tokenOptionPool;
        optionPoolTotalMax = _tokenOptionPoolTotalMax;
    }
    
    modifier verifyTheLock {
        if(optionPoolMembers[msg.sender] == true) {
            if(now < optionPoolMembersUnlockTime) {
                revert();
            } else {
                _;
            }
        } else {
            _;
        }
    }
    
    // Function to access name of token .
    function name() public view returns (string _name) {
        return name;
    }
    // Function to access symbol of token .
    function symbol() public view returns (string _symbol) {
        return symbol;
    }
    // Function to access decimals of token .
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() public returns (uint256 _totalSupply) {
        return totalSupply;
    }
    function allowance(address _owner, address _spender) public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    // Function to access option pool of tokens .
    function optionPool() public view returns (address _optionPool) {
        return optionPool;
    }
    // Function to access option option pool total of tokens .
    function optionPoolTotal() public view returns (uint256 _optionPoolTotal) {
        return optionPoolTotal;
    }
    // Function to access option option pool total max of tokens .
    function optionPoolTotalMax() public view returns (uint256 _optionPoolTotalMax) {
        return optionPoolTotalMax;
    }
    
    function optionPoolBalance() public view returns (uint256 _optionPoolBalance) {
        return balances[optionPool];
    }
    
    function verifyOptionPoolMembers(address _add) public view returns (bool _verifyResults) {
        return optionPoolMembers[_add];
    }
    
    function optionPoolMembersAmount() public view returns (uint _optionPoolMembersAmount) {
        return optionPoolMembersAmount;
    }
    
    function optionPoolMembersUnlockTime() public view returns (uint _optionPoolMembersUnlockTime) {
        return optionPoolMembersUnlockTime;
    }
   
    function _verifyOptionPoolIncome(address _to, uint _value) private returns (bool _verifyIncomeResults) {
        if(msg.sender == optionPool && _to == owner){
          return false;
        }
        if(_to == optionPool) {
            if(optionPoolTotal + _value <= optionPoolTotalMax){
                optionPoolTotal = optionPoolTotal.add(_value);
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }
    
    function _verifyOptionPoolDefray(address _to) private returns (bool _verifyDefrayResults) {
        if(msg.sender == optionPool) {
            if(optionPoolMembers[_to] != true){
              optionPoolMembers[_to] = true;
              optionPoolMembersAmount++;
            }
        }
        
        return true;
    }

    function transfer(address _to, uint _value) public verifyTheLock returns (bool success) {
    	assert(balances[msg.sender] >= _value);

        require(_verifyOptionPoolIncome(_to, _value));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        _verifyOptionPoolDefray(_to);
        
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    	assert(balances[_from] >= _value);
        assert(allowed[_from][msg.sender] >= _value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        return true;
        
    }

    function approve(address _spender, uint256 _value) public verifyTheLock returns (bool success) {
        require(_verifyOptionPoolIncome(_spender, _value));
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        _verifyOptionPoolDefray(_spender);
        
        return true;
    }

    function balanceOf(address _owner) public returns (uint balance) {
        return balances[_owner];
    }
    
}