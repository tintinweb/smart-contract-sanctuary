// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library animFactory {


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

  

  function draw(uint256 headLevel, uint256 tokenId) public pure returns (string memory) {
    string[9] memory helmet_colors = [
      "#555555;", //grey
      "#ff0500;", //red
      "#00ff3c;", //green
      "#009cff;", //lightblue
      "#6d39df;", //purple
      "#df39c0;", //pink
      "#d9df39;", //yellow
      "#64e5c9;", //teal
      "#ff9200;" //orange
    ];

    string[17] memory cycle_color = [
      "#0022ff;", 
      "#1533f6d9;", 
      "#1533f6b0;", 
      "#1533f687;", 
      "#1533f65c;", 
      "#1533f61c;", 
      "#4809b9c7;", 
      "#085642;", 
      "#152e2a;", 
      "#555555;", 
      "#ff0500;", 
      "#00ff3c;", 
      "#009cff;",
      "#6d39df;", 
      "#df39c0;",
      "#64e5c9;",
      "#ff9200;"
    ];

     string memory color = "auto;";
     if (headLevel < 10) {
       color = helmet_colors[headLevel];
     }
     uint256 colorCycle = tokenId % 16;
     string memory color2 = cycle_color[colorCycle];
     string memory custom_colors_css = string(abi.encodePacked(".color1 { fill: ", color, " } .color2 { fill: ", color2, " }"));
     string memory anim1 = _getCycle();
     string memory top = '<svg version="1.1" width="200" height="200" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" preserveAspectRatio="xMinYMin meet" shape-rendering="crispEdges"><rect width="100%" height="100%" fill="grey" />';
     string memory styles = '.base { fill: white; font-family: serif; font-size: 14px; } .neon { fill: #00ff6b; } .owned { fill: #ff2121; } #tire1, #tire2, #tire3 { opacity: 0; -webkit-animation-duration: 0.75s; animation-duration: 0.75s; -webkit-animation-iteration-count: infinite; animation-iteration-count: infinite; -webkit-animation-timing-function: steps(1); animation-timing-function: steps(1); } @-webkit-keyframes shapes-1 { 0% { opacity: 1; } 33.33333% { opacity: 0; } } @keyframes shapes-1 { 0% { opacity: 1; } 33.33333% { opacity: 0; } } :nth-child(1) { -webkit-animation-name: shapes-1; animation-name: shapes-1; } @-webkit-keyframes shapes-2 { 33.33333% { opacity: 1; } 66.66667% { opacity: 0; } } @keyframes shapes-2 { 33.33333% { opacity: 1; } 66.66667% { opacity: 0; } } :nth-child(2) { -webkit-animation-name: shapes-2; animation-name: shapes-2; } @-webkit-keyframes shapes-3 { 66.66667% { opacity: 1; } 100% { opacity: 0; } } @keyframes shapes-3 { 66.66667% { opacity: 1; } 100% { opacity: 0; } } :nth-child(3) { -webkit-animation-name: shapes-3; animation-name: shapes-3; }';
    return string(abi.encodePacked(top, '<style> ',styles, custom_colors_css, ';</style><g transform="scale(2 2)  translate(42 20)">', anim1, '</g>'));
  }

  function _getCycle() internal pure returns (string memory) {
    string memory cycle =    
        unicode'<rect x="4" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="5" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="6" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="7" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="8" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="9" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="10" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="0" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="3" y="1" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="1" width="1" height="1" fill="#555555" />'
        unicode'<rect x="5" y="1" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="1" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="1" width="1" height="1" fill="#555555" />'
        unicode'<rect x="8" y="1" width="1" height="1" fill="#555555" />'
        unicode'<rect x="9" y="1" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="1" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="1" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="1" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="2" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="3" y="2" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="2" width="1" height="1" fill="#555555" />'
        unicode'<rect x="5" y="2" width="1" height="1" fill="#555555" />'
        unicode'<rect x="6" y="2" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="7" y="2" width="1" height="1" fill="#555555" />'
        unicode'<rect x="8" y="2" width="1" height="1" fill="#555555" />'
        unicode'<rect x="9" y="2" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="10" y="2" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="2" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="2" width="1" height="1" fill="#000000" />'
        unicode'<rect x="2" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="3" width="1" height="1" fill="#555555" />'
        unicode'<rect x="4" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="3" width="1" height="1" fill="#555555" />'
        unicode'<rect x="6" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="3" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="3" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="3" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="3" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="4" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="10" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="4" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="5" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="5" width="1" height="1" fill="#555555" />'
        unicode'<rect x="5" y="5" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#555555" />'
        unicode'<rect x="10" y="5" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="5" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="5" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="6" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="6" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="5" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="6" y="6" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="9" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="10" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="6" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="6" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="6" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="3" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="7" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="7" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="7" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="8" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="9" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="10" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="11" y="7" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="7" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="8" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="8" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="8" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="8" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="5" y="8" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="3" y="25" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="3" y="26" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="6" y="8" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="7" y="8" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="8" y="8" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="9" y="8" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="10" y="8" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="11" y="8" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="12" y="8" width="1" height="1" fill="#000000" />'
        unicode'<rect x="13" y="8" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="14" y="8" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="9" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="9" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="4" y="9" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="5" y="9" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="6" y="9" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="7" y="9" width="1" height="1" fill="#A3101F" />'
        unicode'<rect x="8" y="9" width="1" height="1" fill="#A3101F" />'
        unicode'<rect x="9" y="9" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="10" y="9" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="11" y="9" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="12" y="9" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="13" y="9" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="10" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="10" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="10" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="4" y="10" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="5" y="10" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="6" y="10" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="7" y="10" width="1" height="1" fill="#A3101F" />'
        unicode'<rect x="8" y="10" width="1" height="1" fill="#A3101F" />'
        unicode'<rect x="9" y="10" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="10" y="10" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="11" y="10" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="12" y="10" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="13" y="10" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="10" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="0" y="11" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="11" width="1" height="1" fill="#555555" />'
        unicode'<rect x="2" y="11" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="3" y="11" width="1" height="1" fill="#555555" />'
        unicode'<rect x="4" y="11" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="5" y="11" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="6" y="11" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="7" y="11" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="8" y="11" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="9" y="11" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="10" y="11" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="11" y="11" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="12" y="11" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="11" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="14" y="11" width="1" height="1" fill="#555555" />'
        unicode'<rect x="0" y="12" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="12" width="1" height="1" fill="#555555" />'
        unicode'<rect x="2" y="12" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="12" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="12" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="12" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="12" width="1" height="1" fill="#555555" />'
        unicode'<rect x="0" y="13" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="13" width="1" height="1" fill="#555555" />'
        unicode'<rect x="2" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="13" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="13" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="13" y="13" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="14" y="13" width="1" height="1" fill="#555555" />'
        unicode'<rect x="1" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="2" y="14" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="3" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="14" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="5" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="14" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="14" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="13" y="14" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="14" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="0" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="15" width="1" height="1" fill="#555555" />'
        unicode'<rect x="2" y="15" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="5" y="15" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="7" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="8" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="9" y="15" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="11" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="12" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="15" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="15" width="1" height="1" fill="#555555" />'
        unicode'<rect x="0" y="16" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="16" width="1" height="1" fill="#452408" />'
        unicode'<rect x="2" y="16" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="3" y="16" width="1" height="1" fill="#452408" />'
        unicode'<rect x="4" y="16" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="16" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="16" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="16" width="1" height="1" fill="#452408" />'
        unicode'<rect x="13" y="16" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="14" y="16" width="1" height="1" fill="#452408" />'
        unicode'<rect x="1" y="17" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="17" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="3" y="17" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="4" y="17" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="17" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="17" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="17" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="17" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="14" y="17" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="18" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="18" width="1" height="1" fill="#452408" />'
        unicode'<rect x="3" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="13" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="14" y="18" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="19" width="1" height="1" fill="#452408" />'
        unicode'<rect x="3" y="19" width="1" height="1" fill="#452408" />'
        unicode'<rect x="4" y="19" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="19" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="19" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="19" width="1" height="1" fill="#452408" />'
        unicode'<rect x="13" y="19" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="20" width="1" height="1" fill="#452408" />'
        unicode'<rect x="3" y="20" width="1" height="1" fill="#452408" />'
        unicode'<rect x="4" y="20" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="20" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="20" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="12" y="20" width="1" height="1" fill="#452408" />'
        unicode'<rect x="13" y="20" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="21" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="21" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="3" y="21" width="1" height="1" fill="#555555" />'
        unicode'<rect x="4" y="21" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="21" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="21" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="21" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="21" width="1" height="1" fill="#452408" />'
        unicode'<rect x="14" y="21" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="2" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="22" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="22" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="22" width="1" height="1" fill="#452408" />'
        unicode'<rect x="14" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="1" y="23" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="23" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="23" width="1" height="1" fill="#555555" />'
        unicode'<rect x="4" y="23" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="23" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="23" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="12" y="23" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="23" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="14" y="23" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="24" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="24" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="13" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="14" y="24" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="25" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="25" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="25" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="4" y="26" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="26" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="26" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="4" y="27" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="27" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="28" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="28" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="29" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="30" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="31" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="32" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="32" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="33" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="33" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="2" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="36" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="36" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="36" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="36" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="36" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="37" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="37" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="37" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="37" width="1" height="1" fill="#000000" />';
    return cycle;
  }
}