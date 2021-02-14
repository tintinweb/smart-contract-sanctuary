/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

pragma solidity >=0.7.0 <0.8.0;

contract Test {

    uint256 number;

    function store(uint256 num) public {
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}