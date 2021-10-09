/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

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
        lotteryArray.push(Lottery({
           timeline: block.timestamp,
           rannum: random()
        }));
    }
    
    function getLastestLottery () public view returns ( Lottery memory)  {
        if(lotteryArray.length>0){
            return lotteryArray[lotteryArray.length-1] ;
        }
        return lotteryArray[0];
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