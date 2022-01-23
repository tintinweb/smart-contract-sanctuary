// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./abstract/AbstractDependant.sol";
import "./interfaces/IBMICoverStaking.sol";
import "./interfaces/IBMIStaking.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/ILiquidityBridge.sol";
import "./interfaces/IPolicyBook.sol";
import "./interfaces/IPolicyRegistry.sol";
import "./interfaces/IV2BMIStaking.sol";
import "./interfaces/IV2ContractsRegistry.sol";
import "./interfaces/IV2PolicyBook.sol";
import "./interfaces/IV2PolicyBookFacade.sol";
import "./interfaces/tokens/ISTKBMIToken.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./interfaces/IPolicyBookRegistry.sol";

import "./libraries/DecimalsConverter.sol";

contract LiquidityBridge is ILiquidityBridge, OwnableUpgradeable, AbstractDependant {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using Math for uint256;

    address public v1bmiStakingAddress;
    address public v2bmiStakingAddress;
    address public v1bmiCoverStakingAddress;
    address public v2bmiCoverStakingAddress;
    address public v1policyBookFabricAddress;
    address public v2contractsRegistryAddress;
    address public v1contractsRegistryAddress;
    address public v1policyRegistryAddress;
    address public v1policyBookRegistryAddress;
    address public v2policyBoo2RegistryAddress;

    address public admin;

    uint256 public counter;
    uint256 public stblDecimals;

    IERC20 public bmiToken;
    ERC20 public stblToken;

    // Policybook => user
    mapping(address => mapping(address => bool)) public migrateAddLiquidity;
    mapping(address => mapping(address => bool)) public migratedCoverStaking;
    mapping(address => address) public upgradedPolicies;
    mapping(address => uint256) public extractedLiquidity;

    event MigrationAllowanceSetUp(address policybook, uint256 newAllowance);
    event LiquidityCollected(address v1PolicyBook, address v2PolicyBook, uint256 amount);
    event LiquidityMigrated(uint256 migratedCount, address poolAddress, address userAddress);
    event SkippedRequest(uint256 reason, address poolAddress, address userAddress);
    event MigratedAddedLiquidity(address pool, address user, uint256 tetherAmount);

    function __LiquidityBridge_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry) external override {
        v1contractsRegistryAddress = 0x8050c5a46FC224E3BCfa5D7B7cBacB1e4010118d;
        v2contractsRegistryAddress = 0x45269F7e69EE636067835e0DfDd597214A1de6ea;

        require(
            msg.sender == v1contractsRegistryAddress || msg.sender == v2contractsRegistryAddress,
            "Dependant: Not an injector"
        );

        IContractsRegistry _v1contractsRegistry = IContractsRegistry(v1contractsRegistryAddress);
        IV2ContractsRegistry _v2contractsRegistry =
            IV2ContractsRegistry(v2contractsRegistryAddress);

        v1bmiStakingAddress = _v1contractsRegistry.getBMIStakingContract();
        v2bmiStakingAddress = _v2contractsRegistry.getBMIStakingContract();

        v1bmiCoverStakingAddress = _v1contractsRegistry.getBMICoverStakingContract();
        v2bmiCoverStakingAddress = _v2contractsRegistry.getBMICoverStakingContract();

        v1policyBookFabricAddress = _v1contractsRegistry.getPolicyBookFabricContract();

        v1policyRegistryAddress = _v1contractsRegistry.getPolicyRegistryContract();

        v1policyBookRegistryAddress = _v1contractsRegistry.getPolicyBookRegistryContract();
        v2policyBoo2RegistryAddress = _v2contractsRegistry.getPolicyBookRegistryContract();

        bmiToken = IERC20(_v1contractsRegistry.getBMIContract());
        stblToken = ERC20(_contractsRegistry.getUSDTContract());

        stblDecimals = stblToken.decimals();
    }

    modifier onlyAdmins() {
        require(_msgSender() == admin || _msgSender() == owner(), "not in admins");
        _;
    }

    function checkBalances(bool checkLiquidityBridge)
        external
        view
        returns (
            address[] memory policyBooksV1,
            uint256[] memory balanceV1,
            address[] memory policyBooksV2,
            uint256[] memory balanceV2
        )
    {
        address[] memory policyBooks =
            IPolicyBookRegistry(v1policyBookRegistryAddress).list(0, 33);

        policyBooksV1 = new address[](policyBooks.length);
        policyBooksV2 = new address[](policyBooks.length);
        balanceV1 = new uint256[](policyBooks.length);
        balanceV2 = new uint256[](policyBooks.length);

        for (uint256 i = 0; i < policyBooks.length; i++) {
            if (policyBooks[i] == address(0)) {
                break;
            }

            policyBooksV1[i] = policyBooks[i];
            balanceV1[i] = stblToken.balanceOf(policyBooksV1[i]);
            policyBooksV2[i] = upgradedPolicies[policyBooks[i]];

            if (checkLiquidityBridge) {
                balanceV2[i] = stblToken.balanceOf(address(this));
            } else {
                if (policyBooksV2[i] != address(0)) {
                    balanceV2[i] = stblToken.balanceOf(policyBooksV2[i]);
                }
            }
        }
    }

    function collectPolicyBooksLiquidity(uint256 _offset, uint256 _limit) external onlyOwner {
        address[] memory _policyBooks =
            IPolicyBookRegistry(v1policyBookRegistryAddress).list(_offset, _limit);

        uint256 _to = (_offset.add(_limit)).min(_policyBooks.length).max(_offset);

        for (uint256 i = _offset; i < _to; i++) {
            address _policyBook = _policyBooks[i];

            if (_policyBook == address(0)) {
                break;
            }
            if (upgradedPolicies[_policyBook] == address(0)) {
                continue;
            }

            uint256 _pbBalance = stblToken.balanceOf(_policyBook);

            if (_pbBalance > 0) {
                extractedLiquidity[_policyBook].add(_pbBalance);
                IPolicyBook(_policyBook).extractLiquidity();
            }
            emit LiquidityCollected(_policyBook, upgradedPolicies[_policyBook], _pbBalance);
        }
    }

    function setMigrationStblApprovals(uint256 _offset, uint256 _limit) external onlyOwner {
        address[] memory _policyBooks =
            IPolicyBookRegistry(v1policyBookRegistryAddress).list(_offset, _limit);

        uint256 _to = (_offset.add(_limit)).min(_policyBooks.length).max(_offset);

        for (uint256 i = _offset; i < _to; i++) {
            address _v1policyBook = _policyBooks[i];
            address _v2policyBook = upgradedPolicies[_v1policyBook];

            if (upgradedPolicies[_v1policyBook] == address(0)) {
                continue;
            }

            uint256 _currentApproval = stblToken.allowance(address(this), _v2policyBook);

            if (extractedLiquidity[_v1policyBook] > _currentApproval) {
                if (_currentApproval > 0) {
                    stblToken.safeApprove(_v2policyBook, 0);
                }

                stblToken.safeApprove(_v2policyBook, extractedLiquidity[_v1policyBook]);
                emit MigrationAllowanceSetUp(_v2policyBook, extractedLiquidity[_v1policyBook]);
            }
        }
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function linkV2Policies(address[] calldata v1policybooks, address[] calldata v2policybooks)
        external
        onlyAdmins
    {
        for (uint256 i = 0; i < v1policybooks.length; i++) {
            upgradedPolicies[v1policybooks[i]] = v2policybooks[i];
        }
    }

    function _unlockAllowances() internal {
        if (bmiToken.allowance(address(this), v2bmiStakingAddress) == 0) {
            bmiToken.approve(v2bmiStakingAddress, uint256(-1));
        }

        if (bmiToken.allowance(address(this), v2bmiCoverStakingAddress) == 0) {
            bmiToken.approve(v2bmiStakingAddress, uint256(-1));
        }
    }

    function unlockStblAllowanceFor(address _spender, uint256 _amount) external onlyAdmins {
        _unlockStblAllowanceFor(_spender, _amount);
    }

    function _unlockStblAllowanceFor(address _spender, uint256 _amount) internal {
        uint256 _allowance = stblToken.allowance(address(this), _spender);

        if (_allowance < _amount) {
            if (_allowance > 0) {
                stblToken.safeApprove(_spender, 0);
            }

            stblToken.safeIncreaseAllowance(_spender, _amount);
        }
    }

    function validatePolicyHolder(address[] calldata _poolAddress, address[] calldata _userAddress)
        external
        view
        returns (uint256[] memory _indexes, uint256 _counter)
    {
        uint256 _counter = 0;
        uint256[] memory _indexes = new uint256[](_poolAddress.length);

        for (uint256 i = 0; i < _poolAddress.length; i++) {
            IPolicyBook.PolicyHolder memory data =
                IPolicyBook(_poolAddress[i]).userStats(_userAddress[i]);
            if (data.startEpochNumber == 0) {
                _indexes[_counter] = i;
                _counter++;
            }
        }
    }

    function purchasePolicyFor(address _v1Policy, address _sender)
        external
        onlyAdmins
        returns (bool)
    {
        IPolicyBook.PolicyHolder memory data = IPolicyBook(_v1Policy).userStats(_sender);

        if (data.startEpochNumber != 0) {
            uint256 _currentEpoch = IPolicyBook(_v1Policy).getEpoch(block.timestamp);

            uint256 _epochNumbers = data.endEpochNumber.sub(_currentEpoch);

            address facade = IV2PolicyBook(upgradedPolicies[_v1Policy]).policyBookFacade();

            // TODO fund the premiums?
            IV2PolicyBookFacade(facade).buyPolicyFor(_sender, _epochNumbers, data.coverTokens);

            return true;
        }

        return false;
    }

    function migrateAddedLiquidity(
        address[] calldata _poolAddress,
        address[] calldata _userAddress
    ) external onlyAdmins {
        require(_poolAddress.length == _userAddress.length, "Missmatch inputs lenght");
        uint256 maxGasSpent = 0;
        uint256 i;

        for (i = 0; i < _poolAddress.length; i++) {
            uint256 gasStart = gasleft();

            if (upgradedPolicies[_poolAddress[i]] == address(0)) {
                // No linked v2 policyBook
                emit SkippedRequest(0, _poolAddress[i], _userAddress[i]);
                continue;
            }

            migrateStblLiquidity(_poolAddress[i], _userAddress[i]);
            counter++;

            emit LiquidityMigrated(counter, _poolAddress[i], _userAddress[i]);

            uint256 gasEnd = gasleft();
            maxGasSpent = (gasStart - gasEnd) > maxGasSpent ? (gasStart - gasEnd) : maxGasSpent;

            if (gasEnd < maxGasSpent) {
                break;
            }
        }
    }

    function migrateStblLiquidity(address _pool, address _sender)
        public
        onlyAdmins
        returns (bool)
    {
        // (uint256 userBalance, uint256 withdrawalsInfo, uint256 _burnedBMIX)

        (uint256 _tokensToBurn, uint256 _stblAmountTether) =
            IPolicyBook(_pool).getUserBMIXStakeInfo(_sender);

        IPolicyBook(_pool).migrateRequestWithdrawal(_sender, _tokensToBurn);

        if (_stblAmountTether > 0) {
            uint256 _stblAmountStnd =
                DecimalsConverter.convertTo18(_stblAmountTether, stblDecimals);

            address _v2Policy = upgradedPolicies[_pool];
            address facade = IV2PolicyBook(_v2Policy).policyBookFacade();

            IV2PolicyBookFacade(facade).addLiquidityAndStakeFor(
                _sender,
                _stblAmountStnd,
                _stblAmountStnd
            );

            emit MigratedAddedLiquidity(_pool, _sender, _stblAmountTether);
            migrateAddLiquidity[_pool][_sender] = true;
        }
    }

    function migrateBMIStakes(address[] calldata _poolAddress, address[] calldata _userAddress)
        external
        onlyAdmins
    {
        require(_poolAddress.length == _userAddress.length, "Missmatch inputs lenght");
        uint256 maxGasSpent = 0;
        uint256 i;

        for (i = 0; i < _poolAddress.length; i++) {
            uint256 gasStart = gasleft();

            if (upgradedPolicies[_poolAddress[i]] == address(0)) {
                // No linked v2 policyBook
                emit SkippedRequest(0, _poolAddress[i], _userAddress[i]);
                continue;
            }

            migrateBMICoverStaking(_poolAddress[i], _userAddress[i]);
            counter++;

            emit LiquidityMigrated(counter, _poolAddress[i], _userAddress[i]);

            uint256 gasEnd = gasleft();
            maxGasSpent = (gasStart - gasEnd) > maxGasSpent ? (gasStart - gasEnd) : maxGasSpent;

            if (gasEnd < maxGasSpent) {
                break;
            }
        }
    }

    /// @notice migrates a stake from BMIStaking
    /// @param _sender address of the user to migrate description
    /// @param _bmiRewards uint256 unstaked bmi rewards for restaking
    function migrateBMIStake(address _sender, uint256 _bmiRewards) internal returns (bool) {
        (uint256 _amountBMI, uint256 _burnedStkBMI) =
            IBMIStaking(v1bmiStakingAddress).migrateStakeToV2(_sender);

        if (_amountBMI > 0) {
            require(false, "contracts/LiquidityBridgeMigV2.sol 363");
            IV2BMIStaking(v2bmiStakingAddress).stakeFor(_sender, _amountBMI + _bmiRewards);
        }

        emit BMIMigratedToV2(_amountBMI + _bmiRewards, _burnedStkBMI, _sender);
    }

    function migrateBMICoverStaking(address _policyBook, address _sender)
        public
        onlyAdmins
        returns (uint256 _bmiRewards)
    {
        if (migratedCoverStaking[_policyBook][_sender]) {
            return 0;
        }

        uint256 nftAmount = IBMICoverStaking(v1bmiCoverStakingAddress).balanceOf(_sender);
        IBMICoverStaking.StakingInfo memory _stakingInfo;
        uint256[] memory _policyNfts = new uint256[](nftAmount);
        uint256 _nftCount = 0;

        for (uint256 i = 0; i < nftAmount; i++) {
            uint256 nftIndex =
                IBMICoverStaking(v1bmiCoverStakingAddress).tokenOfOwnerByIndex(_sender, i);

            _stakingInfo = IBMICoverStaking(v1bmiCoverStakingAddress).stakingInfoByToken(nftIndex);

            // if (_stakingInfo.policyBookAddress == _policyBook) {
            // }
            _policyNfts[_nftCount] = nftIndex;
            _nftCount++;
        }

        for (uint256 j = 0; j < _nftCount; j++) {
            uint256 _bmi =
                IBMICoverStaking(v1bmiCoverStakingAddress).migrateWitdrawFundsWithProfit(
                    _sender,
                    _policyNfts[j]
                );

            _bmiRewards += _bmi;
        }

        migrateBMIStake(_sender, _bmiRewards);
        migratedCoverStaking[_policyBook][_sender] = true;
    }
}

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
pragma experimental ABIEncoderV2;

