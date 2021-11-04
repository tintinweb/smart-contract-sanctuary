/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

pragma solidity^0.6.0;

contract save_data {
    
    mapping(address => mapping(uint256 => bytes32)) map;
    
    function saveData(address _addr, uint256 _flag, bytes32 _hash) external{
        map[_addr][_flag] = _hash;
    }
    
    function getData(address _addr, uint256 _flag) public view returns(bytes32) {
        return map[_addr][_flag];
    }
}