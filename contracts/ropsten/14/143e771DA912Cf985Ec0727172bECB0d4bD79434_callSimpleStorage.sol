/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.5.16;

interface simpleInterface{

  function set(uint) external;
  function get() external view returns (uint);

}

contract callSimpleStorage {

    address public simpleStorage_address;

    constructor(address _address) public {
        simpleStorage_address = _address;
    }
    function setStorage(uint _value) public {
         simpleInterface contractInstance = simpleInterface(simpleStorage_address);
         contractInstance.set(_value);
    }
    function getStorage() public view returns (uint){
        simpleInterface contractInstance = simpleInterface(simpleStorage_address);
        return contractInstance.get();
    }

}