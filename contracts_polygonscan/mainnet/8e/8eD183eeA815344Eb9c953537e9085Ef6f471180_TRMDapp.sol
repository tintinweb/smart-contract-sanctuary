/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract TRMDapp {
    
    address public owner;
    address public newContractOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor () {
        owner = msg.sender;
    }

    modifier onlyContractOwner {
        require(msg.sender == owner);
        _;
    }
 
    function transferOwnership(address _newOwner) external onlyContractOwner {
        require(_newOwner != address(0));
        newContractOwner = _newOwner;
    }
 
    function acceptOwnership() external {
        require(msg.sender == newContractOwner);
        emit OwnershipTransferred(owner, newContractOwner);
        owner = newContractOwner;
        newContractOwner = address(0);
    }
    
    function claim() external payable {
    }

    receive() external payable {
    }
    
    fallback() external payable {
        revert();
    }
    
    function withdrawBalance(uint256 _amount) external onlyContractOwner {
        payable(owner).transfer(_amount);
    }
   
}