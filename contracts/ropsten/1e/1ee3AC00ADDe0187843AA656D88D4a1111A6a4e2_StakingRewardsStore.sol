// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@bancor/contracts-solidity/solidity/contracts/token/interfaces/IDSToken.sol";

struct PoolProgram {
    uint256 startTime;
    uint256 endTime;
    uint256 rewardRate;
    IERC20[2] reserveTokens;
    uint32[2] rewardShares;
}

struct PoolRewards {
    uint256 lastUpdateTime;
    uint256 rewardPerToken;
    uint256 totalClaimedRewards;
}

struct ProviderRewards {
    uint256 rewardPerToken;
    uint256 pendingBaseRewards;
    uint256 totalClaimedRewards;
    uint256 effectiveStakingTime;
    uint256 baseRewardsDebt;
    uint32 baseRewardsDebtMultiplier;
}

interface IStakingRewardsStore {
    function isPoolParticipating(IDSToken poolToken) external view returns (bool);

    function isReserveParticipating(IDSToken poolToken, IERC20 reserveToken) external view returns (bool);

    function addPoolProgram(
        IDSToken poolToken,
        IERC20[2] calldata reserveTokens,
        uint32[2] calldata rewardShares,
        uint256 endTime,
        uint256 rewardRate
    ) external;

    function removePoolProgram(IDSToken poolToken) external;

    function setPoolProgramEndTime(IDSToken poolToken, uint256 newEndTime) external;

