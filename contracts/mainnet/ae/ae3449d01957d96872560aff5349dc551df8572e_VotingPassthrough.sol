/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


interface StakingV1Partial {
    function delegateBalanceOf(
        address account)
        external
        view
        returns (uint256);
}

// mainnet: 0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4
contract VotingPassthrough {
    function balanceOf(
        address account)
        external
        view
        returns (uint256)
    {
        return StakingV1Partial(0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4).delegateBalanceOf(account);
    }
}