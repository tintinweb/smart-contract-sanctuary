// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract DeepLockLPMining is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
        bool wasInPresale;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 lastRewardBlock;
        uint256 accDeepPerShare;
        uint256 accDeepPerSharePresale;
    }

    IERC20 public deepLock;
    uint256 public deepPerBlock = uint256(1 ether).div(10); // 0.1 DEEP
    uint256 public deepPerBlockPresale = uint256(3 ether).div(10); // 0.3 DEEP

    // base 1000, value * 5 / 100
    uint256 public feePercent = 25;
    uint256 public collectedFees;

    PoolInfo public liquidityMining;
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    function setPoolInfo(IERC20 _deepLock, IERC20 _lpToken) external onlyOwner {
        require(address(deepLock) == address(0) && address(liquidityMining.lpToken) == address(0), 'Tokens already set');
        deepLock = _deepLock;
        liquidityMining = PoolInfo({lpToken : _lpToken, lastRewardBlock : 0, accDeepPerShare : 0, accDeepPerSharePresale : 0});
    }

    function startMining(uint256 startBlock) external onlyOwner {
        require(liquidityMining.lastRewardBlock == 0, 'Mining already started');
        liquidityMining.lastRewardBlock = startBlock;
    }

    function pendingRewards(address _user) external view returns (uint256) {
        if (liquidityMining.lastRewardBlock == 0 || block.number < liquidityMining.lastRewardBlock) {
            return 0;
        }

        UserInfo storage user = userInfo[_user];
        uint256 accDeepPerShare = user.wasInPresale
        ? liquidityMining.accDeepPerSharePresale
        : liquidityMining.accDeepPerShare;
        uint256 lpSupply = liquidityMining.lpToken.balanceOf(address(this));

        if (block.number > liquidityMining.lastRewardBlock && lpSupply != 0) {
            uint256 perBlock = user.wasInPresale ? deepPerBlockPresale : deepPerBlock;
            uint256 multiplier = block.number.sub(liquidityMining.lastRewardBlock);
            uint256 deepReward = multiplier.mul(perBlock);
            accDeepPerShare = accDeepPerShare.add(deepReward.mul(1e12).div(lpSupply));
        }

        return user.amount.mul(accDeepPerShare).div(1e12).sub(user.rewardDebt).add(user.pendingRewards);
    }

    function updatePool() internal {
        require(liquidityMining.lastRewardBlock > 0 && block.number >= liquidityMining.lastRewardBlock, 'Mining not yet started');
        if (block.number <= liquidityMining.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = liquidityMining.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            liquidityMining.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number.sub(liquidityMining.lastRewardBlock);
        uint256 deepReward = multiplier.mul(deepPerBlock);
        uint256 deepRewardPresale = multiplier.mul(deepPerBlockPresale);
        liquidityMining.accDeepPerShare = liquidityMining.accDeepPerShare.add(deepReward.mul(1e12).div(lpSupply));
        liquidityMining.accDeepPerSharePresale = liquidityMining.accDeepPerSharePresale.add(deepRewardPresale.mul(1e12).div(lpSupply));
        liquidityMining.lastRewardBlock = block.number;
    }

    function deposit(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();

        uint256 accDeepPerShare = user.wasInPresale
        ? liquidityMining.accDeepPerSharePresale
        : liquidityMining.accDeepPerShare;

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accDeepPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                user.pendingRewards = user.pendingRewards.add(pending);
            }
        }
        if (amount > 0) {
            liquidityMining.lpToken.safeTransferFrom(address(msg.sender), address(this), amount);

            if (feePercent > 0) {
                uint256 fee = amount.mul(feePercent).div(1000);
                amount = amount.sub(fee);
                collectedFees = collectedFees.add(fee);
            }

            user.amount = user.amount.add(amount);
        }
        user.rewardDebt = user.amount.mul(accDeepPerShare).div(1e12);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount, "Withdrawing more than you have!");
        updatePool();

        uint256 accDeepPerShare = user.wasInPresale
        ? liquidityMining.accDeepPerSharePresale
        : liquidityMining.accDeepPerShare;

        uint256 pending = user.amount.mul(accDeepPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            user.pendingRewards = user.pendingRewards.add(pending);
        }
        if (amount > 0) {
            user.amount = user.amount.sub(amount);

            if (feePercent > 0) {
                uint256 fee = amount.mul(feePercent).div(1000);
                amount = amount.sub(fee);
                collectedFees = collectedFees.add(fee);
            }

            liquidityMining.lpToken.safeTransfer(address(msg.sender), amount);
        }
        user.rewardDebt = user.amount.mul(accDeepPerShare).div(1e12);
        emit Withdraw(msg.sender, amount);
    }

    function claim() external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();

        uint256 accDeepPerShare = user.wasInPresale
        ? liquidityMining.accDeepPerSharePresale
        : liquidityMining.accDeepPerShare;

        uint256 pending = user.amount.mul(accDeepPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0 || user.pendingRewards > 0) {
            user.pendingRewards = user.pendingRewards.add(pending);
            uint256 claimedAmount = safeDeepTransfer(msg.sender, user.pendingRewards);
            emit Claim(msg.sender, claimedAmount);
            user.pendingRewards = user.pendingRewards.sub(claimedAmount);
        }
        user.rewardDebt = user.amount.mul(accDeepPerShare).div(1e12);
    }

    function safeDeepTransfer(address to, uint256 amount) internal returns (uint256) {
        uint256 deepBalance = deepLock.balanceOf(address(this));
        if (amount > deepBalance) {
            deepLock.transfer(to, deepBalance);
            return deepBalance;
        } else {
            deepLock.transfer(to, amount);
            return amount;
        }
    }

    function setDeepPerBlock(uint256 _deepPerBlock) external onlyOwner {
        require(_deepPerBlock > 0, "DEEP per block should be greater than 0!");
        deepPerBlock = _deepPerBlock;
    }

    function setDeepPerBlockPresale(uint256 _deepPerBlock) external onlyOwner {
        require(_deepPerBlock > 0, "DEEP per block should be greater than 0!");
        deepPerBlockPresale = _deepPerBlock;
    }

    function setPresaleAddresses(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            userInfo[addresses[i]].wasInPresale = true;
        }
    }

    function setFee(uint256 fee) external onlyOwner {
        require(fee >= 0, 'Fee is too small');
        require(fee <= 50, 'Fee is too big');
        feePercent = fee;
    }

    function withdrawFees(address payable withdrawalAddress) external onlyOwner {
        liquidityMining.lpToken.safeTransfer(withdrawalAddress, collectedFees);
        collectedFees = 0;
    }
}