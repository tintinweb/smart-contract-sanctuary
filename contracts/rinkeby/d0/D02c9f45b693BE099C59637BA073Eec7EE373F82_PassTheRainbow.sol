// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDoodle {
  function ownerOf(uint256 _realmId) external view returns (address owner);
}

contract PassTheRainbow {
  IDoodle public constant DOODLE =
    IDoodle(0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e);

  uint256 public constant MAX_SUPPLY = 10000;

  uint256 public rainbowHolder;

  mapping(uint256 => uint256) public rainbowCount;

  event Passed(uint256 from, uint256 to);

  function pass(uint256 _from, uint256 _to) external {
    // require(
    //   _to <= MAX_SUPPLY &&
    //     _from == rainbowHolder &&
    //     DOODLE.ownerOf(_from) == msg.sender
    // );

    rainbowHolder = _to;
    rainbowCount[_to]++;

    emit Passed(_from, _to);
  }
}