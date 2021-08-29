/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Cycler {
    enum Status {Pending, Cycled}
    uint256 _id;
    uint256 _levels = 5;
    uint256 _cost = 0.01 * 10 ** 18;
    struct PositionDetail {
        Status status;
        uint256 level;
        address owner;
    }
    struct AccountDetail {
        uint256 id;
        uint256 balance;
    }
    mapping(uint256 => PositionDetail) private positions;
    mapping(address => AccountDetail) private accounts;
    constructor() public {
        positions[_id] = PositionDetail(Status.Pending, 0, msg.sender);
    }
    function PositionInfo(uint256 id) public view returns (Status, uint256, address){
        return (
            positions[id].status,
            positions[id].level,
            positions[id].owner
        );
    }
    function TotalPositions() public view returns (uint256){
        return _id;
    }
    function AccountInfo()  public view returns (uint256, Status, uint256, uint256){
        uint256 id = accounts[msg.sender].id; 
        return (
            id,
            positions[id].status,
            positions[id].level,
            accounts[msg.sender].balance
        );
    }
    function PurchasePostion() external payable returns (bool) {
        require(msg.value == _cost, "Amount doesn't match position cost! Position cost 0.01 BNB!");
        require(accounts[msg.sender].id != 0, "You can purchase one position per account!");
        uint256 current = _id / _levels;
        positions[current].level = positions[current].level + 1;
        if(positions[current].level == _levels){
            positions[current].status = Status.Cycled;
            payable(positions[current].owner).transfer( _cost * _levels );
        }
        _id++;
        positions[_id] = PositionDetail(Status.Pending, 0, msg.sender);
        accounts[msg.sender].id = _id;
        return true;
    }
}