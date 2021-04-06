/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


contract Context {
    
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.6.0;


interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol
pragma solidity ^0.6.2;


interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

   
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) external view returns (uint256 balance);

   
    function ownerOf(uint256 tokenId) external view returns (address owner);

    
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

   
    function transferFrom(address from, address to, uint256 tokenId) external;

    
    function approve(address to, uint256 tokenId) external;

   
    function getApproved(uint256 tokenId) external view returns (address operator);

   
    function setApprovalForAll(address operator, bool _approved) external;

   
    function isApprovedForAll(address owner, address operator) external view returns (bool);

   
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol
pragma solidity ^0.6.2;



interface IERC721Metadata is IERC721 {

   
    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol
pragma solidity ^0.6.2;


interface IERC721Enumerable is IERC721 {


    function totalSupply() external view returns (uint256);


    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);


    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol
pragma solidity ^0.6.0;


abstract contract IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public virtual returns (bytes4);
}


pragma solidity ^0.6.0;

// File: @openzeppelin/contracts/introspection/ERC165.sol
contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;


    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        
        _registerInterface(_INTERFACE_ID_ERC165);
    }


    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }


    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol
pragma solidity ^0.6.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol
pragma solidity ^0.6.2;


library Address {

    function isContract(address account) internal view returns (bool) {
      
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol
pragma solidity ^0.6.0;


library EnumerableSet {


    struct Set {
        
        bytes32[] _values;

        
        mapping (bytes32 => uint256) _indexes;
    }


    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }


    function _remove(Set storage set, bytes32 value) private returns (bool) {
      
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1; 
			
            set._values.pop();


            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }


    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }


    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }


    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }


    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }


    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }


    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

 
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }


    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    
    struct UintSet {
        Set _inner;
    }


    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }


    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }


    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: contracts/EnumerableRandomMapSimple.sol
pragma solidity ^0.6.0;

library EnumerableRandomMapSimple {

    struct Map {
       
        mapping(bytes32 => bytes32) _entries;
        uint256 _length;
    }


    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        bool newVal;
        if (map._entries[key] == bytes32("")) { // add new entry
            map._length++;
            newVal = true;
        }
        else if (value == bytes32("")) { // remove entry
            map._length--;
            newVal = false;
        }
        else {
            newVal = false;
        }
        map._entries[key] = value;
        return newVal;
    }


    function _remove(Map storage /*map*/, bytes32 /*key*/) private pure returns (bool) {
        revert("No removal supported");
    }


    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._entries[key] != bytes32("");
    }


    function _length(Map storage map) private view returns (uint256) {
        return map._length;
    }


    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = bytes32(index);
        require(_contains(map, key), "EnumerableMap: index out of bounds");
        return (key, map._entries[key]);
    }


    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }


    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        require(_contains(map, key), errorMessage); // Equivalent to contains(map, key)
        return map._entries[key];
    }



    struct UintToAddressMap {
        Map _inner;
    }


    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }


    function remove(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _remove(map._inner, bytes32(key));
    }


    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }


    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }


    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }


    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }


    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}


// File: @openzeppelin/contracts/utils/Strings.sol
pragma solidity ^0.6.0;


library Strings {

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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}


// File: contracts/OZ_Clone/ERC721_simplemaps.sol
pragma solidity ^0.6.0;


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableRandomMapSimple for EnumerableRandomMapSimple.UintToAddressMap;
    using Strings for uint256;


    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;


    mapping (address => EnumerableSet.UintSet) private _holderTokens;


    EnumerableRandomMapSimple.UintToAddressMap private _tokenOwners;


    mapping (uint256 => address) private _tokenApprovals;


    mapping (address => mapping (address => bool)) private _operatorApprovals;


    string private _name;


    string private _symbol;


    mapping(uint256 => string) private _tokenURIs;


    string private _baseURI;


    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;


    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;


    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;


        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }


    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }


    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }


    function name() public view override returns (string memory) {
        return _name;
    }


    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }


    function baseURI() public view returns (string memory) {
        return _baseURI;
    }


    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    function totalSupply() public view override virtual returns (uint256) {
        
        return _tokenOwners.length();
    }


    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }


    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }


    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }


    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }


    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
   
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }


    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }


    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }


    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);


        _approve(address(0), tokenId);


        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }


    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);


        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }


    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }


    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }


    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}


