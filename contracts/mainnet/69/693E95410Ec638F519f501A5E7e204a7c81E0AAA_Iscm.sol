pragma solidity ^0.4.21;

contract Iscm {
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event FrozenFunds(address target, bool frozen);

    function Iscm(uint256 initialSupply, string tokenName, string tokenSymbol) public{
        owner = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function transfer(address _to, uint _value) public{
        address _from = msg.sender;
        require(!frozenAccount[_from]);
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function freezeAccount(address target, bool freeze) public{
        require(msg.sender == owner);
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
}