pragma solidity 0.8.7;

interface ERC20Like {
    function burn(address from, uint256 amount) external;
}

interface EtherOrcLike {
    function ownerOf(uint256 id) external view returns (address owner_);
    function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
}


contract HallOfChampions {

    address        implementation_;
    address public admin; //Lame requirement from opensea

    ERC20Like    public zug;
    EtherOrcLike public etherOrcs;
    
    uint256 public namingCost; 

	// Name Storage Slots - Not the most efficient way to store it, but it works well enough
	mapping (uint256 => string)  private _firstNames;
	mapping (uint256 => string)  private _lastNames;
	mapping (uint256 => uint256) public  joined;

	// Tribute Storage Slots
    mapping (uint256 => uint256) public tributes;
	mapping (uint256 => uint256) public timeAtTop;
	mapping (uint256 => uint256) public topEnterTime;
	mapping (uint256 => bool)    public isTopFive;

	// Arrays for easy retrieval
    uint256[]  champions;
    uint256[5] topFive;

    uint256 lowestIndex;

	constructor(address zug_, address etherOrcs_) {
		admin = msg.sender;
		zug = ERC20Like(zug_);
		etherOrcs = EtherOrcLike(etherOrcs_);
	}


	/*///////////////////////////////////////////////////////////////
                    VIEW FUNCTIONS 
    //////////////////////////////////////////////////////////////*/
 
	function getName(uint256 orcId) public view returns(string memory){
		// If not joined, return the boring name
		if (joined[orcId] == 0) return string(abi.encodePacked("Orc #", _toString(orcId)));

		// If Orc has only a fisrt name 
		if (bytes(_firstNames[orcId]).length > 0 && bytes(_lastNames[orcId]).length == 0) 
			return _firstNames[orcId];
		
		// Ir Orc has only a last name
		if (bytes(_firstNames[orcId]).length == 0 && bytes(_lastNames[orcId]).length > 0) 
			return _lastNames[orcId];

		return string(abi.encodePacked(_firstNames[orcId], " ", _lastNames[orcId]));
	}

	function getChampions() external view returns (uint256[] memory ids, uint256[] memory timeSinceJoined, string[] memory names) {
		ids = champions;
		timeSinceJoined = new uint256[](ids.length);
		names           = new string[](ids.length);

		for (uint256 i = 0; i < ids.length; i++) {
			timeSinceJoined[i] = block.timestamp - joined[ids[i]];
			names[i]            = getName(ids[i]);
		}

	}

    function getAllChampions() external view returns(uint256[] memory) {
        return champions;
    }

	function getTopFive() external view returns(uint256[5] memory) {
		return topFive;
	}

	function timeAsChampion(uint256 id) external view returns(uint256 timeInSeconds) {
		return timeAtTop[id] + (isTopFive[id] ? block.timestamp - topEnterTime[id] : 0);
	}

	/*///////////////////////////////////////////////////////////////
                    ADMIN FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

	function setNamingCost(uint256 newCost) external {
		require(msg.sender == admin);
		namingCost = newCost;
	}

	/*///////////////////////////////////////////////////////////////
                    STATE CHANGING FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    function changeName(uint256 orcId, string memory firstName_, string memory lastName_) public {
        require(orcId > 0 && orcId <= 5050, "invalid id");
        (address owner, ,) = etherOrcs.activities(orcId);
		require(msg.sender == owner || msg.sender == etherOrcs.ownerOf(orcId), "Not the orc owner");

		uint256 firstLength = bytes(firstName_).length;
		uint256 lastLength  = bytes(lastName_).length;

		require(firstLength > 0  || lastLength > 0,            "Both names empty");
		require(firstLength == 0 || validateName(firstName_), "Not a valid first name");
		require(lastLength  == 0 || validateName(lastName_),  "Not a valid last name");
		
        zug.burn(msg.sender, namingCost * 1 ether);

        if (joined[orcId] == 0) {
            champions.push(orcId);
			joined[orcId] = block.timestamp;
        }

        if (firstLength > 0) _firstNames[orcId] = firstName_;
		if (lastLength > 0)  _lastNames[orcId]  = lastName_;
	}

    function payTribute(uint256 orcId, uint256 amount) public {
		require(orcId > 0 && orcId <= 5050, "invalid id");
		require(joined[orcId] > 0, "Can't pay tribute to unnamed orc");
        zug.burn(msg.sender, amount * 1 ether);

        uint256 totalTribute = tributes[orcId] + amount;

        // Update Storage
        tributes[orcId] = totalTribute;

        uint256 currentLower = topFive[lowestIndex];

        // This id will enter top 5
        if (totalTribute > currentLower && !isTopFive[orcId]) {
            // Replacing old orc
			uint256 replacedOrc = topFive[lowestIndex];
			isTopFive[replacedOrc] = false;
			timeAtTop[replacedOrc] += block.timestamp - topEnterTime[replacedOrc];
			topEnterTime[replacedOrc] = 0;  

			// Putting new orc on top
            topFive[lowestIndex] = orcId;
			isTopFive[orcId]     = true;
			topEnterTime[orcId] =  block.timestamp;
        }
		_updateLowestIndex();
    }


	/*///////////////////////////////////////////////////////////////
                    INTERNAL HELPERS 
    //////////////////////////////////////////////////////////////*/

	function _updateLowestIndex() internal {
		uint256 lowestTribute = type(uint256).max;
		uint256 lowestI       = 0;

		for (uint256 index = 0; index < topFive.length; index++) {
			uint256 trib = tributes[topFive[index]];
			if (trib < lowestTribute) {
				lowestTribute = trib;
				lowestI = index;
			}
		}
		lowestIndex = lowestI;
	}

	// Helper function inspired by CyberKongz!
    function validateName(string memory str) public pure returns (bool){
		bytes memory b = bytes(str);
		if(b.length < 1) return false;
		if(b.length > 10) return false; // Cannot be longer than 10 characters
		if(b[0] == 0x20) return false; // Leading space
		if (b[b.length - 1] == 0x20) return false; // Trailing space

		for(uint i; i<b.length; i++){
			bytes1 char = b[i];
			if(
				!(char >= 0x30 && char <= 0x39) && //9-0
				!(char >= 0x41 && char <= 0x5A) && //A-Z
				!(char >= 0x61 && char <= 0x7A)    //a-z
			)
				return false;
		}

		return true;
	}

	function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}