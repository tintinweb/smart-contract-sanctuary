// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import 'hardhat-deploy/solc_0.8/proxy/Proxied.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './libraries/FarmLookupLibrary.sol';
import './libraries/VRFLibrary.sol';

import './interfaces/IChickenNoodle.sol';
import './interfaces/IEgg.sol';
import './interfaces/IFarm.sol';
import './interfaces/IRandomnessConsumer.sol';
import './interfaces/IRandomnessProvider.sol';

contract Farm is IRandomnessConsumer, Proxied, PausableUpgradeable {
    using VRFLibrary for VRFLibrary.VRFData;

    // maximum tier score for a Noodle
    uint8 public constant MAX_TIER_SCORE = 8;

    struct ClaimRequest {
        address owner;
        uint256 owed;
        bytes32 hash;
    }

    event ClaimProcessed(address owner, uint256 owed, bool stolen);
    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event ChickenClaimed(
        uint256 tokenId,
        uint256 earned,
        uint256 stolen,
        bool unstaked
    );
    event NoodleClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the ChickenNoodle NFT contract
    IChickenNoodle public chickenNoodle;
    // reference to the $EGG contract for minting $EGG earnings
    IEgg egg;

    // maps tokenId to stake
    mapping(uint16 => IFarm.Stake) public henHouse;
    // maps tier score to all Noodle stakes with their tier
    mapping(uint8 => IFarm.Stake[]) public den;
    // tracks location of each Noodle in Den
    mapping(uint16 => uint16) public denIndices;
    // total tier score scores staked
    uint256 public totalTierScoreStaked;
    // any rewards distributed when no noodles are staked
    uint256 public unaccountedRewards;
    // amount of $EGG due for each tier score point staked
    uint256 public eggPerTierScore;

    // Gen 0 Chickens earn 10000 $EGG per day
    uint256 public constant DAILY_GEN0_EGG_RATE = 10000 ether;
    // Gen 1 Chickens earn 6000 $EGG per day
    uint256 public constant DAILY_GEN1_EGG_RATE = 6000 ether;
    // Chicken must have 2 days worth of $EGG to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // noodles take a 20% tax on all $EGG claimed
    uint256 public constant EGG_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $EGG earned through staking
    uint256 public constant MAXIMUM_GLOBAL_EGG = 2400000000 ether;

    // amount of $EGG earned so far
    uint256 public totalEggEarned;
    // the last time $EGG was claimed
    uint256 public lastClaimTimestamp;
    // number of Chicken staked in the HenHouse
    uint16 public totalChickenStaked;
    // number of Gen 0 Chicken staked in the HenHouse
    uint16 public gen0ChickensStaked;

    // emergency rescue to allow unstaking without any checks but without $EGG
    bool public rescueEnabled;

    // number of claims have been processed so far
    uint16 public claimsProcessed;
    // number of claims have been requested so far
    uint16 public claimsRequested;

    VRFLibrary.VRFData private vrf;

    mapping(uint256 => ClaimRequest) internal claims;

    uint256 randomnessInterval;
    uint256 randomnessClaimsNeeded;
    uint256 randomnessClaimsMinimum;

    // /**
    //  * @param _chickenNoodle reference to the ChickenNoodleSoup NFT contract
    //  * @param _egg reference to the $EGG token
    //  */
    // constructor(address _egg, address _chickenNoodle) {
    //     initialize(_egg, _chickenNoodle);
    // }

    /**
     * @param _chickenNoodle reference to the ChickenNoodleSoup NFT contract
     * @param _egg reference to the $EGG token
     */
    function initialize(address _egg, address _chickenNoodle) public proxied {
        __Pausable_init();

        egg = IEgg(_egg);
        chickenNoodle = IChickenNoodle(_chickenNoodle);

        randomnessInterval = 12 hours;
        randomnessClaimsNeeded = 50;
        randomnessClaimsMinimum = 0;
    }

    function processingStats()
        public
        view
        returns (
            bool requestPending,
            uint256 maxIdAvailableToProcess,
            uint256 readyForProcessing,
            uint256 waitingToBeProcessed,
            uint256 timeTellNextRandomnessRequest
        )
    {
        return vrf.processingStats(claimsRequested, claimsProcessed, randomnessInterval);
    }

    function getTotalStaked()
        public
        view
        returns (
            uint16 chickens,
            uint16 noodles,
            uint16 tier5Noodles,
            uint16 tier4Noodles,
            uint16 tier3Noodles,
            uint16 tier2Noodles,
            uint16 tier1Noodles
        )
    {
        return FarmLookupLibrary.getTotalStaked(address(this), den);
    }

    function getStakedBalanceOf(address tokenOwner)
        public
        view
        returns (
            uint16 chickens,
            uint16 noodles,
            uint16 tier5Noodles,
            uint16 tier4Noodles,
            uint16 tier3Noodles,
            uint16 tier2Noodles,
            uint16 tier1Noodles
        )
    {
        return
            FarmLookupLibrary.getStakedBalanceOf(
                address(this),
                tokenOwner,
                henHouse,
                den,
                denIndices
            );
    }

    function getStakedChickensForOwner(
        address tokenOwner,
        uint16 limit,
        uint16 page
    )
        public
        view
        returns (
            uint16[] memory tokens,
            uint256[] memory timeTellUnlock,
            uint256[] memory earnedEgg
        )
    {
        return
            FarmLookupLibrary.getStakedChickensForOwner(
                address(this),
                IFarm.PagingData(tokenOwner, limit, page),
                henHouse,
                den,
                denIndices
            );
    }

    function getStakedNoodlesForOwner(
        address tokenOwner,
        uint16 limit,
        uint16 page
    )
        public
        view
        returns (
            uint16[] memory tokens,
            uint8[] memory tier,
            uint256[] memory taxedEgg
        )
    {
        return
            FarmLookupLibrary.getStakedNoodlesForOwner(
                address(this),
                IFarm.PagingData(tokenOwner, limit, page),
                henHouse,
                den,
                denIndices
            );
    }

    /** STAKING */

    /**
     * adds Chicken and Noodles to the HenHouse and Den
     * @param tokenIds the IDs of the Chicken and Noodles to stake
     */
    function addManyToHenHouseAndDen(uint16[] calldata tokenIds) external {
        require(tx.origin == _msgSender(), 'Only EOA');

        for (uint16 i = 0; i < tokenIds.length; i++) {
            require(
                chickenNoodle.ownerOf(tokenIds[i]) == _msgSender(),
                'Can only stake your own tokens'
            );

            chickenNoodle.transferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );

            if (isChicken(tokenIds[i])) {
                _addChickenToHenHouse(tokenIds[i]);
            } else {
                _addNoodleToDen(tokenIds[i]);
            }
        }
    }

    /**
     * adds a single Chicken to the HenHouse
     * @param tokenId the ID of the Chicken to add to the HenHouse
     */
    function _addChickenToHenHouse(uint16 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        henHouse[tokenId] = IFarm.Stake({
            owner: _msgSender(),
            tokenId: tokenId,
            value: uint80(block.timestamp)
        });
        if (tokenId <= chickenNoodle.PAID_TOKENS()) {
            gen0ChickensStaked++;
        }
        totalChickenStaked++;
        emit TokenStaked(_msgSender(), tokenId, block.timestamp);
    }

    /**
     * adds a single Noodle to the Den
     * @param tokenId the ID of the Noodle to add to the Den
     */
    function _addNoodleToDen(uint16 tokenId) internal {
        uint8 tierScore = tierScoreForNoodle(tokenId);
        totalTierScoreStaked += tierScore; // Portion of earnings ranges from 8 to 4
        denIndices[tokenId] = uint16(den[tierScore].length); // Store the location of the noodle in the Den
        den[tierScore].push(
            IFarm.Stake({
                owner: _msgSender(),
                tokenId: tokenId,
                value: uint80(eggPerTierScore)
            })
        ); // Add the noodle to the Den
        emit TokenStaked(_msgSender(), tokenId, eggPerTierScore);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $EGG earnings and optionally unstake tokens from the HenHouse / Den
     * to unstake a Chicken it will require it has 2 days worth of $EGG unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromHenHouseAndDen(
        uint16[] calldata tokenIds,
        bool unstake
    ) external whenNotPaused _updateEarnings {
        require(tx.origin == _msgSender(), 'Only EOA');

        uint256 owed = 0;
        for (uint16 i = 0; i < tokenIds.length; i++) {
            require(
                chickenNoodle.ownerOf(tokenIds[i]) == address(this),
                'Can only claim tokens that are staked'
            );

            if (isChicken(tokenIds[i])) {
                owed += _claimChickenFromHenHouse(tokenIds[i], unstake);
            } else {
                owed += _claimNoodleFromDen(tokenIds[i], unstake);
            }
        }
        if (owed == 0) return;
        egg.mint(_msgSender(), owed);
    }

    /**
     * realize $EGG earnings for a single Chicken and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Noodles
     * if unstaking, there is a 50% chance all $EGG is stolen
     * @param tokenId the ID of the Chicken to claim earnings from
     * @param unstake whether or not to unstake the Chicken
     * @return owed - the amount of $EGG earned
     */
    function _claimChickenFromHenHouse(uint16 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        IFarm.Stake memory stake = henHouse[tokenId];
        require(
            stake.owner == _msgSender(),
            'Can only claim tokens you staked'
        );
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            'Can only unstake if you have waited the minimum exit time'
        );
        if (totalEggEarned < MAXIMUM_GLOBAL_EGG) {
            owed =
                ((block.timestamp - stake.value) *
                    (
                        tokenId <= chickenNoodle.PAID_TOKENS()
                            ? DAILY_GEN0_EGG_RATE
                            : DAILY_GEN1_EGG_RATE
                    )) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $EGG production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) *
                    (
                        tokenId <= chickenNoodle.PAID_TOKENS()
                            ? DAILY_GEN0_EGG_RATE
                            : DAILY_GEN1_EGG_RATE
                    )) /
                1 days; // stop earning additional $EGG if it's all been earned
        }

        uint256 stolen;

        if (unstake) {
            claimsRequested++;
            claims[claimsRequested] = ClaimRequest({
                owner: _msgSender(),
                owed: owed,
                hash: blockhash(block.number - 1)
            });

            owed = 0;
            delete henHouse[tokenId];
            if (tokenId <= chickenNoodle.PAID_TOKENS()) {
                gen0ChickensStaked--;
            }
            totalChickenStaked--;

            chickenNoodle.transferFrom(address(this), _msgSender(), tokenId); // send back Chicken
        } else {
            stolen = (owed * EGG_CLAIM_TAX_PERCENTAGE) / 100;
            _payNoodleTax(stolen); // percentage tax to staked noodles
            owed = owed - stolen; // remainder goes to Chicken owner
            henHouse[tokenId] = IFarm.Stake({
                owner: _msgSender(),
                tokenId: tokenId,
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit ChickenClaimed(tokenId, owed, stolen, unstake);

        checkRandomness(false);
    }

    function checkRandomness(bool force) public {
        force = force && _msgSender() == _proxyAdmin();

        if (force) {
            vrf.newRequest();
        } else {
            vrf.checkRandomness(
                claimsRequested, 
                claimsProcessed,
                randomnessInterval,
                randomnessClaimsNeeded,
                randomnessClaimsMinimum);
        }

        _processNext();
    }

    function process(uint256 amount) external override {
        for (uint256 i = 0; i < amount; i++) {
            if (!_processNext()) break;
        }
    }

    function setRandomnessResult(bytes32 requestId, uint256 randomness)
        external
        override
    {
        vrf.setRequestResults(requestId, randomness, claimsRequested);
    }

    function processNext() external override returns (bool) {
        return _processNext();
    }

    function _processNext() internal returns (bool) {
        uint256 claimId = claimsProcessed + 1;

        (bool available, uint256 randomness) = vrf.randomnessForId(claimId);

        if (available) {
            uint256 seed = random(claimId, randomness);

            if (seed & 1 == 1) {
                // 50% chance of all $EGG stolen
                _payNoodleTax(claims[claimId].owed);
                emit ClaimProcessed(
                    claims[claimId].owner,
                    claims[claimId].owed,
                    true
                );
            } else {
                egg.mint(claims[claimId].owner, claims[claimId].owed);
                emit ClaimProcessed(
                    claims[claimId].owner,
                    claims[claimId].owed,
                    false
                );
            }

            delete claims[claimId];
            claimsProcessed++;
            return true;
        }

        return false;
    }

    /**
     * realize $EGG earnings for a single Noodle and optionally unstake it
     * Noodles earn $EGG proportional to their Tier score
     * @param tokenId the ID of the Noodle to claim earnings from
     * @param unstake whether or not to unstake the Noodle
     * @return owed - the amount of $EGG earned
     */
    function _claimNoodleFromDen(uint16 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        uint8 tierScore = tierScoreForNoodle(tokenId);
        IFarm.Stake memory stake = den[tierScore][denIndices[tokenId]];

        require(
            stake.owner == _msgSender(),
            'Can only claim tokens you staked'
        );

        owed = (tierScore) * (eggPerTierScore - stake.value); // Calculate portion of tokens based on Tier score
        if (unstake) {
            totalTierScoreStaked -= tierScore; // Remove Tier score from total staked
            IFarm.Stake memory lastStake = den[tierScore][
                den[tierScore].length - 1
            ];
            den[tierScore][denIndices[tokenId]] = lastStake; // Shuffle last Noodle to current position
            denIndices[lastStake.tokenId] = denIndices[tokenId];
            den[tierScore].pop(); // Remove duplicate
            delete denIndices[tokenId]; // Delete old mapping

            chickenNoodle.transferFrom(address(this), _msgSender(), tokenId); // Send back Noodle
        } else {
            den[tierScore][denIndices[tokenId]] = IFarm.Stake({
                owner: _msgSender(),
                tokenId: tokenId,
                value: uint80(eggPerTierScore)
            }); // reset stake
        }
        emit NoodleClaimed(tokenId, owed, unstake);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint16[] calldata tokenIds) external {
        require(rescueEnabled, 'Rescue is currently disabled');

        uint16 tokenId;
        IFarm.Stake memory stake;
        IFarm.Stake memory lastStake;
        uint8 tierScore;

        for (uint16 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (isChicken(tokenId)) {
                stake = henHouse[tokenId];

                require(
                    stake.owner == _msgSender(),
                    'Can only claim tokens you staked'
                );

                delete henHouse[tokenId];
                if (tokenId <= chickenNoodle.PAID_TOKENS()) {
                    gen0ChickensStaked--;
                }
                totalChickenStaked--;

                chickenNoodle.transferFrom(
                    address(this),
                    _msgSender(),
                    tokenId
                ); // send back Chicken

                emit ChickenClaimed(tokenId, 0, 0, true);
            } else {
                tierScore = tierScoreForNoodle(tokenId);
                stake = den[tierScore][denIndices[tokenId]];

                require(
                    stake.owner == _msgSender(),
                    'Can only claim tokens you staked'
                );

                totalTierScoreStaked -= tierScore; // Remove Tier score from total staked
                lastStake = den[tierScore][den[tierScore].length - 1];
                den[tierScore][denIndices[tokenId]] = lastStake; // Shuffle last Noodle to current position
                denIndices[lastStake.tokenId] = denIndices[tokenId];
                den[tierScore].pop(); // Remove duplicate
                delete denIndices[tokenId]; // Delete old mapping

                chickenNoodle.transferFrom(
                    address(this),
                    _msgSender(),
                    tokenId
                ); // Send back Noodle

                emit NoodleClaimed(tokenId, 0, true);
            }
        }
    }

    /**
     * allows owner to rescue tokens
     */
    function rescueTokens(IERC20 token, uint256 amount)
        external
        onlyProxyAdmin
    {
        token.transfer(_proxyAdmin(), amount);
    }

    /** ACCOUNTING */

    /**
     * add $EGG to claimable pot for the den
     * @param amount $EGG to add to the pot
     */
    function _payNoodleTax(uint256 amount) internal {
        if (totalTierScoreStaked == 0) {
            // if there's no staked noodles
            unaccountedRewards += amount; // keep track of $EGG due to noodles
            return;
        }
        // makes sure to include any unaccounted $EGG
        eggPerTierScore += (amount + unaccountedRewards) / totalTierScoreStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $EGG earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalEggEarned < MAXIMUM_GLOBAL_EGG) {
            totalEggEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    gen0ChickensStaked *
                    DAILY_GEN0_EGG_RATE) /
                1 days;
            totalEggEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    (gen0ChickensStaked - gen0ChickensStaked) *
                    DAILY_GEN1_EGG_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random values
     * @param _randomnessProvider the address of the new RandomnessProvider
     */
    function setRandomnessProvider(address _randomnessProvider)
        external
        override
        onlyProxyAdmin
    {
        vrf.setRandomnessProvider(_randomnessProvider);
    }

    /**
     * called to upoate fee to get randomness
     * @param _fee the fee required for getting randomness
     */
    function updateRandomnessFee(uint256 _fee)
        external
        override
        onlyProxyAdmin
    {
        vrf.updateFee(_fee);
    }

    /**
     * allows owner to rescue LINK tokens
     */
    function rescueLINK(uint256 amount) external override onlyProxyAdmin {
        vrf.rescueLINK(_proxyAdmin(), amount);
    }

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyProxyAdmin {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyProxyAdmin {
        if (_paused) _pause();
        else _unpause();
    }

    /** READ ONLY */

    /**
     * checks if a token is a Chicken
     * @param tokenId the ID of the token to check
     * @return chicken - whether or not a token is a Chicken
     */
    function isChicken(uint16 tokenId) public view returns (bool) {
        return chickenNoodle.tokenTraits(tokenId).isChicken;
    }

    /**
     * gets the tier score for a Noodle
     * @param tokenId the ID of the Noodle to get the tier score for
     * @return the tier score of the Noodle (5-8)
     */
    function tierScoreForNoodle(uint16 tokenId) public view returns (uint8) {
        return chickenNoodle.tokenTraits(tokenId).tier + 3; // tier is 5-1
    }

    /**
     * chooses a random Noodle thief when a newly minted token is stolen
     * @param seed a random value to choose a Noodle from
     * @return the owner of the randomly selected Noodle thief
     */
    function randomNoodleOwner(uint256 seed) external view returns (address) {
        if (totalTierScoreStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalTierScoreStaked; // choose a value from 0 to total tier score staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Noodles with the same tier score
        for (uint8 i = MAX_TIER_SCORE - 4; i <= MAX_TIER_SCORE; i++) {
            cumulative += den[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Noodle with that tier score
            return den[i][seed % den[i].length].owner;
        }
        return address(0x0);
    }

    /**
     * generates a pseudorandom number
     * @param claimId a value ensure different outcomes for different sources in the same block
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 claimId, uint256 seed)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encodePacked(claimId, claims[claimId].hash, seed))
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IFarm.sol';

library FarmLookupLibrary {
    struct Counters {
        uint256 skipCounter;
        uint256 counter;
    }

    function getTotalStaked(
        address farmAddress,
        mapping(uint8 => IFarm.Stake[]) storage den
    )
        public
        view
        returns (
            uint16 chickens,
            uint16 noodles,
            uint16 tier5Noodles,
            uint16 tier4Noodles,
            uint16 tier3Noodles,
            uint16 tier2Noodles,
            uint16 tier1Noodles
        )
    {
        IFarm farm = IFarm(farmAddress);

        chickens = farm.totalChickenStaked();

        tier5Noodles = uint16(den[farm.MAX_TIER_SCORE()].length);
        tier4Noodles = uint16(den[farm.MAX_TIER_SCORE() - 1].length);
        tier3Noodles = uint16(den[farm.MAX_TIER_SCORE() - 2].length);
        tier2Noodles = uint16(den[farm.MAX_TIER_SCORE() - 3].length);
        tier1Noodles = uint16(den[farm.MAX_TIER_SCORE() - 4].length);

        noodles =
            tier5Noodles +
            tier4Noodles +
            tier3Noodles +
            tier2Noodles +
            tier1Noodles;
    }

    function getStakedBalanceOf(
        address farmAddress,
        address tokenOwner,
        mapping(uint16 => IFarm.Stake) storage henHouse,
        mapping(uint8 => IFarm.Stake[]) storage den,
        mapping(uint16 => uint16) storage denIndices
    )
        public
        view
        returns (
            uint16 chickens,
            uint16 noodles,
            uint16 tier5Noodles,
            uint16 tier4Noodles,
            uint16 tier3Noodles,
            uint16 tier2Noodles,
            uint16 tier1Noodles
        )
    {
        IFarm farm = IFarm(farmAddress);

        uint16 supply = uint16(farm.chickenNoodle().totalSupply());

        for (uint16 tokenId = 1; tokenId <= supply; tokenId++) {
            if (farm.chickenNoodle().ownerOf(tokenId) != address(this)) {
                continue;
            }

            if (farm.isChicken(tokenId)) {
                if (henHouse[tokenId].owner == tokenOwner) {
                    chickens++;
                }
            } else {
                uint8 tierScore = farm.tierScoreForNoodle(tokenId);

                if (den[tierScore][denIndices[tokenId]].owner == tokenOwner) {
                    if (tierScore == 8) {
                        tier5Noodles++;
                    } else if (tierScore == 7) {
                        tier4Noodles++;
                    } else if (tierScore == 6) {
                        tier3Noodles++;
                    } else if (tierScore == 5) {
                        tier2Noodles++;
                    } else if (tierScore == 4) {
                        tier1Noodles++;
                    }
                }
            }
        }

        noodles =
            tier5Noodles +
            tier4Noodles +
            tier3Noodles +
            tier2Noodles +
            tier1Noodles;
    }

    function getStakedChickensForOwner(
        address farmAddress,
        IFarm.PagingData memory data,
        mapping(uint16 => IFarm.Stake) storage henHouse,
        mapping(uint8 => IFarm.Stake[]) storage den,
        mapping(uint16 => uint16) storage denIndices
    )
        public
        view
        returns (
            uint16[] memory tokens,
            uint256[] memory timeTellUnlock,
            uint256[] memory earnedEgg
        )
    {
        IFarm farm = IFarm(farmAddress);

        (uint16 tokensOwned, , , , , , ) = getStakedBalanceOf(
            farmAddress,
            data.tokenOwner,
            henHouse,
            den,
            denIndices
        );

        (uint256 tokensSize, uint256 pageStart) = _paging(
            tokensOwned,
            data.limit,
            data.page
        );

        tokens = new uint16[](tokensSize);
        timeTellUnlock = new uint256[](tokensSize);
        earnedEgg = new uint256[](tokensSize);

        Counters memory counters;

        uint16 supply = uint16(farm.chickenNoodle().totalSupply());

        for (
            uint16 tokenId = 1;
            tokenId <= supply && counters.counter < tokens.length;
            tokenId++
        ) {
            if (farm.chickenNoodle().ownerOf(tokenId) != address(this)) {
                continue;
            }

            if (
                farm.isChicken(tokenId) &&
                henHouse[tokenId].owner == data.tokenOwner
            ) {
                IFarm.Stake memory stake = henHouse[tokenId];

                if (counters.skipCounter < pageStart) {
                    counters.skipCounter++;
                    continue;
                }

                tokens[counters.counter] = tokenId;
                timeTellUnlock[counters.counter] = block.timestamp -
                    stake.value <
                    farm.MINIMUM_TO_EXIT()
                    ? farm.MINIMUM_TO_EXIT() - (block.timestamp - stake.value)
                    : 0;

                if (farm.totalEggEarned() < farm.MAXIMUM_GLOBAL_EGG()) {
                    earnedEgg[counters.counter] =
                        ((block.timestamp - stake.value) *
                            (
                                tokenId <= farm.chickenNoodle().PAID_TOKENS()
                                    ? farm.DAILY_GEN0_EGG_RATE()
                                    : farm.DAILY_GEN1_EGG_RATE()
                            )) /
                        1 days;
                } else if (stake.value > farm.lastClaimTimestamp()) {
                    earnedEgg[counters.counter] = 0; // $EGG production stopped already
                } else {
                    earnedEgg[counters.counter] =
                        ((farm.lastClaimTimestamp() - stake.value) *
                            (
                                tokenId <= farm.chickenNoodle().PAID_TOKENS()
                                    ? farm.DAILY_GEN0_EGG_RATE()
                                    : farm.DAILY_GEN1_EGG_RATE()
                            )) /
                        1 days; // stop earning additional $EGG if it's all been earned
                }

                counters.counter++;
            }
        }
    }

    function getStakedNoodlesForOwner(
        address farmAddress,
        IFarm.PagingData memory data,
        mapping(uint16 => IFarm.Stake) storage henHouse,
        mapping(uint8 => IFarm.Stake[]) storage den,
        mapping(uint16 => uint16) storage denIndices
    )
        public
        view
        returns (
            uint16[] memory tokens,
            uint8[] memory tier,
            uint256[] memory taxedEgg
        )
    {
        IFarm farm = IFarm(farmAddress);

        (, uint16 tokensOwned, , , , , ) = getStakedBalanceOf(
            farmAddress,
            data.tokenOwner,
            henHouse,
            den,
            denIndices
        );

        (uint256 tokensSize, uint256 pageStart) = _paging(
            tokensOwned,
            data.limit,
            data.page
        );

        tokens = new uint16[](tokensSize);
        tier = new uint8[](tokensSize);
        taxedEgg = new uint256[](tokensSize);

        Counters memory counters;

        uint16 supply = uint16(farm.chickenNoodle().totalSupply());

        for (
            uint16 tokenId = 1;
            tokenId <= supply && counters.counter < tokens.length;
            tokenId++
        ) {
            if (farm.chickenNoodle().ownerOf(tokenId) != address(this)) {
                continue;
            }

            if (!farm.isChicken(tokenId)) {
                uint8 tierScore = farm.tierScoreForNoodle(tokenId);

                IFarm.Stake memory stake = den[tierScore][denIndices[tokenId]];

                if (stake.owner == data.tokenOwner) {
                    if (counters.skipCounter < pageStart) {
                        counters.skipCounter++;
                        continue;
                    }

                    tokens[counters.counter] = tokenId;
                    tier[counters.counter] = tierScore - 3;
                    taxedEgg[counters.counter] =
                        (tierScore) *
                        (farm.eggPerTierScore() - stake.value);
                    counters.counter++;
                }
            }
        }
    }

    function _paging(
        uint16 tokensOwned,
        uint16 limit,
        uint16 page
    ) private pure returns (uint256 tokensSize, uint256 pageStart) {
        pageStart = limit * page;
        uint256 pageEnd = limit * (page + 1);
        tokensSize = tokensOwned >= pageEnd
            ? limit
            : (tokensOwned > pageStart ? tokensOwned - pageStart : 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IRandomnessProvider.sol';

library VRFLibrary {
    struct VRFData {
        IRandomnessProvider randomnessProvider;
        bytes32 lastRequestId;
        mapping(uint256 => uint256) highestIdForRandomness;
        mapping(uint256 => uint256) randomResults;
        uint256 lastRequest;
        uint256 minResultIndex;
        uint256 resultsReceived;
    }

    modifier onlyRandomnessProvider(VRFData storage self) {
        require(
            msg.sender == address(self.randomnessProvider),
            'Required to be randomnessProvider'
        );
        _;
    }

    function processingStats(
        VRFData storage self,
        uint256 maxId,
        uint256 processedId,
        uint256 interval
    )
        public
        view
        returns (
            bool requestPending,
            uint256 maxIdAvailableToProcess,
            uint256 readyForProcessing,
            uint256 waitingToBeProcessed,
            uint256 timeTellNextRandomnessRequest
        )
    {
        timeTellNextRandomnessRequest = self.lastRequest + interval < block.timestamp
                ? 0
                : (self.lastRequest + interval) - block.timestamp;

        return (
            self.lastRequestId != '' && timeTellNextRandomnessRequest > interval / 2,
            self.highestIdForRandomness[self.resultsReceived],
            self.highestIdForRandomness[self.resultsReceived] - processedId,
            maxId - self.highestIdForRandomness[self.resultsReceived],
            timeTellNextRandomnessRequest
        );
    }

    function checkRandomness(
        VRFData storage self,
        uint256 maxId,
        uint256 processedId,
        uint256 interval,
        uint256 needed,
        uint256 minimum
    ) external {
        (
            bool requested,
            ,
            ,
            uint256 processingNeeded,
            uint256 timeTellNext
        ) = processingStats(self, maxId, processedId, interval);

        if (
            !requested &&
            (processingNeeded >= needed ||
                (timeTellNext == 0 && processingNeeded > minimum))
        ) {
            newRequest(self);
        }
    }

    function newRequest(VRFData storage self) public {
        bytes32 requestId = self.randomnessProvider.newRandomnessRequest();

        if (requestId != '') {
            self.lastRequest = block.timestamp;
            self.lastRequestId = requestId;
        }
    }

    function setRequestResults(
        VRFData storage self,
        bytes32 requestId,
        uint256 randomness,
        uint256 maxId
    ) public onlyRandomnessProvider(self) {
        if (self.lastRequestId == requestId) {
            self.resultsReceived++;
            self.randomResults[self.resultsReceived] = randomness;
            self.highestIdForRandomness[self.resultsReceived] = maxId;
            self.lastRequestId = '';
        }
    }

    function randomnessForId(VRFData storage self, uint256 id)
        public
        returns (bool available, uint256 randomness)
    {
        while (
            self.highestIdForRandomness[self.minResultIndex] < id &&
            self.minResultIndex < self.resultsReceived
        ) {
            delete self.randomResults[self.minResultIndex];
            delete self.highestIdForRandomness[self.minResultIndex];
            self.minResultIndex++;
        }

        if (self.highestIdForRandomness[self.minResultIndex] >= id) {
            return (true, self.randomResults[self.minResultIndex]);
        }

        return (false, 0);
    }

    function setRandomnessProvider(
        VRFData storage self,
        address randomnessProvider
    ) public {
        self.randomnessProvider = IRandomnessProvider(randomnessProvider);
    }

    function updateFee(VRFData storage self, uint256 fee) public {
        self.randomnessProvider.updateFee(fee);
    }

    function rescueLINK(
        VRFData storage self,
        address to,
        uint256 amount
    ) public {
        self.randomnessProvider.rescueLINK(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChickenNoodle {
    // struct to store each token's traits
    struct ChickenNoodleTraits {
        bool minted;
        bool isChicken;
        uint8 backgrounds;
        uint8 snakeBodies;
        uint8 mouthAccessories;
        uint8 pupils;
        uint8 bodyAccessories;
        uint8 hats;
        uint8 tier;
    }

    function MAX_TOKENS() external view returns (uint256);

    function PAID_TOKENS() external view returns (uint256);

    function tokenTraits(uint256 tokenId)
        external
        view
        returns (ChickenNoodleTraits memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(address to, uint16 tokenId) external;

    function finalize(
        uint16 tokenId,
        ChickenNoodleTraits memory traits,
        address thief
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEgg {
    /**
     * mints $EGG to a recipient
     * @param to the recipient of the $EGG
     * @param amount the amount of $EGG to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * burns $EGG from a holder
     * @param from the holder of the $EGG
     * @param amount the amount of $EGG to burn
     */
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IChickenNoodle.sol';

interface IFarm {
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    struct PagingData {
        address tokenOwner;
        uint16 limit;
        uint16 page;
    }

    function totalChickenStaked() external view returns (uint16);

    function MINIMUM_TO_EXIT() external view returns (uint256);

    function MAX_TIER_SCORE() external view returns (uint8);

    function MAXIMUM_GLOBAL_EGG() external view returns (uint256);

    function DAILY_GEN0_EGG_RATE() external view returns (uint256);

    function DAILY_GEN1_EGG_RATE() external view returns (uint256);

    function eggPerTierScore() external view returns (uint256);

    function totalEggEarned() external view returns (uint256);

    function lastClaimTimestamp() external view returns (uint256);

    function denIndices(uint16 tokenId) external view returns (uint16);

    function chickenNoodle() external view returns (IChickenNoodle);

    function isChicken(uint16 tokenId) external view returns (bool);

    function tierScoreForNoodle(uint16 tokenId) external view returns (uint8);

    function randomNoodleOwner(uint256 seed) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomnessConsumer {
    function setRandomnessResult(bytes32 requestId, uint256 randomness)
        external;

    function process(uint256 amount) external;

    function processNext() external returns (bool);

    function setRandomnessProvider(address _randomnessProvider) external;

    function updateRandomnessFee(uint256 _fee) external;

    function rescueLINK(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomnessProvider {
    function newRandomnessRequest() external returns (bytes32);

    function updateFee(uint256) external;

    function rescueLINK(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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