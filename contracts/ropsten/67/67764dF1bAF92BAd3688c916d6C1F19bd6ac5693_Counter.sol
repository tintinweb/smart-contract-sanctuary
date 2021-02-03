pragma solidity >=0.6.6;
import "hardhat/console.sol";
contract Counter {
  uint256 count = 0;
  event CountedTo(uint256 number);
  function getCount() public view returns (uint256) {
    return count;
  }
  function countUp() public returns (uint256) {
    console.log("countUp: count =", count);
    uint256 newCount = count + 1;
    require(newCount > count, "Uint256 overflow");
    count = newCount;
    emit CountedTo(count);
    return count;
  }
  function countUpValue(uint val) public returns (uint256) {
    console.log("countUp: count =", count);
    uint256 newCount = count + val;
    require(newCount > count, "Uint256 overflow");
    count = newCount;
    emit CountedTo(count);
    return count;
  }
  function countDown() public returns (uint256) {
    console.log("countDown: count =", count);
    uint256 newCount = count - 1;
    require(newCount < count, "Uint256 underflow");
    count = newCount;
    emit CountedTo(count);
    return count;
  }
}