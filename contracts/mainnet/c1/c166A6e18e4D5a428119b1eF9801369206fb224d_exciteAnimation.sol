// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./points.sol";
library exciteAnimation {

 
  function draw(uint256 tokenId, uint256 pts) public pure returns (string memory) {
  string memory top = '<svg version="1.1" width="400" height="400" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">';
  string memory styles = _getStyle();
  string memory scene = _getScene();

 return string(abi.encodePacked(top, styles, '<g id="image" transform="scale(4 4)">', scene, '</g></svg>'));
  }
  function _getStyle() internal pure returns (string memory) {
    string memory styles = '<![CDATA[.br{fill:#8f6a09}.B{fill:#ef34c9}.C{fill:#2b2932}.D{fill:#ff53dd}.E{fill:#2e2a37}.F{fill:#211f28}.G{fill:#1439b9}.H{fill:#fdd3a6}.I{fill:#4f5267}.J{fill:#2d2939}.K{fill:#13110f}.L{fill:#3b364b}.M{fill:#121111}.N{fill:#3f3d46}.O{fill:#6a8a90}.P{fill:#9b4930}.Q{fill:#fafbf6}]]>#biker{animation:down 2s infinite linear;transform-origin:center center;}@keyframes down{0%{transform:translate(25px,50px)}5%{transform:translate(25px,50px)}5%{transform:translate(53px,0) rotate(-10deg)}15%{transform:translate(72.5px,-50px) rotate(-20deg)}25%{transform:translate(86px,-100px) rotate(-30deg)}30%{transform:translate(94px,-135px) rotate(-38deg)}35%{transform:translate(95px,-165px) rotate(-45deg)}50%{transform:translate(95px,-165px) rotate(-45deg)}60%{transform:translate(94px,-124px) rotate(-38deg)}66%{transform:translate(90px,-83px) rotate(-30deg)}88%{transform:translate(76px,-19px) rotate(-18deg)}100%{transform:translate(25px,50px)}}#bump{animation:roadMove 2s infinite linear}@keyframes roadMove{0%{transform:translate(50px,50px)}80%{transform:translate(-650px,50px)}80.1%{transform:translate(100px,50px)}100%{transform:translate(50px,50px)}}#path{animation:pathMove 2s infinite linear}@keyframes pathMove{0%{transform:translate(0,0)}80%{transform:translate(-750px,0)}80.1%{transform:translate(100px,0)}100%{transform:translate(0,0)}}';

  return string(abi.encodePacked('<style>', pointsLib._getPointsCss(), styles, '</style>'));
  }
  function _getBackground() internal pure returns (string memory) {
 string memory background = '<rect x="0" y="0" width="100" height="100" fill="#8BC53F" />';
 return background;
  }
  
  function _getRoad() internal pure returns (string memory) {
 string memory road = 
  unicode'<g id="road" transform="translate(0 50)">'
  unicode'<rect x="0" y="26" width="100" height="9" fill="#FAAA03" />'
  unicode'<g id="path">'
  unicode'<path class="br" d="M0 28h1v1H0zm3 0h1v1H3z"/><path class="br" d="M4 28h1v1H4zm2 0h1v1H6z"/><path class="br" d="M7 28h1v1H7zm2 0h1v1H9z"/><path class="br" d="M10 28h1v1h-1z"/><path class="br" d="M11 28h1v1h-1z"/><path class="br" d="M12 28h1v1h-1z"/><path class="br" d="M13 28h1v1h-1zm4 0h1v1h-1z"/><path class="br" d="M18 28h1v1h-1zm2 0h1v1h-1z"/><path class="br" d="M21 28h1v1h-1zm4 0h1v1h-1z"/><path class="br" d="M26 28h1v1h-1z"/><path class="br" d="M27 28h1v1h-1z"/><path class="br" d="M28 28h1v1h-1z"/><path class="br" d="M29 28h1v1h-1zm9 0h1v1h-1z"/><path class="br" d="M39 28h1v1h-1z"/><path class="br" d="M40 28h1v1h-1z"/><path class="br" d="M41 28h1v1h-1zm5 0h1v1h-1z"/><path class="br" d="M47 28h1v1h-1z"/><path class="br" d="M48 28h1v1h-1z"/><path class="br" d="M49 28h1v1h-1z"/><path class="br" d="M50 28h1v1h-1z"/><path class="br" d="M51 28h1v1h-1z"/><path class="br" d="M52 28h1v1h-1z"/><path class="br" d="M53 28h1v1h-1z"/><path class="br" d="M54 28h1v1h-1zm7 0h1v1h-1zm5 0h1v1h-1z"/><path class="br" d="M67 28h1v1h-1zm-19 0h1v1h-1zm31 0h1v1h-1zm-9 0h1v1h-1z"/><path class="br" d="M71 28h1v1h-1zm11 0h1v1h-1z"/><path class="br" d="M83 28h1v1h-1z"/><path class="br" d="M84 28h1v1h-1z"/>'
  unicode'</g>'
  unicode'</g>';
  return road;
  }
  
  function _getBiker() internal pure returns (string memory) {
 string memory biker = 
 unicode'<g id="biker">'
 unicode'<path d="M13 12h1v1h-1z" class="B"/><path d="M14 12h1v1h-1z" class="D"/><g class="B"><path d="M15 12h1v1h-1z"/><path d="M16 12h1v1h-1z"/></g><path d="M12 13h1v1h-1z" class="D"/><g class="B"><path d="M13 13h1v1h-1z"/><path d="M14 13h1v1h-1z"/></g><g class="D"><path d="M15 13h1v1h-1z"/><path d="M16 13h1v1h-1z"/></g><path d="M17 13h1v1h-1zm-5 1h1v1h-1z" class="B"/><path d="M13 14h1v1h-1z" class="D"/><path d="M14 14h1v1h-1z" class="B"/><g class="H"><path d="M15 14h1v1h-1z"/><path d="M16 14h1v1h-1z"/><path d="M17 14h1v1h-1z"/></g><path d="M9 15h1v1H9z" class="B"/><path d="M10 15h1v1h-1z" class="D"/><path d="M11 15h1v1h-1z" class="K"/><path d="M12 15h1v1h-1z" class="D"/><path d="M13 15h1v1h-1z" class="B"/><path d="M14 15h1v1h-1z" class="D"/><g class="H"><path d="M15 15h1v1h-1z"/><path d="M16 15h1v1h-1z"/><path d="M17 15h1v1h-1z"/></g><g class="D"><path d="M8 16h1v1H8z"/><path d="M9 16h1v1H9z"/></g><path d="M10 16h1v1h-1z" class="B"/><g class="D"><path d="M12 16h1v1h-1z"/><path d="M13 16h1v1h-1z"/></g><path d="M14 16h1v1h-1z" class="B"/><g fill="#cd7a6d"><path d="M15 16h1v1h-1z"/><path d="M16 16h1v1h-1z"/></g><path fill="#cb7874" d="M17 16h1v1h-1z"/><path d="M8 17h1v1H8z" class="D"/><path d="M12 17h1v1h-1z" class="K"/><path d="M13 17h1v1h-1z" class="B"/><g class="H"><path d="M14 17h1v1h-1z"/><path d="M15 17h1v1h-1z"/></g><path d="M16 17h1v1h-1z" class="L"/><path d="M17 17h1v1h-1z" class="K"/><path d="M11 18h1v1h-1z" class="J"/><path d="M12 18h1v1h-1z" class="B"/><path fill="#2e2934" d="M13 18h1v1h-1z"/><path fill="#df997a" d="M14 18h1v1h-1z"/><path fill="#fdd3ab" d="M15 18h1v1h-1z"/><path d="M16 18h1v1h-1z" class="H"/><path fill="#3c3d4c" d="M17 18h1v1h-1z"/><path fill="#bdbdbd" d="M22 18h1v1h-1z"/><g class="B"><path d="M10 19h1v1h-1z"/><path d="M11 19h1v1h-1z"/><path d="M12 19h1v1h-1z"/></g><path d="M13 19h1v1h-1z" class="E"/><path fill="#2e283b" d="M14 19h1v1h-1z"/><path fill="#de987d" d="M15 19h1v1h-1z"/><g class="H"><path d="M16 19h1v1h-1z"/><path d="M17 19h1v1h-1z"/></g><path fill="#df997a" d="M18 19h1v1h-1z"/><path fill="#45464a" d="M19 19h1v1h-1z"/><path fill="#16110a" d="M20 19h1v1h-1z"/><path fill="#131112" d="M21 19h1v1h-1z"/><path fill="#fdd3ab" d="M22 19h1v1h-1z"/><path d="M23 19h1v1h-1z" class="G"/><path d="M10 20h1v1h-1z" class="B"/><path d="M12 20h1v1h-1z"/><path d="M13 20h1v1h-1z" class="E"/><path d="M14 20h1v1h-1z" class="M"/><path fill="#493f4d" d="M15 20h1v1h-1z"/><path fill="#d69684" d="M16 20h1v1h-1z"/><path fill="#dd957b" d="M17 20h1v1h-1z"/><path fill="#d69684" d="M18 20h1v1h-1z"/><path d="M19 20h1v1h-1z"/><path d="M20 20h1v1h-1z"/><path d="M23 20h1v1h-1z" class="G"/><path fill="#a9a9a9" d="M24 20h1v1h-1z"/><path fill="red" d="M6 21h1v1H6z"/><path d="M7 21h1v1H7z" class="C"/><g class="N"><path d="M8 21h1v1H8z"/><path d="M9 21h1v1H9z"/></g><path fill="#974a34" d="M11 21h1v1h-1z"/><path fill="#964d3b" d="M12 21h1v1h-1z"/><path fill="#111" d="M13 21h1v1h-1z"/><g class="O"><path d="M14 21h1v1h-1z"/><path d="M15 21h1v1h-1z"/></g><path d="M16 21h1v1h-1z"/><path d="M17 21h1v1h-1z"/><path d="M18 21h1v1h-1z" class="G"/><path d="M19 21h1v1h-1z" class="L"/><path d="M20 21h1v1h-1z" class="J"/><g class="E"><path d="M21 21h1v1h-1z"/><path d="M22 21h1v1h-1z"/></g><path fill="#1e43c3" d="M23 21h1v1h-1z"/><path d="M24 21h1v1h-1z" class="G"/><path d="M8 22h1v1H8z" class="C"/><path fill="#302836" d="M9 22h1v1H9z"/><path d="M10 22h1v1h-1z" class="E"/><path d="M11 22h1v1h-1z" class="I"/><path d="M12 22h1v1h-1z" class="O"/><path fill="#4e5468" d="M13 22h1v1h-1z"/><path d="M14 22h1v1h-1z" class="I"/><path fill="#4e5468" d="M15 22h1v1h-1z"/><g fill="#f3b48c"><path d="M16 22h1v1h-1z"/><path d="M17 22h1v1h-1z"/></g><g class="E"><path d="M18 22h1v1h-1z"/><path d="M19 22h1v1h-1z"/><path d="M20 22h1v1h-1z"/><path d="M21 22h1v1h-1z"/></g><path d="M22 22h1v1h-1z" class="J"/><path d="M23 22h1v1h-1z" class="G"/><path fill="#111" d="M9 23h1v1H9z"/><path d="M10 23h1v1h-1z" class="M"/><path d="M11 23h1v1h-1z" class="I"/><path fill="#505164" d="M12 23h1v1h-1z"/><path d="M13 23h1v1h-1z" class="I"/><path d="M14 23h1v1h-1z" class="M"/><path d="M15 23h1v1h-1z" class="I"/><path fill="#678a96" d="M16 23h1v1h-1z"/><path d="M17 23h1v1h-1z" class="O"/><g class="E"><path d="M18 23h1v1h-1z"/><path d="M19 23h1v1h-1z"/><path d="M20 23h1v1h-1z"/><path d="M21 23h1v1h-1z"/></g><path fill="#2a2831" d="M22 23h1v1h-1z"/><path fill="#0025a5" d="M23 23h1v1h-1z"/><path d="M8 24h1v1H8z"/><path fill="#c7d1d5" d="M9 24h1v1H9z"/><path fill="#767e85" d="M10 24h1v1h-1z"/><path d="M11 24h1v1h-1z" class="E"/><path fill="#78798a" d="M12 24h1v1h-1z"/><path fill="#b7bbbf" d="M13 24h1v1h-1z"/><path fill="#111" d="M14 24h1v1h-1z"/><g fill="#0f1014"><path d="M15 24h1v1h-1z"/><path d="M16 24h1v1h-1z"/></g><path d="M17 24h1v1h-1z" class="P"/><path fill="#777989" d="M18 24h1v1h-1z"/><path fill="#bec0bc" d="M19 24h1v1h-1z"/><path d="M20 24h1v1h-1z" class="Q"/><path fill="#c1c1be" d="M21 24h1v1h-1z"/><path fill="#bec0bc" d="M22 24h1v1h-1z"/><path d="M23 24h1v1h-1z" class="G"/><path fill="#0025a5" d="M24 24h1v1h-1z"/><path d="M25 24h1v1h-1zM7 25h1v1H7z"/><path d="M8 25h1v1H8z" class="C"/><g fill="#000001"><path d="M9 25h1v1H9z"/><path d="M10 25h1v1h-1z"/></g><path fill="#2d2c3b" d="M11 25h1v1h-1z"/><path fill="#797d86" d="M12 25h1v1h-1z"/><path fill="#2b2b30" d="M13 25h1v1h-1z"/><path fill="#797d86" d="M14 25h1v1h-1z"/><path d="M15 25h1v1h-1z" class="Q"/><path fill="#141017" d="M16 25h1v1h-1z"/><path d="M17 25h1v1h-1z" class="P"/><path fill="#7a798c" d="M18 25h1v1h-1z"/><g class="Q"><path d="M19 25h1v1h-1z"/><path d="M20 25h1v1h-1z"/></g><path fill="#c3c3bd" d="M21 25h1v1h-1z"/><path d="M22 25h1v1h-1z" class="J"/><path fill="#67656e" d="M23 25h1v1h-1z"/><path d="M24 25h1v1h-1z" class="F"/><path d="M25 25h1v1h-1z" class="C"/><path d="M26 25h1v1h-1zM6 26h1v1H6z"/><path d="M7 26h1v1H7z"/><path fill="#342635" d="M9 26h1v1H9z"/><path fill="#2e2934" d="M10 26h1v1h-1z"/><path fill="#2f2b37" d="M11 26h1v1h-1z"/><path fill="#2d2c3b" d="M12 26h1v1h-1z"/><path d="M13 26h1v1h-1z" class="L"/><path fill="#bec1bd" d="M14 26h1v1h-1z"/><path fill="#f6faf9" d="M15 26h1v1h-1z"/><path fill="#fcfcfd" d="M16 26h1v1h-1z"/><path fill="#150e12" d="M17 26h1v1h-1z"/><path d="M18 26h1v1h-1z" class="P"/><path fill="#994931" d="M19 26h1v1h-1z"/><path fill="#190c0e" d="M20 26h1v1h-1z"/><path fill="#c0c2bd" d="M21 26h1v1h-1z"/><path fill="#2c2b34" d="M22 26h1v1h-1z"/><path d="M23 26h1v1h-1z" class="N"/><path d="M24 26h1v1h-1z" class="F"/><path d="M26 26h1v1h-1z"/><path d="M27 26h1v1h-1zM6 27h1v1H6z"/><path d="M7 27h1v1H7z" class="C"/><path d="M8 27h1v1H8z" class="F"/><path d="M9 27h1v1H9z" class="N"/><g class="C"><path d="M10 27h1v1h-1z"/><path d="M11 27h1v1h-1z"/></g><path d="M12 27h1v1h-1z"/><path fill="#35333c" d="M14 27h1v1h-1z"/><path d="M15 27h1v1h-1z"/><path fill="#35333c" d="M16 27h1v1h-1z"/><g class="C"><path d="M17 27h1v1h-1z"/><path d="M18 27h1v1h-1z"/></g><path fill="#3a363f" d="M19 27h1v1h-1z"/><path d="M20 27h1v1h-1z" class="C"/><path d="M21 27h1v1h-1z"/><g class="F"><path d="M22 27h1v1h-1z"/><path d="M23 27h1v1h-1z"/></g><path fill="#67656e" d="M24 27h1v1h-1z"/><path d="M25 27h1v1h-1z" class="F"/><path d="M26 27h1v1h-1z" class="C"/><path d="M27 27h1v1h-1zM6 28h1v1H6z"/><path d="M7 28h1v1H7z"/><path d="M9 28h1v1H9z" class="F"/><path d="M11 28h1v1h-1z"/><path d="M12 28h1v1h-1zm9 0h1v1h-1z"/><path d="M22 28h1v1h-1z" class="C"/><path d="M24 28h1v1h-1z" class="F"/><path d="M26 28h1v1h-1z"/><path d="M27 28h1v1h-1zM7 29h1v1H7z"/><path d="M8 29h1v1H8z"/><path d="M9 29h1v1H9z" class="C"/><path d="M10 29h1v1h-1z"/><path d="M11 29h1v1h-1zm11 0h1v1h-1z"/><path d="M23 29h1v1h-1z"/><path d="M24 29h1v1h-1z" class="C"/><path d="M25 29h1v1h-1z"/><path d="M26 29h1v1h-1zM8 30h1v1H8z"/><path d="M9 30h1v1H9z"/><path d="M10 30h1v1h-1zm13 0h1v1h-1z"/><path d="M24 30h1v1h-1z"/><path d="M25 30h1v1h-1z"/>'
 unicode'</g>';
return biker;
  }

 function _getBump() internal pure returns (string memory) {
 string memory bump = 
  unicode'<g id="bump" >'
  unicode'<rect x="38" y="23" width="1" height="1" fill="#6E5205" />'
  unicode'<rect x="39" y="23" width="1" height="1" fill="#EFA801" />'
  unicode'<rect x="40" y="23" width="1" height="1" fill="#F8AB01" />'
  unicode'<rect x="41" y="23" width="1" height="1" fill="#EFBD2C" />'
  unicode'<rect x="37" y="24" width="1" height="1" fill="#876503" />'
  unicode'<rect x="38" y="24" width="1" height="1" fill="#896403" />'
  unicode'<rect x="39" y="24" width="1" height="1" fill="#F8AB03" />'
  unicode'<rect x="40" y="24" width="1" height="1" fill="#FAAA03" />'
  unicode'<rect x="41" y="24" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="42" y="24" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="36" y="25" width="1" height="1" fill="#786500" />'
  unicode'<rect x="37" y="25" width="1" height="1" fill="#896403" />'
  unicode'<rect x="38" y="25" width="1" height="1" fill="#896403" />'
  unicode'<rect x="39" y="25" width="1" height="1" fill="#F8AB03" />'
  unicode'<rect x="40" y="25" width="1" height="1" fill="#F8AB03" />'
  unicode'<rect x="41" y="25" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="42" y="25" width="1" height="1" fill="#FFE677" />'
  unicode'<rect x="43" y="25" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="36" y="26" width="1" height="1" fill="#896501" />'
  unicode'<rect x="37" y="26" width="1" height="1" fill="#896403" />'
  unicode'<rect x="38" y="26" width="1" height="1" fill="#896403" />'
  unicode'<rect x="39" y="26" width="1" height="1" fill="#FAAA03" />'
  unicode'<rect x="40" y="26" width="1" height="1" fill="#F8AB03" />'
  unicode'<rect x="41" y="26" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="42" y="26" width="1" height="1" fill="#FEE373" />'
  unicode'<rect x="43" y="26" width="1" height="1" fill="#FDE473" />'
  unicode'<rect x="36" y="27" width="1" height="1" fill="#896403" />'
  unicode'<rect x="37" y="27" width="1" height="1" fill="#896403" />'
  unicode'<rect x="38" y="27" width="1" height="1" fill="#896403" />'
  unicode'<rect x="39" y="27" width="1" height="1" fill="#F7A902" />'
  unicode'<rect x="40" y="27" width="1" height="1" fill="#FAAA03" />'
  unicode'<rect x="41" y="27" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="42" y="27" width="1" height="1" fill="#FDE473" />'
  unicode'<rect x="43" y="27" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="36" y="28" width="1" height="1" fill="#896403" />'
  unicode'<rect x="37" y="28" width="1" height="1" fill="#896403" />'
  unicode'<rect x="38" y="28" width="1" height="1" fill="#896403" />'
  unicode'<rect x="39" y="28" width="1" height="1" fill="#F9A902" />'
  unicode'<rect x="40" y="28" width="1" height="1" fill="#FAAA03" />'
  unicode'<rect x="41" y="28" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="42" y="28" width="1" height="1" fill="#FCE171" />'
  unicode'<rect x="43" y="28" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="36" y="29" width="1" height="1" fill="#896403" />'
  unicode'<rect x="37" y="29" width="1" height="1" fill="#896403" />'
  unicode'<rect x="38" y="29" width="1" height="1" fill="#896403" />'
  unicode'<rect x="39" y="29" width="1" height="1" fill="#F3AA01" />'
  unicode'<rect x="40" y="29" width="1" height="1" fill="#F7A902" />'
  unicode'<rect x="41" y="29" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="42" y="29" width="1" height="1" fill="#FDE272" />'
  unicode'<rect x="43" y="29" width="1" height="1" fill="#FCE372" />'
  unicode'<rect x="36" y="30" width="1" height="1" fill="#896403" />'
  unicode'<rect x="37" y="30" width="1" height="1" fill="#896403" />'
  unicode'<rect x="38" y="30" width="1" height="1" fill="#896403" />'
  unicode'<rect x="39" y="30" width="1" height="1" fill="#F4AB02" />'
  unicode'<rect x="40" y="30" width="1" height="1" fill="#F9A902" />'
  unicode'<rect x="41" y="30" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="42" y="30" width="1" height="1" fill="#FDE272" />'
  unicode'<rect x="43" y="30" width="1" height="1" fill="#FCE274" />'
  unicode'<rect x="36" y="31" width="1" height="1" fill="#886302" />'
  unicode'<rect x="37" y="31" width="1" height="1" fill="#886302" />'
  unicode'<rect x="38" y="31" width="1" height="1" fill="#896403" />'
  unicode'<rect x="39" y="31" width="1" height="1" fill="#F7A70C" />'
  unicode'<rect x="40" y="31" width="1" height="1" fill="#FAAA03" />'
  unicode'<rect x="41" y="31" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="42" y="31" width="1" height="1" fill="#FCE171" />'
  unicode'<rect x="43" y="31" width="1" height="1" fill="#FAE171" />'
  unicode'<rect x="36" y="32" width="1" height="1" fill="#8A6504" />'
  unicode'<rect x="37" y="32" width="1" height="1" fill="#896403" />'
  unicode'<rect x="38" y="32" width="1" height="1" fill="#6B5202" />'
  unicode'<rect x="39" y="32" width="1" height="1" fill="#886604" />'
  unicode'<rect x="40" y="32" width="1" height="1" fill="#896403" />'
  unicode'<rect x="41" y="32" width="1" height="1" fill="#ECCE60" />'
  unicode'<rect x="42" y="32" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="43" y="32" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="36" y="33" width="1" height="1" fill="#8A6504" />'
  unicode'<rect x="37" y="33" width="1" height="1" fill="#C38700" />'
  unicode'<rect x="38" y="33" width="1" height="1" fill="#896403" />'
  unicode'<rect x="39" y="33" width="1" height="1" fill="#896403" />'
  unicode'<rect x="40" y="33" width="1" height="1" fill="#896403" />'
  unicode'<rect x="41" y="33" width="1" height="1" fill="#8A6504" />'
  unicode'<rect x="42" y="33" width="1" height="1" fill="#FCEB81" />'
  unicode'<rect x="43" y="33" width="1" height="1" fill="#FBE775" />'
  unicode'<rect x="36" y="34" width="1" height="1" fill="#886702" />'
  unicode'<rect x="37" y="34" width="1" height="1" fill="#8A6706" />'
  unicode'<rect x="38" y="34" width="1" height="1" fill="#876503" />'
  unicode'<rect x="39" y="34" width="1" height="1" fill="#876503" />'
  unicode'<rect x="40" y="34" width="1" height="1" fill="#876503" />'
  unicode'<rect x="41" y="34" width="1" height="1" fill="#876503" />'
  unicode'<rect x="42" y="34" width="1" height="1" fill="#886604" />'
  unicode'<rect x="43" y="34" width="1" height="1" fill="#735000" />'
  unicode'</g>';
  return bump;
 }


  function _getScene() internal pure returns (string memory) {
  string memory scene = string(abi.encodePacked(_getBackground(), _getRoad(), _getBiker(), _getBump(), pointsLib._get100Points()));
  return scene;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library pointsLib {

    function _getPointsCss() public pure returns (string memory)  {
        return '<![CDATA[.W{fill:#fff}]]>#text {transform: translate(31px, 10px);}';
    }

   function _get100Points() public pure returns (string memory)  {
      string memory points = '<g id="text"><g class="W"><path d="M2 0h1v1H2z"/><path d="M3 0h1v1H3z"/></g><path d="M4 0h1v1H4z"/><g class="W"><path d="M7 0h1v1H7z"/><path d="M8 0h1v1H8z"/><path d="M9 0h1v1H9z"/></g><path d="M10 0h1v1h-1z"/><g class="W"><path d="M13 0h1v1h-1z"/><path d="M14 0h1v1h-1z"/><path d="M15 0h1v1h-1z"/></g><path d="M16 0h1v1h-1z"/><path d="M29 0h1v1h-1z" class="W"/><path d="M30 0h1v1h-1z"/><g class="W"><path d="M1 1h1v1H1z"/><path d="M2 1h1v1H2z"/><path d="M3 1h1v1H3z"/></g><path d="M4 1h1v1H4z"/><g class="W"><path d="M6 1h1v1H6z"/><path d="M7 1h1v1H7z"/></g><path d="M8 1h1v1H8z"/><g class="W"><path d="M9 1h1v1H9z"/><path d="M10 1h1v1h-1z"/></g><path d="M11 1h1v1h-1z"/><g class="W"><path d="M12 1h1v1h-1z"/><path d="M13 1h1v1h-1z"/></g><path d="M14 1h1v1h-1z"/><g class="W"><path d="M15 1h1v1h-1z"/><path d="M16 1h1v1h-1z"/></g><path d="M17 1h1v1h-1z"/><g class="W"><path d="M28 1h1v1h-1z"/><path d="M29 1h1v1h-1z"/></g><path d="M30 1h1v1h-1z"/><g class="W"><path d="M0 2h1v1H0z"/><path d="M1 2h1v1H1z"/><path d="M2 2h1v1H2z"/><path d="M3 2h1v1H3z"/></g><path d="M4 2h1v1H4z"/><g class="W"><path d="M6 2h1v1H6z"/><path d="M7 2h1v1H7z"/></g><path d="M8 2h1v1H8z"/><g class="W"><path d="M9 2h1v1H9z"/><path d="M10 2h1v1h-1z"/></g><path d="M11 2h1v1h-1z"/><g class="W"><path d="M12 2h1v1h-1z"/><path d="M13 2h1v1h-1z"/></g><path d="M14 2h1v1h-1z"/><g class="W"><path d="M15 2h1v1h-1z"/><path d="M16 2h1v1h-1z"/></g><path d="M17 2h1v1h-1z"/><g class="W"><path d="M21 2h1v1h-1z"/><path d="M22 2h1v1h-1z"/><path d="M23 2h1v1h-1z"/><path d="M24 2h1v1h-1z"/><path d="M25 2h1v1h-1z"/></g><path d="M26 2h1v1h-1z"/><g class="W"><path d="M27 2h1v1h-1z"/><path d="M28 2h1v1h-1z"/><path d="M29 2h1v1h-1z"/><path d="M30 2h1v1h-1z"/></g><path d="M31 2h1v1h-1z"/><g class="W"><path d="M32 2h1v1h-1z"/><path d="M33 2h1v1h-1z"/><path d="M34 2h1v1h-1z"/><path d="M35 2h1v1h-1z"/></g><path d="M36 2h1v1h-1z"/><path d="M0 3h1v1H0z" class="W"/><path d="M1 3h1v1H1z"/><g class="W"><path d="M2 3h1v1H2z"/><path d="M3 3h1v1H3z"/></g><path d="M4 3h1v1H4z"/><g class="W"><path d="M6 3h1v1H6z"/><path d="M7 3h1v1H7z"/></g><path d="M8 3h1v1H8z"/><g class="W"><path d="M9 3h1v1H9z"/><path d="M10 3h1v1h-1z"/></g><path d="M11 3h1v1h-1z"/><g class="W"><path d="M12 3h1v1h-1z"/><path d="M13 3h1v1h-1z"/></g><path d="M14 3h1v1h-1z"/><g class="W"><path d="M15 3h1v1h-1z"/><path d="M16 3h1v1h-1z"/></g><path d="M17 3h1v1h-1z"/><g class="W"><path d="M21 3h1v1h-1z"/><path d="M22 3h1v1h-1z"/></g><path d="M23 3h1v1h-1z"/><g class="W"><path d="M25 3h1v1h-1z"/><path d="M26 3h1v1h-1z"/></g><path d="M27 3h1v1h-1z"/><g class="W"><path d="M28 3h1v1h-1z"/><path d="M29 3h1v1h-1z"/></g><path d="M30 3h1v1h-1z"/><g class="W"><path d="M31 3h1v1h-1z"/><path d="M32 3h1v1h-1z"/></g><path d="M33 3h1v1h-1z"/><g class="W"><path d="M35 3h1v1h-1z"/><path d="M36 3h1v1h-1z"/></g><path d="M37 3h1v1h-1z"/><g class="W"><path d="M2 4h1v1H2z"/><path d="M3 4h1v1H3z"/></g><path d="M4 4h1v1H4z"/><g class="W"><path d="M6 4h1v1H6z"/><path d="M7 4h1v1H7z"/></g><path d="M8 4h1v1H8z"/><g class="W"><path d="M9 4h1v1H9z"/><path d="M10 4h1v1h-1z"/></g><path d="M11 4h1v1h-1z"/><g class="W"><path d="M12 4h1v1h-1z"/><path d="M13 4h1v1h-1z"/></g><path d="M14 4h1v1h-1z"/><g class="W"><path d="M15 4h1v1h-1z"/><path d="M16 4h1v1h-1z"/></g><path d="M17 4h1v1h-1z"/><g class="W"><path d="M21 4h1v1h-1z"/><path d="M22 4h1v1h-1z"/></g><path d="M23 4h1v1h-1z"/><g class="W"><path d="M25 4h1v1h-1z"/><path d="M26 4h1v1h-1z"/></g><path d="M27 4h1v1h-1z"/><g class="W"><path d="M28 4h1v1h-1z"/><path d="M29 4h1v1h-1z"/></g><path d="M30 4h1v1h-1z"/><g class="W"><path d="M31 4h1v1h-1z"/><path d="M32 4h1v1h-1z"/><path d="M33 4h1v1h-1z"/><path d="M34 4h1v1h-1z"/></g><path d="M35 4h1v1h-1z"/><g class="W"><path d="M2 5h1v1H2z"/><path d="M3 5h1v1H3z"/></g><path d="M4 5h1v1H4z"/><g class="W"><path d="M6 5h1v1H6z"/><path d="M7 5h1v1H7z"/></g><path d="M8 5h1v1H8z"/><g class="W"><path d="M9 5h1v1H9z"/><path d="M10 5h1v1h-1z"/></g><path d="M11 5h1v1h-1z"/><g class="W"><path d="M12 5h1v1h-1z"/><path d="M13 5h1v1h-1z"/></g><path d="M14 5h1v1h-1z"/><g class="W"><path d="M15 5h1v1h-1z"/><path d="M16 5h1v1h-1z"/></g><path d="M17 5h1v1h-1z"/><g class="W"><path d="M21 5h1v1h-1z"/><path d="M22 5h1v1h-1z"/></g><path d="M23 5h1v1h-1z"/><g class="W"><path d="M25 5h1v1h-1z"/><path d="M26 5h1v1h-1z"/></g><path d="M27 5h1v1h-1z"/><g class="W"><path d="M28 5h1v1h-1z"/><path d="M29 5h1v1h-1z"/></g><path d="M30 5h1v1h-1z"/><g class="W"><path d="M33 5h1v1h-1z"/><path d="M34 5h1v1h-1z"/><path d="M35 5h1v1h-1z"/><path d="M36 5h1v1h-1z"/></g><path d="M37 5h1v1h-1z"/><g class="W"><path d="M2 6h1v1H2z"/><path d="M3 6h1v1H3z"/></g><path d="M4 6h1v1H4z"/><g class="W"><path d="M6 6h1v1H6z"/><path d="M7 6h1v1H7z"/></g><path d="M8 6h1v1H8z"/><g class="W"><path d="M9 6h1v1H9z"/><path d="M10 6h1v1h-1z"/></g><path d="M11 6h1v1h-1z"/><g class="W"><path d="M12 6h1v1h-1z"/><path d="M13 6h1v1h-1z"/></g><path d="M14 6h1v1h-1z"/><g class="W"><path d="M15 6h1v1h-1z"/><path d="M16 6h1v1h-1z"/></g><path d="M17 6h1v1h-1z"/><g class="W"><path d="M21 6h1v1h-1z"/><path d="M22 6h1v1h-1z"/></g><path d="M23 6h1v1h-1z"/><g class="W"><path d="M25 6h1v1h-1z"/><path d="M26 6h1v1h-1z"/></g><path d="M27 6h1v1h-1z"/><g class="W"><path d="M28 6h1v1h-1z"/><path d="M29 6h1v1h-1z"/></g><path d="M30 6h1v1h-1z"/><g class="W"><path d="M31 6h1v1h-1z"/><path d="M32 6h1v1h-1z"/></g><path d="M33 6h1v1h-1z"/><g class="W"><path d="M35 6h1v1h-1z"/><path d="M36 6h1v1h-1z"/></g><path d="M37 6h1v1h-1z"/><g class="W"><path d="M2 7h1v1H2z"/><path d="M3 7h1v1H3z"/></g><path d="M4 7h1v1H4z"/><g class="W"><path d="M7 7h1v1H7z"/><path d="M8 7h1v1H8z"/><path d="M9 7h1v1H9z"/></g><path d="M10 7h1v1h-1z"/><g class="W"><path d="M13 7h1v1h-1z"/><path d="M14 7h1v1h-1z"/><path d="M15 7h1v1h-1z"/></g><path d="M16 7h1v1h-1z"/><g class="W"><path d="M21 7h1v1h-1z"/><path d="M22 7h1v1h-1z"/><path d="M23 7h1v1h-1z"/><path d="M24 7h1v1h-1z"/><path d="M25 7h1v1h-1z"/></g><path d="M26 7h1v1h-1z"/><g class="W"><path d="M29 7h1v1h-1z"/><path d="M30 7h1v1h-1z"/></g><path d="M31 7h1v1h-1z"/><g class="W"><path d="M32 7h1v1h-1z"/><path d="M33 7h1v1h-1z"/><path d="M34 7h1v1h-1z"/><path d="M35 7h1v1h-1z"/></g><path d="M36 7h1v1h-1z"/><g class="W"><path d="M21 8h1v1h-1z"/><path d="M22 8h1v1h-1z"/></g><path d="M23 8h1v1h-1z"/><g class="W"><path d="M21 9h1v1h-1z"/><path d="M22 9h1v1h-1z"/></g><path d="M23 9h1v1h-1z"/></g>';
    return points;
  }
}