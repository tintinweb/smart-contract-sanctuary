/**
 *Submitted for verification at polygonscan.com on 2021-10-19
*/

pragma solidity ^0.8.7;


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

library Math {
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return (a & b) + (a ^ b) / 2;
    }

    
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

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

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    
    mapping(uint256 => string) private _tokenURIs;

    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
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

interface IHasSecondarySaleFees {
    function getFeeBps(uint256 id) external view returns (uint256[] memory);
    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
}

contract HasSecondarySaleFees is IERC165, IHasSecondarySaleFees {
    
    event ChangeCommonRoyalty(
        address payable[] royaltyAddresses,
        uint256[] royaltiesWithTwoDecimals
    );
    
    event ChangeRoyalty(
        uint256 id,
        address payable[] royaltyAddresses,
        uint256[] royaltiesWithTwoDecimals
    );
    
    struct RoyaltyInfo {
        bool isPresent;
        address payable[] royaltyAddresses;
        uint256[] royaltiesWithTwoDecimals;
    }
    
    mapping(bytes32 => RoyaltyInfo) royaltyInfoMap;
    mapping(uint256 => bytes32) tokenRoyaltyMap;
    
    address payable[] public commonRoyaltyAddresses;
    uint256[] public commonRoyaltiesWithTwoDecimals;

    constructor(
        address payable[] memory _commonRoyaltyAddresses,
        uint256[] memory _commonRoyaltiesWithTwoDecimals
    ) {
        _setCommonRoyalties(_commonRoyaltyAddresses, _commonRoyaltiesWithTwoDecimals);
    }

    function _setRoyaltiesOf(
        uint256 _tokenId,
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) internal {
        require(_royaltyAddresses.length == _royaltiesWithTwoDecimals.length, "input length must be same");
        bytes32 key = 0x0;
        for (uint256 i = 0; i < _royaltyAddresses.length; i++) { 
            require(_royaltyAddresses[i] != address(0), "Must not be zero-address");
            key = keccak256(abi.encodePacked(key, _royaltyAddresses[i], _royaltiesWithTwoDecimals[i]));
        }
        
        tokenRoyaltyMap[_tokenId] = key;
        emit ChangeRoyalty(_tokenId, _royaltyAddresses, _royaltiesWithTwoDecimals);
        
        if (royaltyInfoMap[key].isPresent) { 
            return;
        }
        royaltyInfoMap[key] = RoyaltyInfo(
            true,
            _royaltyAddresses,
            _royaltiesWithTwoDecimals
        );
    }

    function _setCommonRoyalties(
        address payable[] memory _commonRoyaltyAddresses,
        uint256[] memory _commonRoyaltiesWithTwoDecimals
    ) internal {
        require(_commonRoyaltyAddresses.length == _commonRoyaltiesWithTwoDecimals.length, "input length must be same");
        for (uint256 i = 0; i < _commonRoyaltyAddresses.length; i++) { 
            require(_commonRoyaltyAddresses[i] != address(0), "Must not be zero-address");
        }
        
        commonRoyaltyAddresses = _commonRoyaltyAddresses;
        commonRoyaltiesWithTwoDecimals = _commonRoyaltiesWithTwoDecimals;
        
        emit ChangeCommonRoyalty(_commonRoyaltyAddresses, _commonRoyaltiesWithTwoDecimals);
    }

    function getFeeRecipients(uint256 _tokenId)
    public view override returns (address payable[] memory)
    {
        RoyaltyInfo memory royaltyInfo = royaltyInfoMap[tokenRoyaltyMap[_tokenId]];
        if (!royaltyInfo.isPresent) {
            return commonRoyaltyAddresses;
        }
        uint256 length = commonRoyaltyAddresses.length + royaltyInfo.royaltyAddresses.length;

        address payable[] memory recipients = new address payable[](length);
        for (uint256 i = 0; i < commonRoyaltyAddresses.length; i++) {
            recipients[i] = commonRoyaltyAddresses[i];
        }
        for (uint256 i = 0; i < royaltyInfo.royaltyAddresses.length; i++) {
            recipients[i + commonRoyaltyAddresses.length] = royaltyInfo.royaltyAddresses[i];
        }

        return recipients;
    }

    function getFeeBps(uint256 _tokenId) public view override returns (uint256[] memory) {
        RoyaltyInfo memory royaltyInfo = royaltyInfoMap[tokenRoyaltyMap[_tokenId]];
        if (!royaltyInfo.isPresent) {
            return commonRoyaltiesWithTwoDecimals;
        }
        uint256 length = commonRoyaltiesWithTwoDecimals.length + royaltyInfo.royaltiesWithTwoDecimals.length;

        uint256[] memory fees = new uint256[](length);
        for (uint256 i = 0; i < commonRoyaltiesWithTwoDecimals.length; i++) {
            fees[i] = commonRoyaltiesWithTwoDecimals[i];
        }
        for (uint256 i = 0; i < royaltyInfo.royaltiesWithTwoDecimals.length; i++) {
            fees[i + commonRoyaltyAddresses.length] = royaltyInfo.royaltiesWithTwoDecimals[i];
        }

        return fees;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165)
    returns (bool)
    {
        return interfaceId == type(IHasSecondarySaleFees).interfaceId;
    }

}

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract QUOXKA_V3 is ERC721, ERC721Enumerable, ContextMixin, HasSecondarySaleFees, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using Math for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    bool private _isOnSale;
    bool private _isMintLock;
    
    uint256 private constant NFT_SUPPLY_AMOUNT = 1000;
    address private constant ROYALTY_RECIPIENTS_1 = 0xA297b42c882065bB5C6fFcc38441685db32592A8;
    address private constant ROYALTY_RECIPIENTS_2 = 0xF13c426Ae5Fd3381024b582f7BD31b681d571f48;
    string private constant _NAME = "QUOXKAv3";
    string private constant CID = 'QmVbKzuiH9wc4UgEmXTdwxAqQGyc7rwFe8jwrQDH2N6nbz';
    
    event PermanentURI(string _value, uint256 indexed _id);
    
    constructor()
    ERC721(_NAME, _NAME)
    HasSecondarySaleFees(new address payable[](0), new uint256[](0))
    {
        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 1000;

        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
    }
    
    
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
    
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        
        return ERC721.isApprovedForAll(_owner, _operator);
    }
    
    function matchWhiteList(address sender) internal pure returns(bool) {
        uint256 listCount = 19;
        address[] memory addresses = new address[](listCount);
        addresses[0] = 0xa3FDa2F536EF3b64Ff76a18FEd57F7d7C8508f31;
        addresses[1] = 0x06BAc69D925002B5B1e5553b8C20f997144905c0;
        addresses[2] = 0x3d3B69457Ce7e7998f19e85E018B5a296Aed781e;
        addresses[3] = 0x4876aBFa6a5997DF937A3C3bEAcfCa75f33C9BE2;
        addresses[4] = 0x6E3BC51810AA3407463bbf2b094BB91EEb91D918;
        addresses[5] = 0xeC37E60a84708EE22E8cd275c8C6bAAc6A8421f7;
        addresses[6] = 0x42A88445Ff078f097eB105Cf847eA8EBbc82CEBB;
        addresses[7] = 0x96057D75552EDB5836e76F9b0Faf53253452ee68;
        addresses[8] = 0x09557A412FDf6FFa883FE14C4e2febAFc37e993c;
        addresses[9] = 0x109E58Bf171a19dDc0d0b9E4B37BfA72E626873E;
        addresses[10] = 0xf1f415beb600830626146cae957f26C985d00261;
        addresses[11] = 0xa4f23e9A9EAe680e5ff48eA972a31cc1A787500e;
        addresses[12] = 0x878a19E2F2F0FA2273F198bE9eA9E6c901d255FC;
        addresses[13] = 0x06beA5a3B6DBA70E6E74701b1Bc0dA785251aA2B;
        addresses[14] = 0x4A33cEBC2d819a422e7217c5cAe804792f41F9e8;
        addresses[15] = 0xf88343D7781F4B435Cd2Bf717BbFdf18216799D3;
        addresses[16] = 0x9F0be16Da0B9F341eaB7940558844B41B045DAe7;
        addresses[17] = 0x85458ca7c14A6fc044e219ea013106e15Ca9a734;
        addresses[18] = 0x86958051526B119027b8bB33444610538Ec87fB2;
        
        uint256 muchCounter = 0;
        for (uint256 i = 0; i < listCount; i++) {
            if(addresses[i] == sender){
                muchCounter++;
            }
        }
        
        return muchCounter > 0;
    }

    
    function mint() public {
        require(_isMintLock, "Mint Locked");
        require(_isOnSale || matchWhiteList(_msgSender()), "Not on sale");
        require(balanceOf(_msgSender()) < 5, "Upper Limit");
        
        uint256 currentNumber = _tokenIdCounter.current();
        
        require(currentNumber <= NFT_SUPPLY_AMOUNT, "No mint tokens");
        
        _safeMint(_msgSender(), currentNumber);
        _tokenIdCounter.increment();
    }
    
    function switchOnSale() public onlyOwner {
        require(!_isOnSale, "Already on sale");
        _isOnSale = true;
    }

    function mintLock() public onlyOwner {
        require(_isMintLock, "Already mint lock");
        _isMintLock = false;
    }
    
    function mintUnLock() public onlyOwner {
        require(!_isMintLock, "Not mint lock");
        _isMintLock = true;
    }
    
    function ownerMint() public onlyOwner {
        uint256 currentNumber = _tokenIdCounter.current();
        require(currentNumber <= NFT_SUPPLY_AMOUNT, "No mint tokens");
        
        _safeMint(_msgSender(), currentNumber);
        
        _tokenIdCounter.increment();
    }
    
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked('ipfs://', CID, '/', tokenId.toString(), ".json"));
    }

    function withdrawETH() external {
        uint256 royalty = address(this).balance / 2;

        Address.sendValue(payable(ROYALTY_RECIPIENTS_1), royalty);
        Address.sendValue(payable(ROYALTY_RECIPIENTS_2), royalty);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, HasSecondarySaleFees)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) ||
        HasSecondarySaleFees.supportsInterface(interfaceId);
    }
    
    receive() external payable {}

}