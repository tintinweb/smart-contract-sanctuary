/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

pragma solidity 0.8.6;
contract ImplementationV1 {
    address public owner;
    mapping (address => uint) internal points;
    
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
      
    function initOwner() external {
        require (owner == address(0));
        owner = msg.sender;
    }
    
    function addPlayer(address _player, uint _points) virtual
        public onlyOwner 
    {
        require (points[_player] == 0);
        points[_player] = _points;
    }
    
    function setPoints(address _player, uint _points) 
        public onlyOwner 
    {
        require (points[_player] != 0);
        points[_player] = _points;
    }
}