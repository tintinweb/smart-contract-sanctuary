/**
 *Submitted for verification at polygonscan.com on 2021-07-16
*/

// SPDX-License-Identifier: Unlicense 

pragma solidity 0.8.1;

interface IERC20 { // interface for erc20 approve/transfer
    function balanceOf(address who) external view returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
}


contract customDropToken { // transfer msg.sender token to recipients per approved index drop amounts w/ msg.

    address owner; // contract owner
    address dropTKN; // address of drop token 
    
    event TokenDropped(string indexed message);
    
    constructor(address _token) {
        dropTKN = _token; 
        owner = msg.sender;
    }
     
    function customDropTKN(uint256[] memory amounts, address[] memory recipients, string memory message) public {
        uint256 dropAmt;
        
        for (uint256 i = 0; i< amounts.length; i++){
            dropAmt + amounts[i];
        }
        
        require(amounts.length == recipients.length, "!arrays");
        require(IERC20(dropTKN).balanceOf(address(this)) >= dropAmt, "!enough tokens");
        
        for (uint256 i = 0; i < recipients.length; i++) {
	     IERC20(dropTKN).transfer(recipients[i], amounts[i]);
        }
       
	emit TokenDropped(message);
    }
    
    function removeExtras(uint256 amount, address dest) external {
        require(msg.sender == owner, "!owner");
        require(IERC20(dropTKN).balanceOf(address(this)) >= amount, "!enough tokens");
        IERC20(dropTKN).transfer(dest, amount);
    }
    
}