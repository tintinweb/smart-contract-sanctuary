/**
 *Submitted for verification at Etherscan.io on 2021-01-14
*/

pragma solidity  0.8.0;

contract RotatingHands 
{
    function multisend(uint256[] memory amounts, address payable[] memory receivers) payable external
    {
            require(amounts.length == receivers.length, "Amounts and receivers array do not have the same length."); //Amounts array and receivers array needs to have an equal amount of values in them
            require(receivers.length <= 100, "Receivers array is to big."); //maximum receievers can be 100
            
            //Sending the given amount to the receivers
            for(uint256 i=0;i<amounts.length;i++)
            {
                receivers[i].transfer(amounts[i]);
            }
    }
}