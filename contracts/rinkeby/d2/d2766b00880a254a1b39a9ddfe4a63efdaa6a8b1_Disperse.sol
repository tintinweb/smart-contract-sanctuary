/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract ReceiveEth {
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

contract Disperse {
    address public owner;
    address public disperseAddress;

    
    // address[] addresses;
    constructor() {
        owner = msg.sender;
        disperseAddress = address(this);
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // function disperse(uint256 _amount, address[] memory _recepients) external public {

    //     for (uint i = 0; i < _recepients.length; i++){
    //         address payable _addr = payable(_recepients[i]);
    //         _addr.transfer(_amount);
    //     }

        // _addr.transfer(_amount * 10**18);
        
    // }
        function disperseEther(address[] calldata _recipients, uint256[] calldata _values) external payable {
        for (uint256 i = 0; i < _recipients.length; i++) {
            address payable _rec =  payable(_recipients[i]);
            _rec.transfer(_values[i]);
        }

        uint256 balance = address(this).balance;

        if (balance > 0){
            address payable _sender = payable(msg.sender);
            _sender.transfer(balance);
        }
    }

}