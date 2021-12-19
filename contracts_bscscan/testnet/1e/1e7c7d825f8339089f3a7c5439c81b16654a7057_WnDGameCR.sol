// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IWnDGame.sol";
import "./ITower.sol";
import "./ITraits.sol";
import "./IGP.sol";
import "./IWnD.sol";
import "./ISacrificialAlter.sol";
import "./IRandomizer.sol";


contract WnDGameCR is IWnDGame, Ownable, ReentrancyGuard, Pausable {

  event MintCommitted(address indexed owner, uint256 indexed amount);
  event MintRevealed(address indexed owner, uint256 indexed amount);

  struct MintCommit {
    bool stake;
    uint16 amount;
  }

  uint256 public treasureChestTypeId;
  // max $GP cost 
  uint256 private maxGpCost = 72000 ether;

  // address -> commit # -> commits
  mapping(address => mapping(uint16 => MintCommit)) private _mintCommits;
  // address -> commit num of commit need revealed for account
  // mapping(address => uint16) private _pendingCommitId;
  // commit # -> offchain random
  // mapping(uint16 => uint256) private _commitRandoms;
  uint16 private _commitId = 1;
  uint16 private pendingMintAmt;
  bool public allowCommits = true;

  // address => can call addCommitRandom
  mapping(address => bool) private admins;

  IRandomizer public randomer;
  // reference to the Tower for choosing random Dragon thieves
  ITower public tower;
  // reference to $GP for burning on mint
  IGP public gpToken;
  // reference to Traits
  ITraits public traits;
  // reference to NFT collection
  IWnD public wndNFT;
  // reference to alter collection
  ISacrificialAlter public alter;

  constructor() {
    // _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(gpToken) != address(0) && address(traits) != address(0) 
        && address(wndNFT) != address(0) && address(tower) != address(0) && address(alter) != address(0)
        , "Contracts not set");
      _;
  }

  function setContracts(address _gpCoin, address _traits, address _wnd, address _tower, address _alter) external onlyOwner {
    gpToken = IGP(_gpCoin);
    traits = ITraits(_traits);
    wndNFT = IWnD(_wnd);
    tower = ITower(_tower);
    alter = ISacrificialAlter(_alter);
  }

  /** EXTERNAL */

  // function getPendingMint(address addr) external view returns (MintCommit memory) {
  //   require(_pendingCommitId[addr] != 0, "no pending commits");
  //   return _mintCommits[addr][_pendingCommitId[addr]];
  // }

  // function hasMintPending(address addr) external view returns (bool) {
  //   return _pendingCommitId[addr] != 0;
  // }

  // function canMint(address addr) external view returns (bool) {
  //   return _pendingCommitId[addr] != 0 && _commitRandoms[_pendingCommitId[addr]] > 0;
  // }

  // Seed the current commit id so that pending commits can be revealed
  // function addCommitRandom(uint256 seed) external {
  //   require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
  //   _commitRandoms[_commitId] = seed;
  //   _commitId += 1;
  // }

  // function deleteCommit(address addr) external {
  //   require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
  //   uint16 commitIdCur = _pendingCommitId[_msgSender()];
  //   require(commitIdCur > 0, "No pending commit");
  //   delete _mintCommits[addr][commitIdCur];
  //   delete _pendingCommitId[addr];
  // }

  // function forceRevealCommit(address addr) external {
  //   require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
  //   reveal(addr);
  // }

  /** Initiate the start of a mint. This action burns $GP, as the intent of committing is that you cannot back out once you've started.
    * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
    * commit was added to. */
  function mintCommit(uint256 amount, bool stake) external whenNotPaused nonReentrant {
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA mint");
    // require(_pendingCommitId[_msgSender()] == 0, "Already have pending mints");
    uint16 minted = wndNFT.minted();
    uint256 maxTokens = wndNFT.getMaxTokens();
    require(minted + pendingMintAmt + amount <= maxTokens, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");

    uint256 totalGpCost = 0;
    // Loop through the amount of 
    for (uint i = 1; i <= amount; i++) {
      totalGpCost += mintCost(minted + pendingMintAmt + i, maxTokens);
    }
    if (totalGpCost > 0) {
      gpToken.burn(_msgSender(), totalGpCost);
      gpToken.updateOriginAccess();
    }
    // uint16 amt = uint16(amount);
    // _mintCommits[_msgSender()][_commitId] = MintCommit(stake, amt);
    // _pendingCommitId[_msgSender()] = _commitId;
    // pendingMintAmt += amt;
    reveal(_msgSender(),amount,stake);
    emit MintCommitted(_msgSender(), amount);
  }

  /** Reveal the commits for this user. This will be when the user gets their NFT, and can only be done when the commit id that
    * the user is pending for has been assigned a random seed. */
  // function mintReveal() external whenNotPaused nonReentrant {
  //   require(tx.origin == _msgSender(), "Only EOA1");
  //   reveal(_msgSender());
  // }



  function reveal(address addr,uint256 amount,bool stake) internal {
    // uint16 commitIdCur = _pendingCommitId[addr];
    // require(commitIdCur > 0, "No pending commit");
    // require(_commitRandoms[commitIdCur] > 0, "random seed not set");
    uint16 minted = wndNFT.minted();
    // MintCommit memory commit = _mintCommits[addr][commitIdCur];
    // pendingMintAmt -= commit.amount;
    uint16[] memory tokenIds = new uint16[](amount);
    uint16[] memory tokenIdsToStake = new uint16[](amount);
    uint256 seed = 0;
    for (uint k = 0; k < amount; k++) {
      minted++;
      // scramble the random so the steal / treasure mechanic are different per mint
      randomer.addNonce(minted);
      seed = randomer.random(minted);
      // seed = uint256(keccak256(abi.encode(seed, addr)));
      address recipient = selectRecipient(seed);
      if(recipient != addr && alter.balanceOf(addr, treasureChestTypeId) > 0) {
        // If the mint is going to be stolen, there's a 50% chance 
        //  a dragon will prefer a treasure chest over it
        if(seed & 1 == 1) {
          alter.safeTransferFrom(addr, recipient, treasureChestTypeId, 1, "");
          recipient = addr;
        }
      }
      tokenIds[k] = minted;
      if (stake || recipient != addr) {
        wndNFT.mint(recipient, seed);
      } else {
        wndNFT.mint(address(tower), seed);
        tokenIdsToStake[k] = minted;
      }
    }
    wndNFT.updateOriginAccess(tokenIds);
    if(stake) {
      tower.addManyToTowerAndFlight(addr, tokenIdsToStake);
    }
    
    emit MintCommitted(addr, tokenIds.length);
  }

  /** 
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCost(uint256 tokenId, uint256 maxTokens) public view returns (uint256) {
    if (tokenId <= maxTokens * 8 / 20) return 24000 ether;
    if (tokenId <= maxTokens * 11 / 20) return 36000 ether;
    if (tokenId <= maxTokens * 14 / 20) return 48000 ether;
    if (tokenId <= maxTokens * 17 / 20) return 60000 ether; 
    // if (tokenId > maxTokens * 17 / 20)
    return maxGpCost;
  }

  function payTribute(uint256 gpAmt) external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA");
    uint16 minted = wndNFT.minted();
    uint256 maxTokens = wndNFT.getMaxTokens();
    uint256 gpMintCost = mintCost(minted, maxTokens);
    require(gpMintCost > 0, "Sacrificial alter currently closed");
    require(gpAmt >= gpMintCost, "Not enough gp given");
    gpToken.burn(_msgSender(), gpAmt);
    if(gpAmt < gpMintCost * 2) {
      alter.mint(1, 1, _msgSender());
    }
    else {
      alter.mint(2, 1, _msgSender());
    }
  }

  function makeTreasureChests(uint16 qty) external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");
    require(treasureChestTypeId > 0, "DEVS DO SOMETHING");
    // $GP exchange amount handled within alter contract
    // Will fail if sender doesn't have enough $GP
    // Transfer does not need approved,
    //  as there is established trust between this contract and the alter contract 
    alter.mint(treasureChestTypeId, qty, _msgSender());
  }

  function sellTreasureChests(uint16 qty) external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");
    require(treasureChestTypeId > 0, "DEVS DO SOMETHING");
    // $GP exchange amount handled within alter contract
    alter.burn(treasureChestTypeId, qty, _msgSender());
  }

  function sacrifice(uint256 tokenId, uint256 gpAmt) external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA");
    uint64 lastTokenWrite = wndNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    IWnD.WizardDragon memory nft = wndNFT.getTokenTraits(tokenId);
    uint16 minted = wndNFT.minted();
    uint256 maxTokens = wndNFT.getMaxTokens();
    uint256 gpMintCost = mintCost(minted, maxTokens);
    require(gpMintCost > 0, "Sacrificial alter currently closed");
    if(nft.isWizard) {
      // Wizard sacrifice requires 3x $GP curve
      require(gpAmt >= gpMintCost * 3, "not enough gp provided");
      gpToken.burn(_msgSender(), gpAmt);
      // This will check if origin is the owner of the token
      wndNFT.burn(tokenId);
      alter.mint(3, 1, _msgSender());
    }
    else {
      // Dragon sacrifice requires 4x $GP curve
      require(gpAmt >= gpMintCost * 4, "not enough gp provided");
      gpToken.burn(_msgSender(), gpAmt);
      // This will check if origin is the owner of the token
      wndNFT.burn(tokenId);
      alter.mint(4, 1, _msgSender());
    }
  }

  /** INTERNAL */

  /**
   * the first 25% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked dragon
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Dragon thief's owner)
   */
  function selectRecipient(uint256 seed) internal view returns (address) {
    if (((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used
    address thief = tower.randomDragonOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0)) return _msgSender();
    return thief;
  }

  /** ADMIN */

 function setRandomAddress(address _address) external onlyOwner {
      randomer = IRandomizer(_address);
  }

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setMaxGpCost(uint256 _amount) external requireContractsSet onlyOwner {
    maxGpCost = _amount;
  } 

  function setTreasureChestId(uint256 typeId) external onlyOwner {
    treasureChestTypeId = typeId;
  }

  function setAllowCommits(bool allowed) external onlyOwner {
    allowCommits = allowed;
  }

  /** Allow the contract owner to set the pending mint amount.
    * This allows any long-standing pending commits to be overwritten, say for instance if the max supply has been 
    *  reached but there are many stale pending commits, it could be used to free up those spaces if needed/desired by the community.
    * This function should not be called lightly, this will have negative consequences on the game. */
  function setPendingMintAmt(uint256 pendingAmt) external onlyOwner {
    pendingMintAmt = uint16(pendingAmt);
  }

  /**
  * enables an address to mint / burn
  * @param addr the address to enable
  */
  function addAdmin(address addr) external onlyOwner {
      admins[addr] = true;
  }

  /**
  * disables an address from minting / burning
  * @param addr the address to disbale
  */
  function removeAdmin(address addr) external onlyOwner {
      admins[addr] = false;
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}