/**
 *Submitted for verification at BscScan.com on 2021-08-26
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


contract LotteryGenerator  {

    struct Lottery{
        uint timeline;
        uint rannum;
    }
    
    Lottery[] private  lotteryArray;
    
    
     function setLottery() public {
        lotteryArray.push(Lottery(
           block.timestamp,
           random()
        ) );
    }
    
    function getLottery () public view returns ( Lottery[] memory)  {
        return lotteryArray ;
    }
    
    function getLengthLottery () public view returns (uint)  {
        return lotteryArray.length ;
    }
    
    function getIndexLottery (uint index) public view returns (uint)  {
        return lotteryArray[index].rannum;
    }
    function getLottery (uint k) public view returns ( Lottery memory)  {
        return lotteryArray[k] ;
    }
    function random() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 1000000;
    }
}