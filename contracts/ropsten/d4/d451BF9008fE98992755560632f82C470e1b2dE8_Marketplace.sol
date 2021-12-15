/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

pragma solidity >=0.4.21 <0.9.0;

// SPDX-License-Identifier: MIT
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// SPDX-License-Identifier: MIT

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract Device {

    using Counters for Counters.Counter;
    Counters.Counter private id;

    event onDeviceAdded(address indexed ownerOfDevice, uint date, string name);
    event onDeviceUpdated(address indexed ownerOfDevice, string name, string typeDevice, uint date, uint id);
    event onUpdated(address indexed ownerOfDevice, uint date, uint energy, uint id);
    event onDeviceTransferOwnership(address oldOwner, address indexed newOwner, uint id);
    event onDeviceRemoved(address indexed owner, uint id, uint date);
    event onEnergyRecorded(address indexed owner, uint id, uint energy, uint date);

    struct device {
        address owner;
        string typeOfDevice;
        string name;
        uint energy;
        uint uuID;
        uint date;
    }

    mapping(uint => uint) deviceMap;
    device[] devices;

    function createDevice(string memory _typeOfDevice, string memory _name) public {

        ///@notice must added a valid way to check the validity of device input

        address _owner = msg.sender;
        uint currentTime = block.timestamp;
        id.increment();
        uint currentID = id.current();
        uint idx = devices.length;
        deviceMap[currentID] = idx;
        devices.push(device({
            owner: _owner,
            typeOfDevice: _typeOfDevice,
            name: _name,
            energy: 0,
            uuID: currentID,
            date: currentTime
        }));
        emit onDeviceAdded(_owner, currentTime, _name);
    }

    function removeDevice(uint _id) public {
        address _owner = msg.sender;
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].uuID == _id && devices[i].owner == _owner){
                emit onDeviceRemoved(_owner, _id, block.timestamp);
                if (devices.length > 1) {
                    devices[i] = devices[devices.length-1];
                }
                devices.length--;
            }
        }
    }

    function updateDevice(uint _id, string memory _name, string memory _typeOfDevice) public {
        address _owner = msg.sender;
        uint index = deviceMap[_id];
        devices[index].name = _name;
        devices[index].typeOfDevice = _typeOfDevice;
        emit onDeviceUpdated(_owner, _name, _typeOfDevice, block.timestamp, _id);
    }

    function updateDeviceByMarketplace(uint _id, uint _energy) public {
        address _owner = msg.sender;
        uint index = deviceMap[_id];
        devices[index].energy = devices[index].energy - _energy;
        emit onUpdated(_owner, block.timestamp, _id, _energy);
    }

    function transferOwnershipOfDevice(uint _id, address _to) public {
        address _from = msg.sender;
        require(_from != _to, "You can not use the same address");
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].uuID == _id && devices[i].owner == _from){
                devices[i].owner = _to;
                emit onDeviceTransferOwnership(_from, _to, _id);
            }
        }
    }

    function recordEnergyPerDevice(uint _id, uint _energy) public {
        address _owner = msg.sender;
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].uuID == _id && devices[i].owner == _owner){
                devices[i].energy = _energy;
                emit onEnergyRecorded(_owner, _id, _energy, block.timestamp);
            }
        }
    }

    function getCountOfDevices() public view returns(uint){
        address currentAddr = msg.sender;
        uint count = 0;
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].owner == currentAddr){
                count++;
            }
        }
        return count;
    }

    function getMyDevices() public view returns(uint[] memory){
        uint k = 0;
        uint cnt = getCountOfDevices();
        uint[] memory idsList = new uint[](cnt);

        for(uint i = 0; i < devices.length; i++){
            if(devices[i].owner == msg.sender){
                idsList[k] = devices[i].uuID;
                k++;
            }
        }
        return idsList;
    }

    ///@notice In order to iterate with the devices of a given id we need this extra function with the current legth of device array
    ///@notice So in the Front end we would need to get the length and iterate for each device that we want to list in our platform 
    ///@notice and get the index for that device
    function getDeviceByID(uint _id) public view returns(uint, string memory, string memory, uint){
        uint index = deviceMap[_id];
        require(devices.length > index, "Wrong index");
        require(devices[index].uuID == _id, "Wrong ID");
        return(devices[index].uuID, devices[index].typeOfDevice, devices[index].name, devices[index].date);
    }

    function getTotalEnergy() public view returns(uint) {
        address currentAddr = msg.sender;
        uint res = 0;
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].owner == currentAddr){
                res = res + devices[i].energy;
            }
        }
        return res;
    }

    ///@notice Solidity generally can not return dynamic string arrays
    ///@notice so, you can use this function to show the available energy per device
    ///@notice and name, type of device as well, when someone click on it.
    function getEnergyPerDevice(uint _id) public view returns(uint) {
        uint index = deviceMap[_id];
        require(devices.length > index, "Wrong index");
        require(devices[index].uuID == _id, "Wrong ID");
        return(devices[index].energy);
    }
}

