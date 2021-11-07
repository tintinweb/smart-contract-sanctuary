/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

pragma solidity >=0.5.0;







contract TestContract {
    mapping(int16 => uint256) dix;
    
    mapping(int24 => uint256)  public ticks ;
    
      function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(tick % 256);
    }
    
    function initticks()external {
        ticks[-2]=2;
        ticks[-91000]=91000;
        ticks[-91016]=91016;
        
    }
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        require(tick % tickSpacing == 0); // ensure that the tick is spaced
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }
   
    function AddX(uint a,uint b ) external  returns (uint)
    {
        dix[-2]=a;
        return a+b;
    }
    
    int public a ;
    uint8 public ccc;
    function xxxx(int24 tick) public returns (uint8){
        ccc= uint8(tick % 256);
        return ccc;
    }
    
    function SubX(uint a,uint b ) external  returns (uint)
    {
        return a-b;
    }
   
}