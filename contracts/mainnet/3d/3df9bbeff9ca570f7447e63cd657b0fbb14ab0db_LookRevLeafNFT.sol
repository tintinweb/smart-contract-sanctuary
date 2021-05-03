/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

// SPDX-License-Identifier: GNU AGPLv3

pragma solidity ^0.8.0;


interface ILookRevTree {
    function addLeafToOpenBranch(uint256 genesisBranch, uint256 tokenID) external returns (uint256);
    function addLeavesToOpenBranches(uint256[] calldata tokenIDs) external returns (uint256);
}


interface ILookRevLeafNFT {
    function getNFTTokenRecipient(uint256 tokenID) external view returns (address);
    function redeemCredits(address recipient) external returns (uint256);
    function rewardTokenID(uint256[] calldata tokenIDs, uint256[] calldata amount) external;
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // silence state mutability warning without generating bytecode
    // see https://github.com/ethereum/solidity/issues/2691
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

/**
 * @dev Patched. Wrappers over Solidity's arithmetic operations with added overflow
 * checks. Patched.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a && c >= b, "SafeMath: addition overflow");

        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0 || b == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
                
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


/**
 * @dev String operations.
 */
library Strings {

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
}


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


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
        
        
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
            
    // Patched with default value. Base URI
    string private _baseURI = "https://lookscoin.com/nft/";
            
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    
    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
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
     * @dev Patched. Returns custom token uri or generic token uri.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // If there is custom token URI, return the custom URI.
        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        }
        // returns generic token URI
        return bytes(_baseURI).length > 0
            ? string(abi.encodePacked(_baseURI, tokenId.toString()))
            : '';
    }

    
    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: If all token IDs share a prefix (for example, if your URIs look like
     * `https://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}


/// LookRevLeafNFT is ERC721
contract LookRevLeafNFT is
    ERC721,
    ILookRevLeafNFT
    {
    mapping (address => uint256[]) private ownerNFTTokens;
    mapping (uint256 => uint256) public tokenCredits;

    uint256 public nextTokenId = 1;

    /// inital conversion rate is 1 ETH = 200,000 LooksCoin
    uint256 public COIN_RATE = 200000;

    /// LooksCoin credit for new LeafNFT token
    uint256 constant public INIT_CREDIT = 10 ** 15;

    /// Cost of leafNFT changes with the growth of the tree
    /// Initial cost of leafNFT is 0.05 ETH
    uint256 public averageCost = 5 * 10 ** 16;
    /// Maximum amount of LeafNFT allowed to mint at a time
    uint256 public maxBatchCount = 10;
    
    address private admin;
    address private ceo;
    address private cfo;
    address private treeStorage;

    /// LooksCoin contract
    IERC20 public _looksCoin;
    /// LookRevTree contract
    ILookRevTree public _lrTree;
    address[] private treeVersions;
    address[] private tokenVersions;
    
    event CreditRedeemed(
        string indexed str,
        address indexed recipient,
        uint256 indexed amount
    );
    
    event RoleUpdated(
        string indexed str,
        address indexed newaddress
    );

    /// constructor
    constructor() ERC721("LookRev LeafNFT", "LOOKNFT") {
        admin = msg.sender;
    }

    /// @dev Mint yourself a leafNFT
    /// @dev Check averageCost to get cost of leaf on the branch.
    /// This function is going to mint a NFTToken on the open branch of the specified genesis branch.
    /// If the amount sent is more than the cost of the leaf, the remaining amount will be minted into
    /// LooksCoin ERC20 tokens, which will be deposited at the recipient's address.
    /// @param genesisBranch is the id of the genesis branch, new leaf is added to its open branch
    /// @param recipient is the recipient wallet address for receiving ERC721 leafNFT token and
    /// LooksCoin ERC20 tokens.
    function mintLeafNFT(uint256 genesisBranch, address recipient) external payable {
        require(recipient != address(0), "LookRevLeafNFT: recipient needs valid wallet address");
        require(msg.value > averageCost, "LookRevLeafNFT: Amount sent is too small");
        
        _safeMint(recipient, nextTokenId);
        ownerNFTTokens[recipient].push(nextTokenId);
        // Add LooksCoin credits for recipient. Use the redeemCredits method to redeem
        uint256 _creditamt = SafeMath.sub(msg.value, averageCost) + INIT_CREDIT;
        tokenCredits[nextTokenId] = SafeMath.add(tokenCredits[nextTokenId], _creditamt);
        nextTokenId += 1;

        averageCost = _lrTree.addLeafToOpenBranch(genesisBranch, nextTokenId - 1);
    }

    /// @dev Mint leaves on open branches, starting from genesis branches
    /// Can mint up to 10 leafNFT at a time.
    /// @dev Use averageCost to estimate cost of leaf
    /// This function is going to add new leaves on the open branches on the tree
    /// @dev If the amount sent is more than the cost of leaves, the recipient will receive credits
    /// stored in NFTTokens
    /// @param recipient is the recipient wallet address for receiving ERC721 leafNFT token and
    ///  ERC20 LooksCoin tokens.
    function mintLeafNFTTokens(address recipient) external payable {
        require(recipient != address(0), "LookRevLeafNFT: recipient needs valid wallet address");
        require(msg.value > averageCost, "LookRevLeafNFT: Amount sent is too small");
        
        uint256 _creditamt = 0;
        uint256 _count = 0;
        if (msg.value > averageCost * maxBatchCount) {
            _count = maxBatchCount;
            _creditamt = SafeMath.sub(msg.value, averageCost * maxBatchCount);
        } else {
            _count = SafeMath.div(msg.value, averageCost);
            _creditamt = SafeMath.sub(msg.value, _count * averageCost);
        }

        uint256[] memory _tokens = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            ownerNFTTokens[recipient].push(nextTokenId);
            tokenCredits[nextTokenId] = SafeMath.add(tokenCredits[nextTokenId], INIT_CREDIT);
            _tokens[i] = nextTokenId;
            _safeMint(recipient, nextTokenId);
            nextTokenId += 1;
        }
        
        if (_creditamt > 0) {
            tokenCredits[nextTokenId - 1] = SafeMath.add(tokenCredits[nextTokenId - 1], _creditamt);
        }
        
        /// After successfully minted token for user, add them on the tree
        averageCost = _lrTree.addLeavesToOpenBranches(_tokens);
    }

    /// Let token owner to redeem coin credits from credits stored in LeafNFT tokens
    /// @dev Requires refilling the tree escrow as needed
    /// @param recipient is the LeafNFT token owner wallet address
    /// @return uint256 amount of LooksCoin ERC20 token redeemed for token owner
    function redeemCredits(address recipient) external override returns (uint256) {
        require(msg.sender == recipient || msg.sender == admin, "LookRevLeafNFT: Not authorized");
        require(recipient != address(0), "LookRevLeafNFT: recipient needs valid wallet address");
        require(Address.isContract(recipient) == false, "LookRevLeafNFT: recipient can not be a contract");
        uint256[] memory _tokenIDs = ownerNFTTokens[recipient];
        if (_tokenIDs.length < 1) {
            return 0;
        }
        uint256 _amt = 0;
        // prevent reentry
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _c = tokenCredits[_tokenIDs[i]];
            if (_c > 0) {
                tokenCredits[_tokenIDs[i]] = 0;
                _amt = SafeMath.add(_amt, _c);
            }
        }
        if (_amt <= 0) {
            return 0;
        }
        uint256 _coinamt = SafeMath.mul(_amt, COIN_RATE);
        if (_looksCoin.balanceOf(address(this)) >= _coinamt) {
            _looksCoin.transfer(recipient, _coinamt);
            emit CreditRedeemed("Credit Redeemed", recipient, _coinamt);
        } else {
            emit CreditRedeemed("Error redeem credit. Need to refill escrow", msg.sender, _coinamt);
            revert("LookRevLeafNFT: Need to refill tree escrow");
        }
        return _coinamt;
    }
    
    function getNFTTokenRecipient(uint256 tokenID) external override view returns (address) {
        require(tokenID > 0 && tokenID < nextTokenId, "LookRevLeafNFT: tokenID out of range");
        return ERC721.ownerOf(tokenID);
    }
    
    ///===============================
    /// Maintenance methods for admin
    ///===============================
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        ERC721._beforeTokenTransfer(from, to, tokenId);
        if (tokenId < 1 || tokenId >= nextTokenId) {
            return;
        }
        if (from != address(0)) {
            for (uint256 i = 0; i < ownerNFTTokens[from].length; i++) {
                if (ownerNFTTokens[from][i] == tokenId) {
                    delete ownerNFTTokens[from][i];
                }
            }
        }
        if (to != address(0)) {
            ownerNFTTokens[to].push(tokenId);
        }
    }
            
    // Reward contribution for team on off-chain project development
    function rewardTokenID(uint256[] calldata tokenIDs, uint256[] calldata amount) external override {
        require(msg.sender == admin, "LookRevLeafNFT: Not authorized");
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            uint256 _c = tokenIDs[i];
            if(_c > 0 && _c < nextTokenId) {
                tokenCredits[_c] = SafeMath.add(tokenCredits[_c], amount[i]);
            }
        }
    }
        
    /// @dev Set the custom token uri
    function setTokenURI(uint256 tokenId, string memory tokenURI) public {
        require(msg.sender == admin, "LookRevLeafNFT: Not authorized");
        _setTokenURI(tokenId, tokenURI);
    }
    
    /// @dev Withdraw from this contract to fund projects on tree branches
    function withdraw() public {
        require(msg.sender == admin|| msg.sender == ceo || msg.sender == cfo, "LookRevLeafNFT: Not authorized");
        require(treeStorage != address(0), "LookRevLeafNFT: Set storage first");
        payable(treeStorage).transfer(address(this).balance);
    }

    function updateRole(uint256 _role, address _new) public {
        require(msg.sender == admin || msg.sender == ceo || msg.sender == cfo, "LookRevLeafNFT: Not authorized");
        if (_role == 1) {
            admin = _new;
            emit RoleUpdated("admin", _new);
        } else if (_role == 2) {
            ceo = _new;
            emit RoleUpdated("ceo", _new);
        } else if (_role == 3) {
            cfo = _new;
            emit RoleUpdated("cfo", _new);
        } else if (_role == 4) {
            treeStorage = _new;
            emit RoleUpdated("storage", _new);
        } else if (_role == 5) {
            _lrTree = ILookRevTree(_new);
            treeVersions.push(_new);
            emit RoleUpdated("tree", _new);
        }
    }

    function getRoles() public view returns (address[] memory) {
        require(msg.sender == admin || msg.sender == ceo || msg.sender == cfo, "LookRevLeafNFT: Not authorized");
        address[] memory _roles = new address[](5);
        _roles[0] = admin;
        _roles[1] = ceo;
        _roles[2] = cfo;
        _roles[3] = treeStorage;
        _roles[4] = address(_lrTree);
        return _roles;
    }
        
    function updateCoinVersion(address _token, uint256 rate) public {
        require(msg.sender == admin, "LookRevLeafNFT: Not authorized");
        _looksCoin = IERC20(_token);
        tokenVersions.push(_token);
        COIN_RATE = rate;
        emit RoleUpdated("Coin Version Updated", _token);
    }

    function getTreeVersions() public view returns (address[] memory) {
        require(msg.sender == admin, "LookRevLeafNFT: Not authorized");
        return treeVersions;
    }
        
    function getTokenVersions() public view returns (address[] memory) {
        require(msg.sender == admin, "LookRevLeafNFT: Not authorized");
        return tokenVersions;
    }
}