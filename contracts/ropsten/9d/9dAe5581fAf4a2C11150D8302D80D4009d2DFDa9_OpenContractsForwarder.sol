/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity >=0.8.0;

contract OpenContractsForwarder {
    address public hub;
    address public devAddress;
    bool public frozen = false;

    // upon deployment, we set the addresses of the first hub and of the Open Contracts Devs.
    constructor() {
        devAddress = msg.sender;
    }

    // if not frozen, allows the devs to update the hub and their address.
    function update(address newHub, address newDevAddress, bool freeze) public {
        require(!frozen, "The hub can no longer be updated.");
        require(msg.sender == devAddress, "Only the devs can update the forwarder.");
        hub = newHub;
        devAddress = newDevAddress;
        frozen = freeze;
    }

    // forwards call to destination contract
    function forwardCall(address payable destinationContract, bytes memory call) public payable returns(bool, bytes memory) {
        require(msg.sender == hub, 'Only the current hub can use the forwarder.');
        return destinationContract.call{value: msg.value, gas: gasleft()}(call);
    }
}