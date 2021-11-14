/**
 *Submitted for verification at polygonscan.com on 2021-11-13
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


//import "./ITrade.sol";
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


//import "./Common/Trade.sol";
//-----------------------------------------
// トレード
//-----------------------------------------
contract Trade is Ownable, ITrade {
    //-----------------------------------------
    // 設定
    //-----------------------------------------
    address private _market;        // Tradeの中で実装する（ITradeに公開しない＆イベントも不要＝サーバー側で監視する必要はないので）

    uint256 private _max_price;
    uint256 private _min_price;

    uint256 private _max_period;
    uint256 private _min_period;

    bool private _only_no_limit_period;
    bool private _accept_no_limit_period;

    //-----------------------------------------
    // [public] マーケット
    //-----------------------------------------
    function market() public view returns( address ) {
        return( _market );
    }

    //-----------------------------------------
    // [external/onlyOwner] マーケット設定
    //-----------------------------------------
    function setMarket( address contractAddress ) external onlyOwner {
        _market = contractAddress;
    }

    //-----------------------------------------
    // [modifier] マーケットからしか呼べない
    //-----------------------------------------
    modifier onlyMarket() {
        require( market() == _msgSender(), "caller is not the market" );
        _;
    }

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor() Ownable() {
        // 価格制限
        _max_price = 1000000000000000000000000000;      // 1,000,000,000.000000 MATIC
        _min_price = 1000000000000;                     //             0.000001 MATIC

        emit MaxPriceModified( _max_price );
        emit MinPriceModified( _min_price );

        // 期間制限
        _max_period = 30*24*60*60;      // 30 days
        _min_period =  1*24*60*60;      //  1 day

        emit MaxPeriodModified( _max_period );
        emit MinPeriodModified( _min_period );

        // 無期限設定
        _only_no_limit_period = false;
        _accept_no_limit_period = true;

        emit OnlyNoLimitPeriodModified( _only_no_limit_period );
        emit AcceptNoLimiPeriodModified( _accept_no_limit_period );
    }    

    //-----------------------------------------
    // [external] 確認
    //-----------------------------------------
    function maxPrice() external view virtual override returns ( uint256 ) {
        return( _max_price );
    }

    function minPrice() external view virtual override returns ( uint256 ) {
        return( _min_price );
    }

    function maxPeriod() external view virtual override returns ( uint256 ) {
        return( _max_period );
    }

    function minPeriod() external view virtual override returns ( uint256 ) {
        return( _min_period );
    }

    function onlyNoLimitPeriod() external view virtual override returns (bool){
        return( _only_no_limit_period );
    }

    function acceptNoLimitPeriod() external view virtual override returns (bool){
        return( _accept_no_limit_period );
    }

    //-----------------------------------------
    // [external/onlyOwner] 設定
    //-----------------------------------------
    function setMaxPrice( uint256 price ) external virtual override onlyOwner {
        _max_price = price;

        emit MaxPriceModified( _max_price );
    }

    function setMinPrice( uint256 price ) external virtual override onlyOwner {
        _min_price = price;

        emit MinPriceModified( _min_price );
    }

    function setMaxPeriod( uint256 period ) external virtual override onlyOwner {
        _max_period = period;

        emit MaxPeriodModified( _max_period );
    }

    function setMinPeriod( uint256 period ) external virtual override onlyOwner {
        _min_period = period;

        emit MinPeriodModified( _min_period );
    }

    function setOnlyNoLimitPeriod( bool flag ) external virtual override onlyOwner {
        _only_no_limit_period = flag;

        emit OnlyNoLimitPeriodModified( _only_no_limit_period );
    }

    function setAcceptNoLimitPeriod( bool flag ) external virtual override onlyOwner {
        _accept_no_limit_period = flag;

        emit AcceptNoLimiPeriodModified( _accept_no_limit_period );
    }

    //-----------------------------------------
    // [internal] 価格の有効性
    //-----------------------------------------
    function _checkPrice( uint256 price ) internal view virtual returns (bool){
        if( price > _max_price ){
            return( false );
        }

        if( price < _min_price ){
            return( false );
        }

        return( true );
    }

    //-----------------------------------------
    // [internal] 期間の有効性
    //-----------------------------------------
    function _checkPeriod( uint256 period ) internal view virtual returns (bool){
        // 無制限のみ受け付ける場合
        if( _only_no_limit_period ){
            return( period == 0 );
        }

        // 無制限を受け付ける場合
        if( _accept_no_limit_period ){
            if( period == 0 ){
                return( true );
            }
        }

        if( period > _max_period ){
            return( false );
        }

        if( period < _min_period ){
            return( false );
        }

        return( true );
    }

    //----------------------------------------------------------------
    // [external] トークンの転送情報(Tradeの時点では有効なデータが存在しない)
    //----------------------------------------------------------------
    function transferInfo( uint256 /*tradeId*/ ) external view virtual override returns (uint256[4] memory){
        uint256[4] memory words;
        return( words );
    }

    //-----------------------------------------
    // [external] 支払い情報の取得
    //-----------------------------------------
    function payInfo( uint256 /*tradeId*/ ) external view virtual override returns (uint256[3] memory){
        uint256[3] memory words;
        return( words );
    }

    //-----------------------------------------
    // [externa] 払い戻し情報の取得
    //-----------------------------------------
    function refundInfo( uint256 /*tradeId*/ ) external view virtual override returns (uint256[2] memory){
        uint256[2] memory words;
        return( words );
    }
}


