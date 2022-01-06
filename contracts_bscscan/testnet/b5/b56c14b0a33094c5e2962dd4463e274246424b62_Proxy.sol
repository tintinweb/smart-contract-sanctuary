/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;


contract ProxyStorage {
    address public otherContractAddress;

    function setOtherAddressStorage(address _otherContract) internal {
        otherContractAddress = _otherContract;
    }
}

// contract NotLostStorage is ProxyStorage {
//     address public myAddress;
//     uint public myUint;
//     uint256 public u;

//     function setAddress(address _address) public {
//         myAddress = _address;
//     }

//     function setMyUint(uint _uint) public {
//         myUint = _uint;
//     }
    
//     function set(uint _uint) public {
//         u = _uint;
//     }
// }


contract Proxy is ProxyStorage {

    address devwallet;
    constructor(address _otherContract,address _devwallet) {
        setOtherAddress(_otherContract);
        devwallet = _devwallet;
    } 

    function setOtherAddress(address _otherContract) public 
    {
        super.setOtherAddressStorage(_otherContract);
    }
    
    function withdraweth(uint256 amount) external
    {
        require(msg.sender == devwallet,"not devwallet");
        (bool success,)  = devwallet.call{value:amount}("");
        require(success, "refund failed");
    }   
     /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  fallback() payable external {
    address _impl = otherContractAddress;

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}