// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./First.sol";

contract ThirdContract {
  address public testaddress;

  constructor(address _addr)  {
        testaddress = _addr;
  }

  function CheckPass() public returns (bool)  {
    (bool success, bytes memory data) = testaddress.delegatecall(abi.encodeWithSignature("isContract()"));
    if (success == false) {
          // if there is a return reason string
          if (data.length > 0) {
              // bubble up any reason for revert
              assembly {
                  let returndata_size := mload(data)
                  revert(add(32, data), returndata_size)
              }  
          } else {
              revert("Function call reverted");
          }
      }
    bool ispass = abi.decode(data, (bool));
    return ispass;
  } 

}