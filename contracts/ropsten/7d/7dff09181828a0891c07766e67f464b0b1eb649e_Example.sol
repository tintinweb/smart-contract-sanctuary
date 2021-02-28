/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

pragma solidity ^0.6.0;


contract Example {
    string ihavestring;
    
    function storeSometing (string memory _a) public {
        ihavestring = _a;
    }
    
    function getSomething() public view returns (string memory) {
        return ihavestring;
    }
}