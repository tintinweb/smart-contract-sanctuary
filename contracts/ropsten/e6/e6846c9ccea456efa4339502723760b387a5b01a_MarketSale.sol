/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// File: node_modules\@openzeppelin\contracts-upgradeable\utils\introspection\IERC165Upgradeable.sol



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
interface IERC165Upgradeable {
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

// File: @openzeppelin\contracts-upgradeable\token\ERC721\IERC721Upgradeable.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: node_modules\@openzeppelin\contracts-upgradeable\proxy\utils\Initializable.sol



// solhint-disable-next-line compiler-version
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

// File: node_modules\@openzeppelin\contracts-upgradeable\utils\ContextUpgradeable.sol



pragma solidity ^0.8.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin\contracts-upgradeable\access\OwnableUpgradeable.sol



pragma solidity ^0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// File: node_modules\@openzeppelin\contracts-upgradeable\token\ERC721\IERC721ReceiverUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: @openzeppelin\contracts-upgradeable\token\ERC721\utils\ERC721HolderUpgradeable.sol



pragma solidity ^0.8.0;



  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// File: contracts\IMarketSale.sol


pragma solidity ^0.8.0;

interface IMarketSale {
    function sellerSalesCount(address seller) external view returns (uint256);
    
    function saleTokenOfSellerByIndex(address seller, uint256 index) external view returns (uint256);

    function totalSaleToknes() external view returns (uint256);

    function saleTokenByIndex(uint256 index) external view returns (uint256);

    function getTokenOnSale(uint256 tokenId) external view returns (address seller, uint256 price, uint64 startedAt);

    function createSale(uint256 tokenId, uint256 price) external returns (uint256);

    function cancelSale(uint256 tokenId) external;

    function buySale(uint256 tokenId) external payable;
}

// File: contracts\MarketSale.sol


pragma solidity ^0.8.0;





contract MarketSale is IMarketSale, ERC721HolderUpgradeable, OwnableUpgradeable {

    struct Sale {
        address seller;
        uint256 price;
        uint64 startedAt;
    }

    address private _nftContract;

    uint256 private _PRICE_LIMIT;
    uint256 private _minPrice;
    uint256 private _minFee;
    uint8 private _tradeFee;

    mapping(address => uint256) private _saleBalance;

    mapping(uint256 => Sale) private tokenIdToSale;

    mapping(address => uint256) private _sellerSalesCount;
    mapping(address => mapping(uint256 => uint256)) private _sellerSaleTokens;
    mapping(uint256 => uint256) private _sellerSaleTokensIndex;

    uint256[] private _allSaleTokens;
    mapping(uint256 => uint256) private _allSaleTokensIndex;

    event SaleCreated(uint256 tokenId, uint256 price);
    event SaleSucceed(uint256 tokenId, uint256 price, address buyer);
    event SaleCancelled(uint256 tokenId);

    function initialize() initializer public {
        __ERC721Holder_init();
        __Ownable_init();
        _init();
    }

    function _init() internal {
        _PRICE_LIMIT = 1000000000000000;
        _minPrice = 1000000000000000;
        _minFee = 1000000000000000;
        _tradeFee = 1;
    }

    modifier isInitialed() {
        require(_nftContract != address(0));
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    function setNFTContract(address to) public onlyOwner {
        require(to != address(0));
        _nftContract = to;
    }

    function getNFTContract() public view returns (address) {
        return _nftContract;
    }

    function setMinPrice(uint256 to) public onlyOwner {
        require(to > _PRICE_LIMIT);
        _minPrice = to;
    }

    function getMinPrice() public view returns (uint256) {
        return _minPrice;
    }

    function setMinFee(uint256 to) public onlyOwner {
        require(to > _PRICE_LIMIT);
        _minFee = to;
    }

    function getMinFee() public view returns (uint256) {
        return _minFee;
    }

    function setTradeFee(uint8 to) public onlyOwner {
        require(to >= 1 && to < 100 );
        _tradeFee = to;
    }

    function getTradeFee() public view returns (uint256) {
        return _tradeFee;
    }

    function sellerSalesCount(address seller) public view override returns (uint256) {
        return _sellerSalesCount[seller];
    }

    function saleTokenOfSellerByIndex(address seller, uint256 index) public view override returns (uint256) {
        require(index < _sellerSalesCount[seller], "seller index out of bounds");
        return _sellerSaleTokens[seller][index];
    }

    function totalSaleToknes() public view override returns (uint256) {
        return _allSaleTokens.length;
    }

    function saleTokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < _allSaleTokens.length, "global index out of bounds");
        return _allSaleTokens[index];
    }

    function _isOnSale(Sale storage sale) internal view returns (bool) {
        return (sale.startedAt > 0);
    }

    function _safeTransferToken(address from, address to, uint256 tokenId) internal {
        IERC721Upgradeable(_nftContract).safeTransferFrom(from, to, tokenId);
    }

    function _escrow(address _owner, uint256 tokenId) internal {
        if (_owner != address(this)) {
            _safeTransferToken(_owner, address(this), tokenId);
        }
    }

