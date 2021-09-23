//SourceUnit: ClientDeposit_v4.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.7.;

contract ClientDeposit_v4 {
    
    address constant public MASTER_ADDRESS = 0x175EE9BC350237e847eE3603aaB05D446164CE8d;
    address public ownerAddress;
    
    event NewDeposit(address indexed user, uint amount);
    
    constructor() {
        ownerAddress = msg.sender;
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function withdrawAllToMaster() public {
        require(msg.sender == ownerAddress);
        payable(MASTER_ADDRESS).transfer(getBalance());
    }
}