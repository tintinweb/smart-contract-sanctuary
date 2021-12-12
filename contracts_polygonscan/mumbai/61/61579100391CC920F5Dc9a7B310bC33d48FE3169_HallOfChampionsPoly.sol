/**
 *Submitted for verification at polygonscan.com on 2021-12-11
*/

/** 
 *  SourceUnit: /home/jgcarv/Dev/NFT/Orcs/etherOrcs-contracts/src/polygon/HallOfChampionsPoly.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: Unlicense
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


/** 
 *  SourceUnit: /home/jgcarv/Dev/NFT/Orcs/etherOrcs-contracts/src/polygon/HallOfChampionsPoly.sol
*/

pragma solidity 0.8.7;

////import "../interfaces/Interfaces.sol";

contract HallOfChampionsPoly {

    address        implementation_;
    address public admin; 
    address public updater;
        
	// Name Storage Slots - Not the most efficient way to store it, but it works well enough
	mapping (uint256 => string)  private _firstNames;
	mapping (uint256 => string)  private _lastNames;
	mapping (uint256 => uint256) public  joined;


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

	/*///////////////////////////////////////////////////////////////
                    ADMIN FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    function updateName(uint256 orcId, string calldata firstName_, string memory lastName_, uint256 joined_) public {
        require(msg.sender == updater);
        _firstNames[orcId] = firstName_;
		_lastNames[orcId]  = lastName_;
        joined[orcId]      = joined_;
    }

    function updateNames(uint256[] calldata ids, string[] calldata fNames_, string[] calldata lNames_, uint256[] calldata joined_) external {
        require(msg.sender == updater);
        for (uint256 i = 0; i < ids.length; i++) {
            updateName(ids[i], fNames_[i], lNames_[i], joined_[i]);
        }
    }

    function setUpdater(address up_) external {
        require(msg.sender == admin);
        updater = up_;
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