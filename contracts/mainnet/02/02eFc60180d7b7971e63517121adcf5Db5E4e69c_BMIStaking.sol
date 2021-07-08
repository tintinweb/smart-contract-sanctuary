// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IBMIStaking.sol";
import "./interfaces/tokens/ISTKBMIToken.sol";
import "./interfaces/ILiquidityMining.sol";

import "./interfaces/tokens/erc20permit-upgradeable/IERC20PermitUpgradeable.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract BMIStaking is IBMIStaking, OwnableUpgradeable, AbstractDependant {
    using SafeMath for uint256;

    IERC20 public bmiToken;
    ISTKBMIToken public stkBMIToken;
    uint256 public lastUpdateBlock;
    uint256 public rewardPerBlock;
    uint256 public totalPool;

    address public legacyBMIStakingAddress;
    ILiquidityMining public liquidityMining;
    address public bmiCoverStakingAddress;
    address public liquidityMiningStakingAddress;

    mapping(address => WithdrawalInfo) private withdrawalsInfo;

    uint256 internal constant WITHDRAWING_LOCKUP_DURATION = 90 days;
    uint256 internal constant WITHDRAWING_COOLDOWN_DURATION = 8 days;
    uint256 internal constant WITHDRAWAL_PHASE_DURATION = 2 days;

    modifier updateRewardPool() {
        _updateRewardPool();
        _;
    }

    modifier onlyStaking() {
        require(
            _msgSender() == bmiCoverStakingAddress ||
                _msgSender() == liquidityMiningStakingAddress ||
                _msgSender() == legacyBMIStakingAddress,
            "BMIStaking: Not a staking contract"
        );
        _;
    }

    function __BMIStaking_init(uint256 _rewardPerBlock) external initializer {
        __Ownable_init();

        lastUpdateBlock = block.number;
        rewardPerBlock = _rewardPerBlock;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        legacyBMIStakingAddress = _contractsRegistry.getLegacyBMIStakingContract();
        bmiToken = IERC20(_contractsRegistry.getBMIContract());
        stkBMIToken = ISTKBMIToken(_contractsRegistry.getSTKBMIContract());
        liquidityMining = ILiquidityMining(_contractsRegistry.getLiquidityMiningContract());
        bmiCoverStakingAddress = _contractsRegistry.getBMICoverStakingContract();
        liquidityMiningStakingAddress = _contractsRegistry.getLiquidityMiningStakingContract();
    }

    function stakeWithPermit(
        uint256 _amountBMI,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        IERC20PermitUpgradeable(address(bmiToken)).permit(
            _msgSender(),
            address(this),
            _amountBMI,
            MAX_INT,
            _v,
            _r,
            _s
        );

        bmiToken.transferFrom(_msgSender(), address(this), _amountBMI);
        _stake(_msgSender(), _amountBMI);
    }

    function stakeFor(address _user, uint256 _amountBMI) external override onlyStaking {
        require(_amountBMI > 0, "BMIStaking: can't stake 0 tokens");

        _stake(_user, _amountBMI);
    }

    function stake(uint256 _amountBMI) external override {
        require(_amountBMI > 0, "BMIStaking: can't stake 0 tokens");

        bmiToken.transferFrom(_msgSender(), address(this), _amountBMI);
        _stake(_msgSender(), _amountBMI);
    }

    /// @notice checks when the unlockPeriod expires (90 days)
    /// @return exact timestamp of the unlock time or 0 if LME is not started or unlock period is reached
    function maturityAt() external view override returns (uint256) {
        uint256 maturityDate =
            liquidityMining.startLiquidityMiningTime().add(WITHDRAWING_LOCKUP_DURATION);

        return maturityDate < block.timestamp ? 0 : maturityDate;
    }

    // It is unlocked after 90 days
    function isBMIRewardUnlocked() public view override returns (bool) {
        uint256 liquidityMiningStartTime = liquidityMining.startLiquidityMiningTime();

        return
            liquidityMiningStartTime == 0 ||
            liquidityMiningStartTime.add(WITHDRAWING_LOCKUP_DURATION) <= block.timestamp;
    }

    // There is a second withdrawal phase of 48 hours to actually receive the rewards.
    // If a user misses this period, in order to withdraw he has to wait for 10 days again.
    // It will return:
    // 0 if cooldown time didn't start or if phase duration (48hs) has expired
    // #coolDownTimeEnd Time when user can withdraw.
    function whenCanWithdrawBMIReward(address _address) public view override returns (uint256) {
        return
            withdrawalsInfo[_address].coolDownTimeEnd.add(WITHDRAWAL_PHASE_DURATION) >=
                block.timestamp
                ? withdrawalsInfo[_address].coolDownTimeEnd
                : 0;
    }

    /*
     * Before a withdraw, it is needed to wait 90 days after LiquidityMining started.
     * And after 90 days, user can request to withdraw and wait 10 days.
     * After 10 days, user can withdraw, but user has 48hs to withdraw. After 48hs,
     * user will need to request to withdraw again and wait for more 10 days before
     * being able to withdraw.
     */
    function unlockTokensToWithdraw(uint256 _amountBMIUnlock) external override {
        require(_amountBMIUnlock > 0, "BMIStaking: can't unlock 0 tokens");
        require(isBMIRewardUnlocked(), "BMIStaking: lock up time didn't end");

        uint256 _amountStkBMIUnlock = _convertToStkBMI(_amountBMIUnlock);
        require(
            stkBMIToken.balanceOf(_msgSender()) >= _amountStkBMIUnlock,
            "BMIStaking: not enough BMI to unlock"
        );

        withdrawalsInfo[_msgSender()] = WithdrawalInfo(
            block.timestamp.add(WITHDRAWING_COOLDOWN_DURATION),
            _amountBMIUnlock
        );
    }

    // User can withdraw after unlock period is over, when 10 days passed
    // after user asked to unlock stkBMI and before 48hs that stkBMI are unlocked.
    function withdraw() external override updateRewardPool {
        //it will revert (equal to 0) here if passed 48hs after unlock period, if
        //lockup period didn't start or didn't passed 90 days or if unlock didn't start
        uint256 _whenCanWithdrawBMIReward = whenCanWithdrawBMIReward(_msgSender());
        require(_whenCanWithdrawBMIReward != 0, "BMIStaking: unlock not started/exp");
        require(_whenCanWithdrawBMIReward <= block.timestamp, "BMIStaking: cooldown not reached");

        uint256 amountBMI = withdrawalsInfo[_msgSender()].amountBMIRequested;
        delete withdrawalsInfo[_msgSender()];

        require(bmiToken.balanceOf(address(this)) >= amountBMI, "BMIStaking: !enough BMI tokens");

        uint256 _amountStkBMI = _convertToStkBMI(amountBMI);

        require(
            stkBMIToken.balanceOf(_msgSender()) >= _amountStkBMI,
            "BMIStaking: !enough stkBMI to withdraw"
        );

        stkBMIToken.burn(_msgSender(), _amountStkBMI);

        totalPool = totalPool.sub(amountBMI);

        bmiToken.transfer(_msgSender(), amountBMI);

        emit BMIWithdrawn(amountBMI, _amountStkBMI, _msgSender());
    }

    /// @notice Getting withdraw information
    /// @return _amountBMIRequested is amount of bmi tokens requested to unlock
    /// @return _amountStkBMI is amount of stkBMI that will burn
    /// @return _unlockPeriod is its timestamp when user can withdraw
    ///         returns 0 if it didn't unlocked yet. User has 48hs to withdraw
    /// @return _availableFor is the end date if withdraw period has already begun
    ///         or 0 if it is expired or didn't start
    function getWithdrawalInfo(address _userAddr)
        external
        view
        override
        returns (
            uint256 _amountBMIRequested,
            uint256 _amountStkBMI,
            uint256 _unlockPeriod,
            uint256 _availableFor
        )
    {
        // if whenCanWithdrawBMIReward() returns >0 it was unlocked
        // or is not expired
        _unlockPeriod = whenCanWithdrawBMIReward(_userAddr);

        if (_unlockPeriod > 0) {
            _amountBMIRequested = withdrawalsInfo[_userAddr].amountBMIRequested;
            _amountStkBMI = _convertToStkBMI(_amountBMIRequested);

            uint256 endUnlockPeriod = _unlockPeriod.add(WITHDRAWAL_PHASE_DURATION);
            _availableFor = _unlockPeriod <= block.timestamp ? endUnlockPeriod : 0;
        }
    }

    function addToPool(uint256 _amount) external override onlyStaking updateRewardPool {
        totalPool = totalPool.add(_amount);
    }

    function stakingReward(uint256 _amount) external view override returns (uint256) {
        return _convertToBMI(_amount);
    }

    function getStakedBMI(address _address) external view override returns (uint256) {
        uint256 balance = stkBMIToken.balanceOf(_address);
        return balance > 0 ? _convertToBMI(balance) : 0;
    }

    /// @notice returns APY% with 10**5 precision
    function getAPY() external view override returns (uint256) {
        return rewardPerBlock.mul(BLOCKS_PER_YEAR.mul(10**7)).div(totalPool.add(APY_TOKENS));
    }

    function setRewardPerBlock(uint256 _amount) external override onlyOwner updateRewardPool {
        rewardPerBlock = _amount;
    }

    function revokeUnusedRewardPool() external override onlyOwner updateRewardPool {
        uint256 contractBalance = bmiToken.balanceOf(address(this));

        require(contractBalance > totalPool, "BMIStaking: No unused tokens revoke");

        uint256 unusedTokens = contractBalance.sub(totalPool);

        bmiToken.transfer(_msgSender(), unusedTokens);
        emit UnusedRewardPoolRevoked(_msgSender(), unusedTokens);
    }

    function _updateRewardPool() internal {
        if (totalPool == 0) {
            lastUpdateBlock = block.number;
        }

        totalPool = totalPool.add(_calculateReward());
        lastUpdateBlock = block.number;
    }

    function _stake(address _staker, uint256 _amountBMI) internal updateRewardPool {
        uint256 amountStkBMI = _convertToStkBMI(_amountBMI);
        stkBMIToken.mint(_staker, amountStkBMI);

        totalPool = totalPool.add(_amountBMI);

        emit StakedBMI(_amountBMI, amountStkBMI, _staker);
    }

    function _convertToStkBMI(uint256 _amount) internal view returns (uint256) {
        uint256 stkBMITokenTS = stkBMIToken.totalSupply();
        uint256 stakingPool = totalPool.add(_calculateReward());

        if (stakingPool > 0 && stkBMITokenTS > 0) {
            _amount = stkBMITokenTS.mul(_amount).div(stakingPool);
        }

        return _amount;
    }

    function _convertToBMI(uint256 _amount) internal view returns (uint256) {
        uint256 stkBMITokenTS = stkBMIToken.totalSupply();
        uint256 stakingPool = totalPool.add(_calculateReward());

        return stkBMITokenTS > 0 ? stakingPool.mul(_amount).div(stkBMITokenTS) : 0;
    }

    function _calculateReward() internal view returns (uint256) {
        uint256 blocksPassed = block.number.sub(lastUpdateBlock);
        return rewardPerBlock.mul(blocksPassed);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS18 = 10**18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant APY_TOKENS = DECIMALS18;

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "../interfaces/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(IContractsRegistry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./tokens/ISTKBMIToken.sol";

interface IBMIStaking {
    event StakedBMI(uint256 stakedBMI, uint256 mintedStkBMI, address indexed recipient);
    event BMIWithdrawn(uint256 amountBMI, uint256 burnedStkBMI, address indexed recipient);

    event UnusedRewardPoolRevoked(address recipient, uint256 amount);

    struct WithdrawalInfo {
        uint256 coolDownTimeEnd;
        uint256 amountBMIRequested;
    }

    function stakeWithPermit(
        uint256 _amountBMI,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function stakeFor(address _user, uint256 _amountBMI) external;

    function stake(uint256 _amountBMI) external;

    function maturityAt() external view returns (uint256);

    function isBMIRewardUnlocked() external view returns (bool);

    function whenCanWithdrawBMIReward(address _address) external view returns (uint256);

    function unlockTokensToWithdraw(uint256 _amountBMIUnlock) external;

    function withdraw() external;

    /// @notice Getting withdraw information
    /// @return _amountBMIRequested is amount of bmi tokens requested to unlock
    /// @return _amountStkBMI is amount of stkBMI that will burn
    /// @return _unlockPeriod is its timestamp when user can withdraw
    ///         returns 0 if it didn't unlocked yet. User has 48hs to withdraw
    /// @return _availableFor is the end date if withdraw period has already begun
    ///         or 0 if it is expired or didn't start
    function getWithdrawalInfo(address _userAddr)
        external
        view
        returns (
            uint256 _amountBMIRequested,
            uint256 _amountStkBMI,
            uint256 _unlockPeriod,
            uint256 _availableFor
        );

    function addToPool(uint256 _amount) external;

    function stakingReward(uint256 _amount) external view returns (uint256);

    function getStakedBMI(address _address) external view returns (uint256);

    function getAPY() external view returns (uint256);

    function setRewardPerBlock(uint256 _amount) external;

    function revokeUnusedRewardPool() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IContractsRegistry {
    function getUniswapRouterContract() external view returns (address);

    function getUniswapBMIToETHPairContract() external view returns (address);

    function getWETHContract() external view returns (address);

    function getUSDTContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMICoverStakingContract() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getBMIUtilityNFTContract() external view returns (address);

    function getLiquidityMiningContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getReinsurancePoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getLegacyBMIStakingContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getVBMIContract() external view returns (address);

    function getLegacyLiquidityMiningStakingContract() external view returns (address);

    function getLiquidityMiningStakingContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface ILiquidityMining {
    struct TeamDetails {
        string teamName;
        address referralLink;
        uint256 membersNumber;
        uint256 totalStakedAmount;
        uint256 totalReward;
    }

    struct UserInfo {
        address userAddr;
        string teamName;
        uint256 stakedAmount;
        uint256 mainNFT; // 0 or NFT index if available
        uint256 platinumNFT; // 0 or NFT index if available
    }

    struct UserRewardsInfo {
        string teamName;
        uint256 totalBMIReward; // total BMI reward
        uint256 availableBMIReward; // current claimable BMI reward
        uint256 incomingPeriods; // how many month are incoming
        uint256 timeToNextDistribution; // exact time left to next distribution
        uint256 claimedBMI; // actual number of claimed BMI
        uint256 mainNFTAvailability; // 0 or NFT index if available
        uint256 platinumNFTAvailability; // 0 or NFT index if available
        bool claimedNFTs; // true if user claimed NFTs
    }

    struct MyTeamInfo {
        TeamDetails teamDetails;
        uint256 myStakedAmount;
        uint256 teamPlace;
    }

    struct UserTeamInfo {
        address teamAddr;
        uint256 stakedAmount;
        uint256 countOfRewardedMonth;
        bool isNFTDistributed;
    }

    struct TeamInfo {
        string name;
        uint256 totalAmount;
        address[] teamLeaders;
    }

    function startLiquidityMiningTime() external view returns (uint256);

    function getTopTeams() external view returns (TeamDetails[] memory teams);

    function getTopUsers() external view returns (UserInfo[] memory users);

    function getAllTeamsLength() external view returns (uint256);

    function getAllTeamsDetails(uint256 _offset, uint256 _limit)
        external
        view
        returns (TeamDetails[] memory _teamDetailsArr);

    function getMyTeamsLength() external view returns (uint256);

    function getMyTeamMembers(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory _teamMembers, uint256[] memory _memberStakedAmount);

    function getAllUsersLength() external view returns (uint256);

    function getAllUsersInfo(uint256 _offset, uint256 _limit)
        external
        view
        returns (UserInfo[] memory _userInfos);

    function getMyTeamInfo() external view returns (MyTeamInfo memory _myTeamInfo);

    function getRewardsInfo(address user)
        external
        view
        returns (UserRewardsInfo memory userRewardInfo);

    function createTeam(string calldata _teamName) external;

    function deleteTeam() external;

    function joinTheTeam(address _referralLink) external;

    function getSlashingPercentage() external view returns (uint256);

    function investSTBL(uint256 _tokensAmount, address _policyBookAddr) external;

    function distributeNFT() external;

    function checkPlatinumNFTReward(address _userAddr) external view returns (uint256);

    function checkMainNFTReward(address _userAddr) external view returns (uint256);

    function distributeBMIReward() external;

    function getTotalUserBMIReward(address _userAddr) external view returns (uint256);

    function checkAvailableBMIReward(address _userAddr) external view returns (uint256);

    /// @notice checks if liquidity mining event is lasting (startLiquidityMining() has been called)
    /// @return true if LM is started and not ended, false otherwise
    function isLMLasting() external view returns (bool);

    /// @notice checks if liquidity mining event is finished. In order to be finished, it has to be started
    /// @return true if LM is finished, false if event is still going or not started
    function isLMEnded() external view returns (bool);

    function getEndLMTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ISTKBMIToken is IERC20Upgradeable {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tree/release-v3.4/contracts/drafts
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
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