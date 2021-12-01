/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2; // solhint-disable-line

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






/**
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuard {
  using Address for address payable;

  mapping(address => uint256) private pendingWithdrawals;

  event WithdrawPending(address indexed user, uint256 amount);
  event Withdrawal(address indexed user, uint256 amount);

  /**
   * @notice Returns how much funds are available for manual withdraw due to failed transfers.
   */
  function getPendingWithdrawal(address user) public view returns (uint256) {
    return pendingWithdrawals[user];
  }

  /**
   * @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
   */
  function withdraw() public {
    withdrawFor(payable(msg.sender));
  }

  /**
   * @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
   */
  function withdrawFor(address payable user) public nonReentrant {
    uint256 amount = pendingWithdrawals[user];
    require(amount > 0, "No funds are pending withdrawal");
    pendingWithdrawals[user] = 0;
    user.sendValue(amount);
    emit Withdrawal(user, amount);
  }

  /**
   * @dev Attempt to send a user ETH with a reasonably low gas limit of 20k,
   * which is enough to send to contracts as well.
   */
  function _sendValueWithFallbackWithdrawWithLowGasLimit(address user, uint256 amount) internal {
    _sendValueWithFallbackWithdraw(user, amount, 20000);
  }

  /**
   * @dev Attempt to send a user or contract ETH with a moderate gas limit of 90k,
   * which is enough for a 5-way split.
   */
  function _sendValueWithFallbackWithdrawWithMediumGasLimit(address user, uint256 amount) internal {
    _sendValueWithFallbackWithdraw(user, amount, 210000);
  }

  /**
   * @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdrawal.
   */
  function _sendValueWithFallbackWithdraw(
    address user,
    uint256 amount,
    uint256 gasLimit
  ) private {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = payable(user).call{ value: amount, gas: gasLimit }("");
    if (!success) {
      // Record failed sends for a withdrawal later
      // Transfers could fail if sent to a multisig with non-trivial receiver logic
      // solhint-disable-next-line reentrancy
      pendingWithdrawals[user] = pendingWithdrawals[user] + amount;
      emit WithdrawPending(user, amount);
    }
  }
}





interface ICAAsset {

  function ownerOf(uint256 _tokenId) external view returns (address _owner);
  function exists(uint256 _tokenId) external view returns (bool _exists);
  
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from , address _to, uint256 _tokenId, bytes memory _data) external;

  function editionOfTokenId(uint256 _tokenId) external view returns (uint256 tokenId);

  function artistCommission(uint256 _tokenId) external view returns (address _artistAccount, uint256 _artistCommission);

  function editionOptionalCommission(uint256 _tokenId) external view returns (uint256 _rate, address _recipient);

  function mint(address _to, uint256 _editionNumber) external returns (uint256);

  function approve(address _to, uint256 _tokenId) external;



  function createActiveEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string memory _tokenUri,
    uint256 _totalAvailable
  ) external returns (bool);

  function artistsEditions(address _artistsAccount) external returns (uint256[] memory _editionNumbers);

  function totalAvailableEdition(uint256 _editionNumber) external returns (uint256);

  function highestEditionNumber() external returns (uint256);

  function updateOptionalCommission(uint256 _editionNumber, uint256 _rate, address _recipient) external;

  function updateStartDate(uint256 _editionNumber, uint256 _startDate) external;

  function updateEndDate(uint256 _editionNumber, uint256 _endDate) external;

  function updateEditionType(uint256 _editionNumber, uint256 _editionType) external;
}





/**
 * @dev Constant values shared across mixins.
 */
abstract contract Constants {
  uint32 internal constant BASIS_POINTS = 10000;
}







