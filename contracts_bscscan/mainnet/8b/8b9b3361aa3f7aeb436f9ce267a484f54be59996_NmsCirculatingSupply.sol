// SPDX-License-Identifier: AGPL-3.0-or-later\
pragma solidity 0.7.5;

import "IERC20.sol";

import "SafeMath.sol";

contract NmsCirculatingSupply {
    using SafeMath for uint;

    bool public isInitialized;

    address public NMS;
    address public owner;
    address[] public nonCirculatingNMSAddresses;

    constructor( address _owner ) {
        owner = _owner;
    }

    function initialize( address _nms ) external returns ( bool ) {
        require( msg.sender == owner, "caller is not owner" );
        require( isInitialized == false );

        NMS = _nms;

        isInitialized = true;

        return true;
    }

    function NMSCirculatingSupply() external view returns ( uint ) {
        uint _totalSupply = IERC20( NMS ).totalSupply();

        uint _circulatingSupply = _totalSupply.sub( getNonCirculatingNMS() );

        return _circulatingSupply;
    }

    function getNonCirculatingNMS() public view returns ( uint ) {
        uint _nonCirculatingNMS;

        for( uint i=0; i < nonCirculatingNMSAddresses.length; i = i.add( 1 ) ) {
            _nonCirculatingNMS = _nonCirculatingNMS.add( IERC20( NMS ).balanceOf( nonCirculatingNMSAddresses[i] ) );
        }

        return _nonCirculatingNMS;
    }

    function setNonCirculatingNMSAddresses( address[] calldata _nonCirculatingAddresses ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );
        nonCirculatingNMSAddresses = _nonCirculatingAddresses;

        return true;
    }

    function transferOwnership( address _owner ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );

        owner = _owner;

        return true;
    }
}