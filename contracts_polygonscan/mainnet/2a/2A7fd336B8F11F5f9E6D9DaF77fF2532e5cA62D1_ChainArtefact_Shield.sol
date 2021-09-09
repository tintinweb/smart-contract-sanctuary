/**
 *Submitted for verification at polygonscan.com on 2021-09-09
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

contract ChainArtefact_Shield is ERC721Enumerable, ReentrancyGuard, Ownable {

    string private constant discription = 'Full-On-Chain Artefact Series. Shield Version. Engraved on the chain.';
    string private constant namePrefix = 'ChainArtefact Shield #';
    string private constant svgHeader = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="1000px" height="1000px" viewBox="0 0 100 100" style="enable-background:new 0 0 100 100;" xml:space="preserve">';
    
    string private constant effect = '<path id="effect" class="effect" d="M46.7,96.7V95H45v-1.7h-1.7H40v-1.7h-1.7h-1.7v-1.7L35,90v-1.7h-1.7h-1.7v-1.7h-1.7v-1.7h-1.7v-1.7h-1.7v-1.7h-1.7v-1.7h-1.7v-1.7h-1.7v-1.7V75H20v-1.7V70h-1.7v-1.7v-5h-1.7v-1.7v-5h-1.7v-1.7V45h-1.7v-1.7v-6.7h-1.7v-1.7v-6.7h1.7v-1.7v-3.3h1.7v-1.7v-3.3h1.7v1.7v3.3h1.7v-1.7H20v-1.7h-1.7v-1.7v-1.7H20v1.7h1.7h1.7v-1.7h-1.7v-1.7V13h1.7v1.7h1.7h1.7V13h1.7v-1.7V5H30v1.7V10h1.7h1.7V8.3v-5h1.7L35,5v1.7h1.7v1.7h1.7V6.7h1.7L40,5V1.7h1.7v1.7V5h1.7H55V3.3h1.7V5h1.7v1.7h1.7h3.3v1.7h1.7h1.7V6.7V5h1.7v1.7V10h1.7V8.3h1.7V10v3.3h1.7v-1.7V10h1.7v1.7v5H77V15h1.7v1.7v1.7h1.7v-1.7h1.7v1.7v5h1.7v-1.7V20h1.7v1.7V30h1.7v-1.7h1.7V30v6.7h-1.7v1.7V45H85v1.7v10h-1.7v1.7v5h-1.7v1.7v5L80,70v1.7V75h-1.7v1.7v1.7h-1.7v1.7L75,80v1.7h-1.7v1.7h-1.7v1.7L70,85v1.7h-1.7v1.7h-1.7H65v1.7h-1.7v1.7h-1.7H60v1.7h-1.7H55v1.7h-1.7v1.7l0,0h-6.6V96.7z M48.3,91.7v1.7H50h1.7v-1.7h1.7H55V90h1.7H60v-1.7h1.7h1.7v-1.7h1.7v-1.7h1.7h1.7v-1.7h1.7v-1.7h1.7v-1.7h1.7v-1.7h1.7v-1.7V75H77v-1.7v-5h1.7v-1.7v-5h1.7v-1.7v-5h1.7v-1.7v-10h1.7v-1.7v-5h1.7v-1.7v-1.7h-1.7v-1.7V30h-1.7v-1.7h-1.7v-1.7V25h-1.7v-1.7v-1.7H77v-1.7L75,20v-1.7h-1.7v-1.7h-1.7v-1.7L70,15v-1.7h-1.7h-1.7v-1.7h-1.7h-3.3V9.9L60,10h-5V8.3h-1.7H45V10h-1.7h-5v1.7h-1.7h-3.3v1.7h-1.7H30v1.7h-1.7v1.7h-1.7v1.7h-1.7v1.7h-1.7v1.7h-1.7v1.7V25H20v1.7v1.7h-1.7v1.7h-1.7v1.7v1.7h-1.7v3.3h1.7v1.7v5h1.7v1.7v10H20v1.7v5h1.7v1.7v5h1.7v1.7v5h1.7V77v1.7h1.7v1.7h1.7v1.7h1.7v1.7h1.7v1.7h1.7H35v1.7h1.7v1.7h1.7H40v1.7h1.7H45v1.7h1.7h1.6V91.7z M15,25v1.7h1.7V25v-1.7H15L15,25z"/>';
    string private constant st1 = '<polygon class="st1" points="81.7,33.3 81.7,31.7 81.7,30 80,30 80,28.3 78.3,28.3 78.3,26.7 78.3,25 76.7,25 76.7,23.3 76.7,21.7 75,21.7 75,20 73.3,20 73.3,18.3 71.7,18.3 71.7,16.7 70,16.7 70,15 68.3,15 66.7,15 66.7,13.3 65,13.3 63.3,13.3 61.7,13.3 61.7,11.7 60,11.7 58.3,11.7 56.7,11.7 55,11.7 55,10 53.3,10 51.7,10 50,10 48.3,10 46.7,10 45,10 45,11.7 43.3,11.7 41.7,11.7 40,11.7 38.3,11.7 38.3,13.3 36.7,13.3 35,13.3 33.3,13.3 33.3,15 31.7,15 30,15 30,16.7 28.3,16.7 28.3,18.3 26.7,18.3 26.7,20 25,20 25,21.7 23.3,21.7 23.3,23.3 23.3,25 21.7,25 21.7,26.7 21.7,28.3 20,28.3 20,30 18.3,30 18.3,31.7 18.3,33.3 16.7,33.3 16.7,35 16.7,36.7 18.3,36.7 18.3,38.3 18.3,40 18.3,41.7 18.3,43.3 20,43.3 20,45 20,46.7 20,48.3 20,50 20,51.7 20,53.3 20,55 21.7,55 21.7,56.7 21.7,58.3 21.7,60 21.7,61.7 23.3,61.7 23.3,63.3 23.3,65 23.3,66.7 23.3,68.3 25,68.3 25,70 25,71.7 25,73.3 25,75 26.7,75 26.7,76.7 26.7,78.3 28.3,78.3 28.3,80 30,80 30,81.7 31.7,81.7 31.7,83.3 33.3,83.3 35,83.3 35,85 36.7,85 36.7,86.7 38.3,86.7 40,86.7 40,88.3 41.7,88.3 43.3,88.3 45,88.3 45,90 46.7,90 48.3,90 48.3,91.7 50,91.7 51.7,91.7 51.7,90 53.3,90 55,90 55,88.3 56.7,88.3 58.3,88.3 60,88.3 60,86.7 61.7,86.7 63.3,86.7 63.3,85 65,85 65,83.3 66.7,83.3 68.3,83.3 68.3,81.7 70,81.7 70,80 71.7,80 71.7,78.3 73.3,78.3 73.3,76.7 73.3,75 75,75 75,73.3 75,71.7 75,70 75,68.3 76.7,68.3 76.7,66.7 76.7,65 76.7,63.3 76.7,61.7 78.3,61.7 78.3,60 78.3,58.3 78.3,56.7 78.3,55 80,55 80,53.3 80,51.7 80,50 80,48.3 80,46.7 80,45 80,43.3 81.7,43.3 81.7,41.7 81.7,40 81.7,38.3 81.7,36.7 83.3,36.7 83.3,35 83.3,33.3 "/>';
    string private constant base = '<polygon id="base" class="base" points="78.3,31.7 78.3,30 76.7,30 76.7,26.7 75,26.7 75,25 73.3,25 73.3,23.3 71.7,23.3 71.7,21.7 70,21.7 70,20 68.3,20 68.3,18.3 66.7,18.3 66.7,16.7 63.3,16.7 63.3,15 60,15 60,13.3 51.7,13.3 51.7,11.7 48.3,11.7 48.3,13.3 40,13.3 40,15 36.7,15 36.7,16.7 33.3,16.7 33.3,18.3 31.7,18.3 31.7,20 30,20 30,21.7 28.3,21.7 28.3,23.3 26.7,23.3 26.7,25 25,25 25,26.7 23.3,26.7 23.3,30 21.7,30 21.7,31.7 20,31.7 20,41.7 21.7,41.7 21.7,53.3 23.3,53.3 23.3,60 25,60 25,66.7 26.7,66.7 26.7,73.3 28.3,73.3 28.3,75 30,75 30,76.7 31.7,76.7 31.7,80 35,80 35,81.7 36.7,81.7 36.7,83.3 38.3,83.3 38.3,85 41.7,85 41.7,86.7 43.3,86.7 43.3,83.3 45,83.3 45,81.7 48.3,81.7 48.3,80 51.7,80 51.7,81.7 55,81.7 55,83.3 56.7,83.3 56.7,86.7 58.3,86.7 58.3,85 61.7,85 61.7,83.3 63.3,83.3 63.3,81.7 65,81.7 65,80 68.3,80 68.3,76.7 70,76.7 70,75 71.7,75 71.7,73.3 73.3,73.3 73.3,66.7 75,66.7 75,60 76.7,60 76.7,53.3 78.3,53.3 78.3,41.7 80,41.7 80,31.7 "/>';
    string private constant st4 = '<polygon class="st3" points="63.3,20 63.3,18.3 60,18.3 60,16.7 55,16.7 55,15 50,15 50,73.3 51.7,73.3 51.7,75 53.3,75 53.3,78.3 55,78.3 55,80 56.7,80 56.7,81.7 58.3,81.7 58.3,73.3 60,73.3 60,58.3 61.7,58.3 61.7,43.3 63.3,43.3 63.3,30 65,30 65,20 "/><polygon class="st1" points="65,35 61.7,35 61.7,31.6 60,31.6 60,28.3 58.4,28.3 58.4,26.6 56.7,26.6 56.7,25 53.4,25 53.4,21.6 51.7,21.6 51.7,18.3 48.3,18.3 48.3,21.6 46.6,21.6 46.6,25 43.3,25 43.3,26.6 41.6,26.6 41.6,28.3 40,28.3 40,31.6 38.3,31.6 38.3,35 35,35 35,36.6 33.3,36.6 33.3,38.4 35,38.4 35,40 38.3,40 38.3,43.4 40,43.4 40,46.7 41.6,46.7 41.6,48.4 45,48.4 45,50 46.6,50 46.6,53.4 48.3,53.4 48.3,56.7 51.7,56.7 51.7,53.4 53.4,53.4 53.4,50 55,50 55,48.4 58.4,48.4 58.4,46.7 60,46.7 60,43.4 61.7,43.4 61.7,40 65,40 65,38.4 66.7,38.4 66.7,36.6 65,36.6 "/><path class="st4" d="M83.4,33.3V30h-1.7v-1.7H80V25h-1.7v-3.3h-1.7V20H75v-1.7h-1.7v-1.7h-1.7V15H70v-1.7h-3.3v-1.7h-5V10H55V8.3H45V10h-6.7v1.7h-5v1.7H30V15h-1.7v1.7h-1.7v1.7H25V20h-1.7v1.7h-1.7V25H20v3.3h-1.7V30h-1.7v3.3H15v3.4h1.7v6.7h1.7V55H20v6.7h1.7v6.7h1.7V75H25v3.3h1.7V80h1.7v1.7H30v1.7h1.7V85H35v1.7h1.7v1.7H40V90h5v1.7h3.3v1.7h3.4v-1.7H55V90h5v-1.7h3.3v-1.7H65V85h3.3v-1.7H70v-1.7h1.7V80h1.7v-1.7H75V75h1.7v-6.7h1.7v-6.7H80V55h1.7V43.4h1.7v-6.7H85v-3.4H83.4z M83.3,36.6h-1.7v6.7H80V55h-1.7v6.7h-1.7v6.7H75V75h-1.7v3.3h-1.7V80H70v1.7h-1.7v1.7H65V85h-1.7v1.7H60v1.7h-5V90h-3.3v1.7h-3.3V90H45v-1.7h-5v-1.7h-3.3V85H35v-1.7h-3.3v-1.7H30V80h-1.7v-1.7h-1.7V75H25v-6.7h-1.7v-6.7h-1.7V55H20V43.3h-1.7v-6.7h-1.7v-3.3h1.7V30H20v-1.7h1.7V25h1.7v-3.3H25V20h1.7v-1.7h1.7v-1.7H30V15h3.3v-1.7h5v-1.7H45V10h10v1.7h6.7v1.7h5V15H70v1.7h1.7v1.7h1.7V20H75v1.7h1.7V25h1.7v3.3H80V30h1.7v3.3h1.7L83.3,36.6L83.3,36.6z M65,35h-3.3v-3.3H60v-3.3h-1.7v-1.7h-1.7V25h-3.3v-3.3h-1.7v-3.3h-3.4v3.3h-1.7V25h-3.3v1.7h-1.7v1.7H40v3.3h-1.7V35H35v1.7h-1.7v1.7H35V40h3.3v3.3H40v3.3h1.7v1.7H45V50h1.7v3.3h1.7v3.3h3.4v-3.3h1.7V50H55v-1.7h3.3v-1.7H60v-3.3h1.7V40H65v-1.7h1.7v-1.7H65V35z M40,40h-1.6v-1.7H35v-1.6h3.3V35H40V40z M53.4,26.7h3.3v1.7h1.7v3.3h-1.6V30H55v-1.7h-1.7v-1.6H53.4z M46.7,25h1.7v-3.3h3.3V25h1.7v1.6h-6.6V25H46.7z M41.7,28.4h1.7v-1.7h3.3v1.6H45V30h-1.7v1.7h-1.6V28.4z M41.7,33.4h1.7v-1.7H45V30h1.7v-1.7h6.6V30H55v1.7h1.7v1.7h1.7V40h-1.7v1.7H55v1.7h-1.7V45h-6.6v-1.7H45v-1.7h-1.7V40h-1.7v-6.6H41.7z M40,31.7h1.6v1.6H40V31.7z M60,43.3h-1.7v3.3H55v1.7h-1.7V50h-1.7v3.3h-3.3V50h-1.7v-1.7H45v-1.7h-3.3v-3.3H40V40h1.6v1.7h1.7v1.7H45V45h1.7v1.7h6.7V45H55v-1.7h1.7v-1.7h1.7V40H60V43.3z M60,33.3h-1.6v-1.6H60V33.3z M65,38.3h-3.3V40H60v-5h1.6v1.7H65V38.3z"/>';
    string private constant orb = '<polygon id="orb" class="st5" points="56.7,33.3 56.7,31.7 55,31.7 55,30 53.3,30 53.3,28.3 51.7,28.3 50,28.3 48.3,28.3 46.7,28.3 46.7,30 45,30 45,31.7 43.3,31.7 43.3,33.3 41.7,33.3 41.7,35 41.7,36.7 41.7,38.3 41.7,40 43.3,40 43.3,41.7 45,41.7 45,43.3 46.7,43.3 46.7,45 48.3,45 50,45 51.7,45 53.3,45 53.3,43.3 55,43.3 55,41.7 56.7,41.7 56.7,40 58.3,40 58.3,38.3 58.3,36.7 58.3,35 58.3,33.3 "/>';
    string private constant st6 = '<polygon class="st1" points="53.3,31.7 53.3,30 50,30 50,31.7 51.7,31.7 51.7,33.3 53.3,33.3 53.3,35 55,35 55,31.7 "/><polygon class="st6" points="48.3,41.7 48.3,40 46.7,40 46.7,38.3 45,38.3 45,41.7 46.7,41.7 46.7,43.3 50,43.3 50,41.7 "/>';
    string private constant line = '<path id="line" class="line" d="M58.3,83.3v-1.7V80h-1.7v-1.7h-1.7h-1.7v-1.7h-1.7v-1.7L50,75h-1.7v1.7l0,0h-1.7v1.7l0,0h-3.3v1.7l0,0h-1.7v1.7v1.7l0,0H40v-1.7h-1.7v-1.7h-1.7v-1.7h-1.7v-1.7h-1.7V75h-1.7v-1.7h-1.7v-1.7h-1.7v-1.7v-5h-1.7v-1.7v-6.7h-1.7v-1.7v-6.7H23v-1.7v-8.3h-1.7v-1.7v-3.3H23v-1.7h1.7v-1.7V28h1.7v-1.7V25h1.7v1.7h1.7v1.7h1.7v1.7h1.7v1.7l0,0h-1.7v-1.7L30,30v-1.7h-1.7V30h-1.7v1.7v1.7h-1.7v1.7h-1.7v1.7h1.7h3.3v-1.7h1.7v1.7l0,0h-1.7v1.7h-1.7v1.7L25,40v1.7v5h1.7v1.7V50h1.7H30v-1.7h1.7v-1.7h1.7v-1.7h1.7v1.7l0,0h-1.7v1.7V50h-1.7v1.7H30v1.7h-1.7h-1.7v1.7h1.7v1.7v6.7H30v1.7v1.7h1.7h6.7v1.7h1.7v1.7h1.7V72l0,0H40v-1.7h-1.7v-1.7h-1.7H35v1.7h-1.7h-1.7V72h1.7v1.7H35v1.7h1.7v1.7h1.7v1.7h1.7v1.7h1.7v-1.7h1.7v-1.7h1.7h1.7v-1.7h1.7v-1.7h1.7H52v1.7h1.7v1.7h1.7h1.7v1.7h1.7v1.7h1.7v-1.7h1.7v-1.7h1.7v-1.7h1.7v-1.7h1.7V72H69v-1.7h-1.7H65v-1.7h-1.7h-1.7v1.7l0,0H60V72l0,0h-1.7v-1.7H60v-1.7h1.7v-1.7h1.7H70v-1.7v-1.7h1.7v-1.7V55h1.7v-1.7h-1.7H70v-1.7h-1.7v-1.7h-1.7v-1.7v-1.7h-1.7v-1.7h1.7v1.7h1.7v1.7H70v1.7h1.7h1.7v-1.7v-1.7h1.7v-1.7v-5h-1.7v-1.7h-1.7v-1.7H70v-1.7h1.7v1.7h1.7h3.3v-1.7L75,35v-1.7h-1.7v-1.7V30h-1.7v-1.7h-1.7V30l0,0h-1.7v1.7l0,0h-1.7V30h1.7v-1.7h1.7v-1.7h1.7v-1.7h1.7v1.7v1.7H75V30v1.7h1.7v1.7h1.7v1.7v3.3h-1.7v1.7v8.3H75v1.7v6.7h-1.7v1.7V65h-1.7v1.7v5h-1.7v1.7h-1.7v1.7h-1.7v1.7h-1.7v1.7h-1.7v1.7h-1.7v1.7h-1.7v1.7l0,0h-1.4V83.3z"/>';

    string private constant svhfooter = '</svg>';
    
    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        require(tokenId > 0 && tokenId < 10001, "Token ID invalid");
        
        string[4] memory colors;
        colors[0] = Builder.getColor(tokenId * 1, 1); 
        colors[1] = Builder.getColor(tokenId * 3, 2); 
        colors[2] = Builder.getColor(tokenId * 5, 3); 
        colors[3] = Builder.getColor(tokenId * 7, 4); 
        
        string[10] memory styles;
        styles[1] = '<style type="text/css">.st1{fill:#FFFFFF;}.st3{opacity:0.3;fill:#AAAAAA;}.st4{fill:#3D3A39;}.st5{fill:#E50012;}.st6{opacity:0.38;fill:#939393;}.effect{fill:';
        styles[2] = colors[0];
        styles[3] = ';}.base{fill:';
        styles[4] = colors[1];
        styles[5] = ';}.orb{fill:';
        styles[6] = colors[2];
        styles[7] = ';}.line{fill:';
        styles[8] = colors[3];
        styles[9] = ';}.title { fill: #fefefe; font-family: serif; font-size: 5px; }</style><rect width="100%" height="100%" fill="#101010" />';
        
        uint256 rnd = Builder.randomValue(tokenId * 20, 8, 100);
        
        string memory buildSet = string(abi.encodePacked(svgHeader, styles[0], styles[1], styles[2], styles[3], styles[4], styles[5]));
        buildSet = string(abi.encodePacked(buildSet, styles[6], styles[7], styles[8], styles[9]));
        
        uint8 effectint = 0;
        if( rnd < 10 ){
            buildSet = string(abi.encodePacked(buildSet, effect));
            effectint = 1;
        }
        
        string memory text = string(abi.encodePacked('<text x="4" y="99" class="title">', namePrefix, Strings.toString(tokenId), '</text>'));
        
        return createJSON(string(abi.encodePacked(buildSet, st1, base, st4, orb, st6, line, text, svhfooter)), string(abi.encodePacked(namePrefix, Strings.toString(tokenId))), discription, effectint, colors);
    }
    
    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 8001, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 8000 && tokenId < 10001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    
    function createJSON(string memory output, string memory mainString, string memory discriptionStr, uint8 effectint, string[4] memory colors) internal pure returns (string memory) {
        string[13] memory attr;
        attr[0] = '"attributes":[{"trait_type":"Effect","value":"';
        attr[1] = Strings.toString(effectint);
        attr[2] = '"},{"trait_type":"EffectColor","value":"';
        attr[3] = colors[0];
        attr[4] = '"},{"trait_type":"BaseColor","value":"';
        attr[5] = colors[1];
        attr[6] = '"},{"trait_type":"OrbColor","value":"';
        attr[7] = colors[2];
        attr[8] = '"},{"trait_type":"LineColor","value":"';
        attr[9] = colors[3];
        attr[12] = '"}],';
        
        string memory attrStr = string(abi.encodePacked(attr[0], attr[1], attr[2], attr[3], attr[4], attr[5]));
        attrStr = string(abi.encodePacked(attrStr, attr[6], attr[7], attr[8], attr[9], attr[10], attr[11], attr[12]));
        
        string memory out = Base64.encode(bytes(output));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', mainString, '", "description": "', discriptionStr, '", ', attrStr, ' "image": "data:image/svg+xml;base64,', out, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    constructor() ERC721("ChainArtefactShield", "CASd") Ownable() {}
}