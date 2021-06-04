/**
 *Submitted for verification at Etherscan.io on 2021-06-04
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
        uint nonce;
    }

    struct Producer{
        string name;
        string country;
    }

    struct Owner{
        string nick;
    }

    enum Condition {ACCEPTABLE, GOOD, VERYGOOD, BRANDNEW}

    struct Sell{
        uint devID;
        uint price;
        string urlOfPicture;
        string details;
        string country;
        Condition condition;
        bool sold;
    }

    // Devices are stored in map
    mapping (uint => Device) private devices;
    mapping (address => Producer) private producers;
    mapping (address => Owner) private owners;

    Sell[] sells;

    uint nexID;

    // add device to device storage
    function addDevice(string memory name) public returns (int) {
        uint devIDbuf = getUniqueId();
        // check if a name is providet
        if (bytes(name).length == 0){
            emit Message("no name provided");
            return -1;
        }
        // check if a named device with the same id exists
        if(bytes(devices[devIDbuf].name).length == 0) {
            // creating a bufferdevice
            Device memory devicebuff;
            devicebuff.name = name;
            devicebuff.idx = 0;
            devicebuff.owner = new address[](64);
            devicebuff.owner[devicebuff.idx] = msg.sender;
            devicebuff.dates = new uint[](64);
            devicebuff.dates[devicebuff.idx] = block.timestamp;
            // adding device to device storage
            devices[devIDbuf] = devicebuff;
            emit Message("added device");
            return int(devIDbuf);
        } else {
            emit Message("failed to add device id already taken");
            return -2;
        }
        // uint => OK
        //   -1 => no name
    }

    // retriving information about a device
    function getDevice(uint devID) public view returns (string memory, address, uint){
        // check if a named device with the same id exists
        if(bytes(devices[devID].name).length == 0) {
            //emit Message("no device present at deviceID");
            return ("error",address(1),1);
        } else {
            return (devices[devID].name, devices[devID].owner[devices[devID].idx], devices[devID].dates[devices[devID].idx]);
        }
    }

    // retiving device history
    function getDeviceHistory(uint devID) public view returns (string memory, address[] memory, uint[] memory){
        // check if a named device with the same id exists
        if(bytes(devices[devID].name).length == 0) {
            //emit Message("no device present at deviceID");
            return("error", new address[](1) ,new uint[](1));
        } else {
            return (devices[devID].name, devices[devID].owner, devices[devID].dates);
        }
    }

    // transfers ownership form on owner to another
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
                return -1;
            }
        } else {
            emit Message("no such device");
            return -2;
        }
        //  0 => OK
        // -1 => Not the owner of device
        // -2 => no device with devID
    }

    // devID generator
    function getUniqueId() private returns (uint){
        nexID += 1;
        return nexID;
    }

    // add a producer
    function addProducer(string memory name, string memory country) public returns (int){
        if (bytes(name).length == 0){
            emit Message("no name provided");
            return -1;
        } else if (bytes(country).length == 0){
            emit Message("no country provided");
            return -2;
        }
        Producer memory producerbuff;
        producerbuff.name = name;
        producerbuff.country = country;
        producers[msg.sender] = producerbuff;
        emit Message("added producer");
        return 0;
        //  0 => OK
        // -1 => No Name
        // -2 => Mo Country
    }

    // retrive information abour a producer
    function getProducer(address paddress) public view returns (string memory, string memory){
        if (bytes(producers[paddress].name).length == 0){
            return ("Not a Producer", "in no country");
        }
        return (producers[paddress].name, producers[paddress].country);
    }

    // add a Owner
    function addOwner(string memory nick) public returns (int){
        if (bytes(nick).length == 0){
            emit Message("no nick provided");
            return -1;
        }
        Owner memory ownerbuff;
        ownerbuff.nick = nick;
        owners[msg.sender] = ownerbuff;
        return 0;
        //  0 => OK
        // -1 => No Nick
    }

    // retrive information abour a Owner
    function getOwner(address oaddress) public view returns (string memory){
        if (bytes(owners[oaddress].nick).length == 0){
            return "anonymus";
        }
        return (owners[oaddress].nick);
    }

    function addSell(uint devID,uint price,string memory urlOfPicture,string memory details,string memory country,Condition condition) public returns(int){
        if (msg.sender != devices[devID].owner[devices[devID].idx]){
            emit Message("this is not your device you have no powers here");
            return -1;
        }else if (bytes(urlOfPicture).length == 0){
            emit Message("no Picture url given");
            return -2;
        }else if (bytes(details).length == 0){
            emit Message("no details given");
            return -3;
        }else if (bytes(country).length == 0){
            emit Message("no country given");
            return -4;
        }
        Sell memory sellbuff;
        sellbuff.devID = devID;
        sellbuff.price = price;
        sellbuff.urlOfPicture= urlOfPicture;
        sellbuff.details = details;
        sellbuff.country= country;
        sellbuff.condition= condition;
        sellbuff.sold = false;
        sells.push(sellbuff);
        return 0;
        //  0 => OK
        // -1 => Not the owner of device
        // -2 => No picture url
        // -3 => No details
        // -4 => No country
    }
}