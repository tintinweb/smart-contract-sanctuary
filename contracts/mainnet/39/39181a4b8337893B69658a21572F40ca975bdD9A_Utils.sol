// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {
  using Utils for Unlock;
  using Utils for Vest;

  struct Vest {
    uint256 shortAmnt;
    uint256 longAmnt;
    uint256 lastUpdate;
  }

  struct Unlock {
    uint256 unlockAmnt;
    uint256 unlockTime;
  }

  // note: we should be able to unlock all tokens (including vested tokens)
  function unlock(
    Unlock storage self,
    uint256 amount,
    uint256 lockTime
  ) internal {
    self.unlockAmnt = amount;
    self.unlockTime = block.timestamp + lockTime;
  }

  function useUnlocked(Unlock storage self, uint256 amount) internal {
    require(self.unlockTime <= block.timestamp, "sRelU: tokens are not unlocked yet");
    require(self.unlockAmnt >= amount, "sRelU: tokens should be unlocked before transfer");

    self.unlockAmnt -= amount; // update locked amount;
  }

  function resetLock(Unlock storage self) internal {
    self.unlockAmnt = 0;
    self.unlockTime = 0;
  }

  function transferUnvestedTokens(Vest storage self, Vest storage vestTo) internal {
    require(self.shortAmnt | self.longAmnt != 0, "sRelU: nothing to transfer");

    require(
      vestTo.shortAmnt | vestTo.longAmnt == 0,
      "sRelU: cannot transfer to account with unvested tokens"
    );

    vestTo.shortAmnt = self.shortAmnt;
    vestTo.longAmnt = self.longAmnt;
    vestTo.lastUpdate = self.lastUpdate;

    // reset initial vest
    self.shortAmnt = 0;
    self.longAmnt = 0;
    self.lastUpdate = 0;
  }

  function setUnvestedAmount(
    Vest storage self,
    uint256 shortAmnt,
    uint256 longAmnt
  ) public {
    require(self.shortAmnt + self.longAmnt == 0, "sRelU: account has unvested tokens");
    if (shortAmnt > 0) self.shortAmnt = shortAmnt;

    if (longAmnt > 0) self.longAmnt = longAmnt;

    self.lastUpdate = 0;
  }

  function unvested(Vest storage self) internal view returns (uint256) {
    return self.shortAmnt + self.longAmnt;
  }

  // this method updates long and short unvested amounts and returns vested amount
  function updateUnvestedAmount(
    Vest storage self,
    uint256 vestShort,
    uint256 vestLong,
    uint256 vestBegin
  ) public returns (uint256 amount) {
    if (block.timestamp <= vestBegin) return 0;
    uint256 shortAmnt = self.shortAmnt;
    uint256 longAmnt = self.longAmnt;
    uint256 last = self.lastUpdate < vestBegin ? vestBegin : self.lastUpdate;

    if (shortAmnt > 0 && last < vestShort) {
      uint256 sAmnt = block.timestamp < vestShort
        ? (shortAmnt * (block.timestamp - last)) / (vestShort - last)
        : shortAmnt;
      self.shortAmnt = shortAmnt - sAmnt;
      amount += sAmnt;
    }

    if (longAmnt > 0 && last < vestLong) {
      uint256 lAmnt = block.timestamp < vestLong
        ? (longAmnt * (block.timestamp - last)) / (vestLong - last)
        : longAmnt;
      self.longAmnt = longAmnt - lAmnt;
      amount += lAmnt;
    }

    self.lastUpdate = block.timestamp;
    return amount;
  }
}