/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "../utils/Context.sol";
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

//import "@openzeppelin/contracts/access/Ownable.sol";
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

//import "../../utils/introspection/IERC165.sol";
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

//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
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

//import "./Common/ITrade.sol";
//-----------------------------------------------------------------------
// ITrade
//-----------------------------------------------------------------------
interface ITrade {
    //----------------------------------------
    // Events
    //----------------------------------------
    event MaxPriceModified( uint256 maxPrice );
    event MinPriceModified( uint256 minPrice );

    event MaxPeriodModified( uint256 maxPrice );
    event MinPeriodModified( uint256 minPrice );

    event OnlyNoLimitPeriodModified( bool );
    event AcceptNoLimiPeriodModified( bool );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function maxPrice() external view returns ( uint256 );
    function minPrice() external view returns ( uint256 );
    function setMaxPrice( uint256 price ) external;
    function setMinPrice( uint256 price ) external;

    function maxPeriod() external view returns ( uint256 );
    function minPeriod() external view returns ( uint256 );
    function setMaxPeriod( uint256 period ) external;
    function setMinPeriod( uint256 period ) external;

    function onlyNoLimitPeriod() external view returns (bool);
    function acceptNoLimitPeriod() external view returns (bool);
    function setOnlyNoLimitPeriod( bool flag ) external;
    function setAcceptNoLimitPeriod( bool flag ) external;

    //----------------------------------------------
    // トークンの転送情報
    //----------------------------------------------
    // uint256[4]の内訳は下記
    // ・[0]:トークンコントラクト(ERC721へキャストして使う)
    // ・[1]:トークンID
    // ・[2]:供出側(addressへキャストして使う)
    // ・[3]:受領側(addressへキャストして使う)
    //----------------------------------------------
    function transferInfo( uint256 tradeId ) external view returns (uint256[4] memory);

    //----------------------------------------------
    // 支払い情報の取得
    //----------------------------------------------
    // uint256[2]の内訳は下記
    // ・[0]:支払い先(payable addressへキャストして使う)
    // ・[1]:コントラクトアドレス(ERC721へキャストして使う)
    // ・[2]:支払額
    //----------------------------------------------
    function payInfo( uint256 tradeId ) external view returns (uint256[3] memory);

    //----------------------------------------------
    // 払い戻し情報の取得
    //----------------------------------------------
    // uint256[2]の内訳は下記
    // ・[0]:払い戻し先(payable addressへキャストして使う)
    // ・[1]:払い戻し額
    //----------------------------------------------
    function refundInfo( uint256 tradeId ) external view returns (uint256[2] memory);
}

//import "./Common/ISale.sol";
//-----------------------------------------------------------------------
// ISale
//-----------------------------------------------------------------------
interface ISale {
    //----------------------------------------
    // Events
    //----------------------------------------
    event Sale( address indexed contractAddress, uint256 indexed tokenId, address indexed seller, uint256 price, uint256 expireDate, uint256 saleId );
    event SaleCanceled( uint256 indexed saleId, address indexed contractAddress, uint256 indexed tokenId, address seller );
    event Sold( uint256 indexed saleId, address indexed contractAddress, uint256 indexed tokenId, address seller, address buyer, uint256 price );
    event SaleInvalidated( uint256 indexed saleId, address indexed contractAddress, uint256 indexed tokenId, address seller );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function sell( address msgSender, address contractAddress, uint256 tokenId, uint256 price, uint256 period ) external;
    function cancelSale( address msgSender, uint256 saleId ) external;
    function buy( address msgSender, uint256 saleId, uint256 amount ) external;
    function invalidateSales( uint256[] calldata saleIds ) external;
}

