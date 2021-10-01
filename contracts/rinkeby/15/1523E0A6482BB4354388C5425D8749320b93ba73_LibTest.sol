/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Random {
    function random() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)) ;
    }

    struct Manifest {
        uint256[] _data;
    }

    function setup(Manifest storage self, uint256 length) internal {
        uint256[] storage data = self._data;

        require(data.length == 0, 'cannot-setup-during-active-draw');
        assembly { sstore(data.slot, length) }
    }

    function draw(Manifest storage self) internal returns (uint256) {
        return draw(self, random());
    }

    function draw(Manifest storage self, bytes32 seed) internal returns (uint256) {
        uint256[] storage data = self._data;

        uint256 l = data.length;
        uint256 i = uint256(seed) % l;
        uint256 x = data[i];
        uint256 y = data[--l];
        if (x == 0) { x = i + 1;   }
        if (y == 0) { y = l + 1;   }
        if (i != l) { data[i] = y; }
        data.pop();
        return x - 1;
    }

    function put(Manifest storage self, uint256 i) internal {
        self._data.push(i + 1);
    }

    function remaining(Manifest storage self) internal view returns (uint256) {
        return self._data.length;
    }
}
contract LibTest{

    Random.Manifest private seeds;

    event ReturnValue(uint256 result);

    constructor(uint256 _l){
        Random.setup(seeds, _l);
    }
    
    function getToken() public returns (uint256){
        return Random.draw(seeds);
    }
    
}