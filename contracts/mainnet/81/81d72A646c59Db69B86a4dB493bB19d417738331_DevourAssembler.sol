// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IDevour.sol";


contract DevourAssembler is Ownable, ReentrancyGuard {
  IDevour public devour;
  bool public assemblerEnabled;
  mapping (uint256 => uint256) private _shardIds;

  constructor (address _devourAddress) {
    devour = IDevour(_devourAddress);

    // Pre-filled shard identifiers for validation on assembling
    _shardIds[16] = 2;
    _shardIds[376] = 2;
    _shardIds[382] = 2;
    _shardIds[225] = 11;
    _shardIds[6] = 11;
    _shardIds[486] = 15;
    _shardIds[566] = 6;
    _shardIds[468] = 20;
    _shardIds[215] = 20;
    _shardIds[581] = 7;
    _shardIds[586] = 9;
    _shardIds[348] = 13;
    _shardIds[513] = 14;
    _shardIds[452] = 15;
    _shardIds[589] = 16;
    _shardIds[359] = 16;
    _shardIds[541] = 20;
    _shardIds[540] = 20;
    _shardIds[256] = 13;
    _shardIds[268] = 1;
    _shardIds[231] = 17;
    _shardIds[292] = 15;
    _shardIds[227] = 9;
    _shardIds[304] = 11;
    _shardIds[161] = 13;
    _shardIds[271] = 5;
    _shardIds[163] = 17;
    _shardIds[274] = 5;
    _shardIds[34] = 11;
    _shardIds[288] = 19;
    _shardIds[37] = 15;
    _shardIds[292] = 19;
    _shardIds[183] = 11;
    _shardIds[289] = 6;
    _shardIds[184] = 12;
    _shardIds[298] = 9;
    _shardIds[308] = 20;
    _shardIds[41] = 11;
    _shardIds[467] = 5;
    _shardIds[251] = 13;
    _shardIds[329] = 15;
    _shardIds[253] = 5;
    _shardIds[341] = 15;
    _shardIds[267] = 2;
    _shardIds[280] = 10;
    _shardIds[346] = 16;
    _shardIds[334] = 11;
    _shardIds[330] = 5;
    _shardIds[343] = 13;
    _shardIds[350] = 7;
    _shardIds[363] = 14;
    _shardIds[353] = 8;
    _shardIds[365] = 18;
    _shardIds[372] = 2;
    _shardIds[382] = 15;
    _shardIds[394] = 8;
    _shardIds[404] = 19;
    _shardIds[413] = 4;
    _shardIds[420] = 17;
    _shardIds[414] = 18;
    _shardIds[434] = 17;
    _shardIds[430] = 4;
    _shardIds[442] = 15;
    _shardIds[454] = 8;
    _shardIds[464] = 19;
    _shardIds[476] = 7;
    _shardIds[484] = 20;
    _shardIds[509] = 5;
    _shardIds[520] = 13;
    _shardIds[523] = 14;
    _shardIds[532] = 5;
    _shardIds[538] = 9;
    _shardIds[545] = 3;
    _shardIds[550] = 7;
    _shardIds[562] = 12;
    _shardIds[560] = 16;
    _shardIds[572] = 4;
    _shardIds[585] = 17;
    _shardIds[593] = 9;
    _shardIds[472] = 2;
    _shardIds[481] = 17;
  }

  function setAssemblerEnabled(bool _state) external onlyOwner {
    assemblerEnabled = _state;
  }

  function assemble(uint256 _type, uint256[] calldata _tokenIds) external nonReentrant {
    require(assemblerEnabled, "Assembler disabled");

    uint256 flag = 0;
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      uint256 tokenId = _tokenIds[i];
      require(devour.ownerOf(tokenId) == msg.sender, "Invalid access");

      // Calculate the shard index
      uint256 shardId;
      uint256 fixedShardId = _shardIds[tokenId];
      if (fixedShardId > 0) {
        shardId = fixedShardId;
      } else {
        uint256 index = tokenId - 1;
        if (index >= 60 && index < 140) {
          shardId = index;
        } else if (index % 9 == 0) {
          shardId = index + 2;
        } else if (index % 6 == 0) {
          shardId = index + 1;
        } else if (index % 7 == 0) {
          shardId = index + 3;
        } else if (index % 11 == 0 || index % 3 == 0) {
          shardId = index + 5;
        } else {
          shardId = index + 4;
        }
        shardId = (shardId % 20) + 1;
      }

      // Check the type and update the flag based on the shard order
      uint256 devourType = (shardId - 1) / 5 + 1;
      uint256 shardOrder = (shardId - 1) % 5;
      require(_type == devourType, "Shards mismatch");
      flag |= (1 << shardOrder);
    }

    // Correct set of 5 shards should have exactly 2^5-1 for the flag value
    require(flag == 31, "Incomplete shards");

    // Call devour contract to burn shards and mint the assembled piece
    devour.assemble(_type, _tokenIds);
  }
}