/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0
;
contract dataset {
    function child( string calldata $0 ) external {
        require(
            _x[ 0 ].initialized
            , "NOT_YET_INITIALIZED"
        )
        ; _x[ 0 ].count ++
        ; x[ 0 ] = _1(
            _x[ 0 ].count
            , _x[ 0 ].publisher
            , _x[ 0 ].text
            , 3
        )
        ; x[ _x[ 0 ].count ] = _1(
            _x[ 0 ].count
            , msg.sender
            , $0
            , 4
        )
        ;
    }
    constructor() {
        _x[ 0 ].count = 0
        ; _x[ 0 ].initialized = false
        ; _x[ 0 ].publisher = msg.sender
        ; _x[ 0 ].secret = 'none'
        ; _x[ 0 ].text = 'hello world'
        ;
    }
    function parent( string calldata $0 ) external {
        if ( ! _x[ 0 ].initialized ) {
            _x[ 0 ].initialized = true
            ; _x[ 0 ] = _0(
               _x[ 0 ].count
                , _x[ 0 ].initialized
                , _x[ 0 ].publisher
                , $0
                , _x[ 0 ].text
            )           
            ; x[ 0 ] = _1(
                _x[ 0 ].count
                , _x[ 0 ].publisher
                , _x[ 0 ].text
                , 1
            )
            ; return
            ;
        }
        require(
            msg.sender == _x[ 0 ].publisher
            , "NOT_PUBLISHER"
        )
        ; _x[ 0 ] = _0(
            _x[ 0 ].count
            , _x[ 0 ].initialized
            , _x[ 0 ].publisher
            , _x[ 0 ].secret
            , $0
        )
        ; x[ 0 ] = _1(
            _x[ 0 ].count
            , _x[ 0 ].publisher
            , _x[ 0 ].text
            , 2
        )
        ;
    }
    function secret() public view returns ( string memory ) {
        require(
            msg.sender == _x[ 0 ].publisher
            , "NOT_PUBLISHER"
        )
        ; return _x[0].secret
        ;
    }
    mapping( uint256 => _0 ) private _x
    ; mapping( uint256 => _1 ) public x
    ;
    struct _0 {
        uint256 count
        ; bool initialized
        ; address publisher
        ; string secret
        ; string text
        ;
    }
    struct _1 {
        uint256 count
        ; address publisher
        ; string text
        ; uint256 version
        ;
    }
}