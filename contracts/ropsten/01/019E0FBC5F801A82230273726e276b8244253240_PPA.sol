/**
 *Submitted for verification at Etherscan.io on 2021-08-12
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

contract producerRegistry {
    event producerRegistered(address indexed producer);
    event producerDeregistered(address indexed producer);
    
    // map address to bool "is a registered producer"
    mapping(address => bool) producers;
    
    modifier onlyRegisteredProducers {
        require(producers[msg.sender], "You must be a current Producer");
        _;
    }
    
    function registerProducer() public {
        address aproducer = msg.sender;
        emit producerRegistered(aproducer);
        producers[aproducer] = true;
    }

    function deregisterProducer() public {
        address aproducer = msg.sender;
        emit producerDeregistered(aproducer);
        producers[aproducer] = false;
    }
}

contract ppaBuyerRegistry {
    event buyerRegistered(address indexed ppaBuyer);
    event buyerDeregistered(address indexed ppaBuyer);

    mapping(address => uint32) ppaBuyers;
    address[] listOfPPABuyers;

    modifier onlyPPABuyers {
      require(ppaBuyers[msg.sender] > 0, "Only PPA owners");
      _;
    }
    
    function deregisterPPABuyer(address abuyer) public {
        uint32 abuyerID = 0;
        if(abuyerID != 0) {
            emit buyerDeregistered(abuyer);
        }
        ppaBuyers[abuyer] = abuyerID;
    }

    function registerPPABuyer(address abuyer) public {
        uint32 abuyerID = 0;
        abuyerID++;
        if(abuyerID != 0) {
            emit buyerRegistered(abuyer);
        }
        ppaBuyers[abuyer] = abuyerID;
    }
}

//Corporate PPAs
contract PPA is producerRegistry, ppaBuyerRegistry {

    //using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private contractID;

    uint constant cent = 1;
    uint constant dollar = 100 * cent;

    uint constant mWh = 1;
    uint constant  Wh = 1000 * mWh;
    uint constant kWh = 1000 * Wh;
    uint constant MWh = 1000 * kWh;
    uint constant GWh = 1000 * MWh;
    uint constant TWh = 1000 * GWh;

    mapping (uint => uint) price;

    enum Status {Pending, Approved, Rejected, Expired}
    event createdPPA(address indexed producer, uint price);
    event createdCorpPPA(address indexed producer, address indexed buyer, uint price);
    event acceptedCorpPPA(address indexed producer, address indexed buyer, uint id, uint agreedPrice);
    event purchasedPPA(uint id, address indexed buyer, address indexed producer);
    event expiredPPA(address indexed producer, address indexed buyer, uint startDay, uint endDay, Status status);

    struct ppa {               //Struct with all PPA contracts
        address buyer;
        address producer;
        uint kwhPrice;         //price per energy(kwh)
        uint startDay;
        uint endDay;           //It must be timestamp (ex. uint endDay = 1833746400; // 2028-02-10 00:00:00)
        uint id;               //id number of each ppa contract
        Status status;
    }

    mapping(address => ppa) ppas;
    ppa[] listOfPPAs;
    ppa[] corporatePPAList;
    //uint contractID = 0;

    struct approvedPPA{       //Struct only for approved PPAs
        address buyer;
        address producer;
        uint kwhPrice;        //price per energy(kwh)
        uint startDay;
        uint endDay;          //It must be timestamp (ex. uint endDay = 1833746400; // 2028-02-10 00:00:00)
        uint id;              //id number of each ppa contract
        uint totalKwh;        //total amount of purchased kwh
        Status status;
    }

    mapping(address => mapping(uint => approvedPPA)) approvedPPAs;
    approvedPPA[] Appas;

    struct producerEnergy{      //Trial struct for available producer' s energy in order to sale 
        address producer;
        address buyer;          //Address of owner of each PPA conract
        uint timestamp;
        uint energy;
        uint idOfmatchContract; //id of ppa contract that refers to
    }

    mapping(address => mapping(uint => uint)) pEnergy;
    producerEnergy[] listOfkwhs;

    struct purchasesPPA{
        address buyer;
        address producer;
        uint timestamp;
        uint idOfPPA;
        uint purchasedEnergy;
    }

    purchasesPPA[] listOfprchs;

    function corporatePPA(address _buyer, uint _agreedKwhPrice,uint _startDay, uint _endDay, uint _id) public onlyRegisteredProducers {
        address _producer = msg.sender;
        require(_endDay > _startDay, "It's impossible endDay < startDay");
        require(_agreedKwhPrice >= dollar, "Price in Cent, for example 1.5dollar -> 150cents");
        corporatePPAList.push(ppa({
            buyer: _buyer,
            producer: _producer,
            kwhPrice: _agreedKwhPrice,
            startDay: _startDay,
            endDay: _endDay,
            id: _id,
            status: Status.Pending
        }));
        emit createdCorpPPA(_producer, _buyer, _agreedKwhPrice);
    }

    //Corporate PPAs are based on an agreed price
    //Both parties benefit from long-term price guarantees that protect them from market price volatility
    function acceptCorporatePPA() public {
        address _buyer = msg.sender;
        uint _totalKwh = 0;
        for(uint i = 0; i < corporatePPAList.length; i++){
            if((corporatePPAList[i].buyer == _buyer) && (corporatePPAList[i].status == Status.Pending)){
                Appas.push(approvedPPA({
                    buyer: _buyer,
                    producer: corporatePPAList[i].producer,
                    kwhPrice: corporatePPAList[i].kwhPrice,
                    startDay: corporatePPAList[i].startDay,
                    endDay: corporatePPAList[i].endDay,
                    id: corporatePPAList[i].id,
                    totalKwh: _totalKwh,
                    status: Status.Approved
                }));
                ppaBuyerRegistry.registerPPABuyer(_buyer);
                emit acceptedCorpPPA(corporatePPAList[i].producer, _buyer, corporatePPAList[i].id, corporatePPAList[i].kwhPrice);
                if(corporatePPAList.length > 1){
                    corporatePPAList[i] = corporatePPAList[corporatePPAList.length-1];
                }
                corporatePPAList.length--;
                break;
            }
        }
    }

    function createPPA(uint _kwhPrice,uint _startDay, uint _endDay) public onlyRegisteredProducers { //onlyRegisteredProducers
        address _producer = msg.sender;
        contractID.increment();
        uint currentID = contractID.current();
        require(_endDay > _startDay, "It's impossible endDay < startDay");
        require(_kwhPrice >= dollar, "Price in Cent, for example 1.5dollar -> 150cents");
        listOfPPAs.push(ppa({
            buyer: address(0x0),
            producer: _producer,
            kwhPrice: _kwhPrice,
            startDay: _startDay,
            endDay: _endDay,
            id: currentID,
            status: Status.Pending
        }));
        //nextID++;
        emit createdPPA(_producer, _kwhPrice);
    }

    function claimPPA() public {
        uint _totalKwh = 0;
        address buyer = msg.sender;
        for(uint i = 0; i<listOfPPAs.length; i++){
            require(listOfPPAs[i].producer != buyer, "Wrong address buyer");
            require(listOfPPAs[i].status != Status.Rejected, "error");
            require(listOfPPAs[i].endDay > block.timestamp, "PPA has expired");
            if(listOfPPAs[i].status == Status.Pending){
                Appas.push(approvedPPA({
                    buyer: buyer,
                    producer: listOfPPAs[i].producer,
                    kwhPrice: listOfPPAs[i].kwhPrice,
                    startDay: listOfPPAs[i].startDay,
                    endDay: listOfPPAs[i].endDay,
                    id: listOfPPAs[i].id,
                    totalKwh: _totalKwh,
                    status: Status.Approved
                }));
                ppaBuyerRegistry.registerPPABuyer(buyer);
                emit purchasedPPA(listOfPPAs[i].id, listOfPPAs[i].buyer, listOfPPAs[i].producer);
                if(listOfPPAs.length > 1){
                    listOfPPAs[i] = listOfPPAs[listOfPPAs.length-1];
                }
                listOfPPAs.length--;
                break;
            }
        }
    }

    //Claim an Auction type PPA with the lowest price
    function claimAuctionPPA() public {
        uint _totalkwh = 0;
        bool isClaimed = false;
        address buyerAddr = msg.sender;
        //Check for the best price per kwh based on PPA terms
        //Claim the PPA with lowest price and record this purchase
        for(uint i = 0; i < listOfPPAs.length; i++){
            for(uint j = 0; j < listOfPPAs.length; j++){
                if(listOfPPAs[j].kwhPrice < listOfPPAs[i].kwhPrice){
                    require(listOfPPAs[j].status == Status.Pending, "PPA does not exists");
                    require(listOfPPAs[j].producer != buyerAddr, "Wrong address buyer");
                    require(listOfPPAs[j].endDay > block.timestamp, "PPA has expire, you can not buy it");
                    Appas.push(approvedPPA({
                        buyer: buyerAddr,
                        producer: listOfPPAs[j].producer,
                        kwhPrice: listOfPPAs[j].kwhPrice,
                        startDay: listOfPPAs[j].startDay,
                        endDay: listOfPPAs[j].endDay,
                        id: listOfPPAs[j].id,
                        totalKwh: _totalkwh,
                        status: Status.Approved
                        }));
                    ppaBuyerRegistry.registerPPABuyer(buyerAddr);
                    isClaimed = true;
                    emit purchasedPPA(listOfPPAs[j].id, listOfPPAs[j].buyer, listOfPPAs[j].producer);
                }
                if(isClaimed){
                    if(listOfPPAs.length > 1){
                        listOfPPAs[j] = listOfPPAs[listOfPPAs.length-1];
                    }
                    listOfPPAs.length--;
                    break;
                }
            }
            if(isClaimed){
                break;
            }else{
                require(listOfPPAs[i].status == Status.Pending, "PPA does not exists");
                require(listOfPPAs[i].producer != buyerAddr, "Wrong address buyer");
                Appas.push(approvedPPA({
                    buyer: buyerAddr,
                    producer: listOfPPAs[i].producer,
                    kwhPrice: listOfPPAs[i].kwhPrice,
                    startDay: listOfPPAs[i].startDay,
                    endDay: listOfPPAs[i].endDay,
                    id: listOfPPAs[i].id,
                    totalKwh: _totalkwh,
                    status: Status.Approved
                }));
                ppaBuyerRegistry.registerPPABuyer(buyerAddr);
                isClaimed = true;
                emit purchasedPPA(listOfPPAs[i].id, listOfPPAs[i].buyer, listOfPPAs[i].producer);
                if(isClaimed){
                    if(listOfPPAs.length > 1){
                        listOfPPAs[i] = listOfPPAs[listOfPPAs.length-1];
                    }
                    listOfPPAs.length--;
                    break;
                }
            }
        }
    }

    //this is a trial function just for PPA_energy_trading part
    function availableKwhs(address _buyer, uint _energy, uint _idOfMatchPPA) public onlyRegisteredProducers{
        require(_energy >= kWh, "You have to put at least 1Kwh (in whs for example 1.5kwhs -> 1500 (wh))");
        address _producer = msg.sender;
        listOfkwhs.push(producerEnergy({
            producer: _producer,
            buyer: _buyer,
            timestamp: block.timestamp,
            energy: _energy,
            idOfmatchContract: _idOfMatchPPA
        }));
    }

    function buyPPAKwhs(uint _idOfPPA) public onlyPPABuyers{
        uint currentTime = block.timestamp;
        address aBuyer = msg.sender; 
        for(uint j = 0; j<Appas.length; j++){ //uint j = 0; j<Appas.length; j++
            //search on Approved PPAs to match the id - producer with kwhs
            for(uint i = 0; i<listOfkwhs.length; i++){ //uint i = 0; i<listOfkwhs.length; i++
                uint totalEnergyPurchased = 0;
                //find the correct available kwhs based on id of ppa
                if((Appas[j].producer == listOfkwhs[i].producer) && (Appas[j].id == _idOfPPA) && (Appas[j].id == listOfkwhs[i].idOfmatchContract)){
                    require(Appas[j].startDay <= currentTime, "PPA is not active yet");
                    //if endDay < now then PPA has expired 
                    if(Appas[j].endDay < currentTime){
                        revert("PPA has expired");
                    }
                    totalEnergyPurchased = listOfkwhs[i].energy;
                    Appas[j].totalKwh = Appas[j].totalKwh + totalEnergyPurchased;
                    listOfkwhs[i].energy = 0;
                    listOfprchs.push(purchasesPPA({
                        buyer: aBuyer,
                        producer: listOfkwhs[i].producer,
                        timestamp: currentTime,
                        idOfPPA: _idOfPPA,
                        purchasedEnergy: totalEnergyPurchased
                    }));
                }
                if(listOfkwhs[i].energy == 0){
                    if(listOfkwhs.length > 1){
                        listOfkwhs[i] = listOfkwhs[listOfkwhs.length-1];
                    }
                    listOfkwhs.length--;
                    break;
                }
            }
        }
    }

    function energyTradingPPA(uint _idOfContract, uint _buyEnergy) public onlyPPABuyers{
        uint currentTime = block.timestamp;
        uint buyEnergy = _buyEnergy;
        address aBuyer = msg.sender; 
        address _producer;
        bool isEnergyPurchased = false;
        for(uint j = 0; j < Appas.length; j++){
            if((Appas[j].id == _idOfContract) && (Appas[j].buyer == aBuyer)){
                require(Appas[j].startDay <= currentTime, "PPA is not active yet");
                require(Appas[j].endDay > currentTime, "PPA has expired");
                for(uint i = 0; i < listOfkwhs.length; i++){
                    uint totalEnergyPurchased = 0;
                    if((Appas[j].producer == listOfkwhs[i].producer) && (listOfkwhs[i].buyer == aBuyer) && (Appas[j].id == listOfkwhs[i].idOfmatchContract)){
                        if(listOfkwhs[i].energy < buyEnergy){//(listOfkwhs[i].idOfmatchContract == Appas[j].id) && (
                            _producer = listOfkwhs[i].producer;
                            totalEnergyPurchased = listOfkwhs[i].energy;
                            buyEnergy = buyEnergy-totalEnergyPurchased;
                            Appas[j].totalKwh = Appas[j].totalKwh+totalEnergyPurchased;
                            listOfkwhs[i].energy = 0;

                            isEnergyPurchased = true;

                            if(listOfkwhs.length > 1){
                                listOfkwhs[i] = listOfkwhs[listOfkwhs.length-1];
                            }
                            listOfkwhs.length--;

                        }else if(listOfkwhs[i].energy == buyEnergy){//(Appas[j].producer == listOfkwhs[i].producer) && (Appas[j].id == listOfkwhs[i].idOfmatchContract) && 
                            _producer = listOfkwhs[i].producer;
                            totalEnergyPurchased = buyEnergy;
                            Appas[j].totalKwh = Appas[j].totalKwh+totalEnergyPurchased;
                            buyEnergy = 0;
                            listOfkwhs[i].energy = 0;

                            isEnergyPurchased = true;

                            if(listOfkwhs.length > 1){
                                listOfkwhs[i] = listOfkwhs[listOfkwhs.length-1];
                            }
                            listOfkwhs.length--;

                        }else{
                            _producer = listOfkwhs[i].producer;
                            totalEnergyPurchased = buyEnergy;
                            Appas[j].totalKwh = Appas[j].totalKwh+totalEnergyPurchased;
                            listOfkwhs[i].energy = listOfkwhs[i].energy-totalEnergyPurchased;
                            buyEnergy = 0;

                            isEnergyPurchased = true;
                        }

                        if(isEnergyPurchased){
                            listOfprchs.push(purchasesPPA({
                                buyer: aBuyer,
                                producer: _producer,
                                timestamp: currentTime,
                                idOfPPA: _idOfContract,
                                purchasedEnergy: totalEnergyPurchased
                            }));
                        }
                        
                        if(buyEnergy == 0){
                            break;
                        }else{
                            i--;
                        }
                    }
                }
            }
        }
    }

    function killPPA(uint _id) public {
        uint currentTime = block.timestamp;
        for(uint i = 0; i<Appas.length; i++){
            if((Appas[i].id == _id) && (Appas[i].endDay < currentTime)){
                Appas[i].status = Status.Expired;
                listOfPPAs.push(ppa({
                    buyer: Appas[i].buyer,
                    producer: Appas[i].producer,
                    kwhPrice: Appas[i].kwhPrice,
                    startDay: Appas[i].startDay,
                    endDay: Appas[i].endDay,
                    id: Appas[i].id,
                    status: Status.Expired
                }));
                ppaBuyerRegistry.deregisterPPABuyer(Appas[i].buyer);
                emit expiredPPA(Appas[i].producer, Appas[i].buyer, Appas[i].startDay, Appas[i].endDay, Appas[i].status);
                if(Appas.length > 1){
                    Appas[i] = Appas[Appas.length-1];
                }
                Appas.length--;
                break;
            }
        }
    }

    function viewAllpurchases(uint n) public view returns (address[] memory, address[] memory, uint[] memory, uint[] memory){
        address[] memory _producerList1 = new address[](listOfprchs.length);
        address[] memory _buyerList1 = new address[](listOfprchs.length);
        uint[] memory _priceList1 = new uint[](listOfprchs.length);
        uint[] memory _idPPAlist1 = new uint[](listOfprchs.length);
        for(uint i = 0; i < n; i++){
            _producerList1[i] = listOfprchs[i].producer;
            _buyerList1[i] = listOfprchs[i].buyer;
            _priceList1[i] = listOfprchs[i].purchasedEnergy;
            _idPPAlist1[i] = listOfprchs[i].idOfPPA;
        }
        return(_producerList1, _buyerList1, _priceList1, _idPPAlist1);
    }

    function viewCorporatePPAlist(uint n) public view returns(address[] memory, address[] memory, uint[] memory, uint[] memory, uint[] memory){
        address[] memory _producerList = new address[](corporatePPAList.length);
        address[] memory _buyerList = new address[](corporatePPAList.length);
        uint[] memory _priceList = new uint[](corporatePPAList.length);
        uint[] memory _idPPAlist = new uint[](corporatePPAList.length);
        uint[] memory _statusList = new uint[](corporatePPAList.length);
        for(uint i = 0; i < n; i++){
            _producerList[i] = corporatePPAList[i].producer;
            _buyerList[i] = corporatePPAList[i].buyer;
            _priceList[i] = corporatePPAList[i].kwhPrice;
            _idPPAlist[i] = corporatePPAList[i].id;
            _statusList[i] = uint(corporatePPAList[i].status);
        }
        return(_producerList, _buyerList, _priceList, _idPPAlist, _statusList);
    }

    function getApprovedPPAByID(uint _id) public view returns (address, address, uint, uint, uint){
        approvedPPA storage _Appa = Appas[_id];
        return(_Appa.producer, _Appa.buyer, _Appa.kwhPrice, _Appa.startDay, _Appa.endDay);
    }

    function viewAllPPAs (uint n) public view returns (address[] memory, address[] memory, uint[] memory, uint[] memory, uint[] memory){
        address[] memory producerList = new address[](listOfPPAs.length);
        address[] memory buyerList = new address[](listOfPPAs.length);
        uint[] memory priceList = new uint[](listOfPPAs.length);
        uint[] memory idPPAlist = new uint[](listOfPPAs.length);
        uint[] memory statusList = new uint[](listOfPPAs.length);
        for(uint i = 0; i < n; i++){
            producerList[i] = listOfPPAs[i].producer;
            buyerList[i] = listOfPPAs[i].buyer;
            priceList[i] = listOfPPAs[i].kwhPrice;
            idPPAlist[i] = listOfPPAs[i].id;
            statusList[i] = uint(listOfPPAs[i].status);
        }
        return(producerList, buyerList, priceList, idPPAlist, statusList);
     }

    function viewAvailableKwhs(uint n) public view returns(address[] memory, address[] memory, uint[] memory, uint[] memory){
        address[] memory producerList_ = new address[](listOfkwhs.length);
        address[] memory buyerList_ = new address[](listOfkwhs.length);
        uint[] memory energyList_ = new uint[](listOfkwhs.length);
        uint[] memory idOfPPAlist_ = new uint[](listOfkwhs.length);
        for(uint i = 0; i < n; i++){
            producerList_[i] = listOfPPAs[i].producer;
            buyerList_[i] = listOfPPAs[i].buyer;
            energyList_[i] = listOfPPAs[i].kwhPrice;
            idOfPPAlist_[i] = listOfPPAs[i].id;
        }
        return(producerList_, buyerList_, energyList_, idOfPPAlist_);
    }
    
    function getAvKwhs() public view returns(uint count){
        return listOfkwhs.length;
    }

    function getPPAs() public view returns(uint count){
        return listOfPPAs.length;
    }
}