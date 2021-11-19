/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.4.17;
 
contract Coin{
    address public miner;
    mapping(address=>uint) public balances;
    event Sent(address from,address to,uint amount);
    constructor()public{
        miner = msg.sender;
    }
    
    function mint(address receiver,uint amount)public{
        require(msg.sender == miner);
        balances[receiver] += amount;
    }
    function send(address receiver,uint amount)public{
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        
        emit Sent(msg.sender,receiver,amount);
    }
}