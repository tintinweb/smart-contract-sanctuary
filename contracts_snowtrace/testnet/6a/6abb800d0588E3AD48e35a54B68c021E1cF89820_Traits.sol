/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT LICENSE

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

/**
 * @dev String operations.
 */
library Strings {

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    function concat(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }
}

interface IMonstersAndHunters {

    // struct to store each token's traits
    struct Trait {
        bool isHunters;
        uint8 gen;
        uint8[] traits;
    }

    function getTokenTraits(uint256 tokenId) external view returns (Trait memory);
}

contract Traits is Ownable {

    using Strings for uint;
    using Strings for string;

    uint8 public alphaTypeIndex = 8;

    string public IPFSBaseURL;

    mapping(uint => uint8) public huntersTraitCountForType;
    mapping(uint => uint8) public monstersTraitCountForType;

    mapping(uint => uint) public multiplierIndexForHuntersTraitType;
    mapping(uint => uint) public multiplierIndexForMonstersTraitType;

    uint public firstMonstersIndex;
    uint public huntersTraitsNumber = 7;
    uint public monstersTraitsNumber = 8;

    IMonstersAndHunters public MonstersAndHunters;

    function selectHuntersTrait(uint16 seed, uint8 traitType) external view returns(uint8) {
         uint8 modOf = huntersTraitCountForType[traitType] > 0 ? huntersTraitCountForType[traitType] : 10;
        return uint8(seed % modOf);
    }

    function selectMonstersTrait(uint16 seed, uint8 traitType) external view returns(uint8) {
        if (traitType == alphaTypeIndex) {
            uint256 m = seed % 100;
            if (m > 95) {
                return 0;
            } else if (m > 80) {
                return 1;
            } else if (m > 50) {
                return 2;
            } else {
                return 3;
            }
        }
        uint8 modOf = monstersTraitCountForType[traitType] > 0 ? monstersTraitCountForType[traitType] : 10;
        return uint8(seed % modOf);
    }

    function setHuntersTraitCountForType(uint8[] memory _len) public onlyOwner {
        require(_len.length == huntersTraitsNumber);
        uint multiplier = 1;
        uint total = 1;

        for (uint i = 0; i < _len.length; i++) {
            huntersTraitCountForType[i] = _len[i];
            
            multiplierIndexForHuntersTraitType[i] = multiplier;
            multiplier = multiplier *= huntersTraitCountForType[i];
            total *= huntersTraitCountForType[i];
        }

        firstMonstersIndex = total;
    }

    function setMonstersTraitCountForType(uint8[] memory _len) public onlyOwner {
        require(_len.length == monstersTraitsNumber);
        uint multiplier = 1;

        for (uint i = 0; i < _len.length; i++) {
            monstersTraitCountForType[i] = _len[i];
            
            multiplierIndexForMonstersTraitType[i] = multiplier;
            multiplier = multiplier *= monstersTraitCountForType[i];
        }
    }

    function getIndexFromTokenId(uint _tokenId) public view returns (uint index) {
        index = getIndexFromTraits(MonstersAndHunters.getTokenTraits(_tokenId).isHunters, MonstersAndHunters.getTokenTraits(_tokenId).traits);
    }

    function getIndexFromStructTrait(IMonstersAndHunters.Trait memory _trait) public view returns (uint index) {
        index = getIndexFromTraits(_trait.isHunters, _trait.traits);
    }

    /**
        @notice retreive the unique index of traits and side (hunters or monsters)
        @param _isHunters Side of token
        @param _traits All the token traits (be careful to take hunters or monsters traits)
        @return index
    */
    function getIndexFromTraits(bool _isHunters, uint8[] memory _traits) public view returns (uint index) {
        if (_isHunters) {
            for (uint i = 0; i < _traits.length; i++) {
                index += _traits[i] * multiplierIndexForHuntersTraitType[i];
            }
        } else {
            index = firstMonstersIndex;

            for (uint i = 0; i < _traits.length; i++) {
                index += _traits[i] * multiplierIndexForMonstersTraitType[i];
            }
        }
    }

    /**
        @notice get the traits and the side (hunters or monsters) of a token (by its unique index)
        @param _index Nft index (!= tokenId)
        @return bool Is this token (index) a hunters ?
        @return uint[] List of all traits of this token (index)
    */
    function getTraitsFromIndex(uint _index) public view returns (bool, uint[] memory) {
        uint id;
        bool isHunters;

        if (_index < firstMonstersIndex) {
            isHunters = true;
            uint[] memory _traits = new uint[](huntersTraitsNumber);

            for (uint i = 0; i < huntersTraitsNumber; i++) {
                id = huntersTraitsNumber - i - 1; // get the id from the end
                _traits[id] = uint(_index / multiplierIndexForHuntersTraitType[id]);
                _index -= uint(_index / multiplierIndexForHuntersTraitType[id]) * multiplierIndexForHuntersTraitType[id];
            }

            return (isHunters, _traits);
        } else {
            _index -= firstMonstersIndex;
            uint[] memory _traits = new uint[](monstersTraitsNumber);

            for (uint i = 0; i < monstersTraitsNumber; i++) {
                id = monstersTraitsNumber - i - 1; // get the id from the end
                _traits[id] = uint(_index / multiplierIndexForMonstersTraitType[id]);
                _index -= uint(_index / multiplierIndexForMonstersTraitType[id]) * multiplierIndexForMonstersTraitType[id];
            }

            return (isHunters, _traits);
        }
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return IPFSBaseURL.concat(getIndexFromTokenId(tokenId).toString());
    }

    /***ADMIN */

    function setIPFSBaseURL(string memory _url) external onlyOwner {
        IPFSBaseURL = _url;
    }

    function setGame(address _MonstersAndHunters) external onlyOwner {
        MonstersAndHunters = IMonstersAndHunters(_MonstersAndHunters);
    }
}