pragma solidity 0.4.25;


contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () public {
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
* @title -Name Filter- v0.1.9
*/
library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.  
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
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
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}


/**
 * Math operations with safety checks
 */
/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

	/**
	* @dev Multiplies two numbers, reverts on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
		// benefit is lost if &#39;b&#39; is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	/**
	* @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); // Solidity only automatically asserts when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

		return c;
	}

	/**
	* @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	/**
	* @dev Adds two numbers, reverts on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}

	/**
	* @dev Divides two numbers and returns the remainder (unsigned integer modulo),
	* reverts when dividing by zero.
	*/
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

contract CelebrityGame is Ownable {
    using SafeMath for *;
    using NameFilter for string;
    
    string constant public gameName = "Celebrity Game";
    
    // fired whenever a card is created
    event LogNewCard(string name, uint256 id);
    // fired whenever a player is registered
    event LogNewPlayer(string name, uint256 id);
    
    //just for isStartEnable modifier
    bool private isStart = false;
    uint256 private roundId = 0;

    struct Card {
        bytes32 name;           // card owner name
        uint256 fame;           // The number of times CARDS were liked
        uint256 fameValue;      // The charge for the current card to be liked once
        uint256 notorious;      // The number of times CARDS were disliked
        uint256 notoriousValue; // The charge for the current card to be disliked once
    }
	
	struct CardForPlayer {
		uint256 likeCount;      // The number of times the player likes it
		uint256 dislikeCount;   // The number of times the player disliked it
	}
	
	struct CardWinner {
	    bytes32  likeWinner;
		bytes32  dislikeWinner;
	}
	
	Card[] public cards;
	bytes32[] public players;
	
    mapping (uint256 => mapping (uint256 => mapping ( uint256 => CardForPlayer))) public playerCard;      // returns cards of this player like or dislike by playerId and roundId and cardId
    mapping (uint256 => mapping (uint256 => CardWinner)) public cardWinnerMap; // (roundId => (cardId => winner)) returns winner by roundId and cardId
    mapping (uint256 => Card[]) public rounCardMap;                            // returns Card info by roundId
    
    mapping (bytes32 => uint256) private plyNameXId;                           // (playerName => Id) returns playerId by playerName
	mapping (bytes32 => uint256) private cardNameXId;                          // (cardName => Id) returns cardId by cardName
    mapping (bytes32 => bool) private cardIsReg;                               // (cardName => cardCount) returns cardCount by cardName，just for createCard function
    mapping (bytes32 => bool) private playerIsReg;                             // (playerName => isRegister) returns registerInfo by playerName, just for registerPlayer funciton
    mapping (uint256 => bool) private cardIdIsReg;                             // (cardId => card info) returns card info by cardId
	mapping (uint256 => bool) private playerIdIsReg;                           // (playerId => id) returns player index of players by playerId
    
    /**
	 * @dev used to make sure no one can interact with contract until it has been started
	 */
    modifier isStartEnable {
        require(isStart == true);
        _;
    }

    /**
	 * @dev use this function to create card.
	 * - must pay some create fees.
	 * - name must be unique
	 * - max length of 32 characters long
	 * @param _nameString owner desired name for card
	 * @param _id card id
	 * (this might cost a lot of gas)
	 */
    function createCard(string _nameString, uint256 _id) public onlyOwner() {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")));
        
        bytes32 _name = _nameString.nameFilter();
        require(cardIsReg[_name] == false);
        cards.push(Card(_name, 50, 100, 50, 100));
        cardNameXId[_name] = _id;
        cardIsReg[_name] = true;
        cardIdIsReg[_id] = true;
        emit LogNewCard(_nameString, _id);
    }
    
    /**
	 * @dev use this function to register player.
	 * - must pay some register fees.
	 * - name must be unique 
	 * - name cannot be null
	 * - max length of 32 characters long
	 * @param _nameString team desired name for player
	 * @param _id player id
	 * (this might cost a lot of gas)
	 * (tips: The player&#39;s name can be registered multiple times, but the id can only be unique to ensure the integrity of the data)
	 */
    function registerPlayer(string _nameString, uint256 _id)  external {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")));
        
        bytes32 _name = _nameString.nameFilter();
		require(playerIsReg[_name] == false);
		players.push(_name);
		plyNameXId[_name] = _id;
		playerIsReg[_name] = true;
		playerIdIsReg[_id] = true;
		
        emit LogNewPlayer(_nameString, _id);
	}

    /**
	 * @dev this function for One player likes the CARD once.
	 * @param _cardId must be returned when creating CARD
	 * @param _playerId must be returned when registering player
	 * (this might cost a lot of gas)
	 */
    function likeCelebrity(uint256 _cardId, uint256 _playerId) external isStartEnable {
		require(cardIdIsReg[_cardId] == true, "sorry create this card first");
		require(playerIdIsReg[_playerId] == true, "sorry register the player name first");
		
        Card storage queryCard = cards[_cardId];
        queryCard.fame = queryCard.fame.add(1);
        queryCard.fameValue = queryCard.fameValue.add(queryCard.fameValue / 100);
        
        playerCard[_playerId][roundId][_cardId].likeCount == (playerCard[_playerId][roundId][_cardId].likeCount).add(1);
        cardWinnerMap[roundId][_cardId].likeWinner = players[_playerId];
    }

    /**
	 * @dev this function for One player dislikes the CARD once.
	 * @param _cardId must be returned when creating CARD
	 * @param _playerId must be created when registering player
	 * (this might cost a lot of gas)
	 */
    function dislikeCelebrity(uint256 _cardId, uint256 _playerId) external isStartEnable {
		require(cardIdIsReg[_cardId] == true, "sorry create this card first");
		require(playerIdIsReg[_playerId] == true, "sorry register the player name first");
		
        Card storage queryCard = cards[_cardId];
        queryCard.notorious = queryCard.notorious.add(1);
        queryCard.notoriousValue = queryCard.notoriousValue.add(queryCard.notoriousValue / 100);
        
        playerCard[_playerId][roundId][_cardId].dislikeCount == (playerCard[_playerId][roundId][_cardId].dislikeCount).add(1);
        cardWinnerMap[roundId][_cardId].dislikeWinner = players[_playerId];
    }
    
    /**
	 * @dev use this function to reset card properties.
	 * - must be called when game is not started by team.
	 * @param _id must be returned when creating CARD
	 * (this might cost a lot of gas)
	 */
    function reset(uint256 _id) external onlyOwner() {
        require(isStart == false);

        Card storage queryCard = cards[_id];
        queryCard.fame = 50;
        queryCard.fameValue = 100;
        queryCard.notorious = 50;
        queryCard.notoriousValue = 100;
    }
    
    /**
	 * @dev use this function to start the game.
	 * - must be called by owner.
	 * (this might cost a lot of gas)
	 */
    function gameStart() external onlyOwner() {
        isStart = true;
        roundId = roundId.add(1);
    }
    
    /**
	 * @dev use this function to end the game. Just for emergency control by owner
	 * (this might cost a lot of gas)
	 */
    function gameEnd() external onlyOwner() {
        isStart = false;
        rounCardMap[roundId] = cards;
        for (uint i = 0; i < cards.length; i++) {
            Card storage queryCard = cards[i];
            queryCard.fame = 50;
            queryCard.fameValue = 100;
            queryCard.notorious = 50;
            queryCard.notoriousValue = 100;
        }
    }
    
    /**
	 * @dev use this function to get CARDS count
	 * @return Total all CARDS in the current game
	 */
    function getCardsCount() public view returns(uint256) {
        return cards.length;
    }
    
    /**
	 * @dev use this function to get CARDS id by its name.
	 * @param _nameString must be created when creating CARD
	 * @return the card id
	 */
    function getCardId(string _nameString) public view returns(uint256) {
        bytes32 _name = _nameString.nameFilter();
        require(cardIsReg[_name] == true, "sorry create this card first");
        return cardNameXId[_name];
    }
    
    /**
	 * @dev use this function to get player id by the name.
	 * @param _nameString must be created when creating CARD 
	 * @return the player id
	 */
    function getPlayerId(string _nameString) public view returns(uint256) {
        bytes32 _name = _nameString.nameFilter();
        require(playerIsReg[_name] == true, "sorry register the player name first");
        return plyNameXId[_name];
    }
    
    /**
	 * @dev use this function to get player bet count.
	 * @param _playerName must be created when registering player
	 * @param _roundId must be a game that has already started
	 * @param _cardName the player id must be created when creating CARD
	 * @return likeCount 
	 * @return dislikeCount
	 */
    function getPlayerBetCount(string _playerName, uint256 _roundId, string _cardName) public view returns(uint256 likeCount, uint256 dislikeCount) {
        bytes32 _cardNameByte = _cardName.nameFilter();
        require(cardIsReg[_cardNameByte] == false);

        bytes32 _playerNameByte = _playerName.nameFilter();
		require(playerIsReg[_playerNameByte] == false);
        return (playerCard[plyNameXId[_playerNameByte]][_roundId][cardNameXId[_cardNameByte]].likeCount, playerCard[plyNameXId[_playerNameByte]][_roundId][cardNameXId[_cardNameByte]].dislikeCount);
    }
}