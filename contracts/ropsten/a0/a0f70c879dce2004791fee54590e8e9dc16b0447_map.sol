/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

pragma solidity > 0.6.0;

contract map {
    mapping(address => uint) public myMap;
    
    function getAddress(address _addr) public view returns (uint){
        return myMap[_addr];
    }
    
    function setAddress(address _addr, uint _i) public {
        myMap[_addr] = _i;
    }
    
    function remove(address _addr) public {
        delete myMap[_addr];
    }
}