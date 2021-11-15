// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;

library LootMonCard {
 
    function svgStart() public pure returns(string memory) {
       return string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><rect x="100" y="30" width="150" height="200" rx="10" stroke="#fff" class="glow" fill="url(#gradient)"></rect>'));
    }

    function linearGradient(string memory _color1, string memory _color2) public pure returns(string memory) {
        return string(abi.encodePacked('<defs><linearGradient id="gradient" x1="0%" y1="100%" x2="0%" y2="0%"><stop offset="0%" style="stop-color: ', _color1,'; stop-opacity: 1" /><stop offset="100%" style="stop-color: ', _color2,'; stop-opacity: 1" /></linearGradient></defs>'));
    }

    function style() public pure returns(string memory) {
        return string(abi.encodePacked('<style> svg { width: 900px; stroke: none; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); background-color: #000; } .base { fill: #fff; font-family: serif; font-size: 6px; stroke:"none"; } .hd { font-size: 50px; } .md { font-size: 20px; fill: #fff; } .gf { fill: white; stroke: none; } .label { font-size: 4px; fill: #fff; } .glow { animation: glow 1.5s alternate infinite ease-in-out; } @keyframes glow { 0% {filter: drop-shadow(0px 0px 1px #888) drop-shadow(0px 0px 1.5px #fff) drop-shadow(0px 0px 2.5px #f7e6ad) drop-shadow(0px 0px 5px #f98404) drop-shadow(0px 0px 8px #fff338);} 100% {filter: drop-shadow(0px 0px 1px #fff) drop-shadow(0px 0px 2px #fff) drop-shadow(0px 0px 3px #f7e6ad) drop-shadow(0px 0px 6px #f98404) drop-shadow(0px 0px 10px #fff338);} } </style>'));
    }
    
    function card (string memory _element, string memory _type, string memory _horns, string memory _wings, string memory _weapon ) public pure returns(string memory) {
        return string(abi.encodePacked('<text x="105" y="60" class="hd" fill="url(#gradient)">', _element,'</text><text x="110" y="52" class="md">', _type,'</text><text x="114" y="95" class="base">- ', _horns,'</text><text x="114" y="115" class="base">- ', _wings,'</text><text x="114" y="135" class="base">- ', _weapon,'</text>'));
    }

    function cardDetail (string memory _title, string memory _detail) public pure returns(string memory) {
        return string(abi.encodePacked('<rect x="105" y="180" width="140" height="45" rx="7" fill="none" stroke="#fff"></rect><text x="110" y="188" class="label">', _title,'</text><text x="110" y="207" class="gf base glow">', _detail,'</text>'));
    }

    function svgEnd() public pure returns(string memory) {
        return string(abi.encodePacked("</svg>"));
    }

}

