/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

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

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

pragma solidity ^0.8.6;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

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


pragma solidity ^0.8.7;

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    
    string private _name;
    string private _symbol;

    // Mapping from token ID to owner address
    address[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) 
        public 
        view 
        virtual 
        override 
        returns (uint) 
    {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint count;
        for( uint i; i < _owners.length; ++i ){
          if( owner == _owners[i] )
            ++count;
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        _owners.push(to);

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
        _owners[tokenId] = address(0);

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
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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


pragma solidity ^0.8.7;

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account but rips out the core of the gas-wasting processing that comes from OpenZeppelin.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < _owners.length, "ERC721Enumerable: global index out of bounds");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        uint count;
        for(uint i; i < _owners.length; i++){
            if(owner == _owners[i]){
                if(count == index) return i;
                else count++;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }
}

// File:  TruthToken.sol

pragma solidity ^0.8.0;

/**
 * Bayesian Inference: Truth
 */
 
interface BABEL {
    function getBabelById(uint) external view returns (string memory);
    function ownerOf(uint256) external view returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TruthToken is ERC721Enumerable, Ownable {
    string public constant tokenName = "Bayesian Inference: Truth";
    string public constant tokenSymbol = "TRUTH";
    bool public saleIsActive = false;
    uint256 public constant MAX_BAYES_PER_BABEL = 100;
    address public proxyRegistryAddress;
    address public BABEL_ADDRESS;
    address public DIMES_ADDRESS;

    uint256 public mintPrice = 10000000000000000; // 0.01 ETH
    uint256 public ownerMintEthReward = 5000000000000000; // 0.005 ETH
    uint256 public contractMintEthReward = 5000000000000000; // 0.005 ETH
    uint256 public dimesMintReward = 100000000000000000000; // 100 DIMES

    uint256 public updatePrice = 10000000000000000; // 0.01 ETH
    uint256 public ownerUpdateEthReward = 5000000000000000; // 0.005 ETH
    uint256 public contractUpdateEthReward = 5000000000000000; // 0.005 ETH
    uint256 public dimesUpdateReward = 100000000000000000000; // 100 DIMES

    uint256 public pendingDimesRewards = 0;
    uint256 public pendingEthRewards = 0;
    uint256 public contractsClaimableEth = 0;


    mapping (uint256 => uint256) public bayesIdtoBabelId;
    mapping (uint256 => uint256) public bayesIdToRatingValue;

    mapping (uint256 => uint256) public bayesIdRatingCount; // bayes ratings count per babel
    mapping (uint256 => uint256) public bayesIdTotalPoints; // total points awarded per babel

    mapping (address => uint256) public userClaimableDimes; // users total number of pending DIMES rewards
    mapping (address => uint256) public userClaimableEth; // users total number of pending ETH rewards

    mapping(address => bool) public projectProxy;

    constructor(address _proxyRegistryAddress, address _babelAddress, address _dimesAddress) ERC721(tokenName, tokenSymbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        BABEL_ADDRESS = _babelAddress;
        DIMES_ADDRESS = _dimesAddress;
    }

    event SaleStateUpdated(bool indexed _state);
    event mintPriceUpdated(uint256 indexed _price, uint256 indexed _ownerReward, uint256 indexed _contractReward);
    event updatePriceUpdated(uint256 indexed _price, uint256 indexed _ownerReward, uint256 indexed _contractReward);
    event dimesMintRewardUpdated(uint256 indexed _reward);
    event dimesUpdateRewardUpdated(uint256 indexed _reward);
    event bayesRatingUpdated(uint256 indexed _tokenId, uint256 indexed _oldRating, uint256 indexed _newRating);
    event userRewardsClaimed(address indexed _owner, uint256 indexed _dimesAmount, uint256 indexed _ethAmount);

    function getContractDimesBalance() public view returns(uint256) {
        uint256 balance = IERC20(DIMES_ADDRESS).balanceOf(address(this));
        return balance;
    }

    function sendDimesToOwner(address _address, uint256 _reward) internal {
        IERC20(DIMES_ADDRESS).transfer(_address, _reward);
    }

    function sendEthToOwner(address _address, uint256 _reward) internal {
        payable(_address).transfer(_reward);
    }

    function mint(uint256 _babelTokenId, uint256 _bayesRating) public payable {
        uint256 id = totalSupply();
        require(saleIsActive, "Sale is not active");
        require(msg.value >= mintPrice, "Eth value sent is below the mint price");

        // require babelId to exist
        string memory babel = BABEL(BABEL_ADDRESS).getBabelById(_babelTokenId);
        bytes memory b = bytes(babel);
        require(b.length > 0, "Babel token does not exist");
        
        // require _bayesRating to be between 0-100
        require(_bayesRating >= 0 && _bayesRating <= 100, "Rating must be a number from 0-100");
        
        // require babelId to have less than 100 Bayes assigned
        uint256 bayesRatingCount = bayesIdRatingCount[_babelTokenId] | 0;
        require(bayesRatingCount < MAX_BAYES_PER_BABEL, "Bayes are sold out for this Babel");

        // BLOCK USER from minting a bayes for a BABEL if they already have one
        uint256[] memory sendersTokens = this.tokensOfOwner(msg.sender);
        bool alreadyOwnsBayesForBabel = false;
        for(uint256 i; i < sendersTokens.length; ++i){
          // get babel id for that token
          uint256 ownedBabelId = bayesIdtoBabelId[sendersTokens[i]];
          if(ownedBabelId == _babelTokenId) alreadyOwnsBayesForBabel = true;
        }
        require(alreadyOwnsBayesForBabel == false, "User already owns bayes for this babel");

        // conditional to award DIMES if contract has sufficient balance
        uint256 dimesBalance = getContractDimesBalance();
        if ((dimesBalance - pendingDimesRewards) >= dimesMintReward) {
            address owner = BABEL(BABEL_ADDRESS).ownerOf(_babelTokenId);
            assignDimesRewards(owner, dimesMintReward);
        }

        // conditional to award ETH if contract has sufficient balance
        uint256 ethBalance = address(this).balance;
        if ((ethBalance - pendingEthRewards) >= (ownerMintEthReward + contractMintEthReward)) {
            address owner = BABEL(BABEL_ADDRESS).ownerOf(_babelTokenId);
            assignEthRewards(owner, ownerMintEthReward, contractMintEthReward);
        }

        bayesIdtoBabelId[id] = _babelTokenId;
        bayesIdToRatingValue[id] = _bayesRating;
        bayesIdRatingCount[_babelTokenId] += 1;
        bayesIdTotalPoints[_babelTokenId] += _bayesRating;
        _mint(msg.sender, id);
    }

    function claimRewards(address _owner) public {
        require(msg.sender == _owner, "Only the owner can claim rewards");

        uint256 usersDimesRewards = userClaimableDimes[_owner];
        uint256 usersEthRewards = userClaimableEth[_owner];

        if (usersDimesRewards > 0) {
          sendDimesToOwner(_owner, usersDimesRewards);
        }

        if (usersEthRewards > 0) {
          sendEthToOwner(_owner, usersEthRewards);
        }
        
        // clear dimes rewards from user
        userClaimableDimes[_owner] -= usersDimesRewards;
        pendingDimesRewards -= usersDimesRewards;
        // clear ETH rewards from user
        userClaimableEth[_owner] -= usersEthRewards;
        pendingEthRewards -= usersEthRewards;
        emit userRewardsClaimed(_owner, usersDimesRewards, usersEthRewards);
    }

    function updateBayesRating(uint256 _tokenId, uint256 _newRating) public payable {
        uint256 supply = totalSupply();
        require(_tokenId < supply, "Token ID does not exist");
        require(msg.value >= updatePrice, "Eth value sent is below the update price");

        // require msg.sender to be owner of the token
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner, "Bayes rating can only be updated by the owner"); 

        // validate the rating
        require(_newRating >= 0 && _newRating <= 100, "Bayes rating must be a number from 0-100");
        
        // require _newRating to be different than existing rating
        uint256 oldRating = bayesIdToRatingValue[_tokenId];
        require(_newRating != oldRating, "New rating must be a new value");

        uint256 babelTokenId = bayesIdtoBabelId[_tokenId];
        // set new bayes value
        bayesIdToRatingValue[_tokenId] = _newRating;

        // update bayesTotalPoints
        bayesIdTotalPoints[babelTokenId] -= oldRating;
        bayesIdTotalPoints[babelTokenId] += _newRating;

        // emit event that tokenmetadata has been updated
        emit bayesRatingUpdated(_tokenId, oldRating, _newRating);

        address babelOwner = BABEL(BABEL_ADDRESS).ownerOf(babelTokenId);

        // assign update rewards
        uint256 dimesBalance = getContractDimesBalance();
        if ((dimesBalance - pendingDimesRewards) >= dimesUpdateReward) {
            assignDimesRewards(babelOwner, dimesUpdateReward);
        }

        uint256 ethBalance = address(this).balance;
        if ((ethBalance - pendingEthRewards) >= (ownerMintEthReward + contractMintEthReward)) {
            assignEthRewards(babelOwner, ownerUpdateEthReward, contractUpdateEthReward);
        }
    }

    function assignDimesRewards(address _owner, uint256 _reward) internal {
        userClaimableDimes[_owner] += _reward;
        pendingDimesRewards += _reward;
    }

    function assignEthRewards(address _owner, uint256 _ownerReward, uint256 _contractReward) internal {
        userClaimableEth[_owner] += _ownerReward;
        contractsClaimableEth += _contractReward;
        pendingEthRewards += _ownerReward;
        pendingEthRewards += _contractReward;
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    function buildString(string memory _test, uint256 _rating) internal pure returns (string memory) {
        uint256 j = 25;
        bytes memory b = bytes(_test);
        string memory textOutput;
        
        //calculate word wrapping 
        uint i = 0;
        uint e = 0;    
        uint ll = 37; //max length of each line
        
        while (true) {
            e = i + ll;
            if (e >= b.length) {
	            e = b.length;
            } else {
        	    while (b[e] != ' ' && e > i) { 
        	        e--;
        	    }
            }
            
            // splice the line in
            bytes memory line = new bytes(e-i);
            for (uint k = i; k < e; k++) {
    	        line[k-i] = b[k];
            }
    
            textOutput = string(abi.encodePacked(textOutput,'<text class="base" x="15" y = "',toString(j),'">',line,'</text>'));

            j += 22;
            if (e >= b.length) break; // finished
            i = e + 1;
        }

        textOutput = string(abi.encodePacked(textOutput,'<text class="title" alignment-baseline="baseline" x="15" y="330">Dimenschen</text>'));
        textOutput = string(abi.encodePacked(textOutput,'<text class="title" alignment-baseline="baseline" x="250" y="330">',toString(_rating),'% True</text></svg>'));
        return textOutput;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId < totalSupply(), "Token id not yet minted");
        
        // get babel id and rating values
        uint256 babelId = bayesIdtoBabelId[tokenId];
        uint256 ratingValue = bayesIdToRatingValue[tokenId];
        
        string memory babel = BABEL(BABEL_ADDRESS).getBabelById(babelId);

        // "#fffb9d"
        // "#000000"
        // "#53ffa7"

        // return finalized token visuals and metadata
        string memory output = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><defs><linearGradient id="rectGradient" gradientTransform="rotate(90)"><stop offset="69%"  stop-color="#000000" /><stop offset="79%" stop-color="#53ffa7" /></linearGradient><linearGradient id="circleGradient" gradientTransform="rotate(315)"><stop offset="10%" stop-color="#000000" /><stop offset="90%" stop-color="#fffb9d" /></linearGradient></defs><style>.title { fill: #000000; font-family: Liberation Mono; font-size: 22px; } .base { fill: #ffffff; font-family: Liberation Mono; font-size: 18px; font-weight: 300; }</style><rect width="100%" height="100%" fill="url(#rectGradient)" /><circle cx="275" cy="150" r="50" fill="url(#circleGradient)" />'));

        // add text to image
        string memory textString = buildString(babel, ratingValue);
        output = string(abi.encodePacked(output, textString));

        // Add metadata to json
        string memory jsonMeta = string(abi.encodePacked('{"name": "',babel,'", "description": "The Library of Babel is total, perfect, complete, and whole. As an Inquisitor of the Library of Babel, your job is to inquire about the $Babel that have been cataloged by the Librarians, creating a single, decentralized, and permanent record of different types of analysis of thought stored on the Ethereum blockchain.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '",'));
        jsonMeta = string(abi.encodePacked(jsonMeta, ' "attributes": [{ "trait_type": "BABEL ID", "value": "',toString(babelId),'" }, { "trait_type": "TRUTH RATING", "value": "',toString(ratingValue),'" }]}'));
        string memory json = Base64.encode(bytes(jsonMeta));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        
        return output;
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) external onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
        emit SaleStateUpdated(saleIsActive);
    }

    function updateMintPrice(uint256 _price, uint256 _ownerReward, uint256 _contractReward) public onlyOwner {
        require(_ownerReward + _contractReward == _price, "Rewards must be equal to the cost of a mint.");
        ownerMintEthReward = _ownerReward;
        contractMintEthReward = _contractReward;
        mintPrice = _price;
        emit mintPriceUpdated(_price, _ownerReward, _contractReward);
    }

    function updateUpdatePrice(uint256 _price, uint256 _ownerReward, uint256 _contractReward) public onlyOwner {
        require(_ownerReward + _contractReward == _price, "Rewards must be equal to the cost of an update.");
        ownerUpdateEthReward = _ownerReward;
        contractUpdateEthReward = _contractReward;
        updatePrice = _price;
        emit updatePriceUpdated(_price, _ownerReward, _contractReward);
    }

    function updateDimesReward(uint256 _reward) public onlyOwner {
        dimesMintReward = _reward;
        emit dimesMintRewardUpdated(_reward);
    }

    function updateDimesUpdateReward(uint256 _reward) public onlyOwner {
        dimesUpdateReward = _reward;
        emit dimesUpdateRewardUpdated(_reward);
    }

    function getBalance() public view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    function transferContractDimes(address _address, uint256 _amount) public onlyOwner {
        IERC20(DIMES_ADDRESS).transfer(_address, _amount);
    }

    function claimContractEthRewards() public onlyOwner {
        uint256 claimableEth = contractsClaimableEth;
        contractsClaimableEth -= contractsClaimableEth;
        pendingEthRewards -= contractsClaimableEth;
        payable(msg.sender).transfer(claimableEth);
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}