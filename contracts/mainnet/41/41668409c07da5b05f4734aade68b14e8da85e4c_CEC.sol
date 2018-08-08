pragma solidity ^0.4.19;

contract Ownable {
    address public owner; 
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    uint public totalSupply;
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to,uint _value) public returns (bool success);
    function transferFrom(address _from,address _to,uint _value) public returns (bool success);
    function approve(address _spender,uint _value) public returns (bool success);
    function allownce(address _owner,address _spender) public constant returns (uint remaining);
    event Transfer(address indexed _from,address indexed _to,uint _value);
    event Approval(address indexed _owner,address indexed _spender,uint _value);
    
}

contract StandardToken is ERC20 {
    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) allowed;
    
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
    
    function transfer(address _to,uint _value) public returns (bool success) {
        if(balances[msg.sender] > _value && _value > 0 && balances[_to] + _value > balances[_to]){
            balances[_to] += _value;
            balances[msg.sender] -= _value;
            emit Transfer(msg.sender,_to,_value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address _from,address _to,uint _value) public returns (bool success) {
        if(balances[_from] > _value && _value > 0 && allowed[_from][msg.sender] > _value && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from,_to,_value);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    function allownce(address _owner,address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
}

contract CEC is StandardToken,Ownable {
    string public constant name ="17CE";//name of name
    string public constant symbol = "CEC";//symbol of token
    uint8 public constant decimals = 18;
    uint public  constant intial_supply = 100 * (10 ** 6) * (10 ** uint(decimals));//initial 1 hundred million tokens
    uint public reservedteamtoken = intial_supply * 3 / 10; //reserved for team 30%
    uint public contractstarttime = now;
    
    function CEC() public {
        totalSupply = intial_supply;
        balances[msg.sender] = totalSupply - reservedteamtoken * 8 / 10;
    }
    
    //17ce lift a ban plan for yearly
    function lift_ban() public onlyOwner {
        if((now == contractstarttime + 1 years) || (now == contractstarttime + 2 years) || (now == contractstarttime + 3 years) || (now == contractstarttime + 4 years)) {
            balances[owner] += 600 * 10 ** 4 * (10 **  uint(decimals));
        }
    }
    
}