//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./FantasyThings.sol";
import "./CastleCampaignItems.sol";
import "./CampaignPlaymaster.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IVerifier {
	 function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[2] memory input
        ) external view returns (bool r);
}

contract CastleCampaign is VRFConsumerBase, CampaignPlaymaster, CastleCampaignItems {

	bytes32 public keyHash;
	uint256 public fee;

	mapping(bytes32 => uint256) private requestToTokenId;
	mapping(bytes32 => bool) internal proofHashUsed;

	IVerifier verifier;

	constructor(address _fantasyCharacters, address _attributesManager, uint256 _numTurns, address _verifier) VRFConsumerBase(
		0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, //vrfCoordinator
      0x326C977E6efc84E512bB9C30f76E30c160eD06FB //LINK token
	) CampaignPlaymaster(_numTurns, _fantasyCharacters, _attributesManager) {
		keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4; //oracle keyhash;
      fee = 0.0001 * 10**18; //0.0001 LINK //link token fee; 

		//set up some mobs
		FantasyThings.Ability[] memory henchmanAbilities = new FantasyThings.Ability[](1);
		henchmanAbilities[0] = FantasyThings.Ability(FantasyThings.AbilityType.Strength, 1,"Attack");
		_setMob(100, [5,10,5,5,0,0,0,20], "Henchman", henchmanAbilities, 0);

		FantasyThings.Ability[] memory bigBossDragonAbilities = new FantasyThings.Ability[](2);
		bigBossDragonAbilities[0] = FantasyThings.Ability(FantasyThings.AbilityType.Spellpower, 1,"Breathe Fire");
		bigBossDragonAbilities[1] = FantasyThings.Ability(FantasyThings.AbilityType.Strength,1, "Tail Whip");
		_setMob(150, [15,20,10,10,20,15,0,100], "Draco", bigBossDragonAbilities, 1);

		//push the items into the campaign
		CampaignItems.push(iceLance);

		//set up some guaranteed events with the mobs/puzzles/loot and turn types
		//last turn will be a boss fight against the dragon
		turnGuaranteedTypes[_numTurns] = FantasyThings.TurnType.Combat;
		uint256[] memory mobIdsForLast = new uint256[](1);
		mobIdsForLast[0] = 1; //1 corresponds to Draco Id
		combatGuaranteedMobIds[_numTurns] = mobIdsForLast;

		//second to last turn we will find the dragonslayer ice lance
		turnGuaranteedTypes[_numTurns - 1] = FantasyThings.TurnType.Loot;
		uint256[] memory itemIdsForTurn = new uint256[](1);
		itemIdsForTurn[0] = 0; 
		lootGuaranteedItemIds[_numTurns - 1] = itemIdsForTurn;

		verifier = IVerifier(_verifier);
	}

	function unlockFinalTurn(uint256 _tokenId, uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[2] memory input) 
		external controlsCharacter(_tokenId) {
			bytes32 proofHash = keccak256(abi.encodePacked(a,b,c,input));
			require(!proofHashUsed[proofHash], "Stop Cheating");
			proofHashUsed[proofHash] = true;
			bool validProof = verifier.verifyProof(a,b,c,input);
			uint256 currentTurn = playerTurn[_tokenId];
			if(validProof && currentTurn == numberOfTurns) {
				bossFightAvailable[_tokenId] = true;
			}
	}

	function enterCampaign(uint256 _tokenId) external override controlsCharacter(_tokenId) {

		require(playerTurn[_tokenId] == 0, "Campaign Previously Started");
		FantasyThings.CharacterAttributes memory playerCopy = attributesManager.getPlayer(_tokenId);
		FantasyThings.CampaignAttributes storage campaignPlayer = playerStatus[_tokenId][playerNonce[_tokenId]];
		
		//update the campaign attributes and character power

		campaignPlayer.health = playerCopy.health;
		baseHealth[_tokenId] = playerCopy.health;

		campaignPlayer.strength = playerCopy.strength;
		characterPower[_tokenId][FantasyThings.AbilityType.Strength] = playerCopy.strength;

		campaignPlayer.armor = playerCopy.armor;
		characterPower[_tokenId][FantasyThings.AbilityType.Armor] = playerCopy.armor;

		campaignPlayer.physicalblock = playerCopy.physicalblock;
		characterPower[_tokenId][FantasyThings.AbilityType.PhysicalBlock] = playerCopy.physicalblock;

		campaignPlayer.agility = playerCopy.agility;
		characterPower[_tokenId][FantasyThings.AbilityType.Agility] = playerCopy.agility;

		campaignPlayer.spellpower = playerCopy.spellpower;
		characterPower[_tokenId][FantasyThings.AbilityType.Spellpower] = playerCopy.spellpower;

		campaignPlayer.spellresistance = playerCopy.spellresistance;
		characterPower[_tokenId][FantasyThings.AbilityType.Spellresistance] = playerCopy.spellresistance;

		campaignPlayer.healingpower = playerCopy.healingpower;
		characterPower[_tokenId][FantasyThings.AbilityType.HealingPower] = playerCopy.healingpower;

		campaignPlayer.class = playerCopy.class;
		for(uint256 i = 0; i < playerCopy.abilities.length; i++){
			campaignPlayer.abilities.push(playerCopy.abilities[i]);
		}

		playerTurn[_tokenId]++;
		emit CampaignStarted(_tokenId);
	}

	function generateTurn(uint256 _tokenId) external override controlsCharacter(_tokenId) {
		require(playerTurn[_tokenId] > 0, "Enter Campaign First");
		require(!turnInProgress[_tokenId], "Turn in progress");

		turnInProgress[_tokenId] = true;

		if(playerTurn[_tokenId] == numberOfTurns) {
			require(bossFightAvailable[_tokenId], "Not at the end of the maze!");
		}

		//generate the turn if it's not a guaranteed turn type
		//start the turn for both guaranteed and generated turns
		if(turnGuaranteedTypes[playerTurn[_tokenId]] == FantasyThings.TurnType.NotSet) {
		   bytes32 requestId = requestRandomness(keyHash, fee);
			requestToTokenId[requestId] = _tokenId;
		} else {
			turnTypes[_tokenId][playerTurn[_tokenId]]  = turnGuaranteedTypes[playerTurn[_tokenId]];
			if(turnGuaranteedTypes[playerTurn[_tokenId]] == FantasyThings.TurnType.Combat) {
				_setMobsForTurn(_tokenId, combatGuaranteedMobIds[playerTurn[_tokenId]], playerTurn[_tokenId]);
				emit TurnSet(_tokenId);
			} else if (turnGuaranteedTypes[playerTurn[_tokenId]] == FantasyThings.TurnType.Loot) {
				_setItemsForTurn(_tokenId, lootGuaranteedItemIds[playerTurn[_tokenId]]);
				emit TurnSet(_tokenId);
			} else {
				//puzzle
				//emit TurnSet(_tokenId);
			}
			emit TurnStarted(_tokenId);
		}
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
		uint256 tokenId = requestToTokenId[requestId];
		currentRandomSeed[tokenId] = randomness;

		/*
			The Chainlink VRF callback concept is such:
			- Take the randomness provided and generate a turn based on predetermined probabilities 
			- Within the turn time, use the randomnes to determine the number of mobs, what item to drop, what puzzle to render, etc.
			- Use the randomness as a seed for that turn's combat randomness -- dodge, block, etc.
			- A lot the turn generation is "rigged" at the moment for the proof of concept/UI development
		*/
		if(randomness % 100 < 101 ) {
			//set up combat turn
			uint256[] memory mobIdsForTurn = new uint256[](1);
			for(uint256 i=0; i<mobIdsForTurn.length; i++) {
				//if more than 1 mob option, could use randomness to generate from a spawn rate
				mobIdsForTurn[i] = 0;
			}
			_setMobsForTurn(tokenId,mobIdsForTurn,playerTurn[tokenId]);
			turnTypes[tokenId][playerTurn[tokenId]] = FantasyThings.TurnType.Combat;
			} else if(randomness % 100 > 101) {
				//set up looting turn -- no random loot in POC
				turnTypes[tokenId][playerTurn[tokenId]] = FantasyThings.TurnType.Loot;
			} else {
				//set up puzzle turn -- no random loot in POC
				turnTypes[tokenId][playerTurn[tokenId]] = FantasyThings.TurnType.Puzzle;
			}
		emit TurnSet(tokenId);
	}
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./FantasyThings.sol";

contract CastleCampaignItems {

	FantasyThings.Item public iceLance;
	FantasyThings.Item public scrollOfProtection;
	FantasyThings.Item public scrollOfStrength;
	FantasyThings.Item public scrollOfSpellpower;

	constructor() {

		iceLance.item = FantasyThings.ItemType.Weapon;
		iceLance.attr = FantasyThings.AbilityType.Strength;
		iceLance.power = 40;
		iceLance.numUses = 1;
		iceLance.name = "Dragonslayer's Ice Lance";

		scrollOfProtection.item = FantasyThings.ItemType.Spell;
		scrollOfProtection.attr = FantasyThings.AbilityType.Armor;
		scrollOfProtection.power = 20;
		scrollOfProtection.numUses = 1;
		scrollOfProtection.name = "Scroll of Protection";

		scrollOfStrength.item = FantasyThings.ItemType.Spell;
		scrollOfStrength.attr = FantasyThings.AbilityType.Strength;
		scrollOfStrength.power = 20;
		scrollOfStrength.numUses = 1;
		scrollOfStrength.name = "Scroll of Strength";

		scrollOfSpellpower.item = FantasyThings.ItemType.Spell;
		scrollOfSpellpower.attr = FantasyThings.AbilityType.Spellpower;
		scrollOfSpellpower.power = 20;
		scrollOfSpellpower.numUses = 1;
		scrollOfSpellpower.name = "Scroll of Spellpower";
	}

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./FantasyThings.sol";
import "./FantasyAttributesManager.sol";

abstract contract CampaignPlaymaster {

	uint256 immutable public numberOfTurns;
	//tokenId -> Turn Number
	mapping(uint256 => uint256) public playerTurn;
	//tokenId -> Nonce (# of times player has played campaign)
	mapping(uint256 => uint256) public playerNonce; 
	mapping(uint256 => uint256) internal currentRandomSeed;
	mapping(uint256 => uint16) public baseHealth;

	//tokenId -> bool
	mapping(uint256=>bool) public bossFightAvailable;

	//tokenId -> playerNonce -> playerStatus
	mapping(uint256 => mapping(uint256 => FantasyThings.CampaignAttributes)) public playerStatus;
	//tokenId -> Ability Type -> Current Power (do not need a nonce as this is overwritten at enter campaign)
	mapping(uint256 => mapping(FantasyThings.AbilityType => uint8)) public characterPower;
	
	//tokenId -> turnType (no nonce, overwritten)
	mapping(uint256 => FantasyThings.TurnType) public turnGuaranteedTypes;

	//tokenId -> Turn Number -> Turn Type
	mapping(uint256 => mapping(uint256 => FantasyThings.TurnType)) public turnTypes;
	//mobId -> Attributes (no nonce, only ran once in constructor)
	mapping(uint256 => FantasyThings.Mob) public mobAttributes;

	//tokenId -> playerNonce -> Turn Number -> Mobs
	mapping(uint256 => mapping(uint256 => mapping(uint256 => FantasyThings.Mob[]))) public combatTurnToMobs;
	mapping(uint256 => uint256[]) public combatGuaranteedMobIds;

	//tokenId -> nonce -> Items
	mapping(uint256 => mapping(uint256 => FantasyThings.Item[])) public campaignInventory;

    FantasyThings.Item[] public CampaignItems;
	mapping(uint256 => uint256[]) public lootGuaranteedItemIds;

	//tokenId -> Turn Number -> Mobs Alive
	mapping(uint256 => mapping(uint256 => uint256)) public turnNumMobsAlive;
	mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) public mobIndexAlive;

	//tokenId -> Turn in Progress
	mapping(uint256 => bool) public turnInProgress;

	event CampaignStarted(uint256 indexed _tokenId);
	event CampaignEnded(uint256 indexed _tokenId, bool _success);

	event TurnSet(uint256 indexed _tokenId);
	event TurnStarted(uint256 indexed _tokenId);
	event TurnCompleted(uint256 indexed _tokenId);

	event CombatSequence(uint256 indexed _tokenId, uint8 indexed _damageDone);

	IERC721Metadata public fantasyCharacters;
	FantasyAttributesManager public attributesManager;

	constructor(uint256 _numberOfTurns, address _fantasyCharacters, address _attributesManager) {
		numberOfTurns = _numberOfTurns;
		fantasyCharacters = IERC721Metadata(_fantasyCharacters);
		attributesManager = FantasyAttributesManager(_attributesManager);
	}

	modifier controlsCharacter(uint256 _tokenId) {
		require(fantasyCharacters.ownerOf(_tokenId) == msg.sender, "You do not control this character");
		_;
	}

	modifier turnActive(uint256 _tokenId) {
		require(turnInProgress[_tokenId], "No turn in progress, generate a turn");
		_;
	}

	modifier isCombatTurn(uint256 _tokenId) {
		require(turnTypes[_tokenId][playerTurn[_tokenId]] == FantasyThings.TurnType.Combat, "Cannot attack right now!");
		_;
	}

	modifier isCombatAbility(FantasyThings.Ability calldata _ability) {
		require(_ability.action == 1, "Not an attack ability");
		_;
	}

	modifier isLootTurn(uint256 _tokenId) {
		require(turnTypes[_tokenId][playerTurn[_tokenId]] == FantasyThings.TurnType.Loot, "Nothing to loot!");
		_;
	}

	modifier isPuzzleTurn(uint256 _tokenId) {
		require(turnTypes[_tokenId][playerTurn[_tokenId]] == FantasyThings.TurnType.Puzzle, "Not a puzzle!");
		_;
	}

	function getCurrentCampaignStats(uint256 _tokenId) external view returns(FantasyThings.CampaignAttributes memory) {
		return playerStatus[_tokenId][playerNonce[_tokenId]];
	}
	
	function _setMob(uint16 _health, uint8[8] memory _stats, string memory _name, FantasyThings.Ability[] memory _abilities, uint256 _mobId) internal {
		FantasyThings.Mob storage mob = mobAttributes[_mobId];
		mob.strength = _stats[0];
		mob.armor = _stats[1];
		mob.physicalblock = _stats[2];
		mob.agility = _stats[3];
		mob.spellpower = _stats[4];
		mob.spellresistance = _stats[5];
		mob.healingpower = _stats[6];
		mob.spawnRate = _stats[7];
		mob.health = _health;
		mob.name = _name;
		for(uint i = 0; i < _abilities.length; i++) {
			mob.abilities.push(_abilities[i]);
		}
	}

	function _setMobsForTurn(uint256 _tokenId, uint256[] memory _mobIds, uint256 _turnNum) internal {
		for(uint256 i=0; i< _mobIds.length; i++) {
			combatTurnToMobs[_tokenId][playerNonce[_tokenId]][_turnNum].push(mobAttributes[_mobIds[i]]);
			mobIndexAlive[_tokenId][_turnNum][i] = true;
		}
		turnNumMobsAlive[_tokenId][playerTurn[_tokenId]] = _mobIds.length;
	}
	 
	function _setItemsForTurn(uint256 _tokenId, uint256[] memory _itemIds) internal {
		for(uint256 i=0; i< _itemIds.length; i++) {
			campaignInventory[_tokenId][playerNonce[_tokenId]].push(CampaignItems[_itemIds[i]]);
		}
	}
	
	 //This is a default configuration of attack with ability, can be overwritten if want to incorporate some other mechanics
	 function attackWithAbility (
		uint256 _tokenId, uint256 _abilityIndex, uint256 _target) 
		external virtual controlsCharacter(_tokenId) isCombatTurn(_tokenId) turnActive(_tokenId) {
		
		uint256 currentNonce = playerNonce[_tokenId];
		uint256 currentTurn = playerTurn[_tokenId];

		require(combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].health > 0, "Can't attack a dead mob");
		FantasyThings.Ability memory userAbility = attributesManager.getPlayerAbility(_tokenId, _abilityIndex);
		require(userAbility.action == 1, "Cannot attack with this ability!");

		uint8 damageBase = characterPower[_tokenId][userAbility.abilityType];
		uint16 targetHealthStart = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].health;
		uint8 damageTotal = _getDamageTotal(_tokenId, userAbility.abilityType, _target, damageBase);

		if(damageTotal >= targetHealthStart) {
			_killMob(_tokenId, currentNonce, currentTurn, _target);
		} else {
			combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].health-=uint16(damageTotal);
			_retaliate(_tokenId, currentTurn, currentNonce, _target);
		}

		if(turnInProgress[_tokenId]) { 
			emit CombatSequence(_tokenId, damageTotal);
		}
	}

	function attackWithItem(
		uint256 _tokenId, uint256 _itemId, uint256 _target) 
		external virtual controlsCharacter(_tokenId) isCombatTurn(_tokenId) turnActive(_tokenId) {
		  	
	  uint256 currentNonce = playerNonce[_tokenId];
	  uint256 currentTurn = playerTurn[_tokenId];
	  FantasyThings.Item memory attackItem = campaignInventory[_tokenId][currentNonce][_itemId];
	  require(attackItem.item == FantasyThings.ItemType.Weapon, "Can't attack with this Item");
	  require(attackItem.numUses > 0, "This item is expired");
	  require(combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].health > 0, "Can't attack a dead mob");
	  
	  uint8 damageBase = attackItem.power;
	  uint16 targetHealthStart = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].health;
	  uint8 damageTotal = _getDamageTotal(_tokenId, attackItem.attr, _target, damageBase);
	  
	  campaignInventory[_tokenId][playerNonce[_tokenId]][_itemId].numUses--;

	  if(damageTotal >= targetHealthStart) {
			_killMob(_tokenId, currentNonce, currentTurn, _target);
		} else {
			combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].health-=uint16(damageTotal);
			_retaliate(_tokenId, currentTurn, currentNonce, _target);
		}

	  if(turnInProgress[_tokenId]) { 
			emit CombatSequence(_tokenId, damageTotal);
		}
   }

	function applyItemSpell(uint256 _tokenId, uint256 _itemId) external virtual
	controlsCharacter(_tokenId) {
		uint256 currentNonce = playerNonce[_tokenId];
	  	FantasyThings.Item memory applyItem = campaignInventory[_tokenId][currentNonce][_itemId];
		require(applyItem.item == FantasyThings.ItemType.Spell, "Can't apply spells with this Item");
	  	require(applyItem.numUses > 0, "This item is expired");
		campaignInventory[_tokenId][playerNonce[_tokenId]][_itemId].numUses--;

		characterPower[_tokenId][applyItem.attr] + applyItem.power > 255 ? characterPower[_tokenId][applyItem.attr] = 255 : characterPower[_tokenId][applyItem.attr]+=applyItem.power;
	}

	function castHealAbility(uint256 _tokenId, uint256 _abilityIndex) 
		external virtual controlsCharacter(_tokenId) isCombatTurn(_tokenId) turnActive(_tokenId) {
		
		FantasyThings.Ability memory userAbility = attributesManager.getPlayerAbility(_tokenId, _abilityIndex);
		require(userAbility.action == 2, "Cannot heal with this ability!");

		uint256 currentNonce = playerNonce[_tokenId];

		uint8 healingPower = characterPower[_tokenId][userAbility.abilityType];
		uint16 currentHealth = playerStatus[_tokenId][currentNonce].health;

		uint16(healingPower) + currentHealth >= baseHealth[_tokenId] ? playerStatus[_tokenId][currentNonce].health = baseHealth[_tokenId] : 
			playerStatus[_tokenId][currentNonce].health+=uint16(healingPower);

		uint256 index;
		for(uint256 i=0; i < combatTurnToMobs[_tokenId][currentNonce][playerTurn[_tokenId]].length; i++) {
			if (mobIndexAlive[_tokenId][playerTurn[_tokenId]][i]) {
				index = i;
				break;
			}
		}

		_retaliate(_tokenId, playerTurn[_tokenId], currentNonce, index);
	}

	function _retaliate(uint256 _tokenId, uint256 _turn, uint256 _nonce, uint256 _target) internal {
		uint256 numMobAbils = combatTurnToMobs[_tokenId][_nonce][_turn][_target].abilities.length;
		numMobAbils > 1 ? _mobAttackPlayer(_tokenId, _target, uint256(keccak256(abi.encodePacked(currentRandomSeed[_tokenId], block.timestamp, playerStatus[_tokenId][_nonce].health))) % numMobAbils) : _mobAttackPlayer(_tokenId, _target, 0);
		if(playerStatus[_tokenId][_nonce].health == 0) {
			_endCampaign(_tokenId, false);
		}
	}

	function _killMob(uint256 _tokenId, uint256 _currentNonce, uint256 _currentTurn, uint256 _target) internal {
		combatTurnToMobs[_tokenId][_currentNonce][_currentTurn][_target].health = 0;
		turnNumMobsAlive[_tokenId][_currentTurn]--;
		mobIndexAlive[_tokenId][_currentTurn][_target] = false;
		if(turnNumMobsAlive[_tokenId][_currentTurn] == 0) {
			_endTurn(_tokenId, _currentNonce);
		}
	}

	function endExploreLoot(uint256 _tokenId) external virtual controlsCharacter(_tokenId) isLootTurn(_tokenId) turnActive(_tokenId) {
		_endTurn(_tokenId, playerNonce[_tokenId]);
	}

	function _endTurn(uint256 _tokenId, uint256 _currentNonce) internal {
		
		turnInProgress[_tokenId] = false;
		playerTurn[_tokenId]++;

		if(playerTurn[_tokenId] > numberOfTurns) {
			_endCampaign(_tokenId, true);
		} else {
			playerStatus[_tokenId][_currentNonce].health = baseHealth[_tokenId];
			emit TurnCompleted(_tokenId);
		}
	}
	
	function _getDamageTotal(uint256 _tokenId, FantasyThings.AbilityType _attackType, uint256 _target, uint8 _damageBase) internal view returns(uint8) {

		uint256 currentNonce = playerNonce[_tokenId];
		uint8 dmgTotal;

		uint256 PRNG = uint256(keccak256(abi.encodePacked(currentRandomSeed[_tokenId], playerStatus[_tokenId][currentNonce].health, block.timestamp)));

		//Reduction = Base * (1 - Resistance/3*Max Resistance)
		//Chance of block/dodge/full resist = Resistance/5*Max Resistance * Resistance/AttackBase
		//For equally strong attack/defend stats, this gives a 1/5 chance of blocking/dodging/full resisting at max resistance

		if(_attackType == FantasyThings.AbilityType.Strength || _attackType == FantasyThings.AbilityType.Agility){
			uint256 dodgeChance = _dodgeChanceMob(_tokenId, _target, _damageBase);
			if(PRNG % 100000 <= dodgeChance) {return 0;}
			uint256 blockChance = _blockChanceMob(_tokenId, _target, _damageBase);
			if(PRNG % 100000 <= blockChance) {return 0;}
			dmgTotal = _damageReduceArmorMob(_tokenId, _target, _damageBase);
		} else {
			uint256 resistChance = _spellResistChanceMob(_tokenId, _target, _damageBase);
			if(PRNG % 100000 <= resistChance) {return 0;}
			dmgTotal = _damageReduceSpellMob(_tokenId, _target, _damageBase);
		}
		return dmgTotal;
	}

	function _dodgeChanceMob(uint256 _tokenId, uint256 _target, uint8 _baseDamage) internal view returns(uint256) {
		uint256 currentTurn = playerTurn[_tokenId];
		uint256 currentNonce = playerNonce[_tokenId];
		uint8 mobAgil = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].agility;
		return uint256(mobAgil)*1000/(5*255) *  (uint256(mobAgil)*100)/_baseDamage;
	}

	function _blockChanceMob(uint256 _tokenId, uint256 _target, uint8 _baseDamage) internal view returns(uint256) {
		uint256 currentTurn = playerTurn[_tokenId];
		uint256 currentNonce = playerNonce[_tokenId];
		uint8 mobBlock = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].physicalblock;
		return uint256(mobBlock)*1000/(5*255) *  (uint256(mobBlock)*100)/_baseDamage;
	}

	function _spellResistChanceMob(uint256 _tokenId, uint256 _target, uint8 _baseDamage) internal view returns(uint256) {
		uint256 currentTurn = playerTurn[_tokenId];
		uint256 currentNonce = playerNonce[_tokenId];
		uint8 mobSpellResist = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].spellresistance;
		return uint256(mobSpellResist)*1000/(5*255) *  (uint256(mobSpellResist)*100)/_baseDamage;
	}

	function _damageReduceArmorMob(uint256 _tokenId, uint256 _target, uint8 _baseDamage) internal view returns(uint8) {
		uint256 currentTurn = playerTurn[_tokenId];
		uint256 currentNonce = playerNonce[_tokenId];
		uint8 mobArmor = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].armor;
		return uint8((_baseDamage * (1000 - (uint256(mobArmor)*1000)/(3*255)))/1000);
	}

	function _damageReduceSpellMob(uint256 _tokenId, uint256 _target, uint8 _baseDamage) internal view returns(uint8) {
		uint256 currentTurn = playerTurn[_tokenId];
		uint256 currentNonce = playerNonce[_tokenId];
		uint8 mobSpellResistance = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_target].spellresistance;
		return uint8((_baseDamage * (1000 - (uint256(mobSpellResistance)*1000)/(3*255)))/1000);
	}

	function _mobAttackPlayer(uint256 _tokenId, uint256 _mobIndex, uint256 _mobAbilityIndex) internal {
	  uint256 currentNonce = playerNonce[_tokenId];
	  uint256 currentTurn = playerTurn[_tokenId];
	  FantasyThings.Ability memory mobAbility = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_mobIndex].abilities[_mobAbilityIndex];
	  uint8 baseDamage;
	  uint8 totalDamage;
	  if (mobAbility.abilityType == FantasyThings.AbilityType.Strength) {
			baseDamage = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_mobIndex].strength;
	  		totalDamage = _getDamageToPlayerPhysical(_tokenId, baseDamage);
	  } else if (mobAbility.abilityType == FantasyThings.AbilityType.Agility) {
			baseDamage = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_mobIndex].agility;
			totalDamage = _getDamageToPlayerPhysical(_tokenId, baseDamage);
	  } else {
		   baseDamage = combatTurnToMobs[_tokenId][currentNonce][currentTurn][_mobIndex].spellpower;
			totalDamage = _getDamageToPlayerSpell(_tokenId, baseDamage);
		}
		
		totalDamage >= playerStatus[_tokenId][currentNonce].health ? playerStatus[_tokenId][currentNonce].health = 0 : playerStatus[_tokenId][currentNonce].health -= totalDamage;
     }

	function _getDamageToPlayerPhysical(uint256 _tokenId, uint8 _baseDamage) internal view returns(uint8) {

		//block and dodge chance
		uint256 currentNonce = playerNonce[_tokenId];
		uint256 PRNG = uint256(keccak256(abi.encodePacked(currentRandomSeed[_tokenId], playerStatus[_tokenId][currentNonce].health, block.timestamp)));

		uint8 playerAgil = playerStatus[_tokenId][currentNonce].agility;
		uint256 dodgeChance = uint256(playerAgil)*1000/(5*255) *  (uint256(playerAgil)*100)/_baseDamage;
		if(PRNG % 100000 <= dodgeChance) {return 0;}

		uint8 playerBlock = playerStatus[_tokenId][currentNonce].physicalblock;
		uint256 blockChance = uint256(playerBlock)*1000/(5*255) *  (uint256(playerBlock)*100)/_baseDamage;
		if(PRNG % 100000 <= blockChance) {return 0;}

		uint8 playerArmor = playerStatus[_tokenId][currentNonce].armor;
		return uint8((_baseDamage * (1000 - (uint256(playerArmor)*1000)/(3*255)))/1000);
	}

   function _getDamageToPlayerSpell(uint256 _tokenId, uint8 _baseDamage) internal view returns(uint8) {

		uint256 currentNonce = playerNonce[_tokenId];
		uint256 PRNG = uint256(keccak256(abi.encodePacked(currentRandomSeed[_tokenId], playerStatus[_tokenId][currentNonce].health, block.timestamp)));

		uint8 playerSpellResist = playerStatus[_tokenId][currentNonce].spellresistance;
		uint256 resistChance = uint256(playerSpellResist)*1000/(5*255) *  (uint256(playerSpellResist)*100)/_baseDamage;
		if(PRNG % 100000 <= resistChance) {return 0;}

		return uint8((_baseDamage * (1000 - (uint256(playerSpellResist)*1000)/(3*255)))/1000);
	}

	function abandonCampaign(uint256 _tokenId) external controlsCharacter(_tokenId) {
		_endCampaign(_tokenId, false);
	}

	function _endCampaign(uint256 _tokenId, bool _campaignSuccess) internal {
		playerTurn[_tokenId] = 0;
		turnInProgress[_tokenId] = false;
		playerNonce[_tokenId]++;
		emit CampaignEnded(_tokenId, _campaignSuccess);
	}

	function getMobsForTurn(uint256 _tokenId, uint256 _turnNum) public view returns(FantasyThings.Mob[] memory) {
		return combatTurnToMobs[_tokenId][playerNonce[_tokenId]][_turnNum];
	}

	function getInventory(uint256 _tokenId) external view returns(FantasyThings.Item[] memory) {
		return campaignInventory[_tokenId][playerNonce[_tokenId]];
	}

	function enterCampaign(uint256 _tokenId) external virtual;
	function generateTurn(uint256 _tokenId) external virtual;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

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