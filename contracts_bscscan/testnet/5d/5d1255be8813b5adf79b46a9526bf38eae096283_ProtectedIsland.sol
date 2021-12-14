// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Goat.sol";
import "./EGG.sol";

contract ProtectedIsland is Ownable, IERC721Receiver, Pausable {
  // maximum fertility score for a Goat
  uint8 public constant MAX_FERTILITY = 4;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }
  struct Information {
      uint256[] stakedTokens;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event TortoiseClaimed(uint256 tokenId, uint256 earned, uint256 expected, bool unstaked);
  event GoatClaimed(uint256 tokenId, uint256 earned, uint256 expected, bool unstaked);

  // reference to the Goat NFT contract
  Goat goat;
  // reference to the $EGG contract for minting $EGG earnings
  EGG egg;
  // maps address for token id's per user
  mapping(address => Information) user;
  // maps tokenId to stake
  mapping(uint256 => Stake) public protectedIsland; 
  // maps fertility to all Goat stakes with that fertility
  mapping(uint256 => Stake[]) public pack; 
  // tracks location of each Goat in Pack
  mapping(uint256 => uint256) public packIndices; 
  // total fertility scores staked
  uint256 public totalFertilityStaked = 0; 
  // any rewards distributed when no goats are staked
  uint256 public unaccountedRewards = 0; 
  // amount of $EGG due for each fertility point staked
  uint256 public eggPerFertility = 0; 
  // amount of $EGG being claimed
  uint256 public eggClaimed = 0; 

  // Tortoise earn 10000 $EGG per day
  uint256 public constant DAILY_EGG_RATE = 10000 ether;
  // Tortoise must have 2 days worth of $EGG to unstake or else it's too cold
  uint256 public MINIMUM_TO_EXIT = 2 days;
  // goats take a 20% tax on all $EGG claimed
  uint256 public constant EGG_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $EGG earned through staking
  uint256 public constant MAXIMUM_GLOBAL_EGG = 2400000000 ether;

  // amount of $EGG earned so far
  uint256 public totalEggEarned;
  // number of Tortoise staked in the ProtectedIsland
  uint256 public totalTortoiseStaked;
  // number of Goat staked in the ProtectedIsland
  uint256 public totalGoatStaked;
  // the last time $EGG was claimed
  uint256 public lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $EGG
  bool public rescueEnabled = false;

  /**
   * @param _goat reference to the Goat NFT contract
   * @param _egg reference to the $EGG token
   */
  constructor(address _goat, address _egg) { 
    goat = Goat(_goat);
    egg = EGG(_egg);
  }

  /** STAKING */

  /**
   * adds Tortoise and Goats to the ProtectedIsland and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the Tortoise and Goats to stake
   */
  function addManyToProtectedIslandAndPack(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender() || _msgSender() == address(goat), "DONT GIVE YOUR TOKENS AWAY");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(goat)) { // dont do this step if its a mint + stake
        require(goat.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        goat.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (isTortoise(tokenIds[i])) 
        _addTortoiseToProtectedIsland(account, tokenIds[i]);
      else 
        _addGoatToPack(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Tortoise to the ProtectedIsland
   * @param account the address of the staker
   * @param tokenId the ID of the Tortoise to add to the ProtectedIsland
   */
  function _addTortoiseToProtectedIsland(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    protectedIsland[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalTortoiseStaked += 1;
    // add token id to user wallet
    user[account].stakedTokens.push(tokenId);
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single Goat to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the Goat to add to the Pack
   */
  function _addGoatToPack(address account, uint256 tokenId) internal {
    uint256 fertility = _fertilityForGoat(tokenId);
    totalFertilityStaked += fertility; // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = pack[fertility].length; // Store the location of the Goat in the Pack
    pack[fertility].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(eggPerFertility)
    })); // Add the Goat to the Pack
    totalGoatStaked += 1;
    // add token id to user wallet
    user[account].stakedTokens.push(tokenId);
    emit TokenStaked(account, tokenId, eggPerFertility);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $EGG earnings and optionally unstake tokens from the ProtectedIsland / Pack
   * to unstake a Tortoise it will require it has 2 days worth of $EGG unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromProtectedIslandAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
    require(tx.origin == _msgSender(), "Only EOA");
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isTortoise(tokenIds[i]))
        owed += _claimTortoiseFromProtectedIsland(tokenIds[i], unstake);
      else
        owed += _claimGoatFromPack(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    egg.mint(_msgSender(), owed);
  }

  /**
   * realize $EGG earnings for a single Tortoise and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Goats
   * if unstaking, there is a 50% chance all $EGG is stolen
   * @param tokenId the ID of the Tortoise to claim earnings from
   * @param unstake whether or not to unstake the Tortoise
   * @return owed - the amount of $EGG earned
   */
  function _claimTortoiseFromProtectedIsland(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = protectedIsland[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S EGG");
    if (totalEggEarned < MAXIMUM_GLOBAL_EGG) {
      owed = (block.timestamp - stake.value) * DAILY_EGG_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $EGG production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_EGG_RATE / 1 days; // stop earning additional $EGG if it's all been earned
    }
    uint256 expected = owed;
    if (unstake) {
      if (random(tokenId) & 1 == 1) { // 50% chance of all $EGG stolen
        _payGoatTax(owed);
        owed = 0;
      }
      goat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Tortoise

      delete protectedIsland[tokenId];
      totalTortoiseStaked -= 1;
      deleteStakedToken(_msgSender(), tokenId);
    } else {
      _payGoatTax(owed * EGG_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked goats
      owed = owed * (100 - EGG_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Tortoise owner
      protectedIsland[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }

    eggClaimed += owed;
    emit TortoiseClaimed(tokenId, owed, expected, unstake);
  }

  /**
   * realize $EGG earnings for a single Goat and optionally unstake it
   * Goats earn $EGG proportional to their Fertility rank
   * @param tokenId the ID of the Goat to claim earnings from
   * @param unstake whether or not to unstake the Goat
   * @return owed - the amount of $EGG earned
   */
  function _claimGoatFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(goat.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
    uint256 fertility = _fertilityForGoat(tokenId);
    Stake memory stake = pack[fertility][packIndices[tokenId]];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    owed = (fertility) * (eggPerFertility - stake.value); // Calculate portion of tokens based on Fertility
    uint256 expected = owed;
    if (unstake) {
      totalFertilityStaked -= fertility; // Remove Fertility from total staked
      goat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Goat
      Stake memory lastStake = pack[fertility][pack[fertility].length - 1];
      pack[fertility][packIndices[tokenId]] = lastStake; // Shuffle last Goat to current position
      packIndices[lastStake.tokenId] = packIndices[tokenId];
      pack[fertility].pop(); // Remove duplicate
      delete packIndices[tokenId]; // Delete old mapping
      totalGoatStaked -= 1;

      // removes token id from array
      deleteStakedToken(_msgSender(), tokenId);
    } else {
      pack[fertility][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(eggPerFertility)
      }); // reset stake
    }

    eggClaimed += owed;
    emit GoatClaimed(tokenId, owed, expected, unstake);
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
    uint256 fertility;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isTortoise(tokenId)) {
        stake = protectedIsland[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        goat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Tortoise
        delete protectedIsland[tokenId];
        totalTortoiseStaked -= 1;
        emit TortoiseClaimed(tokenId, 0, 0, true);
      } else {
        fertility = _fertilityForGoat(tokenId);
        stake = pack[fertility][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalFertilityStaked -= fertility; // Remove Fertility from total staked
        goat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Goat
        lastStake = pack[fertility][pack[fertility].length - 1];
        pack[fertility][packIndices[tokenId]] = lastStake; // Shuffle last Goat to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[fertility].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        totalGoatStaked -= 1;
        emit GoatClaimed(tokenId, 0, 0, true);
      }

      // removes token id from array
      deleteStakedToken(_msgSender(), tokenId);
    }
  }

  /** ACCOUNTING */
  /** 
  * returns all the staked token id's for a specifik _wallet
  * @param _wallet users wallet address 
  */
  function getStakedTokens(address _wallet) external view returns (uint256 [] memory) {
      return user[_wallet].stakedTokens;
  }

  /** 
   * add $EGG to claimable pot for the Pack
   * @param amount $EGG to add to the pot
   */
  function _payGoatTax(uint256 amount) internal {
    if (totalFertilityStaked == 0) { // if there's no staked goats
      unaccountedRewards += amount; // keep track of $EGG due to goats
      return;
    }
    // makes sure to include any unaccounted $EGG 
    eggPerFertility += (amount + unaccountedRewards) / totalFertilityStaked;
    unaccountedRewards = 0;
  }

  /**
  * tracks $EGG earnings to ensure it stops once 2.4 billion is eclipsed
  */
  modifier _updateEarnings() {
    if (totalEggEarned < MAXIMUM_GLOBAL_EGG) {
      totalEggEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalTortoiseStaked
        * DAILY_EGG_RATE / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

  /**
  * Deletes the token id based on the index value of the struct array
  */
  function deleteStakedTokenFromUserByIndex(uint _index) internal returns(bool) {
    for (uint i = _index; i < user[_msgSender()].stakedTokens.length - 1; i++) {
      user[_msgSender()].stakedTokens[i] = user[_msgSender()].stakedTokens[i + 1];
    }

    user[_msgSender()].stakedTokens.pop();
    return true;
  } 

  /**
  * Deletes the token id based on the index value of the struct array
  */
  function deleteStakedToken(address _user, uint256 _tokenId) internal {
    for (uint256 index = 0; index < user[_user].stakedTokens.length; index++) {
      if(user[_user].stakedTokens[index] == _tokenId) {
        deleteStakedTokenFromUserByIndex(index);
      }
    }
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

  /**
  * @param _minimumTimeToExit the amount for exiting the stake
  */
  function setMinimumTimeToExit(uint256 _minimumTimeToExit) external onlyOwner {
    MINIMUM_TO_EXIT = _minimumTimeToExit;
  }

  /** READ ONLY */

  /**
   * checks if a token is a Tortoise
   * @param tokenId the ID of the token to check
   * @return Tortoise - whether or not a token is a Tortoise
   */
  function isTortoise(uint256 tokenId) public view returns (bool Tortoise) {
    (Tortoise, , , , , , , , , , ) = goat.tokenTraits(tokenId);
  }

  /**
   * gets the fertility score for a Goat
   * @param tokenId the ID of the Goat to get the fertility score for
   * @return the fertility score of the Goat (5-8)
   */
  function _fertilityForGoat(uint256 tokenId) internal view returns (uint8) {
    ( , , , , , , , , , , uint8 fertilityIndex) = goat.tokenTraits(tokenId);
    return MAX_FERTILITY - fertilityIndex; // fertility index is 0-3
  }

  /**
   * chooses a random Goat thief when a newly minted token is stolen
   * @param seed a random value to choose a Goat from
   * @return the owner of the randomly selected Goat thief
   */
  function randomGoatOwner(uint256 seed) external view returns (address) {
    if (totalFertilityStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalFertilityStaked; // choose a value from 0 to total fertility staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Goats with the same fertility score
    for (uint i = MAX_FERTILITY - 3; i <= MAX_FERTILITY; i++) {
      cumulative += pack[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Goat with that fertility score
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
      require(from == address(0x0), "Cannot send tokens to ProtectedIsland directly");
      return IERC721Receiver.onERC721Received.selector;
    }
}