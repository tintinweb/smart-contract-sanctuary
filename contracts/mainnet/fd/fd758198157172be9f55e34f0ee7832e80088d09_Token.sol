pragma solidity ^0.4.21;

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
    event Burn(address indexed burner, uint256 value);
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


contract Token is StandardToken {

    string public name = "BlockStorage";
    uint8 public decimals = 18;
    string public symbol = "BLOCKS";
    string public version = "2.1";
    address public mintableAddress;

    function Token(address sale_address) {
        balances[msg.sender] = 0;
        totalSupply = 0;
        name = name;
        decimals = decimals;
        symbol = symbol;
        mintableAddress = sale_address;
        allowTransfer = true;
        createTokens();
    }

    // creates all tokens 180 millions
    // this address will hold all tokens
    // all community contrubutions coins will be taken from this address
    function createTokens() internal {
        uint256 total = 180000000000000000000000000;
        balances[this] = total;
        totalSupply = total;
    }

    function changeTransfer(bool allowed) external {
        require(msg.sender == mintableAddress);
        allowTransfer = allowed;
    }

    function mintToken(address to, uint256 amount) external returns (bool success) {
        require(msg.sender == mintableAddress);
        require(balances[this] >= amount);
        balances[this] -= amount;
        balances[to] += amount;
        Transfer(this, to, amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] -= _value;
        totalSupply -= _value;
        Burn(_who, _value);
        Transfer(_who, address(0), _value);

    }

}