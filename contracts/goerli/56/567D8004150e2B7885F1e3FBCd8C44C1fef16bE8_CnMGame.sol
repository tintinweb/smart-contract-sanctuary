// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./IHabitat.sol";
import "./ITraits.sol";
import "./ICHEDDAR.sol";
import "./ICnM.sol";
import "./IRandomizer.sol";

contract CnMGame is Ownable, ReentrancyGuard, Pausable {
  event MintCommitted(address indexed owner, uint256 indexed amount);
  event MintRevealed(address indexed owner, uint256 indexed amount);
  event Roll(address indexed owner, uint256 tokenId, uint8 roll);

  struct MintCommit {
    bool stake;
    uint16 amount;
  }
  struct RollCommit {
    uint256 tokenId;
  }

  // on-sale price (genesis NFTS)
  uint256 public MINT_PRICE = 0.001 ether;
  // rolling price
  uint256 public ROLL_COST = 3000 ether;
  bool public isWhitelistActive;
  bool public isPublicActive;
  uint256 public maxPerWallet = 3;
  mapping(address => uint256) perWallet;

  bytes32 public root;
  // address -> mint commit id -> commits
  mapping(address => mapping(uint256 => MintCommit)) private _mintCommits;
  // address -> roll commit id -> roll commits
  // mapping(address => mapping(uint16 => MintCommit)) private _rollCommits;
  // address -> Id of commit need revealed for account
  mapping(address => uint256) private _pendingCommitId;
  // address -> Id of rolling commit need revealed for account
  // mapping(address => uint16) private _pendingRollCommitId;

  // uint16 private _rollCommitId = 1;
  // pending mint amount
  uint16 private pendingMintAmt;

  // pending roll amount
  // uint16 private pendingRollAmt;

  // flag for commits allowment
  bool public allowCommits = true;

  // address => can call addCommitRandom
  mapping(address => bool) private admins;

  // reference to the Habitat for choosing random Cat thieves
  IHabitat public habitat;
  // reference to $CHEDDAR for burning on mint
  ICHEDDAR public cheddarToken;
  // reference to Traits
  ITraits public traits;
  // reference to CnM NFT collection
  ICnM public cnmNFT;
  // reference to IRandomizer
  IRandomizer public randomizer;
  address[] _addresses = [
      0xF456D310b9B40C93d9686199b3A3775d8dd52fd1,
      0x291d931172783AB4B059c9E25F5C2af1D541373f,
      0x4DAfcc597cbEf07A3E089200f054c674d549fc8D,
      0xe3b661D0Fd1FedF2782997E55C417BAA7c49B3b9,
      0xAB4438B61a920B9044A3F182c67FF18138E6EE99,
      0x510245323739DB800B6520463782fBc890cAf023
  ];
  uint256[] _shares = [40,192, 192, 192, 192, 192];

  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(cheddarToken) != address(0) && address(traits) != address(0)
        && address(cnmNFT) != address(0) && address(habitat) != address(0) && address(randomizer) != address(0)
        , "Contracts not set");
      _;
  }

  function setContracts(address _cheddar, address _traits, address _cnm, address _habitat, address _randomizer) external onlyOwner {
    cheddarToken = ICHEDDAR(_cheddar);
    traits = ITraits(_traits);
    cnmNFT = ICnM(_cnm);
    habitat = IHabitat(_habitat);
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
    uint256 seed = randomizer.getCommitRandom(_pendingCommitId[addr]);
    return _pendingCommitId[addr] != 0 && seed > 0;
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

  function whitelistMint(uint256 amount, bool stake, uint256 tokenId, bytes32[] calldata proof) external payable nonReentrant {
    require(isWhitelistActive, "not active");
    require(_verify(_leaf(_msgSender(), tokenId), proof), "invalid");
    require(perWallet[msg.sender] + amount <= maxPerWallet, "cannot exceed max");
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA");
    require(_pendingCommitId[_msgSender()] == 0, "Already have pending mints");
    uint16 minted = cnmNFT.minted();
    uint256 maxTokens = cnmNFT.getMaxTokens();
    uint256 paidTokens = cnmNFT.getPaidTokens();
    require(amount > 0 && minted + pendingMintAmt + amount <= maxTokens, "All tokens minted");
    require(minted + amount <= paidTokens, "All tokens on-sale already sold");
    require(amount * MINT_PRICE == msg.value, "Invalid payment amount");

    uint16 amt = uint16(amount);
    _mintCommits[_msgSender()][randomizer.commitId()] = MintCommit(stake, amt);
    _pendingCommitId[_msgSender()] = randomizer.commitId();
    pendingMintAmt += amt;
    perWallet[msg.sender] += amount;
    emit MintCommitted(_msgSender(), amount);
  }

  /** Initiate the start of a mint. This action burns $CHEDDAR, as the intent of committing is that you cannot back out once you've started.
    * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
    * commit was added to. */
  function mintCommit(uint256 amount, bool stake) external payable nonReentrant whenNotPaused {
    require(isPublicActive, "Not live");
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA");
    require(_pendingCommitId[_msgSender()] == 0, "Already have pending mints");
    uint16 minted = cnmNFT.minted();
    uint256 maxTokens = cnmNFT.getMaxTokens();
    uint256 paidTokens = cnmNFT.getPaidTokens();
    require(minted + pendingMintAmt + amount <= maxTokens, "All tokens minted");
    require(amount > 0 && amount <= 4, "Invalid mint amount");
    if (minted < paidTokens) {
        require(
            minted + amount <= paidTokens,
            "All tokens on-sale already sold"
        );
        require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
    } else {
        require(msg.value == 0);
    }

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
    uint16 minted = cnmNFT.minted();
    MintCommit memory commit = _mintCommits[addr][commitIdCur];
    pendingMintAmt -= commit.amount;
    uint16[] memory tokenIds = new uint16[](commit.amount);
    uint16[] memory tokenIdsToStake = new uint16[](commit.amount);
    for (uint k = 0; k < commit.amount; k++) {
      minted++;
      // scramble the random so the steal are different per mint
      seed = uint256(keccak256(abi.encode(seed, addr)));
      address recipient = selectRecipient(seed);

      tokenIds[k] = minted;
      if (!commit.stake || recipient != addr) {
        cnmNFT.mint(recipient, seed);
      } else {
        cnmNFT.mint(address(habitat), seed);
        tokenIdsToStake[k] = minted;
      }
    }
    cnmNFT.updateOriginAccess(tokenIds);
    if(commit.stake) {
      habitat.addManyToStakingPool(addr, tokenIdsToStake);
    }
    delete _mintCommits[addr][commitIdCur];
    delete _pendingCommitId[addr];
    emit MintRevealed(addr, tokenIds.length);
  }

  /*
  * implement mouse roll
  */
  function rollForage(uint256 tokenId) external whenNotPaused nonReentrant returns(uint8) {
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA");
    require(habitat.isOwner(tokenId, msg.sender), "Not owner");
    require(!cnmNFT.isCat(tokenId), "affected only for Mouse NFTs");

    cheddarToken.burn(_msgSender(), ROLL_COST);
    cheddarToken.updateOriginAccess();
    uint256 seed = randomizer.sRandom(tokenId);
    uint8 roll;

    /*
    * Odds to Roll:
    * Trashcan: Default
    * Cupboard: 70%
    * Pantry: 20%
    * Vault: 10%
    */
    if ((seed & 0xFFFF) % 100 < 10) {
      roll = 3;
    } else if((seed & 0xFFFF) % 100 < 30) {
      roll = 2;
    } else {
      roll = 1;
    }
    uint8 previous = cnmNFT.getTokenRoll(tokenId);
    if(roll > previous) {
      cnmNFT.setRoll(tokenId, roll);
    }

    emit Roll(msg.sender, tokenId, roll);
    return roll;
  }

  /**
  * the first 20% are paid in ETHER
  * the next 20% are 20000 $CHEDDAR
  * the next 40% are 40000 $CHEDDAR
  * the final 20% are 80000 $CHEDDAR
  * @param tokenId the ID to check the cost of to mint
  * @return the cost of the given token ID
  */
  function mintCost(uint256 tokenId, uint256 maxTokens) public pure returns (uint256) {
    if (tokenId <= maxTokens / 5) return 0;
    if (tokenId <= maxTokens * 2 / 5) return 20000 ether;
    if (tokenId <= maxTokens * 4 / 5) return 40000 ether;
    return 80000 ether;
  }

  /** INTERNAL */

  /**
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Cat thief's owner)
   */
  function selectRecipient(uint256 seed) internal view returns (address) {
    // During initial 10k mint, stealing will not happen
    uint16 mintedNum = cnmNFT.minted();
    uint256 paidToken = cnmNFT.getPaidTokens();
    if (mintedNum < paidToken) {
      return _msgSender();
    }

    // 10% chance of stealing
    if (((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used

    // Select stealer cat
    address thief = habitat.randomCatOwner(seed >> 144); // 144 bits reserved for trait selection
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

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function toggleWhitelistActive() external onlyOwner {
    isWhitelistActive = !isWhitelistActive;
  }

  function togglePublicSale() external onlyOwner {
    isPublicActive = !isPublicActive;
  }

  function setMaxPerWallet(uint256 _amount) external onlyOwner {
    maxPerWallet = _amount;
  }

  function setRoot(bytes32 _root) external onlyOwner {
    root = _root;
  }

  function setPrice(uint256 _price) external onlyOwner {
    MINT_PRICE = _price;
  }

  function setRollPrice(uint256 _price) external onlyOwner {
    ROLL_COST = _price * 1 ether;
  }

  function _leaf(address account, uint256 tokenId)
  internal pure returns (bytes32)
  {
      return keccak256(abi.encodePacked(tokenId, account));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof)
  internal view returns (bool)
  {
      return MerkleProof.verify(proof, root, leaf);
  }
}