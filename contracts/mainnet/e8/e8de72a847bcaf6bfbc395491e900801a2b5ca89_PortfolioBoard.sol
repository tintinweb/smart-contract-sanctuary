/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

contract PortfolioBoard {
    address private owner;
    constructor() {
        owner = msg.sender; 
    }
    
    bytes32[] private consolidatedHashes; 
    
    function addNewPortfolioHash (bytes32 _traderPortfolioHash) payable public {
        require (msg.sender == owner); 
        consolidatedHashes.push(_traderPortfolioHash);
    }

}