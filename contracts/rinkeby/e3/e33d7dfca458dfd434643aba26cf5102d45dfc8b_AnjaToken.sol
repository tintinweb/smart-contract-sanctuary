/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity 0.6.12;

contract AnjaToken {
    
    string public name = "Anja";
    uint public totalSupply;
    mapping(address => uint) public balances;

    constructor() public {
        balances[msg.sender] = 1e6;
        totalSupply = 1e6;
    }
    
    function transfer(uint amount, address recipient) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
    }
}