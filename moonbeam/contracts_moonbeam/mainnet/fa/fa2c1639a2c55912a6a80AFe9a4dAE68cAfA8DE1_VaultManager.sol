pragma solidity ^0.8.0;

// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0

import "./VaultManagerInterface.sol";
import "../tokens/MultiToken.sol";
import "../tokens/StableTokenInterface.sol";
import "../random/RandomNumberGeneratorInterface.sol";
import "../strategy/PrizeStrategyInterface.sol";
import "./VaultsStorageLibrary.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title Vault Manager
 * @dev Contract in charge of store and manage the different vaults
 *      created by the community
 *
 */
contract VaultManager is
    IVaultManager,
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    // References to storage
    using VaultsStorageLibrary for VaultsStorageLibrary.VaultsList;
    VaultsStorageLibrary.VaultsList internal vaultsList;

    // Address of the ERC20 used to receive funds from users and distribute rewards
    IRandStableToken internal stableToken;

    // Address of the multi-token implementation
    // It stores the "participations" of users in a specific vault
    RandMultiToken internal multiToken;

    // @dev address of Chainlink Defender
    address internal backendAddress;

    //address of Random Number Generator contract
    IRandomNumberGenerator internal rngService;

    //address of Prize Strategy contract
    IPrizeStrategy internal prizeStrategyService;

    bytes32 public constant BACKEND_ADMIN_ROLE =
        keccak256("BACKEND_ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @notice initialize init the contract with the following parameters
     * @dev this function is called only once during the contract initialization
     * @param _multiTokenAddress Rand Multi Token contract address
     * @param _stableERC20Address Rand Internal Token contract address
     */
    function initialize(
        address _multiTokenAddress,
        address _stableERC20Address,
        address _backendAddress
    ) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        multiToken = RandMultiToken(_multiTokenAddress);
        stableToken = IRandStableToken(_stableERC20Address);

        _setupRole(BACKEND_ADMIN_ROLE, _backendAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice It creates a new vault with the configuration given by the creator
     * @param _vaultId Id of the vault computed using hashVaultId function
     * @param _creator Address of the vault owner
     * @param _minimumParticipants number of participants that need to join in the
     * vault for the yielding to start
     * @param _lockDuration how many blocks the users need to wait before withdrawing
     * after the last deposit
     * @param _isRecurrent indicates wheter the Vault will be recurrent or not
     * @param _isPublic indicates wheter the Vault will be public or private
     */
    function createVault(
        uint256 _vaultId,
        address _creator,
        uint256 _minimumParticipants,
        uint256 _lockDuration,
        bool _isRecurrent,
        bool _isPublic
    ) public onlyRole(BACKEND_ADMIN_ROLE) returns (uint256 vaultId) {
        require(_minimumParticipants >= 1, "VM: #Participants above 1");

        vaultsList.create(
            _vaultId,
            _creator,
            _minimumParticipants,
            _lockDuration,
            _isRecurrent,
            _isPublic
        );

        emit VaultCreated(
            _vaultId,
            _creator,
            block.number,
            _minimumParticipants,
            _lockDuration,
            _isRecurrent,
            _isPublic
        );
        return _vaultId;
    }

    /**
     * @notice It returns the attributes of a specific vault
     */
    function getVault(uint256 _vaultId)
        external
        view
        returns (VaultsStorageLibrary.Vault memory vault)
    {
        vault = vaultsList.get(_vaultId);
    }

    /**
     * @notice Used to update the duration for which the participants cannot withdraw
     * after depositing
     */
    function updateLockDuration(uint256 _vaultId, uint256 _lockDuration)
        external
        whenNotPaused
        onlyRole(BACKEND_ADMIN_ROLE)
    {
        vaultsList.updateLockDuration(_vaultId, _lockDuration);
    }

    /**
     * @notice It returns an array containing the address of the participants to the vault
     */
    function getParticipants(uint256 _vaultId)
        external
        view
        returns (address[] memory participants)
    {
        return vaultsList.getParticipants(_vaultId);
    }

    /**
     * @notice It checks if an address is a selected participant for a specific vault
     */
    function isParticipant(uint256 _vaultId, address _participant)
        public
        view
        returns (bool)
    {
        address[] memory participants = vaultsList.getParticipants(_vaultId);
        for (uint256 i = 0; i < participants.length; i++)
            if (participants[i] == _participant) return true;

        return false;
    }

    /**
     * @notice It allows a valid participant to deposit some amount for joining a vault
     * Requirements:
     * - The vault needs to be in `WaitingParticipants` state
     * - The `amount` should be the one defined by the vault creator
     * - Only selected participants can join
     */
    function participantDeposit(
        uint256 _vaultId,
        address _participant,
        uint256 _amount
    ) public whenNotPaused onlyRole(BACKEND_ADMIN_ROLE) {
        VaultsStorageLibrary.Vault memory vault = vaultsList.get(_vaultId);

        require(_isOpen(vault.state), "VM: Not open");
        require(
            stableToken.balanceOf(_participant) >= _amount,
            "VM: Participant without founds"
        );

        // burning the rand stable tokens from the participant balance
        stableToken.burn(_participant, _amount);

        //increasing the balance of the vault
        vaultsList.increaseBalance(_vaultId, _amount);

        //checking if the participant has deposited before
        if (multiToken.balanceOf(_participant, _vaultId) == 0) {
            // if the participant hasn't deposited before, he is a new participant
            vaultsList.addParticipant(_vaultId, _participant);
            emit ParticipantJoinedVault(_vaultId, _participant);

            // checking if the minimum number of participants joined the vault so the
            // yielding can start
            if (vault.participantsNumber.add(1) >= vault.minimumParticipants) {
                if (
                    vault.state ==
                    VaultsStorageLibrary.VaultState.WaitingParticipants
                ) {
                    vaultsList.updateState(
                        _vaultId,
                        VaultsStorageLibrary.VaultState.Created
                    );
                    emit VaultStateChanged(
                        _vaultId,
                        _msgSender(),
                        VaultsStorageLibrary.VaultState.WaitingParticipants,
                        VaultsStorageLibrary.VaultState.Created
                    );
                }
            }
        }

        uint256 _twaAmount;
        if (vault.state == VaultsStorageLibrary.VaultState.Yielding) {
            // applying a fee for the participants which are joining during the yielding period
            // the fee is increasing as the yielding period get closer to finish
            uint256 endBlock = vault.blockNumberUpdated.add(
                vaultsList.get(_vaultId).duration
            );
            uint256 twaAmount = endBlock.sub(block.number);
            twaAmount = twaAmount.mul(_amount).div(
                vaultsList.get(_vaultId).duration
            );
            multiToken.mint(_participant, _vaultId, _amount, twaAmount, "");
            _twaAmount = twaAmount;
        } else {
            multiToken.mint(_participant, _vaultId, _amount, _amount, "");
            _twaAmount = _amount;
        }
        multiToken.updateParticipantLastDepositDate(_vaultId, _participant);

        emit ParticipantDeposit(
            _vaultId,
            _participant,
            _amount,
            _twaAmount,
            vaultsList.getParticipants(_vaultId)
        );
    }

    /**
     * @notice It allows backend to withdraw Rand Multi Tokens from the vault for a user in
     * exchange of Rand Stable Tokens
     * @param _vaultId Id of the vault from which the funds are being withdrawn
     * @param _participant Address of the participant from whose balance the funds are being withdrawn
     * @param _amount Amount of Rand Multi Tokens which are being withdrawn
     * @param _feeCoefficent The percentage of the fee that should be used for penalization
     */

    function participantWithdraw(
        uint256 _vaultId,
        address _participant,
        uint256 _amount,
        uint256 _feeCoefficent
    ) public whenNotPaused onlyRole(BACKEND_ADMIN_ROLE) {
        VaultsStorageLibrary.Vault memory vault = vaultsList.get(_vaultId);
        require(
            vault.state != VaultsStorageLibrary.VaultState.Rewarding &&
                vault.state != VaultsStorageLibrary.VaultState.Finished,
            "VM: Cannot withdraw now"
        );

        uint256 feeAmount;
        if (vault.state == VaultsStorageLibrary.VaultState.Yielding) {
            // getting the remaining period until the yielding will stop
            feeAmount = vault.blockNumberUpdated.add(vault.duration).sub(
                block.number
            );
            // calculating the percent of the remaining period relative to the yielding duration
            feeAmount = feeAmount.mul(100).div(vault.duration);
            // multiplaying the resulted percentage with the fee coefficient
            feeAmount = feeAmount.mul(_feeCoefficent).div(10000);
            // using the resulted fee percentage to calculate the fee amount
            feeAmount = feeAmount.mul(_amount).div(100);
        } else {
            // if the vault is not yielding, using just the coefficent
            feeAmount = _feeCoefficent.mul(_amount).div(10000);
        }

        if (vault.state == VaultsStorageLibrary.VaultState.Yielding) {
            require(
                vault.blockNumberUpdated.add(vault.lockDuration) <=
                    block.number,
                "VM: In lock period"
            );
        }

        _handleParticipantWithdraw(_vaultId, _participant, _amount, feeAmount);
    }

    /**
     * @notice It allows to close a particular vault  before Yielding
     * and withdraw all funds with no fee
     * @param _vaultId Id of the vault that's going to be cancelled
     */
    function closeVaultBeforeYielding(uint256 _vaultId)
        external
        whenNotPaused
        onlyRole(BACKEND_ADMIN_ROLE)
    {
        require(
            vaultsList.get(_vaultId).state ==
                VaultsStorageLibrary.VaultState.WaitingParticipants ||
                vaultsList.get(_vaultId).state ==
                VaultsStorageLibrary.VaultState.Created,
            "VM: Cannot withdraw after Yielding"
        );

        address[] memory participants = vaultsList.getParticipants(_vaultId);
        require(participants.length > 0, "VM: Above 1 participant");

        for (uint256 i = 0; i < participants.length; i++) {
            uint256 _amount = multiToken.balanceOf(participants[i], _vaultId);
            _handleParticipantWithdraw(_vaultId, participants[i], _amount, 0);
        }

        vaultsList.updateState(
            _vaultId,
            VaultsStorageLibrary.VaultState.Cancelled
        );
        emit VaultStateChanged(
            _vaultId,
            _msgSender(),
            vaultsList.get(_vaultId).state,
            VaultsStorageLibrary.VaultState.Cancelled
        );

        emit CloseVaultBeforeYielding(_vaultId, participants);
    }

    /**
     * @notice Used by the backend to mark the beginning of the yielding period by changing the
     * vault state to yielding
     * @param _vaultId Id of the vault for which the yielding period will begin
     * @param _duration how many blocks the yielding period will take place
     * @param _forceStart if true, a minimum of participants is not required
     */
    function startYielding(
        uint256 _vaultId,
        uint256 _duration,
        bool _forceStart
    ) public whenNotPaused onlyRole(BACKEND_ADMIN_ROLE) {
        require(_duration != 0, "VM: Duration greater than 0");

        vaultsList.setVaultDuration(_vaultId, _duration);

        require(
            vaultsList.get(_vaultId).state ==
                VaultsStorageLibrary.VaultState.Created ||
                _forceStart,
            "VM: Vault not ready"
        );
        vaultsList.updateState(
            _vaultId,
            VaultsStorageLibrary.VaultState.Yielding
        );
        emit VaultStateChanged(
            _vaultId,
            _msgSender(),
            vaultsList.get(_vaultId).state,
            VaultsStorageLibrary.VaultState.Yielding
        );

        emit StartYielding(
            _vaultId,
            _duration,
            _forceStart,
            vaultsList.getParticipants(_vaultId)
        );
    }

    /**
     * @notice If the vault was yielding and the duration is over, it allows to stop the yielding phase
     * and start the rewarding phase
     * Everybody can call this method!
     * @param _vaultId id of the vault for which the winners are calculated
     * @param _tiers array where each index represents the tier and the value
     * from the respective index is the number of prizes for that tier
     * @param _percentages array where each index represents the tier and the value
     * from the respective index is the percentage of the total prize that the user gets
     * if he won that tier
     * @param _prize the amount that represents the amount from which the percentages
     * are calculated
     * @param _rewardCoefficient the percentage of the balance the balance that is not being withdrawn
     * by user from the last prize distribution and is reflected as a reward in the current one
     * @param _externalRandomNumber random number that acts as replacement of RNG from ChainLink
     * @param _timeWeightNonRadom indicates the distribution model for Prize - based on twa weight non random
     * @param _allToCreatorNonRandom indicates the distribution model for Prize - all prize to one non random
     * @param _tierAndRandomBased indicates the distribution model for Prize - several winners and tiers - random based
     */
    function stopYielding(
        uint256 _vaultId,
        uint256[] memory _tiers,
        uint256[] memory _percentages,
        uint256 _prize,
        uint256 _rewardCoefficient,
        uint256 _externalRandomNumber,
        bool _timeWeightNonRadom,
        bool _allToCreatorNonRandom,
        bool _tierAndRandomBased
    ) public whenNotPaused onlyRole(BACKEND_ADMIN_ROLE) {
        VaultsStorageLibrary.Vault memory vaultstate = vaultsList.get(_vaultId);

        if (_timeWeightNonRadom && _allToCreatorNonRandom) {
            revert(
                "VM: Choose between Time Weight or All To Creator distribution"
            );
        }

        if (
            (vaultstate.isRecurrent && _timeWeightNonRadom) ||
            (vaultstate.isRecurrent && _allToCreatorNonRandom)
        ) {
            revert("VM: When recurrent, tiers distribution allowed");
        }

        require(
            vaultstate.state == VaultsStorageLibrary.VaultState.Yielding,
            "VM: Not yielding"
        );

        require(
            block.number >= vaultstate.blockNumberUpdated + vaultstate.duration,
            "VM: Can't stop before duration"
        );

        vaultsList.updateState(
            _vaultId,
            VaultsStorageLibrary.VaultState.Rewarding
        );

        emit VaultStateChanged(
            _vaultId,
            _msgSender(),
            VaultsStorageLibrary.VaultState.Yielding,
            VaultsStorageLibrary.VaultState.Rewarding
        );

        // 1 Based on twa non-random. Non-recurrent only
        if (_timeWeightNonRadom) {
            require(
                !vaultstate.isRecurrent,
                "VM: Time weight based must be non-recurrent"
            );
            _distBasedOnTwaNonRandom(_vaultId, _prize);
            return;
        }

        // 2 All Yield is sent to the creator of the Vault. Non-recurren only
        if (_allToCreatorNonRandom) {
            require(
                !vaultstate.isRecurrent,
                "VM: All To Creator must be non-recurrent"
            );
            _distSendAllToCreatorNonRandom(_vaultId, _prize);
            return;
        }

        require(
            _tierAndRandomBased &&
                !_timeWeightNonRadom &&
                !_allToCreatorNonRandom,
            "VM: Tier distribution needs to be true"
        );

        // verify that Prizes >= Participants in vault
        require(
            _verifyPrizesLessThanParticipants(_vaultId, _tiers),
            "VM: Prizes not greater than participants"
        );

        // 3 y 4 Based on tiers. Single or Multiple Winners. Recurrent/Non-Recurrent
        prizeStrategyService.setPrizeParameters(
            _vaultId,
            _tiers,
            _percentages,
            _prize,
            _rewardCoefficient
        );

        if (_externalRandomNumber == 0) {
            rngService.requestRandomNumber(_vaultId);
        } else {
            rewardDistribution(_vaultId, _externalRandomNumber);
        }
    }

    /**
     * @notice Called inside the stopYielding function, this function is using Prize Strategy contract to compute
     * the prizes for the winners and distribute them based on the type prize distribution and change
     * the vault state to finished (if the vault is non-recurrent) or prepare the vault for the next yielding period
     * (if the vault is recurrent)
     * Function meant to be called by Chainlink
     * @param _vaultId The id of the vault for which the rewards are being computed
     * @param _randomNumber The random number (obtained by the RNG contract) based on which the winners are computed
     */
    function distributeRewards(uint256 _vaultId, uint256 _randomNumber)
        external
        override
    {
        require(address(rngService) == _msgSender(), "VM: RNG only");
        rewardDistribution(_vaultId, _randomNumber);
    }

    /**
     * @notice Passed the vault id and the random number being calculated
     * Function created to by pass the random generated number by chainlink
     * Whenever the random number is passed by the backend, this function could be called internally
     * @param _vaultId The id of the vault for which the rewards are being
     * @param _randomNumber The random number (obtained by the RNG contract) based on which the winners are computed
     */
    function rewardDistribution(uint256 _vaultId, uint256 _randomNumber)
        internal
    {
        VaultsStorageLibrary.Vault memory vault = vaultsList.get(_vaultId);

        require(
            vault.state == VaultsStorageLibrary.VaultState.Rewarding,
            "VM: Not in rewarding"
        );

        address[] memory participants = vaultsList.getParticipants(_vaultId);
        uint256 rewardCoefficient = prizeStrategyService.getRewardCoefficient(
            _vaultId
        );
        uint256 accumulatedTwaAndReward = 0;
        uint256[] memory accumlatedTwaArr = new uint256[](participants.length);

        for (uint256 i = 0; i < accumlatedTwaArr.length; i++) {
            (uint256 amount, uint256 twaAmount) = multiToken.balancesOf(
                participants[i],
                _vaultId
            );
            uint256 reward = multiToken.rewardOf(participants[i], _vaultId);
            accumulatedTwaAndReward += twaAmount.add(reward);
            accumlatedTwaArr[i] = accumulatedTwaAndReward;

            if (
                rewardCoefficient != 0 &&
                vault.isRecurrent &&
                (twaAmount == amount)
            ) {
                prizeStrategyService.computeUserReward(
                    _vaultId,
                    participants[i]
                );
            }
        }

        _handleRewards(
            _vaultId,
            accumulatedTwaAndReward,
            accumlatedTwaArr,
            _randomNumber
        );
    }

    /**
     * @notice Used to transfer Rand Stable Tokens from the Vault to an account and burn
     * the same amount of Rand Multi Tokens from the account balance
     * @param _vaultId Id of the vault
     * @param _participant Address of the account for which the transfer and burn are being made
     */
    function _transferAndBurn(uint256 _vaultId, address _participant) internal {
        (uint256 amount, uint256 twaAmount) = multiToken.balancesOf(
            _participant,
            _vaultId
        );
        stableToken.mint(_participant, amount);
        multiToken.burn(_participant, _vaultId, amount, twaAmount);
        vaultsList.decreaseBalance(_vaultId, amount);
    }

    /**
     * @notice It generates a hash that can be used as unique vaultId
     * @param _owner Address of the owner of the vault
     * @param _minimumParticipants The minimum number of participants required to start yielding
     * @param _duration Duration of the yielding period in blocks
     */
    function hashVaultId(
        address _owner,
        uint256 _minimumParticipants,
        uint256 _duration
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _owner,
                    _minimumParticipants,
                    _duration,
                    block.number
                )
            );
    }

    /**
     * @notice Used to handle the distribution of the rewards and prepares the vault for the next stage
     * @param _vaultId Id of the vault for which the distribution is taking place
     * @param _accumulatedTwaAndReward The sum of the twa balances of the users in the vault
     * @param _randomNumber The random number obtained via RNG used to compute the winners
     */

    function _handleRewards(
        uint256 _vaultId,
        uint256 _accumulatedTwaAndReward,
        uint256[] memory accumulatedTwaArr,
        uint256 _randomNumber
    ) internal {
        address[] memory _participants = vaultsList.getParticipants(_vaultId);

        (
            uint256[] memory _prizes,
            address[] memory _winners
        ) = prizeStrategyService.getPrizesAndWinners(
                accumulatedTwaArr,
                _vaultId,
                _participants,
                _randomNumber,
                _accumulatedTwaAndReward
            );

        _distributeRewards(_vaultId, _prizes, _winners);

        if (vaultsList.get(_vaultId).isRecurrent) {
            // if the vault is recurrent, the twa balance of the users will be increased to be equal to the normal balance
            for (uint256 i = 0; i < _participants.length; i++) {
                (uint256 amount, uint256 twaAmount) = multiToken.balancesOf(
                    _participants[i],
                    _vaultId
                );
                if (amount > twaAmount) {
                    multiToken.mint(
                        _participants[i],
                        _vaultId,
                        0,
                        amount.sub(twaAmount),
                        ""
                    );
                }
            }
            // the created block of the vault will be changed to the current block number
            vaultsList.updateCreatedBlock(_vaultId);
            // the vault state will be set to yielding
            vaultsList.updateState(
                _vaultId,
                VaultsStorageLibrary.VaultState.Yielding
            );
            emit VaultStateChanged(
                _vaultId,
                _msgSender(),
                VaultsStorageLibrary.VaultState.Rewarding,
                VaultsStorageLibrary.VaultState.Yielding
            );
        } else {
            // if the vault is not recurrent, all the Rand Multi Tokens of the users are exchanged into Rand Stable Tokens
            // and transfered to them and the vault state will become 'finished'
            for (uint256 i = 0; i < _participants.length; i++) {
                _transferAndBurn(_vaultId, _participants[i]);
            }

            vaultsList.updateState(
                _vaultId,
                VaultsStorageLibrary.VaultState.Finished
            );

            emit VaultStateChanged(
                _vaultId,
                _msgSender(),
                VaultsStorageLibrary.VaultState.Rewarding,
                VaultsStorageLibrary.VaultState.Finished
            );
        }
    }

    /**
     * @notice Used to get the winners and prizes from the Prize Strategy and mint the tokens for the winners
     * @param _vaultId Id of the vault for which the rewards are being distributed
     * @param _prizes Prizes in an array
     * @param _winners Winners in an array after doing binary search
     */
    function _distributeRewards(
        uint256 _vaultId,
        uint256[] memory _prizes,
        address[] memory _winners
    ) internal {
        for (uint256 i = 0; i < _prizes.length; i++) {
            uint256 twaAmount = multiToken.calculateTwaAmount(
                _vaultId,
                _winners[i],
                _prizes[i]
            );
            multiToken.mint(_winners[i], _vaultId, _prizes[i], twaAmount, "");
            multiToken.increasePrize(_winners[i], _vaultId, _prizes[i]);
            vaultsList.increasePrizes(_vaultId, _prizes[i]);
            vaultsList.increaseBalance(_vaultId, _prizes[i]);
        }

        emit RewardsDistributed(
            _vaultId,
            vaultsList.get(_vaultId).prizesAmount,
            _winners,
            _prizes
        );
    }

    function _distBasedOnTwaNonRandom(uint256 _vaultId, uint256 _prize)
        internal
    {
        address[] memory _participants = vaultsList.getParticipants(_vaultId);
        uint256[] memory _prizes = new uint256[](_participants.length);

        uint256 vaultTwaBalance = 0;
        for (uint256 i = 0; i < _participants.length; i++) {
            vaultTwaBalance = vaultTwaBalance.add(
                multiToken.twaBalanceOf(_participants[i], _vaultId)
            );
        }

        for (uint256 i = 0; i < _participants.length; i++) {
            uint256 twaParticipant = multiToken.twaBalanceOf(
                _participants[i],
                _vaultId
            );

            uint256 participantPrize = twaParticipant.mul(_prize).div(
                vaultTwaBalance
            );

            uint256 _twaAmount = multiToken.calculateTwaAmount(
                _vaultId,
                _participants[i],
                participantPrize
            );

            multiToken.mint(
                _participants[i],
                _vaultId,
                participantPrize,
                _twaAmount,
                ""
            );

            multiToken.increasePrize(
                _participants[i],
                _vaultId,
                participantPrize
            );
            _prizes[i] = multiToken.prizeOf(_participants[i], _vaultId);
            vaultsList.increasePrizes(_vaultId, participantPrize);
            vaultsList.increaseBalance(_vaultId, participantPrize);

            // Transfer and burn
            _transferAndBurn(_vaultId, _participants[i]);
        }

        vaultsList.updateState(
            _vaultId,
            VaultsStorageLibrary.VaultState.Finished
        );

        emit VaultStateChanged(
            _vaultId,
            _msgSender(),
            VaultsStorageLibrary.VaultState.Rewarding,
            VaultsStorageLibrary.VaultState.Finished
        );

        emit RewardsDistributed(_vaultId, _prize, _participants, _prizes);
    }

    function _distSendAllToCreatorNonRandom(uint256 _vaultId, uint256 _prize)
        internal
    {
        address creator = vaultsList.get(_vaultId).creator;
        uint256 twaAmount = multiToken.calculateTwaAmount(
            _vaultId,
            creator,
            _prize
        );
        multiToken.mint(creator, _vaultId, _prize, twaAmount, "");
        multiToken.increasePrize(creator, _vaultId, _prize);
        vaultsList.increasePrizes(_vaultId, _prize);
        vaultsList.increaseBalance(_vaultId, _prize);

        address[] memory _participants = vaultsList.getParticipants(_vaultId);
        for (uint256 i = 0; i < _participants.length; i++) {
            _transferAndBurn(_vaultId, _participants[i]);
        }

        vaultsList.updateState(
            _vaultId,
            VaultsStorageLibrary.VaultState.Finished
        );

        emit VaultStateChanged(
            _vaultId,
            _msgSender(),
            VaultsStorageLibrary.VaultState.Rewarding,
            VaultsStorageLibrary.VaultState.Finished
        );

        emit RewardsSinglyDistributed(
            _vaultId,
            multiToken.prizeOf(creator, _vaultId),
            creator,
            _participants,
            vaultsList.get(_vaultId).balance
        );
    }

    /**
     * @notice Handles the funds when the participant is withdrawing
     * @param _vaultId Id of the vault from which the user is withdrawing
     * @param _participant Address of the user which is withdrawing
     * @param _amount Amount of Rand Multi Tokens that the user wants to withdraw
     * @param _feeAmount Percentage of the fee the is going to be applied on the withdrawed amount
     */
    function _handleParticipantWithdraw(
        uint256 _vaultId,
        address _participant,
        uint256 _amount,
        uint256 _feeAmount
    ) internal {
        uint256 twaAmountToBeBurned = multiToken.calculateTwaAmount(
            _vaultId,
            _participant,
            _amount
        );

        (uint256 amount, uint256 twaAmount) = multiToken.balancesOf(
            _participant,
            _vaultId
        );
        require(
            _amount <= amount && twaAmountToBeBurned <= twaAmount,
            "VM: insufficient funds"
        );

        // burning _amount + fee multi tokens from the participant balance
        multiToken.burn(_participant, _vaultId, _amount, twaAmountToBeBurned);

        // transfering the participant _amount - fee rand stable tokens
        stableToken.mint(_participant, _amount.sub(_feeAmount));

        // decreasing the vault balance
        vaultsList.decreaseBalance(_vaultId, _amount.sub(_feeAmount));

        multiToken.updateParticipantLastWithdrawDate(_vaultId, _participant);

        // if the user doesn't have any token in the balance, it means
        // he left the vault
        bool leftVault;
        if (amount.sub(_amount) == 0) {
            vaultsList.removeParticipant(_vaultId, _participant);
            leftVault = true;
            emit ParticipantLeftVault(_vaultId, _participant);
        }
        multiToken.setReward(_participant, _vaultId, 0);
        emit ParticipantWithdraw(
            _vaultId,
            _participant,
            _amount,
            twaAmountToBeBurned,
            _feeAmount,
            leftVault
        );
    }

    /**
     * @dev Uses RandStableTokenInterface to burn the Rand internal tokens obtained when users
     * are joining to a vault
     * @param _amount amount of Rand internal tokens that will be burned
     */
    function _burn(uint256 _amount) internal {
        stableToken.burn(address(this), _amount);
    }

    /**
     * @dev Checks if a vault is open for the users to join
     * @param _state state of the vault
     */
    function _isOpen(VaultsStorageLibrary.VaultState _state)
        internal
        pure
        returns (bool)
    {
        if (_state == VaultsStorageLibrary.VaultState.Rewarding) return false;
        if (_state == VaultsStorageLibrary.VaultState.Finished) return false;
        if (_state == VaultsStorageLibrary.VaultState.Cancelled) return false;
        return true;
    }

    function _verifyPrizesLessThanParticipants(
        uint256 _vaultId,
        uint256[] memory _tiers
    ) internal view returns (bool) {
        uint256 numberPrizes = 0;
        for (uint256 ix = 0; ix < _tiers.length; ix++) {
            numberPrizes += _tiers[ix];
        }
        return vaultsList.get(_vaultId).participantsNumber >= numberPrizes;
    }

    ////////////////////////////////////////////////////////
    ////////// ACCESS CONTROL HELPER FUNCTIONS  ////////////
    ////////////////////////////////////////////////////////
    function setNewAddressByIndex(uint256 _ix, address _newAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newAddress != address(0), "VM: 0 address");
        // 0 -> prize strategy address
        // 1 -> multitoken address
        // 2 -> internal stable token
        // 3 -> rng address
        // 4 -> backend address
        if (_ix == 0) {
            // _newAddress new address of the Prize Strategy contract
            prizeStrategyService = IPrizeStrategy(_newAddress);
        } else if (_ix == 1) {
            //  _newAddress new address of multitoke
            multiToken = RandMultiToken(_newAddress);
        } else if (_ix == 2) {
            //  _newAddress new address of internal stable token address
            stableToken = IRandStableToken(_newAddress);
        } else if (_ix == 3) {
            // _newAddress new address of the Random Number Generator contract
            rngService = IRandomNumberGenerator(_newAddress);
        } else if (_ix == 4) {
            // _newAddress new address of the Chainlink Defender
            backendAddress = _newAddress;
            grantRole(BACKEND_ADMIN_ROLE, backendAddress);
        }
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0

