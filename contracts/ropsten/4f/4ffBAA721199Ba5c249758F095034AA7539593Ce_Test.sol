/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

contract Test
{
    uint256 x = 0;

    function getX()public view returns(uint256)
    {
        return x;
    }
    function setX(uint256 _x)public
    {
        x = _x;
    }
    receive() external payable {
        setX(5);
    }
    
}