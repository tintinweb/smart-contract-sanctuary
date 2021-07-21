/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract HowDoContractsWork 
{
    function doesRequirePrintIfTrue() public pure
    {
        require(true, "sup homie");
    }
    
    function doesRequirePrintIfFalse() public pure
    {
        require(false, "sup homie");
    }
}