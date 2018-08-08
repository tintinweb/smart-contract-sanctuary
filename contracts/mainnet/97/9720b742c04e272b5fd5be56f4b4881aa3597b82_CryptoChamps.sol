pragma solidity ^0.4.19;

contract Ownable{
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract CryptoChamps is Ownable{
    
    struct Person {
        uint32 id;
        string name;
        uint16 txCount;
        bool discounted;
    }
    
    event Birth(uint32 _id, uint _startingPrice);
    event Discount(uint32 _id, uint _newPrice);
    event Purchase(uint32 indexed _id, address indexed _by, address indexed _from, uint _price, uint _nextPrice);
    event Transfer(address indexed _from, address indexed _to, uint32 _id);
    
    uint public totalSupply = 0;
    string public name = "CryptoChamps";
    string public symbol = "CCH";
    address store;
    mapping (uint32 => Person) private people;
    mapping (uint32 => address) private personToOwner;
    mapping (uint32 => uint256) public personToPrice;
    mapping (uint32 => uint256) public personToOldPrice;
    mapping (address => uint) private noOfPersonsOwned;
    mapping (address => bool) private isUserAdded;
    
    address[] private users;
    
    uint8 BELOW_FIVE = 200;
    uint8 BELOW_TEN = 150;
    uint8 BELOW_FIFTEEN = 130;
    uint8 BELOW_TWENTY = 120;
    uint8 TWENTY_ABOVE = 110;
    
    function CryptoChamps() public{
        store = msg.sender;
    }
    
    function createPerson (uint32 _id, string _name, uint256 _startingPrice) external onlyOwner {
        require(people[_id].id == 0);
        Person memory person = Person(_id, _name, 0, false);
        people[_id] = person;
        personToOwner[_id] = owner;
        personToPrice[_id] = _startingPrice;
        totalSupply++;
        Birth(_id, _startingPrice);
    }
    
    function getPerson(uint32 _id) external view returns (string, uint256, uint256) {
       Person memory person = people[_id];
       require(person.id != 0);
       return (person.name, personToPrice[_id], person.txCount);
    }
    
    function purchase(uint32 _id) payable public{
        uint price = personToPrice[_id] ;
        address personOwner = personToOwner[_id];
        
        require(msg.sender != 0x0);
        require(msg.sender != personOwner);
        require(price <= msg.value);
        
        
        Person storage person = people[_id];
        
        if(price < msg.value){
            msg.sender.transfer(msg.value - price);
        }
        
        _handlePurchase(person, personOwner, price);
        uint newPrice = _onPersonSale(person);
        
        if(!isUserAdded[msg.sender]){
            users.push(msg.sender);
            isUserAdded[msg.sender] = true;
        }
        
        Purchase(_id, msg.sender, personOwner, price, newPrice);
    }
    
    function discount(uint32 _id, uint _newPrice) external ownsPerson(_id) returns (bool){
        uint price = personToPrice[_id];
        require(price > _newPrice);
        
        Person storage person = people[_id];
        person.discounted = true;
        
        personToPrice[_id] = _newPrice;
        
        Discount(_id, _newPrice);
        
        return true;
    }
    
    function _handlePurchase(Person storage _person, address _owner, uint _price) internal {
        uint oldPrice = personToOldPrice[_person.id];
        
        if(_person.discounted){
            _shareDiscountPrice(_price, _owner);
        }else{
            _shareProfit(_price, oldPrice, _owner);
        }
        
        personToOwner[_person.id] = msg.sender;
        
        noOfPersonsOwned[_owner]--;
        noOfPersonsOwned[msg.sender]++;
    }
    
    function _shareDiscountPrice(uint _price, address _target) internal {
        uint commision = _price * 10 / 100;
        
        _target.transfer(_price - commision);
        
        owner.transfer(commision);
    }
    
    function _shareProfit(uint _price, uint _oldPrice, address _target) internal {
        uint profit = _price - _oldPrice;
        
        uint commision = profit * 30 / 100;
        
        _target.transfer(_price - commision);
        
        owner.transfer(commision);
    }
    
    function _onPersonSale(Person storage _person) internal returns (uint) {
        uint currentPrice = personToPrice[_person.id];
        uint percent = 0;
        
        if(currentPrice >= 6.25 ether){
            percent = TWENTY_ABOVE;
        }else if(currentPrice >= 2.5 ether){
            percent = BELOW_TWENTY;
        }else if(currentPrice >=  1 ether){
            percent = BELOW_FIFTEEN;
        }else if(currentPrice >= 0.1 ether){
            percent = BELOW_TEN;
        }else{
            percent = BELOW_FIVE;
        }
        
        personToOldPrice[_person.id] = currentPrice;
        uint newPrice = _approx((currentPrice * percent) / 100);
        personToPrice[_person.id] = newPrice;
        
        _person.txCount++;
        if(_person.discounted){
            _person.discounted = false;
        }
        
        return newPrice;
    }
    
    function _approx(uint _price) internal pure returns (uint){
        uint product = _price / 10 ** 14;
        return product * 10 ** 14;
    }
    
    function transfer(address _to, uint32 _id) external ownsPerson(_id){
        personToOwner[_id] = _to;
        noOfPersonsOwned[_to]++;
        noOfPersonsOwned[msg.sender]--;
        Transfer(msg.sender, _to, _id);
    }
    
    function ownerOf(uint32 _id) external view returns (address) {
        return personToOwner[_id];
    }
    
    function priceOf(uint32 _id) external view returns (uint256) {
        return personToPrice[_id];
    }
    
    function balanceOf(address _owner) external view returns (uint){
        return noOfPersonsOwned[_owner];
    }
    
    function getStore() external view onlyOwner returns (address){
        return store;
    }
    
    function setStore(address _store) external onlyOwner returns (bool) {
        require(_store != 0);
        store = _store;
        return true;
    }
    
    function getUsers() external view returns (address[]) {
        return users;
    }
    
    function withdraw() external onlyOwner returns (bool){
        owner.transfer(this.balance);
        return true;
    }
    
    modifier ownsPerson(uint32 _id){
        require(personToOwner[_id] == msg.sender);
        _;
    }
    
}