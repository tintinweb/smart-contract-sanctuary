/**
 *Submitted for verification at polygonscan.com on 2021-09-19
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

library Base {
    string internal constant discription = 'Full-On-Chain Artefact Series. Arms Version. Engraved on the chain.';
    string internal constant namePrefix = 'ChainArtefact Arms #';
    string internal constant svgHeader = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="1000px" height="1000px" viewBox="0 0 100 100"><style type="text/css">.cls-1{isolation: isolate;}.title { fill: #fefefe; font-family: serif; font-size: 5px; }</style><rect width="100%" height="100%" fill="#101010" /><g class="cls-1">';
    string internal constant svhfooter = '</g></svg>';

    uint256 internal constant limitNumber = 10000;
    uint256 internal constant mintedNumber = 8000;
}

library Monk {
    function _buildMonk(string memory color) internal pure returns (string memory) {
        string memory monk = '<path d="M33.33,35H35V50h1.67v1.67H63.33V50H65V35h1.67V31.67h1.66V30H66.67V28.33H63.33V25H61.67V23.33H60v3.34H55v1.66H45V26.67H40V23.33H38.33V25H36.67v3.33H33.33V30H31.67v1.67h1.66Zm5,28.33H36.67V65H33.33v1.67H31.67v6.66H30v3.34h3.33V75H35V73.33h1.67V70h1.66V68.33H40V65H38.33Zm30,10V66.67H66.67V65H63.33V63.33H61.67V65H60v3.33h1.67V70h1.66v3.33H65V75h1.67v1.67H70V73.33Z" style="fill: ';
        monk = string(abi.encodePacked(monk, color)); // monk_color
        monk = string(abi.encodePacked(monk, '"/>'));
        monk = string(abi.encodePacked(monk, '<path d="M70,71.67V65H68.33V63.33H65V60H63.33V56.67H65v-5h1.67v-15h1.66V33.33H70V30h1.65V28.33H70V26.67H66.67V25H65V23.33H63.33V21.67h-5V25h-5v1.67H46.67V25h-5V21.67h-5v1.66H35V25H33.33v1.67H30v1.66H28.35V30H30v3.33h1.67v3.34h1.66v15H35v5h1.67V60H35v3.33H31.67V65H30v6.67H28.33v6.66H35V76.67h1.67V75h1.66V71.67H40V70h1.67V63.33H40V61.67H38.33V58.33H40V60h1.67v1.67H45v1.66h1.67v3.34H45V63.33H43.33v5h3.34V70H45v3.33h1.67V71.67h1.66V65h3.34v6.67h1.66v1.66H55V70H53.33V68.33h3.34v-5H55v3.34H53.33V63.33H55V61.67h3.33V60H60V58.33h1.67v3.34H60v1.66H58.33V70H60v1.67h1.67V75h1.66v1.67H65v1.66h6.67V71.67ZM51.67,28.33H55V26.67h5V23.33h1.67V25h1.66v3.33h3.34V30h1.66v1.67H66.67V35H65V50H63.33v1.67H51.67ZM40,65v3.33H38.33V70H36.67v3.33H35V75H33.33v1.67H30V73.33h1.67V66.67h1.66V65h3.34V63.33h1.66V65ZM36.67,51.67V50H35V35H33.33V31.67H31.67V30h1.66V28.33h3.34V25h1.66V23.33H40v3.34h5v1.66h3.33V51.67ZM60,55v1.67H58.33v1.66H55V60H51.67v1.67H48.33V60H45V58.33H41.67V56.67H40V55H38.33V53.33H61.67V55ZM70,76.67H66.67V75H65V73.33H63.33V70H61.67V68.33H60V65h1.67V63.33h1.66V65h3.34v1.67h1.66v6.66H70Z" style="fill: #3c3a39"/>'));
        monk = string(abi.encodePacked(monk, '<path d="M46.67,50H38.33V48.33H36.67v-15H35v-5H33.33V30H31.67v1.67h1.66V35H35V50h1.67v1.67H48.33V28.33H46.67ZM38.33,66.67H36.67v1.66H35v3.34H33.33V75H35V73.33h1.67V70h1.66V68.33H40V65H38.33ZM66.67,30V28.33H65v5H63.33v15H61.67V50h-10v1.67H63.33V50H65V35h1.67V31.67h1.66V30ZM65,68.33H63.33V66.67H61.67V65H60v3.33h1.67V70h1.66v3.33H65V75h1.67V71.67H65Z" style="fill: #231815;mix-blend-mode: multiply;opacity: 0.30000000000000004"/>'));
        return monk;
    }
    
    function _buildEffect(string memory color) internal pure returns (string memory) {
        return string(abi.encodePacked('<path d="M13.33,75h-5V73.33H5V71.67H3.33V70H1.67V60H3.33V58.33H5V56.67H8.33V55H10V53.33H8.33V51.67H5V48.33H3.33V46.67H1.67V50H3.33v5H1.67V53.33H0V71.67H1.67v1.66H3.33V75H6.67v1.67h10V75H13.33Zm85-21.67V55H96.67V50h1.66V46.67H96.67v1.66H95v3.34H91.67v1.66H90V55h1.67v1.67H95v1.66h1.67V60h1.66V70H96.67v1.67H95v1.66H91.67V75H83.33v1.67h10V75h3.34V73.33h1.66V71.67H100V53.33Z" style="fill: ', color, '"/>'));
    }
    
    function _buildBase(string memory color) internal pure returns (string memory) {
        return string(abi.encodePacked('<path d="M30,36.67V35H28.33V31.67H25v1.66H23.33V40H25v3.33H21.67V41.67H20V40H18.33v1.67H16.67V45H15v5H13.33v3.33H11.67v3.34h1.66v1.66H15v5H13.33V60H11.67V58.33h-5V60H5v1.67H3.33v6.66H5V70H6.67v1.67H10v1.66h5V71.67h1.67V70h1.66V68.33H20V65H18.33V63.33H20V60h1.67V58.33h1.66V56.67H25V53.33h1.67V55h1.66V53.33H30v-5H28.33v3.34H26.67V50H25V45h1.67V43.33H30V41.67h1.67V38.33H30Zm65,25V60H93.33V58.33h-5V60H86.67v3.33H85v-5h1.67V56.67h1.66V53.33H86.67V50H85V45H83.33V41.67H81.67V40H80v1.67H78.33v1.66H75V40h1.67V33.33H75V31.67H71.67V35H70v3.33H68.33v3.34H70v1.66h3.33V45H75v5H73.33v1.67H71.67V48.33H70v5h1.67V55h1.66V53.33H75v3.34h1.67v1.66h1.66V60H80v3.33h1.67V65H80v3.33h1.67V70h1.66v1.67H85v1.66h5V71.67h3.33V70H95V68.33h1.67V61.67Z" style="fill: ', color, '"/>'));
    }
    
    function _buildShadow() internal pure returns (string memory) {
        return '<path d="M11.67,58.33h-5V60H5v1.67H3.33v6.66H5V70H6.67v1.67H8.33V68.33H6.67V61.67h6.66V60H11.67ZM95,61.67V60H93.33V58.33h-5V60H86.67v1.67h6.66v6.66H91.67v3.34h1.66V70H95V68.33h1.67V61.67Z" style="fill: #231815;mix-blend-mode: multiply;opacity: 0.30000000000000004"/>';
    }
    
    function _buildKazari(string memory color) internal pure returns (string memory) {
        return string(abi.encodePacked('<path d="M25,33.33H23.33V40H25v3.33H23.33v5H21.67V46.67H20V45H18.33V43.33H20V40H18.33v1.67H16.67V45H15v5H13.33v1.67h3.34v-5h1.66v1.66H20V50h5V45h1.67V38.33H25V35h1.67V31.67H25ZM85,50V45H83.33V41.67H81.67V40H80v3.33h1.67V45H80v1.67H78.33v1.66H76.67v-5H75V40h1.67V33.33H75V31.67H73.33V35H75v3.33H73.33V45H75v5h5V48.33h1.67V46.67h1.66v5h3.34V50Z" style="fill: ', color, '"/>'));
    }
    
    function _buildLine() internal pure returns (string memory) {
        return '<path d="M31.67,35V33.33H30V30H26.67V28.33H25V30H23.33v1.67H21.67v5H18.33v1.66H16.67V40H15v3.33H13.33v5H11.67v3.34H10V55H8.33v1.67H5v1.66H3.33V60H1.67V70H3.33v1.67H5v1.66H8.33V75h8.34V73.33h1.66V71.67H20V65h1.67V61.67h1.66V60H25V58.33h3.33V56.67H30V55h1.67V43.33h1.66V36.67H31.67Zm0,5v1.67H30v1.66H26.67V45H25v5h1.67v1.67h1.66V48.33H30v5H28.33V55H26.67V53.33H25v3.34H23.33v1.66H21.67V60H20v3.33H18.33v3.34H16.67v1.66H15V66.67H11.67v1.66h1.66v3.34H6.67V70H5V68.33H3.33V61.67H5V60H6.67V58.33h5V60h1.66v3.33H15v-5H13.33V56.67H11.67V53.33h1.66V50H15V45h1.67V41.67h1.66V40H20v1.67h1.67v1.66H25V40H23.33V33.33H25V31.67h3.33V35H30v3.33h1.67Zm65,20V58.33H95V56.67H91.67V55H90V51.67H88.33V48.33H86.67v-5H85V40H83.33V38.33H81.67V36.67H78.33v-5H76.67V30H75V28.33H73.33V30H70v3.33H68.33v3.34H66.67v6.66h1.66V55H70v1.67h1.67v1.66H75V60h1.67v1.67h1.66V65H80v6.67h1.67v1.66h1.66V75h8.34V73.33H95V71.67h1.67V70h1.66V60Zm0,3.33v5H95V70H93.33v1.67H86.67V68.33h1.66V66.67H85v1.66H83.33V66.67H81.67V63.33H80V60H78.33V58.33H76.67V56.67H75V53.33H73.33V55H71.67V53.33H70v-5h1.67v3.34h1.66V50H75V45H73.33V43.33H70V41.67H68.33V38.33H70V35h1.67V31.67H75v1.66h1.67V40H75v3.33h3.33V41.67H80V40h1.67v1.67h1.66V45H85v5h1.67v3.33h1.66v3.34H86.67v1.66H85v5h1.67V60h1.66V58.33h5V60H95v1.67h1.67Z" style="fill: #3c3a39"/>';
    }
    
    function _buildOrb(string memory color) internal pure returns (string memory) {
        return string(abi.encodePacked('<path d="M13.33,51.67v1.66H11.67v3.34H15V55h1.67V51.67H13.33Zm73.34,1.66V51.67H83.33V55H85v1.67h3.33V53.33Z" style="fill: ', color, '"/>'));
    }
}

contract ChainArtefact_Arms is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        require(tokenId > 0 && tokenId < Base.limitNumber + 1, "Token ID invalid");
        
        string[5] memory colors;
        colors[0] = Builder.getColor(tokenId * 2, 1); 
        colors[1] = Builder.getColor(tokenId * 4, 2); 
        colors[2] = Builder.getColor(tokenId * 6, 3); 
        colors[3] = Builder.getColor(tokenId * 8, 4); 
        colors[4] = Builder.getColor(tokenId * 10, 5); 

        string memory main = "";


        uint256 monkRnd = Builder.randomValue(tokenId, 8, 99);
        uint8 monkint = 0;
        if( monkRnd > 94 ){
            monkint = 1;
            main = string(abi.encodePacked(main, Monk._buildMonk(colors[0])));
        }

        uint256 effectRnd = Builder.randomValue(tokenId, 11, 99);
        uint8 effectint = 0;
        if( effectRnd < 6 ){
            effectint = 1;
            main = string(abi.encodePacked(main, Monk._buildEffect(colors[1])));
        }

        
        main = string(abi.encodePacked(main, Monk._buildBase(colors[2])));
        
        main = string(abi.encodePacked(main, Monk._buildShadow()));
        
        main = string(abi.encodePacked(main, Monk._buildKazari(colors[3])));
        
        main = string(abi.encodePacked(main, Monk._buildLine()));
        
        main = string(abi.encodePacked(main, Monk._buildOrb(colors[4])));
        
        main = string(abi.encodePacked(main, '<text x="4" y="99" class="title">', Base.namePrefix, Strings.toString(tokenId), '</text>'));
        
        return createJSON(string(abi.encodePacked(Base.svgHeader, main, Base.svhfooter)), string(abi.encodePacked(Base.namePrefix, Strings.toString(tokenId))), Base.discription, effectint, monkint, colors);
    }
    
    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < Base.mintedNumber + 1, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > Base.mintedNumber && tokenId < Base.limitNumber + 1, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    
    function createJSON(string memory output, string memory mainString, string memory discriptionStr, uint8 effectint, uint8 monkint, string[5] memory colors) internal pure returns (string memory) {
        string[15] memory attr;
        attr[0] = '"attributes":[{"trait_type":"Effect","value":"';
        attr[1] = Strings.toString(effectint);
        attr[2] = '"},{"trait_type":"Secret","value":"';
        attr[3] = Strings.toString(monkint);
        if(monkint == 1){
            attr[4] = '"},{"trait_type":"SecretColor","value":"';
            attr[5] = colors[0];
        }
        if(effectint == 1){
            attr[6] = '"},{"trait_type":"EffectColor","value":"';
            attr[7] = colors[1];
        }
        attr[8] = '"},{"trait_type":"BaseColor","value":"';
        attr[9] = colors[2];
        attr[10] = '"},{"trait_type":"KazariColor","value":"';
        attr[11] = colors[3];
        attr[12] = '"},{"trait_type":"OrbColor","value":"';
        attr[13] = colors[4];
        attr[14] = '"}],';
        
        string memory attrStr = string(abi.encodePacked(attr[0], attr[1], attr[2], attr[3], attr[4], attr[5]));
        attrStr = string(abi.encodePacked(attrStr, attr[6], attr[7], attr[8], attr[9], attr[10], attr[11], attr[12]));
        attrStr = string(abi.encodePacked(attrStr, attr[13], attr[14]));
        
        string memory out = Base64.encode(bytes(output));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', mainString, '", "description": "', discriptionStr, '", ', attrStr, ' "image": "data:image/svg+xml;base64,', out, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    constructor() ERC721("ChainArtefactArms", "CAArms") Ownable() {}
}