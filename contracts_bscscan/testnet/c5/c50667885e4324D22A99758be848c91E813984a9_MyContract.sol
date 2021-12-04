/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity ^0.5.11;

contract MyContract {
    function invest() external payable {
        if(msg.value < 1 ether){
            revert();
        }
    }

    function balanceOf() external view returns(uint){
        return address(this).balance;
    }
}