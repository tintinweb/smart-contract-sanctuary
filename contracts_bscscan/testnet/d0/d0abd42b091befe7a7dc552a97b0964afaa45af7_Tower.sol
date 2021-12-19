// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IWnDGame.sol";
import "./IWnD.sol";
import "./IGP.sol";
import "./ITower.sol";
import "./ISacrificialAlter.sol";
import "./IRandomizer.sol";

contract Tower is ITower, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  
  // maximum rank for a Wizard/Dragon
  uint8 public constant MAX_RANK = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  uint256 public totalRankStaked;
  uint256 public numWizardsStaked;

  event TokenStaked(address indexed owner, uint256 indexed tokenId, bool indexed isWizard, uint256 value);
  event WizardClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
  event DragonClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);

  // reference to the WnD NFT contract
  IWnD public wndNFT;
  // reference to the WnD NFT contract
  IWnDGame public wndGame;
  // reference to the $GP contract for minting $GP earnings
  IGP public gpToken;
  // reference to Randomer 
  IRandomizer public randomizer;

  // maps tokenId to stake
  mapping(uint256 => Stake) private tower; 
  // maps rank to all Dragon staked with that rank
  mapping(uint256 => Stake[]) private flight; 
  // tracks location of each Dragon in Flight
  mapping(uint256 => uint256) private flightIndices; 


 // maps used to shake list for address
  mapping(address => uint256[]) public listShaked;
  // maps used to unShake list for address
  mapping(address => uint256[]) public unListShaked;

  // any rewards distributed when no dragons are staked
  uint256 private unaccountedRewards = 0; 
  // amount of $GP due for each rank point staked
  uint256 private gpPerRank = 0; 

  // wizards earn 12000 $GP per day
  uint256 public constant DAILY_GP_RATE = 12000 ether;
  // wizards must have 2 days worth of $GP to unstake or else they're still guarding the tower
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // dragons take a 20% tax on all $GP claimed
  uint256 public constant GP_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $GP earned through staking
  uint256 public constant MAXIMUM_GLOBAL_GP = 2880000000 ether;
  uint256 public treasureChestTypeId;

  // amount of $GP earned so far
  uint256 public totalGPEarned;
  // the last time $GP was claimed
  uint256 private lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $GP
  bool public rescueEnabled = false;

  /**
   */
  constructor() {
    //_pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(wndNFT) != address(0) && address(gpToken) != address(0) 
        && address(wndGame) != address(0) && address(randomizer) != address(0), "Contracts not set");
      _;
  }

  function setContracts(address _wndNFT, address _gpCoin, address _wndGame, address _rand) external onlyOwner {
    wndNFT = IWnD(_wndNFT);
    gpToken = IGP(_gpCoin);
    wndGame = IWnDGame(_wndGame);
    randomizer = IRandomizer(_rand);
  }

  function setTreasureChestId(uint256 typeId) external onlyOwner {
    treasureChestTypeId = typeId;
  }

  /** STAKING */

  /**
   * adds Wizards and Dragons to the Tower and Flight
   * @param account the address of the staker
   * @param tokenIds the IDs of the Wizards and Dragons to stake
   */
  function addManyToTowerAndFlight(address account, uint16[] calldata tokenIds) external override nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(wndGame), "Only EOA");
    require(account == tx.origin, "account to sender mismatch");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(wndGame)) { // dont do this step if its a mint + stake
        require(wndNFT.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
        wndNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }
      _addShakingList(account,tokenIds[i]);
      if (wndNFT.isWizard(tokenIds[i])) 
        _addWizardToTower(account, tokenIds[i]);
      else 
        _addDragonToFlight(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Wizard to the Tower
   * @param account the address of the staker
   * @param tokenId the ID of the Wizard to add to the Tower
   */
  function _addWizardToTower(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    tower[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    numWizardsStaked += 1;
    emit TokenStaked(account, tokenId, true, block.timestamp);
  }

  /**
   * adds a single Dragon to the Flight
   * @param account the address of the staker
   * @param tokenId the ID of the Dragon to add to the Flight
   */
  function _addDragonToFlight(address account, uint256 tokenId) internal {
    uint8 rank = _rankForDragon(tokenId);
    totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
    flightIndices[tokenId] = flight[rank].length; // Store the location of the dragon in the Flight
    flight[rank].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(gpPerRank)
    })); // Add the dragon to the Flight
    emit TokenStaked(account, tokenId, false, gpPerRank);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $GP earnings and optionally unstake tokens from the Tower / Flight
   * to unstake a Wizard it will require it has 2 days worth of $GP unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromTowerAndFlight(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(wndGame), "Only EOA");
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (wndNFT.isWizard(tokenIds[i])) {
        owed += _claimWizardFromTower(tokenIds[i], unstake);
      }
      else {
        owed += _claimDragonFromFlight(tokenIds[i], unstake);
      }
    }
    gpToken.updateOriginAccess();
    if (owed == 0) {
      return;
    }
    gpToken.mint(_msgSender(), owed);
  }

  function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
    uint64 lastTokenWrite = wndNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    Stake memory stake = tower[tokenId];
    if(wndNFT.isWizard(tokenId)) {
      if (totalGPEarned < MAXIMUM_GLOBAL_GP) {
        owed = (block.timestamp - stake.value) * DAILY_GP_RATE / 1 days;
      } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $GP production stopped already
      } else {
        owed = (lastClaimTimestamp - stake.value) * DAILY_GP_RATE / 1 days; // stop earning additional $GP if it's all been earned
      }
    }
    else {
      uint8 rank = _rankForDragon(tokenId);
      owed = (rank) * (gpPerRank - stake.value); // Calculate portion of tokens based on Rank
    }
  }

  /**
   * realize $GP earnings for a single Wizard and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Dragons
   * if unstaking, there is a 50% chance all $GP is stolen
   * @param tokenId the ID of the Wizards to claim earnings from
   * @param unstake whether or not to unstake the Wizards
   * @return owed - the amount of $GP earned
   */
  function _claimWizardFromTower(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = tower[tokenId];
    require(stake.owner == _msgSender(), "Don't own the given token");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "Still guarding the tower");
    if (totalGPEarned < MAXIMUM_GLOBAL_GP) {
      owed = (block.timestamp - stake.value) * DAILY_GP_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $GP production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_GP_RATE / 1 days; // stop earning additional $GP if it's all been earned
    }
    if (unstake) {
      randomizer.addNonce(tokenId);
      if (randomizer.random(tokenId) & 1 == 1) { // 50% chance of all $GP stolen
        _payDragonTax(owed);
        owed = 0;
      }
      _delShakingList(_msgSender(),tokenId);
      delete tower[tokenId];
      numWizardsStaked -= 1;
      // Always transfer last to guard against reentrance
      wndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Wizard
    } else {
      _payDragonTax(owed * GP_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked dragons
      owed = owed * (100 - GP_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Wizard owner
      tower[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit WizardClaimed(tokenId, unstake, owed);
  }

  /**
   * realize $GP earnings for a single Dragon and optionally unstake it
   * Dragons earn $GP proportional to their rank
   * @param tokenId the ID of the Dragon to claim earnings from
   * @param unstake whether or not to unstake the Dragon
   * @return owed - the amount of $GP earned
   */
  function _claimDragonFromFlight(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(wndNFT.ownerOf(tokenId) == address(this), "Doesn't own token");
    uint8 rank = _rankForDragon(tokenId);
    Stake memory stake = flight[rank][flightIndices[tokenId]];
    require(stake.owner == _msgSender(), "Doesn't own token");
    owed = (rank) * (gpPerRank - stake.value); // Calculate portion of tokens based on Rank
    if (unstake) {
      totalRankStaked -= rank; // Remove rank from total staked
      Stake memory lastStake = flight[rank][flight[rank].length - 1];
      flight[rank][flightIndices[tokenId]] = lastStake; // Shuffle last Dragon to current position
      flightIndices[lastStake.tokenId] = flightIndices[tokenId];
      flight[rank].pop(); // Remove duplicate
      _delShakingList(_msgSender(),tokenId);
      delete flightIndices[tokenId]; // Delete old mapping
      // Always remove last to guard against reentrance
      wndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Dragon
    } else {
      flight[rank][flightIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(gpPerRank)
      }); // reset stake
    }
    emit DragonClaimed(tokenId, unstake, owed);
  }
  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint8 rank;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (wndNFT.isWizard(tokenId)) {
        stake = tower[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        delete tower[tokenId];
        numWizardsStaked -= 1;
        wndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Wizards
        emit WizardClaimed(tokenId, true, 0);
      } else {
        rank = _rankForDragon(tokenId);
        stake = flight[rank][flightIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalRankStaked -= rank; // Remove Rank from total staked
        lastStake = flight[rank][flight[rank].length - 1];
        flight[rank][flightIndices[tokenId]] = lastStake; // Shuffle last Dragon to current position
        flightIndices[lastStake.tokenId] = flightIndices[tokenId];
        flight[rank].pop(); // Remove duplicate
        delete flightIndices[tokenId]; // Delete old mapping
        wndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Dragon
        emit DragonClaimed(tokenId, true, 0);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $GP to claimable pot for the Flight
   * @param amount $GP to add to the pot
   */
  function _payDragonTax(uint256 amount) internal {
    if (totalRankStaked == 0) { // if there's no staked dragons
      unaccountedRewards += amount; // keep track of $GP due to dragons
      return;
    }
    // makes sure to include any unaccounted $GP 
    gpPerRank += (amount + unaccountedRewards) / totalRankStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $GP earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalGPEarned < MAXIMUM_GLOBAL_GP) {
      totalGPEarned += 
        (block.timestamp - lastClaimTimestamp)
        * numWizardsStaked
        * DAILY_GP_RATE / 1 days; 
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
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** READ ONLY */

  /**
   * gets the rank score for a Dragon
   * @param tokenId the ID of the Dragon to get the rank score for
   * @return the rank score of the Dragon (5-8)
   */
  function _rankForDragon(uint256 tokenId) internal view returns (uint8) {
    IWnD.WizardDragon memory s = wndNFT.getTokenTraits(tokenId);
    return MAX_RANK - s.rankIndex; // rank index is 0-3
  }

  /**
   * chooses a random Dragon thief when a newly minted token is stolen
   * @param seed a random value to choose a Dragon from
   * @return the owner of the randomly selected Dragon thief
   */
  function randomDragonOwner(uint256 seed) external view override returns (address) {
    if (totalRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Dragons with the same rank score
    for (uint i = MAX_RANK - 3; i <= MAX_RANK; i++) {
      cumulative += flight[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Dragon with that rank score
      return flight[i][seed % flight[i].length].owner;
    }
    return address(0x0);
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send to Tower directly");
      return IERC721Receiver.onERC721Received.selector;
    }
  function _addUnShakedList(address account, uint256 tokenId) internal {
      unListShaked[account].push(tokenId);
   }

 function _delUnShakedList(address account, uint256 tokenId) internal {
    uint16  delIndex=0;
    bool exist=false;
    for( uint16 i=0;  i<unListShaked[account].length;i++)
      {
         if(unListShaked[account][i]==tokenId)
         {
           exist =true;
           delIndex=i;
           break;
         }
      }
      if(exist)
      {
        
         delete unListShaked[account][delIndex];
      }
   }

  function _addShakingList(address account, uint16 tokenId) internal {
     
      listShaked[account].push(tokenId);
      _delUnShakedList(account,tokenId);
     
  }
  
  function addUnShakingList(address account, uint16 tokenId) external override {
     
        _addUnShakedList(account,tokenId);
    
  }  
 
  function _delShakingList(address account, uint256  tokenId) internal{
    uint16  delIndex=0;
    bool exist=false;
    for( uint16 i=0;  i<listShaked[account].length;i++)
      {
         if(listShaked[account][i]==tokenId)
         {
           exist =true;
           delIndex=i;
           break;
         }
      }
      if(exist)
      {
         
         delete listShaked[account][delIndex];
        
      }

 }

  function getShakingList(address account) external view returns (uint256[] memory data) {
     data = listShaked[account];
      
  }


   function getUnShakingList(address account) external view returns (uint256[] memory data) {
     data = unListShaked[account];
    
  }
  
}