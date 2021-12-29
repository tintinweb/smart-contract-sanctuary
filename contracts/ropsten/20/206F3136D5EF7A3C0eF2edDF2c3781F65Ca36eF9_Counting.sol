/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

pragma solidity >=0.7.3;

contract Counting {

   event Increased(int256 total, address user, int256 usercount);

   mapping(address => int256) public counts;
   int256 public total;

   constructor() public {
      total = 0;
   }

   function next() public {
      counts[msg.sender] = counts[msg.sender] + 1;
      total = total + 1;
      emit Increased(total, msg.sender, counts[msg.sender]);
   }
}