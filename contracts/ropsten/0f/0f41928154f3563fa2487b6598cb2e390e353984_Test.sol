pragma solidity ^0.4.25;

contract Test{
  event Random(uint randomNumber);
  mapping(uint => uint) storageTest;
  uint stCursor;
  function benchmarkRandom() public{
    for(uint8 i=0;i<120;i++){
      uint calcTest=random(10000,block.number-1,msg.sender,i);
      bool b1=calcTest<567;
      calcTest=random(10000,block.number-1,msg.sender,i+1);
      bool b2=calcTest<765;
      if(b1&&b2){
        calcTest+=calcTest/543;
      }
      //emit Random(calcTest);
      storageTest[stCursor]=calcTest;
      stCursor++;
    }
  }
  function maxRandom(uint blockn, address entropy, uint8 entropy2)
    internal
    returns (uint256 randomNumber)
  {
      return uint256(keccak256(
          abi.encodePacked(
            blockhash(blockn),
            entropy,entropy2)
      ));
  }
  function random(uint256 upper, uint256 blockn, address entropy, uint8 entropy2)
    internal
    returns (uint256 randomNumber)
  {
      return maxRandom(blockn, entropy,entropy2) % upper + 1;
  }
}