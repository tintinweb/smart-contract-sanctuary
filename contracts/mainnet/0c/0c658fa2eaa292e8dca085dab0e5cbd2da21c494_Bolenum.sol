pragma solidity ^0.4.18;

contract Bolenum {

    uint256 public totalSupply = 25*10**27;
    string public name = "Bolenum";
    uint8 public decimals = 18;
    string public symbol = "BLN";
    mapping (address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    

    constructor() public {
        balances[0xC6A7c1d01402a8DACA991024d97E730c15962624] = totalSupply;
    }
    
    function() payable {
        revert();
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

}