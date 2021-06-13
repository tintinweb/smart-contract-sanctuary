/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity >=0.7.0 <0.9.0;
contract Storage {

    uint256 public number;
    function store(uint256 num) public {
        number = num;
    }
    function retrieve() public view returns (uint256){
        return number;
    }
}