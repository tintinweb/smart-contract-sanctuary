/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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

library Strings {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED; _; _status = _NOT_ENTERED;

    }

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

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {

    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

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

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);

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
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

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
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


//██///////█████//██████//██////██//█████//////██///////█████//██████//███████//
//██//////██///██/██///██/██////██/██///██/////██//////██///██/██///██/██///////
//██//////███████/██████//██////██/███████/////██//////███████/██///██/███████//
//██//////██///██/██///██//██//██//██///██/////██//////██///██/██///██//////██//
//███████/██///██/██///██///████///██///██/////███████/██///██/██████//███████//


contract LarvaLadsTest is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply = 5000;
    uint256 public price = 0.05 ether;
    uint256 public maxMint = 10;
    uint256 public numTokensMinted;

    string[8] private baseColors = ['#AE8B61','#DBB181','#E8AA96','#FFC2C2','#EECFA0','#C9CDAF','#D5C6E1','#EAD9D9'];
    string[7] private thirdNames = ['Smile', 'Frown', 'Handlebars', 'Zombie', 'Alien', 'Ape', 'Normal'];
    string[7] private thirdLayers = [
        '<path fill="#000" d="M16 17h1v1h-1z"/>',
        '<path fill="#000" d="M16 19h1v1h-1z"/>',
        '<path stroke="#A66E2C" d="M16.5 20v-2m3.5-.5h-3m3.5.5v2"/><path stroke="#C28946" d="M16 17.5h1m3 0h1"/>',
        '<path fill="#7DA269" d="M22 10v12h-2v2h-1v1H5v-1h1v-1h1v-1h1v-1h1v-1h2v-1h2v-9h1V9h2V8h-1V7h3v1h1v1h2v1h1z"/><path fill="#000" fill-opacity=".4" d="M17 12h-2v1h2v-1zM20 12v1h2v-1h-2zM22 21h-9v1h1v1h6v-1h2v-1zM12 19h-1v6h2v-1h-1v-5zM10 25v-5H9v5h1zM8 25v-3H7v3h1zM6 24H5v1h1v-1zM16 14h-1v1h1v-1zM21 14h-1v1h1v-1zM18 19h-1v1h1v-1z"/><path fill="red" d="M15 13h1v1h-1v-1zM20 13h1v1h-1v-1z"/><path fill="#000" d="M17 13h-1v1h1v-1zM22 13h-1v1h1v-1zM20 16v-1h-2v1h2zM17 18v1h3v-1h-3z"/>',
        '<path fill="#C8FBFB" d="M22 10v12h-2v2h-1v1H5v-1h1v-1h1v-1h1v-1h1v-1h2v-1h2v-9h1V9h2V8h-1V7h3v1h1v1h2v1h1z"/><path stroke="#75BDBD" d="M15.5 12v1m5-1v1"/><path fill="#000" d="M21 19v-1h-5v1h5zM15 13h1v-1h1v1h-1v1h-1v-1zM21 12h1v1h-1v1h-1v-1h1v-1z"/><path fill="#9BE0E0" d="M22 21h-9v1h1v1h6v-1h2v-1zM12 19h-1v6h2v-1h-1v-5zM10 25v-5H9v5h1zM8 25v-3H7v3h1zM6 24H5v1h1v-1zM17 13h-1v1h1v-1zM22 13h-1v1h1v-1zM19 14h-1v3h1v-3z"/>',
        '<path fill="#61503D" d="M22 10v12h-2v2h-1v1H5v-1h1v-1h1v-1h1v-1h1v-1h2v-1h2v-9h1V9h2V8h-1V7h3v1h1v1h2v1h1z"/><path fill="#958A7D" stroke="#958A7D" d="M16.5 19.5v-1h-1v-1h1v-2h-1v-1h-1v-3h2v-1h3v1h2v4h-1v2h1v1h-1v1h-4z"/><path fill="#000" fill-opacity=".4" d="M17 12h-2v1h2v-1zM20 12v1h2v-1h-2zM22 21h-9v1h1v1h6v-1h2v-1zM12 19h-1v6h2v-1h-1v-5zM10 25v-5H9v5h1zM8 25v-3H7v3h1zM6 24H5v1h1v-1z"/><path fill="#000" d="M16 13h-1v1h1v-1zM21 13h-1v1h1v-1zM18 16v-1h-1v1h1zM17 18v1h3v-1h-3zM19.724 16v-1h-1v1h1z"/><path fill="#AAA197" d="M17 14h-1v-1h1v1zM22 14h-1v-1h1v1z"/>',
        ''];
    string[8] private fourthNames = ['3D Glasses','VR','Small Shades','Eye Patch','Classic Shades','Regular Shades','Horned Rim Glasses','None'];
    string[8] private fourthLayers = [
        '<path fill="#F0F0F0" d="M12 11h11v4h-9v-3h-2v-1z"/><path fill="#FD3232" d="M19 12h3v2h-3z"/><path fill="#328DFD" d="M15 12h3v2h-3z"/>',
        '<path fill="#B4B4B4" d="M14 11h9v4h-9z"/><path stroke="#000" d="M14 15.5h8m-8-5h8M13.5 14v1m10-4v4m-10-4v1m2 .5v1h6v-1h-6z"/><path stroke="#8D8D8D" d="M13.5 12v2m1 0v1m0-4v1m8-1v1m0 2v1"/>',
        '<path fill="#000" d="M13 13v-1h9v3h-2v-2h-3v2h-2v-2h-2z"/>',
        '<path fill="#000" d="M13 11h9v1h-4v2h-1v1h-2v-1h-1v-2h-1v-1z"/>',
        '<path stroke="#000" d="M13 11.5h9m-7 3h2m.5-.5v-2m2 0v2m.5.5h2m-7.5-.5v-2"/><path stroke="#5C390F" d="M15 12.5h2m3 0h2"/><path stroke="#C77514" d="M15 13.5h2m3 0h2"/>',
        '<path fill="#000" d="M13 12h11v2h-1v1h-2v-1h-1v-1h-2v1h-1v1h-2v-1h-1v-1h-1v-1z"/>',
        '<path fill="#fff" fill-opacity=".5" d="M14 12h3v3h-3zM19 12h3v3h-3z"/><path fill="#000" d="M13 11h11v2h-1v-1h-4v1h-2v-1h-3v1h-1v-2z"/>',
        ''];
    string[14] private fifthNames = ['Beanie','Cowboy Hat','Fedora','Police Cap','Do-rag','Knitted Cap','Bandana','Peak Spike','Wild Hair','Messy Hair','Cap Forward','Cap','Top Hat','None'];
    string[14] private fifthLayers = [
        '<path fill="#3CC300" d="M14 10h7v1h-7z"/><path fill="#0060C3" d="M16 6v4h-4V8h1V7h1V6h2z"/><path fill="#D60404" d="M19 6v4h4V8h-1V7h-1V6h-2z"/><path fill="#E4EB17" d="M14 9h1V8h1V6h3v2h1v1h1v1h-7V9z"/><path fill="#000" d="M17 5h1v1h-1z"/><path fill="#0060C3" d="M15 4h5v1h-5z"/>',
        '<path fill="#794B11" d="M8 7h1v1h4V4h1V3h2v1h3V3h2v1h1v4h4V7h1v2h-1v1H9V9H8V7z"/><path fill="#502F05" d="M12 7h11v1H12z"/>',
        '<path fill="#3D2F1E" d="M9 9h1V8h3V6h1V4h1V3h5v1h1v2h1v2h3v1h1v1H9V9z"/><path fill="#000" d="M12 7h11v1H12z"/>',
        '<path fill="#26314A" d="M12 5h11v5H12z"/><path stroke="#fff" d="M13 8.5h1m1 0h1m1 0h1m1 0h1m1 0h1"/><path stroke="#FFD800" d="M17 6.5h1"/><path fill="#000" fill-rule="evenodd" d="M23 6V5h-4V4h-3v1h-4v1h-1v2h1v2h3v1h9V9h-1V8h1V6h-1zm0 0h-4V5h-3v1h-4v2h1v1h1V8h1v2h8V9h-1V8h1V6zm-7 3h1V8h-1v1zm2 0h1V8h-1v1zm2 0h1V8h-1v1z" clip-rule="evenodd"/>',
        '<path fill="#4C4C4C" d="M13 7h9v4h-9z"/><path fill="#000" d="M13 10h-1V8h1V7h1V6h7v1h2v2h-1V8h-1V7h-7v1h-1v2z"/><path stroke="#636363" d="M14 9.5h1m0-1h1"/>',
        '<path fill="#CA4E11" d="M14 7h-1v3h9V7h-1V6h-7v1z"/><path fill="#933709" d="M12 8h11v2h-1V9h-1v1h-1V9h-1v1h-1V9h-1v1h-1V9h-1v1h-1V9h-1v1h-1V8z"/><path stroke="#000" d="M11.5 10V8m1 0V7m1 0V6m.5-.5h7m.5.5v1m1 0v1m1 0v2"/>',
        '<path fill="#1A43C8" d="M13 7h9v3H10v3H9v-3H8V9h5V7z"/><path stroke="#1637A4" d="M22 9.5h-1m0 1h-3m0-1h-4m8.5-.5V7m-.5-.5h-8m0 1h-1m0 1h-1m0 1h-1m0 1h-1m0-1H9"/><path stroke="#142C7C" d="M11 11.5h-1m2-1h-1m2-1h-1"/>',
        '<path fill="#000" d="M14 7V5h1V4h1v1h1V4h1v1h1V4h1v1h1v2h1v2h-3v1h-1v1h-1v-1h-1V9h-3V7h1zM12 9v1h1V9h-1z"/>',
        '<path stroke="#000" d="M12 4.5h2m4 0h5m-14 1h1m2 0h10m2 0h2m-17 1h16m-16 1h17m-16 1h15m-16 1h9m2 0h5m-17 1h7m2 0h2m2 0h3m-14 1h4m9 0h2m-16 1h5m9 0h2m-16 1h1m1 0h3m9.5-.5v2M10 14.5h4m-4 1h2"/>',
        '<path fill="#000" d="M14 11h1v1h-1zM15 10h1v1h-1zM18 9h1v3h-1zM12 9h6v1h-6zM13 10h1v1h-1zM11 10h1v1h-1zM11 8h3v1h-3zM12 7h2v1h-2zM13 6h2v1h-2zM14 5h6v1h-6zM21 5h1v2h-1zM21 7h3v1h-3zM21 10h3v1h-3zM20 8h3v2h-3zM15 7h4v2h-4z"/><path fill="#000" d="M17 6h4v2h-4z"/><path fill="#000" d="M14 6h4v3h-4z"/><path stroke="#000" d="M14 5.5h6m1 0h1m-9 1h9m-10 1h12m-13 1h8m1 0h3m-11 1h7m1 0h3m-12 1h1m1 0h1m1 0h1m-2 1h1m3.5-1.5v2m2.5-1.5h3"/>',
        '<path fill="#515151" d="M13 6h9v4h-9V6z"/><path stroke="#000" d="M12 10.5h12.5V9m-.5-.5h-8m0 1h-1m8-2h-1m0-1h-1m0-1h-7m0 1h-1m-.5.5v3"/><path stroke="#353535" d="M24 9.5h-8m-1-3h-1m0 1h-1"/>',
        '<path fill="#8119B7" d="M12 7h1V6h1V5h7v1h1v2h3v1h1v1H12V7z"/><path stroke="#B261DC" d="M21 7.5h-1m0-1h-1"/>',
        '<path fill="#000" d="M13 2h9v1h1v5h1v1h1v1H10V9h1V8h1V3h1V2z"/><path fill="#DC1D1D" d="M12 7h11v1H12z"/>',
        ''];
    string[5] private sixthNames = ['Earring','Vape','Cigarette','Pipe','None'];
    string[5] private sixthLayers = [
        '<path fill="#FFD926" d="M12 14h1v1h-1z"/>',
        '<path stroke="#000" d="M20 17.5h7m1 1h-1m0 1h-7"/><path stroke="#595959" d="M20 18.5h6"/><path stroke="#0040FF" d="M26 18.5h1"/>',
        '<path stroke="#000" d="M20 17.5h7m1 1h-1m0 1h-7"/><path stroke="#D7D1D1" d="M20 18.5h6"/><path stroke="#E7A600" d="M26 18.5h1"/><path fill="#fff" fill-opacity=".4" d="M26 11h1v5h-1z"/>',
        '<path stroke="#000" d="M20 18.5h1m0 1h1m0 1h1m0 1h1.5v-2h4V22m-1 0v1m-.5.5h-4m0-1h-1m0-1h-1m0-1h-1m0-1h-1"/><path stroke="#855114" d="M20 19.5h1m0 1h1m0 1h1m0 1h3m-1-2h3m-2 1h1"/><path stroke="#683C08" d="M25 21.5h1m0 1h1m0-1h1"/><path stroke="#fff" stroke-opacity=".4" d="M26.5 12v1.5m0 0H25m1.5 0H28M26.5 15v1m0 1v1"/>',
        ''];

    struct LarvaObject {
        uint256 baseColor;
        uint256 layerThree;
        uint256 layerFour;
        uint256 layerFive;
        uint256 layerSix;
    }

    function randomLarvaLad(uint256 tokenId) internal view returns (LarvaObject memory) {
        
        LarvaObject memory larvaLad;

        larvaLad.baseColor = getBaseColor(tokenId);
        larvaLad.layerThree = getLayerThree(tokenId);
        larvaLad.layerFour = getLayerFour(tokenId);
        larvaLad.layerFive = getLayerFive(tokenId);
        larvaLad.layerSix = getLayerSix(tokenId);

        return larvaLad;
    }
    
    function getTraits(LarvaObject memory larvaLad) internal view returns (string memory) {
        
        string[20] memory parts;
        
        parts[0] = ', "attributes": [{"trait_type": "Type","value": "';
        if (larvaLad.layerThree == 3) {
            parts[1] = 'Zombie"}, {"trait_type": "Mouth","value": "Zombie"},'; 
        }
        if (larvaLad.layerThree == 4) {
            parts[2] = 'Alien"}, {"trait_type": "Mouth","value": "Alien"},'; 
        }
        if (larvaLad.layerThree == 5) {
            parts[3] = 'Ape"}, {"trait_type": "Mouth","value": "Ape"},'; 
        }
        if (larvaLad.layerThree < 3 || larvaLad.layerThree > 5) {
            parts[4] = 'Normal"}, {"trait_type": "Mouth","value": "';
            parts[5] = thirdNames[larvaLad.layerThree];
            parts[6] = '"},';
        }
        parts[7] = ' {"trait_type": "Eyewear","value": "';
        parts[8] = fourthNames[larvaLad.layerFour];
        parts[9] = '"}, {"trait_type": "Headwear","value": "';
        parts[10] = fifthNames[larvaLad.layerFive];
        parts[11] = '"}, {"trait_type": "Accessory","value": "';
        parts[12] = sixthNames[larvaLad.layerSix];
        parts[13] = '"}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
                      output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13]));
        return output;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBaseColor(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("BASE COLOR", toString(tokenId))));

        uint256 rn1 = rand % 79;
        uint256 bc = 0;

        if (rn1 >= 10 && rn1 < 20) { bc = 1; }
        if (rn1 >= 20 && rn1 < 30) { bc = 2; }
        if (rn1 >= 30 && rn1 < 40) { bc = 3; }
        if (rn1 >= 40 && rn1 < 50) { bc = 4; }
        if (rn1 >= 50 && rn1 < 60) { bc = 5; }
        if (rn1 >= 60 && rn1 < 70) { bc = 6; }
        if (rn1 >= 70) { bc = 7; }

        return bc;
    }

    function getLayerThree(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER THREE", toString(tokenId))));

        uint256 rn3 = rand % 170;
        uint256 l3 = 0;

        if (rn3 >= 46 && rn3 < 64) { l3 = 1; }
        if (rn3 >= 64 && rn3 < 81) { l3 = 2; }
        if (rn3 >= 81 && rn3 < 85) { l3 = 3; }
        if (rn3 == 85) { l3 = 4; }
        if (rn3 >= 86 && rn3 < 88) { l3 = 5; }
        if (rn3 >= 88) { l3 = 6; }
        
        return l3;
    }

    function getLayerFour(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER FOUR", toString(tokenId))));

        uint256 rn4 = rand % 500;
        uint256 l4 = 0;

        if (rn4 >= 41 && rn4 < 81) { l4 = 1; }
        if (rn4 >= 81 && rn4 < 121) { l4 = 2; }
        if (rn4 >= 121 && rn4 < 161) { l4 = 3; }
        if (rn4 >= 161 && rn4 < 201) { l4 = 4; }
        if (rn4 >= 201 && rn4 < 261) { l4 = 5; }
        if (rn4 >= 261 && rn4 < 281) { l4 = 6; }
        if (rn4 >= 281) { l4 = 7; }
        
        return l4;
    }

    function getLayerFive(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER FIVE", toString(tokenId))));

        uint256 rn5 = rand % 240;
        uint256 l5 = 0;

        if (rn5 >= 10 && rn5 < 20) { l5 = 1; }
        if (rn5 >= 20 && rn5 < 30) { l5 = 2; }
        if (rn5 >= 30 && rn5 < 40) { l5 = 3; }
        if (rn5 >= 40 && rn5 < 50) { l5 = 4; }
        if (rn5 >= 50 && rn5 < 60) { l5 = 5; }
        if (rn5 >= 60 && rn5 < 70) { l5 = 6; }
        if (rn5 >= 70 && rn5 < 80) { l5 = 7; }
        if (rn5 >= 80 && rn5 < 90) { l5 = 8; }
        if (rn5 >= 90 && rn5 < 100) { l5 = 9; }
        if (rn5 >= 100 && rn5 < 110) { l5 = 10; }
        if (rn5 >= 110 && rn5 < 120) { l5 = 11; }
        if (rn5 >= 120 && rn5 < 130) { l5 = 12; }
        if (rn5 >= 130) { l5 = 13; }
        
        return l5;
    }

    function getLayerSix(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER SIX", toString(tokenId))));

        uint256 rn6 = rand % 120;
        uint256 l6 = 0;

        if (rn6 >= 10 && rn6 < 20) { l6 = 1; }
        if (rn6 >= 20 && rn6 < 30) { l6 = 2; }
        if (rn6 >= 30 && rn6 < 40) { l6 = 3; }
        if (rn6 >= 40) { l6 = 4; }
        
        return l6;
    }

    function getSVG(LarvaObject memory larvaLad) internal view returns (string memory) {
        string[9] memory parts;

        parts[0] = '<svg id="x" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 30 30"><path fill="#638596" d="M0 0h30v30H0z"/>';
        parts[1] = '<path fill="';
        parts[2] = baseColors[larvaLad.baseColor];
        parts[3] = '" d="M22 10v12h-2v2h-1v1H5v-1h1v-1h1v-1h1v-1h1v-1h2v-1h2v-9h1V9h2V8h-1V7h3v1h1v1h2v1h1z"/><path fill="#000" d="M4 24v2h16v-2h-1v1H5v-1H4zM6 23H5v1h1v-1zM7 22H6v1h1v-1zM8 21H7v1h1v-1zM9 20H8v1h1v-1zM11 19H9v1h2v-1zM12 10v8h-1v1h2v-9h-1zM14 10V9h-1v1h1zM15 8V7h-1v2h2V8h-1zM18 6h-3v1h3V6zM19 7h-1v1h1V7zM21 8h-2v1h2V8zM23 22V9h-2v1h1v12h1zM21 24v-1h1v-1h-2v2h1zM15 13h1v1h-1v-1zM20 13h1v1h-1v-1zM18 15h2v1h-2v-1zM17 18h3v1h-3v-1z"/><path fill="#000" fill-opacity=".2" d="M17 13h-1v1h1v-1zM22 13h-1v1h1v-1z"/><path fill="#000" fill-opacity=".4" d="M17 12h-2v1h2v-1zM20 12v1h2v-1h-2zM22 21h-9v1h1v1h6v-1h2v-1zM12 19h-1v6h2v-1h-1v-5zM10 25v-5H9v5h1zM8 25v-3H7v3h1zM6 24H5v1h1v-1z"/>';
        parts[4] = thirdLayers[larvaLad.layerThree];
        parts[5] = fourthLayers[larvaLad.layerFour];
        parts[6] = fifthLayers[larvaLad.layerFive];
        parts[7] = sixthLayers[larvaLad.layerSix];
        parts[8] = '<style>#x{shape-rendering: crispedges;}</style></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));

        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        LarvaObject memory larvaLad = randomLarvaLad(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Larva Lad #', toString(tokenId), '", "description": "Larva Lads are a play on the CryptoPunks and their creators, Larva Labs. The artwork and metadata are fully on-chain and were randomly generated at mint."', getTraits(larvaLad), '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(larvaLad))), '"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function mint(address destination, uint256 amountOfTokens) private {
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");
        require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
        require(amountOfTokens > 0, "Must mint at least one token");
        require(price * amountOfTokens == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(destination, tokenId);
            numTokensMinted += 1;
        }
    }

    function mintForSelf(uint256 amountOfTokens) public payable virtual {
        mint(_msgSender(),amountOfTokens);
    }

    function mintForFriend(address walletAddress, uint256 amountOfTokens) public payable virtual {
        mint(walletAddress,amountOfTokens);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setMaxMint(uint256 newMaxMint) public onlyOwner {
        maxMint = newMaxMint;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

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
    
    constructor() ERC721("Larva Lads Test", "LARVATEST") Ownable() {}
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

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