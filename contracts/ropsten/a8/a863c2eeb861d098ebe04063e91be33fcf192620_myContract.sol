/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract myContract {
    address payable ownerWallet;
    
    event transfer(address indexed buyer, uint amount);

    constructor() {
        ownerWallet = payable(msg.sender);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function sendEther(address payable _receiver, uint _commission) public payable {

        require(msg.sender.balance > msg.value , 'Insufficient balance');

        uint transferAmount = msg.value - _commission;
        uint commission = _commission;
         
        (bool success, ) = _receiver.call{value: transferAmount}("");
        require(success, "Eth transfer failed.");

        (bool comSuccess, ) = ownerWallet.call{value: commission}("");
        require(comSuccess, "Commission transfer failed.");

        emit transfer(_receiver, transferAmount);
    }

    fallback() external payable {}

    receive() external payable {}

    
}