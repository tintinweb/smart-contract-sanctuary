/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Devices{

    event Message(
        string msg
    );
    
    event ShowId(
        int id
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

    mapping (address => uint[]) private sellOffers;

    Sell[] sells;

    bool hasTestDev =false;
    bool hasTestSell=false;

    uint nexID;

    function buyDevice(uint sidx) public payable returns (int){

        if (msg.value < sells[sidx].price){
            emit Message("send amount not enough");
            (bool sentx,  ) = msg.sender.call{value: msg.value}("");
            require(sentx, "Failed to send Ether");
            return -1;
        }else{
            if (msg.value > sells[sidx].price){
                uint refundFee = msg.value - sells[sidx].price;
                (bool senty,  ) = msg.sender.call{value: refundFee}("");
                require(senty, "Failed to send Ether");
            }
            emit Message("send amount enough");
            (bool sent,  ) = devices[sells[sidx].devID].owner[devices[sells[sidx].devID].idx] .call{value: sells[sidx].price}("");
            require(sent, "Failed to send Ether");
            devices[sells[sidx].devID].idx++;
            devices[sells[sidx].devID].owner[devices[sells[sidx].devID].idx] = msg.sender;
            devices[sells[sidx].devID].dates[devices[sells[sidx].devID].idx] = block.timestamp;
            sells[sidx].sold=true;
            return 0;
        }
        //  0 => OK
        // -1 => not the right amount send
    }

    function addTestDevice() public returns (int){
        if(hasTestDev == false){
            Device memory devicebuff;
            devicebuff.name = 'test device';
            devicebuff.idx = 0;
            devicebuff.owner = new address[](50);
            devicebuff.owner[devicebuff.idx] = address(1);
            devicebuff.dates = new uint[](50);
            devicebuff.dates[devicebuff.idx] = block.timestamp;
            devicebuff.owner[devicebuff.idx++] = address(2);
            devicebuff.dates[devicebuff.idx] = block.timestamp;

            // adding device to device storage
            devices[0]=devicebuff;
            hasTestDev = true;
            return 0;
        } else {
            return -1;
        }
        // 0  => testdevice added
        // -1 => testdevice already exists noch changes
    }

    function addTestSell() public returns (int){
        if(hasTestSell == false){
            Sell memory sellbuf;
            sellbuf.devID=0;
            sellbuf.price=999;
            sellbuf.urlOfPicture="https://youtu.be/6-HUgzYPm9g";
            sellbuf.details="best device ever";
            sellbuf.country="Lummerland";
            sellbuf.condition=Condition.BRANDNEW;
            sellbuf.sold=true;
            sells.push(sellbuf);
            hasTestSell = true;
            return 0;
        } else {
            return -1;
        }
        // 0  => testsell added
        // -1 => testsell already exists noch changes
    }

    // add device to device storage
    function addDevice(string memory name) public returns (int) {
        // check if a name is providet
        if (bytes(name).length == 0){
            emit Message("no name provided");
            return -1;
        }
        uint devIDbuf = getUniqueId();

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
            emit ShowId(int(devIDbuf));
            return int(devIDbuf);
        } else {
            emit Message("failed to add device id already taken");
            return -2;
        }
        // uint => OK
        //   -1 => no name
        //   -2 => id taken
    }

    // retriving information about a device
    function getDevice(uint devID) public view returns (string memory, address, uint){
        // check if a named device with the same id exists
        if(bytes(devices[devID].name).length == 0) {
            //emit Message("no device present at deviceID");
            return ("error",address(1),1);
        } else {
            return (devices[devID].name,
                    devices[devID].owner[devices[devID].idx],
                    devices[devID].dates[devices[devID].idx]);
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
        if ((bytes(devices[devID].name).length) == 0) {
            emit Message("no such device");
            return -1;
        } else if (msg.sender != devices[devID].owner[devices[devID].idx]){
            emit Message("this is not your device you have no powers here");
            return -2;
        }else if (bytes(urlOfPicture).length == 0){
            emit Message("no Picture url given");
            return -3;
        }else if (bytes(details).length == 0){
            emit Message("no details given");
            return -4;
        }else if (bytes(country).length == 0){
            emit Message("no country given");
            return -5;
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

        sellOffers[msg.sender].push(sells.length-1);

        return 0;
        //  0 => OK
        // -1 => No such device
        // -2 => Not the owner of device
        // -3 => No picture url
        // -4 => No details
        // -5 => No country
    }

    function getSells(address sellerAdr) public view returns (Sell[] memory){
        uint len = sellOffers[sellerAdr].length;
        Sell[] memory offers = new Sell[](len);
        for (uint i = 0; i < len; i++) {
            offers[i] = sells[sellOffers[sellerAdr][i]];
        }
        
        return offers;
    }

    function getCurrentOwner(uint devID) public view returns (address){
        address[] memory ownersbuf = devices[devID].owner;
        address currentOwner = ownersbuf[ownersbuf.length-1];
        return currentOwner;
    }

    function getSells() public view returns (Sell[] memory){
        return sells;
    }

    function getLastSellId() public view returns (uint){
        return sells.length-1;
    }

    function getSell(uint sidx) public view returns (
        uint,
        uint,
        string memory,
        string memory,
        string memory,
        Condition,bool){
            return (sells[sidx].devID,
                    sells[sidx].price,
                    sells[sidx].urlOfPicture,
                    sells[sidx].details,
                    sells[sidx].country,
                    sells[sidx].condition,
                    sells[sidx].sold);
        }
}