// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils.sol";
library animFactory {

 
  function draw(uint256 eyes, uint256 color, uint256 tokenId) public pure returns (string memory) {
    string[9] memory lightColors = [
        "#ff87ee",
        "#4b56ff",
        "#4bff64",
        "#ff9552",
        "#529cff",
        "#71ff52",
        "#b1ff52",
        "#daff57",
        "#ff3d3d"
    ];
    string[9] memory darkColors = [
        "#c560b7",
        "#2f37b1",
        "#2d9f3d",
        "#ab6336",
        "#366bb3",
        "#669330",
        "#b1ff52",
        "#89a135",
        "#b12929"
    ];

     string memory beholder = _getBeholder();
     string memory top = '<svg version="1.1" width="200" height="200" xmlns="http://www.w3.org/2000/svg" >';
     string memory styles = '#WhiteEye { animation: blink 1s infinite;}@keyframes blink { 0% { transform: translate(0px,0px) scale(1); } 50% { transform: translate(0px, 14px) scale(1, 0); } 100% { transform: translate(0px, 0px) scale(1); }}#body, #BlackMouth, #MouthTeeth, #BlackTeeth, #greenEye { animation: flatten 1s infinite;}@keyframes flatten { 0% { transform: translate(0px,0px) scale(1); } 50% { transform: translate(0px, 4px) scale(1, .8); } 100% { transform: translate(0px, 0px) scale(1); }}#Eye { animation: disapear 1s infinite;}@keyframes disapear { 0% { transform: translate(0px, 0px); opacity: 1; } 33% { transform: translate(1px, 1px); opacity: 1; } 50% { transform: translate(0px, 2px); opacity: 0; } 66% { transform: translate(-1px, 1px); opacity: 1; } 100% { transform: translate(0px, 0px) scaleY(1); opacity: 1; }}.centerEye { animation: circle 1s infinite;}@keyframes circle { 0% { transform: translate(0px, 0px); } 25% { transform: translate(0px, 1px); } 50% { transform: translate(1px, 1px); } 75% { transform: translate(1px, 0px); } 100% { transform: translate(0px, 1px)); opacity: 1; }}';
     string memory colors = string(abi.encodePacked('.lightBody {fill: ', lightColors[color], ' ;} .darkBody {fill: ', darkColors[color] , ';}.white {fill: #DFFFD6;}.black {fill: #021C2B;}'));
     string memory eyeCss = _getEyeAnimations(0, tokenId);
     for (uint8 k = 1; k < eyes; k++) {
       eyeCss = string(abi.encodePacked(eyeCss, _getEyeAnimations(k, tokenId)));
     }
     string memory eyesvgs = _getEye(0);
     for (uint8 k = 1; k < eyes; k++) {
       eyesvgs = string(abi.encodePacked(eyesvgs, _getEye(k)));
     }
    return string(abi.encodePacked(top, '<style> ',styles, colors, eyeCss, '</style><g transform="scale(8 8)">', beholder, eyesvgs,'</g></svg>'));
  }
  function _getEyeAnimations(uint8 eyeNum, uint256 tokenId) public pure returns (string memory){
    if (eyeNum == 0) {  
      uint256 k = (tokenId % 5);    
      string memory eye = string(abi.encodePacked("#eye0 { animation: down 1s infinite;} @keyframes down {0% { transform:  translate(", toString(8 + k),"px, -2px);} 50% {transform: translate(",toString(8 + k), "px, 0px);} 100% { transform: translate(", toString(8 + k),"px, -2px)}}"));
      return eye;
    } else if (eyeNum % 2 == 1) {
      
      uint256 rand = utils.random(string(abi.encodePacked("EYENUM", utils.toString(tokenId), utils.toString(eyeNum))));

      uint256 x = (rand % 2);  
      uint256 y = (rand % 6);    
      string memory eye = string(abi.encodePacked("#eye", toString(eyeNum)," { animation: down", toString(eyeNum)," 1s infinite;} @keyframes down", toString(eyeNum)));
      eye = string(abi.encodePacked(eye, " {0% { transform:  translate(", toString(2 + x),"px,", toString(y),"px);} 50% {transform: translate(", toString(2 + x), "px, ", toString(y+2),"px);} 100% { transform: translate(", toString(2 + x), "px, ", toString(y) , "px)}}"));
      return eye;
    } else {
      uint256 rand = utils.random(string(abi.encodePacked("EYENUM", utils.toString(tokenId), utils.toString(eyeNum))));
      uint256 x = (rand % 2);  
      uint256 y = (rand % 6);   
      string memory eye = string(abi.encodePacked("#eye", toString(eyeNum), " { animation: down", toString(eyeNum)," 1s infinite;} @keyframes down", toString(eyeNum)));
      eye = string(abi.encodePacked(eye," {0% { transform:  translate(", toString(15 + x),"px,", toString(y),"px);} 50% {transform: translate(", toString(15 + x), "px, ", toString(y+2),"px);} 100% { transform: translate(", toString(15 + x), "px, ", toString(y) , "px)}}"));
      return eye;
    }
  }
  function _getEye(uint8 eyeNum) public pure returns (string memory) {
    string memory eye =
      '<rect x="0" y="10" width="1" height="2" class="darkBody" />'
      '<rect x="1" y="9" width="1" height="2" class="darkBody" />'
      '<rect x="1" y="10" width="4" height="2" class="lightBody" />'
      '<rect x="2" y="9" width="2" height="4" class="lightBody" />'
      '<rect x="1" y="12" width="1" height="1" class="darkBody" />'
      '<rect x="1" y="12" width="1" height="1" class="darkBody" />'
      '<rect x="2" y="10" width="2" height="2" fill="#dfffd6" />'
      '<rect x="2" y="10" width="1" height="1" class="centerEye" fill="#021c2b" />'
      '</g>';
    string memory fullEye = string(abi.encodePacked("<g id='eye", toString(eyeNum), "'>",eye));
    return fullEye;
  }

  function _getBeholder() internal pure returns (string memory) {
    string memory beholder =
      unicode'<g id="body">'
      unicode'<rect x="7" y="11" width="1" height="10" class="darkBody" />'
      unicode'<rect x="6" y="12" width="1" height="8" class="darkBody" />'
      unicode'<rect x="8" y="10" width="1" height="1" class="darkBody" />'
      unicode'<rect x="7" y="12" width="11" height="8" class="lightBody" />'
      unicode'<rect x="8" y="11" width="9" height="10" class="lightBody" />'
      unicode'<rect x="8" y="10" width="8" height="11" class="lightBody" />'
      unicode'<rect x="11" y="21" width="3" height="1" class="lightBody" />'
      unicode'<rect x="8" y="10" width="1" height="1" class="darkBody" />'
      unicode'<rect x="10" y="21" width="1" height="1" class="darkBody" /></g>'
      unicode'<g id="greenEye">'
      unicode'<rect x="10" y="11" width="5" height="3" class="darkBody" />'
      unicode'<rect x="9" y="12" width="7" height="1" class="darkBody" /></g>'
      unicode'<g id="WhiteEye">'
      unicode'<rect x="10" y="12" width="5" height="2" fill="#DFFFD6" />'
      unicode'<rect x="11" y="13" width="3" height="2" fill="#DFFFD6" /></g>'
      unicode'<g id="Eye">'
      unicode'<rect x="12" y="12" width="1" height="1" fill="#021C2B" /></g>'
      unicode'<g id="BlackMouth">'
      unicode'<rect x="9" y="16" width="7" height="4" fill="#021C2B" />'
      unicode'<rect x="8" y="17" width="9" height="2" fill="#021C2B" /></g>'
      unicode'<g id="MouthTeeth">'
      unicode'<rect x="11" y="16" width="1" height="1" fill="#DFFFD6" />'
      unicode'<rect x="13" y="16" width="1" height="1" fill="#DFFFD6" />'
      unicode'<rect x="8" y="19" width="9" height="1" fill="#DFFFD6" /></g>'
      unicode'<g id="BlackTeeth">'
      unicode'<rect x="8" y="18" width="1" height="2" fill="#021C2B" />'
      unicode'<rect x="11" y="18" width="1" height="2" fill="#021C2B" />'
      unicode'<rect x="13" y="18" width="1" height="2" fill="#021C2B" />'
      unicode'<rect x="16" y="18" width="1" height="2" fill="#021C2B" /></g>';
    return beholder;
  }

  function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library utils {

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
}