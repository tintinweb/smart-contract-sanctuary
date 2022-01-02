pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

import "./Redeemers.sol";

///@dev The interface we couple Scouts contract to
interface IScoutsIdGenerator {
  function getScoutId(uint8 _redeemerName, uint256 _tokenId) pure external returns (uint256);
}

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

/**
 * @dev This library exists just to avoid typos and
 * magic numbers when passing Types around and does so by sharing
 * the Types between ScoutsIdGenerator and Redeemers
 */

enum RedeemersTypes { Tickets }

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

import "./IScoutsIdGenerator.sol";
import "./Redeemers.sol";

/**
 * @dev ScoutsIdGenerator implementation
 *
 * When we generate the scouts skills and properties we take into account not
 * only the random number(s) that comes along with it but also which contract
 * minted it. We call such contract a Redeemer.
 *
 * We are starting with just one Redeemer (Tickets) that uses from id 0 to 4699;
 *
 */
contract ScoutsIdGenerator is IScoutsIdGenerator {
  ///This is just so the different types are visible in the ABI
  RedeemersTypes public constant REDEEMER_TICKET = RedeemersTypes.Tickets;

  ///We use uint8 instead of the Types enum because Scouts.sol is not upgradeable.
  function getScoutId(uint8 _redeemerType, uint256 _tokenId) public pure returns (uint256) {
    if (_redeemerType == uint8(RedeemersTypes.Tickets)) {
      // First 4699 scouts reserved for Pioneers
      require(_tokenId < 4700, "Only 4700 Pioneers should be available");
      return(_tokenId);
    } else {
      revert('invalid redeemerType');
    }
  }

  ///This is just a helper function to help with transparency
  function typeBounds() public pure returns(uint8, uint8) {
    return(uint8(type(RedeemersTypes).min), uint8(type(RedeemersTypes).max));
  }

  ///This is just a helper function to help with transparency
  function typeName(uint8 _redeemerType) public pure returns(string memory) {
    if (_redeemerType == uint8(RedeemersTypes.Tickets)) {
      return "Tickets";
    }

    revert("Not existing");
  }
}