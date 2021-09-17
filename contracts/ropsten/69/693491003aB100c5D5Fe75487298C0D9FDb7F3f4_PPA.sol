/**
 *Submitted for verification at Etherscan.io on 2021-09-17
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

    //@title This contract register PPA buyers automatically each time someone purchase a PPA
    //@dev Each buyer must have aBuyerID > 0 
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

    //@notice Using counters for ID of each PPA contract 
    //@dev each time a new PPA is created, ID will increase by one.
    //@param registry is the address of the registry deployed contract to issue and store RECs
    using Counters for Counters.Counter;
    Counters.Counter private contractID;
    address registry;

    uint32 constant cent = 1;
    uint32 constant dollar = 100 * cent;

    uint64 constant mWh = 1;
    uint64 constant  Wh = 1000 * mWh;
    uint64 constant kWh = 1000 * Wh;
    uint64 constant MWh = 1000 * kWh;
    uint64 constant GWh = 1000 * MWh;
    uint64 constant TWh = 1000 * GWh;

    enum Status {Pending, Approved, Rejected, Expired}
    event createdPPA(address indexed producer, uint32 price, uint id);
    event createdCorpPPA(address indexed producer, address indexed buyer, uint32 price, uint id);
    event acceptedCorpPPA(address indexed producer, address indexed buyer, uint id, uint32 agreedPrice);
    event purchasedPPA(address indexed buyer, address indexed producer, uint id);
    event expiredPPA(address indexed producer, address indexed buyer, uint startDay, uint endDay, Status status);
    event availableEnergyNotification(address indexed producer, address indexed buyer, uint64 energy, uint id);

    //@title Structs
    //@dev ppa for all pending PPA contracts
    //@dev When claimed a ppa then store to approvedPPA struct
    //@dev producerEnergy belongs to producer side from which store the available kWhs.
    //@dev purchasesPPA all kWhs purchases based on PPAs.
    //@param startDay, endDay Must be timestamp (ex. uint64 endDay = 1833746400; // 2028-02-10 00:00:00)
    struct ppa {
        address buyer;
        address producer;
        uint32 kwhPrice;
        uint startDay;
        uint endDay;
        uint id;
        Status status;
    }

    mapping(address => ppa[]) ppas;
    ppa[] listOfPPAs;
    ppa[] corporatePPAList;

    struct approvedPPA{
        address buyer;
        address producer;
        uint32 kwhPrice;
        uint startDay;
        uint endDay;
        uint id;
        uint64 totalKwh;
        Status status;
    }

    mapping(uint => uint) approvedPPAs;
    approvedPPA[] Appas;

    struct producerEnergy{
        address producer;
        address buyer;
        uint timestamp;
        uint64 energy;
        uint idOfmatchContract;
    }

    mapping(address => uint) pEnergy;
    producerEnergy[] listOfkwhs;

    struct purchasesPPA{
        address buyer;
        address producer;
        uint timestamp;
        uint idOfPPA;
        uint64 purchasedEnergy;
    }

    purchasesPPA[] listOfprchs;

    //@notice corporate and create PPA function
    //@dev corporatePPA based on agreed terms between 2 parts Both parties benefit from long-term price guarantees that protect them from market price volatility.
    //@dev createPPA ad hoc contracts with specific price per kWhs.
    //@param _agreedKwhPrice agreed price per kWhs.
    //@param _kwhPrice just price per kWhs based on market and producer' s choice.
    //@param _startDay the day the PPA enters into force. 
    //@param _endDay the day the PPA expires.
    function corporatePPA(address _buyer, uint32 _agreedKwhPrice,uint _startDay, uint _endDay, uint _id) public onlyRegisteredProducers {
        address _producer = msg.sender;
        require(_startDay >= block.timestamp, "ERROR...wrong date");
        require(_endDay > _startDay, "ERROR...end day must be greater than start day");
        require(_agreedKwhPrice >= cent, "ERROR...price in Cent, i.e. 1.5dollar = 150cents");
        corporatePPAList.push(ppa({
            buyer: _buyer,
            producer: _producer,
            kwhPrice: _agreedKwhPrice,
            startDay: _startDay,
            endDay: _endDay,
            id: _id,
            status: Status.Pending
        }));
        emit createdCorpPPA(_producer, _buyer, _agreedKwhPrice, _id);
    }

    //@notice acceptCorporatePPA, claimAuctionPPA and claimPPA
    //@dev acceptCorporatePPA based on id and the address which contract refers to.
    //@dev claimPPA you can claim any PPA just from its ID.
    //@dev claimAuctionPPA claim PPA based on lower price per kWhs.
    function acceptCorporatePPA(uint _id) public{
        address _buyer = msg.sender;
        uint64 _totalKwh = 0;
        uint idx = approvedPPAs[_id];
        for(uint i = 0; i < corporatePPAList.length; i++){
            if((corporatePPAList[i].buyer == _buyer) && (corporatePPAList[i].id == _id)){
                idx = Appas.length;
                approvedPPAs[_id] = idx;
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
                if(ppaBuyers[msg.sender] <= 0){
                    ppaBuyerRegistry.registerPPABuyer(_buyer);
                }
                emit acceptedCorpPPA(corporatePPAList[i].producer, _buyer, corporatePPAList[i].id, corporatePPAList[i].kwhPrice);
                if(corporatePPAList.length > 1){
                    corporatePPAList[i] = corporatePPAList[corporatePPAList.length-1];
                }
                corporatePPAList.length--;
                break;
            }
        }
    }

    function createPPA(uint32 _kwhPrice, uint _startDay, uint _endDay) public onlyRegisteredProducers { //onlyRegisteredProducers
        address _producer = msg.sender;
        contractID.increment();
        uint currentID = contractID.current();
        require(_startDay >= block.timestamp, "ERROR...wrong date");
        require(_endDay > _startDay, "ERROR...end day must be greater than start day");
        require(_kwhPrice >= cent, "ERROR...price in Cent, i.e. 1.5dollar = 150cents");
        listOfPPAs.push(ppa({
            buyer: address(0x0),
            producer: _producer,
            kwhPrice: _kwhPrice,
            startDay: _startDay,
            endDay: _endDay,
            id: currentID,
            status: Status.Pending
        }));
        emit createdPPA(_producer, _kwhPrice, currentID);
    }

    function claimPPA(uint _id) public {
        uint64 _totalKwh = 0;
        address buyer = msg.sender;
        uint idx = approvedPPAs[_id];
        for(uint i = 0; i<listOfPPAs.length; i++){
            if((listOfPPAs[i].producer == buyer) && (listOfPPAs[i].endDay < block.timestamp)){
                break;
            }
            if(listOfPPAs[i].id == _id){
                idx = Appas.length;
                approvedPPAs[_id] = idx;
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
                emit purchasedPPA(buyer, listOfPPAs[i].producer, listOfPPAs[i].id);
                if(ppaBuyers[msg.sender] <= 0){
                    ppaBuyerRegistry.registerPPABuyer(buyer);
                }
                if(listOfPPAs.length > 1){
                    listOfPPAs[i] = listOfPPAs[listOfPPAs.length-1];
                }
                listOfPPAs.length--;
                break;
            }
        }
    }

    function claimAuctionPPA() public{
        uint i = 0;
        uint comparePPA = listOfPPAs[i].kwhPrice;
        uint index = 1;
        uint64 _totalkwh = 0;
        address buyerAddr = msg.sender;
        uint idx;
        for(i = 0; i < listOfPPAs.length; i++){
            if(listOfPPAs[i].kwhPrice < comparePPA){
                if((listOfPPAs[i].producer == buyerAddr) && (listOfPPAs[i].endDay < block.timestamp)){
                    break;
                }
                comparePPA = listOfPPAs[i].kwhPrice;
                index = i;
            }
        }
        idx = Appas.length;
        approvedPPAs[listOfPPAs[index].id] = idx;
        Appas.push(approvedPPA({
            buyer: buyerAddr,
            producer: listOfPPAs[index].producer,
            kwhPrice: listOfPPAs[index].kwhPrice,
            startDay: listOfPPAs[index].startDay,
            endDay: listOfPPAs[index].endDay,
            id: listOfPPAs[index].id,
            totalKwh: _totalkwh,
            status: Status.Approved
        }));
        emit purchasedPPA(buyerAddr, listOfPPAs[index].producer, listOfPPAs[index].id);
        if(ppaBuyers[msg.sender] <= 0){
            ppaBuyerRegistry.registerPPABuyer(buyerAddr);
        }
        if(listOfPPAs.length > 1){
            listOfPPAs[index] = listOfPPAs[listOfPPAs.length-1];
        }
        listOfPPAs.length--;
    }

    //@notice availableKwhs, buyPPAKwhs and energyTradingPPA
    //@dev only producers can inform the network for available energy.
    //@dev if there is available energy in network then you can buy kWhs if you have PPA, if not you have to claim one.
    //@dev kWhs you can buy from buyPPAKwhs with your id and from energyTradingPPA you can buy specific amount of kWhs.
    //@param _idOfMatchPPA, producers must also finalized the PPA to which they are referring.
    function availableKwhs(address _buyer, uint64 _energy, uint _idOfMatchPPA) public onlyRegisteredProducers{
        require(_energy >= kWh, "You have to put at least 1Kwh (in whs for example 1.5kwhs -> 1500 (wh)), your current input have to be 1.000.000mwh");
        address _producer = msg.sender;
        listOfkwhs.push(producerEnergy({
            producer: _producer,
            buyer: _buyer,
            timestamp: block.timestamp,
            energy: _energy,
            idOfmatchContract: _idOfMatchPPA
        }));
        emit availableEnergyNotification(_producer, _buyer, _energy, _idOfMatchPPA);
    }

    function buyPPAKwhs(uint _idOfPPA) public onlyPPABuyers{
        uint currentTime = block.timestamp;
        address aBuyer = msg.sender; 
        for(uint j = 0; j<Appas.length; j++){ //uint j = 0; j<Appas.length; j++
            //@dev search on Approved PPAs to match the id - producer with kwhs
            for(uint i = 0; i<listOfkwhs.length; i++){ //uint i = 0; i<listOfkwhs.length; i++
                uint64 totalEnergyPurchased = 0;
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

    function energyTradingPPA(uint _idOfContract, uint64 _buyEnergy) public onlyPPABuyers{
        uint currentTime = block.timestamp;
        uint64 buyEnergy = _buyEnergy;
        address aBuyer = msg.sender; 
        address _producer;
        bool isEnergyPurchased = false;
        for(uint j = 0; j < Appas.length; j++){
            if((Appas[j].id == _idOfContract) && (Appas[j].buyer == aBuyer)){
                require(Appas[j].startDay <= currentTime, "PPA is not active yet");
                require(Appas[j].endDay > currentTime, "PPA has expired");
                for(uint i = 0; i < listOfkwhs.length; i++){
                    uint64 totalEnergyPurchased = 0;
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

    function viewAllpurchases(uint n, uint offset) public view returns (address[] memory, address[] memory, uint64[] memory, uint[] memory){
        require(n>0, "n must be greater than 0");
        if(n>listOfprchs.length) n=listOfprchs.length;
        address[] memory _producerList1 = new address[](n);
        address[] memory _buyerList1 = new address[](n);
        uint64[] memory _purchaseList1 = new uint64[](n);
        uint[] memory _idPPAlist1 = new uint[](n);
        for(uint i = offset; i < n+offset; i++){
            _producerList1[i-offset] = listOfprchs[i].producer;
            _buyerList1[i-offset] = listOfprchs[i].buyer;
            _purchaseList1[i-offset] = listOfprchs[i].purchasedEnergy;
            _idPPAlist1[i-offset] = listOfprchs[i].idOfPPA;
        }
        return(_producerList1, _buyerList1, _purchaseList1, _idPPAlist1);
    }

    function getCountOfCorpPPAByAddress() public view returns(uint){
        address currentAddress = msg.sender;
        uint count = 0;
        for(uint i = 0; i<corporatePPAList.length; i++){
            if((corporatePPAList[i].buyer == currentAddress) || (corporatePPAList[i].producer == currentAddress)){
                count++;
            }
        }
        return count;
    }

    function viewCorporatePPAlist() public view returns(address[] memory, address[] memory, uint32[] memory, uint[] memory, uint[] memory, uint[] memory){
        uint k = 0;
        uint cnt = getCountOfCorpPPAByAddress();
        address[] memory _producerList = new address[](cnt);
        address[] memory _buyerList = new address[](cnt);
        uint32[] memory _priceList = new uint32[](cnt);
        uint[] memory _idPPAlist = new uint[](cnt);
        uint[] memory _sDayList = new uint[](cnt);
        uint[] memory _eDayList = new uint[](cnt);

        for(uint i = 0; i < corporatePPAList.length; i++){
            if((corporatePPAList[i].buyer == msg.sender) || (corporatePPAList[i].producer == msg.sender)){
                _producerList[k] = corporatePPAList[i].producer;
                _buyerList[k] = corporatePPAList[i].buyer;
                _priceList[k] = corporatePPAList[i].kwhPrice;
                _idPPAlist[k] = corporatePPAList[i].id;
                _sDayList[k] = corporatePPAList[i].startDay;
                _eDayList[k] = corporatePPAList[i].endDay;
                k++;
            }
        }
        return(_producerList, _buyerList, _priceList, _idPPAlist, _sDayList, _eDayList);
    }

    function viewAllPPAs (uint n, uint offset) public view returns (address[] memory, uint32[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        require(n>0, "n must be greater than 0");
        if(n>listOfPPAs.length) n=listOfPPAs.length;
        address[] memory producerList = new address[](n);
        uint32[] memory priceList = new uint32[](n);
        uint[] memory idPPAlist = new uint[](n);
        uint[] memory sDayList = new uint[](n);
        uint[] memory eDayList = new uint[](n);
        uint[] memory statusList = new uint[](n);
        for(uint i = offset; i < n+offset; i++){
            producerList[i-offset] = listOfPPAs[i].producer;
            priceList[i-offset] = listOfPPAs[i].kwhPrice;
            idPPAlist[i-offset] = listOfPPAs[i].id;
            sDayList[i-offset] = listOfPPAs[i].startDay;
            eDayList[i-offset] = listOfPPAs[i].endDay;
            statusList[i-offset] = uint(listOfPPAs[i].status);
        }
        return(producerList, priceList, idPPAlist, sDayList, eDayList, statusList);
    }

    function viewAvailableKwhs(uint n, uint offset) public view returns(address[] memory, address[] memory, uint64[] memory, uint[] memory){
        require(n>0, "n must be greater than 0");
        if(n>listOfkwhs.length) n=listOfkwhs.length;
        address[] memory producerList_ = new address[](n);
        address[] memory buyerList_ = new address[](n);
        uint64[] memory energyList_ = new uint64[](n);
        uint[] memory idOfPPAlist_ = new uint[](n);
        for(uint i = offset; i < n+offset; i++){
            producerList_[i-offset] = listOfkwhs[i].producer;
            buyerList_[i-offset] = listOfkwhs[i].buyer;
            energyList_[i-offset] = listOfkwhs[i].energy;
            idOfPPAlist_[i-offset] = listOfkwhs[i].idOfmatchContract;
        }
        return(producerList_, buyerList_, energyList_, idOfPPAlist_);
    }

    function viewApprovalPPAs(uint n, uint offset) public view returns(address[] memory, address[] memory, uint[] memory, uint32[] memory, uint[] memory, uint[] memory){
        require(n>0, "n must be greater than 0");
        if(n>Appas.length) n=Appas.length;
        address[] memory proList = new address[](n);//producer
        address[] memory buyerList = new address[](n);//buyer
        uint[] memory idlist = new uint[](n);//energy
        uint32[] memory prList = new uint32[](n);//price
        uint[] memory sDateList = new uint[](n);//startDay
        uint[] memory eDateList = new uint[](n);//endDay
        for(uint i = offset; i < n+offset; i++){
            proList[i-offset] = Appas[i].producer;
            buyerList[i-offset] = Appas[i].buyer;
            idlist[i-offset] = Appas[i].id;
            prList[i-offset] = Appas[i].kwhPrice;
            sDateList[i-offset] = Appas[i].startDay;
            eDateList[i-offset] = Appas[i].endDay;
        }
        return(proList, buyerList, idlist, prList, sDateList, eDateList);
    }

    function getAvailableEnergyByIndex(uint _idx) public view returns (address, address, uint64, uint, uint){
        producerEnergy storage _kwhs = listOfkwhs[_idx];
        return(_kwhs.producer, _kwhs.buyer, _kwhs.energy, _kwhs.timestamp, _kwhs.idOfmatchContract);
    }

    function getPPAByIndex(uint _idx) public view returns (address, address, uint32, uint, uint, uint){
        ppa storage _ppa = listOfPPAs[_idx];
        return(_ppa.producer, _ppa.buyer, _ppa.kwhPrice, _ppa.startDay, _ppa.endDay, _ppa.id);
    }

    function getCorporatePPAByIndex(uint _idx) public view returns (address, address, uint32, uint, uint, uint){
        ppa storage _corporate = corporatePPAList[_idx];
        return(_corporate.producer, _corporate.buyer, _corporate.kwhPrice, _corporate.startDay, _corporate.endDay, _corporate.id);
    }

    function getApprovedPPAByIndex(uint _idx) public view returns (address, address, uint32, uint, uint, uint){
        approvedPPA storage _Appa = Appas[_idx];
        return(_Appa.producer, _Appa.buyer, _Appa.kwhPrice, _Appa.startDay, _Appa.endDay, _Appa.id);
    }

    function getPurchasesByIndex(uint _idx) public view returns (address, address, uint64, uint, uint){
        purchasesPPA storage _Allpurchases = listOfprchs[_idx];
        return(_Allpurchases.producer, _Allpurchases.buyer, _Allpurchases.purchasedEnergy, _Allpurchases.timestamp, _Allpurchases.idOfPPA);
    }

    //Return lengths of each list
    function getAvKwhs() public view returns(uint count){
        return listOfkwhs.length;
    }

    function getPPAs() public view returns(uint count){
        return listOfPPAs.length;
    }

    function getCorpPPAs () public view returns(uint count){
        return corporatePPAList.length;
    }

    function getApprovedPPAs () public view returns(uint count){
        return Appas.length;
    }

    function getPurchases () public view returns(uint count){
        return listOfprchs.length;
    }
    
    function getApprovedPPAByID(uint _id) public view returns(address, address, uint32, uint, uint, uint){
        uint index = approvedPPAs[_id];
        require(Appas.length > index, "Wrong index");
        require(Appas[index].id == _id, "Wrong PPA ID");
        return(Appas[index].producer, Appas[index].buyer, Appas[index].kwhPrice, Appas[index].startDay, Appas[index].endDay, Appas[index].id);
    }
}