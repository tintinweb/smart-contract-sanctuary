// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "../thirdparty/opensea/OpenSeaGasFreeListing.sol";
import "../utils/OwnerPausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
@notice An ERC721 contract with common functionality:
 - OpenSea gas-free listings
 - OpenZeppelin Pausable
 - OpenZeppelin Pausable with functions exposed to Owner only
 */
contract ERC721Common is Context, ERC721Pausable, OwnerPausable {
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    /// @notice Requires that the token exists.
    modifier tokenExists(uint256 tokenId) {
        require(ERC721._exists(tokenId), "ERC721Common: Token doesn't exist");
        _;
    }

    /// @notice Requires that msg.sender owns or is approved for the token.
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Common: Not approved nor owner"
        );
        _;
    }

    /// @notice Overrides _beforeTokenTransfer as required by inheritance.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
    @notice Returns true if either standard isApprovedForAll() returns true or
    the operator is the OpenSea proxy for the owner.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(owner, operator) ||
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

// Inspired by BaseOpenSea by Simon Fremaux (@dievardump) but without the need
// to pass specific addresses depending on deployment network.
// https://gist.github.com/dievardump/483eb43bc6ed30b14f01e01842e3339b/

import "./ProxyRegistry.sol";

/// @notice Library to achieve gas-free listings on OpenSea.
library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        address proxy = proxyFor(owner);
        return proxy != address(0) && proxy == operator;
    }

    /**
    @notice Returns the OpenSea proxy address for the owner.
     */
    function proxyFor(address owner) internal view returns (address) {
        address registry;
        uint256 chainId;

        assembly {
            chainId := chainid()
            switch chainId
            // Production networks are placed higher to minimise the number of
            // checks performed and therefore reduce gas. By the same rationale,
            // mainnet comes before Polygon as it's more expensive.
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 137 {
                // polygon
                registry := 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
            case 80001 {
                // mumbai
                registry := 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
            }
            case 1337 {
                // The geth SimulatedBackend iff used with the ethier
                // openseatest package. This is mocked as a Wyvern proxy as it's
                // more complex than the 0x ones.
                registry := 0xE1a2bbc877b29ADBC56D2659DBcb0ae14ee62071
            }
        }

        // Unlike Wyvern, the registry itself is the proxy for all owners on 0x
        // chains.
        if (registry == address(0) || chainId == 137 || chainId == 80001) {
            return registry;
        }

        return address(ProxyRegistry(registry).proxies(owner));
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

/// @notice A minimal interface describing OpenSea's Wyvern proxy registry.
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
@dev This pattern of using an empty contract is cargo-culted directly from
OpenSea's example code. TODO: it's likely that the above mapping can be changed
to address => address without affecting anything, but further investigation is
needed (i.e. is there a subtle reason that OpenSea released it like this?).
 */
contract OwnableDelegateProxy {

}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice A Pausable contract that can only be toggled by the Owner.
contract OwnerPausable is Ownable, Pausable {
    /// @notice Pauses the contract.
    function pause() public onlyOwner {
        Pausable._pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        Pausable._unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the aura.lol authors
// Author David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Common.sol";
import "./Renderers/IManifestRenderer.sol";
import "./TokenData.sol";
import "./utils/ERC2981SinglePercentual.sol";

//     \    |   |  _ \     \      |      _ \  |     
//    _ \   |   | |   |   _ \     |     |   | |     
//   ___ \  |   | __ <   ___ \    |     |   | |     
// _/    _\\___/ _| \_\_/    _\_)_____|\___/ _____|
// ________aura.lol________Constant_Dullaart_2022_|
// 
// A generative, dynamic in-chain manifest, with physical off-chain interaction, with a max of 8 (or 9 lol) iterations.
// 
// The word "aura" is a reference to the concept referring to the unique aesthetic authority of a work of art, as defined by Walter Benjamin in "The Work of Art in the Age of Mechanical Reproduction" 
// Where the idea of registering a mechanically reproducible work using decentralised ledger technology would be replacing the sense of 'aura' and making it a commodity.
// 
// 
// 97 110 100 32 115 111 32 105 116 32 98 101 103 105 110 115 
// 
contract AuraLol is ERC721Common, ERC2981SinglePercentual {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Price for minting
    uint256 public mintPrice = 0.3 ether;

    /// @notice Total maximum amount of tokens
    uint16 public constant MAX_NUM_TOKENS = 512;

    /// @notice Token data used by renderes
    mapping(uint256 => TokenData) internal tokenData;

    /// @notice Splits minting fees and royalties between DEVs
    address payable immutable paymentSplitter;

    /// @notice The renderer used to visualize the token
    /// @dev tokenURI will be delegeted to this contract
    IManifestRenderer internal renderer;

    /// @notice Contracts with the ability to modify token data
    EnumerableSet.AddressSet internal mutators;

    /// @notice Only address that is allowed to call ownerMint.
    address internal ownerMinter;

    /// @notice Currently minted supply of tokens
    uint16 public totalSupply = 0;

    /// @notice Remaining mints for {mint}
    uint16 public remainingSales = 256;

    constructor(
        address newOwner,
        address payable paymentSplitter_,
        address ownerMinter_
    ) ERC721Common("aura.lol", "MANI") {
        paymentSplitter = paymentSplitter_;
        ownerMinter = ownerMinter_;

        _setRoyaltyReceiver(paymentSplitter);
        _setRoyaltyPercentage(500);

        transferOwnership(newOwner);
    }

    // -------------------------------------------------------------------------
    //
    //  Minting
    //
    // -------------------------------------------------------------------------

    /// @notice Sets the amount of remaining minting slots and price
    function setSalesParameters(uint16 remainingSales_, uint256 mintPrice_)
        external
        onlyOwner
    {
        remainingSales = remainingSales_;
        mintPrice = mintPrice_;
    }

    /// @dev Disallow all contracts
    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert OnlyEOA();
        _;
    }

    /// @notice Mints tokens to a given address.
    /// @dev The minter might be different than the receiver.
    /// @param to Token receiver
    function mint(address to, uint16 num) external payable onlyEOA {
        if (num > remainingSales) revert InsufficientTokensRemanining();
        if (num * mintPrice != msg.value) revert InvalidPayment();

        remainingSales -= num;

        _processPayment();
        _processMint(to, num);
    }

    /// @notice Mints tokens to a given address (only for ownerMinter).
    /// @dev The minter might be different than the receiver.
    /// @param to Token receiver
    function ownerMint(address to, uint16 num) external {
        if (msg.sender != ownerMinter) revert OnlyOwnerMinter();

        if (num > remainingSales) revert InsufficientTokensRemanining();
        remainingSales -= num;

        _processMint(to, num);
    }

    /// @notice Mints new tokens for the recipient.
    function _processMint(address to, uint16 num) private {
        if (num + totalSupply > MAX_NUM_TOKENS)
            revert InsufficientTokensRemanining();

        uint256 tokenId = totalSupply;
        totalSupply += num;

        for (uint256 i = 0; i < num; i++) {
            tokenData[tokenId] = TokenData({
                originalOwner: to,
                generation: 0,
                mintTimestamp: block.timestamp,
                data: new bytes[](0)
            });
            ERC721._safeMint(to, tokenId, "");
            ++tokenId;
        }
    }

    /// @notice Sets the minter that can access `ownerMint`
    function setOwnerMinter(address ownerMinter_) external onlyOwner {
        ownerMinter = ownerMinter_;
    }

    // -------------------------------------------------------------------------
    //
    //  Payment
    //
    // -------------------------------------------------------------------------

    /// @notice Default function for receiving funds
    /// @dev This enable the contract to be used as splitter for royalties.
    receive() external payable {
        _processPayment();
    }

    function _processPayment() private {
        paymentSplitter.sendValue(msg.value);
    }

    /// @dev Sets the ERC2981 royalty percentage in units of 0.01%
    function setRoyaltyPercentage(uint96 percentage) external onlyOwner {
        _setRoyaltyPercentage(percentage);
    }

    // -------------------------------------------------------------------------
    //
    //  Mutators
    //
    // -------------------------------------------------------------------------

    /// @notice Adds a mutator contract to the allow list
    function addMutator(address mutator) external onlyOwner {
        mutators.add(mutator);
    }

    /// @notice Removes a mutator contract from the allow list
    function removeMutator(address mutator) external onlyOwner {
        mutators.remove(mutator);
    }

    /// @dev Allows only msg.senders from the mutator allow list
    modifier onlyMutators() {
        if (!mutators.contains(msg.sender)) revert OnlyMutators();
        _;
    }

    /// @notice Modifies tokenData for a certain tokenId
    /// @dev Only callable by allowlisted mutator contracts
    function setTokenData(uint256 tokenId, TokenData memory tokenData_)
        external
        onlyMutators
        tokenExists(tokenId)
    {
        tokenData[tokenId] = tokenData_;
    }

    /// @notice Returns the token data for a certain tokenId
    function getTokenData(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (TokenData memory)
    {
        return tokenData[tokenId];
    }

    // -------------------------------------------------------------------------
    //
    //  Metadata
    //
    // -------------------------------------------------------------------------

    /// @notice Changes the current renderer for tokens
    function setRenderer(address renderer_) external onlyOwner {
        renderer = IManifestRenderer(renderer_);
    }

    /// @notice Returns the URI for token.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return renderer.tokenURI(tokenId, tokenData[tokenId]);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Common, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // -------------------------------------------------------------------------
    //
    //  Errors
    //
    // -------------------------------------------------------------------------

    error MintDisabled();
    error OnlyEOA();
    error InsufficientTokensRemanining();
    error InvalidPayment();
    error OnlyMutators();
    error OnlyOwnerMinter();
}
//
// 35303437363833303632353737373262343336613738366635613537343636623530363736663637343934343738333036313538353237333561353433353534363434373536366535393537333537363561333334613638363334373638333534393435333937353632343736633735356135343737373636343437366333303632343735353262343336393431363735303437373837303632366437333637363336643536373335303533346137613634343836633733356135383465366635613537353633303439363934323666363336643536366435303533346136663634343835323737363337613666373634633332333136383635343734653662363236393335363936323332333933303633333335323739353935383432366135613437333437353539333233393734346333323461373636323333353237613634343834613638363334333338376134633661346437353464353333393661363333333464373635393664333937363634343834653330363336643436373734633664333137303632363933353661363333333464363935303637366633383463333236383663353935373531326234333661373836393632333235323335353036373666363734393434373836623631353835393637353933323738363836333333346433393439366434653736363236653532363836313537333536633633363934393262343336393431363734393433343133383561343736633332343934373465373335393538346537613530353334613737353935373634366334633537363836633539353735323663363336393439326234333639343136373439343334313637343934343738366634643534333535343634343735363665353935373335373635613333346136383633343736383335343934353339373536323437366337353561353437373736363134343435326234333639343136373439343334313338346333323532373036343661333434623433363934313637343934333431333836343537373736373539333237383638363333333464333934393664333536383634363934323735353935383539373436343437343636393633373934393637363135373531333934393665353236383539366534643639343934373532363836343437343537343634343734363639363337613330363936343437343636393633373934393262343336393431363734393433343136373439343437383733363135333432373936323332373836633530353334613737363336643536376135613537333533303539353835323730363233323334363934393437346537333539353834653761353035333461363835393333353237303634366435353639353036393431333835393533343236663633366435363664353035333439366135613537333536613632333235323663343936393432366235393538353236383463353835323736356133323634373335613534333036393634343734363639343936613335343636323664346537363561343735353338346333323435326235303433333937333631353433343462343934333431363734393433343136373530343737383730343934383461373636323437353533393439366534323739356135383465366336323665353236383634343736633736363236393439326234393434373836383439343736383739356135373539333934393639346536623561353734653736356134373535363934393437353236383634343734353734363434373339366535613332373836633530353334613330353935373439363935303662353236633539333233393662356135343737373635393534333433383463333237383730353036373666363734393433343136373530343333393331363234343334346234333639343136373439343334313338356134373663333234393437366336623530353334613734363535333331333035393537343937343539333233393735363434373536373536343433343936373539333237383638363333333464333934393665353236383539363933313661363233323335333035613537333533303439366133343462343934333431363734393433343136373530343735323730363436393432366136323437343637613633376133303639363434373436363934633538343236383632366435353637353935373465333036313538356136633439363934323730356134343330363935613537333536613632333235323663343936613334346234393433343136373439343334313637343934333431333835613437366333323530363736663637343934333431363734393433343136373439343334313637353034373637373935303662353637353539333233393662356135333432373435613538346537613539353736343663353034333339366634643661333434623439343334313637343934333431363734393433343136373439343437383737343934373465373335393538346537613530353334613638363234373536373936343433343236383632343735363739363434333331373036323664356137363439366133343462343934333431363734393433343136373439343334313637343934333431363735363437333836373561353733353661363233323532366334393437343536373632353735363761363333323436366535613533343237303632366535323736343934373436373534393437366337343539353736343663346334333432366136313437333937363633333235353637363434373638366334393437366337343539353736343663343934383663373636343533343233333539353733353330343934383532373634393438353637613561353337373637356135373335333035613538343936373635353733393331363336393432333035613538363833303439343734363735356134333432366636313538353136373634343736383663343934343738376136343438346137363632366436333262353235373335366136323332353236633530343333393761363434383461373636323664363332623439343734613331363434383532373636323639333436373530343734613739346337613334346234393433343136373439343334313637343934333431363734393433343136373535333234363332356135333432333036313437353536373632343734363761363434333432373036323537343636653561353337373637363135383531363736343332366337333632343334323661363233323335333035393537366337353439343836633736363435383439363736313437366336623561343735363735343934373331366336333333346536383561333235353735343934343738363936333639333832623433363934313637343934333431363734393433343136373439343334313637343934363461366336323537353637343539366435363739346334333432333036313437353536373632353733393739356135333432333035613538363833303439343836633736363435333432333335393537333533303439343835323736343934373638373035613437353537333439343835323666356135333432373335393538346136653561353834393637363434373638366334393437366337343539353736343663343934373638363836333739343233303632373934323639356135333334363735333537333436373539333234363761356135333432333536323333353536373539333236383736363333323535363735393537333436373631353733313638356133323535363736343437363836383634343334323730363337393432333036323332333836373633333233313638363234373737363736343437333836373631343733393733356134333432333536323333353637393439343733313663363333333465363835613332353536373635353733393331343934383634373036323437373736373539366435353637363135373335366436323333346137343561353735313735353034373461373934633761333433383539366534393736353036373666363734393433343136373439343334313637343934333431363734393433343234663561353736633330363134373536373934393438353236663561353334323730363235373436366535613533343237353632333334393637363434373638366334393437333136633633333334653638356133323535363736353537333933313439343736383730356134373535363736343332366337333632343334323639356135333432363836343433343236383632366536623637363235373339373435613537333533303439343835323739353935373335376136323537366333303634343735363662343934373339333235613538343936373634343736383663343934383634366335393639373736373539353737383733343934383532366635613533343237343539353736343730353937393432366635393538343237373561353733353761343934383634373036343437363837303632363934323335363233333536373934393437346137393632333336343761356135383439373534333639343136373439343334313637343934333431363734393433343133383463333334313262343336393431363734393433343136373439343334313637343934333431333835613664333937393632353334323661363234373436376136333761333036393561366433393739363235333439326234333639343136373439343334313637343934333431363734393433343136373439343437383662363135383539363735393332373836383633333334643339343936643561373636333664333037343561333334613736363435383431363935303637366636373439343334313637343934333431363734393433343136373439343334313637343934343738373036323665343233313634343334323661363234373436376136333761333036393561366433393739363235333331366136323332333533303633366433393733343936393432333036353538343236633530353334613664363135373738366334393639343237353539353733313663353035333461363935393538346536633532366436633733356135333439363736323332333536613631343734363735356133323535333934393665343237393561353835613730356135383634343636323664346537363561343735363461363235373436366535613533363737303439366133343462343934333431363734393433343136373439343334313637343934333431363735303433333936623631353835393262343336373666363734393433343136373439343334313637343934333431363734393433343133383561343736633332343934373465373335393538346537613530353334613664363233333461373434633537363437393632333335363737343936613334346234393433343136373439343334313637343934333431363734393433343136373439343334313338363434373536333436343437343637393561353734353637353933323738363836333333346433393439366435613736363336643330373435393332333937353634343834613736363234333432373435613538346537613539353736343663343936393432373936323333363437613530353334393761343936393432373736323437343636613561353736383736363234373532366336333661333036393532353733353330356135383439363736353537333933313633363934323734356135383465376135393537363436633439343736383663363336643535363935303661373737363634343735363334363434373436373935613537343532623433363934313637343934333431363734393433343136373439343334313637343934343737373635613437366333323530363736663462343934333431363734393433343136373439343334313637343934333431363735303437353237303634363934323661363234373436376136333761333036393561366433393739363235333331366536333664333933313633343334393262343336393431363734393433343136373439343334313637343934333431363734393433343136373530343734613331363434383532373636323639343236613632343734363761363337613330363935613537333536613632333235323663343934373461333036323639343236393634343733343734356134373536366435393538353637333634343334323737363435373738373334633538346137303561333236383330343936393432373636323664346537333631353734653732353035333461366336323664346537363561343735363465356135383465376135393537363436633462343336623639353036623536373535393332333936623561353437373736353936653536333036343437333937353530363736663637343934333431363734393433343136373439343334313637343934333431333834633332353237303634366133343462343934333431363734393433343136373439343334313637343934343737373635613664333937393632353433343462343934333431363734393433343136373439343334313637343934343738366236313538353936373539333237383638363333333464333934393664346537333561353734363739356136643663333434393661333433383463333235323730363436613334346234393433343136373439343334313637343934333431333834633332353237303634366133343462343336393431363734393433343136373439343334313637353034373532373036343639343236613632343734363761363337613330363935613538346137393632333334393639343934383465333036353537373836633530353334613662363135383465373736323437343633353466363934323735363233323335366334663739343932623530343333393662363135383539326234333639343136373439343334313637343934333431363735303437353237303634363934323661363234373436376136333761333036393539366436633735353935383461333534393639343237613634343836633733356135343330363935613437366337613633343737383638363535343666363736323664333937353561353437333639353036373666363734393433343136373439343334313637343934333431363735303437363737613530366234613730363236643436373936353533343237393561353834323739356135383465366336323665353236383634343736633736363236393432373635613639343233353632333335363739343934373331366336333333346536383561333235353338346333323637376135303637366636373439343334313637343934333431363734393433343136373530343835323663363534383532363836333664353636383439343734653733353935383465376135303533346136643632333334613734346335373465373636323665353237393632333237373637363235373536376136333332343636653561353334393637363333333532333536323437353533393439366536343736363336643531373436343333346136383633343437303639363336643536363836313739333133333632333334613662346637393439326234333639343136373439343334313637343934333431363734393433343133383463333335323663363534383532363836333664353636383530363736663637343934333431363734393433343136373439343437373736356134373663333235303637366636373439343334313637343934333431363734393434373836623631353835393637353933323738363836333333346433393439366436633734353935373634366336333739343936373633333335323335363234373535333934393664353237303633333334323733353935383662333634393437333537363632366435353337343936613334346234393433343136373439343334313637343934333431363734393434373836623631353835393637353933323738363836333333346433393439366433393739363135373634373036323664343637333439363934323761363434383663373335613534333036393561343736633761363334373738363836353534366636373632366433393735356135343733363935303637366636373439343334313637343934333431363734393433343136373439343334313338363134343464326235343333346137303561333236633735353935373737333834633332363737613530363736663637343934333431363734393433343136373439343334313637343934333431333835393332343637353634366434363761353036613737373635393332343637353634366434363761353036373666363734393433343136373439343334313637343934333431363735303433333936623631353835393262343336393431363734393433343136373439343334313637343934333431333835613437366333323439343734653733353935383465376135303533346137353634353737383733356135373531363934393438346533303635353737383663353035333461366236313538346537373632343734363335346636393432373536323332333536633466373934393262343336393431363734393433343136373439343334313637343934333431363734393434373836663464376133353466363233333461373435393537373837303635366435363662353034333339366634643761333434623439343334313637343934333431363734393433343136373439343334313637353034373465363836323665356136383633376133343338346333323465363836323665356136383633376133343462343934333431363734393433343136373439343334313637343934343737373635613437366333323530363736663637343934333431363734393433343136373439343334313637353034373532373036343639343236613632343734363761363337613330363936323537353637613633333234363665356135333439363736333333353233353632343735353339343936643532373036333333343237333539353836623336343934373335373636323664353533373439366133343462343934333431363734393433343136373439343334313637343934333431363735303437363737613530366233313663363333333465363835613332353536373631343736633662356134373536373534393437366337353439343736633734353935373634366334393433363837393631353736343666363434333432366136323437366336613631373934313338363333333432363836323639343236613632343734363761363337613330363935613332373833353633343736383730353933323339373534393437363437333635353834323666363135373465373636323639333136383633366534613736363437393331373936313537363436663634343334393262353034333339376136333437343637353530363934323761353935383561366334393437343637613462353437373736363134343464326234333639343136373439343334313637343934333431363734393433343136373439343437383661353935373335333235393538346432623530343333393661353935373335333235393538346432623433363934313637343934333431363734393433343136373439343334313338346333323532373036343661333434623439343334313637343934333431363734393433343133383463333235323730363436613334346234393433343136373439343334313637353034333339366236313538353932623433363736663637343934333431363734393433343133383561343736633332343934373465373335393538346537613530353334613330353935373439373436333437343637353561353334393637363135373531333934393664353236633539333233393662356135333439326234333639343136373439343334313637343934333431363735303437353237303634366133343462343934333431363734393433343136373439343334313637343934343738366634643661333534353561353734653736356134373535363736313537333136383561333235353338346333323637373935303637366636373439343334313637343934333431363734393433343136373530343834313637353933323738363836333333346433393439366434363733356135383461333034393437343637333561353834613330346335373663373535613664333836393530363736663637343934333431363734393433343136373439343334313637343934333432353536323739343236623561353734653736356134373535363735393533343236663631353735323662356135373334363736323537353637613633333234363665356135333432366436333664333937343439343734363735343934373663373435393537363436633463343334323731363435383465333034393437346536663632333233393761356135333432363836323639343237303632353734363665356135333432363836323664353136373631343736633330343934383532366635613533343133383633333335323739363233323335366535303662353236633539333233393662356135343737373636333333353237393632333233353665353036393432363936343538353233303632333233343735353034373461373934633761333433383539366534393736353036373666363734393433343136373439343334313637343934333431363734393433343234663561353736633330363134373536373934393438353236663561353334323730363235373436366535613533343237353632333334393637363434373638366334393437333136633633333334653638356133323535363736343437363836383634343334323666353935383464363735393664353636633632363934323666363135373532366235613537333436373634333236633733363234333432363935613533343236383634343334323638363236653662363736323537333937343561353733353330343934383532373935393537333537613632353736633330363434373536366234393437333933323561353834393637363434373638366334393438363436633539363937373637353935373738373334393438353236663561353334323734353935373634373035393739343236663539353834323737356135373335376134393438363437303634343736383730363236393432333536323333353637393439343734613739363233333634376135613538343937353433363934313637343934333431363734393433343136373439343334313338346333333431326234333639343136373439343334313637343934333431363734393433343133383561366433393739363235333432366136323437343637613633376133303639356136643339373936323533343932623433363934313637343934333431363734393433343136373439343334313637343934343738366236313538353936373539333237383638363333333464333934393664356137363633366433303734356133333461373636343538343136393530363736663637343934333431363734393433343136373439343334313637343934333431363734393434373837303632366534323331363434333432366136323437343637613633376133303639356136643339373936323533333136613632333233353330363336643339373334393639343233303635353834323663353035333461366436313537373836633439363934323735353935373331366335303533346136623561353734653736356134373536343736313537373836633439363934323736363236643465366635393537333536653561353433303639363334383461366336343664366336633634333035323663353933323339366235613535366337343539353736343663346234333662363935303637366636373439343334313637343934333431363734393433343136373439343334313338346333323532373036343661333434623439343334313637343934333431363734393433343136373439343334313637353034373532373036343639343236613632343734363761363337613330363935613664333937393632353333313665363336643339333136333433343932623433363934313637343934333431363734393433343136373439343334313637343934333431363735303437346133313634343835323736363236393432366136323437343637613633376133303639356134373536366136323332353236633439343734613330363236393432363936343437333437343561343735363664353935383536373336343433343237373634353737383733346335383461373035613332363833303439363934323736363236643465373336313537346537323530353334613662356135373465373635613437353634653561353834653761353935373634366334623433366236393530366235323663353933323339366235613534373737363539366535363330363434373339373535303637366636373439343334313637343934333431363734393433343136373439343334313338346333323532373036343661333434623439343334313637343934333431363734393433343136373439343437373736356136643339373936323534333434623439343334313637343934333431363734393433343136373439343437383662363135383539363735393332373836383633333334643339343936643465373335613537343637393561366436633334343936613334333834633332353237303634366133343462343934333431363734393433343136373439343334313338346333323532373036343661333434623439343334313637343934333431363734393433343133383561343736633332343934373465373335393538346537613530353334613639363135373335363836333665366237343561343735363661363233323532366334393639343237613634343836633733356135343330363935613437366337613633343737383638363535343666363736323664333937353561353437333639353036373666363734393433343136373439343334313637343934333431363735303437363737613530366236383730356134373532366336323639343237343561353834653761353935373634366335303433333936663464376133343462343934333431363734393433343136373439343334313637343934343738333035613538363833303539353834613663353935333432366136323437343637613633376133303639356136643339373936323533333136613632333233353330363336643339373334393437333136633633333334653638356133323535363934393438346533303635353737383663353035333461333336323333346136623463353836343739353935383431333635393665346136633539353737333734363433323339373935613434373336393530363736663637343934333431363734393433343136373439343334313637353034333339333035613538363833303539353834613663353935343334346234393433343136373439343334313637343934333431333834633332353237303634366133343462343934333431363734393433343136373439343334313338356134373663333234393437346537333539353834653761353035333461366235613537346537363561343735353639343934383465333036353537373836633530353334613662363135383465373736323437343633353466363934323735363233323335366334663739343932623433363934313637343934333431363734393433343136373439343334313338363134343464326235333537333537373634353835313338346333323637376135303637366636373439343334313637343934333431363734393433343136373530343734653638363236653561363836333761333433383463333234653638363236653561363836333761333434623439343334313637343934333431363734393433343133383463333235323730363436613334346234393433343136373439343334313637353034333339366236313538353932623433363736663637343934333431363735303433333936623631353835393262343336373666363734393433343136373530343735613736363233333532366336333639343237613634343836633733356135343330363936343437353633343634343333313638363234373663366536323661366636373539333235363735363434373536373934663739343237343539353834613665363135373334373436343437333937373466363934313739346434383432333434663739343237343539353834613665363135373334373435393664333933303634343733393734346636393431373834643438343233343466373934393262343336393431363734393433343136373439343335613661363233333432333534663739343137393464343434353330343934373461333534393434373836383439343736383739356135373539333934393664333136383631353737383330363237613730376136343438366337333561353834653331363534383638343135613332333136383631353737373735353933323339373434393661333537613634343836633733356135383465333136353438363733383463333234353262343336393431363734393433343133383463333235613736363233333532366336333661333434623439343334313338346333323532373036343661333434623433363934313637353034383465333036353537373836633530363736663637343934333431363735393332343637353634366434363761343934383733346234393433343136373439343334313637363235373436333434633538363437303561343835323666346636393431373834643434343136633466373736663637343934333431363736363531366636373439343437373736363333333532333536323437353532623433363736663637343934343738376135393333346137303633343835313637363333333461366135303533346136663634343835323737363337613666373634633332343637313539353836373735356133323339373635613332373836633539353834323730363337393335366136323332333037363539353737303638363534333339373336313537346137613463333237303738363435373536373936353533333837383463366134353738346336613435373636313665343633313561353834613335346336643331373036323639333537313633373934393262353034333339376135393333346137303633343835313262343336393431363735303438346536613633366436633737363434333432376136333664346433393439366436383330363434383432376134663639333837363632353734363334353933323532373534633664346137363632333335323761363434383461363836333437346536623632363933353661363233323330373635393664333937363634343834653330363336643436373734633761346437353464373933343738346333323730376134633332346137363632333335323761363434383461363836333433333537343631353733343735363136653464363935303661373737363633333234653739363135383432333035303637366636373439343437383761353933333461373036333438353136373634343836633737356135343330363936343437353633343634343333393462353935383561363835353332346537393631353834323330343936393432376136333664346433393439366534653661363336643663373736343433333537313633373934393262353034333339376135393333346137303633343835313262343336613737373635393664333936623635353433343462353034333339366636343437333137333530363736663364

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the aura.lol authors
// Author David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "../AuraLol.sol";

contract BaseMutator {
    AuraLol internal callback;

    constructor(AuraLol callback_) {
        callback = callback_;
    }

    function _setTokenData(uint256 tokenId, TokenData memory tokenData)
        internal
    {
        callback.setTokenData(tokenId, tokenData);
    }

    function _getTokenData(uint256 tokenId)
        internal
        view
        returns (TokenData memory)
    {
        return callback.getTokenData(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the aura.lol authors
// Author David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "./BaseMutator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GodMutator is Ownable, BaseMutator {
    constructor(AuraLol callback, address newOwner) BaseMutator(callback) {
        transferOwnership(newOwner);
    }

    function setTokenData(uint256 tokenId, TokenData memory tokenData)
        external
        onlyOwner
    {
        _setTokenData(tokenId, tokenData);
    }

    function incrementGeneration(uint256 tokenId) external onlyOwner {
        TokenData memory data = _getTokenData(tokenId);
        data.generation++;
        _setTokenData(tokenId, data);
    }

    function setGeneration(uint256 tokenId, uint96 generation)
        external
        onlyOwner
    {
        TokenData memory data = _getTokenData(tokenId);
        data.generation = generation;
        _setTokenData(tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the aura.lol authors
// Author David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "../TokenData.sol";

interface IManifestRenderer {

    /// @notice Returns the metadata uri for a given token
    function tokenURI(uint256 tokenId, TokenData memory tokenData)
        external
        pure
        returns (string memory);
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the aura.lol authors
// Author David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;


/// @dev Data struct that will be passed to the rendering contract
struct TokenData {
    uint256 mintTimestamp;
    uint96 generation;
    address originalOwner;
    bytes[] data;
}

// SPDX-License-Identifier: MIT
// Copyright 2021 David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "./IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @notice ERC2981 royalty info base contract
 * @dev Implements `supportsInterface`
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2021 David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "./ERC2981.sol";

/**
 * @notice ERC2981 royalty info implementation for a single beneficiary
 * receving a percentage of sales prices.
 * @author David Huber (@cxkoda)
 */
contract ERC2981SinglePercentual is ERC2981 {
    /**
     * @dev The royalty percentage (in units of 0.01%)
     */
    uint96 _percentage;

    /**
     * @dev The address to receive the royalties
     */
    address _receiver;

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        royaltyAmount = (salePrice / 10000) * _percentage;
        receiver = _receiver;
    }

    /**
     * @dev Sets the royalty percentage (in units of 0.01%)
     */
    function _setRoyaltyPercentage(uint96 percentage_) internal {
        _percentage = percentage_;
    }

    /**
     * @dev Sets the address to receive the royalties
     */
    function _setRoyaltyReceiver(address receiver_) internal {
        _receiver = receiver_;
    }
}

// SPDX-License-Identifier: None

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 * @author Taken from https://eips.ethereum.org/EIPS/eip-2981
 */
interface IERC2981 is IERC165 {
    /**
     * @notice Called with the sale price to determine how much royalty
     * is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}