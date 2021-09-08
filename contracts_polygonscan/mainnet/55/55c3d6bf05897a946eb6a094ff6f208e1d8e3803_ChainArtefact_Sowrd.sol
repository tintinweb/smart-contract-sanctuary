/**
 *Submitted for verification at polygonscan.com on 2021-09-08
*/

pragma solidity ^0.8.2;


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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

library Counters {
    struct Counter {
        
        
        
        uint256 _value; 
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

        
        _status = _ENTERED;

        _;

        
        
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Builder {
    bytes private constant STRING_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    function randomValue(uint256 tokenId, uint256 seed, uint256 divide) internal pure returns (uint256) {
        return SafeMath.mod(uint256(keccak256(abi.encodePacked(Strings.toString(SafeMath.mul(tokenId, seed))))), divide);
    }

    function getColor(uint256 tokenId, uint256 colorId) internal pure returns (string memory) {
        uint256 base = Builder.randomValue(tokenId, colorId, 16777215);
        return string(abi.encodePacked("#", Builder.substring(Strings.toHexString(base), 2, 8)));
    }
    
    function getCircle(uint256 tokenId, uint256 seed, string memory color) internal pure returns (string memory) {
        string memory cxStr = Strings.toString(randomValue(tokenId, seed, 350));
        string memory cyStr = Strings.toString(randomValue(tokenId, SafeMath.add(seed, 2), 350));
        string memory size = Strings.toString(randomValue(tokenId, SafeMath.add(seed, 4), 150));
        
        return string(abi.encodePacked('<circle cx="', cxStr, '" cy="', cyStr, '" r="', size, '" fill="', color, '" />'));
    }
    
    function getRect(uint256 tokenId, uint256 seed, string memory color) internal pure returns (string memory) {
        string memory xStr = Strings.toString(randomValue(tokenId, seed, 350));
        string memory yStr = Strings.toString(randomValue(tokenId, SafeMath.add(seed, 1), 350));
        string memory wSize = Strings.toString(randomValue(tokenId, SafeMath.add(seed, 2), 150));
        string memory hSize = Strings.toString(randomValue(tokenId, SafeMath.add(seed, 3), 150));
        
        return string(abi.encodePacked('<rect x="', xStr, '" y="', yStr, '" width="', wSize, '" height="', hSize, '" fill="', color, '" />'));
    }

    function getFont(uint256 tokenId, uint256 seed) internal pure returns (string memory) {
        uint256 str1 = randomValue(tokenId, seed, 25);
        uint256 str2 = randomValue(tokenId, SafeMath.add(seed, 1), 25);
        uint256 str3 = randomValue(tokenId, SafeMath.add(seed, 2), 25);
        uint256 str4 = randomValue(tokenId, SafeMath.add(seed, 3), 25);
        uint256 str5 = randomValue(tokenId, SafeMath.add(seed, 4), 25);
        uint256 str6 = randomValue(tokenId, SafeMath.add(seed, 5), 25);
        return string(abi.encodePacked(STRING_TABLE[str1], STRING_TABLE[str2], STRING_TABLE[str3], STRING_TABLE[str4], STRING_TABLE[str5], STRING_TABLE[str6]));
    }
    
    
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        
        return string(result);
    }
}

library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        
        string memory table = TABLE;

        
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        
        string memory result = new string(encodedLen + 32);

        assembly {
            
            mstore(result, encodedLen)
            
            
            let tablePtr := add(table, 1)
            
            
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            
            let resultPtr := add(result, 32)
            
            
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               
               let input := mload(dataPtr)
               
               
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

library Creator {
    function createSVG(string memory bgcolor, string memory parts, string memory mainString, string memory centerString) internal pure returns (string memory) {
        string[11] memory parts2;
        parts2[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.title { fill: #fefefe; font-family: serif; font-size: 10px; }.base { fill: #fefefe; font-family: serif; font-size: 14px; } .baseshadow { fill: #101010; font-family: serif; font-size: 14px; } .title { fill: #fefefe; font-family: serif; font-size: 70px; } .shadow { fill: #101010; font-family: serif; font-size: 70px; }</style><rect width="100%" height="100%" fill="';
        parts2[1] = bgcolor;
        parts2[2] = '" />';
        parts2[3] = parts;
        parts2[4] = '<text x="11" y="21" class="baseshadow">';
        parts2[5] = mainString;
        parts2[6] = '</text><text x="10" y="20" class="base">';
        parts2[7] = mainString;
        parts2[8] = '</text>';
        parts2[9] = string(abi.encodePacked('<text x="12" y="202" class="shadow">', centerString, '</text><text x="10" y="200" class="title">', centerString, '</text>'));
        parts2[10] = '<text x="0" y="200" class="font">aaaa</text></svg>';

        string memory output = string(abi.encodePacked(parts2[0], parts2[1], parts2[2], parts2[3], parts2[4], parts2[5]));
        return string(abi.encodePacked(output, parts2[6], parts2[7], parts2[8], parts2[9], parts2[10]));
    }
    
    function createJSON(string memory output, string memory mainString,  string memory discription, uint8 effect, string[5] memory colors) internal pure returns (string memory) {
        string[13] memory attr;
        attr[0] = '"attributes":[{"trait_type":"Effect","value":"';
        attr[1] = Strings.toString(effect);
        attr[2] = '"},{"trait_type":"EffectColor","value":"';
        attr[3] = colors[0];
        attr[4] = '"},{"trait_type":"ToshinColor","value":"';
        attr[5] = colors[1];
        attr[6] = '"},{"trait_type":"TsukaColor","value":"';
        attr[7] = colors[2];
        attr[8] = '"},{"trait_type":"MochiteColor","value":"';
        attr[9] = colors[3];
        attr[10] = '"},{"trait_type":"OrbColor","value":"';
        attr[11] = colors[4];
        attr[12] = '"}],';
        
        string memory attrStr = string(abi.encodePacked(attr[0], attr[1], attr[2], attr[3], attr[4], attr[5]));
        attrStr = string(abi.encodePacked(attrStr, attr[6], attr[7], attr[8], attr[9], attr[10], attr[11], attr[12]));
        
        string memory out = Base64.encode(bytes(output));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', mainString, '", "description": "', discription, '", ', attrStr, ' "image": "data:image/svg+xml;base64,', out, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}

contract ChainArtefact_Sowrd is ERC721Enumerable, ReentrancyGuard, Ownable {

    string private constant discription = 'Full-On-Chain Artefact Series. Sowrd Version. Engraved on the chain.';
    string private constant namePrefix = 'ChainArtefact Sowrd #';
    string private constant svgHeader = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="1000px" height="1000px" viewBox="0 0 100 100" style="enable-background:new 0 0 100 100;" xml:space="preserve">';
    string private constant effect = '<path class="st0" d="M66.6,46.6h-3.3V45H65v-1.7h1.7v-1.7H65v1.7h-1.7V45h-4.9v-3.3H60v1.7h1.7v-1.7H60V40h-1.7v1.7H55v-3.3h1.7v-1.7h1.7V35h-1.7v1.7h-3.3v-3.3h-1.7V35h-3.3v-1.6H50V30h1.7v-1.7H50V30h-1.7v1.7H45V30h1.7v-1.7h1.7v-1.7H50V25h3.3v-1.7H55v-1.7h-1.7v1.7H50V25h-1.7v1.7H45v1.7h-1.6v-1.7H40V25h1.7v-1.7h1.7v-1.7h-1.7v1.7h-3.3v-1.6H40v-3.3h1.7v-1.7H40v1.7h-1.7V20h-1.7v1.7H35V15h1.7v-1.7H35V15h-3.3v1.7H30V15h-1.7v-1.6h3.3v-1.7h1.7V10h-1.7v1.7H25V10h1.7V8.4h1.7V6.6h-1.7v1.7h-5V6.6h-15v10h1.7v5H10v1.7h1.7V25h1.7v1.7H15v1.7h1.7V30h1.7v1.7H20v1.7h1.7V35h1.7v1.7H25v1.7h1.7V40h1.7v1.7H30v1.7h1.7V45h1.7v1.7H35v1.7h1.7V50h1.7v1.7H40v1.7h1.7V55h1.7v1.7H45v1.7h1.7v3.3h1.7v5H50v1.7h1.7V70h1.7v-1.7h3.3v-1.7H60V65h-3.4v1.7h-3.3v1.7h-1.6v-1.7H50v-5h-1.7v-3.3h-1.7v-1.7H45V55h-1.7v-1.7h-1.7v-1.7H40V50h-1.7v-1.7h-1.7v-1.7H35V45h-1.7v-1.7h-1.7v-1.7H30V40h-1.7v-1.7h-1.7v-1.7H25V35h-1.7v-1.7h-1.7v-1.7H20V30h-1.7v-1.7h-1.7v-1.7H15V25h-1.7v-1.7h-1.7v-1.7H10v-5H8.4V8.4h8.3V10h5v1.7h1.7v1.7H25V15h1.7v1.7h1.7v1.7H30V20h1.7v1.7h1.7v1.7H35V25h1.7v1.7h1.7v1.7H40V30h1.7v1.7h1.7v1.7H45V35h1.7v1.7h1.7v1.7H50V40h1.7v1.7h1.7v1.7H55V45h1.7v1.7h1.7v1.7h3.3V50h5v1.7h1.7v1.6h-1.7v3.3H65V60h1.7v-3.3h1.7v-3.3H70V50h-1.7v-1.7h-1.7L66.6,46.6l3.4,0V45h-3.4V46.6z M33.3,18.3h-1.6v-1.6h1.6V18.3z M53.3,38.3h-1.6v-1.6h1.6V38.3z"/>';
    string private constant toushin = '<path class="st1" d="M60,60h-1.7v-1.7h-1.7v-1.7H55V55h-1.7v-1.7h-1.7v-1.7H50V50h-1.7v-1.7h-1.7v-1.7H45V45h-1.7v-1.7h-1.7v-1.7H40V40h-1.7v-1.7h-1.7v-1.7H35V35h-1.7v-1.7h-1.7v-1.7H30V30h-1.7v-1.7h-1.7v-1.7H25V25h-1.7v-1.7h-1.7v-1.7H20V20h-1.7v-1.7h-1.7v-1.7H15V15h-1.7v-1.7h-1.7v3.3h1.7v5H15v1.7h1.7V25h1.7v1.7H20v1.7h1.7V30h1.7v1.7H25v1.7h1.7V35h1.7v1.7H30v1.7h1.7V40h1.7v1.7H35v1.7h1.7V45h1.7v1.7H40v1.7h1.7V50h1.7v1.7H45v1.7h1.7V55h1.7v1.7H50v1.7h1.7v3.3h1.7v1.7h3.3v-1.7h1.7v1.7h3.3v-1.7H60V60z M63.3,56.7v-3.3h-1.7v-1.7h-3.3V50h-1.7v-1.7H55v-1.7h-1.7V45h-1.7v-1.7H50v-1.7h-1.7V40h-1.7v-1.7H45v-1.7h-1.7V35h-1.7v-1.7H40v-1.7h-1.7V30h-1.7v-1.7H35v-1.7h-1.7V25h-1.7v-1.7H30v-1.7h-1.7V20h-1.7v-1.7H25v-1.7h-1.7V15h-1.7v-1.7h-5v-1.7h-3.3v1.7H15V15h1.7v1.7h1.7v1.7H20V20h1.7v1.7h1.7v1.7H25V25h1.7v1.7h1.7v1.7H30V30h1.7v1.7h1.7v1.7H35V35h1.7v1.7h1.7v1.7H40V40h1.7v1.7h1.7v1.7H45V45h1.7v1.7h1.7v1.7H50V50h1.7v1.7h1.7v1.7H55V55h1.7v1.7h1.7v1.7H60V60h1.7v1.7h1.7v-3.3h-1.7v-1.7H63.3z"/>';
    string private constant tsuka = '<path class="st2" d="M61.7,66.7H60v1.7h-1.7V70h-1.7v1.7H55v1.7h-1.7V75h-1.7v3.3h5v-1.7h1.7V75H60v-1.7h1.7v-1.7h1.7V70h-1.7V66.7z M75,51.7v1.7h-1.7V55h-1.7v1.7H70v1.7h-1.7V60h-1.7v1.7H70v1.7h1.7v-1.7h1.7V60H75v-1.7h1.7v-1.7h1.7v-5H75z"/>';
    string private constant mochite = '<polygon class="st3" points="83.3,81.7 83.3,80 81.7,80 81.7,78.3 80,78.3 80,76.7 78.3,76.7 78.3,75 76.7,75 76.7,73.3 75,73.3 75,71.7 73.3,71.7 73.3,70 71.7,70 71.7,68.3 70,68.3 70,70 68.3,70 68.3,71.7 70,71.7 70,73.3 71.7,73.3 71.7,75 73.3,75 73.3,76.7 75,76.7 75,78.3 76.7,78.3 76.7,80 78.3,80 78.3,81.7 80,81.7 80,83.3 81.7,83.3 81.7,88.3 88.3,88.3 88.3,81.7 "/>';
    string private constant line = '<path class="st4" d="M90,80l-5,0v-1.7h-1.7v0h0v-1.7h-1.7v0h0V75H80v0h0v-1.7h-1.7v0h0v-1.7h-1.7v0l0,0V70H75v0l0,0v-1.7h-1.7v0l0,0v-1.7h-1.7V65h1.7v-1.7H75v-1.7h1.7V60h1.7v-1.7H80V50h-1.7v-3.3h-1.8v1.7H75V50h-1.7v1.7h-1.7v1.7H70V55h-1.7v1.7h-1.6v-3.2h1.7v-1.8h-1.7V50h-5v-1.7h-3.3v-1.7h-1.7V45H55v-1.7h-1.7v-1.7h-1.7V40H50v-1.7h-1.7v-1.7h-1.7V35H45v-1.7h-1.7v-1.7h-1.7V30H40v-1.7h-1.7v-1.7h-1.7V25H35v-1.7h-1.7v-1.7h-1.7V20H30v-1.7h-1.7v-1.7h-1.7V15H25v-1.7h-1.7v-1.7h-1.7V10h-5V8.3H8.3v8.4H10v5h1.7v1.7h1.7V25H15v1.7h1.7v1.7h1.7V30H20v1.7h1.7v1.7h1.7V35H25v1.7h1.7v1.7h1.7V40H30v1.7h1.7v1.7h1.7V45H35v1.7h1.7v1.7h1.7V50H40v1.7h1.7v1.7h1.7V55H45v1.7h1.7v1.7h1.7v3.3H50v5h1.7v1.7h1.8v-1.7h3.2v1.6H55V70h-1.7v1.7h-1.7v1.7H50V75h-1.7v1.7h-1.7v1.8H50V80h8.4v-1.7H60v-1.7h1.7V75h1.7v-1.7H65v-1.7h1.6v1.7h1.7v0h0V75H70v0h0v1.7h1.7v0h0v1.7h1.7v0h0V80H75v0h0v1.7h1.7v0h0v1.7h1.7v0h0V85H80l0,5L90,90L90,80z M66.7,60h1.7v-1.7H70v-1.7h1.7V55h1.7v-1.7H75v-1.7h3.2v4.9h-1.7v1.7H75V60h-1.7v1.7h-1.7v1.7H70v-1.7h-3.3V60z M13.4,11.7h3.2v1.7h5V15h1.7v1.7H25v1.7h1.7V20h1.7v1.7H30v1.7h1.7V25h1.7v1.7H35v1.7h1.7V30h1.7v1.7H40v1.7h1.7V35h1.7v1.7H45v1.7h1.7V40h1.7v1.7H50v1.7h1.7V45h1.7v1.7H55v1.7h1.7V50h1.7v1.7h3.3v1.7h1.7v3.2h-1.7v1.8h1.7v3.2h-1.6V60H60v-1.7h-1.7v-1.7h-1.7V55H55v-1.7h-1.7v-1.7h-1.7V50H50v-1.7h-1.7v-1.7h-1.7V45H45v-1.7h-1.7v-1.7h-1.7V40H40v-1.7h-1.7v-1.7h-1.7V35H35v-1.7h-1.7v-1.7h-1.7V30H30v-1.7h-1.7v-1.7h-1.7V25H25v-1.7h-1.7v-1.7h-1.7V20H20v-1.7h-1.7v-1.7h-1.7V15H15v-1.7h-1.7V11.7z M53.4,63.3v-1.7h-1.7v-3.3H50v-1.7h-1.7V55h-1.7v-1.7H45v-1.7h-1.7V50h-1.7v-1.7H40v-1.7h-1.7V45h-1.7v-1.7H35v-1.7h-1.7V40h-1.7v-1.7H30v-1.7h-1.7V35h-1.7v-1.7H25v-1.7h-1.7V30h-1.7v-1.7H20v-1.7h-1.7V25h-1.7v-1.7H15v-1.7h-1.7v-5h-1.7v-3.2h1.6V15H15v1.7h1.7v1.7h1.7V20H20v1.7h1.7v1.7h1.7V25H25v1.7h1.7v1.7h1.7V30H30v1.7h1.7v1.7h1.7V35H35v1.7h1.7v1.7h1.7V40H40v1.7h1.7v1.7h1.7V45H45v1.7h1.7v1.7h1.7V50H50v1.7h1.7v1.7h1.7V55H55v1.7h1.7v1.7h1.7V60H60v1.7h1.7v1.6h-3.2v-1.7h-1.8v1.7H53.4z M63.3,71.6h-1.7v1.7H60V75h-1.7v1.7h-1.7v1.7h-4.9V75h1.7v-1.7H55v-1.7h1.7V70h1.7v-1.7H60v-1.7h1.6V70h1.7V71.6z M68.3,66.6v1.7h-1.7V70H65v-1.7h-1.7v-1.7h-1.7V65h1.7v-1.7H65v-1.7h1.6v1.7h1.7V65H70v1.6H68.3z M88.3,88.3h-4.9v-1.6h-1.6v-3.4H80v-1.7h-1.7V80h-1.7v-1.7H75v-1.7h-1.7V75h-1.7v-1.7H70v-1.7h-1.7V70H70v-1.7h1.6V70h1.7v1.7H75v1.7h1.7V75h1.7v1.7H80v1.7h1.7V80h1.7v1.7h3.4v1.6h1.6V88.3z"/>';
    string private constant shine = '<polygon class="st5" points="60,61.6 60,60 58.4,60 58.4,58.3 56.7,58.3 56.7,56.6 55,56.6 55,55 53.4,55 53.4,53.3 51.7,53.3 51.7,51.6 50,51.6 50,50 48.4,50 48.4,48.3 46.7,48.3 46.7,46.6 45,46.6 45,45 43.4,45 43.4,43.3 41.7,43.3 41.7,41.6 40,41.6 40,40 38.4,40 38.4,38.3 36.7,38.3 36.7,36.6 35,36.6 35,35 33.4,35 33.4,33.3 31.7,33.3 31.7,31.6 30,31.6 30,30 28.4,30 28.4,28.3 26.7,28.3 26.7,26.6 25,26.6 25,25 23.4,25 23.4,23.3 21.7,23.3 21.7,21.6 20,21.6 20,20 18.4,20 18.4,18.3 16.7,18.3 16.7,16.6 15,16.6 15,15 13.4,15 13.4,13.3 11.6,13.3 11.6,15 13.3,15 13.3,16.7 15,16.7 15,18.4 16.6,18.4 16.6,20 18.3,20 18.3,21.7 20,21.7 20,23.4 21.6,23.4 21.6,25 23.3,25 23.3,26.7 25,26.7 25,28.4 26.6,28.4 26.6,30 28.3,30 28.3,31.7 30,31.7 30,33.4 31.6,33.4 31.6,35 33.3,35 33.3,36.7 35,36.7 35,38.4 36.6,38.4 36.6,40 38.3,40 38.3,41.7 40,41.7 40,43.4 41.6,43.4 41.6,45 43.3,45 43.3,46.7 45,46.7 45,48.4 46.6,48.4 46.6,50 48.3,50 48.3,51.7 50,51.7 50,53.4 51.6,53.4 51.6,55 53.3,55 53.3,56.7 55,56.7 55,58.4 56.6,58.4 56.6,60 58.3,60 58.3,61.7 60,61.7 60,63.4 61.7,63.4 61.7,61.6 "/><polygon class="st6" points="30,23.3 30,21.6 28.4,21.6 28.4,20 26.7,20 26.7,18.3 25,18.3 25,16.6 23.4,16.6 23.4,15 21.7,15 21.7,13.3 16.7,13.3 16.7,11.6 13.3,11.6 13.3,13.4 16.6,13.4 16.6,15 21.6,15 21.6,16.7 23.3,16.7 23.3,18.4 25,18.4 25,20 26.6,20 26.6,21.7 28.3,21.7 28.3,23.4 30,23.4 30,25 31.7,25 31.7,23.3 "/>';
    string private constant orb = '<polygon class="st7" points="68.4,65 68.4,63.3 66.7,63.3 66.7,61.6 65,61.6 65,63.3 63.3,63.3 63.3,65 61.6,65 61.6,66.7 63.3,66.7 63.3,68.4 65,68.4 65,70 66.7,70 66.7,68.4 68.4,68.4 68.4,66.7 70,66.7 70,65 "/><rect x="65" y="63.3" class="st8" width="1.7" height="1.7"/><polygon class="st9" points="65,68.3 65,66.6 63.3,66.6 63.3,68.4 65,68.4 65,70 66.7,70 66.7,68.3 "/>';
    string private constant svhfooter = '</svg>';
    
    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        require(tokenId > 0 && tokenId < 10001, "Token ID invalid");
        
        string[5] memory colors;
        colors[0] = Builder.getColor(tokenId * 3, 1); 
        colors[1] = Builder.getColor(tokenId * 5, 2); 
        colors[2] = Builder.getColor(tokenId * 7, 3); 
        colors[3] = Builder.getColor(tokenId * 9, 4); 
        colors[4] = Builder.getColor(tokenId * 11, 5); 
        
        string[12] memory styles;
        styles[1] = '<style type="text/css">.st0{fill:';
        styles[2] = colors[0];
        styles[3] = ';}.st1{fill:';
        styles[4] = colors[1];
        styles[5] = ';}.st2{fill:';
        styles[6] = colors[2];
        styles[7] = ';}.st3{fill:';
        styles[8] = colors[3];
        styles[9] = ';}.st4{fill:#3D3A39;}.st5{fill:rgba(255, 255, 255, 0.6);}.st6{fill:rgba(255, 255, 255, 0.3);}.st7{fill:';
        styles[10] = colors[4];
        styles[11] = ';}.st8{fill:#FFFFFF;}.st9{fill:rgba(0, 0, 0, 0.4);}.title { fill: #fefefe; font-family: serif; font-size: 5px; }</style><rect width="100%" height="100%" fill="#101010" />';
        
        uint256 rnd = Builder.randomValue(tokenId * 20, 8, 100);
        
        string memory buildSet = string(abi.encodePacked(svgHeader, styles[0], styles[1], styles[2], styles[3], styles[4], styles[5]));
        buildSet = string(abi.encodePacked(buildSet, styles[6], styles[7], styles[8], styles[9], styles[10], styles[11]));
        
        uint8 effectint = 0;
        if( rnd < 20 ){
            buildSet = string(abi.encodePacked(buildSet, effect));
            effectint = 1;
        }
        
        string memory text = string(abi.encodePacked('<text x="3" y="98" class="title">', namePrefix, Strings.toString(tokenId), '</text>'));
        
        return Creator.createJSON(string(abi.encodePacked(buildSet, toushin, tsuka, mochite, line, shine, orb, text, svhfooter)), string(abi.encodePacked(namePrefix, Strings.toString(tokenId))), discription, effectint, colors);
    }
    
    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 8001, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 8000 && tokenId < 10001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }


    constructor() ERC721("ChainArtefactSowrd", "CAS") Ownable() {}
}