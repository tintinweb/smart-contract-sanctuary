/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT
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

// File: contracts/BananaTreesURI.sol



pragma solidity >=0.7.0 <0.9.0;



library Library {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
            for {
            
            } lt(dataPtr, endPtr) {
            
            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
    
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }
    
    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------

interface IEcoz {}

contract BananaTreesURI is Ownable {
    IEcoz public ecozContract;
    
    uint256 traitCount = 5; //how many traits make up a genesis
    uint256 babyTraitCount = 4; // how many traits make up a baby

    uint8 randI = 0;

    uint16[][6] ranges;

    //All colors used for banana trees
    string []Colors;

    //allows us to encode 6 digit colors, as well as 2 digit locations as 1 symbol
    string[] LETTERS;
  
    struct Trait {
        string traitName;
        string traitType;
        string pixels;
        uint256 pixelCount;
    }

    bool public revealed = false;

    string[3] Leg;

    mapping (uint256 => Trait[]) public traitTypes;
    
    mapping (uint256 => Trait[]) public babyTraitTypes;

    mapping (uint256 => string) treeIDToHash;

    mapping (uint256 => uint256) traitTypeCount;
    
    mapping (uint256 => uint256) babyTraitTypeCount;

    function traitGenerator(uint256 thisTrait, uint256 thisTraitCount, uint256 traitProbability) internal view returns(uint256) {
        if (traitProbability >= 8000 && traitProbability < 10000) {//common
            thisTrait = 0;
        }   
        else if (traitProbability >=6000 && traitProbability < 8000) {//common
            thisTrait = 1;
        }
        else if (traitProbability >=4000 && traitProbability < 6000) {//uncommon
            thisTrait = 2;
        }
        else if (traitProbability >=2000 && traitProbability < 4000) {//uncommon
            thisTrait = 3;
        }
        else if (traitProbability >=1500 && traitProbability < 2000) {//rare
            thisTrait = 4;
        }
        else if (traitProbability >=1000 && traitProbability < 1500) {//rare
            if(thisTraitCount < 6) {
                thisTrait = 5 % thisTraitCount;
            }
            else {
                thisTrait = 5;
            }
        }
        else if (traitProbability >=500 && traitProbability < 1000) {//rare
            if(thisTraitCount < 7) {
                thisTrait = 6 % thisTraitCount;
            }
            else {
                thisTrait = 6;
            }
        }
        else if (traitProbability >=300 && traitProbability < 500) {//super rare
            if(thisTraitCount < 8) {
                thisTrait = 7 % thisTraitCount;
            }
            else {
                thisTrait = 7;
            }
        }
        else if (traitProbability >=100 && traitProbability < 300) {//super rare
            if(traitCount < 9) {
                thisTrait = 8 % thisTraitCount;
            }
            else {
                thisTrait = 8;
            }
        }
        else if (traitProbability >=0 && traitProbability < 100) {//legendary
            if(thisTraitCount < 10) {
                thisTrait = 9 % thisTraitCount;
            }
            else {
                thisTrait = 9;
            }
        }
        return thisTrait;
    }
    
    
    function treeRandomizer(address user, uint256 treeID) external returns(uint256) {
        require(msg.sender == address(ecozContract));
        uint256 thisTrait;
        if (treeID <= 5850 && treeID > 4053) {
            uint256 value = 7;

            for (uint256 i = 0; i < traitCount; i++) {
                uint256 rand = random(user, treeID);
                thisTrait = traitGenerator(i, traitTypeCount[i], rand);

                if (i != 3) {
                    treeIDToHash[treeID] = string(abi.encodePacked(treeIDToHash[treeID], Library.toString(thisTrait)));              
                }
                else {
                    treeIDToHash[treeID] = string(abi.encodePacked(treeIDToHash[treeID], Library.toString(thisTrait), Library.toString(thisTrait)));
                    i++;
                }
                value = value + thisTrait;
            }
            if (value < 38)
            {
                return 5;
            }
            else if (value >= 38 && value < 58)
            {
                return 6;
            }
            else
            {
                return 7;
            }
        }
        else if (treeID > 5850) {
            for (uint256 i = 0; i < babyTraitCount; i++) {
                uint256 rand = random(user, treeID);
                treeIDToHash[treeID] = string(abi.encodePacked(treeIDToHash[treeID], Library.toString(traitGenerator(i, traitTypeCount[i], rand))));
            }
            return 0;
        }
        else {
            return 7;
        }
    } 

    function getHash(uint256 treeID) public view returns(string memory) {
        return treeIDToHash[treeID];
    }

    function random(address user, uint256 treeID) internal returns (uint256) {
            randI = randI + 1;
            if (randI >= 10) {
                randI = 0;
            }
            return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, user, treeID, randI))) % 10000;
    }

    function letterToNumber(string memory _inputLetter) internal view returns (uint8)
        {
            for (uint8 i = 0; i < LETTERS.length; i++) {
                if (
                    keccak256(abi.encodePacked((LETTERS[i]))) ==
                    keccak256(abi.encodePacked((_inputLetter)))
                ) return (i);
            }
            revert();
        }
        
    function letterToColor(string memory _inputLetter) internal view returns (string memory)
        {
            for (uint8 i = 0; i < LETTERS.length; i++) {
                if (keccak256(abi.encodePacked((LETTERS[i]))) == keccak256(abi.encodePacked((_inputLetter))))
                {
                return Colors[i];
                }
            }
            revert();
        }

    function bananaTreeTokenURI(uint256 treeID) external view virtual returns(string memory)
    {
        require(msg.sender == address(ecozContract));

        if (treeID <= 5850) 
        {
            if (revealed == false && treeID > 4053 ) 
            {
                return string(abi.encodePacked(
                    'data:application/json;base64,',Base64.encode(bytes(abi.encodePacked(
                    '{"name": "',
                    '"Ecoz Banana Tree", ',
                    '"description": "',
                    'The Banana Tree Ecoz is the abundant producer of the Ecozystem. Their population stays strong and fruitful unless the Bush Bucks get too hungry...',
                    '", "image": "',
                    'ipfs://QmNXYpab929nJ66dwWmc2XfW3vjJ7ukgYcGeWoxBDzLvj2',
                    '}')))));
            }
            
            string memory metadataString;
            string memory svgString;
            bool[32][32] memory placedPixels;
            uint256 count;
            string memory thisPixel;
            string memory thisTrait;
            uint8 thisTraitIndex;

            if (treeID == 4051) 
            {
                thisTrait = Leg[0];
                metadataString = string(abi.encodePacked(metadataString,'{"trait_type":"','1/1','","value":"','Treedenza''"},','{"trait_type":"','Generation','","value":"','Genesis''"}'));
            }

            else if (treeID == 4052) 
            {
                thisTrait = Leg[1];
                metadataString = string(abi.encodePacked(metadataString,'{"trait_type":"','1/1','","value":"','Alien''"},','{"trait_type":"','Generation','","value":"','Genesis''"}'));
            }

            else if (treeID == 4053) 
            {
                thisTrait = Leg[2];
                metadataString = string(abi.encodePacked(metadataString,'{"trait_type":"','1/1','","value":"','Bubble Gum Blossom''"},','{"trait_type":"','Generation','","value":"','Genesis''"}'));
            }
            else
            {
            metadataString = string(abi.encodePacked(metadataString,'{"trait_type":"','Generation','","value":"','Genesis''"},'));
            }
            
            //Get the metadata from the Traits using the hash
            if (treeID > 4053) 
            {
                for (uint256 i = 0; i < traitCount; i++) 
                {
                    if (i != 4) {
                        thisTraitIndex = Library.parseInt(Library.substring(treeIDToHash[treeID], i, i + 1));
                        metadataString = string(abi.encodePacked(metadataString,'{"trait_type":"',traitTypes[i][thisTraitIndex].traitType,'","value":"',traitTypes[i][thisTraitIndex].traitName,'"}'));
                    }
                    
                    if (i != traitCount-1) 
                    {
                        metadataString = string(abi.encodePacked(metadataString, ","));
                    }
                }
            } 
            
            //Get the SVG from the Traits using the hash
            for (uint256 i = traitCount-1; i >=0 ; i--) 
            {
                if (treeID > 4053) 
                {
                    thisTraitIndex = Library.parseInt(Library.substring(treeIDToHash[treeID], i, i + 1));
                    count = traitTypes[i][thisTraitIndex].pixelCount;
                }
                else 
                {
                    if (treeID == 4051) 
                    {
                        count = bytes(Leg[0]).length / 3;
                    }
                    else if (treeID == 4052) 
                    {
                        count = bytes(Leg[1]).length / 3;
                    }
                    else if (treeID == 4053) 
                    {
                        count = bytes(Leg[2]).length / 3;
                    }
                }

                for (uint16 j = 0; j < count; j++) 
                {
                    if (treeID < 4054) 
                    {
                        thisPixel = Library.substring(thisTrait, j * 3, j * 3 + 3);
                    }
                    else 
                    {
                        thisPixel = Library.substring(traitTypes[i][thisTraitIndex].pixels, j * 3, j * 3 + 3);
                    }

                    uint8 x = letterToNumber(Library.substring(thisPixel, 0, 1));
                    uint8 y = letterToNumber(Library.substring(thisPixel, 1, 2));
            
                    if (placedPixels[x][y]) continue;
            
                    svgString = string(abi.encodePacked(svgString,"<rect fill='#",letterToColor(Library.substring(thisPixel, 2, 3)),"' x='",Library.toString(x),"' y='",Library.toString(y),"'/>"));
                    placedPixels[x][y] = true;
                }

                if (i == 0 || treeID < 4054)  
                {
                    break;
                }
            }
                

            svgString = string(
                Library.encode(bytes(abi.encodePacked(
                '<svg id="ecoz-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 32"> <rect class="bg" x="0" y="0" />',
                svgString,
                '<style>rect.bg{width:32px;height:32px;fill:#B6EAFF} rect{width:1px;height:1px;} #ecoz-svg{shape-rendering: crispedges;} </style></svg>'
                )))
                );

            return string(abi.encodePacked(
                'data:application/json;base64,',Base64.encode(bytes(abi.encodePacked(
                '{"name":',
                '"Banana Tree #',
                Library.toString(treeID),
                '", "description":"',
                "The Banana Tree Ecoz is the abundant producer of the Ecozystem. Their population stays strong and fruitful unless the Bush Bucks get too hungry...",
                '", "image": "',
                'data:image/svg+xml;base64,',
                svgString,'",',
                '"attributes": [',
                metadataString,']',
                '}')))));
        }
        else 
        {
            string memory metadataString;
            string memory svgString;
            bool[32][32] memory placedPixels;
            uint256 count;
            string memory thisPixel;
            uint8 thisTraitIndex;
            metadataString = string(abi.encodePacked(metadataString,'{"trait_type":"','Generation','","value":"','Baby''"},'));

            //Get the metadata from the Traits using the hash
            for (uint256 i = 0; i < babyTraitCount; i++) 
            {
                thisTraitIndex = Library.parseInt(Library.substring(treeIDToHash[treeID], i, i + 1));
                metadataString = string(abi.encodePacked(metadataString,'{"trait_type":"',babyTraitTypes[i][thisTraitIndex].traitType,'","value":"',babyTraitTypes[i][thisTraitIndex].traitName,'"}'));
                    
                if (i != babyTraitCount-1) 
                {
                    metadataString = string(abi.encodePacked(metadataString, ","));
                }
            }
            
            //Get the SVG from the Traits using the hash
            for (uint256 i = babyTraitCount-1; i >=0; i--) 
            {
                thisTraitIndex = Library.parseInt(Library.substring(treeIDToHash[treeID], i, i + 1));
                count = babyTraitTypes[i][thisTraitIndex].pixelCount;

                for (uint16 j = 0; j < count; j++) 
                {
                    thisPixel = Library.substring(babyTraitTypes[i][thisTraitIndex].pixels, j * 3, j * 3 + 3);
                    uint8 x = letterToNumber(Library.substring(thisPixel, 0, 1));
                    uint8 y = letterToNumber(Library.substring(thisPixel, 1, 2));

                    if (placedPixels[x][y]) continue;

                    svgString = string(abi.encodePacked(svgString,"<rect fill='#",letterToColor(Library.substring(thisPixel, 2, 3)),"' x='",Library.toString(x),"' y='",Library.toString(y),"'/>"));
                    placedPixels[x][y] = true;
                }

                if (i == 0) 
                {
                    break;
                }
            }
        

            svgString = string(
                Library.encode(bytes(abi.encodePacked(
                '<svg id="ecoz-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 32"> <rect class="bg" x="0" y="0" />',
                svgString,
                '<style>rect.bg{width:32px;height:32px;fill:#B6EAFF} rect{width:1px;height:1px;} #ecoz-svg{shape-rendering: crispedges;} </style></svg>'
                )))
                );

            return string(abi.encodePacked(
                'data:application/json;base64,',Base64.encode(bytes(abi.encodePacked(
                '{"name":',
                '"Banana Tree #',
                Library.toString(treeID),
                '", "description":"',
                "The Banana Tree Ecoz is the abundant producer of the Ecozystem. Their population stays strong and fruitful unless the Bush Bucks get too hungry...",
                '", "image": "',
                'data:image/svg+xml;base64,',
                svgString,'",',
                '"attributes": [',
                metadataString,']',
                '}')))));    
        }
        
    }

    function setTreeLegendary(string memory inputLeg0, string memory inputLeg1, string memory inputLeg2) public onlyOwner
    {
        Leg[0] = inputLeg0;
        Leg[1] = inputLeg1;
        Leg[2] = inputLeg2;

        return;
    }
    
    function setTreeColorsLETTERS(string[87] memory colors, string[87] memory letters) public onlyOwner
    {
        Colors = colors;
        LETTERS = letters;
    }

    function addTreeTraitType(uint256 _traitTypeIndex, Trait[] memory traits) public onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType,
                    traits[i].pixels,
                    traits[i].pixelCount
                )
            );
        }
        
        traitTypeCount[_traitTypeIndex] = traitTypeCount[_traitTypeIndex] + traits.length;

        return;
    }

    function addBabyTreeTraitType(uint256 _traitTypeIndex, Trait[] memory traits) public onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            babyTraitTypes[_traitTypeIndex].push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType,
                    traits[i].pixels,
                    traits[i].pixelCount
                )
            );
        }
        babyTraitTypeCount[_traitTypeIndex] = babyTraitTypeCount[_traitTypeIndex] + traits.length;

        return;
    }

    function setTreeEcoz(address ecozAddress) external onlyOwner 
    {
        ecozContract = IEcoz(ecozAddress);
        return;
    }

    function setBabyTreeTraitCount(uint256 count) public onlyOwner 
    {
        babyTraitCount = count;
        return;
    }
    
    function reveal() public onlyOwner 
    {
        revealed = true;
        return;
    }
}