    function _addSaleTokenToSellerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _sellerSalesCount[to];
        _sellerSaleTokens[to][length] = tokenId;
        _sellerSaleTokensIndex[tokenId] = length;
        _sellerSalesCount[to] += 1;
    }

    function _addSaleTokenToAllEnumeration(uint256 tokenId) private {
        _allSaleTokensIndex[tokenId] = _allSaleTokens.length;
        _allSaleTokens.push(tokenId);
    }

    function _removeSaleTokenFromSellerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _sellerSalesCount[from] - 1;
        uint256 tokenIndex = _sellerSaleTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _sellerSaleTokens[from][lastTokenIndex];
            _sellerSaleTokens[from][tokenIndex] = lastTokenId;
            _sellerSaleTokensIndex[lastTokenId] = tokenIndex;
        }

        _sellerSalesCount[from] -= 1;
        delete _sellerSaleTokensIndex[tokenId];
        delete _sellerSaleTokens[from][lastTokenIndex];
    }

    function _removeSaleTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allSaleTokens.length - 1;
        uint256 tokenIndex = _allSaleTokensIndex[tokenId];

        uint256 lastTokenId = _allSaleTokens[lastTokenIndex];

        _allSaleTokens[tokenIndex] = lastTokenId;
        _allSaleTokensIndex[lastTokenId] = tokenIndex;

        delete _allSaleTokensIndex[tokenId];
        _allSaleTokens.pop();
    }

    function _addSale(uint256 tokenId, Sale memory sale) internal {
        tokenIdToSale[tokenId] = sale;
        _addSaleTokenToSellerEnumeration(sale.seller, tokenId);
        _addSaleTokenToAllEnumeration(tokenId);
        SaleCreated(
            uint256(tokenId),
            uint256(sale.price)
        );
    }
    
    function _removeSale(uint256 tokenId) internal {
        Sale storage s = tokenIdToSale[tokenId];
        address seller = s.seller;
        _removeSaleTokenFromSellerEnumeration(seller, tokenId);
        _removeSaleTokenFromAllTokensEnumeration(tokenId);
        delete tokenIdToSale[tokenId];
    }

    function _checkMsgSenderMatchOwner(uint256 tokenId) internal view returns (bool) {
        address owner = IERC721Upgradeable(_nftContract).ownerOf(tokenId);
        return (owner == msg.sender);
    }

    function createSale(uint256 tokenId, uint256 price) public isInitialed override returns (uint256) {
        require(_checkMsgSenderMatchOwner(tokenId));
        require(price >= _minPrice, "Unit price too low");
        address seller = msg.sender;
        _escrow(seller, tokenId);
        Sale memory sale = Sale(
            seller,
            price,
            uint64(block.timestamp)
        );
        _addSale(tokenId, sale);
        return _allSaleTokens.length - 1;
    }

    function getTokenOnSale(uint256 tokenId) public view isInitialed override returns (
        address seller,
        uint256 price,
        uint64 startedAt
    ) {
        (seller, price, startedAt) = _getTokenOnSale(tokenId);
    }

    function _getTokenOnSale(uint256 tokenId) internal view returns (
        address seller,
        uint256 price,
        uint64 startedAt
    ) {
        Sale storage s = tokenIdToSale[tokenId];
        require(_isOnSale(s), "Token is not on sale");
        seller = s.seller;
        price = s.price;
        startedAt = s.startedAt;
    }

    function _cancelOnSale(uint256 tokenId, address seller) internal {
        _removeSale(tokenId);
        _safeTransferToken(address(this), seller, tokenId);
        SaleCancelled(tokenId);
    }

    function _cancelSale(uint256 tokenId) internal {
        Sale storage s = tokenIdToSale[tokenId];
        require(_isOnSale(s), "Token is not on sale");
        address seller = s.seller;
        require(msg.sender == seller);
        _cancelOnSale(tokenId, seller);
    }

    function _calculateTradeFee(uint256 payment) internal view returns (uint256) {
        uint256 fee = payment * _tradeFee / 100;
        if (fee < _minFee) {
            fee = _minFee;
        }
        return fee;
    }

    function _buySale(uint256 tokenId) internal {
        require(msg.sender != address(0), "Invalid buyer");
        require(msg.value >= _minPrice, "Invalid payment");
        address seller;
        uint256 price;
        uint64 startedAt;
        (seller, price, startedAt) = _getTokenOnSale(tokenId);
        require(msg.value >= price, "Payment not match sale price");
        _removeSale(tokenId);
        _safeTransferToken(address(this), msg.sender, tokenId);
        uint256 tradeFee = _calculateTradeFee(msg.value);
        if (msg.value > tradeFee) {
            uint256 leastAmount = msg.value - tradeFee;
            _saleBalance[seller] += leastAmount;
            /*
            if (seller != address(this)) {
                payable(seller).transfer(leastAmount);
            }
            */
        }
        SaleSucceed(tokenId, price, msg.sender);
    }

    function cancelSale(uint256 tokenId) external override {
        _cancelSale(tokenId);
    }

    function buySale(uint256 tokenId) external payable isInitialed override {
        _buySale(tokenId);
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        address owner = owner();
        payable(owner).transfer(balance);
    }

    function getSaleBalance(address seller) external view returns (uint256) {
        return _saleBalance[seller];
    }

    function withdrawSaleBalance() external {
        uint256 balance = _saleBalance[msg.sender];
        require(balance >= _minFee, "Too little balance");
        _saleBalance[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }
}