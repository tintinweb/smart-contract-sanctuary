/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title MProRacing
 * @dev Store & retrieve MProRacing game datas, purchase cars
 */

/**
 * @dev MPro token interface
 */
interface MProInterface {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external payable returns (bool success);
    
    
    function approve(
        address _spender, 
        uint256 _value
    ) external returns (bool success);
}

/**
 * @dev Room Information struct. 
 * It will contains betting racing room information
 */ 
struct Room {
    uint256 betAmount;
    uint256 memberCount;
    mapping(address => bool) members;
}

/**
 * @dev Main Contract for the Racing game. 
 * Users can purchase cars and items here.
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract MProRacing {
    /**
     * @dev MPro token address.
     */
    address tokenAddress = 0xc32E9217e5b135f151732A2002E918271172e107;
    
    /**
     * @dev Game Contract owner
     * Owner will get the each racing betting room fee
     */
    address owner = 0x0bA1e7b6B1dAe90F6732dAc179eFa857ba3c59F6;

    /**
     * @dev Game temporary wallet for the game rooms.
     * Have to approve MPro spending between gameWallet and GameContract after deploy. 
     */
    address gameWallet = 0xC4B7413441280cB2aFA12Eae2dc65E960075a86d;

    /**
     * @dev Cars and items price information.
     */
    uint256[] public carPrices;
    uint256[] public wheelPrices;
    uint256[] public spoilerPrices;
    uint256[] public enginePrices;
    uint256[] public suspensionPrices;
    uint256[] public nosPrices;
    uint256[] public bodyColorPrices;
    uint256[] public tintPrices;
    uint256[] public camberPrices;
    
    mapping(address => uint8[10][9][10]) public purchaseItems;
    
    mapping(address => Room) public rooms;

    MProInterface mpro = MProInterface(tokenAddress);
    
    /**
     * @dev Initializes the contract information and setting the deployer as the initial owner.
     */

    constructor() {
        carPrices = [500, 900, 1100, 1500, 3000, 2500, 2900, 4000, 5500, 7000];
        wheelPrices = [40, 50, 60, 70, 80, 90, 100, 110, 120, 130];
        spoilerPrices = [30, 40, 50, 60];
        enginePrices = [40, 50, 60, 70, 80];
        suspensionPrices = [25];
        nosPrices = [40, 50, 60, 70, 80];
        bodyColorPrices = [25, 25];
        tintPrices = [25];
        camberPrices = [25];
    }
    
    /**
     * @dev Returns the user purchased items information.
     */
    function retrieve() public view returns (uint8[10][9][10] memory) {
        return purchaseItems[msg.sender];
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    /**
     * @dev Purchase cars and items.
     */
    function purchase(uint256 _carId, uint256 _itemType, uint256 _itemId) public payable{
        uint256 price;
        
        if (_itemType == 0)
            price = carPrices[_itemId];
        else if(_itemType == 1)
            price = wheelPrices[_itemId];
        else if(_itemType == 2)
            price = spoilerPrices[_itemId];
        else if(_itemType == 3)
            price = enginePrices[_itemId];
        else if(_itemType == 4)
            price = suspensionPrices[_itemId];
        else if(_itemType == 5)
            price = nosPrices[_itemId];
        else if(_itemType == 6)
            price = bodyColorPrices[_itemId];
        else if(_itemType == 7)
            price = tintPrices[_itemId];
        else if(_itemType == 8)
            price = camberPrices[_itemId];

        require(mpro.transferFrom(msg.sender, owner, price * 1e18));

        purchaseItems[msg.sender][_carId][_itemType][_itemId] = 1;
    }
    
    /**
     * @dev SellCar Function, User can sell their purchased car using this function.
     */
    function sellCar(uint256 _carId) public payable {
        require(purchaseItems[msg.sender][_carId][0][_carId] == 1);
        require(mpro.transferFrom(owner, msg.sender, carPrices[_carId] * 3 / 4 * 1e18));
        purchaseItems[msg.sender][_carId][0][_carId] = 0;
    }
    
    // Create room with msg.sender
    function createRoom(uint256 price) public payable {
        require(mpro.transferFrom(msg.sender, gameWallet, price * 1e18));
        
        rooms[msg.sender].betAmount = price;
        rooms[msg.sender].memberCount = 1;
        rooms[msg.sender].members[msg.sender] = true;
    }
    
    // Join room with creator address
    function joinRoom(address creator) public payable {
        require(mpro.transferFrom(msg.sender, gameWallet, rooms[creator].betAmount * 1e18));

        rooms[creator].memberCount += 1;
        rooms[creator].members[msg.sender] = true;
    }
    
    // Finish room with creator address   
    function finishRoom(address creator) public payable {
        require(rooms[creator].members[msg.sender] == true);
        require(mpro.transferFrom(gameWallet, owner, rooms[creator].betAmount * rooms[creator].memberCount / 10 * 1e18));
        require(mpro.transferFrom(gameWallet, msg.sender, rooms[creator].betAmount * rooms[creator].memberCount * 9 / 10 * 1e18));

        rooms[creator].betAmount = 0;
        rooms[creator].memberCount = 0;
    }

    // Leave room with creator address   
    function leaveRoom(address creator) public payable {
        require(rooms[creator].members[msg.sender] == true);
        require(mpro.transferFrom(gameWallet, msg.sender, rooms[creator].betAmount * 1e18));
        
        rooms[creator].memberCount -= 1;
        rooms[creator].members[msg.sender] = false;
    }
}