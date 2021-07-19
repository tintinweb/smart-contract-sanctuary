/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity >=0.7.0 <0.9.0;
contract demo2{
    int256 private total;
    function set(int256  _total) public {
        total = _total;
    } 
    
    function get() public view returns(int256){
        return total;
    }
}