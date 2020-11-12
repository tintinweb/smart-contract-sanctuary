pragma solidity ^0.5.0;

contract BuilderShop {
   address[] builderInstances;
   uint contractId = 0;

   //nifty registry is hard coded
   address niftyRegistryContract = 0x6e53130dDfF21E3BC963Ee902005223b9A202106;

   modifier onlyValidSender() {
       NiftyRegistry nftg_registry = NiftyRegistry(niftyRegistryContract);
       bool is_valid = nftg_registry.isValidNiftySender(msg.sender);
       require(is_valid==true);
       _;
   }

   mapping (address => bool) public BuilderShops;

   function isValidBuilderShop(address builder_shop) public view returns (bool isValid) {
       //public function, allowing anyone to check if a contract address is a valid nifty gateway contract
       return(BuilderShops[builder_shop]);
   }

   event BuilderInstanceCreated(address new_contract_address, uint contractId);

   function createNewBuilderInstance(
       string memory _name,
       string memory _symbol,
       uint num_nifties,
       string memory token_base_uri,
       string memory creator_name)
       public returns (NiftyBuilderInstance tokenAddress) { // <- must replace this !!!
   //public onlyValidSender returns (NiftyBuilderInstance tokenAddress) {

       contractId = contractId + 1;

       NiftyBuilderInstance new_contract = new NiftyBuilderInstance(
           _name,
           _symbol,
           contractId,
           num_nifties,
           token_base_uri,
           creator_name
       );

       address externalId = address(new_contract);

       BuilderShops[externalId] = true;

       emit BuilderInstanceCreated(externalId, contractId);

       return (new_contract);
    }
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
contract Context {
   // Empty internal constructor, to prevent people from mistakenly deploying
   // an instance of this contract, which should be used via inheritance.
   constructor () internal { }
   // solhint-disable-previous-line no-empty-blocks

   function _msgSender() internal view returns (address payable) {
       return msg.sender;
   }

   function _msgData() internal view returns (bytes memory) {
       this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
       return msg.data;
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
* Contracts may inherit from this and call {_registerInterface} to declare
* their support of an interface.
*/
contract ERC165 is IERC165 {
   /*
    * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
    */
   bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

   /**
    * @dev Mapping of interface ids to whether or not it's supported.
    */
   mapping(bytes4 => bool) private _supportedInterfaces;

   constructor () internal {
       // Derived contracts need only register support for their own interfaces,
       // we register support for ERC165 itself here
       _registerInterface(_INTERFACE_ID_ERC165);
   }

   /**
    * @dev See {IERC165-supportsInterface}.
    *
    * Time complexity O(1), guaranteed to always use less than 30 000 gas.
    */
   function supportsInterface(bytes4 interfaceId) external view returns (bool) {
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
   function _registerInterface(bytes4 interfaceId) internal {
       require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
       _supportedInterfaces[interfaceId] = true;
   }
}

/**
* @dev Required interface of an ERC721 compliant contract.
*/
contract IERC721 is IERC165 {
   event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
   event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
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
    * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
    * another (`to`).
    *
    *
    *
    * Requirements:
    * - `from`, `to` cannot be zero.
    * - `tokenId` must be owned by `from`.
    * - If the caller is not `from`, it must be have been allowed to move this
    * NFT by either {approve} or {setApprovalForAll}.
    */
   function safeTransferFrom(address from, address to, uint256 tokenId) public;
   /**
    * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
    * another (`to`).
    *
    * Requirements:
    * - If the caller is not `from`, it must be approved to move this NFT by
    * either {approve} or {setApprovalForAll}.
    */
   function transferFrom(address from, address to, uint256 tokenId) public;
   function approve(address to, uint256 tokenId) public;
   function getApproved(uint256 tokenId) public view returns (address operator);

   function setApprovalForAll(address operator, bool _approved) public;
   function isApprovedForAll(address owner, address operator) public view returns (bool);


   function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

/**
* @title ERC721 token receiver interface
* @dev Interface for any contract that wants to support safeTransfers
* from ERC721 asset contracts.
*/
contract IERC721Receiver {
   /**
    * @notice Handle the receipt of an NFT
    * @dev The ERC721 smart contract calls this function on the recipient
    * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
    * otherwise the caller will revert the transaction. The selector to be
    * returned can be obtained as `this.onERC721Received.selector`. This
    * function MAY throw to revert and reject the transfer.
    * Note: the ERC721 contract address is always the message sender.
    * @param operator The address which called `safeTransferFrom` function
    * @param from The address which previously owned the token
    * @param tokenId The NFT identifier which is being transferred
    * @param data Additional data with no specified format
    * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    */
   function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
   public returns (bytes4);
}

/**
* @title ERC721 Non-Fungible Token Standard basic implementation
* @dev see https://eips.ethereum.org/EIPS/eip-721
*/
contract ERC721 is Context, ERC165, IERC721 {
   using SafeMath for uint256;
   using Address for address;
   using Counters for Counters.Counter;

   // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
   bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

   // Mapping from token ID to owner
   mapping (uint256 => address) private _tokenOwner;

   // Mapping from token ID to approved address
   mapping (uint256 => address) private _tokenApprovals;

   // Mapping from owner to number of owned token
   mapping (address => Counters.Counter) private _ownedTokensCount;

   // Mapping from owner to operator approvals
   mapping (address => mapping (address => bool)) private _operatorApprovals;

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

   constructor () public {
       // register the supported interfaces to conform to ERC721 via ERC165
       _registerInterface(_INTERFACE_ID_ERC721);
   }

   /**
    * @dev Gets the balance of the specified address.
    * @param owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
   function balanceOf(address owner) public view returns (uint256) {
       require(owner != address(0), "ERC721: balance query for the zero address");

       return _ownedTokensCount[owner].current();
   }

   /**
    * @dev Gets the owner of the specified token ID.
    * @param tokenId uint256 ID of the token to query the owner of
    * @return address currently marked as the owner of the given token ID
    */
   function ownerOf(uint256 tokenId) public view returns (address) {
       address owner = _tokenOwner[tokenId];
       require(owner != address(0), "ERC721: owner query for nonexistent token");

       return owner;
   }

   /**
    * @dev Approves another address to transfer the given token ID
    * The zero address indicates there is no approved address.
    * There can only be one approved address per token at a given time.
    * Can only be called by the token owner or an approved operator.
    * @param to address to be approved for the given token ID
    * @param tokenId uint256 ID of the token to be approved
    */
   function approve(address to, uint256 tokenId) public {
       address owner = ownerOf(tokenId);
       require(to != owner, "ERC721: approval to current owner");

       require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
           "ERC721: approve caller is not owner nor approved for all"
       );

       _tokenApprovals[tokenId] = to;
       emit Approval(owner, to, tokenId);
   }

   /**
    * @dev Gets the approved address for a token ID, or zero if no address set
    * Reverts if the token ID does not exist.
    * @param tokenId uint256 ID of the token to query the approval of
    * @return address currently approved for the given token ID
    */
   function getApproved(uint256 tokenId) public view returns (address) {
       require(_exists(tokenId), "ERC721: approved query for nonexistent token");

       return _tokenApprovals[tokenId];
   }

   /**
    * @dev Sets or unsets the approval of a given operator
    * An operator is allowed to transfer all tokens of the sender on their behalf.
    * @param to operator address to set the approval
    * @param approved representing the status of the approval to be set
    */
   function setApprovalForAll(address to, bool approved) public {
       require(to != _msgSender(), "ERC721: approve to caller");

       _operatorApprovals[_msgSender()][to] = approved;
       emit ApprovalForAll(_msgSender(), to, approved);
   }

   /**
    * @dev Tells whether an operator is approved by a given owner.
    * @param owner owner address which you want to query the approval of
    * @param operator operator address which you want to query the approval of
    * @return bool whether the given operator is approved by the given owner
    */
   function isApprovedForAll(address owner, address operator) public view returns (bool) {
       return _operatorApprovals[owner][operator];
   }

   /**
    * @dev Transfers the ownership of a given token ID to another address.
    * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
    * Requires the msg.sender to be the owner, approved, or operator.
    * @param from current owner of the token
    * @param to address to receive the ownership of the given token ID
    * @param tokenId uint256 ID of the token to be transferred
    */
   function transferFrom(address from, address to, uint256 tokenId) public {
       //solhint-disable-next-line max-line-length
       require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

       _transferFrom(from, to, tokenId);
   }

   /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * Requires the msg.sender to be the owner, approved, or operator
    * @param from current owner of the token
    * @param to address to receive the ownership of the given token ID
    * @param tokenId uint256 ID of the token to be transferred
    */
   function safeTransferFrom(address from, address to, uint256 tokenId) public {
       safeTransferFrom(from, to, tokenId, "");
   }

   /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * Requires the _msgSender() to be the owner, approved, or operator
    * @param from current owner of the token
    * @param to address to receive the ownership of the given token ID
    * @param tokenId uint256 ID of the token to be transferred
    * @param _data bytes data to send along with a safe transfer check
    */
   function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
       require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
       _safeTransferFrom(from, to, tokenId, _data);
   }

   /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * If the target address is a contract, it must implement `onERC721Received`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * Requires the msg.sender to be the owner, approved, or operator
    * @param from current owner of the token
    * @param to address to receive the ownership of the given token ID
    * @param tokenId uint256 ID of the token to be transferred
    * @param _data bytes data to send along with a safe transfer check
    */
   function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
       _transferFrom(from, to, tokenId);
       require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
   }

   /**
    * @dev Returns whether the specified token exists.
    * @param tokenId uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
   function _exists(uint256 tokenId) internal view returns (bool) {
       address owner = _tokenOwner[tokenId];
       return owner != address(0);
   }

   /**
    * @dev Returns whether the given spender can transfer a given token ID.
    * @param spender address of the spender to query
    * @param tokenId uint256 ID of the token to be transferred
    * @return bool whether the msg.sender is approved for the given token ID,
    * is an operator of the owner, or is the owner of the token
    */
   function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
       require(_exists(tokenId), "ERC721: operator query for nonexistent token");
       address owner = ownerOf(tokenId);
       return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
   }

   /**
    * @dev Internal function to safely mint a new token.
    * Reverts if the given token ID already exists.
    * If the target address is a contract, it must implement `onERC721Received`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * @param to The address that will own the minted token
    * @param tokenId uint256 ID of the token to be minted
    */
   function _safeMint(address to, uint256 tokenId) internal {
       _safeMint(to, tokenId, "");
   }

   /**
    * @dev Internal function to safely mint a new token.
    * Reverts if the given token ID already exists.
    * If the target address is a contract, it must implement `onERC721Received`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * @param to The address that will own the minted token
    * @param tokenId uint256 ID of the token to be minted
    * @param _data bytes data to send along with a safe transfer check
    */
   function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
       _mint(to, tokenId);
       require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
   }

   /**
    * @dev Internal function to mint a new token.
    * Reverts if the given token ID already exists.
    * @param to The address that will own the minted token
    * @param tokenId uint256 ID of the token to be minted
    */
   function _mint(address to, uint256 tokenId) internal {
       require(to != address(0), "ERC721: mint to the zero address");
       require(!_exists(tokenId), "ERC721: token already minted");

       _tokenOwner[tokenId] = to;
       _ownedTokensCount[to].increment();

       emit Transfer(address(0), to, tokenId);
   }

   /**
    * @dev Internal function to burn a specific token.
    * Reverts if the token does not exist.
    * Deprecated, use {_burn} instead.
    * @param owner owner of the token to burn
    * @param tokenId uint256 ID of the token being burned
    */
   function _burn(address owner, uint256 tokenId) internal {
       require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

       _clearApproval(tokenId);

       _ownedTokensCount[owner].decrement();
       _tokenOwner[tokenId] = address(0);

       emit Transfer(owner, address(0), tokenId);
   }

   /**
    * @dev Internal function to burn a specific token.
    * Reverts if the token does not exist.
    * @param tokenId uint256 ID of the token being burned
    */
   function _burn(uint256 tokenId) internal {
       _burn(ownerOf(tokenId), tokenId);
   }

   /**
    * @dev Internal function to transfer ownership of a given token ID to another address.
    * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
    * @param from current owner of the token
    * @param to address to receive the ownership of the given token ID
    * @param tokenId uint256 ID of the token to be transferred
    */
   function _transferFrom(address from, address to, uint256 tokenId) internal {
       require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
       require(to != address(0), "ERC721: transfer to the zero address");

       _clearApproval(tokenId);

       _ownedTokensCount[from].decrement();
       _ownedTokensCount[to].increment();

       _tokenOwner[tokenId] = to;

       emit Transfer(from, to, tokenId);
   }

   /**
    * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
    * The call is not executed if the target address is not a contract.
    *
    * This function is deprecated.
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

       bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
       return (retval == _ERC721_RECEIVED);
   }

   /**
    * @dev Private function to clear current approval of a given token ID.
    * @param tokenId uint256 ID of the token to be transferred
    */
   function _clearApproval(uint256 tokenId) private {
       if (_tokenApprovals[tokenId] != address(0)) {
           _tokenApprovals[tokenId] = address(0);
       }
   }
}

