/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract StakingVesting {

    address staking;
    address sOHM;

    bool isInitialized;

    function initialize( address staking_, address sOHM_ ) external returns ( bool ) {
        require( !isInitialized );
        require( staking_ != address(0) );
        staking = staking_;
        require( sOHM_ != address(0) );
        sOHM = sOHM_;
        isInitialized = true;
        return true;
    }

    function vest( uint amount_ ) external returns ( bool ) {
        require( msg.sender == staking, "Only staking" );
        return IERC20( sOHM ).transfer( staking, amount_ );
    }
}