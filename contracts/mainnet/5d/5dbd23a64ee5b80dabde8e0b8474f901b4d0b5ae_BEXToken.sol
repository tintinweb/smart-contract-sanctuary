pragma solidity ^0.4.16;

// The ERC20 Token Standard Interface
contract ERC20 {
    function totalSupply() constant returns (uint totals);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// The BEX Token Standard Interface
contract BEXInterface {

    // burn some BEX token from sender&#39;s account to a specific address which nobody can spent
    // this function only called by contract&#39;s owner
    function burn(uint _value, uint _burnpwd) returns (bool success);
}

// BEX Token implemention
contract BEXToken is ERC20, BEXInterface {
    address public constant burnToAddr = 0x0000000000000000000000000000000000000000;
    string public constant name = "BEX";
    string public constant symbol = "BEX";
    uint8 public constant decimals = 18;
    uint256 constant totalAmount = 200000000000000000000000000;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    function BEXToken() {
        balances[msg.sender] = totalAmount;
    }
    
    modifier notAllowBurnedAddr(address _addr) {
        require(_addr != burnToAddr);
        _;
    }
    
    function totalSupply() constant returns (uint totals) {
        return totalAmount;
    }
    
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint _value) notAllowBurnedAddr(msg.sender) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address _from, address _to, uint _value) notAllowBurnedAddr(_from) returns (bool success) {
        if (balances[_from] >= _value && _value > 0 && allowed[_from][msg.sender] >= _value
            && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address _spender, uint _value) notAllowBurnedAddr(msg.sender) returns (bool success) {
        // To change the approve amount you first have to reduce the addresses&#39;s allowance to zero
        if (_value != 0 && allowed[msg.sender][_spender] != 0) {
            return false;
        }
        if (_value >= 0) {
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint _value, uint _burnpwd) returns (bool success) {
        if (_burnpwd == 120915188 && balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[burnToAddr] += _value;
            Transfer(msg.sender, burnToAddr, _value);
            return true;
        } else {
            return false;
        }
    }
}