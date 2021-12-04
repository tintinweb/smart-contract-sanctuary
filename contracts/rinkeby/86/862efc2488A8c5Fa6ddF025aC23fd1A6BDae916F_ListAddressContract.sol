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
    mapMasterERC20[standard] = 0x35c2D5F8C9c7091a8F5569E4053008A3D233CE6E;
    mapMasterERC20[mint] = 0x0ac2e6D3C208817e2ff01D3EA62936Bab68cf814;
    mapMasterERC20[burn] = 0x8967223E884Be0b5af128a061693de6bDdc17BA1;
    mapMasterERC20[pause] = 0xa17f572f043096994671f3ecAE00552fb99Dde1b;
    mapMasterERC20[gover] = 0x0Bc93B99f024dc14F4C716c257630002875a1547;
    mapMasterERC20[mintBurn] = 0x3111E6D192C6C095Ad6dd73b8aa14A072e800B7A;
    mapMasterERC20[mintPause] = 0x5f4dE9D080361Fb64B311c27a5bC2ef67b05cb94;
    mapMasterERC20[mintGover] = 0x0DbC7BCfAa0a3a3702A9942773FbbeE28e33Fd5B;
    mapMasterERC20[burnPause] = 0x95a5136AEE00f1C359e1B6AA403115e9c94c75aA;
    mapMasterERC20[burnGover] = 0x846287B8237611EAbBa3bA012f0B6e638Cb45AbD;
    mapMasterERC20[pauseGover] = 0xb61d5F6A7cB25B1cd836729222e9e3A9aEE0Eb63;
    mapMasterERC20[mintBurnPause] = 0x695C5e4DCC28fe6fdbF5900d38cfd66e3826349C;
    mapMasterERC20[mintBurnGover] = 0x8b95cC540eb70c07F9C2389abb74C3900F1c07Ae;
    mapMasterERC20[mintPauseGover] = 0xe530bc82A093b42A35c230715fbb79B7F3d8148c;
    mapMasterERC20[burnPauseGover] = 0x1A4377f3E090A75Ac8175AadfeF8f6337bE965ac;
    mapMasterERC20[
      mintBurnPauseGover
    ] = 0x1F0701FF44eFe85929a9c3ed32385162C4696916;
  }

  function getValue(bytes32 check) public view returns (address) {
    return mapMasterERC20[check];
  }
}