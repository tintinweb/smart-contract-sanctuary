// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Mintor.sol";
import "./Forest.sol";
import "./Prey.sol";
import "./HunterHound.sol";



contract HunterGame is Mintor, Forest, Ownable {


  // swtich to turn on/off the game
  bool _paused = true;

  // take back staked tokens using rescue() function in rescue mode, rescue mode happens when the code turns buggy
  bool _rescueEnabled = false;

  // switch to turn on/off the whitelist
  bool public _whitelistEnabled = true;

  // ERC20 contract
  Prey public prey;

  // ERC721 contract
  HunterHound public hunterHound;

  constructor(address prey_, address hunterHound_) {
    prey = Prey(prey_);

    hunterHound = HunterHound(hunterHound_);

  }

  /**
   * return main information of the game
   */
  function getGameStatus() public view 
  returns(
    bool paused, uint phase, uint minted, uint requested,
    uint hunterMinted, uint houndMinted, 
    uint hunterStaked, uint houndStaked,
    uint totalClaimed, uint totalBurned,
    uint houndsCaptured, uint maxTokensByCurrentPhase ) {
      paused = _paused;
      phase = currentPhase();
      minted = Mintor.minted;
      requested = Mintor.requested;
      hunterMinted = Mintor.hunterMinted;
      houndMinted = minted - hunterMinted;
      hunterStaked = Forest.hunterStaked;
      houndStaked = Forest.houndStaked;
      totalClaimed = Forest.totalClaimed;
      totalBurned = Forest.totalBurned;
      houndsCaptured = Forest.houndsCaptured;
      maxTokensByCurrentPhase = currentPhaseAmount();
  }

  /**
   * return phase number of the game by recorded mint requests
   */
  function currentPhase() public view returns(uint p) {
    uint[4] memory amounts = [PHASE1_AMOUNT,PHASE2_AMOUNT,PHASE3_AMOUNT,PHASE4_AMOUNT];
    for (uint i = 0; i < amounts.length; i++) {
      p += amounts[i];
      if (requested < p) {
        return i+1;
      }
    }
  }

  /**
   * get target total number of mints in current phase by recorded mint requests
   */
  function currentPhaseAmount() public view returns(uint p) {
    uint[4] memory amounts = [PHASE1_AMOUNT,PHASE2_AMOUNT,PHASE3_AMOUNT,PHASE4_AMOUNT];
    for (uint256 i = 0; i < amounts.length; i++) {
      p += amounts[i];
      if (requested < p) {
        return p;
      }
    }
  }

  /**
   * check whether the address has enough ETH or $PREY balance to mint in the wallet and validity of the number of mints
   */
  function mintPrecheck(uint amount) private {
    uint phaseAmount = currentPhaseAmount();
    // make sure preciseness of mints in every phase
    require(amount > 0 && amount <= 50 && (requested % phaseAmount) <= ((requested + amount - 1) % phaseAmount) , "Invalid mint amount");
    require(requested + amount <= MAX_TOKENS, "All tokens minted");
    uint phase = currentPhase();
    if (phase == 1) {
      require(msg.value == MINT_PRICE * amount, "Invalid payment amount");
    } else {
      require(msg.value == 0, "Only prey");
      uint totalMintCost;
      if (phase == 2) {
        totalMintCost = MINT_PHASE2_PRICE;
      } else if (phase == 3) {
        totalMintCost = MINT_PHASE3_PRICE;
      } else {
        totalMintCost = MINT_PHASE4_PRICE;
      }
      
      prey.burn(msg.sender, totalMintCost * amount);
    }
  }
  

  /************** MINTING **************/

  
  /**
   * security check and execute `Mintor._request()` function
   */
  function requestMint(uint amount) external payable {
    require(tx.origin == msg.sender, "No Access");
    if (_paused) {
      require(_whitelistEnabled, 'Paused');
    }
    mintPrecheck(amount);

    Mintor._request(msg.sender, amount);
  }

  /**
   * security check and execute `Mintor._receive()` function
   */
  function mint() external {
    require(tx.origin == msg.sender, "No Access");
    
    Mintor._receive(msg.sender, hunterHound);
  }

  /**
   * execute `Mintor._mintRequestState()` function
   */
  function mintRequestState(address requestor) external view returns (uint blockNumber, uint amount, uint state, uint open, uint timeout) {
    return _mintRequestState(requestor);
  }

  /************** Forest **************/

  /**
   * return all holders' stake history
   */
  function stakesByOwner(address owner) external view returns(Stake[] memory) {
    return stakes[owner];
  }

  /**
   * security check and execute `Forest._stake()` function
   */
  function stakeToForest(uint256[][] calldata paris) external whenNotPaused {
    require(tx.origin == msg.sender, "No Access");
    
    Forest._stake(msg.sender, paris, hunterHound);
  }

  /**
   * security check and execute `Forest._claim()` function
   */
  function claimFromForest() external whenNotPaused {
    require(tx.origin == msg.sender, "No Access");
    
    Forest._claim(msg.sender, prey);
    
  }

  /**
   * security check and execute `Forest._requestGamble()` function
   */
  function requestGamble(uint action) external whenNotPaused {
    require(tx.origin == msg.sender, "No Access");
    Forest._requestGamble(msg.sender, action);
  }

  /**
   * 执行 `Forest._gambleRequestState()` 
   */
  function gambleRequestState(address requestor) external view returns (uint blockNumber, uint action, uint state, uint open, uint timeout) {
    return Forest._gambleRequestState(requestor);
  }

  /**
   * security check and execute `Forest._unstake()` function
   */
  function unstakeFromForest() external whenNotPaused {
    require(tx.origin == msg.sender, "No Access");
    Forest._unstake(msg.sender, prey, hunterHound);
  }

  /**
   * security check and execute `Forest._rescue()` function
   */
  function rescue() external {
    require(tx.origin == msg.sender, "No Access");
    require(_rescueEnabled, "Rescue disabled");
    Forest._rescue(msg.sender, hunterHound);
  }

  /************** ADMIN **************/

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance available");
    payable(owner()).transfer(address(this).balance);
  }

  /**
   * when the game is not paused
   */
  modifier whenNotPaused() {
      require(_paused == false, "Pausable: paused");
      _;
  }

  /**
   * pause/run the game
   */
  function setPaused(bool paused_) external onlyOwner {
    _paused = paused_;
  }

  /**
   * turn on/off rescue mode
   */
  function setRescueEnabled(bool rescue_) external onlyOwner {
    _rescueEnabled = rescue_;
  }
  
  /**
   * turn on/off whitelist
   */
  function setWhitelistEnabled(bool whitelistEnabled_) external onlyOwner {
    _whitelistEnabled = whitelistEnabled_;
  }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './Prey.sol';

