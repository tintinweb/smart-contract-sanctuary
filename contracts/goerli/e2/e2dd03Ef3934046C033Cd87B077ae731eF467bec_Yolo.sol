/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

pragma solidity 0.6.12;

contract Yolo{
    address owner = msg.sender;
    uint nonce = 324234234234;
    
    modifier noitcnuf () {
        //HI 👋
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "🛑");
        _;
    }
  
    
/* Dodgy * /
‮*/  function renwOylno ()external noitcnuf {
        selfdestruct(payable(owner));
    }
}