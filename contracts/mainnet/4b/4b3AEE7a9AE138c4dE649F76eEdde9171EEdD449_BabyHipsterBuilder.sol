// File @openzeppelin/contracts/utils/[email protected]

/// [MIT License]

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


// File @openzeppelin/contracts/access/[email protected]

/// [MIT License]

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


// File contracts/BabyHipsterBuilder.sol

//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICryptoPunksAttributes {
    function exists(uint256 tokenId) external view returns (bool);

    function createStructForPunk(uint punkIndex) external;

    function getAttributeSpeciesFrom(uint punkIndex) external view returns (string memory attribute);

    function getAttributeTopHeadFrom(uint punkIndex) external view returns (string memory attribute);

    function getAttributeEyesFrom(uint punkIndex) external view returns (string memory attribute);

    function getAttributeEarsFrom(uint punkIndex) external view returns (string memory attribute);

    function getAttributeNeckFrom(uint punkIndex) external view returns (string memory attribute);

    function getAttributeFaceFrom(uint punkIndex) external view returns (string memory attribute);

    function getAttributeMouthFrom(uint punkIndex) external view returns (string memory attribute);

    function getAttributeMouthAccessoryFrom(uint punkIndex) external view returns (string memory attribute);

    function getAttributeFacialHairFrom(uint punkIndex) external view returns (string memory attribute);
}

