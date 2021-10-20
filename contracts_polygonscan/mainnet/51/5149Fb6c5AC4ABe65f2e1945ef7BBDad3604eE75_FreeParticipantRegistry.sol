// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./Owned.sol";

contract FreeParticipantRegistry is Owned
{
    address transferGate;
    mapping (address => bool) public freeParticipantControllers;
    mapping (address => bool) public freeParticipant;

    modifier transferGateOnly()
    {
        require (msg.sender == transferGate, "Transfer Gate only");
        _;
    }

    function setTransferGate(address _transferGate) public ownerOnly()
    {
        transferGate = _transferGate;
    }

    function setFreeParticipantController(address freeParticipantController, bool allow) public transferGateOnly()
    {
        freeParticipantControllers[freeParticipantController] = allow;
    }

    function setFreeParticipant(address participant, bool free) public transferGateOnly()
    {
        freeParticipant[participant] = free;
    }
}