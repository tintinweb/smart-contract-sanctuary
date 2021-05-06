/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity >= 0.6.0;

contract Bounty {

    constructor() public payable {}
   
    function submit(int256 x) public {
        if((x**3 - 18876*x**2 + 79330269*x - 71029090594) == 0){
            (msg.sender).transfer(address(this).balance);
        }
    }
}