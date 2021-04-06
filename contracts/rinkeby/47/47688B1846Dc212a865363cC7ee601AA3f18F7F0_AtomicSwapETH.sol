/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract AtomicSwapETH {
    mapping (bytes32 => uint256) public amount;
    address public owner;
    // mapping (bytes32 => bytes32) swapId;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor () {
        owner = msg.sender;
    }

    function create(bytes32 id) public payable {
        amount[id] = msg.value;
    }

    function redeem(bytes32 secret, address creator, uint64 deadline) public {

        bytes32 _hash = sha256(abi.encodePacked( secret ));

        bytes32 id = sha256(abi.encodePacked(_hash, creator, deadline));

        uint256 _amount = amount[id];
        require(_amount > 0, "Swap is not initalized");
        require(block.timestamp < deadline, "Swap is outdated");

        amount[id] = 0;

        payable(msg.sender).transfer(_amount);
    }

    function undo(bytes32 _hash, uint256 deadline) public {
        // bytes32 _hash = sha256(abi.encodePacked( secret ));

        bytes32 id = sha256(abi.encodePacked(_hash, msg.sender, deadline));

        uint256 _amount = amount[id];
        require(_amount > 0, "Swap is not initalized");
        require(block.timestamp > deadline, "Swap is not finished yet");

        amount[id] = 0;

        payable(msg.sender).transfer(_amount);
    }
}