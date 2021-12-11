// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/Interfaces.sol";

contract HallOfChampions {

    address        implementation_;
    address public admin; 
    
    ERC20Like     public zug;
    EtherOrcsLike public etherOrcs;
    
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

	function getChampions() external view returns (uint256[] memory ids, uint256[] memory timeSinceJoined, string[] memory names, uint256[] memory tributePaid) {
		ids = champions;
		timeSinceJoined = new uint256[](ids.length);
		names           = new string[](ids.length);
		tributePaid     = new uint256[](ids.length);

		for (uint256 i = 0; i < ids.length; i++) {
		    tributePaid[i]     = tributes[ids[i]];
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

	function setAddresses(address orcs_, address zug_) external {
		require(msg.sender == admin);
		etherOrcs = EtherOrcsLike(orcs_);
		zug       = ERC20Like(zug_);
	}

	function overrideName(uint256 orcId, string calldata newFirstName, string calldata newLastName) external {
		require(msg.sender == admin);
		_firstNames[orcId] = newFirstName;
		_lastNames[orcId]  = newLastName;
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

         _firstNames[orcId] = firstName_;
		 _lastNames[orcId]  = lastName_;
	}

    function payTribute(uint256 orcId, uint256 amount) public {
		require(orcId > 0 && orcId <= 5050, "invalid id");
		require(joined[orcId] > 0, "Can't pay tribute to unnamed orc");
        zug.burn(msg.sender, amount * 1 ether);

        uint256 totalTribute = tributes[orcId] + amount;

        // Update Storage
        tributes[orcId] = totalTribute;

        uint256 currentLower = tributes[topFive[lowestIndex]];

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


contract HallOfChampionsFix {

	address        implementation_;
    address  admin; 
    
    ERC20Like    zug;
    EtherOrcsLike etherOrcs;
    
    uint256 namingCost; 

	// Name Storage Slots - Not the most efficient way to store it, but it works well enough
	mapping (uint256 => string)  private _firstNames;
	mapping (uint256 => string)  private _lastNames;
	mapping (uint256 => uint256)  joined;

	// Tribute Storage Slots
    mapping (uint256 => uint256) tributes;
	mapping (uint256 => uint256) timeAtTop;
	mapping (uint256 => uint256) topEnterTime;
	mapping (uint256 => bool)    isTopFive;

	// Arrays for easy retrieval
    uint256[]  champions;
    uint256[5] topFive;

    uint256 lowestIndex;

	function fix() external {
		require(msg.sender == admin);

		topFive = [381,716,4,3,1532];
		_updateLowestIndex();
		implementation_ = 0x859a5b6B90a4D5CB433f61593C59f1c5Edc01977;
	}

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
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface OrcishLike {
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustOrc(uint256 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress) external;
    function transfer(address to, uint256 tokenId) external;
    function orcs(uint256 id) external view returns(uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
    function allies(uint256 id) external view returns (uint8 class, uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, bytes22 details);
    function adjustAlly(uint256 id, uint8 class_, uint16 level_, uint32 lvlProgress_, uint16 modF_, uint8 skillCredits_, bytes22 details_) external;
}

interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface OracleLike {
    function seedFor(uint256 blc) external view returns(bytes32 hs);
}

interface MetadataHandlerLike {
    function getTokenURI(uint16 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier) external view returns (string memory);
}

interface RaidsLike {
    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_) external;
    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_) external;
    function commanders(uint256 id) external returns(address);
    function unstake(uint256 id) external;
}

interface RaidsLikePoly {
    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_, uint256[] calldata potions_) external;
    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_,  uint256[] calldata potions_) external;
    function commanders(uint256 id) external returns(address);
    function unstake(uint256 id) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface EtherOrcsLike {
    function ownerOf(uint256 id) external view returns (address owner_);
    function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
    function orcs(uint256 orcId) external view returns (uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
}

interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function mint(address to, uint256 id, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface HallOfChampionsLike {
    function joined(uint256 orcId) external view returns (uint256 joinDate);
} 

interface AlliesLike {
    function allies(uint256 id) external view returns (uint8 class, uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, bytes22 details);
}