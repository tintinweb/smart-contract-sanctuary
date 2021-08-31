// contracts/Wedding.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Wedding {

    address public lowbAddress;
    address public owner;
    uint private _randomSeed = 5201314;
    uint public balance;
    bool public isStart = true;
    uint public totalWY;

    struct Pool {
        address luckyLoser;
        uint luckyNumber;
        uint totalLoser;
        uint amount;
    }

    Pool[8] public poolOf;
    mapping (address => uint[8]) public luckyNumberOf;
    mapping (address => uint) public wyAmoutOf;

    
    event BlessNewlyweds(address indexed loser, uint indexed n, uint luckyNumber);
    event NewLuckyLoser(address indexed loser, uint indexed n, uint luckyNumber);

    constructor(address lowb_) {
        lowbAddress = lowb_;
        owner = msg.sender;
        poolOf[0].amount = 20000e18;
        poolOf[1].amount = 30000e18;
        poolOf[2].amount = 50000e18;
        poolOf[3].amount = 100000e18;
        poolOf[4].amount = 200000e18;
        poolOf[5].amount = 500000e18;
        poolOf[6].amount = 2000000e18;
        poolOf[7].amount = 10000000e18;
    }

    function getWyAmout(address player) public view returns(uint) {
        return wyAmoutOf[player];
    }
    
    function getPoolInfo(uint n) public view returns (Pool memory) {
      require(n < 8, "Index overflowed.");
      return poolOf[n];
    }

    function getPoolInfoV2(uint n) public view returns (address luckyLoser, uint luckyNumber, uint totalLoser, uint amount) {
      require(n < 8, "Index overflowed.");
      return (poolOf[n].luckyLoser, poolOf[n].luckyNumber, poolOf[n].totalLoser, poolOf[n].amount);
    }

    function setStart(bool _start) public {
        require(msg.sender == owner, "Only owner can start wedding!");
        isStart = _start;
    }
    
    function pullFunds() public {
        require(msg.sender == owner, "Only owner can pull the funds!");
        IERC20 lowb = IERC20(lowbAddress);
        lowb.transfer(msg.sender, balance);
        balance = 0;
    }

    function blessNewlyweds(uint n) public {
        require(isStart, "The weddig is not start.");
        require(n < 8, "Index overflowed.");
        IERC20 lowb = IERC20(lowbAddress);
        require(lowb.transferFrom(msg.sender, address(this), poolOf[n].amount), "Lowb transfer failed");
        _randomSeed = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randomSeed)));
        uint luckyNumber = _randomSeed % 5201314;
        luckyNumberOf[msg.sender][n] = luckyNumber;
        balance += poolOf[n].amount;
        poolOf[n].totalLoser ++;
        wyAmoutOf[msg.sender] += poolOf[n].amount / 100;
        totalWY += poolOf[n].amount / 100;
        emit BlessNewlyweds(msg.sender, n, luckyNumber);
        if (poolOf[n].luckyLoser == address(0) || luckyNumber < poolOf[n].luckyNumber) {
            poolOf[n].luckyNumber = luckyNumber;
            poolOf[n].luckyLoser = msg.sender;
            emit NewLuckyLoser(msg.sender, n, luckyNumber);
        }
    }

}