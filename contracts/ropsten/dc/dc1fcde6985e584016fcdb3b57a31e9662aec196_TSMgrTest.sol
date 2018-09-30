pragma solidity ^0.4.24;

contract TSMgrTest {
    mapping(uint256 => mapping(address => bool)) public whitelist;

    function addToWhitelist(address _beneficiary) public{
        for (uint256 i = 0; i < 5; i++ ) {
            whitelist[i][_beneficiary] = true;
        }
    }

    function addManyToWhitelist(address[] _beneficiaries) public {
        for (uint256 i = 0; i < 5; i++ ) {
            for (uint256 j = 0; j < _beneficiaries.length; j++) {
                whitelist[i][_beneficiaries[j]] = true;
            }
        }
    }
}