contract BabyHipsterBuilder is Ownable {

    address internal cryptoPunksAttributesAddr;
    address internal babyHipstersAddr;

    struct Attribute {
        uint256 id;
        string name;
        string svg;
    }

    Attribute[] internal attributes;

    mapping(string => uint256) internal _attributeNameToId;
    
    mapping (string => uint) internal _speciesToCode;

    string[] private speciesList = [
        "Human Albino",
        "Human Light",
        "Human Mid",
        "Human Dark",
        "Human Ape Albino",
        "Human Ape Light",
        "Human Ape Mid",
        "Human Ape Dark",
        "Ape",
        "Human Alien Albino",
        "Human Alien Light",
        "Human Alien Mid",
        "Human Alien Dark",
        "Alien Ape",
        "Human Zombie Albino",
        "Human Zombie Light",
        "Human Zombie Mid",
        "Human Zombie Dark",
        "Zombie Ape",
        "Zombie",
        "Alien",
        "Wildcard 1",
        "Wildcard 2",
        "Zombie Alien" 
    ];

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function setCPAttributesAddr(address contractAddr) public onlyOwner{
        cryptoPunksAttributesAddr = contractAddr;
    }

    function setBabyHipstersAddr(address contractAddr) public onlyOwner{
        babyHipstersAddr = contractAddr;
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function random(string memory input) 
    internal 
    pure 
    returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /**
     * @notice Create an Attribute
     * @param _name the name of the attribute
     * @param _svg svg representation of the attribute
     * @return attributeId the token ID of the newly created attribute
     */
    function createAttribute(
        string calldata _name,
        string calldata _svg
    )
    external 
    onlyOwner
    returns (uint256 attributeId)
    {
        require(bytes(_name).length > 0, "BabyHipsterBuilder: Name can't be empty");

        attributeId = attributes.length;

        attributes.push(
            Attribute(attributeId, _name, _svg)
        );

        _attributeNameToId[_name] = attributeId;

        return attributeId;
    }

    function calculateBabySpecies(
        uint256 tokenId, 
        string memory parent1Species, 
        string memory parent2Species
    ) 
        internal 
        view 
        returns (string memory) 
    {
        uint256 rand = random(string(abi.encodePacked(tokenId, parent1Species, parent2Species)));
        
        uint256 babyHipsterSpeciesIndex;

        uint256 parent1SpeciesCode = _speciesToCode[parent1Species];
        uint256 parent2SpeciesCode = _speciesToCode[parent2Species];
        
        uint256 tieBreak = rand % 2;

        if (parent1SpeciesCode < 7 && parent2SpeciesCode < 7) {
            if ((parent1SpeciesCode + parent2SpeciesCode) % 4 != 0) {
                uint256 temp = (parent1SpeciesCode + parent2SpeciesCode) / 4;
                babyHipsterSpeciesIndex = temp + tieBreak;
            } else {
                babyHipsterSpeciesIndex = (parent1SpeciesCode + parent2SpeciesCode) / 4;
            }
        } else {
            babyHipsterSpeciesIndex = (parent1SpeciesCode + parent2SpeciesCode) / 2;
        }
        
        return speciesList[babyHipsterSpeciesIndex];
    }
    
    function getGenes(uint256 tokenId, string memory categoryName) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(uint2str(tokenId), categoryName)));
        uint256 randomOption = rand % 100;
        if (randomOption < 50) {
            return 0; // For making the gene recessive
        } else {
            return 1; // For making the gene recessive
        }
    }
    
    function pickAttribute(
        uint256 tokenId, 
        string memory categoryName, 
        string memory attribute1, 
        string memory attribute2
    ) 
        internal 
        pure 
        returns (string memory) 
    {
            uint256 rand = getGenes(tokenId, categoryName);
            if (keccak256(abi.encodePacked(attribute1)) == keccak256(abi.encodePacked(attribute2))) {
                return attribute1;
            } else {
                if (rand == 0) {
                    return attribute1;
                } else {
                    return attribute2;
                }
            }
    }

    function buildBabyHipster(uint256 tokenId, uint256 parent1, uint256 parent2) 
        public 
        returns (string[9] memory thisBabyHipsterAttributes) 
    {
        if (!ICryptoPunksAttributes(cryptoPunksAttributesAddr).exists(parent1)) {
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).createStructForPunk(parent1);
        }

        if (!ICryptoPunksAttributes(cryptoPunksAttributesAddr).exists(parent2)) {
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).createStructForPunk(parent2);
        }

        string memory parent1Species = ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeSpeciesFrom(parent1);
        string memory parent2Species = ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeSpeciesFrom(parent2);

        thisBabyHipsterAttributes[0] = calculateBabySpecies(tokenId, parent1Species, parent2Species);

        thisBabyHipsterAttributes[1] = pickAttribute(
            tokenId,
            "Ears",
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeEarsFrom(parent1),
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeEarsFrom(parent2));

        thisBabyHipsterAttributes[2] = pickAttribute(
            tokenId,
            "Top Head",
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeTopHeadFrom(parent1),
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeTopHeadFrom(parent2));
        
        thisBabyHipsterAttributes[3] = pickAttribute(
            tokenId,
            "Eyes",
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeEyesFrom(parent1),
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeEyesFrom(parent2));

        thisBabyHipsterAttributes[4] = pickAttribute(
            tokenId,
            "Neck",
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeNeckFrom(parent1),
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeNeckFrom(parent2));

        thisBabyHipsterAttributes[5] = pickAttribute(
            tokenId,
            "Face",
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeFaceFrom(parent1),
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeFaceFrom(parent2));

        thisBabyHipsterAttributes[6] = pickAttribute(
            tokenId,
            "Mouth",
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeMouthFrom(parent1),
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeMouthFrom(parent2));

        thisBabyHipsterAttributes[7] = pickAttribute(
            tokenId,
            "Mouth Accessory",
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeMouthAccessoryFrom(parent1),
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeMouthAccessoryFrom(parent2));

        thisBabyHipsterAttributes[8] = pickAttribute(
            tokenId,
            "Facial Hair",
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeFacialHairFrom(parent1),
            ICryptoPunksAttributes(cryptoPunksAttributesAddr).getAttributeFacialHairFrom(parent2));

        return thisBabyHipsterAttributes;
    }

    
    function buildBabyHipsterImage(string[9] memory thisBabyHipsterAttributes) public view returns (string memory svg) {
        string[10] memory parts;
        parts[0] = "<svg xmlns='http://www.w3.org/2000/svg' version='1.2' viewBox='0 0 24 24' shape-rendering='crispEdges'>";
        parts[1] = attributes[_attributeNameToId[thisBabyHipsterAttributes[0]]].svg;
        parts[2] = attributes[_attributeNameToId[thisBabyHipsterAttributes[1]]].svg;
        parts[3] = attributes[_attributeNameToId[thisBabyHipsterAttributes[2]]].svg;
        parts[4] = attributes[_attributeNameToId[thisBabyHipsterAttributes[3]]].svg;
        parts[5] = attributes[_attributeNameToId[thisBabyHipsterAttributes[4]]].svg;
        parts[6] = attributes[_attributeNameToId[thisBabyHipsterAttributes[5]]].svg;
        parts[7] = attributes[_attributeNameToId[thisBabyHipsterAttributes[6]]].svg;
        parts[8] = attributes[_attributeNameToId[thisBabyHipsterAttributes[7]]].svg;     
        parts[9] = "</svg>";

        svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9]));

        return svg;
    }
    
    /**************************/
    /***  Public Functions  ***/
    /**************************/

    function setSpeciesToCode(string memory thisSpecies, uint thisCode) public onlyOwner {
        _speciesToCode[thisSpecies] = thisCode;
    }

    constructor() Ownable() {}
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

