/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

/**
 * The date is 13 May 2021. The simping of the crypto bros for Elon to pick their coin over boomercoin has gotten out of control.
 * 
 * Something had to be done.
 */

pragma solidity ^0.8.0;

contract EndElonSimpPledge {
    string public constant PLEDGE = "I promise to stop simping for Elon on the tl and elsewhere; I accept he will not pick my coin and I promise to move on with my life.";
    
    event StopSimpingPledgeMade(address indexed simplessSoul);
    
    function signPledge() external {
        emit StopSimpingPledgeMade(msg.sender);
    }
}