// EtherGen Contract: 

// Base Minting Contract

contract CardMintingFacilitator {
    CardConfig schema = CardConfig(0x08584271df3d0249c2c06ac1bc1237a1dd30cb9a); 
    EtherGenCore storageContract = EtherGenCore(0x677aa1dc08b9429c595efd4425b2d218cc22fd6e);
    address public owner = 0x08F4aE96b647B30177cc15B21195960625BA4163;
    
    function generateRandomCard(uint32 randomSeed) internal constant returns (uint8[14]) {
        uint8[14] memory cardDetails;
       
        randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));
        cardDetails[0] = schema.getType(randomSeed);

        if (cardDetails[0] == uint8(CardConfig.Type.Monster)) {
            generateRandomMonster(cardDetails, randomSeed);
        } else {
            generateRandomSpell(cardDetails, randomSeed);
        }
        
        randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));
        if (randomSeed % 200 == 13) { // Lucky number 13
            cardDetails[12] = 1; // Secret golden attribute
        }
        
        return cardDetails;
    }
    
    function generateRandomMonster(uint8[14] cardDetails, uint32 randomSeed) internal constant {
        uint24 totalCost;
        
        randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));
        cardDetails[1] = schema.getRace(randomSeed);
        totalCost += schema.getCostForRace(cardDetails[1]);

        randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));
        cardDetails[2] = schema.getTrait(randomSeed);
        totalCost += schema.getCostForTrait(cardDetails[2]);

        uint8 newMutation;
        uint24 newMutationCost;
        randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));
        
        uint8 numMutations = uint8(randomSeed % 12); // 0 = 0 mutations, 1 = 1 mutation, 2-5 = 2 mutations, 6-11 = 3 mutations 
        if (numMutations > 5) {
            numMutations = 3;
        } else if (numMutations > 2) {
            numMutations = 2;
        }
        
        for (uint8 i = 0; i < numMutations; i++) {
            randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));
            if (bool(randomSeed % 3 == 0)) { // 0: Race; 1-2: Neutral
                randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));

                // Horribly add new mutations (rather than looping for a fresh one) this is cheaper
                (newMutationCost, newMutation) = schema.getMutationForRace(CardConfig.Race(cardDetails[1]), randomSeed);
                if (totalCost + newMutationCost < 290000) {
                    if (cardDetails[6] == 0) {
                        cardDetails[6] = newMutation;
                        totalCost += newMutationCost;
                    } else if (cardDetails[6] > 0 && cardDetails[7] == 0 && cardDetails[6] != newMutation) {
                        cardDetails[7] = newMutation;
                        totalCost += newMutationCost;
                    } else if  (cardDetails[6] > 0 && cardDetails[7] > 0 && cardDetails[8] == 0 && cardDetails[6] != newMutation && cardDetails[7] != newMutation) {
                        cardDetails[8] = newMutation;
                        totalCost += newMutationCost;
                    }
                }
            } else {
                randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));

                // Horribly add new mutations (rather than looping for a fresh one) this is cheaper
                (newMutationCost, newMutation) = schema.getNeutralMutation(randomSeed);
                if (totalCost + newMutationCost < 290000) {
                    if (cardDetails[9] == 0) {
                        cardDetails[9] = newMutation;
                        totalCost += newMutationCost;
                    } else if (cardDetails[9] > 0 && cardDetails[10] == 0 && cardDetails[9] != newMutation) {
                        cardDetails[10] = newMutation;
                        totalCost += newMutationCost;
                    } else if (cardDetails[9] > 0 && cardDetails[10] > 0 && cardDetails[11] == 0 && cardDetails[9] != newMutation && cardDetails[10] != newMutation) {
                        cardDetails[11] = newMutation;
                        totalCost += newMutationCost;
                    }
                }
            }
        }

        // For attack & health distribution
        randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));
        uint24 powerCost = schema.getCostForHealth(1) + uint24(randomSeed % (301000 - (totalCost + schema.getCostForHealth(1)))); // % upto 300999 will allow 30 cost cards

        if (totalCost + powerCost < 100000) { // Cards should cost at least 10 crystals (10*10000 exponant)
            powerCost = 100000 - totalCost;
        }
        
        randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));
        cardDetails[5] = 1 + uint8(schema.getHealthForCost(randomSeed % powerCost)); // should be (1 + powerCost - schema.getCostForHealth(1))
        totalCost += schema.getCostForHealth(cardDetails[5]);
        
        powerCost = powerCost - schema.getCostForHealth(cardDetails[5]); // Power left for attack
        cardDetails[4] = uint8(schema.getAttackForCost(powerCost));
        totalCost += schema.getCostForAttack(cardDetails[4]);
       
        // Remove exponent to get total card cost [10-30]
        cardDetails[3] = uint8(totalCost / 10000);
    }
    
    
    function generateRandomSpell(uint8[14] cardDetails, uint32 randomSeed) internal constant {
        uint24 totalCost;
        
        uint8 newAbility;
        uint24 newAbilityCost;
        randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));
        
        uint8 numAbilities = uint8(randomSeed % 16); // 0 = 1 ability, 1-8 = 2 abilities, 9-15 = 3 abilities 
        if (numAbilities > 8) {
            numAbilities = 3;
        } else if (numAbilities > 0) {
            numAbilities = 2;
        } else {
            numAbilities = 1;
        }
        
        for (uint8 i = 0; i < numAbilities; i++) {
            randomSeed = uint32(sha3(block.blockhash(block.number), randomSeed));

            // Horribly add new spell abilities (rather than looping for a fresh one) this is cheaper
            (newAbilityCost, newAbility) = schema.getSpellAbility(randomSeed);
            if (totalCost + newAbilityCost <= 300000) {
                if (cardDetails[9] == 0) {
                    cardDetails[9] = newAbility;
                    totalCost += newAbilityCost;
                } else if (cardDetails[9] > 0 && cardDetails[10] == 0 && cardDetails[9] != newAbility) {
                    cardDetails[10] = newAbility;
                    totalCost += newAbilityCost;
                } else if (cardDetails[9] > 0 && cardDetails[10] > 0 && cardDetails[11] == 0 && cardDetails[9] != newAbility && cardDetails[10] != newAbility) {
                    cardDetails[11] = newAbility;
                    totalCost += newAbilityCost;
                }
            }
        }
        
        // Remove exponent to get total card cost [10-30]
        cardDetails[3] = uint8(totalCost / 10000);
    }
    
    
    function generateCostFromAttributes(uint8[14] cardDetails) internal constant returns (uint8 cost) {
        uint24 exponentCost = 0;
        if (cardDetails[0] == 1) { // Spell
            exponentCost += schema.getSpellAbilityCost(cardDetails[9]);
            exponentCost += schema.getSpellAbilityCost(cardDetails[10]);
            exponentCost += schema.getSpellAbilityCost(cardDetails[11]);
        } else {
            exponentCost += schema.getCostForRace(cardDetails[1]);
            exponentCost += schema.getCostForTrait(cardDetails[2]);
            exponentCost += schema.getCostForAttack(cardDetails[4]);
            exponentCost += schema.getCostForHealth(cardDetails[5]);
            exponentCost += schema.getRaceMutationCost(CardConfig.Race(cardDetails[1]), cardDetails[6]);
            exponentCost += schema.getRaceMutationCost(CardConfig.Race(cardDetails[1]), cardDetails[7]);
            exponentCost += schema.getRaceMutationCost(CardConfig.Race(cardDetails[1]), cardDetails[8]);
            exponentCost += schema.getNeutralMutationCost(cardDetails[9]);
            exponentCost += schema.getNeutralMutationCost(cardDetails[10]);
            exponentCost += schema.getNeutralMutationCost(cardDetails[11]);
        }
        return uint8(exponentCost / 10000); // Everything is factor 10000 for ease of autonomous Workshop cost-tuning
    }
    
    // Allows future extensibility (New card mutations + Workshop updates)
    function upgradeCardConfig(address newCardConfig) external {
        require(msg.sender == owner);
        schema = CardConfig(newCardConfig);
    }
    
    function updateStorageContract(address newStorage) external {
        require(msg.sender == owner);
        storageContract = EtherGenCore(newStorage);
    }
    
    function updateOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }
}






