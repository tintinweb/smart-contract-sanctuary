/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
contract MyContract {
    address public receiverAddress;

    mapping (address => uint) public balances;

    event Sent(address from, address to , uint amount);
    event ChangeReceiverAddress(address from, address to);

    constructor() public {
        receiverAddress = 0xc16689b9a55ACdB244a77726f7248f2B7069E80c;
    }

    function changeReceiverAddress(address newAddress)public{
        address oldAddress=receiverAddress;
        receiverAddress=newAddress;
        emit ChangeReceiverAddress(oldAddress,newAddress);
    }


    function send() payable public {
        require(msg.value <= balances[msg.sender], "Insufficient balance.");
        balances[msg.sender] -= msg.value;
        balances[receiverAddress] += msg.value;
        emit Sent(msg.sender, receiverAddress, msg.value);
    }
}