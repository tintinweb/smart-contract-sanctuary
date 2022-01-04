// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Rat.sol";
import "./CHEESE.sol";

contract Race is Ownable, IERC721Receiver, Pausable {
  
  // maximum greed level for a FatRat
  uint8 public constant MAX_ALPHA = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event SewerRatClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event FatRatClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event UpgradeAttempt(uint256 tokenId, string skill, uint256 attempts, uint256 levelsGained, uint256 newLevel);

  // reference to the Rat NFT contract
  Rat rat;
  // reference to the $CHEESE contract for minting $CHEESE earnings
  CHEESE cheese;

  // maps tokenId to stake
  mapping(uint256 => Stake) public race; 
  // maps greed to all FatRat stakes with that greed
  mapping(uint256 => Stake[]) public pack; 
  // tracks location of each FatRat in Pack
  mapping(uint256 => uint256) public packIndices; 
  // total greed levels staked
  uint256 public totalGreedStaked = 0; 
  // any rewards distributed when no wolves are staked
  uint256 public unaccountedRewards = 0; 
  // amount of $CHEESE due for each greed point staked
  uint256 public cheesePerGreed = 0; 

  // sewerRat earn 10000 $CHEESE per day
  uint256 public constant DAILY_CHEESE_RATE = 10000 ether;
  // sewerRat must have 2 days worth of $CHEESE to unstake or else it's too cold
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // wolves take a 20% tax on all $CHEESE claimed
  uint256 public constant CHEESE_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $CHEESE earned through staking
  uint256 public constant MAXIMUM_GLOBAL_CHEESE = 2400000000 ether;

  // amount of $CHEESE earned so far
  uint256 public totalCheeseEarned;
  // number of SewerRat staked in the Race
  uint256 public totalSewerRatStaked;
  // the last time $CHEESE was claimed
  uint256 public lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $CHEESE
  bool public rescueEnabled = false;

  /**
   * @param _rat reference to the Rat NFT contract
   * @param _cheese reference to the $CHEESE token
   */
  constructor(address _rat, address _cheese) { 
    rat = Rat(_rat);
    cheese = CHEESE(_cheese);
  }

  /** STAKING */

  /**
   * adds SewerRat and Fat Rats to the Race and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the SewerRat and Fat Rats to stake
   */
  function addManyToRace(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender() || _msgSender() == address(rat), "DONT GIVE YOUR TOKENS AWAY");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(rat)) { // dont do this step if its a mint + stake
        require(rat.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        rat.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (isSewerRat(tokenIds[i])) 
        _addSewerRatToRace(account, tokenIds[i]);
      else 
        _addFatRatToPack(account, tokenIds[i]);
    }
  }

  /**
   * adds a single SewerRat to the Race
   * @param account the address of the staker
   * @param tokenId the ID of the SewerRat to add to the Race
   */
  function _addSewerRatToRace(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    race[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalSewerRatStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single FatRat to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the FatRat to add to the Pack
   */
  function _addFatRatToPack(address account, uint256 tokenId) internal {
    uint256 greed = _greedForFatRat(tokenId);
    totalGreedStaked += greed; // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = pack[greed].length; // Store the location of the wolf in the Pack
    pack[greed].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(cheesePerGreed)
    })); // Add the wolf to the Pack
    emit TokenStaked(account, tokenId, cheesePerGreed);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $CHEESE earnings and optionally unstake tokens from the Race / Pack
   * to unstake a SewerRat it will require it has 2 days worth of $CHEESE unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromRaceAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isSewerRat(tokenIds[i]))
        owed += _claimSewerRatFromRace(tokenIds[i], unstake);
      else
        owed += _claimFatRatFromPack(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    cheese.mint(_msgSender(), owed);
  }

  /**
   * realize $CHEESE earnings for a single SewerRat and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Fat Rats
   * if unstaking, there is a 50% chance all $CHEESE is stolen
   * @param tokenId the ID of the SewerRat to claim earnings from
   * @param unstake whether or not to unstake the SewerRat
   * @return owed - the amount of $CHEESE earned
   */
  function _claimSewerRatFromRace(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = race[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S CHEESE");
    if (totalCheeseEarned < MAXIMUM_GLOBAL_CHEESE) {
      owed = (block.timestamp - stake.value) * DAILY_CHEESE_RATE / 1 minutes;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $CHEESE production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_CHEESE_RATE / 1 minutes; // stop earning additional $CHEESE if it's all been earned
    }
    if (unstake) {
      if (random(tokenId) & 1 == 1) { // 50% chance of all $CHEESE stolen
        _payFatRatTax(owed);
        owed = 0;
      }
      rat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back SewerRat
      delete race[tokenId];
      totalSewerRatStaked -= 1;
    } else {
      _payFatRatTax(owed * CHEESE_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked wolves
      owed = owed * (100 - CHEESE_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to SewerRat owner
      race[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit SewerRatClaimed(tokenId, owed, unstake);
  }

  /**
   * realize $CHEESE earnings for a single FatRat and optionally unstake it
   * Fat Rats earn $CHEESE proportional to their Greed rank
   * @param tokenId the ID of the FatRat to claim earnings from
   * @param unstake whether or not to unstake the FatRat
   * @return owed - the amount of $CHEESE earned
   */
  function _claimFatRatFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(rat.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
    uint256 greed = _greedForFatRat(tokenId);
    Stake memory stake = pack[greed][packIndices[tokenId]];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    owed = (greed) * (cheesePerGreed - stake.value); // Calculate portion of tokens based on Greed
    if (unstake) {
      totalGreedStaked -= greed; // Remove Greed from total staked
      rat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back FatRat
      Stake memory lastStake = pack[greed][pack[greed].length - 1];
      pack[greed][packIndices[tokenId]] = lastStake; // Shuffle last FatRat to current position
      packIndices[lastStake.tokenId] = packIndices[tokenId];
      pack[greed].pop(); // Remove duplicate
      delete packIndices[tokenId]; // Delete old mapping
    } else {
      pack[greed][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(cheesePerGreed)
      }); // reset stake
    }
    emit FatRatClaimed(tokenId, owed, unstake);
  }

  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external {
    require(rescueEnabled, "RESCUE DISABLED");
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint256 greed;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isSewerRat(tokenId)) {
        stake = race[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        rat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back SewerRat
        delete race[tokenId];
        totalSewerRatStaked -= 1;
        emit SewerRatClaimed(tokenId, 0, true);
      } else {
        greed = _greedForFatRat(tokenId);
        stake = pack[greed][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalGreedStaked -= greed; // Remove Greed from total staked
        rat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back FatRat
        lastStake = pack[greed][pack[greed].length - 1];
        pack[greed][packIndices[tokenId]] = lastStake; // Shuffle last FatRat to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[greed].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        emit FatRatClaimed(tokenId, 0, true);
      }
    }
  }

  /** UPGRADING */

  /**
   * attempt to upgrade your Rats Speed/Intellect or Greed/Strength levels
   * this will keep attemping to upgrade until the amount of $CHEESE is used
   * or the amount of upgrade attempts is reached
   * @param tokenId the ID of the SewerRat to try upgrade
   * @param amount the amount of $CHEESE to be used
   * @param attempts the amount of upgrade attempts
   * @param skill the skill to attempt to upgrade
   */

   function attemptUpgrade(uint256 tokenId, uint256 amount, uint256 attempts, uint256 skill) external {     
     amount = amount;
     skill = skill;
    //  require(rat.ownerOf(tokenId) == _msgSender(), "ISNT YOUR RAT"); // require _msgSender() == rat.owner
     // require tokenid balance = amountforupgrades
     // balance = balance - maxCheeseToBeUsed
     
    // SewerFat t = tokenTraits[tokenId];
    // t.isSewerRat = (seed & 0xFFFF) % 10 != 0;
    uint256 currentLevel = _greedForFatRat(tokenId);
    //  uint256 currentLevel = skill == 0 ? tokenTraits[tokenId][speedGreed] : tokenTraits[tokenId][intellectStrength];
     uint256 levelsGained = 0;
     uint256 seed = random(attempts); // get random number
     for (uint i = 0; i < attempts; i++) {
       if (currentLevel > 9 || currentLevel + levelsGained > 9) {
         break;
       }
       // use seed to see if upgrade succesful
       seed >>= 16;
       if ((seed & 0xFFFF) % 10 != 0) { // !=0 = 90% chance , ==0 = 10% chance of upgrade
          levelsGained++;
       }
     }

     // **refund any leftover CHEESE **
     // attemptsMade * cost = totalCheeseUsed
     // balance = balance + (maxCheeseToBeUsed - totalCheeseUsed)

     IRat.SewerFat memory s = rat.getTokenTraits(tokenId);
     s.speedGreed = uint8(currentLevel + levelsGained);
    //  rat.tokenTraits[tokenId] = s;
     rat.updateTraits(tokenId, s);
     
    emit UpgradeAttempt(tokenId, "Greed", attempts, levelsGained, currentLevel + levelsGained);
     // Update tokenId with NEW level (currentLevel + levelsGained)
     // Generate new tokenURI for Rat
     // Assign new token URI
     // event(5 attempts, 1 level gained, New Speed Level = 6)
     
  }

  // function attemptUpgrade(uint256 tokenIds) external {
  //   require(_msgSender() == address(rat), "DONT GIVE YOUR TOKENS AWAY");
  //   for (uint i = 0; i < tokenIds.length; i++) {
  //     if (_msgSender() != address(rat)) { // dont do this step if its a mint + stake
  //       require(rat.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
  //       rat.transferFrom(_msgSender(), address(this), tokenIds[i]);
  //     } else if (tokenIds[i] == 0) {
  //       continue; // there may be gaps in the array for stolen tokens
  //     }

  //     if (isSewerRat(tokenIds[i])) 
  //       _addSewerRatToRace(account, tokenIds[i]);
  //     else 
  //       _addFatRatToPack(account, tokenIds[i]);
  //   }
  // }

  /** ACCOUNTING */

  /** 
   * add $CHEESE to claimable pot for the Pack
   * @param amount $CHEESE to add to the pot
   */
  function _payFatRatTax(uint256 amount) internal {
    if (totalGreedStaked == 0) { // if there's no staked wolves
      unaccountedRewards += amount; // keep track of $CHEESE due to wolves
      return;
    }
    // makes sure to include any unaccounted $CHEESE 
    cheesePerGreed += (amount + unaccountedRewards) / totalGreedStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $CHEESE earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalCheeseEarned < MAXIMUM_GLOBAL_CHEESE) {
      totalCheeseEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalSewerRatStaked
        * DAILY_CHEESE_RATE / 1 minutes; 
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

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** READ ONLY */

  /**
   * checks if a token is a SewerRat
   * @param tokenId the ID of the token to check
   * @return sewerRat - whether or not a token is a SewerRat
   */
  function isSewerRat(uint256 tokenId) public view returns (bool sewerRat) {
    (sewerRat, , , , , , , , , ) = rat.tokenTraits(tokenId);
  }

  /**
   * gets the greed level for a FatRat
   * @param tokenId the ID of the FatRat to get the greed level for
   * @return the greed level of the FatRat (5-8)
   */
  function _greedForFatRat(uint256 tokenId) public view returns (uint8) { // was INTERNAL not PUBLIC - REMOVE THIS
    ( , , , , , , , , uint8 greedLevel, ) = rat.tokenTraits(tokenId);
    return greedLevel + 1; // greed level is 0-9 must + 1 to get actual level
  }

  /**
   * chooses a random FatRat thief when a newly minted token is stolen
   * @param seed a random value to choose a FatRat from
   * @return the owner of the randomly selected FatRat thief
   */
  function randomFatRatOwner(uint256 seed) external view returns (address) {
    if (totalGreedStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalGreedStaked; // choose a value from 0 to total greed staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Fat Rats with the same greed level
    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
      cumulative += pack[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random FatRat with that greed level
      return pack[i][seed % pack[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed
    )));
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Race directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}