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

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./base/ERC721HeroCallerBase.sol";
import "./base/ERC20TokenCallerBase.sol";
import "./interface/IHeroMarket.sol";
import "./interface/IHeroMarketEnum.sol";

/* Market Contract
** sell hero by fixed prie
*/
contract HeroMarket is IHeroMarket, IHeroMarketEnum, ERC721HeroCallerBase, ERC20TokenCallerBase, ERC721Holder {

    struct Sale {
        address payable seller;
        uint256 price;
        uint64 startedAt;
    }

    // price limit
    uint256 private _PRICE_LIMIT;
    // min price
    uint256 private _minPrice;
    // min trade fee
    uint256 private _minFee;
    // trade fee pecentage
    uint8 private _tradeFee;
    // total trade fee receieved
    uint256 private _totalFeeAmount;

    mapping(uint256 => Sale) private tokenIdToSale;

    mapping(address => uint256) private _sellerSalesCount;
    mapping(address => mapping(uint256 => uint256)) private _sellerSaleTokens;
    mapping(uint256 => uint256) private _sellerSaleTokensIndex;

    uint256[] private _allSaleTokens;
    mapping(uint256 => uint256) private _allSaleTokensIndex;

    event SaleCreated(uint256 tokenId, uint256 price, address payable seller);
    event SaleSucceed(uint256 tokenId, uint256 price, address payable seller, address buyer);
    event SaleCancelled(uint256 tokenId, address seller);

    constructor() {
        _PRICE_LIMIT = 0.01 ether;
        _minPrice = 0.01 ether;
        _minFee = 0.001 ether;
        _tradeFee = 1;
        _totalFeeAmount = 0;
    }

    fallback() external payable {}

    receive() external payable {}

    function setMinPrice(uint256 to) public {
        require(to > _PRICE_LIMIT);
        _minPrice = to;
    }

    function getMinPrice() public view returns (uint256) {
        return _minPrice;
    }

    function setMinFee(uint256 to) public {
        require(to > _PRICE_LIMIT);
        _minFee = to;
    }

    function getMinFee() public view returns (uint256) {
        return _minFee;
    }

    function setTradeFee(uint8 to) public {
        require(to >= 1 && to < 100 );
        _tradeFee = to;
    }

    function getTradeFee() public view returns (uint256) {
        return _tradeFee;
    }

    function getTotalFeeAmount() public view returns (uint256) {
        return _totalFeeAmount;
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

    function _escrow(address _owner, uint256 tokenId) internal {
        if (_owner != address(this)) {
            _safeTransferHeroToken(_owner, address(this), tokenId);
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

    // add a hero on sale
    function _addSale(uint256 tokenId, Sale memory sale) internal {
        tokenIdToSale[tokenId] = sale;
        _addSaleTokenToSellerEnumeration(sale.seller, tokenId);
        _addSaleTokenToAllEnumeration(tokenId);
        emit SaleCreated(
            uint256(tokenId),
            uint256(sale.price),
            sale.seller
        );
    }
    
    // remove a hero from sale
    function _removeSale(uint256 tokenId) internal {
        Sale storage s = tokenIdToSale[tokenId];
        address seller = s.seller;
        _removeSaleTokenFromSellerEnumeration(seller, tokenId);
        _removeSaleTokenFromAllTokensEnumeration(tokenId);
        delete tokenIdToSale[tokenId];
    }

    // check whether the sender is owner
    function _checkMsgSenderMatchOwner(uint256 tokenId) internal view returns (bool) {
        address owner = ownerOfHero(tokenId);
        return (owner == msg.sender);
    }

    // add a hero on sale
    function createSale(uint256 tokenId, uint256 price) public override returns (uint256) {
        require(_checkMsgSenderMatchOwner(tokenId), "Not hero owner");
        require(price >= _minPrice, "Unit price too low");
        address payable seller = payable(msg.sender);
        _escrow(seller, tokenId);
        Sale memory sale = Sale(
            seller,
            price,
            uint64(block.timestamp)
        );
        _addSale(tokenId, sale);
        // return on sale hero count
        return _allSaleTokens.length - 1;
    }

    // get a hero sale details
    function getTokenOnSale(uint256 tokenId) public view override returns (
        address payable seller,
        uint256 price,
        uint64 startedAt
    ) {
        (seller, price, startedAt) = _getTokenOnSale(tokenId);
    }

    function _getTokenOnSale(uint256 tokenId) internal view returns (
        address payable seller,
        uint256 price,
        uint64 startedAt
    ) {
        Sale storage s = tokenIdToSale[tokenId];
        require(_isOnSale(s), "Token is not on sale");
        seller = s.seller;
        price = s.price;
        startedAt = s.startedAt;
    }

    // cancel a hero from sale
    function _cancelOnSale(uint256 tokenId, address seller) internal {
        // remove sale
        _removeSale(tokenId);
        // transfor the hero back to seller
        _safeTransferHeroToken(address(this), seller, tokenId);
        emit SaleCancelled(tokenId, seller);
    }

    function _cancelSale(uint256 tokenId) internal {
        Sale storage s = tokenIdToSale[tokenId];
        require(_isOnSale(s), "Token is not on sale");
        address seller = s.seller;
        require(msg.sender == seller);
        _cancelOnSale(tokenId, seller);
    }

    function _forceCancelSale(uint256 tokenId) internal {
        Sale storage s = tokenIdToSale[tokenId];
        require(_isOnSale(s), "Token is not on sale");
        address seller = s.seller;
        _cancelOnSale(tokenId, seller);
    }

    // calculate the trade fee
    function _calculateTradeFee(uint256 payment) internal view returns (uint256) {
        uint256 fee = payment * _tradeFee / 100;
        if (fee < _minFee) {
            fee = _minFee;
        }
        return fee;
    }

    // buy a hero on sale
    function _buySale(uint256 tokenId) internal {
        require(msg.sender != address(0), "Invalid buyer");

        address payable seller;
        uint256 price;
        uint64 startedAt;
        (seller, price, startedAt) = _getTokenOnSale(tokenId);

        require(msg.sender != seller, "Could not buy your own item");

        checkERC20TokenBalanceAndApproved(msg.sender, price);

        transferERC20TokenFrom(msg.sender, address(this), price);

        // remove sale first
        _removeSale(tokenId);
        // transfer hero to buyer
        _safeTransferHeroToken(address(this), msg.sender, tokenId);
        uint256 tradeFee = _calculateTradeFee(price);
        // calculate trade fee
        if (price > tradeFee) {
            _totalFeeAmount += tradeFee;
            uint256 leastAmount = price - tradeFee;
            // transfer least payment to seller
            transferERC20Token(msg.sender, leastAmount);
        } else {
            // if trade fee is less than min trade fee, no least fee to pay back to seller
            _totalFeeAmount += msg.value;
        }
        emit SaleSucceed(tokenId, price, seller, msg.sender);
    }

    // cancel a hero from sale
    function cancelSale(uint256 tokenId) external override {
        _cancelSale(tokenId);
    }

    // buy a hero on sale
    function buySale(uint256 tokenId) external payable override {
        _buySale(tokenId);
    }

    // withdraw trade fee from contract
    function withdrawBalance(address payable to, uint256 amount) external override {
        _transferBalance(to, amount);
    }

    function _transferBalance(address payable to, uint256 amount) internal {
        transferERC20Token(to, amount);
    }

    function cancelLastSale(uint256 count) public {
        uint256 totalCount = totalSaleToknes();
        require(count <= totalCount);
        for (uint i=0; i<count; i++) {
            uint256 currentTotal = totalSaleToknes();
            uint256 lastTokenId = saleTokenByIndex(currentTotal - 1);
            _forceCancelSale(lastTokenId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20TokenCallerBase {

    address internal _token20Contract;

    constructor() {
    }

    modifier token20Ready() {
        require(_token20Contract != address(0), "Token contract is not ready");
        _;
    }

    function token20Contract() public view returns (address) {
        return _token20Contract;
    }

    function setToken20Contract(address addr) public {
        _token20Contract = addr;
    }

    function transferERC20TokenFrom(address sender, address recipient, uint256 amount) internal {
        IERC20(_token20Contract).transferFrom(sender, recipient, amount);
    }

    function transferERC20Token(address recipient, uint256 amount) internal {
        IERC20(_token20Contract).transfer(recipient, amount);
    }

    function balanceOfERC20Token(address owner) internal view returns (uint256) {
        return IERC20(_token20Contract).balanceOf(owner);
    }
    
    function allowanceOfERC20Token(address owner, address spender) internal view returns (uint256) {
        return IERC20(_token20Contract).allowance(owner, spender);
    }

    function checkERC20TokenBalanceAndApproved(address owner, uint256 amount) internal view {
        uint256 tokenBalance = balanceOfERC20Token(owner);
        require(tokenBalance >= amount, "Token balance not enough");

        uint256 allowanceToken = allowanceOfERC20Token(owner, address(this));
        require(allowanceToken >= amount, "Token allowance not enough");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/IIdleHero.sol";

contract ERC721HeroCallerBase {

    address internal _heroContract;

    constructor() {
    }

    modifier heroReady() {
        require(_heroContract != address(0), "Hero contract is not ready");
        _;
    }

    function heroContract() public view returns (address) {
        return _heroContract;
    }

    function setHeroContract(address addr) public {
        _heroContract = addr;
    }

    function ownerOfHero(uint256 tokenId) internal view returns (address)  {
        return IERC721(_heroContract).ownerOf(tokenId);
    }

    function _safeMintHero(address to, uint256 newDNA) internal {
        IIdleHero(_heroContract).safeMintHero(to, newDNA);
    }

    function _safeTransferHeroToken(address from, address to, uint256 tokenId) internal {
        IERC721(_heroContract).safeTransferFrom(from, to, tokenId);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// market contract interface
interface IHeroMarket {
    function getTokenOnSale(uint256 tokenId) external view returns (address payable seller, uint256 price, uint64 startedAt);

    function createSale(uint256 tokenId, uint256 price) external returns (uint256);

    function cancelSale(uint256 tokenId) external;

    function buySale(uint256 tokenId) external payable;

    function withdrawBalance(address payable to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// market contract enum interface
interface IHeroMarketEnum {
    function sellerSalesCount(address seller) external view returns (uint256);
    
    function saleTokenOfSellerByIndex(address seller, uint256 index) external view returns (uint256);

    function totalSaleToknes() external view returns (uint256);

    function saleTokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IdleHero contract interface
interface IIdleHero {
    function safeMintHero(address to, uint256 dna) external returns (uint256);
}

