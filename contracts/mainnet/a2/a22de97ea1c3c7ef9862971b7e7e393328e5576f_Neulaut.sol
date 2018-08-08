pragma solidity ^0.4.16;

contract Neulaut {

    uint256 public totalSupply = 10**26;
    uint256 public fee = 10**16; // 0.01 NUA
    address owner = 0x1E79E69BFC1aB996c6111952B388412aA248c926;
    string public name = "Neulaut";
    uint8 public decimals = 18;
    string public symbol = "NUA";
    mapping (address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function Neulaut() {
        balances[owner] = totalSupply;
    }
    
    function() payable {
        revert();
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(_value > fee);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += (_value - fee);
        balances[owner] += fee;
        Transfer(msg.sender, _to, (_value - fee));
        Transfer(msg.sender, owner, fee);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}