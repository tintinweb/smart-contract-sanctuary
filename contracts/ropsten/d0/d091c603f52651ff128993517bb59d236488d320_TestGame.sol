pragma solidity ^0.4.18;

contract TestIPG {

   function transferInGame (address _from, address _to, uint256 _value) public returns (bool success);

}

contract TestGame {

address owner = 0x815dE3E00Be485DBCA2A2ADf40f945a8E0343b29;

bool isPaused;

modifier onlyOwner() {
require (msg.sender == owner);
_;
}

function pauseGame() public onlyOwner {
  isPaused = true;
}

function playGame() public onlyOwner {
  isPaused = false;
}

function GetIsPauded() public view returns(bool) {
  return(isPaused);
}

function sendToken(address _from, address _to, uint256 _amount) public onlyOwner {
  TestIPG w = TestIPG(0x97bFC17fF8d1E282Db45AB64981eDB2D5B6d22d2);
  w.transferInGame(_from, _to, _amount);
}

}