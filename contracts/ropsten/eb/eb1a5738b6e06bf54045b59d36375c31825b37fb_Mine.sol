/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity >=0.7.0 <0.9.0;

contract Mine {
    uint256[] arr; 
    function write(uint256 num) public {
        arr.push(num);
    }
    function show() public view returns (uint256){
        uint256 totalsize = 0;
        uint256 count = arr.length;
        for(uint256 i = 0 ; i < count ; i++ )
        {
            totalsize = arr[i];
        }
        return totalsize;
    }
}