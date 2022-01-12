// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Warrior.sol";
import "./GENE.sol";

contract Factory is Ownable, IERC721Receiver, Pausable {
  
  // maximum alpha score for a Warrior
  uint8 public constant MAX_ALPHA = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  event TokenStaked(address indexed owner, uint256 tokenId, uint256 value);
  event OrcClaimed(uint256 indexed tokenId, uint256 earned, bool indexed unstaked);
  event WarriorClaimed(uint256 indexed tokenId, uint256 earned, bool indexed unstaked);

  // reference to the Warrior NFT contract
  Warrior warrior;
  // reference to the $GENE contract for minting $GENE earnings
  GENE gene;

  // maps tokenId to stake
  mapping(uint256 => Stake) public factory; 
  // maps alpha to all Warrior stakes with that alpha
  mapping(uint256 => Stake[]) public pack; 
  // tracks location of each Warrior in Pack
  mapping(uint256 => uint256) public packIndices; 
  // total alpha scores staked
  uint256 public totalAlphaStaked = 0; 
  // any rewards distributed when no Warriors are staked
  uint256 public unaccountedRewards = 0; 
  // amount of $GENE due for each alpha point staked
  uint256 public genePerAlpha = 0; 

  // orc earn 10000 $GENE per day
  uint256 public constant DAILY_GENE_RATE = 10000 ether;
  // orc must have 2 days worth of $GENE to unstake or else it's too cold
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // Warriors take a 20% tax on all $GENE claimed
  uint256 public constant GENE_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $GENE earned through staking
  uint256 public constant MAXIMUM_GLOBAL_GENE = 2400000000 ether;

  // amount of $GENE earned so far
  uint256 public totalGeneEarned;
  // number of Orc staked in the Factory
  uint256 public totalOrcStaked;
  // the last time $GENE was claimed
  uint256 public lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $GENE
  bool public rescueEnabled = false;

  /**
   * @param _warrior reference to the Warrior NFT contract
   * @param _gene reference to the $GENE token
   */
  constructor(address _warrior, address _gene) { 
    warrior = Warrior(_warrior);
    gene = GENE(_gene);
  }

  /** STAKING */

  /**
   * adds Orc and Warriors to the Factory and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the Orc and Warriors to stake
   */
  function addManyToFactoryAndPack(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender() || _msgSender() == address(warrior), "DONT GIVE YOUR TOKENS AWAY");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(warrior)) { // dont do this step if its a mint + stake
        require(warrior.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        warrior.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (isOrc(tokenIds[i])) 
        _addOrcToFactory(account, tokenIds[i]);
      else 
        _addWarriorToPack(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Orc to the Factory
   * @param account the address of the staker
   * @param tokenId the ID of the Orc to add to the Factory
   */
  function _addOrcToFactory(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    factory[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalOrcStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single Warrior to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the Warrior to add to the Pack
   */
  function _addWarriorToPack(address account, uint256 tokenId) internal {
    uint256 alpha = _alphaForWarrior(tokenId);
    totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = pack[alpha].length; // Store the location of the warrior in the Pack
    pack[alpha].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(genePerAlpha)
    })); // Add the warrior to the Pack
    emit TokenStaked(account, tokenId, genePerAlpha);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $GENE earnings and optionally unstake tokens from the Factory / Pack
   * to unstake a Orc it will require it has 2 days worth of $GENE unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromFactoryAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isOrc(tokenIds[i]))
        owed += _claimOrcFromFactory(tokenIds[i], unstake);
      else
        owed += _claimWarriorFromPack(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    gene.mint(_msgSender(), owed);
  }

  /**
   * realize $GENE earnings for a single Orc and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Warriors
   * if unstaking, there is a 50% chance all $GENE is stolen
   * @param tokenId the ID of the Orc to claim earnings from
   * @param unstake whether or not to unstake the Orc
   * @return owed - the amount of $GENE earned
   */
  function _claimOrcFromFactory(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = factory[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S GENE");
    if (totalGeneEarned < MAXIMUM_GLOBAL_GENE) {
      owed = (block.timestamp - stake.value) * DAILY_GENE_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $GENE production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_GENE_RATE / 1 days; // stop earning additional $GENE if it's all been earned
    }
    if (unstake) {
      if (random(tokenId) & 1 == 1) { // 50% chance of all $GENE stolen
        _payWarriorTax(owed);
        owed = 0;
      }
      warrior.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Orc
      delete factory[tokenId];
      totalOrcStaked -= 1;
    } else {
      _payWarriorTax(owed * GENE_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked Warriors
      owed = owed * (100 - GENE_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Orc owner
      factory[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit OrcClaimed(tokenId, owed, unstake);
  }

  /**
   * realize $GENE earnings for a single Warrior and optionally unstake it
   * Warriors earn $GENE proportional to their Alpha rank
   * @param tokenId the ID of the Warrior to claim earnings from
   * @param unstake whether or not to unstake the Warrior
   * @return owed - the amount of $GENE earned
   */
  function _claimWarriorFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(warrior.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
    uint256 alpha = _alphaForWarrior(tokenId);
    Stake memory stake = pack[alpha][packIndices[tokenId]];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    owed = (alpha) * (genePerAlpha - stake.value); // Calculate portion of tokens based on Alpha
    if (unstake) {
      totalAlphaStaked -= alpha; // Remove Alpha from total staked
      warrior.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Warrior
      Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
      pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Warrior to current position
      packIndices[lastStake.tokenId] = packIndices[tokenId];
      pack[alpha].pop(); // Remove duplicate
      delete packIndices[tokenId]; // Delete old mapping
    } else {
      pack[alpha][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(genePerAlpha)
      }); // reset stake
    }
    emit WarriorClaimed(tokenId, owed, unstake);
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
      if (isOrc(tokenId)) {
        stake = factory[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        warrior.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Orc
        delete factory[tokenId];
        totalOrcStaked -= 1;
        emit OrcClaimed(tokenId, 0, true);
      } else {
        alpha = _alphaForWarrior(tokenId);
        stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalAlphaStaked -= alpha; // Remove Alpha from total staked
        warrior.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Warrior
        lastStake = pack[alpha][pack[alpha].length - 1];
        pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Warrior to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[alpha].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        emit WarriorClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $GENE to claimable pot for the Pack
   * @param amount $GENE to add to the pot
   */
  function _payWarriorTax(uint256 amount) internal {
    if (totalAlphaStaked == 0) { // if there's no staked Warriors
      unaccountedRewards += amount; // keep track of $GENE due to Warriors
      return;
    }
    // makes sure to include any unaccounted $GENE 
    genePerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $GENE earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalGeneEarned < MAXIMUM_GLOBAL_GENE) {
      totalGeneEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalOrcStaked
        * DAILY_GENE_RATE / 1 days; 
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
   * checks if a token is a Orc
   * @param tokenId the ID of the token to check
   * @return orc - whether or not a token is a Orc
   */
  function isOrc(uint256 tokenId) public view returns (bool orc) {
    orc = warrior.getTokenTraits(tokenId).isOrc;
  }

  /**
   * gets the alpha score for a Warrior
   * @param tokenId the ID of the Warrior to get the alpha score for
   * @return the alpha score of the Warrior (5-8)
   */
  function _alphaForWarrior(uint256 tokenId) internal view returns (uint8) {
    uint8 alphaIndex = warrior.getTokenTraits(tokenId).alphaIndex;
    return MAX_ALPHA - alphaIndex; // alpha index is 0-3
  }

  /**
   * chooses a random Warrior thief when a newly minted token is stolen
   * @param seed a random value to choose a Warrior from
   * @return the owner of the randomly selected Warrior thief
   */
  function randomWarriorOwner(uint256 seed) external view returns (address) {
    if (totalAlphaStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Warriors with the same alpha score
    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
      cumulative += pack[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Warrior with that alpha score
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
      require(from == address(0x0), "Cannot send tokens to Factory directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}