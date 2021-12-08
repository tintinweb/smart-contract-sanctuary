/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity ^0.4.21;

interface FuzzyIdentityChallenge {
    function authenticate() external view;
}

contract ItsMe {
    address public owner;
    constructor() {
        owner=msg.sender;
    }

    function name() external view returns (bytes32) {
        return bytes32("smarx");
    }

    function letsGo(address _destination) public {
        require(owner==msg.sender);
        FuzzyIdentityChallenge(_destination).authenticate();
    }
}