/**
* @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
* @dev See https://eips.ethereum.org/EIPS/eip-721
*/
contract IERC721Enumerable is IERC721 {
   function totalSupply() public view returns (uint256);
   function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

   function tokenByIndex(uint256 index) public view returns (uint256);
}

/**
* @title ERC-721 Non-Fungible Token with optional enumeration extension logic
* @dev See https://eips.ethereum.org/EIPS/eip-721
*/
contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
   // Mapping from owner to list of owned token IDs
   mapping(address => uint256[]) private _ownedTokens;

   // Mapping from token ID to index of the owner tokens list
   mapping(uint256 => uint256) private _ownedTokensIndex;

   // Array with all token ids, used for enumeration
   uint256[] private _allTokens;

   // Mapping from token id to position in the allTokens array
   mapping(uint256 => uint256) private _allTokensIndex;

   /*
    *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
    *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
    *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
    *
    *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
    */
   bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

   /**
    * @dev Constructor function.
    */
   constructor () public {
       // register the supported interface to conform to ERC721Enumerable via ERC165
       _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
   }

   /**
    * @dev Gets the token ID at a given index of the tokens list of the requested owner.
    * @param owner address owning the tokens list to be accessed
    * @param index uint256 representing the index to be accessed of the requested tokens list
    * @return uint256 token ID at the given index of the tokens list owned by the requested address
    */
   function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
       require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
       return _ownedTokens[owner][index];
   }

   /**
    * @dev Gets the total amount of tokens stored by the contract.
    * @return uint256 representing the total amount of tokens
    */
   function totalSupply() public view returns (uint256) {
       return _allTokens.length;
   }

   /**
    * @dev Gets the token ID at a given index of all the tokens in this contract
    * Reverts if the index is greater or equal to the total number of tokens.
    * @param index uint256 representing the index to be accessed of the tokens list
    * @return uint256 token ID at the given index of the tokens list
    */
   function tokenByIndex(uint256 index) public view returns (uint256) {
       require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
       return _allTokens[index];
   }

   /**
    * @dev Internal function to transfer ownership of a given token ID to another address.
    * As opposed to transferFrom, this imposes no restrictions on msg.sender.
    * @param from current owner of the token
    * @param to address to receive the ownership of the given token ID
    * @param tokenId uint256 ID of the token to be transferred
    */
   function _transferFrom(address from, address to, uint256 tokenId) internal {
       super._transferFrom(from, to, tokenId);

       _removeTokenFromOwnerEnumeration(from, tokenId);

       _addTokenToOwnerEnumeration(to, tokenId);
   }

   /**
    * @dev Internal function to mint a new token.
    * Reverts if the given token ID already exists.
    * @param to address the beneficiary that will own the minted token
    * @param tokenId uint256 ID of the token to be minted
    */
   function _mint(address to, uint256 tokenId) internal {
       super._mint(to, tokenId);

       _addTokenToOwnerEnumeration(to, tokenId);

       _addTokenToAllTokensEnumeration(tokenId);
   }

   /**
    * @dev Internal function to burn a specific token.
    * Reverts if the token does not exist.
    * Deprecated, use {ERC721-_burn} instead.
    * @param owner owner of the token to burn
    * @param tokenId uint256 ID of the token being burned
    */
   function _burn(address owner, uint256 tokenId) internal {
       super._burn(owner, tokenId);

       _removeTokenFromOwnerEnumeration(owner, tokenId);
       // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
       _ownedTokensIndex[tokenId] = 0;

       _removeTokenFromAllTokensEnumeration(tokenId);
   }

   /**
    * @dev Gets the list of token IDs of the requested owner.
    * @param owner address owning the tokens
    * @return uint256[] List of token IDs owned by the requested address
    */
   function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
       return _ownedTokens[owner];
   }

   /**
    * @dev Private function to add a token to this extension's ownership-tracking data structures.
    * @param to address representing the new owner of the given token ID
    * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
   function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
       _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
       _ownedTokens[to].push(tokenId);
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

       uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
       uint256 tokenIndex = _ownedTokensIndex[tokenId];

       // When the token to delete is the last token, the swap operation is unnecessary
       if (tokenIndex != lastTokenIndex) {
           uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

           _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
           _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
       }

       // This also deletes the contents at the last position of the array
       _ownedTokens[from].length--;

       // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
       // lastTokenId, or just over the end of the array if the token was the last one).
   }

   /**
    * @dev Private function to remove a token from this extension's token tracking data structures.
    * This has O(1) time complexity, but alters the order of the _allTokens array.
    * @param tokenId uint256 ID of the token to be removed from the tokens list
    */
   function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
       // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
       // then delete the last slot (swap and pop).

       uint256 lastTokenIndex = _allTokens.length.sub(1);
       uint256 tokenIndex = _allTokensIndex[tokenId];

       // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
       // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
       // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
       uint256 lastTokenId = _allTokens[lastTokenIndex];

       _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
       _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

       // This also deletes the contents at the last position of the array
       _allTokens.length--;
       _allTokensIndex[tokenId] = 0;
   }
}

