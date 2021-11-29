// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "IERC721Receiver.sol";
import "Ownable.sol";
import "Pausable.sol";
import "Roar.sol";
import "VRFConsumerBase.sol";
import "Address.sol";
import "Counters.sol";
import "ReentrancyGuard.sol";


interface ITMilk {
  function mint(address to, uint256 amount) external;
}

contract Field is Ownable, IERC721Receiver, Pausable, VRFConsumerBase,ReentrancyGuard {
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
  ITMilk milk;                                                           // reference to the $MILK contract for minting $MILK earnings



  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event CatClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event DogClaimed(uint256 tokenId, uint256 earned, bool unstaked);


  mapping(uint256 => Stake) internal riverside;                                 // maps tokenId to stake
  mapping(uint256 => Stake[]) internal Dogs;                                   // maps alpha to all Dog stakes with that alpha
  mapping(address => EnumerableSet.UintSet) private _deposits;
  mapping(uint256 => uint256) public packIndices;                             // tracks location of each Dog in Pack
  
  
  uint256 internal totalAlphaStaked = 0;                                    // total alpha scores staked
  uint256 public unaccountedRewards = 0;                                  // any rewards distributed when no dogs are staked
  uint256 internal MilkPerAlpha = 0;                                      // amount of $MILK due for each alpha point staked


  uint256 internal  DAILY_MILK_RATE = 4000 ether;                        // Cat earn 4000 $MILK per day
  uint256 public  MINIMUM_TO_EXIT = 1.5 days;                               // Cat must have 3 days worth of $MILK to unstake or else it's too cold
  
  /** Constant Parameters*/
  uint256 internal  constant MILK_CLAIM_TAX_PERCENTAGE = 20;              // Dogs take a 20% tax on all $MILK claimed
  uint256 public  constant MAXIMUM_GLOBAL_WOOL = 1000000000 ether;        // there will only ever be (roughly) 1 billion $MILK earned through staking
  uint8   public  constant MAX_ALPHA = 8;       


  uint256 internal totalMilkEarned;                                       // amount of $MILK earned so far
  uint256 internal totalCatStaked;                                    // number of Cat staked in the Riverside
  uint256 public lastClaimTimestamp;                                      // the last time $MILK was claimed

  bool public rescueEnabled = false;                                    // emergency rescue to allow unstaking without any checks but without $MILK


  //Chainlink Setup:
  bytes32 internal keyHash;
  uint256 public fee;
  uint256 internal randomResult;
  uint256 internal randomNumber;
  address public linkToken;
  uint256 public vrfcooldown = 10000;
  Counters.Counter public vrfReqd;


  constructor(address _roar, address _milk, address _vrfCoordinator, address _link) 
      VRFConsumerBase(_vrfCoordinator, _link)
  { 
    roar = Roar(_roar);                                                    // reference to the Roar NFT contract
    milk = ITMilk(_milk);                                                //reference to the $MILK token

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

   function addManyToField(address account, uint16[] calldata tokenIds) external {    // called in mint

    require(account == _msgSender() || _msgSender() == address(roar), "DONT GIVE YOUR TOKENS AWAY");    /// SEE IF I CAN ADD THE MF CONTRACT BAN

    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(roar)) { // dont do this step if its a mint + stake


        require(roar.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        roar.transferFrom(_msgSender(), address(this), tokenIds[i]);
        

      } else if (tokenIds[i] == 0) {

        continue; // there may be gaps in the array for stolen tokens
      }

      if (isCat(tokenIds[i])) 
        _addCatToRiverside(account, tokenIds[i]);
        
      else 
        _addCatToRiverside(account, tokenIds[i]);
    }
  }



  function _addCatToRiverside(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    riverside[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalCatStaked += 1;
   
    emit TokenStaked(account, tokenId, block.timestamp);
    _deposits[account].add(tokenId);
  }

  function _sendDogsFishing(address account, uint256 tokenId) internal {
    uint256 alpha = _alphaForDog(tokenId);
    totalAlphaStaked += alpha;                                                // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = Dogs[alpha].length;                                // Store the location of the Dog in the Pack
    Dogs[alpha].push(Stake({                                                  // Add the Dog to the Pack
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(MilkPerAlpha)
    })); 
    emit TokenStaked(account, tokenId, MilkPerAlpha);
    _deposits[account].add(tokenId);
  }

  /** CLAIMING / UNSTAKING */

  // realize $MILK earnings and optionally unstake tokens from the RIVER / FISHING
  function claimManyFromRiverAndFishing(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant() {

    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    
    uint256  owed = 0;
  
    if (owed == 0) return;
    milk.mint(_msgSender(), owed);


  }


  function calculateReward(uint16[] calldata tokenIds) public view returns (uint256 owed) {

    for (uint i = 0; i < tokenIds.length; i++) {
      if (isCat(tokenIds[i]))
        owed += calcRewardCat(tokenIds[i]);
      else
        owed += calcRewardCat(tokenIds[i]);
    }
  
  }


  function calcRewardCat(uint256 tokenId) internal view returns (uint256 owed) {

    Stake memory stake = riverside[tokenId];

    if (totalMilkEarned < MAXIMUM_GLOBAL_WOOL) {
        owed = (block.timestamp - stake.value) * DAILY_MILK_RATE / 1 days;

    } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $WOOL production stopped already

    } else {
        owed = (lastClaimTimestamp - stake.value) * DAILY_MILK_RATE / 1 days; // stop earning additional $WOOL if it's all been earned
    }


  }


  function calcRewardDog(uint256 tokenId) internal view returns (uint256 owed) {

    uint256 alpha = _alphaForDog(tokenId);  
    Stake memory stake = Dogs[alpha][packIndices[tokenId]];
    owed = (alpha) * (MilkPerAlpha - stake.value); 
    // Calculate portion of tokens based on Alpha

  }

  // Basically, withdraws $MILK earnings for a single Cat and optionally unstake it.
  // 20% Dog Tax, 50% chance all goes to Dog if unstaking. 
  function _claimFisherFromRiver(uint256 tokenId, bool unstake) internal returns (uint256 owed) {

    Stake memory stake = riverside[tokenId];

    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S WOOL");

    owed = calcRewardCat(tokenId);

    if (unstake) {
      
      if (random(tokenId) & 1 == 1) {                                           // 50% chance of all $MILK stolen
        _payDogTax(owed);
        owed = 0;  
      }
      
      delete riverside[tokenId];
      totalCatStaked -= 1;
      _deposits[_msgSender()].remove(tokenId);
      roar.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Cat        


    } else {

      _payDogTax(owed * MILK_CLAIM_TAX_PERCENTAGE / 100);                    // percentage tax to staked Dogs    
      riverside[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
      owed = owed * (100 - MILK_CLAIM_TAX_PERCENTAGE) / 100;                  // remainder goes to Cat owner
    }
    emit CatClaimed(tokenId, owed, unstake);
  }


  // Basically, withdraws $MILK earnings for a single Dog and optionally unstake it.
  function _claimDogFromFishing(uint256 tokenId, bool unstake) internal returns (uint256 owed) {

    uint256 alpha = _alphaForDog(tokenId);  
    Stake memory stake = Dogs[alpha][packIndices[tokenId]];

    require(roar.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");                
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");

    owed = calcRewardDog(tokenId);                                         // Calculate portion of tokens based on Alpha

    if (unstake) {
      totalAlphaStaked -= alpha;                                            // Remove Alpha from total staked
      Stake memory lastStake = Dogs[alpha][Dogs[alpha].length - 1];         // Shuffle last Dog to current position PT 1 
      Dogs[alpha][packIndices[tokenId]] = lastStake;                        // Shuffle last Dog to current position PT 2
      packIndices[lastStake.tokenId] = packIndices[tokenId];                // Shuffle last Dog to current position PT 3
      Dogs[alpha].pop();                                                    // Remove duplicate

      delete packIndices[tokenId];                                          // Delete old mapping
      _deposits[_msgSender()].remove(tokenId);
      roar.safeTransferFrom(address(this), _msgSender(), tokenId, "");     // Send back Dog        


    } else {

      Dogs[alpha][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(MilkPerAlpha)
      }); // reset stake

    }
    emit DogClaimed(tokenId, owed, unstake);
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
      if (isCat(tokenId)) {
        stake = riverside[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        delete riverside[tokenId];
        totalCatStaked -= 1;
        roar.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Cat
        emit CatClaimed(tokenId, 0, true);
      } else {
        alpha = _alphaForDog(tokenId);
        stake = Dogs[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalAlphaStaked -= alpha; // Remove Alpha from total staked
        lastStake = Dogs[alpha][Dogs[alpha].length - 1];
        Dogs[alpha][packIndices[tokenId]] = lastStake; // Shuffle last dog to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        Dogs[alpha].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        roar.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Cat
        emit DogClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  // add $MILK to claimable pot for the Pack
  function _payDogTax(uint256 amount) internal {

    if (totalAlphaStaked == 0) {                                              // if there's no staked Dog > keep track of $MILK due to Dog
      unaccountedRewards += amount; 
      return;
    }

    MilkPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;         // makes sure to include any unaccounted $MILK
    unaccountedRewards = 0;
  }

  // tracks $SALMIN earnings to ensure it stops once 2.4 billion is eclipsed
  modifier _updateEarnings() {

    if (totalMilkEarned < MAXIMUM_GLOBAL_WOOL) {
      totalMilkEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalCatStaked
        * DAILY_MILK_RATE / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }


  function isCat(uint256 tokenId) internal view 
  returns (bool cat) {

   

  
    // SheepWolf memory t = roar.getTokenTraits(tokenId);(sheep, , , , , , , , , ) = roar.tokenTraits(tokenId);
    (cat, ) = roar.tokenTraits(tokenId);


  }

  // gets the alpha score for a Dog                                          
  function _alphaForDog(uint256 tokenId) internal view returns (uint8) {
    ( ,uint8 alphaIndex) = roar.tokenTraits(tokenId);

    return MAX_ALPHA - alphaIndex; // alpha index is 0-3
  }


  // chooses a random Dog thief when a newly minted token is stolen
  function randomDogOwner(uint256 seed) internal view returns (address) {
    if (totalAlphaStaked == 0) return address(0x0);

    uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked;                  // choose a value from 0 to total alpha staked
    uint256 cumulative;
    seed >>= 32;

    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {                     // loop through each bucket of Dogs with the same alpha score
      cumulative += Dogs[i].length * i;
      if (bucket >= cumulative) continue;                                   // if the value is not inside of that bucket, keep going

      return Dogs[i][seed % Dogs[i].length].owner;                          // get the address of a random Dog with that alpha score
    }

    return address(0x0);
  }

  /** CHANGE PARAMETERS */


  function setInit(address _roar, address _milk) external onlyOwner{
    roar = Roar(_roar);                                              // reference to the Roar NFT contract
    milk = ITMilk(_milk);                                                //reference to the $MILK token

  }

  function changeDailyRate(uint256 _newRate) external onlyOwner{
      DAILY_MILK_RATE = _newRate;
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