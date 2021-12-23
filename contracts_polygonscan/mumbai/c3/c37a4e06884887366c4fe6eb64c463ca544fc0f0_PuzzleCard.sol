// SPDX-License-Identifier: UNLICENSED

// This is an ERC1155-compliant smart contract that manages 'Puzzle Cards'.
//
// Puzzle Cards are a collection of semi-fungible and non-fungible tokens that
// can be minted and combined in various ways according to 'recipes'.
//
// This collection was created by Chris Patuzzo and is an accompaniment to his
// upcoming puzzle/platform video game 'Worship the Sun'. All proceeds go to
// supporting Chris's work and towards making the game as enjoyable as possible.
//
// All of the contract and website code is fully auditable and open on GitHub.
// Puzzle Cards can be freely shared on social media, OpenSea, etc. Everything
// else (e.g. code, images) is Copyright, Chris Patuzzo, All Rights Reserved.
//
// This contract supports many ERC1155 extensions such as ERC1155MetadataURI and
// ERC1155Supply. A JavaScript library (PuzzleCard.js) is provided to make it
// easier to work with the contract, e.g. to check which actions can be performed.
//
// - Website: https://puzzlecards.github.io/
// - Library: https://puzzlecards.github.io/PuzzleCard.js
// - GitHub: https://github.com/tuzz/puzzle-cards
// - Twitter: https://twitter.com/chrispatuzzo
// - License: Copyright 2021, Chris Patuzzo, All Rights Reserved

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./vendor/ContextMixin.sol";
import "./vendor/NativeMetaTransaction.sol";
import "./vendor/ProxyRegistry.sol";

//import "hardhat/console.sol";