    function poolProgram(IDSToken poolToken)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            IERC20[2] memory,
            uint32[2] memory
        );

    function poolPrograms()
        external
        view
        returns (
            IDSToken[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            IERC20[2][] memory,
            uint32[2][] memory
        );

    function poolRewards(IDSToken poolToken, IERC20 reserveToken)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function updatePoolRewardsData(
        IDSToken poolToken,
        IERC20 reserveToken,
        uint256 lastUpdateTime,
        uint256 rewardPerToken,
        uint256 totalClaimedRewards
    ) external;

    function providerRewards(
        address provider,
        IDSToken poolToken,
        IERC20 reserveToken
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint32
        );

    function updateProviderRewardsData(
        address provider,
        IDSToken poolToken,
        IERC20 reserveToken,
        uint256 rewardPerToken,
        uint256 pendingBaseRewards,
        uint256 totalClaimedRewards,
        uint256 effectiveStakingTime,
        uint256 baseRewardsDebt,
        uint32 baseRewardsDebtMultiplier
    ) external;

    function updateProviderLastClaimTime(address provider) external;

    function providerLastClaimTime(address provider) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@bancor/contracts-solidity/solidity/contracts/utility/Utils.sol";
import "@bancor/contracts-solidity/solidity/contracts/utility/Time.sol";
import "@bancor/contracts-solidity/solidity/contracts/utility/interfaces/IOwned.sol";
import "@bancor/contracts-solidity/solidity/contracts/converter/interfaces/IConverter.sol";
import "@bancor/contracts-solidity/solidity/contracts/token/interfaces/IDSToken.sol";

import "./IStakingRewardsStore.sol";

/**
 * @dev This contract stores staking rewards liquidity and pool specific data
 */
contract StakingRewardsStore is IStakingRewardsStore, AccessControl, Utils, Time {
    using SafeMath for uint32;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // the supervisor role is used to globally govern the contract and its governing roles.
    bytes32 public constant ROLE_SUPERVISOR = keccak256("ROLE_SUPERVISOR");

    // the owner role is used to set the values in the store.
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");

    // the manager role is used to manage the programs in the store.
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");

    // the seeder roles is used to seed the store with past values.
    bytes32 public constant ROLE_SEEDER = keccak256("ROLE_SEEDER");

    uint32 private constant PPM_RESOLUTION = 1000000;

    uint256 private constant MAX_REWARD_RATE = 2**128 - 1;

    // the mapping between pool tokens and their respective rewards program information.
    mapping(IDSToken => PoolProgram) private _programs;

    // the set of participating pools.
    EnumerableSet.AddressSet private _pools;

    // the mapping between pools, reserve tokens, and their rewards.
    mapping(IDSToken => mapping(IERC20 => PoolRewards)) internal _poolRewards;

    // the mapping between pools, reserve tokens, and provider specific rewards.
    mapping(address => mapping(IDSToken => mapping(IERC20 => ProviderRewards))) internal _providerRewards;

    // the mapping between providers and their respective last claim times.
    mapping(address => uint256) private _providerLastClaimTimes;

    /**
     * @dev triggered when a program is being added
     *
     * @param poolToken the pool token representing the rewards pool
     * @param startTime the starting time of the program
     * @param endTime the ending time of the program
     * @param rewardRate the program's rewards rate per-second
     */
    event PoolProgramAdded(IDSToken indexed poolToken, uint256 startTime, uint256 endTime, uint256 rewardRate);

    /**
     * @dev triggered when a program is being removed
     *
     * @param poolToken the pool token representing the rewards pool
     */
    event PoolProgramRemoved(IDSToken indexed poolToken);

    /**
     * @dev triggered when provider's last claim time is being updated
     *
     * @param provider the owner of the liquidity
     * @param claimTime the time of the last claim
     */
    event ProviderLastClaimTimeUpdated(address indexed provider, uint256 claimTime);

    /**
     * @dev initializes a new StakingRewardsStore contract
     */
    constructor() public {
        // set up administrative roles.
        _setRoleAdmin(ROLE_SUPERVISOR, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_OWNER, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_MANAGER, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_SEEDER, ROLE_SUPERVISOR);

        // allow the deployer to initially govern the contract.
        _setupRole(ROLE_SUPERVISOR, _msgSender());
    }

    // allows execution only by an owner
    modifier onlyOwner {
        _hasRole(ROLE_OWNER);
        _;
    }

    // allows execution only by an manager
    modifier onlyManager {
        _hasRole(ROLE_MANAGER);
        _;
    }

    // allows execution only by a seeder
    modifier onlySeeder {
        _hasRole(ROLE_SEEDER);
        _;
    }

    // error message binary size optimization
    function _hasRole(bytes32 role) internal view {
        require(hasRole(role, msg.sender), "ERR_ACCESS_DENIED");
    }

    /**
     * @dev returns whether the specified pool is participating in the rewards program
     *
     * @param poolToken the pool token representing the rewards pool
     *
     * @return whether the specified pool is participating in the rewards program
     */
    function isPoolParticipating(IDSToken poolToken) public view override returns (bool) {
        PoolProgram memory program = _programs[poolToken];

        return program.endTime > time();
    }

    /**
     * @dev returns whether the specified reserve is participating in the rewards program
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token of the added liquidity
     *
     * @return whether the specified reserve is participating in the rewards program
     */
    function isReserveParticipating(IDSToken poolToken, IERC20 reserveToken) public view override returns (bool) {
        if (!isPoolParticipating(poolToken)) {
            return false;
        }

        PoolProgram memory program = _programs[poolToken];

        return program.reserveTokens[0] == reserveToken || program.reserveTokens[1] == reserveToken;
    }

    /**
     * @dev adds a program
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveTokens the reserve tokens representing the liquidity in the pool
     * @param rewardShares reserve reward shares
     * @param endTime the ending time of the program
     * @param rewardRate the program's rewards rate per-second
     */
    function addPoolProgram(
        IDSToken poolToken,
        IERC20[2] calldata reserveTokens,
        uint32[2] calldata rewardShares,
        uint256 endTime,
        uint256 rewardRate
    ) external override onlyManager validAddress(address(poolToken)) {
        uint256 currentTime = time();

        addPoolProgram(poolToken, reserveTokens, rewardShares, currentTime, endTime, rewardRate);

        emit PoolProgramAdded(poolToken, currentTime, endTime, rewardRate);
    }

    /**
     * @dev adds past programs
     *
     * @param poolTokens pool tokens representing the rewards pool
     * @param reserveTokens reserve tokens representing the liquidity in the pool
     * @param rewardShares reserve reward shares
     * @param startTime starting times of the program
     * @param endTimes ending times of the program
     * @param rewardRates program's rewards rate per-second
     */
    function addPastPoolPrograms(
        IDSToken[] calldata poolTokens,
        IERC20[2][] calldata reserveTokens,
        uint32[2][] calldata rewardShares,
        uint256[] calldata startTime,
        uint256[] calldata endTimes,
        uint256[] calldata rewardRates
    ) external onlySeeder {
        uint256 length = poolTokens.length;
        require(
            length == reserveTokens.length &&
                length == rewardShares.length &&
                length == startTime.length &&
                length == endTimes.length &&
                length == rewardRates.length,
            "ERR_INVALID_LENGTH"
        );

        for (uint256 i = 0; i < length; ++i) {
            addPastPoolProgram(
                poolTokens[i],
                reserveTokens[i],
                rewardShares[i],
                startTime[i],
                endTimes[i],
                rewardRates[i]
            );
        }
    }

    /**
     * @dev adds a past program
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveTokens the reserve tokens representing the liquidity in the pool
     * @param rewardShares reserve reward shares
     * @param startTime the starting time of the program
     * @param endTime the ending time of the program
     * @param rewardRate the program's rewards rate per-second
     */
    function addPastPoolProgram(
        IDSToken poolToken,
        IERC20[2] calldata reserveTokens,
        uint32[2] calldata rewardShares,
        uint256 startTime,
        uint256 endTime,
        uint256 rewardRate
    ) private validAddress(address(poolToken)) {
        require(startTime < time(), "ERR_INVALID_TIME");

        addPoolProgram(poolToken, reserveTokens, rewardShares, startTime, endTime, rewardRate);
    }

    /**
     * @dev adds a program
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveTokens the reserve tokens representing the liquidity in the pool
     * @param rewardShares reserve reward shares
     * @param endTime the ending time of the program
     * @param rewardRate the program's rewards rate per-second
     */
    function addPoolProgram(
        IDSToken poolToken,
        IERC20[2] calldata reserveTokens,
        uint32[2] calldata rewardShares,
        uint256 startTime,
        uint256 endTime,
        uint256 rewardRate
    ) private {
        require(startTime < endTime && endTime > time(), "ERR_INVALID_DURATION");
        require(rewardRate > 0, "ERR_ZERO_VALUE");
        require(rewardRate <= MAX_REWARD_RATE, "ERR_REWARD_RATE_TOO_HIGH");
        require(rewardShares[0].add(rewardShares[1]) == PPM_RESOLUTION, "ERR_INVALID_REWARD_SHARES");

        require(_pools.add(address(poolToken)), "ERR_ALREADY_PARTICIPATING");

        PoolProgram storage program = _programs[poolToken];
        program.startTime = startTime;
        program.endTime = endTime;
        program.rewardRate = rewardRate;
        program.rewardShares = rewardShares;

        // verify that reserve tokens correspond to the pool.
        IConverter converter = IConverter(payable(IConverterAnchor(poolToken).owner()));
        uint256 length = converter.connectorTokenCount();
        require(length == 2, "ERR_POOL_NOT_SUPPORTED");

        require(
            (address(converter.connectorTokens(0)) == address(reserveTokens[0]) &&
                address(converter.connectorTokens(1)) == address(reserveTokens[1])) ||
                (address(converter.connectorTokens(0)) == address(reserveTokens[1]) &&
                    address(converter.connectorTokens(1)) == address(reserveTokens[0])),
            "ERR_INVALID_RESERVE_TOKENS"
        );
        program.reserveTokens = reserveTokens;
    }

    /**
     * @dev removes a program
     *
     * @param poolToken the pool token representing the rewards pool
     */
    function removePoolProgram(IDSToken poolToken) external override onlyManager {
        require(_pools.remove(address(poolToken)), "ERR_POOL_NOT_PARTICIPATING");

        delete _programs[poolToken];

        emit PoolProgramRemoved(poolToken);
    }

    /**
     * @dev updates the ending time of a program
     * note that the new ending time must be in the future
     *
     * @param poolToken the pool token representing the rewards pool
     * @param newEndTime the new ending time of the program
     */
    function setPoolProgramEndTime(IDSToken poolToken, uint256 newEndTime) external override onlyManager {
        require(isPoolParticipating(poolToken), "ERR_POOL_NOT_PARTICIPATING");

        PoolProgram storage program = _programs[poolToken];
        require(newEndTime > time(), "ERR_INVALID_DURATION");

        program.endTime = newEndTime;
    }

    /**
     * @dev returns a program
     *
     * @return the program's starting and ending times
     */
    function poolProgram(IDSToken poolToken)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            IERC20[2] memory,
            uint32[2] memory
        )
    {
        PoolProgram memory program = _programs[poolToken];

        return (program.startTime, program.endTime, program.rewardRate, program.reserveTokens, program.rewardShares);
    }

    /**
     * @dev returns all programs
     *
     * @return all programs
     */
    function poolPrograms()
        external
        view
        override
        returns (
            IDSToken[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            IERC20[2][] memory,
            uint32[2][] memory
        )
    {
        uint256 length = _pools.length();

        IDSToken[] memory poolTokens = new IDSToken[](length);
        uint256[] memory startTimes = new uint256[](length);
        uint256[] memory endTimes = new uint256[](length);
        uint256[] memory rewardRates = new uint256[](length);
        IERC20[2][] memory reserveTokens = new IERC20[2][](length);
        uint32[2][] memory rewardShares = new uint32[2][](length);

        for (uint256 i = 0; i < length; ++i) {
            IDSToken poolToken = IDSToken(_pools.at(i));
            PoolProgram memory program = _programs[poolToken];

            poolTokens[i] = poolToken;
            startTimes[i] = program.startTime;
            endTimes[i] = program.endTime;
            rewardRates[i] = program.rewardRate;
            reserveTokens[i] = program.reserveTokens;
            rewardShares[i] = program.rewardShares;
        }

        return (poolTokens, startTimes, endTimes, rewardRates, reserveTokens, rewardShares);
    }

    /**
     * @dev returns the rewards data of a specific reserve in a specific pool
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token in the rewards pool
     *
     * @return rewards data
     */
    function poolRewards(IDSToken poolToken, IERC20 reserveToken)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        PoolRewards memory data = _poolRewards[poolToken][reserveToken];

        return (data.lastUpdateTime, data.rewardPerToken, data.totalClaimedRewards);
    }

    /**
     * @dev updates the reward data of a specific reserve in a specific pool
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token in the rewards pool
     * @param lastUpdateTime the last update time
     * @param rewardPerToken the new reward rate per-token
     * @param totalClaimedRewards the total claimed rewards up until now
     */
    function updatePoolRewardsData(
        IDSToken poolToken,
        IERC20 reserveToken,
        uint256 lastUpdateTime,
        uint256 rewardPerToken,
        uint256 totalClaimedRewards
    ) external override onlyOwner {
        PoolRewards storage data = _poolRewards[poolToken][reserveToken];
        data.lastUpdateTime = lastUpdateTime;
        data.rewardPerToken = rewardPerToken;
        data.totalClaimedRewards = totalClaimedRewards;
    }

    /**
     * @dev seeds pool rewards data for multiple pools
     *
     * @param poolTokens pool tokens representing the rewards pool
     * @param reserveTokens reserve tokens representing the liquidity in the pool
     * @param lastUpdateTimes last update times (for both the network and reserve tokens)
     * @param rewardsPerToken reward rates per-token (for both the network and reserve tokens)
     * @param totalClaimedRewards total claimed rewards up until now (for both the network and reserve tokens)
     */
    function setPoolsRewardData(
        IDSToken[] calldata poolTokens,
        IERC20[] calldata reserveTokens,
        uint256[] calldata lastUpdateTimes,
        uint256[] calldata rewardsPerToken,
        uint256[] calldata totalClaimedRewards
    ) external onlySeeder {
        uint256 length = poolTokens.length;
        require(
            length == reserveTokens.length &&
                length == lastUpdateTimes.length &&
                length == rewardsPerToken.length &&
                length == totalClaimedRewards.length,
            "ERR_INVALID_LENGTH"
        );

        for (uint256 i = 0; i < length; ++i) {
            IDSToken poolToken = poolTokens[i];
            _validAddress(address(poolToken));

            IERC20 reserveToken = reserveTokens[i];
            _validAddress(address(reserveToken));

            PoolRewards storage data = _poolRewards[poolToken][reserveToken];
            data.lastUpdateTime = lastUpdateTimes[i];
            data.rewardPerToken = rewardsPerToken[i];
            data.totalClaimedRewards = totalClaimedRewards[i];
        }
    }

    /**
     * @dev returns rewards data of a specific provider
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token in the rewards pool
     *
     * @return rewards data
     */
    function providerRewards(
        address provider,
        IDSToken poolToken,
        IERC20 reserveToken
    )
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint32
        )
    {
        ProviderRewards memory data = _providerRewards[provider][poolToken][reserveToken];

        return (
            data.rewardPerToken,
            data.pendingBaseRewards,
            data.totalClaimedRewards,
            data.effectiveStakingTime,
            data.baseRewardsDebt,
            data.baseRewardsDebtMultiplier
        );
    }

    /**
     * @dev updates provider rewards data
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token in the rewards pool
     * @param rewardPerToken the new reward rate per-token
     * @param pendingBaseRewards the updated pending base rewards
     * @param totalClaimedRewards the total claimed rewards up until now
     * @param effectiveStakingTime the new effective staking time
     * @param baseRewardsDebt the updated base rewards debt
     * @param baseRewardsDebtMultiplier the updated base rewards debt multiplier
     */
    function updateProviderRewardsData(
        address provider,
        IDSToken poolToken,
        IERC20 reserveToken,
        uint256 rewardPerToken,
        uint256 pendingBaseRewards,
        uint256 totalClaimedRewards,
        uint256 effectiveStakingTime,
        uint256 baseRewardsDebt,
        uint32 baseRewardsDebtMultiplier
    ) external override onlyOwner {
        ProviderRewards storage data = _providerRewards[provider][poolToken][reserveToken];

        data.rewardPerToken = rewardPerToken;
        data.pendingBaseRewards = pendingBaseRewards;
        data.totalClaimedRewards = totalClaimedRewards;
        data.effectiveStakingTime = effectiveStakingTime;
        data.baseRewardsDebt = baseRewardsDebt;
        data.baseRewardsDebtMultiplier = baseRewardsDebtMultiplier;
    }

    /**
     * @dev seeds specific provider's reward data for multiple providers
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token in the rewards pool
     * @param providers owners of the liquidity
     * @param rewardsPerToken new reward rates per-token
     * @param pendingBaseRewards updated pending base rewards
     * @param totalClaimedRewards total claimed rewards up until now
     * @param effectiveStakingTimes new effective staking times
     * @param baseRewardsDebts updated base rewards debts
     * @param baseRewardsDebtMultipliers updated base rewards debt multipliers
     */
    function setProviderRewardData(
        IDSToken poolToken,
        IERC20 reserveToken,
        address[] memory providers,
        uint256[] memory rewardsPerToken,
        uint256[] memory pendingBaseRewards,
        uint256[] memory totalClaimedRewards,
        uint256[] memory effectiveStakingTimes,
        uint256[] memory baseRewardsDebts,
        uint32[] memory baseRewardsDebtMultipliers
    ) external onlySeeder validAddress(address(poolToken)) validAddress(address(reserveToken)) {
        uint256 length = providers.length;
        require(
            length == rewardsPerToken.length &&
                length == pendingBaseRewards.length &&
                length == totalClaimedRewards.length &&
                length == effectiveStakingTimes.length &&
                length == baseRewardsDebts.length &&
                length == baseRewardsDebtMultipliers.length,
            "ERR_INVALID_LENGTH"
        );

        for (uint256 i = 0; i < length; ++i) {
            ProviderRewards storage data = _providerRewards[providers[i]][poolToken][reserveToken];

            uint256 baseRewardsDebt = baseRewardsDebts[i];
            uint32 baseRewardsDebtMultiplier = baseRewardsDebtMultipliers[i];
            require(
                baseRewardsDebt == 0 ||
                    (baseRewardsDebtMultiplier >= PPM_RESOLUTION && baseRewardsDebtMultiplier <= 2 * PPM_RESOLUTION),
                "ERR_INVALID_MULTIPLIER"
            );

            data.rewardPerToken = rewardsPerToken[i];
            data.pendingBaseRewards = pendingBaseRewards[i];
            data.totalClaimedRewards = totalClaimedRewards[i];
            data.effectiveStakingTime = effectiveStakingTimes[i];
            data.baseRewardsDebt = baseRewardsDebts[i];
            data.baseRewardsDebtMultiplier = baseRewardsDebtMultiplier;
        }
    }

    /**
     * @dev updates provider's last claim time
     *
     * @param provider the owner of the liquidity
     */
    function updateProviderLastClaimTime(address provider) external override onlyOwner {
        uint256 time = time();
        _providerLastClaimTimes[provider] = time;

        emit ProviderLastClaimTimeUpdated(provider, time);
    }

    /**
     * @dev returns provider's last claim time
     *
     * @param provider the owner of the liquidity
     *
     * @return provider's last claim time
     */
    function providerLastClaimTime(address provider) external view override returns (uint256) {
        return _providerLastClaimTimes[provider];
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IConverterAnchor.sol";
import "../../utility/interfaces/IOwned.sol";

/*
    Converter interface
*/
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);

    function anchor() external view returns (IConverterAnchor);

    function isActive() external view returns (bool);

    function targetAmountAndFee(
        IERC20 _sourceToken,
        IERC20 _targetToken,
        uint256 _amount
    ) external view returns (uint256, uint256);

    function convert(
        IERC20 _sourceToken,
        IERC20 _targetToken,
        uint256 _amount,
        address _trader,
        address payable _beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IERC20 _reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 _conversionFee) external;

    function withdrawTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    function withdrawETH(address payable _to) external;

    function addReserve(IERC20 _token, uint32 _ratio) external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address _newOwner) external;

    function acceptTokenOwnership() external;

    function connectors(IERC20 _address)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IERC20 _connectorToken) external view returns (uint256);

    function connectorTokens(uint256 _index) external view returns (IERC20);

    function connectorTokenCount() external view returns (uint16);

    /**
     * @dev triggered when the converter is activated
     *
     * @param _type        converter type
     * @param _anchor      converter anchor
     * @param _activated   true if the converter was activated, false if it was deactivated
     */
    event Activation(uint16 indexed _type, IConverterAnchor indexed _anchor, bool indexed _activated);

    /**
     * @dev triggered when a conversion between two tokens occurs
     *
     * @param _fromToken       source ERC20 token
     * @param _toToken         target ERC20 token
     * @param _trader          wallet that initiated the trade
     * @param _amount          input amount in units of the source token
     * @param _return          output amount minus conversion fee in units of the target token
     * @param _conversionFee   conversion fee in units of the target token
     */
    event Conversion(
        IERC20 indexed _fromToken,
        IERC20 indexed _toToken,
        address indexed _trader,
        uint256 _amount,
        uint256 _return,
        int256 _conversionFee
    );

    /**
     * @dev triggered when the rate between two tokens in the converter changes
     * note that the event might be dispatched for rate updates between any two tokens in the converter
     *
     * @param  _token1 address of the first token
     * @param  _token2 address of the second token
     * @param  _rateN  rate of 1 unit of `_token1` in `_token2` (numerator)
     * @param  _rateD  rate of 1 unit of `_token1` in `_token2` (denominator)
     */
    event TokenRateUpdate(IERC20 indexed _token1, IERC20 indexed _token2, uint256 _rateN, uint256 _rateD);

    /**
     * @dev triggered when the conversion fee is updated
     *
     * @param  _prevFee    previous fee percentage, represented in ppm
     * @param  _newFee     new fee percentage, represented in ppm
     */
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;
import "../../utility/interfaces/IOwned.sol";

/*
    Converter Anchor interface
*/
interface IConverterAnchor is IOwned {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../converter/interfaces/IConverterAnchor.sol";
import "../../utility/interfaces/IOwned.sol";

/*
    DSToken interface
*/
interface IDSToken is IConverterAnchor, IERC20 {
    function issue(address _to, uint256 _amount) external;

    function destroy(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    Time implementing contract
*/
contract Time {
    /**
     * @dev returns the current time
     */
    function time() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address _address) {
        _validExternalAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address _address) internal view {
        require(_address != address(0) && _address != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}