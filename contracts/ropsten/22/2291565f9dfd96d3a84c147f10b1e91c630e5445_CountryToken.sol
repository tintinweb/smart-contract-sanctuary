pragma solidity ^0.4.24;

contract CountryToken {

    address public firstWallet;
    address public secondWallet;
    
    struct Country {
        string name;
        string telegram;
        string admin;
        uint256 price;
    }
    
    Country[] public countries;
    address public owner;
    mapping(uint => address) public ownerOf;
    mapping(uint => bool) public isExist;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }
    
    constructor(address _firstWallet, address _secondWallet) public {
        owner = msg.sender;
        firstWallet = _firstWallet;
        secondWallet = _secondWallet;
    }

    function updateFirstWallet(address _firstWallet) public onlyOwner() {
        firstWallet = _firstWallet;
    }

    function updateSecondWallet(address _secondWallet) public onlyOwner() {
        secondWallet = _secondWallet;
    }
    
    function getCountriesCount() public view returns(uint) {
        return countries.length;
    }

    function createCountry(string _name, string _telegram, string _admin, uint256 _price) public onlyOwner() {
        uint id = countries.length;
        countries.push(Country(_name, _telegram, _admin, _price));
        ownerOf[id] = owner;
        isExist[id] = true;
    }

    function deleteCountry(uint _id) public {
        require(isExist[_id]);
        require(ownerOf[_id] == msg.sender);
        isExist[_id] = false;
    }

    function updateTelegram(uint _id, string _telegram) public onlyOwner() {
        countries[_id].telegram = _telegram;
    }
    
    function buy(uint _id, string _admin) public payable {
        require(msg.value == countries[_id].price);
        uint256 price10 = msg.value / 10;
        firstWallet.transfer(price10 / 2);
        secondWallet.transfer(price10 / 2);
        ownerOf[_id].transfer(msg.value - price10);
        countries[_id].price = msg.value * 2;
        countries[_id].admin = _admin;
        ownerOf[_id] = msg.sender;
    }
}