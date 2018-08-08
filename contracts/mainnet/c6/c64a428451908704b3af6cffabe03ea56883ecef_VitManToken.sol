pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}


contract VitManToken is Ownable {
    using SafeMath for uint256;
     
    string public constant name       = "VitMan";
    string public constant symbol     = "VITMAN";
    uint32 public constant decimals   = 18;
    
    uint256 public totalSupply        = 100000000000 ether;
    uint256 public currentTotalSupply = 0;
    uint256 public startBalance       = 2018 ether;

    
    mapping(address => bool) touched;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    
  
    function _touched(address _address) internal returns(bool) {
         if( !touched[_address] && _address!=owner){
            balances[_address] = balances[_address].add( startBalance );
            currentTotalSupply = currentTotalSupply.add( startBalance );
            touched[_address] = true;
            return true;
        }else{
            return false;
        }
    }

    
    function VitManToken() public {
        balances[msg.sender] = totalSupply; // Give the creator all initial tokens
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        _touched(msg.sender);
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //Same as above. Replace this line with the following if you want to protect against wrapping uints.
        _touched(_from);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public returns (uint256 balance) {
       _touched(_owner);
         return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
     }
     
     function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] -= _value;            
        totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        require(balances[_from] >= _value);                
        require(allowed[_from][msg.sender]>=_value);    
        balances[_from] -= _value;                         
        allowed[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        Burn(_from, _value);
        return true;
    }
    
     function mint(address _target, uint256 _mintedAmount) onlyOwner public {
        require(_target!=address(0));
        balances[_target] += _mintedAmount;
        totalSupply += _mintedAmount;
        Transfer(0, this, _mintedAmount);
        Transfer(this, _target, _mintedAmount);
    }
 
     
    function setStartBalance(uint256 _startBalance) onlyOwner public {
        require(_startBalance>=0);
        startBalance=_startBalance * 1 ether;
    }
    
}