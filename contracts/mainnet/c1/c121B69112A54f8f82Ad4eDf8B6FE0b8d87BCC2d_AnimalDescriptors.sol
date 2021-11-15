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

pragma solidity 0.8.6;

interface IAnimalSVG {
    function svg(string memory eyes) external pure returns(string memory);
}

