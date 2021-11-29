//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./FantasyThings.sol";

//This contract manages/stores the attributes tied to the ERC721 character tokens
//Maybe this goes straight into the ERC721 itself
contract FantasyAttributesManager {

	IERC721Metadata public s_fantasyCharacters;
	address immutable public s_fantasyCharactersAddress;

	mapping(uint256 => FantasyThings.CharacterAttributes) public s_CharacterAttributes; //tokenID to character attributes
	mapping(FantasyThings.CharacterClass => FantasyThings.CharacterAttributes) public s_StartingAttributes;

	constructor(address _fantasyCharacters) {
		s_fantasyCharacters = IERC721Metadata(_fantasyCharacters);
		s_fantasyCharactersAddress = _fantasyCharacters;

		//Create Starting Character Templates
		FantasyThings.Ability[] memory knightAbilities = new FantasyThings.Ability[](1);
		knightAbilities[0] = FantasyThings.Ability(FantasyThings.AbilityType.Strength,1,"Strike");
		_setStartingCharacter(100, [20,30,25,15,0,5,0], FantasyThings.CharacterClass.Knight, knightAbilities);

		FantasyThings.Ability[] memory warlordAbilities = new FantasyThings.Ability[](1);
		warlordAbilities[0] = FantasyThings.Ability(FantasyThings.AbilityType.Strength,1, "Strike");
		_setStartingCharacter(100, [30,20,20,20,0,5,0], FantasyThings.CharacterClass.Warlord, warlordAbilities);

		FantasyThings.Ability[] memory wizardAbilities = new FantasyThings.Ability[](1);
		wizardAbilities[0] = FantasyThings.Ability(FantasyThings.AbilityType.Spellpower, 1,"Fireball");
		_setStartingCharacter(90, [5,10,5,5,30,20,0], FantasyThings.CharacterClass.Wizard, wizardAbilities);

		FantasyThings.Ability[] memory shamanAbilities = new FantasyThings.Ability[](2);
		shamanAbilities[0] = FantasyThings.Ability(FantasyThings.AbilityType.Spellpower,1,"Lightning Bolt");
		shamanAbilities[1] = FantasyThings.Ability(FantasyThings.AbilityType.HealingPower,2,"Nature Heal");
		_setStartingCharacter(110, [10,15,10,10,20,15,10], FantasyThings.CharacterClass.Shaman, shamanAbilities);

		FantasyThings.Ability[] memory clericAbilities = new FantasyThings.Ability[](2);
		clericAbilities[0] = FantasyThings.Ability(FantasyThings.AbilityType.Spellpower,1,"Smite");
		clericAbilities[1] = FantasyThings.Ability(FantasyThings.AbilityType.HealingPower,2,"Angel's Blessing");
		_setStartingCharacter(120, [5,10,5,5,10,30,30],FantasyThings.CharacterClass.Cleric, clericAbilities);

		FantasyThings.Ability[] memory rogueAbilities = new FantasyThings.Ability[](1);
		rogueAbilities[0] = FantasyThings.Ability(FantasyThings.AbilityType.Agility,1,"Stab");
		_setStartingCharacter(100, [15,15,15,30,0,5,0], FantasyThings.CharacterClass.Rogue, rogueAbilities);

		FantasyThings.Ability[] memory rangerAbilities = new FantasyThings.Ability[](1);
		rangerAbilities[0] = FantasyThings.Ability(FantasyThings.AbilityType.Agility,1,"Fire Bow");
		_setStartingCharacter(100, [10,15,10,35,0,5,0], FantasyThings.CharacterClass.Ranger, rangerAbilities);

		FantasyThings.Ability[] memory warlockAbilities = new FantasyThings.Ability[](1);
		rangerAbilities[0] = FantasyThings.Ability(FantasyThings.AbilityType.Agility,1,"Shadow Bolt");
		_setStartingCharacter(90, [5,10,5,5,30,20,0], FantasyThings.CharacterClass.Warlock, warlockAbilities);
	}

	function _setStartingCharacter(uint16 _health, uint8[7] memory _stats, FantasyThings.CharacterClass _charClass, FantasyThings.Ability[] memory _abilities) internal {
		FantasyThings.CharacterAttributes storage character = s_StartingAttributes[_charClass];
		character.health = _health;
		character.strength = _stats[0];
		character.armor = _stats[1];
		character.physicalblock = _stats[2];
		character.agility = _stats[3];
		character.spellpower = _stats[4];
		character.spellresistance = _stats[5];
		character.healingpower = _stats[6];
		character.class = _charClass;
		for(uint i = 0; i < _abilities.length; i++) {
			character.abilities.push(_abilities[i]);
		}
	}

  function registerNewCharacter(uint256 _tokenId, FantasyThings.CharacterClass _charClass) external {
	  require(msg.sender == s_fantasyCharactersAddress, "Only the NFT contract can register a character");
	  FantasyThings.CharacterAttributes storage newChar = s_CharacterAttributes[_tokenId];
	  newChar.abilities = s_StartingAttributes[_charClass].abilities;
	  newChar.health = s_StartingAttributes[_charClass].health;
	  newChar.strength = s_StartingAttributes[_charClass].strength;
	  newChar.armor = s_StartingAttributes[_charClass].armor;
	  newChar.physicalblock = s_StartingAttributes[_charClass].physicalblock;
	  newChar.agility = s_StartingAttributes[_charClass].agility;
	  newChar.spellpower = s_StartingAttributes[_charClass].spellpower;
	  newChar.spellresistance = s_StartingAttributes[_charClass].spellresistance;
	  newChar.healingpower = s_StartingAttributes[_charClass].healingpower;
	  newChar.class = s_StartingAttributes[_charClass].class;
  }

  function getPlayer(uint256 _tokenId) external view returns(FantasyThings.CharacterAttributes memory) {
	  return s_CharacterAttributes[_tokenId];
  }

  function getPlayerAbilities(uint256 _tokenId) external view returns(FantasyThings.Ability[] memory) {
	  return s_CharacterAttributes[_tokenId].abilities;
  }

  function getPlayerAbility(uint256 _tokenId, uint256 _abilityIndex) external view returns(FantasyThings.Ability memory) {
	  return s_CharacterAttributes[_tokenId].abilities[_abilityIndex];
  }

  function getStartingAttrtibutes(FantasyThings.CharacterClass _charClass) external view returns(FantasyThings.CharacterAttributes memory) {
	  return s_StartingAttributes[_charClass];
  }

  function _gainExperience(uint256 _xpEarned, uint256 _tokenId) internal {
	  s_CharacterAttributes[_tokenId].experience += _xpEarned;
  }

  function getLevel(uint256 _tokenId) external pure returns(uint256) {
	  //some formula for calculating level based off xp
	  return 0;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library FantasyThings {

	enum CharacterClass {
			Knight,
			Warlord,
			Wizard,
			Shaman,
			Cleric,
			Rogue,
			Ranger,
			Warlock
	}

	enum AbilityType {
		Strength,
		Armor,
		PhysicalBlock,
		Agility,
		Spellpower,
		Spellresistance,
		HealingPower
	}

	enum TurnType {
		NotSet,
		Combat, 
		Loot,
		Puzzle
	}

	struct Ability {
		AbilityType abilityType;
		uint8 action; //1 is attack, 2 is heal, 3 is defend
		string name;
	}

	struct CharacterAttributes {
		uint256 experience;
		uint16 health;
		uint8 strength;
		uint8 armor;
		uint8 physicalblock;
		uint8 agility;
		uint8 spellpower;
		uint8 spellresistance;
		uint8 healingpower;
		CharacterClass class;
		Ability[] abilities;
	}

	struct Mob {
		uint16 health;
		uint8 strength;
		uint8 armor;
		uint8 physicalblock;
		uint8 agility;
		uint8 spellpower;
		uint8 spellresistance;
		uint8 healingpower;
		uint8 spawnRate;
		string name;
	   Ability[] abilities;
	}

		//represent the current statistics during the campaign
	struct CampaignAttributes {
		uint16 health;
		uint8 strength;
		uint8 armor;
		uint8 physicalblock;
		uint8 agility;
		uint8 spellpower;
		uint8 spellresistance;
		uint8 healingpower;
		CharacterClass class;
		Ability[] abilities;
	}

    // Describe campaign items

  enum ItemType { Spell,Weapon,Shield}

  struct Item {
    ItemType item;
    AbilityType attr;
	 uint8 power;
	 uint8 numUses;
    string name;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}