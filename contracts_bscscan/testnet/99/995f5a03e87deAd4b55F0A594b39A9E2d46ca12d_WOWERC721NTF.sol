/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/presets/WOWERC721NTF.sol)

pragma solidity ^0.8.0;


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
library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance ");
        (bool success, ) = recipient.call{value: amount}(""); 
        require(success, "Address: unable to send value, recipient may have reverted ");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract \xe5\xa7\x94\xe6\x89\x98\xe8\xb0\x83\xe7\x94\xa8\xe9\x9d\x9e\xe5\x90\x88\xe7\xba\xa6\xe5\x9c\xb0\xe5\x9d\x80");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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
abstract contract Pausable{

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;


    constructor() {
        _paused = false;
    }


    function paused() public view virtual returns (bool) {
        return _paused;
    }


    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }


    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }


    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }


    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}
interface IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface IERC165 {
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
     * Requirements:
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




abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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


contract ERC721 is ERC165, IERC721, IERC721Metadata{
    using Address for address;
    using Strings for uint256;

    uint8 public constant ADMIN_ROLE = 0;
    uint8 public constant MANAGER_ROLE = 1;


    struct CardInfo {
        string cardName;
        string nftUrl;
        string nftCate;
        string createTime;
        bool isValid;
    }

    struct CardInfoVo {
        uint256 tokenId;
        string cardName;
        string nftUrl;
        string nftCate;
        string createTime;
        bool isValid;
    }


    // Token name
    string private _name;

    // Token symbol
    string private _symbol;


    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => string) private _tokenIdForCardName;

    mapping(string => CardInfo) private _cards;  


    mapping(address => uint256[]) private _tokenIdsOfOwner; 

    address private admin;

    address private manager;

    modifier isAdmin() {
        require(msg.sender == admin, "Caller is not admin");
        _;
    }

    constructor() {
        _name = "WOW-NFT";
        _symbol = "WOW";
    }


    function _getAllTokenIdsOf(address sender) internal view returns(bytes memory ids){
        uint256[] memory tokenIds=_tokenIdsOfOwner[sender];
        ids =bytes("[");
        for (uint i = 0; i < tokenIds.length; i++) {
            if(i==0){
                ids =bytes.concat(ids,bytes(tokenIds[i].toString()));
            }else{
                ids =bytes.concat(ids,bytes(","),bytes(tokenIds[i].toString()));
            }
        }
        ids =bytes.concat(ids,bytes("]"));
    }

    function _mintCard(string memory cardName, string memory nftUrl, string memory nftCate, string memory createTime) internal returns (bool) {
        _cards[cardName] = CardInfo(cardName, nftUrl, nftCate, createTime, true);
        return true;
    }

    function _exitCard(string memory cardName) internal view returns (bool) {
        return _cards[cardName].isValid;
    }


    function CardOfName(string memory _cardName) public view returns (string memory cardName,string memory nftUrl,string memory nftCate,string memory createTime,bool isValid) {
        cardName=_cards[_cardName].cardName;
        nftUrl=_cards[cardName].nftUrl;
        nftCate=_cards[cardName].nftCate;
        createTime=_cards[cardName].createTime;
        isValid=_cards[cardName].isValid;
        return (cardName,nftUrl,nftCate,createTime,isValid);
    }


