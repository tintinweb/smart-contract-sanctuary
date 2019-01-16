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
    
    string constant public gameName = "Celebrity Game";
    
    // fired whenever a card is created
    event LogNewCard(string name, uint256 id);
    // fired whenever a player is registered
    event LogNewPlayer(string name, uint256 id);
    
    //just for isStartEnable modifier
    bool private isStart = false;
    uint256 private roundId = 0;

    struct Card {
        string  name;           // card owner name
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
	    string  likeWinner;
		string  dislikeWinner;
	}
	
	Card[] public cards;
	string[] public players;
	
	mapping (bytes32 => uint256) public plyNameXId;                            // (playerName => Id) returns playerId by playerName
	mapping (bytes32 => uint256) public cardNameXId;                           // (cardName => Id) returns cardId by cardName
	
    mapping (uint256 => mapping (uint256 => mapping ( uint256 => CardForPlayer))) public playerCard;      // returns cards of this player like or dislike by player id and roundId
    mapping (uint256 => mapping (uint256 => CardWinner)) public cardWinnerMap; // (roundId => (cardId => winner)) returns winner by cardId and roundId
    mapping (uint256 => Card[]) public rounCardMap;                            // returns Card info by roundId
    mapping (bytes32 => uint256) private ownerCardCount;                       // (cardName => cardCount) returns cardCount by cardName，just for createCard function
    mapping (bytes32 => bool) private playerIsReg;                             // (playerName => isRegister) returns registerInfo by playerName, just for registerPlayer funciton
    
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
	 * @param _name owner desired name for card
	 * @return card id
	 * (this might cost a lot of gas)
	 */
    function createCard(string _name) public onlyOwner() returns(uint256) {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")));
        bytes32 nameByte = convert(_name);
        require(ownerCardCount[nameByte] == 0);
        uint256 id = uint256(cards.push(Card(_name, 50, 100, 50, 100)) - 1);
        cardNameXId[nameByte] = id;
        ownerCardCount[nameByte].add(1);
        emit LogNewCard(_name, id);
        return id;
    }
    
    /**
	 * @dev use this function to register player.
	 * - must pay some register fees.
	 * - name must be unique 
	 * - name cannot be null
	 * - max length of 32 characters long
	 * @param _nameString team desired name for player
	 * @return player id
	 * (this might cost a lot of gas)
	 */
    function registerPlayer(string _nameString)  external returns(uint256) {
        require(
			msg.sender == 0x292e41ab6375e693D9df566aBb708466aa109ad2 ||
			msg.sender == 0x21E0655aB21A851D17387D8a08F2Dd6c58ae9108 ||
			msg.sender == 0x2303aC651F1fA8B9116072Da7E9008BCB8a632a2 ||
			msg.sender == 0x6Ea67820A81287B2577D7006e6F6bA69502De994 ||
			msg.sender == 0x1B64518fCC0e0cf88Bd946a5AC747dac0c624641,
			"only team just can registerPlayer"
		);
        require(keccak256(abi.encodePacked(_nameString)) != keccak256(abi.encodePacked("")));
		bytes32 _name = convert(_nameString);
		require(playerIsReg[_name] == false);
		uint256 id = uint256(players.push(_nameString) - 1);
		playerIsReg[_name] = true;
		plyNameXId[_name] = id;
        emit LogNewPlayer(_nameString, id);
        return id;
	}

    /**
	 * @dev this function for One player likes the CARD once.
	 * @param _cardId must be returned when creating CARD
	 * @param _playerId must be returned when registering player
	 * (this might cost a lot of gas)
	 */
    function likeCelebrity(uint256 _cardId, uint256 _playerId) external isStartEnable {
        // only team just can likeCelebrity
		require(
			msg.sender == 0x292e41ab6375e693D9df566aBb708466aa109ad2 ||
			msg.sender == 0x21E0655aB21A851D17387D8a08F2Dd6c58ae9108 ||
			msg.sender == 0x2303aC651F1fA8B9116072Da7E9008BCB8a632a2 ||
			msg.sender == 0x6Ea67820A81287B2577D7006e6F6bA69502De994 ||
			msg.sender == 0x1B64518fCC0e0cf88Bd946a5AC747dac0c624641,
			"only team just can likeCelebrity"
		);
        Card storage queryCard = cards[_cardId];
        queryCard.fame = queryCard.fame.add(1);
        queryCard.fameValue = queryCard.fameValue.add(100);
        
        playerCard[_playerId][roundId][_cardId].likeCount == (playerCard[_playerId][roundId][_cardId].likeCount).add(1);
        cardWinnerMap[roundId][_cardId].likeWinner = players[_playerId];
    }

    /**
	 * @dev this function for One player dislikes the CARD once.
	 * @param _cardId must be returned when creating CARD
	 * @param _playerId must be returned when registering player
	 * (this might cost a lot of gas)
	 */
    function dislikeCelebrity(uint256 _cardId, uint256 _playerId) external isStartEnable {
        // only team just can disLikeCelebrity
		require(
			msg.sender == 0x292e41ab6375e693D9df566aBb708466aa109ad2 ||
			msg.sender == 0x21E0655aB21A851D17387D8a08F2Dd6c58ae9108 ||
			msg.sender == 0x2303aC651F1fA8B9116072Da7E9008BCB8a632a2 ||
			msg.sender == 0x6Ea67820A81287B2577D7006e6F6bA69502De994 ||
			msg.sender == 0x1B64518fCC0e0cf88Bd946a5AC747dac0c624641,
			"only team just can disLikeCelebrity"
		);
        Card storage queryCard = cards[_cardId];
        queryCard.notorious = queryCard.notorious.add(1);
        queryCard.notoriousValue = queryCard.notoriousValue.add(100);
        
        playerCard[_playerId][roundId][_cardId].dislikeCount == (playerCard[_playerId][roundId][_cardId].dislikeCount).add(1);
        cardWinnerMap[roundId][_cardId].dislikeWinner = players[_playerId];
    }
    
    /**
	 * @dev use this function to reset card properties.
	 * - must be called when game is not started by team.
	 * @param _id must be returned when creating CARD
	 * (this might cost a lot of gas)
	 */
    function reset(uint256 _id) external {
        require(isStart == false);
		require(
			msg.sender == 0x292e41ab6375e693D9df566aBb708466aa109ad2 ||
			msg.sender == 0x21E0655aB21A851D17387D8a08F2Dd6c58ae9108 ||
			msg.sender == 0x2303aC651F1fA8B9116072Da7E9008BCB8a632a2 ||
			msg.sender == 0x6Ea67820A81287B2577D7006e6F6bA69502De994 ||
			msg.sender == 0x1B64518fCC0e0cf88Bd946a5AC747dac0c624641,
			"only team just can reset"
		);
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
	 * @return the card id
	 */
    function getCardId(string _nameString) public view returns(uint256) {
        bytes32 _name = convert(_nameString);
        return cardNameXId[_name];
    }
    
    /**
	 * @dev use this function to get player id by the name.
	 * @return the player id
	 */
    function getPlayerId(string _nameString) public view returns(uint256) {
        bytes32 _name = convert(_nameString);
        return plyNameXId[_name];
    }
    
    /**
	 * @dev convert the string to bytes32 
	 * -makes sure it does not start/end with a space
	 * -restricts characters to A-Z, a-z, 0-9, and space
	 * -max length of 32 characters long
	 * @return reprocessed string in bytes32 format
	 */
	function convert(string _key) pure private returns (bytes32 ret) {
	    bytes memory _temp = bytes(_key);
	    uint256 _length = _temp.length;
		require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
		
		assembly {
			ret := mload(add(_temp, 32))
		}
	}

}