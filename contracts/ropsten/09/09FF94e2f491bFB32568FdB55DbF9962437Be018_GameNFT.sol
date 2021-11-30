// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract GameNFT  {
  function mint(uint256 originSeed,uint32 i) public pure  returns (uint256){
      uint256 kind=0;
        uint256 seed = uint256(keccak256(abi.encodePacked(originSeed,i)));
        uint mod = (seed & 0xFFFF) % 50;
        kind =mod == 0 ? 2 : mod < 5 ? 1 : 0;
        return kind;
  }
    function mint2(uint256 originSeed,uint32 i) public pure  returns (uint256){
      uint256 kind=0;
        uint256 seed = uint256(keccak256(abi.encodePacked(originSeed,i)));
        kind =(seed & 0xFFFF) % 10 == 0 ? 1 : 0;
        return kind;
  }
}