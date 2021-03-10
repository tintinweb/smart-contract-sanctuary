/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

pragma solidity ^0.6.0;


contract ExampleContract {
    
    string ihaveastring;
    event changed(string value);

    
    function storeSomething(string memory _a) public {
        ihaveastring = _a;
        emit changed(ihaveastring);
    }
    
    function retrieveSomething() public view returns (string memory) {
        return ihaveastring;
    }
    
}