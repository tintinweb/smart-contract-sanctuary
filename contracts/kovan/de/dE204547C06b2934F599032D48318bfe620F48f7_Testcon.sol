/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity >=0.4.22 <0.7.0;

contract Test {
    uint256 public val = 256;
}


contract Testcon {

    Test testContract;

    function setAddress(address _address) public {
        testContract = Test(_address);            
    }    

    function getVal()  public view returns (uint256) {
        return testContract.val();
    }
}