import "./VaultsStorageLibrary.sol";

/**
 * @dev Interfacefor the contract in charge of store and manage the different vaults
 *      created by the community
 *
 */
interface IVaultManager {
    // Emitted when a new vault is created
    event VaultCreated(
        uint256 indexed _vaultId,
        address indexed _creator,
        uint256 _when,
        uint256 _minimumParticipants,
        uint256 _lockDuration,
        bool isReccurrent,
        bool isPublic
    );

    // Emitted when a new public vault is created
    event PublicVaultCreated(
        uint256 indexed _vaultId,
        uint256 _when,
        uint256 _duration
    );

    // Emitted when a vault participant joins the vault depositing funds
    event ParticipantJoinedVault(
        uint256 indexed _vaultId,
        address indexed _participant
    );

    // Emitted when a vault participant leaves the vault by withdrawing all the funds
    event ParticipantLeftVault(
        uint256 indexed _vaultId,
        address indexed _participant
    );

    // Emitted when a vault participants withdraw an amount from the vault
    event ParticipantWithdraw(
        uint256 indexed _vaultId,
        address indexed _participant,
        uint256 indexed _amount,
        uint256 _twaAmountToBeBurned,
        uint256 _feeAmount,
        bool _leftVault
    );

    // Emitted when the state of the vault changed
    event VaultStateChanged(
        uint256 indexed _vaultId,
        address indexed _who,
        VaultsStorageLibrary.VaultState _previousState,
        VaultsStorageLibrary.VaultState _newState
    );

