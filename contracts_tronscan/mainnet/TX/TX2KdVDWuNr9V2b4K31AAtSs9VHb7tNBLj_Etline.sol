//SourceUnit: Trline.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
contract Etline {
    uint256 public Cost = 10000000;
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
        require(msg.value == Cost, "Amount doesn't match position cost!");
        //require(Account[msg.sender].CyclerID == 0, "You can buy up to 1 position per account!");
        Position[++Total] = Line(0, 0, msg.sender);
        Account[msg.sender].CyclerID = Total;
        Cycle(Total);
        return true;
    }
    function Cycle(uint256 c) private {
        uint256 i = --c/3;
        Position[i].Downlines++;
        if(Position[i].Downlines == 3){
        	Position[i].Level++;
        	payable(Position[i].Owner).transfer(Cost * Position[i].Level);
        	Position[i].Downlines = 0;
        	if(i > 0) Cycle(i);
	    }
    }
}