/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;


contract LIQS_AirDrop_Factory_V1 {
    uint private _index = 0;
    mapping(uint => address) private _airDropsByIndex;
    mapping(address => address) private _airDropsByToken;

    constructor() {}

    function addAirDrop(address airDrop_, address token_) external {
        _airDropsByIndex[_index] = airDrop_;
        _airDropsByToken[token_] = airDrop_;
        _index += 1;
    }

    function getAirDropsByIndex() external view returns(uint) {
        return _index;
    }

    function getAirDropByIndex(uint index_) external view returns(address) {
        return _airDropsByIndex[index_];
    }

    function getAirDropByToken(address token_) external view returns(address) {
        return _airDropsByToken[token_];
    }
}