// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomId {

    uint public tokenMaxSupply;
    uint16[] private _unusedRandomIds;

    constructor(uint initTokenMaxSupply) {
        tokenMaxSupply = initTokenMaxSupply;
    }

    function fillUnusedRandomIds(uint16 howMany) public {
        for(uint16 i = 0; i < howMany; i++) {
            uint16 nextRandomIdIndex = uint16(_unusedRandomIds.length);
            if (nextRandomIdIndex < tokenMaxSupply) {
                _unusedRandomIds.push(nextRandomIdIndex + 1);
            } else {
                return;
            }
        }
    }

    function getUnusedRandomids() public view returns (uint16[] memory) {
        return _unusedRandomIds;
    }

    function emptyRandomIds() public {
        delete _unusedRandomIds;
    }
}

