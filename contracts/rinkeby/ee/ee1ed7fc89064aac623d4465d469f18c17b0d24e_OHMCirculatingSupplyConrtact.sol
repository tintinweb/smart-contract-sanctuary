/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: AGPL-3.0-or-later\
pragma solidity 0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

contract OHMCirculatingSupplyConrtact {
    using SafeMath for uint;

    bool public isInitialized;

    address public OHM;
    address public owner;
    address[] public nonCirculatingOHMAddresses;

    constructor( address _owner, address _ohm ) {        
        owner = _owner;
        OHM = _ohm;
    }

    /**
        @notice get number of OHM in circulation
        @return uint
     */
    function OHMCirculatingSupply() external view returns ( uint ) {
        uint _totalSupply = IERC20( OHM ).totalSupply();

        uint _circulatingSupply = _totalSupply.sub( getNonCirculatingOHM() );

        return _circulatingSupply;
    }

    /**
        @notice get number of OHM out of circulation
        @return uint
     */
    function getNonCirculatingOHM() public view returns ( uint ) {
        uint _nonCirculatingOHM;

        for( uint i=0; i < nonCirculatingOHMAddresses.length; i = i.add( 1 ) ) {
            _nonCirculatingOHM = _nonCirculatingOHM.add( IERC20( OHM ).balanceOf( nonCirculatingOHMAddresses[i] ) );
        }

        return _nonCirculatingOHM;
    }

    /**
        @notice set addresses to be excluded from circulating supply
        @param _nonCirculatingAddresses address[] calldata
        @return bool
     */
    function setNonCirculatingOHMAddresses( address[] calldata _nonCirculatingAddresses ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );
        nonCirculatingOHMAddresses = _nonCirculatingAddresses;

        return true;
    }

    /**
        @notice change owner
        @param _newOwner address
        @return bool
     */
    function transferOwnership( address _newOwner ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );
        owner = _newOwner;
        return true;
    }
}