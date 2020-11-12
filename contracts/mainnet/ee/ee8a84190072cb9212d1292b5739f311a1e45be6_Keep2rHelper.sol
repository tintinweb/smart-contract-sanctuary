// SPDX-License-Identifier: MIT


/**
 * KP2R.NETWORK
 * A standard implementation of kp3rv1 protocol
 * Optimized Dapp
 * Scalability
 * Clean & tested code
 */


pragma solidity ^0.6.12;

library SafeMath {
  
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }

    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

  function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }
  function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
  function mul(uint a, uint b) internal pure returns (uint) {
     if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }

    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
      if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }
 function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }

  function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
 function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "mod: %");
    }
 function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Math {
   function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

interface IChainLinkFeed {
    function latestAnswer() external view returns (int256);
}

interface IKeep2r {
    function totalBonded() external view returns (uint);
    function bonds(address keeper, address credit) external view returns (uint);
    function votes(address keeper) external view returns (uint);
}

contract Keep2rHelper {
    using SafeMath for uint;

    IChainLinkFeed public constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    IKeep2r public constant KP2R = IKeep2r(0x9BdE098Be22658d057C3F1F185e3Fd4653E2fbD1);

    uint constant public BOOST = 50;
    uint constant public BASE = 10;
    uint constant public TARGETBOND = 200e18;

    uint constant public PRICE = 10;

    function getFastGas() external view returns (uint) {
        return uint(FASTGAS.latestAnswer());
    }

    function bonds(address keeper) public view returns (uint) {
        return KP2R.bonds(keeper, address(KP2R)).add(KP2R.votes(keeper));
    }

    function getQuoteLimitFor(address origin, uint gasUsed) public view returns (uint) {
        uint _min = gasUsed.mul(PRICE).mul(uint(FASTGAS.latestAnswer()));
        uint _boost = _min.mul(BOOST).div(BASE); // increase by 2.5
        uint _bond = Math.min(bonds(origin), TARGETBOND);
        return Math.max(_min, _boost.mul(_bond).div(TARGETBOND));
    }

    function getQuoteLimit(uint gasUsed) external view returns (uint) {
        return getQuoteLimitFor(tx.origin, gasUsed);
    }
}