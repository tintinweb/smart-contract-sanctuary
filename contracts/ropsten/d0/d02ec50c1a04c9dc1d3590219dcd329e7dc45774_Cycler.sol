/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Cycler {
    enum Status {Pending, Cycled}
    
    uint256 _id;
    uint256 _levels = 5;
    uint256 _cost = 0.005 * 10 ** 18;
    
    struct PositionDetail {
        Status status;
        uint256 level;
        address owner;
    }
    
    constructor() public {
        positions[_id] = PositionDetail(Status.Pending, 0, msg.sender);
    }
    
    mapping(uint256 => PositionDetail) private positions;
    mapping(address => uint256) private balances;
    
    function getBalance() public view returns(uint256){
        return balances[msg.sender];
    }
    
    function updatePosition() private returns (bool){
        uint256 current = _id / _levels;
        positions[current].level = positions[current].level + 1;
        
        if(positions[current].level == _levels){
            positions[current].status = Status.Cycled;
            balances[positions[current].owner] = balances[positions[current].owner] +  _cost * _levels;
        }
        
        _id++;
        return true;
    }
    
    function positionDetails(uint256 id) public view returns (Status, uint256, address){
        return (
            positions[id].status,
            positions[id].level,
            positions[id].owner
        );
    }
    function totalPositions() public view returns (uint){
        return _id;
    }
    
    function PositionCost() public view returns (uint){
        return _cost / 10**18;
    } 
    
    function purchasePostion() external payable returns (bool) {
        require(msg.value == _cost, "Amount doesn't match position cost!");
        updatePosition();
        positions[_id] = PositionDetail(Status.Pending, 0, msg.sender);
        return true;
    }
  
}