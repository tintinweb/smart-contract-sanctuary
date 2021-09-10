/**
 *Submitted for verification at polygonscan.com on 2021-09-10
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

contract ChainArtefact_Armer is ERC721Enumerable, ReentrancyGuard, Ownable {

    string private constant discription = 'Full-On-Chain Artefact Series. Armer Version. Engraved on the chain.';
    string private constant namePrefix = 'ChainArtefact Armer #';
    string private constant svgHeader = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="1000px" height="1000px" viewBox="0 0 100 100"><g class="cls-1">';
    
    string private constant cls_2 = '<path class="cls-2" d="M83.33,35V30H81.66V25H80V23.33H78.33v-10H80V10H78.33v1.66H76.66v1.67H75v3.33H73.33V13.33H71.66V11.66H70v-5h1.66V3.33H70V5H68.33V6.66H65V5H60V1.66H58.33V3.33H56.66v10H55v3.33H53.33v1.67H51.66V16.66H50v1.67H48.33v3.33H46.66V20H40v1.66H38.33V18.33H40V15H38.33v1.66H36.66v1.67H35V16.66H33.33V15H35V11.66h1.66V10H33.33v3.33H30V5H25V3.33h3.33V1.66H30V0H26.66V1.66H23.33V3.33H21.66V6.66H20V8.33H18.33V10H16.66v1.66H15v1.67H13.33V15H11.66V13.33H10V20H8.33v3.33H6.66v-5H5v5H3.33v5H1.66v5H3.33V35H1.66v3.33H0v5H1.66V45H3.33v1.66H5v1.67H6.66V46.66H8.33V50h3.33v1.66h1.67V48.33H15v-5h1.66V41.66h1.67v1.67H20v3.33h1.66v1.67h1.67v3.33H21.66v1.67H20V50H18.33v5H16.66v3.33H15V55h1.66V51.66H15v1.67H13.33V60H11.66v3.33H10V65H8.33V63.33H6.66V70H5v3.33H6.66V75H8.33v1.66H10v1.67h1.66V80H15V78.33h1.66V76.66h1.67V73.33H20V71.66h1.66V70h1.67v3.33H25V80h1.66v3.33h1.67V85H30v1.66h1.66v1.67H35V90h3.33v1.66h10V90h3.33V88.33H55V86.66h1.66V85h1.67V83.33H60V80h1.66V76.66h1.67v-5h3.33v1.67h1.67v3.33H70v1.67h1.66V80H75V78.33h1.66V76.66h1.67V75H80V66.66H78.33V65H76.66V63.33H75V61.66H73.33V60H71.66V55H70V53.33h1.66V50H70v1.66H68.33V55H66.66V53.33H65V51.66H63.33V48.33h5V46.66H66.66V43.33h1.67v3.33H70V43.33h3.33V45H75v3.33h1.66V46.66H80v1.67H76.66V50h5V46.66h1.67V45H85V35ZM41.66,23.33h5V25H40V23.33ZM13.33,46.66H11.66v1.67H10V45h3.33ZM28.33,75H26.66V73.33h1.67Zm0-5H26.66v1.66H25V65h1.66v1.66H30V70Zm33.33,0v5H60V73.33H58.33V70H56.66V66.66H60V65h1.66v3.33h1.67V70Z"/>';
    string private constant cls_3 = '<polygon class="cls-3" points="81.67 35 81.67 30 80 30 80 25 78.33 25 78.33 23.33 76.67 23.33 76.67 20 75 20 75 18.33 73.33 18.33 73.33 16.67 71.67 16.67 71.67 13.33 70 13.33 70 11.67 68.33 11.67 68.33 10 66.67 10 66.67 8.33 65 8.33 65 6.67 60 6.67 60 8.33 58.33 8.33 58.33 13.33 56.67 13.33 56.67 16.67 55 16.67 55 18.33 53.33 18.33 53.33 20 51.67 20 51.67 21.67 50 21.67 50 23.33 46.67 23.33 46.67 21.67 40 21.67 40 23.33 36.67 23.33 36.67 21.67 35 21.67 35 20 33.33 20 33.33 18.33 31.67 18.33 31.67 16.67 30 16.67 30 13.33 28.33 13.33 28.33 8.33 26.67 8.33 26.67 6.67 21.67 6.67 21.67 8.33 20 8.33 20 10 18.33 10 18.33 11.67 16.67 11.67 16.67 13.33 15 13.33 15 16.67 13.33 16.67 13.33 18.33 11.67 18.33 11.67 20 10 20 10 23.33 8.33 23.33 8.33 25 6.67 25 6.67 30 5 30 5 35 3.33 35 3.33 45 5 45 5 46.67 6.67 46.67 6.67 45 10 45 10 43.33 13.33 43.33 13.33 41.67 16.67 41.67 16.67 40 20 40 20 43.33 21.67 43.33 21.67 46.67 23.33 46.67 23.33 48.33 25 48.33 25 51.67 23.33 51.67 23.33 53.33 21.67 53.33 21.67 55 20 55 20 56.67 18.33 56.67 18.33 58.33 16.67 58.33 16.67 60 15 60 15 61.67 13.33 61.67 13.33 63.33 11.67 63.33 11.67 65 10 65 10 66.67 8.33 66.67 8.33 75 10 75 10 76.67 11.67 76.67 11.67 78.33 15 78.33 15 76.67 16.67 76.67 16.67 73.33 18.33 73.33 18.33 71.67 20 71.67 20 70 21.67 70 21.67 68.33 23.33 68.33 23.33 65 25 65 25 63.33 26.67 63.33 26.67 65 30 65 30 66.67 31.67 66.67 31.67 70 30 70 30 85 31.67 85 31.67 86.67 35 86.67 35 88.33 38.33 88.33 38.33 90 48.33 90 48.33 88.33 51.67 88.33 51.67 86.67 55 86.67 55 85 56.67 85 56.67 70 55 70 55 66.67 56.67 66.67 56.67 65 60 65 60 63.33 61.67 63.33 61.67 65 63.33 65 63.33 68.33 65 68.33 65 70 66.67 70 66.67 71.67 68.33 71.67 68.33 73.33 70 73.33 70 76.67 71.67 76.67 71.67 78.33 75 78.33 75 76.67 76.67 76.67 76.67 75 78.33 75 78.33 66.67 76.67 66.67 76.67 65 75 65 75 63.33 73.33 63.33 73.33 61.67 71.67 61.67 71.67 60 70 60 70 58.33 68.33 58.33 68.33 56.67 66.67 56.67 66.67 55 65 55 65 53.33 63.33 53.33 63.33 51.67 61.67 51.67 61.67 48.33 63.33 48.33 63.33 46.67 65 46.67 65 43.33 66.67 43.33 66.67 40 70 40 70 41.67 73.33 41.67 73.33 43.33 76.67 43.33 76.67 45 80 45 80 46.67 81.67 46.67 81.67 45 83.33 45 83.33 35 81.67 35"/>';
    string private constant cls_4 = '<path class="cls-4" d="M48.33,48.33H46.66V46.66H45V45H41.66v1.66H40v1.67H38.33v5H36.66v3.33h1.67v1.67H40V60h1.66v1.66H45V60h1.66V58.33h1.67V56.66H50V53.33H48.33ZM80,36.66v-5H78.33v-5H76.66V25H75V21.66H73.33V20H71.66V18.33H70V15H68.33V13.33H66.66V11.66H65V10H63.33V8.33H61.66V10H60v5H58.33v5H56.66V18.33H55V20H53.33v1.66H51.66v1.67H50V25H46.66V23.33H40V25H36.66V23.33H35V21.66H33.33V20H31.66V18.33H30V20H28.33V15H26.66V10H25V8.33H23.33V10H21.66v1.66H20v1.67H18.33V15H16.66v3.33H15V20H13.33v1.66H11.66V25H10v1.66H8.33v5H6.66v5H5v5H6.66v1.67H8.33V41.66h3.33V40H15V36.66H11.66V35H10V33.33h1.66V35h5v3.33H20V36.66h1.66v6.67h1.67V45H25v1.66h3.33V50H26.66v3.33H25V55H21.66v1.66H20v1.67H18.33V60H16.66v1.66H15v1.67H13.33V65H11.66v1.66H10V75h1.66v1.66h1.67V75H15V73.33h1.66V70h1.67V68.33H20V66.66h1.66V63.33h1.67V61.66h5v1.67H30V65h6.66v1.66H33.33v5H31.66V83.33h1.67V85H35v1.66h3.33v1.67h3.33V86.66H45v1.67h3.33V86.66h3.33V85h1.67V83.33H55V71.66H53.33v-5H50V65h6.66V63.33h1.67V61.66h5v1.67H65v3.33h1.66v1.67h1.67V70H70v1.66h1.66V75h1.67v1.66H75V75h1.66V66.66H75V65H73.33V63.33H71.66V61.66H70V60H68.33V58.33H66.66V56.66H65V55H61.66V53.33H60v-5H58.33V46.66h3.33V45h1.67V41.66H65v-5h1.66v1.67H70V35h5V33.33h1.66V35H75v1.66H71.66V40H75v1.66h3.33v1.67H80V41.66h1.66v-5Zm-46.67-10H35v1.67h3.33V30H40V28.33h1.66V30H45V28.33h1.66V30h1.67V28.33h3.33V26.66h1.67v1.67H51.66V30H48.33v1.66H46.66v1.67H40V31.66H38.33V30H35V28.33H33.33ZM51.66,75v1.66H48.33v1.67H45V80H41.66V78.33H38.33V76.66H35V75h3.33v1.66h10V75Zm-3.33-8.34v1.67H46.66V66.66H40v1.67H38.33V66.66H40V65h6.66v1.66Zm8.33-18.33H55V50H50v3.33h1.66v3.33H50v1.67H48.33V60H46.66v1.66H45v1.67H41.66V61.66H40V60H38.33V58.33H36.66V56.66H35V53.33h1.66V50h-5V48.33H30V46.66h1.66v1.67h6.67V46.66H40V43.33h1.66V41.66H45v1.67h1.66v3.33h1.67v1.67H55V46.66h1.66Z"/>';
    string private constant cls_5 = '<path class="cls-5" d="M78.33,36.66v-5H76.66v-5H75V25H73.33V21.66H71.66V20H70V16.66H68.33V15H66.66V13.33H65V11.66H63.33V10H61.66v5H60v8.33h1.66v-5h1.67V25h3.33v1.66h1.67v1.67H65V26.66H60V25H58.33v1.66H55V25h3.33V21.66H56.66V20H55v1.66H53.33v1.67H51.66V25H50v1.66H46.66V25H40v1.66H36.66V25H35V23.33H33.33V21.66H31.66V20H30v1.66H28.33V25h3.33v1.66H28.33V25H26.66v1.66h-5v1.67H18.33V26.66H20V25h3.33V18.33H25v5h1.66V15H25V10H23.33v1.66H21.66v1.67H20V15H18.33v1.66H16.66V20H15v1.66H13.33V25H11.66v1.66H10v5H8.33v5H6.66v5H8.33V40h3.33V38.33H15V36.66H11.66V35H10V33.33h1.66V35h5v1.66H20V35h3.33v8.33H25V45h1.66v1.66h1.67v6.67H26.66V55H25v1.66H21.66v1.67H20V60H18.33v1.66H16.66v1.67H15V65H13.33v1.66H11.66V75h1.67V73.33H15V70h1.66V68.33h1.67V66.66H20V63.33h1.66V61.66h1.67V60h3.33V58.33h1.67v3.33H30v1.67h5V65h1.66v3.33H35v3.33H33.33V83.33H35V85h3.33v1.66h3.33V83.33H45v3.33h3.33V85h3.33V83.33h1.67V71.66H51.66V68.33H50V65h1.66V63.33h5V61.66h1.67V58.33H60V60h3.33v1.66H65v1.67h1.66v3.33h1.67v1.67H70V70h1.66v3.33h1.67V75H75V66.66H73.33V65H71.66V63.33H70V61.66H68.33V60H66.66V58.33H65V56.66H61.66V55H60V53.33H58.33V46.66H60V45h1.66V43.33h1.67V35h3.33v1.66H70V35h5V33.33h1.66V35H75v1.66H71.66v1.67H75V40h3.33v1.66H80v-5Zm-45-10H35v1.67h3.33V30H40V28.33h1.66V30H45V28.33h1.66V30h1.67V28.33h3.33V26.66h1.67v1.67H51.66V30H48.33v1.66H46.66v1.67H40V31.66H38.33V30H35V28.33H33.33Zm0,31.67V60H31.66V56.66h1.67ZM51.66,75v1.66H48.33v1.67H45V80H41.66V78.33H38.33V76.66H35V75h3.33v1.66h10V75Zm-3.33-8.34v1.67H46.66V66.66H40v1.67H38.33V66.66H40V65h6.66v1.66ZM55,58.33V60H53.33V56.66H55Zm1.66-10H55V50H50v3.33h1.66v3.33H50v1.67H48.33V60H46.66v1.66H45v1.67H41.66V61.66H40V60H38.33V58.33H36.66V56.66H35V53.33h1.66V50h-5V48.33H30V46.66h1.66v1.67h6.67V46.66H40V43.33h1.66V41.66H45v1.67h1.66v3.33h1.67v1.67H55V46.66h1.66ZM45,53.33V51.66H43.33V50H45V48.33H41.66V50H40v3.33H38.33v3.33H40v1.67h1.66V60H45V58.33h1.66V56.66h1.67V53.33Z"/>';
    string private constant cls_6 = '<path class="cls-6" d="M78.33,36.66v-5H76.66v-5H75V25H73.33V21.66H71.66V20H70V16.66H68.33V15H66.66V13.33H65V11.66H63.33V15H65v1.66h1.66v1.67h1.67v3.33H70v1.67h1.66v3.33h1.67v1.67H75v3.33H73.33v1.67h-5V31.66H60V28.33H58.33V30H56.66v3.33H55V31.66H53.33V35H51.66v1.66H55V35h1.66v1.66h1.67v1.67H60v3.33H58.33v1.67H56.66V45h-5V43.33H50V41.66H45v1.67h3.33V45H50v1.66h6.66V50H55v1.66h1.66v1.67H55V55H53.33v5H50V58.33H48.33V60H46.66v1.66H45v1.67H41.66V61.66H40V60H38.33V58.33H36.66V60H33.33V55H31.66V53.33H30V51.66h1.66V50H30V46.66h6.66V45h1.67V43.33h3.33V41.66h-5v1.67H35V45H30V43.33H28.33V41.66H26.66V38.33h1.67V36.66H30V35h1.66v1.66H35V35H33.33V31.66H31.66v1.67H30V30H28.33V28.33H26.66v3.33H18.33v1.67h-5V31.66H11.66V28.33h1.67V26.66H15V23.33h1.66V21.66h1.67V18.33H20V16.66h1.66V15h1.67V11.66H21.66v1.67H20V15H18.33v1.66H16.66V20H15v1.66H13.33V25H11.66v1.66H10v5H8.33v5H6.66V40H8.33V38.33H10v-5h1.66V35H20V33.33h8.33V35H26.66v1.66H23.33v5H25v1.67h1.66v3.33h1.67v6.67H26.66V55H25v1.66H21.66v1.67H20V60H18.33v1.66H16.66v1.67H15V65H13.33v1.66h3.33V65h1.67V63.33H20V61.66h1.66V60h1.67V58.33h3.33V56.66h1.67V55H30v1.66h1.66v5h1.67v1.67h3.33V70h1.67v1.66H40v5h1.66V70H45v6.66h1.66v-5h1.67V70H50V63.33h3.33V61.66H55v-5h1.66V55h1.67v1.66H60v1.67h3.33V60H65v1.66h1.66v1.67h1.67V65H70v1.66h3.33V65H71.66V63.33H70V61.66H68.33V60H66.66V58.33H65V56.66H61.66V55H60V53.33H58.33V46.66H60V43.33h1.66V41.66h1.67v-5H60V35H58.33V33.33h8.33V35H75V33.33h1.66v5h1.67V40H80V36.66Zm-30,31.67H45V66.66H41.66v1.67H38.33V66.66H40V65h6.66v1.66h1.67Z"/>';
    string private constant cls_7 = '<polygon class="cls-7" points="46.67 53.33 45 53.33 45 51.67 45 50 46.67 50 46.67 48.33 45 48.33 45 46.67 43.33 46.67 41.67 46.67 41.67 48.33 40 48.33 40 50 40 51.67 40 53.33 38.33 53.33 38.33 55 38.33 56.67 40 56.67 40 58.33 41.67 58.33 41.67 60 43.33 60 45 60 45 58.33 46.67 58.33 46.67 56.67 48.33 56.67 48.33 55 48.33 53.33 46.67 53.33"/><polygon class="cls-8" points="41.72 56.62 41.72 54.95 40.05 54.95 40.05 53.28 38.28 53.28 38.28 54.95 38.28 55.05 38.28 56.72 39.95 56.72 39.95 58.38 41.62 58.38 41.62 60.05 43.38 60.05 43.38 58.38 43.38 58.28 43.38 56.62 41.72 56.62"/>';

    string private constant svhfooter = '</g></svg>';
    
    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        require(tokenId > 0 && tokenId < 10001, "Token ID invalid");
        
        string[4] memory colors;
        colors[0] = Builder.getColor(tokenId * 5, 1); 
        colors[1] = Builder.getColor(tokenId * 7, 2); 
        colors[2] = Builder.getColor(tokenId * 9, 3); 
        colors[3] = Builder.getColor(tokenId * 3, 4); 
        
        string[12] memory styles;
        styles[1] = '<style type="text/css">.cls-1{isolation: isolate;}.cls-5 {fill: #fff;}.cls-8 {fill: #000;}.cls-5,.cls-8 {mix-blend-mode: overlay;}.cls-2{fill:';
        styles[2] = colors[0];
        styles[3] = ';}.cls-3{fill:#3d3a39;}.cls-4{fill:';
        styles[6] = colors[1];
        styles[7] = ';}.cls-6{fill:';
        styles[8] = colors[2];
        styles[9] = ';}.cls-7{fill:';
        styles[10] = colors[3];
        styles[11] = ';}.title { fill: #fefefe; font-family: serif; font-size: 5px; }</style><rect width="100%" height="100%" fill="#101010" /><g style="transform:translateX(8px);">';
        
        uint256 rnd = Builder.randomValue(tokenId * 20, 8, 100);
        
        string memory buildSet = string(abi.encodePacked(svgHeader, styles[0], styles[1], styles[2], styles[3], styles[4], styles[5]));
        buildSet = string(abi.encodePacked(buildSet, styles[6], styles[7], styles[8], styles[9], styles[10], styles[11]));
        
        uint8 effectint = 0;
        if( rnd < 10 ){
            buildSet = string(abi.encodePacked(buildSet, cls_2));
            effectint = 1;
        }
        
        string memory text = string(abi.encodePacked('</g><text x="4" y="99" class="title">', namePrefix, Strings.toString(tokenId), '</text>'));
        
        return createJSON(string(abi.encodePacked(buildSet, cls_3, cls_4, cls_5, cls_6, cls_7, text, svhfooter)), string(abi.encodePacked(namePrefix, Strings.toString(tokenId))), discription, effectint, colors);
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
        attr[6] = '"},{"trait_type":"LineColor","value":"';
        attr[7] = colors[2];
        attr[8] = '"},{"trait_type":"OrbColor","value":"';
        attr[9] = colors[3];
        attr[12] = '"}],';
        
        string memory attrStr = string(abi.encodePacked(attr[0], attr[1], attr[2], attr[3], attr[4], attr[5]));
        attrStr = string(abi.encodePacked(attrStr, attr[6], attr[7], attr[8], attr[9], attr[10], attr[11], attr[12]));
        
        string memory out = Base64.encode(bytes(output));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', mainString, '", "description": "', discriptionStr, '", ', attrStr, ' "image": "data:image/svg+xml;base64,', out, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    constructor() ERC721("ChainArtefactArmer", "CAG") Ownable() {}
}