//import "./Common/IOffer.sol";
//-----------------------------------------------------------------------
// IOffer
//-----------------------------------------------------------------------
interface IOffer {
    //----------------------------------------
    // Events
    //----------------------------------------
    event Offer( address indexed contractAddress, uint256 indexed tokenId, address owner, address offeror, uint256 price, uint256 expireDate, uint256 offerId );
    event OfferCanceled( uint256 indexed offerId, address indexed contractAddress, uint256 indexed tokenId, address owner, address offeror, uint256 price );
    event OfferAccepted( uint256 indexed offerId, address indexed contractAddress, uint256 indexed tokenId, address owner, address offeror, uint256 price );
    event OfferWithdrawn( uint256 indexed offerId, address indexed contractAddress, uint256 indexed tokenId, address owner, address offeror, uint256 price );
    event OfferInvalidated( uint256 indexed offerId, address indexed contractAddress, uint256 indexed tokenId, address owner, address offeror );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function offer( address msgSender, address contractAddress, uint256 tokenId, uint256 price, uint256 period, uint256 amount ) external;
    function cancelOffer( address msgSender, uint256 offerId ) external;
    function acceptOffer( address msgSender, uint256 offerId ) external;
    function withdrawFromOffer( address msgSender, uint256 offerId ) external;
    function invalidateOffers( uint256[] calldata offerIds ) external;
}

//import "./Common/IAuction.sol";
//-----------------------------------------------------------------------
// IAuction
//-----------------------------------------------------------------------
interface IAuction  {
    //----------------------------------------
    // Events
    //----------------------------------------
    event Auction( address indexed contractAddress, uint256 indexed tokenId, address auctioneer, uint256 startingPrice, uint256 expireDate, uint256 auctionId );
    event AuctionCanceled( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer );
    event AuctionBidded ( uint256 indexed auctionId,  address indexed contractAddress, uint256 indexed tokenId, address auctioneer, address newBidder, address oldBidder, uint256 newPrice, uint256 updatedExpireDate ); 
    event AuctionFinished( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer, address winner, uint256 price, uint256 expireDate );
    event AuctionWithdrawn( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer, address bidder, uint256 price );
    event AuctionInvalidated( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer, address bidder );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function auction( address msgSender, address contractAddress, uint256 tokenId, uint256 startingPrice, uint256 period ) external;
    function cancelAuction( address msgSender, uint256 auctionId ) external;
    function bid( address msgSender, uint256 auctionId, uint256 price, uint256 amount ) external;
    function finishAuction( address msgSender, uint256 auctionId ) external;
    function withdrawFromAuction( address msgSender, uint256 auctionId ) external;
    function invalidateAuctions( uint256[] calldata auctionIds ) external;
}

