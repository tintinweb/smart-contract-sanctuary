// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

/// @title ISVG image library types interface
/// @dev Allows Solidity files to reference the library's input and return types without referencing the library itself
interface ISVGTypes {

    /// Represents a color in RGB format with alpha
    struct Color {
        uint8 red;
        uint8 green;
        uint8 blue;
        uint8 alpha;
    }

    /// Represents a color attribute in an SVG image file
    enum ColorAttribute {
        Fill, Stroke, Stop
    }

    /// Represents the kind of color attribute in an SVG image file
    enum ColorAttributeKind {
        RGB, URL
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "base64-sol/base64.sol";

/// @title OnChain metadata support library
/**
 * @dev These methods are best suited towards view/pure only function calls (ALL the way through the call stack).
 * Do not waste gas using these methods in functions that also update state, unless your need requires it.
 */
library OnChain {

    /// Returns the prefix needed for a base64-encoded on chain svg image
    function baseSvgImageURI() internal pure returns (bytes memory) {
        return "data:image/svg+xml;base64,";
    }

    /// Returns the prefix needed for a base64-encoded on chain nft metadata
    function baseURI() internal pure returns (bytes memory) {
        return "data:application/json;base64,";
    }

    /// Returns the contents joined with a comma between them
    /// @param contents1 The first content to join
    /// @param contents2 The second content to join
    /// @return A collection of bytes that represent all contents joined with a comma
    function commaSeparated(bytes memory contents1, bytes memory contents2) internal pure returns (bytes memory) {
        return abi.encodePacked(contents1, continuesWith(contents2));
    }

    /// Returns the contents joined with commas between them
    /// @param contents1 The first content to join
    /// @param contents2 The second content to join
    /// @param contents3 The third content to join
    /// @return A collection of bytes that represent all contents joined with commas
    function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3) internal pure returns (bytes memory) {
        return abi.encodePacked(commaSeparated(contents1, contents2), continuesWith(contents3));
    }

    /// Returns the contents joined with commas between them
    /// @param contents1 The first content to join
    /// @param contents2 The second content to join
    /// @param contents3 The third content to join
    /// @param contents4 The fourth content to join
    /// @return A collection of bytes that represent all contents joined with commas
    function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3, bytes memory contents4) internal pure returns (bytes memory) {
        return abi.encodePacked(commaSeparated(contents1, contents2, contents3), continuesWith(contents4));
    }