/**
 * @notice A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is
  Constants,
  SendValueWithFallbackWithdraw
{

  event MarketFeesUpdated(
    uint32 caPoints,
    uint32 artistPoints,
    uint32 sellerPoints,
    uint32 auctionAwardPoints,
    uint32 sharePoints
  );

  ICAAsset immutable caAsset;
  uint32 private caPoints;
  uint32 private sharePoints;
  uint32 private artistPoints;
  uint32 private sellerPoints;

  uint32 private auctionAwardPoints;
  
  uint256 public withdrawThreshold;

  address payable private treasury;


  mapping(address => uint256) public awards;

  mapping(uint256 => bool) private nftContractToTokenIdToFirstSaleCompleted;


  event AuctionAwardUpdated(uint256 indexed auctionId, address indexed bidder, uint256 award);
  event ShareAwardUpdated(address indexed share, uint256 award);

  /**
   * @dev Called once after the initial deployment to set the CART treasury address.
   */
  constructor(
    ICAAsset _caAsset,
    address payable _treasury) {
    require(_treasury != address(0), "NFTMarketFees: Address not zero");
    caAsset = _caAsset;
    treasury = _treasury;

    caPoints = 150;
    sharePoints = 100;
    artistPoints = 1000;
    sellerPoints = 8250;
    auctionAwardPoints = 500;

    withdrawThreshold = 0.1 ether;
  }

  function setCATreasury(address payable _treasury) external {
    require(_treasury != msg.sender, "NFTMarketFees: no permission");
    require(_treasury != address(0), "NFTMarketFees: Address not zero");
    treasury = _treasury;
  }

  /**
   * @notice Returns the address of the CART treasury.
   */
  function getCATreasury() public view returns (address payable) {
    return treasury;
  }

  /**
   * @notice Returns true if the given NFT has not been sold in this market previously and is being sold by the creator.
   */
  function getIsPrimary(uint256 tokenId) public view returns (bool) {
    return !nftContractToTokenIdToFirstSaleCompleted[tokenId];
  }

  function getArtist(uint256 tokenId) public view returns (address artist) {
      uint256 editionNumber = caAsset.editionOfTokenId(tokenId);
      (artist,) = caAsset.artistCommission(editionNumber);
  }


  /**
   * @notice Returns how funds will be distributed for a sale at the given price point.
   * @dev This could be used to present exact fee distributing on listing or before a bid is placed.
   */
  function getFees(uint tokenId, uint256 price)
    public
    view
    returns (
      uint256 caFee,
      uint256 artistFee,
      uint256 sellerFee,
      uint256 auctionFee,
      uint256 shareFee
    )
  {
    sellerFee = sellerPoints * price / BASIS_POINTS;
    // 首次拍卖的时候，作家即卖家，联名者需参与分成
    if (!nftContractToTokenIdToFirstSaleCompleted[tokenId]) {
        caFee = (caPoints + artistPoints) * price / BASIS_POINTS;
        artistFee = sellerFee;
        sellerFee = 0;
    } else {
        caFee = caPoints * price / BASIS_POINTS;
        artistFee = artistPoints * price / BASIS_POINTS;
    }

    auctionFee = auctionAwardPoints * price / BASIS_POINTS;
    shareFee = sharePoints * price / BASIS_POINTS;
  }

  function withdrawFunds(address to) external {
    require(awards[msg.sender] >= withdrawThreshold, "NFTMarketFees: under withdrawThreshold");
    uint wdAmount= awards[msg.sender];
    awards[msg.sender] = 0;
    _sendValueWithFallbackWithdrawWithMediumGasLimit(to, wdAmount);
  }

  function _distributeBidFunds(
      uint256 lastPrice,
      uint256 auctionId,
      uint256 price,
      address bidder
  ) internal {
      uint award = auctionAwardPoints * (price - lastPrice) / BASIS_POINTS;
      awards[bidder] += award;

      emit AuctionAwardUpdated(auctionId, bidder, award);
  }

  /**
   * @dev Distributes funds to foundation, creator, and NFT owner after a sale.
   */
  function _distributeFunds(
    uint256 tokenId,
    address seller,
    address shareUser,
    uint256 price
  ) internal {
    (uint caFee, uint artistFee, uint sellerFee, ,uint shareFee) = getFees(tokenId, price);
    
    if (shareUser == address(0)) {
      _sendValueWithFallbackWithdrawWithLowGasLimit(treasury, caFee + shareFee);
    } else {
      _sendValueWithFallbackWithdrawWithLowGasLimit(treasury, caFee);
      awards[shareUser] += shareFee;

      emit ShareAwardUpdated(shareUser, shareFee);
    }

      uint256 editionNumber = caAsset.editionOfTokenId(tokenId);
      (address artist, uint256 artistRate) = caAsset.artistCommission(editionNumber);
      (uint256 optionalRate, address optionalRecipient) = caAsset.editionOptionalCommission(editionNumber);
    
      if (optionalRecipient == address(0)) { 
        if (artist == seller) {
          _sendValueWithFallbackWithdrawWithMediumGasLimit(seller, artistFee + sellerFee);
        } else {
          _sendValueWithFallbackWithdrawWithMediumGasLimit(seller, sellerFee);
          _sendValueWithFallbackWithdrawWithMediumGasLimit(artist, artistFee);
        }
      } else {
        uint optionalFee = artistFee * optionalRate / (optionalRate + artistRate);
        if (optionalFee > 0) {
          _sendValueWithFallbackWithdrawWithMediumGasLimit(optionalRecipient, optionalFee);
        }

        if (artist == seller) {
          _sendValueWithFallbackWithdrawWithMediumGasLimit(seller, artistFee + sellerFee - optionalFee);
        } else {
          _sendValueWithFallbackWithdrawWithMediumGasLimit(seller, sellerFee);
          _sendValueWithFallbackWithdrawWithMediumGasLimit(artist, artistFee - optionalFee);
        }
      }

    // Anytime fees are distributed that indicates the first sale is complete,
    // which will not change state during a secondary sale.
    // This must come after the `getFees` call above as this state is considered in the function.
    nftContractToTokenIdToFirstSaleCompleted[tokenId] = true;
  }


  /**
   * @notice Returns the current fee configuration in basis points.
   */
  function getFeeConfig()
    public
    view
    returns (
      uint32 ,
      uint32 ,
      uint32 ,
      uint32 ,
      uint32) {
    return (caPoints, artistPoints, sellerPoints, auctionAwardPoints, sharePoints);
  }

  function _updateWithdrawThreshold(uint256 _withdrawalThreshold) internal {
    withdrawThreshold = _withdrawalThreshold;
  }

  /**
   * @notice Allows CA to change the market fees.
   */
  function _updateMarketFees(
    uint32 _caPoints,
    uint32 _artistPoints,
    uint32 _sellerPoints,
    uint32 _auctionAwardPoints,
    uint32 _sharePoints
  ) internal {
    require(_caPoints + _artistPoints + _sellerPoints + _auctionAwardPoints + _sharePoints < BASIS_POINTS, "NFTMarketFees: Fees >= 100%");

    caPoints = caPoints;
    artistPoints = _artistPoints;
    sellerPoints = _sellerPoints;
    auctionAwardPoints = _auctionAwardPoints;
    sharePoints = _sharePoints;

    emit MarketFeesUpdated(
      _caPoints,
      _artistPoints,
      _sellerPoints,
      _auctionAwardPoints,
      _sharePoints
    );
  }

}





