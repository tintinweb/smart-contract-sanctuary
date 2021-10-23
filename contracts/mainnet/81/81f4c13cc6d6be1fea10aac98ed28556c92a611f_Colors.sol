pragma solidity 0.8.9;

import "./VRFConsumerBase.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";

// SPDX-License-Identifier: Unlicense

contract Colors is ERC721, Ownable, VRFConsumerBase {
    /*
          ___  __   __     __  ____  ____ 
         / __)/  \ (  )   /  \(  _ \/ ___)
        ( (__(  O )/ (_/\(  O ))   /\___ \
         \___)\__/ \____/ \__/(__\_)(____/
                everybody gets 4
         
         - 4 colors randomly chosen based on
           seed from chainlink VRF
         - colors may be determined if and only if
           all 10k tokens are minted
         
         - no fee to mint, just gas
         - mint however many you want to =)
    */
    
    uint256 public seed;
    uint256 public totalSupply;
    
    constructor()
        ERC721("Colors", unicode"RGB")
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
    { }
    
    function requestSeed() external {
        require(totalSupply == 10000, 'all tokens have not been minted yet');
        require(seed == 0, 'randomness is filled');
        requestRandomness(0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445, 2 * 10 ** 18);
    }
    
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        require(totalSupply == 10000, 'all tokens have not been minted yet');
        require(seed == 0, 'randomness is filled');
        seed = randomness;
    }

    function mint(uint256 _tokenId) public {
        require(_tokenId < 10000, '10k max tokens');
        totalSupply++;
        _safeMint(msg.sender, _tokenId);
    }
    
    function calculateColors(uint _tokenId) internal view virtual returns (uint24[] memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, _tokenId)));
        uint96 rand96 = uint96(rand);
        uint24[] memory colors = new uint24[](4);
        
        for (uint i = 0; i < 4; i++) {
            colors[i] = uint24(rand96 & 0xffffff);
            rand96 /= 2 ** 24;
        }
        
        return colors;
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toHexColor(uint24 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        for (uint i = 0; i < 6; i++) {
            buffer[6 - 1 - i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }

        return string(abi.encodePacked('#', buffer));
    }
    
    function getColorParts(uint24 value) internal pure returns (uint8[] memory) {
        uint8[] memory parts = new uint8[](3);
        parts[0] = uint8((value & 0xFF0000) >> 16);
        parts[1] = uint8((value & 0x00FF00) >> 8);
        parts[2] = uint8(value & 0x0000FF);
        return parts;
    }
    
    
    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        if (seed == 0) {
            
            string[6] memory comingSoonParts;
            comingSoonParts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">';
            comingSoonParts[1] = '<style>.base { font-family: serif; font-size: 14px; }</style>';
            comingSoonParts[2] = '<text class="base" x="10" y="40">These Colors have not been determined yet.</text>';
            comingSoonParts[3] = '<text class="base" x="10" y="60">Check back when all 10 000 Colors have been minted</text>';
            comingSoonParts[4] = '<text class="base" x="10" y="80">to see your colors!</text>';
            comingSoonParts[5] = '</svg>';
            
            string memory _output = string(
                abi.encodePacked(
                    comingSoonParts[0], comingSoonParts[1], comingSoonParts[2], comingSoonParts[3],
                    comingSoonParts[4], comingSoonParts[5]
                )
            );
            
            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Colors #', Strings.toString(tokenId), '", "description": "These Colors have not been determined yet. Check back when all 10 000 Colors have been minted to see your colors!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(_output)), '"}'))));
            _output = string(abi.encodePacked('data:application/json;base64,', json));

            return _output;
        }

        string[6] memory parts;
        uint24[] memory colors = calculateColors(tokenId);
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1024 1024">';
        parts[1] = string(abi.encodePacked('<rect x="0" y="0" width="512" height="512" style="fill:', toHexColor(colors[0]), '" />'));
        parts[2] = string(abi.encodePacked('<rect x="512" y="0" width="512" height="512" style="fill:', toHexColor(colors[1]), '" />'));
        parts[3] = string(abi.encodePacked('<rect x="0" y="512" width="512" height="512" style="fill:', toHexColor(colors[2]), '" />'));
        parts[4] = string(abi.encodePacked('<rect x="512" y="512" width="512" height="512" style="fill:', toHexColor(colors[3]), '" />'));
        parts[5] = '</svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        
        string[4] memory attributeParts;
        
        uint8[] memory color1 = getColorParts(colors[0]);
        attributeParts[0] = string(
            abi.encodePacked(
                '{"trait_type": "Red 1", "value": ',   Strings.toString(color1[0]), ' }, '
                '{"trait_type": "Green 1", "value": ', Strings.toString(color1[1]), ' }, '
                '{"trait_type": "Blue 1", "value": ',  Strings.toString(color1[2]), ' }, '
                '{"trait_type": "Color 1", "value": ', Strings.toString(colors[0]), ' }, '
            )
        );
        
        uint8[] memory color2 = getColorParts(colors[1]);
        attributeParts[1] = string(
            abi.encodePacked(
                '{"trait_type": "Red 2", "value": ',   Strings.toString(color2[0]), ' }, '
                '{"trait_type": "Green 2", "value": ', Strings.toString(color2[1]), ' }, '
                '{"trait_type": "Blue 2", "value": ',  Strings.toString(color2[2]), ' }, '
                '{"trait_type": "Color 2", "value": ', Strings.toString(colors[1]), ' }, '
            )
        );

        uint8[] memory color3 = getColorParts(colors[2]);
        attributeParts[2] = string(
            abi.encodePacked(
                '{"trait_type": "Red 3", "value": ',   Strings.toString(color3[0]), ' }, '
                '{"trait_type": "Green 3", "value": ', Strings.toString(color3[1]), ' }, '
                '{"trait_type": "Blue 3", "value": ',  Strings.toString(color3[2]), ' }, '
                '{"trait_type": "Color 3", "value": ', Strings.toString(colors[2]), ' }'
            )
        );

        uint8[] memory color4 = getColorParts(colors[3]);
        attributeParts[3] = string(
            abi.encodePacked(
                '{"trait_type": "Red 4", "value": ',   Strings.toString(color4[0]), ' }, '
                '{"trait_type": "Green 4", "value": ', Strings.toString(color4[1]), ' }, '
                '{"trait_type": "Blue 4", "value": ',  Strings.toString(color4[2]), ' }, '
                '{"trait_type": "Color 4", "value": ', Strings.toString(colors[3]), ' }'
            )
        );
        
        string memory description = string(abi.encodePacked(
            '"Colors #',
            Strings.toString(tokenId),
            ' of 10000. Colors in this picture are: ',
                toHexColor(colors[0]), ', ',
                toHexColor(colors[1]), ', ',
                toHexColor(colors[2]), ' and ',
                toHexColor(colors[3]), '.",'
            )
        );

        string memory json = Base64.encode(bytes(string(
            abi.encodePacked('{"name": "Colors #', Strings.toString(tokenId),
            '","description": ', description, '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)),
            '","attributes": [', abi.encodePacked(attributeParts[0], attributeParts[1], attributeParts[2]), ']}'
        ))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
}