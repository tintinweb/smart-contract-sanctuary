/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
/**
 * @title BattleGround
 * @dev Store & Retrieve BattleGround RPG Game data
 */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @dev `The BattleGround` token interface
 */
interface TBGInterface {
    function transfer(
        address _to, 
        uint256 _amount
    ) external payable returns (bool success);
    
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _amount
    ) external payable returns (bool success);
    
    function approve(
        address _spender, 
        uint256 _amount
    ) external payable returns (bool success);
}


/**
 * @dev Player Character infomation struct.
 * It will save player's character information detail.
 */
struct Character {
    string characterName;
    bool characterGender;
    uint256 characterRace;
    uint256 characterType;
    uint256 characterLevel;
    uint256 characterExp;
    bool characterCustomized;
    uint256 characterweaponIndex;
    uint256[] characterWeapons;
    uint256[] characterAttr;
    uint256[] purchasedItems;
}


/**
 * Item Prices information
 */
struct ItemPrice {
    string name;
    uint256[] prices;
}

/**
 * Item Struct
 * Contains Item information.
 */
struct Item {
    string name;
    uint256 itemId;
    bool isUsing;
}

/**
 * @dev Room Information struct. 
 * It will contains betting racing room information
 */ 
struct Room {
    uint256 betAmount;
    uint256 memberCount;
    uint256 roomStatus;
    string name;
    address winner;
    address creator;
    mapping(address => uint256) members;
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
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

contract BattleGround is Ownable {
    using SafeMath for uint256;

    // BattleGround token address.
    address public tokenAddress = 0x8501198A25d549167E01d10c402f25B750bE0199;
    
     /**
     * @dev Game  wallet for the game rooms.
     * All earnings from game goes here
     */
    address public gameWallet = 0xE71CeC5ea58d011c75d5f57AC1209b1145387837;
    
    address public tempGameWallet = 0xE71CeC5ea58d011c75d5f57AC1209b1145387837;
    
    // Arrays of WeaponPrices
    mapping(uint256 => ItemPrice) public weaponPrices;

    // Arrays of itemPrices
    mapping(uint256 => ItemPrice) public itemPrices;
    
    // Count of the Item Added;
    uint256 public itemCount;

    // Array of player characters
    mapping(address => Character[]) public userCharacters;
    
    // Mapping of player point
    mapping(address => uint256) public userPoint;
    
    // Owner Fee for From pool amount
    uint256 public ownerFee = 300 ; // 30% Fee

    // Sell Fee for assets
    uint256 public sellFee = 300 ; // 30% Fee
    
    // Point buy rate
    uint256 public pointBuyRate = 1000; // 1:1

    // Point sell rate
    uint256 public pointSellRate = 1000; // 1:1
    
    // Max Character Per Player
    uint256 public maxCharacter = 10; // 10 Character per player
    
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

    TBGInterface public TBG = TBGInterface(tokenAddress);
    
    /**
     * @dev Initializes the contract information and setting the deployer as the initial owner.
     */
    constructor() {
        // Mage weapons price init.
        weaponPrices[0].name = "Mage weapons";
        weaponPrices[0].prices = [0, 0, 100, 200, 300];

        // Archer weapons price init.
        weaponPrices[1].name = "Archer weapons";
        weaponPrices[1].prices = [0];

        // Ranger weapons price init.
        weaponPrices[2].name = "Ranger weapons";
        weaponPrices[2].prices = [0];

        // Warrior weapons price init.
        weaponPrices[3].name = "Warrior weapons";
        weaponPrices[3].prices = [0, 0, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100];
        
        itemCount = 4;
        owner = msg.sender;
    }
    
    // Returns player characters information.
    function retrieve() public view returns (Character[] memory) {
        return userCharacters[msg.sender];
    }
    
    // Purchase weapon or item for the player character
    function purchase(uint256 _characterId, uint256 _weaponId) public {
        uint256 price = weaponPrices[userCharacters[msg.sender][_characterId].characterType].prices[_weaponId];
        
        require(userPoint[msg.sender] >= price);
        userPoint[msg.sender] = userPoint[msg.sender].sub(price);
        userCharacters[msg.sender][_characterId].characterWeapons.push(_weaponId);
        userCharacters[msg.sender][_characterId].characterweaponIndex = _weaponId;
    }
    
    // Purchase weapon or item for the player character
    function purchaseItem(uint256 _characterId, uint256 _itemId) public {
        uint256 price = itemPrices[userCharacters[msg.sender][_characterId].characterType].prices[_itemId];
        
        require(userPoint[msg.sender] >= price);
        userPoint[msg.sender] = userPoint[msg.sender].sub(price);
        userCharacters[msg.sender][_characterId].purchasedItems.push(_itemId);
    }
    
    // Add character to player
    function addCharacter(
        string memory _characterName, 
        bool _characterGender, 
        uint256 _characterRace, 
        uint256 _characterType, 
        uint256 _characterLevel, 
        uint256 _characterExp,
        bool _characterCustomized,
        uint256 _characterweaponIndex,
        uint256[] memory _characterWeapons,
        uint256[] memory _characterAttr
    ) public {
        require(userCharacters[msg.sender].length < maxCharacter);
        
        require(
            _characterLevel == 1 && 
            _characterExp == 0 && 
            _characterweaponIndex == 0 && 
            _characterWeapons.length == 1 && 
            _characterWeapons[0] == 0
        );
     
        
        Character memory newCharacter;
        newCharacter.characterName = _characterName;
        newCharacter.characterGender = _characterGender;
        newCharacter.characterRace = _characterRace;
        newCharacter.characterType = _characterType;
        newCharacter.characterLevel = _characterLevel;
        newCharacter.characterExp = _characterExp;
        newCharacter.characterCustomized = _characterCustomized;
        newCharacter.characterweaponIndex = _characterweaponIndex;
        newCharacter.characterWeapons = _characterWeapons;
        newCharacter.characterAttr = _characterAttr;

        userCharacters[msg.sender].push(newCharacter);
    }

    // Remove character from player
    function removeCharacter(uint256 _characterId) public {
        require(userCharacters[msg.sender].length > _characterId);
        Character[] storage characterArray = userCharacters[msg.sender];
        for(uint i = 0; i < userCharacters[msg.sender].length; i++) {
            if(i != _characterId)
                characterArray.push(userCharacters[msg.sender][i]);
        }
        userCharacters[msg.sender] = characterArray;
    }
    
    // Equip purchased weapon
    function equipWeapon(uint256 _characterId, uint256 _weaponId) public {
        require(userCharacters[msg.sender].length > _characterId);
        for(uint i = 0; i < userCharacters[msg.sender][_characterId].characterWeapons.length; i++) {
            if(userCharacters[msg.sender][_characterId].characterWeapons[i] == _weaponId) {
                userCharacters[msg.sender][_characterId].characterweaponIndex = _weaponId;
            }
        }
    }
    
    // Retrieve WeaponPrices
    function retrieveWeaponPrice(uint256 _itemId) public view returns (uint256[] memory) {
        return weaponPrices[_itemId].prices;
    }

    // Purchase point with TBG token
    function purchasePoint(uint256 _tokenAmount) public {
        require(TBG.transferFrom(msg.sender, address(this), _tokenAmount.mul(1e18)));
        
        userPoint[msg.sender] += _tokenAmount.mul(pointBuyRate).div(1000);
    }
    
    // Sell point for TBG Token
    function sellPoint(uint256 _amount) public {
        require(userPoint[msg.sender] >= _amount);
        
        uint256 tokenAmount = _amount.mul(1000).div(pointSellRate).mul(1e18);
        
        require(TBG.transfer(msg.sender, tokenAmount));
        
        userPoint[msg.sender].sub(_amount);
    }
    
    // Retrieve point
    function retrievePoint() public view returns(uint256){
        return userPoint[msg.sender];
    }

    // Retrieve Point Buy / Sell Rate
    function retrievePointRate() public view returns(uint256, uint256) {
        return (pointBuyRate, pointSellRate);        
    }

    // Room functions
    function createRoom(uint256 _pointAmount) public {
        require(userPoint[msg.sender] >= _pointAmount);
        userPoint[msg.sender] = userPoint[msg.sender].sub(_pointAmount);
        userPoint[tempGameWallet] = userPoint[tempGameWallet].add(_pointAmount);

        uint256 id = roomsIds.length; 
        roomsIds.push(id);
        rooms[id].betAmount = _pointAmount;
        rooms[id].memberCount = 1;
        rooms[id].roomStatus = 0;           // Room opened for join.
        rooms[id].creator = msg.sender;
        rooms[id].members[msg.sender] = 1;  // Joined Room
        
        userRooms[msg.sender].push(id); 
        creatorRooms[msg.sender].push(id); 
    }
    
    // Retrieve last created room id.
    function retrieveRoomId() public view returns (uint256) {
        return creatorRooms[msg.sender][creatorRooms[msg.sender].length - 1];
    }

    // Join room with room id
    function joinRoom(uint256 _id) public  {
        require(userPoint[msg.sender] >= rooms[_id].betAmount);

        require(rooms[_id].roomStatus == 0, "Room is not opened.");
        require(rooms[_id].members[msg.sender] != 0, "Already a member");
        userPoint[msg.sender] = userPoint[msg.sender].sub(rooms[_id].betAmount);
        userPoint[tempGameWallet] = userPoint[tempGameWallet].add(rooms[_id].betAmount);
        rooms[_id].memberCount += 1;
        rooms[_id].members[msg.sender] = 1; //Joined Room
        userRooms[msg.sender].push(_id); 
    }
    
    // Start room with room id
    function startRoom(uint256 _id, address[] memory roomMembers) public onlyOwner {
        require(rooms[_id].roomStatus == 0, "Room is not opened.");
        
        for(uint i = 0; i < roomMembers.length; i++) {
            require(rooms[_id].members[roomMembers[i]] == 1);
        }
        
        for(uint i = 0; i < roomMembers.length; i++) {
            rooms[_id].members[roomMembers[i]] = 2;     // Players are in the game room. Points are locked.
        }
        
        rooms[_id].roomStatus = 1;          // Room closed for join. But not finished yet.
     
        poolcollected[_id] = rooms[_id].betAmount.mul(roomMembers.length);
    }
    
    // Finish room with id and winner address   
    function finishRoom(uint256 _id, address _winner) public onlyOwner {
        require(rooms[_id].roomStatus == 1, "Room not closed");

        uint256 _fee = poolcollected[_id].mul(ownerFee).div(1000); 
        uint256 _amt = poolcollected[_id]; 

        if(_fee > 0 ){
            _amt = _amt.sub(_fee); 
        }

        userPoint[gameWallet] = userPoint[gameWallet].add(_fee);
        userPoint[_winner] = userPoint[_winner].add(_amt);
        
        rooms[_id].winner = msg.sender;
        rooms[_id].roomStatus = 2;
        poolcollected[_id] = 0 ;
    }
    
    function claimPoint() public {
        uint256 claimAmount = 0;
        for(uint i = 0;i < userRooms[msg.sender].length; i++) {
            if(rooms[userRooms[msg.sender][i]].members[msg.sender] == 1) {  // 
                claimAmount += rooms[userRooms[msg.sender][i]].betAmount;
                rooms[userRooms[msg.sender][i]].members[msg.sender] = 3;    // Claimed unlocked points.
            }
        }
        
        userPoint[tempGameWallet] = userPoint[tempGameWallet].sub(claimAmount);
        userPoint[msg.sender] = userPoint[msg.sender].add(claimAmount);
    }
    
    // Admin functions
    
    // Update token address for the gameplay
    function updateToken(address _token) public onlyOwner {
        tokenAddress = _token;
        TBG = TBGInterface(_token);
    }
    
    // Update variables for the game
    function updateGameWallet(address _wallet) public onlyOwner {
        gameWallet = _wallet ;
    }

    function updateSellFee(uint256 _fee) public onlyOwner {
        sellFee = _fee ;
    }

    function updateOwnerFee(uint256  _fee) public onlyOwner {
        ownerFee = _fee ;
    }
    
    function updatePointBuyRate(uint256 _rate) public onlyOwner {
        pointBuyRate = _rate;
    }
    
    function updatePointSellRate(uint256 _rate) public onlyOwner {
        pointSellRate = _rate;
    }
    
    function updateWeapons(uint256 _itemId, string memory _newItemName, uint256[] memory _newweaponPrices) public onlyOwner {
        weaponPrices[_itemId].name = _newItemName;
        weaponPrices[_itemId].prices = _newweaponPrices;
    }
    
    function addWeapons(string memory _newItemName, uint256[] memory _newweaponPrices) public onlyOwner {
        weaponPrices[itemCount].name = _newItemName;
        weaponPrices[itemCount].prices = _newweaponPrices;
        itemCount += 1;
    }
    
    function updateMaxCharacter(uint256 _maxCharacter) public onlyOwner {
        maxCharacter  = _maxCharacter;
    }
}