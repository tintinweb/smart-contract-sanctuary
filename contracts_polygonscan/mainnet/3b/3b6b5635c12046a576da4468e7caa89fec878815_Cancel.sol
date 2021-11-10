// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";

contract Cancel {
  using SafeMath for uint256;
  
  //this mean, winner gets 90% by prize pool
  uint256 public constant PrizePart = 90;
  
  uint256 public constant _StartDuty = 0.01 ether;
  
  uint private _StartTimer = 20;
  
  uint256 public Duty = 0;
  
  uint256 public RescueCounter = 0;
  
  bool public IsPaused = false;
  bool public IsOver = false;
  
  mapping(address => uint256) public _rescues;
  
  mapping(address => uint256) public _duties;
  
  address private _lastRescue;
  
  uint private _lastBlock;
  
  uint public Timer = 20;
  
  address private devAddress = 0x2D72855b361E0ac011D28297aEaC4B83cFdD5877; //devShare
  
  address private _owner;
  
  ///You can't do it 2 times in a row
  error DoubleRescue();
  
  modifier onlyOwner{
       require(msg.sender==_owner, "Only for owner");
    _;
  }
  
  constructor(){
      _owner = msg.sender;
      restart();
  }
  
  function rescue() external payable {
    require(!IsOver, "Game is over");
    require(!IsPaused, "Game on pause");
    require(msg.value >= Duty, "Insufficient payment");
    require(_lastRescue != msg.sender, "You can't do it 2 times in a row");
    if(_lastBlock == 0)
    {
        _lastBlock = block.number;
    }
    if(block.number-_lastBlock > Timer)
    {
        //game over
        IsOver = true;
        
        (bool success, ) = msg.sender.call{value: msg.value}("rejected");
        if(!success)
        {
            //smth special...
        }
        return;
    }
    
    if(Duty < msg.value)
    {
        Duty = msg.value;
    }

    _rescues[msg.sender] += 1;
    _duties[msg.sender] += msg.value;
    _lastRescue = msg.sender;
    _lastBlock = block.number;
    RescueCounter += 1;
    Timer -= 1;
  }

  function setPause(uint state) external onlyOwner {
    if(state == 0)
    {
        IsPaused = false;
    }
    else if(state == 1)
    {
        IsPaused = true;
    }
  }
  
  function setStartTimer(uint timer) external onlyOwner {
    require(timer > 0, "Timer is null");
    _StartTimer = timer;
  }
  
  function getInfo(address wallet) public view returns (bool, uint, uint, uint256, uint256){
    return (_lastRescue == wallet, _lastBlock, Timer, Duty, getPrizePool());
  }
  
  function withdrawToWinner() external {
    require(_lastBlock > 0, "Game not started");
    require(block.number - _lastBlock > Timer, "Game not completed");
    require(!IsPaused, "Game on pause");
    
    withdraw();
  }
  
  function withdrawWrapper() external onlyOwner {
    withdraw();
  }
  
  function withdraw() private {
    require(address(this).balance > 0, "No balance to withdraw");
    
    if(RescueCounter == 1)
    {
        (bool success, ) = _lastRescue.call{value: address(this).balance}("");
        require(success, "Withdrawal failed 1");
    }
    else
    {
        uint winnerAward = getPrizePool();

        (bool success, ) = _lastRescue.call{value: winnerAward}("");
        require(success, "Withdrawal failed 2");
    
        (success, ) = devAddress.call{value: address(this).balance}("");
        require(success, "Withdrawal failed 3");
    }
    restart();
  }
  
  function restart() private {
    Duty = _StartDuty;
    RescueCounter = 0;
    IsOver = false;
    _lastRescue = address(0);
    _lastBlock=0;
    Timer = _StartTimer;
  }
  
  function getPrizePool() public view returns(uint256){
      return address(this).balance.mul(PrizePart).div(100);
  }
}