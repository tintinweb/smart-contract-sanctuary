// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

import "./LinkTokenInterface.sol";
import "./WoolfReborn.sol";
import "./Barn.sol";
import "./WoolPouch.sol";

contract RiskyGame is 
  Initializable, 
  OwnableUpgradeable, 
  PausableUpgradeable
{

  /*

  Security notes
  ==============

  - Ignoring some Slither warnings regarding sanity checks in the initializer.
  - Ignoring Slither warnings about state changes after calls and usage of block timestamp as it's intended behavior.
  - The game logic trades off gas efficiency for precision. Supply will converge to approximately 2.4b tokens when everybody has claimed. If the number of sheep choosing yes risk is uneven and very small, the final amount will somewhat deviate from that number, but in practice the difference should be negligible.

  */

  bool public optInsEnabled;
  // 14000 tokens / 256 bits x 2 bits
  uint256[110] public tokenStates;

  uint128 public safeGameWool;
  uint128 public riskGameWool;
  uint128 constant TOTAL_GEN0_GEN1 = 13809;
  uint128 constant TOTAL_SHEEP = 12066;
  uint8 constant MAX_ALPHA = 8;
  uint128 constant TOTAL_ALPHA = 9901; 
  uint128 constant BARN_PAUSE_TIMESTAMP = 1637559109;
  uint128 constant MIGRATION_TIMESTAMP = 1638072344;
  uint128 public constant UNSTAKED_EARNINGS = (MIGRATION_TIMESTAMP - BARN_PAUSE_TIMESTAMP) * 10000 ether / 1 days; 
  uint128 constant TOTAL_UNSTAKED_EARNINGS = UNSTAKED_EARNINGS * 310; // NUMBER OF SHEEP THAT WERE UNSTAKED
  uint128 constant TOTAL_STAKED_EARNINGS = 786726742013904746845306880; // PULLED DIRECTLY FROM THE BLOCKCHAIN
  uint128 constant TOTAL_CLAIMED_WOOL = 230110840213821712918605852; // PULLED DIRECTLY FROM THE BLOCKCHAIN
  uint128 constant MAXIMUM_WOOL = 2400000000 ether;
  uint128 public totalRiskTakers;

  uint256 constant STATE_UNDECIDED = 0;
  uint256 constant STATE_OPTED_IN = 1;
  uint256 constant STATE_EXECUTED = 2;

  uint256 public randomSeed; // THIS VALUE WILL COME FROM CHAINLINK

  Woolf public woolf;
  WoolfReborn public woolfReborn;
  Barn public barn;
  WoolPouch public woolPouch;

  // Chainlink references
  LinkTokenInterface internal LINK;
  uint256 linkFee;
  address private vrfCoordinator;
  mapping(bytes32 => uint256) private nonces;

  event SafeClaim(
    address recipient,
    uint256[] tokenIds,
    uint256 amount
  );

  event OptForRisk(
    address owner,
    uint256[] tokenIds
  );

  event RiskyClaim(
    address recipient,
    uint256[] tokenIds,
    bool[] winners,
    uint256 amount
  );

  event WolfClaim(
    address recipient,
    uint256[] tokenIds,
    uint256 amount
  );

  /** 
   * initializes contract
   * @param _woolfReborn reference to WoolfReborn
   * @param _woolf reference to Woolf 
   * @param _barn reference to original Barn
   * @param _woolPouch reference to WoolPouch
   * @param _LINK reference to LINK token
   * @param _vrfCoordinator reference to Chainlink VRF coordinator
   */
  function initialize(
    address _woolfReborn, 
    address _woolf, 
    address _barn, 
    address _woolPouch,
    address _LINK,
    address _vrfCoordinator
  ) external initializer {
    __Ownable_init();
    __Pausable_init();

    woolfReborn = WoolfReborn(_woolfReborn);
    woolf = Woolf(_woolf);
    barn = Barn(_barn);
    woolPouch = WoolPouch(_woolPouch);

    LINK = LinkTokenInterface(_LINK);
    vrfCoordinator = _vrfCoordinator;

    riskGameWool = MAXIMUM_WOOL - TOTAL_CLAIMED_WOOL - TOTAL_STAKED_EARNINGS - TOTAL_UNSTAKED_EARNINGS;

    _pause();
    optInsEnabled = true;
    linkFee = 2 ether;
  }

  /** EXTERNAL */

  /**
   * opts into the No Risk option and claims WOOL Pouches
   * @param tokenIds the Sheep to opt in
   * @param separatePouches whether or not to give a single Pouch or one for each Sheep
   */
  function playItSafe(uint256[] calldata tokenIds, bool separatePouches) external whenNotPaused {
    uint128 earned;
    uint128 temp;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(woolfReborn.ownerOf(tokenIds[i]) == _msgSender(), "SWIPER NO SWIPING");
      require(tokenIds[i] <= TOTAL_GEN0_GEN1, "ONLY ORIGINALS CAN PLAY RISKY GAME");
      require(_isSheep(tokenIds[i]), "WOLVES CANT PLAY IT SAFE");
      require(getTokenState(tokenIds[i]) == STATE_UNDECIDED, "CANT CLAIM TWICE");
      temp = getWoolDue(tokenIds[i]);
      
      setTokenState(tokenIds[i], STATE_EXECUTED);
      if (separatePouches) {
        woolPouch.mint(_msgSender(), temp * 4 / 5, 365 * 4); // charge 20% tax
      }
      earned += temp;
    }

    safeGameWool += earned;
    if (!separatePouches) {
      woolPouch.mint(_msgSender(), earned * 4 / 5, 365 * 4); // charge 20% tax
    }
    emit SafeClaim(_msgSender(), tokenIds, earned);
  }

  /**
   * opts into the Yes Risk option
   * @param tokenIds the Sheep to opt in
   */
  function takeARisk(uint256[] calldata tokenIds) external whenNotPaused {
    require(optInsEnabled, "OPPORTUNITY TO TAKE RISK HAS PASSED");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(woolfReborn.ownerOf(tokenIds[i]) == _msgSender(), "SWIPER NO SWIPING");
      require(tokenIds[i] <= TOTAL_GEN0_GEN1, "ONLY ORIGINALS CAN PLAY RISKY GAME");
      require(_isSheep(tokenIds[i]), "WOLVES CANT TAKE THIS RISK");
      require(getTokenState(tokenIds[i]) == STATE_UNDECIDED, "CANT CLAIM TWICE");

      setTokenState(tokenIds[i], STATE_OPTED_IN);
      riskGameWool += getWoolDue(tokenIds[i]);
      totalRiskTakers += 1;
    }
    emit OptForRisk(_msgSender(), tokenIds);
  }

  /**
   * reveals the results of Yes Risk for Sheep and gives WOOL Pouches
   * @param tokenIds the Wolves to claim WOOL Pouches for
   * @param separatePouches whether or not to give a single Pouch or one for each Sheep
   */
  function executeRisk(uint256[] calldata tokenIds, bool separatePouches) external whenNotPaused {
    require(randomSeed != 0x0, "CANT EXECUTE YET");
    bool[] memory winners = new bool[](tokenIds.length);
    uint128 earned;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(woolfReborn.ownerOf(tokenIds[i]) == _msgSender(), "SWIPER NO SWIPING");
      require(tokenIds[i] <= TOTAL_GEN0_GEN1, "ONLY ORIGINALS CAN PLAY RISKY GAME");
      require(_isSheep(tokenIds[i]), "WOLVES CANT TAKE THIS RISK");
      require(getTokenState(tokenIds[i]) == STATE_OPTED_IN, "YOU DIDNT OPT FOR THE RISK");
      setTokenState(tokenIds[i], STATE_EXECUTED);
      if (!didSheepDefeatWolves(tokenIds[i])) continue;
      
      if (separatePouches) {
        woolPouch.mint(_msgSender(), riskGameWool / totalRiskTakers, 365 * 4);
      }
      earned += riskGameWool / totalRiskTakers;
      winners[i] = true;
    }

    if (!separatePouches && earned > 0) {
      woolPouch.mint(_msgSender(), earned, 365 * 4);
    }
    emit RiskyClaim(_msgSender(), tokenIds, winners, earned);
  }

  /**
   * claims the taxed and Yes Risk earnings for wolves in WOOL Pouches
   * @param tokenIds the Wolves to claim WOOL Pouches for
   * @param separatePouches whether or not to give a single Pouch or one for each Wolf
   */
  function claimWolfEarnings(uint256[] calldata tokenIds, bool separatePouches) external whenNotPaused {
    require(randomSeed != 0x0, "CANT EXECUTE YET");
    uint128 earned;
    uint128 alpha;
    uint128 temp;
    // amount in taxes is 20% of remainder after unclaimed wool from v1 and risk game
    uint128 taxes = (MAXIMUM_WOOL - riskGameWool - TOTAL_CLAIMED_WOOL) / 5;
    // if there are no sheep playing risk game, wolves win the whole pot
    uint128 totalWolfEarnings = taxes + riskGameWool / (totalRiskTakers > 0 ? 2 : 1); 
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(woolfReborn.ownerOf(tokenIds[i]) == _msgSender(), "SWIPER NO SWIPING");
      require(tokenIds[i] <= TOTAL_GEN0_GEN1, "ONLY ORIGINALS CAN PLAY RISKY GAME");
      require(!_isSheep(tokenIds[i]), "SHEEP DONT STEAL");
      require(getTokenState(tokenIds[i]) == STATE_UNDECIDED, "CANT CLAIM TWICE");
      setTokenState(tokenIds[i], STATE_EXECUTED);
      alpha = _alphaForWolf(tokenIds[i]);
      temp = totalWolfEarnings * alpha / TOTAL_ALPHA;
      earned += temp;
      if (separatePouches) {
        woolPouch.mint(_msgSender(), temp, 365 * 4);
      }
    } 
    if (!separatePouches && earned > 0) {
      woolPouch.mint(_msgSender(), earned, 365 * 4);
    }
    emit WolfClaim(_msgSender(), tokenIds, earned);
  }

  /**
   * gets the WOOL due for a Sheep based on their state before Barn v1 was paused
   * @param tokenId the Sheep to check the WOOL due for
   */
  function getWoolDue(uint256 tokenId) internal view returns (uint128) {
    if (woolf.ownerOf(tokenId) == address(barn)) {
      // Sheep that were staked earn all their earnings up until the migration
      ( , uint80 value, ) = barn.barn(tokenId);
      return (MIGRATION_TIMESTAMP - value) * 10000 ether / 1 days; 
    } else {
      // Sheep that were not staked receive what they would have earned between the pause and migration
      return UNSTAKED_EARNINGS;
    }
  }

  function didSheepDefeatWolves(uint256 tokenId) public view returns (bool) {
    return uint256(keccak256(abi.encodePacked(tokenId, randomSeed))) & 1 == 1; // 50/50
  }

  function _isSheep(uint256 tokenId) public view returns (bool sheep) {
    (sheep, , , , , , , , , ) = woolf.tokenTraits(tokenId);
  }

  function _alphaForWolf(uint256 tokenId) internal view returns (uint8) {
    ( , , , , , , , , , uint8 alphaIndex) = woolf.tokenTraits(tokenId);
    return MAX_ALPHA - alphaIndex; // alpha index is 0-3
  }

  /**
   * gets the token's state from a 256 bit integer
   */
  function getTokenState(uint256 tokenId) public view returns (uint256 selection) {
    uint256 packed = tokenStates[tokenId / 128];
    return (packed >> ((tokenId % 128) * 2)) & 0x3;
  }

  /**
   * packs the token's state into a 256 bit integer to save gas
   */
  function setTokenState(uint256 tokenId, uint256 state) internal {
    uint256 packed = tokenStates[tokenId / 128];
    uint256 position = (tokenId % 128) * 2;
    tokenStates[tokenId / 128] = ((packed & ~(0x3 << position)) | (state << position));
  }

  /** ADMIN */

  /**
   * begins risky game by getting a random number from Chainlink
   */
  function initiateRiskGame() external onlyOwner {
    optInsEnabled = false;
    requestRandomness(
      0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445, 
      linkFee
    );
  }

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function updateLinkFee(uint256 fee) external onlyOwner {
    linkFee = fee;
  }

  /** CHAINLINK */
  
  // made compatible with upgradeability from here: 
  // https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/VRFConsumerBase.sol

  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, 0));
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, 0, address(this), nonces[_keyHash]); //USER_SEED
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  function rawFulfillRandomness(bytes32, uint256 randomness) external {
    require(_msgSender() == vrfCoordinator, "Only VRFCoordinator can fulfill");
    require(randomSeed == 0x0, "Randomness already set");
    randomSeed = randomness;
  }

  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}