//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import './interfaces/IPawnShop.sol';
import './libraries/PawnShopLibrary.sol';

contract PawnShop is IPawnShop, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    struct FeeRate {
        uint256 lenderFeeRate;
        uint256 serviceFeeRate;
    }

    struct Offer {
        address owner;
        address lender;
        uint256 borrowAmount;
        address borrowToken;
        address to;
        uint256 startApplyAt;
        uint256 closeApplyAt;
        uint256 borrowPeriod;
        uint256 startLendingAt;
        uint256 liquidationAt;
        uint256 lenderFeeRate;
        uint256 serviceFeeRate;
        uint256 nftType;
        uint256 nftAmount;
        address collection;
        uint256 tokenId;
        bool    isLending;
    }

    // mapping(address => mapping(uint256 => Offer)) private offers;

    mapping(bytes16 => Offer) private offers;

    mapping(address => FeeRate) private _tokenFeeRates;

    address payable public treasury;

    uint256 constant public  LIQUIDATION_PERIOD_IN_SECONDS = 2592000;

    constructor(address payable _treasury) {
        treasury = _treasury;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev functions affected by this modifier can only be invoked if the provided _amount input parameter
     * is not zero.
     * @param _amount the amount provided
     **/
    modifier onlyAmountGreaterThanZero(uint256 _amount) {
        requireAmountGreaterThanZero(_amount);
        _;
    }

    /**
    * @dev functions affected by this modifier can only be invoked if the provided borrowPeriod input parameter
    * is not zero.
    **/
    modifier onlyBorrowPeriodGreaterThanZero(uint256 _borrowPeriod) {
        requireBorrowPeriodGreaterThanZero(_borrowPeriod);
        _;
    }

    function getSystemTokenFeeRates(address _token) external view returns (FeeRate memory) {
        return _tokenFeeRates[_token];
    }

    function setTokenFeeRates(
        address _token,
        uint256 _lenderFeeRate,
        uint256 _serviceFeeRate
    ) external override onlyOwner {
        if (_lenderFeeRate > 0) _tokenFeeRates[_token].lenderFeeRate = _lenderFeeRate;
        if (_serviceFeeRate > 0) _tokenFeeRates[_token].serviceFeeRate = _serviceFeeRate;
    }

    function getOffer(bytes16 tokenId) external view returns(Offer memory offer){
        return offers[tokenId];
    }

    function createOffer721(
        bytes16 _offerId,
        address _collection,
        uint256 _tokenId,
        address _to,
        uint256 _borrowAmount,
        address _borrowToken,
        uint256 _borrowPeriod,
        uint256 _startApplyAt,
        uint256 _closeApplyAt
    )
        external
        override
        whenNotPaused
        nonReentrant
        onlyAmountGreaterThanZero(_borrowAmount)
        onlyBorrowPeriodGreaterThanZero(_borrowPeriod)
    {
        require(IERC721(_collection).getApproved(_tokenId) == address(this), "please approve NFT first");
        // Send NFT to this contract to escrow
        _nftSafeTransfer(msg.sender, address(this), _collection, _tokenId, 1, 721);
        _createOffer(_offerId, _collection, _tokenId, _to, _borrowAmount, _borrowToken, _borrowPeriod, _startApplyAt, _closeApplyAt, 1, 721);
    }

    function createOffer1155(        
        bytes16 _offerId,
        address _collection,
        uint256 _tokenId,
        address _to,
        uint256 _borrowAmount,
        address _borrowToken,
        uint256 _borrowPeriod,
        uint256 _startApplyAt,
        uint256 _closeApplyAt,
        uint256 _nftAmount
    ) external
        override
        whenNotPaused
        nonReentrant
        onlyAmountGreaterThanZero(_borrowAmount)
        onlyBorrowPeriodGreaterThanZero(_borrowPeriod) 
    {
        require(IERC1155(_collection).isApprovedForAll(msg.sender, address(this)) == true, "please approve NFT first");
        // Send NFT to this contract to escrow
        _nftSafeTransfer(msg.sender, address(this), _collection, _tokenId, _nftAmount, 1155);
        _createOffer(_offerId, _collection, _tokenId, _to, _borrowAmount, _borrowToken, _borrowPeriod, _startApplyAt, _closeApplyAt, _nftAmount, 1155);
    }

    function _nftSafeTransfer(address _from, address _to, address _collection, uint256 _tokenId, uint256 _nftAmount, uint256 _nftType) internal {
        if (_nftType  == 1155) {
            IERC1155(_collection).safeTransferFrom(_from, _to, _tokenId, _nftAmount, "0x");
        } else if (_nftType == 721) {
            IERC721(_collection).transferFrom(_from, _to, _tokenId);
        }
    }

    function _createOffer(
        bytes16 _offerId,
        address _collection,
        uint256 _tokenId,
        address _to,
        uint256 _borrowAmount,
        address _borrowToken,
        uint256 _borrowPeriod,
        uint256 _startApplyAt,
        uint256 _closeApplyAt,
        uint256 _nftAmount,
        uint256 _nftType
    )
        internal
        whenNotPaused
        onlyAmountGreaterThanZero(_borrowAmount)
        onlyBorrowPeriodGreaterThanZero(_borrowPeriod)
    {
        // // Validations
        if (_closeApplyAt != 0) require(_closeApplyAt >= block.timestamp, "invalid closed-apply time");

        require(_borrowToken != address(0), "invalid-payment-token");
        require(_tokenFeeRates[_borrowToken].lenderFeeRate != 0, "invalid-payment-token");
        require(offers[_offerId].collection == address(0), "offer-existed");
        {
            (uint256 lenderFee, uint256 serviceFee) = quoteFees(_borrowAmount, _borrowToken, _borrowPeriod);
            require(lenderFee > 0, "required minimum lender fee");
            require(serviceFee> 0, "required minimum service fee");
        }

        // Init offer
        Offer storage offer = offers[_offerId];

        // Set offer informations
        offer.owner = msg.sender;
        offer.borrowAmount = _borrowAmount;
        offer.borrowToken = _borrowToken;
        offer.to = _to;
        offer.collection = _collection;
        offer.tokenId = _tokenId;
        offer.startApplyAt = _startApplyAt;
        if (offer.startApplyAt == 0) offer.startApplyAt = block.timestamp;
        offer.closeApplyAt = _closeApplyAt;
        offer.borrowPeriod = _borrowPeriod;
        offer.lenderFeeRate = _tokenFeeRates[_borrowToken].lenderFeeRate;
        offer.serviceFeeRate = _tokenFeeRates[_borrowToken].serviceFeeRate;
        offer.nftType = _nftType;
        offer.nftAmount = _nftAmount;

        // Emit event
        emit OfferCreated(
            _offerId,
            offer.collection,
            offer.tokenId,
            msg.sender,
            offer.to,
            offer.borrowAmount,
            offer.borrowToken,
            offer.startApplyAt,
            offer.closeApplyAt,
            offer.borrowPeriod,
            offer.nftType,
            offer.nftAmount
        );
    }
    // Lender call this function to accepted the offer immediately
    function applyOffer(
        bytes16 _offerId,
        uint256 _borrowAmount
    ) external whenNotPaused override nonReentrant {
        Offer storage offer = offers[_offerId];

        // Validations
        require(offer.borrowAmount == _borrowAmount, "offer borrow amount has changed");
        require(offer.isLending == false, "apply-non-open-offer");
        if (offer.closeApplyAt != 0) require(offer.closeApplyAt >= block.timestamp, "expired-order");

        // Update offer informations
        offer.isLending = true;
        offer.lender = msg.sender;
        offer.startLendingAt = block.timestamp;

        // Calculate Fees
        (uint256 lenderFee, uint256 serviceFee, ) = quoteApplyAmounts(_offerId);
        uint256 borrowAmountAfterFee = offer.borrowAmount.sub(lenderFee).sub(serviceFee);

        // Send amount to borrower and fee to admin
        IERC20(offer.borrowToken).transferFrom(msg.sender, offer.to, borrowAmountAfterFee);
        IERC20(offer.borrowToken).transferFrom(msg.sender, treasury, serviceFee);

        // Update end times
        offer.liquidationAt = offer.startLendingAt.add(offer.borrowPeriod).add(LIQUIDATION_PERIOD_IN_SECONDS);

        emit OfferApplied(_offerId, offer.collection, offer.tokenId, msg.sender);
    }

    // Borrower pay
    function repay(bytes16 _offerId)
    external
    override
    nonReentrant
    {
        Offer storage offer = offers[_offerId];

        // Validations
        require(offer.isLending == true, "repay-in-progress-offer-only");
        require(offer.startLendingAt.add(offer.borrowPeriod) >= block.timestamp, "overdue loan");
        require(offer.owner == msg.sender, "only owner can repay and get NFT");

        // Repay token to lender
        IERC20(offer.borrowToken).transferFrom(
            msg.sender,
            offer.lender,
            offer.borrowAmount
        );
        // Send NFT back to borrower
        _nftSafeTransfer(address(this), msg.sender, offer.collection, offer.tokenId, offer.nftAmount, offer.nftType);

        // clone amount value to emit
        uint256 borrowAmount = offer.borrowAmount;

        emit Repay(_offerId, offer.collection, offer.tokenId, msg.sender, borrowAmount);
    }

    function updateOffer(
        bytes16 _offerId,
        uint256 _borrowAmount,
        uint256 _borrowPeriod
    ) external whenNotPaused override {
        Offer storage offer = offers[_offerId];

        // Validations
        require(offer.owner == msg.sender, "only owner can update offer");
        require(offer.lender == address(0), "only update unapply offer");

        // Update offer if has changed?
        if (_borrowPeriod > 0) offer.borrowPeriod = _borrowPeriod;
        if (_borrowAmount > 0) offer.borrowAmount = _borrowAmount;

        (uint256 lenderFee, uint256 serviceFee) = quoteFees(offer.borrowAmount, offer.borrowToken, offer.borrowPeriod);

        // Validations
        require(lenderFee > 0, "required minimum lender fee");
        require(serviceFee> 0, "required minimum service fee");

        emit OfferUpdated(_offerId, offer.collection, offer.tokenId, offer.borrowAmount, offer.borrowPeriod);
    }

    function cancelOffer(bytes16 _offerId) external whenNotPaused override {
        Offer storage offer = offers[_offerId];

        // Validations
        require(
            offer.owner == msg.sender,
            "only owner can cancel offer"
        );
        require(offer.lender == address(0), "only update unapply offer");

        // Send NFT back to borrower
        _nftSafeTransfer(address(this), msg.sender, offer.collection, offer.tokenId, offer.nftAmount, offer.nftType);

        emit OfferCancelled(_offerId, offer.collection, offer.tokenId);
    }

    //
    // @dev
    // Borrower can know how much they can receive before creating offer
    //
    function quoteFees(uint256 _borrowAmount, address _token, uint256 _lendingPeriod)
    public
    override
    view
    returns (uint256 lenderFee, uint256 serviceFee)
    {
        lenderFee = PawnShopLibrary.getFeeAmount(_borrowAmount, _tokenFeeRates[_token].lenderFeeRate, _lendingPeriod);
        serviceFee = PawnShopLibrary.getFeeAmount(_borrowAmount, _tokenFeeRates[_token].serviceFeeRate, _lendingPeriod);
    }

    // Borrower call this function to estimate how much fees need to paid to extendTimes
    function quoteExtendFees(bytes16 _tokenId, uint256 _borrowPeriod)
    public
    override
    view
    returns (uint256 lenderFee, uint256 serviceFee)
    {
        Offer memory offer = offers[_tokenId];
        (lenderFee, serviceFee) = quoteFees(offer.borrowAmount, offer.borrowToken, _borrowPeriod);
    }

    //
    // @dev
    // approvedAmount: Token amount lender need to approved to take this offer
    //
    function quoteApplyAmounts(bytes16 _offerId)
    public
    override
    view
    returns (uint256 lenderFee, uint256 serviceFee, uint256 approvedAmount)
    {
        Offer memory offer = offers[_offerId];
        (lenderFee, serviceFee) = quoteFees(offer.borrowAmount, offer.borrowToken, offer.borrowPeriod);
        approvedAmount = offer.borrowAmount.sub(lenderFee);
    }

    // Borrower interest only and extend deadline
    function extendLendingTime(
        bytes16 _offerId,
        uint256 _extendPeriod
    ) external override nonReentrant onlyBorrowPeriodGreaterThanZero(_extendPeriod) {
        Offer storage offer = offers[_offerId];

        // Validations
        require(offer.owner == msg.sender, "only-owner-can-extend-lending-time");
        require(offer.isLending == true, "can only extend in progress offer");
        require(offer.startLendingAt.add(offer.borrowPeriod) >= block.timestamp, "lending-time-closed");

        // Update fees if has changed
        {
            uint256 lenderFeeRate = _tokenFeeRates[offer.borrowToken].lenderFeeRate;
            uint256 serviceFeeRate = _tokenFeeRates[offer.borrowToken].serviceFeeRate;
            if (lenderFeeRate != offer.lenderFeeRate) offer.lenderFeeRate = lenderFeeRate;
            if (serviceFeeRate != offer.serviceFeeRate) offer.serviceFeeRate = serviceFeeRate;
        }

        // Calculate Fees
        (uint256 lenderFee, uint256 serviceFee) = quoteFees(offer.borrowAmount, offer.borrowToken, _extendPeriod);
        require(lenderFee > 0, "required minimum lender fee");
        require(serviceFee > 0, "required minimum service fee");

        IERC20(offer.borrowToken).transferFrom(msg.sender, offer.lender, lenderFee);
        IERC20(offer.borrowToken).transferFrom(msg.sender, treasury, serviceFee);

        // Update end times
        offer.borrowPeriod = offer.borrowPeriod.add(_extendPeriod);
        offer.liquidationAt = offer.liquidationAt.add(_extendPeriod);

        emit ExtendLendingTimeRequested(
            _offerId,
            offer.collection,
            offer.tokenId,
            offer.startLendingAt.add(offer.borrowPeriod),
            offer.liquidationAt,
            lenderFee,
            serviceFee
        );
    }

    /**
     *
     * In liquidation period, only lender can claim NFT
     * After liquidation period, anyone with fast hand can claim NFT
     *
     **/
    function claim(bytes16 _offerId)
    external
    override
    nonReentrant
    {
        Offer storage offer = offers[_offerId];

        // Validations
        require(block.timestamp > offer.startLendingAt.add(offer.borrowPeriod), "can not claim in lending period");
        if (block.timestamp <= offer.liquidationAt)
            require(
                offer.lender == msg.sender,
            "only lender can claim NFT at this time"
            );
        require(
            (msg.sender == treasury) ||
            (msg.sender == offer.lender) ||
            (msg.sender == offer.owner),
            "invalid-address"
        );
        // Send NFT to taker
        _nftSafeTransfer(address(this), msg.sender, offer.collection, offer.tokenId, offer.nftAmount, offer.nftType);

        emit NFTClaim(_offerId, offer.collection, offer.tokenId, msg.sender);
    }

    /**
    * @notice internal function to save on code size for the onlyAmountGreaterThanZero modifier
    **/
    function requireAmountGreaterThanZero(uint256 _amount) internal pure {
        require(_amount > 0, "Amount must be greater than 0");
    }

    /**
    * @notice internal function to save on code size for the onlyAmountGreaterThanZero modifier
    **/
    function requireBorrowPeriodGreaterThanZero(uint256 _borrowAmount) internal pure {
        require(_borrowAmount >= 1, "Borrow period number must be greater than or equal 0");
    }

    /**
     * @notice internal function to save on code size for the onlyAmountGreaterThanZero modifier
     **/
    function requireAmountGreaterThanOrEqualMinAmount(
        uint256 _min,
        uint256 _amount
    ) internal pure {
        require(_amount >= _min, "Min amount must be greatr than or equal expected amount");
    }
    
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    // Function for test
    function currentTime() public view returns (uint256) {
        return block.timestamp;
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

pragma solidity ^0.8.0;

import './IPawnShopEvents.sol';
import './IPawnShopOwnerActions.sol';
import './IPawnShopUserActions.sol';

interface IPawnShop is IPawnShopEvents, IPawnShopOwnerActions, IPawnShopUserActions {
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library PawnShopLibrary {
    using SafeMath for uint256;

    uint256 private constant YEAR_IN_SECONDS = 31556926;

    // 1000000 is 100% * 10_000 PERCENT FACTOR
    function getFeeAmount(uint256 borrowAmount, uint256 feeRate, uint256 lendingPeriod) internal pure returns (uint256) {
        require(feeRate > 0, 'invalid feeRate');
        return lendingPeriod.mul(borrowAmount).mul(feeRate).div(YEAR_IN_SECONDS).div(1000000);
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

pragma solidity ^0.8.0;

interface IPawnShopEvents {

    event OfferCreated(
        bytes16 indexed _offerId,
        address _collection,
        uint256 _tokenId,
        address _owner,
        address _to,
        uint256 _amount,
        address _borrowToken,
        uint256 _startApplyAt,
        uint256 _closeApplyAt,
        uint256 _borrowPeriod,
        uint256 _nftType,
        uint256 _nftAmount
    );

    event OfferApplied(
        bytes16 indexed _offerId,
        address indexed _collection,
        uint256 indexed _tokenId,
        address _lender
    );

    event Repay(
        bytes16 indexed _offerId,
        address indexed _collection,
        uint256 indexed _tokenId,
        address _repayer,
        uint256 _amount
    );

    event OfferUpdated(
        bytes16 indexed _offerId,
        address indexed _collection,
        uint256 indexed _tokenId,
        uint256 _amount,
        uint256 _lendingPeriod
    );

    event OfferCancelled(bytes16 indexed _offerId, address indexed _collection, uint256 indexed _tokenId);

    event ExtendLendingTimeRequested(
        bytes16 indexed _offerId,
        address indexed _collection,
        uint256 indexed _tokenId,
        uint256 _lendingEndAt,
        uint256 _liquidationAt,
        uint256 _lendingFeeAmount,
        uint256 _serviceFeeAmount
    );

    event NFTClaim(
        bytes16 indexed _offerId,
        address indexed _collection,
        uint256 indexed _tokenId,
        address _taker
    );
}

pragma solidity ^0.8.0;

interface IPawnShopOwnerActions {

    function setTokenFeeRates(
        address _token,
        uint256 _lenderFeeRate,
        uint256 _serviceFeeRate
    ) external;
}

pragma solidity ^0.8.0;

interface IPawnShopUserActions {

    function createOffer721(
        bytes16 _offerId,
        address _collection,
        uint256 _tokenId,
        address _to,
        uint256 _borrowAmount,
        address _borrowToken,
        uint256 _borrowPeriod,
        uint256 _startApplyAt,
        uint256 _closeApplyAt
    ) external;

    function createOffer1155(        
        bytes16 _offerId,
        address _collection,
        uint256 _tokenId,
        address _to,
        uint256 _borrowAmount,
        address _borrowToken,
        uint256 _borrowPeriod,
        uint256 _startApplyAt,
        uint256 _closeApplyAt,
        uint256 _nftAmount
    ) external;

    function applyOffer(bytes16 _offerId, uint256 _amount) external;

    function repay(bytes16 _offerId) external;

    function updateOffer(bytes16 _offerId, uint256 _amount, uint256 _borrowCycleNo) external;

    function cancelOffer(bytes16 _offerId) external;

    function extendLendingTime(bytes16 _offerId, uint256 extCycleNo) external;

    function claim(bytes16 _offerId) external;

    function quoteFees(uint256 _borrowAmount, address _token, uint256 _lendingPeriod) external view returns (uint256 lenderFee, uint256 serviceFee);

    function quoteExtendFees(bytes16 _offerId, uint256 _extCycleNo) external view returns (uint256 lenderFee, uint256 serviceFee);

    function quoteApplyAmounts(bytes16 _offerId) external view returns (uint256 lenderFee, uint256 serviceFee, uint256 approvedAmount);
}