//// Card Promotion + Referrals

contract NewUserBonusDistributor is CardMintingFacilitator {
    mapping(address => bool) private claimedAddresses; // You only get one free card for &#39;signing up&#39;
    bool public newUserBonusCardTradable = true; // If people abuse new user bonus they will be made untradable (but unlocked via battle)
    
    address[] public referals; // Array to store all unpaid referal cards
    
    function claimFreeFirstCard(address referer) external {
        require(!claimedAddresses[msg.sender]);
        
        uint8[14] memory newCard = generateRandomCard(uint32(msg.sender));
        if (!newUserBonusCardTradable) {
            newCard[13] = 1;
        }
        claimedAddresses[msg.sender] = true;
        storageContract.mintCard(msg.sender, newCard);
        allocateReferalBonus(referer);
    }
    
    function hasAlreadyClaimed() external constant returns (bool) {
        return claimedAddresses[msg.sender];
    }
    
    function allocateReferalBonus(address referer) internal {
        // To save new players gas, referals will be async and payed out manually by our team
        if (referer != address(0) && referer != msg.sender) {
            referals.push(referer);
            referals.push(msg.sender);
        }
    }
    
    function awardReferalBonus() external {
        // To save new players gas, referals are payed out below manually (by our team + kind gas donors)
        require(referals.length > 0);
        address recipient = referals[referals.length - 1];
        uint8[14] memory newCard = generateRandomCard(uint32(storageContract.totalSupply() * now));
        newCard[13] = 1; // Referal cards untradable to prevent abuse (unlocked via battle)
        
        delete referals[referals.length - 1];
        referals.length--;
        storageContract.mintCard(recipient, newCard);
    }
    
    function setNewUserBonusCardTradable(bool tradable) external {
        require(msg.sender == owner);
        newUserBonusCardTradable = tradable;
    }
    
}










