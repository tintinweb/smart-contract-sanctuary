/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity ^0.4.25;

contract BlockDevTest {
    string public name ="BlockdevTokenTest";
    string public symbol ="BDTT";
    uint8 public decimals = 0; // 1.003 -> 3
    uint256 public totalSupply = 0;
    
    mapping(address=>uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function() public payable {
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

}