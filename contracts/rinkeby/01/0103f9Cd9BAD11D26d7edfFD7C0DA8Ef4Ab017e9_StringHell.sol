// SPDX-License-Identifier: Mixed...
pragma solidity ^0.8.0;

/// @title StringHell
/// @notice If you know a smarter way I could have done this feel free to email me
/// @author Sterling Crispin <[email protected]>
/// my contract is giant 
/// I had to do something with these strings
library StringHell {
    string internal constant svgStart = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400" width="800" height="800"><defs><linearGradient id="grad"  x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="dimgrey" /><stop offset="10%" stop-color="black" /></linearGradient><radialGradient id="grad2" cx="0.5" cy="0.9" r="1.2" fx="0.5" fy="0.9" spreadMethod="repeat"><stop offset="0%" stop-color="red"/><stop offset="100%" stop-color="blue"/></radialGradient></defs><style>.base { fill:';
    string internal constant svgO1 = 'font-family: monospace; font-size: 15px; }</style><rect y="8" width="100%" height="100%" fill="url(#grad';
    string internal constant svgEnd = '<rect width="100%" height="100%" fill="none" stroke="dimgrey" stroke-width="20"/><circle cx="20" cy="395" r="3" fill="limegreen"/></svg>';
    string internal constant svgB1 = '<rect y="50%" width="100%" height="100%" fill="url(#grad';
    string internal constant svgO3 = '<text x="20" y="60" class="base">//usr: ';
    string internal constant svgP2 = '<text x="20" y="250" class="base">//pub: '; 
    string internal constant desc = '", "description": "Message is an experiment in communication. Write via contract, refresh metadata. Be nice. https://sterlingcrispin.com/message.html",';
    string internal constant json = 'data:application/json;base64,';
    string internal constant jsonStub = '], "image": "data:image/svg+xml;base64,';
    
    function SvgStart() external pure returns (string memory){
        return svgStart;
    }
    function SvgO1() external pure returns (string memory){
        return svgO1;
    }
    function SvgEnd() external pure returns (string memory){
        return svgEnd;
    }
    function SvgB1() external pure returns (string memory){
        return svgB1;
    }
    function SvgO3() external pure returns (string memory){
        return svgO3;
    }
    function SvgP2() external pure returns (string memory){
        return svgP2;
    }
    function Desc() external pure returns (string memory){
        return desc;
    }
    function Json() external pure returns (string memory){
        return json;
    }
    function JsonStub() external pure returns (string memory){
        return jsonStub;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 20
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}