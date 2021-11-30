/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity >=0.4.21 <0.9.0;

// SPDX-License-Identifier: MIT

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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

contract Marketplace {

    using Counters for Counters.Counter;
    Counters.Counter private ID;

    event onNewBid(address indexed seller, uint indexed day, uint indexed price, uint energy);
    event onNewAsk(address indexed buyer, uint indexed day, uint indexed price, uint energy);
    event bidRemoved(address indexed seller, uint indexed day, uint id, uint indexed price, uint energy);
    event askRemoved(address indexed buyer, uint indexed day, uint id, uint indexed price, uint energy);
    event onUpdateBid(address indexed seller, uint indexed id, uint indexed price, uint energy);
    event onUpdateAsk(address indexed buyer, uint indexed id, uint indexed price, uint energy);
    event onPurchased(address indexed seller, address indexed buyer, uint indexed day, uint energy);

    uint constant mCent = 1;
    uint constant cent = 100 * mCent;
    uint constant dollar = 100 * cent;

    uint constant mWh = 1;
    uint constant  Wh = 1000 * mWh;
    uint constant kWh = 1000 * Wh;
    uint constant MWh = 1000 * kWh;
    uint constant GWh = 1000 * MWh;
    uint constant TWh = 1000 * GWh;

    struct eBid {
        address seller;
        uint idOfBid;
        uint energy;
        uint eprice;
        uint timestamp;
    }

    mapping(uint => uint) ebids;
    eBid[] listOfEnergyBids;
    
    struct eAsk {
        address buyer;
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
        uint energy;
        uint id;
        uint price;
        uint timestamp;
    }

    mapping(uint => uint) epurchases;
    ePurchases[] listOfPurchases;

    function energyBid(uint _energy, uint _eprice) public {
        require(_energy >= kWh, "Wrong energy input require a minimum offer of 1 kWh(in whs), for instance 5.6kwhs = 5600whs");
        require(_eprice >= dollar, "Price in 'cent', for example 1.5dollars/kwh = 150cents/kwh");
        ID.increment();
        uint currentID = ID.current();
        address currentAddr = msg.sender;
        uint idx = ebids[currentID];
        idx = listOfEnergyBids.length;
        ebids[currentID] = idx;
        listOfEnergyBids.push(eBid({
            seller: currentAddr,
            idOfBid: currentID,
            energy: _energy,
            eprice: _eprice,
            timestamp: block.timestamp
        }));
        emit onNewBid(currentAddr, block.timestamp, _eprice, _energy);
    }

    function energyAsk(uint _energy, uint _price) public {
        require(_energy >= kWh, "Wrong energy input require a minimum offer of 1 kWh(in whs), for instance 5.6kwhs = 5600whs");
        require(_price >= dollar, "Price in 'cent', for example 1.5dollars/kwh = 150cents/kwh");
        ID.increment();
        uint currentID = ID.current();
        address currentAddr = msg.sender;
        uint idx = easks[currentID];
        idx = listOfEnergyAsks.length;
        easks[currentID] = idx;
        listOfEnergyAsks.push(eAsk({
            buyer: currentAddr,
            idOfAsk: currentID,
            energy: _energy,
            price: _price,
            timestamp: block.timestamp
        }));
        emit onNewAsk(currentAddr, block.timestamp, _price, _energy);
    }

    function updateBid(uint _idOfBid, uint _energy, uint _price) public {
        require(_energy >= kWh, "Wrong energy input require a minimum offer of 1 kWh(in whs), for instance 5.6kwhs = 5600whs");
        require(_price >= dollar, "Price in 'cent', for example 1.5dollars/kwh = 150cents/kwh");
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
        require(_price >= dollar, "Price in 'cent', for example 1.5dollars/kwh = 150cents/kwh");
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
        uint index = 0;
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

                    ID.increment();
                    uint currentID = ID.current();
                    index = easks[currentID];
                    index = listOfEnergyAsks.length;
                    easks[currentID] = idx;
                    listOfEnergyAsks.push(eAsk({
                        buyer: currentAddr,
                        idOfAsk: currentID,
                        energy: amount,
                        price: listOfEnergyBids[i].eprice,
                        timestamp: block.timestamp
                    }));
                    emit onNewAsk(currentAddr, block.timestamp, listOfEnergyBids[i].eprice, amount);

                    isEnergyPurchased = true;

                    if (listOfEnergyBids.length > 1) {
                        listOfEnergyBids[i] = listOfEnergyBids[listOfEnergyBids.length-1];
                    }
                    listOfEnergyBids.length--;
                    //i--;

                }else if(listOfEnergyBids[i].energy == amount){
                    _seller = listOfEnergyBids[i].seller;
                    energyPurchased = amount;
                    _price = energyPurchased*listOfEnergyBids[i].eprice;

                    isEnergyPurchased = true;

                    if (listOfEnergyBids.length > 1) {
                        listOfEnergyBids[i] = listOfEnergyBids[listOfEnergyBids.length-1];
                    }
                    listOfEnergyBids.length--;

                }else{
                    _seller = listOfEnergyBids[i].seller;
                    energyPurchased = amount;
                    _price = energyPurchased * listOfEnergyBids[i].eprice;
                    listOfEnergyBids[i].energy = listOfEnergyBids[i].energy-energyPurchased;

                    isEnergyPurchased = true;
                }

                if(isEnergyPurchased){
                    idx = listOfPurchases.length;
                    epurchases[_id] = idx;
                    listOfPurchases.push(ePurchases({
                        buyer: currentAddr,
                        seller: _seller,
                        energy: energyPurchased,
                        id: listOfEnergyBids[i].idOfBid,
                        price: _price,
                        timestamp: block.timestamp
                    }));
                    emit onPurchased(_seller, currentAddr, block.timestamp, energyPurchased);
                }
            }
        }
    }
        
    function buyAsk(uint _id, uint amount) public {
        address currentAddr = msg.sender;
        address _buyer;
        uint index = 0;
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

                    ID.increment();
                    uint currentID = ID.current();
                    index = ebids[currentID];
                    index = listOfEnergyBids.length;
                    ebids[currentID] = idx;
                    listOfEnergyBids.push(eBid({
                        seller: currentAddr,
                        idOfBid: currentID,
                        energy: amount,
                        eprice: listOfEnergyAsks[i].price,
                        timestamp: block.timestamp
                    }));
                    emit onNewBid(currentAddr, block.timestamp, listOfEnergyAsks[i].price, amount);

                    isEnergyPurchased = true;

                    if (listOfEnergyAsks.length > 1) {
                        listOfEnergyAsks[i] = listOfEnergyAsks[listOfEnergyAsks.length-1];
                    }
                    listOfEnergyAsks.length--;
                    //i--;

                }else if(listOfEnergyAsks[i].energy == amount){
                    _buyer = listOfEnergyAsks[i].buyer;
                    energyPurchased = amount;
                    _price = energyPurchased * listOfEnergyAsks[i].price;

                    isEnergyPurchased = true;

                    if (listOfEnergyAsks.length > 1) {
                        listOfEnergyAsks[i] = listOfEnergyAsks[listOfEnergyAsks.length-1];
                    }
                    listOfEnergyAsks.length--;

                }else{
                    _buyer = listOfEnergyAsks[i].buyer;
                    energyPurchased = amount;
                    _price = energyPurchased * listOfEnergyAsks[i].price;
                    listOfEnergyAsks[i].energy = listOfEnergyAsks[i].energy-energyPurchased;

                    isEnergyPurchased = true;
                }

                if(isEnergyPurchased){
                    idx = listOfPurchases.length;
                    epurchases[_id] = idx;
                    listOfPurchases.push(ePurchases({
                        buyer: _buyer,
                        seller: currentAddr,
                        energy: energyPurchased,
                        id: listOfEnergyAsks[i].idOfAsk,
                        price: _price,
                        timestamp: block.timestamp
                    }));
                    emit onPurchased(currentAddr, _buyer, block.timestamp, energyPurchased);
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

    function getBidByID(uint _id) public view returns(address, uint, uint, uint, uint){
        uint index = ebids[_id];
        require(listOfEnergyBids.length > index, "Wrong index");
        require(listOfEnergyBids[index].idOfBid == _id, "Wrong ID");
        return(listOfEnergyBids[index].seller, listOfEnergyBids[index].idOfBid, listOfEnergyBids[index].energy, listOfEnergyBids[index].eprice, listOfEnergyBids[index].timestamp);
    }

    function getAskByID(uint _id) public view returns(address, uint, uint, uint, uint){
        uint index = ebids[_id];
        require(listOfEnergyAsks.length > index, "Wrong index");
        require(listOfEnergyAsks[index].idOfAsk == _id, "Wrong ID");
        return(listOfEnergyAsks[index].buyer, listOfEnergyAsks[index].idOfAsk, listOfEnergyAsks[index].energy, listOfEnergyAsks[index].price, listOfEnergyAsks[index].timestamp);
    }

    function getAllBids() public view returns(address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        address[] memory seller = new address[](listOfEnergyBids.length);
        uint[] memory ids = new uint[](listOfEnergyBids.length);
        uint[] memory energies = new uint[](listOfEnergyBids.length);
        uint[] memory prices = new uint[](listOfEnergyBids.length);
        uint[] memory dates = new uint[](listOfEnergyBids.length);
        for(uint i = 0; i < listOfEnergyBids.length; i++){
            seller[i] = listOfEnergyBids[i].seller;
            ids[i] = listOfEnergyBids[i].idOfBid;
            energies[i] = listOfEnergyBids[i].energy;
            prices[i] = listOfEnergyBids[i].eprice;
            dates[i] = listOfEnergyBids[i].timestamp;
        }
        return(seller, ids, energies, prices, dates);
    }

    function getAllAsks() public view returns(address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        address[] memory buyers = new address[](listOfEnergyAsks.length);
        uint[] memory _ids = new uint[](listOfEnergyAsks.length);
        uint[] memory _energies = new uint[](listOfEnergyAsks.length);
        uint[] memory _prices = new uint[](listOfEnergyAsks.length);
        uint[] memory _dates = new uint[](listOfEnergyAsks.length);
        for(uint i = 0; i < listOfEnergyAsks.length; i++){
            buyers[i] = listOfEnergyAsks[i].buyer;
            _ids[i] = listOfEnergyAsks[i].idOfAsk;
            _energies[i] = listOfEnergyAsks[i].energy;
            _prices[i] = listOfEnergyAsks[i].price;
            _dates[i] = listOfEnergyAsks[i].timestamp;
        }
        return(buyers, _ids, _energies, _prices, _dates);
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

    function getCountOfPurchases() public view returns(uint){
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