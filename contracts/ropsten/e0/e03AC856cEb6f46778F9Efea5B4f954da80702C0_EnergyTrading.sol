/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity >=0.4.21 <0.9.0;

//Contract that allows battery address to be registered
contract batteryRegistry {

    event batteryAdded(address indexed ownerOfBattery, uint date, string id);
    event batteryUpdated(address indexed ownerOfBattery, uint date, string id);

    struct battery {
        address batteryID;            //battery wallet address
        string uuID;                  //id of battery
        uint timestamp;
        bool isExist;                 //Check if battery exists
    }
    //e.g. type of bytes32: 0x454f533857453739536f6e4847486335447175563466787479396248666e4c53
    //You have to convert string to bytes32 through web3.

    //mapping address as key to struct battery with mapping name batteries
    mapping (address => battery) batteries;

    modifier onlyRegisteredBattery{
         require(batteries[msg.sender].isExist==true, "Only registered batteries have access");
         _;
     }

    //add a battery by eth account address
    function addNewBattery (string memory uuID) public {
        require(batteries[msg.sender].isExist==false, "Battery details already added");
        batteries[msg.sender] = battery(msg.sender, uuID, block.timestamp, true);
        emit batteryAdded(msg.sender, block.timestamp, uuID);
    }

    //change details of a battery
    function updateBattery(address batteryID, string memory uuID) public onlyRegisteredBattery {
        batteries[batteryID].uuID = uuID;
        uint day = block.timestamp;
        emit batteryUpdated(batteryID, day, uuID);
    }

    //view single battery by battery id
    function getBatteryByAddress(address batteryID) public view returns (address, string memory, uint){
        return (batteries[batteryID].batteryID, batteries[batteryID].uuID, batteries[batteryID].timestamp);
    }
}