contract Marketplace is Device {

    using Counters for Counters.Counter;
    Counters.Counter private ID;
    uint currentDevice;

    event onNewBid(address indexed seller, uint indexed day, uint indexed price, uint energy);
    event onNewAsk(address indexed buyer, uint indexed day, uint indexed price, uint energy);
    event bidRemoved(address indexed seller, uint indexed day, uint id, uint indexed price, uint energy);
    event askRemoved(address indexed buyer, uint indexed day, uint id, uint indexed price, uint energy);
    event onUpdateBid(address indexed seller, uint indexed id, uint indexed price, uint energy);
    event onUpdateAsk(address indexed buyer, uint indexed id, uint indexed price, uint energy);
    event onPurchased(address indexed seller, address indexed buyer, uint indexed day, uint energy);

    uint constant mCent = 1;
    //uint constant cent = 1000 * mCent;
    //uint constant dollar = 1000 * cent;

    uint constant mWh = 1;
    uint constant  Wh = 1000 * mWh;
    uint constant kWh = 1000 * Wh;
    uint constant MWh = 1000 * kWh;
    uint constant GWh = 1000 * MWh;
    uint constant TWh = 1000 * GWh;

    struct eBid {
        address seller;
        uint idOfDevice;
        uint idOfBid;
        uint energy;
        uint eprice;
        uint timestamp;
    }

    mapping(uint => uint) ebids;
    eBid[] listOfEnergyBids;
    
    struct eAsk {
        address buyer;
        uint idOfDevice;
        uint idOfAsk;
        uint energy;
        uint price;
        uint timestamp;
    }

    mapping(uint => uint) easks;
    eAsk[] listOfEnergyAsks;

    struct ePurchases {
        address buyer;
        address seller;
        uint idOfDevice;
        uint energy;
        uint id;
        uint price;
        uint timestamp;
    }

    mapping(uint => uint) epurchases;
    ePurchases[] listOfPurchases;

    function setDevice(uint _idOfDevice) public {
        currentDevice = _idOfDevice;
    }

    function energyBid(uint _energy, uint _eprice, uint _idOfDevice) public {
        require(_energy >= kWh, "Wrong energy input require a minimum offer of 1 kWh(in whs), for instance 5.6kwhs = 5600whs");
        require(_eprice >= mCent, "Price in 'cent', for example 1.5dollars/kwh = 150cents/kwh");
        setDevice(_idOfDevice);
        ID.increment();
        uint currentID = ID.current();
        address currentAddr = msg.sender;
        uint idx = ebids[currentID];
        idx = listOfEnergyBids.length;
        ebids[currentID] = idx;
        listOfEnergyBids.push(eBid({
            seller: currentAddr,
            idOfDevice: currentDevice,
            idOfBid: currentID,
            energy: _energy,
            eprice: _eprice,
            timestamp: block.timestamp
        }));
        emit onNewBid(currentAddr, block.timestamp, _eprice, _energy);
    }

    function energyAsk(uint _energy, uint _price, uint _idOfDevice) public {
        require(_energy >= kWh, "Wrong energy input require a minimum offer of 1 kWh(in whs), for instance 5.6kwhs = 5600whs");
        require(_price >= mCent, "Price in 'cent', for example 1.5dollars/kwh = 150cents/kwh");
        setDevice(_idOfDevice);
        ID.increment();
        uint currentID = ID.current();
        address currentAddr = msg.sender;
        uint idx = easks[currentID];
        idx = listOfEnergyAsks.length;
        easks[currentID] = idx;
        listOfEnergyAsks.push(eAsk({
            buyer: currentAddr,
            idOfDevice: currentDevice,
            idOfAsk: currentID,
            energy: _energy,
            price: _price,
            timestamp: block.timestamp
        }));
        emit onNewAsk(currentAddr, block.timestamp, _price, _energy);
    }

    function updateBid(uint _idOfBid, uint _energy, uint _price) public {
        require(_energy >= kWh, "Wrong energy input require a minimum offer of 1 kWh(in whs), for instance 5.6kwhs = 5600whs");
        require(_price >= mCent, "Price in 'cent', for example 1.5dollars/kwh = 150cents/kwh");
        for(uint i = 0; i<listOfEnergyBids.length; i++){
            if(listOfEnergyBids[i].idOfBid == _idOfBid){
                listOfEnergyBids[i].energy = _energy;
                listOfEnergyBids[i].eprice = _price;
                emit onUpdateBid(listOfEnergyBids[i].seller, listOfEnergyBids[i].idOfBid, _price, _energy);
            }
        }
    }

    function updateAsk(uint _idOfAsk, uint _energy, uint _price) public {
        require(_energy >= kWh, "Wrong energy input require a minimum offer of 1 kWh(in whs), for instance 5.6kwhs = 5600whs");
        require(_price >= mCent, "Price in 'cent', for example 1.5dollars/kwh = 150cents/kwh");
        for(uint i = 0; i<listOfEnergyAsks.length; i++){
            if(listOfEnergyAsks[i].idOfAsk == _idOfAsk){
                listOfEnergyAsks[i].energy = _energy;
                listOfEnergyAsks[i].price = _price;
                emit onUpdateAsk(listOfEnergyAsks[i].buyer, listOfEnergyAsks[i].idOfAsk, _price, _energy);
            }
        }
    }

    function removeBid(uint _id) public {
        for(uint i = 0; i<listOfEnergyBids.length; i++){
            if(listOfEnergyBids[i].idOfBid == _id){
                emit bidRemoved(listOfEnergyBids[i].seller, block.timestamp, listOfEnergyBids[i].idOfBid, listOfEnergyBids[i].eprice, listOfEnergyBids[i].energy);
                if (listOfEnergyBids.length > 1) {
                    listOfEnergyBids[i] = listOfEnergyBids[listOfEnergyBids.length-1];
                }
                listOfEnergyBids.length--;
            }
        }
    }

    function removeAsk(uint _id) public {
        for(uint i = 0; i<listOfEnergyAsks.length; i++){
            if(listOfEnergyAsks[i].idOfAsk == _id){
                emit askRemoved(listOfEnergyAsks[i].buyer, block.timestamp, listOfEnergyAsks[i].idOfAsk, listOfEnergyAsks[i].price, listOfEnergyAsks[i].energy);
                if (listOfEnergyAsks.length > 1) {
                    listOfEnergyAsks[i] = listOfEnergyAsks[listOfEnergyAsks.length-1];
                }
                listOfEnergyAsks.length--;
            }
        }
    }

    function buyBid(uint _id, uint amount) public{
        address currentAddr = msg.sender;
        address _seller;
        uint idx = epurchases[_id];
        bool isEnergyPurchased = false;
        uint _price = 0;
        uint energyPurchased = 0;
        for(uint i = 0; i<listOfEnergyBids.length; i++){
            if(listOfEnergyBids[i].idOfBid == _id){
                if(listOfEnergyBids[i].energy < amount){
                    _seller = listOfEnergyBids[i].seller;
                    energyPurchased = listOfEnergyBids[i].energy;
                    _price = energyPurchased*listOfEnergyBids[i].eprice;
                    amount = amount-energyPurchased;
                    listOfEnergyBids[i].energy = 0;
                    Device.updateDeviceByMarketplace(listOfEnergyBids[i].idOfDevice, energyPurchased);

                    energyAsk(amount, listOfEnergyBids[i].eprice, currentDevice);

                    isEnergyPurchased = true;

                }else if(listOfEnergyBids[i].energy == amount){
                    _seller = listOfEnergyBids[i].seller;
                    energyPurchased = amount;
                    _price = energyPurchased*listOfEnergyBids[i].eprice;
                    listOfEnergyBids[i].energy = 0;
                    Device.updateDeviceByMarketplace(listOfEnergyBids[i].idOfDevice, energyPurchased);

                    isEnergyPurchased = true;

                }else{
                    _seller = listOfEnergyBids[i].seller;
                    energyPurchased = amount;
                    _price = energyPurchased * listOfEnergyBids[i].eprice;
                    listOfEnergyBids[i].energy = listOfEnergyBids[i].energy-energyPurchased;
                    Device.updateDeviceByMarketplace(listOfEnergyBids[i].idOfDevice, energyPurchased);

                    isEnergyPurchased = true;
                }

                if(isEnergyPurchased){
                    idx = listOfPurchases.length;
                    epurchases[_id] = idx;
                    listOfPurchases.push(ePurchases({
                        buyer: currentAddr,
                        seller: _seller,
                        idOfDevice: listOfEnergyBids[i].idOfDevice,
                        energy: energyPurchased,
                        id: listOfEnergyBids[i].idOfBid,
                        price: _price,
                        timestamp: block.timestamp
                    }));
                    emit onPurchased(_seller, currentAddr, block.timestamp, energyPurchased);

                if(listOfEnergyBids[i].energy == 0) {
                    if (listOfEnergyBids.length > 1) {
                        listOfEnergyBids[i] = listOfEnergyBids[listOfEnergyBids.length-1];
                    }
                    listOfEnergyBids.length--;
                }
                }
            }
        }
    }
        
    function buyAsk(uint _id, uint amount) public {
        address currentAddr = msg.sender;
        address _buyer;
        uint idx = epurchases[_id];
        bool isEnergyPurchased = false;
        uint _price = 0;
        uint energyPurchased = 0;
        for(uint i = 0; i<listOfEnergyAsks.length; i++){
            if(listOfEnergyAsks[i].idOfAsk == _id){
                if(listOfEnergyAsks[i].energy < amount){
                    _buyer = listOfEnergyAsks[i].buyer;
                    energyPurchased = listOfEnergyAsks[i].energy;
                    _price = energyPurchased*listOfEnergyAsks[i].price;
                    amount = amount-energyPurchased;
                    listOfEnergyAsks[i].energy = 0;
                    Device.updateDeviceByMarketplace(listOfEnergyAsks[i].idOfDevice, energyPurchased);

                    ///@notice create a new bid for the leftover amount
                    energyBid(amount, listOfEnergyAsks[i].price, currentDevice);

                    isEnergyPurchased = true;

                }else if(listOfEnergyAsks[i].energy == amount){
                    _buyer = listOfEnergyAsks[i].buyer;
                    energyPurchased = amount;
                    _price = energyPurchased * listOfEnergyAsks[i].price;
                    listOfEnergyAsks[i].energy = 0;
                    Device.updateDeviceByMarketplace(listOfEnergyAsks[i].idOfDevice, energyPurchased);

                    isEnergyPurchased = true;

                }else{
                    _buyer = listOfEnergyAsks[i].buyer;
                    energyPurchased = amount;
                    _price = energyPurchased * listOfEnergyAsks[i].price;
                    listOfEnergyAsks[i].energy = listOfEnergyAsks[i].energy-energyPurchased;
                    Device.updateDeviceByMarketplace(listOfEnergyAsks[i].idOfDevice, energyPurchased);

                    isEnergyPurchased = true;
                }

                if(isEnergyPurchased){
                    idx = listOfPurchases.length;
                    epurchases[_id] = idx;
                    listOfPurchases.push(ePurchases({
                        buyer: _buyer,
                        seller: currentAddr,
                        idOfDevice: listOfEnergyAsks[i].idOfDevice,
                        energy: energyPurchased,
                        id: listOfEnergyAsks[i].idOfAsk,
                        price: _price,
                        timestamp: block.timestamp
                    }));
                    emit onPurchased(currentAddr, _buyer, block.timestamp, energyPurchased);

                    ///@notice for each puschase with listOfEnergyAsks[i].energy = 0, remove the current item and replace it
                if(listOfEnergyAsks[i].energy == 0) {
                    if (listOfEnergyAsks.length > 1) {
                        listOfEnergyAsks[i] = listOfEnergyAsks[listOfEnergyAsks.length-1];
                    }
                    listOfEnergyAsks.length--;
                }
                }
            }
        }
    }

    function getCountOfBids() public view returns(uint){
        address currentAddr = msg.sender;
        uint count = 0;
        for(uint i = 0; i<listOfEnergyBids.length; i++){
            if(listOfEnergyBids[i].seller == currentAddr){
                count++;
            }
        }
        return count;
    }

    function getMyBids() public view returns(address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        uint k = 0;
        uint cnt = getCountOfBids();
        address[] memory sellersList = new address[](cnt);
        uint[] memory energiesList = new uint[](cnt);
        uint[] memory idsList = new uint[](cnt);
        uint[] memory pricesList = new uint[](cnt);
        uint[] memory datesList = new uint[](cnt);

        for(uint i = 0; i < listOfEnergyBids.length; i++){
            if(listOfEnergyBids[i].seller == msg.sender){
                sellersList[k] = listOfEnergyBids[i].seller;
                energiesList[k] = listOfEnergyBids[i].energy;
                idsList[k] = listOfEnergyBids[i].idOfBid;
                pricesList[k] = listOfEnergyBids[i].eprice;
                datesList[k] = listOfEnergyBids[i].timestamp;
                k++;
            }
        }
        return(sellersList, energiesList, idsList, pricesList, datesList);
    }

    function getCountOfAsks() public view returns(uint){
        address currentAddr = msg.sender;
        uint count = 0;
        for(uint i = 0; i<listOfEnergyAsks.length; i++){
            if(listOfEnergyAsks[i].buyer == currentAddr){
                count++;
            }
        }
        return count;
    }

    function getMyAsks() public view returns(address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        uint k = 0;
        uint cnt = getCountOfAsks();
        address[] memory buyersList = new address[](cnt);
        uint[] memory energiesList = new uint[](cnt);
        uint[] memory idsList = new uint[](cnt);
        uint[] memory pricesList = new uint[](cnt);
        uint[] memory datesList = new uint[](cnt);

        for(uint i = 0; i < listOfEnergyAsks.length; i++){
            if(listOfEnergyAsks[i].buyer == msg.sender){
                buyersList[k] = listOfEnergyAsks[i].buyer;
                energiesList[k] = listOfEnergyAsks[i].energy;
                idsList[k] = listOfEnergyAsks[i].idOfAsk;
                pricesList[k] = listOfEnergyAsks[i].price;
                datesList[k] = listOfEnergyAsks[i].timestamp;
                k++;
            }
        }
        return(buyersList, energiesList, idsList, pricesList, datesList);
    }

    function getBidByID(uint _id) public view returns(uint, address, uint, uint, uint, uint){
        uint index = ebids[_id];
        require(listOfEnergyBids.length > index, "Wrong index");
        require(listOfEnergyBids[index].idOfBid == _id, "Wrong ID");
        return(listOfEnergyBids[index].idOfDevice, listOfEnergyBids[index].seller, listOfEnergyBids[index].idOfBid, listOfEnergyBids[index].energy, listOfEnergyBids[index].eprice, listOfEnergyBids[index].timestamp);
    }

    function getAskByID(uint _id) public view returns(uint, address, uint, uint, uint, uint){
        uint index = ebids[_id];
        require(listOfEnergyAsks.length > index, "Wrong index");
        require(listOfEnergyAsks[index].idOfAsk == _id, "Wrong ID");
        return(listOfEnergyAsks[index].idOfDevice, listOfEnergyAsks[index].buyer, listOfEnergyAsks[index].idOfAsk, listOfEnergyAsks[index].energy, listOfEnergyAsks[index].price, listOfEnergyAsks[index].timestamp);
    }

    function getAllBids() public view returns(uint[] memory, address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        address[] memory seller = new address[](listOfEnergyBids.length);
        uint[] memory ids = new uint[](listOfEnergyBids.length);
        uint[] memory idDevice = new uint[](listOfEnergyBids.length);
        uint[] memory energies = new uint[](listOfEnergyBids.length);
        uint[] memory prices = new uint[](listOfEnergyBids.length);
        uint[] memory dates = new uint[](listOfEnergyBids.length);
        for(uint i = 0; i < listOfEnergyBids.length; i++){
            seller[i] = listOfEnergyBids[i].seller;
            ids[i] = listOfEnergyBids[i].idOfBid;
            idDevice[i] = listOfEnergyBids[i].idOfDevice;
            energies[i] = listOfEnergyBids[i].energy;
            prices[i] = listOfEnergyBids[i].eprice;
            dates[i] = listOfEnergyBids[i].timestamp;
        }
        return(idDevice, seller, ids, energies, prices, dates);
    }

    function getAllAsks() public view returns(uint[] memory, address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        address[] memory buyers = new address[](listOfEnergyAsks.length);
        uint[] memory _ids = new uint[](listOfEnergyAsks.length);
        uint[] memory _idDevice = new uint[](listOfEnergyAsks.length);
        uint[] memory _energies = new uint[](listOfEnergyAsks.length);
        uint[] memory _prices = new uint[](listOfEnergyAsks.length);
        uint[] memory _dates = new uint[](listOfEnergyAsks.length);
        for(uint i = 0; i < listOfEnergyAsks.length; i++){
            buyers[i] = listOfEnergyAsks[i].buyer;
            _ids[i] = listOfEnergyAsks[i].idOfAsk;
            _idDevice[i] = listOfEnergyBids[i].idOfDevice;
            _energies[i] = listOfEnergyAsks[i].energy;
            _prices[i] = listOfEnergyAsks[i].price;
            _dates[i] = listOfEnergyAsks[i].timestamp;
        }
        return(_idDevice, buyers, _ids, _energies, _prices, _dates);
    }

    function getAllPurchases() public view returns(address[] memory, address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        address[] memory _seller = new address[](listOfPurchases.length);
        address[] memory _buyers = new address[](listOfPurchases.length);
        uint[] memory _ids = new uint[](listOfPurchases.length);
        uint[] memory _energies = new uint[](listOfPurchases.length);
        uint[] memory _prices = new uint[](listOfPurchases.length);
        uint[] memory _dates = new uint[](listOfPurchases.length);
        for(uint i = 0; i < listOfPurchases.length; i++){
            _seller[i] = listOfPurchases[i].seller;
            _buyers[i] = listOfPurchases[i].buyer;
            _ids[i] = listOfPurchases[i].id;
            _energies[i] = listOfPurchases[i].energy;
            _prices[i] = listOfPurchases[i].price;
            _dates[i] = listOfPurchases[i].timestamp;
        }
        return(_seller, _buyers, _ids, _energies, _prices, _dates);
    }

    function getCountOfPurchases() private view returns(uint){
        address currentAddr = msg.sender;
        uint count = 0;
        for(uint i = 0; i<listOfPurchases.length; i++){
            if((listOfPurchases[i].buyer == currentAddr) || (listOfPurchases[i].seller == currentAddr)){
                count++;
            }
        }
        return count;
    }

    function getPurchases() public view returns(address[] memory, address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        uint k = 0;
        uint cnt = getCountOfPurchases();
        address[] memory buyerList = new address[](cnt);
        address[] memory sellerList = new address[](cnt);
        uint[] memory energyList = new uint[](cnt);
        uint[] memory idList = new uint[](cnt);
        uint[] memory priceList = new uint[](cnt);
        uint[] memory dateList = new uint[](cnt);

        for(uint i = 0; i < listOfPurchases.length; i++){
            if((listOfPurchases[i].buyer == msg.sender) || (listOfPurchases[i].seller == msg.sender)){
                buyerList[k] = listOfPurchases[i].buyer;
                sellerList[k] = listOfPurchases[i].seller;
                energyList[k] = listOfPurchases[i].energy;
                idList[k] = listOfPurchases[i].id;
                priceList[k] = listOfPurchases[i].price;
                dateList[k] = listOfPurchases[i].timestamp;
                k++;
            }
        }
        return(buyerList, sellerList, energyList, idList, priceList, dateList);
    }

    function getTotalBids() public view returns(uint count){
        return listOfEnergyBids.length;
    }

    function getTotalAsks() public view returns(uint count){
        return listOfEnergyAsks.length;
    }

    function getTotalPurchases() public view returns(uint count){
        return listOfPurchases.length;
    }
}