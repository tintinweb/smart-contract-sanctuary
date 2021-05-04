// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

contract ManualOracle is BoringOwnable {
    uint256 public output;

    constructor(uint256 output_) public {
        output = output_;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256) {
        return output;
    }

    function changeInterval(uint256 period_) external {}

    function update() external {}

    function priceChangeMax(uint256 change_) external {}

    function setOracle(uint256 output_) external onlyOwner {
        output = output_;
    }

    function consult(address a, uint256 b) public view returns (uint256) {
        return output;
    }
}

// SPDX-License-Identifier: MIT
// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract BoringOwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract BoringOwnable is BoringOwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        
        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

{
  "optimizer": {
    "enabled": true,
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
  },
  "libraries": {
    "": {
      "__CACHE_BREAKER__": "0x00000000d41867734bbee4c6863d9255b2b06ac1"
    }
  }
}