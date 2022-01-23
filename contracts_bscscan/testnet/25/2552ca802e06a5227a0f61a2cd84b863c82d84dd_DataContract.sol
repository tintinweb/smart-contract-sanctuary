/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

pragma solidity ^0.4.18;
 
contract DataContract {
    mapping (address => uint256) public balanceOf;
 
    function setBlance(address _address, uint256 v) public  {
        balanceOf[_address] = v;
    }
 
}
 
contract ControlContract {
    mapping (address => uint256) public tmp;
    DataContract dataContract;
 
    function ControlContract(address _dataContractAddr) public {
        dataContract = DataContract(_dataContractAddr);
    }
 
    function set(uint256 value) public {
        dataContract.setBlance(msg.sender, value);
        tmp[msg.sender] = value + 10;
    }
}