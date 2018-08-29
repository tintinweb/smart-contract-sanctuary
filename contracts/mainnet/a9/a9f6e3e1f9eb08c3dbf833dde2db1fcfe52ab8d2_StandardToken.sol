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
    mapping(address => bool) optionPoolMembers;
    mapping(address => uint) optionPoolMemberApproveTotal;
    string public name;
    string public symbol;
    uint8 public decimals = 9;
    uint256 public totalSupply;
    uint256 public optionPoolLockTotal = 500000000;
    uint [2][7] public optionPoolMembersUnlockPlans = [
        [1596211200,15],    //2020-08-01 00:00:00 unlock 15%
        [1612108800,30],    //2021-02-01 00:00:00 unlock 30%
        [1627747200,45],    //2021-08-01 00:00:00 unlock 45%
        [1643644800,60],    //2022-02-01 00:00:00 unlock 60%
        [1659283200,75],    //2022-08-01 00:00:00 unlock 75%
        [1675180800,90],    //2023-02-01 00:00:00 unlock 90%
        [1690819200,100]    //2023-08-01 00:00:00 unlock 100%
    ];
    
    constructor(uint256 _initialAmount, string _tokenName, string _tokenSymbol) public  {
        balances[msg.sender] = _initialAmount;               
        totalSupply = _initialAmount;                        
        name = _tokenName;                                   
        symbol = _tokenSymbol;
        optionPoolMembers[0x36b4F89608B5a5d5bd675b13a9d1075eCb64C2B5] = true;
        optionPoolMembers[0xDdcEb1A0c975Da8f0E0c457e06D6eBfb175570A7] = true;
        optionPoolMembers[0x46b6bA8ff5b91FF6B76964e143f3573767a20c1C] = true;
        optionPoolMembers[0xBF95141188dB8FDeFe85Ce2412407A9266d96dA3] = true;
    }

    modifier verifyTheLock(uint _value) {
        if(optionPoolMembers[msg.sender] == true) {
            if(balances[msg.sender] - optionPoolMemberApproveTotal[msg.sender] - _value < optionPoolMembersLockTotalOf(msg.sender)) {
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
    
    function optionPoolMembersLockTotalOf(address _memAdd) public view returns (uint _optionPoolMembersLockTotal) {
        if(optionPoolMembers[_memAdd] != true){
            return 0;
        }
        
        uint unlockPercent = 0;
        
        for (uint8 i = 0; i < optionPoolMembersUnlockPlans.length; i++) {
            if(now >= optionPoolMembersUnlockPlans[i][0]) {
                unlockPercent = optionPoolMembersUnlockPlans[i][1];
            } else {
                break;
            }
        }
        
        return optionPoolLockTotal * (100 - unlockPercent) / 100;
    }
    
    function transfer(address _to, uint _value) public verifyTheLock(_value) returns (bool success) {
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

        if(optionPoolMembers[_from] == true) {
            optionPoolMemberApproveTotal[_from] = optionPoolMemberApproveTotal[_from].sub(_value);
        }
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        return true;
        
    }

    function approve(address _spender, uint256 _value) public verifyTheLock(_value) returns (bool success) {
        assert(_value > 0);
        assert(msg.sender != _spender);
        
        if(optionPoolMembers[msg.sender] == true) {
            
            if(allowed[msg.sender][_spender] > 0){
                optionPoolMemberApproveTotal[msg.sender] = optionPoolMemberApproveTotal[msg.sender].sub(allowed[msg.sender][_spender]);
            }
            
            optionPoolMemberApproveTotal[msg.sender] = optionPoolMemberApproveTotal[msg.sender].add(_value);
        }
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

}