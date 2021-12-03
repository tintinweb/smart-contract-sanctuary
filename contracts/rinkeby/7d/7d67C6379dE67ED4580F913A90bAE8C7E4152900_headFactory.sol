// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library headFactory {

  function draw(uint256 number) public pure returns (string memory) {
     string memory head = _getHelmet(number);
     return string(head);
  }

  function _getHelmet(uint256 number) internal pure returns (string memory) {
    string memory helmet = 
      unicode'<g transform="scale(2 2)  translate(42 13)">'
      unicode'<rect x="7" y="3" width="1" height="1" fill="#30323F" />'
      unicode'<rect x="8" y="3" width="1" height="1" fill="#30323F" />'
      unicode'<rect x="6" y="4" width="1" height="1" fill="#30323F" />'
      unicode'<rect x="7" y="4" width="1" height="1" class="color1" fill="#555555" />'
      unicode'<rect x="8" y="4" width="1" height="1" class="color1" fill="#555555" />'
      unicode'<rect x="9" y="4" width="1" height="1" fill="#30323F" />'
      unicode'<rect x="6" y="5" width="1" height="1" fill="#000000" />'
      unicode'<rect x="7" y="5" width="1" height="1" class="color1" fill="#555555" />'
      unicode'<rect x="8" y="5" width="1" height="1" class="color1" fill="#555555" />'
      unicode'<rect x="9" y="5" width="1" height="1" fill="#000000" />'
      unicode'<rect x="6" y="6" width="1" height="1" fill="#000000" />'
      unicode'<rect x="7" y="6" width="1" height="1" fill="#000000" />'
      unicode'<rect x="8" y="6" width="1" height="1" fill="#000000" />'
      unicode'<rect x="9" y="6" width="1" height="1" fill="#000000" />'
      unicode'</g>'; 
      string memory beanie =       
        unicode'<g transform="scale(2 2)  translate(42 13)">'
        unicode'<rect x="7" y="2" width="1" height="1" fill="#9848BB" />'
        unicode'<rect x="8" y="2" width="1" height="1" fill="#9848BB" />'
        unicode'<rect x="9" y="2" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="3" width="1" height="1" fill="#9848BB" />'
        unicode'<rect x="8" y="3" width="1" height="1" fill="#9848BB" />'
        unicode'<rect x="9" y="3" width="1" height="1" fill="#9848BB" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="10" y="4" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="5" y="5" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="10" y="5" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="5" y="6" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="6" y="6" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="9" y="6" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="10" y="6" width="1" height="1" fill="#3B7B2B" />'
        unicode'</g>';
        string memory blue_vertical = 
          unicode'<g transform="scale(2 2)  translate(42 13)">'
          unicode'<rect x="8" y="0" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="7" y="1" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="8" y="1" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="10" y="1" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="4" y="2" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="5" y="2" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="6" y="2" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="7" y="2" width="1" height="1" fill="#61E8FF" />'
          unicode'<rect x="8" y="2" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="9" y="2" width="1" height="1" fill="#61E8FF" />'
          unicode'<rect x="10" y="2" width="1" height="1" fill="#61E8FF" />'
          unicode'<rect x="5" y="3" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="6" y="3" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="7" y="3" width="1" height="1" fill="#61E8FF" />'
          unicode'<rect x="8" y="3" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="9" y="3" width="1" height="1" fill="#61E8FF" />'
          unicode'<rect x="10" y="3" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="5" y="4" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="6" y="4" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="7" y="4" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="8" y="4" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="9" y="4" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="6" y="5" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="7" y="5" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="8" y="5" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="9" y="5" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="6" y="6" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="7" y="6" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="8" y="6" width="1" height="1" fill="#EEC39A" />'
          unicode'</g>';
        string memory half_buzzed = 
          unicode'<g transform="scale(2 2)  translate(42 13)">'
          unicode'<rect x="7" y="2" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="8" y="2" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="6" y="3" width="1" height="1" fill="#5435FB" />'
          unicode'<rect x="7" y="3" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="8" y="3" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="9" y="3" width="1" height="1" fill="#786C7A" />'
          unicode'<rect x="5" y="4" width="1" height="1" fill="#5435FB" />'
          unicode'<rect x="6" y="4" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="7" y="4" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="8" y="4" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="9" y="4" width="1" height="1" fill="#786C7A" />'
          unicode'<rect x="5" y="5" width="1" height="1" fill="#5435FB" />'
          unicode'<rect x="6" y="5" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="7" y="5" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="8" y="5" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="9" y="5" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="5" y="6" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="6" y="6" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="7" y="6" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="8" y="6" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="9" y="6" width="1" height="1" fill="#E1D69A" />'
          unicode'</g>';

      string memory horns = 
        unicode'<g transform="scale(2 2)  translate(42 13)">'
        unicode'<rect x="5" y="3" width="1" height="1" fill="#53676B" />'
        unicode'<rect x="10" y="3" width="1" height="1" fill="#53676B" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#53676B" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#53676B" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="6" y="6" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="9" y="6" width="1" height="1" fill="#FFF7E9" />'
        unicode'</g>';
      string memory pigtails = 
        unicode'<g transform="scale(2 2)  translate(42 13)">'
        unicode'<rect x="6" y="3" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="7" y="3" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="8" y="3" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="9" y="3" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="5" y="5" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="10" y="5" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="3" y="6" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="4" y="6" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="5" y="6" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="6" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#CB9B4F" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#CB9B4F" />'
        unicode'<rect x="9" y="6" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="10" y="6" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="6" width="1" height="1" fill="#FF53DD" />'
        unicode'</g>';

      string memory straight_long =
        unicode'<g transform="scale(2 2)  translate(42 13)">'
        unicode'<rect x="6" y="2" width="1" height="1" class="color1" fill="#555555" />'
        unicode'<rect x="7" y="2" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="8" y="2" width="1" height="1" class="color1" fill="#555555" />'
        unicode'<rect x="9" y="2" width="1" height="1" class="color1" fill="#555555" />'
        unicode'<rect x="6" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="3" width="1" height="1" fill="#222122" />'
        unicode'<rect x="8" y="3" width="1" height="1" fill="#971BC3" />'
        unicode'<rect x="9" y="3" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#222122" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#222122" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#971BC3" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#040404" />'
        unicode'<rect x="5" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#BB44E6" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#222122" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#040404" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#040404" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#EEC39A" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#EEC39A" />'
        unicode'</g>';
      string memory cowboy = 
        unicode'<g transform="scale(2 2)  translate(42 13)">'
        unicode'<rect x="7" y="0" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="8" y="0" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="6" y="1" width="1" height="1" fill="#543D27" />'
        unicode'<rect x="7" y="1" width="1" height="1" fill="#543D27" />'
        unicode'<rect x="8" y="1" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="9" y="1" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="6" y="2" width="1" height="1" fill="#543D27" />'
        unicode'<rect x="7" y="2" width="1" height="1" fill="#543D27" />'
        unicode'<rect x="8" y="2" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="9" y="2" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="4" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="6" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="7" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="8" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="9" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="10" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="5" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#2B1F12" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#2B1F12" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#2B1F12" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#2B1F12" />'
        unicode'<rect x="10" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="5" width="1" height="1" fill="#9DFAFF" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="10" y="5" width="1" height="1" fill="#9DFAFF" />'
        unicode'<rect x="6" y="6" width="1" height="1" fill="#222222" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="9" y="6" width="1" height="1" fill="#594310" />'
        unicode'</g>';

      string[17] memory heads = [
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        straight_long,
        pigtails,
        half_buzzed,
        blue_vertical,
        horns,
        beanie,
        cowboy
      ];
      return heads[number];    
  }  
}