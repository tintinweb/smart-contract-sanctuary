// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/ICnMGame.sol";
import "./interfaces/ICnM.sol";
import "./interfaces/ICHEDDAR.sol";
import "./interfaces/IHabitat.sol";
import "./interfaces/IRandomizer.sol";
import "./interfaces/IHouse.sol";
import "./interfaces/IHouseGame.sol";

contract Habitat is IHabitat, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {

    // maximum rank for a Cat/Mouse
    uint8 public constant MAX_RANK = 8;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    // number of Mice stacked
    uint256 private numMiceStaked;
    // number of Cat stacked
    uint256 private numCatStaked;
    // number of CrazyCat stacked
    uint256 private numCrazyCatStaked;
    // number of Shack stacked
    uint256 private numShackStaked;
    // number of Ranch stacked
    uint256 private numRanchStaked;
    // number of Mansion stacked
    uint256 private numMansionStaked;

    uint256 public PERIOD = 1 days;

    event TokenStaked(address indexed owner, uint256 indexed tokenId, uint8 tokenType, uint256 value);
    event CatClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event CrazyCatLadyClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event MouseClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event HouseClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);

    // reference to the CnM NFT contract
    ICnM public cnmNFT;

    // reference to the House NFT contract
    IHouse public houseNFT;

    // reference to the CnM game contract
    ICnMGame public cnmGame;

    // reference to the CnM game contract
    IHouseGame public houseGame;

    // reference to the $CHEDDAR contract for minting $CHEDDAR earnings
    ICHEDDAR public cheddarToken;

    // reference to Randomizer
    IRandomizer public randomizer;

    // maps Mouse tokenId to stake
    mapping(uint256 => Stake) private habitat;
    // maps House tokenId to stake
    mapping(uint256 => Stake) private houseYield;

    // maps Cat tokenId to stake
    mapping(uint256 => Stake) private yield;
    // array of Cat token ids;
    uint256[] private yieldIds;
    // maps Crazy Lady Cat tokenId to stake
    mapping(uint256 => Stake) private crazyYield;
    // array of CrazyCat token ids;
    uint256[] private crazyYieldIds;


    // maps houseTokenId to stake

    // any rewards distributed when no Cats are staked
    uint256 private unaccountedRewards = 0;
    // any rewards distributed from House NFTs when no Crazy Cats are staked
    uint256 private unaccountedCrazyRewards = 0;
    // amount of $CHEDDAR due for each cat staked
    uint256 private cheddarPerCat = 0;
    // amount of $CHEDDAR due for each crazy cat staked
    uint256 private cheddarPerCrazy = 0;

    // Mice earn 10,000 $CHEDDAR per day
    uint256 public constant DAILY_CHEDDAR_RATE = 10000 ether;
    // Shack: 17,850 Tokens Per Day
    uint256 public constant DAILY_SHACK_CHEDDAR_RATE = 17850 ether;
    // Ranch: 30,000 Tokens Per Day
    uint256 public constant DAILY_RANCH_CHEDDAR_RATE = 30000 ether;
    // Mansion: 100,000 Tokens Per Day
    uint256 public constant DAILY_MANSION_CHEDDAR_RATE = 100000 ether;

    // Mice must have 2 days worth of $CHEDDAR to un-stake or else they're still remaining the habitat
    uint256 public MINIMUM = 200000 ether;
    // there will only ever  6,000,000,000 $CHEDDAR earned through staking
    uint256 public constant MAXIMUM_GLOBAL_CHEDDAR = 6000000000 ether;



    // // Cats take a 20% tax on all $CHEDDAR claimed
    // uint256 public constant GP_CLAIM_TAX_PERCENTAGE = 20;



    // amount of $CHEDDAR earned so far
    uint256 public totalCHEDDAREarned;
    // the last time $CHEDDAR was claimed
    uint256 private lastClaimTimestamp;

    // emergency rescue to allow un-staking without any checks but without $CHEDDAR
    bool public rescueEnabled = false;

    /**
     */
    constructor() {
        _pause();
    }

    /** CRITICAL TO SETUP */

    modifier requireContractsSet() {
        require(address(cnmNFT) != address(0) && address(cheddarToken) != address(0)
        && address(cnmGame) != address(0) && address(randomizer) != address(0) && address(houseGame) != address(0) && address(houseNFT) != address(0), "Contracts not set");
        _;
    }

    function setContracts(address _cnmNFT, address _cheddar, address _cnmGame, address _houseGame, address _rand, address _houseNFT) external onlyOwner {
        cnmNFT = ICnM(_cnmNFT);
        houseNFT = IHouse(_houseNFT);
        cheddarToken = ICHEDDAR(_cheddar);
        cnmGame = ICnMGame(_cnmGame);
        randomizer = IRandomizer(_rand);
        houseGame = IHouseGame(_houseGame);
    }


    /** STAKING */

    /**
     * adds Cats and Mouse
     * @param account the address of the staker
   * @param tokenIds the IDs of the Cats and Mouse to stake
   */
    function addManyToStakingPool(address account, uint16[] calldata tokenIds) external override nonReentrant {
        require(tx.origin == _msgSender() || _msgSender() == address(cnmGame), "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(cnmGame)) {// dont do this step if its a mint + stake
                require(cnmNFT.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
                cnmNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue;
                // there may be gaps in the array for stolen tokens
            }

            if (cnmNFT.isCat(tokenIds[i])) {
                if (cnmNFT.isCrazyCatLady(tokenIds[i])) {
                    _addCrazyCatToStakingPool(account, tokenIds[i]);
                } else {
                    _addCatToStakingPool(account, tokenIds[i]);
                }
            }
            else
                _addMouseToStakingPool(account, tokenIds[i]);
        }
    }



    /**
     * adds Houses
     * @param account the address of the staker
   * @param tokenIds the IDs of the House token to stake
   */
    function addManyHouseToStakingPool(address account, uint16[] calldata tokenIds) external override nonReentrant {
        require(tx.origin == _msgSender() || _msgSender() == address(houseGame), "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(houseGame)) {// dont do this step if its a mint + stake
                require(houseNFT.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
                houseNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue;
                // there may be gaps in the array for stolen tokens
            }

            _addHouseToStakingPool(account, tokenIds[i]);

        }
    }




    /**
     * adds a single Cat to the Habitat
     * @param account the address of the staker
   * @param tokenId the ID of the Cat/CrazyCat to add to the Staking Pool
   */
    function _addCatToStakingPool(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        yield[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(cheddarPerCat)
        });
        yieldIds.push(tokenId);
        numCatStaked += 1;
        cnmNFT.emitCatStakedEvent(account, tokenId);
        emit TokenStaked(account, tokenId, 1, cheddarPerCat);
    }


    /**
     * adds a single CrazyCat to the Habitat
     * @param account the address of the staker
   * @param tokenId the ID of the Cat/CrazyCat to add to the Staking Pool
   */
    function _addCrazyCatToStakingPool(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        crazyYield[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(cheddarPerCrazy)
        });
        crazyYieldIds.push(tokenId);
        numCrazyCatStaked += 1;
        cnmNFT.emitCrazyCatStakedEvent(account, tokenId);
        emit TokenStaked(account, tokenId, 2, cheddarPerCrazy);
    }


    /**
     * adds a single Mouse to the habitat
     * @param account the address of the staker
   * @param tokenId the ID of the Mouse to add to the Staking Pool
   */
    function _addMouseToStakingPool(address account, uint256 tokenId) internal {
        habitat[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp)
        });
        // Add the mouse to the habitat
        numMiceStaked += 1;
        cnmNFT.emitMouseStakedEvent(account, tokenId);
        emit TokenStaked(account, tokenId, 0, block.timestamp);
    }


    /**
     * adds a single House to the Habitat
     * @param account the address of the staker
   * @param tokenId the ID of the Shack to add to the Staking Pool
   */
    function _addHouseToStakingPool(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        houseYield[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp)
        });
        if (houseNFT.isShack(tokenId)) {
            numShackStaked += 1;
            houseNFT.emitShackStakedEvent(account, tokenId);
        } else if (houseNFT.isRanch(tokenId)) {
            numRanchStaked += 1;
            houseNFT.emitRanchStakedEvent(account, tokenId);
        } else {
            numMansionStaked += 1;
            houseNFT.emitMansionStakedEvent(account, tokenId);
        }
        emit TokenStaked(account, tokenId, 3, block.timestamp);
    }
    /** CLAIMING / UNSTAKING */

    /**
     * realize $CHEDDAR earnings and optionally unstake tokens from the Habitat / Yield
     * to unstake a Mouse it will require it has 2 days worth of $CHEDDAR unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyFromHabitatAndYield(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
        require(tx.origin == _msgSender() || _msgSender() == address(cnmGame), "Only EOA");
        require(cnmNFT.isClaimable(), "Not all genesis tokens are minted");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (cnmNFT.isCat(tokenIds[i])) {
                if (cnmNFT.isCrazyCatLady(tokenIds[i])) {
                    owed += _claimCrazyCatFromYield(tokenIds[i], unstake);
                } else {
                    owed += _claimCatFromYield(tokenIds[i], unstake);
                }
            }
            else {
                owed += _claimMouseFromHabitat(tokenIds[i], unstake);
            }
        }
        cheddarToken.updateOriginAccess();
        if (owed == 0) {
            return;
        }
        cheddarToken.mint(_msgSender(), owed);
    }



    /**
     * realize $CHEDDAR earnings and optionally unstake tokens from the Habitat
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyHouseFromHabitat(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
        require(tx.origin == _msgSender() || _msgSender() == address(houseGame), "Only EOA");
        if (!unstake) {
            require(cnmNFT.isClaimable(), "Not all genesis tokens are minted");
        }
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            owed += _claimHouseFromHabitat(tokenIds[i], unstake);
        }
        cheddarToken.updateOriginAccess();
        if (owed == 0) {
            return;
        }
        cheddarToken.mint(_msgSender(), owed);
    }


    /**
     * realize $CHEDDAR earnings for a single Mouse and optionally unstake it
     * if not unstaking, lose x% chance * y% percent of accumulated $CHEDDAR to the staked Cats based on it's roll
     * if unstaking, there is a % chanc of losing Mouse NFT
     * @param tokenId the ID of the Mouse to claim earnings from
   * @param unstake whether or not to unstake the Mouse
   * @return owed - the amount of $CHEDDAR earned
   */
    function _claimMouseFromHabitat(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = habitat[tokenId];          
        require(stake.owner == _msgSender(), "Don't own the given token");
        owed = getOwedForCnM(tokenId);
        require(!(unstake && owed < MINIMUM), "You can't unstake mice until they have 20k $CHEDDAR.");
        uint256 seed = randomizer.random();
        uint256 seedChance = seed >> 16;
        uint8 mouseRoll = cnmNFT.getTokenRoll(tokenId);
        if (unstake) {
            // Chance to lose mouse:
            // Trashcan: 30%
            // Cupboard: 20%
            // Pantry: 10%
            // Vault: 5%
            if (mouseRoll == 0) {
                if ((seed & 0xFFFF) % 100 < 30) {
                    cnmNFT.burn(tokenId);
                } else {
                    // lose accumulated tokens 50% chance and 60 percent of all token
                    if ((seedChance & 0xFFFF) % 100 < 50) {
                        _payCatTax(owed * 60 / 100);
                        owed = owed * 40 / 100;
                    }
                }
            } else if (mouseRoll == 1) {
                if ((seed & 0xFFFF) % 100 < 20) {
                    cnmNFT.burn(tokenId);
                } else {
                    // lose accumulated tokens 80% chance and 25 percent of all token
                    if ((seedChance & 0xFFFF) % 100 < 80) {
                        _payCatTax(owed * 25 / 100);
                        owed = owed * 75 / 100;
                    }
                }
            } else if (mouseRoll == 2) {
                if ((seed & 0xFFFF) % 100 < 10) {
                    cnmNFT.burn(tokenId);
                } else {
                    // lose accumulated tokens 25% chance and 40 percent of all token
                    if ((seedChance & 0xFFFF) % 100 < 25) {
                        _payCatTax(owed * 40 / 100);
                        owed = owed * 60 / 100;
                    }
                }
            } else if (mouseRoll == 3) {
                if ((seed & 0xFFFF) % 100 < 5) {
                    cnmNFT.burn(tokenId);
                } else {
                    // lose accumulated tokens 20% chance and 25 percent of all token
                    if ((seedChance & 0xFFFF) % 100 < 20) {
                        _payCatTax(owed * 25 / 100);
                        owed = owed * 75 / 100;
                    }
                }
            }

            delete habitat[tokenId];
            numMiceStaked -= 1;
            // reset mouse to trash
            cnmNFT.setRoll(tokenId, 0);
            // Always transfer last to guard against reentrance
            cnmNFT.safeTransferFrom(address(this), _msgSender(), tokenId, "");
            // send back Mouse
            cnmNFT.emitMouseUnStakedEvent(_msgSender(), tokenId);
        } else {// Claiming
            if (mouseRoll == 0) {
                // lose accumulated tokens 50% chance and 60 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 50) {
                    _payCatTax(owed * 60 / 100);
                    owed = owed * 40 / 100;
                }
            } else if (mouseRoll == 1) {
                // lose accumulated tokens 80% chance and 25 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 80) {
                    _payCatTax(owed * 25 / 100);
                    owed = owed * 75 / 100;
                }
            } else if (mouseRoll == 2) {
                // lose accumulated tokens 25% chance and 40 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 25) {
                    _payCatTax(owed * 40 / 100);
                    owed = owed * 60 / 100;
                }
            } else if (mouseRoll == 3) {
                // lose accumulated tokens 20% chance and 25 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 20) {
                    _payCatTax(owed * 25 / 100);
                    owed = owed * 75 / 100;
                }
            }
            habitat[tokenId] = Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(block.timestamp)
            });
            // reset stake
        }
        emit MouseClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $CHEDDAR earnings for a single Cat and optionally unstake it
     * Cats earn $CHEDDAR
     * @param tokenId the ID of the Cat to claim earnings from
   * @param unstake whether or not to unstake the Cat
   */
    function _claimCatFromYield(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = yield[tokenId];
        require(stake.owner == _msgSender(), "Doesn't own given token");
        owed = cheddarPerCat - stake.value;
        if (unstake) {
            delete yield[tokenId];
            uint256 index = 0;
            for (uint256 i = 0; i < yieldIds.length; i++) {
                if (yieldIds[i] == tokenId) {
                    index = i;
                    break;
                }
            }
            delete yieldIds[index];
            numCatStaked -= 1;
            // Always remove last to guard against reentrance
            cnmNFT.safeTransferFrom(address(this), _msgSender(), tokenId, "");
            // Send back Cat
            cnmNFT.emitCatUnStakedEvent(_msgSender(), tokenId);
        } else {
            yield[tokenId] = Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(cheddarPerCat)
            });
            // reset stake

        }
        emit CatClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $CHEDDAR earnings for a Crazy Cat and optionally unstake it
     * Cats earn $CHEDDAR
     * @param tokenId the ID of the Cat to claim earnings from
   * @param unstake whether or not to unstake the Crazy Cat
   */
    function _claimCrazyCatFromYield(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = crazyYield[tokenId];
        require(stake.owner == _msgSender(), "Doesn't own given token");
        owed = cheddarPerCrazy - stake.value;
        if (unstake) {
            delete crazyYield[tokenId];
            uint256 index = 0;
            for (uint256 i = 0; i < crazyYieldIds.length; i++) {
                if (crazyYieldIds[i] == tokenId) {
                    index = i;
                    break;
                }
            }
            delete crazyYieldIds[index];
            numCrazyCatStaked -= 1;
            // Always remove last to guard against reentrance
            cnmNFT.safeTransferFrom(address(this), _msgSender(), tokenId, "");
            // Send back Cat
            cnmNFT.emitCrazyCatUnStakedEvent(_msgSender(), tokenId);
        } else {
            crazyYield[tokenId] = Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(cheddarPerCrazy)
            });
            // reset stake

        }
        emit CrazyCatLadyClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $CHEDDAR earnings for a single Shack and optionally unstake it
     * @param tokenId the ID of the Shack to claim earnings from
   * @param unstake whether or not to unstake the Shack
   * @return owed - the amount of $CHEDDAR earned
   */
    function _claimHouseFromHabitat(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = houseYield[tokenId];
        require(stake.owner == _msgSender(), "Don't own the given token");
        owed = getOwedForHouse(tokenId);
        if (unstake) {
            _payCrazyCatTax(owed * 10 / 100);
            owed = owed * 90 / 100;
            delete houseYield[tokenId];
            if (houseNFT.isShack(tokenId)) {
                numShackStaked -= 1;
                houseNFT.emitShackUnStakedEvent(_msgSender(), tokenId);
            } else if (houseNFT.isRanch(tokenId)) {
                numRanchStaked -= 1;
                houseNFT.emitRanchUnStakedEvent(_msgSender(), tokenId);
            } else {
                numMansionStaked -= 1;
                houseNFT.emitMansionUnStakedEvent(_msgSender(), tokenId);
            }
            // Always transfer last to guard against reentrance
            houseNFT.safeTransferFrom(address(this), _msgSender(), tokenId, "");
            // send back House
        } else {// Claiming
            _payCrazyCatTax(owed * 10 / 100);
            owed = owed * 90 / 100;
            houseYield[tokenId] = Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(block.timestamp)
            });
            // reset stake
        }
        emit HouseClaimed(tokenId, unstake, owed);
    }


    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   */
    function rescue(uint256[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (cnmNFT.isCat(tokenId)) {
                if (cnmNFT.isCrazyCatLady(tokenId)) {
                    stake = crazyYield[tokenId];
                    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                    delete crazyYield[tokenId];
                    uint256 index = 0;
                    for (uint256 j = 0; j < crazyYieldIds.length; j++) {
                        if (crazyYieldIds[j] == tokenId) {
                            index = j;
                            break;
                        }
                    }
                    delete crazyYieldIds[index];
                    numCrazyCatStaked -= 1;
                    cnmNFT.safeTransferFrom(address(this), _msgSender(), tokenId, "");
                    emit CrazyCatLadyClaimed(tokenId, true, 0);
                } else {
                    stake = yield[tokenId];
                    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                    delete yield[tokenId];
                    uint256 index = 0;
                    for (uint256 j = 0; j < yieldIds.length; j++) {
                        if (yieldIds[j] == tokenId) {
                            index = j;
                            break;
                        }
                    }
                    delete yieldIds[index];
                    numCatStaked -= 1;
                    cnmNFT.safeTransferFrom(address(this), _msgSender(), tokenId, "");
                    emit CatClaimed(tokenId, true, 0);
                }
            } else {
                stake = habitat[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                delete habitat[tokenId];
                numMiceStaked -= 1;
                cnmNFT.safeTransferFrom(address(this), _msgSender(), tokenId, "");
                emit MouseClaimed(tokenId, true, 0);
            }
        }
    }

    /**
     * emergency unstake House tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   */
    function rescueHouse(uint256[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            stake = houseYield[tokenId];
            require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
            delete houseYield[tokenId];
            if (houseNFT.isShack(tokenId)) {
                numShackStaked -= 1;
            } else if (houseNFT.isRanch(tokenId)) {
                numRanchStaked -= 1;
            } else {
                numMansionStaked -= 1;
            }
            houseNFT.safeTransferFrom(address(this), _msgSender(), tokenId, "");
            emit HouseClaimed(tokenId, true, 0);
        }
    }
    /** ACCOUNTING */

    /**
     * add $CHEDDAR to claimable pot for the Yield
     * @param amount $CHEDDAR to add to the pot
   */
    function _payCatTax(uint256 amount) internal {
        if (numCatStaked == 0) {// if there's no staked dragons
            unaccountedRewards += amount;
            // keep track of $CHEDDAR due to cats
            return;
        }
        // makes sure to include any unaccounted $GP
        cheddarPerCat += (amount + unaccountedRewards) / numCatStaked;
        unaccountedRewards = 0;
    }

    /**
     * add $CHEDDAR to claimable pot for the Crazy Yield
     * @param amount $CHEDDAR to add to the pot
   */
    function _payCrazyCatTax(uint256 amount) internal {
        if (numCrazyCatStaked == 0) {// if there's no staked dragons
            unaccountedCrazyRewards += amount;
            // keep track of $CHEDDAR due to cats
            return;
        }
        // makes sure to include any unaccounted $GP
        cheddarPerCrazy += (amount + unaccountedCrazyRewards) / numCrazyCatStaked;
        unaccountedCrazyRewards = 0;
    }

    /**
     * tracks $CHEDDAR earnings to ensure it stops once 6,000,000,000‌ is eclipsed
     */
    modifier _updateEarnings() {
        if (totalCHEDDAREarned < MAXIMUM_GLOBAL_CHEDDAR) {
            totalCHEDDAREarned +=
            (block.timestamp - lastClaimTimestamp)
            * (numMiceStaked * DAILY_CHEDDAR_RATE
            + numShackStaked * DAILY_SHACK_CHEDDAR_RATE
            + numRanchStaked * DAILY_RANCH_CHEDDAR_RATE
            + numMansionStaked * DAILY_MANSION_CHEDDAR_RATE)
            / PERIOD;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /** ADMIN */

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    function isOwner(uint256 tokenId, address owner) external view override returns (bool) {
        if (cnmNFT.isCat(tokenId)) {
            if (cnmNFT.isCrazyCatLady(tokenId)) {
                return crazyYield[tokenId].owner == owner;
            } else {
                return yield[tokenId].owner == owner;
            }
        } else {
            return habitat[tokenId].owner == owner;
        }
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** READ ONLY */

    function getOwedForCnM(uint256 tokenId) public view returns (uint256) {
        uint256 owed = 0;
        if(cnmNFT.isCat(tokenId)) {
            if(cnmNFT.isCrazyCatLady(tokenId)) {
                return cheddarPerCrazy - crazyYield[tokenId].value;
            } else {
                return cheddarPerCat - yield[tokenId].value;
            }         
        } else {
            Stake memory stake = habitat[tokenId];
            if (totalCHEDDAREarned < MAXIMUM_GLOBAL_CHEDDAR) {
                owed = (block.timestamp - stake.value) * DAILY_CHEDDAR_RATE / PERIOD;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0;
            } else {
                owed = (lastClaimTimestamp - stake.value) * DAILY_CHEDDAR_RATE / PERIOD;
            }
            return owed;
        }
    }

    function getOwedForHouse(uint256 tokenId) public view returns (uint256) {
        Stake memory stake = houseYield[tokenId];
        if(stake.value == 0) return 0;
        uint256 dailyHouseCheddarRate = 0;
        if (houseNFT.isShack(tokenId)) {
            dailyHouseCheddarRate = DAILY_SHACK_CHEDDAR_RATE;
        } else if (houseNFT.isRanch(tokenId)) {
            dailyHouseCheddarRate = DAILY_RANCH_CHEDDAR_RATE;
        } else {
            dailyHouseCheddarRate = DAILY_MANSION_CHEDDAR_RATE;
        }
        uint256 owed;
        if (totalCHEDDAREarned < MAXIMUM_GLOBAL_CHEDDAR) {
            owed = (block.timestamp - stake.value) * dailyHouseCheddarRate / PERIOD;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $CHEDDAR production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * dailyHouseCheddarRate / PERIOD;
            // stop earning additional $CHEDDAR if it's all been earned
        }
        return owed;
    }

    /**
     * chooses a random Cat thief when a newly minted token is stolen
     * @param seed a random value to choose a Cat from
   * @return the owner of the randomly selected Dragon thief
   */
    function randomCatOwner(uint256 seed) external view override returns (address) {
        if (numCatStaked == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % numCatStaked;
        // choose a value from 0 to total number of cat stacked
        uint256 cumulative = 0;
        seed >>= 32;
        // loop through each bucket of Cats with
        for (uint i = 0; i < yieldIds.length; i++) {
            if (yieldIds[i] == 0) {
                continue;
            } else {
                if (cumulative == bucket) {
                    return yield[yieldIds[i]].owner;
                } else {
                    cumulative += 1;
                }
            }
        }
        return address(0x0);
    }

    /**
     * chooses a random Crazy Cat thief when a newly minted token is stolen
     * @param seed a random value to choose a Dragon from
   * @return the owner of the randomly selected Dragon thief
   */
    function randomCrazyCatOwner(uint256 seed) external view override returns (address) {
        if (numCrazyCatStaked == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % numCrazyCatStaked;
        // choose a value from 0 to total number of crazy cat stacked
        uint256 cumulative = 0;
        seed >>= 32;
        // loop through each bucket of Cats with
        for (uint i = 0; i < crazyYieldIds.length; i++) {
            if (crazyYieldIds[i] == 0) {
                continue;
            } else {
                if (cumulative == bucket) {
                    return crazyYield[crazyYieldIds[i]].owner;
                } else {
                    cumulative += 1;
                }
            }
        }
        return address(0x0);
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send to Habitat directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function updateMinimumExit(uint256 _minimum) external onlyOwner {
        MINIMUM = _minimum;
    }
    
    function updatePeriod(uint256 _period) external onlyOwner {
        PERIOD = _period;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function commitId() external view returns (uint16);
    function getCommitRandom(uint16 id) external view returns (uint256);
    function random() external returns (uint256);
    function sRandom(uint256 tokenId) external returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHouseGame {
  
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHouse is IERC721Enumerable {
    
    // House NFT struct
    struct HouseStruct {
        uint8 roll; //0 - Shack, 1 - Ranch, 2 - Mansion
        uint8 body;
    }

    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function isShack(uint256 tokenId) external view returns(bool);
    function isRanch(uint256 tokenId) external view returns(bool);
    function isMansion(uint256 tokenId) external view returns(bool);
    function getMaxTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (HouseStruct memory);
    function minted() external view returns (uint16);

    function emitShackStakedEvent(address owner, uint256 tokenId) external;
    function emitRanchStakedEvent(address owner, uint256 tokenId) external;
    function emitMansionStakedEvent(address owner, uint256 tokenId) external;

    function emitShackUnStakedEvent(address owner, uint256 tokenId) external;
    function emitRanchUnStakedEvent(address owner, uint256 tokenId) external;
    function emitMansionUnStakedEvent(address owner, uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IHabitat {
  function addManyToStakingPool(address account, uint16[] calldata tokenIds) external;
  function addManyHouseToStakingPool(address account, uint16[] calldata tokenIds) external;
  function randomCatOwner(uint256 seed) external view returns (address);
  function randomCrazyCatOwner(uint256 seed) external view returns (address);
  function isOwner(uint256 tokenId, address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ICnMGame {
  
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICnM is IERC721Enumerable {
    
    // Character NFT struct
    struct CatMouse {
        bool isCat; // true if cat
        bool isCrazy; // true if cat is CrazyCatLady, only check if isCat equals to true
        uint8 roll; //0 - habitatless, 1 - Shack, 2 - Ranch, 3 - Mansion

        uint8 body;
        uint8 color;
        uint8 eyes;
        uint8 eyebrows;
        uint8 neck;
        uint8 glasses;
        uint8 hair;
        uint8 head;
        uint8 markings;
        uint8 mouth;
        uint8 nose;
        uint8 props;
        uint8 shirts;
    }

    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function mint(address recipient, uint256 seed) external;
    // function setRoll(uint256 seed, uint256 tokenId, address addr) external;
    function setRoll(uint256 tokenId, uint8 habitatType) external;

    function emitCatStakedEvent(address owner,uint256 tokenId) external;
    function emitCrazyCatStakedEvent(address owner, uint256 tokenId) external;
    function emitMouseStakedEvent(address owner, uint256 tokenId) external;
    
    function emitCatUnStakedEvent(address owner, uint256 tokenId) external;
    function emitCrazyCatUnStakedEvent(address owner, uint256 tokenId) external;
    function emitMouseUnStakedEvent(address owner, uint256 tokenId) external;
    
    function burn(uint256 tokenId) external;
    function getPaidTokens() external view returns (uint256);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function isCat(uint256 tokenId) external view returns(bool);
    function isClaimable() external view returns(bool);
    function isCrazyCatLady(uint256 tokenId) external view returns(bool);
    function getTokenRoll(uint256 tokenId) external view returns(uint8);
    function getMaxTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (CatMouse memory);
    function minted() external view returns (uint16);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ICHEDDAR {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}