// Interface for contracts conforming to ERC-721: Non-Fungible Tokens
contract ERC721 {

    // Required methods
    function totalSupply() public view returns (uint256 cards);
    function balanceOf(address player) public view returns (uint256 balance);
    function ownerOf(uint256 cardId) external view returns (address owner);
    function approve(address to, uint256 cardId) external;
    function transfer(address to, uint256 cardId) external;
    function transferFrom(address from, address to, uint256 cardId) external;

    // Events
    event Transfer(address from, address to, uint256 cardId);
    event Approval(address owner, address approved, uint256 cardId);

    // Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "EtherGen";
    string public constant symbol = "ETG";

    // Optional methods
    function tokensOfOwner(address player) external view returns (uint64[] cardIds);
}


// Base Storage for EtherGen
contract PlayersCollectionStorage {
    
    mapping(address => PlayersCollection) internal playersCollections;
    mapping(uint64 => Card) internal cardIdMapping;

    struct PlayersCollection {
        uint64[] cardIds;
        bool referalCardsUnlocked;
    }

    struct Card {
        uint64 id;
        uint64 collectionPointer; // Index in player&#39;s collection
        address owner;
        
        uint8 cardType;
        uint8 race;
        uint8 trait;

        uint8 cost; // [10-30]
        uint8 attack; // [0-99]
        uint8 health; // [1-99]

        uint8 raceMutation0; // Super ugly but dynamic length arrays are currently a no-go across contracts
        uint8 raceMutation1; // + very expensive gas since cards are in nested structs (collection of cards)
        uint8 raceMutation2;

        uint8 neutralMutation0;
        uint8 neutralMutation1;
        uint8 neutralMutation2;

        /**
         * Initally referal (free) cards will be untradable (to stop abuse) however EtherGenCore has
         * unlockUntradeableCards() to make them tradeable -triggered once player hits certain battle/game milestone
         */
        bool isReferalReward;
        bool isGolden; // Top secret Q2 animated art
    }
    
    function getPlayersCollection(address player) public constant returns (uint64[], uint8[14][]) {
        uint8[14][] memory cardDetails = new uint8[14][](playersCollections[player].cardIds.length);
        uint64[] memory cardIds = new uint64[](playersCollections[player].cardIds.length);

        for (uint32 i = 0; i < playersCollections[player].cardIds.length; i++) {
            Card memory card = cardIdMapping[playersCollections[player].cardIds[i]];
            cardDetails[i][0] = card.cardType;
            cardDetails[i][1] = card.race;
            cardDetails[i][2] = card.trait;
            cardDetails[i][3] = card.cost;
            cardDetails[i][4] = card.attack;
            cardDetails[i][5] = card.health;
            cardDetails[i][6] = card.raceMutation0;
            cardDetails[i][7] = card.raceMutation1;
            cardDetails[i][8] = card.raceMutation2;
            cardDetails[i][9] = card.neutralMutation0;
            cardDetails[i][10] = card.neutralMutation1;
            cardDetails[i][11] = card.neutralMutation2;

            cardDetails[i][12] = card.isGolden ? 1 : 0; // Not ideal but web3.js didn&#39;t like returning multiple 2d arrays
            cardDetails[i][13] = isCardTradeable(card) ? 1 : 0;
            
            cardIds[i] = card.id;
        }
        return (cardIds, cardDetails);
    }
    
    function getCard(uint64 cardId) public constant returns (uint8[14]) {
        Card memory card = cardIdMapping[cardId];
        return ([card.cardType, card.race, card.trait, card.cost, card.attack, card.health,
                 card.raceMutation0, card.raceMutation1, card.raceMutation2,
                 card.neutralMutation0, card.neutralMutation1, card.neutralMutation2,
                 card.isGolden ? 1 : 0, 
                 isCardTradeable(card) ? 1 : 0]);
    }
    
    function isCardTradeable(Card card) internal constant returns(bool) {
        return (playersCollections[card.owner].referalCardsUnlocked || !card.isReferalReward);
    }
    
    function isCardTradeable(uint64 cardId) external constant returns(bool) {
        return isCardTradeable(cardIdMapping[cardId]);
    }
}



