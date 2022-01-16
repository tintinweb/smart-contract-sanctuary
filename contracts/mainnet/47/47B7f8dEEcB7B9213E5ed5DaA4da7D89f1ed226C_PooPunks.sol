/**
 *Submitted for verification at Etherscan.io on 2022-01-16
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


//   /$$$$$$$                           /$$$$$$$                      /$$                
//  | $$__  $$                         | $$__  $$                    | $$                
//  | $$  \ $$ /$$$$$$   /$$$$$$       | $$  \ $$ /$$   /$$ /$$$$$$$ | $$   /$$  /$$$$$$$
//  | $$$$$$$//$$__  $$ /$$__  $$      | $$$$$$$/| $$  | $$| $$__  $$| $$  /$$/ /$$_____/
//  | $$____/| $$  \ $$| $$  \ $$      | $$____/ | $$  | $$| $$  \ $$| $$$$$$/ |  $$$$$$ 
//  | $$     | $$  | $$| $$  | $$      | $$      | $$  | $$| $$  | $$| $$_  $$  \____  $$
//  | $$     |  $$$$$$/|  $$$$$$/      | $$      |  $$$$$$/| $$  | $$| $$ \  $$ /$$$$$$$/
//  |__/      \______/  \______/       |__/       \______/ |__/  |__/|__/  \__/|_______/ 
// 


contract PooPunks is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply = 6969;
    uint256 public price = 0.02 ether;
    uint256 public maxMint = 10;
    uint256 public numTokensMinted;

   string[8] private baseColors = ['#EAD9D9','#DBB181','#AE8B61','#C9CDAF','#D5C6E1','#FFC2C2','#EECFA0','#E8AA96'];
    string[7] private thirdNames = ['Smile', 'Frown', 'Handlebars', 'Zombie', 'Alien', 'Ape', 'Normal'];
    string[7] private thirdLayers = [
        '<path fill="#000" d="M16 17h1v1h-1z"/>',
        '<path fill="#000" d="M16 19h1v1h-1z"/>',
        '<path stroke="#A66E2C" d="M16.5 20v-2m3.5-.5h-3m3.5.5v2"/><path stroke="#C28946" d="M16 17.5h1m3 0h1"/>',
        '<path fill="#7DA269" d="M14.915 2.475c-.586.724-1.38 1.274-1.67 2.3-.168.694-.27 1.435-.144 2.155.07.454.187.89.322 1.319a3.62 4.162 0 0 0-2.052 3.245 5.462 6.826 0 0 0-2.125 4.951 6.12 4.495 0 0 0-2.52 3.628 6.12 4.495 0 0 0 6.12 4.495 6.12 4.495 0 0 0 2.832-.512 7.502 4.495 0 0 0 3.947.678 7.502 4.495 0 0 0 7.502-4.494 7.502 4.495 0 0 0-1.617-2.787 4.41 5.078 0 0 0 .038-.626 4.41 5.078 0 0 0-4.358-5.075 2.5 4.245 0 0 0-1.696-3.61c.004-.076.005-.152.002-.23.008-.728-.388-1.369-.9-1.658-.654-.416-1.398-.48-2.099-.693-.696-.287-1.032-1.198-1.248-2.012-.117-.326-.178-.906-.334-1.074z"/><path fill-opacity=".4" d="M17 12h-2v1h2v-1zm3 0v1h2v-1h-2zm-4 2h-1v1h1v-1zm5 0h-1v1h1v-1zm-3 5h-1v1h1v-1z"/><path fill="red" d="M15 13h1v1h-1v-1zm5 0h1v1h-1v-1z"/><path d="M17 13h-1v1h1v-1zm5 0h-1v1h1v-1zm-2 3v-1h-2v1h2zm-3 2v1h3v-1h-3z"/>',
        '<path fill="#C8FBFB" d="M14.915 2.475c-.586.724-1.38 1.274-1.67 2.3-.168.694-.27 1.435-.144 2.155.07.454.187.89.322 1.319a3.62 4.162 0 0 0-2.052 3.245 5.462 6.826 0 0 0-2.125 4.951 6.12 4.495 0 0 0-2.52 3.628 6.12 4.495 0 0 0 6.12 4.495 6.12 4.495 0 0 0 2.832-.512 7.502 4.495 0 0 0 3.947.678 7.502 4.495 0 0 0 7.502-4.494 7.502 4.495 0 0 0-1.617-2.787 4.41 5.078 0 0 0 .038-.626 4.41 5.078 0 0 0-4.358-5.075 2.5 4.245 0 0 0-1.696-3.61c.004-.076.005-.152.002-.23.008-.728-.388-1.369-.9-1.658-.654-.416-1.398-.48-2.099-.693-.696-.287-1.032-1.198-1.248-2.012-.117-.326-.178-.906-.334-1.074z"/><path stroke="#75BDBD" d="M15.5 12v1m5-1v1"/><path d="M21 19v-1h-5v1h5zm-6-6h1v-1h1v1h-1v1h-1v-1zm6-1h1v1h-1v1h-1v-1h1v-1z"/><path fill="#9BE0E0" d="M22 21h-1 1v-1zm-5-8h-1v1h1v-1zm5 0h-1v1h1v-1zm-3 1h-1v3h1v-3z"/>',
        '<path fill="#61503D" d="M14.915 2.475c-.586.724-1.38 1.274-1.67 2.3-.168.694-.27 1.435-.144 2.155.07.454.187.89.322 1.319a3.62 4.162 0 0 0-2.052 3.245 5.462 6.826 0 0 0-2.125 4.951 6.12 4.495 0 0 0-2.52 3.628 6.12 4.495 0 0 0 6.12 4.495 6.12 4.495 0 0 0 2.832-.512 7.502 4.495 0 0 0 3.947.678 7.502 4.495 0 0 0 7.502-4.494 7.502 4.495 0 0 0-1.617-2.787 4.41 5.078 0 0 0 .038-.626 4.41 5.078 0 0 0-4.358-5.075 2.5 4.245 0 0 0-1.696-3.61c.004-.076.005-.152.002-.23.008-.728-.388-1.369-.9-1.658-.654-.416-1.398-.48-2.099-.693-.696-.287-1.032-1.198-1.248-2.012-.117-.326-.178-.906-.334-1.074z"/><path fill="#958A7D" stroke="#958A7D" d="M16.5 19.5v-1h-1v-1h1v-2h-1v-1h-1v-3h1v-1h3v1h2v4h-1v2h1v1h-1v1h-4z"/><path fill-opacity=".4" d="M16 12h-2v1h2v-1zm3 0v1h2v-1h-2z"/><path d="M15 13h-1v1h1v-1zm5 0h-1v1h1v-1zm-3 3v-1h-1v1h1zm-1 2v1h3v-1h-3zm3.724-2v-1h-1v1h1z"/><path fill="#AAA197" d="M16 14h-1v-1h1v1zm5 0h-1v-1h1v1z"/>',
        ''];
    string[8] private fourthNames = ['3D Glasses','VR','Small Shades','Eye Patch','Classic Shades','Regular Shades','Horned Rim Glasses','None'];
    string[8] private fourthLayers = [
        '<path fill="#F0F0F0" d="M12 11h11v4h-9v-3h-3v-1z"/><path fill="#FD3232" d="M19 12h3v2h-3z"/><path fill="#328DFD" d="M15 12h3v2h-3z"/>',
        '<path fill="#B4B4B4" d="M14 11h9v4h-9z"/><path stroke="#000" d="M14 15.5h8m-8-5h8M13.5 14v1m10-4v4m-10-4v1m2 .5v1h6v-1h-6z"/><path stroke="#8D8D8D" d="M13.5 12v2m1 0v1m0-4v1m8-1v1m0 2v1"/><path d="M13.1 13.2c-.877.047-1.769.047-2.562-.282l-.05-.6" stroke-width=".8" stroke="#000"/>',
        '<path d="M13 13v-1h9v3h-2v-2h-3v2h-2v-2h-2z"/><path stroke="#000" d="M13.163 12.481h-2.5"/> ',
        '<path stroke="#000" d="M13.5 11.5h-2.4"/><path d="M13 11h9v1h-4v2h-1v1h-2v-1h-1v-2h-1v-1z"/>',
        '<path stroke="#000" d="M13 11.5h9m-7 3h2m.5-.5v-2m2 0v2m.5.5h2m-7.5-.5v-2"/><path stroke="#5C390F" d="M15 12.5h2m3 0h2"/><path stroke="#C77514" d="M15 13.5h2m3 0h2"/><path stroke="#000" d="m22.467 14.126-.047-2.162M13.5 11.5h-2.3"/>',
        '<path fill="#000" d="M13 12h11v2h-1v1h-2v-1h-1v-1h-2v1h-1v1h-2v-1h-1v-1h-1v-1z"/><path stroke="#000" d="M13.5 12.5h-2.9"/>',
        '<path fill="#fff" fill-opacity=".5" d="M14 12h3v3h-3zM19 12h3v3h-3z"/><path fill="#000" d="M11 11h11v2h-1v-1h-2v1h-2v-1h-2v1h-1v-2z"/><path stroke="#000" d="M14 11.5h-2.7"/>',
        ''];
    string[14] private fifthNames = ['Beanie','Cowboy Hat','Fedora','Police Cap','Do-rag','Knitted Cap','Bandana','Peak Spike','Wild Hair','Messy Hair','Cap Forward','Cap','Top Hat','None'];
    string[14] private fifthLayers = [
        '<path fill="#3CC300" d="m12.96617,6.2406l7,0l0,1l-7,0l0,-1z"/><path fill="#0060C3" d="m14.96617,2.2406l0,4l-4,0l0,-2l1,0l0,-1l1,0l0,-1l2,0z"/><path fill="#D60404" d="m17.96617,2.2406l0,4l4,0l0,-2l-1,0l0,-1l-1,0l0,-1l-2,0z"/><path fill="#E4EB17" d="m12.96617,5.2406l1,0l0,-1l1,0l0,-2l3,0l0,2l1,0l0,1l1,0l0,1l-7,0l0,-1z"/><path fill="#000" d="m15.96617,1.2406l1,0l0,1l-1,0l0,-1z"/><path fill="#0060C3" d="m13.96617,0.2406l5,0l0,1l-5,0l0,-1z"/>',
        '<path d="m7.29511,5.59023l1,0l0,1l4,0l0,-4l1,0l0,-1l2,0l0,1l3,0l0,-1l2,0l0,1l1,0l0,4l4,0l0,-1l1,0l0,2l-1,0l0,1l-17,0l0,-1l-1,0l0,-2z" fill="#794B11"/><path d="m11.29511,5.59023l11,0l0,1l-11,0l0,-1z" fill="#502F05"/>',
        '<path d="m7.49624,7.54323l1,0l0,-1l3,0l0,-2l1,0l0,-2l1,0l0,-1l5,0l0,1l1,0l0,2l1,0l0,2l3,0l0,1l1,0l0,1l-17,0l0,-1z" fill="#3D2F1E"/><path d="m10.49624,5.54323l11,0l0,1l-11,0l0,-1z" fill="#000"/>',
        '<path fill="#26314A" d="m11.90602,2.79135l7.05263,0l0,4.24812l-7.05263,0l0,-4.24812z"/><path stroke="#fff" d="m12.34211,5.77444l0.67105,0m0.67105,0l0.67105,0m0.67105,0l0.67105,0m0.67105,0l0.67105,0m0.67105,0l0.67105,0" fill="black"/> <path fill="black"  d="m14.88533,4.11654l1,0" stroke="#FFD800"/><path fill="#000" fill-rule="evenodd" d="m18.85743,3.63695l0,-0.85231l-2.52516,0l0,-0.85231l-1.89387,0l0,0.85231l-2.52516,0l0,0.85231l-0.63129,0l0,1.70462l0.63129,0l0,1.70462l1.89387,0l0,0.85231l5.68161,0l0,-1.70462l-0.63129,0l0,-0.85231l0.63129,0l0,-1.70462l-0.63129,0zm0,0l-2.52516,0l0,-0.85231l-1.89387,0l0,0.85231l-2.52516,0l0,1.70462l0.63129,0l0,0.85231l0.63129,0l0,-0.85231l0.63129,0l0,1.70462l5.05032,0l0,-0.85231l-0.63129,0l0,-0.85231l0.63129,0l0,-1.70462zm-4.41903,2.55693l0.63129,0l0,-0.85231l-0.63129,0l0,0.85231zm1.26258,0l0.63129,0l0,-0.85231l-0.63129,0l0,0.85231zm1.26258,0l0.63129,0l0,-0.85231l-0.63129,0l0,0.85231z" clip-rule="evenodd"/>',
        '<path d="m12.85902,2.91165l6.55639,0l0,4l-6.55639,0l0,-4z" fill="#4C4C4C"/><path d="m12.86757,5.91165l-0.72659,0l0,-2l0.72659,0l0,-1l0.72659,0l0,-1l5.08612,0l0,1l1.45318,0l0,2l-0.72659,0l0,-1l-0.72659,0l0,-1l-5.08612,0l0,1l-0.72659,0l0,2z" fill="#000"/><path fill="black" stroke="#636363" d="m14.28195,5.50564l1,0m0,-1l1,0"/>',
        '<path  d="m13.87991,3.96898l-0.64495,0l0,2.92951l5.80451,0l0,-2.92951l-0.64495,0l0,-0.9765l-4.51462,0l0,0.9765z" fill="#CA4E11"/><path d="m12.93985,4.94549l6.53571,0l0,2l-0.59416,0l0,-1l-0.59416,0l0,1l-0.59416,0l0,-1l-0.59416,0l0,1l-0.59416,0l0,-1l-0.59416,0l0,1l-0.59416,0l0,-1l-0.59416,0l0,1l-0.59416,0l0,-1l-0.59416,0l0,1l-0.59416,0l0,-2z" fill="#933709"/><path stroke="#000" fill="black" d="m13.00376,7.03947l0,-2m0.51833,0l0,-1m0.51833,0l0,-1m0.25916,-0.5l3.62829,0m0.25916,0.5l0,1m0.51833,0l0,1m0.51833,0l0,2"/>',
        '<path  d="m14.01034,2.91165l6.67387,0l0,3.28195l-8.8985,0l0,3.28195l-0.74154,0l0,-3.28195l-0.74154,0l0,-1.09398l3.70771,0l0,-2.18797z" fill="#1A43C8"/><path stroke="#1637A4" fill="black"  d="m20.49972,5.64662l-0.80507,0m0,1l-2.4152,0m0,-1l-3.22027,0m6.84308,-0.5l0,-2m-0.40253,-0.5l-6.44055,0m0,1l-0.80507,0m0,1l-0.80507,0m0,1l-0.80507,0m0,1l-0.80507,0m0,-1l-0.80507,0"/><path stroke="#142C7C" fill="black" d="m12.40977,6.61278l-0.90602,0m1.81203,-1l-0.90602,0m1.81203,-1l-0.90602,0"/>',
        '<path d="m13.55827,4.2073l0,-2.08056l0.70865,0l0,-1.04028l0.70865,0l0,1.04028l0.70865,0l0,-1.04028l0.70865,0l0,1.04028l0.70865,0l0,-1.04028l0.70865,0l0,1.04028l0.70865,0l0,2.08056l0.70865,0l0,2.08056l-2.12594,0l0,1.04028l-0.70865,0l0,1.04028l-0.70865,0l0,-1.04028l-0.70865,0l0,-1.04028l-2.12594,0l0,-2.08056l0.70865,0zm-1.41729,2.08056l0,1.04028l0.70865,0l0,-1.04028l-0.70865,0z" fill="#000"/>',
        '<path stroke="#000" fill="black" d="m10.68943,2.10338l1.79114,0m3.58229,0l4.47786,0m-12.53801,0.96582l0.89557,0m1.79114,0l8.95572,0m1.79114,0l1.79114,0m-15.22473,0.96582l14.32916,0m-14.32916,0.96582l15.22473,0m-14.32916,0.96582l13.43358,0m-14.32916,0.96582l8.06015,0m1.79114,0l4.47786,0m-15.22473,0.96582l6.26901,0m1.79114,0l1.79114,0m1.79114,0l2.68672,0m-12.53801,0.96582l3.58229,0m8.06015,0l1.79114,0m-14.32916,0.96582l4.47786,0m8.06015,0l1.79114,0m-14.32916,0.96582l0.89557,0m0.89557,0l2.68672,0m8.50794,-0.48291l0,1.93165m-12.09023,-0.48291l3.58229,0m-3.58229,0.96582l1.79114,0"/>',
        '<path d="M12.456 8.603h1.019v1h-1.019v-1zm1.019-1h1.018v1h-1.018v-1zm3.054-1h1.018v3h-1.018v-3zm-6.109 0h6.109v1H10.42v-1zm1.018 1h1.018v1h-1.018v-1zm-2.036 0h1.018v1H9.402v-1zm0-2h3.054v1H9.402v-1zm1.018-1h2.036v1H10.42v-1zm1.018-1h2.037v1h-2.037v-1zm1.018-1h6.109v1h-6.109v-1zm7.127 0h1.018v2h-1.018v-2zm0 2h3.054v1h-3.054v-1zm0 3h3.054v1h-3.054v-1zm-1.018-2h3.054v2h-3.054v-2zm-5.09-1h4.072v2h-4.072v-2z"/><path d="M17 6h4v2h-4V6z"/><path d="M14.564 3.98h4v3h-4v-3z"/><path stroke="#000" d="M13.082 3.95h5.197m.867 0h.866m-7.796 1h7.796m-8.663 1h10.395m-11.26 1h6.93m.865 0h2.6m-9.53 1h6.064m.866 0h2.6m-10.396 1h.866m.867 0h.866m.866 0h.866m-1.732 1h.866m3.032-1.5v2m2.166-1.5h2.598"/>',
        '<path d="m11.16729,3.36842l9,0l0,4l-9,0l0,-4z" fill="#515151"/><path d="m10.16729,7.86842l12.5,0l0,-1.5m-0.5,-0.5l-8,0m0,1l-1,0m8,-2l-1,0m0,-1l-1,0m0,-1l-7,0m0,1l-1,0m-0.5,0.5l0,3" stroke="#000"/><path d="m22.16729,6.86842l-8,0m-1,-3l-1,0m0,1l-1,0" stroke="#353535"/>',
        '<path d="m11.85902,4.57519l0.83888,0l0,-1.29135l0.83888,0l0,-1.29135l5.87218,0l0,1.29135l0.83888,0l0,2.58271l2.51665,0l0,1.29135l0.83888,0l0,1.29135l-11.74436,0l0,-3.87406z" fill="#8119B7"/><path fill="black" d="m19.44925,6.04323l-1,0m0,-1l-1,0" stroke="#B261DC"/>',
        '<path d="m13.6015,2.23496l4.88346,0l0,0.74154l0.54261,0l0,3.70771l0.54261,0l0,0.74154l0.54261,0l0,0.74154l-8.1391,0l0,-0.74154l0.54261,0l0,-0.74154l0.54261,0l0,-3.70771l0.54261,0l0,-0.74154z" fill="#000"/><path d="m12.93985,5.30827l5.9718,0l0,1l-5.9718,0l0,-1z" fill="#DC1D1D"/>',
        ''];
    string[5] private sixthNames = ['Covid','Vape','Cigarette','Pipe','None'];
    string[5] private sixthLayers = [
		'<path d="M11.547 22.17h1v1h-1v-1zm2.211-1.493h.952v1h-.952v-1zM20.75 22.6h.951v1h-.952v-1zm-4.422-.962h.952v1h-.952v-1zm2.643-1.057h.952v1h-.952v-1zm3.364.192h.952v1h-.952v-1z" fill="white"/>',
        '<path stroke="#000" d="M20 17.5h7m1 1h-1m0 1h-7"/><path stroke="#595959" d="M20 18.5h6"/><path stroke="#0040FF" d="M26 18.5h1"/>',
        '<path stroke="#000" d="M20 17.5h7m1 1h-1m0 1h-7"/><path stroke="#D7D1D1" d="M20 18.5h6"/><path stroke="#E7A600" d="M26 18.5h1"/><path fill="#fff" fill-opacity=".4" d="M26 11h1v5h-1z"/>',
        '<path stroke="#000" d="M20 18.5h1m0 1h1m0 1h1m0 1h1.5v-2h4V22m-1 0v1m-.5.5h-4m0-1h-1m0-1h-1m0-1h-1m0-1h-1"/><path stroke="#855114" d="M20 19.5h1m0 1h1m0 1h1m0 1h3m-1-2h3m-2 1h1"/><path stroke="#683C08" d="M25 21.5h1m0 1h1m0-1h1"/><path stroke="#fff" stroke-opacity=".4" d="M26.5 12v1.5m0 0H25m1.5 0H28M26.5 15v1m0 1v1"/>',
        ''];

    struct PooObject {
        uint256 baseColor;
        uint256 layerThree;
        uint256 layerFour;
        uint256 layerFive;
        uint256 layerSix;
    }

    function randompooPunk(uint256 tokenId) internal view returns (PooObject memory) {
        
        PooObject memory pooPunk;

        pooPunk.baseColor = getBaseColor(tokenId);
        pooPunk.layerThree = getLayerThree(tokenId);
        pooPunk.layerFour = getLayerFour(tokenId);
        pooPunk.layerFive = getLayerFive(tokenId);
        pooPunk.layerSix = getLayerSix(tokenId);

        return pooPunk;
    }
    
    function getTraits(PooObject memory pooPunk) internal view returns (string memory) {
        
        string[14] memory parts;
        
        parts[0] = ', "attributes": [{"trait_type": "Type","value": "';
        if (pooPunk.layerThree == 3) {
            parts[1] = 'Zombie"}, {"trait_type": "Mouth","value": "Zombie"},'; 
        }
        if (pooPunk.layerThree == 4) {
            parts[2] = 'Alien"}, {"trait_type": "Mouth","value": "Alien"},'; 
        }
        if (pooPunk.layerThree == 5) {
            parts[3] = 'Ape"}, {"trait_type": "Mouth","value": "Ape"},'; 
        }
        if (pooPunk.layerThree < 3 || pooPunk.layerThree > 5) {
            parts[4] = 'Normal"}, {"trait_type": "Mouth","value": "';
            parts[5] = thirdNames[pooPunk.layerThree];
            parts[6] = '"},';
        }
        parts[7] = ' {"trait_type": "Eyewear","value": "';
        parts[8] = fourthNames[pooPunk.layerFour];
        parts[9] = '"}, {"trait_type": "Headwear","value": "';
        parts[10] = fifthNames[pooPunk.layerFive];
        parts[11] = '"}, {"trait_type": "Accessory","value": "';
        parts[12] = sixthNames[pooPunk.layerSix];
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
        if (rn6 >= 50) { l6 = 4; }
        
        return l6;
    }

    function getSVG(PooObject memory pooPunk) internal view returns (string memory) {
        string[9] memory parts;

        parts[0] = '<svg id="x" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 30 30"><path fill="#B68D40" d="M0 0h30v30H0z"/><path fill="';
        parts[1] = baseColors[pooPunk.baseColor];
        parts[2] = '" d="M14.915 2.475c-.586.724-1.38 1.274-1.67 2.3-.168.694-.27 1.435-.144 2.155.07.454.187.89.322 1.319a3.62 4.162 0 0 0-2.052 3.245 5.462 6.826 0 0 0-2.125 4.951 6.12 4.495 0 0 0-2.52 3.628 6.12 4.495 0 0 0 6.12 4.495 6.12 4.495 0 0 0 2.832-.512 7.502 4.495 0 0 0 3.947.678 7.502 4.495 0 0 0 7.502-4.494 7.502 4.495 0 0 0-1.617-2.787 4.41 5.078 0 0 0 .038-.626 4.41 5.078 0 0 0-4.358-5.075 2.5 4.245 0 0 0-1.696-3.61c.004-.076.005-.152.002-.23.008-.728-.388-1.369-.9-1.658-.654-.416-1.398-.48-2.099-.693-.696-.287-1.032-1.198-1.248-2.012-.117-.326-.178-.906-.334-1.074z"/><path fill="#000" d="M15 13h1v1h-1v-1zM20 13h1v1h-1v-1zM18 15h2v1h-2v-1zM17 18h3v1h-3v-1z"/><path fill="#000" fill-opacity=".2" d="M17 13h-1v1h1v-1zM22 13h-1v1h1v-1z"/><path fill="#000" fill-opacity=".4" d="M17 12h-2v1h2v-1zM20 12v1h2v-1h-2z"/>';
        parts[3] = thirdLayers[pooPunk.layerThree];
		parts[4] = '<path d="M10.761 24.46h4.135m-.14-.4h1.456m0 .423h5.921m.024-.282h1.456m-.094-.47h.8m0-.282h.798m-.047-.47h.8m-.119-.465.565-.009m-.096-.508.566-.009m.172-.254.077-2.82M15.46 23.99l.094.047m-6.132-.023h1.456m15.06-6.292.66-.003m-.883.237-.045-2.197m-.367.023.02-1.487m-.655-.079.564.043m-.89-.532.565-.009M6.835 21.561l.1-3.318m2.454-1.992.04-1.952m3.562-7.21.051-2.24m7.883 6.934.043-2.048m-7.566-4.902-.019-.644m.395.08-.019-.644m.395.033-.019-.644m.197-.594h.893m-.648.721-.019-.643m.608 1.293.003-1.152m.336 1.958-.007-.925m.348 1.49-.019-.644m.395 1.208-.019-.644m.268.745h1.55m-.023.333.565-.009m-.002.337.566-.008m1.361 3.111.712.001m-1.859-1.284.03-1.72m.083 1.875.565-.009m.273.891-.044-1.157m.781 3.701h1.645m-.072.38.894.013m.742 1.384.006-1.207M8.717 23.637h.8m-1.552-.47h.8m-1.458-.47h.8m-.838.327.023-1.588m6.111-12.754.027-1.673m-1.249 3.006.01-1.31m-.232-.106h1.692m-3.793 6.06.018-1.497m.452.461.03-1.776m-.044.27.894.013m-.307-.378.566-.009m.327-1.823.566-.009m-.8 2.095V9.657m-2.42 6.831.893.013m-3.337 1.591h.8m1.15-1.452.565-.009m-.989.384.566-.009m-1.13.385.566-.009m-1.035.291.565-.009m18.591 1.264v-1.062m.182.837h.752m-4.089-6.022.894.013" stroke="#000" stroke-width=".5"/>';
        parts[5] = fourthLayers[pooPunk.layerFour];
        parts[6] = fifthLayers[pooPunk.layerFive];
        parts[7] = sixthLayers[pooPunk.layerSix];
        parts[8] = '<path stroke-width=".5" stroke="#000" opacity=".15" d="M10.813 23.618h1.786m-.047-.493h3.759m-.094-.517h1.316m-.047-.517h.987m-.024-.329h.987m-.141-.611h.987m-.118-.47h3.76m-.071-.47h.987m-.047-.422h.987m-.094-.423h1.175M7.054 21.269l2.913.047m-.141-.494h1.316m-.118-.47h.987m-.094-.469h.987m-.094-.517h.987m-.047-.564h.987m-.118-.47h3.76m0-.564h.987m-.047-.423h.986m-.094-.423h1.175m-.047-.564h.987m-.047-.423h.987m-.094-.423h1.175m-.071-.47h1.175m-14.227-2.678h.987m-.047-.423h.987m-.094-.423h1.175m-.047-.564h.987m-.047-.423h.986m-.094-.423h1.175m-.07-.47h1.175m-.059-.517h1.926"/><style>#x{shape-rendering: crispedges;}</style></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7],parts[8]));

        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        PooObject memory pooPunk = randompooPunk(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Poo Punks #', toString(tokenId), '", "description": "Poo punks (POOP) - can\'t stop, won\'t stop are a parody on the CryptoPunks and it inherits the characteristics from PUNKS. The artwork and metadata are fully on-chain and are randomly generated at mint."', getTraits(pooPunk), '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(pooPunk))), '"}'))));
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
    
    constructor() ERC721("Poo Punks", "POOP") Ownable() {}
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