    function CardOfTokenId(uint256  tokenId) public view returns (string memory cardName,string memory nftUrl,string memory nftCate,string memory createTime,bool isValid) {
        cardName=_cards[_tokenIdForCardName[tokenId]].cardName;
        nftUrl=_cards[_tokenIdForCardName[tokenId]].nftUrl;
        nftCate=_cards[_tokenIdForCardName[tokenId]].nftCate;
        createTime=_cards[_tokenIdForCardName[tokenId]].createTime;
        isValid=_cards[_tokenIdForCardName[tokenId]].isValid;
        return (cardName,nftUrl,nftCate,createTime,isValid);
    }


    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "balanceOf: owner can not be 0x0");
        uint256 balance = _balances[owner];
        return balance;
    }


    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ownerOf: owner can not be 0x0");
        return owner;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: tokenId is not exit");
        return string(abi.encodePacked(_cards[_tokenIdForCardName[tokenId]].nftUrl));
    }


    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }


    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        bool flag = _owners[tokenId] != address(0);
        return flag;
    }


    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: tokenId is not exit");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    function _safeMint(address to, uint256 tokenId, string memory cardName) internal virtual {
        _safeMint(to, tokenId, cardName, "");
    }


    function _safeMint(address to, uint256 tokenId, string memory cardName, bytes memory _data) internal virtual {
        _mint(to, tokenId, cardName);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }


    function _mint(address to, uint256 tokenId, string memory cardName) internal virtual {

        require(to != address(0), "ERC721: to can not be 0x0");

        require(!_exists(tokenId), "ERC721: tokenId is exit");

        require(_exitCard(cardName), "ERC721 : this cardName is not exit");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _tokenIdForCardName[tokenId] = cardName;
        _tokenIdsOfOwner[to].push(tokenId);

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }


    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _tokenIdForCardName[tokenId];
        _processingCardAttribution(owner,address(0),tokenId);
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }


    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: from is not the owner of this tokenId");
        require(to != address(0), "ERC721: to can not be 0x0");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        _processingCardAttribution(from,to,tokenId);
        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }



    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: to cant be owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }


    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: tokenId is not exit");
        return _tokenApprovals[tokenId];
    }


    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }


    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _processingCardAttribution(address from, address to, uint256 tokenId) internal returns (bool) {
        require(from != address(0), "_processingCardAttribution: from address can not be 0x0");
        uint256[] storage tokenIds = _tokenIdsOfOwner[from];
        uint256 index;
        bool shifted = false;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                index = i;
                delete tokenIds[i];
                _tokenIdsOfOwner[to].push(tokenId);
                shifted = true;
                break;
            }
        }
        if (shifted) {
            for (uint i = index; i < tokenIds.length - 1; i++) {
                tokenIds[i] = tokenIds[i + 1];
            }
            tokenIds.pop();
            return true;
        }
        return false;
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        address approval = ERC721.ownerOf(tokenId);
        emit Approval(approval, to, tokenId);

    }


    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }


    function setupManager(address account) public isAdmin{
        manager=account;
    }

    function _initAdmin() internal{
        admin=msg.sender;
    }

    function setupAdmin(address account) public isAdmin{
        admin=account;
    }

    function hasRole(address account,uint8 role) view public returns(bool){
        if (role == ADMIN_ROLE && account == admin){
            return true;
        }else if(role==MANAGER_ROLE && account==manager){
            return true;
        }
        return false;
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}


    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
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
}
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        uint256 tokenId=_ownedTokens[owner][index];
        return tokenId;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        uint256 tokenId=_allTokens[index];
        return tokenId;
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
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


    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }


    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }


    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];  //
            _ownedTokens[from][tokenIndex] = lastTokenId; //
            _ownedTokensIndex[lastTokenId] = tokenIndex; //
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }


    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; //
        _allTokensIndex[lastTokenId] = tokenIndex; //

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}
abstract contract ERC721Pausable is ERC721, Pausable {

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}


abstract contract ERC721Burnable is ERC721 {

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

/**
 * @dev {WOWERC721NTF}
 */
contract WOWERC721NTF is  ERC721Enumerable, ERC721Burnable, ERC721Pausable {
 
    event EMint(address indexed minter, address indexed to, uint256 indexed tokenId);

    string private _baseTokenURI;

    constructor() ERC721() {
        _initAdmin();
        setupManager(msg.sender);
    }


    function baseURI() public view   returns (string memory) {
        return _baseTokenURI;
    }


    function getAllTokenIdsOf(address sender) public view returns(string memory tokenIds){
        require(msg.sender == sender || hasRole(msg.sender, MANAGER_ROLE), "ERC721 getAllTokenIdsOf : you have no role for this address");
        bytes memory ids =super._getAllTokenIdsOf(sender);
        tokenIds=string(ids);
    }


    function mintCard(string memory cardName, string memory nftUrl, string memory nftCate, string memory createTime) public returns (bool) {
        require(hasRole(msg.sender, MANAGER_ROLE), "ERC721 mintCard : must be the manager role can mint Card ");
        require(!_exitCard(cardName), "This card already exists");
        return _mintCard(cardName,nftUrl,nftCate,createTime);
    }


    function mint(address to,uint256 tokenId,string memory cardName) public  {
        require(hasRole(msg.sender, MANAGER_ROLE), "mint: must be the manager role can mint token");
        require(tokenId>0, "mint: tokenId must be greater than 0");
        _mint(to, tokenId, cardName);
        emit EMint(msg.sender,to,tokenId);
    }

    function pause() public virtual {
        require(hasRole(msg.sender, MANAGER_ROLE),"pause: must be the manager role can  pause");
        _pause();
    }

    function unpause() public  {
        require(hasRole(msg.sender, MANAGER_ROLE), "unpause: must be manager role can unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view  override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }
}