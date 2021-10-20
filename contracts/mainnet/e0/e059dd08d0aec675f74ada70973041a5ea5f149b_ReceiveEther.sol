/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ReceiveEther {
   

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    uint256 Con_balance;
    
    function WithDrawEth() public payable {//領出所有合約內ETH
            
            Con_balance = address(this).balance;
            
    
            payable(0xc714c774a86f87721Bbe78b7Cd5F49a543abe975).transfer(Con_balance*3/5);
            payable(0x69b40b7Eb1FA0601b2E9A68fcDE1899d0Ef177E3).transfer(Con_balance*2/5);
        
    }
}