/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.9 <0.9.0
;
contract test {
    function _1UrlAdd( string calldata $0 ) external {
        uint _01click
        ;
        while ( _01click < _0click + 1 ) {
            if ( msg.sender == _x[ _01click ]._0admin ) {
                _1click ++
                ; x[ _1click ] = _1map( $0 )
                ; return
                ;
            }
            _01click ++
            ;
        }
        require( _01click < _0click, 'NOT_ADMIN' )
        ;
    }
    function _1Click() public view returns ( uint256 ) {
        return _1click
        ;
    }
    function _1Url( uint256 $0 ) public view returns ( string memory ) {
        return x[ $0 ]._1url
        ;
    }
    uint256 _1click
    ; struct _1map {
        string _1url
        ;
    }
    mapping( uint256 => _1map ) private x
    ;
    function _0AdminAdd( address $0 ) external {
        uint _01click
        ;
        while ( _01click < _0click + 1 ) {
            if ( msg.sender == _x[ _01click ]._0admin ) {
                _0click ++
                ; _x[ _0click ] = _0map( $0 )
                ; return
                ;
            }
            _01click ++
            ;
        }
        require( _01click < _0click, 'NOT_ADMIN' )
        ;
    }
    function _0Admin( uint256 $0 ) public view returns ( address ) {
        return _x[ $0 ]._0admin
        ;
    }
    function _0Click() public view returns ( uint256 ) {
        return _0click
        ;
    }
    uint256 _0click
    ; struct _0map {
        address _0admin
        ;
    }
    mapping( uint256 => _0map ) private _x
    ;
    constructor() {
        _x[ 0 ]._0admin = tx.origin
        ; x[ 0 ]._1url = 'https://gitcoin.co/l/comicno3'
        ;
    }
}