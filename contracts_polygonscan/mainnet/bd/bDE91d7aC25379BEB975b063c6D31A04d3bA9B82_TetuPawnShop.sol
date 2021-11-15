// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../base/governance/Controllable.sol";
import "./ITetuPawnShop.sol";
import "../base/interface/IFeeRewardForwarder.sol";
import "../base/ArrayLib.sol";

/// @title Contract for handling deals between two parties
/// @author belbix
contract TetuPawnShop is ERC721Holder, Controllable, ReentrancyGuard, ITetuPawnShop {
  using SafeERC20 for IERC20;
  using ArrayLib for uint256[];

  /// @dev Tetu Controller address requires for governance actions
  constructor(address _controller) {
    Controllable.initializeControllable(_controller);
  }

  // ---- CONSTANTS

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.0";
  /// @dev Denominator for any internal computation with low precision
  uint256 constant public DENOMINATOR = 10000;
  /// @dev Governance can't set fee more than this value
  uint256 constant public PLATFORM_FEE_MAX = 500; // 5%
  /// @dev Standard auction duration that refresh when a new bid placed
  uint256 constant public AUCTION_DURATION = 1 days;

  // ---- CHANGEABLE VARIABLES

  /// @dev 1% by default, percent of acquired tokens that will be used for buybacks
  uint256 public platformFee = 10;
  /// @dev Amount of tokens for open position. Protection against spam
  ///      1000 TETU by default
  uint256 public positionDepositAmount = 1000 * 1e18;
  /// @dev Token for antispam protection. TETU assumed
  ///      Zero address means no protection
  address public positionDepositToken;

  // ---- POSITIONS

  /// @inheritdoc ITetuPawnShop
  uint256 public override positionCounter = 1;
  /// @dev PosId => Position. Hold all positions. Any record should not be removed
  mapping(uint256 => Position) public positions;
  /// @inheritdoc ITetuPawnShop
  uint256[] public override openPositions;
  /// @inheritdoc ITetuPawnShop
  mapping(address => uint256[]) public override positionsByCollateral;
  /// @inheritdoc ITetuPawnShop
  mapping(address => uint256[]) public override positionsByAcquired;
  /// @inheritdoc ITetuPawnShop
  mapping(address => uint256[]) public override borrowerPositions;
  /// @inheritdoc ITetuPawnShop
  mapping(address => uint256[]) public override lenderPositions;
  /// @inheritdoc ITetuPawnShop
  mapping(IndexType => mapping(uint256 => uint256)) public override posIndexes;

  // ---- AUCTION

  /// @inheritdoc ITetuPawnShop
  uint256 public override auctionBidCounter = 1;
  /// @dev BidId => Bid. Hold all bids. Any record should not be removed
  mapping(uint256 => AuctionBid) public auctionBids;
  /// @inheritdoc ITetuPawnShop
  mapping(address => mapping(uint256 => uint256)) public override lenderOpenBids;
  /// @inheritdoc ITetuPawnShop
  mapping(uint256 => uint256[]) public override positionToBidIds;
  /// @inheritdoc ITetuPawnShop
  mapping(uint256 => uint256) public override lastAuctionBidTs;

  // ************* USER ACTIONS *************

  /// @inheritdoc ITetuPawnShop
  function openPosition(
    address _collateralToken,
    uint256 _collateralAmount,
    uint256 _collateralTokenId,
    address _acquiredToken,
    uint256 _acquiredAmount,
    uint256 _posDurationBlocks,
    uint256 _posFee
  ) external onlyAllowedUsers nonReentrant override returns (uint256){
    require(_posFee <= DENOMINATOR * 10, "TL: Pos fee absurdly high");
    require(_posDurationBlocks != 0 || _posFee == 0, "TL: Fee for instant deal forbidden");
    require(_collateralAmount != 0 || _collateralTokenId != 0, "TL: Wrong amounts");
    require(_collateralToken != address(0), "TL: Zero cToken");
    require(_acquiredToken != address(0), "TL: Zero aToken");

    Position memory pos;
    {
      PositionInfo memory info = PositionInfo(
        _posDurationBlocks,
        _posFee,
        block.number,
        block.timestamp
      );

      PositionCollateral memory collateral = PositionCollateral(
        _collateralToken,
        getAssetType(_collateralToken),
        _collateralAmount,
        _collateralTokenId
      );

      PositionAcquired memory acquired = PositionAcquired(
        _acquiredToken,
        _acquiredAmount
      );

      PositionExecution memory execution = PositionExecution(
        address(0),
        0,
        0,
        0
      );

      pos = Position(
        positionCounter, // id
        msg.sender, // borrower
        positionDepositToken,
        positionDepositAmount,
        true, // open
        info,
        collateral,
        acquired,
        execution
      );
    }

    openPositions.push(pos.id);
    posIndexes[IndexType.LIST][pos.id] = openPositions.length - 1;

    positionsByCollateral[_collateralToken].push(pos.id);
    posIndexes[IndexType.BY_COLLATERAL][pos.id] = positionsByCollateral[_collateralToken].length - 1;

    positionsByAcquired[_acquiredToken].push(pos.id);
    posIndexes[IndexType.BY_ACQUIRED][pos.id] = positionsByAcquired[_acquiredToken].length - 1;

    borrowerPositions[msg.sender].push(pos.id);
    posIndexes[IndexType.BORROWER_POSITION][pos.id] = borrowerPositions[msg.sender].length - 1;

    positions[pos.id] = pos;
    positionCounter++;

    _takeDeposit(pos.id);
    _transferCollateral(pos.collateral, msg.sender, address(this));
    emit PositionOpened(pos.id);
    return pos.id;
  }

  /// @inheritdoc ITetuPawnShop
  function closePosition(uint256 id) external onlyAllowedUsers nonReentrant override {
    Position storage pos = positions[id];
    require(pos.id == id, "TL: Wrong ID");
    require(pos.borrower == msg.sender, "TL: Only borrower can close a position");
    require(pos.execution.lender == address(0), "TL: Can't close executed position");
    require(pos.open, "TL: Position closed");

    _removePosFromIndexes(pos);
    borrowerPositions[pos.borrower].removeIndexed(posIndexes[IndexType.BORROWER_POSITION], pos.id);

    _transferCollateral(pos.collateral, address(this), pos.borrower);
    _returnDeposit(id);
    pos.open = false;
    emit PositionClosed(id);
  }

  /// @inheritdoc ITetuPawnShop
  function bid(uint256 id, uint256 amount) external onlyAllowedUsers nonReentrant override {
    Position storage pos = positions[id];
    require(pos.id == id, "TL: Wrong ID");
    require(pos.open, "TL: Position closed");
    require(pos.execution.lender == address(0), "TL: Can't bid executed position");
    if (pos.acquired.acquiredAmount != 0) {
      require(amount == pos.acquired.acquiredAmount, "TL: Wrong bid amount");
      _executeBid(pos, amount, msg.sender, msg.sender);
    } else {
      _auctionBid(pos, amount, msg.sender);
    }
  }

  /// @inheritdoc ITetuPawnShop
  function claim(uint256 id) external onlyAllowedUsers nonReentrant override {
    Position storage pos = positions[id];
    require(pos.id == id, "TL: Wrong ID");
    require(pos.execution.lender == msg.sender, "TL: Only lender can claim");
    uint256 posEnd = pos.execution.posStartBlock + pos.info.posDurationBlocks;
    require(posEnd < block.number, "TL: Too early to claim");

    _endPosition(pos);
    _transferCollateral(pos.collateral, address(this), msg.sender);
    _returnDeposit(id);
    pos.open = false;
    emit PositionClaimed(id);
  }

  /// @inheritdoc ITetuPawnShop
  function redeem(uint256 id) external onlyAllowedUsers nonReentrant override {
    Position storage pos = positions[id];
    require(pos.id == id, "TL: Wrong ID");
    require(pos.borrower == msg.sender, "TL: Only borrower can redeem");
    require(pos.execution.lender != address(0), "TL: Not executed position");

    _endPosition(pos);
    uint256 toSend = toRedeem(id);
    IERC20(pos.acquired.acquiredToken).safeTransferFrom(msg.sender, pos.execution.lender, toSend);
    _transferCollateral(pos.collateral, address(this), msg.sender);
    _returnDeposit(id);
    pos.open = false;
    emit PositionRedeemed(id);
  }

  /// @inheritdoc ITetuPawnShop
  function acceptAuctionBid(uint256 posId) external onlyAllowedUsers nonReentrant override {
    require(lastAuctionBidTs[posId] + AUCTION_DURATION < block.timestamp, "TL: Auction not ended");
    require(positionToBidIds[posId].length > 0, "TL: No bids");
    uint256 bidId = positionToBidIds[posId][positionToBidIds[posId].length - 1];

    AuctionBid storage _bid = auctionBids[bidId];
    require(_bid.id != 0, "TL: Auction bid not found");
    require(_bid.open, "TL: Bid closed");
    require(_bid.posId == posId, "TL: Wrong bid");

    Position storage pos = positions[posId];
    require(pos.borrower == msg.sender, "TL: Not borrower");
    require(pos.open, "TL: Position closed");

    pos.acquired.acquiredAmount = _bid.amount;
    _executeBid(pos, _bid.amount, address(this), _bid.lender);
    lenderOpenBids[_bid.lender][pos.id] = 0;
    _bid.open = false;
    emit AuctionBidAccepted(posId, _bid.id);
  }

  /// @inheritdoc ITetuPawnShop
  function closeAuctionBid(uint256 bidId) external onlyAllowedUsers nonReentrant override {
    AuctionBid storage _bid = auctionBids[bidId];
    require(_bid.id != 0, "TL: Auction bid not found");
    Position storage pos = positions[_bid.posId];

    bool isAuctionEnded = lastAuctionBidTs[pos.id] + AUCTION_DURATION < block.timestamp;
    bool isLastBid = false;
    if (positionToBidIds[pos.id].length != 0) {
      uint256 lastBidId = positionToBidIds[pos.id][positionToBidIds[pos.id].length - 1];
      isLastBid = lastBidId == bidId;
    }
    require((isLastBid && isAuctionEnded) || !isLastBid || !pos.open, "TL: Auction is not ended");

    lenderOpenBids[_bid.lender][pos.id] = 0;
    _bid.open = false;
    IERC20(pos.acquired.acquiredToken).safeTransfer(msg.sender, _bid.amount);
    emit AuctionBidClosed(pos.id, bidId);
  }

  // ************* INTERNAL FUNCTIONS *************

  /// @dev Transfer to this contract a deposit
  function _takeDeposit(uint256 posId) internal {
    Position storage pos = positions[posId];
    if (pos.depositToken != address(0)) {
      IERC20(pos.depositToken).safeTransferFrom(pos.borrower, address(this), pos.depositAmount);
    }
  }

  /// @dev Return to borrower a deposit
  function _returnDeposit(uint256 posId) internal {
    Position storage pos = positions[posId];
    if (pos.depositToken != address(0)) {
      IERC20(pos.depositToken).safeTransfer(pos.borrower, pos.depositAmount);
    }
  }

  /// @dev Execute bid for the open position
  ///      Transfer acquired tokens to borrower
  ///      In case of instant deal transfer collateral to lender
  function _executeBid(
    Position storage pos,
    uint256 amount,
    address acquiredMoneyHolder,
    address lender
  ) internal {
    uint256 feeAmount = amount * platformFee / DENOMINATOR;
    _transferFee(pos.acquired.acquiredToken, acquiredMoneyHolder, feeAmount);
    uint256 toSend = amount - feeAmount;
    if (acquiredMoneyHolder == address(this)) {
      IERC20(pos.acquired.acquiredToken).safeTransfer(pos.borrower, toSend);
    } else {
      IERC20(pos.acquired.acquiredToken).safeTransferFrom(acquiredMoneyHolder, pos.borrower, toSend);
    }

    pos.execution.lender = lender;
    pos.execution.posStartBlock = block.number;
    pos.execution.posStartTs = block.timestamp;
    _removePosFromIndexes(pos);

    lenderPositions[lender].push(pos.id);
    posIndexes[IndexType.LENDER_POSITION][pos.id] = lenderPositions[lender].length - 1;

    // instant buy
    if (pos.info.posDurationBlocks == 0) {
      _transferCollateral(pos.collateral, address(this), lender);
      _endPosition(pos);
    }
    emit BidExecuted(pos.id, lender, amount);
  }

  /// @dev Open an auction bid
  ///      Transfer acquired token to this contract
  function _auctionBid(Position storage pos, uint256 amount, address lender) internal {
    require(lenderOpenBids[lender][pos.id] == 0, "TL: Auction bid already exist");

    if (positionToBidIds[pos.id].length != 0) {
      // if we have bids need to check auction duration
      require(lastAuctionBidTs[pos.id] + AUCTION_DURATION > block.timestamp, "TL: Auction ended");

      uint256 lastBidId = positionToBidIds[pos.id][positionToBidIds[pos.id].length - 1];
      AuctionBid storage lastBid = auctionBids[lastBidId];
      require(lastBid.amount < amount, "TL: New bid lower than previous");
    }

    AuctionBid memory _bid = AuctionBid(
      auctionBidCounter,
      pos.id,
      lender,
      amount,
      true
    );

    positionToBidIds[pos.id].push(_bid.id);
    // write index + 1 for keep zero as empty value
    lenderOpenBids[lender][pos.id] = positionToBidIds[pos.id].length;

    IERC20(pos.acquired.acquiredToken).safeTransferFrom(msg.sender, address(this), amount);

    lastAuctionBidTs[pos.id] = block.timestamp;
    auctionBids[_bid.id] = _bid;
    auctionBidCounter++;
    emit AuctionBidOpened(pos.id, _bid.id);
  }

  /// @dev Finalize position. Remove position from indexes
  function _endPosition(Position storage pos) internal {
    require(pos.execution.posEndTs == 0, "TL: Position claimed");
    pos.execution.posEndTs = block.timestamp;
    borrowerPositions[pos.borrower].removeIndexed(posIndexes[IndexType.BORROWER_POSITION], pos.id);
    if (pos.execution.lender != address(0)) {
      lenderPositions[pos.execution.lender].removeIndexed(posIndexes[IndexType.LENDER_POSITION], pos.id);
    }

  }

  /// @dev Transfer collateral from sender to recipient
  function _transferCollateral(PositionCollateral memory _collateral, address _sender, address _recipient) internal {
    if (_collateral.collateralType == AssetType.ERC20) {
      if (_sender == address(this)) {
        IERC20(_collateral.collateralToken).safeTransfer(_recipient, _collateral.collateralAmount);
      } else {
        IERC20(_collateral.collateralToken).safeTransferFrom(_sender, _recipient, _collateral.collateralAmount);
      }
    } else if (_collateral.collateralType == AssetType.ERC721) {
      IERC721(_collateral.collateralToken).safeTransferFrom(_sender, _recipient, _collateral.collateralTokenId);
    } else {
      revert("TL: Wrong asset type");
    }
  }

  /// @dev Transfer fee to platform.
  ///      Do buyback if possible, otherwise just send to controller for manual handling
  function _transferFee(address token, address from, uint256 amount) internal {
    // little deals can have zero fees
    if (amount == 0) {
      return;
    }
    IFeeRewardForwarder forwarder = IFeeRewardForwarder(IController(controller()).feeRewardForwarder());
    address targetToken = IController(controller()).rewardToken();

    IERC20(token).safeTransferFrom(from, address(this), amount);
    IERC20(token).safeApprove(address(forwarder), 0);
    IERC20(token).safeApprove(address(forwarder), amount);

    // try to buy target token and if no luck send it to controller
    // should have gas limitation for not breaking the main logic
    try forwarder.liquidate{gas : 2_000_000}(token, targetToken, amount) returns (uint256 amountOut) {
      // send to controller
      IERC20(targetToken).safeTransfer(controller(), amountOut);
    } catch {
      // it will be manually handled in the controller
      IERC20(token).safeTransfer(controller(), amount);
    }
  }

  /// @dev Remove position from common indexes
  function _removePosFromIndexes(Position memory _pos) internal {
    openPositions.removeIndexed(posIndexes[IndexType.LIST], _pos.id);
    positionsByCollateral[_pos.collateral.collateralToken].removeIndexed(posIndexes[IndexType.BY_COLLATERAL], _pos.id);
    positionsByAcquired[_pos.acquired.acquiredToken].removeIndexed(posIndexes[IndexType.BY_ACQUIRED], _pos.id);
  }

  // ************* VIEWS **************************

  /// @inheritdoc ITetuPawnShop
  function toRedeem(uint256 id) public view override returns (uint256){
    Position memory pos = positions[id];
    return pos.acquired.acquiredAmount +
    (pos.acquired.acquiredAmount * pos.info.posFee / DENOMINATOR);
  }

  /// @inheritdoc ITetuPawnShop
  function getAssetType(address _token) public view override returns (AssetType){
    if (isERC721(_token)) {
      return AssetType.ERC721;
    } else if (isERC20(_token)) {
      return AssetType.ERC20;
    } else {
      revert("TL: Unknown asset");
    }
  }

  //noinspection NoReturn
  function isERC721(address _token) public view override returns (bool) {
    //slither-disable-next-line unused-return,variable-scope,uninitialized-local
    try IERC721(_token).supportsInterface{gas : 30000}(type(IERC721).interfaceId) returns (bool result){
      return result;
    } catch {
      return false;
    }
  }

  //noinspection NoReturn
  function isERC20(address _token) public view override returns (bool) {
    //slither-disable-next-line unused-return,variable-scope,uninitialized-local
    try IERC20(_token).totalSupply{gas : 30000}() returns (uint256){
      return true;
    } catch {
      return false;
    }
  }

  /// @inheritdoc ITetuPawnShop
  function openPositionsSize() external view override returns (uint256) {
    return openPositions.length;
  }

  /// @inheritdoc ITetuPawnShop
  function auctionBidSize(uint256 posId) external view override returns (uint256) {
    return positionToBidIds[posId].length;
  }

  function positionsByCollateralSize(address collateral) external view override returns (uint256) {
    return positionsByCollateral[collateral].length;
  }

  function positionsByAcquiredSize(address acquiredToken) external view override returns (uint256) {
    return positionsByAcquired[acquiredToken].length;
  }

  function borrowerPositionsSize(address borrower) external view override returns (uint256) {
    return borrowerPositions[borrower].length;
  }

  function lenderPositionsSize(address lender) external view override returns (uint256) {
    return lenderPositions[lender].length;
  }

  /// @inheritdoc ITetuPawnShop
  function getPosition(uint256 posId) external view override returns (Position memory) {
    return positions[posId];
  }

  /// @inheritdoc ITetuPawnShop
  function getAuctionBid(uint256 bidId) external view override returns (AuctionBid memory) {
    return auctionBids[bidId];
  }

  // ************* GOVERNANCE ACTIONS *************

  /// @inheritdoc ITetuPawnShop
  function setPlatformFee(uint256 _value) external onlyControllerOrGovernance override {
    require(_value <= PLATFORM_FEE_MAX, "TL: Too high fee");
    platformFee = _value;
  }

  /// @inheritdoc ITetuPawnShop
  function setPositionDepositAmount(uint256 _value) external onlyControllerOrGovernance override {
    positionDepositAmount = _value;
  }

  /// @inheritdoc ITetuPawnShop
  function setPositionDepositToken(address _value) external onlyControllerOrGovernance override {
    positionDepositToken = _value;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IController.sol";
import "../interface/IControllable.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  /// @notice Controller address changed
  event UpdateController(address oldValue, address newValue);

  constructor() {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param _controller Controller address
  function initializeControllable(address _controller) public initializer {
    setController(_controller);
    setCreated(block.timestamp);
  }

  function isController(address _adr) public override view returns (bool) {
    return _adr == controller();
  }

  /// @notice Return true is given address is setup as governance in Controller
  /// @param _adr Address for check
  /// @return true if given address is governance
  function isGovernance(address _adr) public override view returns (bool) {
    return IController(controller()).governance() == _adr;
  }

  // ************ MODIFIERS **********************

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(controller() == msg.sender, "not controller");
    _;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(isController(msg.sender) || isGovernance(msg.sender), "not controller or gov");
    _;
  }

  /// @dev Only smart contracts will be affected by this modifier
  ///      If it is a contract it should be whitelisted
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  /// @dev Only Reward Distributor allowed. Governance is Reward Distributor by default.
  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  /// @return adr Controller address
  function controller() public view returns (address adr) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      adr := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  /// @param _newController Controller address
  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _created block.timestamp
  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @title Interface for Tetu PawnShop contract
/// @author belbix
interface ITetuPawnShop {

  event PositionOpened(uint256 posId);
  event PositionClosed(uint256 posId);
  event BidExecuted(uint256 posId, address lender, uint256 amount);
  event AuctionBidOpened(uint256 posId, uint256 bidId);
  event PositionClaimed(uint256 posId);
  event PositionRedeemed(uint256 posId);
  event AuctionBidAccepted(uint256 posId, uint256 bidId);
  event AuctionBidClosed(uint256 posId, uint256 bidId);

  enum AssetType {
    ERC20, // 0
    ERC721 // 1
  }

  enum IndexType {
    LIST, // 0
    BY_COLLATERAL, // 1
    BY_ACQUIRED, // 2
    BORROWER_POSITION, // 3
    LENDER_POSITION // 4
  }

  struct Position {
    uint256 id;
    address borrower;
    address depositToken;
    uint256 depositAmount;
    bool open;
    PositionInfo info;
    PositionCollateral collateral;
    PositionAcquired acquired;
    PositionExecution execution;
  }

  struct PositionInfo {
    uint256 posDurationBlocks;
    uint256 posFee;
    uint256 createdBlock;
    uint256 createdTs;
  }

  struct PositionCollateral {
    address collateralToken;
    AssetType collateralType;
    uint256 collateralAmount;
    uint256 collateralTokenId;
  }

  struct PositionAcquired {
    address acquiredToken;
    uint256 acquiredAmount;
  }

  struct PositionExecution {
    address lender;
    uint256 posStartBlock;
    uint256 posStartTs;
    uint256 posEndTs;
  }

  struct AuctionBid {
    uint256 id;
    uint256 posId;
    address lender;
    uint256 amount;
    bool open;
  }

  // ****************** VIEWS ****************************

  /// @dev PosId counter. Should start from 1 for keep 0 as empty value
  function positionCounter() external view returns (uint256);

  /// @notice Return Position for given id
  /// @dev AbiEncoder not able to auto generate functions for mapping with structs
  function getPosition(uint256 posId) external view returns (Position memory);

  /// @dev Hold open positions ids. Removed when position closed
  function openPositions(uint256 index) external view returns (uint256 posId);

  /// @dev Collateral token => PosIds
  function positionsByCollateral(address collateralToken, uint256 index) external view returns (uint256 posId);

  /// @dev Acquired token => PosIds
  function positionsByAcquired(address acquiredToken, uint256 index) external view returns (uint256 posId);

  /// @dev Borrower token => PosIds
  function borrowerPositions(address borrower, uint256 index) external view returns (uint256 posId);

  /// @dev Lender token => PosIds
  function lenderPositions(address lender, uint256 index) external view returns (uint256 posId);

  /// @dev index type => PosId => index
  ///      Hold array positions for given type of array
  function posIndexes(IndexType typeId, uint256 posId) external view returns (uint256 index);

  /// @dev BidId counter. Should start from 1 for keep 0 as empty value
  function auctionBidCounter() external view returns (uint256);

  /// @notice Return auction bid for given id
  /// @dev AbiEncoder not able to auto generate functions for mapping with structs
  function getAuctionBid(uint256 bidId) external view returns (AuctionBid memory);

  /// @dev lender => PosId => positionToBidIds + 1
  ///      Lender auction position for given PosId. 0 keep for empty position
  function lenderOpenBids(address lender, uint256 posId) external view returns (uint256 index);

  /// @dev PosId => bidIds. All open and close bids for the given position
  function positionToBidIds(uint256 posId, uint256 index) external view returns (uint256 bidId);

  /// @dev PosId => timestamp. Timestamp of the last bid for the auction
  function lastAuctionBidTs(uint256 posId) external view returns (uint256 ts);

  /// @dev Return amount required for redeem position
  function toRedeem(uint256 posId) external view returns (uint256 amount);

  /// @dev Return asset type ERC20 or ERC721
  function getAssetType(address _token) external view returns (AssetType);

  function isERC721(address _token) external view returns (bool);

  function isERC20(address _token) external view returns (bool);

  /// @dev Return size of active positions
  function openPositionsSize() external view returns (uint256);

  /// @dev Return size of all auction bids for given position
  function auctionBidSize(uint256 posId) external view returns (uint256);

  function positionsByCollateralSize(address collateral) external view returns (uint256);

  function positionsByAcquiredSize(address acquiredToken) external view returns (uint256);

  function borrowerPositionsSize(address borrower) external view returns (uint256);

  function lenderPositionsSize(address lender) external view returns (uint256);

  // ************* USER ACTIONS *************

  /// @dev Borrower action. Assume approve
  ///      Open a position with multiple options - loan / instant deal / auction
  function openPosition(
    address _collateralToken,
    uint256 _collateralAmount,
    uint256 _collateralTokenId,
    address _acquiredToken,
    uint256 _acquiredAmount,
    uint256 _posDurationBlocks,
    uint256 _posFee
  ) external returns (uint256);

  /// @dev Borrower action
  ///      Close not executed position. Return collateral and deposit to borrower
  function closePosition(uint256 id) external;

  /// @dev Lender action. Assume approve for acquired token
  ///      Place a bid for given position ID
  ///      It can be an auction bid if acquired amount is zero
  function bid(uint256 id, uint256 amount) external;

  /// @dev Lender action
  ///      Transfer collateral to lender if borrower didn't return the loan
  ///      Deposit will be returned to borrower
  function claim(uint256 id) external;

  /// @dev Borrower action. Assume approve on acquired token
  ///      Return the loan to lender, transfer collateral and deposit to borrower
  function redeem(uint256 id) external;

  /// @dev Borrower action. Assume that auction ended.
  ///      Transfer acquired token to borrower
  function acceptAuctionBid(uint256 posId) external;

  /// @dev Lender action. Requires ended auction, or not the last bid
  ///      Close auction bid and transfer acquired tokens to lender
  function closeAuctionBid(uint256 bidId) external;


  /// @dev Platform fee in range 0 - 500, with denominator 10000
  function setPlatformFee(uint256 _value) external;

  /// @dev Tokens amount that need to deposit for a new position
  ///      Will be returned when position closed
  function setPositionDepositAmount(uint256 _value) external;

  /// @dev Tokens that need to deposit for a new position
  function setPositionDepositToken(address _value) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IFeeRewardForwarder {
  function distribute(uint256 _amount, address _token, address _vault) external returns (uint256);

  function notifyPsPool(address _token, uint256 _amount) external returns (uint256);

  function notifyCustomPool(address _token, address _rewardPool, uint256 _maxBuyback) external returns (uint256);

  function liquidate(address tokenIn, address tokenOut, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Library for useful functions for address and uin256 arrays
/// @author bogdoslav, belbix
library ArrayLib {

  string constant INDEX_OUT_OF_BOUND = "ArrayLib: Index out of bounds";
  string constant NOT_UNIQUE_ITEM = "ArrayLib: Not unique item";
  string constant ITEM_NOT_FOUND = "ArrayLib: Item not found";

  /// @dev Return true if given item found in address array
  function contains(address[] storage array, address _item) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) return true;
    }
    return false;
  }

  /// @dev Return true if given item found in uin256 array
  function contains(uint256[] storage array, uint256 _item) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) return true;
    }
    return false;
  }

  // -----------------------------------

  /// @dev If token not exist in the array push it, otherwise throw an error
  function addUnique(address[] storage array, address _item) internal {
    require(!contains(array, _item), NOT_UNIQUE_ITEM);
    array.push(_item);
  }

  /// @dev If token not exist in the array push it, otherwise throw an error
  function addUnique(uint256[] storage array, uint256 _item) internal {
    require(!contains(array, _item), NOT_UNIQUE_ITEM);
    array.push(_item);
  }

  // -----------------------------------

  /// @dev Call addUnique for the given items array
  function addUniqueArray(address[] storage array, address[] memory _items) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      addUnique(array, _items[i]);
    }
  }

  /// @dev Call addUnique for the given items array
  function addUniqueArray(uint256[] storage array, uint256[] memory _items) internal {
    for (uint i = 0; i < _items.length; i++) {
      addUnique(array, _items[i]);
    }
  }

  // -----------------------------------

  /// @dev Remove an item by given index.
  /// @param keepSorting If true the function will shift elements to the place of removed item
  ///                    If false will move the last element on the place of removed item
  function removeByIndex(address[] storage array, uint256 index, bool keepSorting) internal {
    require(index < array.length, INDEX_OUT_OF_BOUND);

    if (keepSorting) {
      // shift all elements to the place of removed item
      // the loop must not include the last element
      for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
      }
    } else {
      // copy the last address in the array
      array[index] = array[array.length - 1];
    }
    array.pop();
  }

  /// @dev Remove an item by given index.
  /// @param keepSorting If true the function will shift elements to the place of removed item
  ///                    If false will move the last element on the place of removed item
  function removeByIndex(uint256[] storage array, uint256 index, bool keepSorting) internal {
    require(index < array.length, INDEX_OUT_OF_BOUND);

    if (keepSorting) {
      // shift all elements to the place of removed item
      // the loop must not include the last element
      for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
      }
    } else {
      // copy the last address in the array
      array[index] = array[array.length - 1];
    }
    array.pop();
  }

  // -----------------------------------

  /// @dev Find given item in the array and call removeByIndex function if exist. If not throw an error
  function findAndRemove(address[] storage array, address _item, bool keepSorting) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        removeByIndex(array, i, keepSorting);
        return;
      }
    }
    revert(ITEM_NOT_FOUND);
  }

  /// @dev Find given item in the array and call removeByIndex function if exist. If not throw an error
  function findAndRemove(uint256[] storage array, uint256 _item, bool keepSorting) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        removeByIndex(array, i, keepSorting);
        return;
      }
    }
    revert(ITEM_NOT_FOUND);
  }

  // -----------------------------------

  /// @dev Call findAndRemove function for given item array
  function findAndRemoveArray(address[] storage array, address[] memory _items, bool keepSorting) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      findAndRemove(array, _items[i], keepSorting);
    }
  }

  /// @dev Call findAndRemove function for given item array
  function findAndRemoveArray(uint256[] storage array, uint256[] memory _items, bool keepSorting) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      findAndRemove(array, _items[i], keepSorting);
    }
  }

  // -----------------------------------

  /// @dev Remove from array the item with given id and move the last item on it place
  ///      Use with mapping for keeping indexes in correct ordering
  function removeIndexed(
    uint256[] storage array,
    mapping(uint256 => uint256) storage indexes,
    uint256 id
  ) internal {
    uint256 lastId = array[array.length - 1];
    uint256 index = indexes[id];
    indexes[lastId] = index;
    indexes[id] = type(uint256).max;
    array[index] = lastId;
    array.pop();
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultAndStrategy(address _vault, address _strategy) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function addToWhiteListMulti(address[] calldata _targets) external;

  function addToWhiteList(address _target) external;

  function removeFromWhiteListMulti(address[] calldata _targets) external;

  function removeFromWhiteList(address _target) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);
}

