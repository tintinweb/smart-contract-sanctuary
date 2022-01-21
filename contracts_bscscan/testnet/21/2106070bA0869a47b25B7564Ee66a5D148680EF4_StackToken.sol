//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StackToken {
    mapping(address => uint) owner;
    uint totalToken;

    function deposit() public payable {
        owner[msg.sender] += msg.value;
        totalToken += owner[msg.sender];
    }

    function withdrow() public {
        payable(msg.sender).transfer(owner[msg.sender]);
        totalToken -= owner[msg.sender];
        // owner[msg.sender] -= owner[msg.sender];
        
    }

    function checkBalance(address _ownerAddress) public view returns(uint){
        return owner[_ownerAddress];
    }

    function checkTotalToken() public view returns(uint) {
        return totalToken;
    }
}