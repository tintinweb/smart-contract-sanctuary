/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

pragma solidity ^0.4.21;

contract CallMeChallenge {
    bool public isComplete = false;

    function callme() public {
        isComplete = true;
    }
}