/**
 * @notice An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarketAuction {
  /**
   * @dev A global id for auctions of any type.
   */
  uint256 private nextAuctionId = 1;


  function _getNextAndIncrementAuctionId() internal returns (uint256) {
    return nextAuctionId++;
  }

}





/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAccessControl {

  function isCAAdmin(address _operator) external view returns (bool);
  function hasRole(address _operator, uint8 _role) external view returns (bool);
  function canPlayRole(address _operator, uint8 _role) external view returns (bool);
}










/**
 * @notice Manages a reserve price countdown auction for NFTs.
 */
abstract contract NFTMarketReserveAuction is
  Constants,
  ReentrancyGuard,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction
{

  struct ReserveAuction {
    uint256 tokenId;
    address seller;
    uint32 duration;
    uint32 extensionDuration;
    uint32 endTime;
    address bidder;
    uint256 amount;
    address shareUser;
  }

  mapping(uint256 => uint256) private nftTokenIdToAuctionId;
  mapping(uint256 => ReserveAuction) private auctionIdToAuction;

  IAccessControl public immutable accessControl;

  uint32 private _minPercentIncrementInBasisPoints;

  uint32 private _duration;

  // Cap the max duration so that overflows will not occur
  uint32 private constant MAX_MAX_DURATION = 1000 days;

  uint32 private constant EXTENSION_DURATION = 15 minutes;

  event ReserveAuctionConfigUpdated(
    uint32 minPercentIncrementInBasisPoints,
    uint256 maxBidIncrementRequirement,
    uint256 duration,
    uint256 extensionDuration,
    uint256 goLiveDate
  );

  event ReserveAuctionCreated(
    address indexed seller,
    uint256 indexed tokenId,
    uint256 indexed auctionId,
    uint256 duration,
    uint256 extensionDuration,
    uint256 reservePrice
    
  );
  event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);
  event ReserveAuctionCanceled(uint256 indexed auctionId);
  event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  event ReserveAuctionFinalized(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 tokenId,
    uint256 amount
  );
  event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
  event ReserveAuctionSellerMigrated(
    uint256 indexed auctionId,
    address indexed originalSellerAddress,
    address indexed newSellerAddress
  );

  modifier onlyValidAuctionConfig(uint256 reservePrice) {
    require(reservePrice > 0, "NFTMarketReserveAuction: Reserve price must be at least 1 wei");
    _;
  }

  modifier onlyCAAdmin(address user) {
    require(accessControl.isCAAdmin(user), "CAAdminRole: caller does not have the Admin role");
    _;
  }

  constructor(IAccessControl access) {
    _duration = 24 hours; // A sensible default value
    accessControl = access;
    _minPercentIncrementInBasisPoints = 1000;
  }

  /**
   * @notice Returns auction details for a given auctionId.
   */
  function getReserveAuction(uint256 auctionId) public view returns (ReserveAuction memory) {
    return auctionIdToAuction[auctionId];
  }

  /**
   * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
   * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
   */
  function getReserveAuctionIdFor(uint256 tokenId) public view returns (uint256) {
    return nftTokenIdToAuctionId[tokenId];
  }

  /**
   * @dev Returns the seller that put a given NFT into escrow,
   * or bubbles the call up to check the current owner if the NFT is not currently in escrow.
   */
  function getSellerFor(uint256 tokenId)
    internal
    view
    virtual
    returns (address)
  {
    address seller = auctionIdToAuction[nftTokenIdToAuctionId[tokenId]].seller;
    if (seller == address(0)) {
      return caAsset.ownerOf(tokenId);
    }
    return seller;
  }

  /**
   * @notice Returns the current configuration for reserve auctions.
   */
  function getReserveAuctionConfig() public view returns (uint256 minPercentIncrementInBasisPoints, uint256 duration) {
    minPercentIncrementInBasisPoints = _minPercentIncrementInBasisPoints;
    duration = _duration;
  }



  function _updateReserveAuctionConfig(uint32 minPercentIncrementInBasisPoints, uint32 duration) internal {
    require(minPercentIncrementInBasisPoints <= BASIS_POINTS, "NFTMarketReserveAuction: Min increment must be <= 100%");
    // Cap the max duration so that overflows will not occur
    require(duration <= MAX_MAX_DURATION, "NFTMarketReserveAuction: Duration must be <= 1000 days");
    require(duration >= EXTENSION_DURATION, "NFTMarketReserveAuction: Duration must be >= EXTENSION_DURATION");
    _minPercentIncrementInBasisPoints = minPercentIncrementInBasisPoints;
    _duration = duration;

    // We continue to emit unused configuration variables to simplify the subgraph integration.
    emit ReserveAuctionConfigUpdated(minPercentIncrementInBasisPoints, 0, duration, EXTENSION_DURATION, 0);
  }

  /**
   * @notice Creates an auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   */
  function createReserveAuction(
    uint256 tokenId,
    address seller,
    uint256 reservePrice
  ) public onlyValidAuctionConfig(reservePrice) nonReentrant {
    
    // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed
    uint256 auctionId = _getNextAndIncrementAuctionId();
    nftTokenIdToAuctionId[tokenId] = auctionId;
    auctionIdToAuction[auctionId] = ReserveAuction(
      tokenId,
      seller,
      _duration,
      EXTENSION_DURATION,
      0, // endTime is only known once the reserve price is met
      address(0), // bidder is only known once a bid has been placed
      reservePrice,
      address(0)
    );

    caAsset.transferFrom(msg.sender, address(this), tokenId);

    emit ReserveAuctionCreated(
      seller,
      tokenId,
      auctionId,
      _duration,
      EXTENSION_DURATION,
      reservePrice
    );
  }

  /**
   * @notice If an auction has been created but has not yet received bids, the configuration
   * such as the reservePrice may be changed by the seller.
   */
  function updateReserveAuction(uint256 auctionId, uint256 reservePrice) public onlyValidAuctionConfig(reservePrice) {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    require(auction.seller == msg.sender, "NFTMarketReserveAuction: Not your auction");
    require(auction.endTime == 0, "NFTMarketReserveAuction: Auction in progress");

    auction.amount = reservePrice;

    emit ReserveAuctionUpdated(auctionId, reservePrice);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
   * The NFT is returned to the seller from escrow.
   */
  function cancelReserveAuction(uint256 auctionId) public nonReentrant {
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    require(auction.seller == msg.sender, "NFTMarketReserveAuction: Not your auction");
    require(auction.endTime == 0, "NFTMarketReserveAuction: Auction in progress");

    delete nftTokenIdToAuctionId[auction.tokenId];
    delete auctionIdToAuction[auctionId];

    caAsset.transferFrom(address(this), auction.seller, auction.tokenId);

    emit ReserveAuctionCanceled(auctionId);
  }

  /**
   * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   */
  function placeBid(uint256 auctionId, address shareUser) public payable nonReentrant {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    require(auction.amount != 0, "NFTMarketReserveAuction: Auction not found");

    if (auction.endTime == 0) {
      // If this is the first bid, ensure it's >= the reserve price
      require(auction.amount <= msg.value, "NFTMarketReserveAuction: Bid must be at least the reserve price");
    } else {
      // If this bid outbids another, confirm that the bid is at least x% greater than the last
      require(auction.endTime >= block.timestamp, "NFTMarketReserveAuction: Auction is over");
      require(auction.bidder != msg.sender, "NFTMarketReserveAuction: You already have an outstanding bid");
      uint256 minAmount = _getMinBidAmountForReserveAuction(auction.amount);
      require(msg.value >= minAmount, "NFTMarketReserveAuction: Bid amount too low");
    }

    if (auction.endTime == 0) {
      auction.amount = msg.value;
      auction.bidder = msg.sender;
      // On the first bid, the endTime is now + duration
      auction.endTime = uint32(block.timestamp) + auction.duration;
      auction.shareUser = shareUser;

      _distributeBidFunds(0, auctionId, msg.value, msg.sender);
    } else {
      // Cache and update bidder state before a possible reentrancy (via the value transfer)
      uint256 originalAmount = auction.amount;
      address originalBidder = auction.bidder;
      auction.amount = msg.value;
      auction.bidder = msg.sender;
      auction.shareUser = shareUser;

      // When a bid outbids another, check to see if a time extension should apply.
      if (auction.endTime - uint32(block.timestamp) < auction.extensionDuration) {
        auction.endTime = uint32(block.timestamp) + auction.extensionDuration;
      }
      
      _distributeBidFunds(originalAmount, auctionId, msg.value, msg.sender);

      // Refund the previous bidder
      _sendValueWithFallbackWithdrawWithLowGasLimit(originalBidder, originalAmount);
    }

    emit ReserveAuctionBidPlaced(auctionId, msg.sender, msg.value, auction.endTime);
  }

  /**
   * @notice Once the countdown has expired for an auction, anyone can settle the auction.
   * This will send the NFT to the highest bidder and distribute funds.
   */
  function finalizeReserveAuction(uint256 auctionId) public nonReentrant {
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    require(auction.endTime > 0, "NFTMarketReserveAuction: Auction was already settled");
    require(auction.endTime < uint32(block.timestamp), "NFTMarketReserveAuction: Auction still in progress");

    delete nftTokenIdToAuctionId[auction.tokenId];
    delete auctionIdToAuction[auctionId];

    caAsset.transferFrom(address(this), auction.bidder, auction.tokenId);

    _distributeFunds(auction.tokenId, auction.seller, auction.shareUser, auction.amount);

    emit ReserveAuctionFinalized(auctionId, auction.seller, auction.bidder, auction.tokenId, auction.amount);
  }


  /**
   * @notice Returns the minimum amount a bidder must spend to participate in an auction.
   */
  function getMinBidAmount(uint256 auctionId) public view returns (uint256) {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinBidAmountForReserveAuction(auction.amount);
  }

  /**
   * @dev Determines the minimum bid amount when outbidding another user.
   */
  function _getMinBidAmountForReserveAuction(uint256 currentBidAmount) private view returns (uint256) {
    uint256 minIncrement = currentBidAmount * _minPercentIncrementInBasisPoints / BASIS_POINTS;
    if (minIncrement == 0) {
      // The next bid must be at least 1 wei greater than the current.
      return currentBidAmount + 1;
    }
    return minIncrement + currentBidAmount;
  }

  /**
   * @notice Allows Foundation to cancel an auction, refunding the bidder and returning the NFT to the seller.
   * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
   */
  function adminCancelReserveAuction(uint256 auctionId, string memory reason) public onlyCAAdmin(msg.sender) {
    require(bytes(reason).length > 0, "NFTMarketReserveAuction: Include a reason for this cancellation");
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    require(auction.amount > 0, "NFTMarketReserveAuction: Auction not found");

    delete nftTokenIdToAuctionId[auction.tokenId];
    delete auctionIdToAuction[auctionId];

    caAsset.transferFrom(address(this), auction.seller, auction.tokenId);
    if (auction.bidder != address(0)) {
      _sendValueWithFallbackWithdrawWithMediumGasLimit(auction.bidder, auction.amount);
    }

    emit ReserveAuctionCanceledByAdmin(auctionId, reason);
  }
}










