pragma solidity ^0.8.0;

// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0

library VaultsStorageLibrary {
    enum VaultState {
        WaitingParticipants,
        Created,
        Yielding,
        Rewarding,
        Finished,
        Cancelled
    }

    struct Vault {
        // State of the vault, depending on that different methods can allow or not some actions
        VaultState state;
        // Who created the vault
        address creator;
        // When was created
        uint256 blockNumberCreated;
        // Who was the last one updating the vault
        address lastUpdatedBy;
        // When was updated
        uint256 blockNumberUpdated;
        // Minimum number of participants in the vault
        uint256 minimumParticipants;
        // Number of participants in the vault
        uint256 participantsNumber;
        // During how much time the vault will be active
        uint256 duration;
        // Balance of the vault
        uint256 balance;
        // Total amount of rewarded prizes
        uint256 prizesAmount;
        // How much time a participant needs to wait before making a withdraw
        uint256 lockDuration;
        // Indicates whether a vault is recurrent or not
        bool isRecurrent;
        // // Indicates whether a vault is public or private
        bool isPublic;
    }

    struct VaultsList {
        mapping(uint256 => Vault) vaults;
        mapping(uint256 => address[]) participants;
    }

    struct Reward {
        // Who won the vault
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
        VaultsList storage _self,
        uint256 _vaultId,
        address _creator,
        uint256 _minimumParticipants,
        uint256 _lockDuration,
        bool _isReccurrent,
        bool _isPublic
    ) external returns (uint256) {
        _self.vaults[_vaultId] = Vault({
            state: VaultState.WaitingParticipants,
            creator: _creator,
            blockNumberCreated: block.number,
            lastUpdatedBy: _creator,
            blockNumberUpdated: block.number,
            minimumParticipants: _minimumParticipants,
            participantsNumber: 0,
            duration: 0,
            balance: 0,
            prizesAmount: 0,
            lockDuration: _lockDuration,
            isRecurrent: _isReccurrent,
            isPublic: _isPublic
        });

        return _vaultId;
    }

    function addParticipant(
        VaultsList storage _self,
        uint256 _vaultId,
        address _participant
    ) external {
        _self.vaults[_vaultId].participantsNumber += 1;
        _self.participants[_vaultId].push(_participant);
    }

    function removeParticipant(
        VaultsList storage _self,
        uint256 _vaultId,
        address _participant
    ) external {
        _self.vaults[_vaultId].participantsNumber -= 1;

        for (uint256 i = 0; i < _self.participants[_vaultId].length; i++) {
            if (_self.participants[_vaultId][i] == _participant) {
                _self.participants[_vaultId][i] = _self.participants[_vaultId][
                    _self.participants[_vaultId].length - 1
                ];
                _self.participants[_vaultId].pop();
                break;
            }
        }
    }

    function createReward(
        RewardsList storage _self,
        uint256 _vaultId,
        address _winner,
        uint256 _yield
    ) external returns (uint256) {
        _self.rewards[_vaultId].push(
            Reward({
                winner: _winner,
                yield: _yield,
                blockNumberUpdated: block.number
            })
        );
        return _vaultId;
    }

    function setVaultDuration(
        VaultsList storage _self,
        uint256 _vaultId,
        uint256 _duration
    ) external {
        _self.vaults[_vaultId].duration = _duration;
    }

    function isVaultPublic(VaultsList storage _self, uint256 _vaultId)
        external
        view
        returns (bool isPublic)
    {
        Vault storage vault = _self.vaults[_vaultId];
        isPublic = vault.isPublic;
    }

    function isVaultRecurrent(VaultsList storage _self, uint256 _vaultId)
        external
        view
        returns (bool isRecurrent)
    {
        Vault storage vault = _self.vaults[_vaultId];
        isRecurrent = vault.isRecurrent;
    }

    function get(VaultsList storage _self, uint256 _vaultId)
        external
        view
        returns (Vault memory)
    {
        return _self.vaults[_vaultId];
    }

    function getParticipants(VaultsList storage _self, uint256 _vaultId)
        external
        view
        returns (address[] memory participants)
    {
        return _self.participants[_vaultId];
    }

    function getReward(
        RewardsList storage _self,
        uint256 _vaultId,
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
        Reward storage reward = _self.rewards[_vaultId][_rewardId];
        winner = reward.winner;
        yield = reward.yield;
        blockNumberUpdated = reward.blockNumberUpdated;
    }

    function getRewards(RewardsList storage _self, uint256 _vaultId)
        external
        view
        returns (Reward[] memory rewards)
    {
        rewards = _self.rewards[_vaultId];
    }

    function updateState(
        VaultsList storage _self,
        uint256 _vaultId,
        VaultState newState
    ) internal {
        require(_self.vaults[_vaultId].state != newState);
        _self.vaults[_vaultId].state = newState;
        _self.vaults[_vaultId].lastUpdatedBy = msg.sender;
        _self.vaults[_vaultId].blockNumberUpdated = block.number;
    }

    function updateCreatedBlock(VaultsList storage _self, uint256 _vaultId)
        internal
    {
        _self.vaults[_vaultId].blockNumberCreated = block.number;
        _self.vaults[_vaultId].blockNumberUpdated = block.number;
        _self.vaults[_vaultId].lastUpdatedBy = msg.sender;
    }

    function updateLockDuration(
        VaultsList storage _self,
        uint256 _vaultId,
        uint256 _lockDuration
    ) internal {
        _self.vaults[_vaultId].lockDuration = _lockDuration;
    }

    function increaseBalance(
        VaultsList storage _self,
        uint256 _vaultId,
        uint256 _amount
    ) internal {
        _self.vaults[_vaultId].balance += _amount;
    }

    function decreaseBalance(
        VaultsList storage _self,
        uint256 _vaultId,
        uint256 _amount
    ) internal {
        _self.vaults[_vaultId].balance -= _amount;
    }

    function increasePrizes(
        VaultsList storage _self,
        uint256 _vaultId,
        uint256 _amount
    ) internal {
        _self.vaults[_vaultId].prizesAmount += _amount;
    }

    function decreasePrizes(
        VaultsList storage _self,
        uint256 _vaultId,
        uint256 _amount
    ) internal {
        _self.vaults[_vaultId].prizesAmount -= _amount;
    }
}