//import "./Common/IDutchAuction.sol";
//-----------------------------------------------------------------------
// IDutchAuction
//-----------------------------------------------------------------------
interface IDutchAuction  {
    //----------------------------------------
    // Events
    //----------------------------------------
    event DutchAuction( address indexed contractAddress, uint256 indexed tokenId, address auctioneer, uint256 startingPrice, uint256 endingPrice, uint256 expireDate, uint256 startMargin, uint256 endMargin, uint256 auctionId );
    event DutchAuctionCanceled( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer );
    event DutchAuctionSold( uint256 indexed auctionId,  address indexed contractAddress, uint256 indexed tokenId, address auctioneer, address buyer, uint256 price ); 
    event DutchAuctionInvalidated( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function dutchAuction( address msgSender, address contractAddress, uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 period, uint256 startMargin, uint256 endMargin ) external;
    function cancelDutchAuction( address msgSender, uint256 auctionId ) external;
    function buyDutchAuction( address msgSender, uint256 auctionId, uint256 amount ) external;
    function invalidateDutchAuctions( uint256[] calldata auctionIds ) external;
}

//----------------------------------------------------------------
// マーケット（リリースしたら何があってもこのコントラクトは変えてはならない）
//----------------------------------------------------------------
contract Market is Ownable {
    //-----------------------------------------
    // イベント
    //-----------------------------------------
    event SaleStartSuspended( bool );
    event OfferStartSuspended( bool );
    event AuctionStartSuspended( bool );
    event DutchAuctionStartSuspended( bool );

    event SaleModified( address contractAddress );
    event OfferModified( address contractAddress );
    event AuctionModified( address contractAddress );
    event DutchAuctionModified( address contractAddress );

    event DefaultMarketFeeModified( uint feeRate );
    event DefaultCollectionFeeModified( uint feeRate );

    event MarketFeeModified( address indexed contractAddress, uint feeRate );
    event CollectionFeeModified( address indexed contractAdress, uint feeRate );
    event MarketFeeReset( address indexed contractAddress );
    event CollectionFeeReset( address indexed contractAdress );

    // プレゼント(単なる転送なのでIPresent的なインターフェイスを用意せずMarket内部で完結させてしまう)
    event Presented( address indexed contractAddress, uint256 indexed tokenId, address from, address to );

    //-----------------------------------------
    // 定数
    //-----------------------------------------
    uint256 constant private FEE_RATE_BASE = 10000;  // 手数料の基底値（万分率）（この値を超えた指定をすると無料となる／０は無効値としてデフォルトを参照するため）

    //-----------------------------------------
    // 設定
    //-----------------------------------------
    // 開始停止フラグ
    bool private _sale_start_suspended;
    bool private _offer_start_suspended;
    bool private _auction_start_suspended;
    bool private _dutch_auction_start_suspended;

    // 構成要素
    ISale private _sale;
    IOffer private _offer;
    IAuction private _auction;
    IDutchAuction private _dutch_auction;

    // 手数料
    uint256 private _default_fee_rate_market;       // 基本マーケット手数料割合
    uint256 private _default_fee_rate_collection;   // 基本コレクション手数料割合

    // 個別手数料
    mapping( address => uint256 ) private _fixed_fee_rate_market;
    mapping( address => uint256 ) private _fixed_fee_rate_collection;

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor() Ownable() {
        _default_fee_rate_market = 1000;        // 10.0 %
        _default_fee_rate_collection = 1000;    // 10.0 %

        emit DefaultMarketFeeModified( _default_fee_rate_market );
        emit DefaultCollectionFeeModified( _default_fee_rate_collection );
    }

    //-----------------------------------------
    // [external] 取得
    //-----------------------------------------
    function saleStartSuspended() external view returns (bool) {
        return( _sale_start_suspended );
    }

    function offerStartSuspended() external view returns (bool) {
        return( _offer_start_suspended );
    }

    function auctionStartSuspended() external view returns (bool) {
        return( _auction_start_suspended );
    }

    function dutchAuctionStartSuspended() external view returns (bool) {
        return( _dutch_auction_start_suspended );
    }

    function sale() external view returns (address) {
        return( address(_sale) );
    }

    function offer() external view returns (address) {
        return( address(_offer) );
    }

    function auction() external view returns (address) {
        return( address(_auction) );
    }

    function dutchAuction() external view returns (address) {
        return( address(_dutch_auction) );
    }

    function defaultFeeRateForMarket() external view returns (uint256) {
        return( _default_fee_rate_market );
    }

    function defaultFeeRateForCollection() external view returns (uint256) {
        return( _default_fee_rate_collection );
    }

    //-----------------------------------------
    // [external/onlyOwner] 設定
    //-----------------------------------------
    function setSaleStartSuspended( bool flag ) external onlyOwner {
        _sale_start_suspended = flag;

        emit SaleStartSuspended( flag );
    }

    function setOfferStartSuspended( bool flag ) external onlyOwner {
        _offer_start_suspended = flag;

        emit OfferStartSuspended( flag );
    }

    function setAuctionStartSuspended( bool flag ) external onlyOwner {
        _auction_start_suspended = flag;

        emit AuctionStartSuspended( flag );
    }

    function setDutchAuctionStartSuspended( bool flag ) external onlyOwner {
        _dutch_auction_start_suspended = flag;

        emit DutchAuctionStartSuspended( flag );
    }

    function setSale( address contractAddress ) external onlyOwner {
        _sale = ISale(contractAddress);

        emit SaleModified( contractAddress );
    }

    function setOffer( address contractAddress ) external onlyOwner {
        _offer = IOffer( contractAddress );

        emit OfferModified( contractAddress );
    }

    function setAuction( address contractAddress ) external onlyOwner {
        _auction = IAuction( contractAddress );

        emit AuctionModified( contractAddress );
    }

    function setDutchAuction( address contractAddress ) external onlyOwner {
        _dutch_auction = IDutchAuction( contractAddress );

        emit DutchAuctionModified( contractAddress );
    }

    function setDefaultFeeRateForMarket( uint256 rate ) external onlyOwner {
        _default_fee_rate_market = rate;

        emit DefaultMarketFeeModified( rate );
    }

    function setDefaultFeeRateForCollection( uint256 rate ) external onlyOwner {
        _default_fee_rate_collection = rate;

        emit DefaultCollectionFeeModified( rate );
    }

    //----------------------------------------
    // [external] 個別手数料取得
    //----------------------------------------
    function fixedFeeRateForMarket( address contractAddress ) external view returns (uint256) {
        return( _fixed_fee_rate_market[contractAddress] );
    }

    function fixedFeeRateForCollection( address contractAddress ) external view returns (uint256) {
        return( _fixed_fee_rate_collection[contractAddress] );
    }

    //----------------------------------------
    // [external/onlyOwner] 個別手数料設定
    //----------------------------------------
    function setFixedFeeRateForMarket( address contractAddress, uint256 rate ) external onlyOwner {
        _fixed_fee_rate_market[contractAddress] = rate;

        emit MarketFeeModified( contractAddress, rate );
    }

    function setFixedFeeRateForCollection( address contractAddress, uint256 rate ) external onlyOwner {
        _fixed_fee_rate_collection[contractAddress] = rate;

        emit CollectionFeeModified( contractAddress, rate );
    }

    function resetFixedFeeRateForMarket( address contractAddress ) external onlyOwner {
        delete _fixed_fee_rate_market[contractAddress];

        emit MarketFeeReset( contractAddress );
    }

    function resetFixedFeeRateForCollection( address contractAddress ) external onlyOwner {
        delete _fixed_fee_rate_collection[contractAddress];

        emit CollectionFeeReset( contractAddress );
    }

    //----------------------------------------
    // [public] 実手数料割合取得
    //----------------------------------------
    function feeRateForMarket( address contractAddress ) public view returns (uint256) {
        uint256 fee = _fixed_fee_rate_market[contractAddress];

        // 有効なら
        if( fee > 0 ){
            // １を超えたら０とする
            if( fee > FEE_RATE_BASE ){
                return( 0 );
            }

            return( fee );
        }

        return( _default_fee_rate_market );
    }

    function feeRateForCollection( address contractAddress ) public view returns (uint256) {
        uint256 fee = _fixed_fee_rate_collection[contractAddress];

        // 有効なら
        if( fee > 0 ){
            // １を超えたら０とする
            if( fee > FEE_RATE_BASE ){
                return( 0 );
            }

            return( fee );
        }

        return( _default_fee_rate_collection );
    }

    //-----------------------------------------
    // [external] 窓口：Sale
    //-----------------------------------------
    function sell( address contractAddress, uint256 tokenId, uint256 price, uint256 period ) external {
        require( address(_sale) != address(0), "invalid sale" );
        require( !_sale_start_suspended, "sale suspended" );  // 新規セール中止中

        _sale.sell( msg.sender, contractAddress, tokenId, price, period );
    }

    function cancelSale( uint256 saleId ) external {
        require( address(_sale) != address(0), "invalid sale" );

        _sale.cancelSale( msg.sender, saleId );
    }

    function buy( uint256 saleId ) external payable {
        require( address(_sale) != address(0), "invalid sale" );

        _sale.buy( msg.sender, saleId, msg.value );

        // トークンの転送
        uint256[4] memory transferInfo = ITrade(address(_sale)).transferInfo( saleId );
        _transfer( transferInfo );

        // 支払い
        uint256[3] memory payInfo = ITrade(address(_sale)).payInfo( saleId );
        _pay( payInfo );
    }

    //-----------------------------------------
    // [external] 窓口：Offer
    //-----------------------------------------
    function offer( address contractAddress, uint256 tokenId, uint256 price, uint256 period ) external payable {
        require( address(_offer) != address(0), "invalid offer" );
        require( !_offer_start_suspended, "offer suspended" );  // 新規オファー中止中

        _offer.offer( msg.sender, contractAddress, tokenId, price, period, msg.value );
    }

    function cancelOffer( uint256 offerId ) external {
        require( address(_offer) != address(0), "invalid offer" );

        _offer.cancelOffer( msg.sender, offerId );

        // 払い戻し
        uint256[2] memory refundInfo = ITrade(address(_offer)).refundInfo( offerId );
        _refund( refundInfo );
    }

    function acceptOffer( uint256 offerId ) external {
        require( address(_offer) != address(0), "invalid offer" );

        _offer.acceptOffer( msg.sender, offerId );

        // トークンの転送
        uint256[4] memory transferInfo = ITrade(address(_offer)).transferInfo( offerId );
        _transfer( transferInfo );

        // 支払い
        uint256[3] memory payInfo = ITrade(address(_offer)).payInfo( offerId );
        _pay( payInfo );
    }

    function withdrawFromOffer( uint256 offerId ) external {
        require( address(_offer) != address(0), "invalid offer" );

        _offer.withdrawFromOffer( msg.sender, offerId );

        // 払い戻し
        uint256[2] memory refundInfo = ITrade(address(_offer)).refundInfo( offerId );
        _refund( refundInfo );
    }

    //-----------------------------------------
    // [external] 窓口：Auction
    //-----------------------------------------
    function auction( address contractAddress, uint256 tokenId, uint256 startingPrice, uint256 period ) external {
        require( address(_auction) != address(0), "invalid auction" );
        require( !_auction_start_suspended, "auction suspended" );  // 新規オークション中止中

        _auction.auction( msg.sender, contractAddress, tokenId, startingPrice, period );
    }

    function cancelAuction( uint256 auctionId ) external {
        require( address(_auction) != address(0), "invalid auction" );

        _auction.cancelAuction( msg.sender, auctionId );
    }

    function bid( uint256 auctionId, uint256 price ) external payable {
        require( address(_auction) != address(0), "invalid auction" );

        // 既存の入札に対して払い戻し（既存の入札が有効であれば）
        uint256[2] memory refundInfo = ITrade(address(_auction)).refundInfo( auctionId );
        if( refundInfo[0] != 0 ){
            _refund( refundInfo );
        }

        _auction.bid( msg.sender, auctionId, price, msg.value );
    }

    function finishAuction( uint256 auctionId ) external {
        require( address(_auction) != address(0), "invalid auction" );

        _auction.finishAuction( msg.sender, auctionId );

        // トークンの転送
        uint256[4] memory transferInfo = ITrade(address(_auction)).transferInfo( auctionId );
        _transfer( transferInfo );

        // 支払い
        uint256[3] memory payInfo = ITrade(address(_auction)).payInfo( auctionId );
        _pay( payInfo );
    }

    function withdrawFromAuction( uint256 auctionId ) external{
        require( address(_auction) != address(0), "invalid auction" );

        _auction.withdrawFromAuction( msg.sender, auctionId );

        // 払い戻し
        uint256[2] memory refundInfo = ITrade(address(_auction)).refundInfo( auctionId );
        _refund( refundInfo );
    }

    //-----------------------------------------
    // [external] 窓口：DutchAuction
    //-----------------------------------------
    function dutchAuction( address contractAddress, uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 period, uint256 startMargin, uint256 endMargin ) external {
        require( address(_dutch_auction) != address(0), "invalid dutch auction" );
        require( !_dutch_auction_start_suspended, "dutch_auction suspended" );  // 新規ダッチオークション中止中

        _dutch_auction.dutchAuction( msg.sender, contractAddress, tokenId, startingPrice, endingPrice, period, startMargin, endMargin );
    }

    function cancelDutchAuction( uint256 auctionId ) external {
        require( address(_dutch_auction) != address(0), "invalid dutch auction" );

        _dutch_auction.cancelDutchAuction( msg.sender, auctionId );
    }

    function dutchAuctionBuy( uint256 auctionId ) external payable {
        require( address(_dutch_auction) != address(0), "invalid dutch_auction" );

        _dutch_auction.buyDutchAuction( msg.sender, auctionId, msg.value );

        // トークンの転送
        uint256[4] memory transferInfo = ITrade(address(_dutch_auction)).transferInfo( auctionId );
        _transfer( transferInfo );

        // 支払い
        uint256[3] memory payInfo = ITrade(address(_dutch_auction)).payInfo( auctionId );
        _pay( payInfo );
    }

    //---------------------------------------------------------------------------
    // [external] 窓口：Present（Tradeにするほどではないのでマーケット上で実装してしまう）
    //---------------------------------------------------------------------------
    function present( address contractAddress, uint256 tokenId, address to ) external {
        // 停止制御も不要（後腐れのない処理なので）

        // オーナーが有効か？
        IERC721 tokenContract = IERC721( contractAddress );
        address owner = tokenContract.ownerOf( tokenId );
        require( owner == msg.sender, "sender is not the owner" );

        // event
        emit Presented( contractAddress, tokenId, msg.sender, to );

        // トークンの転送
        uint256[4] memory transferInfo;
        transferInfo[0] = uint256(uint160(contractAddress));
        transferInfo[1] = tokenId;
        transferInfo[2] = uint256(uint160(msg.sender));
        transferInfo[3] = uint256(uint160(to));
        _transfer( transferInfo );
    }

    //-----------------------------------
    // [internal] 共通処理：トークンの転送
    //-----------------------------------
    function _transfer( uint256[4] memory words ) internal {
        require( words[0] != 0, "invalid contract" );
        require( words[2] != 0, "invalid from" );
        require( words[3] != 0, "invalid to" );

        // wordsの内訳は[ITrade.sol]を参照
        IERC721 tokenContract = IERC721( address( uint160( words[0] ) ) );
        uint256 tokenId = words[1];
        address from = address( uint160( words[2] ) );
        address to = address( uint160( words[3] ) );
        tokenContract.safeTransferFrom( from, to, tokenId );
    }

    //-----------------------------------
    // [internal] 共通処理：支払い
    //-----------------------------------
    function _pay( uint256[3] memory words ) internal {
        require( words[0] != 0, "invalid to" );
        require( words[1] != 0, "invalid contract address" );

        // 売上金の振込先
        address payable to = payable( address( uint160( words[0] ) ) );

        // クリエイター（コレクションコントラクトのオーナー）
        address contractAddress = address( uint160( words[1] ) );
        Ownable collectionContract = Ownable( contractAddress );
        address payable creator = payable( collectionContract.owner() );

        // マーケット（このコントラクトのオーナー）
        address payable market = payable( owner() );

        // 清算
        uint256 amount = words[2];

        // マーケット手数料（支払い先と同じなら無視）
        if( market != to ){
	        uint256 fee = feeRateForMarket( contractAddress );
	        fee = (words[2] * fee)/FEE_RATE_BASE;
	        if( fee > 0 ){
	            if( fee > amount ){
	                fee = amount;
	            }
	            market.transfer( fee );
	            amount -= fee;
	        }
	    }

        // クリエイター手数料（支払い先と同じなら無視）
        if( creator != to ){
	        uint256 fee = feeRateForCollection( contractAddress );
	        fee = (words[2] * fee)/FEE_RATE_BASE;
	        if( fee > 0 ){
	            if( fee > amount ){
	                fee = amount;
	            }
	            creator.transfer( fee );
	            amount -= fee;
	        }
	    }

        // 売り上げ
        if( amount > 0 ){
            to.transfer( amount );
        }
    }

    //-----------------------------------
    // [internal] 共通処理：預託金の払い戻し
    //-----------------------------------
    function _refund( uint256[2] memory words ) internal {
        require( words[0] != 0, "invalid to" );

        address payable to = payable( address( uint160( words[0] ) ) );

        if( words[1] > 0 ){
            to.transfer( words[1] );
        }
    }

}