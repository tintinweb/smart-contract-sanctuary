/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity >=0.7.0 <0.8.0;

contract EnterpriseModelsContract {
    mapping(address => mapping(string => string)) private permissions;
    address private owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function setPermission(address pAddress, string memory pAsset, string memory pKey) public {
        if (msg.sender == owner) {
            permissions[pAddress][pAsset] = pKey;
        }
    }
    
    function getPermission(string memory pAsset) public view returns (string memory) {
        return permissions[msg.sender][pAsset];
    }
}