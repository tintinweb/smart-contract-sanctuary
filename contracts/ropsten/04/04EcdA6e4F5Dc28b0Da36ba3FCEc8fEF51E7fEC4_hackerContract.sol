pragma solidity ^0.4.21;

import './FuzzyIdentity.sol';

contract hackerContract is IName {
    FuzzyIdentityChallenge ficContract = FuzzyIdentityChallenge(0x52d8CaBb5f3F914C472Bfaf34205D9466000cD69);
    
    function name() external view returns (bytes32) {
        return bytes32("smarx");
    }
    
    function doIt() public {
        ficContract.authenticate();
    }
}