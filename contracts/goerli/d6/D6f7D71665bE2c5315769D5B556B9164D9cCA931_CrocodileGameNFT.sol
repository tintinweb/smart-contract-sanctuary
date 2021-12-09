/*
 ██████╗██████╗  ██████╗  ██████╗ ██████╗ ██████╗ ██╗██╗     ███████╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔══██╗██╔═══██╗██╔════╝██╔═══██╗██╔══██╗██║██║     ██╔════╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
██║     ██████╔╝██║   ██║██║     ██║   ██║██║  ██║██║██║     █████╗      ██║  ███╗███████║██╔████╔██║█████╗  
██║     ██╔══██╗██║   ██║██║     ██║   ██║██║  ██║██║██║     ██╔══╝      ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
╚██████╗██║  ██║╚██████╔╝╚██████╗╚██████╔╝██████╔╝██║███████╗███████╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
 ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

import "./ICrocodileGamePiranha.sol";
import "./ICrocodileGameNFT.sol";
import "./ICrocodileGame.sol";

contract CrocodileGameNFT is ICrocodileGameNFT, ERC721Enumerable, Ownable, ReentrancyGuard {
  using Address for address;
  using Strings for uint256;

  string[] private preTraitsCroco;
  string[] private preTraitsBird;

  // Mumber of players minted
  uint16 public minted;

  // Maximum players in the game
  uint16 public constant MAX_TOKENS = 20000;

  // Semi-OnChain.
  uint256[MAX_TOKENS+1] public pseudoTokenId;
  mapping(uint256 => bool) public ExistpseudoTokenId; 
  mapping(uint256 => bool) public ExistRandId;

  // Number of GEN 0 tokens
  uint16 public constant MAX_GEN0_TOKENS = 10000;

  // External contracts
  ICrocodileGamePiranha private immutable crocodilePirinha;
  ICrocodileGame private immutable crocodileGame;

  // GEN 0 mint price
  uint256 public constant MINT_PRICE = 0.07 ether;

  // Mapping of token ID to player traits
  mapping(uint256 => Traits) public tokenTraits;

  // Events
  event Mint(string kind, address owner, uint16 tokenId);  
  
  // Initialize
  // TODO Change
  //constructor(address Piranha, address game, address traits) ERC721("CrocodileGame", "CROCO") {
    constructor(address Piranha, address game) ERC721("Test", "Test") {
    crocodilePirinha = ICrocodileGamePiranha(Piranha);
    crocodileGame = ICrocodileGame(game);
    }

  /**
   * Expose traits to trait contract.
   */
  function getTraits(uint16 tokenId) external view override returns (Traits memory) {
    return tokenTraits[pseudoTokenId[tokenId]];
  }

  /**
   * Expose maximum GEN 0 tokens.
   */
  function getMaxGEN0Players() external pure override returns (uint16) {
    return MAX_GEN0_TOKENS;
  }

  /**
   * Internal helper for minting.
   */
  function _mint(uint32 amount, bool stake, bool dilemma, uint256 originSeed) internal {
    Kind kind;
    uint16[] memory tokenIdsToStake = stake ? new uint16[](amount) : new uint16[](0);
    uint8[] memory dilemmas = stake? new uint8[](amount) : new uint8[](0);
    uint256 PiranhaCost;
    uint256 seed;
    
    // semi-onchain
    uint256 randid;
    
    for (uint32 i = 0; i < amount; i++) {
      minted++;
 
      // semi-onchain
      while (!ExistpseudoTokenId[minted]){
        // generate random number
        randid = uint256(keccak256(abi.encodePacked(block.timestamp))) % MAX_TOKENS;
        if (!ExistRandId[randid])
        {
          pseudoTokenId[minted] = randid;
          ExistpseudoTokenId[minted] = true;
        }
      }

      seed = _reseedWithIndex(originSeed, i);
      PiranhaCost += getMintPiranhaCost(minted);
      kind = _generateAndStoreTraits(minted, seed, 0).kind;
      address recipient = _selectRecipient(seed);
      if (!stake || recipient != msg.sender) {
        _safeMint(recipient, minted);
      } 
      else {
        // When Stake, dilemma==true => Cooperate, dilemma==true => Betraay
        tokenIdsToStake[i] = minted;
        if (dilemma == true){
          dilemmas[i]=1;
          }
        else {
          dilemmas[i]=2;
            }
        _safeMint(address(crocodileGame), minted);
      }
      emit Mint(kind == Kind.CROCODILE ? "CROCODILE" : "CROCODILEBIRD", recipient, minted);
    }
    if (PiranhaCost > 0) {
      crocodilePirinha.burn(msg.sender, PiranhaCost);
    }
    if (stake) {
      crocodileGame.stakeTokens(msg.sender, tokenIdsToStake, dilemmas);
    }
  }

  /**
   * Mint your players.
   * @param amount number of tokens to mint
   * @param stake mint directly to staking
   * @param seed random seed per mint
   * @param sig signature 
   */
  function mint(uint32 amount, bool stake, bool dilemma, uint256 seed, uint48 expiration, bytes calldata sig) external payable nonReentrant {
    require(tx.origin == msg.sender, "eos only");
    //require(amount > 0 && amount <= maxMint, "invalid mint amount");
    require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
    require(minted + amount <= MAX_TOKENS, "minted out");
    require(expiration > block.timestamp, "signature has expired");
    // TODO what is this?
    //require(crocodileGame.isValidSignature(msg.sender, false, expiration, seed, sig), "invalid signature");

    _mint(amount, stake, dilemma, seed);
  }

  function burn(uint16 tokenId) external nonReentrant{
    if (msg.sender != address(crocodileGame)) {
      require(_isApprovedOrOwner(msg.sender, tokenId), "transfer not owner nor approved");
    }
    _burn(tokenId);
  }

  /**
   * Calculate the crocodilePirinha cost:
   * - the first 50% are paid in ETH
   * - the next 25% are 40000 $PIRANHA
   * - the final 25% are 80000 $PIRANHA
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function getMintPiranhaCost(uint16 tokenId) public pure returns (uint256) {
    if (tokenId <= MAX_GEN0_TOKENS) return 0;
    if (tokenId <= MAX_TOKENS * 1 / 2) return 40000 ether;
    if (tokenId <= MAX_TOKENS * 3 / 4) return 80000 ether;
    return 80000 ether;
  }

  /**
   * Generate and store player traits. Recursively called to ensure uniqueness.
   * Give users 3 attempts, bit shifting the seed each time (uses 5 bytes of entropy before failing)
   * @param tokenId id of the token to generate traits
   * @param seed random 256 bit seed to derive traits
   * @return t player trait struct
   */
  function _generateAndStoreTraits(uint16 tokenId, uint256 seed, uint8 attempt) internal returns (Traits memory t) {
    require(attempt < 6, "unable to generate unique traits");
    t = _SetTraits(tokenId);
    
    // TODO uploadTriats function needed
    tokenTraits[pseudoTokenId[tokenId]] = t;
    return t;
  }

  /**
   * the first 50% (ETH purchases) go to the minter
   * the remaining 50% have a 10% chance to be given to a random staked crocodile / crocodile birds
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the fox thief's owner)
   */
  function _selectRecipient(uint256 seed) internal view returns (address) {
    if (minted <= MAX_GEN0_TOKENS || ((seed >> 245) % 10) != 0) {
      return msg.sender; // top 10 bits haven't been used
    }
    // 144 bits reserved for trait selection
    address thief = crocodileGame.randomKarmaOwner(seed >> 144);
    if (thief == address(0x0)) {
      return msg.sender;
    }
    return thief;
  }

  /**
   * Set traits by enrolling trait distribution.
   * return struct of randomly selected traits
   */
  function _SetTraits(uint16 tokenId) internal view returns (Traits memory t) {
  
    //read string 
    bytes memory numbers = bytes(preTraitsCroco[pseudoTokenId[tokenId]]); 
    for(uint256 i=0;i<7;i++){
      t.traits[i] = uint8(numbers[i])-uint8(0x30);
    }
    t.dilemma = 0;
    t.karmaP = 0;
    t.karmaM = 0;
  }

  function EnrollPseudoIDCrocoTraits(string[] memory traits) public onlyOwner {
    for (uint16 i = 0; i < traits.length; i++) {
        preTraitsCroco[i] = traits[i];
    }
  }

  function EnrollPseudoIDBirdTraits(string[] memory traits) public onlyOwner {
    for (uint16 i = 0; i < traits.length; i++) {
        preTraitsBird[i] = traits[i];
    }
  }

  /**
   * Reseeds entropy with mint amount offset.
   * @param seed random seed
   * @param offset additional entropy during mint
   * return rotated seed
   */
  function _reseedWithIndex(uint256 seed, uint32 offset) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed, offset)));
  }

  /**
   * Allow private sales.
   */
  function mintToAddress(uint256 amount, address recipient, uint256 originSeed) external onlyOwner {
    require(minted + amount <= MAX_TOKENS, "minted out");
    require(amount > 0, "invalid mint amount");
    
    Kind kind;
    uint256 seed;
    for (uint32 i = 0; i < amount; i++) {
      minted++;
      seed = _reseedWithIndex(originSeed, i);
      kind = _generateAndStoreTraits(minted, seed, 0).kind;
      _safeMint(recipient, minted);
      emit Mint(kind == Kind.CROCODILE ? "CROCODILE" : "CROCODILEBIRD", recipient, minted);
    }
  }

  /**
   * Allows owner to withdraw funds from minting.
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /**
   * Override transfer to avoid the approval step during staking.
   */
  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, ICrocodileGameNFT) {
    if (msg.sender != address(crocodileGame)) {
      require(_isApprovedOrOwner(msg.sender, tokenId), "transfer not owner nor approved");
    }
    _transfer(from, to, tokenId);
  }

  /**
   * Override NFT token uri. Calls into traits contract.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, pseudoTokenId[tokenId].toString())) : "";
  }

  /**
   * Ennumerate tokens by owner.
   */
  function tokensOf(address owner) external view returns (uint16[] memory) {
    uint32 tokenCount = uint32(balanceOf(owner));
    uint16[] memory tokensId = new uint16[](tokenCount);
    for (uint32 i = 0; i < tokenCount; i++){
      tokensId[i] = uint16(tokenOfOwnerByIndex(owner, i));
    }
    return tokensId;
  }

  /**
   * Overridden to resolve multiple inherited interfaces.
   */
  function ownerOf(uint256 tokenId) public view override(ERC721, ICrocodileGameNFT) returns (address) {
    return super.ownerOf(tokenId);
  }

  /**
   * Overridden to resolve multiple inherited interfaces.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721, ICrocodileGameNFT) {
    super.safeTransferFrom(from, to, tokenId, _data);
  }

  function setDilemma(uint16 tokenId, uint8 dilemma) public override(ICrocodileGameNFT){
    tokenTraits[pseudoTokenId[tokenId]].dilemma = dilemma;
  }

  function setKarmaP(uint16 tokenId, uint8 karmaP) public override(ICrocodileGameNFT){
    tokenTraits[pseudoTokenId[tokenId]].karmaP = karmaP;
  }
  function setKarmaM(uint16 tokenId, uint8 karmaM) public override(ICrocodileGameNFT){
    tokenTraits[pseudoTokenId[tokenId]].karmaM = karmaM;
  }
  function _baseURI() override internal pure returns (string memory) {
    //TODO change baseURI
    return "https://";
  }
}