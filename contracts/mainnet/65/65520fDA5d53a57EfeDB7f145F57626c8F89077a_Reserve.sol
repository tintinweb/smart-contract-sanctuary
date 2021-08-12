// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

contract Reserve {

    struct Rectangle {
        uint xTopLeft;
        uint yTopLeft;
        uint xBottomRight;
        uint yBottomRight;
        uint timestamp;
        address owner;
    }

    Rectangle[] private reservePixels;

    uint[] public needClean;

    function reserve(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight) public {

        Rectangle memory rectangle = Rectangle(xTopLeft, yTopLeft, xBottomRight, yBottomRight,
            block.timestamp, msg.sender);


        for (uint i = 0; i < reservePixels.length; i++) {
            if (block.timestamp <= reservePixels[i].timestamp + 30 * 1 minutes) {
                require(!dotInRectangle(reservePixels[i], xTopLeft, yTopLeft), '1: Already reserved another user');
                require(!dotInRectangle(reservePixels[i], xTopLeft, yBottomRight), '2: Already reserved another user');
                require(!dotInRectangle(reservePixels[i], xBottomRight, yBottomRight), '3: Already reserved another user');
                require(!dotInRectangle(reservePixels[i], xBottomRight, yTopLeft), '4: Already reserved another user');
                require(!dotInRectangle(rectangle, reservePixels[i].xBottomRight, reservePixels[i].yTopLeft), '5: Already reserved another user');
                require(!dotInRectangle(rectangle, reservePixels[i].xBottomRight, reservePixels[i].yBottomRight), '6: Already reserved another user');
                require(!dotInRectangle(rectangle, reservePixels[i].xTopLeft, reservePixels[i].yBottomRight), '7: Already reserved another user');
                require(!dotInRectangle(rectangle, reservePixels[i].xTopLeft, reservePixels[i].yTopLeft), '8: Already reserved another user');
            }
            else {
                needClean.push(i);
            }
        }


        if (needClean.length > 0) {

            for (int256 i = int256(needClean.length) - 1; i >= 0; i--) {
                if (reservePixels.length > 0) {
                    reservePixels[needClean[uint(i)]] = reservePixels[reservePixels.length - 1];
                    reservePixels.pop();
                }
            }
            delete needClean;
        }

        reservePixels.push(rectangle);
    }

    function dotInRectangle(Rectangle memory rectangle, uint x, uint y) internal pure returns (bool){
        return x >= rectangle.xTopLeft && x <= rectangle.xBottomRight
        && y >= rectangle.yTopLeft && y <= rectangle.yBottomRight;
    }

    function getAllReservedRectangles() public view returns (Rectangle[] memory){
        return reservePixels;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
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