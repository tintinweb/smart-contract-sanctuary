pragma solidity ^0.4.16;

contract Neulaut {

    uint256 public totalSupply = 7*10**27;
    uint256 public fee = 15*10**18; // 15 NUA
    uint256 public burn = 10**19; // 10 NUA
    address owner;
    string public name = "Neulaut";
    uint8 public decimals = 18;
    string public symbol = "NUA";
    mapping (address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    

    function Neulaut() {
        balances[owner] = totalSupply;
        owner = msg.sender;
    }
    
    function() payable {
        revert();
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(_value > fee+burn);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += (_value - fee - burn);
        balances[owner] += fee;
        Transfer(msg.sender, _to, (_value - fee - burn));
        Transfer(msg.sender, owner, fee);
        Transfer(msg.sender, address(0), burn);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}