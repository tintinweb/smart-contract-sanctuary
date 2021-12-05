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
    mapMasterERC20[standard] = 0xBeD06b507981042aD436833bF5e707287190431e;
    mapMasterERC20[mint] = 0xE8b9292AEa87220aE58A0B5343b0755C6d2E9f50;
    mapMasterERC20[burn] = 0xD56e182f16A09aC61E4f49EbdC85CE82F9DAd625;
    mapMasterERC20[pause] = 0x0650a4253B0Be6921A49ABDEfCE1857F640bb5a5;
    mapMasterERC20[gover] = 0xE9a4ADf4d78bf21e3E064c60073F0e423B2b424f;
    mapMasterERC20[mintBurn] = 0x7995454C2a05405e45d3185A68312a3AC6e34D49;
    mapMasterERC20[mintPause] = 0x3012EA13718a306688685770560A6B8CD1789034;
    mapMasterERC20[mintGover] = 0x35a585D43EbEf6628BB610c180649aCC0a1D2388;
    mapMasterERC20[burnPause] = 0xD3e0d4c229B6eAaB4D7809cF4713cE864B29543a;
    mapMasterERC20[burnGover] = 0x6897bad7e6A09a79AF7bf8dEcD62114BCaaB6A3F;
    mapMasterERC20[pauseGover] = 0xA46B8897c2b657ffedbAb2A013F33ba6BF9c1F0F;
    mapMasterERC20[mintBurnPause] = 0x1e59279E29dACBfcA75EA5d7bC3142AAd61BF728;
    mapMasterERC20[mintBurnGover] = 0x52AD02C3f0c753D355e6F31eDf262d132eEB08B1;
    mapMasterERC20[mintPauseGover] = 0xCf73cB3181123383E63b3524b354Acb8179bCB5c;
    mapMasterERC20[burnPauseGover] = 0xCf395A2CB61500ded98337678787feAb404eD497;
    mapMasterERC20[mintBurnPauseGover] = 0xf5143E7b2F09C5507dE512A94281625BE0fb7F2A;
  }

  function getValue(bytes32 check) public view returns (address) {
    return mapMasterERC20[check];
  }
}