    // Emitted when the rewards of a specific vault are distributed correctly
    event RewardsDistributed(
        uint256 indexed _vaultId,
        uint256 _yield,
        address[] _winners,
        uint256[] _prizes
    );

    event RewardsSinglyDistributed(
        uint256 indexed _vaultId,
        uint256 _yield,
        address indexed _winner,
        address[] participants,
        uint256 _vaultBalance
    );

    event ParticipantDeposit(
        uint256 indexed _vaultId,
        address indexed _participant,
        uint256 _amount,
        uint256 _twaAmount,
        address[] participants
    );

    event StartYielding(
        uint256 indexed _vaultId,
        uint256 _duration,
        bool _forceStart,
        address[] participants
    );

    event CloseVaultBeforeYielding(
        uint256 indexed _vaultId,
        address[] participants
    );

    /**
     * @notice used to distribute the rewards for a specific vault after the yielding
     *         has finished
     * @param _vaultId the id of the vault for which the rewards are being distributed
     * @param _randomNumber the random number obtained from RNG Service used for computing
     * the winners of the vault
     */
    function distributeRewards(uint256 _vaultId, uint256 _randomNumber)
        external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Rand Multi Token implementation
 * @dev ERC1155 contract where each token represents a vault and the balances of the token represent
 *  the balances of the user for the vault
 * @dev Each token has a normal balance and a time weighted one, the time weighted balance represents the
 * contribution of the user to the vault
 * @dev The fees for late deposits or early withdraws are reflected in the time weighted balance
 */
contract RandMultiToken is
    Initializable,
    ERC165Upgradeable,
    IERC1155Upgradeable,
    IERC1155MetadataURIUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    bytes32 public constant MINTER_AND_BURNER_ROLE =
        keccak256("MINTER_AND_BURNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    // Mapping from token ID to account to balance of the account
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from token ID to account to twa balance of the account
    mapping(uint256 => mapping(address => uint256)) private _twaBalances;

    // Mapping from token ID to account to rewards of the account
    mapping(uint256 => mapping(address => uint256)) private _rewards;

    // Mapping from token ID to account to prizes of the account
    mapping(uint256 => mapping(address => uint256)) private _prizes;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from token ID to account to the date of the last withdraw
    mapping(uint256 => mapping(address => uint256)) private _lastWithdrawDate;

    // Mapping from the token ID to account to the date of the last deposit
    mapping(uint256 => mapping(address => uint256)) private _lastDepositDate;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @notice initialize init the contract with the following parameters
     * @dev this function is called only once during the contract initialization
     */
    function initialize() external initializer {
        __ERC1155_init("https://rand.network/api/vault/{id}.json");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    function setURI(string memory newuri)
        public
        whenNotPaused
        onlyRole(URI_SETTER_ROLE)
    {
        _setURI(newuri);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165Upgradeable,
            IERC165Upgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(AccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        uint256 twaAmount,
        bytes memory data
    ) public whenNotPaused {
        require(
            hasRole(MINTER_AND_BURNER_ROLE, _msgSender()),
            "Rand Multi Token: You don't have permission to mint tokens!"
        );
        _mint(account, id, amount, twaAmount, data);
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount,
        uint256 twaAmount
    ) public whenNotPaused {
        require(
            hasRole(MINTER_AND_BURNER_ROLE, _msgSender()),
            "Rand Multi Token: You don't have permission to burn tokens!"
        );
        _burn(account, id, amount, twaAmount);
    }

    function setReward(
        address account,
        uint256 id,
        uint256 amount
    ) public whenNotPaused onlyRole(ADMIN_ROLE) {
        require(
            account != address(0),
            "Rand Multi Token: reward set for the zero address"
        );
        _rewards[id][account] = amount;
    }

    function increaseReward(
        address account,
        uint256 id,
        uint256 amount
    ) public whenNotPaused onlyRole(ADMIN_ROLE) {
        require(
            account != address(0),
            "Rand Multi Token: reward increase for the zero address"
        );
        _rewards[id][account] += amount;
    }

    function decreaseReward(
        address account,
        uint256 id,
        uint256 amount
    ) public whenNotPaused onlyRole(ADMIN_ROLE) {
        require(
            account != address(0),
            "Rand Multi Token: reward decrase for the zero address"
        );
        _rewards[id][account] -= amount;
    }

    function setPrize(
        address account,
        uint256 id,
        uint256 amount
    ) public whenNotPaused onlyRole(ADMIN_ROLE) {
        require(
            account != address(0),
            "Rand Multi Token: prize set for the zero address"
        );
        _prizes[id][account] = amount;
    }

    function increasePrize(
        address account,
        uint256 id,
        uint256 amount
    ) public whenNotPaused onlyRole(ADMIN_ROLE) {
        require(
            account != address(0),
            "Rand Multi Token: prize increase for the zero address"
        );
        _prizes[id][account] += amount;
    }

    function decreasePrize(
        address account,
        uint256 id,
        uint256 amount
    ) public whenNotPaused onlyRole(ADMIN_ROLE) {
        require(
            account != address(0),
            "Rand Multi Token: prize decrease for the zero address"
        );
        _prizes[id][account] -= amount;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function twaBalanceOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _twaBalances[id][account];
    }

    function balancesOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256 amount, uint256 twaAmount)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        amount = _balances[id][account];
        twaAmount = _twaBalances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @notice Used to get the vault prize won by an account, 0 in case
     * it didn't won anything
     * @param account the address of the users for which the prize is checked
     * @param id the id of the vault for which the prize is checked
     */
    function rewardOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _rewards[id][account];
    }

    /**
     * @notice Used to get the vault prize won by an account, 0 in case
     * it didn't won anything
     * @param account the address of the users for which the prize is checked
     * @param id the id of the vault for which the prize is checked
     */
    function prizeOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _prizes[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function twaBalanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = twaBalanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice Used to calculate the twa amount that needs to be transfered
     * based on the real amount and balances of the user
     * @param id id of the vault
     * @param account account for which the twa amount is being calculated
     * @param realAmount amount of Rand Multi Tokens from the normal balance
     * @return _twaAmount amount of Rand Multi Tokens from the twa balance that will be
     * transfered when realAmount is being transfered
     */
    function calculateTwaAmount(
        uint256 id,
        address account,
        uint256 realAmount
    ) public view returns (uint256 _twaAmount) {
        _twaAmount = _twaBalances[id][account].mul(realAmount).div(
            _balances[id][account]
        );
    }

    /**
     * @notice Used to update the date of the last withdraw for an participant
     * @dev Called inside the participantWithdraw function of the Vault Manager
     * @param id - id of the vault
     * @param account account which made the withdraw
     */
    function updateParticipantLastWithdrawDate(uint256 id, address account)
        external
        onlyRole(ADMIN_ROLE)
    {
        _lastWithdrawDate[id][account] = block.number;
    }

    /**
     * @param id - id of the vault
     * @param account account whose date of last withdraw is being returned
     * @return the block number when the user made laste withdraw from the vault
     */
    function getParticipantLastWithdrawDate(uint256 id, address account)
        external
        view
        returns (uint256)
    {
        return _lastWithdrawDate[id][account];
    }

    /**
     * @notice Used to update the date of the last deposit for an user
     * @dev Called inside the participantDeposit function of the Vault Manager
     * @param id - id of the vault
     * @param account account which made the deposit
     */
    function updateParticipantLastDepositDate(uint256 id, address account)
        external
        onlyRole(ADMIN_ROLE)
    {
        _lastDepositDate[id][account] = block.number;
    }

    /**
     * @param id - id of the vault
     * @param account account whose date of last deposit is being returned
     * @return the block number when the user made laste deposit from the vault
     */
    function getParticipantLastDepositDate(uint256 id, address account)
        external
        view
        returns (uint256)
    {
        return _lastDepositDate[id][account];
    }

    /**
     * @notice used to grant an address the rights to mint and burn
     * Rand internal token
     * @param _address address that receive the grant to burn and mint tokens
     */
    function grantMintAndBurnRights(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _address != address(0),
            "Rand Multi Token: Address cannot be address 0!"
        );
        AccessControlUpgradeable.grantRole(MINTER_AND_BURNER_ROLE, _address);
    }

    /**
     * @notice used to grant and address admin rights
     * @param _address address that receive the admin role
     */
    function grantAdminRole(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _address != address(0),
            "Rand Multi Token: Address cannot be address 0!"
        );
        AccessControlUpgradeable.grantRole(ADMIN_ROLE, _address);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        uint256 twaAmount = calculateTwaAmount(id, from, amount);
        uint256 fromBalance = _balances[id][from];
        uint256 fromTwaBalance = _twaBalances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        require(
            fromTwaBalance >= twaAmount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
            _twaBalances[id][from] = fromTwaBalance - twaAmount;
        }
        _balances[id][to] += amount;
        _twaBalances[id][to] += twaAmount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 twaAmount = calculateTwaAmount(id, from, amount);

            uint256 fromBalance = _balances[id][from];
            uint256 fromTwaBalance = _twaBalances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            require(
                fromTwaBalance >= twaAmount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
                _twaBalances[id][from] = fromTwaBalance - twaAmount;
            }
            _balances[id][to] += amount;
            _twaBalances[id][to] += twaAmount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        uint256 twaAmount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] += amount;
        _twaBalances[id][account] += twaAmount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory twaAmounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
            _twaBalances[ids[i]][to] += twaAmounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount,
        uint256 twaAmount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 accountBalance = _balances[id][account];
        uint256 accountTwaBalance = _twaBalances[id][account];
        require(
            accountBalance >= amount,
            "ERC1155: burn amount exceeds balance"
        );
        require(
            accountTwaBalance >= twaAmount,
            "ERC1155: burn amount exceeds balance"
        );
        unchecked {
            _balances[id][account] = accountBalance - amount;
            _twaBalances[id][account] = accountTwaBalance - twaAmount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 twaAmount = calculateTwaAmount(id, account, amount);

            uint256 accountBalance = _balances[id][account];
            uint256 accountTwaBalance = _twaBalances[id][account];
            require(
                accountBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            require(
                accountTwaBalance >= twaAmount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                _balances[id][account] = accountBalance - amount;
                _twaBalances[id][account] = accountTwaBalance - twaAmount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable.onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    uint256[47] private __gap;

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0

pragma solidity >=0.6.0;

/**
 * @title Rand Stable Token Interface
 
 *
 * @dev Provides an interface for Rand internal token which implements
 * the tokens associated to the USDC balance of the user.
 *
 */
interface IRandStableToken {
    /**
     * @dev Creates 'amount' tokens and assigns them to 'account', increasing
     * the total supply.
     * @param account account that receives the 'amount' of tokens
     * @param amount amount of tokens that will be created
     */
    event Mint(address account, uint256 amount);

    /**
     * @dev Removes `amount` of tokens and assigns them to `account`
     * @param account account from which the 'amount' of tokens is removed
     * @param amount amount of tokens that will be removed
     */
    event Burn(address account, uint256 amount);

    /**
     * @dev Creates 'amount' tokens and assigns them to 'account', increasing
     * the total supply.
     * @param account account that receives the 'amount' of tokens
     * @param amount amount of tokens that will be created
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Removes `amount` of tokens and assigns them to `account`
     * @param account account from which the 'amount' of tokens is removed
     * @param amount amount of tokens that will be removed
     */
    function burn(address account, uint256 amount) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Approves 'amount' of tokens to be transfered from the 'from' to 'to'
     * @param from address from which account the tokens will be transfered
     * @param to address which can use the tokens
     * @param amount amount of tokens to be approved
     */
    function approveExternal(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0

pragma solidity ^0.8.0;

/**
 * @title Random Number Generator Interface
 * @author Keyko
 *
 * @dev Provides an interface for requesting random numbers from 3rd-vault
 *      Rand Number Generator service (Chainlink VRF)
 *
 */
interface IRandomNumberGenerator {
    /**
     * @notice Emitted when the key has been modified
     */
    event KeyHashSet(bytes32 keyHash);

    /**
     * @notice Emitted when the fee has been modified
     */
    event FeeSet(uint256 fee);

    /**
     * @notice Emitted when the address of the VRF Coordinator contract has been modified
     */
    event VrfCoordinatorSet(address indexed vrfCoordinator);

    /**
     * @notice Emitted when a new random request has been sent for the VRF Coordinator
     */
    event VRFRequested(bytes32 indexed requestId);

    /**
     * @notice Emitted when a new request for a random number has been submitted
     * @param vaultId The indexed ID of the vault for which random number request has been made
     * @param requestId The indexed ID of the request used to get the results of the RNG service
     */
    event RandomNumberRequested(
        uint256 indexed vaultId,
        bytes32 indexed requestId
    );

    /**
     * @notice Emitted when an existing request for a random number has been completed
     * @param vaultId The indexed ID of the vault for which random number request has been made
     * @param requestId The indexed ID of the request used to get the results of the Rand Number Generator service
     * @param randomNumber The random number produced by the 3rd-vault service
     */
    event RandomNumberCompleted(
        uint256 indexed vaultId,
        bytes32 indexed requestId,
        uint256 randomNumber
    );

    /**
     * @notice Emitted when the Random Number Generator contract is close to run out of Link Tokens
     * @param linkBalance The remaining amount of Link Tokens
     */
    event BalanceAlmostZero(uint256 linkBalance);

    /**
     * @notice Gets the Fee for making a Request against 3d-vault service (Chainlink VRF)
     * @return feeToken The address of the token that is used to pay fees
     * @return requestFee The fee required to be paid to make a request
     */
    function getRequestFee()
        external
        view
        returns (address feeToken, uint256 requestFee);

    /**
     * @notice Sends a request for a random number to the 3rd-vault service
     * @dev Some services will complete the request immediately, others may have a time-delay
     * @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
     * @param vaultId The ID of the vault for which random number request has been made
     * @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.
     * The calling contract should "lock" all activity until the result is available via the `requestId`
     */
    function requestRandomNumber(uint256 vaultId)
        external
        returns (uint32 lockBlock);

    /**
     * @notice Checks if the request for randomness from the 3rd-vault service has completed
     * @dev For time-delayed requests, this function is used to check/confirm completion
     * @param vaultId The ID of the vault for which random number request has been made
     * @return isCompleted True if the request has completed and a random number is available, false otherwise
     */
    function isRequestComplete(uint256 vaultId)
        external
        view
        returns (bool isCompleted);

    /**
     * @dev Returns the block number at which the RNG service will start generating time-delayed randomness
     * @param _vaultId The ID of the vault for which the 'lockBlock' is returned
     * @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.
     * The calling contract should "lock" all activity until the result is available via the `requestId`
     */
    function getLockBlock(uint256 _vaultId)
        external
        view
        returns (uint256 lockBlock);

    /**
     * @notice Gets the random number produced by the 3rd-vault service
     * @param vaultId The ID of the vault for which random number request has been made
     * @return randomNumber The random number
     */
    function getRandomNumber(uint256 vaultId)
        external
        view
        returns (uint256 randomNumber);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0

/**
 * @title Prize Strategy Interface
 * @dev Provides an interface for calculating users contributions and sharing their rewards
 *
 */

interface IPrizeStrategy {
    /**
     * @notice Emitted after winners are calculated inside 'getWinners'
     * @param vaultId id of the vault for which the winners are calculated
     * @param winners array containing the winners addresses
     */
    event Winners(
        uint256 indexed vaultId,
        address[] winners,
        uint256[] _prizes
    );

    /**
     * @notice Used to set up the parameters necessary for calculating the prizes for a vault
     * @param tiers array where each index represents the tier and the value
     * from the respective index is the number of prizes for that tier
     * @param percentages array where each index represents the tier and the value
     * from the respective index is the percentage of the total prize that the user gets
     * if he won the that tier
     * @param prize the amount that reprents the amount from which the percentages
     * are calculated
     * @param rewardCoefficient the coefficient that is used to compute the rewards for the users which
     * are not withdrawing since the last prize distribution
     */

    function setPrizeParameters(
        uint256 vaultId,
        uint256[] memory tiers,
        uint256[] memory percentages,
        uint256 prize,
        uint256 rewardCoefficient
    ) external;

    function getRewardCoefficient(uint256 _vaultId) external returns (uint256);

    function computeUserReward(uint256 _vaultId, address _user) external;

    function getPrizesAndWinners(
        uint256[] memory accumlatedTwaArr,
        uint256 _vaultId,
        address[] memory _participants,
        uint256 _randomNumber,
        uint256 _totalMax
    ) external returns (uint256[] memory _prizes, address[] memory _winners);
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}