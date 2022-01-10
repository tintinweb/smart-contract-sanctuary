/**
 *Submitted for verification at polygonscan.com on 2022-01-10
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
 
contract heisenbergNFT is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply = 2999;
    uint256 public price = 10 ether;
    uint256 public maxMint = 10;
    uint256 public numTokensMinted;
    
    // Hat Outline
    string[5] private attribute_1_Names = ['Gray Hat', 'Beige Hat', 'Almond Hat', 'Brown Hat', 'Black Hat'];
    string[5] private attribute_1a = [
        '<path stroke="#A9A6A6"', 
        '<path stroke="#B29791"', 
        '<path stroke="#856161"', 
        '<path stroke="#5A3232"', 
        '<path stroke="#000000"'];

    // Hat Band
    string[5] private attribute_2_Names = ['Gray Band', 'Brown Band', 'Yellow Band', 'Orange Band', 'Black Band'];
    string[5] private attribute_2a = [
        '<path stroke="#A6A7A7"', 
        '<path stroke="#502711"', 
        '<path stroke="#EFDC1B"', 
        '<path stroke="#EFA21B"', 
        '<path stroke="#000000"'];
 
    // Shades
    string[10] private attribute_3_Names = ['Gray Shades', 'Brown Shade', 'Beige Shade', 'Antique Shade', 'Original Shade', 'Looking Right', '[email protected]', 'Looking Left', 'Closed Eyes', 'Devils Eyes'];
    string[5] private attribute_3a = [
        '<path stroke="#A9A6A6" d="M9 23h32" />', 
        '<path stroke="#B29791" d="M9 23h32" />', 
        '<path stroke="#856161" d="M9 23h32" />', 
        '<path stroke="#5A3232" d="M9 23h32" />', 
        '<path stroke="#000000" d="M9 23h32" />'];

    // Glasses
    string[5] private attribute_3d = [
        '<path stroke="#d50000" d="M11 25h1M13 25h1M29 25h1M31 25h1M11 26h1M13 26h1M29 26h1M31 26h1M12 27h1M30 27h1" />', 
        '<path stroke="#d50000" d="M15 25h1M17 25h1M32 25h1M34 25h1M15 26h1M17 26h1M32 26h1M34 26h1M16 27h1M33 27h1" />', 
        '<path stroke="#d50000" d="M18 25h1M20 25h1M36 25h1M38 25h1M18 26h1M20 26h1M36 26h1M38 26h1M19 27h1M37 27h1" />', 
        '<path stroke="#d50000" d="M15 26h3M32 26h3" />', 
        '<path stroke="#5d4037" d="M14 25h5M31 25h5" /><path stroke="#d50000" d="M16 26h1M33 26h1" />'];

    // Accessory - Pipe
    string[7] private attribute_4_Names = ['None', 'Pipe', 'Blue E-Sig', 'Brown E-Sig', 'Green E-Sig', 'Yellow E-Sig', 'Gray E-Sig'];

    // Accessory - Cigarette
    string[5] private attribute_4c = [
        '<path stroke="#04159F" d="M4 41h16M4 42h16" />', 
        '<path stroke="#4E0103" d="M4 41h16M4 42h16" />', 
        '<path stroke="#014E0A" d="M4 41h16M4 42h16" />', 
        '<path stroke="#ADA703" d="M4 41h16M4 42h16" />', 
        '<path stroke="#A9A6A6" d="M4 41h16M4 42h16" />'];

    // Freedom 
    string[2] private attribute_5_Names = ['BUSTED!', 'Free Man'];

    struct HeisenbergObject {
        uint256 attribute_1;
        uint256 attribute_2;
        uint256 attribute_3;
        uint256 attribute_4;
        uint256 attribute_5;
    }

    function randomHeisenberg(uint256 tokenId) internal pure returns (HeisenbergObject memory) {
        
        HeisenbergObject memory Heisenberg;

        Heisenberg.attribute_1 = getattribute_1(tokenId);
        Heisenberg.attribute_2 = getattribute_2(tokenId);
        Heisenberg.attribute_3 = getattribute_3(tokenId);
        Heisenberg.attribute_4 = getattribute_4(tokenId);
        Heisenberg.attribute_5 = getattribute_5(tokenId);

        return Heisenberg;
    }

    function getattributes(HeisenbergObject memory Heisenberg) internal view returns (string memory) {
        
        string[11] memory parts;
        
        parts[0] = ', "attributes": [{"trait_type": "Hat","value": "';
        parts[1] = attribute_1_Names[Heisenberg.attribute_1];
        parts[2] = '"}, {"trait_type": "HatBand","value": "';
        parts[3] = attribute_2_Names[Heisenberg.attribute_2];
        parts[4] = '"}, {"trait_type": "Glasses","value": "';
        parts[5] = attribute_3_Names[Heisenberg.attribute_3];
        parts[6] = '"}, {"trait_type": "Accessory","value": "';
        parts[7] = attribute_4_Names[Heisenberg.attribute_4];
        parts[8] = '"}, {"trait_type": "Freedome","value": "';
        parts[9] = attribute_5_Names[Heisenberg.attribute_5];
        parts[10] = '"}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10]));
        return output;
    }

    function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
    }

    function getattribute_1(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("f5D", toString(tokenId))));

        uint256 rn1 = rand % 50;
        uint256 a1;

        if (rn1 >= 0 && rn1 < 10) { a1 = 0; }
        if (rn1 >= 10 && rn1 < 20) { a1 = 1; }
        if (rn1 >= 20 && rn1 < 30) { a1 = 2; }
        if (rn1 >= 30 && rn1 < 40) { a1 = 3; }
        if (rn1 >= 40 && rn1 < 50) { a1 = 4; }

        return a1;
    }

    function getattribute_2(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("gpm", toString(tokenId))));

        uint256 rn2 = rand % 50;
        uint256 a2;

        if (rn2 >= 0 && rn2 < 10) { a2 = 0; }
        if (rn2 >= 10 && rn2 < 20) { a2 = 1; }
        if (rn2 >= 20 && rn2 < 30) { a2 = 2; }
        if (rn2 >= 30 && rn2 < 40) { a2 = 3; }
        if (rn2 >= 40) { a2 = 4; }

        return a2;
    }

    function getattribute_3(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("L2D", toString(tokenId))));

        uint256 rn3 = rand % 100;
        uint256 a3;

        if (rn3 >= 0 && rn3 < 10) { a3 = 0; }
        if (rn3 >= 10 && rn3 < 20) { a3 = 1; }
        if (rn3 >= 20 && rn3 < 30) { a3 = 2; }
        if (rn3 >= 30 && rn3 < 40) { a3 = 3; }
        if (rn3 >= 40 && rn3 < 50) { a3 = 4; }
        if (rn3 >= 50 && rn3 < 60) { a3 = 5; }
        if (rn3 >= 60 && rn3 < 70) { a3 = 6; }
        if (rn3 >= 70 && rn3 < 80) { a3 = 7; }
        if (rn3 >= 80 && rn3 < 90) { a3 = 8; }
        if (rn3 >= 90) { a3 = 9; }

        return a3;
    }

    function getattribute_4(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("yUB", toString(tokenId))));

        uint256 rn4 = rand % 100;
        uint256 a4;

        if (rn4 >= 0 && rn4 < 50) { a4 = 0; }
        if (rn4 >= 50 && rn4 < 75) { a4 = 1; }
        if (rn4 >= 75 && rn4 < 80) { a4 = 2; }
        if (rn4 >= 80 && rn4 < 85) { a4 = 3; }
        if (rn4 >= 85 && rn4 < 90) { a4 = 4; }
        if (rn4 >= 90 && rn4 < 95) { a4 = 5; }
        if (rn4 >= 95) { a4 = 6; }

        return a4;
    }

    function getattribute_5(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("8LP", toString(tokenId))));

        uint256 rn5 = rand % 100;
        uint256 a5;

        if (rn5 >= 0 && rn5 < 10) { a5 = 0; }
        if (rn5 >= 10) { a5 = 1; }

        return a5;
    }

    function getSVG(HeisenbergObject memory Heisenberg) internal view returns (string memory) {
        string[11] memory parts;

        parts[0] = '<svg id="x" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 51 52"><rect x="0" y="0" width="51" height="52" style="fill:#e8e1df"></rect><path stroke="#000000" d="M11 2h28M10 3h30M9 4h32M9 5h32M9 6h32M9 7h32M9 8h32M9 9h32M9 10h32M9 11h32M9 14h32M9 15h32M2 16h46M4 17h42M7 18h36M9 19h32M12 20h26" /><path stroke="#000000" d="M20 38h12M18 39h16M16 40h19M16 41h3M32 41h3M16 42h3M32 42h3M16 43h3M23 43h5M32 43h3M16 44h3M22 44h7M32 44h3M16 45h19M16 46h19M16 47h19M17 48h17M18 49h15M19 50h13M21 51h9" />';
        parts[1] = attribute_1a[Heisenberg.attribute_1];
        parts[2] = ' d="M10 1h30M9 2h2M39 2h2M8 3h2M40 3h2M8 4h1M41 4h1M8 5h1M41 5h1M8 6h1M41 6h1M8 7h1M41 7h1M8 8h1M41 8h1M8 9h1M41 9h1M8 10h1M41 10h1M8 11h1M41 11h1M8 12h1M41 12h1M8 13h1M41 13h1M8 14h1M41 14h1M1 15h8M41 15h8M1 16h1M48 16h1M1 17h3M46 17h3M3 18h4M43 18h4M6 19h3M41 19h3M8 20h4M38 20h4M11 21h28" />';
        parts[3] = attribute_2a[Heisenberg.attribute_2];
        parts[4] = ' d="M9 12h32M9 13h32" />';

        if (Heisenberg.attribute_3 >= 0 && Heisenberg.attribute_3 <5) {
            parts[5] = attribute_3a[Heisenberg.attribute_3];
            parts[6] = '<path stroke="#000000" d="M9 24h32M9 25h32M9 26h15M26 26h15M10 27h1M13 27h11M26 27h2M30 27h10M10 28h2M14 28h9M27 28h2M31 28h9M10 29h3M14 29h9M27 29h3M31 29h9M11 30h11M28 30h11M12 31h9M29 31h9" />';
        }
        if (Heisenberg.attribute_3 >= 5) {
            parts[5] = '<path stroke="#000000" d="M4 20h1M45 20h1M4 21h2M44 21h2M5 22h2M43 22h2M6 23h2M9 23h14M27 23h14M42 23h2M7 24h3M22 24h1M27 24h1M40 24h3M8 25h2M22 25h1M27 25h1M40 25h2M9 26h1M22 26h1M27 26h1M40 26h1M9 27h1M22 27h1M27 27h1M40 27h1M9 28h2M22 28h1M27 28h1M39 28h2M10 29h2M21 29h2M27 29h2M38 29h2M11 30h2M20 30h2M28 30h2M37 30h2M12 31h9M29 31h9" />';
            parts[6] = attribute_3d[(Heisenberg.attribute_3 - 5)];
        }

        if (Heisenberg.attribute_4 == 0) {
            parts[7] = '';
            parts[8] ='';
        }

        if (Heisenberg.attribute_4 == 1) {
            parts[7] = '<path stroke="#5d4037" d="M39 40h8M31 41h3M39 41h1M45 41h2M31 42h4M39 42h1M45 42h2M34 43h3M39 43h1M43 43h4M35 44h2M39 44h1M41 44h6M36 45h2M39 45h1M41 45h5M37 46h8" /><path stroke="#992a08" d="M34 41h1M40 41h5M35 42h1M40 42h5M40 43h3M37 44h1M40 44h1M38 45h1M40 45h1" /><path stroke="#dbbfb6" d="M45 32h1M44 33h1M44 34h1M44 35h1" /><path stroke="#bdbdbd" d="M45 34h1M46 35h1M45 36h1" /><path stroke="#dbbfb6" d="M46 36h1M45 37h2M44 38h1" />';
            parts[8] ='';
        }
        if (Heisenberg.attribute_4 >= 2) {
            parts[7] = '<rect x="2" y="40.5" width="2" height="2" style="fill:red"><animate attributeType="CSS" attributeName="opacity" from="1" to="0" dur="5s" repeatCount="indefinite" /></rect><path stroke="#bdbdbd" d="M2 34h1M2 35h1M2 36h1M2 37h1M2 38h1M2 39h1"><animate attributeType="CSS" attributeName="opacity" from="1" to="0" dur="5s" repeatCount="indefinite" /></path>';
            parts[8] = attribute_4c[(Heisenberg.attribute_4 - 2)];
        }

        if (Heisenberg.attribute_5 == 0) {
            parts[9] = '<rect x="15" y="0" width="1" height="52" style="fill:#616161;fill-opacity:0.5"></rect> <rect x="25" y="0" width="1" height="52" style="fill:#616161;fill-opacity:0.5"></rect> <rect x="35" y="0" width="1" height="52" style="fill:#616161;fill-opacity:0.5"></rect> <rect x="5" y="0" width="1" height="52" style="fill:#616161;fill-opacity:0.5"></rect> <rect x="45" y="0" width="1" height="52" style="fill:#616161;fill-opacity:0.5"></rect>';
                        
        }
        if (Heisenberg.attribute_5 != 0) {
            parts[9] = '';
        }

        parts[10] = '<style>#x{shape-rendering: crispedges;}</style></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10]));

        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        HeisenbergObject memory Heisenberg = randomHeisenberg(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Heisenber NFT #', toString(tokenId), '", "description": "Heisenbergs are COOL NFT tokens - $METH. The illustrations are fully on-chain and each NFT is randomly generated at mint"', getattributes(Heisenberg), '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(Heisenberg))), '"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function mintheisenberg(address destination, uint256 amountOfTokens) private {
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");
        require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
        require(amountOfTokens > 0, "Must mint at least one token");
        require(price * amountOfTokens == msg.value, "Paid amount is incorrect");

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(destination, tokenId);
            numTokensMinted += 1;
        }
    }

    function mint(uint256 amountOfTokens) public payable virtual {
        mintheisenberg(_msgSender(),amountOfTokens);
    }

    //function setPrice(uint256 newPrice) public onlyOwner {
    //    price = newPrice;
    //}

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
    
    constructor() ERC721("Heisenberg NFT", "METH") Ownable() {}
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