/**
* @title ERC-721 Non-Fungible Token Standard, optional metadata extension
* @dev See https://eips.ethereum.org/EIPS/eip-721
*/
contract IERC721Metadata is IERC721 {
   function name() external view returns (string memory);
   function symbol() external view returns (string memory);
   function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
   // Token name
   string private _name;

   // Token symbol
   string private _symbol;

   // Optional mapping for token URIs
   mapping(uint256 => string) private _tokenURIs;
  
   
   //Optional mapping for IPFS link to canonical image file
   mapping(uint256 => string) private _tokenIPFSHashes;

   /*
    *     bytes4(keccak256('name()')) == 0x06fdde03
    *     bytes4(keccak256('symbol()')) == 0x95d89b41
    *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
    *
    *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
    */
   bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

   /**
    * @dev Constructor function
    */
   constructor (string memory name, string memory symbol) public {
       _name = name;
       _symbol = symbol;

       // register the supported interfaces to conform to ERC721 via ERC165
       _registerInterface(_INTERFACE_ID_ERC721_METADATA);
   }

   /**
    * @dev Gets the token name.
    * @return string representing the token name
    */
   function name() external view returns (string memory) {
       return _name;
   }

   /**
    * @dev Gets the token symbol.
    * @return string representing the token symbol
    */
   function symbol() external view returns (string memory) {
       return _symbol;
   }

   /**
    * @dev Returns an URI for a given token ID.
    * Throws if the token ID does not exist. May return an empty string.
    * @param tokenId uint256 ID of the token to query
    */
   function tokenURI(uint256 tokenId) external view returns (string memory) {
       require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
       return _tokenURIs[tokenId];
   }
   
   
     /**
    * @dev Returns an URI for a given token ID.
    * Throws if the token ID does not exist. May return an empty string.
    * @param tokenId uint256 ID of the token to query
    */
   function tokenIPFSHash(uint256 tokenId) external view returns (string memory) {
       require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
       return _tokenIPFSHashes[tokenId];
   }

   /**
    * @dev Internal function to set the token URI for a given token.
    * Reverts if the token ID does not exist.
    * @param tokenId uint256 ID of the token to set its URI
    * @param uri string URI to assign
    */
   function _setTokenURI(uint256 tokenId, string memory uri) internal {
       require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
       _tokenURIs[tokenId] = uri;
   }
   
      /**
    * @dev Internal function to set the token IPFS hash for a given token.
    * Reverts if the token ID does not exist.
    * @param tokenId uint256 ID of the token to set its URI
    * @param ipfs_hash string IPFS link to assign
    */
   function _setTokenIPFSHash(uint256 tokenId, string memory ipfs_hash) internal {
       require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
       _tokenIPFSHashes[tokenId] = ipfs_hash;
   }
   
   

   /**
    * @dev Internal function to burn a specific token.
    * Reverts if the token does not exist.
    * Deprecated, use _burn(uint256) instead.
    * @param owner owner of the token to burn
    * @param tokenId uint256 ID of the token being burned by the msg.sender
    */
   function _burn(address owner, uint256 tokenId) internal {
       super._burn(owner, tokenId);

       // Clear metadata (if any)
       if (bytes(_tokenURIs[tokenId]).length != 0) {
           delete _tokenURIs[tokenId];
       }
   }
}