// File: contracts/ERC721SimpleMapsURI.sol
pragma solidity ^0.6.0;



contract ERC721SimpleMapsURI is ERC721 {


    event BaseURI(string value);

    constructor (string memory name, string memory symbol, string memory baseURI)
    ERC721(name, symbol)
    public
    {
        _setBaseURI(baseURI);
    }


    function _setBaseURI(string memory baseURI_) internal override virtual {
        super._setBaseURI(baseURI_);
        emit BaseURI(baseURI());
    }

}


pragma solidity ^0.6.0;

interface SOISColorsI {

    enum Colors {
        White,
        Black,
        Yellow,
        Cyan,
        Magenta
    }

    function getColor(uint256 tokenId) external view returns (Colors);

}


pragma solidity ^0.6.0;

interface STWPropertiesI {

    enum AssetType {
        Master,
        Preferred,
        VIP,
        SuperVIP
    }

    enum Colors {
        White,
        Black,
        Yellow,
        Cyan,
        Magenta
    }

    function getType(uint256 tokenId) external view returns (AssetType);
    function getColor(uint256 tokenId) external view returns (Colors);

}

// File: contracts/ENSReverseRegistrarI.sol
pragma solidity ^0.6.0;

interface ENSRegistryOwnerI {
    function owner(bytes32 node) external view returns (address);
}

interface ENSReverseRegistrarI {
    function setName(string calldata name) external returns (bytes32 node);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity ^0.6.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.0;



interface AchievementsUpgradingI is IERC165 {