contract PuzzleCard is ERC1155, Ownable, ContextMixin, NativeMetaTransaction {
    string public name = "Worship the Sun Puzzle Cards";
    string public symbol = "WSUN";

    struct Attributes {
        uint8 series;
        uint8 puzzle;
        uint8 tier;
        uint8 type_;
        uint8 color1;
        uint8 color2;
        uint8 variant;
        uint8 condition;
        uint8 edition;
    }

    mapping(uint256 => uint256) public totalSupply;
    mapping(address => uint8) public maxTierUnlocked;
    mapping(uint256 => uint256) public limitedEditions;
    mapping(uint16 => uint8) public masterCopyClaimedAt;
    uint256 public basePriceInWei = 5263157894736843; // $0.01

    constructor(address proxyRegistryAddress) ERC1155("") {
        PROXY_REGISTRY_ADDRESS = proxyRegistryAddress;
        CONTRACT_METADATA_URI = "https://d3fjxldyah6ziy.cloudfront.net/metadata_api/contract.json";

        _setURI("https://d3fjxldyah6ziy.cloudfront.net/metadata_api/{id}.json");
        _initializeEIP712(name);
    }

    function contractURI() external view returns (string memory) {
      return CONTRACT_METADATA_URI;
    }

    function exists(uint256 tokenID) external view returns (bool) {
      return totalSupply[tokenID] != 0;
    }

    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        ProxyRegistry registry = ProxyRegistry(PROXY_REGISTRY_ADDRESS);
        return address(registry.proxies(owner)) == operator || ERC1155.isApprovedForAll(owner, operator);
    }

    // minting

    function mint(uint256 numberToMint, uint8 tier, address to) external payable {
        if (msg.sender != owner()) {
          require(MINTING_CARDS_ENABLED);
          require(tier <= maxTierUnlocked[msg.sender]);
          payable(owner()).transfer(basePriceInWei * numberToMint * MINT_PRICE_MULTIPLERS[tier]);
        }

        if (to == address(0)) { to = msg.sender; }
        mintStarterCards(numberToMint, tier, to);
    }

    function unlockMintingAtAllTiers(address address_) external payable {
        if (address_ == address(0)) { address_ = msg.sender; }
        require(maxTierUnlocked[address_] < MASTER_TIER);

        if (msg.sender != owner()) {
          payable(owner()).transfer(basePriceInWei * UNLOCK_PRICE_MULTIPLIER);
        }

        maxTierUnlocked[address_] = MASTER_TIER;
    }

    function mintStarterCards(uint256 numberToMint, uint8 tier, address to) private {
        uint256[] memory tokenIDs = new uint256[](numberToMint);
        uint256[] memory oneOfEach = new uint256[](numberToMint);

        for (uint256 i = 0; i < numberToMint; i += 1) {
            uint8 condition = PRISTINE_CONDITION - uint8(randomNumber() % 3);
            uint256 newCardID = tokenIDForCard(starterCardForTier(tier, condition));

            tokenIDs[i] = newCardID;
            oneOfEach[i] = 1;
            totalSupply[newCardID] += 1;
        }

        _mintBatch(to, tokenIDs, oneOfEach, "");
    }

    function starterCardForTier(uint8 tier, uint8 condition) private returns (Attributes memory) {
        uint256[] memory typeProbabilities =
          tier == MASTER_TIER                        ? MASTER_TYPE_PROBABILITIES_CUMULATIVE :
          tier == VIRTUAL_TIER || tier == GODLY_TIER ? VIRTUAL_TYPE_PROBABILITIES_CUMULATIVE :
                                                       STANDARD_TYPE_PROBABILITIES_CUMULATIVE;

        return randomCard(tier, condition, typeProbabilities);
    }

    function randomCard(uint8 tier, uint8 condition, uint256[] memory typeProbabilities) private returns (Attributes memory) {
        (uint8 series, uint8 puzzle) = randomPuzzle();
        uint8 type_ = pickRandom(typeProbabilities);
        (uint8 color1, uint8 color2) = randomColors(tier, type_);
        uint8 variant = randomVariant(type_);

        return Attributes(series, puzzle, tier, type_, color1, color2, variant, condition, STANDARD_EDITION);
    }

    // actions

    function activateSunOrMoon(uint256[] memory tokenIDs) external {
        (bool ok,) = canActivateSunOrMoon(tokenIDs); require(ok);

        uint256 inactiveID = tokenIDs[1];

        (uint8 series, uint8 puzzle) = randomPuzzle();
        uint8 tier = tierForTokenID(inactiveID);
        uint8 type_ = ACTIVE_TYPE;
        uint8 color1 = color1ForTokenID(inactiveID);
        uint8 color2 = 0;
        uint8 variant = variantForTokenID(inactiveID);
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        replace(tokenIDs, Attributes(series, puzzle, tier, type_, color1, color2, variant, condition, STANDARD_EDITION));
    }

    function canActivateSunOrMoon(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 2, [ACTIVATOR_TYPE, INACTIVE_TYPE, 0, 0, 0, 0, 0], errors);
        ok = ok && cloakCanActivateSunOrMoon(tokenIDs, errors);

        return (ok, errors);
    }

    function lookThroughTelescope(uint256[] memory tokenIDs) external {
        (bool ok,) = canLookThroughTelescope(tokenIDs); require(ok);

        (uint8 series, uint8 puzzle) = randomPuzzle();
        uint8 tier = tierForTokenID(tokenIDs[0]);
        uint8 type_ = HELIX_TYPE + uint8(randomNumber() % 3);
        (uint8 color1, uint8 color2) = randomColors(tier, type_);
        uint8 variant = randomVariant(type_);
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        replace(tokenIDs, Attributes(series, puzzle, tier, type_, color1, color2, variant, condition, STANDARD_EDITION));
    }

    function canLookThroughTelescope(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 3, [PLAYER_TYPE, ACTIVE_TYPE, TELESCOPE_TYPE, 0, 0, 0, 0], errors);
        if (!ok) { return (false, errors); }

        uint256 activeID = tokenIDs[1];
        uint256 telescopeID = tokenIDs[2];

        bool matches = variantForTokenID(activeID) == variantForTokenID(telescopeID)
                    && color1ForTokenID(activeID) == color1ForTokenID(telescopeID);

        if (!matches) { ok = false; errors[TELESCOPE_DOESNT_MATCH] = true; }

        return (ok, errors);
    }

    function lookThroughGlasses(uint256[] memory tokenIDs) external {
        (bool ok,) = canLookThroughGlasses(tokenIDs); require(ok);

        uint256 glassesID = tokenIDs[1];

        uint8 tier = tierForTokenID(glassesID);
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        replace(tokenIDs, randomCard(tier, condition, POST_VIRTUAL_TYPE_PROBABILITIES_CUMULATIVE));

        if (color1ForTokenID(glassesID) != color2ForTokenID(glassesID)) {
          condition = randomlyDegrade(tokenIDs, tier);
          mintCard(randomCard(tier, condition, POST_VIRTUAL_TYPE_PROBABILITIES_CUMULATIVE));
        }
    }

    function canLookThroughGlasses(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 3, [PLAYER_TYPE, GLASSES_TYPE, HIDDEN_TYPE, 0, 0, 0, 0], errors);
        return (ok, errors);
    }

    function changeLensColor(uint256[] memory tokenIDs) external {
        (bool ok,) = canChangeLensColor(tokenIDs); require(ok);

        uint256 lensID = tokenIDs[2];
        uint8 activatedColor = color1ForTokenID(tokenIDs[1]);

        (uint8 series, uint8 puzzle) = randomPuzzle();
        uint8 tier = tierForTokenID(lensID);
        uint8 type_ = typeForTokenID(lensID);
        uint8 color1 = color2ForTokenID(lensID);
        uint8 color2 = color1ForTokenID(lensID);
        uint8 variant = randomVariant(type_);
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        if (activatedColor != color1 && activatedColor != color2) {
            if (randomNumber() % 2 == 0) {
              color1 = activatedColor;
            } else {
              color2 = activatedColor;
            }
        }

        replace(tokenIDs, Attributes(series, puzzle, tier, type_, color1, color2, variant, condition, STANDARD_EDITION));
    }

    function canChangeLensColor(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 3, [ACTIVATOR_TYPE, INACTIVE_TYPE, LENS_TYPE, 0, 0, 0, 0], errors);
        ok = ok && cloakCanActivateSunOrMoon(tokenIDs, errors);

        return (ok, errors);
    }

    function shineTorchOnBasePair(uint256[] memory tokenIDs) external {
        (bool ok,) = canShineTorchOnBasePair(tokenIDs); require(ok);

        (uint8 series, uint8 puzzle) = randomPuzzle();
        uint8 tier = tierForTokenID(tokenIDs[0]);
        uint8 type_ = MAP_TYPE + uint8(randomNumber() % 2);
        uint8 color1 = 0;
        uint8 color2 = 0;
        uint8 variant = randomVariant(type_);
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        replace(tokenIDs, Attributes(series, puzzle, tier, type_, color1, color2, variant, condition, STANDARD_EDITION));
    }

    function canShineTorchOnBasePair(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 3, [PLAYER_TYPE, HELIX_TYPE, TORCH_TYPE, 0, 0, 0, 0], errors);

        uint256 helixID = tokenIDs[1];
        uint256 torchID = tokenIDs[2];

        bool colorsMatch = color1ForTokenID(helixID) == color1ForTokenID(torchID)
                        && color2ForTokenID(helixID) == color2ForTokenID(torchID);

        if (!colorsMatch) { ok = false; errors[TORCH_DOESNT_MATCH] = true; }

        return (ok, errors);
    }

    function teleportToNextArea(uint256[] memory tokenIDs) external {
        (bool ok,) = canTeleportToNextArea(tokenIDs); require(ok);

        uint8 tier = tierForTokenID(tokenIDs[0]);
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        unlockMintingAtTier(tier + 1);
        replace(tokenIDs, starterCardForTier(tier + 1, condition));
    }

    function canTeleportToNextArea(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 3, [PLAYER_TYPE, MAP_TYPE, TELEPORT_TYPE, 0, 0, 0, 0], errors);
        return (ok, errors);
    }

    function goThroughStarDoor(uint256[] memory tokenIDs) external {
        (bool ok,) = canGoThroughStarDoor(tokenIDs); require(ok);

        uint8 tier = tierForTokenID(tokenIDs[0]);
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        unlockMintingAtTier(tier + 1);
        replace(tokenIDs, starterCardForTier(tier + 1, condition));
    }

    function canGoThroughStarDoor(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 2, [PLAYER_TYPE, DOOR_TYPE, 0, 0, 0, 0, 0], errors);

        if (ok && variantForTokenID(tokenIDs[1]) != OPEN_VARIANT) { ok = false; errors[DOOR_IS_CLOSED] = true; }

        return (ok, errors);
    }

    function jumpIntoBeacon(uint256[] memory tokenIDs) external {
        (bool ok,) = canJumpIntoBeacon(tokenIDs); require(ok);

        uint8 beaconColor = color1ForTokenID(tokenIDs[1]);
        uint256 lensID = tokenIDs[2];

        (uint8 series, uint8 puzzle) = randomPuzzle();
        uint8 tier = tierForTokenID(lensID);
        uint8 type_ = typeForTokenID(lensID);
        uint8 color1 = beaconColor;
        uint8 color2 = beaconColor;
        uint8 variant = randomVariant(type_);
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        replace(tokenIDs, Attributes(series, puzzle, tier, type_, color1, color2, variant, condition, STANDARD_EDITION));
    }

    function canJumpIntoBeacon(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 3, [PLAYER_TYPE, BEACON_TYPE, LENS_TYPE, 0, 0, 0, 0], errors);
        return (ok, errors);
    }

    function jumpIntoEclipse(uint256[] memory tokenIDs) external {
        (bool ok,) = canJumpIntoEclipse(tokenIDs); require(ok);

        (uint8 series, uint8 puzzle) = randomPuzzle();
        uint8 tier = tierForTokenID(tokenIDs[0]);
        uint8 type_ = DOOR_TYPE;
        uint8 color1 = 0;
        uint8 color2 = 0;
        uint8 variant = OPEN_VARIANT;
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        replace(tokenIDs, Attributes(series, puzzle, tier, type_, color1, color2, variant, condition, STANDARD_EDITION));
    }

    function canJumpIntoEclipse(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 3, [PLAYER_TYPE, ECLIPSE_TYPE, DOOR_TYPE, 0, 0, 0, 0], errors);

        if (ok && variantForTokenID(tokenIDs[2]) == OPEN_VARIANT) { ok = false; errors[DOOR_IS_OPEN] = true; }

        return (ok, errors);
    }

    function puzzleMastery1(uint256[] memory tokenIDs) external {
        (bool ok,) = canPuzzleMastery1(tokenIDs); require(ok);

        uint256 artworkID1 = tokenIDs[0];

        uint8 series = seriesForTokenID(artworkID1);
        uint8 puzzle = puzzleForTokenID(artworkID1);
        uint8 tier = MASTER_TIER;
        uint8 type_ = STAR_TYPE;
        uint8 color1 = 1 + uint8(randomNumber() % NUM_COLORS);
        uint8 color2 = 0;
        uint8 variant = randomVariant(type_);
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        replace(tokenIDs, Attributes(series, puzzle, tier, type_, color1, color2, variant, condition, STANDARD_EDITION));
    }

    function canPuzzleMastery1(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 2, [ARTWORK_TYPE, ARTWORK_TYPE, 0, 0, 0, 0, 0], errors);
        if (!ok) { return (false, errors); }

        uint256 artworkID1 = tokenIDs[0];
        uint256 artworkID2 = tokenIDs[1];

        bool samePuzzle = seriesForTokenID(artworkID1) == seriesForTokenID(artworkID2)
                       && puzzleForTokenID(artworkID1) == puzzleForTokenID(artworkID2);

        bool standardEdition = editionForTokenID(artworkID1) == STANDARD_EDITION
                            && editionForTokenID(artworkID2) == STANDARD_EDITION;

        if (!samePuzzle)           { ok = false; errors[PUZZLES_DONT_MATCH] = true; }
        if (!standardEdition)      { ok = false; errors[ART_ALREADY_SIGNED] = true; }
        if (doubleSpent(tokenIDs)) { ok = false; errors[SAME_CARD_USED_TWICE] = true; }

        return (ok, errors);
    }

    function puzzleMastery2(uint256[] memory tokenIDs) external {
        (bool ok,) = canPuzzleMastery2(tokenIDs); require(ok);

        uint256 starID = tokenIDs[randomNumber() % 7];

        uint8 series = seriesForTokenID(starID);
        uint8 puzzle = puzzleForTokenID(starID);
        uint8 tier = MASTER_TIER;
        uint8 type_ = ARTWORK_TYPE;
        uint8 color1 = 0;
        uint8 color2 = 0;
        uint8 variant = randomVariant(type_);
        uint8 condition = randomlyDegrade(tokenIDs, tier);
        uint8 edition = SIGNED_EDITION;

        bool allPristine = true;

        for (uint8 i = 0; i < tokenIDs.length; i += 1) {
            allPristine = allPristine && conditionForTokenID(tokenIDs[i]) == PRISTINE_CONDITION;
        }

        if (allPristine) {
            condition = PRISTINE_CONDITION;

            uint16 editionsKey_ = editionsKey(series, puzzle);
            uint256 numOthers = limitedEditions[editionsKey_];

            if (numOthers < MAX_LIMITED_EDITIONS) {
                edition = LIMITED_EDITION;
                limitedEditions[editionsKey_] += 1;

                if (masterCopyClaimedAt[editionsKey_] == 0) {
                  uint256 shortenedOdds = MAX_LIMITED_EDITIONS - numOthers;

                  if (randomNumber() % shortenedOdds == 0) {
                    edition = MASTER_COPY_EDITION;
                    masterCopyClaimedAt[editionsKey_] = uint8(numOthers + 1);
                  }
                }
            }
        }

        replace(tokenIDs, Attributes(series, puzzle, tier, type_, color1, color2, variant, condition, edition));
    }

    function canPuzzleMastery2(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 7, [STAR_TYPE, STAR_TYPE, STAR_TYPE, STAR_TYPE, STAR_TYPE, STAR_TYPE, STAR_TYPE], errors);

        bool[8] memory colorsUsed = [false, false, false, false, false, false, false, false];

        for (uint8 i = 0; i < 7; i += 1) {
            uint8 color = color1ForTokenID(tokenIDs[i]);

            if (colorsUsed[color]) { ok = false; errors[STAR_COLOR_REPEATED] = true; }
            colorsUsed[color] = true;
        }

        return (ok, errors);
    }

    function discard2Pickup1(uint256[] memory tokenIDs) external {
        (bool ok,) = canDiscard2Pickup1(tokenIDs); require(ok);

        uint256 tokenID1 = tokenIDs[0];
        uint256 tokenID2 = tokenIDs[1];

        removeLimitedOrMasterEdition(tokenID1);
        removeLimitedOrMasterEdition(tokenID2);

        uint8 tier = tierForTokenID(tokenID1);
        uint8 condition = randomlyDegrade(tokenIDs, tier);

        replace(tokenIDs, starterCardForTier(tier, condition));
    }

    function canDiscard2Pickup1(uint256[] memory tokenIDs) public view returns (bool ok, bool[34] memory errors) {
        ok = basicChecksPassed(tokenIDs, 2, [ANY_TYPE, ANY_TYPE, 0, 0, 0, 0, 0], errors);

        if (ok && doubleSpent(tokenIDs)) { ok = false; errors[SAME_CARD_USED_TWICE] = true; }

        return (ok, errors);
    }

    // utilities

    function basicChecksPassed(uint256[] memory tokenIDs, uint8 numCards, uint8[7] memory types, bool[34] memory errors) private view returns (bool ok) {
        ok = true;

        uint256 length = tokenIDs.length;

        if (numCards != length) { ok = false; errors[NUM_CARDS_REQUIRED + length] = true; }

        if (!ownsAll(tokenIDs))           { ok = false; errors[DOESNT_OWN_CARDS] = true; }
        if (!ok)                          { return false; }

        uint8 tier = tierForTokenID(tokenIDs[0]);

        for (uint8 i = 0; i < tokenIDs.length; i += 1) {
            bool tierOk = tier == tierForTokenID(tokenIDs[i]);

            uint8 type_ = typeForTokenID(tokenIDs[i]);
            uint8 expected = types[i];

            bool typeOk = expected == type_
                       || expected == ANY_TYPE
                       || expected == LENS_TYPE && (type_ == TORCH_TYPE || type_ == GLASSES_TYPE)
                       || expected == ACTIVATOR_TYPE && type_ <= CLOAK_TYPE;

            if (!tierOk) { ok = false; errors[TIERS_DONT_MATCH] = true; }
            if (!typeOk) { ok = false; errors[expected] = true; }
        }

        return ok;
    }

    function ownsAll(uint256[] memory tokenIDs) private view returns (bool) {
        for (uint8 i = 0; i < tokenIDs.length; i += 1) {
            if (balanceOf(msg.sender, tokenIDs[i]) == 0) { return false; }
        }

        return true;
    }

    function doubleSpent(uint256[] memory tokenIDs) private view returns (bool) {
        return tokenIDs[0] == tokenIDs[1] && balanceOf(msg.sender, tokenIDs[0]) < 2;
    }

    function cloakCanActivateSunOrMoon(uint256[] memory tokenIDs, bool[34] memory errors) private pure returns (bool ok) {
        ok = true;

        uint256 activatorID = tokenIDs[0];
        uint256 inactiveID = tokenIDs[1];

        bool cloakUsed = typeForTokenID(activatorID) == CLOAK_TYPE;
        bool colorsMatch = color1ForTokenID(activatorID) == color1ForTokenID(inactiveID);

        uint8 tier = tierForTokenID(inactiveID);
        bool inaccessible = tier == ETHEREAL_TIER || tier == GODLY_TIER;

        if (cloakUsed && !colorsMatch)  { ok = false; errors[CLOAK_DOESNT_MATCH] = true; }
        if (!cloakUsed && inaccessible) { ok = false; errors[CLOAK_REQUIRED_AT_TIER] = true; }

        return ok;
    }

    function removeLimitedOrMasterEdition(uint256 tokenID) private {
        uint8 edition = editionForTokenID(tokenID);

        if (edition >= LIMITED_EDITION) {
            uint16 editionsKey_ = editionsKey(seriesForTokenID(tokenID), puzzleForTokenID(tokenID));
            limitedEditions[editionsKey_] -= 1;

            if (edition == MASTER_COPY_EDITION) {
                masterCopyClaimedAt[editionsKey_] = 0;
            }
        }
    }

    function replace(uint256[] memory tokenIDs, Attributes memory newCard) private {
        uint256[] memory oneOfEach = new uint256[](tokenIDs.length);
        for (uint8 i = 0; i < tokenIDs.length; i += 1) { oneOfEach[i] = 1; totalSupply[tokenIDs[i]] -= 1; }
        _burnBatch(msg.sender, tokenIDs, oneOfEach);

        mintCard(newCard);
    }

    function mintCard(Attributes memory newCard) private {
        uint256 newCardID = tokenIDForCard(newCard);
        _mint(msg.sender, newCardID, 1, "");
        totalSupply[newCardID] += 1;
    }

    function unlockMintingAtTier(uint8 tier) private {
        if (tier > maxTierUnlocked[msg.sender]) {
            maxTierUnlocked[msg.sender] = tier;
        }
    }

    // randomness

    function randomPuzzle() private returns (uint8, uint8) {
        uint256 random = randomNumber();

        // Use a random puzzle as a means of choosing a series uniformly random.
        uint8 puzzle = uint8(random % SERIES_FOR_EACH_PUZZLE.length);
        uint8 series = SERIES_FOR_EACH_PUZZLE[puzzle];

        // The actual puzzle is chosen here. We may as well reuse the randomness.
        uint8 relativePuzzle = uint8(random % NUM_PUZZLES_PER_SERIES[series]);

        return (series, relativePuzzle);
    }

    function randomColors(uint8 tier, uint8 type_) private returns (uint8, uint8) {
        uint8 numSlots = NUM_COLOR_SLOTS_PER_TYPE[type_];

        uint8 color1 = numSlots < 1 ? 0 : 1 + uint8(randomNumber() % NUM_COLORS);
        uint8 color2 = numSlots < 2 ? 0 :
          (type_ == HELIX_TYPE && (tier == CELESTIAL_TIER || tier == GODLY_TIER)) ? color1 :
          1 + uint8(randomNumber() % NUM_COLORS);

        return (color1, color2);
    }

    function randomVariant(uint8 type_) private returns (uint8) {
        uint8 numVariants = NUM_VARIANTS_PER_TYPE[type_];
        uint8 variant = numVariants < 1 ? 0 : uint8(randomNumber() % numVariants);

        return variant;
    }

    function randomlyDegrade(uint256[] memory tokenIDs, uint8 tier) private returns (uint8) {
        uint8 worstCondition = PRISTINE_CONDITION;

        for (uint8 i = 0; i < tokenIDs.length; i += 1) {
            uint8 condition = conditionForTokenID(tokenIDs[i]);
            if (condition < worstCondition) { worstCondition = condition; }
        }

        return worstCondition == DIRE_CONDITION || tier == IMMORTAL_TIER || tier == GODLY_TIER
             ? worstCondition
             : worstCondition - uint8(randomNumber() % 2);
    }

    function pickRandom(uint256[] memory cumulativeProbabilities) private returns (uint8 index) {
        uint256 outOf = cumulativeProbabilities[cumulativeProbabilities.length - 1];
        uint256 random = randomNumber() % outOf;

        for (uint8 i = 0; i < cumulativeProbabilities.length; i += 1) {
          if (random < cumulativeProbabilities[i]) { return i; }
        }
    }

    function randomNumber() private returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, block.difficulty, NUM_RANDOM_CALLS++)));
    }

    // conversions

    function tokenIDForCard(Attributes memory card) private pure returns (uint256) {
        return (
            uint256(card.series)    << 64 |
            uint256(card.puzzle)    << 56 |
            uint256(card.tier)      << 48 |
            uint256(card.type_)     << 40 |
            uint256(card.color1)    << 32 |
            uint256(card.color2)    << 24 |
            uint256(card.variant)   << 16 |
            uint256(card.condition) << 8  |
            uint256(card.edition)
        );
    }

    function seriesForTokenID(uint256 tokenID) private pure returns (uint8) { return uint8(tokenID >> 64); }
    function puzzleForTokenID(uint256 tokenID) private pure returns (uint8) { return uint8(tokenID >> 56); }
    function tierForTokenID(uint256 tokenID) private pure returns (uint8) { return uint8(tokenID >> 48); }
    function typeForTokenID(uint256 tokenID) private pure returns (uint8) { return uint8(tokenID >> 40); }
    function color1ForTokenID(uint256 tokenID) private pure returns (uint8) { return uint8(tokenID >> 32); }
    function color2ForTokenID(uint256 tokenID) private pure returns (uint8) { return uint8(tokenID >> 24); }
    function variantForTokenID(uint256 tokenID) private pure returns (uint8) { return uint8(tokenID >> 16); }
    function conditionForTokenID(uint256 tokenID) private pure returns (uint8) { return uint8(tokenID >> 8); }
    function editionForTokenID(uint256 tokenID) private pure returns (uint8) { return uint8(tokenID); }

    function editionsKey(uint8 series, uint8 puzzle) private pure returns (uint16) {
        return (uint16(series) << 8) | puzzle;
    }

    // constants

    uint8 private constant MORTAL_TIER = 0;
    uint8 private constant IMMORTAL_TIER = 1;
    uint8 private constant ETHEREAL_TIER = 2;
    uint8 private constant VIRTUAL_TIER = 3;
    uint8 private constant CELESTIAL_TIER = 4;
    uint8 private constant GODLY_TIER = 5;
    uint8 private constant MASTER_TIER = 6;

    uint8 private constant PLAYER_TYPE = 0;
    uint8 private constant CRAB_TYPE = 1;
    uint8 private constant CLOAK_TYPE = 2;
    uint8 private constant INACTIVE_TYPE = 3;
    uint8 private constant ACTIVE_TYPE = 4;
    uint8 private constant TELESCOPE_TYPE = 5;
    uint8 private constant HELIX_TYPE = 6;
    uint8 private constant BEACON_TYPE = 7;
    uint8 private constant TORCH_TYPE = 8;
    uint8 private constant MAP_TYPE = 9;
    uint8 private constant TELEPORT_TYPE = 10;
    uint8 private constant GLASSES_TYPE = 11;
    uint8 private constant ECLIPSE_TYPE = 12;
    uint8 private constant DOOR_TYPE = 13;
    uint8 private constant HIDDEN_TYPE = 14;
    uint8 private constant STAR_TYPE = 15;
    uint8 private constant ARTWORK_TYPE = 16;

    uint8 private constant ACTIVATOR_TYPE = 17;
    uint8 private constant LENS_TYPE = 18;
    uint8 private constant ANY_TYPE = 19;

    uint8 private constant NUM_CARDS_REQUIRED = 17;

    // TWO_CARDS_REQUIRED = NUM_CARDS_REQUIRED + 2 = 19
    // THREE_CARDS_REQUIRED = NUM_CARDS_REQUIRED + 3 = 20
    uint8 private constant TIERS_DONT_MATCH = 21;
    uint8 private constant DOESNT_OWN_CARDS = 22;
    uint8 private constant CLOAK_REQUIRED_AT_TIER = 23;
    // SEVEN_CARDS_REQUIRED = NUM_CARDS_REQUIRED + 7 = 24
    uint8 private constant CLOAK_DOESNT_MATCH = 25;
    uint8 private constant TELESCOPE_DOESNT_MATCH = 26;
    uint8 private constant TORCH_DOESNT_MATCH = 27;
    uint8 private constant PUZZLES_DONT_MATCH = 28;
    uint8 private constant DOOR_IS_OPEN = 29;
    uint8 private constant DOOR_IS_CLOSED = 30;
    uint8 private constant ART_ALREADY_SIGNED = 31;
    uint8 private constant SAME_CARD_USED_TWICE = 32;
    uint8 private constant STAR_COLOR_REPEATED = 33;

    uint8 private constant OPEN_VARIANT = 0; // Relative

    uint8 private constant DIRE_CONDITION = 0;
    uint8 private constant PRISTINE_CONDITION = 4;

    uint8 private constant STANDARD_EDITION = 0;
    uint8 private constant SIGNED_EDITION = 1;
    uint8 private constant LIMITED_EDITION = 2;
    uint8 private constant MASTER_COPY_EDITION = 3;

    uint8 private constant NUM_COLORS = 7;
    uint8 private constant MAX_LIMITED_EDITIONS = 100;

    uint8[] private NUM_PUZZLES_PER_SERIES = [4, 9, 13, 3, 7, 14, 14, 4, 3, 8, 4, 5, 6, 8, 4, 6, 4];
    uint8[] private SERIES_FOR_EACH_PUZZLE = [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 11, 11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13, 13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 16, 16, 16, 16];
    uint8[] private NUM_COLOR_SLOTS_PER_TYPE = [0, 0, 1, 1, 1, 1, 2, 1, 2, 0, 0, 2, 0, 0, 0, 1, 0];
    uint8[] private NUM_VARIANTS_PER_TYPE = [56, 6, 0, 2, 2, 2, 0, 0, 0, 8, 0, 0, 0, 2, 0, 0, 23];

    uint256[7] private MINT_PRICE_MULTIPLERS = [1, 2, 5, 10, 20, 50, 100];
    uint256 private UNLOCK_PRICE_MULTIPLIER = 10000;

    // These differ from PuzzleCard.js because these are cumulative.
    uint256[] private STANDARD_TYPE_PROBABILITIES_CUMULATIVE = [300, 400, 500, 700, 800, 900, 920, 940, 960, 970, 980, 990, 994, 1000];
    uint256[] private VIRTUAL_TYPE_PROBABILITIES_CUMULATIVE = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 3];
    uint256[] private POST_VIRTUAL_TYPE_PROBABILITIES_CUMULATIVE = [0, 1, 101, 301, 401, 501, 521, 541, 561, 571, 581, 581, 585, 591];
    uint256[] private MASTER_TYPE_PROBABILITIES_CUMULATIVE = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1];

    bool internal MINTING_CARDS_ENABLED;
    address private PROXY_REGISTRY_ADDRESS;
    string private CONTRACT_METADATA_URI;
    uint256 private NUM_RANDOM_CALLS = 0;

    // Be very careful not to invalidate existing cards when calling this method.
    // The arrays must be append only and not reorder or remove puzzles/variants.
    function updateConstants(
        bool mintingCardsEnabled,
        uint8[] memory numPuzzlesPerSeries,
        uint8[] memory seriesForEachPuzzle,
        uint8[] memory numVariantsPerType,
        uint256[7] memory mintPriceMultipliers,
        uint256 unlockPriceMultiplier,
        address proxyRegistryAddress,
        string memory contractMetadataURI,
        string memory tokenMetadataURI
    ) external onlyOwner {
        MINTING_CARDS_ENABLED = mintingCardsEnabled;
        NUM_PUZZLES_PER_SERIES = numPuzzlesPerSeries;
        SERIES_FOR_EACH_PUZZLE = seriesForEachPuzzle;
        NUM_VARIANTS_PER_TYPE = numVariantsPerType;
        MINT_PRICE_MULTIPLERS = mintPriceMultipliers;
        UNLOCK_PRICE_MULTIPLIER = unlockPriceMultiplier;
        PROXY_REGISTRY_ADDRESS = proxyRegistryAddress;
        CONTRACT_METADATA_URI = contractMetadataURI;
        _setURI(tokenMetadataURI);
    }

    function setBasePrice(uint256 _basePriceInWei) external onlyOwner {
        basePriceInWei = _basePriceInWei;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}