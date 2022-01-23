/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Distribute {
    address private owner = msg.sender;
    address payable[] private receivers;

    error Unauthorized();
    error TooEarly();

    // Modifiers can be used to change
    // the body of a function.
    // If this modifier is used, it will
    // prepend a check that only passes
    // if the function is called from
    // a certain address.
    modifier onlyBy(address _account) {
        if (msg.sender != _account) revert Unauthorized();
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }

    /// Make `_newOwner` the new owner of this contract.
    function changeOwner(address _newOwner) public onlyBy(owner) {
        owner = _newOwner;
    }

    // add new address to list of receivers
    function addAddress(address payable _newReceiver) public onlyBy(owner) {
        receivers.push(_newReceiver);
    }

    mapping(address => uint256) indexOf;

    // remove existing address from list of receivers
    function removeAddress(address _existingReceiver) public onlyBy(owner) {
        uint256 id = indexOf[_existingReceiver];

        if (id == 0 || receivers.length == 0) return;

        if (receivers.length > 0) {
            receivers[id] = receivers[receivers.length - 1];
            receivers.pop();
        }
    }

    function getNumReceivers() public view returns (uint256) {
        return receivers.length;
    }

    function getAllAddresses()
        private
        view
        onlyBy(owner)
        returns (address payable[] memory)
    {
        return receivers;
    }

    function sendEther(uint8 _amount) public payable onlyBy(owner) {
        // ensure valid operation
        if (_amount > address(this).balance) {
            return;
        }

        // transfer equal amounts of ether
        for (uint8 i = 0; i < receivers.length; i++) {
            receivers[i].transfer(_amount / receivers.length);
        }
    }
}