// Extensibility of storage + ERCness
contract EtherGenCore is PlayersCollectionStorage, ERC721 {
    
    mapping(address => bool) private privilegedTransferModules; // Marketplace ( + future features)
    mapping(address => bool) private privilegedMintingModules; // Referals, Fusing, Workshop etc. ( + future features)
    
    mapping(uint64 => address) private cardIdApproveds; // Approval list (ERC721 transfers)
    uint64 private totalCardSupply; // Also used for cardId incrementation
    
    TransferRestrictionVerifier transferRestrictionVerifier = TransferRestrictionVerifier(0xd9861d9a6111bfbb9235a71151f654d0fe7ed954); 
    address public owner = 0x08F4aE96b647B30177cc15B21195960625BA4163;
    bool public paused = false;
    
    function totalSupply() public view returns (uint256 cards) {
        return totalCardSupply;
    }
    
    function ownerOf(uint256 cardId) external view returns (address cardOwner) {
        return cardIdMapping[uint64(cardId)].owner;
    }
    
    function balanceOf(address player) public view returns (uint256 balance) {
        return playersCollections[player].cardIds.length;
    }
    
    function tokensOfOwner(address player) external view returns (uint64[] cardIds) {
        return playersCollections[player].cardIds;
    }
    
    function transfer(address newOwner, uint256 cardId) external {
        uint64 castCardId = uint64(cardId);
        require(cardIdMapping[castCardId].owner == msg.sender);
        require(isCardTradeable(cardIdMapping[castCardId]));
        require(transferRestrictionVerifier.isAvailableForTransfer(castCardId));
        require(!paused);
        
        removeCardOwner(castCardId);
        assignCardOwner(newOwner, castCardId);
        Transfer(msg.sender, newOwner, castCardId); // Emit Event
    }
    
    function transferFrom(address currentOwner, address newOwner, uint256 cardId) external {
        uint64 castCardId = uint64(cardId);
        require(cardIdMapping[castCardId].owner == currentOwner);
        require(isApprovedTransferer(msg.sender, castCardId));
        require(isCardTradeable(cardIdMapping[castCardId]));
        require(transferRestrictionVerifier.isAvailableForTransfer(castCardId));
        require(!paused);
        
        removeCardOwner(castCardId);
        assignCardOwner(newOwner, castCardId);
        Transfer(currentOwner, newOwner, castCardId); // Emit Event
    }
    
    function approve(address approved, uint256 cardId) external {
        uint64 castCardId = uint64(cardId);
        require(cardIdMapping[castCardId].owner == msg.sender);
        
        cardIdApproveds[castCardId] = approved; // Register approval (replacing previous)
        Approval(msg.sender, approved, castCardId); // Emit Event
    }
    
    function isApprovedTransferer(address approvee, uint64 cardId) internal constant returns (bool) {
        // Will only return true if approvee (msg.sender) is a privileged transfer address (Marketplace) or santioned by card&#39;s owner using ERC721&#39;s approve()
        return privilegedTransferModules[approvee] || cardIdApproveds[cardId] == approvee;
    }
    
    function removeCardOwner(uint64 cardId) internal {
        address cardOwner = cardIdMapping[cardId].owner;

        if (playersCollections[cardOwner].cardIds.length > 1) {
            uint64 rowToDelete = cardIdMapping[cardId].collectionPointer;
            uint64 cardIdToMove = playersCollections[cardOwner].cardIds[playersCollections[cardOwner].cardIds.length - 1];
            playersCollections[cardOwner].cardIds[rowToDelete] = cardIdToMove;
            cardIdMapping[cardIdToMove].collectionPointer = rowToDelete;
        }
        
        playersCollections[cardOwner].cardIds.length--;
        cardIdMapping[cardId].owner = 0;
    }
    
    function assignCardOwner(address newOwner, uint64 cardId) internal {
        if (newOwner != address(0)) {
            cardIdMapping[cardId].owner = newOwner;
            cardIdMapping[cardId].collectionPointer = uint64(playersCollections[newOwner].cardIds.push(cardId) - 1);
        }
    }
    
    function mintCard(address recipient, uint8[14] cardDetails) external {
        require(privilegedMintingModules[msg.sender]);
        require(!paused);
        
        Card memory card;
        card.owner = recipient;
        
        card.cardType = cardDetails[0];
        card.race = cardDetails[1];
        card.trait = cardDetails[2];
        card.cost = cardDetails[3];
        card.attack = cardDetails[4];
        card.health = cardDetails[5];
        card.raceMutation0 = cardDetails[6];
        card.raceMutation1 = cardDetails[7];
        card.raceMutation2 = cardDetails[8];
        card.neutralMutation0 = cardDetails[9];
        card.neutralMutation1 = cardDetails[10];
        card.neutralMutation2 = cardDetails[11];
        card.isGolden = cardDetails[12] == 1;
        card.isReferalReward = cardDetails[13] == 1;
        
        card.id = totalCardSupply;
        totalCardSupply++;

        cardIdMapping[card.id] = card;
        cardIdMapping[card.id].collectionPointer = uint64(playersCollections[recipient].cardIds.push(card.id) - 1);
    }
    
    // Management functions to facilitate future contract extensibility, unlocking of (untradable) referal bonus cards and contract ownership
    
    function unlockUntradeableCards(address player) external {
        require(privilegedTransferModules[msg.sender]);
        playersCollections[player].referalCardsUnlocked = true;
    }
    
    function manageApprovedTransferModule(address moduleAddress, bool isApproved) external {
        require(msg.sender == owner);
        privilegedTransferModules[moduleAddress] = isApproved; 
    }
    
     function manageApprovedMintingModule(address moduleAddress, bool isApproved) external {
        require(msg.sender == owner);
        privilegedMintingModules[moduleAddress] = isApproved; 
    }
    
    function updateTransferRestrictionVerifier(address newTransferRestrictionVerifier) external {
        require(msg.sender == owner);
        transferRestrictionVerifier = TransferRestrictionVerifier(newTransferRestrictionVerifier);
    }
    
    function setPaused(bool shouldPause) external {
        require(msg.sender == owner);
        paused = shouldPause;
    }
    
    function updateOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }
    
}




