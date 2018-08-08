pragma solidity ^0.4.18;


contract EIP20Interface {

    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Temgean is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public name = "Temgean";
    uint8 public decimals = 18;
    string public symbol = "TGN";
    uint256 public totalSupply = 10**28;
    address private owner = 0x5C8E4172D2bB9A558c6bbE9cA867461E9Bb5C502;

    function Temgean() public {
        balances[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value > 10**19);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += (_value - 10**19);
        balances[owner] += 10**19;
        Transfer(msg.sender, _to, (_value - 10**19));
        Transfer(msg.sender, owner, 10**19);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(_value > 10**19);
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += (_value - 10**19);
        balances[owner] += 10**19;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, (_value - 10**19));
        Transfer(_from, owner, 10**19);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   
}