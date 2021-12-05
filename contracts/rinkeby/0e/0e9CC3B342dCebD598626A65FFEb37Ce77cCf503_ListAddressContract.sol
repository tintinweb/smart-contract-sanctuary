//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ListAddressContract {
  mapping(bytes32 => address) public mapMasterERC20;

  bytes32 _standard = keccak256(abi.encodePacked("20standard"));
  bytes32 _mint = keccak256(abi.encodePacked("20mint"));
  bytes32 _burn = keccak256(abi.encodePacked("20burn"));
  bytes32 _pause = keccak256(abi.encodePacked("20pause"));
  bytes32 _gover = keccak256(abi.encodePacked("20governance"));

  //
  bytes32 standard = keccak256(abi.encodePacked([_standard]));
  bytes32 mint = keccak256(abi.encodePacked([_standard, _mint]));
  bytes32 burn = keccak256(abi.encodePacked([_standard, _burn]));
  bytes32 pause = keccak256(abi.encodePacked([_standard, _pause]));
  bytes32 gover = keccak256(abi.encodePacked([_standard, _gover]));
  bytes32 mintBurn = keccak256(abi.encodePacked([_standard, _mint, _burn]));
  bytes32 mintPause = keccak256(abi.encodePacked([_standard, _mint, _pause]));
  bytes32 mintGover = keccak256(abi.encodePacked([_standard, _mint, _gover]));
  bytes32 burnPause = keccak256(abi.encodePacked([_standard, _burn, _pause]));
  bytes32 burnGover = keccak256(abi.encodePacked([_standard, _burn, _gover]));
  bytes32 pauseGover = keccak256(abi.encodePacked([_standard, _pause, _gover]));
  bytes32 mintBurnPause =
    keccak256(abi.encodePacked([_standard, _mint, _burn, _pause]));
  bytes32 mintBurnGover =
    keccak256(abi.encodePacked([_standard, _mint, _burn, _gover]));
  bytes32 mintPauseGover =
    keccak256(abi.encodePacked([_standard, _mint, _pause, _gover]));
  bytes32 burnPauseGover =
    keccak256(abi.encodePacked([_standard, _burn, _pause, _gover]));
  bytes32 mintBurnPauseGover =
    keccak256(abi.encodePacked([_standard, _mint, _burn, _pause, _gover]));

  // bytes
  constructor() {
    mapMasterERC20[standard] = 0x318984A3CD843e2d88E890628b3A18a955c4204d;
    mapMasterERC20[mint] = 0xf6D264fBdFA0C504284f758487bF396B76c8bA59;
    mapMasterERC20[burn] = 0xF8a7e7e0F3D9c4D59db3C731D7028Dfe28E5584d;
    mapMasterERC20[pause] = 0x73c5F7E5949Fd55d52E5bed0Da2Ed356Bbc635C1;
    mapMasterERC20[gover] = 0x9ce1013f46e96F27c78dEebB00002389fc856cD6;
    mapMasterERC20[mintBurn] = 0x237BE6B11BFC42C3D45cC911245083DcEf9c7cD6;
    mapMasterERC20[mintPause] = 0x021a95738a642c0d8942AdB889b259c544433Ad1;
    mapMasterERC20[mintGover] = 0x010022378503A91017FE7972497da16b5be70E92;
    mapMasterERC20[burnPause] = 0xd374B3f75784c0057253B0E66e0B1f811F2C897E;
    mapMasterERC20[burnGover] = 0x63c55ba38aaF3af7Dd1060abA115Abdb4093b096;
    mapMasterERC20[pauseGover] = 0xd3b20d49c88e6Fa2F6D5C21DDc38d0D9A23a944a;
    mapMasterERC20[mintBurnPause] = 0x06d8cFB162f8c301730e633e1CbFB899e4bea96b;
    mapMasterERC20[mintBurnGover] = 0x005BdEaFbd2B838FB813cfb643e10e971B91c1E7;
    mapMasterERC20[mintPauseGover] = 0xbC14Ded2Cc76E7A6157b38E4094fEDFCFF769A58;
    mapMasterERC20[burnPauseGover] = 0x8a0381e9343e71B56FB039F2f7b7E6bF681391DA;
    mapMasterERC20[mintBurnPauseGover] = 0x16BBCF56F4888FD5ACfE74c21714Fb38766dD236;
  }

  function getValue(bytes32 key) public view returns (address) {
    return mapMasterERC20[key];
  }
}