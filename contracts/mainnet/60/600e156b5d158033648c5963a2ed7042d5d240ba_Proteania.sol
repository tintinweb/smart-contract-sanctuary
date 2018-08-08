pragma solidity ^0.4.18;

contract Proteania {

    uint256 public totalSupply = 65*10**27;
    address owner;
    string public name = "Proteania";
    uint8 public decimals = 18;
    string public symbol = "PRN";
    mapping (address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    

    constructor() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
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