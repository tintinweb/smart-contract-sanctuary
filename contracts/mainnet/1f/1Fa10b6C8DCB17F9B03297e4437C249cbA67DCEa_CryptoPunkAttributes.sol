/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: MIT

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


// File contracts/CryptoPunkAttributes.sol

pragma solidity ^0.8.0;

/**************************/
/***     Interfaces     ***/
/**************************/

interface ICryptoPunksData {
    function punkAttributes(uint16 index)
        external
        view
        returns (string memory text);
}

contract CryptoPunkAttributes is Ownable {

    address internal constant CRYPTO_PUNKS_DATA_ADDR = 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2;

    struct CryptoPunk {
        string species;
        string ears;
        string topHead;
        string eyes;
        string neck;
        string face;
        string mouth;
        string mouthAccessory;
        string facialHair;
    }

    mapping(uint256 => CryptoPunk) internal _punkIdToAttributes;

    mapping(uint256 => address) private _creators;

    mapping(string => uint) private _attributesToCategoryIndex;

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    /**
     * Strings Library (author James Lockhart: james at n3tw0rk.co.uk)
     *
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
        function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }
    
    /**
     * Strings Library (author James Lockhart: james at n3tw0rk.co.uk)
     * 
     * Modified String Split:
     * String splitByComaAndSpace
     *
     * Splits a string into an array of strings based off the delimiter value, in this case ",".
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string value to be split.
     * 
     * @return splitArr
     */
        function _splitByComaAndSpace(string memory _base) internal pure returns (string[] memory splitArr) {
            bytes memory _baseBytes = bytes(_base);
            string memory _value = ",";
            
            uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);
        
        _offset = 0;
        _splitsCount = 0;
        
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int(_baseBytes.length);
            }
            
            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);
            
            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            
            _offset = uint(_limit) + 2;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
        }


    /**************************/
    /***  Public Functions  ***/
    /**************************/

    function exists(uint256 tokenId) public view returns (bool) {
        return _creators[tokenId] != address(0);
    }

    function createStructForPunk(uint punkIndex) public {
        require(!exists(punkIndex), "Crypto Punks Attributes: There are already attributes stored for the Punk you are requesting");
        require(punkIndex >= 0 && punkIndex < 10000, "Crypto Punks Attributes: You have to enter a Punk Index between 0 and 9999");
        string memory punkAttributes = ICryptoPunksData(CRYPTO_PUNKS_DATA_ADDR).punkAttributes(uint16(punkIndex));

        string[] memory punkAttributesArray = _splitByComaAndSpace(punkAttributes);

        CryptoPunk memory thisCryptoPunk;

        thisCryptoPunk.topHead;

        thisCryptoPunk.species = punkAttributesArray[0];

        for (uint i = 1; i < punkAttributesArray.length; i++) {

            uint attributeCategoryIndex = _attributesToCategoryIndex[punkAttributesArray[i]];
            
            if (attributeCategoryIndex == 1) {
                thisCryptoPunk.ears = punkAttributesArray[i];
            } 
            else if (attributeCategoryIndex == 2) {
                thisCryptoPunk.topHead = punkAttributesArray[i];
            } 
            else if (attributeCategoryIndex == 3) {
                thisCryptoPunk.eyes = punkAttributesArray[i];
            } 
            else if (attributeCategoryIndex == 4) {
                thisCryptoPunk.neck = punkAttributesArray[i];
            } 
            else if (attributeCategoryIndex == 5) {
                thisCryptoPunk.face = punkAttributesArray[i];
            } 
            else if (attributeCategoryIndex == 6) {
                thisCryptoPunk.mouth = punkAttributesArray[i];
            } 
            else if (attributeCategoryIndex == 7) {
                thisCryptoPunk.mouthAccessory = punkAttributesArray[i];
            }
            else if (attributeCategoryIndex == 8) {
                thisCryptoPunk.facialHair = punkAttributesArray[i];
            }
            }

        _punkIdToAttributes[punkIndex] = thisCryptoPunk;
        _creators[punkIndex] = msg.sender;
    }

    function getAttributeSpeciesFrom(uint punkIndex) public view returns (string memory attribute) {
        require(exists(punkIndex), "Crypto Punks Attributes: There aren't any attributes stored for the Punk you are requesting");
        return _punkIdToAttributes[punkIndex].species;
    }

    function getAttributeTopHeadFrom(uint punkIndex) public view returns (string memory attribute) {
        require(exists(punkIndex), "Crypto Punks Attributes: There aren't any attributes stored for the Punk you are requesting");
        return _punkIdToAttributes[punkIndex].topHead;
    }

    function getAttributeEyesFrom(uint punkIndex) public view returns (string memory attribute) {
        require(exists(punkIndex), "Crypto Punks Attributes: There aren't any attributes stored for the Punk you are requesting");
        return _punkIdToAttributes[punkIndex].eyes;
    }

    function getAttributeEarsFrom(uint punkIndex) public view returns (string memory attribute) {
        require(exists(punkIndex), "Crypto Punks Attributes: There aren't any attributes stored for the Punk you are requesting");
        return _punkIdToAttributes[punkIndex].ears;
    }

    function getAttributeNeckFrom(uint punkIndex) public view returns (string memory attribute) {
        require(exists(punkIndex), "Crypto Punks Attributes: There aren't any attributes stored for the Punk you are requesting");
        return _punkIdToAttributes[punkIndex].neck;
    }

    function getAttributeFaceFrom(uint punkIndex) public view returns (string memory attribute) {
        require(exists(punkIndex), "Crypto Punks Attributes: There aren't any attributes stored for the Punk you are requesting");
        return _punkIdToAttributes[punkIndex].face;
    }

    function getAttributeMouthFrom(uint punkIndex) public view returns (string memory attribute) {
        require(exists(punkIndex), "Crypto Punks Attributes: There aren't any attributes stored for the Punk you are requesting");
        return _punkIdToAttributes[punkIndex].mouth;
    }

    function getAttributeMouthAccessoryFrom(uint punkIndex) public view returns (string memory attribute) {
        require(exists(punkIndex), "Crypto Punks Attributes: There aren't any attributes stored for the Punk you are requesting");
        return _punkIdToAttributes[punkIndex].mouthAccessory;
    }

    function getAttributeFacialHairFrom(uint punkIndex) public view returns (string memory attribute) {
        require(exists(punkIndex), "Crypto Punks Attributes: There aren't any attributes stored for the Punk you are requesting");
        return _punkIdToAttributes[punkIndex].facialHair;
    }

    function setCategoryIndex(string memory attribute, uint categoryIndex) public onlyOwner {
        _attributesToCategoryIndex[attribute] = categoryIndex;
    }

    constructor() Ownable() {}
}