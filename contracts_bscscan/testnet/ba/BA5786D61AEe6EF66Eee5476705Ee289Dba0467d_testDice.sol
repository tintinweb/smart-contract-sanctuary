pragma solidity 0.6.12;
 
contract testDice {
  bool public success;
  bytes public data;
  constructor() public {
      address target = 0x5F80919c0d1b65E76a1A2744F958654d3D2a84df;
        (bool _success, bytes memory _data) = target.delegatecall(
            abi.encodeWithSignature("bet(address,uint,uint256)", 0x1CbDdf83De068464Eba3a4E319bd3197a7EEa12c,10,100)
        );  
      success = _success;
      data = _data;
  }
}

