// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "base64-sol/base64.sol";



contract BlasterData {

struct Project {
        string name;
        string scope;
        string body;
        string trigger;
        string muzzle;
        uint256 invocations;
        uint256 maxInvocations;
        uint256 hashes;        
    }

    uint256 constant ONE_THOUSAND = 1_000;
    mapping(uint256 => Project) projects;

    address public admin;
    uint256 public nextProjectId;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

constructor()  {
        admin = msg.sender;
    }

function addProject(string memory _projectName) public onlyAdmin {

        uint256 projectId = nextProjectId;
        projects[projectId].name = _projectName;
        projects[projectId].maxInvocations = ONE_THOUSAND;
        nextProjectId = nextProjectId + 1;
    }

function addProjectSVG(uint256 _projectId, string memory scopeSVG, string memory bodySVG, string memory triggerSVG, string memory muzzleSVG) public onlyAdmin {
        projects[_projectId].scope = scopeSVG;
        projects[_projectId].body = bodySVG;
        projects[_projectId].trigger = triggerSVG;
        projects[_projectId].muzzle = muzzleSVG;
    }



function blasterConcat(uint256 _projectId, uint256 _num1, uint256 _num2, uint256 _num3, uint256 _num4) public view returns (string memory) {
        uint256 a = _projectId + _num1;
        uint256 b = _projectId + _num2;
        uint256 c = _projectId + _num3;
        uint256 d = _projectId + _num4;
        string memory svgHEAD = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -.5 64 64" shape-rendering="crispEdges">';
        string memory svgFOOT = '</svg>';
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svgHEAD,projects[a].scope,projects[b].body,projects[c].trigger,projects[d].muzzle,svgFOOT))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
        

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  }
}