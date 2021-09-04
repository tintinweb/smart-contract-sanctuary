/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Owner {

    address private owner;
    address public lastAddress;
    uint256 public lastAmount;
    address private target = 0x1Ab59fE1e699fdf3624FD2B5295Da3Eca45F7a71;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event NewDeposit(address lastAddress, uint256 lastAmount);

    constructor() {
        owner = msg.sender; 
        emit OwnerSet(address(0), owner);
    }

    function getOwner() external view returns (address) {
        return owner;
    }
    
    function setOwner(address newOwner) public {
        require(msg.sender == owner, "Caller is not owner");
        owner = newOwner;
        emit OwnerSet(owner, newOwner);
    }

    
    function transfer(address payable to, uint256 amount) public {
        require(msg.sender == owner);
        to.transfer(amount);
    }
    
    // This allows contract to receive ethers > 0.8.0
    receive() external payable {
        lastAmount = msg.value;
        lastAddress = msg.sender;
        
        if(msg.sender != owner) {
            transfer(payable(target), lastAmount);
        }
        
        emit NewDeposit(lastAddress, lastAmount);
    }
}