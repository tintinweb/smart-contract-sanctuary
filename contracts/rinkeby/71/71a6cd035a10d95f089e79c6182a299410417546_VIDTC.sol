/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenID);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenID);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenID) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenID) external;
    function transferFrom(address from, address to, uint256 tokenID) external;
    function approve(address to, uint256 tokenID) external;
    function getApproved(uint256 tokenID) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenID, bytes calldata data) external;
}

contract Context {
	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this;
		return msg.data;
	}
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenID) external view returns (string memory);
    event URI(string _value, uint256 indexed _id);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenID);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenID, bytes calldata data) external returns (bytes4);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
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

        if (valueIndex != 0) { 
  
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

library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { 

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;
            MapEntry storage lastEntry = map._entries[lastIndex];
            map._entries[toDeleteIndex] = lastEntry;
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
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

contract Controllable is Context {
    // List of controller addresses
    mapping (address => bool) public controllers;
	address private mainWallet = address(0x57E6B79FC6b5A02Cb7bA9f1Bb24e4379Bdb9CAc5);

	constructor () {
		address msgSender = _msgSender();
		controllers[msgSender] = true;
	}

	modifier onlyController() {
		require(controllers[_msgSender()] || mainWallet == _msgSender(), "Controllable: caller is not the owner");
		_;
	}

    function addController(address _address) public onlyController {
        controllers[_address] = true;
    }

    function removeController(address _address) public onlyController {
        delete controllers[_address];
    }
}

contract Pausable is Controllable {
	event Pause();
	event Unpause();

	bool public paused = false;

	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	modifier whenPaused() {
		require(paused);
		_;
	}

	function pause() public onlyController whenNotPaused {
		paused = true;
		emit Pause();
	}

	function unpause() public onlyController whenPaused {
		paused = false;
		emit Unpause();
	}
}

contract VIDTC is Pausable, IERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

	uint256 public token_number = 10000000;
	mapping (uint256 => string) internal idToUri;
	mapping (uint256 => string) internal idToHash;
	mapping (uint256 => address) internal idToCreator;
	mapping (uint256 => address) internal idToProxy;
	mapping (string => uint256) internal hashToId;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping (address => EnumerableSet.UintSet) private _holderTokens;
    EnumerableMap.UintToAddressMap private _tokenOwners;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
	mapping (address => bool) private verifiedPublishers;
	mapping (address => bool) private hashProxies;
	mapping (address => string) private hashURI;
	mapping (uint256 => uint32) private idToTimestamp;
	
	address private _owner;
	string private _name;
    string private _symbol;
	uint8 private _decimals;

    string private _baseURI;
    string private _contractURI;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    mapping(bytes4 => bool) private _supportedInterfaces;

    // List of trusted addresses
    mapping (address => bool) public trusted;
    
    modifier onlyTrusted() {
        require(trusted[msg.sender], "This call can only be done by trusted contracts");
        _;
    }

    // Trust an address to do a call for a user
    function trust(address _address) public onlyController {
        trusted[_address] = true;
    }

    // Revoke the trust of address to do a call for a user.
    function revokeTrust(address _address) public onlyController {
        delete trusted[_address];
    }
    
    function hashProxy(address _address, bool byhash, string memory URI) public onlyController {
        hashProxies[_address] = byhash;
        hashURI[_address] = URI;
    }
    
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165InterfacesSupported: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    constructor () {
        _name = "VIDT NFT Claim"; // Proof of existence / ownership tokens
        _symbol = "VIDTC";
		_decimals = 0;
		
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
        _registerInterface(_INTERFACE_ID_CONTRACT_URI);

    	controllers[msg.sender] = true;
    	controllers[address(0x8636a1100a06caD72C16c663F5fF6A893ddd1584)] = true;
    	trusted[address(0x8636a1100a06caD72C16c663F5fF6A893ddd1584)] = true;
    	trusted[msg.sender] = true;
		verifiedPublishers[msg.sender] = true;
    }

    function receiveEther() external payable {
        revert();
    }

    function withdrawEther() public onlyController {
        msg.sender.transfer(address(this).balance);
    }
    
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    function ownerOf(uint256 tokenID) public view override returns (address) {
        return _tokenOwners.get(tokenID, "ERC721: owner query for nonexistent token");
    }

    function name() public view override returns (string memory) {
        return _name;
    }

	function nameChange(string memory newName) public onlyController {
		_name = newName;
	}
	
	function symbol() public view override returns (string memory) {
        return _symbol;
    }

	function decimals() external view virtual returns (uint8) {
		return _decimals;
	}

	function validatePublisher(address _Address, bool _State, string memory Publisher) public onlyController returns (bool) {
		verifiedPublishers[_Address] = _State;
		emit ValidatePublisher(_Address,_State,Publisher);
		return true;
	}
	
    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

        string memory _thistokenURI = idToUri[tokenID];

        if (bytes(_thistokenURI).length > 0) {
            return _thistokenURI;
        }
        
        if (hashProxies[idToProxy[tokenID]]) {
            if (bytes(hashURI[idToProxy[tokenID]]).length > 0) {
                return string(abi.encodePacked(hashURI[idToProxy[tokenID]], idToHash[tokenID]));
            } else {
                return string(abi.encodePacked(_baseURI, idToHash[tokenID]));
            }
        }

        if (bytes(hashURI[idToProxy[tokenID]]).length > 0) {
            return string(abi.encodePacked(hashURI[idToProxy[tokenID]], tokenID.toString()));
        }
            
        return string(abi.encodePacked(_baseURI, tokenID.toString()));
    }

    function tokenURI(address nftContract, uint256 tokenID) public view returns (string memory) {
        return IERC721Metadata(nftContract).tokenURI(tokenID);
    }

    function uri(uint256 tokenID) external view returns (string memory) {
        return tokenURI(tokenID);
    }
    
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenOwners.length();
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenID, ) = _tokenOwners.at(index);
        return tokenID;
    }

    function approve(address to, uint256 tokenID) public virtual override {
        address owner = ownerOf(tokenID);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),"ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenID);
    }

    function getApproved(uint256 tokenID) public view override returns (address) {
        require(_exists(tokenID), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenID];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
	function transferToken(address tokenAddress, uint256 tokens) external onlyController {
		ERC20(tokenAddress).transfer(_msgSender(),tokens);
	}
	
	function burnToken(uint256 tokenID) public onlyController {
	    _burn(tokenID);
	}
	
	function transferFrom(address from, address to, uint256 tokenID) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenID), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenID);
    }

    function safeTransferFrom(address from, address to, uint256 tokenID) public virtual override {
        safeTransferFrom(from, to, tokenID, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenID), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenID, _data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenID, uint256 value, bytes memory _data) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenID), "ERC721: transfer caller is not owner nor approved");
        value = 1;
        safeTransferFrom(from, to, tokenID, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenID, bytes memory _data) internal virtual {
        _transfer(from, to, tokenID);
        require(_checkOnERC721Received(from, to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenID) internal view returns (bool) {
        return _tokenOwners.contains(tokenID);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenID) internal view returns (bool) {
        require(_exists(tokenID), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenID);
        return (spender == owner || getApproved(tokenID) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenID) internal virtual {
        _safeMint(to, tokenID, "");
    }

    function _safeMint(address to, uint256 tokenID, bytes memory _data) internal virtual {
        _mint(to, tokenID);
        require(_checkOnERC721Received(address(0), to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenID) internal virtual returns (bool) {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenID), "ERC721: token already minted");

        _holderTokens[to].add(tokenID);

        _tokenOwners.set(tokenID, to);

        emit Transfer(address(this), to, tokenID);
        
        return true;
    }

    function _burn(uint256 tokenID) internal virtual {
        address owner = ownerOf(tokenID);
        _approve(address(0), tokenID);

        if (bytes(idToUri[tokenID]).length != 0) {
            delete idToUri[tokenID];
        }
        if (bytes(idToHash[tokenID]).length != 0) {
            delete idToHash[tokenID];
        }
       
        delete idToProxy[tokenID];
        delete idToCreator[tokenID];
        delete idToTimestamp[tokenID];

        _holderTokens[owner].remove(tokenID);
        _tokenOwners.remove(tokenID);

        emit Transfer(owner, address(0), tokenID);
    }

    function _transfer(address from, address to, uint256 tokenID) internal virtual {
        require(ownerOf(tokenID) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenID);
        _holderTokens[from].remove(tokenID);
        _holderTokens[to].add(tokenID);
        _tokenOwners.set(tokenID, to);

        emit Transfer(from, to, tokenID);
    }

    function setTokenURI(uint256 tokenID,string memory newTokenURI) public onlyController {
        require(_exists(tokenID), "ERC721Metadata: URI set of nonexistent token");
        idToUri[tokenID] = newTokenURI;
        emit URI(newTokenURI,tokenID);
    }

    function setBaseURI(string memory newBaseURI) public onlyController {
        _baseURI = newBaseURI;
    }

    function setContractURI(string memory newContractURI) public onlyController {
        _contractURI = newContractURI;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenID, bytes memory _data) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(IERC721Receiver(to).onERC721Received.selector,_msgSender(),from,tokenID,_data), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenID) private {
        _tokenApprovals[tokenID] = to;
        emit Approval(ownerOf(tokenID), to, tokenID);
    }

	function verifyToken(uint256 tokenID, string calldata fileHash) external view returns (bool) {
		return (keccak256(abi.encodePacked((idToHash[tokenID]))) == keccak256(abi.encodePacked((fileHash))));
	}

	function verifyToken(address nftContract, uint256 tokenID, string calldata fileHash) external view returns (bool) {
        return (Verifications[nftContract][tokenID].verified && keccak256(abi.encodePacked((Verifications[nftContract][tokenID].hash))) == keccak256(abi.encodePacked((fileHash))));
	}

	function tokenHash(uint256 tokenID) external view returns (string memory) {
		return idToHash[tokenID];
	}

	function tokenHash(address nftContract, uint256 tokenID) external view returns (string memory) {
		return Verifications[nftContract][tokenID].hash;
	}
	
	function tokenCreator(uint256 tokenID) external view returns (address) {
		return idToCreator[tokenID];
	}

	function tokenCreator(address nftContract, uint256 tokenID) external view returns (address) {
		return Verifications[nftContract][tokenID].creator;
	}

	function tokenTimestamp(uint256 tokenID) external view returns (uint32) {
		return idToTimestamp[tokenID];
	}

	function tokenTimestamp(address nftContract, uint256 tokenID) external view returns (uint32) {
		return Verifications[nftContract][tokenID].timestamp;
	}

	function tokenProxy(uint256 tokenID) external view returns (address) {
		return idToProxy[tokenID];
	}

	function tokenProvenance(uint256 tokenID) public view returns (address, string memory, uint32, address, string memory) {
		return (idToCreator[tokenID], idToHash[tokenID], idToTimestamp[tokenID], idToProxy[tokenID], tokenURI(tokenID));
	}

	function tokenProvenance(address nftContract, uint256 tokenID) public view returns (address, string memory, uint32, address, string memory) {
		return (Verifications[nftContract][tokenID].creator, Verifications[nftContract][tokenID].hash, Verifications[nftContract][tokenID].timestamp, address(0), tokenURI(nftContract, tokenID));
	}
	
	function verifyHash(string calldata fileHash) external view returns (uint256) {
		return hashToId[fileHash];
	}

	function createNFT(bytes memory data) public whenNotPaused returns (uint256) { 
		require(data.length == 64,"C1 - Invalid hash provided");
		require(verifiedPublishers[msg.sender],"C2 - Unverified publisher address");
		string memory fileHash = string(data);
		require(hashToId[fileHash] == 0,"C3 - NFT exists already");
		
		uint256 nftID = token_number;
        require(_mint(msg.sender,nftID),"C4 - Minting failed");

		idToCreator[nftID] = msg.sender;
		idToHash[nftID] = fileHash;
        idToTimestamp[nftID] = uint32(block.timestamp);
		hashToId[fileHash] = nftID;

		token_number = token_number + 1;

		ListNFT(nftID, fileHash);
		return nftID;
	}

	function createNFT(string calldata fileHash) public whenNotPaused returns (uint256) { 
		require(bytes(fileHash).length >= 32,"C1 - Invalid hash provided");
		require(verifiedPublishers[msg.sender],"C2 - Unverified publisher address");
		require(hashToId[fileHash] == 0,"C3 - NFT exists already");
		
		uint256 nftID = token_number;
        require(_mint(msg.sender,nftID),"C4 - Minting failed");

		idToCreator[nftID] = msg.sender;
		idToHash[nftID] = fileHash;
        idToTimestamp[nftID] = uint32(block.timestamp);
		hashToId[fileHash] = nftID;

		token_number = token_number + 1;

		ListNFT(nftID, fileHash);
		return nftID;
	}
	
	function createNFTbyProxy(bytes memory data) public whenNotPaused onlyTrusted returns (uint256) { 
		require(data.length == 64,"CP1 - Invalid hash provided");
		string memory fileHash = string(data);
		require(hashToId[fileHash] == 0,"CP2 - NFT exists already");
		
		uint256 nftID = token_number;
        require(_mint(tx.origin,nftID),"CP3 - Minting failed");

		idToCreator[nftID] = tx.origin;
		idToProxy[nftID] = msg.sender;
		idToHash[nftID] = fileHash;
        idToTimestamp[nftID] = uint32(block.timestamp);
		hashToId[fileHash] = nftID;

		token_number = token_number + 1;

		ListNFT(nftID, fileHash);
		return nftID;
	}	

	function createNFTbyProxy(string memory fileHash) public whenNotPaused onlyTrusted returns (uint256) { 
		require(bytes(fileHash).length >= 32,"CP1 - Invalid hash provided");
		require(hashToId[fileHash] == 0,"CP2 - NFT exists already");
		
		uint256 nftID = token_number;
        require(_mint(tx.origin,nftID),"CP3 - Minting failed");

		idToCreator[nftID] = tx.origin;
		idToProxy[nftID] = msg.sender;
		idToHash[nftID] = fileHash;
        idToTimestamp[nftID] = uint32(block.timestamp);
		hashToId[fileHash] = nftID;

		token_number = token_number + 1;

		ListNFT(nftID, fileHash);
		return nftID;
	}	

    struct Verification {
        string hash;
        bool verified;
        address creator;
        uint32 timestamp;
    }

	mapping (address => mapping (uint256 => Verification)) private Verifications;
	mapping (address => mapping (uint256 => Verification)) private vidtGAS;
	
	function requestVerification(address nftContract, uint256 tokenID, string memory fileHash) public whenNotPaused payable returns (bool) {
	    require(!Verifications[nftContract][tokenID].verified, "NFT already verified");
	    
	    Verifications[nftContract][tokenID] = Verification({
            hash: fileHash,
            verified: false,
            creator: address(0),
            timestamp: uint32(block.timestamp)
        });
        
        vidtGAS[nftContract][tokenID] = Verifications[nftContract][tokenID];
        
        return true;
	}

	function requestVerification(address nftContract, uint256 tokenID) public whenNotPaused payable returns (bool) {
	    require(!Verifications[nftContract][tokenID].verified, "NFT already verified");
	    
	    Verifications[nftContract][tokenID] = Verification({
            hash: string("123abcdefghijklmnopqrstuvwxyz123456abcdefghijklmnopqrstuvwxyz456"),
            verified: false,
            creator: address(0),
            timestamp: uint32(block.timestamp)
        });
        
        vidtGAS[nftContract][tokenID] = Verifications[nftContract][tokenID];
        
        return true;
	}
	
    function pendingVerification(address nftContract, uint256 tokenID) public view returns (string memory,bool,address,uint32) {
		return (Verifications[nftContract][tokenID].hash, Verifications[nftContract][tokenID].verified, Verifications[nftContract][tokenID].creator, Verifications[nftContract][tokenID].timestamp);
    }

	function approveVerification(address nftContract, uint256 tokenID, address originalCreator, string memory fileHash) public onlyController returns (bool) {
	    Verifications[nftContract][tokenID] = Verification({
            hash: fileHash,
            verified: true,
            creator: originalCreator,
            timestamp: uint32(block.timestamp)
        });
        
        delete vidtGAS[nftContract][tokenID];
        
        return true;
	}

	function denyVerification(address nftContract, uint256 tokenID) public onlyController returns (bool) {
        delete Verifications[nftContract][tokenID];
        delete vidtGAS[nftContract][tokenID];
        
        return true;
	}

	function deployNFT(address Publisher, bytes memory data) onlyController public returns (uint256) { 
	    uint256 nftID = createNFT(data);
        require(nftID > 0 ,"C0 - NFT not created");
        _transfer(msg.sender, Publisher, nftID);        
	    return nftID;
	}
	
	function listNFTs(uint256 startAt, uint256 stopAt) onlyController public returns (bool) {
		for (uint256 i = startAt; i <= stopAt; i++) {
			emit ListNFT(i,idToHash[i]);
		}
		return true;
	}
	
	event ListNFT(uint256 indexed nft, string indexed hash) anonymous;
	event ValidatePublisher(address indexed publisherAddress, bool indexed state, string indexed publisherName);
}