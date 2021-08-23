// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../interfaces/IDiscountProfile.sol";

contract NoDiscountProfile is IDiscountProfile {
    function discount(address) external pure override returns (float memory) {
        return float({numerator: 0, denominator: 1});
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@mochifi/library/contracts/Float.sol";

interface IDiscountProfile {
    function discount(address _user) external view returns (float memory);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

struct float {
    uint256 numerator;
    uint256 denominator;
}

library Float {
    function multiply(uint256 a, float memory f) internal pure returns(uint256) {
        require(f.denominator != 0, "div 0");
        return a * f.numerator / f.denominator;
    }

    function inverse(float memory f) internal pure returns(float memory) {
        require(f.numerator != 0 && f.denominator != 0, "div 0");
        return float({
            numerator: f.denominator,
            denominator: f.numerator
        });
    }

    function divide(uint256 a, float memory f) internal pure returns(uint256) {
        require(f.denominator != 0, "div 0");
        return a * f.denominator / f.numerator;
    }

    function add(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator*b.denominator + a.denominator*b.numerator,
            denominator : a.denominator*b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }
    
    function sub(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator*b.denominator - b.numerator*a.denominator,
            denominator : a.denominator*b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }

    function mul(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator * b.numerator,
            denominator : a.denominator * b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }

    function gt(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator > a.denominator * b.numerator;
    }

    function lt(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator < a.denominator * b.numerator;
    }

    function gte(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator >= a.denominator * b.numerator;
    }

    function lte(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator <= a.denominator * b.numerator;
    }

    function equals(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator == b.numerator * a.denominator;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "metadata": {
    "bytecodeHash": "none"
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