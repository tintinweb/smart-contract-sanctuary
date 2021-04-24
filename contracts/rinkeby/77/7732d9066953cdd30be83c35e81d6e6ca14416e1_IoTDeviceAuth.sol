/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IoTDeviceAuth
 * @dev Validates a device to the network
 */
contract IoTDeviceAuth {

    struct Device {
        string firmware;
        string deviceName;
        int authId;
        uint8 deviceId;
        uint8 version;
        uint timestamp;
        bool isAuthorized;
    }// end of struct
    
    address private owner;
    mapping (uint8 => string) private network;
    Device private device;
        
    int constant authId1 = 2110;
    int constant authId2 = 1120;
    int constant authId3 = 3011;
    
    // event for EVM logging
    event OwnerSet(address _owner);
    event KillContract(address _owner);
    event AuthorizedDevice(Device _d);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }// end of modifier
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender;
        emit OwnerSet(owner);
    }// end of constructor
    
    /**
     * @dev This function authorizes the device to the network
     */
    function authorizeDeviceConnection(string memory _firmware,
                                       string memory _deviceName,
                                       uint8 _deviceId,
                                       uint8 _version,
                                       int _authId) external returns (bool) {
        bool auth = false;
        
        device.firmware = _firmware;
        device.deviceName = _deviceName;
        device.deviceId = _deviceId;
        device.version = _version;
        device.authId = _authId;
        device.timestamp = block.timestamp;
        
        if (device.authId == authId1) {
            auth = true;        
        }
        else if (device.authId == authId2) {
            auth = true;
        }
        else if (device.authId == authId3) {
            auth = true;
        }
        
        device.isAuthorized = auth;
        
        emit AuthorizedDevice(device);
        return auth;
    }// end of function
    
    /**
     * @dev Selfdestruct the contract when it is no longer needed
     */
    function kill() external isOwner payable {
        
        address payable addr = payable(address(owner));
        
        emit KillContract(owner);
        selfdestruct(addr);
        
    }// end of function
    
}// end of contract IoTDeviceAuth