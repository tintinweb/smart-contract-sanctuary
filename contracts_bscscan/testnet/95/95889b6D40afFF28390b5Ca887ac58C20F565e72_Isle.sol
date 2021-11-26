// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Goat.sol";
import "./EGGS.sol";

contract Isle is Ownable, IERC721Receiver, Pausable {
  
  // maximum alpha score for a Goat
  uint8 public constant MAX_ALPHA = 8;
  bool lock;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event TortoiseClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event GoatClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  // reference to the Goat NFT contract
  Goat goat;
  // reference to the $EGGS contract for minting $EGGS earnings
  EGGS eggs;

  // maps tokenId to stake
  mapping(uint256 => Stake) public isle; 
  // maps alpha to all Goat stakes with that alpha
  mapping(uint256 => Stake[]) public pack; 
  // tracks location of each Goat in Pack
  mapping(uint256 => uint256) public packIndices; 
  // total alpha scores staked
  uint256 public totalAlphaStaked = 0; 
  // any rewards distributed when no wolves are staked
  uint256 public unaccountedRewards = 0; 
  // amount of $EGGS due for each alpha point staked
  uint256 public eggsPerAlpha = 0; 

  // tortoise earn 10000 $EGGS per day
  uint256 public constant DAILY_EGGS_RATE = 10000 ether;
  // tortoise must have 2 days worth of $EGGS to unstake or else it's too cold
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // Goat take a 20% tax on all $EGGS claimed
  uint256 public constant EGGS_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $EGGS earned through staking
  uint256 public constant MAXIMUM_GLOBAL_EGGS = 2400000000 ether;

  // amount of $EGGS earned so far
  uint256 public totalEggsEarned;
  // number of Tortoise staked in the Isle
  uint256 public totalTortoiseStaked;
  // the last time $EGGS was claimed
  uint256 public lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $EGGS
  bool public rescueEnabled = false;

  /**
   * @param _goat reference to the Tortoise NFT contract
   * @param _eggs reference to the $EGGS token
   */
  constructor(address _goat, address _eggs) { 
    goat = Goat(_goat);
    eggs = EGGS(_eggs);
  }

  /** STAKING */

  /**
   * adds Tortoises and Goats to the Isle and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the Tortoises and Goats to stake
   */
  function addManyToIsleAndPack(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender() || _msgSender() == address(goat), "DONT GIVE YOUR TOKENS AWAY");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(goat)) { // dont do this step if its a mint + stake
        require(goat.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        goat.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (isTortoise(tokenIds[i])) 
        _addTortoiseToIsle(account, tokenIds[i]);
      else 
        _addTortoiseToIsle(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Tortoise to the Isle
   * @param account the address of the staker
   * @param tokenId the ID of the Tortoise to add to the Isle
   */
  function _addTortoiseToIsle(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    isle[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalTortoiseStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single Goat to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the Goat to add to the Pack
   */
  function _addGoatToPack(address account, uint256 tokenId) internal {
    uint256 alpha = _alphaForGoat(tokenId);
    totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = pack[alpha].length; // Store the location of the Goat in the Pack
    pack[alpha].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(eggsPerAlpha)
    })); // Add the goat to the Pack
    emit TokenStaked(account, tokenId, eggsPerAlpha);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $EGGS earnings and optionally unstake tokens from the Isle / Pack
   * to unstake a Tortoise it will require it has 2 days worth of $EGGS unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromIsleAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isTortoise(tokenIds[i]))
        owed += _claimTortoiseFromIsle(tokenIds[i], unstake);
      else
        owed += _claimGoatFromPack(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    eggs.mint(_msgSender(), owed);
  }

  /**
   * realize $EGGS earnings for a single Tortoise and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Goats
   * if unstaking, there is a 50% chance all $EGGS is stolen
   * @param tokenId the ID of the Tortoise to claim earnings from
   * @param unstake whether or not to unstake the Tortoise
   * @return owed - the amount of $EGGS earned
   */
  function _claimTortoiseFromIsle(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = isle[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S EGGS");
    if (totalEggsEarned < MAXIMUM_GLOBAL_EGGS) {
      owed = (block.timestamp - stake.value) * DAILY_EGGS_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $EGGS production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_EGGS_RATE / 1 days; // stop earning additional $EGGS if it's all been earned
    }
    if (unstake) {
      
      if (random(tokenId) & 1 == 1) { // 50% chance of all $EGGS stolen
        _payGoatTax(owed);
        owed = 0;
      }
      require(!lock);
      lock = true;
      goat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Tortoise
      delete isle[tokenId];
      totalTortoiseStaked -= 1;
      lock = false;
    } else {
      _payGoatTax(owed * EGGS_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked goats
      owed = owed * (100 - EGGS_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to goat owner
      isle[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit TortoiseClaimed(tokenId, owed, unstake);
  }

  /**
   * realize $EGGS earnings for a single Goat and optionally unstake it
   * Wolves earn $EGGS proportional to their Alpha rank
   * @param tokenId the ID of the Goat to claim earnings from
   * @param unstake whether or not to unstake the Goat
   * @return owed - the amount of $EGGS earned
   */
  function _claimGoatFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(!lock);
    lock = true;
    require(goat.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
    uint256 alpha = _alphaForGoat(tokenId);
    Stake memory stake = pack[alpha][packIndices[tokenId]];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    owed = (alpha) * (eggsPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
    if (unstake) {
      totalAlphaStaked -= alpha; // Remove Alpha from total staked
      goat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Goat
      Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
      pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Goat to current position
      packIndices[lastStake.tokenId] = packIndices[tokenId];
      pack[alpha].pop(); // Remove duplicate
      delete packIndices[tokenId]; // Delete old mapping
    } else {
      pack[alpha][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(eggsPerAlpha)
      }); // reset stake
    }
    emit GoatClaimed(tokenId, owed, unstake);
    lock = false;
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
    uint256 alpha;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isTortoise(tokenId)) {
        stake = isle[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        goat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Tortoise
        delete isle[tokenId];
        totalTortoiseStaked -= 1;
        emit TortoiseClaimed(tokenId, 0, true);
      } else {
        alpha = _alphaForGoat(tokenId);
        stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalAlphaStaked -= alpha; // Remove Alpha from total staked
        goat.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Goat
        lastStake = pack[alpha][pack[alpha].length - 1];
        pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Goat to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[alpha].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        emit GoatClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $EGGS to claimable pot for the Pack
   * @param amount $EGGS to add to the pot
   */
  function _payGoatTax(uint256 amount) internal {
    if (totalAlphaStaked == 0) { // if there's no staked goats
      unaccountedRewards += amount; // keep track of $EGGS due to wolves
      return;
    }
    // makes sure to include any unaccounted $EGGS 
    eggsPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $EGGS earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalEggsEarned < MAXIMUM_GLOBAL_EGGS) {
      totalEggsEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalTortoiseStaked
        * DAILY_EGGS_RATE / 1 days; 
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
   * checks if a token is a Tortoise
   * @param tokenId the ID of the token to check
   * @return tortoise - whether or not a token is a Tortoise
   */
  function isTortoise(uint256 tokenId) public view returns (bool tortoise) {
    (tortoise, , , , , , , , , ) = goat.tokenTraits(tokenId);
  }

  /**
   * gets the alpha score for a Goat
   * @param tokenId the ID of the Goat to get the alpha score for
   * @return the alpha score of the Goat (5-8)
   */
  function _alphaForGoat(uint256 tokenId) internal view returns (uint8) {
    ( , , , , , , , , , uint8 alphaIndex) = goat.tokenTraits(tokenId);
    return MAX_ALPHA - alphaIndex; // alpha index is 0-3
  }

  /**
   * chooses a random Goat thief when a newly minted token is stolen
   * @param seed a random value to choose a Goat from
   * @return the owner of the randomly selected Goat thief
   */
  function randomGoatOwner(uint256 seed) external view returns (address) {
    if (totalAlphaStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Wolves with the same alpha score
    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
      cumulative += pack[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Goat with that alpha score
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
      require(from == address(0x0), "Cannot send tokens to Isle directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}