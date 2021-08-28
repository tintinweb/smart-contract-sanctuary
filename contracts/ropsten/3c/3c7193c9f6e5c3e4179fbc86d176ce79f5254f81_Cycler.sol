/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Cycler {
    enum Status {Pending, Cycled}
    
    uint256 public Position_Cost = 0.005 * 10 ** 18;
    
    uint256 _id;
    uint256 _levels = 5;
    uint256 _cost = Position_Cost;
    
    struct PositionDetail {
        Status status;
        uint256 level;
        address owner;
    }
    
    mapping(uint256 => PositionDetail) private positions;
    mapping(address => uint256) private balances;
    
    constructor() public {
        positions[_id] = PositionDetail(Status.Pending, 0, msg.sender);
    }
    
    
    function getBalance() public view returns(uint256){
        return balances[msg.sender];
    }
    function Position_Details(uint256 id) public view returns (Status, uint256, address){
        return (
            positions[id].status,
            positions[id].level,
            positions[id].owner
        );
    }
    function Total_Positions() public view returns (uint){
        return _id;
    }
    
    function Purchase_Postion() external payable returns (bool) {
        require(msg.value == _cost, "Amount doesn't match position cost!");
        
        uint256 current = _id / _levels;
        positions[current].level = positions[current].level + 1;
        
        if(positions[current].level == _levels){
            positions[current].status = Status.Cycled;
            payable(positions[current].owner).transfer( _cost * _levels );
        }
        
        _id++;
        positions[_id] = PositionDetail(Status.Pending, 0, msg.sender);
        return true;
    }
  
}