// import "./Common/IOffer.sol";
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


//-----------------------------------------
// オファー
//-----------------------------------------
contract Offer is Trade, IOffer {
    //----------------------------------------
    // 定数
    //----------------------------------------
    // IDのオフセット
    uint256 constant private OFFER_ID_OFS = 1;

    // 構造体を使いたくないので[uint256]の配列で管理する
    uint256 constant private OFFER_DATA_CONTRACT_ADDRESS        = 0;    // コントラクトアドレス(address)
    uint256 constant private OFFER_DATA_TOKEN_ID                = 1;    // トークンID
    uint256 constant private OFFER_DATA_OWNER                   = 2;    // 保有者(address)
    uint256 constant private OFFER_DATA_PRICE                   = 3;    // 価格
    uint256 constant private OFFER_DATA_INFO                    = 4;    // 情報
    uint256 constant private OFFER_DATA_SIZE                    = 5;    // データサイズ

    // [OFFER_DATA_INFO]操作：フラグ
    uint256 constant private OFFER_DATA_INFO_FLAG_ACTIVE        = 0x8000000000000000000000000000000000000000000000000000000000000000; // アクティブか？
    uint256 constant private OFFER_DATA_INFO_FLAG_ACCEPTED      = 0x4000000000000000000000000000000000000000000000000000000000000000; // 承諾済みか？
    uint256 constant private OFFER_DATA_INFO_FLAG_CANCELED      = 0x2000000000000000000000000000000000000000000000000000000000000000; // キャンセル済みか？
    uint256 constant private OFFER_DATA_INFO_FLAG_INVALID       = 0x1000000000000000000000000000000000000000000000000000000000000000; // 無効化されたか？

    // [OFFER_DATA_INFO]操作：申込者
    uint256 constant private OFFER_DATA_INFO_OFFEROR_SHIFT      = 0;
    uint256 constant private OFFER_DATA_INFO_OFFEROR_MASK       = 0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // uint160：申込者(address)

    // [OFFER_DATA_INFO]操作：申込期間
    uint256 constant private OFFER_DATA_INFO_EXPIRE_DATE_SHIFT  = 160;
    uint256 constant private OFFER_DATA_INFO_EXPIRE_DATE_MASK   = 0x00000000FFFFFFFFFFFFFFFF0000000000000000000000000000000000000000; // uint64：申込終了日時

    //-----------------------------------------
    // ストレージ
    //-----------------------------------------
    uint256[OFFER_DATA_SIZE][] private _offers;

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor() Trade() {
    }

    //-----------------------------------------------
    // [public] データ取得：有効な offerId が来る前提
    //-----------------------------------------------
    function offerContractAddress( uint256 offerId ) public view returns (address) {
        return( address((uint160(_offers[offerId-OFFER_ID_OFS][OFFER_DATA_CONTRACT_ADDRESS]))) );
    }

    function offerTokenId( uint256 offerId ) public view returns (uint256) {
        return( _offers[offerId-OFFER_ID_OFS][OFFER_DATA_TOKEN_ID] );
    }

    function offerOwner( uint256 offerId ) public view returns (address) {
        return( address((uint160(_offers[offerId-OFFER_ID_OFS][OFFER_DATA_OWNER]))) );
    }

    function offerPrice( uint256 offerId ) public view returns (uint256) {
        return( _offers[offerId-OFFER_ID_OFS][OFFER_DATA_PRICE] );
    }

    function offerOfferor( uint256 offerId ) public view returns (address) {
        return( address(uint160((_offers[offerId-OFFER_ID_OFS][OFFER_DATA_INFO] & OFFER_DATA_INFO_OFFEROR_MASK) >> OFFER_DATA_INFO_OFFEROR_SHIFT)) );
    }

    function offerExpireDate( uint256 offerId ) public view returns (uint256) {
        return( (_offers[offerId-OFFER_ID_OFS][OFFER_DATA_INFO] & OFFER_DATA_INFO_EXPIRE_DATE_MASK) >> OFFER_DATA_INFO_EXPIRE_DATE_SHIFT );
    }

    function offerIsActive( uint256 offerId ) public view returns (bool) {
        return( (_offers[offerId-OFFER_ID_OFS][OFFER_DATA_INFO] & OFFER_DATA_INFO_FLAG_ACTIVE) != 0);
    }

    function offerIsAccepted( uint256 offerId ) public view returns (bool) {
        return( (_offers[offerId-OFFER_ID_OFS][OFFER_DATA_INFO] & OFFER_DATA_INFO_FLAG_ACCEPTED) != 0);
    }

    function offerIsCanceled( uint256 offerId ) public view returns (bool) {
        return( (_offers[offerId-OFFER_ID_OFS][OFFER_DATA_INFO] & OFFER_DATA_INFO_FLAG_CANCELED) != 0);
    }

    function offerIsInvalid( uint256 offerId ) public view returns (bool) {
        return( (_offers[offerId-OFFER_ID_OFS][OFFER_DATA_INFO] & OFFER_DATA_INFO_FLAG_INVALID) != 0);
    }

    //----------------------------------------------
    // [external/onlyMarket] 申し込み
    //----------------------------------------------
    function offer( address msgSender, address contractAddress, uint256 tokenId, uint256 price, uint256 period, uint256 amount ) external override onlyMarket {
        // オーナーが有効か？
        IERC721 tokenContract = IERC721( contractAddress );
        address owner = tokenContract.ownerOf( tokenId );
        require( owner != address(0), "burned token" );
        require( owner != msgSender, "offeror is the owner" );

        // 支払額確認
        require( _checkPrice( price ), "invalid price" );
        require( price <= amount, "Insufficient amount" );

        // 期間が有効か？
        require( _checkPeriod( period ), "invalid period" );

        //------------
        // チェック完了
        //------------

        uint256 offerId = OFFER_ID_OFS + _offers.length;

        uint256 expireDate;
        if( period == 0 ){
            expireDate = 0;
        }else{
            expireDate = block.timestamp + period;
        }

        uint256[OFFER_DATA_SIZE] memory words;
        words[OFFER_DATA_CONTRACT_ADDRESS] = uint256(uint160(contractAddress));
        words[OFFER_DATA_TOKEN_ID] = tokenId;
        words[OFFER_DATA_OWNER] = uint256(uint160(owner));
        words[OFFER_DATA_PRICE] = price;

        uint256 offeror = uint256( uint160(msgSender) );
        words[OFFER_DATA_INFO] |= (offeror<<OFFER_DATA_INFO_OFFEROR_SHIFT) & OFFER_DATA_INFO_OFFEROR_MASK;
        words[OFFER_DATA_INFO] |= (expireDate << OFFER_DATA_INFO_EXPIRE_DATE_SHIFT) & OFFER_DATA_INFO_EXPIRE_DATE_MASK;

        // フラグ設定（アクティブに）
        words[OFFER_DATA_INFO] |= OFFER_DATA_INFO_FLAG_ACTIVE;

        _offers.push( words );

        // event
        emit Offer( contractAddress, tokenId, owner, msgSender, price, expireDate, offerId );
    }

    //-------------------------------------------------------------
    // [external/onlyMarket] 申込中止（払い戻し処理は呼び出し元へ任せる）
    //-------------------------------------------------------------
    function cancelOffer( address msgSender, uint256 offerId ) external override onlyMarket {
        require( _exists( offerId ), "nonexistent offer" );

        // ここは無効化をみない（返金するので）

        // アクティブか？
        require( offerIsActive( offerId ), "not active offer" );

        // 申込者判定
        address offeror = offerOfferor( offerId );
        require( msgSender == offeror, "not offeror" );

        //------------
        // チェック完了
        //------------

        uint256 dataId = offerId - OFFER_ID_OFS;
        uint256[OFFER_DATA_SIZE] memory words = _offers[dataId];

        // フラグ設定（非アクティブにしてキャンセル済みに）
        words[OFFER_DATA_INFO] &= ~OFFER_DATA_INFO_FLAG_ACTIVE;
        words[OFFER_DATA_INFO] |= OFFER_DATA_INFO_FLAG_CANCELED;

        // 更新
        _offers[dataId] = words;

        // event
        emit OfferCanceled( offerId, offerContractAddress( offerId ), offerTokenId( offerId ), offerOwner( offerId ), msgSender, offerPrice( offerId ) );
    }

    //------------------------------------------------------------------
    // [external/onlyMarket] 申込承諾（支払いとNFTの処理は呼び出し元へ任せる）
    //------------------------------------------------------------------
    function acceptOffer( address msgSender, uint256 offerId ) external override onlyMarket {
        require( _exists( offerId ), "nonexistent offer" );

        // 無効化されていないか？（無効化されていたら取引は成立しない）
        require( ! offerIsInvalid( offerId ), "invalid offer" );

        // 有効か？
        require( offerIsActive( offerId ), "offer not active" );

        // オーナーが有効か？
        IERC721 tokenContract = IERC721( offerContractAddress( offerId ) );
        address owner = tokenContract.ownerOf( offerTokenId( offerId ) );
        require( owner == msgSender, "sender is not the owner" );
        require( owner == offerOwner( offerId ), "mismatch owner" );

        // 期間判定
        uint256 expireDate = offerExpireDate( offerId );
        require( expireDate == 0 || expireDate > block.timestamp, "expired" );

        //------------
        // チェック完了
        //------------

        uint256 dataId = offerId - OFFER_ID_OFS;
        uint256[OFFER_DATA_SIZE] memory words = _offers[dataId];

        // フラグ設定（非アクティブにして承諾済みに）
        words[OFFER_DATA_INFO] &= ~OFFER_DATA_INFO_FLAG_ACTIVE;
        words[OFFER_DATA_INFO] |= OFFER_DATA_INFO_FLAG_ACCEPTED;

        // 更新
        _offers[dataId] = words;

        // event
        emit OfferAccepted( offerId, offerContractAddress( offerId ), offerTokenId( offerId ), owner, offerOfferor( offerId ), offerPrice( offerId ) );
    }

    //----------------------------------------------------------------------------------------
    // [external/onlyMarket] 申込の払い戻し（商品が無効になった場合）（払い戻し処理は呼び出し元へ任せる）
    //----------------------------------------------------------------------------------------
    function withdrawFromOffer( address msgSender, uint256 offerId ) external override onlyMarket {
        require( _exists( offerId ), "nonexistent offer" );

        // 有効か？
        require( offerIsActive( offerId ), "not active offer" );

        // 入札者か？
        require( msgSender == offerOfferor( offerId ), "not offeror" );

        // 払い戻し条件を満たしているか？（オファーが無効化されている、もしくは、オーナーが変わっている）
        IERC721 tokenContract = IERC721( offerContractAddress( offerId ) );
        address owner = tokenContract.ownerOf( offerTokenId( offerId ) );
        require( offerIsInvalid( offerId ) || owner != offerOwner( offerId ), "valid offer" );

        //------------
        // チェック完了
        //------------

        uint256 dataId = offerId - OFFER_ID_OFS;
        uint256[OFFER_DATA_SIZE] memory words = _offers[dataId];

        // フラグ設定（非アクティブにするだけ）
        words[OFFER_DATA_INFO] &= ~OFFER_DATA_INFO_FLAG_ACTIVE;

        // 更新
        _offers[dataId] = words;

        // event
        emit OfferWithdrawn( offerId, offerContractAddress( offerId ), offerTokenId( offerId ), offerOwner( offerId ), msgSender, offerPrice( offerId ) );
    }

    //----------------------------------------------
    // [external/onlyOwner] オファーの無効化
    //----------------------------------------------
    function invalidateOffers( uint256[] calldata offerIds ) external override onlyOwner {
        for( uint256 i=0; i<offerIds.length; i++ ){
            uint256 offerId = offerIds[i];

            // まだ無効化されていなければ
            if( _exists( offerId ) && ! offerIsInvalid( offerId ) ){
                uint256 dataId = offerId - OFFER_ID_OFS;
                uint256[OFFER_DATA_SIZE] memory words = _offers[dataId];

                // フラグ設定(ACTIVEは寝かさない)
                words[OFFER_DATA_INFO] |= OFFER_DATA_INFO_FLAG_INVALID;

                // 更新
                _offers[dataId] = words;

                // event
                emit OfferInvalidated( offerId, offerContractAddress( offerId ), offerTokenId( offerId ), offerOwner( offerId ), offerOfferor( offerId ) );
            }
        }
    }

    //----------------------------------------------
    // [external] トークンの転送情報
    //----------------------------------------------
    function transferInfo( uint256 offerId ) external view override returns (uint256[4] memory){
        require( _exists( offerId ), "nonexistent offer" );

        // wordsの内訳は[ITrade.sol]を参照
        uint256[4] memory words;
        words[0] = uint256(uint160(offerContractAddress( offerId )));
        words[1] = offerTokenId( offerId );
        words[2] = uint256(uint160(offerOwner( offerId )));
        words[3] = uint256(uint160(offerOfferor( offerId )));

        return( words );
    }

    //----------------------------------------------
    // [external] 支払い情報の取得
    //----------------------------------------------
    function payInfo( uint256 offerId ) external view override returns (uint256[3] memory){
        require( _exists( offerId ), "nonexistent offer" );

        // wordsの内訳は[ITrade.sol]を参照
        uint256[3] memory words;
        words[0] = uint256(uint160(offerOwner( offerId )));
        words[1] = uint256(uint160(offerContractAddress( offerId )));
        words[2] = offerPrice( offerId );

        return( words );
    }

    //----------------------------------------------
    // [externa] 払い戻し情報の取得
    //----------------------------------------------
    function refundInfo( uint256 offerId ) external view override returns (uint256[2] memory){
        require( _exists( offerId ), "nonexistent offer" );

        // wordsの内訳は[ITrade.sol]を参照
        uint256[2] memory words;
        words[0] = uint256(uint160(offerOfferor( offerId )));
        words[1] = offerPrice( offerId );

        return( words );
    }

    //-----------------------------------------
    // [internal] 存在確認
    //-----------------------------------------
    function _exists( uint256 offerId ) internal view returns (bool) {        
        return( offerId >= OFFER_ID_OFS && offerId < (_offers.length+OFFER_ID_OFS) );
    }

}