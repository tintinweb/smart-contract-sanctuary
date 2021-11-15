// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;
import './UintStrings.sol';
import './AnimalDescriptors.sol';
import 'base64-sol/base64.sol';
// import './AnimalColoringBook.sol';

interface IAnimalColoringBook{
    function animalInfo(uint256 tokenId) external view returns (uint8, uint8);
    function transferHistory(uint256 tokenId) external view returns (address[] memory);
}

interface IAnimalDescriptors{
    function animalSvg(uint8 animalType, uint8 mood) external view returns (string memory);
    function moodSvg(uint8 mood) external view returns (string memory);
    function animalTypeString(uint8 animalType) external view returns (string memory);
    function moodTypeString(uint8 mood) external view returns (string memory);
    // function randomishIntLessThan(bytes32 salt, uint8 n) external view returns (uint8);
}

contract AnimalColoringBookDescriptors {
    address public animalDescriptors;

    constructor(address _animalDescriptors) {
        animalDescriptors = _animalDescriptors;
    }

    function addressH(address account) public view returns (string memory){
        uint256 h = uint256(keccak256(abi.encodePacked(account))) % 360;
        return UintStrings.decimalString(h, 0, false);
    }

    function tokenURI(uint256 tokenId, IAnimalColoringBook animalColoringBook) external view returns(string memory) {
        (uint8 animalType, uint8 mood) = animalColoringBook.animalInfo(tokenId);
        address[] memory history = animalColoringBook.transferHistory(tokenId);
        return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"',
                                    '#',
                                    UintStrings.decimalString(tokenId, 0, false),
                                    ' - ',
                                    history.length < 4 ? '' : string(abi.encodePacked(IAnimalDescriptors(animalDescriptors).moodTypeString(mood), ' ')),
                                    IAnimalDescriptors(animalDescriptors).animalTypeString(animalType),
                                    '", "description":"',
                                    "The first four transfers of this NFT add a color to part of the image. First, the background. Second, the body. Third, the nose and mouth. And finally, the eyes. The colors are determined by the to address of the transfer. On the fourth transfer, the Animal's mood is revealed, corresponding to the animation of its eyes. The SVG image and animation are generated and stored entirely on-chain.",
                                    '", "attributes": [',
                                    '{',
                                    '"trait_type": "Type",', 
                                    '"value":"',
                                    IAnimalDescriptors(animalDescriptors).animalTypeString(animalType),
                                    '"}',
                                    ', {',
                                    '"trait_type": "Coloring",', 
                                    '"value":"',
                                    UintStrings.decimalString(history.length, 0, false),
                                    '/4',
                                    '"}',
                                    moodTrait(mood),
                                    ']',
                                    ', "image": "'
                                    'data:image/svg+xml;base64,',
                                    Base64.encode(bytes(svgImage(tokenId, animalType, mood, history))),
                                    '"}'
                                )
                            )
                        )
                )
            );
    }

    function moodTrait(uint8  mood) public view returns (string memory) {
        if (mood == 0){
            return '';
        }
        return string(
            abi.encodePacked(
                ', {',
                '"trait_type": "Mood",', 
                '"value":"',
                IAnimalDescriptors(animalDescriptors).moodTypeString(mood),
                '"}'
            )
        );
    }


    function svgImage(uint256 tokenId, uint8 animalType, uint8 mood, address[] memory history) public view returns (bytes memory){
        return abi.encodePacked(
                '<svg version="1.1" shape-rendering="optimizeSpeed" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 10 10" width="300" height="300" xml:space="preserve">',
                styles(tokenId, history),
                IAnimalDescriptors(animalDescriptors).animalSvg(animalType, mood),
                '</svg>'
            );
    }

    function styles(uint256 tokenId, address[] memory history) public view returns (string memory) {
        string memory color1 = history.length > 0 ? string(abi.encodePacked('hsl(', addressH(history[0]),',100%,50%)')) : '#ffffff;';
        string memory color2 = history.length > 1 ? string(abi.encodePacked('hsl(', addressH(history[1]),',100%,50%)')) : '#ffffff;';
        string memory color3 = history.length > 2 ? string(abi.encodePacked('hsl(', addressH(history[2]),',100%,50%)')) : history.length > 1 ? color2 : '#ffffff';
        string memory color4 = history.length > 3 ? string(abi.encodePacked('hsl(', addressH(history[3]),',100%,50%)')) : history.length > 1 ? color2 : '#ffffff';
        string memory color5 = history.length < 4 ? color2 : '#ffffff;';
        return string(
            abi.encodePacked(
                '<style type="text/css">',
                    'rect{width: 1px; height: 1px;}',
                    '.l{width: 2px; height: 1px;}',
	                '.c1{fill:',
                    color2
                    ,'}',
                    '.c2{fill:',
                    color3
                    ,'}'
                    '.c3{fill:',
                    color4
                    ,'}'
                    '.c4{fill:',
                    color1
                    ,'}'
                    '.c5{fill:',
                    color5,
                    '}',
                '</style>'
                )
        );

    }
}

