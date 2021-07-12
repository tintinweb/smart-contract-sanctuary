/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC721Metadata).interfaceId
        || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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
    private returns (bool)
    {
        if (to.isContract()) {
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
}

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract SpaceShipsus is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    uint256 public tokenSupply;

    address public DIV_NFT_ADDRESS;
    address public MARKETPLACE_ADDRESS;
    string public constant URI = "https://gateway.pinata.cloud/ipfs/QmZLThHV46SzDFNV92pFJzprudDWGh9tuYxgFJ5PHsoTTX";

    struct ShipInfo {
        address owner;
        address minter;
        uint id;
        uint attack;
        uint gold;
        uint level;
        uint cargo;
        uint life;
        uint energy;
        uint maxEnergy;
        uint battleWon;
        uint battleLost;
        // uint speed;
    }

    uint goldPerLevel = 50;
    uint cargoIncreasePL = 2;
    uint lifeIncreasePL = 3;
    uint attackIncreasePL = 5;
    uint energyIncreasePL = 2;
    /* Only Minted */
    mapping(address => ShipInfo) public allShips;
    mapping(uint => address) public shipIdToAccount;
    mapping(uint => address) public idToAccount;

    mapping(uint => uint) public shipIdToEnergyRefreshCD;

    event NewShipMinted(address _owner, uint256 _tokenId);
    event NFTNotInAccount(address _owner, uint256 _divId);
    event SpeedsterTransfered(address _previousOwner, address _newOwner, uint _tokenID, uint blockNumber, uint timeStamp);

    constructor () ERC721("YoloShips", "Y_SHIP"){
        tokenCounter = 0;
        tokenSupply = 0;
    }

    modifier onlyDiv() {
        require(msg.sender == DIV_NFT_ADDRESS, "UnAuth");
        _;
    }

    modifier onlyMarketplace() {
        require(msg.sender == MARKETPLACE_ADDRESS, "UnAuth");
        _;
    }
 
     uint private unlocked = 1;
    modifier antiReentrant() {
        require(unlocked == 1, 'ERROR: Anti-Reentrant');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    uint public mintPrice = 1e17;

    function create(address _account) external payable antiReentrant() {
        //Must check if has 0!
        
        if (this.balanceOf(_account) == 0 && msg.value == mintPrice) {
                _createShip(_account);
            } else {
                // revert("SpeedNFT not in account !");
                // emit NFTNotInAccount(_account, _divSpotId);
                return;
            }
        
    }

    function createTest() external {
        _createShip(this.owner());
        _createShip(0x20590c641Ac65223f4163870e99cb4f1837f4629);
        _createShip(0xeBE29EBB375E946Dd43f2CeBd76E979a07EB4c77);
    }

    function _createShip(address _account) internal {
        uint newItemId = tokenCounter + 1;

        ShipInfo memory nftInfo = ShipInfo({
        owner : _account,
        minter : _account,
        id : 0,
        level : 1,
        gold : 250,
        cargo : 200,
        life : 800,
        // speed : 500,
        attack : 50,
        energy : 12,
        maxEnergy: 12,
        battleWon: 0,
        battleLost: 0
        });

        allShips[_account] = nftInfo;
        idToAccount[newItemId] = _account;
        shipIdToEnergyRefreshCD[newItemId] = block.number + 28800;
        tokenCounter++;
        tokenSupply++;

        super._safeMint(_account, newItemId);
        super._setTokenURI(newItemId, URI);

        emit NewShipMinted(_account, newItemId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override (ERC721) virtual {
        require(this.balanceOf(to) == 0, "Ownership limited to 1 !");

        super._transfer(from, to, tokenId);

        ShipInfo memory nftInfo = allShips[from];
       
        idToAccount[tokenId] = to;
        delete allShips[from];

        allShips[to].id = nftInfo.id;
        allShips[to].owner = to;

        emit SpeedsterTransfered(from, to, tokenId, block.number, block.timestamp);
    }

    function marketTransfer(address _from, address _to, uint _nftId) public onlyMarketplace {
        _transfer(_from, _to, _nftId);
    }

    function _burn(uint256 tokenId) internal override (ERC721URIStorage) virtual {
        tokenId;
        revert("ERROR_CANT_BURN: Resistant-To-Fire");
    }
    
    
    
    function increaseCargoPerm(uint _amountOfGold) external {
        ShipInfo memory nftInfo = allShips[msg.sender];
        require(_amountOfGold % 10 == 0, "Must be divisable by 10!");
        uint currentGold = nftInfo.gold;
        uint increasedCargo = 5 * _amountOfGold / 10;
        if(currentGold > _amountOfGold){
            nftInfo.cargo += increasedCargo;
            nftInfo.gold -= _amountOfGold;
            allShips[msg.sender] = nftInfo;
        } else {
            revert("No success!");
        }
    }

    function levelUP(uint _amountOfLevels) external antiReentrant returns(uint newLvl){
         
         ShipInfo memory nftInfo = allShips[msg.sender];

         uint currentGold = nftInfo.gold;
         uint goldCost = goldPerLevel * _amountOfLevels;

         //Memory modify here
         if(currentGold >= goldCost) {
             nftInfo.gold -= goldCost;
             nftInfo.level += _amountOfLevels;
             nftInfo.attack += (attackIncreasePL * _amountOfLevels);
             nftInfo.life += (lifeIncreasePL * _amountOfLevels);
             nftInfo.cargo += (cargoIncreasePL * _amountOfLevels);
            //  nftInfo.maxEnergy += (energyIncreasePL * _amountOfLevels);
             //Replace in Storage
             allShips[msg.sender] = nftInfo; 
         }

         return nftInfo.level;
    }
    
    function explorationFlight(uint _energySpent) external antiReentrant returns(uint goldRewarded) {
        ShipInfo memory nftInfo = allShips[msg.sender];
        require(_energySpent == 1 || _energySpent == 2 || _energySpent == 5, "Incorrect energy input!");
        require(_energySpent <= nftInfo.energy, "Insufficient Energy!");        
        
        uint goldRewarFlight = generateChest(_energySpent, msg.sender);
        return goldRewarFlight;
    }

    uint COMMON_WEIGHT = 55;
    uint RARE_WEIGHT = 26;
    uint EPIC_WEIGHT = 15;
    uint LEGENDARY_WEIGHT = 4;

    function generateChest(uint _energySpent, address _account) public returns(uint goldReward) {
        ShipInfo memory nftInfo = allShips[_account];

       bytes32 _structHash;
       uint256 randomNumber;
       bytes32 _blockhash = blockhash(block.number-1);

       //waste some gas fee here
       ShipInfo memory waster;
       for (uint i = 0; i < 9; i++) {
           waster = allShips[_account];
       }
       uint256 gaslefted = gasleft();
       delete waster;

       uint256[] memory outherFactor = new uint256[](4);
       outherFactor[0] = block.difficulty;
       outherFactor[1] = gaslefted;
       outherFactor[2] = nftInfo.attack;
       outherFactor[3] = block.number-1; 

       _structHash = keccak256(
               abi.encode(
                   _blockhash,
                   outherFactor[0],
                   outherFactor[1],
                   outherFactor[2],
                   outherFactor[3]
               )
           );
           uint goldRewards;
           //Short Flight
           if(_energySpent == 1) {
                randomNumber = uint256(_structHash) % 81;
           }
           //Medium Flight
           if(_energySpent == 2) {
                randomNumber = uint256(_structHash) % 96;
           }
           //Long Flight
           if(_energySpent == 5) {
               
                randomNumber = uint256(_structHash) % 100;
           }

            if(_energySpent == 5 && randomNumber < LEGENDARY_WEIGHT) {
              goldRewards = 750;
              nftInfo.gold += 750;
              nftInfo.attack += 5;
              nftInfo.life += 5;
              nftInfo.maxEnergy += 2;
              nftInfo.cargo += 50;
              
           } else if(_energySpent == 2 && randomNumber < EPIC_WEIGHT) {
              goldRewards = 500;
              nftInfo.gold += 500;
              nftInfo.attack += 2;
              nftInfo.life += 2;
              nftInfo.maxEnergy += 1;
              nftInfo.cargo += 20;
           } else if(randomNumber < RARE_WEIGHT) {
              goldRewards = 250;
              nftInfo.gold += 250;
              nftInfo.attack += 3;
              nftInfo.life += 3;
              nftInfo.cargo += 10;
           } else if(randomNumber < COMMON_WEIGHT) {
              goldRewards = 100;
              nftInfo.gold += 100;
              nftInfo.attack += 1;
              nftInfo.life += 1;
           }

           nftInfo.energy -= _energySpent;
           allShips[_account] = nftInfo;
           return goldRewards;
    }

    function attackFlight() external returns(bool winOrNot) {
        
        ShipInfo memory attackerInfo = allShips[msg.sender];

        require(attackerInfo.energy >= 2, "Not enough energy!");

        attackerInfo.energy -= 2;

        address randomDefenderId = getRandomDefender(msg.sender);
        ShipInfo memory defenderInfo = allShips[randomDefenderId];

        uint goldDefender = defenderInfo.gold;
        uint maxPlunderAmount = goldDefender * 2500 / 10000; //25%

        address _winner = fightingSimulator(msg.sender, randomDefenderId);
        if(_winner == msg.sender) {
            if(maxPlunderAmount >= attackerInfo.cargo) {
                attackerInfo.gold += maxPlunderAmount;
                defenderInfo.gold -= maxPlunderAmount;
            } else {
                attackerInfo.gold += attackerInfo.cargo;
                defenderInfo.gold -= attackerInfo.cargo;
            }
            
            attackerInfo.attack++;
            attackerInfo.life++;
            attackerInfo.battleWon++;

            defenderInfo.battleLost++;
            
        } else {
            defenderInfo.battleWon++;
            defenderInfo.gold += 25;
            defenderInfo.life++;
            defenderInfo.attack++;

            attackerInfo.battleLost++;
        }

        allShips[msg.sender] = attackerInfo;
        allShips[randomDefenderId] = defenderInfo;
        return _winner == msg.sender;
    }

    function getRandomDefender(address _attacker) public view returns(address defenderAddress) {
       uint256 randomNumber;
       bytes32 _blockhash = blockhash(block.number-1);

       //waste some gas fee here
       uint e;
       for (uint i = 0; i < 9; i++) {
           e+=2*1/1;
       }
       uint256 gaslefted = gasleft();

       bytes32 _structHash = keccak256(
               abi.encode(
                   _blockhash,
                   gaslefted,
                   block.difficulty,
                   block.number-1
               )
           );

        uint totalSupply1 = this.totalSupply();
        randomNumber = uint256(_structHash) % totalSupply1;

        for(uint i = 0; i < totalSupply1; i++){
            if(idToAccount[randomNumber] != _attacker && idToAccount[randomNumber]!=address(0)) {
               return idToAccount[randomNumber];
            } else {
                 randomNumber++;
            }
        }
    }

    function fightingSimulator(address _attacker, address _defender) internal view returns(address winner){
        ShipInfo memory attackerInfo = allShips[_attacker];
        ShipInfo memory defenderInfo = allShips[_defender];

        uint lifeAttacker = attackerInfo.attack;
        uint attackAttacker = attackerInfo.life;
        uint damageDealtAttacker;

        uint lifeDefender = defenderInfo.life;
        uint attackDefender = defenderInfo.attack;
        uint damageDealtDefender;

        //MAY THE FUN BEGIN
        for(uint i = 0; i < 10; i++){
            bool hitOrMissAttacker = randomHit(i);
            bool hitOrMissDefender = randomHit(i);

            if(hitOrMissAttacker){
                if(lifeDefender <= attackAttacker){
                    return _attacker;
                } else {
                    lifeDefender -= attackAttacker;
                    damageDealtAttacker += attackAttacker;
                }
            }

            if(hitOrMissDefender) {
                if(lifeAttacker <= attackDefender) {
                    return _defender;
                } else {
                    lifeAttacker -= attackDefender;
                    damageDealtDefender += attackDefender;
                }
            }
        }
        bool didAttackerWin = damageDealtAttacker >= damageDealtDefender;
        return didAttackerWin ? _attacker : _defender;
    }

    //True = hit
    //False = miss
    // 1 = attacker
    // 2 = defender
    function randomHit(uint _round) internal view returns (bool didHitOrMiss) {
       uint256 randomNumber;
       bytes32 _blockhash = blockhash(block.number-1);

       uint inc;
       //waste some gas fee here
       for (uint i = 0; i < 9; i++) {
            inc+=1*2+1-1;
       }
       uint256 gaslefted = gasleft();

       bytes32 _structHash = keccak256(
               abi.encode(
                   _blockhash,
                   block.difficulty,
                   gaslefted,
                   _round,
                   block.number-1
               )
           );

        randomNumber = uint256(_structHash);
        return randomNumber % 2 == 1;
    }

    function refreshEnergy() external {
        ShipInfo memory attackerInfo = allShips[msg.sender];
        uint refreshBlock = shipIdToEnergyRefreshCD[allShips[msg.sender].id];
        if(block.number >= refreshBlock) {
            attackerInfo.energy = attackerInfo.maxEnergy;
            shipIdToEnergyRefreshCD[allShips[msg.sender].id] = block.number + 28800;
        } else {
            revert("Need to wait more!");
        }
    }

    function totalSupply() external view returns (uint){
        return tokenSupply;
    }


    function myInfo() external view returns (
        address owner,
        address minter,
        uint id,
        uint attack,
        uint gold,
        uint level,
        uint cargo,
        uint life,
        uint energy,
        uint maxEnergy,
        uint battleWon,
        uint battleLost
    )   {
        ShipInfo memory myShipInfo = allShips[msg.sender];
        return(myShipInfo.owner, myShipInfo.minter, myShipInfo.id, myShipInfo.attack, myShipInfo.gold, myShipInfo.level, myShipInfo.cargo, myShipInfo.life, myShipInfo.energy, myShipInfo.maxEnergy, myShipInfo.battleWon, myShipInfo.battleLost);
    }

    function mplaceInfo(address _account) external onlyMarketplace view returns (
        address owner,
        address minter,
        uint id,
        uint attack,
        uint gold,
        uint level,
        uint cargo,
        uint life,
        uint energy,
        uint maxEnergy,
        uint battleWon,
        uint battleLost
    )   {
        ShipInfo memory myShipInfo = allShips[_account];
        return(myShipInfo.owner, myShipInfo.minter, myShipInfo.id, myShipInfo.attack, myShipInfo.gold, myShipInfo.level, myShipInfo.cargo, myShipInfo.life, myShipInfo.energy, myShipInfo.maxEnergy, myShipInfo.battleWon, myShipInfo.battleLost);
    }

    function getMinter(uint _tokenId) external view returns (address){
        return allShips[idToAccount[_tokenId]].minter;
    }

    // function setDivNftAddress(address _divNftAddress) external onlyOwner {
    //     require(_divNftAddress != address(0), "Zero address !");
    //     DIV_NFT_ADDRESS = _divNftAddress;
    // }

    function setMarketplaceAddress(address _addy) external onlyOwner {
        require(_addy != address(0), "Zero address !");
        MARKETPLACE_ADDRESS = _addy;
    }
    //Deal with BNB
    fallback() external payable {}

    receive() external payable {}
}