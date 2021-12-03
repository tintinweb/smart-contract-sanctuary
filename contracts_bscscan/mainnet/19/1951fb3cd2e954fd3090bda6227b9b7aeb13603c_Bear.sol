// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./VRFConsumerBase.sol";
import "./Counters.sol";
import "./IERC20.sol";


import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";


interface IFish {
  function burn(address from, uint256 amount) external;
}

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IBear {
  struct ManBear {bool isFisherman; uint8[14] traitarray; uint8 alphaIndex;}
  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (ManBear memory);
}

interface IRiver {
  function addManyToRiverSideAndFishing(address account, uint16[] calldata tokenIds) external;
  function randomBearOwner(uint256 seed) external view returns (address);
}

contract Bear is IBear, ERC721Enumerable, Ownable, Pausable, VRFConsumerBase {
  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.UintSet; 


  // mint variables                    
  uint256 public immutable MAX_TOKENS;                                   // max number of tokens that can be minted - 50000 in production
  uint256 public PAID_TOKENS;                                            // number of tokens that can be claimed for free - 20% of MAX_TOKENS
  uint16 public minted;                                                  // number of tokens have been minted so far
  uint256 public constant MINT_PRICE = .069420 ether;                    // mint price
      

  
  string public baseURI;

  // mappings
  mapping(address => uint256) public whitelists;
  mapping(uint256 => ManBear) public tokenTraits;                       // mapping from tokenId to a struct containing the token's traits
  mapping(uint256 => uint256) public existingCombinations;              // mapping from hashed(tokenTrait) to the tokenId it's associated with, Why? used to ensure there are no duplicates
  mapping(address => uint256[]) public _mints;



  // Pobabilities & Aliases
  // 0 - 8 are associated with fishermen, 9 - 13 are associated with Bears
  uint8[][18] public rarities;
  uint8[][18] public aliases;


  IRiver public river;                                                       // STAKING - reference to the Barn for choosing random Bear thieves
  IFish public fish;                                                       // TOKEN - reference to $WOOL for burning on mint
  ITraits public traits;                                                    // TRAITS - reference to Traits

  // Team Wallets

  address private project_wallet = 0x20A6e48906a1A3069dB74a5BDD6b5248E355c960; 
  address private Bear1 = 0x20A6e48906a1A3069dB74a5BDD6b5248E355c960; 
  address private Bear2 = 0x20A6e48906a1A3069dB74a5BDD6b5248E355c960; 
  address private Bear3 = 0x20A6e48906a1A3069dB74a5BDD6b5248E355c960; 
  address private Bear4 = 0x20A6e48906a1A3069dB74a5BDD6b5248E355c960; 
  

  //Chainlink Setup:
  bytes32 internal keyHash;
  uint256 public fee;
  uint256 internal randomResult;
  uint256 internal randomNumber;
  address public linkToken;
  uint256 public vrfcooldown = 10000;
  Counters.Counter public vrfReqd;




  constructor(address _fish, uint256 _maxTokens, address _vrfCoordinator, address _link) 
      ERC721("BearFishGame", 'BFGAME') 
      VRFConsumerBase(_vrfCoordinator, _link)  

  { 


    keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
    fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)
    linkToken = _link;
    
  


    // Initate Interfaces
    fish = IFish(_fish);

    
    MAX_TOKENS = _maxTokens;
    PAID_TOKENS = _maxTokens / 5;

    // string[13] _traitTypes = ['Hat','Eyes','Body','Pants','Skintone','Mouth','Feet','Fishing Pole','Fish','Fur','Eyes','Clothes','Mouth','Alpha'];

    rarities[0] = [31,49,51,69,113,187,204,207,225]; 
    rarities[1] = [35,48,67,115,189,208,221];
    rarities[2] = [59,97,136,159,197];
    rarities[3] = [85,113,131,143,169];
    rarities[4] = [255,255,255,255];
    rarities[5] = [34,59,118,164,197,222];
    rarities[6] = [59,111,145,197];
    rarities[7] = [57,93,163,199];
    rarities[8] = [255];

    aliases[0] = [8,7,6,5,4,3,2,1,0];
    aliases[1] = [6,5,4,3,2,1,0];
    aliases[2] = [4,3,2,1,0];
    aliases[3] = [4,3,2,1,0];
    aliases[4] = [3,2,1,0];
    aliases[5] = [5,4,3,2,1,0];
    aliases[6] = [3,2,1,0];
    aliases[7] = [3,2,1,0];
    aliases[8] = [0];

    rarities[9] = [255,255,255,255,255];
    rarities[10] = [39,51,59,67,125,131,189,197,204,217];
    rarities[11] = [51,54,57,64,72,90,194,199,202,207,212];
    rarities[12] = [48,60,96,160,196,208];
    rarities[13] = [51,102,153,204];

    aliases[9] = [0,1,2,3,4];
    aliases[10] = [9,8,7,6,5,4,3,2,1,0];
    aliases[11] = [10,9,8,7,6,5,4,3,2,1,0];
    aliases[12] = [5,4,3,2,1,0];
    aliases[13] = [3,2,1,0];
    

  }


  /** 
   * mint a token - 90% Bears, 10% Fisherman
   * The first 20% are free to claim, the remaining cost $FISH
   */
      
    
  // Calculates Mint Cost using $FISH
  function mintCost(uint256 tokenId) public view returns (uint256) {
    if (tokenId <= PAID_TOKENS) return 0;                           // the first 20% are paid in ETH, Hence 0 $FISH
    if (tokenId <= MAX_TOKENS * 2 / 5) return 20000 ether;          // the next 20% are 20000 $FISH
    if (tokenId <= MAX_TOKENS * 4 / 5) return 40000 ether;          // the next 40% are 40000 $FISH
    return 80000 ether;                                             // the final 20% are 80000 $FISH
  }

  // Main Mint Functions
  function mint(uint256 amount, bool stake) external payable whenNotPaused {

    address msgSender = _msgSender();

    require(tx.origin == msgSender, "Only EOA");
    require(minted + amount <= MAX_TOKENS, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");
    
    if (minted < PAID_TOKENS) {


      uint256 mintCostEther = MINT_PRICE * amount;
      if (whitelists[msgSender] == 1) {
          mintCostEther = ( amount - 1) * MINT_PRICE;
          whitelists[msgSender] = 0;
      }
    
      require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
      require(mintCostEther == msg.value, "Invalid payment amount");


    } else {

      require(msg.value == 0);

    }

    uint256 totalFishCost = 0;                                                          // $FISH Cost to mint. 0 is Gen0
    uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);          
    uint256 seed;

    for (uint i = 0; i < amount; i++) {
      minted++;
      seed = random(minted);                                                             // NOTES: SUS
      generate(minted, seed);                                                            // Generates Token Traits and adds it to the array
      address recipient = selectRecipient(seed);                                         // Selects who the NFT is going to. Gen0 always will be minter. 
      if (!stake || recipient != msgSender) {                                            // recipient != _msgSender() -- IF I BAN CONTRACT, SHIT MIGHT BE GOOOOOFY
        _safeMint(recipient, minted);
      } else {
        _safeMint(address(river), minted);
        tokenIds[i] = minted;
      }
      totalFishCost += mintCost(minted);
    }
    
    if (totalFishCost > 0) fish.burn(msgSender, totalFishCost);
    if (stake) river.addManyToRiverSideAndFishing(msgSender, tokenIds);
  }





  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    // Hardcode the River's approval so that users don't have to waste gas approving
    if (_msgSender() != address(river))
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
  }

 function reName(string memory name_, string memory symbol_) external onlyOwner {
    _reName(name_,symbol_);
  }


  // generates traits for a specific token, checking to make sure it's unique
  function generate(uint256 tokenId, uint256 seed) internal returns (ManBear memory t) {
    getRandomChainlink();
    t = selectTraits(seed);
    if (existingCombinations[structToHash(t.isFisherman, t.traitarray, t.alphaIndex)] == 0) {
      tokenTraits[tokenId] = t;
      existingCombinations[structToHash(t.isFisherman, t.traitarray, t.alphaIndex)] = tokenId;
      return t;
    }
    return generate(tokenId, random(seed));
  }

  // Selects Trait using A.J. Walker's Alias algorithm for O(1) rarity table lookup
  function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {

    uint8 trait = uint8(seed) % uint8(rarities[traitType].length);           
    if (seed >> 8 < rarities[traitType][trait]) return trait;                 
    return aliases[traitType][trait];

  }


  // selects the species and all of its traits based on the seed value
  function selectTraits(uint256 seed) internal view returns (ManBear memory t) {    
    t.isFisherman = (seed & 0xFFFF) % 10 != 0;
    uint8 shift = t.isFisherman ? 0 : 9;                                          // 0 if its a Fisherman, 9 if its Bear

    seed >>= 16;
    if (t.isFisherman) {

      // / 0 - 8 are associated with fishermen, 


      t.traitarray[0] = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
      seed >>= 16;
      t.traitarray[1] = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
      seed >>= 16;
      t.traitarray[2] = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
      seed >>= 16;
      t.traitarray[3] = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
      seed >>= 16;
      t.traitarray[4] = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
      seed >>= 16;
      t.traitarray[5] = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
      seed >>= 16;
      t.traitarray[6] = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
      seed >>= 16;
      t.traitarray[7] = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
      seed >>= 16;
      t.traitarray[8] = selectTrait(uint16(seed & 0xFFFF), 8 + shift);

      t.alphaIndex = 0;




    } else {
      // 9 - 13 are associated with Bears

      t.traitarray[9] = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
      seed >>= 16;
      t.traitarray[10] = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
      seed >>= 16;
      t.traitarray[11] = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
      seed >>= 16;
      t.traitarray[12] = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
      seed >>= 16;
      t.traitarray[13] = selectTrait(uint16(seed & 0xFFFF), 4 + shift);

      t.alphaIndex = t.traitarray[13];
      
      
    }

  }


  // converts a struct to a 256 bit hash to check for uniqueness
