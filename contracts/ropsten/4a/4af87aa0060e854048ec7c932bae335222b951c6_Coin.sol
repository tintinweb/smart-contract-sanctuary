/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity >0.4.22;

contract Coin {
    mapping(address => uint) public balances;

    event Sent(address from, address to, uint amount);

    constructor(uint initalSupply) public {
        balances[msg.sender] = initalSupply;
    }

    function send(address receiver, uint amount) public returns (bool succes) {
        require(balances[msg.sender] >= amount);
        require(balances[receiver] + amount >= balances[receiver]);
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        return true;
        emit Sent(msg.sender, receiver, amount);
    }

}