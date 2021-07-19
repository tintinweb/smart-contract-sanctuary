/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity >=0.7.0 <0.9.0;

contract DogWater{
    
    function absoluteDogWater(uint256 bruhMoment) public view returns (uint256){
        return bruhMoment + 5;
    }
    function  bruh() public view returns (uint256){
        return 12;
    }
    function zzz() public view returns (bytes memory){
        bytes memory brr = abi.encodeWithSignature("absoluteDogWater(uint256)",7);
        return brr;
    }
}