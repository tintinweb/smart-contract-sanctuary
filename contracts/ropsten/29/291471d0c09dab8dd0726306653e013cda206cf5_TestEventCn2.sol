/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity ^0.6.12;
contract TestEventCn2 {
    
    string public name = "聚集聚集聚集聚集聚集聚集1212";
   
    event EventDemo( address indexed sender, uint256 indexed _aid,  uint256 indexed _pid, string _name, string _desc);
    event EventDemo2( address indexed sender, uint256 indexed _aid,  uint256 indexed _pid, string _name, string _desc);
    
    function test1(uint256 _aid, uint256 _pid, string memory _name,  string memory _desc) public {
        emit EventDemo(msg.sender,_aid,_pid,_name,_desc);
        emit EventDemo2(msg.sender,_aid,_pid,_name,_desc);
    }
    
    function test2(uint256 _aid, uint256 _pid, string memory _name,  string memory _desc) public {
        emit EventDemo2(msg.sender,_aid,_pid,_name,_desc);
        emit EventDemo(msg.sender,_aid,_pid,_name,_desc);
    }
}