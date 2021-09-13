/**
 *Submitted for verification at polygonscan.com on 2021-09-13
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

contract ChainArtefact_Boots is ERC721Enumerable, ReentrancyGuard, Ownable {

    string private constant discription = 'Full-On-Chain Artefact Series. Boots Version. Engraved on the chain.';
    string private constant namePrefix = 'ChainArtefact Boots #';
    string private constant svgHeader = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="1000px" height="1000px" viewBox="0 0 100 100"><g class="cls-1">';
    
    string private constant effect = '<path class="cls-3" d="M83.33,65V58.33H81.67v3.34H80v1.66H78.33V60H76.67V58.33h1.66V55H80V53.33H76.67v3.34H75V53.33h1.67V51.67h1.66V48.33H76.67V50H75V48.33H73.33V46.67H75V45h1.67V43.33h1.66V41.67H80V38.33H78.33V40H76.67V33.33H75V31.67h1.67V25h1.66V21.67H76.67v1.66H75V25H73.33v1.67H71.67v1.66H70V30H66.67v3.33H65V35H63.33v1.67h-5v1.66H51.67V40H50V38.33H43.33V36.67h-5V35H36.67V33.33H35V30H31.67V28.33H30V26.67H28.33V25H26.67V23.33H25V21.67H23.33V25H25v6.67h1.67v1.66H25V40H23.33V38.33H21.67v3.34h1.66v1.66H25V45h1.67v1.67h1.66v1.66H26.67V50H25V48.33H23.33v3.34H25v1.66h1.67v3.34H25V53.33H21.67V55h1.66v3.33H25V60H23.33v3.33H21.67V61.67H20V58.33H18.33V65H16.67v6.67h1.66V75H20v1.67H43.33V73.33H50V56.67H46.67V48.33h1.66V45h5v3.33H55v8.34H51.67V73.33h6.66v3.34H81.67V75h1.66V71.67H85V65ZM20,70H18.33V68.33H20Zm63.33,0H81.67V68.33h1.66Z"/>';
    string private constant base = '<polygon class="cls-4" points="75 66.67 75 65 75 63.33 73.33 63.33 73.33 61.67 73.33 60 71.67 60 71.67 58.33 70 58.33 70 60 68.33 60 66.67 60 65 60 63.33 60 61.67 60 61.67 58.33 61.67 56.67 61.67 55 61.67 53.33 63.33 53.33 65 53.33 66.67 53.33 68.33 53.33 68.33 51.67 70 51.67 70 50 70 48.33 70 46.67 70 45 70 43.33 70 41.67 70 40 70 38.33 71.67 38.33 71.67 40 73.33 40 73.33 38.33 73.33 36.67 71.67 36.67 71.67 35 71.67 33.33 71.67 31.67 70 31.67 68.33 31.67 68.33 33.33 68.33 35 66.67 35 66.67 36.67 65 36.67 65 38.33 63.33 38.33 61.67 38.33 60 38.33 58.33 38.33 56.67 38.33 55 38.33 53.33 38.33 51.67 38.33 50 38.33 48.33 38.33 46.67 38.33 45 38.33 43.33 38.33 41.67 38.33 40 38.33 38.33 38.33 36.67 38.33 36.67 36.67 35 36.67 35 35 33.33 35 33.33 33.33 33.33 31.67 31.67 31.67 30 31.67 30 33.33 30 35 30 36.67 28.33 36.67 28.33 38.33 28.33 40 30 40 30 38.33 31.67 38.33 31.67 40 31.67 41.67 31.67 43.33 31.67 45 31.67 46.67 31.67 48.33 31.67 50 31.67 51.67 33.33 51.67 33.33 53.33 35 53.33 36.67 53.33 38.33 53.33 40 53.33 40 55 40 56.67 40 58.33 40 60 38.33 60 36.67 60 35 60 33.33 60 31.67 60 31.67 58.33 30 58.33 30 60 28.33 60 28.33 61.67 28.33 63.33 26.67 63.33 26.67 65 26.67 66.67 25 66.67 25 68.33 25 70 25 71.67 26.67 71.67 28.33 71.67 30 71.67 31.67 71.67 33.33 71.67 35 71.67 36.67 71.67 38.33 71.67 40 71.67 41.67 71.67 43.33 71.67 43.33 70 43.33 68.33 45 68.33 45 66.67 45 65 45 63.33 43.33 63.33 43.33 61.67 43.33 60 43.33 58.33 43.33 56.67 43.33 55 43.33 53.33 43.33 51.67 43.33 50 43.33 48.33 43.33 46.67 43.33 45 45 45 45 43.33 45 41.67 46.67 41.67 46.67 40 48.33 40 50 40 51.67 40 53.33 40 55 40 55 41.67 56.67 41.67 56.67 43.33 56.67 45 58.33 45 58.33 46.67 58.33 48.33 58.33 50 58.33 51.67 58.33 53.33 58.33 55 58.33 56.67 58.33 58.33 58.33 60 58.33 61.67 58.33 63.33 56.67 63.33 56.67 65 56.67 66.67 56.67 68.33 58.33 68.33 58.33 70 58.33 71.67 60 71.67 61.67 71.67 63.33 71.67 65 71.67 66.67 71.67 68.33 71.67 70 71.67 71.67 71.67 73.33 71.67 75 71.67 76.67 71.67 76.67 70 76.67 68.33 76.67 66.67 75 66.67"/>';
    string private constant shadow = '<path id="shadow-2" data-name="shadow" class="cls-5" d="M75,66.67v1.66H73.33V70H61.67V68.33H60V65H58.33v6.67H76.67v-5ZM41.67,68.33H40V70H28.33V68.33H26.67V66.67H25v5H43.33V65H41.67Z"/>';
    string private constant kazari = '<polygon class="cls-6" points="68.33 31.67 68.33 35 66.67 35 66.67 36.67 65 36.67 65 38.33 36.67 38.33 36.67 36.67 35 36.67 35 35 33.33 35 33.33 31.67 30 31.67 30 33.33 31.67 33.33 31.67 36.67 33.33 36.67 33.33 38.33 31.67 38.33 31.67 41.67 33.33 41.67 33.33 40 35 40 35 41.67 36.67 41.67 36.67 40 40 40 40 41.67 43.33 41.67 43.33 43.33 41.67 43.33 41.67 53.33 38.33 53.33 38.33 55 31.67 55 31.67 56.67 33.33 56.67 33.33 58.33 38.33 58.33 38.33 56.67 41.67 56.67 41.67 65 43.33 65 43.33 68.33 45 68.33 45 63.33 43.33 63.33 43.33 45 45 45 45 41.67 46.67 41.67 46.67 40 55 40 55 41.67 56.67 41.67 56.67 45 58.33 45 58.33 63.33 56.67 63.33 56.67 68.33 58.33 68.33 58.33 65 60 65 60 56.67 63.33 56.67 63.33 58.33 68.33 58.33 68.33 56.67 70 56.67 70 55 63.33 55 63.33 53.33 60 53.33 60 43.33 58.33 43.33 58.33 41.67 61.67 41.67 61.67 40 65 40 65 41.67 66.67 41.67 66.67 40 68.33 40 68.33 41.67 70 41.67 70 38.33 68.33 38.33 68.33 36.67 70 36.67 70 33.33 71.67 33.33 71.67 31.67 68.33 31.67"/>';
    string private constant line_demon = '<path class="cls-7" d="M83.33,38.33V35H81.67V31.67H80V28.33H78.33V25H76.67V38.33h1.66V40H80v3.33H78.33V45H76.67v1.67H75V45H73.33V41.67H75V35H73.33V30H66.67v3.33H65V35H63.33v1.67h-5v1.66h-15V36.67h-5V35H36.67V33.33H35V30H28.33v5H26.67v6.67h1.66V45H26.67v1.67H25V45H23.33V43.33H21.67V40h1.66V38.33H25V25H23.33v3.33H21.67v3.34H20V35H18.33v3.33H16.67v10h1.66V50H20v1.67h1.67v1.66H25V55h3.33v3.33H26.67v3.34H25v1.66H23.33V65H21.67V76.67H43.33V73.33h5v-10H46.67V60H45V46.67h1.67V43.33h1.66V40h5v3.33H55v3.34h1.67V60H55v3.33H53.33v10h5v3.34H80V65H78.33V63.33H76.67V61.67H75V58.33H73.33V55h3.34V53.33H80V51.67h1.67V50h1.66V48.33H85v-10ZM46.67,41.67H45V45H43.33V63.33H45v5H43.33v3.34H25v-5h1.67V63.33h1.66V60H30V58.33h1.67V60H40V53.33H33.33V51.67H31.67V38.33H30V40H28.33V36.67H30v-5h3.33V35H35v1.67h1.67v1.66h5V40h5Zm-15,15V55h6.66v3.33h-5V56.67ZM73.33,60v3.33H75v3.34h1.67v5H58.33V68.33H56.67v-5h1.66V45H56.67V41.67H55V40h5V38.33h5V36.67h1.67V35h1.66V31.67h3.34v5h1.66V40H71.67V38.33H70V51.67H68.33v1.66H61.67V60H70V58.33h1.67V60ZM70,55v1.67H68.33v1.66h-5V55H70Z"/>';
    string private constant line_angel = '<path class="cls-7" d="M76.67,20v1.67H75v1.66H73.33V25H71.67v5h-5v3.33H65V35H63.33v1.67h-5v1.66h-15V36.67h-5V35H36.67V33.33H35V30H30V25H28.33V23.33H26.67V21.67H25V20H8.33v1.67h5v1.66H15V25h5v1.67H13.33v1.66h3.34V30h5v1.67h-5v1.66h5V35H20v1.67h3.33v1.66H21.67V40H25v5h1.67v3.33h1.66V50H30v6.67H28.33v1.66H26.67v3.34H25v1.66H23.33V65H21.67V76.67H43.33V73.33h5v-10H46.67V60H45V46.67h1.67V43.33h1.66V40h5v3.33H55v3.34h1.67V60H55v3.33H53.33v10h5v3.34H80V65H78.33V63.33H76.67V61.67H75V58.33H73.33V56.67H71.67V50h1.66V48.33H75V45h1.67V40H80V38.33H78.33V36.67h3.34V35H80V33.33h5V31.67H80V30h5V28.33h3.33V26.67H81.67V25h5V23.33h1.66V21.67h5V20Zm-50,15V31.67h1.66V35Zm20,6.67H45V45H43.33V63.33H45v5H43.33v3.34H25v-5h1.67V63.33h1.66V60H30V58.33h1.67V60H40V53.33H33.33V51.67H31.67V38.33H30V40H28.33V36.67H30v-5h3.33V35H35v1.67h1.67v1.66h5V40h5Zm-15,15V55h6.66v3.33h-5V56.67ZM73.33,40H71.67V38.33H70V51.67H68.33v1.66H61.67V60H70V58.33h1.67V60h1.66v3.33H75v3.34h1.67v5H58.33V68.33H56.67v-5h1.66V45H56.67V41.67H55V40h5V38.33h5V36.67h1.67V35h1.66V31.67h3.34v5h1.66ZM70,55v1.67H68.33v1.66h-5V55Zm5-20H73.33V31.67H75Z"/>';
    string private constant line_spike = '<path class="cls-7" d="M80,58.33V60H78.33v1.67H75V58.33H73.33V56.67H71.67v-5h1.66V50H75V46.67h1.67V45h1.66V36.67H76.67V35H73.33V33.33H75V26.67h1.67V23.33H75V25H73.33v1.67H71.67V30h-5v3.33H65V35H63.33v1.67h-5v1.66h-15V36.67h-5V35H36.67V33.33H35V30H30V26.67H28.33V25H26.67V23.33H25v3.34h1.67v6.66h1.66V35H25v1.67H23.33V45H25v1.67h1.67V50h1.66v1.67H30v5H28.33v1.66H26.67v3.34H23.33V60H21.67V58.33H20v5h1.67V76.67H43.33V73.33h5V56.67H50V53.33H48.33V55H46.67v3.33H45V46.67h1.67V43.33h1.66V40h5v3.33H55v3.34h1.67V58.33H55V55H53.33V53.33H51.67v3.34h1.66V73.33h5v3.34H80V63.33h1.67v-5ZM26.67,45V43.33H25V40h1.67v1.67h1.66v1.66H30V45Zm20-3.33H45V45H43.33V63.33H45v5H43.33v3.34H25v-5h1.67V63.33h1.66V60H30V58.33h1.67V60H40V53.33H33.33V51.67H31.67V38.33H30V40H28.33V36.67H30v-5h3.33V35H35v1.67h1.67v1.66h5V40h5Zm-15,15V55h6.66v3.33h-5V56.67ZM75,41.67V40h1.67v3.33H75V45H71.67V43.33h1.66V41.67Zm1.67,30H58.33V68.33H56.67v-5h1.66V45H56.67V41.67H55V40h5V38.33h5V36.67h1.67V35h1.66V31.67h3.34v5h1.66V40H71.67V38.33H70V51.67H68.33v1.66H61.67V60H70V58.33h1.67V60h1.66v3.33H75v3.34h1.67ZM70,55v1.67H68.33v1.66h-5V55Z"/>';
    string private constant line_normal = '<path class="cls-7" d="M78.33,65V63.33H76.67V61.67H75V58.33H73.33V56.67H71.67V43.33h1.66V41.67H75V35H73.33V30H66.67v3.33H65V35H63.33v1.67h-5v1.66h-15V36.67h-5V35H36.67V33.33H35V30H28.33v5H26.67v6.67h1.66v1.66H30V56.67H28.33v1.66H26.67v3.34H25v1.66H23.33V65H21.67V76.67H43.33V73.33h5v-10H46.67V60H45V46.67h1.67V43.33h1.66V40h5v3.33H55v3.34h1.67V60H55v3.33H53.33v10h5v3.34H80V65ZM31.67,55h6.66v3.33h-5V56.67H31.67Zm15-13.33H45V45H43.33V63.33H45v5H43.33v3.34H25v-5h1.67V63.33h1.66V60H30V58.33h1.67V60H40V53.33H33.33V51.67H31.67V38.33H30V40H28.33V36.67H30v-5h3.33V35H35v1.67h1.67v1.66h5V40h5ZM70,56.67H68.33v1.66h-5V55H70ZM58.33,70V68.33H56.67v-5h1.66V45H56.67V41.67H55V40h5V38.33h5V36.67h1.67V35h1.66V31.67h3.34v5h1.66V40H71.67V38.33H70V51.67H68.33v1.66H61.67V60H70V58.33h1.67V60h1.66v3.33H75v3.34h1.67v5H58.33Z"/>';
    string private constant orb = '<path class="cls-8" d="M68.33,41.67V40H66.67v1.67H65V45h1.67v1.67h1.66V45H70V41.67ZM35,40H33.33v1.67H31.67V45h1.66v1.67H35V45h1.67V41.67H35Z"/>';

    string private constant svhfooter = '</g></svg>';

    uint256 private constant limitNumber = 3000;
    uint256 private constant mintedNumber = 2000;
    
    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        require(tokenId > 0 && tokenId < limitNumber + 1, "Token ID invalid");
        
        string[4] memory colors;
        colors[0] = Builder.getColor(tokenId * 2, 1); 
        colors[1] = Builder.getColor(tokenId * 4, 2); 
        colors[2] = Builder.getColor(tokenId * 6, 3); 
        colors[3] = Builder.getColor(tokenId * 8, 4); 
        
        string[9] memory styles;
        styles[0] = '<style type="text/css">.cls-1{isolation: isolate;}.cls-5 {fill: #231815;mix-blend-mode: hard-light;opacity: 0.3;}.cls-7 {fill: #4a4848;}.cls-3{fill:';
        styles[1] = colors[0];
        styles[2] = ';}.cls-4{fill:';
        styles[3] = colors[1];
        styles[4] = ';}.cls-6{fill:';
        styles[5] = colors[2];
        styles[6] = ';}.cls-8{fill:';
        styles[7] = colors[3];
        styles[8] = ';}.title { fill: #fefefe; font-family: serif; font-size: 5px; }</style><rect width="100%" height="100%" fill="#101010" />';
        
        string memory styleSet = string(abi.encodePacked(svgHeader, styles[0], styles[1], styles[2], styles[3], styles[4]));
        styleSet = string(abi.encodePacked(styleSet, styles[5], styles[6], styles[7], styles[8]));

        uint256 effectRnd = Builder.randomValue(tokenId, 11, 100);
        uint8 effectint = 0;
        string memory effectData = "";
        if( effectRnd > 95 ){
            effectRnd = 1;
            effectData = effect;
        }

        uint256 lineRnd = Builder.randomValue(tokenId, 9, 100);
        string memory lineData = line_normal;
        string memory lineName = "Normal";
        if( lineRnd == 100 ){
            lineData = line_demon;
            lineName = "Demon";
        }
        if( lineRnd == 50 ){
            lineData = line_angel;
            lineName = "Angel";
        }
        if( lineRnd <= 10 ){
            lineData = line_spike;
            lineName = "Spike";
        }

        string memory text = string(abi.encodePacked('<text x="4" y="99" class="title">', namePrefix, Strings.toString(tokenId), '</text>'));
        
        return createJSON(string(abi.encodePacked(styleSet, effectData, base, shadow, kazari, lineData, orb, text, svhfooter)), string(abi.encodePacked(namePrefix, Strings.toString(tokenId))), discription, effectint, lineName, colors);
    }
    
    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < mintedNumber + 1, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > mintedNumber && tokenId < limitNumber + 1, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    
    function createJSON(string memory output, string memory mainString, string memory discriptionStr, uint8 effectint, string memory lineName, string[4] memory colors) internal pure returns (string memory) {
        string[13] memory attr;
        attr[0] = '"attributes":[{"trait_type":"Effect","value":"';
        attr[1] = Strings.toString(effectint);
        attr[2] = '"},{"trait_type":"Style","value":"';
        attr[3] = lineName;
        attr[4] = '"},{"trait_type":"EffectColor","value":"';
        attr[5] = colors[0];
        attr[6] = '"},{"trait_type":"BaseColor","value":"';
        attr[7] = colors[1];
        attr[8] = '"},{"trait_type":"LineColor","value":"';
        attr[9] = colors[2];
        attr[10] = '"},{"trait_type":"OrbColor","value":"';
        attr[11] = colors[3];
        attr[12] = '"}],';
        
        string memory attrStr = string(abi.encodePacked(attr[0], attr[1], attr[2], attr[3], attr[4], attr[5]));
        attrStr = string(abi.encodePacked(attrStr, attr[6], attr[7], attr[8], attr[9], attr[10], attr[11], attr[12]));
        
        string memory out = Base64.encode(bytes(output));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', mainString, '", "description": "', discriptionStr, '", ', attrStr, ' "image": "data:image/svg+xml;base64,', out, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    constructor() ERC721("ChainArtefactBoots", "CABoots") Ownable() {}
}