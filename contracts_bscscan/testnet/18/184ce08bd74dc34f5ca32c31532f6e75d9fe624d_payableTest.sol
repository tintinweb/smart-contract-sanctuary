/**
 *Submitted for verification at BscScan.com on 2022-01-11
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract payableTest{

    function transferBNB(address payable to) public payable{
        to.transfer(msg.value);
    }

    function getBanlance() external view  returns (uint){
        return address(this).balance;
    }

    fallback() external {
}
receive() payable external {
  
}
    

}