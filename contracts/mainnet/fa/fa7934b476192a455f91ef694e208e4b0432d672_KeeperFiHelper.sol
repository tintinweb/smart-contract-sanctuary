/**
 *Submitted for verification at Etherscan.io on 2020-11-29
*/

// SPDX-License-Identifier: MIT


/**
 * KEEPERFI.COM
 * Optimized Dapp
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

interface IKeeperFi {
    function totalBonded() external view returns (uint);
    function bonds(address keeper, address credit) external view returns (uint);
    function votes(address keeper) external view returns (uint);
}

contract KeeperFiHelper {
    using SafeMath for uint;

    IChainLinkFeed public constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    IKeeperFi public constant KFI = IKeeperFi(0x4e59DFe7c5D34C498Cfe18f0b6dB10941d6E1A8a);

    uint constant public BOOST = 50;
    uint constant public BASE = 10;
    uint constant public TARGETBOND = 300e18;

    uint constant public PRICE = 10;

    function getFastGas() external view returns (uint) {
        return uint(FASTGAS.latestAnswer());
    }

    function bonds(address keeper) public view returns (uint) {
        return KFI.bonds(keeper, address(KFI)).add(KFI.votes(keeper));
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