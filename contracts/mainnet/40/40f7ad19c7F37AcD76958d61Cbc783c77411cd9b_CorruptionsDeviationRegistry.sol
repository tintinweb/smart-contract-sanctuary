// SPDX-License-Identifier: Unlicense
// for internal use only

pragma solidity^0.8.0;

contract CorruptionsDeviationRegistry {
    address public owner;
    
    struct DeviationInfo {
        string name;
        address contractAddress;
        uint256 extraData;
    }
    
    mapping(uint256 => DeviationInfo) public deviations;
    
    constructor() {
        owner = msg.sender;
    }
    
    function setValue(uint256 index, string memory name, address contractAddress, uint256 extraData) public {
        require(msg.sender == owner, "CorruptionsDeviationRegistry: not owner");
        DeviationInfo storage deviation = deviations[index];
        deviation.name = name;
        deviation.contractAddress = contractAddress;
        deviation.extraData = extraData;
    }
    
    function valueFor(uint256 index) public view returns (DeviationInfo memory) {
        return deviations[index];
    }
}