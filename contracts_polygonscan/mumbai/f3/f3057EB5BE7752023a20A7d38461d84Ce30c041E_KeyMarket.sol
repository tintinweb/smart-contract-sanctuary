/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

// File: node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol

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

// File: node_modules\@openzeppelin\contracts\token\ERC721\IERC721.sol






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

// File: @openzeppelin\contracts\token\ERC721\extensions\IERC721Enumerable.sol






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

// File: contracts\interface\IIdleKey.sol




// IdleKey Interface
interface IIdleKey {
    function currentId() external view returns (uint256);
    function isSoldOut() external view returns (bool);
    function safeMintKeys(address to, uint256 count) external;
    function safeMintKey(address to) external returns (uint256);
    function burn(uint256 tokenId) external;
}

// File: contracts\base\ERC721KeyCallerBase.sol






contract ERC721KeyCallerBase {

    address internal _keyContract;

    constructor() {
    }

    modifier keyReady() {
        require(_keyContract != address(0), "Key contract is not ready");
        _;
    }

    function keyContract() public view returns (address) {
        return _keyContract;
    }

    function setKeyContract(address addr) public {
        _keyContract = addr;
    }

    function balanceOfKey(address owner) internal view returns (uint256) {
        return IERC721Enumerable(_keyContract).balanceOf(owner);
    }
    
    function isApprovedForAllKeys(address owner, address operator) internal view returns (bool) {
        return IERC721Enumerable(_keyContract).isApprovedForAll(owner, operator);
    }

    function keyOfOwnerByIndex(address owner, uint256 index) internal view returns (uint256) {
        return IERC721Enumerable(_keyContract).tokenOfOwnerByIndex(owner, index);
    }

    function burnKey(uint256 tokenId) internal {
        IIdleKey(_keyContract).burn(tokenId);
    }

    function isKeySoldOut() internal view returns (bool) {
        return IIdleKey(_keyContract).isSoldOut();
    }

    function safeMintKey(address to) internal {
        IIdleKey(_keyContract).safeMintKey(to);
    }

    function safeMintKeys(address to, uint256 count) internal {
        IIdleKey(_keyContract).safeMintKeys(to, count);
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol





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

// File: contracts\base\ERC20TokenCallerBase.sol





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

// File: contracts\KeyMarket.sol






contract KeyMarket is ERC721KeyCallerBase, ERC20TokenCallerBase {

    uint256 private _keyPrice;

    event KeyPriceChanged(uint256 newPrice);

    constructor() {
        _keyPrice = 1 ether;
    }

    function setKeyPrice(uint256 price) public {
        _keyPrice = price;
        emit KeyPriceChanged(_keyPrice);
    }

    function buyKey() public payable {
        bool isKeySoldOut = isKeySoldOut();
        require(!isKeySoldOut, "Key has been sold out");

        checkERC20TokenBalanceAndApproved(msg.sender, _keyPrice);

        transferERC20TokenFrom(msg.sender, address(this), _keyPrice);

        safeMintKey(msg.sender);
    }

    function buyKeys(uint256 count) public payable {
        bool isKeySoldOut = isKeySoldOut();
        require(!isKeySoldOut, "Key has been sold out");
        require(count <= 10, "Max 10 keys in one time");

        uint256 totalPrice = _keyPrice * count;

        checkERC20TokenBalanceAndApproved(msg.sender, totalPrice);

        transferERC20TokenFrom(msg.sender, address(this), totalPrice);
        
        safeMintKeys(msg.sender, count);
    }

    function withdraw(address payable to, uint256 amount) public {
        uint256 currentBalance = address(this).balance;
        require(amount <= currentBalance, "No enough balance");
        transferERC20Token(to, amount);
    }

}