/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;

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
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
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
    function balanceOf(address owner) public view returns (uint256 balance);
    
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */    
    function ownerOf(uint256 tokenId) public view returns (address owner);
    
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
    function transferFrom(address from, address to, uint256 tokenId) public;
    
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
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */

contract IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
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
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
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
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */    
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => uint256) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);
    }
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exists(tokenId));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
        emit Transfer(address(0), to, tokenId);
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));
        _clearApproval(tokenId);
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
        _tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
    function uint2str(uint i) internal pure returns (string memory){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint j = 0; j < _bb.length; j++) bab[k++] = _bb[j];
        return string(bab);
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
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        _addTokenToAllTokensEnumeration(tokenId);
    }
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        _ownedTokens[from].length--;
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;
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

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    string private _name;
    string private _symbol;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    
    
}

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    string name   = "elfin";
    string symbol = "ELFIN";
    constructor () public ERC721Metadata(name, symbol) {
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));
        role.bearer[account] = true;
    }
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));
        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    Roles.Role private _minters;
    constructor () internal {
        _addMinter(msg.sender);
    }
    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }
    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
        //return true;
    }
    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }
    function renounceMinter() public onlyMinter{
        _removeMinter(msg.sender);
    }
    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }
    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}


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
contract Ownable {
    address private _owner;
    using Roles for Roles.Role;
    Roles.Role private _minters;
    
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () internal {
        _owner = msg.sender;
        _addMinter(msg.sender);
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }
    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }
    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }
    function renounceMinter(address account) public onlyOwner{
        _removeMinter(account);
    }
    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }
    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract elfin is ERC721Full, Ownable {
    using SafeMath for uint256;
    
    
    string public tokenURIPrefix = "https://elfinkingdom.com/wapi/elfin/";
    
    
    event minted(address indexed toAddr , uint256 tokenId);
    event transfered(address indexed fromAddr,address indexed toAddr, uint256 tokenId);
    
    
    constructor () public ERC721Full(){}
    
    function transfer(address _to, uint256 _tokenId) public {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }
    
    //Batch transfer to same address.
    function transferAll(address _to, uint256[] memory _tokenId) public {
        for (uint i = 0; i < _tokenId.length; i++) {
            safeTransferFrom(msg.sender, _to, _tokenId[i]);
        }
    }
    
    //Batch transfer to different address.
    function batchTransfer(address[] memory _to, uint256[] memory _tokenId) public {
        require(_to.length == _tokenId.length,"Length is not equal");
        for (uint i = 0; i < _tokenId.length; i++) {
            safeTransferFrom(msg.sender, _to[i], _tokenId[i]);
        }
    }    
    
    //Mint NFT.
    function mint(address _to, uint256 _tokenId) public onlyMinter {
        _mint(_to, _tokenId);

    }
    
    //Batch mint to same address
    function batchMint(address _to, uint256[] memory _tokenId) public onlyMinter {
        for (uint i = 0; i < _tokenId.length; i++) {
            _mint(_to, _tokenId[i]);
        }
    }
    
    //Batch mint to different address.
    function batchAddrMint(address[] memory _to, uint256 _tokenId) public onlyMinter{
        for (uint i = 0; i < _to.length; i++) {
            _mint(_to[i], _tokenId.add(i));
        }
    }
    
    //Set tokenURIPrefix.
    function setUri(string memory uri) public onlyMinter {
        tokenURIPrefix = uri;
    }
    
    //Get tokenURI by tokenId.
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        
        require(_exists(tokenId));
        string memory infoUrl;
        infoUrl = strConcat(tokenURIPrefix, uint2str(tokenId));
        
        //emit tokenURIed(tokenId,infoUrl);

        return infoUrl;
        
        //emit tokenURIed(tokenId,infoUrl);
    }
    
}