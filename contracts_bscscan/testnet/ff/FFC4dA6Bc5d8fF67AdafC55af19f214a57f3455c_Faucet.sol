/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    uint256 constant public tokenAmount = 100000000000000000000;
    uint256 constant public waitTime = 3 minutes;

    ERC20 public tokenInstance;

    mapping(address => uint256) lastAccessTime;

    constructor(address _tokenInstance) {
        require(_tokenInstance != address(0));
        tokenInstance = ERC20(_tokenInstance);
    }

    struct Participant {
        bool registered;  // if true, that person already registered
    }

    mapping(address => Participant) public participants;
    uint public numParticipants;

    modifier onlyOnce() {
        if (participants[msg.sender].registered) {
            revert("GROGU::MultiSig::Transfers to non-whitelisted contracts declined");
        }
        _;
    }

    function Registration() internal {
        numParticipants = 0;
    }

    function register() internal onlyOnce{
        Participant storage p = participants[msg.sender];
        p.registered = true;
        numParticipants++;
    }

    function requestTokens() public onlyOnce() {
        require(allowedToWithdraw(msg.sender));
        tokenInstance.transfer(msg.sender, tokenAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}