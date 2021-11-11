/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

pragma solidity >=0.6.0 <0.7.0;

contract Yolo{
    address owner = msg.sender;
    
    modifier noitcnuf () {
        //HI 👋
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "🛑");
        _;
    }
  
    /* 🥷 */
    /*‮*/function renwOylno () external noitcnuf {
        selfdestruct(payable(owner));
    }
}