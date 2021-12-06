// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Manageable {
    address public manager;
    address public pendingManager;

    event ManagementTransferred(address indexed oldManager, address indexed newManager);

    modifier onlyManager() {
        require(manager == msg.sender, "Manageable: Caller is not the manager");
        _;
    }

    constructor(address _manager) {
        _setManager(_manager);
    }

    function transferManagement(address newManager) public onlyManager {
        pendingManager = newManager;
    }

    function claimManagement() public {
        require(pendingManager == msg.sender, "Manageable: Caller is not the pending manager");
        _setManager(pendingManager);
        pendingManager = address(0);
    }

    function _setManager(address newManager) private {
        address oldManager = manager;
        manager = newManager;
        emit ManagementTransferred(oldManager, newManager);
    }
}