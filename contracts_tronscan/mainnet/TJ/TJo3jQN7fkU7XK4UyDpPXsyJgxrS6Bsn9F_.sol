//SourceUnit: MaskPunks.sol

pragma solidity ^0.5.12;

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
contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface ITRC165 {
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
 * Contracts may inherit from this and override {supportsInterface} to declare
 * their support of an interface.
 */
contract TRC165 is ITRC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_TRC165 = 0x01ffc9a7;

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _INTERFACE_ID_TRC165 == interfaceId;
    }
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract ITRC721 is ITRC165 {
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
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
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
    function transferFrom(address from, address to, uint256 tokenId) public;

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
    function approve(address to, uint256 tokenId) public;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view returns (address operator);

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
    function setApprovalForAll(address operator, bool _approved) public;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool);


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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

/**
 * @title TRC-721 Non-Fungible Token Standard, optional enumeration extension
 */
contract ITRC721Enumerable is ITRC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) public view returns (uint256);
}

contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is ITRC721 {

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
 * @title TRC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from TRC721 asset contracts.
 */
contract ITRC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The TRC721 smart contract calls this function on the recipient
     * after a {ITRC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onTRC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the TRC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`
     */
    function onTRC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

/**
 * @title MaskPunks contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract MaskPunks is Ownable, TRC165, ITRC721Enumerable, IERC721Metadata, ReentrancyGuard {

    // Public variables

    // This is the provenance record of all artwork in existence
    // shasum -a256 tron_punks.png
    string public constant PUNKS_PROVENANCE = "683c9ab5430e9cf98450d50590178777c42e5fea54d70cf2f47e4a0bf47eb1f3";
    // shasum -a256 justins.png
    string public constant JUSTIN_PROVENANCE = "b91518027fcb4e74a4ad96262514e2142fb55df01aa0f4877e80cd98c3cd421c";

    uint256 public constant MAX_NFT_SUPPLY = 10000;
    uint256 public constant MAX_SPECIAL_SUPPLY = 11;
    // uint256 public startingIndexBlock;

    // uint256 public startingIndex;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _TRC721_RECEIVED = 0x5175f878;


    event CFOUpdated(address indexed previousCFO, address indexed newCFO);
    event Recovered(address indexed cfo, address indexed token, uint256 indexed amount);

    address public constant APENFT_ADDRESS = address(0x3Dfe637B2b9aE4190A458B5F3EfC1969afE27819);
    uint256 public multiplySpecialPrice = 100;
    uint256 public multiplyTrx2NFT = 20000;

    address payable public _cfo;
    // price in TRX for normal mint one token
    uint256 private _trxPrice = 1000_000000;

    uint256[] private _special_punks;
    // |--240 bits for Special tokens --|-- 16 bits for normal tokens --|
    uint256 private _totalSupply;
    uint256[] private _tokenIdxs;
    // |-- index in user's token list --|-- uint160(user address) --| => tokenId
    mapping(uint256 => uint256) private _userIndexTokens;

    struct IndexOwner {
        uint64 idx;
        address owner;
    }
    // Mapping from token ID to owner address
    mapping(uint256 => IndexOwner) private _owners;
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // TokenURI baseURI
    string public baseURI;

    // for randomized
    uint256[10] private punks_index = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    uint256[10] private punks_index_exists = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    uint256 private punks_index_exists_length = 10;

    uint256 private constant PUNKS_PER_COLUMN = 1000;

    // initialize
    bool private start_sale = false;

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
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_TRC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *
     *     => 0x06fdde03 ^ 0x95d89b41 == 0x93254542
     */
    bytes4 private constant _INTERFACE_ID_TRC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_TRC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        for(uint i = 0; i < MAX_SPECIAL_SUPPLY; ++i){
            _special_punks.push(i + 10000);
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return
        _INTERFACE_ID_TRC721 == interfaceId ||
        _INTERFACE_ID_TRC721_METADATA == interfaceId ||
        _INTERFACE_ID_TRC721_ENUMERABLE == interfaceId ||
        super.supportsInterface(interfaceId);
    }
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "TRC721: balance query for the zero address");
        return _balances[owner];
        //return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toString(tokenId))) : "";
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        uint256 balance = _balances[owner];
        require(index < balance, "index out of range");
        uint256 tokenId = _userIndexTokens[(index << 160) + uint160(owner)];
        return tokenId;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        uint256 total = _totalSupply;
        return (total >> 16) + (total & uint16(-1));
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < _tokenIdxs.length, "TRC721: operator query for nonexistent token");
        return _tokenIdxs[index];
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "TRC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {

        require(_exists(tokenId), "TRC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "TRC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "TRC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "TRC721: transfer caller is not owner nor approved");
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnTRC721Received(from, to, tokenId, _data), "TRC721: transfer to non TRC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId].owner != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "TRC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {

        (uint256 _special, uint256 _normal) = detailSupply();

        if (tokenId < MAX_NFT_SUPPLY){
            require(_normal < MAX_NFT_SUPPLY);
            _normal++;
        }else{
            require(_special < MAX_SPECIAL_SUPPLY);
            _special++;
        }
        _totalSupply = (_special << 16) + _normal;

        _safeMint(to, tokenId, "");

    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {

        _mint(to, tokenId);
        require(_checkOnTRC721Received(address(0), to, tokenId, _data), "TRC721: transfer to non TRC721Receiver implementer");
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
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "TRC721: mint to the zero address");
        require(!_exists(tokenId), "TRC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // |-- index in user's token list --|-- uint160(user address) --| => tokenId
        uint256 _balance = _balances[to];
        _userIndexTokens[(_balance << 160) + uint160(to)] = tokenId;
        _balances[to] = _balance + 1;
        _owners[tokenId] = IndexOwner({ idx: uint64(_balance), owner: to });

        // because no burn function. so no need to record the global index of index
        _tokenIdxs.push(tokenId);

        emit Transfer(address(0), to, tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal {
        IndexOwner memory indexOwner = _owners[tokenId];
        require(indexOwner.owner == from, "TRC721: transfer of token that is not own");
        require(to != address(0), "TRC721: transfer to the zero address");
        uint256 _balance = _balances[from];
        require(_balance > 0, "TRC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        uint256 _idx = indexOwner.idx;
        _balance--;
        uint256 _tmp = 0;
        // not the last one
        if (_idx < _balance){
            // the last index;
            uint256 _key = (_balance << 160) + uint160(from);
            _tmp = _userIndexTokens[_key];
            // |-- index in user's token list --|-- uint160(user address) --| => tokenId
            _userIndexTokens[(_idx << 160) + uint160(from)] = _tmp;
        }
        // this balance is the length of _userIndexTokens[index << 160 + uint160(from)], so _balance - 1 is array.pop()
        _balances[from] = _balance;

        _balance = _balances[to];
        _userIndexTokens[(_balance << 160) + uint160(to)] = tokenId;
        _balances[to] = _balance + 1;
        _owners[tokenId] = IndexOwner({ idx: uint64(_balance), owner: to });

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
    function _checkOnTRC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    internal returns (bool)
    {
         if (!to.isContract) {
             return true;
         }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
                ITRC721Receiver(to).onTRC721Received.selector,
                msg.sender,
                from,
                tokenId,
                _data
            ));
        if (success){
            return (abi.decode(returndata, (bytes4)) == _TRC721_RECEIVED);
        }
        if (returndata.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert("TRC721: transfer to non TRC721Receiver implementer");
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal { }

    // special functions goes from here
    function setTokenURI(string memory _baseURI) onlyOwner public {
        baseURI = _baseURI;
    }

    function setCFO(address CFO) onlyOwner public {
        emit CFOUpdated(_cfo, CFO);
        _cfo = address(uint160(CFO));
    }

    function setMultiply(uint256 trx2NFT, uint256 specialPunk) onlyOwner public {
        if (trx2NFT > 0){
            multiplyTrx2NFT = trx2NFT;
        }
        if (specialPunk > 0){
            multiplySpecialPrice = specialPunk;
        }
    }

    function detailSupply() public view returns (uint256, uint256) {
        uint256 total = _totalSupply;
        return ((total >> 16), (total & uint16(-1)));
    }

    function initializeOwners(address[] memory users, uint256 _column) onlyOwner public {
        require(!start_sale, 'You can not do it when sale is start');

        for(uint256 i = 0; i < users.length; i++){
            uint256 idx = punks_index[_column];
            if(idx >= PUNKS_PER_COLUMN - 1){
                // cannot used all of this column
                break;
            }
            idx = idx + ((_column * PUNKS_PER_COLUMN));

            _safeMint(users[i], idx);
            punks_index[_column] = idx + 1;
        }
    }

    function finishInitializeOwners() onlyOwner public {
        start_sale = true;
    }

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
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function ownersOf(uint256[] memory indexes) public view returns (address[] memory) {
        uint len = indexes.length;
        require(len > 0);
        address[] memory addrList = new address[](len);
        for(uint i = 0; i < len; ++i){
            addrList[i] = _owners[indexes[i]].owner;
        }
        return addrList;
    }

    /**
     * @dev return tokensOfOwnerFromStart}.
     */
    function tokensOfOwnerFromStart(address owner, uint256 start_index, uint256 page_size) public view
        returns
    (uint256 total, uint256[] memory tokenIds) {
        require(page_size > 0 && page_size <= 1000, "index out of range");
        uint256 balance = _balances[owner];
        total = balance;
        if((balance > 0 || start_index > 0) && start_index < balance){
            // [start_index, end_index), end_index is not included
            balance = (balance <= (start_index + page_size) ? balance : (start_index + page_size));

            tokenIds = new uint256[](balance - start_index);
            for(uint i = start_index; i < balance; ++i){
                tokenIds[i - start_index] = _userIndexTokens[(i << 160) + uint160(owner)];
            }
        }
    }

    /**
     * @dev Gets current MaskPunk Price
     */
    function getNormalTrxPrice() public view returns (uint256) {
        return _trxPrice;
    }

    /**
     * @dev Gets current MaskPunk Price
     */
    function getNormalNFTPrice() public view returns (uint256) {
        return _trxPrice * multiplyTrx2NFT;
    }

    /**
     * @dev Gets current MaskPunk Price
     */
    function getSpecialTrxPrice() public view returns (uint256) {
        return _trxPrice * multiplySpecialPrice;
    }

    /**
    * @dev Mints MaskPunk
    */
    function mintNormal(uint256 number) nonReentrant public payable {
        require(start_sale, 'sale is not start');
        require(number > 0 && number <= 20, "You may not buy more than 20 NFTs at once");
        (uint256 _special, uint256 _normal) = detailSupply();
        require(_normal + number <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");

        uint256 msgValue = msg.value;
        if (msgValue > 0){
            uint256 _fee = _trxPrice * number;
            require(_fee <= msgValue, "Trx value sent is not correct");
            if (_fee < msgValue){
                address(uint160(msg.sender)).transfer(msgValue - _fee);
            }
        }else{
            uint256 _fee = _trxPrice * multiplyTrx2NFT * number;
            // 0x23b872dd7302113369cda2901243429419bec145408fa8b352b3dd92b66c680b = keccak256(bytes('transferFrom(address,address,uint256)'))
            // 0x23b872dd = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
            (bool success, bytes memory data) = address(APENFT_ADDRESS).call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), _fee));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'mintNormal: TRANSFER_FROM_FAILED');
        }

        for (uint i = 0; i < number; i++) {
            uint256 mintIndex = getNextPunkIndex();
            _safeMint(msg.sender, mintIndex, "");
        }

        if (_normal % 1000 > (_normal + number) % 1000){
            _trxPrice += 100_000000;
        }

        _totalSupply = (_special << 16) + _normal + number;
    }

    /**
    * @dev Mints MaskPunk
    */
    function mintSpecial() nonReentrant public payable returns (bool){
        require(start_sale, 'sale is not start');
        (uint256 _special, uint256 _normal) = detailSupply();
        require(_special < MAX_SPECIAL_SUPPLY, "Exceeds MAX_SPECIAL_SUPPLY");
        require(_normal >= MAX_NFT_SUPPLY * 800 / 1000, "still not ready to mint special");
        uint256 _random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));

        uint256 _fee = _trxPrice * multiplySpecialPrice;
        uint256 msgValue = msg.value;
        require(_fee <= msgValue, "Trx value sent is not correct");
        if (_fee < msgValue){
            address(uint160(msg.sender)).transfer(msgValue - _fee);
        }

        uint len = _special_punks.length;
        uint n = _random % len;

        _safeMint(msg.sender, _special_punks[n], "");
        len--;
        if (n != len){
            _special_punks[n] = _special_punks[len];
        }
        _special_punks.pop();

        _totalSupply = ((_special + 1) << 16) + _normal;

        return true;
    }

    function getNextPunkIndex() private returns(uint256) {

        uint256 n = 0;
        if (punks_index_exists_length > 1){
            n = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % punks_index_exists_length;
        }
        uint256 row_num = punks_index_exists[n];
        uint256 idx_in_row = punks_index[row_num];

        require(punks_index_exists_length >= 1 && idx_in_row < PUNKS_PER_COLUMN, "all item used!");
        idx_in_row++;
        punks_index[row_num] = idx_in_row;

        if (idx_in_row >= PUNKS_PER_COLUMN){
            uint tail = punks_index_exists_length - 1;
            punks_index_exists_length = tail;
            if (n < tail){
                punks_index_exists[n] = punks_index_exists[tail];
            }
        }
        return (row_num * PUNKS_PER_COLUMN + idx_in_row - 1);
    }

    // Added to support recovering TRX to be distributed to holders
    function recoverTRX(uint256 value) external {
        require(_cfo != address(0), "cfo is empty");
        //require(owner == msg.sender || _cfo == msg.sender, "Ownable: caller is not the owner");
        _cfo.transfer(value);
        emit Recovered(_cfo, address(0), value);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverTRC20(address token, uint256 value) external {
        require(_cfo != address(0), "cfo is empty");
        require(token != address(this));
        // 0xa9059cbb2ab09eb219583f4a59a5d0623ade346d962bcd4e46b11da047c9049b == keccak256(bytes('transfer(address,uint256)'))
        // 0xa9059cbb = bytes4(keccak256(bytes('transfer(address,uint256)')));
        token.call(abi.encodeWithSelector(0xa9059cbb, _cfo, value));
        emit Recovered(_cfo, token, value);
    }

}