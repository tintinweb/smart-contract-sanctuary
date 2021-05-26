/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract StakingLocker {

    address immutable staking;
    address immutable sOHM;

    constructor( address staking_, address sOHM_ ) {
        require( staking_ != address(0) );
        staking = staking_;
        require( sOHM_ != address(0) );
        sOHM = sOHM_;
    }

    function unlock( uint amount_, uint bonus_, address staker_ ) external returns ( bool ) {
        require( msg.sender == staking, "Only staking" );
        IERC20( sOHM ).transfer( staking, bonus_ );
        return IERC20( sOHM ).transfer( staker_, amount_ );
    }
}