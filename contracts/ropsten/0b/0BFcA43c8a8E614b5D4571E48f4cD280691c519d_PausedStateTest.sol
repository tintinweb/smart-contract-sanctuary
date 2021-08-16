/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract PausedStateTest {
    address public owner = msg.sender;
    uint256 constant value = 4;
    enum State { Active, Paused, Dead }
    State public currentState = State.Active;
    string newVersionMessage;

    function getValue() public pure returns (uint256) {
        return value;
    }

    function getNewVersionMessage() public view returns (string memory) {
        return newVersionMessage;
    }

    function setNewVersionMessage(string memory addr) public onlyOwner {
        string memory baseString = "Address of new Implementation is: ";
        newVersionMessage = string(abi.encodePacked(baseString, addr));
    }

    function selfDestruct() public payable onlyOwner {
        address payable addr = payable(address(msg.sender));
        selfdestruct(addr);
    }

    function depositMoney() public payable isNotDead isActive {
        
    }

    function pauseContract() public onlyOwner isActive {
        currentState = State.Paused;
    }

    function reactivateContract() public onlyOwner isPaused {
        currentState = State.Active;
    }

    function killContract() public payable onlyOwner isNotDead {
        (bool sent, bytes memory data) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
        currentState = State.Dead;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier isActive() {
        require(currentState == State.Active);
        _;
    }

    modifier isPaused() {
        require(currentState == State.Paused);
        _;
    }

    modifier isNotDead() {
        require(currentState != State.Dead, newVersionMessage); //"Address of new Implementation is: " + abi.encodePacked(newVersion)
        _;
    }
}