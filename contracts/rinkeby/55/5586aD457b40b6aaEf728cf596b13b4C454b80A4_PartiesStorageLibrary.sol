pragma solidity ^0.8.0;

// Copyright 2021 Keyko GmbH.
// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0

library PartiesStorageLibrary {
    enum PartyState {
        WaitingParticipants,
        Created,
        Yielding,
        Rewarding,
        Finished,
        Cancelled
    }

    struct Party {
        // State of the party, depending on that different methods can allow or not some actions
        PartyState state;
        // Who created the party
        address creator;
        // When was created
        uint256 blockNumberCreated;
        // Who was the last one updating the party
        address lastUpdatedBy;
        // When was updated
        uint256 blockNumberUpdated;
        // Minimum number of participants in the party
        uint256 minimumParticipants;
        // Number of participants in the party
        uint256 participantsNumber;
        // During how much time the party will be active
        uint256 duration;
        // Balance of the party
        uint256 balance;
        // Total amount of rewarded prizes
        uint256 prizes_amount;
    }

    struct PartiesList {
        mapping(uint256 => Party) parties;
        mapping(uint256 => address[]) participants;
    }

    struct Reward {
        // Who won the party
        address winner;
        // Total amount of yield generated (including the original amount staked)
        uint256 yield;
        // When was updated
        uint256 blockNumberUpdated;
    }

    struct RewardsList {
        mapping(uint256 => Reward[]) rewards;
    }

    function create(
        PartiesList storage _self,
        uint256 _partyId,
        address _creator,
        uint256 _minimumParticipants,
        uint256 _duration
    ) external returns (uint256) {
        _self.parties[_partyId] = Party({
            state: PartyState.WaitingParticipants,
            creator: _creator,
            blockNumberCreated: block.number,
            lastUpdatedBy: _creator,
            blockNumberUpdated: block.number,
            minimumParticipants: _minimumParticipants,
            participantsNumber: 0,
            duration: _duration,
            balance: 0,
            prizes_amount: 0
        });

        return _partyId;
    }

    function addParticipant(
        PartiesList storage _self,
        uint256 _partyId,
        address _participant
    ) external {
        _self.parties[_partyId].participantsNumber += 1;
        _self.participants[_partyId].push(_participant);
    }

    function createReward(
        RewardsList storage _self,
        uint256 _partyId,
        address _winner,
        uint256 _yield
    ) external returns (uint256) {
        _self.rewards[_partyId].push(
            Reward({
                winner: _winner,
                yield: _yield,
                blockNumberUpdated: block.number
            })
        );
        return _partyId;
    }

    function get(PartiesList storage _self, uint256 _partyId)
        external
        view
        returns (
            PartyState state,
            address creator,
            uint256 blockNumberCreated,
            address lastUpdatedBy,
            uint256 blockNumberUpdated,
            uint256 minimumParticipants,
            uint256 participantsNumber,
            uint256 duration,
            uint256 balance,
            uint256 prizes_amount
        )
    {
        Party storage party = _self.parties[_partyId];
        state = party.state;
        creator = party.creator;
        blockNumberCreated = party.blockNumberCreated;
        lastUpdatedBy = party.lastUpdatedBy;
        blockNumberUpdated = party.blockNumberUpdated;
        minimumParticipants = party.minimumParticipants;
        participantsNumber = party.participantsNumber;
        duration = party.duration;
        balance = party.balance;
        prizes_amount = party.prizes_amount;
    }

    function getParticipants(PartiesList storage _self, uint256 _partyId)
        external
        view
        returns (address[] memory participants)
    {
        return _self.participants[_partyId];
    }

    function getReward(
        RewardsList storage _self,
        uint256 _partyId,
        uint256 _rewardId
    )
        external
        view
        returns (
            address winner,
            uint256 yield,
            uint256 blockNumberUpdated
        )
    {
        Reward storage reward = _self.rewards[_partyId][_rewardId];
        winner = reward.winner;
        yield = reward.yield;
        blockNumberUpdated = reward.blockNumberUpdated;
    }

    function getRewards(RewardsList storage _self, uint256 _partyId)
        external
        view
        returns (Reward[] memory rewards)
    {
        rewards = _self.rewards[_partyId];
    }

    function updateState(
        PartiesList storage _self,
        uint256 _partyId,
        PartyState newState
    ) internal {
        require(_self.parties[_partyId].state != newState);
        _self.parties[_partyId].state = newState;
        _self.parties[_partyId].lastUpdatedBy = msg.sender;
        _self.parties[_partyId].blockNumberUpdated = block.number;
    }

    function updateCreatedBlock(PartiesList storage _self, uint256 _partyId)
        internal
    {
        _self.parties[_partyId].blockNumberCreated = block.number;
        _self.parties[_partyId].blockNumberUpdated = block.number;
        _self.parties[_partyId].lastUpdatedBy = msg.sender;
    }

    function increaseBalance(
        PartiesList storage _self,
        uint256 _partyId,
        uint256 _amount
    ) internal {
        _self.parties[_partyId].balance += _amount;
    }

    function decreaseBalance(
        PartiesList storage _self,
        uint256 _partyId,
        uint256 _amount
    ) internal {
        _self.parties[_partyId].balance -= _amount;
    }

    function increasePrizes(
        PartiesList storage _self,
        uint256 _partyId,
        uint256 _amount
    ) internal {
        _self.parties[_partyId].prizes_amount += _amount;
    }

    function decreasePrizes(
        PartiesList storage _self,
        uint256 _partyId,
        uint256 _amount
    ) internal {
        _self.parties[_partyId].prizes_amount -= _amount;
    }
}