/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

pragma solidity >=0.4.22 <0.8.0;

contract Storage {
    uint256 public number;
    
    function store(uint256 _num)public {
        number=_num;
    }
    
    function review()public view returns(uint256){
        return number;
    }
}