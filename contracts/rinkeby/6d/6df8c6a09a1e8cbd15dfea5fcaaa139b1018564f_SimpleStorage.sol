/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity >=0.7.0 <=0.8;

contract SimpleStorage {
    uint myData;


    function setData(uint newData) public {
    myData = newData;
    }

    
    function getData() public view returns (uint) {
    return myData;
    }

}