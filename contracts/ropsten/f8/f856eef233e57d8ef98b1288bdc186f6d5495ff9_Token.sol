/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity >= 0.6.0;

contract Token {
    
    mapping(address => uint256) public balances;
    
    constructor() {
        balances[msg.sender] = 100;
    }
    
    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
    
}