// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";

import "../token/TokenListenerInterface.sol";
import "../external/pooltogether/FixedPoint.sol";
import "../token/TokenControllerInterface.sol";
import "../token/ControlledToken.sol";
import "../token/TicketInterface.sol";
import "../prize-pool/PrizePool.sol";
import "../Constants.sol";
import "../utils/RelayRecipient.sol";

/* solium-disable security/no-block-members */
abstract contract PeriodicPrizeStrategy is Initializable,
                                           OwnableUpgradeSafe,
                                           RelayRecipient,
                                           ReentrancyGuardUpgradeSafe,
                                           TokenListenerInterface {

  using SafeMath for uint256;
  using SafeCast for uint256;
  using MappedSinglyLinkedList for MappedSinglyLinkedList.Mapping;
  using Address for address;

  uint256 internal constant ETHEREUM_BLOCK_TIME_ESTIMATE_MANTISSA = 13.4 ether;

  event PrizePoolOpened(
    address indexed operator,
    uint256 indexed prizePeriodStartedAt
  );

  event PrizePoolAwardStarted(
    address indexed operator,
    address indexed prizePool,
    uint32 indexed rngRequestId,
    uint32 rngLockBlock
  );

  event RngRequestFailed();

  event PrizePoolAwarded(
    address indexed operator,
    uint256 randomNumber
  );

  event RngServiceUpdated(
    address indexed rngService
  );

  event TokenListenerUpdated(
    address indexed tokenListener
  );

  event RngRequestTimeoutSet(
    uint32 rngRequestTimeout
  );

  event ExternalErc721AwardAdded(
    address indexed externalErc721,
    uint256[] tokenIds
  );

  event ExternalErc20AwardAdded(
    address indexed externalErc20
  );

  event ExternalErc721AwardRemoved(
    address indexed externalErc721Award
  );

  event ExternalErc20AwardRemoved(
    address indexed externalErc20Award
  );

  struct RngRequest {
    uint32 id;
    uint32 lockBlock;
    uint32 requestedAt;
  }

  // Comptroller
  TokenListenerInterface public tokenListener;

  // Contract Interfaces
  PrizePool public prizePool;
  TicketInterface public ticket;
  IERC20 public sponsorship;
  RNGInterface public rng;

  // Current RNG Request
  RngRequest internal rngRequest;

  // RNG Request Timeout
  uint32 public rngRequestTimeout;

  // Prize period
  uint256 public prizePeriodSeconds;
  uint256 public prizePeriodStartedAt;

  // External tokens awarded as part of prize
  MappedSinglyLinkedList.Mapping internal externalErc20s;
  MappedSinglyLinkedList.Mapping internal externalErc721s;

  // External NFT token IDs to be awarded
  //   NFT Address => TokenIds
  mapping (address => uint256[]) internal externalErc721TokenIds;

  function initialize (
    address _trustedForwarder,
    uint256 _prizePeriodStart,
    uint256 _prizePeriodSeconds,
    PrizePool _prizePool,
    address _ticket,
    address _sponsorship,
    RNGInterface _rng,
    address[] memory _externalErc20s
  ) public initializer {
    require(_prizePeriodSeconds > 0, "PeriodicPrizeStrategy/prize-period-greater-than-zero");
    require(address(_prizePool) != address(0), "PeriodicPrizeStrategy/prize-pool-not-zero");
    require(address(_ticket) != address(0), "PeriodicPrizeStrategy/ticket-not-zero");
    require(address(_sponsorship) != address(0), "PeriodicPrizeStrategy/sponsorship-not-zero");
    require(address(_rng) != address(0), "PeriodicPrizeStrategy/rng-not-zero");
    prizePool = _prizePool;
    ticket = TicketInterface(_ticket);
    rng = _rng;
    sponsorship = IERC20(_sponsorship);
    trustedForwarder = _trustedForwarder;

    __Ownable_init();
    __ReentrancyGuard_init();
    Constants.REGISTRY.setInterfaceImplementer(address(this), Constants.TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

    for (uint256 i = 0; i < _externalErc20s.length; i++) {
      require(prizePool.canAwardExternal(_externalErc20s[i]), "PeriodicPrizeStrategy/cannot-award-external");
    }
    externalErc20s.initialize();
    externalErc20s.addAddresses(_externalErc20s);

    prizePeriodSeconds = _prizePeriodSeconds;
    prizePeriodStartedAt = _prizePeriodStart;

    externalErc721s.initialize();

    // 1 hour timeout
    _setRngRequestTimeout(3600);

    emit PrizePoolOpened(_msgSender(), prizePeriodStartedAt);
  }

  function _distribute(uint256 randomNumber) internal virtual;

  /// @notice Calculates and returns the currently accrued prize
  /// @return The current prize size
  function currentPrize() public view returns (uint256) {
    return prizePool.awardBalance();
  }

  function setTokenListener(TokenListenerInterface _tokenListener) external onlyOwner {
    tokenListener = _tokenListener;

    emit TokenListenerUpdated(address(tokenListener));
  }

  /// @notice Estimates the remaining blocks until the prize given a number of seconds per block
  /// @param secondsPerBlockMantissa The number of seconds per block to use for the calculation.  Should be a fixed point 18 number like Ether.
  /// @return The estimated number of blocks remaining until the prize can be awarded.
  function estimateRemainingBlocksToPrize(uint256 secondsPerBlockMantissa) public view returns (uint256) {
    return FixedPoint.divideUintByMantissa(
      _prizePeriodRemainingSeconds(),
      secondsPerBlockMantissa
    );
  }

  /// @notice Returns the number of seconds remaining until the prize can be awarded.
  /// @return The number of seconds remaining until the prize can be awarded.
  function prizePeriodRemainingSeconds() external view returns (uint256) {
    return _prizePeriodRemainingSeconds();
  }

  /// @notice Returns the number of seconds remaining until the prize can be awarded.
  /// @return The number of seconds remaining until the prize can be awarded.
  function _prizePeriodRemainingSeconds() internal view returns (uint256) {
    uint256 endAt = _prizePeriodEndAt();
    uint256 time = _currentTime();
    if (time > endAt) {
      return 0;
    }
    return endAt.sub(time);
  }

  /// @notice Returns whether the prize period is over
  /// @return True if the prize period is over, false otherwise
  function isPrizePeriodOver() external view returns (bool) {
    return _isPrizePeriodOver();
  }

  /// @notice Returns whether the prize period is over
  /// @return True if the prize period is over, false otherwise
  function _isPrizePeriodOver() internal view returns (bool) {
    return _currentTime() >= _prizePeriodEndAt();
  }

  /// @notice Awards collateral as tickets to a user
  /// @param user The user to whom the tickets are minted
  /// @param amount The amount of interest to mint as tickets.
  function _awardTickets(address user, uint256 amount) internal {
    prizePool.award(user, amount, address(ticket));
  }

  /// @notice Awards all external tokens with non-zero balances to the given user.  The external tokens must be held by the PrizePool contract.
  /// @param winner The user to transfer the tokens to
  function _awardAllExternalTokens(address winner) internal {
    _awardExternalErc20s(winner);
    _awardExternalErc721s(winner);
  }

  /// @notice Awards all external ERC20 tokens with non-zero balances to the given user.
  /// The external tokens must be held by the PrizePool contract.
  /// @param winner The user to transfer the tokens to
  function _awardExternalErc20s(address winner) internal {
    address currentToken = externalErc20s.start();
    while (currentToken != address(0) && currentToken != externalErc20s.end()) {
      uint256 balance = IERC20(currentToken).balanceOf(address(prizePool));
      if (balance > 0) {
        prizePool.awardExternalERC20(winner, currentToken, balance);
      }
      currentToken = externalErc20s.next(currentToken);
    }
  }

  /// @notice Awards all external ERC721 tokens to the given user.
  /// The external tokens must be held by the PrizePool contract.
  /// @dev The list of ERC721s is reset after every award
  /// @param winner The user to transfer the tokens to
  function _awardExternalErc721s(address winner) internal {
    address currentToken = externalErc721s.start();
    while (currentToken != address(0) && currentToken != externalErc721s.end()) {
      uint256 balance = IERC721(currentToken).balanceOf(address(prizePool));
      if (balance > 0) {
        prizePool.awardExternalERC721(winner, currentToken, externalErc721TokenIds[currentToken]);
        delete externalErc721TokenIds[currentToken];
      }
      currentToken = externalErc721s.next(currentToken);
    }
    externalErc721s.clearAll();
  }

  /// @notice Returns the timestamp at which the prize period ends
  /// @return The timestamp at which the prize period ends.
  function prizePeriodEndAt() external view returns (uint256) {
    // current prize started at is non-inclusive, so add one
    return _prizePeriodEndAt();
  }

  /// @notice Returns the timestamp at which the prize period ends
  /// @return The timestamp at which the prize period ends.
  function _prizePeriodEndAt() internal view returns (uint256) {
    // current prize started at is non-inclusive, so add one
    return prizePeriodStartedAt.add(prizePeriodSeconds);
  }

  /// @notice Called by the PrizePool for transfers of controlled tokens
  /// @dev Note that this is only for *transfers*, not mints or burns
  /// @param controlledToken The type of collateral that is being sent
  function beforeTokenTransfer(address from, address to, uint256 amount, address controlledToken) external override onlyPrizePool {
    if (controlledToken == address(ticket)) {
      _requireNotLocked();
    }
    if (address(tokenListener) != address(0)) {
      tokenListener.beforeTokenTransfer(from, to, amount, controlledToken);
    }
  }

  /// @notice Called by the PrizePool when minting controlled tokens
  /// @param controlledToken The type of collateral that is being minted
  function beforeTokenMint(
    address to,
    uint256 amount,
    address controlledToken,
    address referrer
  )
    external
    override
    onlyPrizePool
  {
    if (controlledToken == address(ticket)) {
      _requireNotLocked();
    }
    if (address(tokenListener) != address(0)) {
      tokenListener.beforeTokenMint(to, amount, controlledToken, referrer);
    }
  }

  /// @notice returns the current time.  Used for testing.
  /// @return The current time (block.timestamp)
  function _currentTime() internal virtual view returns (uint256) {
    return block.timestamp;
  }

  /// @notice returns the current time.  Used for testing.
  /// @return The current time (block.timestamp)
  function _currentBlock() internal virtual view returns (uint256) {
    return block.number;
  }

  /// @notice Starts the award process by starting random number request.  The prize period must have ended.
  /// @dev The RNG-Request-Fee is expected to be held within this contract before calling this function
  function startAward() external requireCanStartAward {
    if (isRngTimedOut()) {
      delete rngRequest;
      emit RngRequestFailed();
    }
    (address feeToken, uint256 requestFee) = rng.getRequestFee();
    if (feeToken != address(0) && requestFee > 0) {
      IERC20(feeToken).approve(address(rng), requestFee);
    }

    (uint32 requestId, uint32 lockBlock) = rng.requestRandomNumber();
    rngRequest.id = requestId;
    rngRequest.lockBlock = lockBlock;
    rngRequest.requestedAt = _currentTime().toUint32();

    emit PrizePoolAwardStarted(_msgSender(), address(prizePool), requestId, lockBlock);
  }

  /// @notice Completes the award process and awards the winners.  The random number must have been requested and is now available.
  function completeAward() external requireCanCompleteAward {
    uint256 randomNumber = rng.randomNumber(rngRequest.id);
    delete rngRequest;

    _distribute(randomNumber);

    // to avoid clock drift, we should calculate the start time based on the previous period start time.
    prizePeriodStartedAt = _calculateNextPrizePeriodStartTime(_currentTime());

    emit PrizePoolAwarded(_msgSender(), randomNumber);
    emit PrizePoolOpened(_msgSender(), prizePeriodStartedAt);
  }

  function _calculateNextPrizePeriodStartTime(uint256 currentTime) internal view returns (uint256) {
    uint256 elapsedPeriods = currentTime.sub(prizePeriodStartedAt).div(prizePeriodSeconds);
    return prizePeriodStartedAt.add(elapsedPeriods.mul(prizePeriodSeconds));
  }

  function calculateNextPrizePeriodStartTime(uint256 currentTime) external view returns (uint256) {
    return _calculateNextPrizePeriodStartTime(currentTime);
  }

  /// @notice Returns whether an award process can be started
  /// @return True if an award can be started, false otherwise.
  function canStartAward() external view returns (bool) {
    return _isPrizePeriodOver() && !isRngRequested();
  }

  /// @notice Returns whether an award process can be completed
  /// @return True if an award can be completed, false otherwise.
  function canCompleteAward() external view returns (bool) {
    return isRngRequested() && isRngCompleted();
  }

  /// @notice Returns whether a random number has been requested
  /// @return True if a random number has been requested, false otherwise.
  function isRngRequested() public view returns (bool) {
    return rngRequest.id != 0;
  }

  /// @notice Returns whether the random number request has completed.
  /// @return True if a random number request has completed, false otherwise.
  function isRngCompleted() public view returns (bool) {
    return rng.isRequestComplete(rngRequest.id);
  }

  /// @notice Returns the block number that the current RNG request has been locked to
  /// @return The block number that the RNG request is locked to
  function getLastRngLockBlock() external view returns (uint32) {
    return rngRequest.lockBlock;
  }

  /// @notice Returns the current RNG Request ID
  /// @return The current Request ID
  function getLastRngRequestId() external view returns (uint32) {
    return rngRequest.id;
  }

  /// @notice Sets the RNG service that the Prize Strategy is connected to
  /// @param rngService The address of the new RNG service interface
  function setRngService(RNGInterface rngService) external onlyOwner {
    require(!isRngRequested(), "PeriodicPrizeStrategy/rng-in-flight");

    rng = rngService;
    emit RngServiceUpdated(address(rngService));
  }

  function setRngRequestTimeout(uint32 _rngRequestTimeout) external onlyOwner {
    _setRngRequestTimeout(_rngRequestTimeout);
  }

  function _setRngRequestTimeout(uint32 _rngRequestTimeout) internal {
    require(_rngRequestTimeout > 60, "PeriodicPrizeStrategy/rng-timeout-gt-60-secs");
    rngRequestTimeout = _rngRequestTimeout;
    emit RngRequestTimeoutSet(rngRequestTimeout);
  }

  /// @notice Gets the current list of External ERC20 tokens that will be awarded with the current prize
  /// @return An array of External ERC20 token addresses
  function getExternalErc20Awards() external view returns (address[] memory) {
    return externalErc20s.addressArray();
  }

  /// @notice Adds an external ERC20 token type as an additional prize that can be awarded
  /// @dev Only the Prize-Strategy owner/creator can assign external tokens,
  /// and they must be approved by the Prize-Pool
  /// @param _externalErc20 The address of an ERC20 token to be awarded
  function addExternalErc20Award(address _externalErc20) external onlyOwner {
    // require(_externalErc20.isContract(), "PeriodicPrizeStrategy/external-erc20-not-contract");
    require(prizePool.canAwardExternal(_externalErc20), "PeriodicPrizeStrategy/cannot-award-external");
    externalErc20s.addAddress(_externalErc20);
    emit ExternalErc20AwardAdded(_externalErc20);
  }

  /// @notice Removes an external ERC20 token type as an additional prize that can be awarded
  /// @dev Only the Prize-Strategy owner/creator can remove external tokens
  /// @param _externalErc20 The address of an ERC20 token to be removed
  /// @param _prevExternalErc20 The address of the previous ERC20 token in the `externalErc20s` list.
  /// If the ERC20 is the first address, then the previous address is the SENTINEL address: 0x0000000000000000000000000000000000000001
  function removeExternalErc20Award(address _externalErc20, address _prevExternalErc20) external onlyOwner {
    externalErc20s.removeAddress(_prevExternalErc20, _externalErc20);
    emit ExternalErc20AwardRemoved(_externalErc20);
  }

  /// @notice Gets the current list of External ERC721 tokens that will be awarded with the current prize
  /// @return An array of External ERC721 token addresses
  function getExternalErc721Awards() external view returns (address[] memory) {
    return externalErc721s.addressArray();
  }

  /// @notice Gets the current list of External ERC721 tokens that will be awarded with the current prize
  /// @return An array of External ERC721 token addresses
  function getExternalErc721AwardTokenIds(address _externalErc721) external view returns (uint256[] memory) {
    return externalErc721TokenIds[_externalErc721];
  }

  /// @notice Adds an external ERC721 token as an additional prize that can be awarded
  /// @dev Only the Prize-Strategy owner/creator can assign external tokens,
  /// and they must be approved by the Prize-Pool
  /// NOTE: The NFT must already be owned by the Prize-Pool
  /// @param _externalErc721 The address of an ERC721 token to be awarded
  /// @param _tokenIds An array of token IDs of the ERC721 to be awarded
  function addExternalErc721Award(address _externalErc721, uint256[] calldata _tokenIds) external onlyOwner {
    // require(_externalErc721.isContract(), "PeriodicPrizeStrategy/external-erc721-not-contract");
    require(prizePool.canAwardExternal(_externalErc721), "PeriodicPrizeStrategy/cannot-award-external");
    externalErc721s.addAddress(_externalErc721);

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      uint256 tokenId = _tokenIds[i];
      require(IERC721(_externalErc721).ownerOf(tokenId) == address(prizePool), "PeriodicPrizeStrategy/unavailable-token");
      externalErc721TokenIds[_externalErc721].push(tokenId);
    }

    emit ExternalErc721AwardAdded(_externalErc721, _tokenIds);
  }

  /// @notice Removes an external ERC721 token as an additional prize that can be awarded
  /// @dev Only the Prize-Strategy owner/creator can remove external tokens
  /// @param _externalErc721 The address of an ERC721 token to be removed
  /// @param _prevExternalErc721 The address of the previous ERC721 token in the list.
  /// If no previous, then pass the SENTINEL address: 0x0000000000000000000000000000000000000001
  function removeExternalErc721Award(address _externalErc721, address _prevExternalErc721) external onlyOwner {
    externalErc721s.removeAddress(_prevExternalErc721, _externalErc721);
    delete externalErc721TokenIds[_externalErc721];
    emit ExternalErc721AwardRemoved(_externalErc721);
  }

  /// @notice Allows the owner to transfer out external ERC20 tokens
  /// @dev Used to transfer out tokens held by the Prize Pool.  Could be liquidated, or anything.
  /// @param to The address that receives the tokens
  /// @param externalToken The address of the external asset token being transferred
  /// @param amount The amount of external assets to be transferred
  function transferExternalERC20(
    address to,
    address externalToken,
    uint256 amount
  )
    external
    onlyOwner
  {
    prizePool.transferExternalERC20(to, externalToken, amount);
  }

  function _requireNotLocked() internal view {
    uint256 currentBlock = _currentBlock();
    require(rngRequest.lockBlock == 0 || currentBlock < rngRequest.lockBlock, "PeriodicPrizeStrategy/rng-in-flight");
  }

  function isRngTimedOut() public view returns (bool) {
    if (rngRequest.requestedAt == 0) {
      return false;
    } else {
      return _currentTime() > uint256(rngRequestTimeout).add(rngRequest.requestedAt);
    }
  }

  /// @dev Provides information about the current execution context for GSN Meta-Txs.
  /// @return The payable address of the message sender
  function _msgSender()
    internal
    override(BaseRelayRecipient, ContextUpgradeSafe)
    virtual
    view
    returns (address payable)
  {
    return BaseRelayRecipient._msgSender();
  }

  /// @dev Provides information about the current execution context for GSN Meta-Txs.
  /// @return The payable address of the message sender
  function _msgData()
    internal
    override(BaseRelayRecipient, ContextUpgradeSafe)
    virtual
    view
    returns (bytes memory)
  {
    return BaseRelayRecipient._msgData();
  }

  modifier requireNotLocked() {
    _requireNotLocked();
    _;
  }

  modifier requireCanStartAward() {
    require(_isPrizePeriodOver(), "PeriodicPrizeStrategy/prize-period-not-over");
    require(!isRngRequested() || isRngTimedOut(), "PeriodicPrizeStrategy/rng-already-requested");
    _;
  }

  modifier requireCanCompleteAward() {
    require(_isPrizePeriodOver(), "PeriodicPrizeStrategy/prize-period-not-over");
    require(isRngRequested(), "PeriodicPrizeStrategy/rng-not-requested");
    require(isRngCompleted(), "PeriodicPrizeStrategy/rng-not-complete");
    _;
  }

  modifier onlyPrizePool() {
    require(_msgSender() == address(prizePool), "PeriodicPrizeStrategy/only-prize-pool");
    _;
  }
}
