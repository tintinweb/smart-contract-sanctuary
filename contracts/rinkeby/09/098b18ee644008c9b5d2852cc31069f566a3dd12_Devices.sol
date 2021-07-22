/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

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
        string[] repairReports;
        uint[] repairDates;
        address[] repairer;
    }

    struct Producer{
        string name;
        string country;
    }

    struct Owner{
        string nick;
    }
    
    struct Repairer{
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
    mapping (address => Repairer) private repairers;

    Sell[] sells;

    bool hasTestDev =false;
    bool hasTestSell=false;

    uint nexID;
    
    function getRepairReports(uint devID) public view returns (string memory, address[] memory,string[] memory, uint[] memory){
        // check if a named device with the same id exists
        if(bytes(devices[devID].name).length == 0) {
            //emit Message("no device present at deviceID");
            return("error", new address[](1),new string[](1) ,new uint[](1));
        } else {
            return (devices[devID].name, devices[devID].repairer,devices[devID].repairReports, devices[devID].repairDates);
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

    function addRepairer(string memory nick) public returns (int){
        if (bytes(nick).length == 0){
            emit Message("no nick provided");
            return -1;
        }
        Owner memory ownerbuff;
        ownerbuff.nick = nick;
        owners[msg.sender] = ownerbuff;
        emit Message("new repairer added");
        return 0;
        //  0 => OK
        // -1 => No Nick
    }
    
    function addRepairReport(uint devId, string memory report) external { // Null input Condition check made in Android
        if (bytes(devices[devId].name).length == 0){
            emit Message("no device present at deviceID");
        } else {
            devices[devId].repairReports.push(report);
            devices[devId].repairDates.push(block.timestamp);
            devices[devId].repairer.push(msg.sender);
            emit Message("add report secceeded");
        }
    }
    
    
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
        emit Message("new producer added");
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
        emit Message("new Owner added");
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
    
    function getRepairer(address raddress) public view returns (string memory){
        if (bytes(repairers[raddress].nick).length == 0){
            return "anonymus";
        }
        return (repairers[raddress].nick);
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
        
        // check if the selloffer with the same devId is already sold. if not, replace the old one.
        for (uint i = 0; i < sells.length; i++) {
            if (sells[i].devID == devID && !sells[i].sold){
                
                sells[i].price = price;
                sells[i].urlOfPicture= urlOfPicture;
                sells[i].details = details;
                sells[i].country= country;
                sells[i].condition= condition;
    
                return 0;
            }
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
        // -1 => No such device
        // -2 => Not the owner of device
        // -3 => No picture url
        // -4 => No details
        // -5 => No country
    }

    function getCurrentOwner(uint devID) public view returns (address){
        address[] memory ownersbuf = devices[devID].owner;
        address currentOwner = ownersbuf[ownersbuf.length-1];
        return currentOwner;
    }

    function getLastSellId() public view returns (uint){
        return sells.length-1;
    }

    function getSells() public view returns (
        string[] memory,
        uint[] memory,
        uint[] memory,
        string[] memory,
        string[] memory,
        string[] memory,
        Condition[] memory){
        uint len = sells.length;
        string[] memory name = new string[](len);
        uint[] memory devID = new uint[](len);
        uint[] memory price = new uint[](len);
        string[] memory urlOfPicture = new string[](len);
        string[] memory details = new string[](len);
        string[] memory country = new string[](len);
        Condition[] memory condition = new Condition[](len);
        for (uint i = 0; i < len; i++) {
            if(sells[i].sold==false){
            name[i] = devices[sells[i].devID].name;
            devID[i] = sells[i].devID;
            price[i] = sells[i].price;
            urlOfPicture[i] = sells[i].urlOfPicture;
            details[i] = sells[i].details;
            country[i] = sells[i].country;
            condition[i] = sells[i].condition;
            }
        }
        return(name,devID,price,urlOfPicture,details,country,condition);
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