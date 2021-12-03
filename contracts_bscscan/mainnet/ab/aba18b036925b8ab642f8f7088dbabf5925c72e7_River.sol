// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Bear.sol";
import "./VRFConsumerBase.sol";
import "./Address.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";


interface ITFish {
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
  Bear bear;                                                                 // reference to the Roar NFT contract
  ITFish fish;                                                           // reference to the $SALMON contract for minting $SALMON earnings



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


  uint256 public  DAILY_FISH_RATE = 10000 ether;                        // Fisherman earn 10000 $SALMON per day
  uint256 public  MINIMUM_TO_EXIT = 2 days;                               // Fisherman must have 2 days worth of $SALMON to unstake or else it's too cold
  
  /** Constant Parameters*/
  uint256 public  constant SALMON_CLAIM_TAX_PERCENTAGE = 20;              // Bears take a 20% tax on all $SALMON claimed
  uint256 public  constant MAXIMUM_GLOBAL_WOOL = 2400000000 ether;        // there will only ever be (roughly) 2.4 billion $SALMON earned through staking
  uint8   public  constant MAX_ALPHA = 8; 


  uint256 public totalFishEarned;                                       // amount of $SALMON earned so far
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


  constructor(address _bear, address _fish, address _vrfCoordinator, address _link) 
      VRFConsumerBase(_vrfCoordinator, _link)
  { 
    bear = Bear(_bear);                                                    // reference to the Bear NFT contract
    fish = ITFish(_fish);                                                //reference to the $fish token

    keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
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

    require(account == _msgSender() || _msgSender() == address(bear), "DONT GIVE YOUR TOKENS AWAY");    /// SEE IF I CAN ADD THE MF CONTRACT BAN

    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(bear)) { // dont do this step if its a mint + stake


        require(bear.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        bear.transferFrom(_msgSender(), address(this), tokenIds[i]);
        

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
    fish.mint(_msgSender(), owed);


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

    if (totalFishEarned < MAXIMUM_GLOBAL_WOOL) {
        owed = (block.timestamp - stake.value) * DAILY_FISH_RATE / 1 days;

    } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $WOOL production stopped already

    } else {
        owed = (lastClaimTimestamp - stake.value) * DAILY_FISH_RATE / 1 days; // stop earning additional $WOOL if it's all been earned
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
      bear.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Fisherman        


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

    require(bear.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");                
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
      bear.safeTransferFrom(address(this), _msgSender(), tokenId, "");     // Send back Bear        


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
        bear.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Fisherman
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
        bear.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Fisherman
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

    if (totalFishEarned < MAXIMUM_GLOBAL_WOOL) {
      totalFishEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalFishermanStaked
        * DAILY_FISH_RATE / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }


  function isFisherman(uint256 tokenId) public view returns (bool fisherman) {
    // SheepWolf memory t = roar.getTokenTraits(tokenId);(sheep, , , , , , , , , ) = roar.tokenTraits(tokenId);
    (fisherman,  ) = bear.tokenTraits(tokenId);


  }

  // gets the alpha score for a Bear                                          
  function _alphaForBear(uint256 tokenId) public view returns (uint8) {
    ( ,uint8 alphaIndex) = bear.tokenTraits(tokenId);

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


  function setInit(address _bear, address _fish) external onlyOwner{
    bear = Bear(_bear);                                              // reference to the Roar NFT contract
    fish = ITFish(_fish);                                                //reference to the $SALMON token

  }

  function changeDailyRate(uint256 _newRate) external onlyOwner{
      DAILY_FISH_RATE = _newRate;
  }

  // function changeMinExit(uint256 _newExit) external onlyOwner{
  //     _newExit = _newExit ;
  // }

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
      require(reqId>0);
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