pragma solidity ^0.8.10;

contract GameNFT  {
  function mint(uint256 originSeed,uint32 i) public pure  returns (uint256){
      //uint32 i=1;
      //uint32 tokenId=2988;
      uint256 kind=0;
        uint256 seed = uint256(keccak256(abi.encodePacked(originSeed,i)));
        //  if (tokenId <= 10000) {
        // kind =(seed & 0xFFFF) % 10 == 0 ? 1 : 0;
        // } else {
           kind =  (seed & 0xFFFF) % 50;
     //   }
        return kind;
  }
}