// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./interfaces/IBMICoverStaking.sol";
import "./interfaces/ILiquidityMining.sol";
import "./interfaces/IBMICoverStakingView.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IRewardsGenerator.sol";
import "./interfaces/IPolicyBook.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract BMICoverStakingView is IBMICoverStakingView, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;

    IBMICoverStaking public bmiCoverStaking;
    IRewardsGenerator public rewardsGenerator;
    ILiquidityMining public liquidityMining;

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        rewardsGenerator = IRewardsGenerator(_contractsRegistry.getRewardsGeneratorContract());
        liquidityMining = ILiquidityMining(_contractsRegistry.getLiquidityMiningContract());
        bmiCoverStaking = IBMICoverStaking(_contractsRegistry.getBMICoverStakingContract());
    }

    /// @notice Retunrs the APY of a policybook address
    /// @dev returns 0 for non whitelisted policybooks
    /// @param policyBookAddress address of the policybook
    /// @return uint256 apy amount
    function getPolicyBookAPY(address policyBookAddress) public view override returns (uint256) {
        return
            IPolicyBook(policyBookAddress).whitelisted()
                ? rewardsGenerator.getPolicyBookAPY(policyBookAddress)
                : 0;
    }

    /// @notice gets the policy addres given an nft token id
    /// @param tokenId uint256 numeric id of the nft token
    /// @return policyBookAddress
    function policyBookByNFT(uint256 tokenId) external view override returns (address) {
        (address policyBookAddress, ) = bmiCoverStaking._stakersPool(tokenId);
        return policyBookAddress;
    }

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
        override
        returns (
            IBMICoverStaking.PolicyBookInfo[] memory policyBooksInfo,
            IBMICoverStaking.UserInfo[] memory usersInfo,
            uint256[] memory nftsCount,
            IBMICoverStaking.NFTsInfo[][] memory nftsInfo
        )
    {
        uint256 to = (offset.add(limit)).min(bmiCoverStaking.balanceOf(staker)).max(offset);

        policyBooksInfo = new IBMICoverStaking.PolicyBookInfo[](policyBooksAddresses.length);
        usersInfo = new IBMICoverStaking.UserInfo[](policyBooksAddresses.length);
        nftsCount = new uint256[](policyBooksAddresses.length);
        nftsInfo = new IBMICoverStaking.NFTsInfo[][](policyBooksAddresses.length);

        for (uint256 i = 0; i < policyBooksAddresses.length; i++) {
            nftsInfo[i] = new IBMICoverStaking.NFTsInfo[](to - offset);

            policyBooksInfo[i] = IBMICoverStaking.PolicyBookInfo(
                rewardsGenerator.getStakedPolicyBookSTBL(policyBooksAddresses[i]),
                rewardsGenerator.getPolicyBookRewardPerBlock(policyBooksAddresses[i]),
                getPolicyBookAPY(policyBooksAddresses[i]),
                IPolicyBook(policyBooksAddresses[i]).getAPY()
            );

            for (uint256 j = offset; j < to; j++) {
                uint256 nftIndex = bmiCoverStaking.tokenOfOwnerByIndex(staker, j);
                (address policyBookAddress, uint256 stakedBMIXAmount) =
                    bmiCoverStaking._stakersPool(nftIndex);

                if (policyBookAddress == policyBooksAddresses[i]) {
                    nftsInfo[i][nftsCount[i]] = IBMICoverStaking.NFTsInfo(
                        nftIndex,
                        bmiCoverStaking.uri(nftIndex),
                        stakedBMIXAmount,
                        rewardsGenerator.getStakedNFTSTBL(nftIndex),
                        bmiCoverStaking.getBMIProfit(nftIndex)
                    );

                    usersInfo[i].totalStakedBMIX = usersInfo[i].totalStakedBMIX.add(
                        nftsInfo[i][nftsCount[i]].stakedBMIXAmount
                    );
                    usersInfo[i].totalStakedSTBL = usersInfo[i].totalStakedSTBL.add(
                        nftsInfo[i][nftsCount[i]].stakedSTBLAmount
                    );
                    usersInfo[i].totalBmiReward = usersInfo[i].totalBmiReward.add(
                        nftsInfo[i][nftsCount[i]].reward
                    );

                    nftsCount[i]++;
                }
            }
        }
    }

    /// @notice Returns a StakingInfo (policyBookAdress and stakedBMIXAmount) for a given nft index
    /// @param tokenId numeric id of the nft index
    /// @return _stakingInfo IBMICoverStaking.StakingInfo
    function stakingInfoByToken(uint256 tokenId)
        external
        view
        override
        returns (IBMICoverStaking.StakingInfo memory _stakingInfo)
    {
        (_stakingInfo.policyBookAddress, _stakingInfo.stakedBMIXAmount) = bmiCoverStaking
            ._stakersPool(tokenId);
        require(_stakingInfo.policyBookAddress != address(0), "BDS: Token doesn't exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant DAYS_IN_THE_YEAR = 365;
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS18 = 10**18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant APY_TOKENS = DECIMALS18;

uint256 constant PROTOCOL_PERCENTAGE = 20 * PRECISION;

uint256 constant DEFAULT_REBALANCING_THRESHOLD = 1 * PRECISION;

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

    // mappings

    function _stakersPool(uint256 index)
        external
        view
        returns (address policyBookAddress, uint256 stakedBMIXAmount);

    // function getPolicyBookAPY(address policyBookAddress) external view returns (uint256);

    function restakeBMIProfit(uint256 tokenId) external;

    function restakeStakerBMIProfit(address policyBookAddress) external;

    function withdrawBMIProfit(uint256 tokenID) external;

    function withdrawStakerBMIProfit(address policyBookAddress) external;

    function withdrawFundsWithProfit(uint256 tokenID) external;

    function withdrawStakerFundsWithProfit(address policyBookAddress) external;

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

    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function uri(uint256 tokenId) external view returns (string memory);

    function tokenOfOwnerByIndex(address user, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IBMICoverStaking.sol";

interface IBMICoverStakingView {
    function getPolicyBookAPY(address policyBookAddress) external view returns (uint256);

    function policyBookByNFT(uint256 tokenId) external view returns (address);

    function stakingInfoByStaker(
        address staker,
        address[] calldata policyBooksAddresses,
        uint256 offset,
        uint256 limit
    )
        external
        view
        returns (
            IBMICoverStaking.PolicyBookInfo[] memory policyBooksInfo,
            IBMICoverStaking.UserInfo[] memory usersInfo,
            uint256[] memory nftsCount,
            IBMICoverStaking.NFTsInfo[][] memory nftsInfo
        );

    function stakingInfoByToken(uint256 tokenId)
        external
        view
        returns (IBMICoverStaking.StakingInfo memory);

    // Not Migratable
    // function totalStaked(address user) external view returns (uint256);
    // function totalStakedSTBL(address user) external view returns (uint256);
    // function getStakerBMIProfit(address staker, address policyBookAddress, uint256 offset, uint256 limit) external view returns (uint256) ;
    // function getSlashedBMIProfit(uint256 tokenId) external view returns (uint256);
    // function getBMIProfit(uint256 tokenId) external view returns (uint256);
    // function uri(uint256 tokenId) external view returns (string memory);
    // function tokenOfOwnerByIndex(address user, uint256 index) external view returns (uint256);
    // function ownerOf(uint256 tokenId) external view returns (address);
    // function getSlashingPercentage() external view returns (uint256);
    // function getSlashedStakerBMIProfit( address staker, address policyBookAddress, uint256 offset, uint256 limit) external view returns (uint256 totalProfit) ;
    // function balanceOf(address user) external view returns (uint256);
    // function _aggregateForEach( address staker, address policyBookAddress, uint256 offset, uint256 limit, function(uint256) view returns (uint256) func) internal view returns (uint256 total);
    // function stakedByNFT(uint256 tokenId) external view returns (uint256);
    // function stakedSTBLByNFT(uint256 tokenId) external view returns (uint256);
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

    function getClaimableIndexes() external view returns (uint256[] memory, uint256);

    function getClaimableAmounts(uint256[] memory _claimIndexes) external view returns (uint256);

    /// @notice marks the user's claim as Accepted
    function acceptClaim(uint256 index) external;

    /// @notice marks the user's claim as Rejected
    function rejectClaim(uint256 index) external;

    /// @notice Update Image Uri in case it contains material that is ilegal
    ///         or offensive.
    /// @dev Only the owner of the PolicyBookAdmin can erase/update evidenceUri.
    /// @param _claimIndex Claim Index that is going to be updated
    /// @param _newEvidenceURI New evidence uri. It can be blank.
    function updateImageUriOfClaim(uint256 _claimIndex, string calldata _newEvidenceURI) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IContractsRegistry {
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

    function getLiquidityMiningContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getReinsurancePoolContract() external view returns (address);

    function getUserLeveragePoolContract() external view returns (address);

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

    function getMPHProtocolContract() external view returns (address);

    function getBarnBridgeProtocolContract() external view returns (address);

    function getYieldGeneratorContract() external view returns (address);

    function getShieldMiningContract() external view returns (address);
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
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";
import "./IPolicyBookFacade.sol";

interface IPolicyBook {
    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    struct PolicyHolder {
        uint256 coverTokens;
        uint256 startEpochNumber;
        uint256 endEpochNumber;
        uint256 paid;
        uint256 reinsurancePrice;
    }

    struct WithdrawalInfo {
        uint256 withdrawalAmount;
        uint256 readyToWithdrawDate;
        bool withdrawalAllowed;
    }

    struct BuyPolicyParameters {
        address buyer;
        uint256 epochsNumber;
        uint256 coverTokens;
        uint256 distributorFee;
        address distributor;
    }

    function policyHolders(address _holder)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function policyBookFacade() external view returns (IPolicyBookFacade);

    function setPolicyBookFacade(address _policyBookFacade) external;

    function EPOCH_DURATION() external view returns (uint256);

    function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

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

    // /// @notice return MPL for user leverage pool
    // function userleveragedMPL() external view returns (uint256);

    // /// @notice return MPL for reinsurance pool
    // function reinsurancePoolMPL() external view returns (uint256);

    // function bmiRewardMultiplier() external view returns (uint256);

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
    /// @param _epochsNumber is number of epochs to cover
    /// @param _coverTokens is number of tokens to cover
    /// @param _buyer address of the user who buy the policy
    /// @return totalSeconds is number of seconds to cover
    /// @return totalPrice is the policy price which will pay by the buyer
    function getPolicyPrice(
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _buyer
    ) external view returns (uint256 totalSeconds, uint256 totalPrice);

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _buyer who is buying the coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributorFee distributor fee (commission). It can't be greater than PROTOCOL_PERCENTAGE
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicy(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        uint256 _distributorFee,
        address _distributor
    ) external returns (uint256);

    function updateEpochsInfo() external;

    function secondsToEndCurrentEpoch() external view returns (uint256);

    /// @notice Let eligible contracts add liqiudity for another user by supplying stable coin
    /// @param _liquidityHolderAddr is address of address to assign cover
    /// @param _liqudityAmount is amount of stable coin tokens to secure
    function addLiquidityFor(address _liquidityHolderAddr, uint256 _liqudityAmount) external;

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liqudityAmount is amount of stable coin tokens to secure
    /// @param _liquidityAmount uint256 amount to be added on behalf the sender
    /// @param _stakeSTBLAmount uint256 the staked amount if add liq and stake
    function addLiquidity(
        address _liquidityAmount,
        uint256 _liqudityAmount,
        uint256 _stakeSTBLAmount
    ) external;

    function getAvailableBMIXWithdrawableAmount(address _userAddr) external view returns (uint256);

    function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    function requestWithdrawal(uint256 _tokensToWithdraw, address _user) external;

    // function requestWithdrawalWithPermit(
    //     uint256 _tokensToWithdraw,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s
    // ) external;

    function unlockTokens() external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity(address sender) external returns (uint256);

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
    enum ContractType {CONTRACT, STABLECOIN, SERVICE, EXCHANGE, VARIOUS}

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

    /// @notice add user leverage pool to policy book registry : access owner
    /// @param userLeverageAddress address user leverage pool proxy address
    /// @param contractType ContractType type of contract that leverage pool will cover
    function addUserLeveragePoolToRegistry(address userLeverageAddress, ContractType contractType)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./IPolicyBook.sol";

interface IPolicyBookFacade {
    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    function buyPolicy(uint256 _epochsNumber, uint256 _coverTokens) external;

    /// @param _buyer who is buying the coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    function buyPolicyFor(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external;

    function policyBook() external view returns (IPolicyBook);

    function userLiquidity(address account) external view returns (uint256);

    /// @notice virtual funds deployed by reinsurance pool
    function VUreinsurnacePool() external view returns (uint256);

    /// @notice leverage funds deployed by reinsurance pool
    function LUreinsurnacePool() external view returns (uint256);

    /// @notice leverage funds deployed by user leverage pool
    function LUuserLeveragePool() external view returns (uint256);

    /// @notice total leverage funds deployed to the pool sum of (VUreinsurnacePool,LUreinsurnacePool,LUuserLeveragePool)
    function totalLeveragedLiquidity() external view returns (uint256);

    function userleveragedMPL() external view returns (uint256);

    function reinsurancePoolMPL() external view returns (uint256);

    function rebalancingThreshold() external view returns (uint256);

    /// @notice policyBookFacade initializer
    /// @param pbProxy polciybook address upgreadable cotnract.
    function __PolicyBookFacade_init(
        address pbProxy,
        address liquidityProvider,
        uint256 initialDeposit
    ) external;

    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicyFromDistributor(
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _distributor
    ) external;

    /// @param _buyer who is buying the coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicyFromDistributorFor(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _distributor
    ) external;

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liquidityAmount is amount of stable coin tokens to secure
    function addLiquidity(uint256 _liquidityAmount) external;

    /// @notice Let user to add liquidity by supplying stable coin and stake it,
    /// @dev access: ANY
    function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _stakeSTBLAmount) external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external;

    /// @notice fetches all the pools data
    /// @return uint256 VUreinsurnacePool
    /// @return uint256 LUreinsurnacePool
    /// @return uint256 LUleveragePool
    function getPoolsData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @notice deploy leverage funds (RP vStable, RP lStable, ULP lStable)
    /// @param  deployedAmount uint256 the deployed amount to be added or substracted from the total liquidity
    /// @param isLeverage bool true for increase , false for decrease
    function deployLeverageFundsAfterRebalance(uint256 deployedAmount, bool isLeverage) external;

    /// @notice set the MPL for the user leverage and the reinsurance leverage
    /// @param _userLeverageMPL uint256 value of the user leverage MPL
    /// @param _reinsuranceLeverageMPL uint256  value of the reinsurance leverage MPL
    function setMPLs(uint256 _userLeverageMPL, uint256 _reinsuranceLeverageMPL) external;

    /// @notice sets the rebalancing threshold value
    /// @param _newRebalancingThreshold uint256 rebalancing threshhold value
    function setRebalancingThreshold(uint256 _newRebalancingThreshold) external;

    /// @notice returns how many BMI tokens needs to approve in order to submit a claim
    function getClaimApprovalAmount(address user) external view returns (uint256);

    /// @notice upserts a withdraw request
    /// @dev prevents adding a request if an already pending or ready request is open.
    /// @param _tokensToWithdraw uint256 amount of tokens to withdraw
    function requestWithdrawal(uint256 _tokensToWithdraw) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IRewardsGenerator {
    struct PolicyBookRewardInfo {
        uint256 rewardMultiplier; // includes 5 decimal places
        uint256 totalStaked;
        uint256 lastUpdateBlock;
        uint256 lastCumulativeSum; // includes 100 percentage
        uint256 cumulativeReward; // includes 100 percentage
    }

    struct StakeRewardInfo {
        uint256 lastCumulativeSum; // includes 100 percentage
        uint256 cumulativeReward;
        uint256 stakeAmount;
    }

    /// @notice this function is called every time policybook's STBL to bmiX rate changes
    function updatePolicyBookShare(uint256 newRewardMultiplier) external;

    /// @notice aggregates specified nfts into a single one
    function aggregate(
        address policyBookAddress,
        uint256[] calldata nftIndexes,
        uint256 nftIndexTo
    ) external;

    /// @notice migrates stake from the LegacyRewardsGenerator (will be called once for each user)
    /// the rewards multipliers must be set in advance
    function migrationStake(
        address policyBookAddress,
        uint256 nftIndex,
        uint256 amount,
        uint256 currentReward
    ) external;

    /// @notice informs generator of stake (rewards)
    function stake(
        address policyBookAddress,
        uint256 nftIndex,
        uint256 amount
    ) external;

    /// @notice returns policybook's APY multiplied by 10**5
    function getPolicyBookAPY(address policyBookAddress) external view returns (uint256);

    /// @notice returns policybook's RewardMultiplier multiplied by 10**5
    function getPolicyBookRewardMultiplier(address policyBookAddress)
        external
        view
        returns (uint256);

    /// @dev returns PolicyBook reward per block multiplied by 10**25
    function getPolicyBookRewardPerBlock(address policyBookAddress)
        external
        view
        returns (uint256);

    /// @notice returns PolicyBook's staked STBL
    function getStakedPolicyBookSTBL(address policyBookAddress) external view returns (uint256);

    /// @notice returns NFT's staked STBL
    function getStakedNFTSTBL(uint256 nftIndex) external view returns (uint256);

    /// @notice returns a reward of NFT
    function getReward(address policyBookAddress, uint256 nftIndex)
        external
        view
        returns (uint256);

    /// @notice informs generator of withdrawal (all funds)
    function withdrawFunds(address policyBookAddress, uint256 nftIndex) external returns (uint256);

    /// @notice informs generator of withdrawal (rewards)
    function withdrawReward(address policyBookAddress, uint256 nftIndex)
        external
        returns (uint256);
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