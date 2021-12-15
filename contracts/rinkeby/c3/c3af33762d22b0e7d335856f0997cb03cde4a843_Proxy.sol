/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
 

contract Proxy {
    
    string wellcomeString; //slot 0
    address payable implementation = payable(0xf464cCbCd7BfEA0A211a4854a10c3C754E9aF421);
    uint256 version = 1; //slot 2
    function getData() public view returns (string memory) {
        return wellcomeString;
    }
    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
         }
    
    function changeImplementation(address payable _newImplementation, uint256 _newVersion) public  {
        require(_newVersion > version, "New version must be greater then previous");
        implementation = _newImplementation;
    }
    

}