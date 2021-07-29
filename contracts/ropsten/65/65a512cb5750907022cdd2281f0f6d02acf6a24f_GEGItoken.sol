/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

pragma solidity 0.7.4;

contract GEGItoken {
    address public minter;
    mapping (address => uint) public balances;
    
    event Sent(address from, address to, uint amount);
    
    constructor() {
        minter = msg.sender;
    }
    
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }
    
    function send(address receiver, uint amount) public {
        require(amount <= balances[msg.sender], "Insufficient Balance");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
    
    function terminate() public{
        selfdestruct(0xD88e4d41BFC02F4E03eF96bcf40eF1D20f20fC8E);
    }
}