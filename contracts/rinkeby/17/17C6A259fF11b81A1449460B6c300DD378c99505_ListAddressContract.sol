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
    mapMasterERC20[standard] = 0xd00aC075BF31C4b45DcD911d1332D7534fE2dFeE;
    mapMasterERC20[mint] = 0x6B45416DCf2e44aEaF6070DB6b0BeA9CC436929c;
    mapMasterERC20[burn] = 0x17589D783f0959D46D922d25350e0084F0Ed6090;
    mapMasterERC20[pause] = 0x2eb92B0559F775C850F21082E6A3F05528C79251;
    mapMasterERC20[gover] = 0x7E0Df58a08aa40af34b6547EF0Ee20299ECFFE35;
    mapMasterERC20[mintBurn] = 0xE06D3B044d21176BB04b813DdDC33b69578BaE60;
    mapMasterERC20[mintPause] = 0x4950969d102c36a09f41DF7f44BF45f97A693195;
    mapMasterERC20[mintGover] = 0xd8fD91A3D844Da4890f3249442Ab04B4a553Cb40;
    mapMasterERC20[burnPause] = 0x3677320c53bd1262C26a6564a0b54D3547464470;
    mapMasterERC20[burnGover] = 0xF83369511897eD1d9C315C137f798aCeCFc84E9c;
    mapMasterERC20[pauseGover] = 0x33722b6CAf3B4fC586166A4a8F5BDAA3Ca963228;
    mapMasterERC20[mintBurnPause] = 0x5bB793cdEAdD5c3B428458dc3E4C1BA82768b34e;
    mapMasterERC20[mintBurnGover] = 0x958e6E3f3d4c6673CB214B7dDEa486bC88BC7D49;
    mapMasterERC20[mintPauseGover] = 0x113842B543922456549C061994148Aa1516638Bb;
    mapMasterERC20[burnPauseGover] = 0x5A3972C88612F4a220e85d040C911aE5e4bf99Ae;
    mapMasterERC20[mintBurnPauseGover] = 0x52AaCBE05014D534f7B09A461F20e51bbF4064B6;
  }

  function getValue(bytes32 check) public view returns (address) {
    return mapMasterERC20[check];
  }
}