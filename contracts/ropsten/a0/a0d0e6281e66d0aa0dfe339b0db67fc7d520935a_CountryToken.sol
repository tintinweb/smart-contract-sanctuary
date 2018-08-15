pragma solidity ^0.4.24;

contract CountryToken {
    
    struct Country {
        string name;
        string whatsapp;
        uint256 price;
    }
    
    Country[] public countries;
    address public owner;
    mapping(uint => address) public ownerOf;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function getCountriesCount() public view returns(uint) {
        return countries.length;
    }

    function createCountry(string _name, string _whatsapp, uint256 _price) public onlyOwner() {
        uint id = countries.length;
        countries.push(Country(_name, _whatsapp, _price));
        ownerOf[id] = owner;
    }
    
    function buy(uint _id, string _whatsapp) public payable {
        require(msg.value == countries[_id].price);
        uint256 price20 = msg.value / 20;
        owner.transfer(price20);
        ownerOf[_id].transfer(msg.value - price20);
        countries[_id].price = msg.value * 2;
        countries[_id].whatsapp = _whatsapp;
        ownerOf[_id] = msg.sender;
    }
}