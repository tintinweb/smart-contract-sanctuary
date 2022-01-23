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