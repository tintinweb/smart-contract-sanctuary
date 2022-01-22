/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-22
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
        uint8 power;
        uint id;
    }

    function getTokenTraits(uint256 tokenId) external view returns (Trait memory);
}

contract Traits is Ownable {

    using Strings for uint;
    using Strings for string;

    uint8 public constant MAX_POWER = 4;

    string public IPFSBaseURL;
    string public IPFSLastURL;
    uint public totalIdNumber; // total number of unique nft
    uint public totalMonstersNumber; // total number of unique monsters nft
    uint public firstPowerHuntersNumber; // first power (3) index 
    uint public secondPowerHuntersNumber; // second power (2) index 
    uint public thirdPowerHuntersNumbers; // third power (1) index 
    uint public fourthPowerHuntersNumbers; // fourth power (0) index 

    IMonstersAndHunters public MonstersAndHunters;

    // return (isMonster?, power score and index)
    function selectRandomId(uint16 seed) external view returns(bool isMonster, uint8 power, uint id) {
        id = (seed % (totalIdNumber+1)) + 1;
        if (id <= totalMonstersNumber) {
            isMonster = true;
        } else {
            if (id >= firstPowerHuntersNumber) {
                power = 3;
            } else if (id >= secondPowerHuntersNumber) {
                power = 2;
            } else if (id >= thirdPowerHuntersNumbers) {
                power = 1;
            } else if (id >= fourthPowerHuntersNumbers) {
                power = 0;
            }
        }
    }

    function getIndexFromTokenId(uint _tokenId) public view returns (uint) {
        return MonstersAndHunters.getTokenTraits(_tokenId).id;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return IPFSBaseURL.concat(getIndexFromTokenId(tokenId).toString()).concat(IPFSLastURL);
    }

    /***ADMIN */

    function setCollectionsNumbers(uint _totalIdNumber, uint _totalMonstersNumber, uint _firstPowerHuntersNumber, uint _secondPowerHuntersNumber, uint _thirdPowerHuntersNumbers, uint _fourthPowerHuntersNumbers) external onlyOwner {
        totalIdNumber = _totalIdNumber;
        totalMonstersNumber = _totalMonstersNumber;
        firstPowerHuntersNumber = _firstPowerHuntersNumber;
        secondPowerHuntersNumber = _secondPowerHuntersNumber;
        thirdPowerHuntersNumbers = _thirdPowerHuntersNumbers;
        fourthPowerHuntersNumbers = _fourthPowerHuntersNumbers;
    }

    function setIPFSBaseURL(string memory _url) external onlyOwner {
        IPFSBaseURL = _url;
    }

    function setIPFSLastURL(string memory _url) external onlyOwner {
        IPFSLastURL = _url;
    }

    function setGame(address _MonstersAndHunters) external onlyOwner {
        MonstersAndHunters = IMonstersAndHunters(_MonstersAndHunters);
    }
}