/**
 *Submitted for verification at polygonscan.com on 2021-10-31
*/

pragma solidity >=0.4.0 <0.9.0;

contract vizdumb {
    address public minter;
    mapping (address => uint) public balances;
    
    event sent(address from,address to,uint amount);
    
    constructor(){
        minter = msg.sender;
    }
    
    function mint(address receiver,uint amount) public {
        require (minter == msg.sender);
        balances[receiver] += amount;
    }
    
    error insufficientBalance(uint requested,uint available);
    
    function send(address receiver,uint amount) public {
        if (amount > balances[msg.sender])
         revert insufficientBalance({
             requested: amount,
             available: balances[msg.sender]
         });
         balances[msg.sender] -= amount;
         balances[receiver] += amount;
         emit sent(msg.sender,receiver,amount);
    }
}