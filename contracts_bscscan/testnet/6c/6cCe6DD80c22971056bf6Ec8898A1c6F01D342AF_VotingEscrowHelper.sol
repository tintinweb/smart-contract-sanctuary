// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import {IVotingEscrowCallback} from "./VotingEscrowV2.sol";

contract VotingEscrowHelper is IVotingEscrowCallback {
    IVotingEscrowCallback public immutable distributor;
    IVotingEscrowCallback public immutable ballot;
    IVotingEscrowCallback public immutable exchange;

    constructor(
        address distributor_,
        address ballot_,
        address exchange_
    ) public {
        distributor = IVotingEscrowCallback(distributor_);
        ballot = IVotingEscrowCallback(ballot_);
        exchange = IVotingEscrowCallback(exchange_);
    }

    function syncWithVotingEscrow(address account) external override {
        distributor.syncWithVotingEscrow(account);
        ballot.syncWithVotingEscrow(account);
        exchange.syncWithVotingEscrow(account);
    }
}