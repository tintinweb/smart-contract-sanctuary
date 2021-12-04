//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BrokenContract {
    // allow this contract to receive ether
    receive() external payable {}
    // this function will withdraw the entire ether balance in this smart-contract to the first person who calls it
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }    
    // this function can be used to keep track of the contract's ethereum balance
    function balance() external view returns(uint) {
        return address(this).balance;
    }
}