    /// Returns the contents joined with commas between them
    /// @param contents1 The first content to join
    /// @param contents2 The second content to join
    /// @param contents3 The third content to join
    /// @param contents4 The fourth content to join
    /// @param contents5 The fifth content to join
    /// @return A collection of bytes that represent all contents joined with commas
    function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3, bytes memory contents4, bytes memory contents5) internal pure returns (bytes memory) {
        return abi.encodePacked(commaSeparated(contents1, contents2, contents3, contents4), continuesWith(contents5));
    }

    /// Returns the contents joined with commas between them
    /// @param contents1 The first content to join
    /// @param contents2 The second content to join
    /// @param contents3 The third content to join
    /// @param contents4 The fourth content to join
    /// @param contents5 The fifth content to join
    /// @param contents6 The sixth content to join
    /// @return A collection of bytes that represent all contents joined with commas
    function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3, bytes memory contents4, bytes memory contents5, bytes memory contents6) internal pure returns (bytes memory) {
        return abi.encodePacked(commaSeparated(contents1, contents2, contents3, contents4, contents5), continuesWith(contents6));
    }

    /// Returns the contents prefixed by a comma
    /// @dev This is used to append multiple attributes into the json
    /// @param contents The contents with which to prefix
    /// @return A bytes collection of the contents prefixed with a comma
    function continuesWith(bytes memory contents) internal pure returns (bytes memory) {
        return abi.encodePacked(",", contents);
    }

    /// Returns the contents wrapped in a json dictionary
    /// @param contents The contents with which to wrap
    /// @return A bytes collection of the contents wrapped as a json dictionary
    function dictionary(bytes memory contents) internal pure returns (bytes memory) {
        return abi.encodePacked("{", contents, "}");
    }

    /// Returns an unwrapped key/value pair where the value is an array
    /// @param key The name of the key used in the pair
    /// @param value The value of pair, as an array
    /// @return A bytes collection that is suitable for inclusion in a larger dictionary
    function keyValueArray(string memory key, bytes memory value) internal pure returns (bytes memory) {
        return abi.encodePacked("\"", key, "\":[", value, "]");
    }

    /// Returns an unwrapped key/value pair where the value is a string
    /// @param key The name of the key used in the pair
    /// @param value The value of pair, as a string
    /// @return A bytes collection that is suitable for inclusion in a larger dictionary
    function keyValueString(string memory key, bytes memory value) internal pure returns (bytes memory) {
        return abi.encodePacked("\"", key, "\":\"", value, "\"");
    }

    /// Encodes an SVG as base64 and prefixes it with a URI scheme suitable for on-chain data
    /// @param svg The contents of the svg
    /// @return A bytes collection that may be added to the "image" key/value pair in ERC-721 or ERC-1155 metadata
    function svgImageURI(bytes memory svg) internal pure returns (bytes memory) {
        return abi.encodePacked(baseSvgImageURI(), Base64.encode(svg));
    }

    /// Encodes json as base64 and prefixes it with a URI scheme suitable for on-chain data
    /// @param metadata The contents of the metadata
    /// @return A bytes collection that may be returned as the tokenURI in a ERC-721 or ERC-1155 contract
    function tokenURI(bytes memory metadata) internal pure returns (bytes memory) {
        return abi.encodePacked(baseURI(), Base64.encode(metadata));
    }

    /// Returns the json dictionary of a single trait attribute for an ERC-721 or ERC-1155 NFT
    /// @param name The name of the trait
    /// @param value The value of the trait
    /// @return A collection of bytes that can be embedded within a larger array of attributes
    function traitAttribute(string memory name, bytes memory value) internal pure returns (bytes memory) {
        return dictionary(commaSeparated(
            keyValueString("trait_type", bytes(name)),
            keyValueString("value", value)
        ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./RandomizationErrors.sol";

/// @title Randomization library
/// @dev Lightweight library used for basic randomization capabilities for ERC-721 tokens when an Oracle is not available
library Randomization {

    /// Returns a value based on the spread of a random uint8 seed and provided percentages
    /// @dev The last percentage is assumed if the sum of all elements do not add up to 100, in which case the length of the array is returned
    /// @param random A uint8 random value
    /// @param percentages An array of percentages
    /// @return The index in which the random seed falls, which can be the length of the input array if the values do not add up to 100
    function randomIndex(uint8 random, uint8[] memory percentages) internal pure returns (uint256) {
        uint256 spread = (3921 * uint256(random) / 10000) % 100; // 0-255 needs to be balanced to evenly spread with % 100
        uint256 remainingPercent = 100;
        for (uint256 i = 0; i < percentages.length; i++) {
            uint256 nextPercentage = percentages[i];
            if (remainingPercent < nextPercentage) revert PercentagesGreaterThan100();
            remainingPercent -= nextPercentage;
            if (spread >= remainingPercent) {
                return i;
            }
        }
        return percentages.length;
    }

    /// Returns a random seed suitable for ERC-721 attribute generation when an Oracle such as ChainLink VRF is not available to a contract
    /// @dev Not suitable for mission-critical code. Always be sure to perform an analysis of your randomization before deploying to production
    /// @param initialSeed A uint256 that seeds the randomization function
    /// @return A seed that can be used for attribute generation, which may also be used as the `initialSeed` for a future call
    function randomSeed(uint256 initialSeed) internal view returns (uint256) {
        // Unit tests should confirm that this provides a more-or-less even spread of randomness
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, initialSeed >> 1)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When the percentages array sum up to more than 100
error PercentagesGreaterThan100();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/ISVGTypes.sol";
import "./OnChain.sol";
import "./SVGErrors.sol";

/// @title SVG image library
/**
 * @dev These methods are best suited towards view/pure only function calls (ALL the way through the call stack).
 * Do not waste gas using these methods in functions that also update state, unless your need requires it.
 */
library SVG {

    using Strings for uint256;

    /// Returns a named element based on the supplied attributes and contents
    /// @dev attributes and contents is usually generated from abi.encodePacked, attributes is expecting a leading space
    /// @param name The name of the element
    /// @param attributes The attributes of the element, as bytes, with a leading space
    /// @param contents The contents of the element, as bytes
    /// @return a bytes collection representing the whole element
    function createElement(string memory name, bytes memory attributes, bytes memory contents) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "<", attributes.length == 0 ? bytes(name) : abi.encodePacked(name, attributes),
            contents.length == 0 ? bytes("/>") : abi.encodePacked(">", contents, "</", name, ">")
        );
    }

    /// Returns the root SVG attributes based on the supplied width and height
    /// @dev includes necessary leading space for createElement's `attributes` parameter
    /// @param width The width of the SVG view box
    /// @param height The height of the SVG view box
    /// @return a bytes collection representing the root SVG attributes, including a leading space
    function svgAttributes(uint256 width, uint256 height) internal pure returns (bytes memory) {
        return abi.encodePacked(" viewBox='0 0 ", width.toString(), " ", height.toString(), "' xmlns='http://www.w3.org/2000/svg'");
    }

    /// Returns an RGB bytes collection suitable as an attribute for SVG elements based on the supplied Color and ColorType
    /// @dev includes necessary leading space for all types _except_ None
    /// @param attribute The `ISVGTypes.ColorAttribute` of the desired attribute
    /// @param value The converted color value as bytes
    /// @return a bytes collection representing a color attribute in an SVG element
    function colorAttribute(ISVGTypes.ColorAttribute attribute, bytes memory value) internal pure returns (bytes memory) {
        if (attribute == ISVGTypes.ColorAttribute.Fill) return _attribute("fill", value);
        if (attribute == ISVGTypes.ColorAttribute.Stop) return _attribute("stop-color", value);
        return  _attribute("stroke", value); // Fallback to Stroke
    }

    /// Returns an RGB color attribute value
    /// @param color The `ISVGTypes.Color` of the color
    /// @return a bytes collection representing the url attribute value
    function colorAttributeRGBValue(ISVGTypes.Color memory color) internal pure returns (bytes memory) {
        return _colorValue(ISVGTypes.ColorAttributeKind.RGB, OnChain.commaSeparated(
            bytes(uint256(color.red).toString()),
            bytes(uint256(color.green).toString()),
            bytes(uint256(color.blue).toString())
        ));
    }

    /// Returns a URL color attribute value
    /// @param url The url to the color
    /// @return a bytes collection representing the url attribute value
    function colorAttributeURLValue(bytes memory url) internal pure returns (bytes memory) {
        return _colorValue(ISVGTypes.ColorAttributeKind.URL, url);
    }

    /// Returns an `ISVGTypes.Color` that is brightened by the provided percentage
    /// @param source The `ISVGTypes.Color` to brighten
    /// @param percentage The percentage of brightness to apply
    /// @param minimumBump A minimum increase for each channel to ensure dark Colors also brighten
    /// @return color the brightened `ISVGTypes.Color`
    function brightenColor(ISVGTypes.Color memory source, uint32 percentage, uint8 minimumBump) internal pure returns (ISVGTypes.Color memory color) {
        color.red = _brightenComponent(source.red, percentage, minimumBump);
        color.green = _brightenComponent(source.green, percentage, minimumBump);
        color.blue = _brightenComponent(source.blue, percentage, minimumBump);
        color.alpha = source.alpha;
    }

    /// Returns an `ISVGTypes.Color` based on a packed representation of r, g, and b
    /// @notice Useful for code where you want to utilize rgb hex values provided by a designer (e.g. #835525)
    /// @dev Alpha will be hard-coded to 100% opacity
    /// @param packedColor The `ISVGTypes.Color` to convert, e.g. 0x835525
    /// @return color representing the packed input
    function fromPackedColor(uint24 packedColor) internal pure returns (ISVGTypes.Color memory color) {
        color.red = uint8(packedColor >> 16);
        color.green = uint8(packedColor >> 8);
        color.blue = uint8(packedColor);
        color.alpha = 0xFF;
    }

    /// Returns a mixed Color by balancing the ratio of `color1` over `color2`, with a total percentage (for overmixing and undermixing outside the source bounds)
    /// @dev Reverts with `RatioInvalid()` if `ratioPercentage` is > 100
    /// @param color1 The first `ISVGTypes.Color` to mix
    /// @param color2 The second `ISVGTypes.Color` to mix
    /// @param ratioPercentage The percentage ratio of `color1` over `color2` (e.g. 60 = 60% first, 40% second)
    /// @param totalPercentage The total percentage after mixing (for overmixing and undermixing outside the input colors)
    /// @return color representing the result of the mixture
    function mixColors(ISVGTypes.Color memory color1, ISVGTypes.Color memory color2, uint32 ratioPercentage, uint32 totalPercentage) internal pure returns (ISVGTypes.Color memory color) {
        if (ratioPercentage > 100) revert RatioInvalid();
        color.red = _mixComponents(color1.red, color2.red, ratioPercentage, totalPercentage);
        color.green = _mixComponents(color1.green, color2.green, ratioPercentage, totalPercentage);
        color.blue = _mixComponents(color1.blue, color2.blue, ratioPercentage, totalPercentage);
        color.alpha = _mixComponents(color1.alpha, color2.alpha, ratioPercentage, totalPercentage);
    }

    /// Returns a proportionally-randomized Color between the start and stop colors using a random Color seed
    /// @dev Each component (r,g,b) will move proportionally together in the direction from start to stop
    /// @param start The starting bound of the `ISVGTypes.Color` to randomize
    /// @param stop The stopping bound of the `ISVGTypes.Color` to randomize
    /// @param random An `ISVGTypes.Color` to use as a seed for randomization
    /// @return color representing the result of the randomization
    function randomizeColors(ISVGTypes.Color memory start, ISVGTypes.Color memory stop, ISVGTypes.Color memory random) internal pure returns (ISVGTypes.Color memory color) {
        uint16 percent = uint16((1320 * (uint(random.red) + uint(random.green) + uint(random.blue)) / 10000) % 101); // Range is from 0-100
        color.red = _randomizeComponent(start.red, stop.red, random.red, percent);
        color.green = _randomizeComponent(start.green, stop.green, random.green, percent);
        color.blue = _randomizeComponent(start.blue, stop.blue, random.blue, percent);
        color.alpha = 0xFF;
    }

    function _attribute(bytes memory name, bytes memory contents) private pure returns (bytes memory) {
        return abi.encodePacked(" ", name, "='", contents, "'");
    }

    function _brightenComponent(uint8 component, uint32 percentage, uint8 minimumBump) private pure returns (uint8 result) {
        uint32 wideComponent = uint32(component);
        uint32 brightenedComponent = wideComponent * (percentage + 100) / 100;
        uint32 wideMinimumBump = uint32(minimumBump);
        if (brightenedComponent - wideComponent < wideMinimumBump) {
            brightenedComponent = wideComponent + wideMinimumBump;
        }
        if (brightenedComponent > 0xFF) {
            result = 0xFF; // Clamp to 8 bits
        } else {
            result = uint8(brightenedComponent);
        }
    }

    function _colorValue(ISVGTypes.ColorAttributeKind attributeKind, bytes memory contents) private pure returns (bytes memory) {
        return abi.encodePacked(attributeKind == ISVGTypes.ColorAttributeKind.RGB ? "rgb(" : "url(#", contents, ")");
    }

    function _mixComponents(uint8 component1, uint8 component2, uint32 ratioPercentage, uint32 totalPercentage) private pure returns (uint8 component) {
        uint32 mixedComponent = (uint32(component1) * ratioPercentage + uint32(component2) * (100 - ratioPercentage)) * totalPercentage / 10000;
        if (mixedComponent > 0xFF) {
            component = 0xFF; // Clamp to 8 bits
        } else {
            component = uint8(mixedComponent);
        }
    }

    function _randomizeComponent(uint8 start, uint8 stop, uint8 random, uint16 percent) private pure returns (uint8 component) {
        if (start == stop) {
            component = start;
        } else { // This is the standard case
            (uint8 floor, uint8 ceiling) = start < stop ? (start, stop) : (stop, start);
            component = floor + uint8(uint16(ceiling - (random & 0x01) - floor) * percent / uint16(100));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When the ratio percentage provided to a function is > 100
error RatioInvalid();

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICloudTraits.sol";

/// @title CloudCollective NFT Interface for provided ICloudTraits
interface ICloudTraitProvider{

    /// Returns the ButterflyEffect for the given cloud
    /// @param tokenId The ID of the token that represents the Cloud
    /// @return The Forecast structure
    function butterflyEffect(uint256 tokenId) external view returns (ICloudTraits.ButterflyEffect memory);

    /// Returns the cloud forecast associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the Cloud
    /// @return forecast memory
    function cloudForecast(uint256 tokenId) external view returns (ICloudTraits.Forecast memory forecast);

    /// Returns the text of a cloud condition
    /// @param condition The Condition
    /// @return The condition text
    function conditionName(ICloudTraits.Condition condition) external pure returns (string memory);

    /// Returns the text of the cloud energy category
    /// @param energyCategory The EnergyCategory
    /// @return the energy category text
    function energyCategoryName(ICloudTraits.EnergyCategory energyCategory) external pure returns (string memory);

    /// Represents the text of the cloud energy state
    /// @param forecast The forecast obtained from `forecastForCloud()`
    /// @return The cloud energy state text
    function energyStateName(ICloudTraits.Forecast memory forecast) external view returns (string memory);

    /// Returns the text of a cloud scale
    /// @param scale The Scale
    /// @return The scale text
    function scaleName(ICloudTraits.Scale scale) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@theappstudio/solidity/contracts/interfaces/ISVGTypes.sol";

/// @title ICloudTraits interface
interface ICloudTraits {

    /// Represents the cloud condition
    enum Condition {
        Luminous, Overcast, Stormy, Golden, Magic
    }

    /// Represents the Categories of energies
    enum EnergyCategory {
        Soothe, Center, Grow, Connect, Empower, Enlighten
    }

    /// Represents the formations in CloudCollective
    enum Formation {
        A, B, C, D, E
    }

    /// Represents the cloud scales
    enum Scale {
        Tiny, Petite, Moyenne, Milieu, Grande, Super, Monstre
    }

    /// Represents the seed that forms a group of clouds
    /// @dev organized to fit within 256 bits and consume the least amount of resources
    struct ButterflyEffect {
        uint256 seed;
    }

    /// Represents the forecast of a CloudCollective Cloud
    struct Forecast {
        Formation formation;
        bool mirrored;
        Scale scale;
        Condition condition;
        ISVGTypes.Color color;
        EnergyCategory energyCategory;
        uint8 energy;
        uint200 chaos;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@theappstudio/solidity/contracts/utils/OnChain.sol";
import "@theappstudio/solidity/contracts/utils/Randomization.sol";
import "@theappstudio/solidity/contracts/utils/SVG.sol";
import "../interfaces/ICloudTraitProvider.sol";
import "../utils/CloudCollectiveErrors.sol";
import "../utils/CloudFormation.sol";
import "../utils/Whitelisted.sol";

/// @title CloudCollective
contract CloudCollective is ERC721, PaymentSplitter, ICloudTraitProvider, Ownable, ReentrancyGuard {

    using Strings for uint256;

    /// Price to form one cloud
    uint256 public constant FORMATION_PRICE = 0.06 ether;

    /// Maximum clouds that will be formed
    uint256 public constant MAX_CLOUDS = 9999;

    /// Maximum quantity of clouds that can be formed at once
    /// @dev changing this has an impact on `_forecastForToken()`
    uint256 public constant MAX_FORMATION_QUANTITY = 50;

    /// @dev Seed for randomness
    uint256 private _seed;

    /// @dev The block number when formation is available
    uint256 private _wenMint;

    /// @dev Enables/disables the reveal
    bool private _wenReveal;

    /// @dev Mapping of TokenIds to Seeds
    uint256[] private _tokenIdsToSeeds;

    /// @dev Holders of these 100% on-chain projects are whitelisted
    Whitelisted private immutable _whitelisted;

    /// Look...at these...Clouds
    constructor(uint256 seed, address whitelisted, address[] memory payees, uint256[] memory shares_) ERC721("CloudCollective", "CCT") PaymentSplitter(payees, shares_) {
        _seed = seed;
        _whitelisted = Whitelisted(whitelisted);
    }

    /// @inheritdoc ICloudTraitProvider
    function butterflyEffect(uint256 tokenId) external view onlyWhenExists(tokenId) onlyWenRevealed returns (ICloudTraits.ButterflyEffect memory) {
        return _seedForToken(tokenId);
    }

    /// @inheritdoc ICloudTraitProvider
    function cloudForecast(uint256 tokenId) public view override onlyWhenExists(tokenId) onlyWenRevealed returns (ICloudTraits.Forecast memory forecast) {
        forecast = _forecastForToken(tokenId);
    }

    /// @inheritdoc ICloudTraitProvider
    function conditionName(ICloudTraits.Condition condition) public pure returns (string memory) {
        string[5] memory conditions = ["Luminous", "Overcast", "Stormy", "Golden", "Magic"];
        return conditions[uint256(condition)];
    }

    /// @notice For easy import into MetaMask
    function decimals() external pure returns (uint256) {
        return 0;
    }

    /// @inheritdoc ICloudTraitProvider
    function energyCategoryName(ICloudTraits.EnergyCategory energyCategory) public pure override returns (string memory) {
        string[6] memory energyCategories = ["Soothe", "Center", "Grow", "Connect", "Empower", "Enlighten"];
        return energyCategories[uint256(energyCategory)];
    }

    /// @inheritdoc ICloudTraitProvider
    function energyStateName(ICloudTraits.Forecast memory forecast) public pure override returns (string memory) {
        string[6] memory energyCategories;
        if (forecast.energyCategory == ICloudTraits.EnergyCategory.Soothe) {
            energyCategories = ["Relaxation", "Peace", "Calm", "Lightness", "Comfort", "Healing"];
        } else if (forecast.energyCategory == ICloudTraits.EnergyCategory.Center) {
            energyCategories = ["Truth", "Gratitude", "Clarity", "Awareness", "Acceptance", "Alignment"];
        } else if (forecast.energyCategory == ICloudTraits.EnergyCategory.Grow) {
            energyCategories = ["Transformation", "Possibility", "Expansiveness", "Prosperity", "Opportunity", "Abundance"];
        } else if (forecast.energyCategory == ICloudTraits.EnergyCategory.Connect) {
            energyCategories = ["Love", "Wisdom", "Intuition", "Compassion", "Alignment", "Empathy"];
        } else if (forecast.energyCategory == ICloudTraits.EnergyCategory.Empower) {
            energyCategories = ["Courage", "Strength", "Groundedness", "Resilience", "Purpose", "Certainty"];
        } else /* if (forecast.energyCategory == ICloudTraits.EnergyCategory.Enlighten) */ {
            energyCategories = ["Joy", "Happiness", "Amusement", "Manifestation", "Creativity", "Passion"];
        }
        return energyCategories[forecast.energy];
    }

    /// Forms the provided quantity of CloudCollective tokens
    /// @param quantity The quantity of CloudCollective tokens to form
    function formClouds(uint256 quantity) external payable nonReentrant {
        if (_wenMint > 0) {
            if (block.number < _wenMint) revert NotOpenForMinting();
        } else { // Check whitelist (needs reentrancy protection)
            if (!_whitelisted.isWhitelisted(_msgSender())) revert NotWhitelisted();
        }
        if (quantity == 0 || quantity > MAX_FORMATION_QUANTITY) revert InvalidQuantity();
        if (_tokenIdsToSeeds.length + quantity > MAX_CLOUDS) revert NoMoreClouds();
        if (msg.value < FORMATION_PRICE * quantity) revert InvalidPriceSent();
        _formClouds(quantity);
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /// @inheritdoc ICloudTraitProvider
    function scaleName(ICloudTraits.Scale scale) public pure returns (string memory) {
        string[7] memory scales = ["Tiny", "Petite", "Moyenne", "Milieu", "Grande", "Super", "Monstre"];
        return scales[uint256(scale)];
    }

    /// Wen the world is ready
    /// @dev Only the contract owner can invoke this
    function revealClouds() external onlyOwner {
        _wenReveal = true;
    }

    /// Enable minting
    /// @dev Only the contract owner can invoke this
    function setMintingBlock(uint256 wenMint) external onlyOwner {
        _wenMint = wenMint;
    }

    /// Exposes the raw image SVG to the world, for any applications that can take advantage
    function imageSVG(uint256 tokenId) public view returns (string memory) {
        return string(CloudFormation.createSvg(cloudForecast(tokenId), tokenId));
    }

    /// Exposes the image URI to the world, for any applications that can take advantage
    function imageURI(uint256 tokenId) external view returns (string memory) {
        return string(OnChain.svgImageURI(bytes(imageSVG(tokenId))));
    }

    /// Prevents a function from executing until wenReveal is set
    modifier onlyWenRevealed() {
        if (!_wenReveal) revert NotYetRevealed();
        _;
    }

    /// Prevents a function from executing if the tokenId does not exist
    modifier onlyWhenExists(uint256 tokenId) {
        if (!_exists(tokenId)) revert NonexistentCloud();
        _;
    }

    /// @inheritdoc PaymentSplitter
    /// @dev Only the owner is allowed to attempt to release for another account. All other failures are handled by the base class
    function release(address payable account) public override {
        if (_msgSender() != account && _msgSender() != owner()) revert OnlyShareholders();
        super.release(account);
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) public view override onlyWhenExists(tokenId) returns (string memory) {
        return string(OnChain.tokenURI(_metadataForToken(tokenId)));
    }

    /// @dev Returns the total amount of tokens stored by the contract.
    function totalSupply() external view returns (uint256) {
        return _tokenIdsToSeeds.length;
    }

    function _attributesFromForecast(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory) {
        return OnChain.commaSeparated(
            OnChain.traitAttribute("Condition", bytes(conditionName(forecast.condition))),
            OnChain.traitAttribute("Energy", bytes(energyStateName(forecast))),
            OnChain.traitAttribute("Energy Category", bytes(energyCategoryName(forecast.energyCategory))),
            OnChain.traitAttribute("Hue", SVG.colorAttributeRGBValue(forecast.color)),
            OnChain.traitAttribute("Scale", bytes(scaleName(forecast.scale)))
        );
    }

    function _conditionPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](4);
        array[0] = 38; // 38% Luminous
        array[1] = 33; // 33% Overcast
        array[2] = 19; // 19% Stormy
        array[3] = 9; // 9% Golden
        return array; // 1% Magic
    }

    function _energyCategoryPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](5);
        array[0] = 35; // 35% Soothe
        array[1] = 25; // 25% Center
        array[2] = 20; // 20% Grow
        array[3] = 15; // 15% Connect
        array[4] = 4; // 4% Empower
        return array; // 1% Enlighten
    }

    function _forecastForToken(uint256 tokenId) private view returns (ICloudTraits.Forecast memory forecast) {
        forecast.chaos = uint200(_seedForToken(tokenId).seed >> (tokenId % MAX_FORMATION_QUANTITY));

        bytes25 random = bytes25(forecast.chaos);
        uint256 increment = tokenId % 20;

        forecast.formation = ICloudTraits.Formation(uint8(random[increment]) % 5);
        forecast.mirrored = uint8(random[increment+1]) % 2 == 0;
        forecast.scale = ICloudTraits.Scale(uint8(random[increment+2]) % 7);
        forecast.condition = ICloudTraits.Condition(Randomization.randomIndex(uint8(random[increment+3]), _conditionPercentages()));
        forecast.color = CloudFormation.conditionColor(forecast.condition, forecast.chaos, tokenId);
        forecast.energyCategory = ICloudTraits.EnergyCategory(Randomization.randomIndex(uint8(random[increment+4]), _energyCategoryPercentages()));
        forecast.energy = uint8(random[increment+5]) % 6;
    }

    function _formClouds(uint256 quantity) private {
        uint256 seed = Randomization.randomSeed(_seed);
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(_msgSender(), _tokenIdsToSeeds.length, "");
            _tokenIdsToSeeds.push(seed);
        }
        _seed = seed;
    }

    function _metadataForToken(uint256 tokenId) private view returns (bytes memory) {
        string memory token = tokenId.toString();
        if (_wenReveal) {
            ICloudTraits.Forecast memory forecast = _forecastForToken(tokenId);
            return OnChain.dictionary(OnChain.commaSeparated(
                OnChain.keyValueString("name",  abi.encodePacked(scaleName(forecast.scale), " ", conditionName(forecast.condition), " ", energyStateName(forecast), " ", token)),
                OnChain.keyValueArray("attributes", _attributesFromForecast(forecast)),
                OnChain.keyValueString("image", OnChain.svgImageURI(CloudFormation.createSvg(forecast, tokenId)))
            ));
        }
        return OnChain.dictionary(OnChain.commaSeparated(
            OnChain.keyValueString("name", abi.encodePacked("Forming Cloud ", token)),
            OnChain.keyValueString("image", "ipfs://QmWaooUQqr1VCqU2cdWypixg8Jcr5XhhSdi1Vg4u9krvDq")
        ));
    }

    function _seedForToken(uint256 tokenId) private view returns (ICloudTraits.ButterflyEffect memory effect) {
        effect.seed = _tokenIdsToSeeds[tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When cloud quantity is too high or too low
error InvalidQuantity();

/// @dev When the price for cloud formation is not correct
error InvalidPriceSent();

/// @dev When the maximum number of clouds has been met
error NoMoreClouds();

/// @dev When the cloud tokenId does not exist
error NonexistentCloud();

/// @dev When minting block hasn't yet been reached
error NotOpenForMinting();

/// @dev When Reveal is false
error NotYetRevealed();

/// @dev Only owners of other 100% on-chain projects: Anonymice & TwoBitBears are whitelisted
error NotWhitelisted();

/// @dev Only available to shareholders
error OnlyShareholders();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@theappstudio/solidity/contracts/utils/SVG.sol";
import "../interfaces/ICloudTraits.sol";

/// @title CloudFormation
library CloudFormation {

    using Strings for uint256;

    /// @dev Length of the image side -- used as a constant throughout to eliminate parameters and reduce contract size
    uint private constant SIDE = 1000;

    /// Creates the SVG for a CloudCollective Cloud based on its ICloudTraits.Forecast and Token Id
    function createSvg(ICloudTraits.Forecast memory forecast, uint256 tokenId) internal pure returns (bytes memory) {
        return SVG.createElement("svg", abi.encodePacked(" width='1000' height='1000'", SVG.svgAttributes(SIDE, SIDE), " xlink='http://www.w3.org/1999/xlink'"), abi.encodePacked(
            _defElement(forecast),
            SVG.createElement("g", " clip-path='url(#clip)'", abi.encodePacked(
                _rectElement(100, 100, " fill='url(#backgroundGradient)'"),
                _groupForClouds(forecast, tokenId),
                SVG.createElement("g", abi.encodePacked(" style='mix-blend-mode: overlay'"), _rectElement(100, 100, " filter='url(#noise)'"))
            ))
        ));
    }

    /// Returns the start color gradient of a Cloud
    function conditionColor(ICloudTraits.Condition condition, uint200 chaos, uint256 tokenId) internal pure returns (ISVGTypes.Color memory) {
        bytes25 source = bytes25(chaos);
        uint256 increment = tokenId % 23; // We use 3 bytes at a time
        return SVG.randomizeColors(
            _colorStart(condition),
            _colorStop(condition),
            ISVGTypes.Color(uint8(source[increment]), uint8(source[increment+1]), uint8(source[increment+2]), 0xFF)
        );
    }

    function _cloudPuff(uint256 cx, uint256 cy, uint256 r, bytes1 source) private pure returns (bytes memory) {
        uint256 wR = r * (98 + (uint8(source) % 5)) / 100;
        return abi.encodePacked(
            "<circle cx='", cx.toString(), "' cy='", cy.toString(), "' r='", wR.toString(), "' fill='url(#circleGradient)'/>"
        );
    }

    function _cloudPuffs(ICloudTraits.Forecast memory forecast, uint256 tokenId) private pure returns (bytes memory) {
        bytes18 source = bytes18(uint144(forecast.chaos >> (tokenId % 50)));
        if (forecast.formation == ICloudTraits.Formation.A) {
            return abi.encodePacked(
                _cloudPuff(500, 471, 105, source[17]),
                _cloudPuff(405, 516, 80, source[16]),
                _cloudPuff(595, 516, 80, source[15]),
                _cloudPuff(500, 566, 67, source[14])
            );
        } else if (forecast.formation == ICloudTraits.Formation.B) {
            return abi.encodePacked(
                _cloudPuff(296, 500, 42, source[17]),
                _cloudPuff(651, 448, 66, source[16]),
                _cloudPuff(555, 451, 80, source[15]),
                _cloudPuff(475, 505, 57, source[14]),
                _cloudPuff(669, 522, 77, source[13]),
                _cloudPuff(563, 557, 72, source[12])
            );
        } else if (forecast.formation == ICloudTraits.Formation.C) {
            return abi.encodePacked(
                _cloudPuff(445, 435, 60, source[17]),
                _cloudPuff(534, 442, 76, source[16]),
                _cloudPuff(407, 509, 82, source[15]),
                _cloudPuff(598, 514, 77, source[14]),
                _cloudPuff(501, 551, 82, source[13])
            );
        } if (forecast.formation == ICloudTraits.Formation.D) {
            return abi.encodePacked(
                _cloudPuff(688, 509, 46, source[17]),
                _cloudPuff(444, 469, 98, source[16]),
                _cloudPuff(345, 510, 79, source[15]),
                _cloudPuff(535, 510, 63, source[14]),
                _cloudPuff(444, 554, 62, source[13])
            );
        } else /* if (forecast.formation == ICloudTraits.Formation.E) */ {
            return abi.encodePacked(
                _cloudPuff(475, 463, 94, source[17]),
                _cloudPuff(583, 504, 92, source[16]),
                _cloudPuff(389, 504, 63, source[15]),
                _cloudPuff(482, 558, 74, source[14])
            );
        }
    }

    function _colorStart(ICloudTraits.Condition condition) private pure returns (ISVGTypes.Color memory) {
        if (condition == ICloudTraits.Condition.Luminous) {
            return SVG.fromPackedColor(0xC2DDF8);
        } else if (condition == ICloudTraits.Condition.Overcast) {
            return SVG.fromPackedColor(0x666666);
        } else if (condition == ICloudTraits.Condition.Stormy) {
            return SVG.fromPackedColor(0x0E4178);
        } else if (condition == ICloudTraits.Condition.Golden) {
            return SVG.fromPackedColor(0xFFDA7A);
        } // Magic
        return SVG.fromPackedColor(0x8D00B0);
    }

    function _colorStop(ICloudTraits.Condition condition) private pure returns (ISVGTypes.Color memory) {
        if (condition == ICloudTraits.Condition.Luminous) {
            return SVG.fromPackedColor(0x89C0F7);
        } else if (condition == ICloudTraits.Condition.Overcast) {
            return SVG.fromPackedColor(0x333333);
        } else if (condition == ICloudTraits.Condition.Stormy) {
            return SVG.fromPackedColor(0x060F2D);
        } else if (condition == ICloudTraits.Condition.Golden) {
            return SVG.fromPackedColor(0xFFB905);
        } // Magic
        return SVG.fromPackedColor(0x8D00B0);
    }

    function _colorMatrix(ICloudTraits.Condition condition) private pure returns (bytes memory) {
        (bytes12 first3, bytes11 last) = condition == ICloudTraits.Condition.Golden ||
                                         condition == ICloudTraits.Condition.Luminous ?
                                         (bytes12("0.8 0 0 0 0 "), bytes11("0 0 0 1.0 0")) :
                                         (bytes12("0.4 0 0 0 0 "), bytes11("0 0 0 2.0 0"));
        return abi.encodePacked("<feColorMatrix values='", first3, first3, first3, last, "' type='matrix'/>");
    }

    function _defElement(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory) {
        return SVG.createElement("defs", "", abi.encodePacked(
            _gradientElements(forecast),
            SVG.createElement("filter", " id='noise'", abi.encodePacked(
                "<feImage x='0' y='0' href='", OnChain.svgImageURI(_noiseSVG(forecast.condition)), "' width='1350' height='1350'/>"
            )),
            SVG.createElement("clipPath", " id='clip'", _rectElement(100, 100, ""))
        ));
    }

    function _gradientElements(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory) {
        string memory linearGradient = "linearGradient";
        bytes memory stopColorElements = _stopColorElements(forecast);
        return abi.encodePacked(
            SVG.createElement(linearGradient, _linearGradientAttributes("backgroundGradient"), stopColorElements),
            SVG.createElement(linearGradient, _puffGradientAttributes("circleGradient", forecast.mirrored), stopColorElements)
        );
    }

    function _groupForClouds(ICloudTraits.Forecast memory forecast, uint256 tokenId) private pure returns (bytes memory) {
        return SVG.createElement("g", _transformAttributes(forecast), _cloudPuffs(forecast, tokenId));
    }

    function _linearGradientAttributes(string memory name) private pure returns (bytes memory) {
        return abi.encodePacked(" id='", name, "' x1='0' y1='1' x2='1' y2='0'");
    }

    function _noiseSVG(ICloudTraits.Condition condition) private pure returns (bytes memory) {
        return SVG.createElement(
            "svg", abi.encodePacked(" width='", (2*SIDE).toString(), "' height='", (2*SIDE).toString(), "' xmlns='http://www.w3.org/2000/svg'"),
                abi.encodePacked(
                    SVG.createElement("defs", "", SVG.createElement(
                        "filter", " id='noise'", abi.encodePacked("<feTurbulence type='fractalNoise' numOctaves='1' baseFrequency='0.75' stitchTiles='stitch'/>", _colorMatrix(condition))
                    )),
                    _rectElement(100, 100, " filter='url(#noise)'")
                )
        );
    }

    function _puffGradientAttributes(string memory name, bool mirrored) private pure returns (bytes memory) {
        return abi.encodePacked(" y1='0.63' y2='0.115' id='", name, mirrored ? "' x1='0.59' x2='0.153'" : "' x1='0.41' x2='0.847'");
    }

    function _rectElement(uint256 widthPercentage, uint256 heightPercentage, bytes memory attributes) private pure returns (bytes memory) {
        return abi.encodePacked("<rect width='", widthPercentage.toString(), "%' height='", heightPercentage.toString(), "%'", attributes, "/>");
    }

    function _stopColorElement(ISVGTypes.Color memory color, uint256 offset) private pure returns (bytes memory) {
        bytes memory attributes = abi.encodePacked(SVG.colorAttribute(ISVGTypes.ColorAttribute.Stop, SVG.colorAttributeRGBValue(color)), " offset='", offset.toString(), "%'");
        return SVG.createElement("stop", attributes, "");
    }

    function _stopColorElements(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory) {
        return abi.encodePacked(
            _stopColorElement(forecast.color, 0),
            forecast.condition == ICloudTraits.Condition.Magic ? _stopColorElement(SVG.fromPackedColor(0xFF54C3), 50) : bytes(""),
            _stopColorElement(SVG.fromPackedColor(0xFFFFFF), 95)
        );
    }

    function _transformAttributes(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory) {
        (bytes memory scale, bytes memory translation) = _transforms(forecast);
        return abi.encodePacked(" transform='translate(", translation, "),scale(", scale, ")'");
    }

    function _transforms(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory scale, bytes memory translation) {

        bytes3[7] memory scales = [bytes3("0.5"), "0.6", "0.7", "0.8", "0.9", "1.0", "4.3"];
        bytes3 themeScale = bytes3(scales[uint256(forecast.scale)]);
        scale = forecast.mirrored ? abi.encodePacked("-", themeScale, ",", themeScale) : abi.encodePacked(themeScale);

        if (forecast.scale == ICloudTraits.Scale.Monstre) {
            uint16[5] memory xTranslations = [1650, 773, 1645, 1290, 1651];
            uint256 xTranslationValue = xTranslations[uint256(forecast.formation)];
            if (forecast.mirrored) {
                xTranslationValue += SIDE;
            }
            uint16[5] memory yTranslations = [1400, 1650, 1325, 1395, 1395];
            translation = abi.encodePacked(forecast.mirrored ? "" : "-", xTranslationValue.toString(), ",-", uint256(yTranslations[uint256(forecast.formation)]).toString());
        } else { // non-Monstre non-mirrored translation = (1 - scale) * 500
            uint8[6] memory translations = [250, 200, 150, 100, 50, 0];
            uint256 translationValue = translations[uint256(forecast.scale)];
            translation = abi.encodePacked(translationValue.toString());
            if (forecast.mirrored) {
                translationValue = SIDE - translationValue;
            }
            translation = abi.encodePacked(translationValue.toString(), ",", translation);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Interface describing the required method for a whitelistable project
interface IWhitelistable {

    /// @dev Returns the number of tokens in the owner's account.
    function balanceOf(address owner) external view returns (uint256 balance);
}

/// @title Contract for Whitelisting 100% on-chain projects
/// @dev Since this contract is public, other projects may wish to rely on this list
contract Whitelisted is Ownable {

    /// Holds the list of IWhitelistable (e.g. ERC-721) projects in which ownership affords whitelisting
    IWhitelistable[] private _approvedProjects;

    /// Deploys a new Whitelisted contract with approved projects
    /// @param projects The list of contracts to add to the approved list
    constructor(address[] memory projects) {
        for (uint256 index = 0; index < projects.length; index++) {
            _approvedProjects.push(IWhitelistable(projects[index]));
        }
    }

    /// Adds additional projects to the approved list
    /// @dev Providing valid contract address that implement `balanceOf()` is the responsibility of the caller
    /// @param projects The list of contracts to add to the approved list
    function addApprovedProjects(address[] calldata projects) external onlyOwner {
        for (uint256 index = 0; index < projects.length; index++) {
            _approvedProjects.push(IWhitelistable(projects[index]));
        }
    }

    /// Returns the approved projects whitelisted by this contract
    function getApprovedProjects() external view returns (IWhitelistable[] memory) {
        return _approvedProjects;
    }

    /// Removes an approved project whitelisted by this contract
    /// @param project The address to remove from the list
    function removeApprovedProject(address project) external onlyOwner {
        uint256 length = _approvedProjects.length;
        for (uint256 index = 0; index < length; index++) {
            if (address(_approvedProjects[index]) == project) {
                if (index < length-1) {
                    _approvedProjects[index] = _approvedProjects[length-1];
                }
                _approvedProjects.pop();
                return;
            }
        }
    }

    /// Returns whether the owning address is eligible for whitelisting due to ownership in one of the approved projects
    /// @param owner The owning address to check
    /// @return True if the address at owner owns a token in one of the approved projects
    function isWhitelisted(address owner) external view returns (bool) {
        uint256 projects = _approvedProjects.length;
        for (uint256 index = 0; index < projects; index++) {
            IWhitelistable project = _approvedProjects[index];
            if (project.balanceOf(owner) > 0) {
                return true;
            }
        }
        return false;
    }
}