// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Game.sol";
import "./Feather.sol";

contract Barn is Ownable, IERC721Receiver, Pausable {
  
  // maximum alpha score for a Eagle
  uint8 public constant MAX_ALPHA = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event ChickClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event EagleClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  // reference to the game NFT contract
  Game game;
  // reference to the $Feather contract for minting $Feather earnings
  Feather feather;

  // maps tokenId to stake
  mapping(uint256 => Stake) public barn; 
  // maps alpha to all Eagle stakes with that alpha
  mapping(uint256 => Stake[]) public pack; 
  // tracks location of each Eagle in Pack
  mapping(uint256 => uint256) public packIndices; 
  // total alpha scores staked
  uint256 public totalAlphaStaked = 0; 
  // any rewards distributed when no wolves are staked
  uint256 public unaccountedRewards = 0; 
  // amount of $Feather due for each alpha point staked
  uint256 public featherPerAlpha = 0; 

  // sheep earn 10000 $Feather per day
  uint256 public constant DAILY_Feather_RATE = 10000 ether;
  // sheep must have 2 days worth of $Feather to unstake or else it's too cold
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // wolves take a 20% tax on all $Feather claimed
  uint256 public constant Feather_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $Feather earned through staking
  uint256 public constant MAXIMUM_GLOBAL_Feather = 2400000000 ether;

  // amount of $Feather earned so far
  uint256 public totalFeatherEarned;
  // number of Chick staked in the Barn
  uint256 public totalChickStaked;
  // the last time $Feather was claimed
  uint256 public lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $Feather
  bool public rescueEnabled = false;

  /**
   * @param _game reference to the game NFT contract
   * @param _feather reference to the $Feather token
   */
  constructor(address _game, address _feather) { 
    game = Game(_game);
    feather = Feather(_feather);
  }

  /** STAKING */

  /**
   * adds Chick and Wolves to the Barn and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the Chick and Wolves to stake
   */
  function addManyToBarnAndPack(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender() || _msgSender() == address(game), "DONT GIVE YOUR TOKENS AWAY");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(game)) { // dont do this step if its a mint + stake
        require(game.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        game.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (isChick(tokenIds[i])) 
        _addChickToBarn(account, tokenIds[i]);
      else 
        _addEagleToPack(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Chick to the Barn
   * @param account the address of the staker
   * @param tokenId the ID of the Chick to add to the Barn
   */
  function _addChickToBarn(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    barn[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalChickStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single Eagle to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the Eagle to add to the Pack
   */
  function _addEagleToPack(address account, uint256 tokenId) internal {
    uint256 alpha = _alphaForEagle(tokenId);
    totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = pack[alpha].length; // Store the location of the wolf in the Pack
    pack[alpha].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(featherPerAlpha)
    })); // Add the wolf to the Pack
    emit TokenStaked(account, tokenId, featherPerAlpha);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $Feather earnings and optionally unstake tokens from the Barn / Pack
   * to unstake a Chick it will require it has 2 days worth of $Feather unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromBarnAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isChick(tokenIds[i]))
        owed += _claimChickFromBarn(tokenIds[i], unstake);
      else
        owed += _claimEagleFromPack(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    feather.mint(_msgSender(), owed);
  }

  /**
   * realize $Feather earnings for a single Chick and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Wolves
   * if unstaking, there is a 50% chance all $Feather is stolen
   * @param tokenId the ID of the Chick to claim earnings from
   * @param unstake whether or not to unstake the Chick
   * @return owed - the amount of $Feather earned
   */
  function _claimChickFromBarn(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = barn[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S Feather");
    if (totalFeatherEarned < MAXIMUM_GLOBAL_Feather) {
      owed = (block.timestamp - stake.value) * DAILY_Feather_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $Feather production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_Feather_RATE / 1 days; // stop earning additional $Feather if it's all been earned
    }
    if (unstake) {
      if (random(tokenId) & 1 == 1) { // 50% chance of all $Feather stolen
        _payEagleTax(owed);
        owed = 0;
      }
      game.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Chick
      delete barn[tokenId];
      totalChickStaked -= 1;
    } else {
      _payEagleTax(owed * Feather_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked wolves
      owed = owed * (100 - Feather_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Chick owner
      barn[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit ChickClaimed(tokenId, owed, unstake);
  }

  /**
   * realize $Feather earnings for a single Eagle and optionally unstake it
   * Wolves earn $Feather proportional to their Alpha rank
   * @param tokenId the ID of the Eagle to claim earnings from
   * @param unstake whether or not to unstake the Eagle
   * @return owed - the amount of $Feather earned
   */
  function _claimEagleFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(game.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
    uint256 alpha = _alphaForEagle(tokenId);
    Stake memory stake = pack[alpha][packIndices[tokenId]];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    owed = (alpha) * (featherPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
    if (unstake) {
      totalAlphaStaked -= alpha; // Remove Alpha from total staked
      game.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Eagle
      Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
      pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Eagle to current position
      packIndices[lastStake.tokenId] = packIndices[tokenId];
      pack[alpha].pop(); // Remove duplicate
      delete packIndices[tokenId]; // Delete old mapping
    } else {
      pack[alpha][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(featherPerAlpha)
      }); // reset stake
    }
    emit EagleClaimed(tokenId, owed, unstake);
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
      if (isChick(tokenId)) {
        stake = barn[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        game.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Chick
        delete barn[tokenId];
        totalChickStaked -= 1;
        emit ChickClaimed(tokenId, 0, true);
      } else {
        alpha = _alphaForEagle(tokenId);
        stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalAlphaStaked -= alpha; // Remove Alpha from total staked
        game.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Eagle
        lastStake = pack[alpha][pack[alpha].length - 1];
        pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Eagle to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[alpha].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        emit EagleClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $Feather to claimable pot for the Pack
   * @param amount $Feather to add to the pot
   */
  function _payEagleTax(uint256 amount) internal {
    if (totalAlphaStaked == 0) { // if there's no staked wolves
      unaccountedRewards += amount; // keep track of $Feather due to wolves
      return;
    }
    // makes sure to include any unaccounted $Feather 
    featherPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $Feather earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalFeatherEarned < MAXIMUM_GLOBAL_Feather) {
      totalFeatherEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalChickStaked
        * DAILY_Feather_RATE / 1 days; 
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
   * checks if a token is a Chick
   * @param tokenId the ID of the token to check
   * @return sheep - whether or not a token is a Chick
   */
  function isChick(uint256 tokenId) public view returns (bool sheep) {
    (sheep, , , , , , , , , ) = game.tokenTraits(tokenId);
  }

  /**
   * gets the alpha score for a Eagle
   * @param tokenId the ID of the Eagle to get the alpha score for
   * @return the alpha score of the Eagle (5-8)
   */
  function _alphaForEagle(uint256 tokenId) internal view returns (uint8) {
    ( , , , , , , , , , uint8 alphaIndex) = game.tokenTraits(tokenId);
    return MAX_ALPHA - alphaIndex; // alpha index is 0-3
  }

  /**
   * chooses a random Eagle thief when a newly minted token is stolen
   * @param seed a random value to choose a Eagle from
   * @return the owner of the randomly selected Eagle thief
   */
  function randomEagleOwner(uint256 seed) external view returns (address) {
    if (totalAlphaStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Wolves with the same alpha score
    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
      cumulative += pack[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Eagle with that alpha score
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
      require(from == address(0x0), "Cannot send tokens to Barn directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}