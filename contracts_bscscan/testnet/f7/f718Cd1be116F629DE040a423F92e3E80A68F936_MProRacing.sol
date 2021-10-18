/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

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
    
    function transfer(
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
    bool roomOpen;
    string name;
    address winner;
    address creator;
    mapping(address => bool) members;
}


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
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
contract MProRacing is Ownable {
    /**
     * @dev MPro token address.
     */
    address public tokenAddress = 0x79fDe167C18C51892BE4B559b60d9420c02afd05;
    
 
    /**
     * @dev Game  wallet for the game rooms.
     * All earnings from game goes here
     */
    address public gameWallet = 0xC4B7413441280cB2aFA12Eae2dc65E960075a86d;

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
    
    // Array of Rooms 
    mapping(uint256 => Room) public rooms;

    // Array of members in a room
    mapping(uint256 => address[]) public members;

    // Array of rooms of a user
    mapping(address => uint256[]) public userRooms;

    // Array of created rooms of a user
    mapping(address => uint256[]) public creatorRooms;

    // Pool Colleced for a room
    mapping(uint256 => uint256) public poolcollected;

    // Array of Room IDs
    uint256[] public roomsIds ; 

    // Owner Fee for From pool amount
    uint256 public ownerFee = 300 ; // 30% Fee

    // Sell Fee for assets
    uint256 public sellFee = 300 ; // 30% Fee

    MProInterface public mpro = MProInterface(tokenAddress);
    
    /**
     * @dev Initializes the contract information and setting the deployer as the initial owner.
     */

    constructor() public {
        carPrices = [500, 900, 1100, 1500, 3000, 2500, 2900, 4000, 5500, 7000];
        wheelPrices = [40, 50, 60, 70, 80, 90, 100, 110, 120, 130];
        spoilerPrices = [30, 40, 50, 60];
        enginePrices = [40, 50, 60, 70, 80];
        suspensionPrices = [25];
        nosPrices = [40, 50, 60, 70, 80];
        bodyColorPrices = [25, 25];
        tintPrices = [25];
        camberPrices = [25];
        owner = msg.sender ; 
    }
    
    /**
     * @dev Returns the user purchased items information.
     */
    function retrieve() public view returns (uint8[10][9][10] memory) {
        return purchaseItems[msg.sender];
    }
    
 
    
    /**
     * @dev Purchase cars and items.
     */
    function purchase(uint256 _carId, uint256 _itemType, uint256 _itemId) public {
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

        require(mpro.transferFrom(msg.sender, address(this), price * 1e18));

        purchaseItems[msg.sender][_carId][_itemType][_itemId] = 1;
    }
    
    /**
     * @dev SellCar Function, User can sell their purchased car using this function.
     */
    function sellCar(uint256 _carId) public {
        require(purchaseItems[msg.sender][_carId][0][_carId] == 1);
        uint256 _fee = carPrices[_carId]*sellFee/1000 ; 
        uint256 _amt =  carPrices[_carId] ; 
        if(_fee > 0 ){
                _amt = _amt - _fee ; 
        }
        require(mpro.transfer(msg.sender, _amt * 1e18));
        require(mpro.transfer(gameWallet, _fee * 1e18));
        purchaseItems[msg.sender][_carId][0][_carId] = 0;
    }
    
    // Create room with msg.sender and price
    function createRoom(string memory _name ,  uint256 price) public  {
        require(mpro.transferFrom(msg.sender, address(this), price * 1e18));

        uint256 id = roomsIds.length ; 
        roomsIds.push(id) ;
        poolcollected[id] = poolcollected[id] + price  ;
        rooms[id].betAmount = price;
        rooms[id].memberCount = 1;
        rooms[id].name = _name;
        rooms[id].roomOpen = true;
        rooms[id].creator = msg.sender;
        rooms[id].members[msg.sender] = true;
        
        userRooms[msg.sender].push(id) ; 
        creatorRooms[msg.sender].push(id) ; 
        
    }
    
    // Join room with room id
    function joinRoom(uint256 _id) public  {

        require(rooms[_id].roomOpen == true , "Room Closed");
        require(rooms[_id].members[msg.sender] == false , "Already a member");
        require(mpro.transferFrom(msg.sender, address(this), rooms[_id].betAmount * 1e18));
        poolcollected[_id] = poolcollected[_id] + rooms[_id].betAmount  ;

        rooms[_id].memberCount += 1;
        rooms[_id].members[msg.sender] = true;
        userRooms[msg.sender].push(_id) ; 

    }
    
    // Finish room with id and winner address   
    function finishRoom(uint256 _id, address _winner) public onlyOwner {
        require(rooms[_id].roomOpen  == false, "Room not closed");

        uint256 _fee = poolcollected[_id]*ownerFee/1000 ; 
        uint256 _amt =  poolcollected[_id] ; 
        if(_fee > 0 ){
                _amt = _amt - _fee ; 
        }

        require(mpro.transfer(gameWallet, _fee * 1e18));
        require(mpro.transfer(_winner, _amt * 1e18));

        rooms[_id].winner = msg.sender;
       
        poolcollected[_id] = 0 ;
 
    }

    // Allow to remove
    function leaveRoom(uint256 _id) public  {
        require(rooms[_id].roomOpen  == true, "Room Closed");
        require(rooms[_id].members[msg.sender] == true , "Not a member");
        require(mpro.transfer(msg.sender,   rooms[_id].betAmount * 1e18));
        poolcollected[_id] = poolcollected[_id] - rooms[_id].betAmount  ;

        rooms[_id].memberCount -= 1;
        rooms[_id].members[msg.sender] = false;
    }

    // Allow to Claim
    function winnerClaim(uint256 _id) public  {
        require(rooms[_id].roomOpen  == true, "Room Closed");
        rooms[_id].roomOpen = false;
    }
    

    // Return the length of the creatorRooms with address
    function retrieveRoomId() public view returns (uint256) {
        return creatorRooms[msg.sender][creatorRooms[msg.sender].length - 1];
    }
    
    // Admin Functions

    function updateToken(
        address _token 
    )
        public onlyOwner
    {
        tokenAddress = _token ;
        mpro = MProInterface(_token) ;
    }

    
    function updateGameWallet(
        address _wallet 
    )
        public onlyOwner
    {
        gameWallet = _wallet ;
    }

    function updateSellFee(
        uint256 _fee
    )
        public onlyOwner
    {
        sellFee = _fee ;
    }

    function updateOwnerFee(
        uint256  _fee 
    )
        public onlyOwner
    {
        ownerFee = _fee ;
    }

   
 
  

    function updateCarPrices(
        uint256[] memory _carPrices 
    )
        public onlyOwner
    {
        carPrices = _carPrices ;
    }


    function updateWheelPrices(
        uint256[] memory _wheelPrices 
    )
        public onlyOwner
    {
        wheelPrices = _wheelPrices ;
    }

    
    function updateSpoilerPrices(
        uint256[] memory _spoilerPrices 
    )
        public onlyOwner
    {
        spoilerPrices = _spoilerPrices ;
    }

    
    function updateEnginePrices(
        uint256[] memory _enginePrices 
    )
        public onlyOwner
    {
        enginePrices = _enginePrices ;
    }

    
    function updateSuspensionPrices(
        uint256[] memory _suspensionPrices 
    )
        public onlyOwner
    {
        suspensionPrices = _suspensionPrices ;
    }

        function updateNosPrices(
        uint256[] memory _nosPrices 
    )
        public onlyOwner
    {
        nosPrices = _nosPrices ;
    }

        function updateBodyColorPrices(
        uint256[] memory _bodyColorPrices 
    )
        public onlyOwner
    {
        bodyColorPrices = _bodyColorPrices ;
    }

        function updateTintPrices(
        uint256[] memory _tintPrices 
    )
        public onlyOwner
    {
        tintPrices = _tintPrices ;
    }

        function updateCamberPrices(
        uint256[] memory _camberPrices 
    )
        public onlyOwner
    {
        camberPrices = _camberPrices ;
    }



}