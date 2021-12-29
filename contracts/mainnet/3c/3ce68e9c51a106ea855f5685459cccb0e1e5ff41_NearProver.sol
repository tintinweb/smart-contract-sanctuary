/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

contract AdminControlled {
    address public admin;
    uint public paused;

    constructor(address _admin, uint flags) public {
        admin = _admin;
        paused = flags;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier pausable(uint flag) {
        require((paused & flag) == 0 || msg.sender == admin);
        _;
    }

    function adminPause(uint flags) public onlyAdmin {
        paused = flags;
    }

    function adminSstore(uint key, uint value) public onlyAdmin {
        assembly {
            sstore(key, value)
        }
    }

    function adminSstoreWithMask(
        uint key,
        uint value,
        uint mask
    ) public onlyAdmin {
        assembly {
            let oldval := sload(key)
            sstore(key, xor(and(xor(value, oldval), mask), oldval))
        }
    }

    function adminSendEth(address payable destination, uint amount) public onlyAdmin {
        destination.transfer(amount);
    }

    function adminReceiveEth() public payable onlyAdmin {}

    function adminDelegatecall(address target, bytes memory data) public payable onlyAdmin returns (bytes memory) {
        (bool success, bytes memory rdata) = target.delegatecall(data);
        require(success);
        return rdata;
    }
}

contract NearProver is AdminControlled {
    address public bridge;

    constructor(
        address _bridge,
        address _admin,
        uint _pausedFlags
    ) public AdminControlled(_admin, _pausedFlags) {
        bridge = _bridge;
    }
}