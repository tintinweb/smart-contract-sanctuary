/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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

interface IMigration {
    function currentTokenID() external view returns(uint256);
    function characterInfo( uint _key) external view returns (address _owner,string memory _characterName,uint8 _level,uint _skill,uint _baseAccuracy,uint _power,uint _skillValue);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable {
    using Strings for uint256;

    string private _baseURI;
    uint256 internal _currentTokenID = 0;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    mapping(uint => bool) public blackList;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

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
        return "DVERSE Characters";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return "DVERSENFT";
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory __baseURI = baseURI();
        return bytes(__baseURI).length > 0 ? string(abi.encodePacked(__baseURI,  tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    function setBaseURI( string memory __baseURI) public onlyOwner {
        _baseURI = __baseURI;
    }

    function setNFTBlackList( uint _tokenID, bool _stat) public onlyOwner {
        blackList[_tokenID] = _stat;
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

    function currentTokenID() external view returns(uint256){
        return _currentTokenID;
    }

    function _getNextTokenID() external view returns (uint256) {
        return _currentTokenID+1;
    }

    function _incrementTokenTypeId() internal  {
        _currentTokenID++;
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
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
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
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
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!blackList[tokenId], "ERC721: Token is on black list");

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
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

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

contract Verifier {
    bytes32 public constant SIGNATURE_PERMIT_TYPEHASH = keccak256("verify(address _receiver, uint _nonces, uint _deadline, bytes memory signature)");
    uint public chainId;
    
    using ECDSA for bytes32;
    
    constructor() {
        uint _chainId;
        assembly {
            _chainId := chainid()
        }
        
        chainId = _chainId;
    }
    
    function hashCreation() internal pure returns (bytes32  messageHash){
        bytes32 hash = keccak256(abi.encodePacked());
        messageHash = hash.toSignedMessageHash();
    }
    
    function verify(address _receiver, uint _nonces, uint _deadline, bytes memory signature) public view returns (address){
      // This recreates the message hash that was signed on the client.
      bytes32 hash = keccak256(abi.encodePacked(SIGNATURE_PERMIT_TYPEHASH, _receiver, chainId, _nonces, _deadline));
      bytes32 messageHash = hash.toSignedMessageHash();
    
      // Verify that the message's signer is the owner of the order
      return messageHash.recover(signature);
    }
}

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   */
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables with inline assembly.
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

contract Migration is ERC721Enumerable {
    mapping(uint => characterInfo) public charInfo;

    address public migrateNFT;

    struct characterInfo {
        string charName;
        uint8 level;
        uint8 skillRarity;
        uint8 baseAccuracy;
        uint8 power;
        uint8 skillValue;
    }

    constructor() {
        
    }

    function setMigrateNFT( address migrateAdd) external onlyOwner {
         migrateNFT = migrateAdd;
        _currentTokenID = IMigration(migrateNFT).currentTokenID();
    }

    function migrate( uint tokenId, address receiver) external {
        require(IERC721(migrateNFT).ownerOf(tokenId) == _msgSender(), "Migration : caller is not a owner of token id");
        require(!_exists(tokenId), "Migration : token id is already migrated");
        require(IERC721(migrateNFT).getApproved(tokenId) == address(this), "Migration : token is not approved");

        IERC721(migrateNFT).transferFrom(_msgSender(), address(0x000000000000000000000000000000000000dEaD), tokenId);
        _mint( receiver, tokenId);
        (,string memory _characterName,uint8 _level,uint _skill,uint _baseAccuracy,uint _power,uint _skillValue) = IMigration(migrateNFT).characterInfo(tokenId);
        
        charInfo[tokenId] = characterInfo({
            charName : _characterName,
            level : _level,
            skillRarity : uint8(_skill),
            baseAccuracy : uint8(_baseAccuracy),
            power : uint8(_power),
            skillValue : uint8(_skillValue)
        });

    }
}

contract DVERSENFT is Migration, Verifier, Pausable {    
    mapping(bytes => uint) public signInfo; // nonce and sign message.
    mapping(address => uint) public nonce;
    
    address public DVERSE;
    address public sellPriceToken = address(0);
    uint[] public charactersOnSale;
    uint public fusionFee;
    uint[3] public individualSaleInfo = [ 0 /*saleIndex*/, 0 /*bnbPriceForSale*/, 0 /*defversePriceForSale*/];
    bool[2] public individualSaleStat = [false /*_isSaleOn*/, false /*switchSale*/];
    
    event NewBornCharacter( uint indexed _characterKey, uint _birthTime, address _receiver);
    event PurchasedCharactersOnSale( uint indexed _characterKey, address _receiver, uint _purchaseTime);
    event Fusion( address indexed owner, address indexed _receiver, uint[3] _tokenIDs, uint _newTokenID);
    
    constructor(address _dverse){
        DVERSE = _dverse;
    }
    struct parameters {
        address _receiver;
        uint _sellForValue;
        uint _deadline;
        bytes signature;
    }

    function createCharacterDemo( /*parameters calldata _var,*/ characterInfo calldata _charInfo) external whenNotPaused {
        // _validateSignature(_var);
        // validateSpec(_charInfo);
        // require(_var._sellForValue > 0, "DVERSENFT :: createCharacter : _sellForValue should not be zero");
        // require(IERC20(DVERSE).transferFrom(msg.sender, owner(),_var._sellForValue), "DVERSE :: createCharacter : sell token transfer failed");
        _createCharacters(msg.sender, _charInfo);
    }   
    
    function createCharacter( parameters calldata _var, characterInfo calldata _charInfo) external whenNotPaused {
        _validateSignature(_var);
        validateSpec(_charInfo);
        require(_var._sellForValue > 0, "DVERSENFT :: createCharacter : _sellForValue should not be zero");
        require(IERC20(DVERSE).transferFrom(msg.sender, owner(),_var._sellForValue), "DVERSE :: createCharacter : sell token transfer failed");
        _createCharacters(_var._receiver, _charInfo);
        
    }    
    
    function createCharacterBatch( parameters[3] calldata _var, characterInfo[3] calldata _charInfo) external whenNotPaused{
        for(uint i=0; i<_var.length; i++){            
            _validateSignature(_var[i]);
            validateSpec(_charInfo[i]);
            require(_var[i]._sellForValue > 0, "DVERSENFT :: createCharacterBatch : _sellForValue should not be zero");
            require(IERC20(DVERSE).transferFrom(msg.sender, owner(),_var[i]._sellForValue), "DVERSE :: createCharacterBatch : sell token transfer failed");
            _createCharacters(_var[i]._receiver, _charInfo[i]);
        }
    }
    
    function createCharacterBatchLevel4( parameters[] calldata _var, characterInfo[] calldata _charInfo, uint _len, bool _sale) external onlyOwner {
        require((_var.length == _len) && (_charInfo.length == _len), "DVERSE :: createCharacterBatchLevel4 : require the length to be matched");
        for(uint i=0; i<_var.length; i++){
            validateSpec(_charInfo[i]);
            uint _charID = _createCharacters(_var[i]._receiver, _charInfo[i]);

            if(_sale){
                charactersOnSale.push(_charID);
            } 
        }
    
    }

    function fusion(uint[3] calldata _tokenIDs, uint _deadLine , characterInfo calldata _charInfo, bytes calldata _signature) external whenNotPaused {
        require(fusionFee > 0, "DVERSENFT :: fusion : fusionFee should greater than zero");
        require((_tokenIDs[0] != _tokenIDs[1]) && (_tokenIDs[1] != _tokenIDs[2]), "DVERSE :: fusion : repeated token id identified");
        require(_charInfo.level == 4, "DVERSENFT :: fusion : level must be 4");
        parameters memory _var;
        (_var._receiver, _var._deadline, _var.signature) = (_msgSender(), _deadLine, _signature);
        _validateSignature(_var);
        validateSpec(_charInfo);

        IERC20(DVERSE).transferFrom(_msgSender(), owner(), fusionFee);

        for(uint8 i=0; i < _tokenIDs.length; i++){
            require(ownerOf(_tokenIDs[i]) == _msgSender(),"DVERSENFT :: fusion : is not a owner");
            require(charInfo[_tokenIDs[i]].level == i+1,"DVERSENFT :: fusion : level is not in order");
            _burn(_tokenIDs[i]);
        }

        uint _charID = _createCharacters(_var._receiver, _charInfo);
        emit Fusion( _msgSender(), _var._receiver, _tokenIDs, _charID);
    }

    function setDverse( address _dverse) external onlyOwner {
        DVERSE = _dverse;
    }

    function setFusionFee( uint _fusionFee) external onlyOwner {
        require(_fusionFee > 0, "DVERSENFT :: setFusionFee : _fusionFee should greater than zero");
        fusionFee = _fusionFee;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBNBPriceForSale( uint _value) external onlyOwner {
        individualSaleInfo[1] = _value;
    }
    
    function setDefversePriceForSale( uint _value) external onlyOwner {
        individualSaleInfo[2] = _value;
    }
    
    function setSaleOn( bool _isSaleOn) external onlyOwner {
        individualSaleStat[0] = _isSaleOn;
    }
    
    function setSwitchSale( bool _switchSale) external onlyOwner {
        individualSaleStat[1] = _switchSale;
    }

    function viewSaleschar()public view returns(uint[] memory){
        return charactersOnSale;
    }
    
    function buySale() external payable {
        require(individualSaleStat[0], "DVERSENFT :: buySale : sale is not active");
        require(charactersOnSale.length > 0, "DVERSENFT :: buySale : sale not yet begain");
        require(individualSaleInfo[0] != charactersOnSale.length, "DVERSENFT :: buySale : sale closed");
        
        
        if(individualSaleStat[1]) sellPriceToken = DVERSE;
        
        if(sellPriceToken == address(0)){
            require(individualSaleInfo[1] > 0, "DVERSENFT :: buySale : bnbPriceForSale is not set");
            require(msg.value == individualSaleInfo[1], "DVERSENFT :: buySale : invaild bnb to purchase the character");
            payable(owner()).transfer(individualSaleInfo[1]);
        }
        else{
            require(msg.value == 0, "value must not be passed for deface sale");
            require(individualSaleInfo[2] > 0, "DVERSENFT :: buySale : defversePriceForSale is not set");
            IERC20(DVERSE).transferFrom(msg.sender, owner(),individualSaleInfo[2]);
        }
        
        uint _character = charactersOnSale[individualSaleInfo[0]];
        individualSaleInfo[0]++;
        
        _transfer(owner(), msg.sender, _character);
        
        emit PurchasedCharactersOnSale(
            _character,
            msg.sender,
            block.timestamp
        );
    }

    function _createCharacters( address _receiver, characterInfo calldata _charInfo) private returns (uint) {
        uint nxtCharacter = this._getNextTokenID();
        _mint( _receiver, nxtCharacter);
        charInfo[nxtCharacter] = _charInfo;
        _incrementTokenTypeId();
        
        emit NewBornCharacter(
            nxtCharacter,
            block.timestamp,
            _receiver
        );
        
        return nxtCharacter;
    }
    
    function _validateSignature(parameters memory _var) private {
        require(_var._deadline >= block.timestamp, "DVERSENFT :: createCharacterBatch : deadline expired");
        require(signInfo[_var.signature] == 0, "DVERSENFT :: createCharacterWithURl : message already signed");
        
        address _signer = verify( _var._receiver, ++nonce[msg.sender], _var._deadline, _var.signature);
        require(_signer == msg.sender, "DVERSENFT :: _validateSignature : invalid signature");
        
        signInfo[_var.signature] = 1; // store sign hash.
    }

    function validateSpec(characterInfo memory _charInfo) private pure {
        require((_charInfo.level > 0) && (_charInfo.level <= 4));

        if(_charInfo.level == 1) {
            require((_charInfo.baseAccuracy >= 15) && (_charInfo.baseAccuracy <= 30), "validateSpec : invalid base accuracy for level 1");
            require((_charInfo.power >= 15) && (_charInfo.power <= 30), "validateSpec : invalid power for level 1");
        } else if (_charInfo.level == 2) {
            require((_charInfo.baseAccuracy >= 31) && (_charInfo.baseAccuracy <= 45), "validateSpec : invalid base accuracy for level 2");
            require((_charInfo.power >= 31) && (_charInfo.power <= 45), "validateSpec : invalid power for level 2");
        } else if(_charInfo.level == 3) {
            require((_charInfo.baseAccuracy >= 46) && (_charInfo.baseAccuracy <= 60), "validateSpec : invalid base accuracy for level 3");
            require((_charInfo.power >= 46) && (_charInfo.power <= 60), "validateSpec : invalid power for level 3");
        } else {
            require(_charInfo.baseAccuracy >= 70, "validateSpec : invalid base accuracy for level 4");
            require(_charInfo.power >= 70, "validateSpec : invalid power for level 4");
        }
    }
}