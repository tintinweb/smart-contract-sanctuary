/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.8.0;
contract Cal{
    uint256 c;
    uint256 d;
    
    function add(uint256 c, uint256 d) public view returns(uint256){
        return c+d;
    }
    function sub(uint256 c, uint256 d) public view returns(uint256){
        return c-d;
    }
    function mul(uint256 c, uint256 d) public view returns(uint256){
        return c*d;
    }
    function div(uint256 c, uint256 d) public view returns(uint256){
        return c/d;
    }
    
}