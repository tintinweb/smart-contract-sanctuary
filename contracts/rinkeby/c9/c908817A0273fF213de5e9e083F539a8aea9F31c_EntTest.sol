// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Itest.sol";
import "./ITraits.sol";


contract EntTest is Itest, ERC721Enumerable, Ownable, Pausable {

  uint256 public constant MAX_MINT = 20;
  uint256 public constant MAX_PRIVATE_SUPPLY = 4000;
  uint256 public constant MAX_PUBLIC_SUPPLY = 6000;
  uint256 public constant MAX_SUPPLY = MAX_PRIVATE_SUPPLY + MAX_PUBLIC_SUPPLY;
  uint256 public totalPrivateSupply;
  uint256 public totalPublicSupply;
  uint16 public minted;
  uint256 private price;
  uint256 private burnNTTZ;
  string private _baseContractURI;
  uint96 public constant royaltyFeeBps = 1000; //10%
  
  mapping(uint256 => bool) private _tokenClaimed;
    
  struct Claims {
    uint256 tokenId;
    bool claimed;
  }
  mapping(uint256 => Claims) public claimlist;
  
  mapping (uint256 => uint256) public tokenIndex;
  mapping (uint256 => uint256) public maxIndex;
  
  MintPassContract public mintPassContract;
  NTTZToken public nttzToken;

  // mapping from tokenId to a struct containing the token's traits
  mapping(uint256 => mapping(uint256 => SheepWolf)) public tokenTraits;
  // mapping from hashed(tokenTrait) to the tokenId it's associated with
  // used to ensure there are no duplicates
  mapping(uint256 => uint256) public existingCombinations;

  // list of probabilities for each trait type
  // 0 - 9 are associated with Sheep, 10 - 18 are associated with Wolves
  uint8[][18] public rarities;
  // list of aliases for Walker's Alias algorithm
  // 0 - 9 are associated with Sheep, 10 - 18 are associated with Wolves
  uint8[][18] public aliases;

  // reference to Traits
  ITraits public traits;

  /** 
   * instantiates contract and rarity tables
   */
  constructor(
    string memory baseContractURI,
    uint256 _price,
    uint256 _burnNTTZ,
    address _mintPassToken,
    address _nttzToken
  ) ERC721("EntTest", "ET") {
    _baseContractURI = baseContractURI;
    price = _price;
    burnNTTZ = _burnNTTZ;
    mintPassContract = MintPassContract(_mintPassToken);
    nttzToken = NTTZToken(_nttzToken);
    

    // I know this looks weird but it saves users gas by making lookup O(1)
    // A.J. Walker's Alias Algorithm
    // sheep
    // fur
    rarities[0] = [15, 50, 200, 250, 255];
    aliases[0] = [4, 4, 4, 4, 4];
    // head
    rarities[1] = [190, 215, 240, 100, 110, 135, 160, 185, 80, 210, 235, 240, 80, 80, 100, 100, 100, 245, 250, 255];
    aliases[1] = [1, 2, 4, 0, 5, 6, 7, 9, 0, 10, 11, 17, 0, 0, 0, 0, 4, 18, 19, 19];
    // ears
    rarities[2] =  [255, 30, 60, 60, 150, 156];
    aliases[2] = [0, 0, 0, 0, 0, 0];
    // eyes
    rarities[3] = [221, 100, 181, 140, 224, 147, 84, 228, 140, 224, 250, 160, 241, 207, 173, 84, 254, 220, 196, 140, 168, 252, 140, 183, 236, 252, 224, 255];
    aliases[3] = [1, 2, 5, 0, 1, 7, 1, 10, 5, 10, 11, 12, 13, 14, 16, 11, 17, 23, 13, 14, 17, 23, 23, 24, 27, 27, 27, 27];
    // nose
    rarities[4] = [175, 100, 40, 250, 115, 100, 185, 175, 180, 255];
    aliases[4] = [3, 0, 4, 6, 6, 7, 8, 8, 9, 9];
    // mouth
    rarities[5] = [80, 225, 227, 228, 112, 240, 64, 160, 167, 217, 171, 64, 240, 126, 80, 255];
    aliases[5] = [1, 2, 3, 8, 2, 8, 8, 9, 9, 10, 13, 10, 13, 15, 13, 15];
    // neck
    rarities[6] = [255];
    aliases[6] = [0];
    // feet
    rarities[7] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255];
    aliases[7] = [1, 7, 0, 0, 0, 0, 0, 10, 0, 0, 11, 18, 0, 0, 0, 1, 7, 11, 18];
    // alphaIndex
    rarities[8] = [255];
    aliases[8] = [0];

    // wolves
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
  }

  /** EXTERNAL */

  /** 
   * mint a token - 99% Sheep, 1% Wolves
   */
  function mint(uint256 amount) external payable whenNotPaused {
    require(msg.sender == tx.origin, "Cannot use a contract to mint");
    require(amount <= MAX_MINT, "Over max limit");
    require(totalSupply() < MAX_SUPPLY, "All tokens minted");
    require(totalPublicSupply < MAX_PUBLIC_SUPPLY, "Over max public limit");
    require(msg.value >= price * amount, "ETH sent is not correct");

    uint256 seed;
    for (uint256 i; i < amount; i++) {
        if (totalPublicSupply < MAX_PUBLIC_SUPPLY) {
            totalPublicSupply += 1;
            minted++;
            seed = random(minted);
            generate(minted, seed);
            _safeMint(msg.sender, minted);
        }
    }
}

  function genesisMint(uint256[] memory tokenIds) public {
    require(tokenIds.length <= 20, "Can't claim more than 20 Geckos at once.");
    require(msg.sender == tx.origin, "Cannot use a contract for this");
    require(totalSupply() < MAX_SUPPLY, "All tokens minted");
    require(
        totalPrivateSupply + (tokenIds.length) < MAX_PRIVATE_SUPPLY + 1,
        "Exceeds private supply"
    );
    
    uint256 seed;
    for (uint i = 0; i < tokenIds.length; i++) {
        require(mintPassContract.ownerOf(tokenIds[i]) == msg.sender, "You do not own this token.");
        require(!isClaimed(tokenIds[i]), "Gecko has already been claimed for this token.");
        claimlist[tokenIds[i]].tokenId = tokenIds[i];
        claimlist[tokenIds[i]].claimed = true;
        totalPrivateSupply += 1;
        minted++;
        seed = random(minted);
        generate(minted, seed);
        _safeMint(msg.sender, minted);
    }
}

  function burnAndRecycle(uint256 tokenId) external {
    require(msg.sender == tx.origin, "Cannot use a contract for this");
    require(burnNTTZ <= nttzToken.balanceOf(msg.sender), "You don't have enough NTTZ to perform this action");
        
    uint256 seed;
        require(ownerOf(tokenId) == msg.sender, "You do not own that NFT");
        nttzToken.burn(msg.sender, burnNTTZ);
        seed = random(tokenId);
        maxIndex[tokenId] = maxIndex[tokenId] + 1;
        tokenIndex[tokenId] = maxIndex[tokenId];
        tokenTraits[tokenId][tokenIndex[tokenId]] = generate(tokenId, seed);
    }
        
    

  /** INTERNAL */

  /**
   * generates traits for a specific token, checking to make sure it's unique
   * @param tokenId the id of the token to generate traits for
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t - a struct of traits for the given token ID
   */
  function generate(uint256 tokenId, uint256 seed) internal returns (SheepWolf memory t) {
    t = selectTraits(seed);
    if (existingCombinations[structToHash(t)] == 0) {
      tokenTraits[tokenId][maxIndex[tokenId]] = t;
      existingCombinations[structToHash(t)] = tokenId;
      return t;
    }
    return generate(tokenId, random(seed));
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
    if (seed >> 8 < rarities[traitType][trait]) return trait;
    return aliases[traitType][trait];
  }

  /**
   * selects the species and all of its traits based on the seed value
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t -  a struct of randomly selected traits
   */
  function selectTraits(uint256 seed) internal view returns (SheepWolf memory t) {    
    t.isSheep = (seed & 0xFFFF) % 1 != 0;
    uint8 shift = t.isSheep ? 0 : 9;
    seed >>= 16;
    t.fur = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
    seed >>= 16;
    t.head = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
    seed >>= 16;
    t.ears = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
    seed >>= 16;
    t.eyes = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
    seed >>= 16;
    t.nose = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
    seed >>= 16;
    t.mouth = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
    seed >>= 16;
    t.neck = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
    seed >>= 16;
    t.feet = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
    seed >>= 16;
    t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
  }

  /**
   * converts a struct to a 256 bit hash to check for uniqueness
   * @param s the struct to pack into a hash
   * @return the 256 bit hash of the struct
   */
  function structToHash(SheepWolf memory s) internal pure returns (uint256) {
    return uint256(bytes32(
      abi.encodePacked(
        s.isSheep,
        s.fur,
        s.head,
        s.eyes,
        s.mouth,
        s.neck,
        s.ears,
        s.feet,
        s.alphaIndex
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
  
  function nttz_SetAddress(address _nttz) external onlyOwner {
	nttzToken = NTTZToken(_nttz);
  }

  function getTokenTraits(uint256 tokenId) external view override returns (SheepWolf memory) {
    return tokenTraits[tokenId][0];
  }

  function chooseImage(uint256 tokenId, uint256 index) public {
    require(maxIndex[tokenId] >= index, "Not available");
    require(0 <= index, "Not available");
    tokenIndex[tokenId] = index;
  }

  function _getTokenTraits(uint256 tokenId) external view override returns (SheepWolf memory) {
    return tokenTraits[tokenId][tokenIndex[tokenId]];
  }
  
  function setMintPrice(uint256 val) external onlyOwner {
    price = val;
  }
    
  function setBurnPrice(uint256 val) external onlyOwner {
    burnNTTZ = val;
  }

  function isClaimed(uint256 tokenId) public view returns (bool claimed) {
    return claimlist[tokenId].tokenId == tokenId;
  }
  
  function setContractURI(string memory _contractURI) public onlyOwner {
    _baseContractURI = _contractURI;    
  }
  
  function contractURI() public view returns (string memory) {
    return _baseContractURI;
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** RENDER */

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return traits.tokenURI(tokenId);
  }
}

interface MintPassContract {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
 }
 
interface NTTZToken {
    function burn(address _from, uint256 _amount) external;
    function balanceOf(address account) external view returns (uint256);
}