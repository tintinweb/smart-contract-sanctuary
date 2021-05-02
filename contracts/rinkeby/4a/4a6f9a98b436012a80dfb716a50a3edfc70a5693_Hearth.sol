/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Hearth {

    address public ares;
    address public owner;
    address public newOwner;
    address public OHM;

    constructor( address ares_, address owner_, address OHM_ ) {
        require( ares_ != address(0) );
        ares = ares_;
        require( owner_ != address(0) );
        owner = owner_;
        require( OHM_ != address(0) );
        OHM = OHM_;
    }

    function transferIn( uint amount_ ) external returns ( bool ) {
        require( msg.sender == ares, "Only Ares" );
        IERC20( OHM ).transfer( ares, amount_ );
        return true;
    }

    function reclaim( address token_, uint amount_ ) external returns ( bool ) {
        require(msg.sender == owner, "Only owner" );
        IERC20( token_ ).transfer( owner, amount_ );
        return true;
    }

    function pushTransferOwnership( address newOwner_ ) external returns ( bool ) {
        require(msg.sender == owner, "Only owner" );
        newOwner = newOwner_;
        return true;
    }

    function pullTransferOwnership() external returns ( bool ) {
        require(msg.sender == newOwner, "Only new owner" );
        owner = newOwner;
        return true;
    }
}