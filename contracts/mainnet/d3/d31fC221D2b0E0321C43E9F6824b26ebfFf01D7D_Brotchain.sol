// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

// SPDX-License-Identifier: MIT

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 Arran Schlosberg / Twitter @divergence_art
// All Rights Reserved
pragma solidity >=0.8.0 <0.9.0;

import "base64-sol/base64.sol";

/**
 * @dev 8-bit BMP encoding with arbitrary colour palettes.
 */
contract BMP {
    using Base64 for string;

    /**
     * @dev Returns an 8-bit grayscale palette for bitmap images.
     */
    function grayscale() public pure returns (bytes memory) {
        bytes memory palette = new bytes(768);
        // TODO: investigate a way around using ++ += or + on a bytes1 without
        // having to use a placeholder int8 for incrementing!
        uint8 j;
        bytes1 b;
        for (uint16 i = 0; i < 768; i += 3) {
            b = bytes1(j);
            palette[i  ] = b;
            palette[i+1] = b;
            palette[i+2] = b;
            // The last increment would revert if checked.
            unchecked { j++; }
        }
        return palette;
    }

    /**
     * @dev Returns an 8-bit BMP encoding of the pixels.
     *
     * Spec: https://www.digicamsoft.com/bmp/bmp.html
     *
     * Layout description with offsets:
     * http://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/2003_w/misc/bmp_file_format/bmp_file_format.htm
     *
     * N.B. Everything is little-endian, hence the assembly for masking and
     * shifting.
     */
    function bmp(bytes memory pixels, uint32 width, uint32 height, bytes memory palette) public pure returns (bytes memory) {
        require(width * height == pixels.length, "Invalid dimensions");
        require(palette.length == 768, "256 colours required");

        // 14 bytes for BITMAPFILEHEADER + 40 for BITMAPINFOHEADER + 1024 for palette
        bytes memory buf = new bytes(1078);

        // BITMAPFILEHEADER
        buf[0] = 0x42; buf[1] = 0x4d; // bfType = BM
        
        uint32 size = 1078 + uint32(pixels.length);
        // bfSize; bytes in the entire buffer
        uint32 b;
        for (uint i = 2; i < 6; i++) {
            assembly {
                b := and(size, 0xff)
                size := shr(8, size)
            }
            buf[i] = bytes1(uint8(b));
        }

        // Next 4 bytes are bfReserved1 & 2; both = 0 = initial value

        // bfOffBits; bytes from beginning of file to pixels = 14 + 40 + 1024
        // (see size above)
        buf[0x0a] = 0x36;
        buf[0x0b] = 0x04;

        // BITMAPINFOHEADER
        // biSize; bytes in this struct = 40
        buf[0x0e] = 0x28;

        // biWidth / biHeight
        for (uint i = 0x12; i < 0x16; i++) {
            assembly {
                b := and(width, 0xff)
                width := shr(8, width)
            }
            buf[i] = bytes1(uint8(b));
        }
        for (uint i = 0x16; i < 0x1a; i++) {
            assembly {
                b := and(height, 0xff)
                height := shr(8, height)
            }
            buf[i] = bytes1(uint8(b));
        }

        // biPlanes
        buf[0x1a] = 0x01;
        // biBitCount
        buf[0x1c] = 0x08;

        // I've decided to use raw pixels instead of run-length encoding for
        // compression as these aren't being stored. It's therefore simpler to
        // avoid the extra computation. Therefore biSize can be 0. Similarly
        // there's no point checking exactly which colours are used, so
        // biClrUsed and biClrImportant can be 0 to indicate all colours. This
        // is therefore the end of BITMAPINFOHEADER. Simples.

        uint j = 54;
        for (uint i = 0; i < 768; i += 3) {
            // RGBQUAD is in reverse order and the 4th byte is unused.
            buf[j  ] = palette[i+2];
            buf[j+1] = palette[i+1];
            buf[j+2] = palette[i  ];
            j += 4;
        }

        return abi.encodePacked(buf, pixels);
    }

    /**
     * @dev Returns the buffer, presumably from bmp(), as a base64 data URI.
     */
    function bmpDataURI(bytes memory bmpBuf) public pure returns (string memory) {
        return string(abi.encodePacked(
            'data:image/bmp;base64,',
            Base64.encode(bmpBuf)
        ));
    }

    /**
     * @dev Scale pixels by repetition along both axes.
     */
    function scalePixels(bytes memory pixels, uint32 width, uint32 height, uint32 scale) public pure returns (bytes memory) {
        require(width * height == pixels.length, "Invalid dimensions");
        bytes memory scaled = new bytes(pixels.length * scale * scale);

        // Indices in each of the original and scaled buffers, respectively. The
        // scaled-buffer index is always incremented. The original index is
        // incremented only after scaling x-wise by scale times, then reversed
        // at the end of the width to allow for y-wise scaling.
        uint32 origIdx;
        uint32 scaleIdx;
        for (uint32 y = 0; y < height; y++) {
            for (uint32 yScale = 0; yScale < scale; yScale++) {
                for (uint32 x = 0; x < width; x++) {
                    for (uint32 xScale = 0; xScale < scale; xScale++) {
                        scaled[scaleIdx] = pixels[origIdx];
                        scaleIdx++;
                    }
                    origIdx++;
                }
                // Rewind to copy the row again.
                origIdx -= width;
            }
            // Don't just copy the first row.
            origIdx += width;
        }

        return scaled;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://gist.github.com/dievardump/483eb43bc6ed30b14f01e01842e3339b/

/// @title OpenSea contract helper that defines a few things
/// @author Simon Fremaux (@dievardump)
/// @dev This is a contract used to add OpenSea's support for gas-less trading
///      by checking if operator is owner's proxy
contract BaseOpenSea {
    string private _contractURI;
    ProxyRegistry private _proxyRegistry;

    /// @notice Returns the contract URI function. Used on OpenSea to get details
    ///         about a contract (owner, royalties etc...)
    ///         See documentation: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Helper for OpenSea gas-less trading
    /// @dev Allows to check if `operator` is owner's OpenSea proxy
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return
            // we have a proxy registry address
            address(proxyRegistry) != address(0) &&
            // current operator is owner's proxy address
            address(proxyRegistry.proxies(owner)) == operator;
    }

    /// @dev Internal function to set the _contractURI
    /// @param contractURI_ the new contract uri
    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 Arran Schlosberg / Twitter @divergence_art
// All Rights Reserved
pragma solidity >=0.8.0 <0.9.0;

/*

  ____            _       _           _       
 |  _ \          | |     | |         (_)      
 | |_) |_ __ ___ | |_ ___| |__   __ _ _ _ __  
 |  _ <| '__/ _ \| __/ __| '_ \ / _` | | '_ \ 
 | |_) | | | (_) | || (__| | | | (_| | | | | |
 |____/|_|  \___/ \__\___|_| |_|\__,_|_|_| |_|
                                              
                                              
"In-chain" generative art, Brots are BMP images generated and rendered entirely
by this contract. No externalities, no rendering dependencies—just 100%
Solidity.

                                .                               
                         ...............                        
                     .......................                    
                   ...........................                  
                 ...............................                
               ...................................              
              .....................................             
             .......................................            
           ...........................................          
          .............................................         
         ...............................................        
        .................................................       
        .................................................       
       ...................................................      
      ...................'''```'''.........................     
     ..................''''``^```'''........................    
     .................''''````",$''''.......................    
    ................''''''````"^``''''.......................   
    ...............''''''```"^$"^```'''......................   
   ...............'''''`````,$$$!````''.......................  
   ..............'''''``````:$$$l`````''......................  
  .............'''''``^^^`^^"$$$"^^```^''...................... 
  ............''''````^:,^Y$$$$$$/$^,^^`'......................
  ...........''```````^I$#$$$$$$$$$I$|"``'..................... 
  .........''````````^^,$$$$$$$$$$$$$$^``'..................... 
 ........''``````````"$$$$$$$$$$$$$$$_^``'......................
 .....'''```"````````:$$$$$$$$$$$$$$$$,!`''.....................
 ...''''````^,^^,"^^^}$$$$$$$$$$$$$$$$$^`''.....................
 .'''''`````^:$$$l:^"$$$$$$$$$$$$$$$$$$"`''.....................
 '''''``````")$$$$$<,$$$$$$$$$$$$$$$$$$``''.....................
 ''''`````^^,$$$$$$$;$$$$$$$$$$$$$$$$$,``''.....................
 ````````^,$}$$$$$$$<$$$$$$$$$$$$$$$$$```''.....................
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$^```''.....................
 ````````^,$}$$$$$$$<$$$$$$$$$$$$$$$$$```''.....................
 ''''`````^^,$$$$$$$;$$$$$$$$$$$$$$$$$,``''.....................
 '''''``````")$$$$$<,$$$$$$$$$$$$$$$$$$``''.....................
 .'''''`````^:$$$l:^"$$$$$$$$$$$$$$$$$$"`''.....................
 ...''''````^,^^,"^^^}$$$$$$$$$$$$$$$$$^`''.....................
 .....'''```"````````:$$$$$$$$$$$$$$$$,!`''.....................
 ........''``````````"$$$$$$$$$$$$$$$_^``'......................
  .........''````````^^,$$$$$$$$$$$$$$^``'..................... 
  ...........''```````^I$#$$$$$$$$$I$|"``'.....................
  ............''''````^:,^Y$$$$$$/$^,^^`'...................... 
  .............'''''``^^^`^^"$$$"^^```^''...................... 
   ..............'''''``````:$$$l`````''......................  
   ...............'''''`````,$$$!````''.......................  
    ...............''''''```"^$"^```'''......................   
    ................''''''````"^``''''.......................   
     .................''''````",$''''.......................    
     ..................''''``^```'''........................    
      ...................'''```'''.........................     
       ...................................................      
        .................................................       
        .................................................       
         ...............................................        
          .............................................         
           ...........................................          
             .......................................            
              .....................................             
               ...................................              
                 ...............................                
                   ...........................                  
                     .......................                    
                         ...............                        
*/

import "./BaseOpenSea.sol";
import "./BMP.sol";
import "./Mandelbrot.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/PullPayment.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

contract Brotchain is BaseOpenSea, ERC721Enumerable, ERC721Pausable, Ownable, PullPayment {
    /**
     * @dev A BMP pixel encoder, supporting arbitrary colour palettes.
     */
    BMP public immutable _bmp;

    /**
     * @dev A Mandelbrot-and-friends fractal generator.
     */
    Mandelbrot public immutable _brots;

    /**
     * @dev Maximum number of editions per series.
     */
    uint256 public constant MAX_PER_SERIES = 64;

    /**
     * @dev Mint price = pi/10.
     */
    uint256 public constant MINT_PRICE = (314159 ether) / 1000000;

    constructor(string memory name, string memory symbol, address brots, address openSeaProxyRegistry) ERC721(name, symbol) {
        _bmp = new BMP();
        _brots = Mandelbrot(brots);

        if (openSeaProxyRegistry != address(0)) {
            _setOpenSeaRegistry(openSeaProxyRegistry);
        }
    }

    /**
     * @dev Base config for pricing + all tokens in a series.
     */
    struct Series {
        uint256[] patches;
        uint256 numMinted;
        uint32 width;
        uint32 height;
        bytes defaultPalette;
        bool locked;
        string name;
        string description;
    }

    /**
     * @dev All existing series configs.
     */
    Series[] public seriesConfigs;

    /**
     * @dev Require that the series exists.
     */
    modifier seriesMustExist(uint256 seriesId) {
        require(seriesId < seriesConfigs.length, "Series doesn't exist");
        _;
    }

    /**
     * @dev Creates a new series of brots, based on the precomputed patches.
     *
     * The seriesId MUST be equal to seriesConfigs.length. This is a safety
     * measure for automated deployment of multiple series in case an earlier
     * transaction fails as series would otherwise be created out of order. This
     * effectively makes newSeries() idempotent.
     */
    function newSeries(uint256 seriesId, string memory name, string memory description, uint256[] memory patches, uint32 width, uint32 height) external onlyOwner {
        require(seriesId == seriesConfigs.length, "Invalid new series ID");
        
        seriesConfigs.push(Series({
            name: name,
            description: description,
            patches: patches,
            width: width,
            height: height,
            numMinted: 0,
            locked: false,
            defaultPalette: new bytes(0)
        }));
        emit SeriesPixelsChanged(seriesId);
    }

    /**
     * @dev Require that the series isn't locked to updates.
     */
    modifier seriesNotLocked(uint256 seriesId) {
        require(!seriesConfigs[seriesId].locked, "Series locked");
        _;
    }

    /**
     * @dev Permanently lock the series to changes in pixels.
     */
    function lockSeries(uint256 seriesId) external seriesMustExist(seriesId) onlyOwner {
        Series memory series = seriesConfigs[seriesId];
        uint256 length;
        for (uint i = 0; i < series.patches.length; i++) {
            length += _brots.cachedPatch(series.patches[i]).pixels.length;
        }
        require(series.width * series.height == length, "Invalid dimensions");
        
        seriesConfigs[seriesId].locked = true;
    }

    /**
     * @dev Emitted when a series' patches or dimensions change.
     */
    event SeriesPixelsChanged(uint256 indexed seriesId);

    /**
     * @dev Update the patches that govern series pixels.
     */
    function setSeriesPatches(uint256 seriesId, uint256[] memory patches) external seriesMustExist(seriesId) seriesNotLocked(seriesId) onlyOwner {
        seriesConfigs[seriesId].patches = patches;
        emit SeriesPixelsChanged(seriesId);
    }

    /**
     * @dev Update the dimensions of the series.
     */
    function setSeriesDimensions(uint256 seriesId, uint32 width, uint32 height) external seriesMustExist(seriesId) seriesNotLocked(seriesId) onlyOwner {
        seriesConfigs[seriesId].width = width;
        seriesConfigs[seriesId].height = height;
        emit SeriesPixelsChanged(seriesId);
    }

    /**
     * @dev Update the default palette for a series when the token doesn't have one.
     */
    function setSeriesDefaultPalette(uint256 seriesId, bytes memory palette) external seriesMustExist(seriesId) seriesNotLocked(seriesId) onlyOwner {
        require(palette.length == 768, "256 colours required");
        seriesConfigs[seriesId].defaultPalette = palette;
    }

    /**
     * @dev Update the series name.
     */
    function setSeriesName(uint256 seriesId, string memory name) external seriesMustExist(seriesId) onlyOwner {
        seriesConfigs[seriesId].name = name;
    }

    /**
     * @dev Update the series description.
     */
    function setSeriesDescription(uint256 seriesId, string memory description) external seriesMustExist(seriesId) onlyOwner {
        seriesConfigs[seriesId].description = description;
    }

    /**
     * @dev Token configuration such as series (pixels).
     */
    struct TokenConfig {
        uint256 paletteChanges;
        address paletteBy;
        address paletteApproval;
        // paletteReset is actually a boolean, but sized to align with a 256-bit
        // boundary for better storage. See resetPalette();
        uint192 paletteReset;
        bytes palette;
    }

    /**
     * @dev All existing token configs.
     */
    mapping(uint256 => TokenConfig) public tokenConfigs;
    
    /**
     * @dev Whether to limit minting only to those in _earlyAccess mapping.
     */
    bool public onlyEarlyAccess = true;

    /**
     * @dev Addresses with early minting access.
     */
    mapping(address => uint256) private _earlyAccess;

    /**
     * @dev Emitted when setOnlyEarlyAccess(to) is called.
     */
    event OnlyEarlyAccess();

    /**
     * @dev Set the onlyEarlyAccess flag.
     */
    function setOnlyEarlyAccess(bool to) external onlyOwner {
        onlyEarlyAccess = to;
        emit OnlyEarlyAccess();
    }

    /**
     * @dev Call parameter for early access because mapping()s are disallowed.
     */
    struct EarlyAccess {
        address addr;
        uint256 totalAllowed;
    }

    /**
     * @dev Set early-access granting or revocation for the addresses.
     *
     * The supply is not the amount left, but the total in the early-access
     * phase.
     */
    function setEarlyAccessGrants(EarlyAccess[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _earlyAccess[addresses[i].addr] = addresses[i].totalAllowed;
        }
    }

    /**
     * @dev Returns the total early-access allocation for the address.
     */
    function earlyAccessFor(address addr) public view returns (uint256) {
        return _earlyAccess[addr];
    }

    /**
     * @dev Max number that the contract owner can mint in a specific series.
     */
    uint256 public constant OWNER_ALLOCATION = 2;

    /**
     * @dev Allow minting of the genesis pieces.
     */
    function safeMintInSeries(uint256 seriesId) external seriesMustExist(seriesId) onlyOwner {
        require(seriesConfigs[seriesId].numMinted < OWNER_ALLOCATION, "Don't be greedy");
        _safeMintInSeries(seriesId);
    }

    /**
     * @dev Mint one edition, from a randomly selected series.
     *
     * # NB see the bug described in _safeMintInSeries().
     */
    function safeMint() external payable {
        require(msg.value >= MINT_PRICE, "Insufficient payment");
        _asyncTransfer(owner(), msg.value);

        uint256 numSeries = seriesConfigs.length;
        // We need some sort of randomness to choose which series is issued
        // next. sha3 is, by nature of being a cryptographic hash, a good PRNG.
        // Although this can technically be manipulated by someone in control of
        // block.timestamp, they're in a race against other blocks and also the
        // last minted (which is also random). If you can control this and care
        // enough to do so, then you deserve to choose which series you get!
        uint256 rand = uint256(keccak256(abi.encodePacked(
            _msgSender(),
            block.timestamp,
            lastTokenMinted
        ))) % numSeries; // uniform if numSeries is a power of 2 (it is)
        
        // Try each, starting from a random index, until a series with
        // capacity is found.
        for (uint256 i = 0; i < numSeries; i++) {
            uint256 seriesId = (rand + i) % numSeries;
            if (seriesConfigs[seriesId].numMinted < MAX_PER_SERIES) {
                _safeMintInSeries(seriesId);
                return;
            }
        }
        revert("All series sold out");
    }

    /**
     * @dev Last tokenId minted.
     *
     * This doesn't increment because the series could be different to the one
     * before. It's useful for randomly choosing the next token and for testing
     * too. Even at a gas price of 100, updating this only costs 0.0005 ETH.
     */
    uint256 public lastTokenMinted;

    /**
     * @dev Value by which seriesId is multiplied for the prefix of a tokenId.
     *
     * Series 0 will have tokens 0, 1, 2…; series 1 will have tokens 1000, 1001,
     * etc.
     */
    uint256 private constant _tokenIdSeriesMultiplier = 1e4;

    /**
     * @dev Returns the seriesId of a token. The token may not exist.
     */
    function tokenSeries(uint256 tokenId) public pure returns (uint256) {
        return tokenId / _tokenIdSeriesMultiplier;
    }

    /**
     * @dev Returns a token's edition within its series. The token may not exist.
     */
    function tokenEditionNum(uint256 tokenId) public pure returns (uint256) {
        return tokenId % _tokenIdSeriesMultiplier;
    }

    /**
     * @dev Mints the next token in the series.
     */
    function _safeMintInSeries(uint256 seriesId) internal seriesMustExist(seriesId) {
        /**
         * ################################
         * There is a bug in this code that we only discovered after deployment.
         * A minter can move their piece to a different wallet, reducing their
         * balance, and then mint again. See GermanBakery.sol for the fix.
         * ################################
         */
        if (_msgSender() != owner()) {
            if (onlyEarlyAccess) {
                require(balanceOf(_msgSender()) < _earlyAccess[_msgSender()], "Early access exhausted for wallet");
            } else {
                require(balanceOf(_msgSender()) < seriesConfigs.length, "Wallet cap reached");
            }
        }

        Series memory series = seriesConfigs[seriesId];
        uint256 tokenId = seriesId * _tokenIdSeriesMultiplier + series.numMinted;
        lastTokenMinted = tokenId;

        tokenConfigs[tokenId] = TokenConfig({
            paletteChanges: 0,
            paletteBy: address(0),
            paletteApproval: address(0),
            paletteReset: 0,
            palette: new bytes(0)
        });
        seriesConfigs[seriesId].numMinted++;

        _safeMint(_msgSender(), tokenId);
        emit TokenBMPChanged(tokenId);
    }

    /**
     * @dev Emitted when the address is approved to change a token's palette.
     */
    event PaletteApproval(uint256 indexed tokenId, address approved);

    /**
     * @dev Approve the address to change the token's palette.
     *
     * Set to 0x00 address to revoke. Token owner and ERC721 approved already
     * have palette approval. This is to allow someone else to modify a palette
     * without the risk of them transferring the token.
     *
     * Revoked upon token transfer.
     */
    function approveForPalette(uint256 tokenId, address approved) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only owner or approver");
        address owner = ownerOf(tokenId);
        require(approved != owner, "Approving token owner");
        
       tokenConfigs[tokenId].paletteApproval = approved;
        emit PaletteApproval(tokenId, approved);
    }

    /**
     * @dev Emitted to signal changing of a token's BMP.
     */
    event TokenBMPChanged(uint256 indexed tokenId);

    /**
     * @dev Require that the message sender is approved for palette changes.
     */
    modifier approvedForPalette(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) ||
            tokenConfigs[tokenId].paletteApproval == _msgSender(),
            "Not approved for palette"
        );
        _;
    }

    /**
     * @dev Clear a token's palette, using the series default instead.
     *
     * Does not reset the paletteChanges count, but increments it.
     *
     * Emits TokenBMPChanged(tokenId);
     */
    function resetPalette(uint256 tokenId) approvedForPalette(tokenId) external {
        require(tokenConfigs[tokenId].paletteReset == 0, "Already reset");
        
        tokenConfigs[tokenId].paletteChanges++;
        tokenConfigs[tokenId].paletteBy = address(0);
        // Initial palette setting costs about 0.01 ETH at 30 gas but changes
        // are a little over 25% of that. Using a boolean for reset adds
        // negligible cost to the reset, in exchange for  greater savings on the
        // next setPalette() call.
        tokenConfigs[tokenId].paletteReset = 1;
        
        emit TokenBMPChanged(tokenId);
    }

    /**
     * @dev Set a token's palette if an owner or has approval.
     *
     * Emits TokenBMPChanged(tokenId).
     */
    function setPalette(uint256 tokenId, bytes memory palette) approvedForPalette(tokenId) external {
        require(palette.length == 768, "256 colours required");
        
        tokenConfigs[tokenId].palette = palette;
        tokenConfigs[tokenId].paletteChanges++;
        tokenConfigs[tokenId].paletteBy = _msgSender();
        tokenConfigs[tokenId].paletteReset = 0;
        
        emit TokenBMPChanged(tokenId);
    }

    /**
     * @dev Concatenates a series' patches into a single array.
     */
    function seriesPixels(uint256 seriesId) public view seriesMustExist(seriesId) returns (bytes memory) {
        return _brots.concatenatePatches(seriesConfigs[seriesId].patches);
    }

    /**
     * @dev Token equivalent of seriesPixels().
     */
    function pixelsOf(uint256 tokenId) public view returns (bytes memory) {
        require(_exists(tokenId), "Token doesn't exist");
        return seriesPixels(tokenSeries(tokenId));
    }

    /**
     * @dev Returns the effective token palette, considering resets.
     *
     * Boolean flag indicates whether it's the original palette; i.e. nothing is
     * set or the palette has been explicitly reset().
     */
    function _tokenPalette(uint256 tokenId) private view returns (bytes memory, bool) {
        TokenConfig memory token = tokenConfigs[tokenId];
        bytes memory palette = token.palette;
        bool original = token.paletteReset == 1 || palette.length == 0;
        
        if (original) {
            palette = seriesConfigs[tokenSeries(tokenId)].defaultPalette;
            if (palette.length == 0) {
                palette = _bmp.grayscale();
            }
        }
        
        return (palette, original);
    }

    /**
     * @dev Returns the BMP-encoded token image, scaling pixels in both dimensions.
     *
     * Scale of 0 is treated as 1.
     */
    function bmpOf(uint256 tokenId, uint32 scale) public view returns (bytes memory) {
        require(_exists(tokenId), "Token doesn't exist");
        Series memory series = seriesConfigs[tokenSeries(tokenId)];
        (bytes memory palette, ) = _tokenPalette(tokenId);
        
        bytes memory pixels = pixelsOf(tokenId);
        if (scale > 1) {
            return _bmp.bmp(
                _bmp.scalePixels(pixels, series.width, series.height, scale),
                series.width * scale,
                series.height * scale,
                palette
            );
        }
        return _bmp.bmp(pixels, series.width, series.height, palette);
    }

    /**
     * @dev Equivalent to bmpOf() but encoded as a data URI to view in a browser.
     */
    function bmpDataURIOf(uint256 tokenId, uint32 scale) public view returns (string memory) {
        return _bmp.bmpDataURI(bmpOf(tokenId, scale));
    }

    /**
     * @dev Renders the token as an ASCII brot.
     *
     * This is an homage to Robert W Brooks and Peter Matelski who were the
     * first to render the Mandelbrot, in this form.
     */
    function brooksMatelskiOf(uint256 tokenId, string memory characters) external view returns (string memory) {
        bytes memory charset = abi.encodePacked(characters);
        require(charset.length == 256, "256 characters");

        Series memory series = seriesConfigs[tokenSeries(tokenId)];
        // Include newlines except for the end.
        bytes memory ascii = new bytes((series.width+1)*series.height - 1);
        
        bytes memory pixels = pixelsOf(tokenId);

        uint col;
        uint a; // ascii index
        for (uint p = 0; p < pixels.length; p++) {
            ascii[a] = charset[uint8(pixels[p])];
            a++;
            col++;
            
            if (col == series.width && a < ascii.length) {
                ascii[a] = 0x0a; // Not compatible with Windows and typewriters.
                a++;
                col = 0;
            }
        }

        return string(ascii);
    }

    /**
     * @dev Base URL for external_url metadata field.
     */
    string private _baseExternalUrl = "https://brotchain.art/brot/";

    /**
     * @dev Set the base URL for external_url metadata field.
     */
    function setBaseExternalUrl(string memory url) public onlyOwner {
        _baseExternalUrl = url;
    }

    /**
     * @dev Returns data URI of token metadata.
     *
     * The BMP-encoded image is included in its own base64-encoded data URI.
     */
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        TokenConfig memory token = tokenConfigs[tokenId];
        Series memory series = seriesConfigs[tokenSeries(tokenId)];
        uint256 editionNum = tokenEditionNum(tokenId);

        bytes memory data = abi.encodePacked(
            'data:application/json,{',
                '"name":"', series.name, ' #', Strings.toString(editionNum) ,'",',
                '"description":"', series.description, '",'
                '"external_url":"', _baseExternalUrl, Strings.toString(tokenId),'",'
        );

        // Combining this packing with the one above would result in the stack
        // being too deep and a failure to compile.
        data = abi.encodePacked(
            data,
            '"attributes":['
                '{"value":"', series.name, '"},'
                '{',
                    '"trait_type":"Palette Changes",',
                    '"value":', Strings.toString(token.paletteChanges),
                '}'
        );

        if (token.paletteBy != address(0)) {
            data = abi.encodePacked(
                data,
                ',{',
                    '"trait_type":"Palette By",',
                    '"value":"', Strings.toHexString(uint256(uint160(token.paletteBy)), 20),'"',
                '}'
            );
        }

        (, bool original) = _tokenPalette(tokenId);
        if (original) {
            data = abi.encodePacked(
                data,
                ',{"value":"Original Palette"}'
            );
        }      
        if (editionNum == 0) {
            data = abi.encodePacked(
                data,
                ',{"value":"Genesis"}'
            );
        }

        return string(abi.encodePacked(
            data,
                '],',
                '"image":"', bmpDataURIOf(tokenId, 1), '"',
            '}'
        ));
    }

    /**
     * @dev Pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator) || isOwnersOpenSeaProxy(owner, operator);
    }

    /**
     * @dev OpenSea collection config.
     *
     * https://docs.opensea.io/docs/contract-level-metadata
     */
    function setContractURI(string memory contractURI) external onlyOwner {
        _setContractURI(contractURI);
    }

    /**
     * @dev Revoke palette approval upon token transfer.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        tokenConfigs[tokenId].paletteApproval = address(0);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 Arran Schlosberg / Twitter @divergence_art
// All Rights Reserved
pragma solidity >=0.8.0 <0.9.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * @dev Pure-Solidity rendering of Mandelbrot and similar fractals.
 */