contract EnergyTrading is batteryRegistry {

    event offerEnergyNotifier(address indexed seller, uint indexed day, uint indexed price, uint energy);
    event askEnergyNotifier(address indexed buyer, uint indexed day, uint energy);

    uint constant cent = 1;
    uint constant dollar = 100 * cent;

    uint constant mWh = 1;
    uint constant  Wh = 1000 * mWh;
    uint constant kWh = 1000 * Wh;
    uint constant MWh = 1000 * kWh;
    uint constant GWh = 1000 * MWh;
    uint constant TWh = 1000 * GWh;

    //uint uinversalPrice = 2; //Energy market price per kWh (ex. 2euro/kWh, the price is trial)

    struct bid {
        address prosumerID;    
        uint numberOfBid;    //A battery can create more than one energy offer
        uint energy;         //energy to trade
        uint eprice;         //Energy market price per kWh
        uint timestamp;      //timestamp for when the bid was created
    }
    
    struct ask {
        address consumerID;
        uint energy;
        uint timestamp;
        uint remainingEnergy;
    }

    //struct to store all energy purchases
    struct buyedEnergy {
        address consumerID;
        address prosumerID;
        uint energy;
        uint price;
        uint timestamp;
    }
    
    mapping(address => uint) asks; 
    ask[] listOfAsks;

    buyedEnergy[] listOfBuyedEnergy;

    mapping(address => uint) bids;
    bid[] listOfBids;
    uint nextNumberOfBid;                                    

    //create energy offer 
    //There is a minimum energy requirement 
    //Only registered batteries can use this function
    function energyOffer(uint _energy, uint _eprice) public {
        require(_energy >= kWh, "Wrong energy input require a minimum offer of 1 kWh(in whs), for instance 5.6kwhs = 5600whs");
        require(_eprice >= cent, "Price in 'cent', for example 1.5dollars/kwh = 150cents/kwh");

        listOfBids.push(bid({
            prosumerID: msg.sender,
            numberOfBid: nextNumberOfBid,
            energy: _energy,
            eprice: _eprice,
            timestamp: block.timestamp
        }));
        nextNumberOfBid++;

        emit offerEnergyNotifier(msg.sender, block.timestamp, _eprice, _energy);

        bidEnergyTrading(listOfBids[listOfBids.length-1]);
    }

    //make ask request and buy energy from available bids
    function askEnergy(uint _energy) public {
        require(_energy >= kWh, "Wrong energy input require a minimum offer of 1 kWh (in whs), for instance 5.6kwhs = 5600whs");

        listOfAsks.push(ask({
            consumerID: msg.sender,
            energy: _energy,
            timestamp: block.timestamp,
            remainingEnergy: _energy
        }));

        emit askEnergyNotifier(msg.sender, block.timestamp, _energy);

        askEnergyTrading(listOfAsks[listOfAsks.length-1]);
    }

    //core function for energy trading (ask case)
    function askEnergyTrading(ask memory _ask) private {
        //require(listOfBids.length > 0, "There is no energy offer");

        uint remainingEnergy = _ask.remainingEnergy;

        for(uint i = 0; i<listOfBids.length; i++){

            address _prosumerID;
            bool isEnergyPurchased = false;
            uint energyPurchased = 0;
            uint _price = 0;

            if(listOfBids[i].energy < remainingEnergy){
                _prosumerID = listOfBids[i].prosumerID;
                energyPurchased = listOfBids[i].energy; 
                remainingEnergy = remainingEnergy - listOfBids[i].energy;
                listOfAsks[i].remainingEnergy = remainingEnergy;
                _price = listOfBids[i].eprice*energyPurchased;
                listOfBids[i].energy = 0;

                isEnergyPurchased = true;

                //remove energy offer from the list if energy is zero
                if (listOfBids.length > 1) {
                    listOfBids[i] = listOfBids[listOfBids.length-1];
                }
                listOfBids.length--;
                i--;

            }else if(listOfBids[i].energy == remainingEnergy){
                _prosumerID = listOfBids[i].prosumerID;
                energyPurchased = remainingEnergy;
                _price = listOfBids[i].eprice*energyPurchased;
                listOfBids[i].energy = 0;
                remainingEnergy = 0;

                isEnergyPurchased = true;

                if (listOfBids.length > 1) {
                    listOfBids[i] = listOfBids[listOfBids.length-1];
                }
                listOfBids.length--;

            }else{
                _prosumerID = listOfBids[i].prosumerID;
                energyPurchased = remainingEnergy;
                listOfBids[i].energy = listOfBids[i].energy - remainingEnergy;
                _price = listOfBids[i].eprice*energyPurchased;
                remainingEnergy = 0;

                isEnergyPurchased = true;
            }

            //store purchase 
            if(isEnergyPurchased){
                listOfBuyedEnergy.push(buyedEnergy({
                    consumerID: msg.sender,
                    prosumerID: _prosumerID,
                    energy: energyPurchased,
                    price: _price,
                    timestamp: _ask.timestamp
                }));
            }

            //remove ask request from list 
            if(remainingEnergy == 0){
                if (listOfAsks.length > 1){
                    listOfAsks[i] = listOfAsks[listOfAsks.length-1];
                }
                listOfAsks.length--;
                break ;
            }
        }
    }

    /////Energy trading for bid case 
    function bidEnergyTrading(bid memory _bid) private {
        uint _remainingBidEnergy = _bid.energy;

        for(uint i = 0; i<listOfAsks.length; i++){
            
            address _consumerID;
            bool isEnergyPurchased = false;
            uint energyPurchased = 0;
            uint _price = 0;
            if(listOfAsks[i].remainingEnergy < _remainingBidEnergy){
                _consumerID = listOfAsks[i].consumerID;
                energyPurchased = listOfAsks[i].remainingEnergy;
                _remainingBidEnergy = _remainingBidEnergy - energyPurchased;
                listOfBids[i].energy = _remainingBidEnergy;
                _price = _bid.eprice*energyPurchased;
                listOfAsks[i].remainingEnergy = 0;

                isEnergyPurchased = true;

                if(listOfAsks.length > 1){
                    listOfAsks[i] = listOfAsks[listOfAsks.length-1];
                }
                listOfAsks.length--;
                i--;

            }else if(listOfAsks[i].remainingEnergy == _remainingBidEnergy){
                _consumerID = listOfAsks[i].consumerID;
                energyPurchased = _remainingBidEnergy;
                _price = _bid.eprice*energyPurchased;
                _remainingBidEnergy = 0;
                listOfAsks[i].remainingEnergy = 0;

                isEnergyPurchased = true;

                if(listOfAsks.length > 1){
                    listOfAsks[i] = listOfAsks[listOfAsks.length-1];
                }
                listOfAsks.length--;

            }else{
                _consumerID = listOfAsks[i].consumerID;
                energyPurchased = _remainingBidEnergy;
                listOfAsks[i].remainingEnergy = listOfAsks[i].remainingEnergy - energyPurchased;
                _price = _bid.eprice*energyPurchased;
                _remainingBidEnergy = 0;

                isEnergyPurchased = true;
            }

            if(isEnergyPurchased){
                listOfBuyedEnergy.push(buyedEnergy({
                    consumerID: _consumerID,
                    prosumerID: msg.sender,
                    energy: energyPurchased,
                    price: _price,
                    timestamp: _bid.timestamp
                }));
            }

            if(_remainingBidEnergy == 0){
                if(listOfBids.length > 1){
                    listOfBids[i] = listOfBids[listOfBids.length-1];
                }
                listOfBids.length--;
                break;
            }
        }
    }

    //list of all ask energy requests
    function viewAllAsks (uint n, uint offset) public view returns (address[] memory, uint[] memory, uint[] memory, uint[] memory){
        require(n>0, "n must be greater than 0");
        if(offset+n > listOfAsks.length) offset = 0;
        if(n>listOfAsks.length) n=listOfAsks.length;
        address[] memory _consumers = new address[](n);
        uint[] memory _dates = new uint[](n);
        uint[] memory _energyList = new uint[](n);
        uint[] memory _remainingEnList = new uint[](n);
        for(uint i = offset; i < n; i++){
            _consumers[i] = listOfAsks[i].consumerID;
            _dates[i] = listOfAsks[i].timestamp;
            _energyList[i] = listOfAsks[i].energy;
            _remainingEnList[i] = listOfAsks[i].remainingEnergy;
        }
        return(_consumers, _dates, _energyList, _remainingEnList);
    }

    //list of all energy purchases
    function viewAllEnergyPurchases (uint n, uint offset) public view returns (address[] memory, address[] memory, uint[] memory, uint[] memory, uint[] memory){
        require(n>0, "n must be greater than 0");
        if(offset+n > listOfBuyedEnergy.length) offset = 0;
        if(n>listOfBuyedEnergy.length) n=listOfBuyedEnergy.length;
        address[] memory _prosumers = new address[](n);
        address[] memory _consumersList= new address[](n);
        uint[] memory _prchsEnergy = new uint[](n);
        uint[] memory _prices = new uint[](n);
        uint[] memory _time = new uint[](n);
        for(uint i = offset; i < n; i++){
            _prosumers[i] = listOfBuyedEnergy[i].prosumerID;
            _consumersList[i] = listOfBuyedEnergy[i].consumerID;
            _prchsEnergy[i] = listOfBuyedEnergy[i].energy;
            _prices[i] = listOfBuyedEnergy[i].price;
            _time[i] = listOfBuyedEnergy[i].timestamp;
        }
        return(_prosumers, _consumersList, _prchsEnergy, _prices, _time);
    }

    //view all bids 
    function viewAllBids (uint n, uint offset) public view returns (address[] memory, uint[] memory, uint[] memory, uint[] memory){
        require(n>0, "n must be greater than 0");
        if(offset+n > listOfBids.length) offset=0;
        if(n>listOfBids.length) n=listOfBids.length;
        address[] memory prosumers = new address[](n);
        uint[] memory dates = new uint[](n);
        uint[] memory energyList = new uint[](n);
        uint[] memory prices = new uint[](n);
        for(uint i = offset; i < n; i++){
            prosumers[i] = listOfBids[i].prosumerID;
            dates[i] = listOfBids[i].timestamp;
            energyList[i] = listOfBids[i].energy;
            prices[i] = listOfBids[i].eprice;
        }
        return(prosumers, dates, energyList, prices);
    }

    function getCountOfAsks () public view returns (uint count){
        return listOfAsks.length;
    }

    function getCountOfBids () public view returns (uint count){
        return listOfBids.length;
    }

    function getCountOfPurchases () public view returns (uint count){
        return listOfBuyedEnergy.length;
    }

    function getPurchaseByIndex (uint _index) public view returns (address, address, uint, uint, uint){
        buyedEnergy storage _purchases = listOfBuyedEnergy[_index];
        return(_purchases.prosumerID, _purchases.consumerID, _purchases.energy, _purchases.price, _purchases.timestamp);
    }

    function getBidsByIndex (uint _index) public view returns (address, uint, uint, uint){
        bid storage _bid = listOfBids[_index];
        return(_bid.prosumerID, _bid.energy, _bid.eprice, _bid.timestamp);
    }

    function getAsksByIndex (uint _index) public view returns (address, uint, uint, uint){
        ask storage _ask = listOfAsks[_index];
        return(_ask.consumerID, _ask.energy, _ask.timestamp, _ask.remainingEnergy);
    }
}