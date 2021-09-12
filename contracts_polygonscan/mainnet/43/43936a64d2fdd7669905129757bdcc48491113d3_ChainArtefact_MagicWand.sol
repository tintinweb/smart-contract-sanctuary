/**
 *Submitted for verification at polygonscan.com on 2021-09-12
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

contract ChainArtefact_MagicWand is ERC721Enumerable, ReentrancyGuard, Ownable {

    string private constant discription = 'Full-On-Chain Artefact Series. MagicWand Version. Engraved on the chain.';
    string private constant namePrefix = 'ChainArtefact MagicWand #';
    string private constant svgHeader = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="1000px" height="1000px" viewBox="0 0 100 100"><g class="cls-1">';
    
    string private constant effect_3 = '<path class="cls-3" d="M78.56,40.22V36.89H76.89V33.56H75.22V30.22H73.56V28.56H71.89V26.89H70.22V25.22H68.56V23.56H66.89V21.89H63.56V20.22H60.22V18.56h-5V16.89H43.56v1.67H36.89V5.22H35.22V6.89H33.56V8.56H31.89v1.66H30.22v1.67H28.56V10.22H26.89V8.56H25.22V6.89H23.56V5.22H21.89V18.56h-10v1.66h1.67v1.67h1.66v1.67h1.67v1.66H15.22v1.67H13.56v1.67H11.89v1.66H10.22v1.67H8.56v1.67H20.22v1.66H18.56v3.34H16.89v5H15.22V55.22h1.67v5h1.67v3.34h1.66v3.33h1.67v1.67h1.67v1.66h1.66v1.67h1.67v1.67h1.67v1.66h1.66v1.67h3.34v1.67h3.33v1.66h5v1.67H55.22V80.22h5V78.56h3.34V76.89h3.33V75.22h1.67V73.56h1.66V71.89h1.67V70.22h1.67V68.56h1.66V65.22h1.67V61.89h1.67v-5h1.66V40.22Zm-38.34-20h10v1.67H48.56v1.67H46.89v1.66H43.56V23.56H41.89V21.89H40.22Zm18.34,8.34v1.66h3.33v1.67h1.67v1.67h1.66v1.66h1.67v3.34h1.67v3.33h1.66v5h1.67v5H70.22v5H68.56v3.33H66.89v1.67H65.22v1.67H63.56v1.66H61.89v1.67H60.22v1.67H58.56v1.66h-5v1.67H41.89V70.22H38.56V68.56H35.22V66.89H33.56V65.22H31.89V63.56H30.22V61.89H28.56V58.56H26.89v-5H25.22V50.22h1.67V46.89h1.67V45.22h1.66V43.56h1.67V41.89h1.67V40.22h1.66V38.56h1.67V36.89h1.67V35.22h1.66V33.56h10V31.89H48.56V30.22H46.89V26.89h8.33v1.67ZM31.89,11.89h1.67V10.22h1.66v6.67H33.56V15.22H31.89Zm-3.33,5V13.56h1.66v3.33h1.67v1.67h-5V16.89Zm-5-6.67h1.66v1.67h1.67v3.33H25.22v1.67H23.56Zm0,10H36.89v1.67h1.67v1.67h1.66v1.66h1.67v1.67h1.67v1.67H41.89v3.33H23.56Zm0,13.34H36.89v1.66H35.22v1.67H33.56v1.67H31.89v1.66H30.22v1.67H28.56v1.67H26.89v1.66H25.22v1.67H23.56ZM16.89,20.22h3.33v1.67H16.89ZM13.56,31.89V30.22h1.66V28.56h1.67V26.89h1.67V25.22h1.66V23.56h1.67v8.33Zm65,23.33H76.89v5H75.22v3.34H73.56v3.33H71.89v1.67H70.22v1.66H68.56v1.67H66.89v1.67H65.22v1.66H61.89v1.67H58.56v1.67h-5v1.66h-10V78.56h-5V76.89H35.22V75.22H31.89V73.56H30.22V71.89H28.56V70.22H26.89V68.56H25.22V66.89H23.56V65.22H21.89V61.89H20.22V58.56H18.56v-5H16.89V45.22h1.67v-5h1.66V36.89h1.67v15h1.67v3.33h1.66v5h1.67v3.34h1.67v1.66h1.66v1.67h1.67v1.67h1.67v1.66h3.33v1.67h3.33v1.67h15V71.89h5V70.22h1.67V68.56h1.67V66.89h1.66V65.22h1.67V63.56h1.67V61.89h1.66V58.56h1.67v-5h1.67V45.22H71.89v-5H70.22V36.89H68.56V33.56H66.89V31.89H65.22V30.22H63.56V28.56H60.22V26.89H56.89V25.22H50.22V23.56h1.67V21.89h1.67V20.22h5v1.67h3.33v1.67h3.33v1.66h1.67v1.67h1.67v1.67h1.66v1.66h1.67v1.67h1.67v3.33h1.66v3.34h1.67v3.33h1.67Z"/>';
    string private constant effect_2 = '<path class="cls-4" d="M68.56,31.89H56.89v1.67H55.22v1.66h-5v1.67H48.56V33.56h1.66V31.89h1.67V30.22h1.67V28.56h1.66V26.89H48.56V25.22h3.33V23.56h5V21.89h3.33V20.22H48.56V18.56h3.33V16.89h3.33V15.22h1.67V13.56h1.67V11.89h5V10.22H46.89V8.56H38.56v1.66h-5v1.67H30.22v1.67H28.56v1.66H25.22v1.67H21.89v1.67H18.56v1.66h5v1.67H21.89v1.67H18.56v1.66H15.22v1.67H11.89v1.67H23.56v1.66H21.89v1.67H18.56v1.67H15.22v1.66H11.89v1.67H10.22v1.67h15v1.66H21.89v1.67H20.22v1.67h6.67v1.66H25.22v1.67H21.89v1.67H18.56v1.66H16.89v1.67H28.56V50.22h3.33V48.56h5V46.89H50.22V45.22h5V43.56h3.34V41.89h1.66V40.22h1.67V38.56h1.67V36.89h1.66V35.22h1.67V33.56h3.33V31.89Z"/>';
    string private constant effect_1 = '<path class="cls-5" d="M51.89,11.89v1.67h-5v1.66H43.56V13.56h1.66V11.89h1.67V8.56h1.67V6.89h1.66V5.22H43.56V6.89H31.89V8.56H28.56v3.33H26.89v1.67H25.22v3.33H23.56v10h1.66v6.67h1.67v1.66h1.67v3.34h1.66v1.66h6.67V38.56h1.67V36.89h1.66V35.22h1.67v-5h1.67V28.56h1.66v-5h1.67V21.89h3.33V20.22h1.67V18.56h1.67v-5h3.33V11.89Z"/>';
    string private constant color = '<path class="cls-6" d="M81.89,78.56V76.89H80.22V75.22H78.56V73.56H76.89V71.89H75.22V70.22H73.56V66.89H71.89V65.22H70.22V61.89H68.56V60.22H66.89V56.89H65.22V53.56H63.56V51.89H61.89V48.56H60.22V45.22h1.67V36.89H60.22V33.56H58.56V30.22H56.89V26.89H53.56V25.22h-5V23.56H46.89v3.33h3.33v1.67h1.67v6.66h1.67v3.34H51.89v3.33H50.22v1.67H46.89v1.66H45.22V43.56h-5V41.89H38.56V40.22H36.89V38.56H35.22V36.89H33.56V35.22H31.89V33.56H30.22V30.22H28.56V28.56H26.89V26.89H25.22V25.22H18.56v1.67H16.89v6.67h1.67v1.66h1.66V31.89h1.67v1.67h1.67v1.66h1.66v3.34h1.67v3.33h1.67v1.67h1.66v1.66h1.67v1.67h1.67v1.67h1.66v1.66h1.67v1.67H48.56v1.67h6.66v1.66h1.67v1.67h1.67v1.67h1.66v3.33h1.67v3.33h1.67v1.67h1.66v5h1.67v3.33h1.67v1.67h1.66v3.33h1.67v1.67h1.67v3.33h1.66v3.34h1.67v6.66h1.67V91.89h3.33V85.22h1.67V78.56Z"/>';
    string private constant brigt = '<polygon class="cls-7" points="60.22 43.56 60.22 38.56 58.56 38.56 58.56 35.22 56.89 35.22 56.89 31.89 55.22 31.89 55.22 28.56 53.56 28.56 53.56 33.56 55.22 33.56 55.22 36.89 56.89 36.89 56.89 40.22 58.56 40.22 58.56 41.89 56.89 41.89 56.89 51.89 58.56 51.89 58.56 53.56 60.22 53.56 60.22 50.22 58.56 50.22 58.56 43.56 60.22 43.56"/>';
    string private constant mainorb = '<polygon class="cls-8" points="46.89 36.89 46.89 35.22 46.89 33.56 46.89 31.89 46.89 30.22 45.22 30.22 45.22 28.56 45.22 26.89 43.56 26.89 43.56 25.22 43.56 23.56 41.89 23.56 41.89 21.89 41.89 20.22 40.22 20.22 40.22 18.56 38.56 18.56 38.56 16.89 36.89 16.89 36.89 15.22 35.22 15.22 33.56 15.22 31.89 15.22 31.89 13.56 30.22 13.56 28.56 13.56 28.56 15.22 26.89 15.22 26.89 16.89 26.89 18.56 26.89 20.22 26.89 21.89 26.89 23.56 26.89 25.22 28.56 25.22 28.56 26.89 30.22 26.89 30.22 28.56 31.89 28.56 31.89 30.22 33.56 30.22 33.56 31.89 35.22 31.89 35.22 33.56 36.89 33.56 36.89 35.22 38.56 35.22 40.22 35.22 40.22 36.89 41.89 36.89 41.89 38.56 43.56 38.56 45.22 38.56 45.22 40.22 46.89 40.22 48.56 40.22 48.56 38.56 48.56 36.89 46.89 36.89"/><polygon class="cls-9" points="30.23 23.55 30.23 20.22 31.89 20.22 31.89 18.55 35.23 18.55 35.23 16.88 30.23 16.88 30.23 18.55 28.56 18.55 28.56 23.55 30.23 23.55"/>';
    string private constant line = '<path class="cls-10" d="M81.89,78.55V76.88H80.23V75.22H78.56V73.55H76.89V71.88H75.23V70.22H73.56V66.88H71.89V65.22H70.23V61.88H68.56V60.22H66.89V56.88H65.23V53.55H63.56V51.88H61.89V48.55H60.23V45.23h1.66V36.88H60.23V33.55H58.56V30.22H56.89V26.88H53.56V25.22h-5V23.55H46.88v1.67H43.56V23.55H41.89V20.22H40.23V18.55H38.56V16.88H36.89V15.22h-5V13.55H28.55v1.67H26.88v10h1.67v1.65H25.23V25.22H18.55v1.66H16.88v6.68h1.67v1.67h1.68V31.89h1.65v1.67h1.67v1.67h1.67v3.33h1.66v3.33h1.67v1.67h1.67v1.67h1.66v1.66h1.67v1.67h1.67v1.67h1.66v1.66h5v1.67h1.67v8.32H41.88v3.34H40.22v1.67h1.67V65.23h3.34V63.56h8.32v1.67h3.33v1.66h1.68V65.22H56.89V61.88H55.23V55.23h1.65v1.66h1.67v1.67h1.67v3.33h1.66v3.34h1.67v1.66h1.67v5h1.66v3.34h1.67v1.66h1.67v3.34h1.66v1.66h1.67v3.34h1.67v3.33h1.66v6.67h1.68V91.89h3.33V85.23h1.67V78.55ZM45.23,60.22v-5h1.66V53.56h5v1.67h1.67v5H51.88v1.66h-5V60.22Zm31.65,15v3.32H75.22v1.67H73.56v-5Zm-3.33-3.34v1.66H71.88v1.67H70.23V71.89ZM41.89,50.22V48.55H40.22v1.67H38.56V48.55H36.89V46.88H35.23V45.22H33.56V43.55H31.89V41.88H30.23V40.22H28.56V36.88H26.89V33.55H25.23V31.88H23.56V30.22H21.89V28.55H20.23V26.89h3.32v1.67h1.67v1.67h1.66v1.66h1.67v3.34h1.67v1.66h1.66v1.67h1.67v1.67h1.67v1.66h1.66v1.67h1.67v1.67h5v1.66h5V45.23h3.33V43.56h1.67V40.23h1.67V33.55H53.56v-5h1.66v3.33h1.66v3.34h1.67v3.33h1.67v5H58.55v6.68h1.67v3.33h1.66v1.67h1.67v3.33h1.67v3.33h1.66v1.67h1.67v3.33h1.67v3.33H66.89v-5H65.23V63.55H63.56V60.22H61.89V56.88H60.23V55.22H58.56V53.55H56.89V50.22H53.55v1.66H50.23V50.22Zm-5-31.66v1.67h1.67v1.66h1.67v3.34h1.66v3.33h1.67v3.33h1.67v5H43.56V35.22H41.89V33.55H38.56V31.88H36.89V30.22H35.23V28.55H33.56V26.88H31.89V25.22H30.23V23.55H28.56V16.89h6.66v1.67Zm15,10v6.67h1.67v3.32H51.88v3.33H50.22v1.67H46.88v1.67H45.23V43.55h-5V41.88H38.56V40.22H36.89V38.55H35.23V36.88H33.56V35.23h6.66v1.66h1.66v1.67h3.34v1.67h3.34V36.88H46.89V30.22H45.23V26.89h5v1.67ZM33.55,30.23v1.66h1.67v1.66h-5V30.22H28.56V28.56h3.32v1.67ZM76.89,86.88V80.23h1.67V78.56h1.66v1.67h1.66v3.32H80.22v6.67H78.56V86.88Z"/>';
    string private constant orb = '<polygon class="cls-8" points="51.89 55.22 51.89 53.56 50.22 53.56 48.56 53.56 46.89 53.56 46.89 55.22 45.22 55.22 45.22 56.89 45.22 58.56 45.22 60.22 46.89 60.22 46.89 61.89 48.56 61.89 50.22 61.89 51.89 61.89 51.89 60.22 53.56 60.22 53.56 58.56 53.56 56.89 53.56 55.22 51.89 55.22"/><polygon class="cls-9" points="46.89 60.23 46.89 56.89 48.56 56.89 48.56 55.23 51.89 55.23 51.89 53.56 46.89 53.56 46.89 55.23 45.23 55.23 45.23 60.23 46.89 60.23"/>';

    string private constant svhfooter = '</g></svg>';

    uint256 private constant limitNumber = 3000;
    uint256 private constant mintedNumber = 2000;
    
    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        require(tokenId > 0 && tokenId < limitNumber + 1, "Token ID invalid");
        
        string[5] memory colors;
        colors[0] = Builder.getColor(tokenId * 9, 1); 
        colors[1] = Builder.getColor(tokenId * 5, 2); 
        colors[2] = Builder.getColor(tokenId * 3, 3); 
        colors[3] = Builder.getColor(tokenId * 7, 4); 
        colors[4] = Builder.getColor(tokenId * 11, 4); 
        
        string[11] memory styles;
        styles[0] = '<style type="text/css">.cls-1{isolation: isolate;}.cls-7 {fill: #717071;}.cls-7, .cls-9 {mix-blend-mode: overlay;}.cls-9 {fill: #fff;}.cls-10 {fill: #3e3a39;}.cls-3{fill:';
        styles[1] = colors[0];
        styles[2] = ';}.cls-4{fill:';
        styles[3] = colors[1];
        styles[4] = ';}.cls-5{fill:';
        styles[5] = colors[2];
        styles[6] = ';}.cls-6{fill:';
        styles[7] = colors[3];
        styles[8] = ';}.cls-8{fill:';
        styles[9] = colors[4];
        styles[10] = ';}.title { fill: #fefefe; font-family: serif; font-size: 5px; }</style><rect width="100%" height="100%" fill="#101010" />';
        
        string memory buildSet = string(abi.encodePacked(svgHeader, styles[0], styles[1], styles[2], styles[3], styles[4], styles[5]));
        buildSet = string(abi.encodePacked(buildSet, styles[6], styles[7], styles[8], styles[9], styles[10]));

        uint256 lineRnd = Builder.randomValue(tokenId, 9, 100);
        uint8 effectint = 0;
        string memory effectData = "";
        if( lineRnd >= 98 ){
            effectData = effect_3;
            effectint = 3;
        }
        if( lineRnd >= 83 && lineRnd < 98 ){
            effectData = effect_2;
            effectint = 2;
        }
        if( lineRnd >= 78 && lineRnd < 83 ){
            effectData = effect_1;
            effectint = 1;
        }
        string memory text = string(abi.encodePacked('<text x="4" y="99" class="title">', namePrefix, Strings.toString(tokenId), '</text>'));
        
        return createJSON(string(abi.encodePacked(buildSet, effectData, color, brigt, mainorb, line, orb, text, svhfooter)), string(abi.encodePacked(namePrefix, Strings.toString(tokenId))), discription, effectint, colors);
    }
    
    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < mintedNumber + 1, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > mintedNumber && tokenId < limitNumber + 1, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    
    function createJSON(string memory output, string memory mainString, string memory discriptionStr, uint8 effectint, string[5] memory colors) internal pure returns (string memory) {
        string[13] memory attr;
        attr[0] = '"attributes":[{"trait_type":"Effect","value":"';
        attr[1] = Strings.toString(effectint);
        attr[2] = '"},{"trait_type":"EffectColor","value":"';
        if(effectint == 3){
            attr[3] = colors[0];
        }
        if(effectint == 2){
            attr[3] = colors[1];
        }
        if(effectint == 1){
            attr[3] = colors[2];
        }
        if(effectint == 0){
            attr[3] = 'None';
        }
        attr[4] = '"},{"trait_type":"BaseColor","value":"';
        attr[5] = colors[3];
        attr[6] = '"},{"trait_type":"OrbColor","value":"';
        attr[7] = colors[4];
        attr[12] = '"}],';
        
        string memory attrStr = string(abi.encodePacked(attr[0], attr[1], attr[2], attr[3], attr[4], attr[5]));
        attrStr = string(abi.encodePacked(attrStr, attr[6], attr[7], attr[8], attr[9], attr[10], attr[11], attr[12]));
        
        string memory out = Base64.encode(bytes(output));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', mainString, '", "description": "', discriptionStr, '", ', attrStr, ' "image": "data:image/svg+xml;base64,', out, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    constructor() ERC721("ChainArtefactMagicWand", "CAMagicWand") Ownable() {}
}