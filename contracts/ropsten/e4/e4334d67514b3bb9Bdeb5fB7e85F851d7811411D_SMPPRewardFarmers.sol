/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract SMPPRewardFarmers {

    address private owner;
    uint total_value;


    event OwnerSet(address indexed oldOwner, address indexed newOwner);


    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() payable{
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
        total_value = msg.value;  
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function charge() payable public isOwner {
        total_value += msg.value;
    }

    receive() external payable virtual {
        total_value += msg.value;
    }

    function sum(uint[] memory amounts) private returns (uint retVal) {
        uint totalAmnt = 0;
        for (uint i=0; i < amounts.length; i++) {
            totalAmnt += amounts[i];
        }

        return totalAmnt;
    }

    function withdraw(address payable receiverAddr, uint receiverAmnt) private {
        receiverAddr.transfer(receiverAmnt);
    }

    function withdrawls(address payable[] memory addrs, uint[] memory amnts) payable public isOwner {
        total_value += msg.value;
        require(addrs.length == amnts.length, "The length of two array should be the same");
        uint totalAmnt = sum(amnts);
        require(total_value >= totalAmnt, "The value is not sufficient or exceed");
        for (uint i=0; i < addrs.length; i++) {
            total_value -= amnts[i];
            withdraw(addrs[i], amnts[i]);
        }
    }

    function balance() public view returns(uint) {
        return total_value;
    }

}