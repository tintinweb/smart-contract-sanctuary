/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

pragma solidity ^0.4.24;
contract DistributeTokens {
    address public owner; // gets set somewhere
    address[] public investors; // array of investors
    uint[] public investorTokens; // the amount of tokens each investor gets
    
    constructor() public {
        owner = msg.sender;
    }

    function invest() public payable {
        investors.push(msg.sender);
        investorTokens.push(msg.value / 100); // 5 times the wei sent
    }
    
    function getLast() public view returns(uint len){
        return investors.length;
    }


}