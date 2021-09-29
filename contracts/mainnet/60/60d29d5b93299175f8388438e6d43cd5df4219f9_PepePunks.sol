/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
// Pixel PepePunks // pepunks.com //

pragma solidity ^0.8.0;


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 *
 *  IMPORTANT CHANGES !!!
 *   _owners: visibility set to internal.
 *   _balances: visibility set to internal.
 *   _checkOnERC721Received: removed
 *   All calls from contract ERC721 set to overwritables. For example, ERC721.ownerOf(tokenId) set to ownerOf(tokenId).
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    //using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

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
        address owner = ownerOf(tokenId);
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
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
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
        address owner = ownerOf(tokenId);
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
     * The approval is cleared when the token is burned.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

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
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     */
    /*function _checkOnERC721Received(
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
    }*/

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


/**
 *  ERC721 with premint feautures. Premint owner can't be null address. 
 */
contract ERC721Premint is ERC721 {

    uint256 private _premintedCount;
    address private _premintOwner;
    uint256 private _mintedCount;
    mapping(uint256 => bool) private _burned;


    constructor(string memory name_, string memory symbol_, address premintOwner_) ERC721(name_, symbol_) {        
        _premintOwner = premintOwner_ == address(0) ? _msgSender() : premintOwner_;
    }

   
    // ------------------ IERC721 Overrides ---------------

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return super.balanceOf(owner) 
                    + (_isPremintOwner(owner) ? _premintedCount : 0); 
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if (isPremintedToken(tokenId)){  
            owner = _premintOwner;
        }
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
        return _owners[tokenId] != address(0) || isPremintedToken(tokenId); 
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);

        _mintedCount += 1;
    }

    function _burn(uint256 tokenId) internal virtual override {
        require(!isPremintedToken(tokenId), "Premint: burning preminted token");
        super._burn(tokenId);

        _burned[tokenId] = true;
    }


    function _transfer(address from, address to, uint256 tokenId) internal override virtual {
        bool _isPremintedToken = isPremintedToken(tokenId);

        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!_isPremintedToken || !_isPremintOwner(to), "Premint: transfer preminted token to the Premint Owner");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        if (_isPremintOwner(from) && _isPremintedToken){
            _premintedCount -= 1;
            _mintedCount += 1;
        }
        else {
            _balances[from] -= 1;
        }

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }


    // ------------------ IERC721Premint and utils ---------------


    function _totalSupply() internal view returns (uint256) {
        return _mintedCount + _premintedCount;
    }

    function _isPremintOwner(address addr) internal view returns (bool) {
        return _premintOwner == addr;
    }

    function originBalanceOf(address owner) public view virtual returns (uint256) {
        return super.balanceOf(owner);
    }

    function originOwnerOf(uint256 tokenId) public view virtual returns (address) {
        return super.ownerOf(tokenId);
    }

    function premintOwner() public virtual view returns (address) {
        return _premintOwner;
    }

    function premintedCount() public virtual view returns (uint256) {
        return _premintedCount;
    }

    function isPremintedToken(uint256 tokenId) public view virtual returns (bool) {
        return 
            _owners[tokenId] == address(0) && 
            !_burned[tokenId] &&
            tokenId <= _totalSupply();
    }

    function mintedCount() public virtual view returns (uint256) {
        return _mintedCount; 
    }

    function _premint(uint256 count) internal virtual {
        require(count > 0, "Premint: premint count is zero");

        uint256 startTokenId = _totalSupply() + 1;
        _premintedCount += count;

        for(uint256 i = 0; i < count; i++){
            emit Transfer(address(0), _premintOwner, startTokenId + i);
        }
    }  

}


/**
 *  ERC721Premint with sequential token indexes and others features.
 */
