// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDoodle {
  function ownerOf(uint256 _realmId) external view returns (address owner);
}

contract PassTheRainbow {
  IDoodle public constant DOODLE =
    IDoodle(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);

  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public constant CLAIM = 1; //2 days;

  uint256 public rainbowHolder;
  uint256 public claimed;

  mapping(uint256 => uint256) public rainbowCount;

  event Passed(uint256 from, uint256 to);

  constructor() {
    rainbowHolder = 0;
    claimed = block.timestamp;
  }

  function pass(uint256 _from, uint256 _to) external {
    require(
      _to <= MAX_SUPPLY &&
        _from == rainbowHolder &&
        DOODLE.ownerOf(_from) == msg.sender
    );

    rainbowHolder = _to;
    rainbowCount[_to]++;

    emit Passed(_from, _to);
  }

  function claim(uint256 _tokenId) external {
    require(claimed > CLAIM && DOODLE.ownerOf(_tokenId) == msg.sender);

    emit Passed(rainbowHolder, _tokenId);

    rainbowHolder = _tokenId;
    claimed = block.timestamp;
  }
}