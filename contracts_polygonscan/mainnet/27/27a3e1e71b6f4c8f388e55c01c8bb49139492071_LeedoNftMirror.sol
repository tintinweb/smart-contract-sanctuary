/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol



pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
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

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}   


// File: contracts/LeedoNftMirror.sol



pragma solidity ^0.8.0;

/**
 * @dev LEEDO NFT Mirror
 *
 *  _              ______      
 * | |             |  _  \     
 * | |     ___  ___| | | |___  
 * | |    / _ \/ _ \ | | / _ \ 
 * | |___|  __/  __/ |/ / (_) |
 * \_____/\___|\___|___/ \___/ 
 * LEEDO Project
 */

contract LeedoNftMirror is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet; 
    
    string[15] private simpleConsonants = [
        "&#12593;", //0 ㄱ 
        "&#12596;", //1 ㄴ 
        "&#12599;", //2 ㄷ 
        "&#12601;", //3 ㄹ
        "&#12609;", //4 ㅁ
        "&#12610;", //5 ㅂ
        "&#12613;", //6 ㅅ
        "&#12615;", //7 o 
        "&#12616;", //8 ㅈ
        "&#12618;", //9 ㅊ
        "&#12619;", //10 ㅋ        
        "&#12620;", //11 ㅌ
        "&#12621;", //12 ㅍ
        "&#12622;", //13 ㅎ
        "&#12671;"  //14 triangle
    ];
    uint8[7] private baseGenes = [0, 1, 2, 3, 4, 5, 6];
    uint8 private constant _PICKSIZE = 10;
    uint public totalSupply;
    mapping(address => EnumerableSet.UintSet) private _tokensOf; //owner address => tokenIds
    mapping(uint => address) private _ownerOf; //tokenId => owner address
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {
        //_unpause();
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }    
    
    function add(uint[] calldata _tokenIds, address[] calldata _addrs) external onlyOwner {
        require(_tokenIds.length == _addrs.length, "TokenIds and Addrs'size do not match");
        for(uint i=0; i<_tokenIds.length; i++) {
            require(_ownerOf[_tokenIds[i]] == address(0), 'NftMirror: Existing tokendId');
            _ownerOf[_tokenIds[i]] = _addrs[i];
            _tokensOf[_addrs[i]].add(_tokenIds[i]);
            totalSupply += 1;
            emit Transfer(address(0), _addrs[i], _tokenIds[i]);
        }                
    } 

    function remove(uint[] calldata _tokenIds) external onlyOwner {
        for(uint i=0; i<_tokenIds.length; i++) {
            address owner = _ownerOf[_tokenIds[i]];
            if (owner != address(0)) {
                delete _ownerOf[_tokenIds[i]];
                _tokensOf[owner].remove(_tokenIds[i]);
                totalSupply -= 1;
                emit Transfer(owner, address(0), _tokenIds[i]);
            }
        }  
    }
    
    function transfer(address _from, address _to, uint _tokenId) public onlyOwner returns (bool) {
        _ownerOf[_tokenId] = _to;
        _tokensOf[_to].add(_tokenId);
        _tokensOf[_from].remove(_tokenId);
        emit Transfer(_from, _to, _tokenId);
        return true;
    }
    
    function bulkTransfer(address[] calldata _froms, address[] calldata _tos, uint[] calldata _tokenIds) external onlyOwner {
        for(uint i=0; i<_tokenIds.length; i++) { 
            require(transfer(_froms[i], _tos[i], _tokenIds[i]), '');
        }
    }
    
    function ownerOf(uint _tokenId) external view whenNotPaused returns (address) {
        return _ownerOf[_tokenId];
    }
    
    function tokensOf(address _addr) external view whenNotPaused returns (uint256[] memory) {
        EnumerableSet.UintSet storage tokenSet = _tokensOf[_addr];
        uint256[] memory tokenIds = new uint256[] (tokenSet.length());
        
        for (uint256 i; i < tokenSet.length(); i++) {
            tokenIds[i] = tokenSet.at(i);
        }
        return tokenIds;
    }
    
    function balanceOf(address _addr) external view whenNotPaused returns (uint) {
        return _tokensOf[_addr].length();
    }

    function genSeed(uint _tokenId) private pure returns (uint) {
        return uint256(keccak256(abi.encodePacked(_tokenId)));
    } 
    
    function getRand(uint _seed, uint _prefix) private pure returns (uint) {
        return uint256(keccak256(abi.encodePacked(_seed, _prefix)));
    }

    function getGenes(uint256 _tokenId) public pure returns (uint8[8] memory) {

        uint8[8] memory genes;
        uint seed = genSeed(_tokenId);
        uint number = getRand(seed, 20211009);

        for (uint8 i=0; i<8; i++) {
            uint8 output = uint8(number % 8);
            uint greatness = getRand(number, i) % 21;
            if (greatness > 16) {
                output += 1;
            } 
            if (greatness > 17) {
                output += 1;
            }
            if (greatness > 18) {
                output += 1;
            }
            if (output > 9) {
                output = 9;
            }            
            genes[i] = output;
            number = number / 10;
        }        
        return genes;
    }

    function getConsonants(uint256 _tokenId) public view returns (string[3] memory) {
    
        uint8[3] memory idx = getConsonantsIndex(_tokenId);
        string[3] memory consArray;
        consArray[0] = simpleConsonants[idx[0]];
        consArray[1] = simpleConsonants[idx[1]];
        consArray[2] = simpleConsonants[idx[2]];
        return consArray;
    }

    function getConsonantsIndex(uint256 _tokenId) public view returns (uint8[3] memory) {
        
        uint8[3] memory consArray;
        uint seed = genSeed(_tokenId);
        require(seed != 0);
        uint q = getRand(seed, 3) % 4;
        if (_tokenId <= _PICKSIZE || q == 0) {
            consArray[0] = 7;
            consArray[1] = 14;
            consArray[2] = 4; 
        } else {
            consArray[0] = uint8(getRand(seed, 11) % simpleConsonants.length);
            consArray[1] = uint8(getRand(seed, 12) % simpleConsonants.length);
            consArray[2] = uint8(getRand(seed, 13) % simpleConsonants.length);
        }
        return consArray;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        
        string[9] memory parts;
        string[27] memory attrParts;
        string memory ojingeo;
        string memory sameConsonants;
        uint8[8] memory geneArray = getGenes(_tokenId);
        string[3] memory consArray = getConsonants(_tokenId);
        uint8[3] memory consIndex = getConsonantsIndex(_tokenId);        
        if (consIndex[0] == 7 && consIndex[1] == 14 && consIndex[2] == 4) {
            ojingeo = 'Y';
        } else {
            ojingeo = 'N';
        }
        if (consIndex[0] == consIndex[1] && consIndex[0] == consIndex[2]) {
            sameConsonants = 'Y';
        } else {
            sameConsonants = 'N';
        }

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 220">';
        parts[1] = '<style>.base {font-family: Verdana; fill: white;}</style>';
        parts[2] = '<rect width="100%" height="100%" fill="#5A2C99" />';
        parts[3] = '<text x="50%" y="100" dominant-baseline="middle" text-anchor="middle" class="base" style="font-size:700%; letter-spacing: -0.2em;">';
        parts[4] = string(abi.encodePacked(consArray[0], ' ', consArray[1], ' ', consArray[2]));
        parts[5] = '</text><text x="50%" y="180" dominant-baseline="middle" text-anchor="middle" class="base" style="font-size:150%;">&#937; ';
        parts[6] = string(abi.encodePacked(toString(geneArray[0]), toString(geneArray[1]), toString(geneArray[2]), toString(geneArray[3]), ' '));
        parts[7] = string(abi.encodePacked(toString(geneArray[4]), toString(geneArray[5]), toString(geneArray[6]), toString(geneArray[7]) ));
        parts[8] ='</text></svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));

        attrParts[0] = '[{"trait_type": "Left Consonant", "value": "';
        attrParts[1] = consArray[0];
        attrParts[2] = '"}, {"trait_type": "Center Consonant", "value": "';
        attrParts[3] = consArray[1];
        attrParts[4] = '"}, {"trait_type": "Right Consonant", "value": "';        
        attrParts[5] = consArray[2];
        attrParts[6] = '"}, {"trait_type": "Gene0", "value": "';
        attrParts[7] = toString(geneArray[0]);
        attrParts[8] = '"}, {"trait_type": "Gene1", "value": "';
        attrParts[9] = toString(geneArray[1]);
        attrParts[10] = '"}, {"trait_type": "Gene2", "value": "';        
        attrParts[11] = toString(geneArray[2]);
        attrParts[12] = '"}, {"trait_type": "Gene3", "value": "';        
        attrParts[13] = toString(geneArray[3]);
        attrParts[14] = '"}, {"trait_type": "Gene4", "value": "';        
        attrParts[15] = toString(geneArray[4]);
        attrParts[16] = '"}, {"trait_type": "Gene5", "value": "';        
        attrParts[17] = toString(geneArray[5]);
        attrParts[18] = '"}, {"trait_type": "Gene6", "value": "';        
        attrParts[19] = toString(geneArray[6]);
        attrParts[20] = '"}, {"trait_type": "Gene7", "value": "';        
        attrParts[21] = toString(geneArray[7]);
        attrParts[22] = '"}, {"trait_type": "Ojingeo", "value": "';        
        attrParts[23] = ojingeo;
        attrParts[24] = '"}, {"trait_type": "Same Consonants", "value": "';        
        attrParts[25] = sameConsonants;
        attrParts[26] = '"}]';
        
        string memory attrs = string(abi.encodePacked(attrParts[0], attrParts[1], attrParts[2], attrParts[3], attrParts[4], attrParts[5], attrParts[6], attrParts[7]));
        attrs = string(abi.encodePacked(attrs, attrParts[8], attrParts[9], attrParts[10], attrParts[11], attrParts[12], attrParts[13], attrParts[14]));        
        attrs = string(abi.encodePacked(attrs, attrParts[15], attrParts[16], attrParts[17], attrParts[18], attrParts[19], attrParts[20]));        
        attrs = string(abi.encodePacked(attrs, attrParts[21], attrParts[22], attrParts[23], attrParts[24], attrParts[25], attrParts[26]));        

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Mirror Squid Game Card NFT #', toString(_tokenId), '", "attributes": ', attrs ,', "description": "The squid game cards are invitation to enter the adventurous and mysterious metaverse games. Genes characteristics and other functionality are intentionally omitted for unlimited imagination and community-driven game development. Start your journey now!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
}