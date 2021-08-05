/**
 *Submitted for verification at Etherscan.io on 2021-01-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

// iRUNE Interface
interface iRUNE {
    function transfer(address, uint) external returns (bool);
    function transferTo(address, uint) external returns (bool);
}

contract RUNE_Bridge {

    address public owner;
    address public server;
    address public RUNE;

    event Deposit(address indexed from, uint value, string memo);
    event Outbound(address indexed to, uint value, string memo);

    constructor() {
        owner = msg.sender;
    }

    // Only Owner can execute
    modifier onlyOwner() {
        require(msg.sender == owner, "Must be Owner");
        _;
    }

    // Only Owner/Server can execute
    modifier onlyAdmin() {
        require(msg.sender == server || msg.sender == owner, "Must be Admin");
        _;
    }

    // Owner calls to set server
    function setServer(address _server) public onlyOwner {
        server = _server;
    }

    // Owner calls to set RUNE
    function setRune(address _rune) public onlyOwner {
        RUNE = _rune;
    }

    // User to deposit RUNE with a memo.
    function deposit(uint value, string memory memo) public {
        require(value > 0, "user must send assets");
        iRUNE(RUNE).transferTo(address(this), value);
        emit Deposit(msg.sender, value, memo);
    }

    // Admin to transfer to recipient
    function transferOut(address to, uint value, string memory memo) public onlyAdmin {
        iRUNE(RUNE).transfer(to, value);
        emit Outbound(to, value, memo);
    }

}