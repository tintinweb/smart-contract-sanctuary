/**
 *Submitted for verification at Etherscan.io on 2020-03-04
*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;


interface Ir1{
    function userInfo(uint256 a,address b) external view returns(uint256 c,uint256 d);
}

contract Test{

    function getValue() public view returns(uint256) {
        Ir1 er = Ir1(0x64cf2df6679Fc56F109EAB0530d46f90086BBfF4);
        uint256 one;
        uint256 two;
        (one,two) = er.userInfo(1,address(0x05B7b3A933aC4bBdf667851BC07708AcA02C35f6));
        return one;
    }

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}