    function onSTWColorChanged(uint256 tokenId, STWPropertiesI.Colors previousColor, STWPropertiesI.Colors newColor)
    external returns (bytes4);

}

// File: @openzeppelin/contracts/cryptography/ECDSA.sol
pragma solidity ^0.6.0;


library ECDSA {

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }


        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }


    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {

        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


// File: @openzeppelin/contracts/cryptography/MerkleProof.sol
pragma solidity ^0.6.0;

library MerkleProof {

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {

                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {

                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }
}

pragma solidity ^0.6.0;


contract StadiumWorld is ERC721SimpleMapsURI, STWPropertiesI {
    using SafeMath for uint256;

    bytes4 private constant _INTERFACE_ID_ACHIEVEMENTS_UPGRADING = 0x58cac597;
    uint8 private constant COLORBITS = 4;
    uint8 private constant COLORMOD = uint8(2) ** COLORBITS;

    address public createControl;
    address public tokenAssignmentControl;
    address public SOISAddress;
    address public SOISColorsAddress;
    AchievementsUpgradingI public achievementsContract;

    uint256 immutable finalSupply;
    uint256 constant maxSupportedSupply = 2 ** 24;
    bool public allowPublicMinting = false;
    bytes32 public dataRoot;

    uint256 public upgradesDone = 0;
    uint256 public upgradeMaximum;

    uint8[maxSupportedSupply] private properties;
    uint256[5][4] public typeColorSupply; // Note that numbers are reversed in Solidity compared to other languages!
    mapping(uint256 => bool) public usedInUpgrade;
    mapping(uint256 => bool) public usedInUpgradeSOIS;

    mapping(address => uint256) public signedTransferNonce;

    event CreateControlTransferred(address indexed previousCreateControl, address indexed newCreateControl);
    event TokenAssignmentControlTransferred(address indexed previousTokenAssignmentControl, address indexed newTokenAssignmentControl);
    event AchievementsContractSet(address indexed achievementsContractAddress);
    event UpgradeMaximumChanged(uint256 previousUpgradeMaximum, uint256 newUpgradeMaximum);
    event DataRootSet(bytes32 dataRoot);
    event PublicMintingEnabled();
    event PublicMintingDisabled();
    event MintedWithProof(address operator, uint256 indexed tokenId, address indexed owner, AssetType aType, Colors color);
    event SignedTransfer(address operator, address indexed from, address indexed to, uint256 indexed tokenId, uint256 signedTransferNonce);
    event SeatUpgraded(uint256 indexed changedTokenId, Colors previousColor, Colors newColor, bool withSoccerIndustry, uint256 usedTokedId1, uint256 usedTokenId2);
    // TestAchievementsUpgrading event - never emitted in this contract but helpful for running our tests.
    event SeenSTWColorChanged(uint256 tokenId, Colors previousColor, Colors newColor);

    constructor(address _createControl, address _tokenAssignmentControl, address _SOISAddress, address _SOISColorsAddress, uint256 _finalSupply, uint256 _upgradeMaximum)
    ERC721SimpleMapsURI("Stadium World", "STW", "https://soccerindustry.org/stadiumworld/meta/")
    public
    {
        createControl = _createControl;
        require(address(createControl) != address(0x0), "You need to provide an actual createControl address.");
        tokenAssignmentControl = _tokenAssignmentControl;
        require(address(tokenAssignmentControl) != address(0x0), "You need to provide an actual tokenAssignmentControl address.");
        SOISColorsAddress = _SOISColorsAddress;
        require(address(SOISColorsAddress) != address(0x0), "You need to provide an actual SOIS colors address.");
        SOISAddress = _SOISAddress;
        require(address(SOISAddress) != address(0x0), "You need to provide an actual SOIS address.");
        finalSupply = _finalSupply;
        require(_finalSupply <= maxSupportedSupply, "The final supply is too high.");
        upgradeMaximum = _upgradeMaximum;
    }

    modifier onlyCreateControl()
    {
        require(msg.sender == createControl, "createControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier requireMinting() {
        require(mintingFinished() == false, "This call only works when minting is not finished.");
        _;
    }



    function transferTokenAssignmentControl(address _newTokenAssignmentControl)
    public
    onlyTokenAssignmentControl
    {
        require(_newTokenAssignmentControl != address(0), "tokenAssignmentControl cannot be the zero address.");
        emit TokenAssignmentControlTransferred(tokenAssignmentControl, _newTokenAssignmentControl);
        tokenAssignmentControl = _newTokenAssignmentControl;
    }

    function transferCreateControl(address _newCreateControl)
    public
    onlyCreateControl
    {
        require(_newCreateControl != address(0), "createControl cannot be the zero address.");
        emit CreateControlTransferred(createControl, _newCreateControl);
        createControl = _newCreateControl;
    }

    
    function setAchievementsContract(address _achievementsAddress)
    public
    onlyCreateControl
    {
        achievementsContract = AchievementsUpgradingI(_achievementsAddress);
        emit AchievementsContractSet(_achievementsAddress);
        if (_achievementsAddress != address(0)) {
            require(IERC165(achievementsContract).supportsInterface(_INTERFACE_ID_ACHIEVEMENTS_UPGRADING),
                    "Need to implement the achievements upgrading interface!");
        }
    }

    function setUpgradeMaximum(uint256 _newUpgradeMaximum)
    public
    onlyCreateControl
    {
        require(upgradesDone <= _newUpgradeMaximum, "Already more upgrades done than the requested limit.");
        emit UpgradeMaximumChanged(upgradeMaximum, _newUpgradeMaximum);
        upgradeMaximum = _newUpgradeMaximum;
    }

    function setDataRoot(bytes32 _newDataRoot)
    public
    onlyCreateControl
    {
        require(dataRoot == bytes32(""), "Can only set root once.");
        emit DataRootSet(_newDataRoot);
        dataRoot = _newDataRoot;
    }


    function totalSupply()
    public view override
    returns (uint256) {
        return finalSupply;
    }


    function mintedSupply()
    public view
    returns (uint256) {
        return super.totalSupply();
    }


    function create(uint256 _tokenId, address _owner, AssetType _type, Colors _color)
    public
    onlyCreateControl
    requireMinting
    {

        _mintWithProperties(_tokenId, _owner, _type, _color);
    }


    function createMulti(uint256 _tokenIdStart, address[] memory _owners, AssetType[] memory _types, Colors[] memory _colors)
    public
    onlyCreateControl
    requireMinting
    {
        require(_owners.length == _types.length && _owners.length == _colors.length, "All given arrays need to be the same length.");
        uint256 addrcount = _owners.length;
        for (uint256 i = 0; i < addrcount; i++) {

            _mintWithProperties(_tokenIdStart + i, _owners[i], _types[i], _colors[i]);
        }
    }


    function createWithProof(bytes32 tokenData, bytes32[] memory merkleProof)
    public
    requireMinting
    returns (uint256)
    {
        require(publicMintingAllowed(), "Public minting needs to be allowed.");
        (uint256 tokenId, address owner, AssetType aType, Colors color) = getDataFieldsFromProof(tokenData, merkleProof);
        require(!_exists(tokenId), "Token already exists.");
        emit MintedWithProof(msg.sender, tokenId, owner, aType, color);
        _mintWithProperties(tokenId, owner, aType, color);
        return tokenId;
    }


    function getTokenIdFromProof(bytes32 tokenData, bytes32[] memory merkleProof)
    public view
    returns (uint256) {
        (uint256 tokenId, /*address owner*/, /*AssetType aType*/, /*Colors color*/) = getDataFieldsFromProof(tokenData, merkleProof);
        return tokenId;
    }


    function getOwnerFromProof(bytes32 tokenData, bytes32[] memory merkleProof)
    public view
    returns (address) {
        (uint256 tokenId, address owner, /*AssetType aType*/, /*Colors color*/) = getDataFieldsFromProof(tokenData, merkleProof);
        if (_exists(tokenId)) return ownerOf(tokenId);
        return owner;
    }


    function getTypeFromProof(bytes32 tokenData, bytes32[] memory merkleProof)
    public view
    returns (AssetType) {
        (uint256 tokenId, /*address owner*/, AssetType aType, /*Colors color*/) = getDataFieldsFromProof(tokenData, merkleProof);
        if (_exists(tokenId)) return getType(tokenId);
        return aType;
    }


    function getColorFromProof(bytes32 tokenData, bytes32[] memory merkleProof)
    public view
    returns (Colors) {
        (uint256 tokenId, /*address owner*/, /*AssetType aType*/, Colors color) = getDataFieldsFromProof(tokenData, merkleProof);
        if (_exists(tokenId)) return getColor(tokenId);
        return color;
    }


    function getDataFieldsFromProof(bytes32 tokenData, bytes32[] memory merkleProof)
    public view
    returns (uint256, address, AssetType, Colors)
    {
        require(dataRoot != bytes32(""), "Root needs to be set.");
        require(MerkleProof.verify(merkleProof, dataRoot, tokenData), "Verification failed.");
        uint256 tokenId = uint256(tokenData >> 168); 
        AssetType aType = AssetType(uint8(tokenData[11]) >> COLORBITS);
        Colors color = Colors(uint8(tokenData[11]) % COLORMOD);
        address owner = address(uint256(tokenData)); 
        require(owner != address(0), "tokenData needs to contain an owner.");
        return (tokenId, owner, aType, color);
    }


    function _mintWithProperties(uint256 _tokenId, address _owner, AssetType _type, Colors _color)
    internal
    {
        if (_exists(_tokenId)) {
            require(getType(_tokenId) == _type, "Type mismatch with existing token.");
            if (upgradesDone == 0) {
               
                require(getColor(_tokenId) == _color, "Color mismatch with existing token.");
            }
        }
        else {
            _mint(_owner, _tokenId);
           
            properties[_tokenId] = uint8(_type) * COLORMOD + uint8(_color);
            typeColorSupply[uint(_type)][uint(_color)] = typeColorSupply[uint(_type)][uint(_color)].add(1);
        }
    }


    function mintingFinished()
    public view
    returns (bool)
    {
        return (super.totalSupply() >= finalSupply);
    }

    function enablePublicMinting()
    public
    onlyCreateControl
    {
        require(dataRoot != bytes32(""), "Root needs to be set.");
        allowPublicMinting = true;
        emit PublicMintingEnabled();
    }


    function disablePublicMinting()
    public
    onlyCreateControl
    {
        allowPublicMinting = false;
        emit PublicMintingDisabled();
    }


    function publicMintingAllowed()
    public view
    returns (bool)
    {
        return (!mintingFinished() && allowPublicMinting);
    }

    function setBaseURI(string memory _newBaseURI)
    public
    onlyCreateControl
    {
        super._setBaseURI(_newBaseURI);
    }

    function getType(uint256 tokenId)
    public view override
    returns (AssetType) {
        require(_exists(tokenId), "Token ID needs to exist.");
        return AssetType(properties[tokenId] >> COLORBITS);
    }

    function getColor(uint256 tokenId)
    public view override
    returns (Colors) {
        require(_exists(tokenId), "Token ID needs to exist.");
        return Colors(properties[tokenId] % COLORMOD);
    }

    function exists(uint256 tokenId)
    public view
    returns (bool) {
        return _exists(tokenId);
    }


    function typeSupply(AssetType _type)
    public view
    returns (uint256) {
        uint256 thisTypeSupply = 0;
        for (uint256 i = 0; i < typeColorSupply[uint(_type)].length; i++) {
          thisTypeSupply = thisTypeSupply.add(typeColorSupply[uint(_type)][i]);
        }
        return thisTypeSupply;
    }


    function colorSupply(Colors _color)
    public view
    returns (uint256) {
        uint256 thisColorSupply = 0;
        for (uint256 i = 0; i < typeColorSupply.length; i++) {
          thisColorSupply = thisColorSupply.add(typeColorSupply[i][uint(_color)]);
        }
        return thisColorSupply;
    }


    function signedTransfer(uint256 _tokenId, address _to, bytes memory _signature)
    public
    {
        address currentOwner = ownerOf(_tokenId);

        bytes32 data = keccak256(abi.encodePacked(address(this), this.signedTransfer.selector, currentOwner, _to, _tokenId, signedTransferNonce[currentOwner]));
        _signedTransferInternal(currentOwner, data, _tokenId, _to, _signature);
    }


    function signedTransferWithOperator(uint256 _tokenId, address _to, bytes memory _signature)
    public
    {
        address currentOwner = ownerOf(_tokenId);

        bytes32 data = keccak256(abi.encodePacked(address(this), this.signedTransferWithOperator.selector, msg.sender, currentOwner, _tokenId, signedTransferNonce[currentOwner]));
        _signedTransferInternal(currentOwner, data, _tokenId, _to, _signature);
    }


    function _signedTransferInternal(address _currentOwner, bytes32 _data, uint256 _tokenId, address _to, bytes memory _signature)
    internal
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(_data);
        address signer = ECDSA.recover(hash, _signature);
        require(signer == _currentOwner, "Signature needs to match parameters, nonce, and current owner.");

        emit SignedTransfer(msg.sender, _currentOwner, _to, _tokenId, signedTransferNonce[_currentOwner]);
        signedTransferNonce[_currentOwner] = signedTransferNonce[_currentOwner].add(1);
        _safeTransfer(_currentOwner, _to, _tokenId, "");
    }


    function signedTransferWithMintProof(bytes32 tokenData, address _to, bytes calldata _signature, bytes32[] calldata merkleProof)
    external
    {
        uint256 tokenId = createWithProof(tokenData, merkleProof);
        signedTransfer(tokenId, _to, _signature);
    }


    function signedTransferWithOperatorAndMintProof(bytes32 tokenData, address _to, bytes calldata _signature, bytes32[] calldata merkleProof)
    external
    {
        uint256 tokenId = createWithProof(tokenData, merkleProof);
        signedTransferWithOperator(tokenId, _to, _signature);
    }


    function upgradesAllowed() public view returns (bool) {
        return (address(achievementsContract) != address(0) && upgradesDone < upgradeMaximum);
    }


    function upgradeSeat(uint256 _upgradeTokenId, uint256 _helperTokenId1, uint256 _helperTokenId2)
    public
    {
        require(address(achievementsContract) != address(0), "No achievements contract set");
        require(upgradesDone < upgradeMaximum, "Maximum upgrades reached");
        require(_upgradeTokenId != _helperTokenId1 &&
                _upgradeTokenId != _helperTokenId2 &&
                _helperTokenId1 != _helperTokenId2,
                "You actually need to use 3 different tokens to upgrade");
        require(msg.sender == ownerOf(_upgradeTokenId) &&
                msg.sender == ownerOf(_helperTokenId1) &&
                msg.sender == ownerOf(_helperTokenId2),
                "Caller has to be owner of all tokens.");
        require(usedInUpgrade[_upgradeTokenId] == false &&
                usedInUpgrade[_helperTokenId1] == false &&
                usedInUpgrade[_helperTokenId2] == false,
                "Cannot used seat already used in a upgrade.");
        Colors previousColor = getColor(_upgradeTokenId);
        AssetType aType = getType(_upgradeTokenId);
        require(getType(_helperTokenId1) == aType && getColor(_helperTokenId1) == previousColor &&
                getType(_helperTokenId2) == aType && getColor(_helperTokenId2) == previousColor,
                "All tokens involved must have the same type and color");
        usedInUpgrade[_helperTokenId1] = true;
        usedInUpgrade[_helperTokenId2] = true;

        Colors newColor = _upgradeColor(_upgradeTokenId, aType, previousColor);
        emit SeatUpgraded(_upgradeTokenId, previousColor, newColor, false, _helperTokenId1, _helperTokenId2);
    }


    function upgradeSeatwithSoccerIndustry(uint256 _upgradeTokenId, uint256 _helperTokenId, uint256 _helperSOISTokenId)
    public
    {
        require(address(achievementsContract) != address(0), "No achievements contract set");
        require(upgradesDone < upgradeMaximum, "Maximum upgrades reached");
        require(_upgradeTokenId != _helperTokenId, "You actually need to use different tokens to upgrade");
        IERC721 SOIS = IERC721(SOISAddress);
        SOISColorsI SOISColors = SOISColorsI(SOISColorsAddress);
        require(msg.sender == ownerOf(_upgradeTokenId) &&
                msg.sender == ownerOf(_helperTokenId) &&
                msg.sender == SOIS.ownerOf(_helperSOISTokenId),
                "Caller has to be owner of all tokens.");
        require(usedInUpgrade[_upgradeTokenId] == false &&
                usedInUpgrade[_helperTokenId] == false &&
                usedInUpgradeSOIS[_helperSOISTokenId] == false,
                "Cannot used seats already used in a upgrade.");
        Colors previousColor = getColor(_upgradeTokenId);
        AssetType aType = getType(_upgradeTokenId);

        require(getType(_helperTokenId) == aType && getColor(_helperTokenId) == previousColor &&
                SOISColors.getColor(_helperSOISTokenId) == SOISColorsI.Colors(uint8(previousColor)),
                "All tokens involved must have the same color, and all STW tokens the same type");
        usedInUpgrade[_helperTokenId] = true;
        usedInUpgradeSOIS[_helperSOISTokenId] = true;

        Colors newColor = _upgradeColor(_upgradeTokenId, aType, previousColor);
        emit SeatUpgraded(_upgradeTokenId, previousColor, newColor, true, _helperTokenId, _helperSOISTokenId);
    }

    function _upgradeColor(uint256 _upgradeTokenId, AssetType _assetType, Colors _previousColor)
    private
    returns(Colors)
    {
        Colors newColor = Colors(uint256(_previousColor).add(1));
        properties[_upgradeTokenId] = uint8(_assetType) * COLORMOD + uint8(newColor);
        typeColorSupply[uint(_assetType)][uint(_previousColor)] = typeColorSupply[uint(_assetType)][uint(_previousColor)].sub(1);
        typeColorSupply[uint(_assetType)][uint(newColor)] = typeColorSupply[uint(_assetType)][uint(newColor)].add(1);
        upgradesDone = upgradesDone.add(1);
        require(
            achievementsContract.onSTWColorChanged(_upgradeTokenId, _previousColor, newColor) ==
                achievementsContract.onSTWColorChanged.selector,
            "Achievements upgrading: got unknown value from onSTWColorChanged"
        );
        return newColor;
    }


    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name)
    external
    onlyTokenAssignmentControl
    {
       require(_reverseRegistrarAddress != address(0), "need a valid reverse registrar");
       ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }


    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }


    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }


    receive()
    external payable
    {
        revert("The contract cannot receive ETH payments.");
    }
}