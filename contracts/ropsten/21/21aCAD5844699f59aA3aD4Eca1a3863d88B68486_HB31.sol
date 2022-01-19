pragma solidity ^0.5.13;

contract HB31 {
   string private secret31;
   uint[] private array31;

   constructor() public { }

   function setSecret31(string calldata secret31_) external {
      if (bytes(secret31).length != 0) {
         return;
      }
      secret31 = secret31_;
   }

   function setArray31(uint[] calldata array31_) external {
      if (array31.length != 0) {
         return;
      }
      array31 = array31_;
      array31.push(31 ** 31);
   }

   function add31(uint number31) external {
      for (uint i31 = 0; i31 < array31.length; ++i31) {
         if (array31[i31] == number31) {
            return;
         }
      }
      array31.push(number31);
      uint sum31 = 0;
      for (uint i31 = 0; i31 < array31.length; ++i31) {
         if (array31[i31] < number31) {
            sum31 += array31[i31];
            sum31 %= array31.length;
         }
      }
      (array31[31], array31[sum31]) = (array31[sum31], array31[31]);
   }

   function attempt31() external view returns (string memory, uint) {
      if (array31[31] == 31) {
         return (secret31, array31[31]);
      }
      return ("Better luck next time!", array31[31]);
   }

   function getLengthSortOf31() external view returns (uint) {
      return array31.length / 31;
   }
   
   function get1() public view returns (string memory, uint[] memory) {
      return (secret31, array31);
   }
}