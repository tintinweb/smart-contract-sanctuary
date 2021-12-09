/**
 *Submitted for verification at polygonscan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

interface IVotingEscrowCallback {
    function syncWithVotingEscrow(address account) external;
}

// File: contracts/misc/VotingEscrowHelperV2.sol

pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;


contract VotingEscrowHelperV2 is IVotingEscrowCallback {
    IVotingEscrowCallback public immutable ballot;

    IVotingEscrowCallback public immutable distributor;
    IVotingEscrowCallback public immutable exchange;

    IVotingEscrowCallback public immutable distributor2;
    IVotingEscrowCallback public immutable exchange2;

    constructor(
        address ballot_,
        address distributor_,
        address exchange_,
        address distributor2_,
        address exchange2_
    ) public {
        ballot = IVotingEscrowCallback(ballot_);

        distributor = IVotingEscrowCallback(distributor_);
        exchange = IVotingEscrowCallback(exchange_);

        distributor2 = IVotingEscrowCallback(distributor2_);
        exchange2 = IVotingEscrowCallback(exchange2_);
    }

    function syncWithVotingEscrow(address account) external override {
        ballot.syncWithVotingEscrow(account);

        distributor.syncWithVotingEscrow(account);
        exchange.syncWithVotingEscrow(account);

        distributor2.syncWithVotingEscrow(account);
        exchange2.syncWithVotingEscrow(account);
    }
}