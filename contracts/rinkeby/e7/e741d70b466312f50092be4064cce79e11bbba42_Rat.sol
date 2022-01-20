// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.10;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";
import "./IRat.sol";
import "./IRace.sol";
import "./ITraits.sol";
import "./CHEESE.sol";
import "./Counters.sol";


contract Rat is IRat, ERC721, Ownable, Pausable {

  using Counters for Counters.Counter;
  Counters.Counter private _nextTokenId;
  // Counters.Counter private _tokenSupply;
  // mint price 1-1,000
  uint256 public constant MINT_PRICE_FIRST = .05 ether;
  // mint price 1,001-3,000
  uint256 public constant MINT_PRICE_SECOND = .055 ether;
  // mint price 3,001-6,000
  uint256 public constant MINT_PRICE_THIRD = .06 ether;
  // mint price 6,001 - 10,000
  uint256 public constant MINT_PRICE_FOURTH = .069420 ether;
  // max number of tokens that can be minted - 50000 in production
  uint256 public immutable MAX_TOKENS;
  // used to allocate tokens that can be claimed for .05 ether
  uint256 public PAID_TOKENS_FIRST;
  // used to allocate tokens that can be claimed for .055 ether
  uint256 public PAID_TOKENS_SECOND;
  // used to allocate tokens that can be claimed for .06 ether
  uint256 public PAID_TOKENS_THIRD;
  // used to allocate tokens that can be claimed for .069420 ether and total that can be claimed with ETH - 20% of MAX_TOKENS
  uint256 public PAID_TOKENS_TOTAL;
  // number of tokens have been minted so far
  // uint16 public minted = 1;

  // mapping from tokenId to a struct containing the token's traits
  mapping(uint256 => SewerFat) public tokenTraits;
  // mapping from hashed(tokenTrait) to the tokenId it's associated with
  // used to ensure there are no duplicates
  mapping(uint256 => uint256) public existingCombinations;

  // list of probabilities for each trait type
  // 0 - 9 are associated with Sewer Rat, 10 - 18 are associated with Fat Rats
  uint8[][18] public rarities;
  // list of aliases for Walker's Alias algorithm
  // 0 - 9 are associated with Sewer Rat, 10 - 18 are associated with Fat Rats
  uint8[][18] public aliases;

  // reference to the Race for choosing random Fat Rat thieves
  IRace public Race;
  // reference to $CHEESE for burning on mint
  CHEESE public cheese;
  // reference to Traits
  ITraits public traits;

  // string public imageURL = "ratrace-game.herokuapp.com/0,5,41,2,1,1,1,1,8/";
  string public imageURL = "https://ratrace-game.herokuapp.com";


  event LogAddress(uint8 id, string a, address addressA, string b, address addressB);
  /** 
   * instantiates contract and rarity tables
   */
  constructor(address _cheese, address _traits, uint256 _maxTokens) ERC721("Rat Race", 'RRACE') { 
    _nextTokenId.increment();
    // minted++; // Initialise minted to 1 as 0 incurs a waste space penalty due to gas calculation of SSTORE operation approx. 20K gas to first minter.
    cheese = CHEESE(_cheese);
    traits = ITraits(_traits);
    MAX_TOKENS = _maxTokens;    
    PAID_TOKENS_FIRST = 1000;
    PAID_TOKENS_SECOND = 3000;
    PAID_TOKENS_THIRD = 6000;
    PAID_TOKENS_TOTAL = _maxTokens / 5;

    // I know this looks weird but it saves users gas by making lookup O(1)
    // A.J. Walker's Alias Algorithm
    // Sewer Rat
    // fur 
    rarities[0] = [100, 100, 100];
    aliases[0] = [0, 1, 2];
    // eyes
    rarities[1] = [100, 100, 100, 100, 100];
    aliases[1] = [0, 1, 2, 3, 4];
    // nose
    rarities[2] =  [100, 100, 100];
    aliases[2] = [0, 1, 2];
    // neck
    rarities[3] = [100, 100, 100, 100, 100];
    aliases[3] = [0, 1, 2, 3, 4];
    // mouth
    rarities[4] = [100, 100, 100, 100];
    aliases[4] = [0, 1, 2, 3];
    // head
    rarities[5] = [100, 100, 100, 100, 100];
    aliases[5] = [0, 1, 2, 3, 4];
    // hands
    rarities[6] = [255];
    aliases[6] = [0];
    // speedGreed
    rarities[7] = [100, 100, 100, 100, 100, 0, 0, 0, 0, 0];
    aliases[7] = [0, 1, 2, 3, 4, 0, 1, 2, 3, 4];
    // intellectStrength
    rarities[8] = [100, 100, 100, 100, 100, 0, 0, 0, 0, 0];
    aliases[8] = [0, 1, 2, 3, 4, 0, 1, 2, 3, 4];

    // Fat Rats
    // fur
    rarities[9] = [210, 90, 9, 9, 9, 150, 9, 255, 9];
    aliases[9] = [5, 0, 0, 5, 5, 7, 5, 7, 5];
    // head
    rarities[10] = [255];
    aliases[10] = [0];
    // ears
    rarities[11] = [255];
    aliases[11] = [0];
    // eyes
    rarities[12] = [135, 177, 219, 141, 183, 225, 147, 189, 231, 135, 135, 135, 135, 246, 150, 150, 156, 165, 171, 180, 186, 195, 201, 210, 243, 252, 255];
    aliases[12] = [1, 2, 3, 4, 5, 6, 7, 8, 13, 3, 6, 14, 15, 16, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 26, 26];
    // nose
    rarities[13] = [255];
    aliases[13] = [0];
    // mouth
    rarities[14] = [239, 244, 249, 234, 234, 234, 234, 234, 234, 234, 130, 255, 247];
    aliases[14] = [1, 2, 11, 0, 11, 11, 11, 11, 11, 11, 11, 11, 11];
    // neck
    rarities[15] = [75, 180, 165, 120, 60, 150, 105, 195, 45, 225, 75, 45, 195, 120, 255];
    aliases[15] = [1, 9, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 14, 12, 14];
    // feet 
    rarities[16] = [255];
    aliases[16] = [0];
    // alphaIndex
    rarities[17] = [8, 160, 73, 255]; 
    aliases[17] = [2, 3, 3, 3];


    // // Sewer Rat
    // // fur 
    // rarities[0] = [15, 50, 200, 250, 255];
    // aliases[0] = [4, 4, 4, 4, 4];
    // // head
    // rarities[1] = [190, 215, 240, 100, 110, 135, 160, 185, 80, 210, 235, 240, 80, 80, 100, 100, 100, 245, 250, 255];
    // aliases[1] = [1, 2, 4, 0, 5, 6, 7, 9, 0, 10, 11, 17, 0, 0, 0, 0, 4, 18, 19, 19];
    // // ears
    // rarities[2] =  [255, 30, 60, 60, 150, 156];
    // aliases[2] = [0, 0, 0, 0, 0, 0];
    // // eyes
    // rarities[3] = [221, 100, 181, 140, 224, 147, 84, 228, 140, 224, 250, 160, 241, 207, 173, 84, 254, 220, 196, 140, 168, 252, 140, 183, 236, 252, 224, 255];
    // aliases[3] = [1, 2, 5, 0, 1, 7, 1, 10, 5, 10, 11, 12, 13, 14, 16, 11, 17, 23, 13, 14, 17, 23, 23, 24, 27, 27, 27, 27];
    // // nose
    // rarities[4] = [175, 100, 40, 250, 115, 100, 185, 175, 180, 255];
    // aliases[4] = [3, 0, 4, 6, 6, 7, 8, 8, 9, 9];
    // // mouth
    // rarities[5] = [80, 225, 227, 228, 112, 240, 64, 160, 167, 217, 171, 64, 240, 126, 80, 255];
    // aliases[5] = [1, 2, 3, 8, 2, 8, 8, 9, 9, 10, 13, 10, 13, 15, 13, 15];
    // // neck
    // rarities[6] = [255];
    // aliases[6] = [0];
    // // feet
    // rarities[7] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255];
    // aliases[7] = [1, 7, 0, 0, 0, 0, 0, 10, 0, 0, 11, 18, 0, 0, 0, 1, 7, 11, 18];
    // // alphaIndex
    // rarities[8] = [255];
    // aliases[8] = [0];

    // // Fat Rats
    // // fur
    // rarities[9] = [210, 90, 9, 9, 9, 150, 9, 255, 9];
    // aliases[9] = [5, 0, 0, 5, 5, 7, 5, 7, 5];
    // // head
    // rarities[10] = [255];
    // aliases[10] = [0];
    // // ears
    // rarities[11] = [255];
    // aliases[11] = [0];
    // // eyes
    // rarities[12] = [135, 177, 219, 141, 183, 225, 147, 189, 231, 135, 135, 135, 135, 246, 150, 150, 156, 165, 171, 180, 186, 195, 201, 210, 243, 252, 255];
    // aliases[12] = [1, 2, 3, 4, 5, 6, 7, 8, 13, 3, 6, 14, 15, 16, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 26, 26];
    // // nose
    // rarities[13] = [255];
    // aliases[13] = [0];
    // // mouth
    // rarities[14] = [239, 244, 249, 234, 234, 234, 234, 234, 234, 234, 130, 255, 247];
    // aliases[14] = [1, 2, 11, 0, 11, 11, 11, 11, 11, 11, 11, 11, 11];
    // // neck
    // rarities[15] = [75, 180, 165, 120, 60, 150, 105, 195, 45, 225, 75, 45, 195, 120, 255];
    // aliases[15] = [1, 9, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 14, 12, 14];
    // // feet 
    // rarities[16] = [255];
    // aliases[16] = [0];
    // // alphaIndex
    // rarities[17] = [8, 160, 73, 255]; 
    // aliases[17] = [2, 3, 3, 3];
  }

  /** EXTERNAL */

  /** 
   * mint a token - 90% Sewer Rat, 10% Fat Rats
   * The first 20% are free to claim, the remaining cost $CHEESE
   */
  function mint(uint256 amount, bool stake) external payable whenNotPaused {
    emit LogAddress(1, "tx.origin: ", tx.origin, "_msgSender(): ", _msgSender());
    // uint16 tokenId = uint16(_nextTokenId.current());
    require(tx.origin == _msgSender(), "Only EOA");
    require(_nextTokenId.current() + amount <= MAX_TOKENS, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");

    if (_nextTokenId.current() < PAID_TOKENS_FIRST) { // will allow tokens 1 - 1,000 to be minted
      require(_nextTokenId.current() + amount <= PAID_TOKENS_FIRST, "Not enough mints left for 0.05ETH");
      require(amount * MINT_PRICE_FIRST == msg.value, "Invalid payment amount1");
    }
    else if (_nextTokenId.current() < PAID_TOKENS_SECOND) { // will allow tokens 1,001 - 3,000 to be minted
      require(_nextTokenId.current() + amount <= PAID_TOKENS_SECOND, "Not enough mints left for 0.055ETH");
      require(amount * MINT_PRICE_SECOND == msg.value, "Invalid payment amount2");
    }
    else if (_nextTokenId.current() < PAID_TOKENS_THIRD) { // will allow tokens 3,001 - 6,000 to be minted
      require(_nextTokenId.current() + amount <= PAID_TOKENS_THIRD, "Not enough mints left for 0.06ETH");
      require(amount * MINT_PRICE_THIRD == msg.value, "Invalid payment amount3");
    }
    else if (_nextTokenId.current() < PAID_TOKENS_TOTAL) { // will allow tokens 6,001 - 10,000 to be minted
      require(_nextTokenId.current() + amount <= PAID_TOKENS_TOTAL, "Not enough mints left for 0.069420ETH");
      require(amount * MINT_PRICE_FOURTH == msg.value, "Invalid payment amount4");
    }
    else {
      require(msg.value == 0);
    }

    // if (minted < PAID_TOKENS) {
    //   require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
    //   require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
    // } 
    

    uint256 totalCHEESECost = 0;
    uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);
    uint256 seed;
    for (uint i = 0; i < amount; i++) {
      seed = random(_nextTokenId.current());
      generate(_nextTokenId.current(), seed);
      address recipient = selectRecipient(seed);
      
    
    emit LogAddress(2, "trecipient: ", recipient, "_msgSender(): ", _msgSender());
    emit LogAddress(uint8(_nextTokenId.current()), "mint", _msgSender(), "to", _msgSender());

      if (!stake || recipient != _msgSender()) {
        _safeMint(recipient, _nextTokenId.current());
        emit LogAddress(3, "recipient: ", recipient, "_msgSender(): ", _msgSender());
      } else {
        _safeMint(address(Race), _nextTokenId.current());      // PUT THIS BACK IN -
        // _safeMint(recipient, minted);        

        emit LogAddress(4, "recipient: ", recipient, "_msgSender(): ", _msgSender());
        tokenIds[i] = uint16(_nextTokenId.current());
      }
      totalCHEESECost += mintCost(_nextTokenId.current());
    }    
    _nextTokenId.increment();
    
    if (totalCHEESECost > 0) cheese.burn(_msgSender(), totalCHEESECost);
    if (stake) Race.addManyToRace(_msgSender(), tokenIds);
  }

  /** 
   * the first 20% are paid in ETH
   * the next 20% are 20000 $CHEESE
   * the next 40% are 40000 $CHEESE
   * the final 20% are 80000 $CHEESE
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCost(uint256 tokenId) public view returns (uint256) {
    if (tokenId <= PAID_TOKENS_TOTAL) return 0;
    if (tokenId <= MAX_TOKENS * 2 / 5) return 20000 ether;
    if (tokenId <= MAX_TOKENS * 3 / 5) return 40000 ether;
    if (tokenId <= MAX_TOKENS * 4 / 5) return 80000 ether;
    return 160000 ether;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    // Hardcode the Race's approval so that users don't have to waste gas approving
    if (_msgSender() != address(Race))
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
  }

  /** INTERNAL */

  /**
   * generates traits for a specific token, checking to make sure it's unique
   * @param tokenId the id of the token to generate traits for
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t - a struct of traits for the given token ID
   */
  function generate(uint256 tokenId, uint256 seed) internal returns (SewerFat memory t) {    
    t = selectTraits(seed);
    if (existingCombinations[structToHash(t)] == 0) {
      tokenTraits[tokenId] = t;
      existingCombinations[structToHash(t)] = tokenId;
      return t;
    }
    return generate(tokenId, random(seed));
  }

  /**
   * updates traits of tokenId
   * @param tokenId the id of the token to generate traits for
   * @param s the SewerFat struct of tokeId
   */
  function updateTraits(uint256 tokenId, SewerFat memory s) external onlyOwner {    
      tokenTraits[tokenId] = s;
      existingCombinations[structToHash(s)] = tokenId;
  }

  /**
   * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
   * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
   * probability & alias tables are generated off-chain beforehand
   * @param seed portion of the 256 bit seed to remove trait correlation
   * @param traitType the trait type to select a trait for 
   * @return the ID of the randomly selected trait
   */
  function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
    uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
    // uint16 = 0-65535 or 0x5678
    // uint8 = 0-255 or 0x78
    // (4 = uint8(rarities[traitType].length) = no of variations of traits, 4 eyes etc) 
    // trait = 255 % 4 = 2 (% = modulus, 2 is left over after 255/4 = 63.75)
    if (seed >> 8 < rarities[traitType][trait]) return trait;
    //if seed 60000 / 2**8 = 234.375 < 
    return aliases[traitType][trait];
  }

  /**
   * the first 20% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked Fat Rat
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Fat Rat thief's owner)
   */
  function selectRecipient(uint256 seed) internal view returns (address) {
    if (_nextTokenId.current() <= PAID_TOKENS_TOTAL || ((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used
    address thief = Race.randomFatRatOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0)) return _msgSender();
    return thief;
  }

  /**
   * selects the species and all of its traits based on the seed value
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t -  a struct of randomly selected traits
   */
  function selectTraits(uint256 seed) internal view returns (SewerFat memory t) {    
    t.isSewerRat = (seed & 0xFFFF) % 10 != 0;
    uint8 shift = t.isSewerRat ? 0 : 9;
    seed >>= 16;
    t.fur = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
    seed >>= 16;
    t.eyes = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
    seed >>= 16;
    t.nose = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
    seed >>= 16;
    t.neck = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
    seed >>= 16;
    t.mouth = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
    seed >>= 16;
    t.head = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
    seed >>= 16;
    t.hands = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
    seed >>= 16;
    t.speedGreed = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
    seed >>= 16;
    t.intellectStrength = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
  }

  /**
   * converts a struct to a 256 bit hash to check for uniqueness
   * @param s the struct to pack into a hash
   * @return the 256 bit hash of the struct
   */
  function structToHash(SewerFat memory s) internal pure returns (uint256) {
    return uint256(bytes32(
      abi.encodePacked(
        s.isSewerRat,
        s.fur,
        s.eyes,
        s.nose,
        s.neck,
        s.mouth,
        s.head,
        s.hands,
        s.speedGreed,
        s.intellectStrength
        // s.ears,
        // s.feet,
      )
    ));
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

  /** READ */

  function getTokenTraits(uint256 tokenId) external view override returns (SewerFat memory) {
    return tokenTraits[tokenId];
  }

  function getPaidTokens() external view override returns (uint256) {
    return PAID_TOKENS_TOTAL;
  }

  function getImageURL() external view override returns (string memory) {
    return imageURL;
  }

  /** ADMIN */

  /**
   * called after deployment so that the contract can get random Fat Rat thieves
   * @param _Race the address of the Race
   */
  function setRace(address _Race) external onlyOwner {
    Race = IRace(_Race);
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /**
   * updates the number of tokens for sale
   */
  function setPaidTokens(uint256 _paidTokens) external onlyOwner {
    PAID_TOKENS_TOTAL = _paidTokens;
  }

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * updates URL of imageURI  
   */
  function updateImageURL(string calldata _imageURL) external onlyOwner {    
      imageURL = _imageURL;
  }

  /** RENDER */

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return traits.tokenURI(tokenId);
  }
}