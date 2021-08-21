pragma solidity ^0.8.0;

import "./OracleMockUtils.sol";

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Yamato
 * Copyright (C) 2021 Yamato Protocol (DeFiGeek Community Japan)
 *
 * This Factory is a fork of Murray Software's deliverables.
 * And this entire project is including the fork of Hegic Protocol.
 * Hence the license is alinging to the GPL-3.0
*/

contract TellorMock is OracleMockUtils {

    uint256 public lastPrice;

    function getCurrentValue(uint256 _requestId) public returns (bool ifRetrieve, uint256 value, uint256 _timestampRetrieved){
        require(_requestId == 59, "Only ETH/JPY is supported.");
        (
        uint deviation,
        bool sign
        ) = randomize();

        if (deviation == 0) {
            // no deviation
            value = lastPrice;
        } else {
            if (deviation == 10) {
                if (chaos()) {
                    deviation = 51;
                }
            }

            uint change = lastPrice / 1000;
            change = change * deviation;
            value = sign ? lastPrice + change : lastPrice - change;

            if (value == 0) {
                // Price shouldn't be zero, reset if so
                setPriceToDefault();
                value = lastPrice;
            }
            lastPrice = value;
        }
        
        return (true, lastPrice, block.timestamp);
    }

    function setLastPrice(uint256 _price) public {
      lastPrice = _price;
    }

    function setPriceToDefault() public {
      lastPrice = 300000000000; // 300000 JPY
    }

}

pragma solidity ^0.8.0;

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Yamato
 * Copyright (C) 2021 Yamato Protocol (DeFiGeek Community Japan)
 *
 * This Factory is a fork of Murray Software's deliverables.
 * And this entire project is including the fork of Hegic Protocol.
 * Hence the license is alinging to the GPL-3.0
*/

//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract OracleMockUtils {

    uint8 private chaosCounter = 0;

    function randomize() internal view returns (uint, bool) {
      uint randomNumber = uint(keccak256(abi.encodePacked(msg.sender,  block.timestamp,  blockhash(block.number - 1))));
      uint deviation = randomNumber % 11;
      bool sign = randomNumber % 2 == 1 ? true : false;
      return (deviation, sign);
    }

    // If chaos counter == 10, reset it to 0 and trigger chaos = 51% deviation
    // Otherwise, increment the chaos counter and return false
    function chaos() internal returns (bool) {
      if (chaosCounter == 10) {
        chaosCounter == 0;
        return true;
      }
      chaosCounter += 1;
      return false;
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
  "libraries": {}
}