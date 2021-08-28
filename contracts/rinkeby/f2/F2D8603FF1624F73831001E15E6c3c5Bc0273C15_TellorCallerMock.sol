pragma solidity 0.7.6;

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Written by somewherecat
 * Copyright (C) 2021 Yamato Protocol (DeFiGeek Community Japan)
*/

import "./OracleMockBase.sol";

//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract TellorCallerMock is OracleMockBase {

    constructor() {
        setPriceToDefault();
    }

    function getTellorCurrentValue(uint256 _requestId) external returns (bool ifRetrieve, uint256 value, uint256 _timestampRetrieved){
        require(_requestId == 59, "Only ETH/JPY is supported.");
        (
        uint deviation,
        bool sign
        ) = randomize();

        uint256 _lastPrice = uint256(lastPrice);
        if (deviation == 0) {
            // no deviation
            value = _lastPrice;
        } else {
            if (deviation == 10) {
                if (chaos()) {
                    deviation = 51;
                }
            }

            uint change = _lastPrice / 100;
            change = change * deviation;
            value = sign ? _lastPrice + change : _lastPrice - change;

            if (value == 0) {
                // Price shouldn't be zero, reset if so
                setPriceToDefault();
                value = _lastPrice;
            }
            lastPrice = int256(value);
        }
        
        return (true, value, block.timestamp);
    }

    function setPriceToDefault() public override {
      lastPrice = 300000000000; // 300000 JPY
    }
}

pragma solidity 0.7.6;

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Written by somewherecat
 * Copyright (C) 2021 Yamato Protocol (DeFiGeek Community Japan)
*/

//solhint-disable max-line-length
//solhint-disable no-inline-assembly

import "./Dependencies/Ownable.sol";

// Base class to create a oracle mock contract for a specific provider
abstract contract OracleMockBase is Ownable {

    uint8 public chaosCounter = 0;

    int256 public lastPrice;

    function setLastPrice(int256 _price) public {
      lastPrice = _price;
    }

    function setPriceToDefault() public virtual;

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
        chaosCounter = 0;
        return true;
      }
      chaosCounter += 1;
      return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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