/**
* @title Full ERC721 Token
* @dev This implementation includes all the required and some optional functionality of the ERC721 standard
* Moreover, it includes approve all functionality using operator terminology.
*
* See https://eips.ethereum.org/EIPS/eip-721
*/
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
   constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
       // solhint-disable-previous-line no-empty-blocks
   }
}


contract NiftyBuilderInstance is ERC721Full {

   //MODIFIERS

   modifier onlyValidSender() {
       NiftyRegistry nftg_registry = NiftyRegistry(niftyRegistryContract);
       bool is_valid = nftg_registry.isValidNiftySender(msg.sender);
       require(is_valid==true);
       _;
   }

   //CONSTANTS

   // how many nifties this contract is selling
   // used for metadat retrieval
   uint public numNiftiesCurrentlyInContract;

   //id of this contract for metadata server
   uint public contractId;
   
   //is permanently closed
   bool public isClosed = false;

   //baseURI for metadata server
   string public baseURI;

//   //name of creator
//   string public creatorName;

   string public nameOfCreator;

   //nifty registry contract
   address public niftyRegistryContract = 0x6e53130dDfF21E3BC963Ee902005223b9A202106;

   //master builder - ONLY DOES STATIC CALLS
   address public masterBuilderContract = 0x6EFB06cF568253a53C7511BD3c31AB28BecB0192;

   using Counters for Counters.Counter;

   //MAPPINGS

   //mappings for token Ids
   mapping (uint => Counters.Counter) public _numNiftyMinted;
   mapping (uint => uint) public _niftyPrice;
   mapping (uint => string) public _niftyIPFSHashes;
   mapping (uint => bool) public _IPFSHashHasBeenSet;

   //EVENTS

   //purchase + creation events
   event NiftyPurchased(address _buyer, uint256 _amount, uint _tokenId);
   event NiftyCreated(address new_owner, uint _niftyType, uint _tokenId);

   //CONSTRUCTOR FUNCTION

   constructor(
       string memory _name,
       string memory _symbol,
       uint contract_id,
       uint num_nifties,
       string memory base_uri,
       string memory name_of_creator) ERC721Full(_name, _symbol) public {

       //set local variables based on inputs
       contractId = contract_id;
       numNiftiesCurrentlyInContract = num_nifties;
       baseURI = base_uri;
       nameOfCreator = name_of_creator;

       //offset starts at 1 - there is no niftyType of 0
    //   for (uint i=0; i<(num_nifties); i++) {
    //       _numNiftyPermitted[i+1] = nifty_quantities[i];
    //   }
   }
   
   function setNiftyIPFSHash(uint niftyType, 
                            string memory ipfs_hash) onlyValidSender public {
        //can only be set once
        if (_IPFSHashHasBeenSet[niftyType] == true) {
            revert("Can only be set once");
        } else {
            _niftyIPFSHashes[niftyType] = ipfs_hash;
            _IPFSHashHasBeenSet[niftyType]  = true;
        }
    }
    
    function closeContract() onlyValidSender public {
        //permanently close this open edition
        isClosed = true;
        
    }

   function giftNifty(address collector_address, 
                      uint niftyType) onlyValidSender public {
       //master for static calls
       BuilderMaster bm = BuilderMaster(masterBuilderContract);
       _numNiftyMinted[niftyType].increment();
       //check if this collection is closed
       if (isClosed==true) {
           revert("This contract is closed!");
       }
       //mint a nifty
       uint specificTokenId = _numNiftyMinted[niftyType].current();
       uint tokenId = bm.encodeTokenId(contractId, niftyType, specificTokenId);
       string memory tokenIdStr = bm.uint2str(tokenId);
       string memory tokenURI = bm.strConcat(baseURI, tokenIdStr);
       string memory ipfsHash = _niftyIPFSHashes[niftyType];
       //mint token
       _mint(collector_address, tokenId);
       _setTokenURI(tokenId, tokenURI);
       _setTokenIPFSHash(tokenId, ipfsHash);
       //do events
       emit NiftyCreated(collector_address, niftyType, tokenId);
   }

}