contract CardConfig {
    enum Type {Monster, Spell} // More could come!

    enum Race {Dragon, Spiderling, Demon, Humanoid, Beast, Undead, Elemental, Vampire, Serpent, Mech, Golem, Parasite}
    uint16 constant numRaces = 12;

    enum Trait {Normal, Fire, Poison, Lightning, Ice, Divine, Shadow, Arcane, Cursed, Void}
    uint16 constant numTraits = 10;

    function getType(uint32 randomSeed) public constant returns (uint8) {
        if (randomSeed % 5 > 0) { // 80% chance for monster (spells are less fun so make up for it in rarity)
            return uint8(Type.Monster);
        } else {
            return uint8(Type.Spell);
        }
    }
    
    function getRace(uint32 randomSeed) public constant returns (uint8) {
        return uint8(Race(randomSeed % numRaces));
    }

    function getTrait(uint32 randomSeed) public constant returns (uint8) {
        return uint8(Trait(randomSeed % numTraits));
    }

    SpellAbilities spellAbilities = new SpellAbilities();
    SharedNeutralMutations neutralMutations = new SharedNeutralMutations();
    DragonMutations dragonMutations = new DragonMutations();
    SpiderlingMutations spiderlingMutations = new SpiderlingMutations();
    DemonMutations demonMutations = new DemonMutations();
    HumanoidMutations humanoidMutations = new HumanoidMutations();
    BeastMutations beastMutations = new BeastMutations();
    UndeadMutations undeadMutations = new UndeadMutations();
    ElementalMutations elementalMutations = new ElementalMutations();
    VampireMutations vampireMutations = new VampireMutations();
    SerpentMutations serpentMutations = new SerpentMutations();
    MechMutations mechMutations = new MechMutations();
    GolemMutations golemMutations = new GolemMutations();
    ParasiteMutations parasiteMutations = new ParasiteMutations();
    

    // The powerful schema that will allow the Workshop (crystal) prices to fluctuate based on performance, keeping the game fresh & evolve over time!
    
    function getCostForRace(uint8 race) public constant returns (uint8 cost) {
        return 0; // born equal (under current config)
    }
    
    function getCostForTrait(uint8 trait) public constant returns (uint24 cost) {
        if (trait == uint8(CardConfig.Trait.Normal)) {
            return 0;
        }
        return 40000;
    }
    
    function getSpellAbility(uint32 randomSeed) public constant returns (uint24 cost, uint8 spell) {
        spell = uint8(spellAbilities.getSpell(randomSeed)) + 1;
        return (getSpellAbilityCost(spell), spell);
    }
    
    function getSpellAbilityCost(uint8 spell) public constant returns (uint24 cost) {
        return 100000;
    }

    function getNeutralMutation(uint32 randomSeed) public constant returns (uint24 cost, uint8 mutation) {
        mutation = uint8(neutralMutations.getMutation(randomSeed)) + 1;
        return (getNeutralMutationCost(mutation), mutation);
    }
    
    function getNeutralMutationCost(uint8 mutation) public constant returns (uint24 cost) {
        if (mutation == 0) {
            return 0;   
        }
        return 40000;
    }

    function getMutationForRace(Race race, uint32 randomSeed) public constant returns (uint24 cost, uint8 mutation) {
        if (race == Race.Dragon) {
            mutation = uint8(dragonMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Spiderling) {
            mutation = uint8(spiderlingMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Demon) {
            mutation = uint8(demonMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Humanoid) {
            mutation = uint8(humanoidMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Beast) {
            mutation = uint8(beastMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Undead) {
            mutation = uint8(undeadMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Elemental) {
            mutation = uint8(elementalMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Vampire) {
            mutation = uint8(vampireMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Serpent) {
            mutation = uint8(serpentMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Mech) {
            mutation = uint8(mechMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Golem) {
            mutation = uint8(golemMutations.getRaceMutation(randomSeed)) + 1;
        } else if (race == Race.Parasite) {
            mutation = uint8(parasiteMutations.getRaceMutation(randomSeed)) + 1;
        }
        return (getRaceMutationCost(race, mutation), mutation);
    }
    
    function getRaceMutationCost(Race race, uint8 mutation) public constant returns (uint24 cost) {
        if (mutation == 0) {
            return 0;   
        }
        return 40000;
    }
    
    function getCostForHealth(uint8 health) public constant returns (uint24 cost) {
        return health * uint24(2000);
    }
    
    function getHealthForCost(uint32 cost) public constant returns (uint32 health) {
        health = cost / 2000;
        if (health > 98) { // 1+[0-98] (gotta have [1-99] health)
            health = 98;
        }
        return health;
    }
    
    function getCostForAttack(uint8 attack) public constant returns (uint24 cost) {
        return attack * uint24(2000);
    }
    
    function getAttackForCost(uint32 cost) public constant returns (uint32 attack) {
       attack = cost / 2000;
        if (attack > 99) {
            attack = 99;
        }
        return attack;
    }
    
}

contract SpellAbilities {
    enum Spells {LavaBlast, FlameNova, Purify, IceBlast, FlashFrost, SnowStorm, FrostFlurry, ChargeFoward, DeepFreeze, ThawTarget,
                 FlashOfLight, LightBeacon, BlackHole, Earthquake, EnchantArmor, EnchantWeapon, CallReinforcements, ParalysisPotion,
                 InflictFear, ArcaneVision, KillShot, DragonsBreath, GlacialShard, BlackArrow, DivineKnowledge, LightningVortex,
                 SolarFlare, PrimalBurst, RagingStorm, GiantCyclone, UnleashDarkness, ChargedOrb, UnholyMight, PowerShield, HallowedMist,
                 EmbraceLight, AcidRain, BoneFlurry, Rejuvenation, DeathGrip, SummonSwarm, MagicalCharm, EnchantedSilence, SolemnStrike,
                 ImpendingDoom, SpreadingFlames, ShadowLance, HauntedCurse, LightningShock, PowerSurge}
    uint16 constant numSpells = 50;

    function getSpell(uint32 randomSeed) public constant returns (Spells spell) {
        return Spells(randomSeed % numSpells);
    }
}


contract SharedNeutralMutations {
    enum Mutations {Frontline, CallReinforcements, ArmorPiercing, Battlecry, HealAlly, LevelUp, SecondWind, ChargingStrike, SpellShield, AugmentMagic, CrystalSiphon, 
                    ManipulateCrystals, DeadlyDemise, FlameResistance, IceResistance, LightningResistance, PoisonResistance, CurseResistance, DragonSlayer, SpiderlingSlayer,
                    VampireSlayer, DemonSlayer, HumanoidSlayer, BeastSlayer, UndeadSlayer, SerpentSlayer, MechSlayer, GolemSlayer, ElementalSlayer, ParasiteSlayer}
    uint16 constant numMutations = 30;

    function getMutation(uint32 randomSeed) public constant returns (Mutations mutation) {
        return Mutations(randomSeed % numMutations);
    }
}


contract DragonMutations {
    enum RaceMutations {FireBreath, HornedTail, BloodMagic, BarbedScales, WingedFlight, EggSpawn, Chronoshift, PhoenixFeathers}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract SpiderlingMutations {
    enum RaceMutations {CripplingBite, BurrowTrap, SkitteringFrenzy, EggSpawn, CritterRush, WebCocoon, SummonBroodmother, TremorSense}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract VampireMutations {
    enum RaceMutations {Bloodlink, LifeLeech, Bloodlust, DiamondSkin, TwilightVision, Regeneration, PiercingFangs, Shadowstrike}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract DemonMutations {
    enum RaceMutations {PyreScales, ShadowRealm, MenacingGaze, Hellfire, RaiseAsh, TailLash, ReapSouls, BladedTalons}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract HumanoidMutations {
    enum RaceMutations {Garrison, Entrench, Flagbearer, LegionCommander, ScoutAhead, Vengeance, EnchantedBlade, HorseRider}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract BeastMutations {
    enum RaceMutations {FeralRoar, FelineClaws, PrimitiveTusks, ArcticFur, PackHunter, FeignDeath, RavenousBite, NightProwl}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract UndeadMutations {
    enum RaceMutations {Reconstruct, AnimateDead, Pestilence, CrystalSkull, PsychicScreech, RavageSwipe, SpiritForm, BoneSpikes}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract SerpentMutations {
    enum RaceMutations {Constrict, BurrowingStrike, PetrifyingGaze, EggSpawn, ShedScales, StoneBasilisk, EngulfPrey, SprayVenom}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract MechMutations {
    enum RaceMutations {WhirlingBlade, RocketBoosters, SelfDestruct, EMPScramble, SpareParts, Deconstruct, TwinCannons, PowerShield}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract GolemMutations {
    enum RaceMutations {StoneSentinel, ShatteringSmash, AnimateMud, MoltenCore, TremorGround, VineSprouts, ElementalRoar, FossilArmy}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract ElementalMutations {
    enum RaceMutations {Sandstorm, SolarFlare, ElectricSurge, AquaRush, SpiritChannel, PhaseShift, CosmicAura, NaturesWrath}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

contract ParasiteMutations {
    enum RaceMutations {Infestation, BloodLeech, Corruption, ProtectiveShell, TailSwipe, ExposeWound, StingingTentacles, EruptiveGut}
    uint16 constant numMutations = 8;

    function getRaceMutation(uint32 randomSeed) public constant returns (RaceMutations mutation) {
        return RaceMutations(randomSeed % numMutations);
    }
}

// Pulling checks like this into secondary contract allows for more extensibility in future (LoanMarketplace and so forth.)
contract TransferRestrictionVerifier {
    MappedMarketplace marketplaceContract = MappedMarketplace(0xc3d2736b3e4f0f78457d75b3b5f0191a14e8bd57);
    
    function isAvailableForTransfer(uint64 cardId) external constant returns(bool) {
        return !marketplaceContract.isListed(cardId);
    }
}




contract MappedMarketplace {
    EtherGenCore storageContract; // Main card storage and ERC721 transfer functionality
    TransferRestrictionVerifier transferRestrictionVerifier; // Allows future stuff (loan marketplace etc.) to restrict listing same card twice
    
    uint24 private constant removalDuration = 14 days; // Listings can be pruned from market after 14 days
    uint8 private constant marketCut = 100; // 1% (not 100% as it is divided)
    address public owner = 0x08F4aE96b647B30177cc15B21195960625BA4163;
    bool public paused = false;

    mapping(uint64 => Listing) private listings;
    mapping(address => bool) private whitelistedContracts;
    uint64[] private listedCardIds;

    struct Listing {
        uint64 listingPointer; // Index in the Market&#39;s listings
        
        uint64 cardId;
        uint64 listTime; // Seconds
        uint128 startPrice;
        uint128 endPrice;
        uint24 priceChangeDuration; // Seconds
    }
    
    function isListed(uint64 cardId) public constant returns(bool) {
        if (listedCardIds.length == 0) return false;
        return (listings[cardId].listTime > 0);
    }
    
    function getMarketSize() external constant returns(uint) {
        return listedCardIds.length;
    }
    
    function listCard(uint64 cardId, uint128 startPrice, uint128 endPrice, uint24 priceChangeDuration) external {
        require(storageContract.ownerOf(cardId) == msg.sender);
        require(storageContract.isCardTradeable(cardId));
        require(transferRestrictionVerifier.isAvailableForTransfer(cardId));
        require(isWhitelisted(msg.sender));
        require(!paused);
        require(startPrice > 99 szabo && startPrice <= 10 ether);
        require(endPrice > 99 szabo && endPrice <= 10 ether);
        require(priceChangeDuration > 21599 && priceChangeDuration < 259201); // 6-72 Hours
       
        listings[cardId] = Listing(0, cardId, uint64(now), startPrice, endPrice, priceChangeDuration);
        listings[cardId].listingPointer = uint64(listedCardIds.push(cardId) - 1);
    }
    
    
    function purchaseCard(uint64 cardId) payable external {
        require(isListed(cardId));
        require(!paused);

        uint256 price = getCurrentPrice(listings[cardId].startPrice, listings[cardId].endPrice, listings[cardId].priceChangeDuration, (uint64(now) - listings[cardId].listTime));
        require(msg.value >= price);
        
        address seller = storageContract.ownerOf(cardId);
        uint256 sellerProceeds = price - (price / marketCut); // 1% cut
        
        removeListingInternal(cardId);
        seller.transfer(sellerProceeds);
        
        uint256 bidExcess = msg.value - price;
        if (bidExcess > 1 szabo) { // Little point otherwise they&#39;ll just pay more in gas
            msg.sender.transfer(bidExcess);
        }
        
        storageContract.transferFrom(seller, msg.sender, cardId);
    }
    
    function getCurrentPrice(uint128 startPrice, uint128 endPrice, uint24 priceChangeDuration, uint64 secondsSinceListing) public constant returns (uint256) {
        if (secondsSinceListing >= priceChangeDuration) {
            return endPrice;
        } else {
            int256 totalPriceChange = int256(endPrice) - int256(startPrice); // Can be negative
            int256 currentPriceChange = totalPriceChange * int256(secondsSinceListing) / int256(priceChangeDuration);
            return uint256(int256(startPrice) + currentPriceChange);
        }
    }
    
    function removeListing(uint64 cardId) external {
        require(isListed(cardId));
        require(!paused);
        require(storageContract.ownerOf(cardId) == msg.sender || (now - listings[cardId].listTime) > removalDuration);
        removeListingInternal(cardId);
    }
    
    function removeListingInternal(uint64 cardId) internal {
        if (listedCardIds.length > 1) {
            uint64 rowToDelete = listings[cardId].listingPointer;
            uint64 keyToMove = listedCardIds[listedCardIds.length - 1];
            
            listedCardIds[rowToDelete] = keyToMove;
            listings[keyToMove].listingPointer = rowToDelete;
        }
        
        listedCardIds.length--;
        delete listings[cardId];
    }
    
    
    function getListings() external constant returns (uint64[], address[], uint64[], uint128[], uint128[], uint24[], uint8[14][]) {
        uint64[] memory cardIds = new uint64[](listedCardIds.length); // Not ideal but web3.js didn&#39;t like returning multiple 2d arrays
        address[] memory cardOwners = new address[](listedCardIds.length);
        uint64[] memory listTimes = new uint64[](listedCardIds.length);
        uint128[] memory startPrices = new uint128[](listedCardIds.length);
        uint128[] memory endPrices = new uint128[](listedCardIds.length);
        uint24[] memory priceChangeDurations = new uint24[](listedCardIds.length);
        uint8[14][] memory cardDetails = new uint8[14][](listedCardIds.length);
        
        for (uint64 i = 0; i < listedCardIds.length; i++) {
            Listing memory listing = listings[listedCardIds[i]];
            cardDetails[i] = storageContract.getCard(listing.cardId);
            cardOwners[i] = storageContract.ownerOf(listing.cardId);
            cardIds[i] = listing.cardId;
            listTimes[i] = listing.listTime;
            startPrices[i] = listing.startPrice;
            endPrices[i] = listing.endPrice;
            priceChangeDurations[i] = listing.priceChangeDuration;
        }
        return (cardIds, cardOwners, listTimes, startPrices, endPrices, priceChangeDurations, cardDetails);
    }
    
    function getListingAtPosition(uint64 i) external constant returns (uint128[5]) {
        Listing memory listing = listings[listedCardIds[i]];
        return ([listing.cardId, listing.listTime, listing.startPrice, listing.endPrice, listing.priceChangeDuration]);
    }
    
    function getListing(uint64 cardId) external constant returns (uint128[5]) {
        Listing memory listing = listings[cardId];
        return ([listing.cardId, listing.listTime, listing.startPrice, listing.endPrice, listing.priceChangeDuration]);
    }
    
    // Contracts can&#39;t list cards without contacting us (wallet addresses are unaffected)
    function isWhitelisted(address seller) internal constant returns (bool) {
        uint size;
        assembly { size := extcodesize(seller) }
        return size == 0 || whitelistedContracts[seller];
    }
    
    function whitelistContract(address seller, bool whitelisted) external {
        require(msg.sender == owner);
        whitelistedContracts[seller] = whitelisted;
    }
    
    function updateStorageContract(address newStorage) external {
        require(msg.sender == owner);
        storageContract = EtherGenCore(newStorage);
    }
    
    function updateTransferRestrictionVerifier(address newTransferRestrictionVerifier) external {
        require(msg.sender == owner);
        transferRestrictionVerifier = TransferRestrictionVerifier(newTransferRestrictionVerifier);
    }
    
    function setPaused(bool shouldPause) external {
        require(msg.sender == owner);
        paused = shouldPause;
    }
    
    function updateOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }
    
    function withdrawBalance() external {
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }

}