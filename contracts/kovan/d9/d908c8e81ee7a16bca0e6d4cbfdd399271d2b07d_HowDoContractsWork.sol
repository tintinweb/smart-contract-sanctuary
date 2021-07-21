/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract HowDoContractsWork 
{
    function doesRequirePrintIfTrue() public payable returns (uint256 weiPaid)
    {
        require(true, "sup anwi");
        return msg.value;
    }
    
    function doesRequirePrintIfFalse() public payable returns (uint256 weiPaid)
    {
        require(false, "sup homie");
        return msg.value;
    }
}