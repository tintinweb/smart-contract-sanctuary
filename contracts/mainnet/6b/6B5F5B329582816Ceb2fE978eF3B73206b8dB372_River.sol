// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Roar.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface ITSalmon {
  function mint(address to, uint256 amount) external;
}

contract River is Ownable, IERC721Receiver, Pausable, VRFConsumerBase,ReentrancyGuard {
  using Address for address;
  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.UintSet; 

                             
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }


  /** INTERFACES */
  Roar roar;                                                                 // reference to the Roar NFT contract
  ITSalmon salmon;                                                           // reference to the $SALMON contract for minting $SALMON earnings



  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event FishermanClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event BearClaimed(uint256 tokenId, uint256 earned, bool unstaked);


  mapping(uint256 => Stake) public riverside;                                 // maps tokenId to stake
  mapping(uint256 => Stake[]) public Bears;                                   // maps alpha to all Bear stakes with that alpha
  mapping(address => EnumerableSet.UintSet) private _deposits;
  mapping(uint256 => uint256) public packIndices;                             // tracks location of each Bear in Pack
  
  
  uint256 public totalAlphaStaked = 0;                                    // total alpha scores staked
  uint256 public unaccountedRewards = 0;                                  // any rewards distributed when no bears are staked
  uint256 public SalmonPerAlpha = 0;                                      // amount of $SALMON due for each alpha point staked


  uint256 public  DAILY_SALMON_RATE = 10000 ether;                        // Fisherman earn 10000 $SALMON per day
  uint256 public  MINIMUM_TO_EXIT = 2 days;                               // Fisherman must have 2 days worth of $SALMON to unstake or else it's too cold
  
  /** Constant Parameters*/
  uint256 public  constant SALMON_CLAIM_TAX_PERCENTAGE = 20;              // Bears take a 20% tax on all $SALMON claimed
  uint256 public  constant MAXIMUM_GLOBAL_WOOL = 2400000000 ether;        // there will only ever be (roughly) 2.4 billion $SALMON earned through staking
  uint8   public  constant MAX_ALPHA = 8; 


  uint256 public totalSalmonEarned;                                       // amount of $SALMON earned so far
  uint256 public totalFishermanStaked;                                    // number of Fisherman staked in the Riverside
  uint256 public lastClaimTimestamp;                                      // the last time $SALMON was claimed

  bool public rescueEnabled = false;                                    // emergency rescue to allow unstaking without any checks but without $SALMON


  //Chainlink Setup:
  bytes32 internal keyHash;
  uint256 public fee;
  uint256 internal randomResult;
  uint256 internal randomNumber;
  address public linkToken;
  uint256 public vrfcooldown = 10000;
  Counters.Counter public vrfReqd;


  constructor(address _roar, address _salmon, address _vrfCoordinator, address _link) 
      VRFConsumerBase(_vrfCoordinator, _link)
  { 
    roar = Roar(_roar);                                                    // reference to the Roar NFT contract
    salmon = ITSalmon(_salmon);                                                //reference to the $SALMON token

    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)
    linkToken = _link;





  }

  function depositsOf(address account) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage depositSet = _deposits[account];
    uint256[] memory tokenIds = new uint256[] (depositSet.length());

    for (uint256 i; i < depositSet.length(); i++) {
      tokenIds[i] = depositSet.at(i);
    }

    return tokenIds;
  }

  /** STAKING */

  function addManyToRiverSideAndFishing(address account, uint16[] calldata tokenIds) external {    // called in mint

    require(account == _msgSender() || _msgSender() == address(roar), "DONT GIVE YOUR TOKENS AWAY");    /// SEE IF I CAN ADD THE MF CONTRACT BAN

    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(roar)) { // dont do this step if its a mint + stake


        require(roar.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        roar.transferFrom(_msgSender(), address(this), tokenIds[i]);
        

      } else if (tokenIds[i] == 0) {

        continue; // there may be gaps in the array for stolen tokens
      }

      if (isFisherman(tokenIds[i])) 
        _addFishermanToRiverside(account, tokenIds[i]);
        
      else 
        _sendBearsFishing(account, tokenIds[i]);
    }
  }



  function _addFishermanToRiverside(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    riverside[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalFishermanStaked += 1;
   
    emit TokenStaked(account, tokenId, block.timestamp);
    _deposits[account].add(tokenId);
  }

  function _sendBearsFishing(address account, uint256 tokenId) internal {
    uint256 alpha = _alphaForBear(tokenId);
    totalAlphaStaked += alpha;                                                // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = Bears[alpha].length;                                // Store the location of the Bear in the Pack
    Bears[alpha].push(Stake({                                                  // Add the Bear to the Pack
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(SalmonPerAlpha)
    })); 
    emit TokenStaked(account, tokenId, SalmonPerAlpha);
    _deposits[account].add(tokenId);
  }

  /** CLAIMING / UNSTAKING */

  // realize $SALMON earnings and optionally unstake tokens from the RIVER / FISHING
  function claimManyFromRiverAndFishing(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant() {

    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    
    uint256  owed = 0;
    
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isFisherman(tokenIds[i]))
        owed += _claimFisherFromRiver(tokenIds[i], unstake);
      else
        owed += _claimBearFromFishing(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    salmon.mint(_msgSender(), owed);


  }


  function calculateReward(uint16[] calldata tokenIds) public view returns (uint256 owed) {

    for (uint i = 0; i < tokenIds.length; i++) {
      if (isFisherman(tokenIds[i]))
        owed += calcRewardFisherman(tokenIds[i]);
      else
        owed +=  calcRewardBear(tokenIds[i]);
    }
  
  }


  function calcRewardFisherman(uint256 tokenId) public view returns (uint256 owed) {

    Stake memory stake = riverside[tokenId];

    if (totalSalmonEarned < MAXIMUM_GLOBAL_WOOL) {
        owed = (block.timestamp - stake.value) * DAILY_SALMON_RATE / 1 days;

    } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $WOOL production stopped already

    } else {
        owed = (lastClaimTimestamp - stake.value) * DAILY_SALMON_RATE / 1 days; // stop earning additional $WOOL if it's all been earned
    }


  }


  function calcRewardBear(uint256 tokenId) public view returns (uint256 owed) {

    uint256 alpha = _alphaForBear(tokenId);  
    Stake memory stake = Bears[alpha][packIndices[tokenId]];
    owed = (alpha) * (SalmonPerAlpha - stake.value); 
    // Calculate portion of tokens based on Alpha

  }

  // Basically, withdraws $SALMON earnings for a single Fisherman and optionally unstake it.
  // 20% Bear Tax, 50% chance all goes to Bear if unstaking. 
  function _claimFisherFromRiver(uint256 tokenId, bool unstake) internal returns (uint256 owed) {

    Stake memory stake = riverside[tokenId];

    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S WOOL");

    owed = calcRewardFisherman(tokenId);

    if (unstake) {
      getRandomChainlink();
      
      if (random(tokenId) & 1 == 1) {                                           // 50% chance of all $SALMON stolen
        _payBearTax(owed);
        owed = 0;  
      }
      
      delete riverside[tokenId];
      totalFishermanStaked -= 1;
      _deposits[_msgSender()].remove(tokenId);
      roar.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Fisherman        


    } else {

      _payBearTax(owed * SALMON_CLAIM_TAX_PERCENTAGE / 100);                    // percentage tax to staked Bears    
      riverside[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
      owed = owed * (100 - SALMON_CLAIM_TAX_PERCENTAGE) / 100;                  // remainder goes to Fisherman owner
    }
    emit FishermanClaimed(tokenId, owed, unstake);
  }


  // Basically, withdraws $SALMON earnings for a single BEAR and optionally unstake it.
  function _claimBearFromFishing(uint256 tokenId, bool unstake) internal returns (uint256 owed) {

    uint256 alpha = _alphaForBear(tokenId);  
    Stake memory stake = Bears[alpha][packIndices[tokenId]];

    require(roar.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");                
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");

    owed = calcRewardBear(tokenId);                                         // Calculate portion of tokens based on Alpha

    if (unstake) {
      totalAlphaStaked -= alpha;                                            // Remove Alpha from total staked
      Stake memory lastStake = Bears[alpha][Bears[alpha].length - 1];         // Shuffle last Bear to current position PT 1 
      Bears[alpha][packIndices[tokenId]] = lastStake;                        // Shuffle last Bear to current position PT 2
      packIndices[lastStake.tokenId] = packIndices[tokenId];                // Shuffle last Bear to current position PT 3
      Bears[alpha].pop();                                                    // Remove duplicate

      delete packIndices[tokenId];                                          // Delete old mapping
      _deposits[_msgSender()].remove(tokenId);
      roar.safeTransferFrom(address(this), _msgSender(), tokenId, "");     // Send back Bear        


    } else {

      Bears[alpha][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(SalmonPerAlpha)
      }); // reset stake

    }
    emit BearClaimed(tokenId, owed, unstake);
  }



   // emergency unstake tokens
  function rescue(uint256[] calldata tokenIds) external nonReentrant() {
    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    require(rescueEnabled, "RESCUE DISABLED");

    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint256 alpha;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isFisherman(tokenId)) {
        stake = riverside[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        delete riverside[tokenId];
        totalFishermanStaked -= 1;
        roar.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Fisherman
        emit FishermanClaimed(tokenId, 0, true);
      } else {
        alpha = _alphaForBear(tokenId);
        stake = Bears[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalAlphaStaked -= alpha; // Remove Alpha from total staked
        lastStake = Bears[alpha][Bears[alpha].length - 1];
        Bears[alpha][packIndices[tokenId]] = lastStake; // Shuffle last bear to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        Bears[alpha].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        roar.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Fisherman
        emit BearClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  // add $SALMON to claimable pot for the Pack
  function _payBearTax(uint256 amount) internal {

    if (totalAlphaStaked == 0) {                                              // if there's no staked Bear > keep track of $SALMON due to Bear
      unaccountedRewards += amount; 
      return;
    }

    SalmonPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;         // makes sure to include any unaccounted $SALMON
    unaccountedRewards = 0;
  }

  // tracks $SALMIN earnings to ensure it stops once 2.4 billion is eclipsed
  modifier _updateEarnings() {

    if (totalSalmonEarned < MAXIMUM_GLOBAL_WOOL) {
      totalSalmonEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalFishermanStaked
        * DAILY_SALMON_RATE / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }


  function isFisherman(uint256 tokenId) public view returns (bool fisherman) {
    // SheepWolf memory t = roar.getTokenTraits(tokenId);(sheep, , , , , , , , , ) = roar.tokenTraits(tokenId);
    (fisherman,  ) = roar.tokenTraits(tokenId);


  }

  // gets the alpha score for a Bear                                          
  function _alphaForBear(uint256 tokenId) public view returns (uint8) {
    ( ,uint8 alphaIndex) = roar.tokenTraits(tokenId);

    return MAX_ALPHA - alphaIndex; // alpha index is 0-3
  }


  // chooses a random Bear thief when a newly minted token is stolen
  function randomBearOwner(uint256 seed) external view returns (address) {
    if (totalAlphaStaked == 0) return address(0x0);

    uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked;                  // choose a value from 0 to total alpha staked
    uint256 cumulative;
    seed >>= 32;

    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {                     // loop through each bucket of Bears with the same alpha score
      cumulative += Bears[i].length * i;
      if (bucket >= cumulative) continue;                                   // if the value is not inside of that bucket, keep going

      return Bears[i][seed % Bears[i].length].owner;                          // get the address of a random Bear with that alpha score
    }

    return address(0x0);
  }

  /** CHANGE PARAMETERS */


  function setInit(address _roar, address _salmon) external onlyOwner{
    roar = Roar(_roar);                                              // reference to the Roar NFT contract
    salmon = ITSalmon(_salmon);                                                //reference to the $SALMON token

  }

  function changeDailyRate(uint256 _newRate) external onlyOwner{
      DAILY_SALMON_RATE = _newRate;
  }

  function changeMinExit(uint256 _newExit) external onlyOwner{
      _newExit = _newExit ;
  }

  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }
  
        
  /** RANDOMNESSSS */

  function changeLinkFee(uint256 _fee) external onlyOwner {
    // fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    fee = _fee;
  }

  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed,
      randomNumber
    )));
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
      randomNumber = randomness;
  }

  function withdrawLINK() external onlyOwner {
    uint256 tokenSupply = IERC20(linkToken).balanceOf(address(this));
    IERC20(linkToken).transfer(msg.sender, tokenSupply);
  }
   
   
  /** OTHERS  */


  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {

    require(from == address(0x0), "Cannot send tokens to Barn directly");
    return IERC721Receiver.onERC721Received.selector;

  }




  
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface ISalmon {
  function burn(address from, uint256 amount) external;
}

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IRoar {
  struct ManBear {bool isFisherman; uint8[14] traitarray; uint8 alphaIndex;}
  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (ManBear memory);
}

interface IRiver {
  function addManyToRiverSideAndFishing(address account, uint16[] calldata tokenIds) external;
  function randomBearOwner(uint256 seed) external view returns (address);
}

contract Roar is IRoar, ERC721Enumerable, Ownable, Pausable, VRFConsumerBase {
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
  ISalmon public salmon;                                                       // TOKEN - reference to $WOOL for burning on mint
  ITraits public traits;                                                    // TRAITS - reference to Traits

  // Team Wallets

  address private project_wallet = 0x06e8198A5a4AB3E5F4B13DdC9e5c2FCDDD4f8838; 
	address private Bear1 = 0x9E4FaAA4EFd0fb8CbC653Ee68C01c066d078098D; 
	address private Bear2 = 0xe18195D4995D994fAa3663db0b6E2FFF4042D0a1; 
	address private Bear3 = 0x9c39cD2f557B5E851f44ab18714BbBB15FA7417E; 
  address private Bear4 = 0x24af21668F33C8C279025b0E53fCC3bFf48426A0; 
  

  //Chainlink Setup:
  bytes32 internal keyHash;
  uint256 public fee;
  uint256 internal randomResult;
  uint256 internal randomNumber;
  address public linkToken;
  uint256 public vrfcooldown = 10000;
  Counters.Counter public vrfReqd;




  constructor(address _salmon, uint256 _maxTokens, address _vrfCoordinator, address _link) 
      ERC721("BearGame", 'BEARGAME') 
      VRFConsumerBase(_vrfCoordinator, _link)  

  { 


    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)
    linkToken = _link;
    
  


    // Initate Interfaces
    salmon = ISalmon(_salmon);

    
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
   * The first 20% are free to claim, the remaining cost $SALMON
   */
      
    
  // Calculates Mint Cost using $SALMON
  function mintCost(uint256 tokenId) public view returns (uint256) {
    if (tokenId <= PAID_TOKENS) return 0;                           // the first 20% are paid in ETH, Hence 0 $SALMON
    if (tokenId <= MAX_TOKENS * 2 / 5) return 20000 ether;          // the next 20% are 20000 $SALMON
    if (tokenId <= MAX_TOKENS * 4 / 5) return 40000 ether;          // the next 40% are 40000 $SALMON
    return 80000 ether;                                             // the final 20% are 80000 $SALMON
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

    uint256 totalSalmonCost = 0;                                                          // $SALMON Cost to mint. 0 is Gen0
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
      totalSalmonCost += mintCost(minted);
    }
    
    if (totalSalmonCost > 0) salmon.burn(msgSender, totalSalmonCost);
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
    salmon = ISalmon(erc20Address);
    // salmon = IERC20(_salmon);
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
      randomNumber = randomness;
  }

  function withdrawLINK() external onlyOwner {
    uint256 tokenSupply = IERC20(linkToken).balanceOf(address(this));
    IERC20(linkToken).transfer(msg.sender, tokenSupply);
  }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}