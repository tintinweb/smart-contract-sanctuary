/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

pragma solidity >=0.4.21 <0.7.0;

contract SimpleStorage {
  uint storedData;
  uint storedData1;
  uint storedData2;
  uint counter;

  function setX(uint x) public {
    storedData = x;
    counter++;
  }

  function setY(uint y) public {
    storedData1 = y;
    counter++;
  }

  function setSUM(uint x, uint y) public {
    storedData2 = x+y;
    counter++;
  }

  function getX() public view returns (uint) {
    return storedData;
  }
  function getY() public view returns (uint) {
     return storedData1;
  }

  function getSUM() public view returns (uint){
    return storedData2;
  }
  function getCounter() public view returns (uint){
    return counter;
  }
}