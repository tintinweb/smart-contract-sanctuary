/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity 0.5.1;
contract Shop {

    uint256 itemCount = 0;
    uint256 peopleCount = 0;
    
    mapping(uint => Person) public people;
    mapping(uint => Item) public items;
    
    struct Person {
        uint _id;
        string _firstName;
        string _lastName;
        uint _wealth; 
    }
    
    struct Item {
        uint _id;
        string _name;
        bool _available;
        uint256 price;
        uint256 owner;
        uint256 purchaseTime;
    }
    
    event Purchase(
        string _buyer,
        uint256 _amount
    );
    
    event Sale(
        string _seller,
        uint256 _amount
    );
    
    modifier onlyWhileOpen(uint b) {
        uint purchaseTime = 0; 
        for(uint i = 0 ;i<=itemCount; i++)
            {
                uint id = items[i]._id;
                if (id == b) {
                    purchaseTime = items[i].purchaseTime;
                }
        
            }
        require(block.timestamp >= purchaseTime + 100);
        _;
    }
    
    function sellItem(uint b) public onlyWhileOpen(b) returns(uint result) {
        uint itemCost = 0;
        uint p = 0;
        for(uint i = 0 ;i<=itemCount; i++)
            {
                uint id = items[i]._id;
                if (id == b) {
                    string memory name = items[i]._name;
                    p = items[i].owner;
                    itemCost = items[i].price;
                    items[i] = Item(b,name,true,itemCost,0,0);
                }
        
            }
        for(uint i = 0 ;i<=peopleCount; i++)
            {
                uint id = people[i]._id;
                if (id == p) {
                    string memory _firstName = people[i]._firstName;
                    string memory _lastName = people[i]._lastName;
                    uint _wealth = people[i]._wealth;
                    _wealth += itemCost;
                    people[i] = Person(p,_firstName,_lastName,_wealth);
                    emit Sale(_lastName, itemCost);
                }
        
            }
        return 1;
    }
    
    function buyItem(uint p, uint b) public returns(uint result) {
        uint itemCost = 0;
        for(uint i = 0 ;i<=itemCount; i++)
            {
                uint id = items[i]._id;
                if (id == b) {
                    string memory name = items[i]._name;
                    itemCost = items[i].price;
                    items[i] = Item(b,name,false,itemCost,p,block.timestamp);
                }
        
            }
        for(uint i = 0 ;i<=peopleCount; i++)
            {
                uint id = people[i]._id;
                if (id == p) {
                    string memory _firstName = people[i]._firstName;
                    string memory _lastName = people[i]._lastName;
                    uint _wealth = people[i]._wealth;
                    _wealth -= itemCost;
                    people[i] = Person(p,_firstName,_lastName,_wealth);
                    emit Purchase(_lastName, itemCost);
                }
        
            }
        return 1;
    }

    function addPerson(
        string memory _firstName,
        string memory _lastName,
        uint _wealth
    )
        public
    {
        incrementCount();
        people[peopleCount] = Person(peopleCount, _firstName, _lastName, _wealth);
    }

    function incrementCount() internal {
        peopleCount += 1;
    }
    
    function addItem(
        string memory _name,
        uint256 _price
    )
        public
    {
        incrementCount2();
        items[itemCount] = Item(itemCount, _name, true, _price, 0, 0);
    }

    function incrementCount2() internal {
        itemCount += 1;
    }
}