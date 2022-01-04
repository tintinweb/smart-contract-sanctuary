// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ICnMGame.sol";
import "./ICnM.sol";
import "./ICHEDDAR.sol";
import "./IHabitat.sol";
import "./IRandomizer.sol";
import "./IHouse.sol";
import "./IHouseGame.sol";

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