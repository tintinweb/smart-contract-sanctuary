/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-21
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


contract LarvaLads is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply = 5000;
    uint256 public price = 0.00 ether;
    uint256 public maxMint = 10;
    uint256 public numTokensMinted;

    string[8] private bgColors = ['#AE8B61','#DBB181','#E8AA96','#FFC2C2','#EECFA0','#C9CDAF','#D5C6E1','#EAD9D9'];
    string[11] private baseColors = ['#c74029','#904419','#33b6bb','#6f9cd5','#bc6fd5','#96377e','#cdb2bb','#e46265', '#ff8b51', '#eda342', '#86c54e'];
    string[1] private thirdNames = ['Alive'];
    string[1] private thirdLayers = ['<g><path d="m11 13h2v1h-2z" style="opacity: .05; fill: #000000;"/><path d="m15 13h2v1h-2z" style="opacity: .05; fill: #000000;"/><path d="m11 10h2v3h-2z" style="opacity: .8; fill: #ffffff;"/><path d="m15 10h2v3h-2z" style="opacity: .8; fill: #ffffff;"/><path d="m12 11h1v2h-1z" style="opacity: .8; fill: #000000;"/><path d="m15 11h1v2h-1z" style="opacity: .8; fill: #000000;"/><path d="m11 11h2v1h-2z" style="opacity: .1; fill: #000000;"/><path d="m15 11h2v1h-2z" style="opacity: .1; fill: #000000;"/><path d="m11 12h2v1h-2z" style="opacity: .2; fill: #000000;"/><path d="m15 12h2v1h-2z" style="opacity: .2; fill: #000000;"/></g>'];
    string[5] private fourthNames = ['Cool Shades','Night vision','Eye patch','Laser', 'None'];
    string[5] private fourthLayers = [
        '<path d="m19 11h-1v2h-3v-1h-2v1h-3v-2h-2v-1h11z" style="opacity: .9; fill: #000000;"/>',
        '<g><path d="m18 10v2h-1v1h-6v-1h-1v-2z" style="opacity: .3; fill: #128f12;"/><path d="m10 12v-2h8v1h-1h-6v1z" style="opacity: .2;fill: #000000;"/><path class="s1" d="m8 10h2v-1h8v1h1v1h-2v-1h-6v1h-3z"/></g>',
        '<path class="s1" d="m8 10h11v1h-5v1h-1v1h-2v-1h-1v-1h-2z"/>',
        '<g><path d="m8 13h11v1h-11z" style="opacity: .1; fill: #000000;"/><path class="s1" d="m8 10h11v1h-11z"/><path class="s1" d="m8 12h11v1h-11z"/><path d="m8 11h11v1h-11z" style="opacity: .3; fill: #ff0000;"/></g>',
        ''];
    string[8] private fifthNames = ['Green hat', 'Pink hat', 'Cyan hat', 'Yellow hat', 'Top hat' 'None'];
    string[8] private fifthLayers = [
        '<path d="m9 5h9v1h1v1h1v2h-13v-2h1v-1h1z" class="s1"/><path d="m8 7h1v-1h9v1h1v1h-11z" fill="#128f12"/><path class="s3" d="m8 8v-1h1v-1h9v1h-8v1z"/><path class="s3" d="m9 6h3v1h-3z"/><path class="s3" d="m10 7h3h1v-1h1v1v1h-5z"/>',
        '<path d="m9 5h9v1h1v1h1v2h-13v-2h1v-1h1z" class="s1"/><path d="m8 7h1v-1h9v1h1v1h-11z" fill="#ed9dd2"/><path class="s3" d="m8 8v-1h1v-1h9v1h-8v1z"/><path class="s3" d="m9 6h3v1h-3z"/><path class="s3" d="m10 7h3h1v-1h1v1v1h-5z"/>',
        '<path d="m9 5h9v1h1v1h1v2h-13v-2h1v-1h1z" class="s1"/><path d="m8 7h1v-1h9v1h1v1h-11z" fill="#96deeb"/><path class="s3" d="m8 8v-1h1v-1h9v1h-8v1z"/><path class="s3" d="m9 6h3v1h-3z"/><path class="s3" d="m10 7h3h1v-1h1v1v1h-5z"/>',
        '<path d="m9 5h9v1h1v1h1v2h-13v-2h1v-1h1z" class="s1"/><path d="m8 7h1v-1h9v1h1v1h-11z" fill="#e9eb96"/><path class="s3" d="m8 8v-1h1v-1h9v1h-8v1z"/><path class="s3" d="m9 6h3v1h-3z"/><path class="s3" d="m10 7h3h1v-1h1v1v1h-5z"/>',
        '<g><path d="m7 8h12v1h-12z" style="opacity: .2; fill: #000000;"/><path class="s1" d="m6 7h1v-1h1v-5h10v5h1v1h1v1h-14z"/><path d="m8 5h10v1h-10z" fill="#ff0000"/><path d="m7 7v-1h6v1z" style="opacity: .05;fill: #ffffff;"/><path d="m15 8v-1h3v1z" style="opacity: .05;fill: #ffffff;"/><path d="m8 4v-3h3v1h-2v2" style="opacity: .05;fill: #ffffff;"/><path d="m15 4v-2h1h1v1h-1v1z" style="opacity: .05;fill: #ffffff;"/><path d="m11 6v1h1v1h-2v-2z" style="opacity: 0.05; fill: #ffffff;"/><path d="m13 7h2v-1h1v2h-3z" style="opacity: 0.05; fill: #ffffff;"/></g>',
        '<path d="m7 10h1v-1h1v-1h3v-1h4v1h2v1h2v2h-3v-1h-7v1h-3z" fill="#4c4575"/><path d="m12 7h3v2h2v1h-7v1h-1v-1v-1h1h3v-1h-1z" style="opacity: .1; fill: #ffffff;"/><path d="m8 10v-1h3v1z" style="opacity: .1; fill: #ffffff;"/><path d="m16 10v-1h2v1h1v1h-2v-1z" style="opacity: .1; fill: #ffffff;"/><path d="m17 9h-3v-1h3z" style="opacity: .1; fill: #000000;"/><path d="m12 9h-3v-1h3z" style="opacity: .1; fill: #000000;"/>',
        '<path d="m7 10h1v-1h1v-1h3v-1h4v1h2v1h2v2h-3v-1h-7v1h-3z" fill="#ff0404"/><path d="m12 7h3v2h2v1h-7v1h-1v-1v-1h1h3v-1h-1z" style="opacity: .1; fill: #ffffff;"/><path d="m8 10v-1h3v1z" style="opacity: .1; fill: #ffffff;"/><path d="m16 10v-1h2v1h1v1h-2v-1z" style="opacity: .1; fill: #ffffff;"/><path d="m17 9h-3v-1h3z" style="opacity: .1; fill: #000000;"/><path d="m12 9h-3v-1h3z" style="opacity: .1; fill: #000000;"/>',
        ''];
    string[3] private dotsNames = ['Black','White','None'];
    string[3] private dotsLayers = [
        '<g style="opacity: .4"><path class="s1" d="m6 19h1v1h-1z"/><path class="s1" d="m9 17h1v1h-1z"/><path class="s1" d="m9 11h1v1h-1z"/><path class="s1" d="m14 9h1v1h-1z"/><path class="s1" d="m18 11h1v1h-1z"/><path class="s1" d="m17 17h1v1h-1z"/><path class="s1" d="m8 14h1v1h-1z"/><path class="s1" d="m10 6h1v1h-1z"/></g>',
        '<g style="opacity: .5"><path d="m6 19h1v1h-1z" fill="#ffffff"/><path d="m9 17h1v1h-1z" fill="#ffffff"/><path d="m9 11h1v1h-1z" fill="#ffffff"/><path d="m14 9h1v1h-1z" fill="#ffffff"/><path d="m18 11h1v1h-1z" fill="#ffffff"/><path d="m17 17h1v1h-1z" fill="#ffffff"/><path d="m8 14h1v1h-1z" fill="#ffffff"/><path d="m10 6h1v1h-1z" fill="#ffffff"/></g>',
        ''];
    string[3] private sixthNames = ['Black','Gold','None'];
    string[3] private sixthLayers = [
        '<path class="s1" d="m8 14h3v1h5v-1h2v1h-1v1h-2h-2h-3v-1h-2z"/><path d="m16 14h2v1h-2z" style="opacity: 0; fill: #ffffff;"/><path d="m11 15h3v1h-3z" style="opacity: 0; fill: #ffffff;"/>',
        '<path d="m8 14h3v1h5v-1h2v1h-1v1h-2v1h-2v-1h-3v-1h-2z" fill="#ffe96b"/><path d="m13 15h2v2h-2z" fill="#ddc11f"/><path d="m16 14h2v1h-2z" style="opacity: .1; fill: #000000;"/><path d="m11 15h3v1h-3z" style="opacity: .1; fill: #000000;"/>',
        ''];
    
    struct LarvaObject {
        uint256 bgColor;
        uint256 baseColor;
        uint256 layerThree;
        uint256 layerFour;
        uint256 layerFive;
        uint256 layerSix;
        uint256 layerDot;
    }

    function randomLarvaLad(uint256 tokenId) internal view returns (LarvaObject memory) {
        
        LarvaObject memory larvaLad;

        larvaLad.bgColor = getBgColor(tokenId);
        larvaLad.baseColor = getBaseColor(tokenId);
        larvaLad.layerThree = getLayerThree(tokenId);
        larvaLad.layerFour = getLayerFour(tokenId);
        larvaLad.layerFive = getLayerFive(tokenId);
        larvaLad.layerSix = getLayerSix(tokenId);
        larvaLad.layerDot = getLayerDot(tokenId);

        return larvaLad;
    }
    
    function getTraits(LarvaObject memory larvaLad) internal view returns (string memory) {
        
        string[20] memory parts;
        
        parts[0] = ', "attributes": [{"trait_type": "Type","value": "';
        
            parts[4] = 'Normal"}, {"trait_type": "Mouth","value": "';
            parts[5] = thirdNames[larvaLad.layerThree];
            parts[6] = '"},';
        
        parts[7] = ' {"trait_type": "Eyewear","value": "';
        parts[8] = fourthNames[larvaLad.layerFour];
        parts[9] = '"}, {"trait_type": "Headwear","value": "';
        parts[10] = fifthNames[larvaLad.layerFive];
        parts[11] = '"}, {"trait_type": "Background","value": "';
        parts[12] = bgColors[larvaLad.bgColor];
        parts[13] = '"}, {"trait_type": "Accessory","value": "';
        parts[14] = sixthNames[larvaLad.layerSix];
        parts[15] = '"}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
                      output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15]));
        return output;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBaseColor(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("BASE COLOR", toString(tokenId))));

        uint256 rn1 = rand % 119;
        uint256 bc = 0;

        if (rn1 >= 10 && rn1 < 20) { bc = 1; }
        if (rn1 >= 20 && rn1 < 30) { bc = 2; }
        if (rn1 >= 30 && rn1 < 40) { bc = 3; }
        if (rn1 >= 40 && rn1 < 50) { bc = 4; }
        if (rn1 >= 50 && rn1 < 60) { bc = 5; }
        if (rn1 >= 60 && rn1 < 70) { bc = 6; }
        if (rn1 >= 70 && rn1 < 80) { bc = 7; }
        if (rn1 >= 80 && rn1 < 90) { bc = 8; }
        if (rn1 >= 90 && rn1 < 100) { bc = 9; }
        if (rn1 >= 100) { bc = 10; }

        return bc;
    }

    function getBgColor(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("BG COLOR", toString(tokenId))));

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
        uint256 l3 = 0;
        
        return l3;
    }

    function getLayerFour(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER FOUR", toString(tokenId))));

        uint256 rn4 = rand % 120;
        uint256 l4 = 0;

        if (rn4 >= 41 && rn4 < 81) { l4 = 1; }
        if (rn4 >= 81 && rn4 < 121) { l4 = 2; }
        if (rn4 >= 121 && rn4 < 161) { l4 = 3; }
        if (rn4 >= 161) { l4 = 4; }
        
        return l4;
    }

    function getLayerFive(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER FIVE", toString(tokenId))));

        uint256 rn5 = rand % 210;
        uint256 l5 = 0;

        if (rn5 >= 10 && rn5 < 20) { l5 = 1; }
        if (rn5 >= 20 && rn5 < 30) { l5 = 2; }
        if (rn5 >= 30 && rn5 < 40) { l5 = 3; }
        if (rn5 >= 40 && rn5 < 50) { l5 = 4; }
        if (rn5 >= 50 && rn5 < 60) { l5 = 5; }
        if (rn5 >= 60 && rn5 < 70) { l5 = 6; }
        if (rn5 >= 70) { l5 = 7; }
        
        return l5;
    }

    function getLayerSix(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER SIX", toString(tokenId))));

        uint256 rn6 = rand % 60;
        uint256 l6 = 0;

        if (rn6 >= 10 && rn6 < 20) { l6 = 1; }
        if (rn6 >= 40) { l6 = 2; }
        
        return l6;
    }

    function getLayerDot(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER DOT", toString(tokenId))));

        uint256 rn6x = rand % 60;
        uint256 l6x = 0;

        if (rn6x >= 10 && rn6x < 20) { l6x = 1; }
        if (rn6x >= 40) { l6x = 2; }
        
        return l6x;
    }

    function getSVG(LarvaObject memory larvaLad) internal view returns (string memory) {
        string[14] memory parts;

        parts[0] = '<svg id="x" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24"><path fill="';
        parts[1] = bgColors[larvaLad.bgColor];
        parts[2] = '" d="m0 0h24v24h-24z"/><path fill="#000000" d="m4 20v-2h1v-1h1v-3h1v-7h1v-1h1v-1h2v1h1v2h3v-2h1v-1h2v1h1v3h1v5h-1v4h1v3h-16z"/><path d="m4 21h16v2h-1v1h-14v-1h-1z" style="opacity: .2; fill: #000000;"/><path fill="';
        parts[3] = baseColors[larvaLad.baseColor];
        parts[4] = '" d="m5 20v-2h1v-1h1v-3h1v-7h1v-1h2v2h1v1h3v-1h1v-2h2v3h1v5h-1v4h1v2"/>';
        parts[10] = '<path fill="#f8a495" d="m17 7h1v2h-1z" /><path fill="#f8a495" d="m9 9v-2h1v2z" /><path d="m12 20v-2h-1v-3h-1v-2h8v2h-1v2h-1v1v2z" style="opacity: .7; fill: #ffffff;"/><path d="m13 13h2v1h-2z" style="opacity: .8; fill: #000000;"/><path style="opacity: .1;fill: #000000;" class="s3" d="m13 14h2v1h-2z"/>';
        parts[11] = '<g xmlns="http://www.w3.org/2000/svg"><path class="s1" d="m11 18h3v3h-3z"/><path class="s1" d="m15 18h3v3h-3z"/>';
        parts[12] = '<path d="m15 18h2v1h-2z" style="opacity: .1;fill: #ffffff;"/><path d="m11 18h2v1h-2z" style="opacity: .1;fill: #ffffff;"/></g>';

        parts[5] = thirdLayers[0];
        parts[6] = fourthLayers[larvaLad.layerFour];
        parts[7] = fifthLayers[larvaLad.layerFive];
        parts[13] = sixthLayers[larvaLad.layerSix];
        parts[8] = dotsLayers[larvaLad.layerDot];
        
        
        parts[9] = '<path class="s0" d="m8 12v-2v-4h4v3h-2v-1h-1v6h-1v3h-1v1h-1v1h-1v-1l1-1l1-3" /><path class="s0" d="m19 20v-1h-1v-1h-1v-4h1v-5h-3v-2h1v-1h3v3h1v5h-1v4h1v3z" /><style>#x{shape-rendering: crispedges;}.s0{opacity: .07;fill:#000000}.s3{opacity: .1;fill:#000000}</style></svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[10], parts[11], parts[12], parts[13], parts[5]));
                      output = string(abi.encodePacked(output, parts[4], parts[7], parts[8], parts[9]));

        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        LarvaObject memory larvaLad = randomLarvaLad(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Matic Foxes #', toString(tokenId), ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(larvaLad))), '"}'))));
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
    
    constructor() ERC721("Larva Lads", "LARVA") Ownable() {}
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