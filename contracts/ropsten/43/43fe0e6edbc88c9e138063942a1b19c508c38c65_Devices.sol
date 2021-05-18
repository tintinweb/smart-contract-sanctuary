/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Devices{

    event Message(
        string msg
    );

    struct Device{
        string name;
        uint idx;                                           // das geht besser
        address[] owner;
        uint[] dates;
    }

    // Devices are stored in map
    mapping (uint => Device) private devices;

    // add device to device storage
    function addDevice(uint devID, string memory name) public returns (int) {

        // check if a name is providet
        if (bytes(name).length == 0){
            emit Message("no name provided");
            return 1;
        }

        // check if a named device with the same id exists
        if(bytes(devices[devID].name).length == 0) {

            // creating a bufferdevice
            Device memory devicebuff;
            devicebuff.name = name;
            devicebuff.idx = 0;
            devicebuff.owner = new address[](50);
            devicebuff.owner[devicebuff.idx] = msg.sender;
            devicebuff.dates = new uint[](50);
            devicebuff.dates[devicebuff.idx] = block.timestamp;

            // adding device to device storage
            devices[devID] = devicebuff;
            emit Message("added device");
            return 0;
        } else {
            emit Message("failed to add device id already taken");
            return 1;
        }
    }


    // retriving information about a device
    function getDevice(uint devID) public returns (string memory, address, uint){
        // check if a named device with the same id exists
        if(bytes(devices[devID].name).length == 0) {
            emit Message("no device present at deviceID");
            return ("error",address(1),1);
        } else {
            return (devices[devID].name, devices[devID].owner[devices[devID].idx], devices[devID].dates[devices[devID].idx]);
        }
    }

    function transferOwnership(uint devID, address nextOwner) public returns (int) {
        // check if device eists
        if(bytes(devices[devID].name).length != 0) {
            emit Message("device exists");
            // check if message sender is owner of the device
            if(msg.sender == devices[devID].owner[devices[devID].idx]){
                emit Message("this is your device");
                devices[devID].idx++;
                devices[devID].owner[devices[devID].idx] = nextOwner;
                devices[devID].dates[devices[devID].idx] = block.timestamp;
                emit Message("deviceownership transfered");
                return 0;
            } else {
                emit Message("this is not your device you have no powers here");
                return 1;
            }
        } else {
            emit Message("no such device");
            return 1;
        }
    }
}