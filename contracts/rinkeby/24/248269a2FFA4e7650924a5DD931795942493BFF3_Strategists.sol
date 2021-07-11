// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

contract Strategists {

    address[] vip = [
    0x7A6714015fcc9dB1f9E5688759bcCc0F16ACBc48,
    0xc84535F22417Eb9F598982385b23775b063104fc,
    0xe4Ef24C0FCD913BfeE33416258bBbA9fF36920bB,
    0x12e8987C762701d60f0FcfeE687Bb8E4c07555aa,
    0xd6979dd7034B474Bf45cA2fb3745F4Fb2E393B39,
    0x95D2acCc4d9317E9575E6Ee2AdcC7E8A65B30DC4,
    0xD62B29617F081775f739186C9989bAF66A8c78c6,
    0xDfe2abc3d395a87a1476f5B707E77f5F23B1d88b,
    0xea243097c0b97211C116825ebc3A09fd221FfC84,
    0x0b304924fAa64b0f040dcA67bC5175Dd6078db52,
    0xa49Fb9C9545a2a2673De7f1E9e5Fca2241C2354c,
    0x6D644d0963AFb162FEeda98F2ee37402004aA6B2,
    0xE04FEe8a68584A3C45cD0df45a165529E0035F68,
    0x087AfAFd713c6842690AeCeC015c10F69D7aD5FB,
    0xd33619B122B27f712AA5F784BC54DE9c95c7588d,
    0x9cdbBca91819B8C3F993b51C3aFea259959179Cc,
    0x8888888888E9997E64793849389a8Faf5E8e547C,
    0x0FfD214b8bD957ec23986c3e342c4d9065742A98,
    0xFC7Ce16Aca27CB9C9540210de214c0E13D455A52
    ];


    mapping(address => bool) private vipMap;

    constructor(){
        for (uint8 i; i < vip.length; i++) {
            vipMap[vip[i]] = true;
        }
    }

    function isVip(address verified) public view returns (bool){
        return vipMap[verified];
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}