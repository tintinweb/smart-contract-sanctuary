// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IGardenerAndFarmer.sol";
import "./GardenerAndFarmer.sol";
import "./interfaces/IBurnableToken.sol";
import "./interfaces/IField.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/Array.sol";

contract Field is Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
  using Array for uint256[];
  // Maximum score for a Farmer
  uint8 public constant MAX_SCORE = 8;

  event TokenStaked(
    bool indexed isGardener,
    address indexed owner,
    uint256 indexed tokenId,
    uint256 value
  );
  event GardenerClaimed(
    uint256 indexed tokenId,
    bool indexed unstaked,
    uint256 earned
  );
  event FarmerClaimed(
    uint256 indexed tokenId,
    bool indexed unstaked,
    uint256 earned
  );

  // Reference to the GardenerAndFarmer NFT contract
  GardenerAndFarmer private game;
  // Reference to the $SEED contract for minting $SEED earnings
  IBurnableToken private seedToken;

  // maps tokenId to stake
  mapping(uint256 => Stake) public field;
  // maps score to all Farmer stakes with that score
  mapping(uint256 => Stake[]) public pack;
  // tracks location of each Farmer in Pack
  mapping(uint256 => uint256) public packIndices;
  // Owner => Staked token ids belonging to that owner
  mapping(address => uint256[]) private ownerToTokenIds;
  // total scores staked
  uint256 public totalScoreStaked = 0;
  // any rewards distributed when no Farmers are staked
  uint256 public unaccountedRewards = 0;
  // amount of $SEED due for each score point staked
  uint256 public seedPerScore = 0;

  // Gardeners earn 10000 $SEED per day
  uint256 public constant DAILY_SEED_RATE = 10000 ether;
  // Farmers take a 20% tax on all $SEED claimed
  uint256 public constant SEED_CLAIM_TAX_PERCENTAGE = 20;
  // There will only ever be (roughly) 2.4 billion $SEED earned through staking
  uint256 public constant MAXIMUM_GLOBAL_SEED = 2400000000 ether;

  // amount of $SEED earned so far
  uint256 public totalSeedEarned;
  // number of Gardener staked in the Field
  uint256 public totalGardenerStaked;
  // the last time $SEED was claimed
  uint256 public lastClaimTimestamp;

  // Emergency rescue to allow unstaking without any checks but without $SEED
  bool public rescueEnabled = false;

  bool public canClaim = false;

  /**
   * @param _game reference to the GardenerAndFarmer NFT contract
   * @param _seedToken reference to the $SEED token
   */
  constructor(address _game, address _seedToken) {
    require(_game != address(0), "Invalid address for NFT contract");
    require(_seedToken != address(0), "Invalid address for SEED contract");
    game = GardenerAndFarmer(_game);
    seedToken = IBurnableToken(_seedToken);
  }

  /***STAKING */

  /**
   * adds Gardener and Farmers to the Field and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the Garderners and Farmers to stake
   */
  function addManyToFieldAndPack(address account, uint16[] calldata tokenIds)
    external
    whenNotPaused
    nonReentrant
  {
    require(
      (account == _msgSender() && account == tx.origin) ||
        _msgSender() == address(game),
      "Not allowed"
    );

    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (tokenIds[i] == 0) {
        continue;
      }

      if (_msgSender() != address(game)) {
        // dont do this step if its a mint + stake
        require(
          game.ownerOf(tokenIds[i]) == _msgSender(),
          "Not owner of tokens"
        );
        game.transferFrom(_msgSender(), address(this), tokenIds[i]);
      }

      if (isGardener(tokenIds[i])) {
        _addGardenerToField(account, tokenIds[i]);
      } else {
        _addFarmerToPack(account, tokenIds[i]);
      }
    }
  }

  /**
   * adds a single Gardener to the Field
   * @param account the address of the staker
   * @param tokenId the ID of the Gardener to add to the Field
   */
  function _addGardenerToField(address account, uint256 tokenId)
    internal
    whenNotPaused
    _updateEarnings
  {
    field[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalGardenerStaked += 1;
    ownerToTokenIds[account].push(tokenId);
    emit TokenStaked(true, account, tokenId, block.timestamp);
  }

  /**
   * adds a single Farmer to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the Farmer to add to the Pack
   */
  function _addFarmerToPack(address account, uint256 tokenId) internal {
    uint256 score = _scoreForFarmer(tokenId);
    totalScoreStaked += score;
    // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = pack[score].length;

    // Store the location of the farmer in the Pack
    pack[score].push(
      Stake({
        owner: account,
        tokenId: uint16(tokenId),
        value: uint80(seedPerScore)
      })
    );
    // Add the farmer to the Pack
    ownerToTokenIds[account].push(tokenId);
    emit TokenStaked(false, account, tokenId, seedPerScore);
  }

  /***CLAIMING / UNSTAKING */

  /**
   * realize $SEED earnings and optionally unstake tokens from the Field / Pack
   * to unstake a Gardener it will require it has 2 days worth of $SEEd unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromFieldAndPack(uint16[] calldata tokenIds, bool unstake)
    external
    nonReentrant
    _updateEarnings
  {
    require(msg.sender == tx.origin, "Only EOA");
    require(canClaim, "Claim disabled");

    uint256 owed = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (isGardener(tokenIds[i])) {
        owed += _claimGardenerFromField(tokenIds[i], unstake);
      } else {
        owed += _claimFarmerFromPack(tokenIds[i], unstake);
      }
    }
    if (owed == 0) {
      return;
    }
    seedToken.mint(_msgSender(), owed);
  }

  /**
   * realize $SEED earnings for a single Gardener and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Farmers
   * if unstaking, there is a 50% chance all $SEED is stolen
   * @param tokenId the ID of the Gardener to claim earnings from
   * @param unstake whether or not to unstake the Gardener
   * @return owed - the amount of $SEED earned
   */
  function _claimGardenerFromField(uint256 tokenId, bool unstake)
    internal
    returns (uint256 owed)
  {
    Stake memory stake = field[tokenId];
    require(stake.owner == _msgSender(), "Not owner");
    if (totalSeedEarned < MAXIMUM_GLOBAL_SEED) {
      owed = ((block.timestamp - stake.value) * DAILY_SEED_RATE) / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0;
      // $SEED production stopped already
    } else {
      owed = ((lastClaimTimestamp - stake.value) * DAILY_SEED_RATE) / 1 days;
      // stop earning additional $SEED if it's all been earned
    }
    if (unstake) {
      if (random(tokenId) & 1 == 1) {
        // 50% chance of all $SEED stolen
        _payFarmerTax(owed);
        owed = 0;
      }
      game.transferFrom(address(this), _msgSender(), tokenId);
      // send back Gardener
      delete field[tokenId];
      totalGardenerStaked -= 1;
      ownerToTokenIds[_msgSender()].remove(tokenId);
    } else {
      _payFarmerTax((owed * SEED_CLAIM_TAX_PERCENTAGE) / 100);
      // percentage tax to staked Farmers
      owed = (owed * (100 - SEED_CLAIM_TAX_PERCENTAGE)) / 100;
      // remainder goes to Gardener owner
      field[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      });
      // reset stake
    }
    emit GardenerClaimed(tokenId, unstake, owed);
  }

  /**
   * realize $SEED earnings for a single Farmer and optionally unstake it
   * Famrers earn $SEED proportional to their Score rank
   * @param tokenId the ID of the Farmer to claim earnings from
   * @param unstake whether or not to unstake the Farmer
   * @return owed - the amount of $SEED earned
   */
  function _claimFarmerFromPack(uint256 tokenId, bool unstake)
    internal
    returns (uint256 owed)
  {
    require(game.ownerOf(tokenId) == address(this), "Not staked");
    uint256 score = _scoreForFarmer(tokenId);
    Stake memory stake = pack[score][packIndices[tokenId]];
    require(stake.owner == _msgSender(), "Not owner");
    owed = (score) * (seedPerScore - stake.value);
    // Calculate portion of tokens based on Score
    if (unstake) {
      totalScoreStaked -= score;
      // Remove Score from total staked
      game.transferFrom(address(this), _msgSender(), tokenId);
      // Send back Farmer
      Stake memory lastStake = pack[score][pack[score].length - 1];
      pack[score][packIndices[tokenId]] = lastStake;
      // Shuffle last Farmer to current position
      packIndices[lastStake.tokenId] = packIndices[tokenId];
      pack[score].pop();
      // Remove duplicate
      delete packIndices[tokenId];
      ownerToTokenIds[_msgSender()].remove(tokenId);
    } else {
      pack[score][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(seedPerScore)
      });
      // reset stake
    }
    emit FarmerClaimed(tokenId, unstake, owed);
  }

  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, "Rescue disabled");
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint256 score;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isGardener(tokenId)) {
        stake = field[tokenId];
        require(stake.owner == _msgSender(), "Not owner");
        game.transferFrom(address(this), _msgSender(), tokenId);
        // send back Gardener
        delete field[tokenId];
        totalGardenerStaked -= 1;
        ownerToTokenIds[_msgSender()].remove(tokenId);
        emit GardenerClaimed(tokenId, true, 0);
      } else {
        score = _scoreForFarmer(tokenId);
        stake = pack[score][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "Not owner");
        totalScoreStaked -= score;
        // Remove Score from total staked
        game.transferFrom(address(this), _msgSender(), tokenId);
        // Send back Farmer
        lastStake = pack[score][pack[score].length - 1];
        pack[score][packIndices[tokenId]] = lastStake;
        // Shuffle last Farmer to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[score].pop();
        // Remove duplicate
        delete packIndices[tokenId];
        ownerToTokenIds[_msgSender()].remove(tokenId);
        emit FarmerClaimed(tokenId, true, 0);
      }
    }
  }

  /***ACCOUNTING */

  /**
   * add $SEED to claimable pot for the Pack
   * @param amount $SEED to add to the pot
   */
  function _payFarmerTax(uint256 amount) internal {
    if (totalScoreStaked == 0) {
      // if there's no staked Farmers
      unaccountedRewards += amount;
      // keep track of $SEED due to Farmers
      return;
    }
    // makes sure to include any unaccounted $SEED
    seedPerScore += (amount + unaccountedRewards) / totalScoreStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $SEED earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalSeedEarned < MAXIMUM_GLOBAL_SEED) {
      totalSeedEarned +=
        ((block.timestamp - lastClaimTimestamp) *
          totalGardenerStaked *
          DAILY_SEED_RATE) /
        1 days;
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

  /***ADMIN */

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  /***READ ONLY */

  /**
   * checks if a token is a Gardener
   * @param tokenId the ID of the token to check
   * @return gardener - whether or not a token is a Gardener
   */
  function isGardener(uint256 tokenId) public view returns (bool gardener) {
    GardenerAndFarmer.GardenerFarmer memory s = game.getTokenTraits(tokenId);
    gardener = s.isGardener;
  }

  /**
   * gets the score for a Farmer
   * @param tokenId the ID of the Farmer to get the score for
   * @return the score of the Farmer (5-8)
   */
  function _scoreForFarmer(uint256 tokenId) internal view returns (uint8) {
    GardenerAndFarmer.GardenerFarmer memory s = game.getTokenTraits(tokenId);
    return MAX_SCORE - s.scoreIndex;
    // score index is 0-3
  }

  /**
   * chooses a random Farmer thief when a newly minted token is stolen
   * @param seed a random value to choose a Farmer from
   * @return the owner of the randomly selected Farmer thief
   */
  function randomFarmerOwner(uint256 seed) external view returns (address) {
    if (totalScoreStaked == 0) {
      return address(0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalScoreStaked;
    // choose a value from 0 to total score staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Farmers with the same score
    for (uint256 i = MAX_SCORE - 3; i <= MAX_SCORE; i++) {
      cumulative += pack[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) {
        continue;
      }
      // get the address of a random Farmer with that score
      return pack[i][seed % pack[i].length].owner;
    }
    return address(0);
  }

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed,
            totalGardenerStaked,
            totalScoreStaked,
            lastClaimTimestamp
          )
        )
      ) ^ game.randomSource().seed();
  }

  function onERC721Received(
    address,
    address from,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    require(from == address(0), "Cannot send tokens directly");
    return IERC721Receiver.onERC721Received.selector;
  }

  function setGame(address _nGame) external onlyOwner {
    require(_nGame != address(0), "Invalid address");
    game = GardenerAndFarmer(_nGame);
  }

  function setClaiming(bool _canClaim) external onlyOwner {
    canClaim = _canClaim;
  }

  function getTokensByOwner(address owner)
    external
    view
    returns (uint256[] memory tokenIds)
  {
    return ownerToTokenIds[owner];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

interface IGardenerAndFarmer {
  // struct to store each token's traits
  struct GardenerFarmer {
    bool isGardener;
    uint8 eyes;
    uint8 hat;
    uint8 beard;
    uint8 clothes;
    uint8 shoes;
    uint8 accessory;
    uint8 gloves;
    uint8 hair;
    uint8 scoreIndex;
  }

  function getPaidTokens() external view returns (uint256);

  function getTokenTraits(uint256 tokenId)
    external
    view
    returns (GardenerFarmer memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/IGardenerAndFarmer.sol";
import "./interfaces/IField.sol";
import "./interfaces/ITraits.sol";
import "./interfaces/IBurnableToken.sol";
import "./Seed.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IWhitelist.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract GardenerAndFarmer is
  IGardenerAndFarmer,
  ERC721,
  ERC721Enumerable,
  Ownable,
  Pausable,
  ReentrancyGuard
{
  using Address for address payable;
  // Regular mint price - 1.5 AVAX
  uint256 private constant MINT_PRICE = 1500000000000000000;
  // Discounted mint price for white listed addresses - 1.2 AVAX
  uint256 private constant DISCOUNTED_MINT_PRICE = 1200000000000000000;
  // Maximum of tokens that can be minted
  uint256 public constant MAX_TOKENS = 50000;
  // Number of tokens that can be claimed against AVAX - 20% of MAX_TOKENS
  uint256 private constant PAID_TOKENS = 10000;

  // Add more info to the Transfer event as the owner can
  // be different from the sender
  event Mint(
    uint256 indexed tokenId,
    bool indexed isGardener,
    address indexed owner
  );

  // mapping from tokenId to a struct containing the token's traits
  mapping(uint256 => GardenerFarmer) private tokenTraits;
  // reference to the Field for choosing random Farmer thieves
  IField private field;
  // reference to $SEED for burning on mint
  IBurnableToken private seedToken;
  // reference to Traits
  ITraits private traits;

  Seed public randomSource;

  IWhitelist private whitelist;

  address private constant multiSigAddress =
    0x430406E3B0F14fe57Ecd1F56593effCf3ab3e548;
  address private constant mAddress =
    0xD6d366dBBC288B8b7B366304644E5c3703C3Fca8;
  address private constant mCAddress =
    0xc141fbEE6Ffd463f5BF2efac88CeB8edb09b097d;
  address private constant mFAddress =
    0x26e40C31DefBEc06FF2777a0Aa124ea47da7AD0E;
  address private constant hAddress =
    0xBaEA11FdaD9FF90d8AE73Ff59d956C62e6657D81;
  address private constant dAddress =
    0xA3c14510d91073dCE6c2F74d39f802dBA50155ee;
  address private constant bAddress =
    0x4755Aca74710eCb02c74cCFAb355CDb47fc19e6e;
  address private constant devAddress =
    0x3Ff8c87e46Fc8e2E5Dff95cf093637DA27Ab7562;

  // The address of the contract that will receive the liquidity
  // and initiate the pool SEED/AVAX
  address public immutable liquidityController;

  /**
   * instantiates contract
   */
  constructor(
    address _seedToken,
    address _traits,
    address _whitelist,
    address _liquidityController
  ) ERC721("Gardener & Farmer Game", "FARMER") {
    require(
      _seedToken != address(0) &&
        _traits != address(0) &&
        _whitelist != address(0) &&
        _liquidityController != address(0),
      "Invalid address"
    );
    seedToken = IBurnableToken(_seedToken);
    traits = ITraits(_traits);
    whitelist = IWhitelist(_whitelist);
    randomSource = new Seed();
    liquidityController = _liquidityController;
  }

  /***EXTERNAL */

  /**
   * Mint a token - 90% Gardener, 10% Farmer
   * The first 20% are claimable with AVAX, the remaining cost $SEED
   */
  function mint(uint256 amount, bool stake)
    external
    payable
    nonReentrant
    whenNotPaused
  {
    require(tx.origin == _msgSender(), "Only EOA");
    require(totalSupply() + amount <= MAX_TOKENS, "All tokens minted");
    require(amount > 0 && amount <= 30, "Invalid mint amount");

    if (totalSupply() < PAID_TOKENS) {
      require(
        totalSupply() + amount <= PAID_TOKENS,
        "All tokens on-sale already sold"
      );
      uint256 total = getTotalPrice(_msgSender(), amount);
      require(total == msg.value, "Invalid payment amount");
    } else {
      require(msg.value == 0, "No AVAX, just $SEED");
    }

    uint256 totalSeedCost = 0;
    uint16[] memory tokenIds = new uint16[](amount);
    address[] memory owners = new address[](amount);
    uint256 seed;
    uint256 firstMinted = totalSupply();
    uint256 minted = firstMinted;

    for (uint256 i = 0; i < amount; i++) {
      minted++;
      seed = random(minted);
      randomSource.update(minted ^ seed);
      generate(minted, seed);
      address recipient = selectRecipient(seed);
      totalSeedCost += mintCost(minted);
      if (!stake || recipient != _msgSender()) {
        owners[i] = recipient;
      } else {
        tokenIds[i] = uint16(minted);
        owners[i] = address(field);
      }
    }

    if (totalSeedCost > 0) {
      seedToken.burn(_msgSender(), totalSeedCost);
    }

    for (uint256 i = 0; i < owners.length; i++) {
      uint256 id = firstMinted + i + 1;
      if (!stake || owners[i] != _msgSender()) {
        _safeMint(owners[i], id);
        emit Mint(id, tokenTraits[id].isGardener, owners[i]);
      }
    }
    if (stake) {
      field.addManyToFieldAndPack(_msgSender(), tokenIds);
    }
  }

  /**
   * the first 20% are paid in AVAX
   * the next 20% are 20000 $SEED
   * the next 40% are 40000 $SEED
   * the final 20% are 80000 $SEED
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCost(uint256 tokenId) public pure returns (uint256) {
    if (tokenId <= PAID_TOKENS) {
      return 0;
    }
    if (tokenId <= (MAX_TOKENS * 2) / 5) {
      return 20000 ether;
    }
    if (tokenId <= (MAX_TOKENS * 4) / 5) {
      return 40000 ether;
    }
    return 60000 ether;
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    // The Field contract can transfer any token without prior approval
    return
      operator == address(field) || super.isApprovedForAll(owner, operator);
  }

  /***INTERNAL */

  /**
   * generates traits for a specific token, checking to make sure it's unique
   * @param tokenId the id of the token to generate traits for
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t - a struct of traits for the given token ID
   */
  function generate(uint256 tokenId, uint256 seed)
    internal
    returns (GardenerFarmer memory t)
  {
    t = selectTraits(seed);
    tokenTraits[tokenId] = t;
    return t;
  }

  /**
   * @param seed portion of the 256 bit seed to remove trait correlation
   * @param traitType the trait type to select a trait for
   * @return the ID of the randomly selected trait
   */
  function selectTrait(uint16 seed, uint8 traitType)
    internal
    view
    returns (uint8)
  {
    return traits.selectTrait(seed, traitType);
  }

  /**
   * the first 20% (AVAX purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked farmer
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Farmer thief's owner)
   */
  function selectRecipient(uint256 seed) internal view returns (address) {
    if (totalSupply() <= PAID_TOKENS || ((seed >> 245) % 10) != 0) {
      return _msgSender();
    }
    // top 10 bits haven't been used
    address thief = field.randomFarmerOwner(seed >> 144);
    // 144 bits reserved for trait selection
    if (thief == address(0)) {
      return _msgSender();
    }
    return thief;
  }

  /**
   * selects the species and all of its traits based on the seed value
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t -  a struct of randomly selected traits
   */
  function selectTraits(uint256 seed)
    internal
    view
    returns (GardenerFarmer memory t)
  {
    // Around 90% percent probability of getting a Gardener
    t.isGardener = (seed & 0xFFFF) % 10 != 0;
    uint8 shift = t.isGardener ? 0 : 10;

    // Since we use the last 16 bits of the seed every time
    // as the seed for the attribute we need to shift to these
    // 16 bits to the right to make them go away to use new
    // parts of the seed for the subsquent traits
    seed >>= 16;
    t.eyes = selectTrait(uint16(seed & 0xFFFF), 0 + shift);

    seed >>= 16;
    t.clothes = selectTrait(uint16(seed & 0xFFFF), 1 + shift);

    seed >>= 16;
    t.shoes = selectTrait(uint16(seed & 0xFFFF), 2 + shift);

    seed >>= 16;
    t.accessory = selectTrait(uint16(seed & 0xFFFF), 3 + shift);

    if (!t.isGardener) {
      seed >>= 16;
      t.hat = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
      seed >>= 16;
      t.beard = selectTrait(uint16(seed & 0xFFFF), 5 + shift);

      seed >>= 16;
      // The Farmer has a score
      // It follows that since the shift is 10 in this case that
      // the score index is 16
      t.scoreIndex = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
    } else {
      seed >>= 16;
      t.gloves = selectTrait(uint16(seed & 0xFFFF), 4 + shift);

      seed >>= 16;
      t.hair = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
    }
  }

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
          )
        )
      ) ^ randomSource.seed();
  }

  /***READ */

  function getTokenTraits(uint256 tokenId)
    external
    view
    override
    returns (GardenerFarmer memory)
  {
    return tokenTraits[tokenId];
  }

  function getPaidTokens() external pure override returns (uint256) {
    return PAID_TOKENS;
  }

  function getTotalPrice(address addr, uint256 tokenAmount)
    public
    view
    returns (uint256 total)
  {
    bool isWhitelisted = whitelist.isWhitelisted(addr) && balanceOf(addr) < 5;
    if (isWhitelisted) {
      // A whitelisted address can only mint up to 5 NFTs at the discounted price
      uint256 discountedAmount = tokenAmount > 5 - balanceOf(addr)
        ? 5 - balanceOf(addr)
        : tokenAmount;
      // We get the total according to the remaining token at the discounted price
      // plus the rest at regular price
      total =
        DISCOUNTED_MINT_PRICE *
        discountedAmount +
        MINT_PRICE *
        (tokenAmount - discountedAmount);
    } else {
      total = MINT_PRICE * tokenAmount;
    }
  }

  /***ADMIN */

  /**
   * called after deployment so that the contract can get random farmer thieves
   * @param _field the address of the Field
   */
  function setField(address _field) external onlyOwner {
    field = IField(_field);
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external {
    require(
      _msgSender() == owner() || _msgSender() == multiSigAddress,
      "Not allowed"
    );

    uint256 totalBalance = address(this).balance;

    uint256 balanceToTransfer = (totalBalance * 30) / 144;
    payable(liquidityController).sendValue(balanceToTransfer);

    balanceToTransfer = (totalBalance * 201) / 14400;
    payable(mAddress).sendValue(balanceToTransfer);

    balanceToTransfer = (totalBalance * 1643) / 14400;
    payable(mCAddress).sendValue(balanceToTransfer);
    payable(mFAddress).sendValue(balanceToTransfer);
    payable(hAddress).sendValue(balanceToTransfer);

    balanceToTransfer = (totalBalance * 194) / 1440;
    payable(dAddress).sendValue(balanceToTransfer);

    balanceToTransfer = (totalBalance * 2165) / 14400;
    payable(bAddress).sendValue(balanceToTransfer);
    payable(devAddress).sendValue(balanceToTransfer);
  }

  /**
   * Enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  /***RENDER */

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return traits.tokenURI(tokenId);
  }

  function setTraits(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    traits = ITraits(addr);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBurnableToken is IERC20 {
  function mint(address account, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Stake {
  uint16 tokenId;
  uint80 value;
  address owner;
}

interface IField {
  function addManyToFieldAndPack(address account, uint16[] calldata tokenIds)
    external;

  function randomFarmerOwner(uint256 seed) external view returns (address);

  function field(uint256)
    external
    view
    returns (
      uint16,
      uint80,
      address
    );

  function totalSeedEarned() external view returns (uint256);

  function lastClaimTimestamp() external view returns (uint256);

  function pack(uint256, uint256) external view returns (Stake memory);

  function packIndices(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

library Array {
  function remove(uint256[] storage array, uint256 item) internal {
    require(array.length > 0, "Empty array");
    for (uint256 i = 0; i < array.length; i++) {
      // Move the last element into the place to delete
      if (array[i] == item) {
        array[i] = array[array.length - 1];
        // Remove the last element
        array.pop();
        break;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);

  function selectTrait(uint16 seed, uint8 traitType)
    external
    view
    returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Seed is Ownable {
  uint256 public seed;

  function update(uint256 _seed) external onlyOwner returns (uint256) {
    seed = seed ^ _seed;

    return seed;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWhitelist {
  function isWhitelisted(address addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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