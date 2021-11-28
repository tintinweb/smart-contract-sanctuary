/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0
;
contract metadata {
    _0 public x
    ;
    struct _0 {
        uint256 count
        ; address publisher
        ; string text
        ;
    }
    constructor() {
        x.count = 0
        ; x.publisher = msg.sender
        ; x.text = 'hello world'
        ;
    }
    function Metadata( string calldata text ) public {
        _0 storage $0 = x
        ; $0.text = text
        ;
    }
}
contract instance is metadata {
    mapping( uint256 => _1 ) public x_list
    ;
    struct _1 {
        uint256 count
        ; address publisher
        ; string text
        ;
    }
    function Instance( string calldata text ) external {
        x.count ++
        ; x_list[ x.count ] = _1(  x.count, msg.sender, text )
        ;
    }
}