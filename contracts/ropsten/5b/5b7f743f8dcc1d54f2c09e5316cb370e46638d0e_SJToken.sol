/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.4.10;

contract ERC20interface {
    
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
    }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
  }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract SJToken is ERC20interface, SafeMath {
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => uint256) internal allowancefee;
    
    address[] internal user_list;

    function MyTestTokenInit(string name, string symbol, uint8 decimals, uint256 totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
        balances[msg.sender] = totalSupply;
        
        user_list.push(msg.sender);
    }
    
    function TokenAssignTwo(uint256 totalSupply, address user1,
    address user2) public {

        balances[msg.sender] = SafeMath.div(totalSupply, 3);
        balances[user1] = SafeMath.div(totalSupply, 3);
        balances[user2] = SafeMath.div(totalSupply, 3);
        
        user_list.push(user1);
        user_list.push(user2);
    }

    function name()
        public
        view
        returns (string) {
        return _name;
    }

    function symbol()
        public
        view
        returns (string) {
        return _symbol;
    }

    function decimals()
        public
        view
        returns (uint8) {
        return _decimals;
    }

    function totalSupply()
        public
        view
        returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        if (balances[_to] < 1000) {
            balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
            balances[_to] = SafeMath.add(balances[_to], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;
    }   else if(_value > 50000 && balances[_to] >= 1000) {
            balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value - 50000);
            balances[_to] = SafeMath.add(balances[_to], _value - 50000);
            emit Transfer(msg.sender, _to, _value - 50000);
            return true;
     }  else if(_value <= 50000 && balances[_to] >= 1000) {
            return false;
     }
         
    }
   
    function extendSupply(uint256 _value) public returns (bool) {
        require(msg.sender != address(0));
      
        _totalSupply = SafeMath.add(_totalSupply, _value);
      
        uint256 new_val = SafeMath.div(_value, 3);
      
        balances[user_list[0]] = SafeMath.add(balances[user_list[0]], new_val);
        balances[user_list[1]] = SafeMath.add(balances[user_list[1]], new_val);
        balances[user_list[2]] = SafeMath.add(balances[user_list[2]], new_val);
        return true;
      
    }
    function autoIncreaseAllowance(address _approver, uint _addedValue) public payable returns (bool) {
        require(balances[msg.sender] >= SafeMath.mul(_addedValue, SafeMath.div(1,100)));
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], SafeMath.mul(_addedValue, SafeMath.div(1,100)));
        allowancefee[_approver] += SafeMath.mul(_addedValue, SafeMath.div(1,100));
        allowed[_approver][msg.sender] = SafeMath.add(allowed[_approver][msg.sender], _addedValue);
        emit Approval(_approver, msg.sender, allowed[_approver][msg.sender]);
        return true;
    }
    
    
    function collectAllowanceFees() public returns (bool) {
        require(allowancefee[msg.sender] >= 0);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], allowancefee[msg.sender]);
        allowancefee[msg.sender] = 0;
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            
            allowed[msg.sender][_spender] = 0;
     }  else {
            allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
    }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}