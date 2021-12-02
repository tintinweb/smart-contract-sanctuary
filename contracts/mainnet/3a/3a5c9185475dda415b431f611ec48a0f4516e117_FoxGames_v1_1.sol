/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./IFoxGame.sol";
import "./IFoxGameCarrot.sol";
import "./IFoxGameNFT.sol";

contract FoxGames_v1_1 is IFoxGame, OwnableUpgradeable, IERC721ReceiverUpgradeable,
                    PausableUpgradeable, ReentrancyGuardUpgradeable {
  using ECDSAUpgradeable for bytes32; // signature verification helpers
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet; // iterable staked tokens

  /****
   * Thanks for checking out our contracts.
   * If you're interested in working with us, you can find us on
   * discord (https://discord.gg/foxgame). We also have a bug bounty
   * program and are available at @officialfoxgame or [email protected]
   ***/

  // Maximum advantage score for both foxes and hunters
  uint8 public constant MAX_ADVANTAGE = 8;

  // Foxes take a 20% tax on all rabbiot $CARROT claimed
  uint8 public constant RABBIT_CLAIM_TAX_PERCENTAGE = 20;

  // Hunters have a 5% chance of stealing a fox as it unstakes
  uint8 private hunterStealFoxProbabilityMod;

  // Cut between hunters and foxes
  uint8 private hunterTaxCutPercentage;

  // Total hunter marksman scores staked
  uint16 public totalMarksmanPointsStaked;

  // Total fox cunning scores staked
  uint16 public totalCunningPointsStaked;

  // Number of Rabbit staked
  uint32 public totalRabbitsStaked;

  // Number of Foxes staked
  uint32 public totalFoxesStaked;

  // Number of Hunters staked
  uint32 public totalHuntersStaked;

  // The last time $CARROT was claimed
  uint48 public lastClaimTimestamp;

  // Rabbits must have 2 days worth of $CARROT to unstake or else it's too cold
  uint48 public constant RABBIT_MINIMUM_TO_EXIT = 2 days;

  // There will only ever be (roughly) 2.5 billion $CARROT earned through staking
  uint128 public constant MAXIMUM_GLOBAL_CARROT = 2500000000 ether;

  // amount of $CARROT earned so far
  uint128 public totalCarrotEarned;

  // Collected rewards before any foxes staked
  uint128 public unaccountedFoxRewards;

  // Collected rewards before any foxes staked
  uint128 public unaccountedHunterRewards;

  // Amount of $CARROT due for each cunning point staked
  uint128 public carrotPerCunningPoint;

  // Amount of $CARROT due for each marksman point staked
  uint128 public carrotPerMarksmanPoint; 

  // Rabbit earn 10000 $CARROT per day
  uint128 public constant RABBIT_EARNING_RATE = 115740740740740740; // 10000 ether / 1 days;

  // Hunters earn 20000 $CARROT per day
  uint128 public constant HUNTER_EARNING_RATE = 231481481481481470; // 20000 ether / 1 days;

  // Staking maps for both time-based and ad-hoc-earning-based
  struct TimeStake { uint16 tokenId; uint48 time; address owner; }
  struct EarningStake { uint16 tokenId; uint128 earningRate; address owner; }

  // Events
  event TokenStaked(string kind, uint16 tokenId, address owner);
  event TokenUnstaked(string kind, uint16 tokenId, address owner, uint128 earnings);
  event FoxStolen(uint16 foxTokenId, address thief, address victim);

  // Signature to prove membership and randomness
  address private signVerifier;

  // External contract reference
  IFoxGameNFT private foxNFT;
  IFoxGameCarrot private foxCarrot;

  // Staked rabbits
  mapping(uint16 => TimeStake) public rabbitStakeByToken;

  // Staked foxes
  mapping(uint8 => EarningStake[]) public foxStakeByCunning; // foxes grouped by cunning
  mapping(uint16 => uint16) public foxHierarchy; // fox location within cunning group

  // Staked hunters
  mapping(uint16 => TimeStake) public hunterStakeByToken;
  mapping(uint8 => EarningStake[]) public hunterStakeByMarksman; // hunter grouped by markman
  mapping(uint16 => uint16) public hunterHierarchy; // hunter location within marksman group

  // FoxGame membership date
  mapping(address => uint48) public membershipDate;
  mapping(address => uint32) public memberNumber;
  event MemberJoined(address member, uint32 memberCount);
  uint32 public membershipCount;

  // External contract reference
  IFoxGameNFT private foxNFTGen1;

  // Mapping for staked tokens
  mapping(address => EnumerableSetUpgradeable.UintSet) private _stakedTokens;

  // Bool to store staking data
  bool private _storeStaking;

  // Use seed instead
  uint256 private _seed;

  /**
   * Fetch and replace seeds
   */
  function _getSeed(uint16 offset, uint256 offset2) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      _seed,
      offset,
      offset2
    )));
  }

  /**
   * Fetch and replace seeds
   */
  function getSeed(uint16 offset) external view returns (uint256) {
    require(msg.sender == address(foxNFTGen1), "not approved");
    return _getSeed(offset, 0);
  }

  /**
   * Update seeds used for randomness.
   */
  function setSeed(uint256 seed) external onlyOwner {
    _seed = seed;
  }

  /**
   * Init contract upgradability (only called once).
   */
  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();

    hunterStealFoxProbabilityMod = 20; // 100/5=20
    hunterTaxCutPercentage = 30; // whole number %

    // Pause staking on init
    _pause();
  }

  /**
   * FoxGames welcomes you to the club!
   */
  function joinFoxGames() external {
    require(tx.origin == msg.sender, "eos only");
    require(membershipDate[msg.sender] == 0, "already joined");
    membershipDate[msg.sender] = uint48(block.timestamp);
    memberNumber[msg.sender] = membershipCount;
    emit MemberJoined(msg.sender, membershipCount);
    membershipCount += 1;
  }

  /**
   * Hash together proof of membership and randomness.
   */
  function getSigningHash(address recipient, bool membership, uint48 expiration, uint256 seed) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(recipient, membership, expiration, seed));
  }

  /**
   * Validate mebership and randomness.
   */
  function isValidSignature(address recipient, bool membership, uint48 expiration, uint256 seed, bytes memory sig) public view returns (bool) {
    bytes32 message = getSigningHash(recipient, membership, expiration, seed).toEthSignedMessageHash();
    return ECDSAUpgradeable.recover(message, sig) == signVerifier;
  }

  /**
   * Return the appropriate contract interface for token.
   */
  function getTokenContract(uint16 tokenId) private view returns (IFoxGameNFT) {
    return tokenId <= 10000 ? foxNFT : foxNFTGen1;
  }

  /**
   * Adds Rabbits, Foxes and Hunters to their respective safe homes.
   * @param account the address of the staker
   * @param tokenIds the IDs of the Rabbit and Foxes to stake
   */
  function stakeTokens(address account, uint16[] calldata tokenIds) external whenNotPaused nonReentrant _updateEarnings {
    require((account == msg.sender && tx.origin == msg.sender) || msg.sender == address(foxNFTGen1), "not approved");
    
    IFoxGameNFT nftContract;
    for (uint16 i = 0; i < tokenIds.length; i++) {

      // Thieves abound and leave minting gaps
      if (tokenIds[i] == 0) {
        continue;
      }

      // Add to respective safe homes
      nftContract = getTokenContract(tokenIds[i]);
      IFoxGameNFT.Kind kind = _getKind(nftContract, tokenIds[i]);
      if (kind == IFoxGameNFT.Kind.RABBIT) {
        _addRabbitToKeep(account, tokenIds[i]);
      } else if (kind == IFoxGameNFT.Kind.FOX) {
        _addFoxToDen(nftContract, account, tokenIds[i]);
      } else { // HUNTER
        _addHunterToCabin(nftContract, account, tokenIds[i]);
      }

      // Transfer into safe house
      if (msg.sender != address(foxNFTGen1)) { // dont do this step if its a mint + stake
        require(nftContract.ownerOf(tokenIds[i]) == msg.sender, "only token owners can stake");
        nftContract.transferFrom(msg.sender, address(this), tokenIds[i]);
      }
    }
  }

  /**
   * Adds Rabbit to the Keep.
   * @param account the address of the staker
   * @param tokenId the ID of the Rabbit to add to the Barn
   */
  function _addRabbitToKeep(address account, uint16 tokenId) internal {
    rabbitStakeByToken[tokenId] = TimeStake({
      owner: account,
      tokenId: tokenId,
      time: uint48(block.timestamp)
    });
    totalRabbitsStaked += 1;
    if (_storeStaking) _stakedTokens[account].add(tokenId); // add staked ref
    emit TokenStaked("RABBIT", tokenId, account);
  }

  /**
   * Add Fox to the Den.
   * @param account the address of the staker
   * @param tokenId the ID of the Fox
   */
  function _addFoxToDen(IFoxGameNFT nftContract, address account, uint16 tokenId) internal {
    uint8 cunning = _getAdvantagePoints(nftContract, tokenId);
    totalCunningPointsStaked += cunning;
    // Store fox by rating
    foxHierarchy[tokenId] = uint16(foxStakeByCunning[cunning].length);
    // Add fox to their cunning group
    foxStakeByCunning[cunning].push(EarningStake({
      owner: account,
      tokenId: tokenId,
      earningRate: carrotPerCunningPoint
    }));
    totalFoxesStaked += 1;
    if (_storeStaking) _stakedTokens[account].add(tokenId); // add staked ref
    emit TokenStaked("FOX", tokenId, account);
  }

  /**
   * Adds Hunter to the Cabin.
   * @param account the address of the staker
   * @param tokenId the ID of the Hunter
   */
  function _addHunterToCabin(IFoxGameNFT nftContract, address account, uint16 tokenId) internal {
    uint8 marksman = _getAdvantagePoints(nftContract, tokenId);
    totalMarksmanPointsStaked += marksman;
    // Store hunter by rating
    hunterHierarchy[tokenId] = uint16(hunterStakeByMarksman[marksman].length);
    // Add hunter to their marksman group
    hunterStakeByMarksman[marksman].push(EarningStake({
      owner: account,
      tokenId: tokenId,
      earningRate: carrotPerMarksmanPoint
    }));
    hunterStakeByToken[tokenId] = TimeStake({
      owner: account,
      tokenId: tokenId,
      time: uint48(block.timestamp)
    });
    totalHuntersStaked += 1;
    if (_storeStaking) _stakedTokens[account].add(tokenId); // add staked ref
    emit TokenStaked("HUNTER", tokenId, account);
  }

  /**
   * Realize $CARROT earnings and optionally unstake tokens.
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   * @param membership wheather user is membership or not
   * @param originSeed account seed
   * @param sig signature
   */
  function claimRewardsAndUnstake(uint16[] calldata tokenIds, bool unstake, bool membership, uint48 expiration, uint256 originSeed, bytes memory sig) external whenNotPaused nonReentrant _updateEarnings {
    require(tx.origin == msg.sender, "eos only");
    require(isValidSignature(msg.sender, membership, expiration, originSeed, sig), "invalid signature");

    uint256 seed;
    uint128 reward;
    IFoxGameNFT.Kind kind;
    IFoxGameNFT nftContract;
    uint48 time = uint48(block.timestamp);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      nftContract = getTokenContract(tokenIds[i]);
      kind = _getKind(nftContract, tokenIds[i]);
      seed = _getSeed(tokenIds[i], originSeed);
      if (kind == IFoxGameNFT.Kind.RABBIT) {
        reward += _claimRabbitsFromKeep(nftContract, tokenIds[i], unstake, time, seed);
      } else if (kind == IFoxGameNFT.Kind.FOX) {
        reward += _claimFoxFromDen(nftContract, tokenIds[i], unstake, seed);
      } else { // HUNTER
        reward += _claimHunterFromCabin(nftContract, tokenIds[i], unstake, time);
      }
    }
    if (reward != 0) {
      foxCarrot.mint(msg.sender, reward);
    }
  }

  /**
   * realize $CARROT earnings for a single Rabbit and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked foxes
   * if unstaking, there is a 50% chance all $CARROT is stolen
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Rabbit to claim earnings from
   * @param unstake whether or not to unstake the Rabbit
   * @param time currnet block time
   * @param seed account seed
   * @return reward - the amount of $CARROT earned
   */
  function _claimRabbitsFromKeep(IFoxGameNFT nftContract, uint16 tokenId, bool unstake, uint48 time, uint256 seed) internal returns (uint128 reward) {
    TimeStake memory stake = rabbitStakeByToken[tokenId];
    require(stake.owner == msg.sender, "only token owners can unstake");
    require(!(unstake && block.timestamp - stake.time < RABBIT_MINIMUM_TO_EXIT), "rabbits need 2 days of carrot");

    // Calcuate time-based rewards
    if (totalCarrotEarned < MAXIMUM_GLOBAL_CARROT) {
      reward = (time - stake.time) * RABBIT_EARNING_RATE;
    } else if (stake.time <= lastClaimTimestamp) {
      // stop earning additional $CARROT if it's all been earned
      reward = (lastClaimTimestamp - stake.time) * RABBIT_EARNING_RATE;
    }

    // Update reward based on game rules
    if (unstake) {
      // 50% chance of all $CARROT stolen
      if (((seed >> 245) % 2) == 0) {
        _payTaxToPredators(reward, true);
        reward = 0;
      }
      delete rabbitStakeByToken[tokenId];
      totalRabbitsStaked -= 1;
      if (_storeStaking) _stakedTokens[stake.owner].remove(tokenId); // delete staked ref
      // send back Rabbit
      nftContract.safeTransferFrom(address(this), msg.sender, tokenId, "");
    } else {
      // Pay foxes their tax
      _payTaxToPredators(reward * RABBIT_CLAIM_TAX_PERCENTAGE / 100, false);
      reward = reward * (100 - RABBIT_CLAIM_TAX_PERCENTAGE) / 100;
      // Update last earned time
      rabbitStakeByToken[tokenId] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time
      });
    }

    emit TokenUnstaked("RABBIT", tokenId, stake.owner, reward);
  }

  /**
   * realize $CARROT earnings for a single Fox and optionally unstake it
   * foxes earn $CARROT proportional to their Alpha rank
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param unstake whether or not to unstake the Fox
   * @param seed account seed
   * @return reward - the amount of $CARROT earned
   */
  function _claimFoxFromDen(IFoxGameNFT nftContract, uint16 tokenId, bool unstake, uint256 seed) internal returns (uint128 reward) {
    require(nftContract.ownerOf(tokenId) == address(this), "must be staked to claim rewards");
    uint8 cunning = _getAdvantagePoints(nftContract, tokenId);
    EarningStake memory stake = foxStakeByCunning[cunning][foxHierarchy[tokenId]];
    require(stake.owner == msg.sender, "only token owners can unstake");

    // Calculate advantage-based rewards
    reward = (cunning) * (carrotPerCunningPoint - stake.earningRate);
    if (unstake) {
      totalCunningPointsStaked -= cunning; // Remove Alpha from total staked
      EarningStake memory lastStake = foxStakeByCunning[cunning][foxStakeByCunning[cunning].length - 1];
      foxStakeByCunning[cunning][foxHierarchy[tokenId]] = lastStake; // Shuffle last Fox to current position
      foxHierarchy[lastStake.tokenId] = foxHierarchy[tokenId];
      foxStakeByCunning[cunning].pop(); // Remove duplicate
      delete foxHierarchy[tokenId]; // Delete old mapping
      totalFoxesStaked -= 1;
      if (_storeStaking) _stakedTokens[stake.owner].remove(tokenId); // delete staked ref

      // Determine if Fox should be stolen by hunter
      address recipient = msg.sender;
      if (((seed >> 245) % hunterStealFoxProbabilityMod) == 0) {
        recipient = _randomHunterOwner(seed);
        if (recipient == address(0x0)) {
          recipient = msg.sender;
        } else if (recipient != msg.sender) {
          emit FoxStolen(tokenId, recipient, msg.sender);
        }
      }
      nftContract.safeTransferFrom(address(this), recipient, tokenId, "");
    } else {
      // Update earning rate
      foxStakeByCunning[cunning][foxHierarchy[tokenId]] = EarningStake({
        owner: msg.sender,
        tokenId: tokenId,
        earningRate: carrotPerCunningPoint
      });
    }

    emit TokenUnstaked("FOX", tokenId, stake.owner, reward);
  }

  /**
   * realize $CARROT earnings for a single Fox and optionally unstake it
   * foxes earn $CARROT proportional to their Alpha rank
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param unstake whether or not to unstake the Fox
   * @param time currnet block time
   * @return reward - the amount of $CARROT earned
   */
  function _claimHunterFromCabin(IFoxGameNFT nftContract, uint16 tokenId, bool unstake, uint48 time) internal returns (uint128 reward) {
    require(foxNFTGen1.ownerOf(tokenId) == address(this), "must be staked to claim rewards");
    uint8 marksman = _getAdvantagePoints(nftContract, tokenId);
    EarningStake memory earningStake = hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]];
    require(earningStake.owner == msg.sender, "only token owners can unstake");

    // Calculate advantage-based rewards
    reward = (marksman) * (carrotPerMarksmanPoint - earningStake.earningRate);
    if (unstake) {
      totalMarksmanPointsStaked -= marksman; // Remove Alpha from total staked
      EarningStake memory lastStake = hunterStakeByMarksman[marksman][hunterStakeByMarksman[marksman].length - 1];
      hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]] = lastStake; // Shuffle last Fox to current position
      hunterHierarchy[lastStake.tokenId] = hunterHierarchy[tokenId];
      hunterStakeByMarksman[marksman].pop(); // Remove duplicate
      delete hunterHierarchy[tokenId]; // Delete old mapping
      if (_storeStaking) _stakedTokens[earningStake.owner].remove(tokenId); // delete staked ref
    } else {
      // Update earning rate
      hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]] = EarningStake({
        owner: msg.sender,
        tokenId: tokenId,
        earningRate: carrotPerMarksmanPoint
      });
    }

    // Calcuate time-based rewards
    TimeStake memory timeStake = hunterStakeByToken[tokenId];
    require(timeStake.owner == msg.sender, "only token owners can unstake");
    if (totalCarrotEarned < MAXIMUM_GLOBAL_CARROT) {
      reward += (time - timeStake.time) * HUNTER_EARNING_RATE;
    } else if (timeStake.time <= lastClaimTimestamp) {
      // stop earning additional $CARROT if it's all been earned
      reward += (lastClaimTimestamp - timeStake.time) * HUNTER_EARNING_RATE;
    }
    if (unstake) {
      delete hunterStakeByToken[tokenId];
      totalHuntersStaked -= 1;
      // Unstake to owner
      foxNFTGen1.safeTransferFrom(address(this), msg.sender, tokenId, "");
    } else {
      // Update last earned time
      hunterStakeByToken[tokenId] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time
      });
    }

    emit TokenUnstaked("HUNTER", tokenId, earningStake.owner, reward);
  }

  /** 
   * Add $CARROT claimable pots for hunters and foxes
   * @param amount $CARROT to add to the pot
   * @param includeHunters true if hunters take a cut of the spoils
   */
  function _payTaxToPredators(uint128 amount, bool includeHunters) internal {
    uint128 amountDueFoxes = amount;

    // Hunters take their cut first
    if (includeHunters) {
      uint128 amountDueHunters = amount * hunterTaxCutPercentage / 100;
      amountDueFoxes -= amountDueHunters;

      // Update hunter pools
      if (totalMarksmanPointsStaked == 0) {
        unaccountedHunterRewards += amountDueHunters;
      } else {
        carrotPerMarksmanPoint += (amountDueHunters + unaccountedHunterRewards) / totalMarksmanPointsStaked;
        unaccountedHunterRewards = 0;
      }
    }

    // Update fox pools
    if (totalCunningPointsStaked == 0) {
      unaccountedFoxRewards += amountDueFoxes;
    } else {
      // makes sure to include any unaccounted $CARROT 
      carrotPerCunningPoint += (amountDueFoxes + unaccountedFoxRewards) / totalCunningPointsStaked;
      unaccountedFoxRewards = 0;
    }
  }

  /**
   * Tracks $CARROT earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalCarrotEarned < MAXIMUM_GLOBAL_CARROT) {
      uint48 time = uint48(block.timestamp);
      uint48 elapsed = time - lastClaimTimestamp;
      totalCarrotEarned +=
        (elapsed * totalRabbitsStaked * RABBIT_EARNING_RATE) +
        (elapsed * totalHuntersStaked * HUNTER_EARNING_RATE);
      lastClaimTimestamp = time;
    }
    _;
  }

  /**
   * Get token kind (rabbit, fox, hunter)
   * @param tokenId the ID of the token to check
   * @return kind
   */
  function _getKind(IFoxGameNFT nftContract, uint16 tokenId) internal view returns (IFoxGameNFT.Kind) {
    return nftContract.getTraits(tokenId).kind;
  }

  /**
   * gets the alpha score for a Fox
   * @param tokenId the ID of the Fox to get the alpha score for
   * @return the alpha score of the Fox (5-8)
   */
  function _getAdvantagePoints(IFoxGameNFT nftContract, uint16 tokenId) internal view returns (uint8) {
    return MAX_ADVANTAGE - nftContract.getTraits(tokenId).advantage; // alpha index is 0-3
  }

  /**
   * chooses a random Fox thief when a newly minted token is stolen
   * @param seed a random value to choose a Fox from
   * @return the owner of the randomly selected Fox thief
   */
  function randomFoxOwner(uint256 seed) external view returns (address) {
    if (totalCunningPointsStaked == 0) {
      return address(0x0); // use 0x0 to return to msg.sender
    }
    // choose a value from 0 to total alpha staked
    uint256 bucket = (seed & 0xFFFFFFFF) % totalCunningPointsStaked;
    uint256 cumulative;
    seed >>= 32;
    // loop through each cunning bucket of Foxes
    for (uint8 i = MAX_ADVANTAGE - 3; i <= MAX_ADVANTAGE; i++) {
      cumulative += foxStakeByCunning[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Fox with that alpha score
      return foxStakeByCunning[i][seed % foxStakeByCunning[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * Chooses a random Hunter to steal a fox.
   * @param seed a random value to choose a Hunter from
   * @return the owner of the randomly selected Hunter thief
   */
  function _randomHunterOwner(uint256 seed) internal view returns (address) {
    if (totalMarksmanPointsStaked == 0) {
      return address(0x0); // use 0x0 to return to msg.sender
    }
    // choose a value from 0 to total alpha staked
    uint256 bucket = (seed & 0xFFFFFFFF) % totalMarksmanPointsStaked;
    uint256 cumulative;
    seed >>= 32;
    // loop through each cunning bucket of Foxes
    for (uint8 i = MAX_ADVANTAGE - 3; i <= MAX_ADVANTAGE; i++) {
      cumulative += hunterStakeByMarksman[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Fox with that alpha score
      return hunterStakeByMarksman[i][seed % hunterStakeByMarksman[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * Hydrate existing staked token owners into owner mapping.
   */
  function storeStakedUsers() external onlyOwner {
    // Rabbits
    TimeStake memory timeStake;
    for (uint16 tokenId = 0; tokenId < 10000; tokenId++) {
      timeStake = rabbitStakeByToken[tokenId];
      if (timeStake.tokenId != 0) {
        _stakedTokens[timeStake.owner].add(tokenId);
      }
    }

    uint256 earningLength;
    uint8 earningIdx;
    EarningStake memory earningStake;
    for (uint8 advantage = 5; advantage < 9; advantage++) {
      // Foxes
      earningLength = foxStakeByCunning[advantage].length;
      for (earningIdx = 5; earningIdx < earningLength; earningIdx++) {
        earningStake = foxStakeByCunning[advantage][earningIdx];
        _stakedTokens[earningStake.owner].add(earningStake.tokenId);
      }

      // Hunters
      earningLength = hunterStakeByMarksman[advantage].length;
      for (earningIdx = 5; earningIdx < earningLength; earningIdx++) {
        earningStake = hunterStakeByMarksman[advantage][earningIdx];
        _stakedTokens[earningStake.owner].add(earningStake.tokenId);
      }
    }

    _storeStaking = true;
  }

  /**
   * Realize $CARROT earnings and optionally unstake tokens.
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function calculateRewards(uint16[] calldata tokenIds) external view returns (uint256[] memory) {
    require(tx.origin == msg.sender, "eos only");

    IFoxGameNFT.Kind kind;
    IFoxGameNFT nftContract;
    uint256[] memory rewards = new uint256[](tokenIds.length);
    uint48 time = uint48(block.timestamp);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      nftContract = getTokenContract(tokenIds[i]);
      kind = _getKind(nftContract, tokenIds[i]);
      if (kind == IFoxGameNFT.Kind.RABBIT) {
        rewards[i] = _calculateRabbitReward(tokenIds[i], time);
      } else if (kind == IFoxGameNFT.Kind.FOX) {
        rewards[i] = _calculateFoxReward(nftContract, tokenIds[i]);
      } else { // HUNTER
        rewards[i] = _calculateHunterReward(nftContract, tokenIds[i], time);
      }
    }

    return rewards;
  }

  /**
   * Calculate rabbit reward.
   * @param tokenId the ID of the Rabbit to claim earnings from
   * @param time currnet block time
   * @return reward - the amount of $CARROT earned
   */
  function _calculateRabbitReward(uint16 tokenId, uint48 time) internal view returns (uint256) {
    TimeStake memory stake = rabbitStakeByToken[tokenId];
    require(stake.owner == msg.sender, "only token owners can unstake");

    // Calcuate time-based rewards
    uint256 reward = 0;
    if (totalCarrotEarned < MAXIMUM_GLOBAL_CARROT) {
      reward = (time - stake.time) * RABBIT_EARNING_RATE;
    } else if (stake.time <= lastClaimTimestamp) {
      // stop earning additional $CARROT if it's all been earned
      reward = (lastClaimTimestamp - stake.time) * RABBIT_EARNING_RATE;
    }

    // Fox tax
    return reward * (100 - RABBIT_CLAIM_TAX_PERCENTAGE) / 100;
  }

  /**
   * Calculate fox reward.
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @return reward - the amount of $CARROT earned
   */
  function _calculateFoxReward(IFoxGameNFT nftContract, uint16 tokenId) internal view returns (uint256) {
    uint8 cunning = _getAdvantagePoints(nftContract, tokenId);
    EarningStake memory stake = foxStakeByCunning[cunning][foxHierarchy[tokenId]];
    require(stake.owner == msg.sender, "only token owners can unstake");

    // Calculate advantage-based rewards
    return (cunning) * (carrotPerCunningPoint - stake.earningRate);
  }

  /**
   * Calculate hunter reward.
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param time currnet block time
   * @return reward - the amount of $CARROT earned
   */
  function _calculateHunterReward(IFoxGameNFT nftContract, uint16 tokenId, uint48 time) internal view returns (uint256) {
    uint8 marksman = _getAdvantagePoints(nftContract, tokenId);
    EarningStake memory earningStake = hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]];
    require(earningStake.owner == msg.sender, "only token owners can unstake");

    // Calculate advantage-based rewards
    uint256 reward = 0;
    reward = (marksman) * (carrotPerMarksmanPoint - earningStake.earningRate);

    // Calcuate time-based rewards
    TimeStake memory timeStake = hunterStakeByToken[tokenId];
    require(timeStake.owner == msg.sender, "only token owners can unstake");
    if (totalCarrotEarned < MAXIMUM_GLOBAL_CARROT) {
      reward += (time - timeStake.time) * HUNTER_EARNING_RATE;
    } else if (timeStake.time <= lastClaimTimestamp) {
      reward += (lastClaimTimestamp - timeStake.time) * HUNTER_EARNING_RATE;
    }

    return reward;
  }

  /**
   * Toggle staking / unstaking.
   */
  function togglePaused() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  /**
   * Sets a new signature verifier.
   */
  function setSignVerifier(address verifier) external onlyOwner {
    signVerifier = verifier;
  }

  /**
   * Update the NFT GEN 0 contract address.
   */
  function setNFTContract(address _address) external onlyOwner {
    foxNFT = IFoxGameNFT(_address);
  }

  /**
   * Update the NFT GEN 1 contract address.
   */
  function setNFTGen1Contract(address _address) external onlyOwner {
    foxNFTGen1 = IFoxGameNFT(_address);
  }

  /**
   * Update the utility token contract address.
   */
  function setCarrotContract(address _address) external onlyOwner {
    foxCarrot = IFoxGameCarrot(_address);
  }

  /**
   * Update the balance between Hunter and Fox tax distribution. 
   */
  function setHunterTaxCutPercentage(uint8 percentCut) external onlyOwner {
    hunterTaxCutPercentage = percentCut;
  }

  /**
   * Update the liklihood foxes will get stolen by hunters.
   */
  function setHunterStealFoxPropabilityMod(uint8 mod) external onlyOwner {
    hunterStealFoxProbabilityMod = mod;
  }

  /**
   * List staked tokens by user.
   */
  function depositsOf(address account) external view returns (uint16[] memory) {
    EnumerableSetUpgradeable.UintSet storage depositSet = _stakedTokens[account];
    uint16[] memory tokenIds = new uint16[] (depositSet.length());

    for (uint16 i; i < depositSet.length(); i++) {
      tokenIds[i] = uint16(depositSet.at(i));
    }

    return tokenIds;
  }

  /**
   * Store staking mapping from owners to tokens.
   */
  function setStoredStaking(bool value) external onlyOwner {
    _storeStaking = value;
  }

  /**
   * Interface support to allow player staking.
   */
  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {    
    require(from == address(0x0), "only allow directly from mint");
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IFoxGame {
  function stakeTokens(address, uint16[] calldata) external;
  function randomFoxOwner(uint256) external view returns (address);
  function isValidSignature(address, bool, uint48, uint256, bytes memory) external view returns (bool);
  function getSeed(uint16) external returns (uint256);
}

/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IFoxGameCarrot {
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
}

/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IFoxGameNFT {
  enum Kind { RABBIT, FOX, HUNTER }
  struct Traits { Kind kind; uint8 advantage; uint8[7] traits; }
  function getMaxGEN0Players() external pure returns (uint16);
  function getTraits(uint16) external view returns (Traits memory);
  function ownerOf(uint256) external view returns (address owner);
  function transferFrom(address, address, uint256) external;
  function safeTransferFrom(address, address, uint256, bytes memory) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}