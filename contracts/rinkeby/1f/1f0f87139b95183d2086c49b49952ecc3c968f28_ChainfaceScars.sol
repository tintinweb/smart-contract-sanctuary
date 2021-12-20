/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract ChainfaceScars {

    string scarHeader = "<svg xmlns='http://www.w3.org/2000/svg' width='350' height='350' style='background-color:RGB(207,207,255)'><symbol id='scar' ><g stroke='RGBA(200,40,40,.45)'><line style='stroke-width: 3px;' x1='28' y1='46' x2='96' y2='46'></line><line style='stroke-width: 2px;' x1='88' y1='37' x2='89' y2='54'></line><line style='stroke-width: 2px;' x1='78' y1='38' x2='79' y2='53'></line><line style='stroke-width: 2px;' x1='69' y1='38' x2='68' y2='55'></line><line style='stroke-width: 2px;' x1='59' y1='37' x2='58' y2='51'></line><line style='stroke-width: 2px;' x1='48' y1='54' x2='48' y2='40'></line><line style='stroke-width: 2px;' x1='37' y1='53' x2='38' y2='39'></line></g></symbol>";
    string scarPlacement1 = "<g transform='scale(";
    string dot = ".";
    string scarPlacement2 = ") translate(";
    string scarPlacement3 = " ";
    string scarPlacement4 = ") rotate(";
    string scarPlacement5 = ")'> <use href='#scar'/></g>";
    string faceSVG = "<text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' font-size='75px' fill='RGB(150,50,50)'>(^_^)</text></svg>";

    constructor() {
    }

    function assembleSVG(uint256 tokenId) public view returns (string memory finalSVG) {
        finalSVG = string(abi.encodePacked(scarHeader,addScars(tokenId)));
        finalSVG = string(abi.encodePacked(finalSVG,faceSVG));
    }


    function addScars(uint256 tokenId) public view returns (string memory scarSVG) {

        uint256 scale1;
        uint256 scale2;
        uint256 xShift;
        uint256 yShift;
        uint256 rotate;    

        uint256 numberOfScars = uint256(keccak256(abi.encodePacked(tokenId)))%125;

        for(uint i = 0; i < numberOfScars; i++) {

            (scale1, scale2, xShift, yShift, rotate) = scarSalt(uint256(keccak256(abi.encodePacked(tokenId,i))));

            scarSVG = string(abi.encodePacked(scarSVG,scarPlacement1,toString(scale1)));
            scarSVG = string(abi.encodePacked(scarSVG,dot,toString(scale2)));
            scarSVG = string(abi.encodePacked(scarSVG,scarPlacement2,toString(xShift)));
            scarSVG = string(abi.encodePacked(scarSVG,scarPlacement3,toString(yShift)));
            scarSVG = string(abi.encodePacked(scarSVG,scarPlacement4,toString(rotate)));
            scarSVG = string(abi.encodePacked(scarSVG,scarPlacement5));
        }
    }



    function scarSalt(uint256 seed) public pure returns (uint256 scale1, uint256 scale2, uint256 xShift, uint256 yShift, uint256 rotate) {
        scale1 = uint256(keccak256(abi.encodePacked(seed)))%2;

        if(scale1 == 0){
        scale2 = uint256(keccak256(abi.encodePacked(seed)))%6 + 4;
        }
        else {
        scale2 = uint256(keccak256(abi.encodePacked(seed)))%5;    
        }
        xShift =  uint256(keccak256(abi.encodePacked(seed)))%332;
        yShift =  uint256(keccak256(abi.encodePacked(seed)))%354;
        rotate = uint256(keccak256(abi.encodePacked(seed)))%360;
    }

    
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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