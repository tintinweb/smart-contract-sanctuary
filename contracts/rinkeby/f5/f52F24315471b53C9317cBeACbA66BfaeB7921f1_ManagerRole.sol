// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract ManagerRole {
    address public superAdmin;

    event ManagerAdded(address _manager, bool _status);
    event ManagerUpdated(address _manager, bool _status);
    
    constructor() {
        superAdmin = msg.sender;
    }
    
    modifier onlySuperAdmin {
        require(superAdmin == msg.sender, "Unauthorized Access");
        _;
    }

    struct Manager {
        address _manager;
        bool _isActive;
    }
    
    mapping (address => Manager) public managers;
    
    function addManager(address _address, bool _status) external onlySuperAdmin {
        require(_address != address(0), "Manager can't be the zero address");
        managers[_address]._manager = _address;
        managers[_address]._isActive = _status;
        emit ManagerAdded(_address, _status);
    }
    
    function getManager(address _address) view external returns (address, bool) {
        return(managers[_address]._manager, managers[_address]._isActive);
    }

    function isManager(address _address) external view returns(bool _status) {
        return(managers[_address]._isActive);
    }
    
    function updateManager(address _address, bool _status) external onlySuperAdmin {
        require(managers[_address]._isActive != _status);
        managers[_address]._isActive = _status;
        emit ManagerUpdated(_address, _status);
    }
    
}

