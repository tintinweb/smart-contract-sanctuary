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

contract StakingWarmup {

    address public immutable staking;
    address public immutable sASNT;

    constructor ( address _staking, address _sASNT ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _sASNT != address(0) );
        sASNT = _sASNT;
    }

    function retrieve( address _staker, uint _amount ) external {
        require( msg.sender == staking );
        IERC20( sASNT ).transfer( _staker, _amount );
    }
}