/**
 * Useful for simple vesting schedules like "developers get their tokens
 * after 2 years".
 */
contract TokenTimelock {

    // ERC20 basic token contract being held
    Prey private immutable _token;

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;
    
    //a vesting duration to release tokens 
    uint256 private immutable _releaseDuration;
    
    //record last withdraw time, through which calculate the total withdraw amount
    uint256 private lastWithdrawTime;
    //total amount of tokens to release
    uint256 private immutable _totalToken;

    constructor(
        Prey token_,
        address beneficiary_,
        uint256 releaseTime_,
        uint256 releaseDuration_,
        uint256 totalToken_
    ) {
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
        lastWithdrawTime = _releaseTime;
        _releaseDuration = releaseDuration_;
        _totalToken = totalToken_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (Prey) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        uint256 releaseAmount = (block.timestamp - lastWithdrawTime) * _totalToken / _releaseDuration;
        
        require(amount >= releaseAmount, "TokenTimelock: no tokens to release");

        lastWithdrawTime = block.timestamp;
        token().transfer(beneficiary(), releaseAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './TokenTimelock.sol';

/**
 * $PREY token contract
 */
contract Prey is ERC20, Ownable {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) public controllers;
  
  // the total amount allocated for developers
  uint constant developerTokenAmount = 600000000 ether;

  // the total amount allocated for community rewards
  uint constant communityTokenAmount = 2000000000 ether;

  // the total amount of tokens staked in the forest to yeild
  uint constant forestTokenAmount = 2400000000 ether;
  
  // the amount of $PREY tokens community has yielded
  uint mintedByCommunity;
  // the amount of $PREY tokens staked and yielded in the forest
  uint mintedByForest;

  /**
   * Contract constructor function
   * @param developerAccount The address that receives locked $PREY rewards for developers, in total 600 million
   */
  constructor(address developerAccount) ERC20("Prey", "PREY") {

    // create contract to lock $PREY token for 2 years (732 days in total) for developers, after which there is a 10 months(300 days in total) vesting schedule to release 600 million tokens
    TokenTimelock timelock = new TokenTimelock(this, developerAccount, block.timestamp + 732 days, 300 days, developerTokenAmount);
    _mint(address(timelock), developerTokenAmount);
    controllers[_msgSender()] = true;
  }
  /**
   * the function mints $PREY tokens to community members, effectively controls maximum yields
   * @param account mint $PREY to account
   * @param amount $PREY amount to mint
   */
  function mintByCommunity(address account, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    require(mintedByCommunity + amount <= communityTokenAmount, "No mint out");
    mintedByCommunity = mintedByCommunity + amount;
    _mint(account, amount);
  }

  /**
   * the function mints $PREY tokens to community members, effectively controls maximum yields
   * @param accounts mint $PREY to accounts
   * @param amount $PREY amount to mint
   */
  function mintsByCommunity(address[] calldata accounts, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    require(mintedByCommunity + (amount * accounts.length) <= communityTokenAmount, "No mint out");
    mintedByCommunity = mintedByCommunity + (amount * accounts.length);
    for (uint256 i = 0; i < accounts.length; i++) {
      _mint(accounts[i], amount);
    }
  }

  /**
   * the function mints $PREY tokens by the forest, effectively controls maximum yields
   * @param account mint $PREY to account
   * @param amount $PREY amount to mint
   */
  function mintByForest(address account, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    require(mintedByForest + amount <= forestTokenAmount, "No mint out");
    mintedByForest = mintedByForest + amount;
    _mint(account, amount);
  }

  /**
   * burn $PREY token by controller
   * @param account account holds $PREY token
   * @param amount the amount of $PREY token to burn
   */
  function burn(address account, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    _burn(account, amount);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './LotteryBox.sol';
import "./HunterHound.sol";


contract Mintor is LotteryBox {

  event MintEvent(address indexed operator, uint hunters, uint hounds, uint256[] tokenIds);

  struct Minting {
    uint blockNumber;
    uint amount;
  }

  // the cost to mint in every phase
  uint256 constant MINT_PRICE = .067 ether;
  uint256 constant MINT_PHASE2_PRICE = 40000 ether;
  uint256 constant MINT_PHASE3_PRICE = 60000 ether;
  uint256 constant MINT_PHASE4_PRICE = 80000 ether;

  // the amount corresponds to every hunter's alpha score
  uint constant maxAlpha8Count = 500;
  uint constant maxAlpha7Count = 1500;
  uint constant maxAlpha6Count = 3000;
  uint constant maxAlpha5Count = 5000;

  // 50,000 tokens in total and mint amount in every phase
  uint constant MAX_TOKENS = 50000;
  uint constant PHASE1_AMOUNT = 10000;
  uint constant PHASE2_AMOUNT = 10000;
  uint constant PHASE3_AMOUNT = 20000;
  uint constant PHASE4_AMOUNT = 10000;


  // saves metadataID for next hunter
  uint private alpha8Count = 1;
  uint private alpha7Count = 1;
  uint private alpha6Count = 1;
  uint private alpha5Count = 1;

  // saves metadataId for next hound
  uint internal totalHoundMinted = 1;

  // saves mint request of users
  mapping(address => Minting) internal mintRequests;

  // total minted amount
  uint256 internal minted;

  // total minted number of hunters
  uint256 internal hunterMinted;

  // recorded mint requests
  uint internal requested;

  /**
   * check mint request
   * @return blockNumber mint request block
   * @return amount mint amount
   * @return state mint state
   * @return open NFT reavel countdown
   * @return timeout NFT request reveal timeout countdown
   */
  function _mintRequestState(address requestor) internal view returns (uint blockNumber, uint amount, uint state, uint open, uint timeout) {
    Minting memory req = mintRequests[requestor];
    blockNumber = req.blockNumber;
    amount = req.amount;
    state = boxState(req.blockNumber);
    open = openCountdown(req.blockNumber);
    timeout = timeoutCountdown(req.blockNumber);
  }

  /**
   * create mint request, record requested block and data
   */
  function _request(address requestor, uint amount) internal {

    require(mintRequests[requestor].blockNumber == 0, 'Request already exists');
    
    mintRequests[requestor] = Minting({
      blockNumber: block.number,
      amount: amount
    });

    requested = requested + amount;
  }

  /**
   * process mint request to get random number, through which to determine hunter or hound
   */
  function _receive(address requestor, HunterHound hh) internal {
    Minting memory minting = mintRequests[requestor];
    require(minting.blockNumber > 0, "No mint request found");

    delete mintRequests[requestor];

    uint random = openBox(minting.blockNumber);
    uint boxResult = percentNumber(random);
    uint percent = boxResult;
    uint hunters = 0;
    uint256[] memory tokenIds = new uint256[](minting.amount);
    for (uint256 i = 0; i < minting.amount; i++) {
      HunterHoundTraits memory traits;
      if (i > 0 && boxResult > 0) {
        random = simpleRandom(percent);
        percent = percentNumber(random);
      }
      if (percent == 0) {
        traits = selectHound();
      } else if (percent >= 80) {
        traits = selectHunter(random);
      } else {
        traits = selectHound();
      }
      minted = minted + 1;
      hh.mintByController(requestor, minted, traits);
      tokenIds[i] = minted;
      if (traits.isHunter) {
        hunters ++;
      }
    }
    if (hunters > 0) {
      hunterMinted = hunterMinted + hunters;
    }
    emit MintEvent(requestor, hunters, minting.amount - hunters, tokenIds);
  }

  /**
   *  return a hunter, if hunters run out, return a hound
   * @param random make parameter random a random seed to generate another random number to determine alpha score of a hunter
   *               if number of hunters with corresponding alpha score runs out, it chooses the one with alpha score minus one util it runs out, otherwise it will be a hound
   *
   * probabilities of hunters with different alpha score and their numbers:
   * alpha 8: 5%   500
   * alpha 7: 15%  1500
   * alpha 6: 30%  3000
   * alpha 5: 50%  5000
   */
  function selectHunter(uint random) private returns(HunterHoundTraits memory hh) {
    
    random = simpleRandom(random);
    uint percent = percentNumber(random);
    if (percent <= 5 && alpha8Count <= maxAlpha8Count) {
      hh.alpha = 8;
      hh.metadataId = alpha8Count;
      alpha8Count = alpha8Count + 1;
    } else if (percent <= 20 && alpha7Count <= maxAlpha7Count) {
      hh.alpha = 7;
      hh.metadataId = alpha7Count;
      alpha7Count = alpha7Count + 1;
    } else if (percent <= 50 && alpha6Count <= maxAlpha6Count) {
      hh.alpha = 6;
      hh.metadataId = alpha6Count;
      alpha6Count = alpha6Count + 1;
    } else if (alpha5Count <= maxAlpha5Count) {
      hh.alpha = 5;
      hh.metadataId = alpha5Count;
      alpha5Count = alpha5Count + 1;
    } else {
      return selectHound();
    }
    hh.isHunter = true;

  }

  /**
   * return a hound
   */
  function selectHound() private returns(HunterHoundTraits memory hh) {
    hh.isHunter = false;
    hh.metadataId = totalHoundMinted;
    totalHoundMinted = totalHoundMinted + 1;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LotteryBox {

  // take 3 blocks' hash values to make a random seed
  uint constant SEED_BLOCK_HASH_AMOUNT = 3;
  
  // blackhash can only retrieve the most recent 256 blocks' hash values
  uint constant MAX_BLOCK_HASH_DISTANCE = 256;


  /**
   * generate a simple random number using the parameter
   */
  function simpleRandom(uint seed) internal view returns(uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      block.timestamp,
      seed
    )));
  }

  /**
   * Using the hashes of `SEED_BLOCK_HASH_AMOUNT` previously generated blocks as random seed to generate a random number, based on height of the request block
   */
  function randomNumber(uint requestBlockNumber, uint seed) internal view returns (uint256) {
    bytes32[SEED_BLOCK_HASH_AMOUNT] memory blockhashs;
    for (uint i = 0; i < SEED_BLOCK_HASH_AMOUNT; i++) {
      blockhashs[i] = blockhash(requestBlockNumber+1+i);
    }
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhashs,
      seed
    )));
  }

  /**
   * request status 
   */
  function boxState(uint requestBlockNumber) internal view returns (uint) {
    if (requestBlockNumber == 0) {
      return 0; // not requested
    }
    if (openCountdown(requestBlockNumber) > 0) {
      return 1; // waiting for reveal
    }
    if (timeoutCountdown(requestBlockNumber) > 0) {
      return 2; // waiting to reveal the result
    }

    return 3; // timeout
  }

  /**
   * reveal countdown
   */
  function openCountdown(uint requestBlockNumber) internal view returns(uint) {
    return countdown(requestBlockNumber, SEED_BLOCK_HASH_AMOUNT+1);
  }

  /**
   * timeout countdown
   */
  function timeoutCountdown(uint requestBlockNumber) internal view returns(uint) {
    return countdown(requestBlockNumber, MAX_BLOCK_HASH_DISTANCE+1);
  }

  /**
   * calculate countdown
   */
  function countdown(uint requestBlockNumber, uint v) internal view returns(uint) {
    uint diff = block.number - requestBlockNumber;
    if (diff > v) {
      return 0;
    }
    return v - diff;
  }

  /**
   * convert big random number into less or equal to 100 random number
   */
  function percentNumber(uint random) internal pure returns(uint) {
    if (random > 0) {
      return (random % 100) + 1;
    }
    return 0;
  }

  /**
   * generate big random number through block height
   */
  function openBox(uint requestBlockNumber) internal view returns (uint) {
    
    require(openCountdown(requestBlockNumber) == 0, "Invalid block number");

    
    if (timeoutCountdown(requestBlockNumber) > 0) {
      
      return randomNumber(requestBlockNumber, 0);
    } else {
     
      return 0;
    }

  }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct HunterHoundTraits {

  bool isHunter;
  uint alpha;
  uint metadataId;
}
uint constant MIN_ALPHA = 5;
uint constant MAX_ALPHA = 8;
contract HunterHound is ERC721Enumerable, Ownable {

  using Strings for uint256;

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) public controllers;

  // save token traits
  mapping(uint256 => HunterHoundTraits) private tokenTraits;

  //the base url for metadata
  string baseUrl = "ipfs://QmZWmcX4jRVZtQGQY64U26wkA83QNB1msZUhjqxJEyfaWP/";

  constructor() ERC721("HunterHound","HH") {

  }

  /**
   * set base URL for metadata
   */
  function setBaseUrl(string calldata baseUrl_) external onlyOwner {
    baseUrl = baseUrl_;
  }

  /**
   * get token traits
   */
  function getTokenTraits(uint256 tokenId) external view returns (HunterHoundTraits memory) {
    return tokenTraits[tokenId];
  }

  /**
   * get multiple token traits
   */
  function getTraitsByTokenIds(uint256[] calldata tokenIds) external view returns (HunterHoundTraits[] memory traits) {
    traits = new HunterHoundTraits[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      traits[i] = tokenTraits[tokenIds[i]];
    }
  }
  /**
   * Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    HunterHoundTraits memory s = tokenTraits[tokenId];

    return string(abi.encodePacked(
      baseUrl,
      s.isHunter ? 'Hunter' : 'Hound',
      '-',
      s.alpha.toString(),
      '/',
      s.isHunter ? 'Hunter' : 'Hound',
      '-',
      s.alpha.toString(),
      '-',
      s.metadataId.toString(),
      '.json'
    ));
  }

  /**
   * return holder's entire tokens
   */
  function tokensByOwner(address owner) external view returns (uint256[] memory tokenIds, HunterHoundTraits[] memory traits) {
    uint totalCount = balanceOf(owner);
    tokenIds = new uint256[](totalCount);
    traits = new HunterHoundTraits[](totalCount);
    for (uint256 i = 0; i < totalCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
      traits[i] = tokenTraits[tokenIds[i]];
    }
  }

  /**
   * return token traits
   */
  function isHunterAndAlphaByTokenId(uint256 tokenId) external view returns (bool, uint) {
    HunterHoundTraits memory traits = tokenTraits[tokenId];
    return (traits.isHunter, traits.alpha);
  }

  /**
   * controller to mint a token
   */
  function mintByController(address account, uint256 tokenId, HunterHoundTraits calldata traits) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    tokenTraits[tokenId] = traits;
    _safeMint(account, tokenId);
  }

  /**
   * controller to transfer a token
   */
  function transferByController(address from, address to, uint256 tokenId) external {
    require(controllers[_msgSender()], "Only controllers can transfer");
    _transfer(from, to, tokenId);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './LotteryBox.sol';
import './HunterHound.sol';
import './Prey.sol';

contract Forest is LotteryBox {

  event StakeEvent(address indexed operator, uint256[][] pairs);
  event ClaimEvent(address indexed operator, uint256 receiveProfit, uint256 totalProfit);
  event UnstakeEvent(address indexed operator, address indexed recipient, uint256 indexed tokenId, uint256 receiveProfit, uint256 totalProfit);

  struct Stake{
    uint timestamp;
    bool hunter;
    uint hounds;
    uint alpha;
    uint256[] tokenIds;
  }
  uint constant GAMBLE_CLAIM = 1;
  uint constant GAMBLE_UNSTAKE = 2;
  uint constant GAMBLE_UNSTAKE_GREDDY = 3;
  // action 1:claim 2:unstake 3:unstake with greddy
  struct Gamble {
    uint action;
    uint blockNumber;
  }

  // the minimum amount of $PREY tokens to own before unstaking
  uint constant MINIMUN_UNSTAKE_AMOUNT = 20000 ether; 
  // every hound receives 10,000 tokens a day
  uint constant PROFIT_PER_SINGLE_HOUND = 10000 ether;

  // the total profit
  uint constant TOTAL_PROFIT = 2400000000 ether;

  // the total claimed $PREY including burned in the game
  uint internal totalClaimed; 
  // the total bunred $PREY
  uint internal totalBurned;

  // staked list
  mapping(address => Stake[]) internal stakes;

  // record original owner of the token
  mapping(uint => address) internal tokenOwners;

  // record tokenId of the hunters who have corresponding alpha score
  mapping(uint256 => uint256[]) internal hunterAlphaMap;

  // record index of hunter tokenId in `hunterAlphaMap`
  mapping(uint256 => uint256) internal hunterTokenIndices;

  // staked hounds count
  uint internal houndStaked;
  // staked hunters count
  uint internal hunterStaked;
  // the number of hounds adopted by other hunters
  uint internal houndsCaptured;

  mapping(address => Gamble) internal gambleRequests;


  /**
   * When there is a gamble request
   */
  modifier whenGambleRequested() {
      require(gambleRequests[msg.sender].blockNumber == 0, "Unstake or claim first");
      _;
  }

  /**
   * stake submitted tokens group and transfer to the staking contract
   */
  function _stake(address owner, uint256[][] calldata pairs, HunterHound hh) internal whenGambleRequested {

    require(pairs.length > 0, "Tokens empty");
    require(totalClaimed < TOTAL_PROFIT, "No profit");

    uint totalHunter = 0;
    uint totalHounds = 0;
    
    (totalHunter, totalHounds) = _storeStake(owner, pairs, hh);

    hunterStaked = hunterStaked + totalHunter;
    houndStaked = houndStaked + totalHounds;

    // transfer token
    for (uint256 i = 0; i < pairs.length; i++) {
      for (uint256 j = 0; j < pairs[i].length; j++) {
        uint256 tokenId = pairs[i][j];
        hh.transferByController(owner, address(this), tokenId);
      }
    }
    emit StakeEvent(owner, pairs);
  }

  /**
   * store staking groups
   */
  function _storeStake(address owner, uint256[][] calldata paris, HunterHound hh) private returns(uint totalHunter, uint totalHounds) {
    for (uint256 i = 0; i < paris.length; i++) {
      uint256[] calldata tokenIds = paris[i];
      uint hunters;
      uint hounds;
      uint256 hunterAlpha;
      uint hunterIndex = 0;
      (hunters, hounds, hunterAlpha, hunterIndex) = _storeTokenOwner(owner, tokenIds, hh);
      require(hounds > 0 && hounds <= 3, "Must have 1-3 hound in a pair");
      require(hunters <= 1, "Only be one hunter in a pair");
      
      // in order to select a hound, a hunter must be placed in the rear of the group
      require(hunters == 0 || hunterIndex == (tokenIds.length-1), "Hunter must be last one");
      totalHunter = totalHunter + hunters;
      totalHounds = totalHounds + hounds;
      stakes[owner].push(Stake({
        timestamp: block.timestamp,
        hunter: hunters > 0,
        hounds: hounds,
        alpha: hunterAlpha,
        tokenIds: tokenIds
      }));

      if (hunters > 0) {
        uint256 hunterTokenId = tokenIds[tokenIds.length-1];
        hunterTokenIndices[hunterTokenId] = hunterAlphaMap[hunterAlpha].length;
        hunterAlphaMap[hunterAlpha].push(hunterTokenId);
      }
    }
  }

  /**
   * record token owner in order to return $PREY token correctly to the owner in case of unstaking
   */
  function _storeTokenOwner(address owner, uint[] calldata tokenIds, HunterHound hh) private 
    returns(uint hunters,uint hounds,uint hunterAlpha,uint hunterIndex) {
    for (uint256 j = 0; j < tokenIds.length; j++) {
        uint256 tokenId = tokenIds[j];
        require(tokenOwners[tokenId] == address(0), "Unstake first");
        require(hh.ownerOf(tokenId) == owner, "Not your token");
        bool isHunter;
        uint alpha;
        (isHunter, alpha) = hh.isHunterAndAlphaByTokenId(tokenId);

        if (isHunter) {
          hunters = hunters + 1;
          hunterAlpha = alpha;
          hunterIndex = j;
        } else {
          hounds = hounds + 1;
        }
        tokenOwners[tokenId] = owner;
      }
  }
  
  /**
   * calculate and claim staked reward, if the players chooses to gamble, there's a probability to lose all rewards
   */
  function _claim(address owner, Prey prey) internal {

    uint requestBlockNumber = gambleRequests[owner].blockNumber;
    uint totalProfit = _claimProfit(owner, false);
    uint receiveProfit;
    if (requestBlockNumber > 0) {
      require(gambleRequests[owner].action == GAMBLE_CLAIM, "Unstake first");
      uint random = openBox(requestBlockNumber);
      uint percent = percentNumber(random);
      if (percent <= 50) {
        receiveProfit = 0;
      } else {
        receiveProfit = totalProfit;
      }
      delete gambleRequests[owner];
    } else {
      receiveProfit = (totalProfit * 80) / 100;
    }

    if (receiveProfit > 0) {
      prey.mintByForest(owner, receiveProfit);
    }
    if (totalProfit - receiveProfit > 0) {
      totalBurned = totalBurned + (totalProfit - receiveProfit);
    }
    emit ClaimEvent(owner, receiveProfit, totalProfit);
  }

  /**
   * calculate stake rewards, reset timestamp in case of claiming
   */
  function _collectStakeProfit(address owner, bool unstake) private returns (uint profit) {
    for (uint i = 0; i < stakes[owner].length; i++) {
      Stake storage stake = stakes[owner][i];
      
      profit = profit + _caculateProfit(stake);
      if (!unstake) {
        stake.timestamp = block.timestamp;
      }
    }
    
    require(unstake == false || profit >= MINIMUN_UNSTAKE_AMOUNT, "Minimum claim is 20000 PREY");
  }
  
  /**
   * return claimable staked rewards, update `totalClaimed`
   */
  function _claimProfit(address owner, bool unstake) private returns (uint) {
    uint profit = _collectStakeProfit(owner, unstake);
    
    if (totalClaimed + profit > TOTAL_PROFIT) {
      profit = TOTAL_PROFIT - totalClaimed;
    }
    totalClaimed = totalClaimed + profit;
    
    return profit;
  }

  /**
   * create a gamble request in case of unstaking or claim with gambling
   */
  function _requestGamble(address owner, uint action) internal whenGambleRequested {

    require(stakes[owner].length > 0, 'Stake first');
    require(action == GAMBLE_CLAIM || action == GAMBLE_UNSTAKE || action == GAMBLE_UNSTAKE_GREDDY, 'Invalid action');
    if (action != GAMBLE_CLAIM) {
      _collectStakeProfit(owner, true);
    }
    gambleRequests[owner] = Gamble({
      action: action,
      blockNumber: block.number
    });
  }

  /**
   * return gamble request status
   */
  function _gambleRequestState(address requestor) internal view returns (uint blockNumber, uint action, uint state, uint open, uint timeout) {
    Gamble memory req = gambleRequests[requestor];
    blockNumber = req.blockNumber;
    action = req.action;
    state = boxState(req.blockNumber);
    open = openCountdown(req.blockNumber);
    timeout = timeoutCountdown(req.blockNumber);
  }

  
  /**
   * claim all profits and take back staked tokens in case of unstaking
   * 20% chance to lose one of the hounds and adopted by other hunter
   * if players chooses to gamble, 50% chance to burn all the profits
   */
  function _unstake(address owner, Prey prey, HunterHound hh) internal {
    uint requestBlockNumber = gambleRequests[owner].blockNumber;
    require(requestBlockNumber > 0, "No unstake request found");
    uint action = gambleRequests[owner].action;
    require(action == GAMBLE_UNSTAKE || action == GAMBLE_UNSTAKE_GREDDY, "Claim first");

    uint256 totalProfit = _claimProfit(owner, true);

    uint random = openBox(requestBlockNumber);
    uint percent = percentNumber(random);

    address houndRecipient;
    if (percent <= 20) {
      //draw a player who has a hunter in case of losing
      houndRecipient= selectLuckyRecipient(owner, percent);
      if (houndRecipient != address(0)) {
        houndsCaptured = houndsCaptured + 1;
      }
    }

    uint receiveProfit = totalProfit;
    if (action == GAMBLE_UNSTAKE_GREDDY) {
      // 50/50 chance to lose all or take all
      if (percent > 0) {
        random = randomNumber(requestBlockNumber, random);
        percent = percentNumber(random);
        if (percent <= 50) {
          receiveProfit = 0;
        }
      } else {
          receiveProfit = 0;
      }
    } else {
      receiveProfit = (receiveProfit * 80) / 100;
    }


    delete gambleRequests[owner];

    uint totalHunter = 0;
    uint totalHound = 0;
    uint256 capturedTokenId;
    (totalHunter, totalHound, capturedTokenId) = _cleanOwner(percent, owner, hh, houndRecipient);
    
    hunterStaked = hunterStaked - totalHunter;
    houndStaked = houndStaked - totalHound;
    delete stakes[owner];

    if (receiveProfit > 0) {
      prey.mintByForest(owner, receiveProfit);
    }

    if (totalProfit - receiveProfit > 0) {
      totalBurned = totalBurned + (totalProfit - receiveProfit);
    }
    emit UnstakeEvent(owner, houndRecipient, capturedTokenId, receiveProfit, totalProfit);
  }

  /**
   * delete all data on staking, if `houndRecipient` exists, use `percent` to generate a random number and choose a hound to transfer
   */
  function _cleanOwner(uint percent, address owner, HunterHound hh, address houndRecipient) private returns(uint totalHunter, uint totalHound, uint256 capturedTokenId) {
    uint randomRow = percent % stakes[owner].length;
    for (uint256 i = 0; i < stakes[owner].length; i++) {
      Stake memory stake = stakes[owner][i];
      totalHound = totalHound + stake.tokenIds.length;
      if (stake.hunter) {
        totalHunter = totalHunter + 1;
        totalHound = totalHound - 1;
        uint256 hunterTokenId = stake.tokenIds[stake.tokenIds.length-1];
        uint alphaHunterLength = hunterAlphaMap[stake.alpha].length;
        if (alphaHunterLength > 1 && hunterTokenIndices[hunterTokenId] < (alphaHunterLength-1)) {
          uint lastHunterTokenId = hunterAlphaMap[stake.alpha][alphaHunterLength - 1];
          hunterTokenIndices[lastHunterTokenId] = hunterTokenIndices[hunterTokenId];
          hunterAlphaMap[stake.alpha][hunterTokenIndices[hunterTokenId]] = lastHunterTokenId;
        }
        
        hunterAlphaMap[stake.alpha].pop();
        delete hunterTokenIndices[hunterTokenId];
      }
      
      for (uint256 j = 0; j < stake.tokenIds.length; j++) {
        uint256 tokenId = stake.tokenIds[j];
        
        delete tokenOwners[tokenId];
        
        // randomly select 1 hound
        if (i == randomRow && houndRecipient != address(0) && (stake.tokenIds.length == 1 || j == (percent % (stake.tokenIds.length-1)))) {
          hh.transferByController(address(this), houndRecipient, tokenId);
          capturedTokenId = tokenId;
        } else {
          hh.transferByController(address(this), owner, tokenId);
        }
      }
    }
  }

  /**
   * of all hunters staked, choose one to adopt the hound, hunter with higher alpha score takes precedence.
   * alpha 8: 50%
   * alpha 7: 30%
   * alpha 6: 15%
   * alpha 5: 5%
   */
  function selectLuckyRecipient(address owner, uint seed) private view returns (address) {
    uint random = simpleRandom(seed);
    uint percent = percentNumber(random);
    uint alpha;
    if (percent <= 5) {
      alpha = 5;
    } else if (percent <= 20) {
      alpha = 6;
    } else if (percent <= 50) {
      alpha = 7;
    } else {
      alpha = 8;
    }
    uint alphaCount = 4;
    uint startAlpha = alpha;
    bool directionUp = true;
    while(alphaCount > 0) {
      alphaCount --;
      uint hunterCount = hunterAlphaMap[alpha].length;
      if (hunterCount != 0) {
        
        uint index = random % hunterCount;
        uint count = 0;
        while(count < hunterCount) {
          if (index >= hunterCount) {
            index = 0;
          }
          address hunterOwner = tokenOwners[hunterAlphaMap[alpha][index]];
          if (owner != hunterOwner) {
            return hunterOwner;
          }
          index ++;
          count ++;
        }
      }
      if (alpha >= 8) {
        directionUp = false;
        alpha = startAlpha;
      } 
      if (directionUp) {
        alpha ++;
      } else {
        alpha --;
      }
    }

    return address(0);
  }

  /**
   * calculate the claimable profits of the stake 
   */
  function _caculateProfit(Stake memory stake) internal view returns (uint) {
    uint profitPerStake = 0;
    if (stake.hunter) {
      profitPerStake = ((stake.hounds * PROFIT_PER_SINGLE_HOUND) * (stake.alpha + 10)) / 10;
    } else {
      profitPerStake = stake.hounds * PROFIT_PER_SINGLE_HOUND;
    }

    return (block.timestamp - stake.timestamp) * profitPerStake / 1 days;
  }

  /**
   * take back all staked tokens in case of rescue mode
   */
  function _rescue(address owner, HunterHound hh) internal {
    delete gambleRequests[owner];
    uint totalHound = 0;
    uint totalHunter = 0;
    (totalHunter, totalHound, ) = _cleanOwner(0, owner, hh, address(0));
    delete stakes[owner];
    houndStaked = houndStaked - totalHound;
    hunterStaked = hunterStaked - totalHunter;
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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