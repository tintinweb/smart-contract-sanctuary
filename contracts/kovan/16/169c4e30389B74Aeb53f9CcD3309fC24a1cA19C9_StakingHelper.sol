// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

//     ___                         __ 
//    /   |  _____________  ____  / /_
//   / /| | / ___/ ___/ _ \/ __ \/ __/
//  / ___ |(__  |__  )  __/ / / / /_  
// /_/  |_/____/____/\___/_/ /_/\__/  
// 
// 2022 - Assent Protocol
// Code based on OlympusDAO development

import './IERC20.sol';
import './IStaking.sol';


contract StakingHelper {

    address public immutable staking;
    address public immutable ASNT;

    constructor ( address _staking, address _ASNT ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _ASNT != address(0) );
        ASNT = _ASNT;
    }

    function stake( uint _amount ) external {
        IERC20( ASNT ).transferFrom( msg.sender, address(this), _amount );
        IERC20( ASNT ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, msg.sender );
        IStaking( staking ).claim( msg.sender );
    }
}