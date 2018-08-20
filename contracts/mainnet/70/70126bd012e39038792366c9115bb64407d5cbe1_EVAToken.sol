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
    function totalSupply() public view returns (uint supply);
    function balanceOf( address owner ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool success);
    function transferFrom( address from, address to, uint value) public returns (bool success);
    function approve( address spender, uint value ) public returns (bool success);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract EVAAuth is ERC20Interface {
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

contract EVAToken is EVAAuth {
    using SafeMath for uint;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) optionPoolMembers; //
    string public name;
    string public symbol;
    uint8 public decimals = 9;
    uint256 public totalSupply;
    uint256 public optionPoolMembersUnlockTime = 1596211200; 
    
    constructor(uint256 _initialAmount, string _tokenName, string _tokenSymbol) public  {
        balances[msg.sender] = _initialAmount;               
        totalSupply = _initialAmount;                        
        name = _tokenName;                                   
        symbol = _tokenSymbol;    
        optionPoolMembers[0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef] = true;
        optionPoolMembers[0x821aEa9a577a9b44299B9c15c88cf3087F3b5544] = true;
        optionPoolMembers[0x0d1d4e623D10F9FBA5Db95830F7d3839406C6AF2] = true;
        optionPoolMembers[0x2932b7A2355D6fecc4b5c0B6BD44cC31df247a2e] = true;
        optionPoolMembers[0x2191eF87E392377ec08E7c08Eb105Ef5448eCED5] = true;
        optionPoolMembers[0x0F4F2Ac550A1b4e2280d04c21cEa7EBD822934b5] = true;
        optionPoolMembers[0x6330A553Fc93768F612722BB8c2eC78aC90B3bbc] = true;
        optionPoolMembers[0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE] = true;
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
    function totalSupply() public view returns (uint _totalSupply) {
        return totalSupply;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
    function verifyOptionPoolMembers(address _add) public view returns (bool _verifyResults) {
        return optionPoolMembers[_add];
    }
    
    function optionPoolMembersUnlockTime() public view returns (uint _optionPoolMembersUnlockTime) {
        return optionPoolMembersUnlockTime;
    }


    function transfer(address _to, uint _value) public verifyTheLock returns (bool success) {
    	assert(_value > 0);
        assert(balances[msg.sender] >= _value);
        assert(msg.sender != _to);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
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
        assert(_value > 0);
        assert(msg.sender != _spender);
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

}