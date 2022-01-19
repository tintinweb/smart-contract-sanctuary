/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

pragma solidity >0.4.22;

contract Coin{
    address public minter;
    mapping(address => uint) public balances;
    constructor() public{
        minter = msg.sender;
    }
    event Sent(address from, address to, uint amount);
    function mint(address receiver, uint amount) public{
        require(msg.sender == receiver);
        balances[receiver] += amount;
    }
    function send(address receiver, uint amount) public{
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}