/**
 *Submitted for verification at polygonscan.com on 2021-09-11
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

contract ChainArtefact_Helmet is ERC721Enumerable, ReentrancyGuard, Ownable {

    string private constant discription = 'Full-On-Chain Artefact Series. Helmet Version. Engraved on the chain.';
    string private constant namePrefix = 'ChainArtefact Helmet #';
    string private constant svgHeader = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="1000px" height="1000px" viewBox="0 0 100 100"><g class="cls-1">';
    
    string private constant effect = '<path id="effect" class="cls-2" d="M73.33,30V26.67H71.67v1.66H70v3.34H68.33v-5H66.67V23.33h1.66V20H66.67v1.67H65v5H63.33V20H61.67v3.33H60V16.67H58.33v5H55V18.33H53.33V16.67H51.67V13.33h1.66V10H51.67v1.67H50v5H48.33v1.66H45V16.67h1.67V13.33H45V15H43.33v3.33H41.67v5H40v-5H38.33v5H36.67v3.34H35V30H33.33V26.67H31.67V30H30v5H28.33V31.67H26.67v35h1.66V70H30v3.33h1.67v3.34h1.66v1.66h3.34v3.34h1.66v1.66H40V85h3.33V81.67H41.67V78.33H58.33v3.34H56.67V85H60V83.33h1.67V81.67h1.66V78.33h3.34V76.67h1.66V73.33H70V70h1.67V66.67h1.66v-30H71.67V30ZM65,28.33h1.67V30H65ZM46.67,25V23.33h1.66V21.67h3.34v1.66h1.66V25H55v5H53.33v1.67H51.67v1.66H48.33V31.67H46.67V30H45V25Zm-3.34-5H45v1.67H43.33ZM31.67,38.33h1.66V35H35V33.33h1.67V31.67h1.66V30H40V28.33h3.33v3.34H45v1.66h1.67V35h6.66V33.33H55V31.67h1.67V28.33H60V30h1.67v1.67h1.66v1.66H65V35h1.67v3.33h1.66v3.34H66.67v5H65v1.66H61.67V50H38.33V48.33H35V46.67H33.33v-5H31.67ZM70,65H68.33v3.33H66.67V70H65v1.67H63.33v1.66H60V75H56.67v1.67h-5V75H48.33v1.67h-5V75H40V73.33H36.67V71.67H35V70H33.33V68.33H31.67V65H30V50h3.33v1.67H35V50h1.67v1.67H63.33V50H65v1.67h1.67V50H70Z" transform="translate(-6.67 -10)"/>';
    string private constant base = '<path id="base" class="cls-3" d="M70,41.67v-5H68.33V33.33H66.67V31.67H65V30H63.33V28.33H61.67V26.67H58.33V25H55V21.67H53.33V20H46.67v1.67H45V25H41.67v1.67H38.33v1.66H36.67V30H35v1.67H33.33v1.66H31.67v3.34H30v5H28.33v25H30V70h1.67v1.67h1.66v1.66H35v-15h1.67V56.67h1.66V73.33H35V75h3.33v1.67h3.34v-20h1.66V55H45V76.67H41.67v1.66H58.33V76.67H55V55h1.67v1.67h1.66v20h3.34V75H65V73.33H61.67V56.67h1.66v1.66H65v15h1.67V71.67h1.66V70H70V66.67h1.67v-25Zm-40,20V53.33h1.67v10H30Zm20,15H48.33V53.33h3.34V76.67ZM70,55v8.33H68.33v-10H70Z" transform="translate(-6.67 -10)"/>';
    string private constant element = '<polygon id="element" class="cls-4" points="46.67 15 46.67 13.33 45 13.33 45 11.67 43.33 11.67 41.67 11.67 41.67 13.33 40 13.33 40 15 38.33 15 38.33 16.67 38.33 18.33 38.33 20 40 20 40 21.67 41.67 21.67 41.67 23.33 43.33 23.33 45 23.33 45 21.67 46.67 21.67 46.67 20 48.33 20 48.33 18.33 48.33 16.67 48.33 15 46.67 15"/>';
    string private constant lineDemon = '<path id="line-demon" class="cls-5" d="M85,35V31.67H83.33V30H81.67V25H80v8.33h1.67v5H80V40H78.33v1.67H76.67v1.66H75V45H71.67V38.33h1.66V35H75V31.67h1.67v-10H75V18.33H73.33V16.67H71.67v6.66h1.66v3.34H71.67v1.66H70v3.34H68.33v1.66H66.67V31.67H65V28.33h1.67V25h1.66V18.33H66.67V15H65V13.33H63.33v3.34H65V20h1.67v3.33H65V25H63.33v1.67h-5V25H56.67V23.33H55V21.67H53.33V20H46.67v1.67H45v1.66H43.33V25H41.67v1.67h-5V25H35V23.33H33.33V20H35V16.67h1.67V13.33H35V15H33.33v3.33H31.67V25h1.66v3.33H35v3.34H33.33v1.66H31.67V31.67H30V28.33H28.33V26.67H26.67V23.33h1.66V16.67H26.67v1.66H25v3.34H23.33v10H25V35h1.67v3.33h1.66V45H25V43.33H23.33V41.67H21.67V40H20V38.33H18.33v-5H20V25H18.33v5H16.67v1.67H15V35H13.33v6.67H15V45h1.67v3.33h1.66v3.34H20v1.66h1.67V55H20v1.67h5v1.66H16.67V60h1.66v1.67H20V65H18.33v1.67H16.67v1.66H15v5h1.67V75h1.66v1.67H20v1.66h1.67V80h1.66v1.67h3.34v1.66h5V85h5V83.33H33.33V81.67H31.67V80h-5V78.33H25V76.67H23.33V75H21.67V70h1.66V68.33H25V66.67h1.67v1.66H30V70h1.67v3.33h1.66v3.34h3.34v1.66h1.66v3.34H40v1.66h3.33V85H56.67V83.33H60V81.67h1.67V78.33h1.66V76.67h3.34V73.33h1.66V70H70V68.33h3.33V66.67H75v1.66h1.67V70h1.66v5H76.67v1.67H75v1.66H73.33V80h-5v1.67H66.67v1.66H63.33V85h5V83.33h5V81.67h3.34V80h1.66V78.33H80V76.67h1.67V75h1.66V73.33H85v-5H83.33V66.67H81.67V65H80V61.67h1.67V60h1.66V58.33H75V56.67h5V55H78.33V53.33H80V51.67h1.67V48.33h1.66V45H85V41.67h1.67V35ZM25,61.67H23.33V60H25ZM45,28.33V25h1.67V23.33h1.66V21.67h3.34v1.66h1.66V25H55v5H53.33v1.67H51.67v1.66H48.33V31.67H46.67V30H45ZM31.67,40V38.33h1.66V35H35V33.33h1.67V31.67h1.66V30H40V28.33h3.33v3.34H45v1.66h1.67V35h6.66V33.33H55V31.67h1.67V28.33H60V30h1.67v1.67h1.66v1.66H65V35h1.67v3.33h1.66v3.34H66.67v5H65v1.66H61.67V50H38.33V48.33H35V46.67H33.33v-5H31.67ZM70,51.67V65H68.33v3.33H66.67V70H65v1.67H63.33v1.66H60V75H56.67v1.67h-5V75H48.33v1.67h-5V75H40V73.33H36.67V71.67H35V70H33.33V68.33H31.67V65H30V50h3.33v1.67H35V50h1.67v1.67H63.33V50H65v1.67h1.67V50H70ZM76.67,60v1.67H75V60Z" transform="translate(-6.67 -10)"/>';
    string private constant lineAngel = '<path id="line-angel" class="cls-5" d="M71.67,23.33V25H70v1.67H68.33V30H70v1.67h1.67v1.66h1.66V35H75v5H73.33v6.67H71.67v-5H70v-5H68.33V33.33H66.67V31.67H65V30H63.33V28.33H61.67V26.67H58.33V25H56.67V23.33H55V21.67H53.33V20H46.67v1.67H45v1.66H43.33V25H41.67v1.67H38.33v1.66H36.67V30H35v1.67H33.33v1.66H31.67v3.34H30v5H28.33v5H26.67V40H25V35h1.67V33.33h1.66V31.67H30V30h1.67V26.67H30V25H28.33V23.33H6.67V25h5v1.67h1.66v1.66h5V30H11.67v1.67H15v1.66h5V35H15v1.67h5v1.66H18.33V40h3.34v1.67H20v1.66h3.33v5H21.67v10h1.66V70H21.67V80H20v3.33H18.33V90H16.67v1.67h10V90H25V86.67H23.33V83.33H25V65h1.67V60h1.66v6.67H30V70h1.67v3.33h1.66v3.34h3.34v1.66h1.66v3.34H40v1.66h3.33V81.67H41.67V78.33H58.33v3.34H56.67v1.66H60V81.67h1.67V78.33h1.66V76.67h3.34V73.33h1.66V70H70V66.67h1.67V60h1.66v5H75V83.33h1.67v3.34H75V90H73.33v1.67h10V90H81.67V83.33H80V80H78.33V70H76.67V58.33h1.66v-10H76.67v-5H80V41.67H78.33V40h3.34V38.33H80V36.67h5V35H80V33.33h5V31.67h3.33V30H81.67V28.33h5V26.67h1.66V25h5V23.33ZM45,25h1.67V23.33h1.66V21.67h3.34v1.66h1.66V25H55v5H53.33v1.67H51.67v1.66H48.33V31.67H46.67V30H45ZM31.67,38.33h1.66V35H35V33.33h1.67V31.67h1.66V30H40V28.33h3.33v3.34H45v1.66h1.67V35h6.66V33.33H55V31.67h1.67V28.33H60V30h1.67v1.67h1.66v1.66H65V35h1.67v3.33h1.66v3.34H66.67v5H65v1.66H61.67V50H38.33V48.33H35V46.67H33.33v-5H31.67ZM70,65H68.33v3.33H66.67V70H65v1.67H63.33v1.66H60V75H56.67v1.67h-5V75H48.33v1.67h-5V75H40V73.33H36.67V71.67H35V70H33.33V68.33H31.67V65H30V50h3.33v1.67H35V50h1.67v1.67H63.33V50H65v1.67h1.67V50H70Z" transform="translate(-6.67 -10)"/>';
    string private constant lineHorn = '<path id="line-horn" class="cls-5" d="M83.33,40V33.33H81.67V31.67H80V23.33h1.67V21.67h1.66V20h-5v1.67H76.67v1.66H75v5H73.33V40H75v3.33h1.67v3.34H73.33V45H71.67V41.67H70v-5H68.33V33.33H66.67V31.67H65V30H63.33V28.33H61.67V26.67H58.33V25H56.67V23.33H55V21.67H53.33V20H46.67v1.67H45v1.66H43.33V25H41.67v1.67H38.33v1.66H36.67V30H35v1.67H33.33v1.66H31.67v3.34H30v5H28.33V45H26.67v1.67H23.33V43.33H25V40h1.67V28.33H25v-5H23.33V21.67H21.67V20h-5v1.67h1.66v1.66H20v8.34H18.33v1.66H16.67V40H15V53.33h1.67V55h1.66v1.67H20v1.66h3.33V60h3.34v1.67h1.66v5H30V70h1.67v3.33h1.66v3.34h3.34v1.66h1.66v3.34H40v1.66h3.33V81.67H41.67V78.33H58.33v3.34H56.67v1.66H60V81.67h1.67V78.33h1.66V76.67h3.34V73.33h1.66V70H70V66.67h1.67v-5h1.66V60h3.34V58.33H80V56.67h1.67V55h1.66V53.33H85V40ZM45,25h1.67V23.33h1.66V21.67h3.34v1.66h1.66V25H55v5H53.33v1.67H51.67v1.66H48.33V31.67H46.67V30H45ZM31.67,38.33h1.66V35H35V33.33h1.67V31.67h1.66V30H40V28.33h3.33v3.34H45v1.66h1.67V35h6.66V33.33H55V31.67h1.67V28.33H60V30h1.67v1.67h1.66v1.66H65V35h1.67v3.33h1.66v3.34H66.67v5H65v1.66H61.67V50H38.33V48.33H35V46.67H33.33v-5H31.67ZM70,65H68.33v3.33H66.67V70H65v1.67H63.33v1.66H60V75H56.67v1.67h-5V75H48.33v1.67h-5V75H40V73.33H36.67V71.67H35V70H33.33V68.33H31.67V65H30V50h3.33v1.67H35V50h1.67v1.67H63.33V50H65v1.67h1.67V50H70Z" transform="translate(-6.67 -10)"/>';
    string private constant line = '<path id="line-normal" class="cls-5" d="M75.06,53.27V49.94H73.4V48.27H71.73V41.6H70.06v-5H68.4V33.27H66.73V31.6H65.06V29.94H63.4V28.27H61.73V26.6H58.4V24.94H56.73V23.27H55.06V21.6H53.4V19.94H46.6V21.6H44.94v1.67H43.27v1.67H41.6V26.6H38.27v1.67H36.6v1.67H34.94V31.6H33.27v1.67H31.6V36.6H29.94v5H28.27v6.67H26.6v1.67H24.94v3.33H23.27v3.46h1.67v3.33H26.6v1.67h1.67v5h1.67v3.33H31.6V73.4h1.67v3.33H36.6V78.4h1.67v3.33h1.67V83.4H43.4V81.6H41.73V78.4H58.27v3.2H56.6v1.8h3.46V81.73h1.67V78.4H63.4V76.73h3.33V73.4H68.4V70.06h1.66V66.73h1.67v-5H73.4V60.06h1.66V56.73h1.67V53.27Zm-30-28.21h1.67V23.4H48.4V21.73h3.2V23.4h1.67v1.66h1.67v4.88H53.27V31.6H51.6v1.67H48.4V31.6H46.73V29.94H45.06ZM31.73,38.4H33.4V35.06h1.66V33.4h1.67V31.73H38.4V30.06h1.66V28.4h3.21v3.33h1.67V33.4H46.6v1.66h6.8V33.4h1.66V31.73h1.67V28.4h3.21v1.66H61.6v1.67h1.67V33.4h1.67v1.66H66.6V38.4h1.67v3.2H66.6v5H64.94v1.67H61.6v1.67H38.4V48.27H35.06V46.6H33.4v-5H31.73ZM69.94,64.94H68.27v3.33H66.6v1.67H64.94V71.6H63.27v1.67H59.94v1.67H56.6V76.6H51.73V74.94H48.27V76.6H43.4V74.94H40.06V73.27H36.73V71.6H35.06V69.94H33.4V68.27H31.73V64.94H30.06V50.06h3.21v1.67h1.79V50.06H36.6v1.67H63.4V50.06h1.54v1.67h1.79V50.06h3.21Z" transform="translate(-6.67 -10)"/>';
    string private constant orb = '<rect id="orb" class="cls-6" x="41.67" y="26.67" width="3.33" height="5"/>';
    string private constant decoration = '<path id="kazari" class="cls-7" d="M63.33,36.67V35H61.67V33.33H60v3.34h1.67v1.66h1.66v5H61.67V45H60v1.67H51.67V43.33h1.66V36.67H55V35h1.67V33.33h1.66V30H60V28.33H56.67v3.34H55v1.66H53.33V35H46.67V33.33H45V31.67H43.33V28.33H40V30h1.67v3.33h1.66V35H45v1.67h1.67v6.66h1.66v3.34H40V45H38.33V43.33H36.67v-5h1.66V36.67H40V33.33H38.33V35H36.67v1.67H35V45h1.67v1.67h1.66v1.66h5V50H56.67V48.33h5V46.67h1.66V45H65V36.67ZM48.33,40V36.67h3.34v5H48.33Z" transform="translate(-6.67 -10)"/>';

    string private constant svhfooter = '</g></svg>';

    uint256 private constant limitNumber = 3000;
    uint256 private constant mintedNumber = 2000;
    
    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        require(tokenId > 0 && tokenId < limitNumber + 1, "Token ID invalid");
        
        string[4] memory colors;
        colors[0] = Builder.getColor(tokenId * 7, 1); 
        colors[1] = Builder.getColor(tokenId * 5, 2); 
        colors[2] = Builder.getColor(tokenId * 3, 3); 
        colors[3] = Builder.getColor(tokenId * 9, 4); 
        
        string[12] memory styles;
        styles[1] = '<style type="text/css">.cls-1{isolation: isolate;}.cls-4 {fill: #000;mix-blend-mode: overlay;}.cls-5 {fill: #4a4848;}.cls-2{fill:';
        styles[2] = colors[0];
        styles[3] = ';}.cls-3{fill:';
        styles[6] = colors[1];
        styles[7] = ';}.cls-6{fill:';
        styles[8] = colors[2];
        styles[9] = ';}.cls-7{fill:';
        styles[10] = colors[3];
        styles[11] = ';}.title { fill: #fefefe; font-family: serif; font-size: 5px; }</style><rect width="100%" height="100%" fill="#101010" /><g transform="scale(1.1 1.1) translate(1,0)">';
        
        string memory buildSet = string(abi.encodePacked(svgHeader, styles[0], styles[1], styles[2], styles[3], styles[4], styles[5]));
        buildSet = string(abi.encodePacked(buildSet, styles[6], styles[7], styles[8], styles[9], styles[10], styles[11]));
        
        uint256 effectRnd = Builder.randomValue(tokenId * 20, 8, 100);
        uint8 effectint = 0;
        if( effectRnd < 10 ){
            buildSet = string(abi.encodePacked(buildSet, effect));
            effectint = 1;
        }
        
        buildSet = string(abi.encodePacked(buildSet, base, element));

        uint256 lineRnd = Builder.randomValue(tokenId * 11, 6, 100);
        string memory style;
        if( lineRnd >= 90 ){
            buildSet = string(abi.encodePacked(buildSet, lineHorn));
            style = "Horn";
        }
        if( lineRnd >= 85 && lineRnd < 90 ){
            buildSet = string(abi.encodePacked(buildSet, lineAngel));
            style = "Angel";
        }
        if( lineRnd >= 80 && lineRnd < 85 ){
            buildSet = string(abi.encodePacked(buildSet, lineDemon));
            style = "Demon";
        }
        if( lineRnd < 80 ){
            buildSet = string(abi.encodePacked(buildSet, line));
            style = "Normal";
        }

        string memory text = string(abi.encodePacked('</g><text x="4" y="99" class="title">', namePrefix, Strings.toString(tokenId), '</text>'));
        
        return createJSON(string(abi.encodePacked(buildSet, orb, decoration, text, svhfooter)), string(abi.encodePacked(namePrefix, Strings.toString(tokenId))), discription, effectint, colors, style);
    }
    
    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < mintedNumber + 1, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > mintedNumber && tokenId < limitNumber + 1, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    
    function createJSON(string memory output, string memory mainString, string memory discriptionStr, uint8 effectint, string[4] memory colors, string memory style) internal pure returns (string memory) {
        string[13] memory attr;
        attr[0] = '"attributes":[{"trait_type":"Effect","value":"';
        attr[1] = Strings.toString(effectint);
        attr[0] = '"attributes":[{"trait_type":"Style","value":"';
        attr[1] = style;
        attr[2] = '"},{"trait_type":"EffectColor","value":"';
        attr[3] = colors[0];
        attr[4] = '"},{"trait_type":"BaseColor","value":"';
        attr[5] = colors[1];
        attr[6] = '"},{"trait_type":"OrbColor","value":"';
        attr[7] = colors[2];
        attr[8] = '"},{"trait_type":"DecorationColor","value":"';
        attr[9] = colors[3];
        attr[12] = '"}],';
        
        string memory attrStr = string(abi.encodePacked(attr[0], attr[1], attr[2], attr[3], attr[4], attr[5]));
        attrStr = string(abi.encodePacked(attrStr, attr[6], attr[7], attr[8], attr[9], attr[10], attr[11], attr[12]));
        
        string memory out = Base64.encode(bytes(output));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', mainString, '", "description": "', discriptionStr, '", ', attrStr, ' "image": "data:image/svg+xml;base64,', out, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    constructor() ERC721("ChainArtefactHelmet", "CAHelmet") Ownable() {}
}