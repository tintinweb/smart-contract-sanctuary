pragma solidity ^0.4.24;

contract BasicToken {
    uint256 public totalSupply;
    bool public allowTransfer;

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is BasicToken {

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(allowTransfer);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(allowTransfer);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        require(allowTransfer);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract UtlToken is StandardToken {

    string public name = "Utile Token";
    uint8 public decimals = 18;
    string public symbol = "UTL";
    string public version = &#39;UTL_1.0&#39;;
    address public presaleAddress;
    address public mainsaleAddress;
    address public platformAddress;
    address public creator;

    event DepositEvent(address user, uint256 amount);
    event WithdrawEvent(address from, address to, uint256 amount);

    function UtlToken(address presale_address, address mainsale_address, address platform_address) {
        balances[msg.sender] = 0;
        totalSupply = 0;
        creator = msg.sender;
        name = name;
        decimals = decimals;
        symbol = symbol;
        presaleAddress = presale_address;
        mainsaleAddress = mainsale_address;
        platformAddress = platform_address;
        allowTransfer = true;
        createTokens();
    }

    // creates all tokens 200 million
    // this address will hold all tokens
    // all community contributions coins will be taken from this address
    function createTokens() internal {
        uint256 total = 200000000000000000000000000;
        balances[this] = total;
        totalSupply = total;
    }

    function setAllowTransfer(bool allowed) external {
        require(msg.sender == creator);
        allowTransfer = allowed;
    }

    function mintToken(address to, uint256 amount) external returns (bool success) {
        require(msg.sender == presaleAddress || msg.sender == mainsaleAddress || msg.sender == creator || msg.sender == platformAddress);
        require(balances[this] >= amount);
        balances[this] -= amount;
        balances[to] += amount;
        Transfer(this, to, amount);
        return true;
    }

    function withdrawToken(address to, uint256 amount) external returns (bool success) {
        require(msg.sender == platformAddress);
        require(balances[this] >= amount || balances[msg.sender] >= amount);
        if(balances[msg.sender] >= amount){
            balances[msg.sender] -= amount;
            balances[to] += amount;
            WithdrawEvent(msg.sender, to, amount);
        } else {
            balances[this] -= amount;
            balances[to] += amount;
            WithdrawEvent(this, to, amount);
        }
        return true;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(allowTransfer);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        if(_to == platformAddress){
            DepositEvent(msg.sender, _value);
        } else {
            Transfer(msg.sender, _to, _value);
        }
        return true;
    }
}