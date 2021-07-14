/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract aa
{
    address public a;
    address public b;
    address public c;
    
    function send(address _a, address _b, address _c) external returns(uint, uint)
    {
        a = _a;
        b = _b;
        c = _c;
        
        return(1, 2);
    }
    
    function reset() external {
        a = address(0);
        b = address(0);
        c = address(0);
    }
}