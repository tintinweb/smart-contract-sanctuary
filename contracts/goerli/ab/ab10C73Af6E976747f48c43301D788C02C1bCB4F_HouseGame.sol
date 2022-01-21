// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IHabitat.sol";
import "./IHouseTraits.sol";
import "./ICHEDDAR.sol";
import "./IHouse.sol";
import "./IRandomizer.sol";


contract HouseGame is Ownable, ReentrancyGuard, Pausable {

  event MintCommitted(address indexed owner, uint256 indexed amount);
  event MintRevealed(address indexed owner, uint256 indexed amount);

  struct MintCommit {
    bool stake;
    uint16 amount;
  }

  // address -> commit id -> commits
  mapping(address => mapping(uint256 => MintCommit)) private _mintCommits;
  // address -> commit num of commit need revealed for account
  mapping(address => uint256) private _pendingCommitId;
  // pending mint amount
  uint16 private pendingMintAmt;
  // flag for commits allowment
  bool public allowCommits = true;

  // address => can call addCommitRandom
  mapping(address => bool) private admins;

  // reference to the Habitat for choosing random Cat thieves
  IHabitat public habitat;
  // reference to $CHEDDAR for burning on mint
  ICHEDDAR public cheddarToken;
  // reference to House Traits
  IHouseTraits public houseTraits;
  // reference to House NFT collection
  IHouse public houseNFT;
  // reference to IRandomizer
  IRandomizer public randomizer;


  constructor() {
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(cheddarToken) != address(0) && address(houseTraits) != address(0)
        && address(habitat) != address(0) && address(houseNFT) != address(0)  && address(randomizer) != address(0)
        , "Contracts not set");
      _;
  }

  function setContracts(address _cheddar,address _houseTraits, address _habitat, address _house, address _randomizer) external onlyOwner {
    cheddarToken = ICHEDDAR(_cheddar);
    habitat = IHabitat(_habitat);
    houseNFT = IHouse(_house);
    houseTraits = IHouseTraits(_houseTraits);
    randomizer = IRandomizer(_randomizer);
  }

  /** EXTERNAL */

  function getPendingMint(address addr) external view returns (MintCommit memory) {
    require(_pendingCommitId[addr] != 0, "no pending commits");
    return _mintCommits[addr][_pendingCommitId[addr]];
  }

  function hasMintPending(address addr) external view returns (bool) {
    return _pendingCommitId[addr] != 0;
  }

  function canMint(address addr) external view returns (bool) {
    return _pendingCommitId[addr] != 0 && randomizer.getCommitRandom(_pendingCommitId[addr]) > 0;
  }

  function deleteCommit(address addr) external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
    uint256 commitIdCur = _pendingCommitId[_msgSender()];
    require(commitIdCur > 0, "No pending commit");
    delete _mintCommits[addr][commitIdCur];
    delete _pendingCommitId[addr];
  }

  function forceRevealCommit(address addr) external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
    reveal(addr);
  }

  /** Initiate the start of a mint. This action burns $CHEDDAR, as the intent of committing is that you cannot back out once you've started.
    * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
    * commit was added to. */
  function mintCommit(uint256 amount, bool stake) external whenNotPaused nonReentrant {
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA");
    require(_pendingCommitId[_msgSender()] == 0, "Already have pending mints");
    uint16 minted = houseNFT.minted();
    uint256 maxTokens = houseNFT.getMaxTokens();
    require(minted + pendingMintAmt + amount <= maxTokens, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");

    uint256 totalCheddarCost = 0;
    // Loop through the amount of 
    for (uint i = 1; i <= amount; i++) {
      totalCheddarCost += mintCost(minted + pendingMintAmt + i, maxTokens);
    }
    if (totalCheddarCost > 0) {
      cheddarToken.burn(_msgSender(), totalCheddarCost);
      cheddarToken.updateOriginAccess();
    }
    uint16 amt = uint16(amount);
    _mintCommits[_msgSender()][randomizer.commitId()] = MintCommit(stake, amt);
    _pendingCommitId[_msgSender()] = randomizer.commitId();
    pendingMintAmt += amt;
    emit MintCommitted(_msgSender(), amount);
  }

  /** Reveal the commits for this user. This will be when the user gets their NFT, and can only be done when the commit id that
    * the user is pending for has been assigned a random seed. */
  function mintReveal() external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA1");
    reveal(_msgSender());
  }

  function reveal(address addr) internal {
    uint256 commitIdCur = _pendingCommitId[addr];
    uint256 seed = randomizer.getCommitRandom(commitIdCur);
    require(commitIdCur > 0, "No pending commit");
    require(seed > 0, "random seed not set");
    uint16 minted = houseNFT.minted();
    MintCommit memory commit = _mintCommits[addr][commitIdCur];
    pendingMintAmt -= commit.amount;
    uint16[] memory tokenIds = new uint16[](commit.amount);
    uint16[] memory tokenIdsToStake = new uint16[](commit.amount);
    for (uint k = 0; k < commit.amount; k++) {
      minted++;
      // scramble the random so the steal / treasure mechanic are different per mint
      seed = uint256(keccak256(abi.encode(seed, addr)));
      address recipient = selectRecipient(seed);

      tokenIds[k] = minted;
      if (!commit.stake || recipient != addr) {
        houseNFT.mint(recipient, seed);
      } else {
        houseNFT.mint(address(habitat), seed);
        tokenIdsToStake[k] = minted;
      }
    }
    houseNFT.updateOriginAccess(tokenIds);
    if(commit.stake) {
      habitat.addManyHouseToStakingPool(addr, tokenIdsToStake);
    }
    delete _mintCommits[addr][commitIdCur];
    delete _pendingCommitId[addr];
    emit MintRevealed(addr, tokenIds.length);
  }

  /**
  * the first 25% are 80000 $CHEDDAR
  * the next 50% are 160000 $CHEDDAR
  * the next 25% are 320000 $WOOL
  * @param tokenId the ID to check the cost of to mint
  * @return the cost of the given token ID
  */
  function mintCost(uint256 tokenId, uint256 maxTokens) public pure returns (uint256) {
    if (tokenId <= maxTokens / 4) return 80000 ether;
    if (tokenId <= maxTokens * 3 / 4) return 160000 ether;
    return 320000 ether;
  }

  /** INTERNAL */

  /**
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Cat thief's owner)
   */
  function selectRecipient(uint256 seed) internal view returns (address) {
    if (((seed >> 245) % 8) != 0) return _msgSender(); // top 8 bits haven't been used
    address thief = habitat.randomCrazyCatOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0)) return _msgSender();
    return thief;
  }

  /** ADMIN */

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
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
}