/**
 * @title A market for NFTs on CA.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract CANFTMarket is
  ReentrancyGuard,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction,
  NFTMarketReserveAuction
{
  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This farms the initialize call out to inherited contracts as needed.
   */
  constructor (IAccessControl access,
    ICAAsset caAsset,
    address payable treasury)
    NFTMarketFees(caAsset, treasury)
    NFTMarketReserveAuction(access) {
  }


  /**
   * @notice Allows Foundation to update the market configuration.
   */
  function adminUpdateConfig(
    uint32 minPercentIncrementInBasisPoints,
    uint32 duration,
    uint32 _caPoints,
    uint32 _artistPoints,
    uint32 _sellerPoints,
    uint32 _auctionAwardPoints,
    uint32 _sharePoints
  ) public onlyCAAdmin(msg.sender) {
    _updateReserveAuctionConfig(minPercentIncrementInBasisPoints, duration);
    _updateMarketFees(_caPoints, _artistPoints, _sellerPoints, _auctionAwardPoints, _sharePoints);
  }

  function adminUpdateWithdrawThreshold(uint256 _withdrawalThreshold) public onlyCAAdmin(msg.sender) {
    _updateWithdrawThreshold(_withdrawalThreshold);
  }

    /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyCAAdmin(msg.sender) public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    payable(_withdrawalAccount).transfer(address(this).balance);
  }

}