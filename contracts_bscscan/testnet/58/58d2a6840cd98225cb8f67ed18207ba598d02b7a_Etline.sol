/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

// SPDX-License-Identifier: GPL-3.0


/**
 * Etline is decentraliced system.
 * 
 * 
 * 
 **/
 
 
pragma solidity 0.8.0;
contract Etline {
    uint256 public Total;
    struct Line {
        uint8 Level;
        uint256 Downlines;
        address Owner;
    }
    struct Address {
        uint256 CyclerID;
    }
    mapping(uint256 => Line) public Position;
    mapping(address => Address) public Account;
    constructor() {
        Position[Total] = Line(0, 0, msg.sender);
    }
    function MyAccount() public view returns (uint256 CyclerID, uint8 Level, uint256 Downlines){
        uint256 ID = Account[msg.sender].CyclerID;
        return (
            ID,
            Position[ID].Level,
            Position[ID].Downlines
        );
    }
    function Buy() external payable returns (bool) {
        require(msg.value == 1, "Amount doesn't match position cost!");
        Cycle(Total / 3);
        Position[++Total] = Line(0, 0, msg.sender);
        Account[msg.sender].CyclerID = Total;
        return true;
    }
    function Cycle(uint256 _id) private returns (bool){
        Position[_id].Downlines = Position[_id].Downlines + 1;
        if(Position[_id].Downlines != 3) return true;
        payable(Position[_id].Owner).transfer(2);
        Position[_id].Level = Position[_id].Level + 1;
        Position[_id].Downlines = 0;
        if(_id > 0) Cycle(_id - 1);
        return true;
    }
}