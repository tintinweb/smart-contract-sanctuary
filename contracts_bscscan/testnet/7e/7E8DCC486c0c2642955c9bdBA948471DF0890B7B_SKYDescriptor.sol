// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import './PlanetRandom.sol';


library SKYDescriptor {

  uint256 constant xPayload = 192345;
  uint256 constant yPayload = 360493;
  uint256 constant XYMin = 0;
  uint256 constant XYMax = 566;
  uint256 constant CircleStarPayload = 213231;
  uint256 constant MinNumCircleStar = 10;
  uint256 constant MaxNumCircleStar = 25;
  uint256 constant CircleStarAnimPayload = 598327;
  uint256 constant MinNumCircleStarAnim = 2;
  uint256 constant MaxNumCircleStarAnim = 7;
  uint256 constant SpeedCircleStartPayload = 438238;
  uint256 constant MinSpeedCircleStar = 5;
  uint256 constant MaxSpeedCircleStar = 15;
  uint256 constant SizeCircleStartPayload = 111287;
  uint256 constant MinSizeCircleStar = 0; // 0.0
  uint256 constant MaxSizeCircleStar = 20; // 2.0
  uint256 constant RhombusStarPayload = 232902;
  uint256 constant MinNumRhombusStar = 1;
  uint256 constant MaxNumRhombusStar = 4;
  uint256 constant RhombusStarAnimPayload = 876298;
  uint256 constant MinNumRhombusStarAnim = 0;
  uint256 constant MaxNumRhombusStarAnim = 2;

  function getSky_backup_v1() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
    '<g id="sky_x5F_4"> ',
    '<linearGradient id="SVGID_1_" gradientUnits="userSpaceOnUse" x1="213.306" y1="7236.2441" x2="213.306" y2="6947.5923" gradientTransform="matrix(2 0 0 1.9641 -143.1475 -13645.4883)"> ',
    '<stop  offset="0" style="stop-color:#4F4E4E"/> ',
    '<stop  offset="1" style="stop-color:#2C1908"/> ',
    '</linearGradient> ',
    '<rect y="0" class="st0" width="566.93" height="566.93"/> ',
    '<path class="st1" d="M56.55,319.66c2.8,0,2.81-4.36,0-4.36C53.75,315.3,53.74,319.66,56.55,319.66z"/> ',
    '<path class="st1" d="M298.51,86.06c2.8,0,2.81-4.36,0-4.36C295.7,81.71,295.7,86.06,298.51,86.06z"/> ',
    '<path class="st1" d="M360.26,542.75c2.8,0,2.81-4.36,0-4.36C357.46,538.39,357.45,542.75,360.26,542.75z"/> ',
    '<path class="st1" d="M29.56,40.5c2.8,0,2.81-4.36,0-4.36C26.76,36.14,26.75,40.5,29.56,40.5z"/> ',
    '<path class="st1" d="M488.74,104.4c2.8,0,2.81-4.36,0-4.36C485.94,100.04,485.93,104.4,488.74,104.4z"/> ',
    '<path class="st1" d="M172.94,539.14c2.8,0,2.81-4.36,0-4.36C170.14,534.78,170.13,539.14,172.94,539.14z"/> ',
    '<path class="st1" d="M504.56,319.85c2.8,0,2.81-4.36,0-4.36C501.75,315.49,501.75,319.85,504.56,319.85z"/> ',
    '<path class="st1" d="M217.78,368.88c2.8,0,2.81-4.36,0-4.36C214.97,364.52,214.97,368.88,217.78,368.88z"/> ',
    '<path class="st1" d="M24.61,353.53c2.8,0,2.81-4.36,0-4.36C21.8,349.17,21.8,353.53,24.61,353.53z"/> ',
    '<path class="st1" d="M537.25,397.61c2.8,0,2.81-4.36,0-4.36C534.44,393.25,534.44,397.61,537.25,397.61z"/> ',
    '<path class="st1" d="M466.91,465.68c2.8,0,2.81-4.36,0-4.36C464.1,461.32,464.1,465.68,466.91,465.68z"/> ',
    '<path class="st1" d="M525.44,20.08c2.8,0,2.81-4.36,0-4.36C522.63,15.72,522.63,20.08,525.44,20.08z"/> ',
    '<path class="st1" d="M259.38,188.99c1.4,0,1.4-2.18,0-2.18C257.98,186.81,257.98,188.99,259.38,188.99z"/> ',
    '<path class="st1" d="M520.12,532.49c1.4,0,1.4-2.18,0-2.18C518.71,530.31,518.71,532.49,520.12,532.49z"/> ',
    '<path class="st1" d="M164.78,215.24c1.4,0,1.4-2.18,0-2.18C163.38,213.06,163.37,215.24,164.78,215.24z"/> ',
    '<path class="st1" d="M287.28,82.65c1.4,0,1.4-2.18,0-2.18C285.88,80.47,285.87,82.65,287.28,82.65z"/> ',
    '<path class="st1" d="M325.91,69.77c1.4,0,1.4-2.18,0-2.18C324.51,67.6,324.51,69.77,325.91,69.77z"/> ',
    '<path class="st1" d="M374.46,526.69c1.4,0,1.4-2.18,0-2.18C373.06,524.51,373.06,526.69,374.46,526.69z"/> ',
    '<path class="st1" d="M468.24,96.86c1.4,0,1.4-2.18,0-2.18C466.84,94.68,466.83,96.86,468.24,96.86z"/> ',
    '<path class="st1" d="M166.52,549.34c1.4,0,1.4-2.18,0-2.18C165.12,547.16,165.11,549.34,166.52,549.34z"/> ',
    '<path class="st1" d="M474.34,112.22c1.4,0,1.4-2.18,0-2.18C472.94,110.04,472.94,112.22,474.34,112.22z"/> ',
    '<path class="st1" d="M532.79,193.45c1.4,0,1.4-2.18,0-2.18C531.39,191.27,531.38,193.45,532.79,193.45z"/> ',
    '<path class="st1" d="M392.42,541.32c1.4,0,1.4-2.18,0-2.18C391.02,539.14,391.02,541.32,392.42,541.32z"/> ',
    '<path class="st1" d="M543.39,543.79c1.4,0,1.4-2.18,0-2.18C541.99,541.61,541.99,543.79,543.39,543.79z"/> ',
    '<path class="st1" d="M46.58,524.21c2.8,0,2.81-4.36,0-4.36C43.77,519.85,43.77,524.21,46.58,524.21z"/> ',
    '<path class="st1" d="M48.99,506.73c1.4,0,1.4-2.18,0-2.18C47.58,504.55,47.58,506.73,48.99,506.73z"/> ',
    '<path class="st1" d="M467.41,347.98c1.4,0,1.4-2.18,0-2.18C466.01,345.8,466,347.98,467.41,347.98z"/> ',
    '<path class="st1" d="M457.6,460.18c1.4,0,1.4-2.18,0-2.18C456.2,458,456.19,460.18,457.6,460.18z"/> ',
    '<path class="st1" d="M270.77,403.45c1.4,0,1.4-2.18,0-2.18C269.37,401.28,269.37,403.45,270.77,403.45z"/> ',
    '<path class="st1" d="M121.69,400.48c1.4,0,1.4-2.18,0-2.18C120.28,398.3,120.28,400.48,121.69,400.48z"/> ',
    '<circle r="1.90" fill="white"> ',
    '<animateMotion dur="15s" repeatCount="indefinite" path="M115.08,49 0,49 M566.93,49 115.08,49" /> ',
    '</circle> ',
    '<path class="st1" d="M159.82,304.39c1.4,0,1.4-2.18,0-2.18C158.42,302.21,158.42,304.39,159.82,304.39z"/> ',
    '<path class="st1" d="M49.37,310.34c1.4,0,1.4-2.18,0-2.18C47.97,308.16,47.97,310.34,49.37,310.34z"/> ',
    '<path class="st1" d="M33.52,224.65c1.4,0,1.4-2.18,0-2.18C32.12,222.47,32.12,224.65,33.52,224.65z"/> ',
    '<path class="st1" d="M37.93,137.61c1.4,0,1.4-2.18,0-2.18C36.53,135.43,36.53,137.61,37.93,137.61z"/> ',
    '<path class="st1" d="M68.19,253.38c1.4,0,1.4-2.18,0-2.18C66.79,251.2,66.79,253.38,68.19,253.38z"/> ',
    '<path class="st1" d="M123.14,43.75c1.4,0,1.4-2.18,0-2.18C121.74,41.57,121.74,43.75,123.14,43.75z"/> ',
    '<circle r="1.90" fill="white"> ',
    '<animateMotion dur="5s" repeatCount="indefinite" path="M37.98,10.68 0,10.68 M566.93,10.68 37.98,10.68" /> ',
    '</circle> ',
    '<circle r="1.90" fill="white"> ',
    '<animateMotion dur="5s" repeatCount="indefinite" path="M97.98,80.68 0,80.68 M566.93,80.68 97.98,80.68" /> ',
    '</circle> ',
    '<circle r="1.20" fill="white"> ',
    '<animateMotion dur="2s" repeatCount="indefinite" path="M812.13,315.01 0,315.01 M566.93,315.01 812.13,315.01" /> ',
    '</circle> ',
    '<path class="st1" d="M24.61,142.43c1.4,0,1.4-2.18,0-2.18C23.2,140.25,23.2,142.43,24.61,142.43z"/> ',
    '<path class="st1" d="M139.02,130.54c1.4,0,1.4-2.18,0-2.18C137.62,128.36,137.62,130.54,139.02,130.54z"/> ',
    '<path class="st1" d="M239.57,100.33c1.4,0,1.4-2.18,0-2.18C238.17,98.15,238.16,100.33,239.57,100.33z"/> ',
    '<path class="st1" d="M349.53,77.54c1.4,0,1.4-2.18,0-2.18C348.12,75.37,348.12,77.54,349.53,77.54z"/> ',
    '<path class="st1" d="M466.91,279.63c1.4,0,1.4-2.18,0-2.18C465.51,277.45,465.51,279.63,466.91,279.63z"/> ',
    '<path class="st1" d="M475.92,440.86c1.4,0,1.4-2.18,0-2.18C474.52,438.68,474.52,440.86,475.92,440.86z"/> ',
    '<path class="st1" d="M513.47,13.65c1.4,0,1.4-2.18,0-2.18C512.07,11.47,512.07,13.65,513.47,13.65z"/> ',
    '<path class="st1" d="M158.1,522.59c1.4,0,1.4-2.18,0-2.18C156.7,520.41,156.69,522.59,158.1,522.59z"/> ',
    '<path class="st1" d="M33.39,164.57l1.91,8.41c0.22,0.99,1.02,1.74,2.01,1.92l8.48,1.53l-8.41,1.91c-0.99,0.22-1.74,1.02-1.92,2.01',
    'l-1.53,8.49l-1.91-8.41c-0.22-0.99-1.02-1.74-2.01-1.92l-8.48-1.53l8.41-1.91c0.99-0.22,1.74-1.02,1.92-2.01L33.39,164.57z" > ',
    '<animateMotion dur="20s" repeatCount="indefinite" path="M36.39,164.5 -30,164.5 M566.93,164.5 36.39,164.5" /> ',
    '</path> ',
    '</g> '
    )
    );
  }

  function getSky(uint256 tokenId_, uint256 revealBlock_) public view returns (string memory svg) {

    svg = string(
      abi.encodePacked(
    '<g id="sky_x5F_4"> ',
    '<linearGradient id="SVGID_1_" gradientUnits="userSpaceOnUse" x1="213.306" y1="7236.2441" x2="213.306" y2="6947.5923" gradientTransform="matrix(2 0 0 1.9641 -143.1475 -13645.4883)"> ',
    '<stop  offset="0" style="stop-color:#4F4E4E"/> ',
    '<stop  offset="1" style="stop-color:#2C1908"/> ',
    '</linearGradient> ',
    '<rect y="0" class="st0" width="566.93" height="566.93"/> ',
    getRandomCircleStar(tokenId_ + CircleStarPayload, revealBlock_),
    getRandomCircleStarMove(tokenId_, revealBlock_),
    '</g> '
    )
    );
  }

  function getRandomCircleStar(uint256 tokenId_, uint256 revealBlock_) private view returns(string memory) {
    uint256 numRandomCircleStar = PlanetRandom.calcRandom(MinNumCircleStar, MaxNumCircleStar, revealBlock_, tokenId_);
    string memory svgCircleStarTemp;
    uint xTemp;
    uint yTemp;
    uint256 sizeTemp;
    for (uint i=0; i < numRandomCircleStar; i++) {
      xTemp = PlanetRandom.calcRandom(XYMin, XYMax, revealBlock_ + i, tokenId_ + i);
      yTemp = PlanetRandom.calcRandom(XYMin, XYMax, revealBlock_ + i, tokenId_ + i);
      svgCircleStarTemp = string(
        abi.encodePacked(
          svgCircleStarTemp,
          getSVGCircleStar(3, xTemp, yTemp)
        )
      );
    }
    return svgCircleStarTemp;
  }

  function getRandomCircleStarMove(uint256 tokenId_, uint256 revealBlock_) private view returns(string memory) {
    uint256 numRandomCircleStart = PlanetRandom.calcRandom(MinNumCircleStarAnim, MaxNumCircleStarAnim, revealBlock_, tokenId_);
    string memory svgCircleStarTemp;
    uint xTemp;
    uint yTemp;
    uint256 sizeTemp;
    uint256 speedTemp;
    for (uint i=0; i < numRandomCircleStart; i++) {
      xTemp = PlanetRandom.calcRandom(XYMin, XYMax, revealBlock_ + i, tokenId_ + i);
      yTemp = PlanetRandom.calcRandom(XYMin, XYMax, revealBlock_ + i, tokenId_ + i);
      speedTemp = PlanetRandom.calcRandom(MinSpeedCircleStar, MaxSpeedCircleStar, revealBlock_ + i, tokenId_ + i);
      svgCircleStarTemp = string(
        abi.encodePacked(
          svgCircleStarTemp,
          getSVGCircleStarMove(3, xTemp, yTemp, speedTemp)
        )
      );
    }
    return svgCircleStarTemp;
  }

  function getSVGCircleStar(uint256 size_, uint256 x, uint256 y) private view returns(string memory svg) {
    svg = string(
      abi.encodePacked(
    '<circle r="',
    uint2str(size_),
        '" cx="',
    uint2str(x),
    '" cy="',
    uint2str(y),
    '" fill="white"> ',
    '</circle> '
      )
  );
  }

  function getSVGCircleStarMove(uint256 size_, uint256 x_, uint256 y_, uint256 speed_) private view returns(string memory svg) {
    svg = string(
      abi.encodePacked(
    '<circle r="',
    uint2str(size_),
        '" fill="white"> ',
    '<animateMotion dur="',
    uint2str(speed_),
    '" repeatCount="indefinite" path="M',
    uint2str(x_),',',uint2str(y_),
    ' 0,',uint2str(y_),' M566.93,',uint2str(y_),' ',uint2str(x_),',',uint2str(y_),'" /> ',
    '</circle> '
      )
  );
  }

  function uint2str(uint i_) internal pure returns (string memory _uintAsString) {
    if (i_ == 0) {
      return "0";
    }
    uint j = i_;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (i_ != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(i_ - i_ / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      i_ /= 10;
    }
    return string(bstr);
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import 'base64-sol/base64.sol';


library PlanetRandom {

  function calcRandom(uint256 _min, uint256 _max, uint256 _blockNumber, uint256 _payload) public view returns (uint256) {
    uint256 _randomHash = uint(keccak256(abi.encodePacked(_blockNumber, blockhash(_blockNumber), _payload)));
    return (_randomHash % _max) + _min;
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