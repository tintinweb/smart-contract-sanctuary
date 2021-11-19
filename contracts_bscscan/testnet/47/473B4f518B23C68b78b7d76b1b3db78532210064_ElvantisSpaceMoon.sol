// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20Mintable.sol";
import "./interfaces/ICardHandler.sol";
import "./interfaces/IProjectHandler.sol";
import "./interfaces/IReferral.sol";
import "./interfaces/IFeeReceiver.sol";
import "./BaseStructs.sol";

contract Reserve is Ownable {
    function safeTransfer(IERC20 rewardToken, address _to, uint256 _amount) external onlyOwner {
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        if (_amount > tokenBal) {
            rewardToken.transfer(_to, tokenBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }
}

/**
    The ElvantisSpaceMoon provides following NFT cards to provide utility features to users.
    
    - Required Cards
        These nft cards are required to use a pool, without these cards you cannot enter a pool.
    - Multiplier Card
        This card increases the user shares of the reward pool, multiple cards can be used together to increase shares further.
    - Harvest Card
        This card is used to provide harvesting relief, so user can harvest more frequently, by using higher value or multiple harvest cards together.
    - Fee Discount Card
        This card provides discount on deposit/withdraw fees, multiple cards can be aggregated to get higher discounts.
 */

contract ElvantisSpaceMoon is BaseStructs, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ICardHandler public cardHandler;
    IProjectHandler public projectHandler;

    mapping(uint256 => mapping(uint256 => mapping (address => UserInfo))) public userInfo;
    mapping(uint256 => mapping(uint256 => mapping (address => UserRewardInfo[]))) public userRewardInfo;
    
    IReferral public referral;
    uint16 public referralCommissionRate = 100;
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;

    uint256 public constant CARD_AMOUNT_MULIPLITER = 1e18;
    Reserve public rewardReserve;

    event Deposit(address indexed user, uint256 indexed projectId, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed projectId, uint256 indexed poolId, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 indexed projectId, uint256 indexed poolId, uint256 amount);
    event RewardLockedUp(address indexed user, uint256 indexed projectId, uint256 indexed poolId, uint256 amountLockedUp);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    event ReferralUpdated(address indexed oldReferral, address indexed newReferral);
    event ReferralCommissionRateUpdated(uint256 indexed oldRate, uint256 indexed newRate);

    modifier validatePoolByPoolId(uint256 projectId, uint256 poolId) {
        require (poolId < projectHandler.getProjectInfo(projectId).pools.length , "ElvantisSpaceMoon: Pool does not exist");
        _;
    }

    // using custom modifier cause the openzeppelin ReentrancyGuard exceeds the contract size limit
    bool entered;
    modifier nonReentrant() {
        require(!entered);
        entered = true;
        _;
        entered = false;
    }

    constructor() {
        rewardReserve = new Reserve();
    }

    function setProjectAndCardHandler(IProjectHandler _projectHandler, ICardHandler _cardHandler) onlyOwner external {
        require(address(projectHandler) == address(0) && address(cardHandler) == address(0), "ElvantisSpaceMoon: _projectHandler & _cardHandler already set");
        require(address(_projectHandler) != address(0) && address(_cardHandler) != address(0), "ElvantisSpaceMoon: _projectHandler or _cardHandler is zero address");
        projectHandler = _projectHandler;
        cardHandler = _cardHandler;

        projectHandler.setCardHandler(_cardHandler);
        cardHandler.setProjectHandler(address(_projectHandler));
    }

    function depositRewardToken(uint256 projectId, uint256 poolId, uint256 rewardId, uint256 amount) external {
        RewardInfo memory _rewardInfo = projectHandler.getRewardInfo(projectId, poolId)[rewardId];
        require(!_rewardInfo.mintable, "ElvantisSpaceMoon: Mintable!");

        uint256 initialBalance = _rewardInfo.token.balanceOf(address(rewardReserve));
        _rewardInfo.token.transferFrom(msg.sender, address(rewardReserve), amount);
        uint256 finalBalance = _rewardInfo.token.balanceOf(address(rewardReserve));
        projectHandler.setRewardSupply(projectId, poolId, rewardId, _rewardInfo.supply + finalBalance - initialBalance);
    }

    function updatePool(uint256 projectId, uint256 poolId) validatePoolByPoolId(projectId,poolId) public {
        ProjectInfo memory project = projectHandler.getProjectInfo(projectId);
        PoolInfo memory _pool = project.pools[poolId];
        RewardInfo[] memory rewardInfo = projectHandler.getRewardInfo(projectId, poolId);
        for (uint256 i = 0; i < rewardInfo.length; i++) {
            RewardInfo memory _rewardInfo = rewardInfo[i];
            
            if(_rewardInfo.paused) {
                projectHandler.setLastRewardBlock(projectId, poolId, i, block.number);
                return;
            }

            if (block.number <= _rewardInfo.lastRewardBlock)
                return;

            if (_pool.totalShares == 0 || _rewardInfo.rewardPerBlock == 0) {
                projectHandler.setLastRewardBlock(projectId, poolId, i, block.number);
                return;
            }
            
            uint256 multiplier = block.number.sub(_rewardInfo.lastRewardBlock);
            uint256 rewardAmount = multiplier.mul(_rewardInfo.rewardPerBlock);
            uint256 devFee = rewardAmount.mul(project.rewardFee).div(10000);
            uint256 adminFee = rewardAmount.mul(project.adminReward).div(10000);
            rewardAmount = _rewardInfo.excludeFee ? 
                rewardAmount :
                rewardAmount.sub(devFee).sub(adminFee);
            uint256 totalRewards = rewardAmount.add(devFee).add(adminFee);
            if(!_rewardInfo.mintable && _rewardInfo.supply < totalRewards) {
                totalRewards = _rewardInfo.supply;
                devFee = totalRewards.mul(project.rewardFee).div(10000);
                adminFee = totalRewards.mul(project.adminReward).div(10000);
                rewardAmount = totalRewards - devFee - adminFee;
            }
            if(_rewardInfo.mintable) {
                projectHandler.setRewardPerShare(projectId, poolId, i, _rewardInfo.accRewardPerShare.add(rewardAmount.mul(1e12).div(_pool.totalShares)));
                if(devFee > 0) {
                    _rewardInfo.token.mint(address(projectHandler.rewardFeeRecipient()), devFee);
                    projectHandler.rewardFeeRecipient().onFeeReceived(address(_rewardInfo.token), devFee);
                }
                if(adminFee > 0){
                    _rewardInfo.token.mint(project.admin, adminFee);
                }
                _rewardInfo.token.mint(address(rewardReserve), rewardAmount);
            } else {
                if(rewardAmount > 0) projectHandler.setRewardPerShare(projectId, poolId, i, _rewardInfo.accRewardPerShare.add(rewardAmount.mul(1e12).div(_pool.totalShares)));
                if(devFee > 0) {
                    rewardReserve.safeTransfer(_rewardInfo.token, address(projectHandler.rewardFeeRecipient()), devFee);
                    projectHandler.rewardFeeRecipient().onFeeReceived(address(_rewardInfo.token), devFee);
                }
                if(adminFee > 0) rewardReserve.safeTransfer(_rewardInfo.token, project.admin, adminFee);
                projectHandler.setRewardSupply(projectId, poolId, i, _rewardInfo.supply - totalRewards);
            }
            projectHandler.setLastRewardBlock(projectId, poolId, i, block.number);
        }
    }

    function pendingRewards(uint256 projectId, uint256 poolId, address _user) external view returns (uint256[] memory) {
        UserInfo memory user = userInfo[projectId][poolId][_user];
        UserRewardInfo[] memory userReward = userRewardInfo[projectId][poolId][_user];
        return projectHandler.pendingRewards(projectId, poolId, user, userReward);
    }

    function _updateRewardDebt(uint256 projectId, uint256 poolId) private {
        UserInfo storage user = userInfo[projectId][poolId][msg.sender];
        UserRewardInfo[] storage userReward = userRewardInfo[projectId][poolId][msg.sender];
        RewardInfo[] memory _rewardInfo = projectHandler.getRewardInfo(projectId, poolId);
        if(userReward.length < _rewardInfo.length) {
            for (uint256 i = 0; i < _rewardInfo.length - userReward.length; i++) {
                userReward.push();
            }
        }
        for (uint256 i = 0; i < userReward.length; i++) {
            userReward[i].rewardDebt = user.shares.mul(_rewardInfo[i].accRewardPerShare).div(1e12);
        }
    }

    function deposit(uint256 projectId, uint256 poolId, uint256 amount,
        NftDeposit[] memory depositFeeCards, NftDeposit[] memory withdrawFeeCards,
        NftDeposit[] memory harvestCards, NftDeposit[] memory multiplierCards, address referrer)  external {
        require (poolId < projectHandler.getProjectInfo(projectId).pools.length , "ElvantisSpaceMoon: Pool does not exist");

        ProjectInfo memory project = projectHandler.getProjectInfo(projectId);
        PoolInfo memory pool = project.pools[poolId];

        require(!project.paused, "ElvantisSpaceMoon: Project paused!");
        require(!pool.lockDeposit, "ElvantisSpaceMoon: Deposit locked!");
        require(pool.minDeposit <= amount || amount == 0, "ElvantisSpaceMoon: Deposit amount too low!");

        _depositFeeDiscountCards(projectId, poolId, amount, depositFeeCards, withdrawFeeCards);

        if (amount > 0 && address(referral) != address(0) && referrer != address(0) && referrer != msg.sender) {
            referral.recordReferral(msg.sender, referrer);
        }

        updatePool(projectId, poolId);
        _payOrLockupPendingToken(projectId, poolId);
        
        _depositCards(projectId, poolId, depositFeeCards, harvestCards, multiplierCards);
        
        _updateRewardDebt(projectId, poolId);
        emit Deposit(msg.sender, projectId, poolId, amount);
    }

    function _depositFeeDiscountCards(uint256 projectId, uint256 poolId, uint256 amount, NftDeposit[] memory depositFeeCards, NftDeposit[] memory withdrawFeeCards) private {
        UserInfo storage user = userInfo[projectId][poolId][msg.sender];
        // only allow to use withdraw fee discout card on first deposit
        if(user.amount == 0) {
            uint256 withdrawFeeDiscount = cardHandler.useCard(msg.sender, uint8(CardType.FEE_DISCOUNT), projectId, poolId, withdrawFeeCards);
            user.withdrawFeeDiscount = withdrawFeeDiscount > 10000 ? 10000 : withdrawFeeDiscount;
        }
        if(amount > 0) {
            uint256 depositFeeDiscount = cardHandler.useCard(msg.sender, uint8(CardType.FEE_DISCOUNT), projectId, poolId, depositFeeCards) + user.depositFeeDiscount;
            user.depositFeeDiscount = depositFeeDiscount > 10000 ? 10000 : depositFeeDiscount;
            _depositTokens(projectId, poolId, amount);
        }
    }

    function _depositCards(uint256 projectId, uint256 poolId, 
        NftDeposit[] memory depositFeeCards,
        NftDeposit[] memory harvestCards, NftDeposit[] memory multiplierCards) private {
        require (poolId < projectHandler.getProjectInfo(projectId).pools.length , "ElvantisSpaceMoon: Pool does not exist");

        UserInfo storage user = userInfo[projectId][poolId][msg.sender];
        PoolInfo memory pool = projectHandler.getProjectInfo(projectId).pools[poolId];

        cardHandler.useCard(msg.sender, uint8(CardType.REQUIRED), projectId, poolId, depositFeeCards); // deposit cards are just a dummy value here, to be able to call the function
        
        uint256 harvestRelief = cardHandler.useCard(msg.sender, uint8(CardType.HARVEST_RELIEF), projectId, poolId, harvestCards);
        user.harvestRelief += harvestRelief;
        user.nextHarvestUntil -= user.nextHarvestUntil >= harvestRelief ? harvestRelief : 0;
        
        uint256 multiplier = cardHandler.useCard(msg.sender, uint8(CardType.MULTIPLIER), projectId, poolId, multiplierCards);
        uint256 sharesToIncrease = user.amount.mul(multiplier).div(10000);
        user.shares += sharesToIncrease;
        projectHandler.setPoolShares(projectId, poolId, pool.totalShares + sharesToIncrease);
    }
    
    function _depositTokens(uint256 projectId, uint256 poolId, uint256 amount) private {
        ProjectInfo memory project = projectHandler.getProjectInfo(projectId);
        PoolInfo memory pool = project.pools[poolId];
        UserInfo storage user = userInfo[projectId][poolId][msg.sender];
        
        user.stakedTimestamp = block.timestamp;
        uint256 depositedAmount = transferStakedToken(pool, address(msg.sender), address(this), amount);
        uint256 depositFee = user.depositFeeDiscount >= 10000 ? 0 : pool.depositFee - ((pool.depositFee * user.depositFeeDiscount) / 10000);
        uint256 shares;
        if(depositFee > 0) {
            uint256 adminDepositFee = amount.mul(depositFee).div(10000);
            transferStakedToken(pool, address(this), project.admin, adminDepositFee);
            user.amount = user.amount.add(depositedAmount).sub(adminDepositFee);
            projectHandler.setStakedAmount(projectId, poolId, pool.stakedAmount.add(depositedAmount).sub(adminDepositFee));
            shares = depositedAmount.sub(adminDepositFee);
            user.shares = user.shares.add(shares);
        } else {
            user.amount = user.amount.add(depositedAmount);
            projectHandler.setStakedAmount(projectId, poolId, pool.stakedAmount.add(depositedAmount));
            shares = depositedAmount;
            user.shares = user.shares.add(shares);
        }
        projectHandler.setPoolShares(projectId, poolId, pool.totalShares + shares);
    }

    function transferStakedToken(PoolInfo memory pool, address from, address to, uint256 amount) private returns(uint256) {
        if(pool.stakedTokenStandard == uint8(TokenStandard.ERC20)) {
            uint256 initialBalance = IERC20(pool.stakedToken).balanceOf(to);
            if(from == address(this))
                IERC20(pool.stakedToken).safeTransfer(to, amount);
            else
                IERC20(pool.stakedToken).safeTransferFrom(from,to, amount);
            uint256 finalBalance = IERC20(pool.stakedToken).balanceOf(to);
            return finalBalance.sub(initialBalance);
        } else if(pool.stakedTokenStandard == uint8(TokenStandard.ERC721)) {
            cardHandler.ERC721Transferfrom(pool.stakedToken, from, to, pool.stakedTokenId);
            return CARD_AMOUNT_MULIPLITER;
        } else if(pool.stakedTokenStandard == uint8(TokenStandard.ERC1155)) {
            cardHandler.ERC1155Transferfrom(pool.stakedToken, from, to, pool.stakedTokenId, amount);
            return from == address(this) ? amount / CARD_AMOUNT_MULIPLITER : amount * CARD_AMOUNT_MULIPLITER;
        }
        return 0;
    }

    function withdraw(uint256 projectId, uint256 poolId, uint256 amount) external {
        require (poolId < projectHandler.getProjectInfo(projectId).pools.length , "ElvantisSpaceMoon: Pool does not exist");

        ProjectInfo memory project = projectHandler.getProjectInfo(projectId);
        PoolInfo memory pool = project.pools[poolId];
        UserInfo storage user = userInfo[projectId][poolId][msg.sender];
        require(user.amount >= amount, "ElvantisSpaceMoon: Invalid withdraw!");
        updatePool(projectId, poolId);
        _payOrLockupPendingToken(projectId, poolId);
        uint256 withdrawFeeDiscount = user.withdrawFeeDiscount;
        if(user.amount == amount) {
            cardHandler.withdrawCard(msg.sender, uint8(CardType.REQUIRED), projectId, poolId, cardHandler.getUserCardsInfo(projectId, poolId, msg.sender).required);
            cardHandler.withdrawCard(msg.sender, uint8(CardType.FEE_DISCOUNT), projectId, poolId, cardHandler.getUserCardsInfo(projectId, poolId, msg.sender).feeDiscount);
            user.harvestRelief -= cardHandler.withdrawCard(msg.sender, uint8(CardType.HARVEST_RELIEF), projectId, poolId, cardHandler.getUserCardsInfo(projectId, poolId, msg.sender).harvest);
            uint256 multiplier = cardHandler.withdrawCard(msg.sender, uint8(CardType.MULTIPLIER), projectId, poolId, cardHandler.getUserCardsInfo(projectId, poolId, msg.sender).multiplier);
            uint256 sharesToDecrease = user.amount.mul(multiplier).div(10000);
            user.depositFeeDiscount = 0;
            user.withdrawFeeDiscount = 0;
            user.shares -= sharesToDecrease;
            projectHandler.setPoolShares(projectId, poolId, pool.totalShares - sharesToDecrease);
        }
        if(amount > 0) {
            projectHandler.setStakedAmount(projectId, poolId, pool.stakedAmount.sub(amount));
            uint256 sharesToRemove = amount.mul(user.shares).div(user.amount);
            user.amount = user.amount.sub(amount);
            user.shares = user.shares.sub(sharesToRemove);
            projectHandler.setPoolShares(projectId, poolId, pool.totalShares.sub(sharesToRemove));

            uint256 amountToTransfer = amount;
            // calculate withdrawl fee
            if(pool.maxWithdrawlFee != 0) {
                uint256 withdrawFee = pool.minWithdrawlFee;
                uint256 stakedTime = block.timestamp - user.stakedTimestamp;
                if(pool.minWithdrawlFee < pool.maxWithdrawlFee && pool.withdrawlFeeReliefInterval > stakedTime) {
                    uint256 feeReliefOverTime = ((stakedTime * 1e8 / pool.withdrawlFeeReliefInterval) * (pool.maxWithdrawlFee - pool.minWithdrawlFee)) / 1e8;
                    withdrawFee = pool.maxWithdrawlFee - feeReliefOverTime;
                    if(withdrawFee < pool.minWithdrawlFee) withdrawFee += pool.minWithdrawlFee;
                }
                uint256 feeAmount = amount * withdrawFee / 10000; // withdraw fee
                feeAmount = feeAmount - (feeAmount * withdrawFeeDiscount / 10000); // withdraw fee after discount
                if(feeAmount > 0) {
                    transferStakedToken(pool, address(this), project.admin, feeAmount);
                    amountToTransfer = amount - feeAmount;
                }
            }
            transferStakedToken(pool, address(this), address(msg.sender), amountToTransfer);
        }
        _updateRewardDebt(projectId, poolId);
        emit Withdraw(msg.sender, projectId, poolId, amount);
    }

    function withdrawHarvestCard(uint256 projectId, uint256 poolId, NftDeposit[] calldata cards) external {
        UserInfo storage user = userInfo[projectId][poolId][msg.sender];
        user.harvestRelief -= cardHandler.withdrawCard(msg.sender, uint8(CardType.HARVEST_RELIEF), projectId, poolId, cards);
    }

    function withdrawMultiplierCard(uint256 projectId, uint256 poolId, NftDeposit[] calldata cards) validatePoolByPoolId(projectId, poolId) external {
        _payOrLockupPendingToken(projectId, poolId);
        PoolInfo memory pool = projectHandler.getProjectInfo(projectId).pools[poolId];
        UserInfo storage user = userInfo[projectId][poolId][msg.sender];
        uint256 multiplier = cardHandler.withdrawCard(msg.sender, uint8(CardType.MULTIPLIER), projectId, poolId, cards);
        uint256 sharesToDecrease = user.amount.mul(multiplier).div(10000);
        user.shares -= sharesToDecrease;
        projectHandler.setPoolShares(projectId, poolId, pool.totalShares - sharesToDecrease);
        _updateRewardDebt(projectId, poolId);
    }

    function _payOrLockupPendingToken(uint256 projectId, uint256 poolId) private {
        ProjectInfo memory project = projectHandler.getProjectInfo(projectId);
        PoolInfo memory pool = project.pools[poolId];
        UserInfo storage user = userInfo[projectId][poolId][msg.sender];
        UserRewardInfo[] storage userReward = userRewardInfo[projectId][poolId][msg.sender];
        RewardInfo[] memory _rewardInfo = projectHandler.getRewardInfo(projectId, poolId);

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(user.harvestRelief > pool.harvestInterval ? 0 : pool.harvestInterval - user.harvestRelief);
        }

        for (uint256 i = 0; i < _rewardInfo.length; i++) {
            if(userReward.length == 0 || userReward.length - 1 < i) userReward.push();
            uint256 pending = user.shares.mul(_rewardInfo[i].accRewardPerShare).div(1e12).sub(userReward[i].rewardDebt);
            if (canHarvest(projectId, poolId, msg.sender)) {
                if (pending > 0 || userReward[i].rewardLockedUp > 0) {
                    uint256 totalRewards = pending.add(userReward[i].rewardLockedUp);

                    // reset lockup
                    userReward[i].rewardLockedUp = 0;
                    user.nextHarvestUntil = block.timestamp.add(user.harvestRelief > pool.harvestInterval ? 0 : pool.harvestInterval - user.harvestRelief);

                    // send rewards
                    rewardReserve.safeTransfer(_rewardInfo[i].token, msg.sender, totalRewards);
                    payReferralCommission(projectId, poolId, i ,msg.sender, totalRewards, _rewardInfo[i]);
                }
            } else if (pending > 0) {
                userReward[i].rewardLockedUp = userReward[i].rewardLockedUp.add(pending);
                emit RewardLockedUp(msg.sender, projectId, poolId, pending);
            }
        }
    }

    function payReferralCommission(uint256 projectId, uint256 poolId, uint256 rewardInfoIndex, address _user, uint256 _pending, RewardInfo memory rewardInfo) internal {
        if (address(referral) != address(0) && referralCommissionRate > 0) {
            address referrer = referral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                if(rewardInfo.mintable){
                    rewardInfo.token.mint(referrer, commissionAmount);
                    referral.recordReferralCommission(referrer, commissionAmount);
                    emit ReferralCommissionPaid(_user, referrer, commissionAmount);
                } 
                else if(commissionAmount <= rewardInfo.supply) {
                    projectHandler.setRewardSupply(projectId, poolId, rewardInfoIndex, rewardInfo.supply - commissionAmount);
                    rewardReserve.safeTransfer(rewardInfo.token, msg.sender, commissionAmount);
                    referral.recordReferralCommission(referrer, commissionAmount);
                    emit ReferralCommissionPaid(_user, referrer, commissionAmount);
                }
            }
        }
    }

    function setReferral(IReferral _referral) external onlyOwner {
        require(address(_referral) != address(0), "ElvantisSpaceMoon: _referral is a zero address");
        emit ReferralUpdated(address(referral), address(_referral));
        referral = _referral;
    }

    function setReferralCommissionRate(uint16 _referralCommissionRate) external onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "ElvantisSpaceMoon: invalid referral commission rate basis points");
        emit ReferralCommissionRateUpdated(referralCommissionRate, _referralCommissionRate);
        referralCommissionRate = _referralCommissionRate;
    }

    function canHarvest(uint256 _projectId, uint256 _poolId, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_projectId][_poolId][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    function emergencyWithdraw(uint256 projectId, uint256 poolId) validatePoolByPoolId(projectId, poolId) external nonReentrant {
        ProjectInfo memory project = projectHandler.getProjectInfo(projectId);
        PoolInfo memory pool = project.pools[poolId];
        UserInfo storage user = userInfo[projectId][poolId][msg.sender];

        cardHandler.withdrawCard(msg.sender, uint8(CardType.REQUIRED), projectId, poolId, cardHandler.getUserCardsInfo(projectId, poolId, msg.sender).required);
        cardHandler.withdrawCard(msg.sender, uint8(CardType.FEE_DISCOUNT), projectId, poolId, cardHandler.getUserCardsInfo(projectId, poolId, msg.sender).feeDiscount);
        cardHandler.withdrawCard(msg.sender, uint8(CardType.HARVEST_RELIEF), projectId, poolId, cardHandler.getUserCardsInfo(projectId, poolId, msg.sender).harvest);
        cardHandler.withdrawCard(msg.sender, uint8(CardType.MULTIPLIER), projectId, poolId, cardHandler.getUserCardsInfo(projectId, poolId, msg.sender).multiplier);
        
        uint256 amount = user.amount;
        if(pool.stakedAmount >= amount){
            projectHandler.setStakedAmount(projectId, poolId, pool.stakedAmount - amount);
        }
        if(pool.totalShares >= user.shares){
            projectHandler.setPoolShares(projectId, poolId, pool.totalShares - user.shares);
        }
        user.amount = 0;
        user.shares = 0;
        user.nextHarvestUntil = 0;
        UserRewardInfo[] storage userReward = userRewardInfo[projectId][poolId][msg.sender];
        for (uint256 i = 0; i < userReward.length; i++) {
            userReward[i].rewardDebt = 0;
            userReward[i].rewardLockedUp = 0;
        }
        transferStakedToken(pool, address(this), address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, projectId, poolId, amount);
    }

    function emergencyProjectAdminWithdraw(uint256 projectId, uint256 poolId, uint256 rewardId) external {
        ProjectInfo memory project = projectHandler.getProjectInfo(projectId);
        require(msg.sender == project.admin, "ProjectHandler: Only Project Admin!");

        RewardInfo memory _rewardInfo = projectHandler.getRewardInfo(projectId,poolId)[rewardId];
        _rewardInfo.token.transfer(project.admin, _rewardInfo.token.balanceOf(address(this)));
        rewardReserve.safeTransfer(_rewardInfo.token, project.admin, _rewardInfo.supply);
        projectHandler.setLastRewardBlock(projectId, poolId, rewardId,  block.number);
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
library SafeMath {
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

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

import "./IElvantisPoolCards.sol";
import "../BaseStructs.sol";

pragma solidity ^0.8.0;

interface ICardHandler is BaseStructs {
    function setProjectHandler(address _projectHandler) external;
    function ERC721Transferfrom(address token, address from, address to, uint256 amount) external ;
    function ERC1155Transferfrom(address token, address from, address to, uint256 tokenId, uint256 amount) external;
    function getUserCardsInfo(uint256 projectId, uint256 poolId, address account) external view returns (NftDepositInfo memory);
    function getPoolRequiredCards(uint256 projectId, uint256 poolId) external view returns (NftDeposit[] memory);
    function setPoolCard(uint256 _projectId, IElvantisPoolCards _poolcard) external;
    function addPoolRequiredCards(uint256 _projectId, uint256 _poolId, NftDeposit[] calldata _requiredCards) external;
    function useCard(address user, uint8 cardType, uint256 projectId, uint256 poolId, NftDeposit[] calldata cards) external returns(uint256);
    function withdrawCard(address user, uint8 cardType, uint256 projectId, uint256 poolId, NftDeposit[] calldata cards) external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ICardHandler.sol";
import "./IFeeReceiver.sol";
import "../BaseStructs.sol";

interface IProjectHandler is BaseStructs {
    function setCardHandler(ICardHandler _cardHandler) external;
    function initializeProject(uint256 projectId) external;
    function getRewardInfo(uint256 projectId, uint256 poolId) external returns(RewardInfo[] calldata);
   
    function projectFeeRecipient() external returns(IFeeReceiver);
    function poolFeeRecipient() external returns(IFeeReceiver);
    function rewardFeeRecipient() external returns(IFeeReceiver);
    function projectFee() external returns(uint256);
    function poolFee() external returns(uint256);
    function rewardFee() external returns(uint256);
    
    function getProjectInfo(uint256 projectId) external returns(ProjectInfo memory);
    function projectLength() external view returns (uint256);
    function projectPoolLength(uint256 projectId) external view returns (uint256);
    function getPoolInfo(uint256 projectId, uint256 poolId) external view returns (PoolInfo memory);

    function addProject(address _admin, uint256 _adminReward, uint256 _startBlock, IElvantisPoolCards _poolCards) external payable;
    function setProject(uint256 projectId, address _admin, uint256 _adminReward, IElvantisPoolCards _poolCards) external;
    function addPool(uint256 projectId, PoolInfo memory _pool, RewardInfo[] calldata _rewardInfo, NftDeposit[] calldata _requiredCards) external payable;
    function setPool(uint256 projectId, uint256 poolId, PoolInfo calldata _pool, RewardInfo[] memory _rewardInfo) external;

    function setPoolShares(uint256 projectId, uint256 poolId, uint256 shares) external;
    function setStakedAmount(uint256 projectId, uint256 poolId, uint256 amount) external;

    function setRewardPerBlock(uint256 projectId, uint256 poolId, uint256 rewardId, uint256 rewardPerBlock) external;
    function setLastRewardBlock(uint256 projectId, uint256 poolId, uint256 rewardId, uint256 lastRewardBlock) external;
    function setRewardPerShare(uint256 projectId, uint256 poolId, uint256 rewardId, uint256 accRewardPerShare) external;
    function setRewardSupply(uint256 projectId, uint256 poolId, uint256 rewardId, uint256 supply) external;

    function pendingRewards(uint256 projectId, uint256 poolId, UserInfo memory user, UserRewardInfo[] calldata userReward) external view returns (uint256[] calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeReceiver {
    function onFeeReceived(address token, uint256 amount) payable external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20Mintable.sol";
import "./interfaces/IElvantisPoolCards.sol";

interface BaseStructs {
    
    enum CardType { REQUIRED, FEE_DISCOUNT, HARVEST_RELIEF, MULTIPLIER }
    
    enum TokenStandard { ERC20, ERC721, ERC1155 }

    struct NftDeposit {
        uint256 tokenId;
        uint256 amount;
    }

    struct NftDepositInfo {
        NftDeposit[] required;
        NftDeposit[] feeDiscount;
        NftDeposit[] harvest;
        NftDeposit[] multiplier;
    }
    
    struct ProjectInfo {
        address admin;
        uint256 adminReward;
        uint256 rewardFee;
        uint256 startBlock;
        bool initialized;
        bool paused;
        IElvantisPoolCards poolCards;
        PoolInfo[] pools;
    }

    struct PoolInfo {
        address stakedToken;
        bool lockDeposit;
        uint8 stakedTokenStandard;
        uint256 stakedTokenId;
        uint256 stakedAmount;
        uint256 totalShares;
        uint16 depositFee;
        uint16 minWithdrawlFee;
        uint16 maxWithdrawlFee;
        uint16 withdrawlFeeReliefInterval;
        uint256 minDeposit;
        uint256 harvestInterval;
    }

    struct RewardInfo {
        IERC20Mintable token;
        bool paused;
        bool mintable;
        bool excludeFee;
        uint256 rewardPerBlock;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 supply;
    }

    struct UserInfo {
        uint256 amount;
        uint256 shares;
        uint256 nextHarvestUntil;
        uint256 harvestRelief;
        uint256 withdrawFeeDiscount;
        uint256 depositFeeDiscount;
        uint256 stakedTimestamp;
    }

    struct UserRewardInfo {
        uint256 rewardDebt;
        uint256 rewardLockedUp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract IElvantisPoolCards is IERC1155 {
    function getHarvestRelief(uint256 id) virtual external returns (uint256);
    function getFeeDiscount(uint256 id) virtual external returns (uint256);
    function getMultiplier(uint256 id) virtual external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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