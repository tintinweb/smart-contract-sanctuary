/**
 *Submitted for verification at BscScan.com on 2021-10-10
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

       return 'https://gateway.pinata.cloud/ipfs/QmVefgQHhFKcUEqdHQPfcZVhQCo3rcXDzrPsG6KmyuYz1h';
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract YoloShips is ERC721URIStorage, Ownable {
   uint256 public tokenCounter;
   
   string public constant URI = "https://gateway.pinata.cloud/ipfs/QmVefgQHhFKcUEqdHQPfcZVhQCo3rcXDzrPsG6KmyuYz1h";
   uint refreshRate = 30 minutes;
   uint goldRate = 1 hours;
   uint public mintPrice = 500e18;
   address public currentTopLevelAcc;
   uint public currentTopLevel;
   address public currentTopBpAcc;
   uint public currentTopBp;
   uint public fightId;
   uint public startTimeStamp;
   
   bool public hasStarted;
   struct ShipInfo {
       address owner;
       uint id;
       uint attack;
       uint gold;
       uint level;
       uint energy;
       uint maxEnergy;
       uint battleWon;
       uint battleLost;
       uint battlePoints;
   }

   /* Only Minted */
   mapping(address => ShipInfo) internal allShips;
   mapping(uint => address) internal idToAccount;

   //Timestamp
   mapping(uint => uint) public shipIdToEnergyRefreshCD;
   mapping(uint => uint) public shipIdToLastBattleBlock;
   mapping(uint => uint) public shipIdToLastGold;
   //ID - Type Of Chest - Number of times found
   mapping(uint => mapping(uint => uint)) internal shipIdToChestsFound;

   event ShipTransferred(address _previousOwner, address _newOwner, uint _tokenID, uint blockNumber, uint timeStamp);
   event EndFightResult(uint fightId, address attacker, address defender, address winner, uint battlepoint, uint goldAwarded);
   event ChestGeneration(uint tokenid, uint rand, uint chest);
   
   constructor () ERC721("YoloShip", "YoloShip"){
       tokenCounter = 0;
       startTimeStamp = block.timestamp;
       hasStarted = false;
   }

   uint private unlocked = 1;
   modifier antiReentrant() {
       require(unlocked == 1, 'ERROR: Anti-Reentrant');
       unlocked = 0;
       _;
       unlocked = 1;
   }

   modifier noInstantCheck(uint id) {
       require(block.number > shipIdToLastBattleBlock[id], "Can't Look in same block");
       _;
   }

   function create() external antiReentrant() {
       require(isOpen(), "Season Closed!");
       if (this.balanceOf(msg.sender) == 0) {
           IERC20(0xD084C5a4a621914eD2992310024d2438DFde5BfD).transferFrom(msg.sender, 0x625470be1D57f5d584142Faf23263330D4FD287E, mintPrice);
               _createShip(msg.sender);
           } else {
               revert("Already has ship");
           }
   }

   function _createShip(address _account) internal {
       uint newItemId = tokenCounter + 1;

       ShipInfo memory nftInfo = ShipInfo({
       owner : _account,
       id : newItemId,
       level : 1,
       gold : 100,
       attack : 15,
       energy : 10,
       maxEnergy: 15,
       battleWon: 0,
       battleLost: 0,
       battlePoints : 0
       });
       shipIdToEnergyRefreshCD[newItemId] = block.timestamp;
       shipIdToLastBattleBlock[newItemId] = block.number;
       shipIdToLastGold[newItemId] = block.timestamp;
       allShips[_account] = nftInfo;
       idToAccount[newItemId] = _account;
       tokenCounter++;

       super._safeMint(_account, newItemId);
       super._setTokenURI(newItemId, URI);
   }


   function getNextLevelCost(address _account) public view returns(uint levelCost, uint levelNext) {
        uint nextLevel =  allShips[_account].level + 1;
        return(nextLevel * 50, nextLevel);
   }

   function levelUP() external antiReentrant returns(uint newLvl){
        require(isOpen(), "Season Closed!");
        ShipInfo memory nftInfo = allShips[msg.sender];

        (uint goldCost, uint nextLevel) = getNextLevelCost(msg.sender);
        
        if(nftInfo.gold >= goldCost) {

            nftInfo.gold -= goldCost;
            nftInfo.level = nextLevel;

            if(nftInfo.level > 25) {
               nftInfo.attack += 15;
            } else {
               nftInfo.attack += 5;
            }
            
            if(nftInfo.level % 5 == 0) {
                nftInfo.maxEnergy++;
                nftInfo.attack += 5;
            }
            
           if(nftInfo.level > currentTopLevel) {
               currentTopLevelAcc = nftInfo.owner;
               currentTopLevel = nftInfo.level;
           }
            //Replace in Storage
           allShips[msg.sender] = nftInfo;
           return nftInfo.level;
        } else {
            revert("Not Enough Gold");
        }
   }

   function explorationFlight() external antiReentrant returns(uint goldRewarded) {
       require(isOpen(), "Season Closed!");
       ShipInfo memory nftInfo = allShips[msg.sender];
       require(3 <= nftInfo.energy, "Insufficient Energy!");
       require(shipIdToLastBattleBlock[nftInfo.id] < block.number, "1 per block");
       shipIdToLastBattleBlock[nftInfo.id] = block.number;
       generateChest(msg.sender);
       return allShips[msg.sender].gold - nftInfo.gold;
   }

   function generateChest(address _account) internal {
        ShipInfo memory _nftInfo = allShips[_account];

        uint256 randomNumber;
        bytes32 _structHash = keccak256(
              abi.encode(
                  blockhash(block.number-1),
                  gasleft(),
                  block.number,
                  _nftInfo.attack,
                  _account
              )
          );
     
          randomNumber = uint256(_structHash) % 100;
          
          if(randomNumber <= 5) {
             _nftInfo.gold += 300;
             _nftInfo.attack += 4;
             _nftInfo.maxEnergy += 2;
             shipIdToChestsFound[_nftInfo.id][3]++;
             emit ChestGeneration(_nftInfo.id, randomNumber, 1);
          } else if(randomNumber <= 25) {
             _nftInfo.gold += 150;
             _nftInfo.attack += 3;
             _nftInfo.maxEnergy++;
             shipIdToChestsFound[_nftInfo.id][2]++;
             emit ChestGeneration(_nftInfo.id, randomNumber, 1);
          } else {
             _nftInfo.gold += 100;
             _nftInfo.attack++;
             shipIdToChestsFound[_nftInfo.id][1]++;
             emit ChestGeneration(_nftInfo.id, randomNumber, 1);
          }
        
          _nftInfo.energy -= 3;
          allShips[_account] = _nftInfo;
   }

   function attackFlight() external antiReentrant {
       require(isOpen(), "Season Closed!");
       ShipInfo memory attackerInfo = allShips[msg.sender];

       require(attackerInfo.energy >= 2, "Not enough energy!");

       attackerInfo.energy -= 2;
       shipIdToLastBattleBlock[attackerInfo.id] = block.number; 

       uint256 randomNumber;

          bytes32 _structHash = keccak256(
                  abi.encode(
                      gasleft(),
                      msg.sender,
                      blockhash(block.number-1),
                      block.number
                  )
              );
    
           uint totalSupply1 = tokenCounter;
           randomNumber = (uint256(_structHash) % totalSupply1) + 1;
    
           uint incr = 1;
           while(idToAccount[randomNumber] == msg.sender) {
    
               bytes32 _structHash1 = keccak256(
                  abi.encode(
                      randomNumber + incr,
                      blockhash(block.number-incr)
                  )
                );
    
                randomNumber = (uint256(_structHash1) % totalSupply1) + 1;
                incr++;
           }
      
       ShipInfo memory defenderInfo = allShips[idToAccount[randomNumber]];

       uint plunderAmt = defenderInfo.gold >= 4 ? defenderInfo.gold * 2500 / 10000 : 0; //25%
       address _winner = attackerInfo.attack >= defenderInfo.attack ? msg.sender : defenderInfo.owner;
       
       
      if(_winner == msg.sender) {
        
          attackerInfo.gold += plunderAmt;
          defenderInfo.gold -= plunderAmt;
          attackerInfo.battlePoints += attackerInfo.attack;
           
          attackerInfo.attack += 2;
          attackerInfo.battleWon++;
         
           
          if(attackerInfo.battleWon % 3 == 0) attackerInfo.maxEnergy++;
          if(attackerInfo.battlePoints > currentTopBp) {
             currentTopBpAcc = _winner;
             currentTopBp = attackerInfo.battlePoints;
          }
           
          defenderInfo.battleLost++;
          fightId++;
          emit EndFightResult(fightId, msg.sender, defenderInfo.owner, msg.sender, attackerInfo.attack, plunderAmt);
      } else {
           
          defenderInfo.gold += 25;
          defenderInfo.battlePoints += defenderInfo.attack;
          defenderInfo.attack++;
          defenderInfo.battleWon++;
         

          if(defenderInfo.battleWon % 3 == 0) defenderInfo.maxEnergy++;
          if(defenderInfo.battlePoints > currentTopBp) {
             currentTopBpAcc = _winner;
             currentTopBp = defenderInfo.battlePoints;
          }
           
          attackerInfo.battleLost++;
          fightId++;
          emit EndFightResult(fightId, msg.sender, defenderInfo.owner, defenderInfo.owner, defenderInfo.attack, 25);
      }
       
       allShips[msg.sender] = attackerInfo;
       allShips[defenderInfo.owner] = defenderInfo;
   }

   function getAmountOfEnergyRefresh(address _account) external view returns(uint enrgyAmt){

       ShipInfo memory attackerInfo = allShips[_account];
       uint lastRefreshTimestamp = shipIdToEnergyRefreshCD[attackerInfo.id];
       uint passedTimeSinceLastRefresh = block.timestamp - lastRefreshTimestamp;
       if(passedTimeSinceLastRefresh < refreshRate) return 0;
       uint energyRefreshAmount;
       
       for(uint i = lastRefreshTimestamp; i <= block.timestamp; i += refreshRate) {
           if(energyRefreshAmount + attackerInfo.energy < attackerInfo.maxEnergy){
               energyRefreshAmount++;
           }
       }
       return energyRefreshAmount;
   }

   function refreshEnergy() external antiReentrant {
       require(isOpen(), "Season Closed!");
       ShipInfo memory attackerInfo = allShips[msg.sender];

       uint pendingEnergy = this.getAmountOfEnergyRefresh(msg.sender);
       require(pendingEnergy > 0, "Not yet");

       attackerInfo.energy += pendingEnergy;
       shipIdToEnergyRefreshCD[attackerInfo.id] = block.timestamp;
       allShips[msg.sender] = attackerInfo;
   }
   
   function pendingGold(address _acc) external view returns(uint goldPending) {
        ShipInfo memory attackerInfo = allShips[_acc];
        uint lastGoldTimestamp = shipIdToLastGold[attackerInfo.id];
        uint passedTimeSinceLastClaim = block.timestamp - lastGoldTimestamp;
        if(passedTimeSinceLastClaim < refreshRate) return 0;
        uint _gold;
        uint _scale = 20 + (attackerInfo.level * 2);
        for(uint i = lastGoldTimestamp; i <= block.timestamp; i += goldRate) {
            _gold += _scale;
        }
        
        return _gold;
   }
   
   function claimGold() external antiReentrant {
        require(isOpen(), "Season Closed!");
        ShipInfo memory ship = allShips[msg.sender];
    
        uint pending = this.pendingGold(msg.sender);
        require(pending > 0, "Not yet");
        ship.gold += pending;
        shipIdToLastGold[ship.id] = block.timestamp;
        allShips[msg.sender] = ship;
   }

   function totalSupply() external view returns (uint){
       return tokenCounter;
   }
   
   function chestsCommonFoundByShip(uint256 tokenId) external view noInstantCheck(tokenId) returns(uint256 timesFoundC) {
       return shipIdToChestsFound[tokenId][1];
   }
   
   function chestsRareFoundByShip(uint256 tokenId) external view noInstantCheck(tokenId) returns(uint256 timesFoundR) {
       return shipIdToChestsFound[tokenId][2];
   }
   
   function chestsEpicFoundByShip(uint256 tokenId) external view noInstantCheck(tokenId) returns(uint256 timesFoundE) {
       return shipIdToChestsFound[tokenId][3];
   }
   
   function _transfer(address from, address to, uint256 tokenId) internal override (ERC721) virtual {
       require(this.balanceOf(to) == 0, "Ownership limited to 1 !");

       super._transfer(from, to, tokenId);

       ShipInfo memory nftInfo = allShips[from];

       idToAccount[tokenId] = to;
       delete allShips[from];

       allShips[to].id = nftInfo.id;
       allShips[to].owner = to;

       emit ShipTransferred(from, to, tokenId, block.number, block.timestamp);
   }

   function _burn(uint256 tokenId) internal override (ERC721URIStorage) virtual {
       tokenId;
       revert("ERROR_CANT_BURN: Resistant-To-Fire");
   }
    
   function isOpen() public view returns(bool openOrNot){
       return block.timestamp < startTimeStamp + 2 weeks && hasStarted;
   }
   
   function startSeason() external {
       require(msg.sender == owner(), "Error0");
       require(hasStarted == false, "Error1");
       hasStarted = true;
   }
   
   function myInfo() external view noInstantCheck(allShips[msg.sender].id) returns(
       uint attack,
       uint gold,
       uint level,
       uint energy,
       uint maxEnergy,
       uint battleWon,
       uint battleLost,
       uint battlePoints
   )   {
       ShipInfo memory myShipInfo = allShips[msg.sender];
       return(myShipInfo.attack, myShipInfo.gold, myShipInfo.level, myShipInfo.energy, myShipInfo.maxEnergy, myShipInfo.battleWon, myShipInfo.battleLost, myShipInfo.battlePoints);
   }

   //Deal with BNB
   fallback() external payable {}
   receive() external payable {}
}