/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;



// Part: DeepFreeze

contract DeepFreeze {
    // Variables
    address payable public owner; // publicly visible owner of the freezer
    string internal _hint; // only this contract can see this.
    bytes32 internal _answer; // only this contract can see this.
    uint256 public launchblock; // block the freezer was locked at.
    uint256 public blocklock; // optional, lock the withdraw function for a certain number of blocks.

    constructor(
        address eoa,
        string memory hint,
        bytes32 answer
    ) {
        // see createFreezer
        owner = payable(eoa); //  owner is freezer creator as payable
        _hint = hint;
        _answer = answer;
        launchblock = block.number;
        blocklock = 0; // default to no lock
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the freezer owner can do that!");
        _;
    }

    modifier checkLock() {
        require(
            block.number > launchblock + blocklock,
            "This contract is still time-locked!"
        );
        _;
    }

    function LockWithdraw(uint256 numblocks) public onlyOwner {
        blocklock = numblocks;
    }

    function requestHint() public view onlyOwner returns (string memory) {
        return (_hint);
    }

    function requestKey() public view onlyOwner returns (bytes32) {
        return (_answer);
    }

    function deposit() public payable {
        // accept deposits from anyone
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(string memory passphrase_) public onlyOwner checkLock {
        require(
            keccak256(abi.encodePacked(passphrase_)) == _answer,
            "Your passphrase is wrong."
        );
        require(getBalance() != 0, "There's nothing to withdraw.");
        // Input code for withdrawing a specific ERC-20 asset.
        selfdestruct(owner); // automatically sends **ETH** to address upon contract death.
        // ONLY ETH. Don't self destruct with ERC-20 balance!
    }
}

// File: DeepFreeze.sol

contract CreateFreezer {
    address public creatorOwner; // public state variable automatically has getter function
    DeepFreeze[] public deployedFreezer; // public array automatically has getter function
    mapping(address => DeepFreeze[]) public userFreezer;

    constructor() {
        creatorOwner = msg.sender;
        // owner of the creator contract is the original deployer (i.e., protocol admin, not freezer owner)
    }

    function createFreezer(string memory hint_, bytes32 answer_) public {
        DeepFreeze new_freezer_address = new DeepFreeze(
            msg.sender,
            hint_,
            answer_
        );
        // pass caller to DeepFreeze constructor as eoa; makes them owner of a their freezer
        userFreezer[msg.sender].push(new_freezer_address); // track freezers at the owner level
        deployedFreezer.push(new_freezer_address);
    }
}