interface IBMICoverStaking {
    struct StakingInfo {
        address policyBookAddress;
        uint256 stakedBMIXAmount;
    }

    struct PolicyBookInfo {
        uint256 totalStakedSTBL;
        uint256 rewardPerBlock;
        uint256 stakingAPY;
        uint256 liquidityAPY;
    }

    struct UserInfo {
        uint256 totalStakedBMIX;
        uint256 totalStakedSTBL;
        uint256 totalBmiReward;
    }

    struct NFTsInfo {
        uint256 nftIndex;
        string uri;
        uint256 stakedBMIXAmount;
        uint256 stakedSTBLAmount;
        uint256 reward;
    }

    function aggregateNFTs(address policyBookAddress, uint256[] calldata tokenIds) external;

    function stakeBMIX(uint256 amount, address policyBookAddress) external;

    function stakeBMIXWithPermit(
        uint256 bmiXAmount,
        address policyBookAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function stakeBMIXFrom(address user, uint256 amount) external;

    function stakeBMIXFromWithPermit(
        address user,
        uint256 bmiXAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getPolicyBookAPY(address policyBookAddress) external view returns (uint256);

    function restakeBMIProfit(uint256 tokenId) external;

    function restakeStakerBMIProfit(address policyBookAddress) external;

    function withdrawBMIProfit(uint256 tokenID) external;

    function withdrawStakerBMIProfit(address policyBookAddress) external;

    function migrateWitdrawFundsWithProfit(address _sender, uint256 tokenId)
        external
        returns (uint256);

    function withdrawFundsWithProfit(uint256 tokenID) external;

    function withdrawStakerFundsWithProfit(address policyBookAddress) external;

    function stakingInfoByToken(uint256 tokenID) external view returns (StakingInfo memory);

    /// @notice exhaustive information about staker's stakes
    /// @param staker is a user to return information for
    /// @param policyBooksAddresses is an array of PolicyBooks to check the stakes in
    /// @param offset is a starting ordinal number of user's NFT
    /// @param limit is a number of NFTs to check per function's call
    /// @return policyBooksInfo - an array of infos (totalStakedSTBL, rewardPerBlock (in BMI), stakingAPY, liquidityAPY)
    /// @return usersInfo - an array of user's info per PolicyBook (totalStakedBMIX, totalStakedSTBL, totalBmiReward)
    /// @return nftsCount - number of NFTs for each respective PolicyBook
    /// @return nftsInfo - 2 dimensional array of NFTs info per each PolicyBook
    ///     (nftIndex, uri, stakedBMIXAmount, stakedSTBLAmount, reward (in BMI))
    function stakingInfoByStaker(
        address staker,
        address[] calldata policyBooksAddresses,
        uint256 offset,
        uint256 limit
    )
        external
        view
        returns (
            PolicyBookInfo[] memory policyBooksInfo,
            UserInfo[] memory usersInfo,
            uint256[] memory nftsCount,
            NFTsInfo[][] memory nftsInfo
        );

    function getSlashedBMIProfit(uint256 tokenId) external view returns (uint256);

    function getBMIProfit(uint256 tokenId) external view returns (uint256);

    function getSlashedStakerBMIProfit(
        address staker,
        address policyBookAddress,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256 totalProfit);

    function getStakerBMIProfit(
        address staker,
        address policyBookAddress,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256 totalProfit);

    function totalStaked(address user) external view returns (uint256);

    function totalStakedSTBL(address user) external view returns (uint256);

    function stakedByNFT(uint256 tokenId) external view returns (uint256);

    function stakedSTBLByNFT(uint256 tokenId) external view returns (uint256);

    function policyBookByNFT(uint256 tokenId) external view returns (address);

    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenOfOwnerByIndex(address user, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./tokens/ISTKBMIToken.sol";

interface IBMIStaking {
    event StakedBMI(uint256 stakedBMI, uint256 mintedStkBMI, address indexed recipient);
    event BMIWithdrawn(uint256 amountBMI, uint256 burnedStkBMI, address indexed recipient);

    event UnusedRewardPoolRevoked(address recipient, uint256 amount);
    event RewardPoolRevoked(address recipient, uint256 amount);

    event BMIMigratedToV2(uint256 amountBMI, uint256 burnedStkBMI, address indexed recipient);

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

    function migrateStakeToV2(address _user)
        external
        returns (uint256 amountBMI, uint256 _amountStkBMI);

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

    function revokeRewardPool(uint256 _amount) external;

    function revokeUnusedRewardPool() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";

interface IClaimingRegistry {
    enum ClaimStatus {
        CAN_CLAIM,
        UNCLAIMABLE,
        PENDING,
        AWAITING_CALCULATION,
        REJECTED_CAN_APPEAL,
        REJECTED,
        ACCEPTED
    }

    struct ClaimInfo {
        address claimer;
        address policyBookAddress;
        string evidenceURI;
        uint256 dateSubmitted;
        uint256 dateEnded;
        bool appeal;
        ClaimStatus status;
        uint256 claimAmount;
    }

    /// @notice returns anonymous voting duration
    function anonymousVotingDuration(uint256 index) external view returns (uint256);

    /// @notice returns the whole voting duration
    function votingDuration(uint256 index) external view returns (uint256);

    /// @notice returns how many time should pass before anyone could calculate a claim result
    function anyoneCanCalculateClaimResultAfter(uint256 index) external view returns (uint256);

    /// @notice returns true if a user can buy new policy of specified PolicyBook
    function canBuyNewPolicy(address buyer, address policyBookAddress)
        external
        view
        returns (bool);

    /// @notice submits new PolicyBook claim for the user
    function submitClaim(
        address user,
        address policyBookAddress,
        string calldata evidenceURI,
        uint256 cover,
        bool appeal
    ) external returns (uint256);

    /// @notice returns true if the claim with this index exists
    function claimExists(uint256 index) external view returns (bool);

    /// @notice returns claim submition time
    function claimSubmittedTime(uint256 index) external view returns (uint256);

    /// @notice returns claim end time or zero in case it is pending
    function claimEndTime(uint256 index) external view returns (uint256);

    /// @notice returns true if the claim is anonymously votable
    function isClaimAnonymouslyVotable(uint256 index) external view returns (bool);

    /// @notice returns true if the claim is exposably votable
    function isClaimExposablyVotable(uint256 index) external view returns (bool);

    /// @notice returns true if claim is anonymously votable or exposably votable
    function isClaimVotable(uint256 index) external view returns (bool);

    /// @notice returns true if a claim can be calculated by anyone
    function canClaimBeCalculatedByAnyone(uint256 index) external view returns (bool);

    /// @notice returns true if this claim is pending or awaiting
    function isClaimPending(uint256 index) external view returns (bool);

    /// @notice returns how many claims the holder has
    function countPolicyClaimerClaims(address user) external view returns (uint256);

    /// @notice returns how many pending claims are there
    function countPendingClaims() external view returns (uint256);

    /// @notice returns how many claims are there
    function countClaims() external view returns (uint256);

    /// @notice returns a claim index of it's claimer and an ordinal number
    function claimOfOwnerIndexAt(address claimer, uint256 orderIndex)
        external
        view
        returns (uint256);

    /// @notice returns pending claim index by its ordinal index
    function pendingClaimIndexAt(uint256 orderIndex) external view returns (uint256);

    /// @notice returns claim index by its ordinal index
    function claimIndexAt(uint256 orderIndex) external view returns (uint256);

    /// @notice returns current active claim index by policybook and claimer
    function claimIndex(address claimer, address policyBookAddress)
        external
        view
        returns (uint256);

    /// @notice returns true if the claim is appealed
    function isClaimAppeal(uint256 index) external view returns (bool);

    /// @notice returns current status of a claim
    function policyStatus(address claimer, address policyBookAddress)
        external
        view
        returns (ClaimStatus);

    /// @notice returns current status of a claim
    function claimStatus(uint256 index) external view returns (ClaimStatus);

    /// @notice returns the claim owner (claimer)
    function claimOwner(uint256 index) external view returns (address);

    /// @notice returns the claim PolicyBook
    function claimPolicyBook(uint256 index) external view returns (address);

    /// @notice returns claim info by its index
    function claimInfo(uint256 index) external view returns (ClaimInfo memory _claimInfo);

    /// @notice marks the user's claim as Accepted
    function acceptClaim(uint256 index) external;

    /// @notice marks the user's claim as Rejected
    function rejectClaim(uint256 index) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IContractsRegistry {
    function liquidityBridgeImplementation() external view returns (address);

    function getUniswapRouterContract() external view returns (address);

    function getUniswapBMIToETHPairContract() external view returns (address);

    function getWETHContract() external view returns (address);

    function getUSDTContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMICoverStakingContract() external view returns (address);

    function getLegacyRewardsGeneratorContract() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getBMIUtilityNFTContract() external view returns (address);

    function getLiquidityMiningContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getReinsurancePoolContract() external view returns (address);

    function getLiquidityBridgeContract() external view returns (address);

    function getContractsRegistryV2Contract() external view returns (address);

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

interface ILiquidityBridge {
    event BMIMigratedToV2(uint256 amountBMI, uint256 burnedStkBMI, address indexed recipient);
    event MigratedBMIStakers(uint256 migratedCount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";

interface IPolicyBook {
    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    struct PolicyHolder {
        uint256 coverTokens;
        uint256 startEpochNumber;
        uint256 endEpochNumber;
        uint256 paid;
    }

    struct WithdrawalInfo {
        uint256 withdrawalAmount;
        uint256 readyToWithdrawDate;
        bool withdrawalAllowed;
    }

    function EPOCH_DURATION() external view returns (uint256);

    function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    function extractLiquidity() external;

    function getUserBMIXStakeInfo(address _sendere) external returns (uint256, uint256);

    function whitelisted() external view returns (bool);

    function epochStartTime() external view returns (uint256);

    // @TODO: should we let DAO to change contract address?
    /// @notice Returns address of contract this PolicyBook covers, access: ANY
    /// @return _contract is address of covered contract
    function insuranceContractAddress() external view returns (address _contract);

    /// @notice Returns type of contract this PolicyBook covers, access: ANY
    /// @return _type is type of contract
    function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    function totalLiquidity() external view returns (uint256);

    function totalCoverTokens() external view returns (uint256);

    function withdrawalsInfo(address _userAddr)
        external
        view
        returns (
            uint256 _withdrawalAmount,
            uint256 _readyToWithdrawDate,
            bool _withdrawalAllowed
        );

    function __PolicyBook_init(
        address _insuranceContract,
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external;

    function whitelist(bool _whitelisted) external;

    function getEpoch(uint256 time) external view returns (uint256);

    /// @notice get STBL equivalent
    function convertBMIXToSTBL(uint256 _amount) external view returns (uint256);

    /// @notice get BMIX equivalent
    function convertSTBLToBMIX(uint256 _amount) external view returns (uint256);

    /// @notice returns how many BMI tokens needs to approve in order to submit a claim
    function getClaimApprovalAmount(address user) external view returns (uint256);

    /// @notice submits new claim of the policy book
    function submitClaimAndInitializeVoting(string calldata evidenceURI) external;

    /// @notice submits new appeal claim of the policy book
    function submitAppealAndInitializeVoting(string calldata evidenceURI) external;

    /// @notice updates info on claim acceptance
    function commitClaim(
        address claimer,
        uint256 claimAmount,
        uint256 claimEndTime,
        IClaimingRegistry.ClaimStatus status
    ) external;

    /// @notice forces an update of RewardsGenerator multiplier
    function forceUpdateBMICoverStakingRewardMultiplier() external;

    /// @notice function to get precise current cover and liquidity
    function getNewCoverAndLiquidity()
        external
        view
        returns (uint256 newTotalCoverTokens, uint256 newTotalLiquidity);

    /// @notice view function to get precise policy price
    function getPolicyPrice(uint256 _epochsNumber, uint256 _coverTokens)
        external
        view
        returns (uint256 totalSeconds, uint256 totalPrice);

    function buyPolicyFor(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external;

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _durationSeconds is number of seconds to cover
    /// @param _coverTokens is number of tokens to cover
    function buyPolicy(uint256 _durationSeconds, uint256 _coverTokens) external;

    function updateEpochsInfo() external;

    function secondsToEndCurrentEpoch() external view returns (uint256);

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liqudityAmount is amount of stable coin tokens to secure
    function addLiquidity(uint256 _liqudityAmount) external;

    /// @notice Let eligible contracts add liqiudity for another user by supplying stable coin
    /// @param _liquidityHolderAddr is address of address to assign cover
    /// @param _liqudityAmount is amount of stable coin tokens to secure
    function addLiquidityFor(address _liquidityHolderAddr, uint256 _liqudityAmount) external;

    function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _stakeSTBLAmount) external;

    function getAvailableBMIXWithdrawableAmount(address _userAddr) external view returns (uint256);

    function getUserAvailableSTBL(address _userAddr) external view returns (uint256);

    function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    function requestWithdrawal(uint256 _tokensToWithdraw) external;

    function requestWithdrawalWithPermit(
        uint256 _tokensToWithdraw,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function unlockTokens() external;

    function migrateRequestWithdrawal(address _sender, uint256 _tokensToBurn)
        external
        returns (uint256 _sbtlAmount);

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external;

    function getAPY() external view returns (uint256);

    /// @notice Getting user stats, access: ANY
    function userStats(address _user) external view returns (PolicyHolder memory);

    /// @notice Getting number stats, access: ANY
    /// @return _maxCapacities is a max token amount that a user can buy
    /// @return _totalSTBLLiquidity is PolicyBook's liquidity
    /// @return _stakedSTBL is how much stable coin are staked on this PolicyBook
    /// @return _annualProfitYields is its APY
    /// @return _annualInsuranceCost is percentage of cover tokens that is required to be paid for 1 year of insurance
    function numberStats()
        external
        view
        returns (
            uint256 _maxCapacities,
            uint256 _totalSTBLLiquidity,
            uint256 _stakedSTBL,
            uint256 _annualProfitYields,
            uint256 _annualInsuranceCost,
            uint256 _bmiXRatio
        );

    /// @notice Getting info, access: ANY
    /// @return _symbol is the symbol of PolicyBook (bmiXCover)
    /// @return _insuredContract is an addres of insured contract
    /// @return _contractType is a type of insured contract
    /// @return _whitelisted is a state of whitelisting
    function info()
        external
        view
        returns (
            string memory _symbol,
            address _insuredContract,
            IPolicyBookFabric.ContractType _contractType,
            bool _whitelisted
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPolicyBookFabric {
    enum ContractType {CONTRACT, STABLECOIN, SERVICE, EXCHANGE}

    /// @notice Create new Policy Book contract, access: ANY
    /// @param _contract is Contract to create policy book for
    /// @param _contractType is Contract to create policy book for
    /// @param _description is bmiXCover token desription for this policy book
    /// @param _projectSymbol replaces x in bmiXCover token symbol
    /// @param _initialDeposit is an amount user deposits on creation (addLiquidity())
    /// @return _policyBook is address of created contract
    function create(
        address _contract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol,
        uint256 _initialDeposit
    ) external returns (address);

    function isMigrating() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";

interface IPolicyBookRegistry {
    struct PolicyBookStats {
        string symbol;
        address insuredContract;
        IPolicyBookFabric.ContractType contractType;
        uint256 maxCapacity;
        uint256 totalSTBLLiquidity;
        uint256 stakedSTBL;
        uint256 APY;
        uint256 annualInsuranceCost;
        uint256 bmiXRatio;
        bool whitelisted;
    }

    /// @notice Adds PolicyBook to registry, access: PolicyFabric
    function add(
        address insuredContract,
        IPolicyBookFabric.ContractType contractType,
        address policyBook
    ) external;

    function whitelist(address policyBookAddress, bool whitelisted) external;

    /// @notice returns required allowances for the policybooks
    function getPoliciesPrices(
        address[] calldata policyBooks,
        uint256[] calldata epochsNumbers,
        uint256[] calldata coversTokens
    ) external view returns (uint256[] memory _durations, uint256[] memory _allowances);

    /// @notice Buys a batch of policies
    function buyPolicyBatch(
        address[] calldata policyBooks,
        uint256[] calldata epochsNumbers,
        uint256[] calldata coversTokens
    ) external;

    /// @notice Checks if provided address is a PolicyBook
    function isPolicyBook(address policyBook) external view returns (bool);

    /// @notice Returns number of registered PolicyBooks with certain contract type
    function countByType(IPolicyBookFabric.ContractType contractType)
        external
        view
        returns (uint256);

    /// @notice Returns number of registered PolicyBooks, access: ANY
    function count() external view returns (uint256);

    function countByTypeWhitelisted(IPolicyBookFabric.ContractType contractType)
        external
        view
        returns (uint256);

    function countWhitelisted() external view returns (uint256);

    /// @notice Listing registered PolicyBooks with certain contract type, access: ANY
    /// @return _policyBooksArr is array of registered PolicyBook addresses with certain contract type
    function listByType(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr);

    /// @notice Listing registered PolicyBooks, access: ANY
    /// @return _policyBooksArr is array of registered PolicyBook addresses
    function list(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr);

    function listByTypeWhitelisted(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr);

    function listWhitelisted(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr);

    /// @notice Listing registered PolicyBooks with stats and certain contract type, access: ANY
    function listWithStatsByType(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    /// @notice Listing registered PolicyBooks with stats, access: ANY
    function listWithStats(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    function listWithStatsByTypeWhitelisted(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    function listWithStatsWhitelisted(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    /// @notice Getting stats from policy books, access: ANY
    /// @param policyBooks is list of PolicyBooks addresses
    function stats(address[] calldata policyBooks)
        external
        view
        returns (PolicyBookStats[] memory _stats);

    /// @notice Return existing Policy Book contract, access: ANY
    /// @param insuredContract is contract address to lookup for created IPolicyBook
    function policyBookFor(address insuredContract) external view returns (address);

    /// @notice Getting stats from policy books, access: ANY
    /// @param insuredContracts is list of insuredContracts in registry
    function statsByInsuredContracts(address[] calldata insuredContracts)
        external
        view
        returns (PolicyBookStats[] memory _stats);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";

interface IPolicyRegistry {
    struct PolicyInfo {
        uint256 coverAmount;
        uint256 premium;
        uint256 startTime;
        uint256 endTime;
    }

    struct PolicyUserInfo {
        string symbol;
        address insuredContract;
        IPolicyBookFabric.ContractType contractType;
        uint256 coverTokens;
        uint256 startTime;
        uint256 endTime;
        uint256 paid;
    }

    function STILL_CLAIMABLE_FOR() external view returns (uint256);

    /// @notice Returns the number of the policy for the user, access: ANY
    /// @param _userAddr Policy holder address
    /// @return the number of police in the array
    function getPoliciesLength(address _userAddr) external view returns (uint256);

    /// @notice Shows whether the user has a policy, access: ANY
    /// @param _userAddr Policy holder address
    /// @param _policyBookAddr Address of policy book
    /// @return true if user has policy in specific policy book
    function policyExists(address _userAddr, address _policyBookAddr) external view returns (bool);

    /// @notice Returns information about current policy, access: ANY
    /// @param _userAddr Policy holder address
    /// @param _policyBookAddr Address of policy book
    /// @return true if user has active policy in specific policy book
    function isPolicyActive(address _userAddr, address _policyBookAddr)
        external
        view
        returns (bool);

    /// @notice returns current policy start time or zero
    function policyStartTime(address _userAddr, address _policyBookAddr)
        external
        view
        returns (uint256);

    /// @notice returns current policy end time or zero
    function policyEndTime(address _userAddr, address _policyBookAddr)
        external
        view
        returns (uint256);

    /// @notice Returns the array of the policy itself , access: ANY
    /// @param _userAddr Policy holder address
    /// @param _isActive If true, then returns an array with information about active policies, if false, about inactive
    /// @return _policiesCount is the number of police in the array
    /// @return _policyBooksArr is the array of policy books addresses
    /// @return _policies is the array of policies
    /// @return _policyStatuses parameter will show which button to display on the dashboard
    function getPoliciesInfo(
        address _userAddr,
        bool _isActive,
        uint256 _offset,
        uint256 _limit
    )
        external
        view
        returns (
            uint256 _policiesCount,
            address[] memory _policyBooksArr,
            PolicyInfo[] memory _policies,
            IClaimingRegistry.ClaimStatus[] memory _policyStatuses
        );

    /// @notice Getting stats from users of policy books, access: ANY
    function getUsersInfo(address[] calldata _users, address[] calldata _policyBooks)
        external
        view
        returns (PolicyUserInfo[] memory _stats);

    function getPoliciesArr(address _userAddr) external view returns (address[] memory _arr);

    /// @notice Adds a new policy to the list , access: ONLY POLICY BOOKS
    /// @param _userAddr is the user's address
    /// @param _coverAmount is the number of insured tokens
    /// @param _premium is the name of PolicyBook
    /// @param _durationDays is the number of days for which the insured
    function addPolicy(
        address _userAddr,
        uint256 _coverAmount,
        uint256 _premium,
        uint256 _durationDays
    ) external;

    /// @notice Removes the policy book from the list, access: ONLY POLICY BOOKS
    /// @param _userAddr is the user's address
    function removePolicy(address _userAddr) external;

    function removePolicy(address _policy, address _userAddr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./tokens/ISTKBMIToken.sol";

interface IV2BMIStaking {
    event StakedBMI(uint256 stakedBMI, uint256 mintedStkBMI, address indexed recipient);
    event BMIWithdrawn(uint256 amountBMI, uint256 burnedStkBMI, address indexed recipient);

    event UnusedRewardPoolRevoked(address recipient, uint256 amount);
    event RewardPoolRevoked(address recipient, uint256 amount);

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

    function revokeRewardPool(uint256 _amount) external;

    function revokeUnusedRewardPool() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IV2ContractsRegistry {
    function addProxyContract(bytes32 name, address contractAddress) external;

    function upgradeContract(bytes32 name, address contractAddress) external;

    function injectDependencies(bytes32 name) external;

    function getUniswapRouterContract() external view returns (address);

    function getUniswapBMIToETHPairContract() external view returns (address);

    function getUniswapBMIToUSDTPairContract() external view returns (address);

    function getSushiswapRouterContract() external view returns (address);

    function getSushiswapBMIToETHPairContract() external view returns (address);

    function getSushiswapBMIToUSDTPairContract() external view returns (address);

    function getSushiSwapMasterChefV2Contract() external view returns (address);

    function getWETHContract() external view returns (address);

    function getUSDTContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMICoverStakingContract() external view returns (address);

    function getBMICoverStakingViewContract() external view returns (address);

    function getLegacyRewardsGeneratorContract() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getBMIUtilityNFTContract() external view returns (address);

    function getNFTStakingContract() external view returns (address);

    function getLiquidityBridgeContract() external view returns (address);

    function getLiquidityMiningContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getReinsurancePoolContract() external view returns (address);

    function getLeveragePortfolioViewContract() external view returns (address);

    function getCapitalPoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getLegacyBMIStakingContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getVBMIContract() external view returns (address);

    function getLegacyLiquidityMiningStakingContract() external view returns (address);

    function getLiquidityMiningStakingETHContract() external view returns (address);

    function getLiquidityMiningStakingUSDTContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);

    function getAaveProtocolContract() external view returns (address);

    function getAaveLendPoolAddressProvdierContract() external view returns (address);

    function getAaveATokenContract() external view returns (address);

    function getCompoundProtocolContract() external view returns (address);

    function getCompoundCTokenContract() external view returns (address);

    function getCompoundComptrollerContract() external view returns (address);

    function getYearnProtocolContract() external view returns (address);

    function getYearnVaultContract() external view returns (address);

    function getYieldGeneratorContract() external view returns (address);

    function getShieldMiningContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

// import "./IPolicyBookFabric.sol";
// import "./IClaimingRegistry.sol";
// import "./IPolicyBookFacade.sol";

interface IV2PolicyBook {
    function policyBookFacade() external view returns (address);

    ///// @notice Let eligible contracts add liqiudity for another user by supplying stable coin
    ///// @param _liquidityHolderAddr is address of address to assign cover
    ///// @param _liqudityAmount is amount of stable coin tokens to secure
    function addLiquidityFor(address _liquidityHolderAddr, uint256 _liqudityAmount) external;

    //enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    //struct PolicyHolder {
    //    uint256 coverTokens;
    //    uint256 startEpochNumber;
    //    uint256 endEpochNumber;
    //    uint256 paid;
    //    uint256 reinsurancePrice;
    //}

    //struct WithdrawalInfo {
    //    uint256 withdrawalAmount;
    //    uint256 readyToWithdrawDate;
    //    bool withdrawalAllowed;
    //}

    //struct BuyPolicyParameters {
    //    address buyer;
    //    address holder;
    //    uint256 epochsNumber;
    //    uint256 coverTokens;
    //    uint256 distributorFee;
    //    address distributor;
    //}

    //function policyHolders(address _holder)
    //    external
    //    view
    //    returns (
    //        uint256,
    //        uint256,
    //        uint256,
    //        uint256,
    //        uint256
    //    );

    //function policyBookFacade() external view returns (IPolicyBookFacade);

    //function setPolicyBookFacade(address _policyBookFacade) external;

    //function EPOCH_DURATION() external view returns (uint256);

    //function stblDecimals() external view returns (uint256);

    //function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    //function whitelisted() external view returns (bool);

    //function epochStartTime() external view returns (uint256);

    //// @TODO: should we let DAO to change contract address?
    ///// @notice Returns address of contract this PolicyBook covers, access: ANY
    ///// @return _contract is address of covered contract
    //function insuranceContractAddress() external view returns (address _contract);

    ///// @notice Returns type of contract this PolicyBook covers, access: ANY
    ///// @return _type is type of contract
    //function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    //function totalLiquidity() external view returns (uint256);

    //function totalCoverTokens() external view returns (uint256);

    //// /// @notice return MPL for user leverage pool
    //// function userleveragedMPL() external view returns (uint256);

    //// /// @notice return MPL for reinsurance pool
    //// function reinsurancePoolMPL() external view returns (uint256);

    //// function bmiRewardMultiplier() external view returns (uint256);

    //function withdrawalsInfo(address _userAddr)
    //    external
    //    view
    //    returns (
    //        uint256 _withdrawalAmount,
    //        uint256 _readyToWithdrawDate,
    //        bool _withdrawalAllowed
    //    );

    //function __PolicyBook_init(
    //    address _insuranceContract,
    //    IPolicyBookFabric.ContractType _contractType,
    //    string calldata _description,
    //    string calldata _projectSymbol
    //) external;

    //function whitelist(bool _whitelisted) external;

    ///// @notice get STBL equivalent
    //function convertBMIXToSTBL(uint256 _amount) external view returns (uint256);

    ///// @notice get BMIX equivalent
    //function convertSTBLToBMIX(uint256 _amount) external view returns (uint256);

    ///// @notice submits new claim of the policy book
    //function submitClaimAndInitializeVoting(string calldata evidenceURI) external;

    ///// @notice submits new appeal claim of the policy book
    //function submitAppealAndInitializeVoting(string calldata evidenceURI) external;

    ///// @notice updates info on claim acceptance
    //function commitClaim(
    //    address claimer,
    //    uint256 claimAmount,
    //    uint256 claimEndTime,
    //    IClaimingRegistry.ClaimStatus status
    //) external;

    ///// @notice forces an update of RewardsGenerator multiplier
    //function forceUpdateBMICoverStakingRewardMultiplier() external;

    ///// @notice function to get precise current cover and liquidity
    //function getNewCoverAndLiquidity()
    //    external
    //    view
    //    returns (uint256 newTotalCoverTokens, uint256 newTotalLiquidity);

    ///// @notice view function to get precise policy price
    ///// @param _epochsNumber is number of epochs to cover
    ///// @param _coverTokens is number of tokens to cover
    ///// @param _buyer address of the user who buy the policy
    ///// @return totalSeconds is number of seconds to cover
    ///// @return totalPrice is the policy price which will pay by the buyer
    //function getPolicyPrice(
    //    uint256 _epochsNumber,
    //    uint256 _coverTokens,
    //    address _buyer
    //)
    //    external
    //    view
    //    returns (
    //        uint256 totalSeconds,
    //        uint256 totalPrice,
    //        uint256 pricePercentage
    //    );

    //function updateEpochsInfo() external;

    //function secondsToEndCurrentEpoch() external view returns (uint256);

    //function getAvailableBMIXWithdrawableAmount(address _userAddr) external view returns (uint256);

    //function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    //function requestWithdrawal(uint256 _tokensToWithdraw, address _user) external;

    //// function requestWithdrawalWithPermit(
    ////     uint256 _tokensToWithdraw,
    ////     uint8 _v,
    ////     bytes32 _r,
    ////     bytes32 _s
    //// ) external;

    //function unlockTokens() external;

    ///// @notice Let user to withdraw deposited liqiudity, access: ANY
    //function withdrawLiquidity(address sender) external returns (uint256);

    /////@notice for doing defi hard rebalancing, access: policyBookFacade
    //function updateLiquidity(uint256 _newLiquidity) external;

    //function getAPY() external view returns (uint256);

    ///// @notice Getting user stats, access: ANY
    //function userStats(address _user) external view returns (PolicyHolder memory);

    ///// @notice Getting number stats, access: ANY
    ///// @return _maxCapacities is a max token amount that a user can buy
    ///// @return _totalSTBLLiquidity is PolicyBook's liquidity
    ///// @return _totalLeveragedLiquidity is PolicyBook's leveraged liquidity
    ///// @return _stakedSTBL is how much stable coin are staked on this PolicyBook
    ///// @return _annualProfitYields is its APY
    ///// @return _annualInsuranceCost is percentage of cover tokens that is required to be paid for 1 year of insurance
    //function numberStats()
    //    external
    //    view
    //    returns (
    //        uint256 _maxCapacities,
    //        uint256 _totalSTBLLiquidity,
    //        uint256 _totalLeveragedLiquidity,
    //        uint256 _stakedSTBL,
    //        uint256 _annualProfitYields,
    //        uint256 _annualInsuranceCost,
    //        uint256 _bmiXRatio
    //    );

    ///// @notice Getting info, access: ANY
    ///// @return _symbol is the symbol of PolicyBook (bmiXCover)
    ///// @return _insuredContract is an addres of insured contract
    ///// @return _contractType is a type of insured contract
    ///// @return _whitelisted is a state of whitelisting
    //function info()
    //    external
    //    view
    //    returns (
    //        string memory _symbol,
    //        address _insuredContract,
    //        IPolicyBookFabric.ContractType _contractType,
    //        bool _whitelisted
    //    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IV2PolicyBookFacade {
    function addLiquidityAndStakeFor(
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _stakeSTBLAmount
    ) external;

    /// @param _holder who owns coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    function buyPolicyFor(
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external;

    ///// @notice Let user to buy policy by supplying stable coin, access: ANY
    ///// @param _epochsNumber period policy will cover
    ///// @param _coverTokens amount paid for the coverage
    //function buyPolicy(uint256 _epochsNumber, uint256 _coverTokens) external;

    //function policyBook() external view returns (IPolicyBook);

    //function userLiquidity(address account) external view returns (uint256);

    ///// @notice virtual funds deployed by reinsurance pool
    //function VUreinsurnacePool() external view returns (uint256);

    ///// @notice leverage funds deployed by reinsurance pool
    //function LUreinsurnacePool() external view returns (uint256);

    ///// @notice leverage funds deployed by user leverage pool
    //function LUuserLeveragePool(address userLeveragePool) external view returns (uint256);

    ///// @notice total leverage funds deployed to the pool sum of (VUreinsurnacePool,LUreinsurnacePool,LUuserLeveragePool)
    //function totalLeveragedLiquidity() external view returns (uint256);

    //function userleveragedMPL() external view returns (uint256);

    //function reinsurancePoolMPL() external view returns (uint256);

    //function rebalancingThreshold() external view returns (uint256);

    //function safePricingModel() external view returns (bool);

    ///// @notice policyBookFacade initializer
    ///// @param pbProxy polciybook address upgreadable cotnract.
    //function __PolicyBookFacade_init(
    //    address pbProxy,
    //    address liquidityProvider,
    //    uint256 initialDeposit
    //) external;

    ///// @param _epochsNumber period policy will cover
    ///// @param _coverTokens amount paid for the coverage
    ///// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    //function buyPolicyFromDistributor(
    //    uint256 _epochsNumber,
    //    uint256 _coverTokens,
    //    address _distributor
    //) external;

    ///// @param _buyer who is buying the coverage
    ///// @param _epochsNumber period policy will cover
    ///// @param _coverTokens amount paid for the coverage
    ///// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    //function buyPolicyFromDistributorFor(
    //    address _buyer,
    //    uint256 _epochsNumber,
    //    uint256 _coverTokens,
    //    address _distributor
    //) external;

    ///// @notice Let user to add liquidity by supplying stable coin, access: ANY
    ///// @param _liquidityAmount is amount of stable coin tokens to secure
    //function addLiquidity(uint256 _liquidityAmount) external;

    ///// @notice Let user to add liquidity by supplying stable coin, access: ANY
    ///// @param _user the one taht add liquidity
    ///// @param _liquidityAmount is amount of stable coin tokens to secure
    //function addLiquidityFromDistributorFor(address _user, uint256 _liquidityAmount) external;

    ///// @notice Let user to add liquidity by supplying stable coin and stake it,
    ///// @dev access: ANY
    //function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _stakeSTBLAmount) external;

    ///// @notice Let user to withdraw deposited liqiudity, access: ANY
    //function withdrawLiquidity() external;

    ///// @notice fetches all the pools data
    ///// @return uint256 VUreinsurnacePool
    ///// @return uint256 LUreinsurnacePool
    ///// @return uint256 LUleveragePool
    ///// @return uint256 user leverage pool address
    //function getPoolsData()
    //    external
    //    view
    //    returns (
    //        uint256,
    //        uint256,
    //        uint256,
    //        address
    //    );

    ///// @notice deploy leverage funds (RP lStable, ULP lStable)
    ///// @param  deployedAmount uint256 the deployed amount to be added or substracted from the total liquidity
    ///// @param leveragePool whether user leverage or reinsurance leverage
    //function deployLeverageFundsAfterRebalance(
    //    uint256 deployedAmount,
    //    ILeveragePortfolio.LeveragePortfolio leveragePool
    //) external;

    ///// @notice deploy virtual funds (RP vStable)
    ///// @param  deployedAmount uint256 the deployed amount to be added to the liquidity
    //function deployVirtualFundsAfterRebalance(uint256 deployedAmount) external;

    /////@dev in case ur changed of the pools by commit a claim or policy expired
    //function reevaluateProvidedLeverageStable() external;

    ///// @notice set the MPL for the user leverage and the reinsurance leverage
    ///// @param _userLeverageMPL uint256 value of the user leverage MPL
    ///// @param _reinsuranceLeverageMPL uint256  value of the reinsurance leverage MPL
    //function setMPLs(uint256 _userLeverageMPL, uint256 _reinsuranceLeverageMPL) external;

    ///// @notice sets the rebalancing threshold value
    ///// @param _newRebalancingThreshold uint256 rebalancing threshhold value
    //function setRebalancingThreshold(uint256 _newRebalancingThreshold) external;

    ///// @notice sets the rebalancing threshold value
    ///// @param _safePricingModel bool is pricing model safe (true) or not (false)
    //function setSafePricingModel(bool _safePricingModel) external;

    ///// @notice returns how many BMI tokens needs to approve in order to submit a claim
    //function getClaimApprovalAmount(address user) external view returns (uint256);

    ///// @notice upserts a withdraw request
    ///// @dev prevents adding a request if an already pending or ready request is open.
    ///// @param _tokensToWithdraw uint256 amount of tokens to withdraw
    //function requestWithdrawal(uint256 _tokensToWithdraw) external;

    //function listUserLeveragePools(uint256 offset, uint256 limit)
    //    external
    //    view
    //    returns (address[] memory _userLeveragePools);

    //function countUserLeveragePools() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ISTKBMIToken is IERC20Upgradeable {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

/// @notice the intention of this library is to be able to easily convert
///     one amount of tokens with N decimal places
///     to another amount with M decimal places
library DecimalsConverter {
    using SafeMath for uint256;

    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount.div(10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount.mul(10**(destinationDecimals - baseDecimals));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals) internal pure returns (uint256) {
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, 18, destinationDecimals);
    }
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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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