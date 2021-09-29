//SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "./ERC20.sol";

contract AmusementParkToken {
    
    // Opening statements

    ERC20 private token;
    address payable public owner;

    constructor() {
        token = new ERC20(10000);
        owner = payable(msg.sender);
    }

    struct customer {
        uint buyedTokens;
        string[] usedRides;
        string[] boughtFood;
    }

    mapping(address=>customer) public customers;

    // Token management

    function tokenPrice(uint _tokenQty) internal pure returns(uint) {
        return _tokenQty*(1 ether);
    }

    function buyToken(uint _tokenQty) public payable {
        uint cost = tokenPrice(_tokenQty);
        require(msg.value>=cost, "You do not have the amount of ethers necessary for the purchase.");
        uint returnValue = msg.value-cost;
        payable(msg.sender).transfer(returnValue);
        uint balance = balanceOf();
        require(_tokenQty<=balance, "The number of tokens requested exceeds the number of tokens for sale.");
        token.transfer(msg.sender, _tokenQty);
        customers[msg.sender].buyedTokens = _tokenQty;
    }

    function balanceOf() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    function myTokens() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }

    function generateTokens(uint _tokenQty) public Park(msg.sender) {
        token.increaseTotalSupply(_tokenQty);
    }

    modifier Park(address _address) {
        require(_address==owner, "You don't have the permissions to execute this function");
        _;
    }

    // Park management

    // Rides
    event rideWasUsed(string, uint, address);
    event rideWasAdded(string, uint);
    event rideWasRemoved(string);

    struct ride {
        string name;
        uint price;
        bool status;
    }

    mapping(string=>ride) public rides;

    string[] ridesNames;

    mapping(address=>string[]) ridesHistory;

    function newRide(string memory _name, uint _price) public Park(msg.sender) {
        rides[_name] = ride(_name, _price, true);
        ridesNames.push(_name);
        emit rideWasAdded(_name, _price);
    }

    function removeRide(string memory _name) public Park(msg.sender) {
        rides[_name].status = false;
        emit rideWasRemoved(_name);
    }

    function getRides() public view returns(string[] memory) {
        return ridesNames;
    }
    
    function useRide(string memory _name) public {
        uint ridePrice = rides[_name].price;
        require(rides[_name].status == true, "Ride unavailable.");
        require(ridePrice <= myTokens(), "Insufficient tokens.");
        token.transferToPark(msg.sender, address(this), ridePrice);
        ridesHistory[msg.sender].push(_name);
        emit rideWasUsed(_name, ridePrice, msg.sender);
    }

    function customerRides() public view returns(string[] memory) {
        return ridesHistory[msg.sender];
    }

    // Foods
    event foodWasBought(string, uint, address);
    event foodWasAdded(string, uint);
    event foodWasRemoved(string);

    struct food {
        string name;
        uint price;
        bool status;
    }

    mapping(string=>food) public foods;

    string[] foodsNames;

    mapping(address=>string[]) foodsHistory;
    
    function newFood(string memory _name, uint _price) public Park(msg.sender) {
        foods[_name] = food(_name, _price, true);
        foodsNames.push(_name);
        emit foodWasAdded(_name, _price);
    }

    function removeFood(string memory _name) public Park(msg.sender) {
        foods[_name].status = false;
        emit foodWasRemoved(_name);
    }

    function getFoods() public view returns(string[] memory) {
        return foodsNames;
    }
    
    function buyFood(string memory _name) public {
        uint foodPrice = foods[_name].price;
        require(foods[_name].status == true, "Food unavailable.");
        require(foodPrice <= myTokens(), "Insufficient tokens.");
        token.transferToPark(msg.sender, address(this), foodPrice);
        foodsHistory[msg.sender].push(_name);
        emit foodWasBought(_name, foodPrice, msg.sender);
    }

    function customerFoods() public view returns(string[] memory) {
        return foodsHistory[msg.sender];
    }

    // Tokens

    function swapTokens(uint _tokenQty) public payable {
        require(_tokenQty > 0, "The number of tokens must be greater than 0.");
        require(_tokenQty <= myTokens(), "Insufficient tokens.");
        token.transferToPark(msg.sender, address(this), _tokenQty);
        payable(msg.sender).transfer(tokenPrice(_tokenQty));
    }

}