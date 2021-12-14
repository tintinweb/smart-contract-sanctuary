// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './base64.sol';
import './String.sol';

library GetMetadata {
  function getMetadata(
    uint256 tokenId,
    uint256 color,
    uint256 level
  ) external pure returns (string memory) {
    string[5] memory parts;

    parts[
      0
    ] = '<svg width="512" height="512" viewBox="0 0 512 512" fill="none" xmlns="http://www.w3.org/2000/svg">';

    if (level == 1) {
      parts[
        1
      ] = '<path d="M256.319 94.5795L70.6586 416.183H442L256.319 94.5795Z" fill="';
      parts[
        3
      ] = '"/><path d="M256.319 219.277L178.633 353.843H334.006L256.319 219.277Z" fill="url(#paint0_linear)" fill-opacity="0.3"/><path d="M256.319 219.278V94.5795L442 416.183L334.006 353.843L295.163 286.57L256.319 219.278Z" fill="white" fill-opacity="0.5"/><path d="M70.6586 416.182L178.633 353.843H334.006L442 416.182H70.6586Z" fill="url(#paint1_linear)" fill-opacity="0.4"/><path d="M70.6586 416.183L256.319 94.5795V219.278L178.633 353.843L70.6586 416.183Z" fill="url(#paint2_linear)" fill-opacity="0.4"/><path d="M292.598 282.106L275.271 252.111L185.564 341.822L178.633 353.843H220.844L292.598 282.106Z" fill="white"/><path d="M303.856 301.607L298.452 292.248L236.839 353.843H251.621L303.856 301.607Z" fill="white"/><defs><linearGradient id="paint0_linear" x1="256.319" y1="219.277" x2="256.319" y2="353.843" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint1_linear" x1="256.329" y1="353.843" x2="221.294" y2="440.282" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear" x1="163.489" y1="94.5795" x2="407.691" y2="130.342" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient></defs>';
    } else if (level == 2) {
      parts[
        1
      ] = '<path d="M456 255.713L255.705 55.4117L55.4108 255.713L255.705 456.013L456 255.713Z" fill="';
      parts[
        3
      ] = '"/><path d="M352.206 255.724L255.705 159.22L159.204 255.724L255.705 352.228L352.206 255.724Z" fill="url(#paint0_linear)" fill-opacity="0.3"/><path d="M255.715 159.216V55.427L455.992 255.727H352.206L255.715 159.216Z" fill="white" fill-opacity="0.6"/><path d="M352.206 255.727H455.992L255.715 456.011V352.222L352.206 255.727Z" fill="url(#paint1_linear)" fill-opacity="0.4"/><path d="M255.715 352.222V456.011L55.421 255.727H159.207L255.715 352.222Z" fill="url(#paint2_linear)" fill-opacity="0.6"/><path d="M159.207 255.727H55.4207L255.714 55.4267V159.216L159.207 255.727Z" fill="url(#paint3_linear)" fill-opacity="0.4"/><path d="M323.971 227.488L227.47 323.992L233.47 329.993L329.971 233.489L323.971 227.488Z" fill="white"/><path d="M298.291 201.803L201.79 298.307L220.982 317.5L317.483 220.996L298.291 201.803Z" fill="white"/><defs><linearGradient id="paint0_linear" x1="303.956" y1="207.472" x2="207.452" y2="303.973" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint1_linear" x1="355.854" y1="255.727" x2="428.37" y2="318.419" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear" x1="155.568" y1="255.727" x2="155.568" y2="456.011" gradientUnits="userSpaceOnUse"><stop stop-opacity="0.75"/><stop offset="1"/></linearGradient><linearGradient id="paint3_linear" x1="155.568" y1="55.4267" x2="314.02" y2="130.18" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient></defs>';
    } else if (level == 3) {
      parts[
        1
      ] = '<path d="M255.992 77L68 213.358L139.807 434H372.176L444 213.358L255.992 77Z" fill="';
      parts[
        3
      ] = '"/><path d="M255.5 164L150 240.384L190.295 364H320.705L361 240.384L255.5 164Z" fill="url(#paint0_linear)" fill-opacity="0.4"/><path d="M256 77V163.766L361.246 240L444 213.189L256 77Z" fill="white" fill-opacity="0.6"/><path d="M68 213.189L150.745 240L256 163.766V77L68 213.189Z" fill="url(#paint1_linear)" fill-opacity="0.4"/><path d="M444 214L361.213 240.766L321 363.931L372.152 434L444 214Z" fill="url(#paint2_linear)" fill-opacity="0.4"/><path d="M372 434L320.727 364H190.273L139 434H372Z" fill="black" fill-opacity="0.45"/><path d="M139.841 434L191 363.931L150.781 240.766L68 214L139.841 434Z" fill="black" fill-opacity="0.3"/><defs><linearGradient id="paint0_linear" x1="255.5" y1="164" x2="255.5" y2="364" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint1_linear" x1="162" y1="77" x2="302.289" y2="153.338" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear" x1="382.5" y1="214" x2="431.752" y2="332.845" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient></defs>';
    } else if (level == 4) {
      parts[
        1
      ] = '<path d="M403.669 146.671V363.994L255.834 472.665L108 363.994V146.671L255.834 38L403.669 146.671Z" fill="';
      parts[
        3
      ] = '"/><path d="M343.78 190.681V319.984L255.834 384.626L167.889 319.984V190.681L255.834 126.039L343.78 190.681Z" fill="url(#paint0_linear)" fill-opacity="0.4"/><path d="M255.834 126.039V38L403.669 146.671L343.78 190.681L255.834 126.039Z" fill="white" fill-opacity="0.6"/><path d="M343.78 319.984L403.669 363.994V146.671L343.78 190.681V319.984Z" fill="url(#paint1_linear)" fill-opacity="0.4"/><path d="M255.834 384.626L343.78 319.984L403.669 363.994L255.834 472.665V384.626Z" fill="url(#paint2_linear)" fill-opacity="0.4"/><path d="M167.871 319.984L255.834 384.626V472.665L108 363.994L167.871 319.984Z" fill="black" fill-opacity="0.4"/><path d="M167.871 190.681V319.984L108 363.994V146.671L167.871 190.681Z" fill="black" fill-opacity="0.3"/><path d="M255.834 38V126.039L167.871 190.681L108 146.671L255.834 38Z" fill="url(#paint3_linear)" fill-opacity="0.4"/><path d="M173.706 324.265L204.997 347.264L343.78 208.458V190.681L322.751 175.216L173.706 324.265Z" fill="white"/><path d="M343.78 243.779V226.814L215.565 355.033L225.357 362.223L343.78 243.779Z" fill="white"/><defs><linearGradient id="paint0_linear" x1="255.834" y1="126.039" x2="255.834" y2="384.626" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint1_linear" x1="373.724" y1="146.671" x2="458.663" y2="178.097" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear" x1="329.751" y1="319.984" x2="351.625" y2="411.393" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint3_linear" x1="181.917" y1="38" x2="300.213" y2="92.0385" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient></defs>';
    } else if (level == 5) {
      parts[
        1
      ] = '<path d="M256.258 42.5145L124.973 196.72L92.5332 338.812L150.211 436.151L256.258 469.338L362.322 436.151L420 338.812L387.56 196.72L256.258 42.5145Z" fill="';
      parts[
        3
      ] = '"/><path d="M256.258 166.337L186.451 248.326L169.21 323.861L199.875 375.617L256.258 393.273L312.659 375.617L343.323 323.861L326.082 248.326L256.258 166.337Z" fill="url(#paint0_linear)" fill-opacity="0.4"/><path d="M256.258 42.5145V166.337L326.083 248.326L387.56 196.72L256.258 42.5145Z" fill="white" fill-opacity="0.6"/><path d="M343.323 323.861L326.083 248.326L387.56 196.72L420 338.812L343.323 323.861Z" fill="url(#paint1_linear)" fill-opacity="0.2"/><path d="M312.659 375.617L362.322 436.151L420 338.812L343.323 323.861L312.659 375.617Z" fill="black" fill-opacity="0.15"/><path d="M256.258 393.272L312.659 375.617L362.322 436.151L256.258 469.338V393.272Z" fill="url(#paint2_linear)" fill-opacity="0.4"/><path d="M256.258 42V165.806L186.451 247.795L124.973 196.205L256.258 42Z" fill="url(#paint3_linear)" fill-opacity="0.4"/><path d="M169.21 323.347L186.451 247.795L124.973 196.205L92.5332 338.281L169.21 323.347Z" fill="white" fill-opacity="0.25"/><path d="M199.875 375.102L150.211 435.62L92.5332 338.281L169.21 323.346L199.875 375.102Z" fill="black" fill-opacity="0.4"/><path d="M256.258 392.741L199.875 375.102L150.211 435.62L256.258 468.807V392.741Z" fill="black" fill-opacity="0.2"/><path d="M331.708 272.985L328.804 260.257L210.196 378.853L222.109 382.586L331.708 272.985Z" fill="white"/><path d="M302.023 220.084L180.013 342.098L198.63 373.509L325.037 247.098L302.023 220.084Z" fill="white"/><defs><linearGradient id="paint0_linear" x1="256.267" y1="166.337" x2="256.267" y2="393.273" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint1_linear" x1="373.041" y1="196.72" x2="373.041" y2="338.812" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint2_linear" x1="309.29" y1="375.617" x2="389.116" y2="418.237" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint3_linear" x1="190.616" y1="42" x2="307.044" y2="77.0417" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient></defs>';
    }

    if (color == 1) {
      parts[2] = '#00FF00';
    } else if (color == 2) {
      parts[2] = '#00A3FF';
    } else if (color == 3) {
      parts[2] = '#FF0000';
    } else if (color == 4) {
      parts[2] = '#FFFF00';
    } else if (color == 5) {
      parts[2] = '#D331D7';
    } else if (color == 6) {
      parts[2] = '#FF8A00';
    } else if (color == 7) {
      parts[2] = '#00F0FF';
    } else if (color == 8) {
      parts[2] = '#FFFFFF';
    } else if (color == 9) {
      parts[2] = '#000000';
    } else {
      parts[2] = '';
    }

    if (tokenId == 0) {
      parts[
        1
      ] = '<path d="M232.974 78.9771L233.058 148.26L293.017 182.974L223.734 183.058L189.02 243.017L188.936 173.734L128.977 139.02L198.26 138.936L232.974 78.9771Z" fill="white"/><path d="M377.74 203.447L377.81 261.602L428.139 290.74L369.984 290.81L340.846 341.139L340.775 282.984L290.447 253.846L348.602 253.775L377.74 203.447Z" fill="white"/><path d="M216.592 304.758L216.648 351.281L256.911 374.592L210.387 374.648L187.076 414.911L187.02 368.387L146.758 345.077L193.281 345.02L216.592 304.758Z" fill="white"/>';
      parts[2] = '';
      parts[3] = '';
    }

    parts[4] = '</svg>';

    string memory output = string(
      abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
    );

    string memory name;
    string memory description;
    string memory jsonString;

    if (tokenId == 0) {
      name = 'Gem dust';
      description = 'Used to craft gems.';

      jsonString = string(abi.encodePacked(
        '{"name": "',
        name,
        '", "description": "',
        description,
        '", "background_color" : "000000", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(output)),
        '"}'
      ));
    } else {
      name = string(abi.encodePacked('Gem #', String.toString(tokenId)));
      description = 'A beautiful gem.';

      jsonString = string(abi.encodePacked(
        '{"name": "',
        name,
        '", "attributes": [ { "trait_type": "Level",  "value": ',
        String.toString(level),
        ' }, { "trait_type": "Color",  "value": "',
        String.toString(color),
        '" } ], "description": "',
        description,
        '", "background_color" : "000000", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(output)),
        '"}'
      ));
    }

    string memory json = Base64.encode(bytes(jsonString));
    output = string(abi.encodePacked('data:application/json;base64,', json));
    return output;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library String {
  function toString(uint256 value) internal pure returns (string memory) {

    if (value == 0) {
      return '0';
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