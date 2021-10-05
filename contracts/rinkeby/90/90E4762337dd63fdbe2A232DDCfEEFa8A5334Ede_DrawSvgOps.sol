// SPDX-License-Identifier: Mixed...
pragma solidity ^0.8.0;

library TypeConversions {
    // borrowed from https://github.com/provable-things/ethereum-api/issues/102
    function uint2str(uint256 _i) internal pure returns (string memory str){
        if (_i == 0){
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0){
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }
}

/// Copyright (c) Sterling Crispin
/// All rights reserved.
/// @title DrawSvgOps
/// @notice Provides some drawing functions used in MESSAGE
/// @author Sterling Crispin <[email protected]>
library DrawSvgOps {

    string internal constant elli1 = '<ellipse cx="';
    string internal constant elli2 = '" cy="';
    string internal constant elli3 = '" rx="';
    string internal constant elli4 = '" ry="';
    string internal constant elli5 = '" stroke="mediumpurple" stroke-dasharray="';
    string internal constant upgradeShapeEnd = '"  fill-opacity="0"/>';
    string internal constant strBlank = ' ';

    function rand(uint num) internal view returns (uint256) {
        return  uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, num))) % num;
    }
    function Ellipse(uint256 size) external view returns (string memory){
        string memory xLoc = TypeConversions.uint2str(rand(size-1));
        string memory yLoc = TypeConversions.uint2str(rand(size-2));
        string memory output = string(abi.encodePacked(
            elli1,xLoc,
            elli2,yLoc,
            elli3,TypeConversions.uint2str(rand(size-3)),
            elli4,TypeConversions.uint2str(rand(size-3))));
        output = string(abi.encodePacked(
            output,
            elli5,TypeConversions.uint2str(rand(7)+1),upgradeShapeEnd,
            elli1,xLoc,
            elli2,yLoc
        ));
        output = string(abi.encodePacked(
            output,elli3,
            TypeConversions.uint2str(rand(size-4)),
            elli4,TypeConversions.uint2str(rand(size-5)),
            elli5,TypeConversions.uint2str(rand(6)+1),upgradeShapeEnd
            ));
        output = string(abi.encodePacked(
            output,
            elli1,xLoc,
            elli2,yLoc,
            elli3,TypeConversions.uint2str(rand(size-5)),
            elli4));
        output = string(abi.encodePacked(
            output,TypeConversions.uint2str(rand(size-6)),
            elli5,TypeConversions.uint2str(rand(4)+1),upgradeShapeEnd
        ));
        return output;
    }

    function Wiggle(uint256 size) external view returns (string memory){
        string memory output = string(abi.encodePacked(
            '<path d="M ',
            TypeConversions.uint2str(rand(size-1)), strBlank,
            TypeConversions.uint2str(rand(size-2)), strBlank,
            'Q ', TypeConversions.uint2str(rand(size-3)), strBlank));
        output = string(abi.encodePacked(output,
            TypeConversions.uint2str(rand(size-4)), ', ',
            TypeConversions.uint2str(rand(size-5)), strBlank,
            TypeConversions.uint2str(rand(size-6)), strBlank,
            'T ',  TypeConversions.uint2str(rand(size-7)), strBlank,
            TypeConversions.uint2str(rand(size-8)), '"'
            ));
        output = string(abi.encodePacked(output,
            ' stroke="red" stroke-dasharray="',TypeConversions.uint2str(rand(7)+1), upgradeShapeEnd
        ));
        return output;
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
        "abi"
      ]
    }
  }
}