contract ERC721PremintBasic is ERC721Premint, IERC721Enumerable, Ownable {
    using Strings for uint256;

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    string private _baseUri;

    // Storage: tokenURIs
    mapping(uint256 => string) private _tokenURIs;
    

    constructor(string memory name_, string memory symbol_, address premintOwner_) 
                ERC721Premint(name_, symbol_, premintOwner_) {}

    /**
     * @dev See {ERC721Premint}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function canMint(address to, uint256 count) public view virtual returns (bool) {
        require(to != address(0), "Recipient is required");  
        require(count > 0, "Mint: Count must be 1 or more");
        return true;
    }

    function canPremint(uint256 count) public view virtual returns (bool) {
        require(count > 0, "Premint: Count must be 1 or more");
        return true;
    }

    function mintTo(address to, uint256 count) public onlyOwner {  
        require(canMint(to, count));
        
        for(uint256 i = 0; i < count; i++){
            _safeMint(to, totalSupply() + 1);
        }
    }

    function premint(uint256 count) public virtual onlyOwner {
        require(canPremint(count));
        _premint(count);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev See {IERC721Enumerable}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply();
    }

    /**
     * @dev See {IERC721Enumerable}.
     */
    function tokenOfOwnerByIndex(address owner_, uint256 index) external view override returns (uint256 tokenId) {
        require(index < balanceOf(owner_), "ERC721Enumerable: owner index out of bounds");
        if (_isPremintOwner(owner_)){
            //
            // IMPORTANT !!! Calling with index of preminted tokens throws an error!
            //
            require(index < originBalanceOf(owner_), "Premint: Premint Owner index out of bounds");
        } 
        return _ownedTokens[owner_][index];
    }

    /**
     * @dev See {IERC721Enumerable}.
     * 
     * Important!!! Without throw error when token by index is burned!
     */
    function tokenByIndex(uint256 index) external view override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index + 1;
    }

    /**
     * @dev {Storage}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory base = _baseURI();
        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString())) : ""; 
    }

    /**
     * @dev {Storage}.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseUri;
    }
    function setBaseURI(string memory uri) public virtual onlyOwner {
        _baseUri = uri;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev {Storage}.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual onlyOwner {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            // do nothing
        } else if (from != to && !isPremintedToken(tokenId)) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            // do nothing
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Premint.originBalanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }   

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Premint.originBalanceOf(from) - 1;
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

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}


abstract contract ERC721MysteryBox is ERC721PremintBasic {
    uint256 private _maxTokens = 5555;

    mapping(uint256 => address) private _mapBoxesTo;
    mapping(uint256 => uint256) private _mapBoxesCount;
    mapping(uint256 => address) private _mapBoxesProxy;
    mapping(uint256 => string) private _mapBoxesName;


    uint256 private _reservedForBox;


    function maxTokens() public view virtual returns (uint256) {
        return _maxTokens;
    }
    function setMaxTokens(uint256 maxTokens_) public virtual onlyOwner {
        require(maxTokens_ >= totalSupply() + _reservedForBox, "Max count is not correct");  
        _maxTokens = maxTokens_;
    }
    function reservedForMysteryBox() public view returns (uint256) {
        return _reservedForBox;
    }

    function canMint(address to, uint256 count) public view virtual override returns (bool) {
        if (_maxTokens > 0){
            require(_maxTokens >= totalSupply() + count + _reservedForBox, "Exceeds maximum tokens available");
        }
        return super.canMint(to, count);
    }

    function isMysteryBoxToken(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return address(_mapBoxesTo[tokenId]) != address(0);
    }

    function mysteryBoxInfo(uint256 tokenId) public view 
            returns (uint256 count, string memory name, address proxy) {

        require(isMysteryBoxToken(tokenId), "Token is not a Mystery Box");

        return (
            _mapBoxesCount[tokenId], 
            _mapBoxesName[tokenId], 
            _mapBoxesProxy[tokenId] 
        );
    }

    function mintBox(address to, uint256 count, string memory name) public onlyOwner {
        require(canMint(to, count + 1));
        mintBoxProxy(to, count, name, address(0));
    }

    function mintBoxProxy(
        address to, 
        uint256 count, 
        string memory name,
        address proxyUnpackerAddress) public onlyOwner {

        require(canMint(to, count + 1));

        uint256 boxId = totalSupply() + 1;
        _safeMint(to, boxId);

        _reservedForBox += count;

        _mapBoxesTo[boxId] = to; 
        _mapBoxesCount[boxId] = count; 
        _mapBoxesProxy[boxId] = proxyUnpackerAddress; 
        _mapBoxesName[boxId] = name; 
    }

    function unpack(uint256 tokenId) public {
        require(isMysteryBoxToken(tokenId), "Error: token is not a Mystery Box token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner or approved");

        address to = ownerOf(tokenId);

        uint256 boxCoint = _mapBoxesCount[tokenId];

        if (boxCoint > 0){
            for(uint256 i = 0; i < boxCoint; i++){
                _safeMint(to, totalSupply() + 1);
            }
            _reservedForBox -= boxCoint;
        }

        if (_mapBoxesProxy[tokenId] != address(0)){
            IProxyUnpacker proxyUnpacker = IProxyUnpacker(_mapBoxesProxy[tokenId]);
            proxyUnpacker.unpackMysteryBox(to);
        }

        // Burn the Mystery Box
        burn(tokenId);
    }

}

/**
 *  @title Interface for contract unpacking Mistery Box 
 */
interface IProxyUnpacker {
    function unpackMysteryBox(address to) external;
}

contract PepePunks is ERC721MysteryBox {
    constructor(address premintOwner) ERC721PremintBasic("PepePunks", "PPP", premintOwner) {}
}