contract NiftyRegistry {
   function isValidNiftySender(address sending_key) public view returns (bool);
   function isOwner(address owner_key) public view returns (bool);
}

contract BuilderMaster {
   function getContractId(uint tokenId) public view returns (uint);
   function getNiftyTypeId(uint tokenId) public view returns (uint);
   function getSpecificNiftyNum(uint tokenId) public view returns (uint);
   function encodeTokenId(uint contractId, uint niftyType, uint specificNiftyNum) public view returns (uint);
   function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) public view returns (string memory);
   function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) public view returns (string memory);
   function strConcat(string memory _a, string memory _b, string memory _c) public view returns (string memory);
   function strConcat(string memory _a, string memory _b) public view returns (string memory);
   function uint2str(uint _i) public view returns (string memory _uintAsString);
}

/**
* Contracts and libraries below are from OpenZeppelin, except nifty builder instance
**/


/**
* @dev Wrappers over Solidity's arithmetic operations with added overflow
* checks.
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
    * - Addition cannot overflow.
    */
   function add(uint256 a, uint256 b) internal pure returns (uint256) {
       uint256 c = a + b;
       require(c >= a, "SafeMath: addition overflow");

       return c;
   }

   /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       return sub(a, b, "SafeMath: subtraction overflow");
   }

   /**
    * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    *
    * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
    * @dev Get it via `npm install @openzeppelin/contracts@next`.
    */
   function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       require(b <= a, errorMessage);
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
    * - Multiplication cannot overflow.
    */
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
       // benefit is lost if 'b' is also tested.
       // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
       if (a == 0) {
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
    * - The divisor cannot be zero.
    */
   function div(uint256 a, uint256 b) internal pure returns (uint256) {
       return div(a, b, "SafeMath: division by zero");
   }

   /**
    * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
    * @dev Get it via `npm install @openzeppelin/contracts@next`.
    */
   function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       // Solidity only automatically asserts when dividing by 0
       require(b > 0, errorMessage);
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
    * - The divisor cannot be zero.
    */
   function mod(uint256 a, uint256 b) internal pure returns (uint256) {
       return mod(a, b, "SafeMath: modulo by zero");
   }

   /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts with custom message when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    *
    * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
    * @dev Get it via `npm install @openzeppelin/contracts@next`.
    */
   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       require(b != 0, errorMessage);
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
    * This test is non-exhaustive, and there may be false-negatives: during the
    * execution of a contract's constructor, its address will be reported as
    * not containing a contract.
    *
    * IMPORTANT: It is unsafe to assume that an address for which this
    * function returns false is an externally-owned account (EOA) and not a
    * contract.
    */
   function isContract(address account) internal view returns (bool) {
       // This method relies in extcodesize, which returns 0 for contracts in
       // construction, since the code is only stored at the end of the
       // constructor execution.

       // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
       // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
       // for accounts without code, i.e. `keccak256('')`
       bytes32 codehash;
       bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
       // solhint-disable-next-line no-inline-assembly
       assembly { codehash := extcodehash(account) }
       return (codehash != 0x0 && codehash != accountHash);
   }

   /**
    * @dev Converts an `address` into `address payable`. Note that this is
    * simply a type cast: the actual underlying value is not changed.
    *
    * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
    * @dev Get it via `npm install @openzeppelin/contracts@next`.
    */
   function toPayable(address account) internal pure returns (address payable) {
       return address(uint160(account));
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

       // solhint-disable-next-line avoid-call-value
       (bool success, ) = recipient.call.value(amount)("");
       require(success, "Address: unable to send value, recipient may have reverted");
   }
}

/**
* @title Counters
* @author Matt Condon (@shrugs)
* @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
* of elements in a mapping, issuing ERC721 ids, or counting request ids.
*
* Include with `using Counters for Counters.Counter;`
* Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
* overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
* directly accessed.
*/
library Counters {
   using SafeMath for uint256;

   struct Counter {
       // This variable should never be directly accessed by users of the library: interactions must be restricted to
       // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
       // this feature: see https://github.com/ethereum/solidity/issues/4637
       uint256 _value; // default: 0
   }

   function current(Counter storage counter) internal view returns (uint256) {
       return counter._value;
   }

   function increment(Counter storage counter) internal {
       // The {SafeMath} overflow check can be skipped here, see the comment at the top
       counter._value += 1;
   }

   function decrement(Counter storage counter) internal {
       counter._value = counter._value.sub(1);
   }
}