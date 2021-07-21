/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

 contract test{
    struct Fee {
        address payable recipient;
        uint256 value;
    }
     
     
     function ccc(uint256  f,Fee[] memory s) internal pure returns (string memory c ) {
        c = "liaolei";
        return c;
    }
    
    function DDD(uint256 f, Fee[] memory s) public {
        ccc(f,s);
    }
 }