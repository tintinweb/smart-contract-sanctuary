/**
 *Submitted for verification at FtmScan.com on 2021-12-13
*/

// SPDX-license-identifier: MIT
pragma solidity ^0.8.0;


contract Admin {

    event TransferOwnership(address _old_owner, address _new_owner);

    address public owner;
    address public future_owner;

    constructor() {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    function execute(address[] calldata _targets, bytes[] calldata _calldatas) external {
        require(msg.sender == owner);

        for (uint256 i = 0; i < _targets.length; i++) {
            address target = _targets[i];
            (bool success, bytes memory result) = target.call{value: 0}(_calldatas[i]);
            require(success);
        }
    }

    function commit_transfer_ownership(address _future_owner) external {
        require(msg.sender == owner);

        future_owner = _future_owner;
    }

    function accept_transfer_ownership() external {
        require(msg.sender == future_owner);

        emit TransferOwnership(owner, msg.sender);
        owner = msg.sender;
    }
}