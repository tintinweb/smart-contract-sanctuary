pragma solidity ^0.4.18;

contract Phillionex {

    uint256 public totalSupply = 55*10**27;
    string public name = "Phillionex";
    uint8 public decimals = 18;
    string public symbol = "PHN";
    mapping (address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    

    constructor() public {
        balances[0xcad39D48CC441d472Cf0446C9BEB0Ce3aF3e3BF9] = totalSupply;
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