pragma solidity 0.8.6;


library UintStrings {
    function decimalString(uint256 number, uint8 decimals, bool isPercent) internal pure returns(string memory){
        if(number == 0){
            return isPercent ? "0%" : "0";
        }
        
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;

        uint256 temp = number;
        uint8 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params;
        params.isPercent = isPercent;
        if((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if(tenPowDecimals > number){
                // number is less than one
                // in this case, there may be leading zeros after the decimal place 
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return generateDecimalString(params);
    }

    // With modifications, From https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/NFTDescriptor.sol#L189-L231

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function generateDecimalString(DecimalStringParams memory params) private pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = '%';
        }
        if (params.isLessThanOne) {
            buffer[0] = '0';
            buffer[1] = '.';
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[--params.sigfigIndex] = '.';
            }
            buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import './Eyes.sol';
import './UintStrings.sol';
import './IAnimalSVG.sol';

contract AnimalDescriptors {
    IAnimalSVG public immutable creator;
    IAnimalSVG public immutable unicorn;
    IAnimalSVG public immutable skull;
    IAnimalSVG public immutable cat;
    IAnimalSVG public immutable mouse;
    IAnimalSVG public immutable bunny;

    constructor(IAnimalSVG _creator, IAnimalSVG _unicorn, IAnimalSVG _skull, IAnimalSVG _cat, IAnimalSVG _mouse, IAnimalSVG _bunny){
        creator = _creator;
        unicorn = _unicorn;
        skull = _skull;
        cat = _cat;
        mouse = _mouse;
        bunny = _bunny;
    }

    function animalSvg(uint8 animalType, uint8 mood) external view returns (string memory){
        string memory moodSVG = moodSvg(mood);
        return (animalType == 1 ? cat.svg(moodSVG) :
                    (animalType == 2 ? bunny.svg(moodSVG) :
                        (animalType == 3 ? mouse.svg(moodSVG) :
                            (animalType == 4 ? skull.svg(moodSVG) : 
                                (animalType == 5 ? unicorn.svg(moodSVG) : creator.svg(moodSVG))))));
    }

    function moodSvg(uint8 mood) public view returns (string memory){
        if(mood == 1){
            string memory rand1 = UintStrings.decimalString(_randomishIntLessThan('rand1', 4) + 10, 0, false);
            string memory rand2 = UintStrings.decimalString(_randomishIntLessThan('rand2', 5) + 14, 0, false);
            string memory rand3 = UintStrings.decimalString(_randomishIntLessThan('rand3', 3) + 5, 0, false);
            return Eyes.aloof(rand1, rand2, rand3);
        } else {
            return (mood == 2 ? Eyes.sly() : 
                        (mood == 3 ? Eyes.dramatic() : 
                            (mood == 4 ? Eyes.mischievous() : 
                                (mood == 5 ? Eyes.flirty() : Eyes.shy()))));
        }
    }

    function _randomishIntLessThan(bytes32 salt, uint8 n) private view returns (uint8) {
        if (n == 0)
            return 0;
        return uint8(keccak256(abi.encodePacked(block.timestamp, msg.sender, salt))[0]) % n;
    }

    function animalTypeString(uint8 animalType) public view returns (string memory){
        return (animalType == 1 ? "Cat" : 
                (animalType == 2 ? "Bunny" : 
                    (animalType == 3 ? "Mouse" : 
                        (animalType == 4 ? "Skull" : 
                            (animalType == 5 ? "Unicorn" : "Creator")))));
    }

    function moodTypeString(uint8 mood) public view returns (string memory){
        return (mood == 1 ? "Aloof" : 
                (mood == 2 ? "Sly" : 
                    (mood == 3 ? "Dramatic" : 
                        (mood == 4 ? "Mischievous" : 
                            (mood == 5 ? "Flirty" : "Shy")))));
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

library Eyes{
    function sly() internal pure returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="sly">',
                    '<rect x="1" y="1" class="c3">',
                        '<animate attributeName="x" values="1;1;.5;.5;1;1" keyTimes="0;.55;.6;.83;.85;1" dur="13s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="6" y="1" class="c3">',
                        '<animate attributeName="x" values="6;6;5.5;5.5;6;6" keyTimes="0;.55;.6;.83;.85;1" dur="13s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="0" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;1;1;2;1;1;0;0" keyTimes="0;.55;.6;.72;.73;.74;.83;.85;1" dur="13s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;1;1;0;0" keyTimes="0;.55;.6;.83;.85;1" dur="13s" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }

    function aloof(string memory rand1, string memory rand2, string memory rand3) internal view returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="aloof">',
                    '<rect x="0" y="1" class="c3">',
                        '<animate attributeName="x" values="0;0;1;1;0;0" keyTimes="0;.5;.56;.96;.98;1" dur="',
                        rand1,
                        's" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="1;1;0;0;1;1" keyTimes="0;.5;.56;.96;.98;1" dur="',
                        rand2,
                        's" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="1" class="c3">',
                        '<animate attributeName="x" values="5;5;6;6;5;5" keyTimes="0;.5;.56;.96;.98;1" dur="',
                        rand1,
                        's" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="1;1;0;0;1;1" keyTimes="0;.5;.56;.96;.98;1" dur="',
                        rand2,
                        's" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="0" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;0" keyTimes="0;.55;.57;.59;1" dur="',
                        rand3,
                        's" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;0" keyTimes="0;.55;.57;.59;1" dur="',
                        rand3,
                        's" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }

    function dramatic() internal pure returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="dramatic">',
                    '<rect x="0" y="1" class="c3">',
                        '<animate attributeName="x" values="0;0;0;1;1;0;0;" keyTimes="0;.6;.62;.64;.82;.84;1" dur="12s" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="1;1;0;0;0;1;1" keyTimes="0;.6;.62;.64;.82;.84;1" dur="12s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="1" class="c3">',
                        '<animate attributeName="x" values="5;5;5;6;6;5;5" keyTimes="0;.6;.62;.64;.82;.84;1" dur="12s" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="1;1;0;0;0;1;1" keyTimes="0;.6;.62;.64;.82;.84;1" dur="12s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="0" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;0;2;0;0" keyTimes="0;.58;.59;.6;.8;.81;.82;1" dur="12s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;0;2;0;0" keyTimes="0;.58;.59;.6;.8;.81;.82;1" dur="12s" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }

    function flirty() internal pure returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="flirty">',
                    '<rect x="0" y="0" class="c3">',
                        '<animate attributeName="x" values="0;0;1;1;0;0" keyTimes="0;.5;.52;.96;.98;1" dur="20s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c3">',
                        '<animate attributeName="x" values="5;5;6;6;5;5" keyTimes="0;.5;.52;.96;.98;1" dur="20s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="0" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;2;0;0" keyTimes="0;.16;.17;.18;.19;.2;1" dur="10s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;2;0;0" keyTimes="0;.16;.17;.18;.19;.2;1" dur="10s" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }

    function mischievous() internal pure returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="mischievous">',
                    '<rect x="0" y="1" class="c3 s">',
                        '<animate attributeName="x" values="0;0;1;1;0;0" keyTimes="0;.3;.5;.83;.85;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="1" class="c3 s">',
                        '<animate attributeName="x" values="5;5;6;6;5;5" keyTimes="0;.3;.5;.83;.85;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="0" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;1;1;0;0" keyTimes="0;.2;.25;.63;.65;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;1;1;0;0" keyTimes="0;.2;.25;.63;.65;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }

    function shy() internal pure returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="shy">',
                    '<rect x="0" y="0" class="c3">',
                        '<animate attributeName="x" values="0;0;.5;0;0" keyTimes="0;.1;.7;.71;1" dur="8s" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="0;0;.5;0;0" keyTimes="0;.1;.7;.71;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c3">',
                        '<animate attributeName="x" values="5;5;5.5;5;5" keyTimes="0;.1;.7;.71;1" dur="8s" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="0;0;.5;0;0" keyTimes="0;.1;.7;.71;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }
}

pragma solidity 0.8.6;

interface IAnimalSVG {
    function svg(string memory eyes) external pure returns(string memory);
}

