// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


import "./IERC20.sol";


contract NayaStakingWarmup {

    address public immutable staking;
    address public immutable sNAYA;

    constructor ( address _staking, address _sNAYA ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _sNAYA != address(0) );
        sNAYA = _sNAYA;
    }

    function retrieve( address _staker, uint _amount ) external {
        require( msg.sender == staking );
        IERC20( sNAYA ).transfer( _staker, _amount );
    }
}