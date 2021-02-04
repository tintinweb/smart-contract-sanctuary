// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IDPexFeeAggregator.sol";
import "./interfaces/IDPexRouter.sol";
import "./abstracts/Governable.sol";
import "./abstracts/SafeGas.sol";

contract DPexFeeAggregator is IDPexFeeAggregator, Initializable, ContextUpgradeable, 
ReentrancyGuardUpgradeable, Governable, SafeGas {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RewardSnapshot {
        uint256 time;
        uint256 totalPSI;
        mapping(address => uint256) userRewards;
    }

    //== Variables ==
    EnumerableSet.AddressSet private _feeTokens; // all the token where a fee is deducted from on swap
    EnumerableSet.AddressSet private _tokenHolders; // all the tokens holder who will retrieve a share of fees
    mapping(address => uint256) private _claimed; // total amount of psi claimed by a user

    /**
     * @notice psi token contract
     */
    address public psi;
    /**
     * @notice psi token contract
     */
    address public WETH;
    /**
     * @notice percentage which get deducted from a swap (1 = 0.1%)
     */
    uint256 public dpexFee;
    /**
     * @notice token fees gathered in the current period
     */
    mapping(address => uint256) public tokensGathered;
    /**
     * @notice returns the latest reward snapshot id
     */
    uint public latestRewardSnapshotId;
    /**
     * @notice all user reward snapshots taken
     */
    mapping (uint => RewardSnapshot) public rewardSnapshots;


    //== CONSTRUCTOR ==
    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    function initialize(address _gov_contract, address _WETH, address _psi) public initializer {
        __Context_init();
        __ReentrancyGuard_init();
        super.initialize(_gov_contract);
        dpexFee = 1;
        latestRewardSnapshotId = 0;
        psi = _psi;
        WETH = _WETH;
    }


    //== MODIFIERS ==
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'DPexFeeAggregator: EXPIRED');
        _;
    }
    modifier onlyRouter() {
        require(router() == _msgSender(), "DPexFeeAggregator: ONLY_ROUTER_ALLOWED");
        _;
    }

    //== VIEW ==
    /**
     * @notice check if the current user is an token holder
     */
    function isTokenHolder(address user) public override view returns (bool) {
        return _tokenHolders.contains(user);
    }
    /**
     * @notice return all the tokens where a fee is deducted from on swap
     */
    function feeTokens() external override view returns (address[] memory) {
        address[] memory tokens = new address[](_feeTokens.length());
        for(uint256 idx = 0; idx < _feeTokens.length(); idx++) {
            tokens[idx] = _feeTokens.at(idx);
        }
        return tokens;
    }
    /**
     * @notice checks if the token is a token where a fee is deducted from on swap
     * @param token fee token to check
     */
    function isFeeToken(address token) public override view returns (bool) {
        return _feeTokens.contains(token);
    }

    /**
     * @notice returns the fee for the amount given
     * @param amount amount to calculate the fee for
     */
    function calculateFee(uint256 amount) public override view returns (uint256 fee, uint256 amountLeft) {
        amountLeft = (amount.mul(1000).sub(amount.mul(dpexFee))).div(1000);
        fee = amount.sub(amountLeft);
    }
    /**
     * @notice returns the fee for the amount given, but only if the token is in the feetokens list
     * @param token token to check if it exists in the feetokens list
     * @param amount amount to calculate the fee for
     */
    function calculateFee(address token, uint256 amount) external override view 
    returns (uint256 fee, uint256 amountLeft) {
        if (!_feeTokens.contains(token)) { return (0, amount); }
        return calculateFee(amount);
    }

    /**
     * @notice returns the time and totalPSI from a snapshot
     * @param snapshotId the id from the snapshot to retrieve
     */
    function getSnapshot(uint256 snapshotId) external override view returns (uint256 time, uint256 totalPsi) {
        require(snapshotId > 0 && snapshotId <= latestRewardSnapshotId, "DPexFeeAggregator: INVALID_SNAPSHOT_ID");
        require(latestRewardSnapshotId > 0, "DPexFeeAggregator: NO_SNAPSHOT_TAKEN_YET");
        time = rewardSnapshots[snapshotId].time;
        totalPsi = rewardSnapshots[snapshotId].totalPSI;
    }
    /**
     * @notice returns the rewards for a user from a snapshot
     * @param snapshotId the id from the snapshot to retrieve
     * @param user the address from the user to check rewards for
     */
    function getSnapshotRewards(uint256 snapshotId, address user) external override view returns (uint256 rewards) {
        require(snapshotId > 0 && snapshotId <= latestRewardSnapshotId, "DPexFeeAggregator: INVALID_SNAPSHOT_ID");
        require(user != address(0), "DPexFeeAggregator: NO_ADDRESS");
        require(latestRewardSnapshotId > 0, "DPexFeeAggregator: NO_SNAPSHOT_TAKEN_YET");
        rewards = rewardSnapshots[snapshotId].userRewards[user];
    }
    /**
     * @notice returns the rewards for a user from a snapshot
     * @param user the address from the user to check rewards for
     */
    function getTotalRewards(address user) public override view returns (uint256 rewards) {
        require(user != address(0), "DPexFeeAggregator: NO_ADDRESS");
        require(latestRewardSnapshotId > 0, "DPexFeeAggregator: NO_SNAPSHOT_TAKEN_YET");
        for(uint256 id = 1; id <= latestRewardSnapshotId; id++) {
            rewards += rewardSnapshots[id].userRewards[user];
        }
    }
    /**
     * @notice returns the unclaimed rewards for a user from a snapshot
     * @param user the address from the user to check rewards for
     */
    function getUnclaimedRewards(address user) public override view returns (uint256 rewards) {
        rewards = getTotalRewards(user).sub(_claimed[user]);
    }
    /**
     * @notice returns the claimed rewards for a user from a snapshot
     * @param user the address from the user to check rewards for
     */
    function getClaimedRewards(address user) external override view returns (uint256 rewards) {
        rewards =_claimed[user];
    }

    //== SET INTERNAL VARIABLES==
    /**
     * @notice adds a new token holder
     * @param user address of the token holder
     */
    function addTokenHolder(address user) external override {
        require(user != address(0), "DPexFeeAggregator: TOKENHOLDER_NO_ADDRESS");
        require(!isTokenHolder(user), "DPexFeeAggregator: ALREADY_TOKENHOLDER");
        _tokenHolders.add(user);
    }
    /**
     * @notice removes the msg_sender token holder
     */
    function removeTokenHolder() external override {
        require(isTokenHolder(_msgSender()), "DPexFeeAggregator: NOT_A_TOKENHOLDER");
        _tokenHolders.remove(_msgSender());
    }
    /**
     * @notice removes a token holder
     * @param user address of the token holder
     */
    function removeTokenHolder(address user) external override onlyGovernor {
        require(user != address(0), "DPexFeeAggregator: TOKENHOLDER_NO_ADDRESS");
        require(isTokenHolder(user), "DPexFeeAggregator: NOT_A_TOKENHOLDER");
        _tokenHolders.remove(user);
    }

    /**
     * @notice add a token to deduct a fee for on swap
     * @param token fee token to add
     */
    function addFeeToken(address token) public override onlyGovernor {
        require(!_feeTokens.contains(token), "DPexFeeAggregator: ALREADY_FEE_TOKEN");
        _feeTokens.add(token);
        IERC20(token).approve(router(), 1e18);
    }
    /**
     * @notice remove a token to deduct a fee for on swap
     * @param token fee token to add
     */
    function removeFeeToken(address token) external override onlyGovernor {
        require(_feeTokens.contains(token), "DPexFeeAggregator: NO_FEE_TOKEN");
        _feeTokens.remove(token);
    }
    /**
     * @notice set the percentage which get deducted from a swap (1 = 0.1%)
     * @param fee percentage to set as fee
     */
    function setDPexFee(uint256 fee) external override onlyGovernor {
        require(fee >= 0 && fee <= 200, "DPexFeeAggregator: FEE_MIN_0_MAX_20");
        dpexFee = fee;
    }
    
    /**
     * @notice Adds the fee to the tokensGathered list. Transfer is done in the router
     * @param token fee token to check
     * @param fee fee to add to the tokensGathered list
     */
    function addTokenFee(address token, uint256 fee) external override onlyRouter {
        require (_feeTokens.contains(token), "Token is not a feeToken");
        tokensGathered[token] += fee;
    }

    /**
     * @notice takes a snapshot of the current moment and transfer non PSI token to PSI
     */
    function takeSnapshotWithRewards(uint256 deadline) external override useCHI onlyGovernor ensure(deadline) {
        uint256 psiBalanceBefore = IERC20(psi).balanceOf(address(this));
        sellFeesToPSI();
        uint256 psiFeeBalance = IERC20(psi).balanceOf(address(this)).sub(psiBalanceBefore);
        if (tokensGathered[psi] > 0) {
            psiFeeBalance += tokensGathered[psi];
            tokensGathered[psi] = 0;
        }

        uint256 totalPSIFromHolders = 0;
        for(uint256 idx = 0; idx < _tokenHolders.length(); idx++) {
            totalPSIFromHolders += IERC20(psi).balanceOf(_tokenHolders.at(idx));
        }

        latestRewardSnapshotId++;
        rewardSnapshots[latestRewardSnapshotId].time = block.timestamp;
        rewardSnapshots[latestRewardSnapshotId].totalPSI = psiFeeBalance;
        for(uint256 idx = 0; idx < _tokenHolders.length(); idx++) {
            uint256 userReward = psiFeeBalance.div(totalPSIFromHolders
                .div(IERC20(psi).balanceOf(_tokenHolders.at(idx))));
            if (userReward > 0) {
                rewardSnapshots[latestRewardSnapshotId].userRewards[_tokenHolders.at(idx)] = userReward;
            }
        }
    }
    function sellFeesToPSI() internal {
        for(uint256 idx = 0; idx < _feeTokens.length(); idx++) {
            address token = _feeTokens.at(idx);
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            if (token != WETH && token != psi && tokenBalance > 0) {
                tokensGathered[token] = 0;
                address[] memory path = new address[](2);
                path[0] = token;
                path[1] = WETH;
                IDPexRouter(router()).swapAggregatorToken(tokenBalance, path, address(this));
            }
        }

        sellWETHToPSI();
    }
    function sellWETHToPSI() internal {
        uint256 balance = IERC20(WETH).balanceOf(address(this));
        if (balance <= 0) { return; }

        tokensGathered[WETH] = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = psi;
        IDPexRouter(router()).swapAggregatorToken(balance, path, address(this));
    }

    /**
     * @notice Claims the rewards for a user
     */
    function claim() external override nonReentrant useCHI {
        uint256 rewards = getUnclaimedRewards(_msgSender());
        require (rewards > 0, "DPexFeeAggregator: NO_REWARDS_TO_CLAIM");

        _claimed[_msgSender()] += rewards;
        IERC20(psi).safeTransfer(msg.sender, rewards);
    }
}