/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

pragma solidity <0.6.5;

contract HelloWorld{
    
    string latestString;
    
    constructor() public {
        latestString = 'HelloWorld';
    }
    
    // set string
    function setString(string memory _latestString) public {
        latestString = _latestString;
    }
    
    // get string
    function getString() view public returns(string memory){
        return latestString;
    }
}