/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.6.0;

contract A {
    function a() public view returns(uint256,uint256,uint256,uint256,uint256){
        return (1,2,5,6,4);
    }
    
    function B()public{
        (uint256 a,,,,) = a();
    }
    
    function C()public{
        (uint256 a,uint256 b,uint256 c,uint256 d,uint256 e) = a();
    }
    
}