function structToHash(bool isFisherman, uint8[14] memory traitarray, uint8 alphaIndex) internal pure returns (uint256) {
    if(isFisherman){
      return uint256(bytes32(abi.encodePacked(true,
        traitarray[0],
        traitarray[1],
        traitarray[2],
        traitarray[3],
        traitarray[4],
        traitarray[5],
        traitarray[6],
        traitarray[7],
        traitarray[8],
        "0",
        "0",
        "0",
        "0",
        "0",
        alphaIndex)));
    }
    else{
      return uint256(bytes32(abi.encodePacked(false,
        "0",
        "0",
        "0",
        "0",
        "0",
        "0",
        "0",
        "0",
        "0",
        traitarray[9],
        traitarray[10],
        traitarray[11],
        traitarray[12],
        traitarray[13],
        alphaIndex)));
    }
    
  }
  // Select who the NFT goes to --- The first 20% (ETH purchases) go to the minter & the remaining 80% have a 10% chance to be given to a random staked Bear
  function selectRecipient(uint256 seed) internal view returns (address) {
    if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0) return _msgSender();                 // top 10 bits haven't been used
    address thief = river.randomBearOwner(seed >> 144);                                          // 144 bits reserved for trait selection
    if (thief == address(0x0)) return _msgSender();
    return thief;
  }


  /** READ */

  function getTokenTraits(uint256 tokenId) external view override returns (ManBear memory) {
    return tokenTraits[tokenId];
  }

  function getPaidTokens() external view override returns (uint256) {
    return PAID_TOKENS;
  }


  // called after deployment so that the contract can get random Bear thieves
  function setRiver(address _river) external onlyOwner {
    river = IRiver(_river);
    getRandomChainlink();
  }

  // Set Interfaces
  function setInit(address _river, address erc20Address, address _traits ) public onlyOwner {
    river = IRiver(_river);
    fish = IFish(erc20Address);
    // fish = IERC20(_fish);
    traits = ITraits(_traits);
    getRandomChainlink();
  }
  
  // Set Base URL
  function setURI(string memory _newBaseURI) external onlyOwner {
      baseURI = _newBaseURI;
  }

  // withdraw functions
  function withdraw() public payable onlyOwner {

    uint256 _project = (address(this).balance * 10) / 100;        
    uint256 _bear1 = (address(this).balance * 225) / 1000;  
    uint256 _bear2 = (address(this).balance * 225) / 1000;  
    uint256 _bear3 = (address(this).balance * 225) / 1000;  
    uint256 _bear4 = (address(this).balance * 225) / 1000;  

    payable(project_wallet).transfer(_project);
    payable(Bear1).transfer(_bear1);
    payable(Bear2).transfer(_bear2);
    payable(Bear3).transfer(_bear3);
    payable(Bear4).transfer(_bear4);

  }



  // updates the number of tokens for sale
  function setPaidTokens(uint256 _paidTokens) external onlyOwner {
    PAID_TOKENS = _paidTokens;
    // MAX_TOKENS = _maxTokens;
    // PAID_TOKENS = _maxTokens / 5;
  }


  // enables owner to pause / unpause minting
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }


  function addWhitelist(address[] calldata addressArrays) external onlyOwner {

    uint256 addylength = addressArrays.length;

    for (uint256 i; i < addylength; i++ ){

          whitelists[addressArrays[i]] = 1;
    }
  }




  /** RENDER */

  function setBaseURI(string memory newUri) public onlyOwner {
      baseURI = newUri;
  }


  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }


  function getTokenIds(address _owner) public view returns (uint256[] memory _tokensOfOwner) {
        _tokensOfOwner = new uint256[](balanceOf(_owner));
        for (uint256 i;i<balanceOf(_owner);i++){
            _tokensOfOwner[i] = tokenOfOwnerByIndex(_owner, i);
        }
  }


      
  /** RANDOMNESSSS */

  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed,
      randomNumber
    )));
  }

  function changeLinkFee(uint256 _fee) external onlyOwner {
    // fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    fee = _fee;
  }

  function initChainLink() external onlyOwner {
      getRandomChainlink();
  }

  function getRandomChainlink() internal returns (bytes32 requestId) {

    if (vrfReqd.current() <= vrfcooldown) {
      vrfReqd.increment();
      return 0x000;
    }

    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
    vrfReqd.reset();
    return requestRandomness(keyHash, fee);
  }

  function changeVrfCooldown(uint256 _cooldown) external onlyOwner{
      vrfcooldown = _cooldown;
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
      bytes32 reqId = requestId;
      require(reqId>0," Error requestId");
      randomNumber = randomness;
  }

  function withdrawLINK() external onlyOwner {
    uint256 tokenSupply = IERC20(linkToken).balanceOf(address(this));
    IERC20(linkToken).transfer(msg.sender, tokenSupply);
  }


}