contract Mandelbrot is Ownable {
    /**
     * @dev Defines the fixed-point precision for non-integer numbers.
     *
     * The number 1 is represented as 1<<PRECISION, 0.5 as 1<<(PRECISION-1).
     * These values can be thought of as the binary equivalent of working in
     * cents vs dollars (100c = $1) which is the same 2 _decimal_ precision.
     *
     * Addition functions as normal. Multiplication results in twice as many
     * fractional bits so requires devision by the "dollar-equivalent":
     * 
     *   $1 × $2 = $2
     *   100c × 200c = 20,000 (extra precision) / 100 = $2
     *
     * The binary equivalent of this division is a right arithmetic shift (sar)
     * to maintain the sign. The specific value was chosen to avoid overflow
     * based on Mandelbrot escape conditions. Although it's possible to first
     * right-shift both the multiplier and multiplicand by PRECISION/2 and then
     * multiply in order to allow higher values, this changes gas from 8 to 11
     * as mul=5 and sar=3.
     */
    uint256 private constant PRECISION = 125;

    /**
     * @dev Pre-computed value for PRECISION+2.
     */
    uint256 private constant PRECISION_PLUS_2 = 127;

    /**
     * @dev The number 1 in @PRECISION fixed-point representation.
     *
     * This is useful for external callers, which should use ONE as bignum menas
     * of computing fractions.
     */
    int256 public constant ONE = 2**125;

    /**
     * @dev The number 2 in @PRECISION fixed-point representation.
     */
    int256 private constant TWO = 2**126;

    /**
     * @dev By now I think you can see the pattern.
     */
    int256 private constant FOUR = 2**127;

    /**
     * @dev You're gonna have to trust me on this one!
     */
    int256 private constant POINT_FOUR = 0xccccccccccccccccccccccccccccccc;

    /**
     * @dev Some bounds checks for inclusion in the cardioid, main bulb, etc.
     */
    int256 private constant QUARTER = 2**123;
    int256 private constant EIGHTH = 2**122;
    int256 private constant SIXTEENTH = 2**121;
    int256 private constant NEG_THREE_QUARTERS = 2**123 - 2**125;
    int256 private constant NEG_ONE_PT_TWO_FIVE = -(2**123 + 2**125);

    /**
     * @dev The number -2 in @PRECISION fixed-point representation.
     *
     * This is the lower bound of the parts of real and imaginary axes on which
     * fractals are defined.
     */
    int256 public constant NEG_TWO = -TWO;

    /**
     * @dev Supported Mandelbrot-derived fractals.
     *
     * The INVALID sentinel value MUST be last as it allows for rapid checking
     * of valid values with <.
     */
    enum Fractal {
        Mandelbrot,
        Mandelbar,
        Multi3,
        BurningShip,

        INVALID
    }

    /**
     * @dev Parameters for computing a patch in a fractal.
     */
    struct Patch {
        // Fixed-point values, not actually integers. See ONE.
        int256 minReal;
        int256 minImaginary;
        // Dimensions in pixels. Pixel width is controlled by zoomLog2.
        int256 width;
        int256 height;
        // For a full fractal, set equal width and height, and
        // zoomLog2 = log_2(width).
        int16 zoomLog2;
        uint8 maxIterations;
        Fractal fractal;
    }

    /**
     * @dev Computes escape times (pixel values) for a fractal rendering.
     *
     * These are the components that make up the final image when concatenated,
     * but are computed piecemeal to save compute time of any single call.
     */
    function patchPixels(Patch memory patch) public pure returns (bytes memory) {
        require(patch.width > 0, "Non-positive width");
        require(patch.height > 0, "Non-positive height");
        require(patch.zoomLog2 > 0, "Non-positive zoom");
        require(patch.fractal < Fractal.INVALID, "Unsupported fractal");

        // Mandelbrots are defined on [-2,2] (i.e. width 4 = 2^2), hence the use
        // of PRECISION+2. Every increment of zoomLog2 increases the
        // mangification of both axes 2× by halving the pixelWidth.
        int256 pixelWidth;
        {
            int16 zoomLog2 = patch.zoomLog2;
            assembly { pixelWidth := shl(sub(PRECISION_PLUS_2, zoomLog2), 1) }
        }
        int256 maxRe = patch.minReal + pixelWidth*patch.width;
        int256 maxIm = patch.minImaginary + pixelWidth*patch.height;

        // While this duplicates a lot of code, it saves having the if statement
        // inside the loops, which would be much less efficient.
        if (patch.fractal == Fractal.Mandelbrot) {
            return _mandelbrot(patch, pixelWidth, maxRe, maxIm);
        } else if (patch.fractal == Fractal.Mandelbar) {
            return _mandelbar(patch, pixelWidth, maxRe, maxIm);
        } else if (patch.fractal == Fractal.Multi3) {
            return _multi3(patch, pixelWidth, maxRe, maxIm);
        } else if (patch.fractal == Fractal.BurningShip) {
            return _burningShip(patch, pixelWidth, maxRe, maxIm);
        }
        // The check for patch.fractal < Fractal.INVALID makes this impossible,
        // but we still need a return value.
        return new bytes(0);
    }

    /**
     * @dev Computes the standard Mandelbrot.
     */
    function _mandelbrot(Patch memory patch, int256 pixelWidth, int256 maxRe, int256 maxIm) internal pure returns (bytes memory) {
        bytes memory pixels = new bytes(uint256(patch.width * patch.height));
        
        int256 zRe;
        int256 zIm;
        int256 reSq;
        int256 imSq;

        uint8 maxIters  = patch.maxIterations;
        uint256 pixelIdx = 0;
        for (int256 cIm = patch.minImaginary; cIm < maxIm; cIm += pixelWidth) {
            for (int256 cRe = patch.minReal; cRe < maxRe; cRe += pixelWidth) {
                // Points in the Mandelbrot are expensive to compute by force
                // because they require maxIters iterations. Ruling out the two
                // largest areas adds a little more computation to other
                // regions, but is a net saving.
                //
                // From https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set#Border_tracing_/_edge_checking
                //
                // NOTE: to keep the stack small, all variable names are
                // overloaded with different meanings. It's ugly, but so be it.

                // TODO: the checks are only performed based on real ranges;
                // test if there's a benefit to computing |cIm| and limiting
                // further. At this point the speed-up is good enough to render
                // a 256x256 fairly quickly, for some subjective definition of
                // "fairly".

                // Inside the cardioid?
                if (cRe >= NEG_THREE_QUARTERS && cRe < POINT_FOUR) {
                    zRe = cRe - QUARTER;
                    zIm = cIm;
                    assembly {
                        reSq := shr(PRECISION, mul(zRe, zRe)) // (x - 1/4)^2
                        imSq := shr(PRECISION, mul(zIm, zIm)) // y^2
                        zIm := add(reSq, imSq) // q
                        zRe := add(zRe, zIm) // q + x - 1/4
                        zRe := sar(PRECISION, mul(zRe, zIm)) // q(q + x - 1/4)
                        imSq := shr(2, imSq) // y^2/4
                    }
                    if (zRe <= imSq) {
                        pixelIdx++;
                        continue;
                    }
                }
                
                // Inside the main bulb?
                if (cRe <= NEG_THREE_QUARTERS && cRe >= NEG_ONE_PT_TWO_FIVE) {
                    zRe = cRe + ONE;
                    zIm = cIm;
                    assembly {
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))
                    }
                    if (reSq + imSq <= SIXTEENTH) {
                        pixelIdx++;
                        continue;
                    }
                }

                // Brute-force computation from here on. Variables now mean what
                // they say on the tin.

                // Technically z_0 = (0,0) but z_1 is always c, so skip that
                // iteration and eke out an extra iteration.
                zRe = cRe;
                zIm = cIm;
                uint8 pixelVal;
                assembly {
                    for { let i := 0 } lt(i, maxIters) { i := add(i, 1) } {
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))
                        
                        if gt(add(reSq, imSq), FOUR) {
                            pixelVal := sub(maxIters, i)
                            i := maxIters
                        }

                        // (x+iy)^2 = (x^2 - y^2) + 2ixy
                        //
                        // mul is 5 gas but add is 3, so 2xy is mul(add(x,x),y) instead
                        // of mul(mul(x,y),2)
                        zIm := add(cIm, sar(PRECISION, mul(add(zRe, zRe), zIm)))
                        zRe := add(cRe, sub(reSq, imSq))

                    } // for maxIters
                } // assembly

                pixels[pixelIdx] = bytes1(pixelVal);
                pixelIdx++;

            } // for cIm
        } // for cRe

        return pixels;
    }

    /**
     * @dev Computes the "Mandelbar", taking the conjugate of z (hence bar).
     *
     * Also known as a "Tricorn". This differs from _mandelbrot() in that it has
     * no efficiency checks, initial zIm = -cIm (not cIm) and the zIm in the
     * assembly block is wrapped in sub(0, …). Each difference is noted with
     * comments.
     */
    function _mandelbar(Patch memory patch, int256 pixelWidth, int256 maxRe, int256 maxIm) internal pure returns (bytes memory) {
        bytes memory pixels = new bytes(uint256(patch.width * patch.height));
        
        int256 zRe;
        int256 zIm;
        int256 reSq;
        int256 imSq;

        uint8 maxIters  = patch.maxIterations;
        uint256 pixelIdx = 0;
        for (int256 cIm = patch.minImaginary; cIm < maxIm; cIm += pixelWidth) {
            for (int256 cRe = patch.minReal; cRe < maxRe; cRe += pixelWidth) {
                // Note: there are no containment checks we can do to reduce
                // brute-force computation.

                // Technically z_0 = (0,0) but z_1 is always c, so skip that
                // iteration and eke out an extra iteration.
                zRe = cRe;
                // Note: the -cIm for the conjugate.
                zIm = -cIm;
                uint8 pixelVal;
                assembly {
                    for { let i := 0 } lt(i, maxIters) { i := add(i, 1) } {
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))
                        
                        if gt(add(reSq, imSq), FOUR) {
                            pixelVal := sub(maxIters, i)
                            i := maxIters
                        }

                        // (x+iy)^2 = (x^2 - y^2) + 2ixy
                        //
                        // mul is 5 gas but add is 3, so 2xy is mul(add(x,x),y) instead
                        // of mul(mul(x,y),2)
                        //
                        // Note: the sub(0, …) is the "bar" part of the fractal.
                        zIm := sub(0, add(cIm, sar(PRECISION, mul(add(zRe, zRe), zIm))))
                        zRe := add(cRe, sub(reSq, imSq))

                    } // for maxIters
                } // assembly

                pixels[pixelIdx] = bytes1(pixelVal);
                pixelIdx++;

            } // for cIm
        } // for cRe

        return pixels;
    }

    /**
     * @dev Computes the 3-headed Multibrot, z_n -> z_n^4 + z_0;
     *
     * This is effectively the same as the Mandelbrot but we square z_n twice.
     * Each difference is noted with comments.
     */
    function _multi3(Patch memory patch, int256 pixelWidth, int256 maxRe, int256 maxIm) internal pure returns (bytes memory) {
        bytes memory pixels = new bytes(uint256(patch.width * patch.height));
        
        int256 zRe;
        int256 zIm;
        int256 reSq;
        int256 imSq;

        uint8 maxIters  = patch.maxIterations;
        uint256 pixelIdx = 0;
        for (int256 cIm = patch.minImaginary; cIm < maxIm; cIm += pixelWidth) {
            for (int256 cRe = patch.minReal; cRe < maxRe; cRe += pixelWidth) {
                // As with the containment tests for the Mandelbrot cardioid and
                // bulb, variable names are sometimes used differently to reduce
                // stack usage. 

                assembly {
                    reSq := shr(PRECISION, mul(cRe, cRe))
                    imSq := shr(PRECISION, mul(cIm, cIm))
                    reSq := add(reSq, imSq) // |z^2|
                }
                if (reSq > FOUR) {
                    // There's odd behaviour in the [-2,-2] corner without this
                    // initial check.
                    pixels[pixelIdx] = bytes1(maxIters);
                    pixelIdx++;
                    continue;
                } else if (reSq < EIGHTH) {
                    // Multibrots have cardioid-oids (great word eh?) that grow
                    // in minimum radius as the power increases. The
                    // Mandelbrot's cardioid inverts to 0.25.
                    // 
                    // TODO: loosen this bound to rule out more computation.
                    pixelIdx++;
                    continue;
                }

                // Brute-force computation from here on. Variables now mean what
                // they say on the tin.

                // Technically z_0 = (0,0) but z_1 is always c, so skip that
                // iteration and eke out an extra iteration.
                zRe = cRe;
                zIm = cIm;
                uint8 pixelVal;
                assembly {
                    for { let i := 0 } lt(i, maxIters) { i := add(i, 1) } {
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))

                        // Note: instead of immediately checking for divergence,
                        // we complete z^2 and then check |z^2|^2 > 4 whereas
                        // the standard Mandelbrot checks |z|^2.
                        //
                        // (x+iy)^2 = (x^2 - y^2) + 2ixy
                        //
                        // mul is 5 gas but add is 3, so 2xy is mul(add(x,x),y) instead
                        // of mul(mul(x,y),2)
                        //
                        // Note: unlike Mandelbrot, we don't add z_0 (c) yet.
                        zIm := sar(PRECISION, mul(add(zRe, zRe), zIm))
                        zRe := sub(reSq, imSq)
                        
                        // // Note: reSq + imSq = |z^2|^2
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))

                        if gt(add(reSq, imSq), FOUR) {
                            pixelVal := sub(maxIters, i)
                            i := maxIters
                        }

                        // Note: same as above except adding c.
                        zIm := add(cIm, sar(PRECISION, mul(add(zRe, zRe), zIm)))
                        zRe := add(cRe, sub(reSq, imSq))

                    } // for maxIters
                } // assembly

                pixels[pixelIdx] = bytes1(pixelVal);
                pixelIdx++;

            } // for cIm
        } // for cRe

        return pixels;
    }

    /**
     * @dev Computes the Burning Ship by using |Re| and |Im|.
     */
    function _burningShip(Patch memory patch, int256 pixelWidth, int256 maxRe, int256 maxIm) internal pure returns (bytes memory) {
        bytes memory pixels = new bytes(uint256(patch.width * patch.height));
        
        int256 zRe;
        int256 zIm;
        int256 reSq;
        int256 imSq;

        uint8 maxIters  = patch.maxIterations;
        uint256 pixelIdx = 0;
        // Note: the burning ship only looks like a ship when the imaginary axis
        // is flipped. Flipping the real is common too.
        for (int256 cIm = maxIm - pixelWidth; cIm >= patch.minImaginary; cIm -= pixelWidth) {
            for (int256 cRe = maxRe - pixelWidth; cRe >= patch.minReal; cRe -= pixelWidth) {
                // Technically z_0 = (0,0) but z_1 is always c, so skip that
                // iteration and eke out an extra iteration.
                zRe = cRe;
                zIm = cIm;
                uint8 pixelVal;
                assembly {
                    for { let i := 0 } lt(i, maxIters) { i := add(i, 1) } {
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))
                        
                        if gt(add(reSq, imSq), FOUR) {
                            pixelVal := sub(maxIters, i)
                            i := maxIters
                        }

                        // (x+iy)^2 = (x^2 - y^2) + 2ixy
                        //
                        // mul is 5 gas but add is 3, so 2xy is mul(add(x,x),y) instead
                        // of mul(mul(x,y),2)
                        zIm := add(cIm, sar(PRECISION, mul(add(zRe, zRe), zIm)))
                        zRe := add(cRe, sub(reSq, imSq))

                        // Note: burning ship is identical to Mandelbrot except
                        // for the absolute values of real and imaginary.
                        if slt(zRe, 0) {
                            zRe := sub(0, zRe)
                        }
                        if slt(zIm, 0) {
                            zIm := sub(0, zIm)
                        }
                    } // for maxIters
                } // assembly

                pixels[pixelIdx] = bytes1(pixelVal);
                pixelIdx++;

            } // for cIm
        } // for cRe

        return pixels;
    }

    /**
     * @dev Precomputed pixels with their generating information.
     */
    struct CachedPatch {
        bytes pixels;
        Patch patch;
    }

    /**
     * @dev A cache of precomputed pixels.
     *
     * Key is patchCacheKey(patch).
     */
    mapping(uint256 => CachedPatch) public patchCache;

    /**
     * @dev Returns the key for the patchCache mapping of this patch.
     */
    function patchCacheKey(Patch memory patch) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(patch)));
    }

    /**
     * @dev Cache a precomputed patch of pixels.
     *
     * See verifyCachedPatch().
     */
    function cachePatch(bytes memory pixels, Patch memory patch) public onlyOwner {
        require(pixels.length == uint256(patch.width * patch.height), "Invalid dimensions");
        patchCache[patchCacheKey(patch)] = CachedPatch(pixels, patch);
    }

    /**
     * @dev Returns a cached patch, confirming existence.
     *
     * As mappings always return a value, width and height both > 0 is used as
     * a proxy for the patch having been cached. Those with 0 area are
     * redundant anyway.
     */
    function cachedPatch(uint256 cacheIdx) public view returns (CachedPatch memory) {
        CachedPatch memory cached = patchCache[cacheIdx];
        require(cached.patch.width > 0 && cached.patch.height > 0, "Patch not cached");
        return cached;
    }

    /**
     * @dev Recompute pixels for a patch and confirm that they match the cache.
     *
     * This contract works on a trust-but-verify model. If patchPixels() were to
     * be used in a transaction, the gas fee would make the entire project
     * infeasible. Instead, it's only used in (free, read-only) calls, and the
     * returned values are stored via cachePatch(), which is cheaper. It's
     * possible to recompute the patch at any time via another free call to
     * verifyCachedPatch().
     */
    function verifyCachedPatch(uint256 cacheIdx) public view returns (bool) {
        CachedPatch memory cached = cachedPatch(cacheIdx);
        bytes memory fresh = patchPixels(cached.patch);
        return keccak256(fresh) == keccak256(cached.pixels);
    }

    /**
     * @dev Returns a concatenated pixel buffer of cached patches.
     */
    function concatenatePatches(uint256[] memory patches) public view returns (bytes memory) {
        CachedPatch[] memory cached = new CachedPatch[](patches.length);

        uint256 len;
        for (uint i = 0; i < patches.length; i++) {
            cached[i] = cachedPatch(patches[i]);
            len += cached[i].pixels.length;
        }

        bytes memory buf = new bytes(len);
        uint idx;
        for (uint i = 0; i < cached.length; i++) {
            for (uint j = 0; j < cached[i].pixels.length; j++) {
                buf[idx] = cached[i].pixels[j];
                idx++;
            }
        }
        return buf;
    }
}

