// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Math.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./BEP20.sol";
import "./BHeroDetails.sol";
import "./IBHeroDesign.sol";

// Use with Chainlink VRF.
// import "./RandomGenerator.sol";

contract BHeroToken is ERC721Upgradeable, AccessControlUpgradeable {
  struct CreateTokenRequest {
    // Use with Chainlink VRF.
    // bytes32 requestId; // For Chainlink VRF request ID.
    // uint32 orderId; // Differentiate with other requests with the same request ID.

    uint256 targetBlock; // Use future block.
    uint16 count; // Amount of tokens to mint.
    uint8 rarity; // 0: random rarity, 1 - 6: specified rarity.
  }

  using Counters for Counters.Counter;
  using BHeroDetails for BHeroDetails.Details;

  // Use with Chainlink VRF.
  // event TokenCreateRequested(bytes32 requestId);
  // event TokenCreateFulfilled(bytes32 requestId);

  event TokenCreateRequested(address to, uint256 block);
  event TokenCreated(address to, uint256 tokenId, uint256 details);

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
  bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  // Use with Chainlink VRF.
  // bytes32 public constant RANDOM_CREATOR_ROLE = keccak256("RANDOM_CREATOR_ROLE");
  // bytes32 public constant RANDOM_GENERATOR_ROLE = keccak256("RANDOM_GENERATOR_ROLE");

  uint256 private constant maskLast8Bits = uint256(0xff);
  uint256 private constant maskFirst248Bits = ~uint256(0xff);

  IBEP20 public coinToken;
  Counters.Counter public tokenIdCounter;

  // Mapping from owner address to token ID.
  mapping(address => uint256[]) public tokenIds;

  // Mapping from token ID to token details.
  mapping(uint256 => uint256) public tokenDetails;

  // Mapping from owner address to claimable token count.
  mapping(address => mapping(uint256 => uint256)) public claimableTokens;

  // Mapping from owner address to token requests.
  mapping(address => CreateTokenRequest[]) public tokenRequests;

  IBHeroDesign public design;

  // Use with Chainlink VRF.
  // IRandomGenerator public randomGenerator;

  function initialize(IBEP20 coinToken_) public initializer {
    __ERC721_init("Bomber Hero", "BHERO");
    __AccessControl_init();
    //__Pausable_init();
    //__UUPSUpgradeable_init();
    coinToken = coinToken_;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(PAUSER_ROLE, msg.sender);
    _setupRole(UPGRADER_ROLE, msg.sender);
    _setupRole(DESIGNER_ROLE, msg.sender);
    _setupRole(CLAIMER_ROLE, msg.sender);

    // Use with Chainlink VRF.
    // _setupRole(RANDOM_CREATOR_ROLE, msg.sender);
  }

  //function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    coinToken.transfer(msg.sender, coinToken.balanceOf(address(this)));
  }

  // Use with Chainlink VRF.
  /** Sets the random generator. */
  // function createRandomGenerator() external onlyRole(RANDOM_CREATOR_ROLE) {
  //   randomGenerator = new RandomGenerator();
  //   _setupRole(RANDOM_GENERATOR_ROLE, address(randomGenerator));
  // }

  /** Sets the design. */
  function setDesign(address contractAddress) external onlyRole(DESIGNER_ROLE) {
    design = IBHeroDesign(contractAddress);
  }

  /** Gets token details for the specified owner. */
  function getTokenDetailsByOwner(address to) external view returns (uint256[] memory) {
    uint256[] storage ids = tokenIds[to];
    uint256[] memory result = new uint256[](ids.length);
    for (uint256 i = 0; i < ids.length; ++i) {
      result[i] = tokenDetails[ids[i]];
    }
    return result;
  }

  struct Recipient {
    address to;
    uint256 count;
  }

  /** Increase claimable tokens. */
  function increaseClaimableTokens(Recipient[] memory recipients, uint256 rarity) external onlyRole(CLAIMER_ROLE) {
    for (uint256 i = 0; i < recipients.length; ++i) {
      claimableTokens[recipients[i].to][rarity] += recipients[i].count;
    }
  }

  function decreaseClaimableTokens(Recipient[] memory recipients, uint256 rarity) external onlyRole(CLAIMER_ROLE) {
    for (uint256 i = 0; i < recipients.length; ++i) {
      claimableTokens[recipients[i].to][rarity] -= recipients[i].count;
    }
  }

  function getClaimableTokens(address to) external view returns (uint256) {
    uint256 result;
    for (uint256 i = 0; i <= 6; ++i) {
      result += claimableTokens[to][i];
    }
    return result;
  }

  /** Mints tokens. */
  function mint(uint256 count) external {
    require(count > 0, "No token to mint");

    // Check limit.
    address to = msg.sender;
    require(tokenIds[to].length + count <= design.getTokenLimit(), "User limit reached");

    // Transfer coin token.
    coinToken.transferFrom(to, address(this), design.getMintCost() * count);

    // Create requests.
    requestCreateToken(to, count, BHeroDetails.ALL_RARITY);
  }

  /** Requests a create token request. */
  function requestCreateToken(
    address to,
    uint256 count,
    uint256 rarity
  ) internal {
    // Use with Chainlink VRF.
    // Request randomness.
    // bytes32 requestId;
    // uint256 orderId;
    // (requestId, orderId) = randomGenerator.requestRandom();

    // Create request.
    uint256 targetBlock = block.number + 5;
    tokenRequests[to].push(CreateTokenRequest(targetBlock, uint16(count), uint8(rarity)));

    // Use with Chainlink VRF.
    // emit TokenCreateRequested(requestId);

    emit TokenCreateRequested(to, targetBlock);
  }

  // Use with Chainlink VRF.
  /** Called by random generator. */
  // function requestRandomFulfilled(bytes32 requestId) external override onlyRole(RANDOM_GENERATOR_ROLE) {
  //   emit TokenCreateFulfilled(requestId);
  // }

  /** Gets the number of tokens that can be processed at the moment. */
  function getPendingTokens(address to) external view returns (uint256) {
    uint256 result;
    CreateTokenRequest[] storage requests = tokenRequests[to];
    for (uint256 i = 0; i < requests.length; ++i) {
      CreateTokenRequest storage request = requests[i];
      if (block.number > request.targetBlock) {
        result += request.count;
      } else {
        break;
      }
    }
    return result;
  }

  /** Gets the number of tokens that can be processed.  */
  function getProcessableTokens(address to) external view returns (uint256) {
    uint256 result;
    CreateTokenRequest[] storage requests = tokenRequests[to];
    for (uint256 i = 0; i < requests.length; ++i) {
      result += requests[i].count;
    }
    return result;
  }

  /** Processes token requests. */
  function processTokenRequests() external {
    address to = msg.sender;
    uint256 size = tokenIds[to].length;
    uint256 limit = design.getTokenLimit();
    require(size < limit, "User limit reached");

    uint256 available = limit - size;
    CreateTokenRequest[] storage requests = tokenRequests[to];
    for (uint256 i = requests.length; i > 0; --i) {
      CreateTokenRequest storage request = requests[i - 1];

      // Use with Chainlink VRF.
      // uint256 seed = randomGenerator.getResult(request.requestId, request.orderId);

      uint256 targetBlock = request.targetBlock;
      require(block.number > targetBlock, "Target block not arrived");
      uint256 seed = uint256(blockhash(targetBlock));
      uint256 rarity = request.rarity;
      if (seed == 0) {
        if (rarity == BHeroDetails.ALL_RARITY) {
          // Expired, forced common.
          rarity = 1;
        }

        // Re-roll seed.
        targetBlock = (block.number & maskFirst248Bits) + (targetBlock & maskLast8Bits);
        if (targetBlock >= block.number) {
          targetBlock -= 256;
        }
        seed = uint256(blockhash(targetBlock));
      }

      if (available < request.count) {
        request.count -= uint16(available);
        createToken(to, available, rarity, seed);
        break;
      }
      available -= request.count;
      createToken(to, request.count, rarity, seed);
      requests.pop();
      if (available == 0) {
        break;
      }
    }
  }

  /** Creates token(s) with a random seed. */
  function createToken(
    address to,
    uint256 count,
    uint256 rarity,
    uint256 seed
  ) internal {
    uint256 details;
    for (uint256 i = 0; i < count; ++i) {
      uint256 id = tokenIdCounter.current();
      uint256 tokenSeed = uint256(keccak256(abi.encode(seed, id)));
      (, details) = design.createRandomToken(tokenSeed, id, rarity);
      tokenIdCounter.increment();
      tokenDetails[id] = details;
      _safeMint(to, id);
      emit TokenCreated(to, id, details);
    }
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    require(false, "Temporarily disabled");
    ERC721Upgradeable._transfer(from, to, tokenId);
  }

  
}