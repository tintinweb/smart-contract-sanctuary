/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity >=0.4.0 <0.6.0;

contract A  {
    uint public X = 0;
    
    function changeX(uint _val) public {

      X = _val;
    }
}