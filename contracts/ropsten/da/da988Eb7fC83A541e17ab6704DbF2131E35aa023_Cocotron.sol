/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity >=0.7.0 <0.9.0;

//Allow only owner to create coins
//Anyone can send coins to each other through key pairs

contract Cocotron {
    address public minter;
    mapping(address => uint) public balances;

    event Sent(address from, address to, uint amount);
    error insufficientBalance(uint requested, uint available);

    constructor() {
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public payable {
        require(minter == msg.sender);
        balances[receiver] += amount;
    }

    //Send coins
    function send(address receiver, uint amount) public{
        if(amount > balances[msg.sender]) {
           revert insufficientBalance({
               requested: amount, 
               available: balances[msg.sender]
           });
        }

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
    
}