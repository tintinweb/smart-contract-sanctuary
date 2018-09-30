pragma solidity ^0.4.19;

contract ExmoEvent {
    uint8[] keys;
    
    constructor(uint8[] _params) {
        for (uint i = 0; i < _params.length; i++) {
            
            keys.push(_params[i]);
        }
    }

    function createRandomZombie(int256 dotcom) public view returns (uint8[]) {
        return keys;
    }

}