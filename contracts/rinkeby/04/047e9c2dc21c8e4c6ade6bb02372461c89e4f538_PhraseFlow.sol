/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.4.20;

contract PhraseFlow {
    string[] public flow;
    uint256 public count;
    
    function add (string newPhrase) public {
        flow.push(newPhrase);
        count += 1;
    }
}