pragma solidity ^ 0.4.24; 

/***
 *     __   __   ___      ___    ___   
 *     \ \ / /  / _ \    | _ \  / _ \  
 *      \ V /  | (_) |   |  _/ | (_) | 
 *      _|_|_   \___/   _|_|_   \___/  
 *    _| """ |_|"""""|_| """ |_|"""""| 
 *    "`-0-0-&#39;"`-0-0-&#39;"`-0-0-&#39;"`-0-0-&#39; 
 *   
 */

interface IGameBuilder{
    function buildGame (address _manager, string _name, string _title, uint256 _price, uint256 _timespan,
        uint8 _profitOfManager, uint8 _profitOfFirstPlayer, uint8 _profitOfWinner) payable external returns(address);
} 
contract IGame {
     
    address public owner; 
    address public creator;
    address public manager;
	uint256 public poolValue = 0;
	uint256 public round = 0;
	uint256 public totalBets = 0;
	uint256 public startTime = now;
    bytes32 public name;
    string public title;
	uint256 public price;
	uint256 public timespan;
	uint32 public gameType;

    /* profit divisions */
	uint256 public profitOfSociety = 5;  
	uint256 public profitOfManager = 1; 
	uint256 public profitOfFirstPlayer = 15;
	uint256 public profitOfWinner = 40;
	
	function getGame() view public returns(
        address, uint256, address, uint256, 
        uint256, uint256, uint256, 
        uint256, uint256, uint256, uint256);
} 
/***
 *       ___     ___      _    
 *      /   \   |_  )    / |   
 *      | - |    / /     | |   
 *      |_|_|   /___|   _|_|_  
 *    _|"""""|_|"""""|_|"""""| 
 *    "`-0-0-&#39;"`-0-0-&#39;"`-0-0-&#39; 
 */
contract Owned {
    modifier isActivated {
        require(activated == true, "its not ready yet."); 
        _;
    }
    
    modifier isHuman {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
 
    modifier limits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }
 
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    address public owner;
	bool public activated = true;

    constructor() public{
        owner = msg.sender;
    }

	function terminate() public onlyOwner {
		selfdestruct(owner);
	}

	function setIsActivated(bool _activated) public onlyOwner {
		activated = _activated;
	}
} 
 
/**
 * @title NameFilter
 * @dev filter string
 */
library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.  
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x 
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 || 
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}



contract GameFactory is Owned {
	uint256 private constant MINIMUM_PRICE = 0.01 ether;
	uint256 private constant MAXIMUM_PRICE = 100 ether;
	uint256 private constant MINIMUM_TIMESPAN = 1 minutes;  
	uint256 private constant MAXIMUM_TIMESPAN = 24 hours;  

    using NameFilter for string;
	mapping(bytes32 => address) public games; 
	mapping(uint256 => address) public builders; 
    bytes32[] public names;
    address[] public addresses;
    address[] public approved;
    address[] public offlines;
    uint256 public fee = 0.2 ether;
    uint8 public numberOfEarlybirds = 10;
    uint256 public numberOfGames = 0;

    event onNewGame (address sender, bytes32 gameName, address gameAddress, uint256 fee, uint256 timestamp);

    function newGame (address _manager, string _name, string _title, uint256 _price, uint256 _timespan,
        uint8 _profitOfManager, uint8 _profitOfFirstPlayer, uint8 _profitOfWinner, uint256 _gameType) 
        limits(msg.value) isActivated payable public 
    {
		require(address(_manager)!=0x0, "invaild address");
		require(_price >= MINIMUM_PRICE && _price <= MAXIMUM_PRICE, "price not in range (MINIMUM_PRICE, MAXIMUM_PRICE)");
		require(_timespan >= MINIMUM_TIMESPAN && _timespan <= MAXIMUM_TIMESPAN, "timespan not in range(MINIMUM_TIMESPAN, MAXIMUM_TIMESPAN)");
		bytes32 name = _name.nameFilter();
        require(name[0] != 0, "invaild name");
        require(checkName(name), "duplicate name");
        require(_profitOfManager <=20, "[profitOfManager] don&#39;t take too much commission :)");
        require(_profitOfFirstPlayer <=50, "[profitOfFirstPlayer] don&#39;t take too much commission :)");
        require(_profitOfWinner <=100 && (_profitOfManager + _profitOfWinner + _profitOfFirstPlayer) <=100, "[profitOfWinner] don&#39;t take too much commission :)");
        require(msg.value >= getTicketPrice(_profitOfManager), "fee is not enough");

        address builderAddress = builders[_gameType];
		require(address(builderAddress)!=0x0, "invaild game type");
        
        IGameBuilder builder = IGameBuilder(builderAddress);
        address game = builder.buildGame(_manager, _name, _title, _price, _timespan, _profitOfManager, _profitOfFirstPlayer, _profitOfWinner);
        games[name] = game; 
        names.push(name);
        addresses.push(game);
        numberOfGames ++;
        owner.transfer(msg.value); 

        if(numberOfGames > numberOfEarlybirds){
            // plus 10% fee everytime    
            // might overflow? I wish as well, however, at that time no one can afford the fee.
            fee +=  (fee/10);        
        }

        emit onNewGame(msg.sender, name, game, fee, now);
    } 

    function checkName(bytes32 _name) view public returns(bool){
        return address(games[_name]) == 0x0;
    }

	function addGame(address _addr) public payable onlyOwner {
	    IGame game = IGame(_addr);  
        require(checkName(game.name()), "duplicate name");
        
	    games[game.name()] = _addr;
        names.push(game.name());
	    addresses.push(_addr);
        approved.push(_addr);
        numberOfGames ++;
	}
	
	function addBuilder(uint256 _gameType, address _builderAddress) public payable onlyOwner {
        builders[_gameType] = _builderAddress;
	}
	
	function approveGame(address _addr) public payable onlyOwner {
        approved.push(_addr);
	}
	
	function offlineGame(address _addr) public payable onlyOwner {
        offlines.push(_addr);
	}
	
	function setFee(uint256 _fee) public payable onlyOwner {
        fee = _fee;
	}

    function getTicketPrice(uint8 _profitOfManager) view public returns(uint256){
        // might overflow? I wish as well, however, at that time no one can afford the fee.
        return fee * _profitOfManager; 
    }

    function getNames() view public returns(bytes32[]){
        return names;
    }

    function getAddresses() view public returns(address[]){
        return addresses;
    }

    function getGame(bytes32 _name) view public returns(
        address, uint256, address, uint256, 
        uint256, uint256, uint256, 
        uint256, uint256, uint256, uint256) {
        require(!checkName(_name), "name not found!");
        address gameAddress = games[_name];
        IGame game = IGame(gameAddress);  
        return game.getGame();
    }

	function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
	}
}