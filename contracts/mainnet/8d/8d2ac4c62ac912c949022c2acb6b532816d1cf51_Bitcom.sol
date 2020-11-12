pragma solidity >= 0.5.0;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public returns  (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) view public returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


contract StandardToken is Token , SafeMath {

    bool public status = true;
    modifier on() {
        require(status == true);
        _;
    }

    function transfer(address _to, uint256 _value) on public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_to]);
        if (balances[msg.sender] >= _value && _value > 0 && _to != address(0)) {
            balances[msg.sender] -= _value;
            balances[_to] = safeAdd(balances[_to],_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) on public returns (bool success) {
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to],_value);
            balances[_from] = safeSubtract(balances[_from],_value);
            allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) on view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) on public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) on view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}



contract Bitcom is StandardToken {
    string public name = "bitcom";
    uint8 public decimals = 18;
    string public symbol = "BITCOM";
    bool private init =true;
    
    event Mint(address indexed to, uint value);
    event Burn(address indexed burner, uint256 value);
    event FrozenFunds(address target, bool frozen);
    
    
    function turnon() controller public {
        status = true;
    }
    function turnoff() controller public {
        status = false;
    }
    constructor() public {
        require(init==true);
        totalSupply = 2000000000*10**18;
        balances[0x633B4c6220111FC9fa693A22B03E413627B67b16] = totalSupply;
        init = false;
    }
    address public controllerAddress = 0x633B4c6220111FC9fa693A22B03E413627B67b16;

    modifier controller () {
        require(msg.sender == controllerAddress);
        _;
    }
    
    function mint(address _to, uint256 _amount) on controller public returns (bool) {
        totalSupply = safeAdd(totalSupply, _amount);
        balances[_to] = safeAdd(balances[_to], _amount);

        emit Mint(_to, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function burn(uint256 _value) on public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] = safeSubtract(balances[msg.sender],_value);
        totalSupply = safeSubtract(totalSupply,_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
   
    function freezeAccount(address target, bool freeze) on controller public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}