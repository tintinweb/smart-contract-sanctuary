pragma solidity 0.8.4;

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Written by somewherecat
 * Copyright (C) 2021 Yamato Protocol (DeFiGeek Community Japan)
*/

import "./OracleMockBase.sol";
import "./Interfaces/ITellorCaller.sol";

//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract TellorCallerMock is OracleMockBase, ITellorCaller {

    constructor() {
        setPriceToDefault();
    }

    function getTellorCurrentValue(uint256 _requestId) external virtual override view returns (bool ifRetrieve, uint256 value, uint256 _timestampRetrieved){
        require(_requestId == 59, "Only ETH/JPY is supported.");
        return (true, uint256(lastPrice), block.timestamp);
    }

    function simulatePriceMove(uint deviation, bool sign) internal override onlyOwner {
        uint256 _lastPrice = uint256(lastPrice);
        uint256 value;
        if (deviation != 0) { // nothing to do if deviation is zero
            uint change = _lastPrice / 1000;
            change = change * deviation;
            value = sign ? _lastPrice + change : _lastPrice - change;

            if (value == 0) {
                // Price shouldn't be zero, reset if so
                setPriceToDefault();
                value = _lastPrice;
            }
            lastPrice = int256(value);
        }
    }

    function setPriceToDefault() public override onlyOwner {
      lastPrice = 300000000000; // 300000 JPY
    }
}

pragma solidity 0.8.4;

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

    int256 internal lastPrice;
    uint private lastBlockNumber;

    function setLastPrice(int256 _price) public onlyOwner {
      lastPrice = _price;
      lastBlockNumber = block.number;
    }

    function setPriceToDefault() public virtual;

    function simulatePriceMove(uint deviation, bool sign) internal virtual;

    function simulatePriceMove() public onlyOwner {
      // Within each block, only once price update is allowed (volatility control)
      if (block.number != lastBlockNumber) {
        lastBlockNumber = block.number;

        uint randomNumber = uint(keccak256(abi.encodePacked(msg.sender,  block.timestamp,  blockhash(block.number - 1))));
        uint deviation = randomNumber % 11;
        bool sign = randomNumber % 2 == 1 ? true : false;
        simulatePriceMove(deviation, sign);
      }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITellorCaller {
    function getTellorCurrentValue(uint256 _requestId) external returns (bool, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}