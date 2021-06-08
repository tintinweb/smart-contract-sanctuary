/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// MINIMAL INTERFACE OF QANX REQUIRED FOR THE DISTRIBUTOR TO WORK
interface TransferableQANX {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferLocked(address recipient, uint256 amount, uint32 hardLockUntil, uint32 softLockUntil, uint8 allowedHops) external returns (bool);
}

contract DistributeQANX {

    // POINTS TO THE OFFICIAL QANX CONTRACT
    TransferableQANX private _qanx;

    // ADDRESS OF THE OFFICIAL QANX CONTRACT WILL BE PROVIDED UPON CONSTRUCT
    constructor(TransferableQANX qanx_) {
        _qanx = qanx_;
    }

    // METHOD TO DISTRIBUTE UNLOCKED TOKENS
    function distribute(uint256 total, address[] calldata recipients, uint256[] calldata amounts) external {

        // FIRST TRANSFER THE TOTAL AMOUNT TO BE DISTRIBUTED FROM THE SENDER TO THIS CONTRACT
        require(_qanx.transferFrom(msg.sender, address(this), total));

        // THEN TRANSFER THE SPECIFIED AMOUNTS TO THE RECIPIENTS ONE-BY-ONE
        for (uint256 i = 0; i < recipients.length; i++){
            require(_qanx.transfer(recipients[i], amounts[i]));
        }
    }

    // METHOD TO DISTRIBUTE LOCKED TOKENS WITH CUSTOM PARAMS
    function distributeLocked(
        uint256 total,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint32[]  calldata hardLocks, 
        uint32[]  calldata softLocks,
        uint8[]   calldata allowedHops) external 
    {

        // FIRST TRANSFER THE TOTAL AMOUNT TO BE DISTRIBUTED FROM THE SENDER TO THIS CONTRACT
        require(_qanx.transferFrom(msg.sender, address(this), total));

        // THEN TRANSFER THE SPECIFIED AMOUNTS TO THE RECIPIENTS ONE-BY-ONE WITH THE PARAMS SPECIFIED
        for (uint256 i = 0; i < recipients.length; i++){
            require(_qanx.transferLocked(recipients[i], amounts[i], hardLocks[i], softLocks[i], allowedHops[i]));
        }
    }
}