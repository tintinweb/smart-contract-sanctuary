// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.8;

import { SafeMath64 } from './SafeMath64.sol';


/**
 * Library helper for extracting timestamp component of Version 1 UUIDs
 */
library UUID {
  using SafeMath64 for uint64;

  /**
   * Extracts the timestamp component of a Version 1 UUID. Used to make time-based assertions
   * against a wallet-privided nonce
   */
  function getTimestampInMsFromUuidV1(uint128 uuid)
    internal
    pure
    returns (uint64 msSinceUnixEpoch)
  {
    // https://tools.ietf.org/html/rfc4122#section-4.1.2
    uint128 version = (uuid >> 76) & 0x0000000000000000000000000000000F;
    require(version == 1, 'Must be v1 UUID');

    // Time components are in reverse order so shift+mask each to reassemble
    uint128 timeHigh = (uuid >> 16) & 0x00000000000000000FFF000000000000;
    uint128 timeMid = (uuid >> 48) & 0x00000000000000000000FFFF00000000;
    uint128 timeLow = (uuid >> 96) & 0x000000000000000000000000FFFFFFFF;
    uint128 nsSinceGregorianEpoch = (timeHigh | timeMid | timeLow);
    // Gregorian offset given in seconds by https://www.wolframalpha.com/input/?i=convert+1582-10-15+UTC+to+unix+time
    msSinceUnixEpoch = uint64(nsSinceGregorianEpoch / 10000).sub(
      12219292800000
    );

    return msSinceUnixEpoch;
  }
}
