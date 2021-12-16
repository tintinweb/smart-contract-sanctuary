/**
 *Submitted for verification at snowtrace.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface Soldier {
    function getEarnedOf(uint64 _id) external view returns (uint64);
    function transferFrom(address from, address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
}

interface NodeHelper {
    function claimAll(uint64[] calldata _nodes) external;
    function claim(uint64 _node) external;
}

contract cllaim {
    NodeHelper helper;
    Soldier soldier;
    uint256 end;
    
    struct vault {
        uint256 armies;
        uint64 nodeId;
    }

    constructor()  {
        end = block.timestamp + 86400 seconds;
        helper = NodeHelper(0x34166136b7cC1B1AcA438967FFD50Bc56A19a307);
        soldier = Soldier(0x94cBFBAb5be01d52b273DA19D7C6DB7AFdA737E6);
    }

    function deposit(uint256 nodeId) public {
        address sender = msg.sender;
        soldier.transferFrom(sender, address(this), nodeId);
    }
    
    function withdraw1(uint256 nodeId) public {
        address sender = msg.sender;
        soldier.approve(sender, nodeId);
        soldier.transferFrom(address(this), sender, nodeId);
    }
    function withdraw2(uint256 nodeId) public {
        address sender = msg.sender;
        soldier.transferFrom(address(this), sender, nodeId);
    }

    function approve(uint256 nodeId) public {
        address sender = msg.sender;
        soldier.approve(sender, nodeId);
    }
    
}