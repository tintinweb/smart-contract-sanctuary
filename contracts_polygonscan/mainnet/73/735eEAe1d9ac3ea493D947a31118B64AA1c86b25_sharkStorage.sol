/**
 *Submitted for verification at polygonscan.com on 2021-12-11
*/

// File: base64-sol/base64.sol



pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
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

// File: contracts/teststore.sol


pragma solidity ^0.8.0;



contract sharkCoordinatorInterface {

   function getFinalDNA(uint tokenId)view public returns (uint256[10] memory) {}
   function tokenCounter() view public returns (uint256) {}

}

contract sharkStorage is Ownable {
    
 
    
    sharkCoordinatorInterface coordinatorContract;

    function setSharkTokenAddress(address _address) onlyOwner public {
        coordinatorContract = sharkCoordinatorInterface(_address);            
    }
  
    uint256 baseTraitCounter = 0;
    uint256 public colorTraitCounter = 0;
    
    uint256 public headTraitCounter = 1;
    uint256 public clothingTraitCounter = 1;
    uint256 public eyeTraitCounter = 1;
    uint256 public mouthTraitCounter = 1;
    uint256 public leftFinTraitCounter = 1;
    uint256 public rightFinTraitCounter = 1;
    uint256 public extraTraitCounter = 1;
    uint256 public metaTraitCounter = 1;
    uint256 public neckTraitCounter = 1;
    uint256 public svgPartCounter = 0;
    

    

//There are other Public Functions needed for Shark Reveal, in the Weight Contract
//The functions needed for Reveal define CSS Styles for the Base, and Paths and Styles Both for the Traits
//idToSVGPart[0] -> ColorTraits -> idToSVGPart[1] -> SharkBase -> Traits -> idToSVGPart[2]

    
    
//---------    
//SVG Traits Code, Inserted Into SVG Code During Assembly

      struct SVGPart {
        uint256 _partId;
        string _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
    } mapping(uint256 => SVGPart) public idToSVGPart;
    
    function setSVGPart(string memory _partName, string memory _svgCode) onlyOwner public {
    
    uint _partId = svgPartCounter;
    svgPartCounter = svgPartCounter+ 1;
    
    idToSVGPart[_partId] =  SVGPart(
      _partId,
      "N/A",
      "SVG Part",
      _partName,
      _svgCode
    );
}
    
  

    //---------
    //Color Trait Style Code for Base Paths, Inserted Into SVG Code During Assembly

    struct ColorTrait {
        uint256 _traitId;
        string  _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
    } mapping(uint256 => ColorTrait) public idToColorTrait;
    
    function setColorTrait(string memory _rarity, string memory _colorName, string memory _svgCode) onlyOwner public {
    
    uint _traitId = colorTraitCounter;
    colorTraitCounter = colorTraitCounter + 1;
    
    idToColorTrait[_traitId] =  ColorTrait(
      _traitId,
      _rarity,
      "Color",
      _colorName,
      _svgCode
    );
}
   
    //---------
    //Extra Paths Code, Inserted Into SVG Code During Assembly
    //Uses In-Line Styles to Prevent Inserting Two Separate Strings
    //Needs SVG Code and Metadata inserted into contract after deployment

    struct HeadTrait {
        uint256 _traitId;
        string _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
        
    } mapping(uint256 => HeadTrait) public idToHeadTrait;
    
    function setHeadTrait(string memory _rarity, string memory _traitSet, string memory _headName, string memory _svgCode) onlyOwner public {
    
    uint _traitId = headTraitCounter;
    headTraitCounter = headTraitCounter + 1;
    
    idToHeadTrait[_traitId] =  HeadTrait(
      _traitId,
      _rarity,
      _traitSet,
      _headName,
      _svgCode
    );
}
     
    struct ClothingTrait {
        uint256 _traitId;
        string _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
} mapping(uint256 => ClothingTrait) public idToClothingTrait;

    function setClothingTrait(string memory _rarity, string memory _traitSet, string memory _clothingName, string memory _svgCode) onlyOwner public {
    
    uint _traitId = clothingTraitCounter;
    clothingTraitCounter = clothingTraitCounter + 1;
    
    idToClothingTrait[_traitId] =  ClothingTrait(
      _traitId,
      _rarity,
      _traitSet,
      _clothingName,
      _svgCode
    );
}
     
    struct EyeTrait {
        uint256 _traitId;
        string _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
} mapping(uint256 => EyeTrait) public idToEyeTrait;

    function setEyeTrait(string memory _rarity, string memory _traitSet, string memory _eyeName, string memory _svgCode) onlyOwner public {
    
    uint _traitId = eyeTraitCounter;
    eyeTraitCounter = eyeTraitCounter + 1;
    
    idToEyeTrait[_traitId] =  EyeTrait(
      _traitId,
      _rarity,
      _traitSet,
      _eyeName,
      _svgCode
    );
}
    
    struct MouthTrait {
        uint256 _traitId;
        string _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
} mapping(uint256 => MouthTrait) public idToMouthTrait;

    function setMouthTrait(string memory _rarity, string memory _traitSet, string memory _mouthName, string memory _svgCode) onlyOwner public {
    
    uint _traitId = mouthTraitCounter;
    mouthTraitCounter = mouthTraitCounter + 1;
    
    idToMouthTrait[_traitId] =  MouthTrait(
      _traitId,
      _rarity,
      _traitSet,
      _mouthName,
      _svgCode
    );
}
    
    struct LeftFinTrait {
        uint256 _traitId;
        string _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
} mapping(uint256 => LeftFinTrait) public idToLeftFinTrait;   

    function setLeftFinTrait(string memory _rarity, string memory _traitSet, string memory _leftFinName, string memory _svgCode) onlyOwner public {
    
    uint _traitId = leftFinTraitCounter;
    leftFinTraitCounter = leftFinTraitCounter + 1;
    
    idToLeftFinTrait[_traitId] =  LeftFinTrait(
      _traitId,
      _rarity,
      _traitSet,
      _leftFinName,
      _svgCode
    );
}
        
    struct RightFinTrait {
        uint256 _traitId;
        string _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
} mapping(uint256 => RightFinTrait) public idToRightFinTrait;

    function setRightFinTrait(string memory _rarity, string memory _traitSet, string memory _rightFinName, string memory _svgCode) onlyOwner public {
    
    uint _traitId = rightFinTraitCounter;
    rightFinTraitCounter = rightFinTraitCounter + 1;
    
    idToRightFinTrait[_traitId] =  RightFinTrait(
      _traitId,
      _rarity,
      _traitSet,
      _rightFinName,
      _svgCode
    );
}
    
    struct ExtraTrait {
        uint256 _traitId;
        string _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
    } mapping(uint256 => ExtraTrait) public idToExtraTrait;
    
    function setExtraTrait(string memory _rarity, string memory _traitSet, string memory _backName, string memory _svgCode) onlyOwner public {
    
    uint _traitId = extraTraitCounter;
    extraTraitCounter = extraTraitCounter + 1;
    
    idToExtraTrait[_traitId] =  ExtraTrait(
      _traitId,
      _rarity,
      _traitSet,
      _backName,
      _svgCode
    );
}
    
    struct MetaTrait {
        uint256 _traitId;
        string _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
    } mapping(uint256 => MetaTrait) public idToMetaTrait;

    function setMetaTrait(string memory _rarity, string memory _traitSet, string memory _metaName, string memory _svgCode) onlyOwner public {

    uint _traitId = metaTraitCounter;
    metaTraitCounter = metaTraitCounter + 1;

    idToMetaTrait[_traitId] =  MetaTrait(
      _traitId,
      _rarity,
      _traitSet,
      _metaName,
      _svgCode
    );
}
    
    struct NeckTrait {
        uint256 _traitId;
        string _rarity;
        string _traitSet;
        string _traitName;
        string _svgCode;
    } mapping(uint256 => NeckTrait) public idToNeckTrait;
    
    function setNeckTrait(string memory _rarity, string memory _traitSet, string memory _neckName, string memory _svgCode) onlyOwner public {
    
    uint _traitId = neckTraitCounter;
    neckTraitCounter = neckTraitCounter + 1;
    
    idToNeckTrait[_traitId] =  NeckTrait(
      _traitId,
      _rarity,
      _traitSet,
      _neckName,
      _svgCode
    );
}
    
   
    //---------
    //Public Functions
    
    //Returns finalSVG of Revealed Shark in base64 format
    //Requires Shark to be Revealed
    //Backup Function for pulling Shark Image only, sans Metadata
    //Called by getSharkMetadata
    //Calls assembleShark01 & 02
    function getSharkSVG(uint256 tokenId) public view returns(string memory) {
       
       string memory SVG = string(abi.encodePacked(
       assembleShark01(tokenId),
       assembleShark02(tokenId)
       ));
       
       string memory baseURL = "data:image/svg+xml;base64,";
       string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(SVG))));
       return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }
    
    //Returns Base Sample Shark
    function getSharkSample() public view returns(string memory) {
       
       string memory SVG = string(abi.encodePacked(
       idToSVGPart[0]._svgCode,
       idToColorTrait[0]._svgCode,
       idToSVGPart[1]._svgCode,
       
       idToSVGPart[2]._svgCode
       ));
        
       
       string memory baseURL = "data:image/svg+xml;base64,";
       string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(SVG))));
       return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }
    
    //Internal Functions
    
    //Body and Trait Assembly
    function assembleShark01(uint256 tokenId) public view returns(string memory) {
       uint256[10] memory finalDNA = coordinatorContract.getFinalDNA(tokenId);
       require(finalDNA[0] < 99);
       
       string memory ExtraTrait1 = "";
       string memory ClothingTrait1 = "";
       string memory NeckTrait1 = "";
       
       if (finalDNA[8] >= 1) {
           ExtraTrait1 = idToExtraTrait[finalDNA[8]]._svgCode;
       }
       
       if (finalDNA[2] >= 1) {
           ClothingTrait1 = idToClothingTrait[finalDNA[2]]._svgCode;
       }
       
        if (finalDNA[5] >= 1) {
           NeckTrait1 = idToNeckTrait[finalDNA[5]]._svgCode;
       }
       
       string memory SVG = string(abi.encodePacked(
       idToSVGPart[0]._svgCode,
       idToColorTrait[finalDNA[0]]._svgCode,
       ExtraTrait1,
       idToSVGPart[1]._svgCode,
       
       ClothingTrait1,
       NeckTrait1
       ));
        
        return SVG;
    }
    function assembleShark02(uint256 tokenId) public view returns(string memory) {
       uint256[10] memory finalDNA = coordinatorContract.getFinalDNA(tokenId);
       require(finalDNA[0] < 99);
       
       string memory LeftFinTrait1 = "";
       string memory RightFinTrait1 = "";
       string memory HeadTrait1 = "";
       string memory MouthTrait1 = "";
       string memory EyeTrait1 = "";
       
       string memory MetaTrait1 = "";
      
        if (finalDNA[6] >= 1) {
           LeftFinTrait1 = idToLeftFinTrait[finalDNA[6]]._svgCode;
       }
       
       if (finalDNA[7] >= 1) {
           RightFinTrait1 = idToRightFinTrait[finalDNA[7]]._svgCode;
       }
       
        if (finalDNA[1] >= 1) {
           HeadTrait1 = idToHeadTrait[finalDNA[1]]._svgCode;
       }
       
        if (finalDNA[3] >= 1) {
           EyeTrait1 = idToEyeTrait[finalDNA[3]]._svgCode;
       }
       
        if (finalDNA[4] >= 1) {
           MouthTrait1 = idToMouthTrait[finalDNA[4]]._svgCode;
       }
       
        if (finalDNA[9] >= 1) {
           MetaTrait1 = idToMetaTrait[finalDNA[9]]._svgCode;
       }
       
       string memory SVG = string(abi.encodePacked(
       LeftFinTrait1,
       RightFinTrait1,
       HeadTrait1,
       
       MouthTrait1,
       EyeTrait1,
       MetaTrait1,
       idToSVGPart[2]._svgCode
       ));
        
        return SVG;
    }
    
    
}