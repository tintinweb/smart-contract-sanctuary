/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity >=0.7.0 <0.9.0;

contract CrossCoin {
    address public minter;
    mapping (address => uint) public balances;
    
    event Sent(address from, address to, uint amount);
    
    constructor() {
        minter = msg.sender;
    }
    
    function mint(address reciever, uint amount) public {
        require((msg.sender == minter), "Minter Privillage Only.");
        require(amount <= 1e60);
        balances[reciever] += amount;
    }
    
    function send(address reciever, uint amount) public {
        require(amount <= balances[msg.sender], "Insufficient Balance.");
        balances[msg.sender] -= amount;
        balances[reciever] += amount;
        emit Sent(msg.sender, reciever, amount);
    }
}