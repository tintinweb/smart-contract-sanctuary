// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./MasterChef.sol";
import "./IMigrator.sol";
import "./ERC20Mintable.sol";

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

// Sushiswap - PID 232: BDI/ETH
// BasketDAO - PID   1: BDI/ETH

// Sushiswap - PID 233: BASK/ETH
// BasketDAO - PID   2: BASK/ETH

interface ISushiswapMasterchef {
    function sushiPerBlock() external view returns (uint256);
}

contract StackedMasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PoolInfo {
        uint256 lastRewardBlock;
        uint256 accRewardsPerShare;
    }

    struct UserInfo {
        uint256 amount;
        uint256 sushiRewardDebt;
        uint256 basketRewardDebt;
    }

    address public timelock;

    IERC20 public stakingToken; // Stake in SUSHI
    IERC20 public mintableToken; // Mint and deposit in BASK (Since we have full control over it)

    IERC20 public constant baskToken = IERC20(0x44564d0bd94343f72E3C8a0D22308B7Fa71DB0Bb);
    IERC20 public constant sushiToken = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);

    mapping(address => UserInfo) public userInfo;
    mapping(address => PoolInfo) public poolInfo;

    MasterChef basketdaoMasterChef = MasterChef(0xDB9daa0a50B33e4fe9d0ac16a1Df1d335F96595e);
    uint256 public baskPID;

    MasterChef sushiMasterChef = MasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    uint256 public sushiPID;

    constructor(
        address _timelock,
        IERC20 _stakingToken,
        IERC20 _mintableToken,
        uint256 _sushiPID,
        uint256 _baskPID
    ) {
        timelock = _timelock;

        stakingToken = _stakingToken;
        mintableToken = _mintableToken;
        sushiPID = _sushiPID;
        baskPID = _baskPID;

        stakingToken.approve(address(sushiMasterChef), uint256(-1));
        mintableToken.approve(address(basketdaoMasterChef), uint256(-1));

        updatePools();
    }

    modifier onlyTimelock {
        require(msg.sender == timelock, "!timelock");
        _;
    }

    function deposit(uint256 _amount) public {
        PoolInfo storage sushiPool = poolInfo[address(sushiToken)];
        PoolInfo storage baskPool = poolInfo[address(baskToken)];
        UserInfo storage user = userInfo[msg.sender];

        // Deposit first to trigger token transfer
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        ERC20Mintable(address(mintableToken)).mint(address(this), _amount);

        sushiMasterChef.deposit(sushiPID, _amount);
        basketdaoMasterChef.deposit(baskPID, _amount);

        if (user.amount > 0) {
            uint256 baskPending = user.amount.mul(baskPool.accRewardsPerShare).div(1e12).sub(user.basketRewardDebt);
            uint256 sushiPending = user.amount.mul(sushiPool.accRewardsPerShare).div(1e12).sub(user.sushiRewardDebt);

            _safeTransfer(baskToken, msg.sender, baskPending);
            _safeTransfer(sushiToken, msg.sender, sushiPending);
        }

        user.amount = user.amount.add(_amount);
        user.sushiRewardDebt = user.amount.mul(sushiPool.accRewardsPerShare).div(1e12);
        user.basketRewardDebt = user.amount.mul(baskPool.accRewardsPerShare).div(1e12);
    }

    function withdraw(uint256 _amount) public {
        PoolInfo storage sushiPool = poolInfo[address(sushiToken)];
        PoolInfo storage baskPool = poolInfo[address(baskToken)];
        UserInfo storage user = userInfo[msg.sender];

        // Withdraw first to trigger token transfer
        sushiMasterChef.withdraw(sushiPID, _amount);
        basketdaoMasterChef.withdraw(baskPID, _amount);

        stakingToken.transfer(msg.sender, _amount);
        ERC20Mintable(address(mintableToken)).burn(_amount);

        updatePools();
        if (user.amount > 0) {
            uint256 baskPending = user.amount.mul(baskPool.accRewardsPerShare).div(1e12).sub(user.basketRewardDebt);
            uint256 sushiPending = user.amount.mul(sushiPool.accRewardsPerShare).div(1e12).sub(user.sushiRewardDebt);

            _safeTransfer(baskToken, msg.sender, baskPending);
            _safeTransfer(sushiToken, msg.sender, sushiPending);
        }

        user.amount = user.amount.sub(_amount);
        user.sushiRewardDebt = user.amount.mul(sushiPool.accRewardsPerShare).div(1e12);
        user.basketRewardDebt = user.amount.mul(baskPool.accRewardsPerShare).div(1e12);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        sushiMasterChef.withdraw(sushiPID, user.amount);
        stakingToken.safeTransfer(address(msg.sender), user.amount);

        user.amount = 0;
        user.sushiRewardDebt = 0;
        user.basketRewardDebt = 0;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePools() public {
        // Update the pools
        sushiMasterChef.updatePool(sushiPID);
        basketdaoMasterChef.updatePool(baskPID);

        // Sushi Pools
        (, , uint256 sushiLastRewardBlock, uint256 accSushiPerShare) = sushiMasterChef.poolInfo(sushiPID);
        PoolInfo storage sushiPool = poolInfo[address(sushiToken)];
        sushiPool.accRewardsPerShare = accSushiPerShare;
        sushiPool.lastRewardBlock = sushiLastRewardBlock;

        // Bask Pools
        (, , uint256 baskLastRewardBlock, uint256 accBaskPerShare) = basketdaoMasterChef.poolInfo(baskPID);
        PoolInfo storage baskPool = poolInfo[address(baskToken)];
        baskPool.accRewardsPerShare = accBaskPerShare;
        baskPool.lastRewardBlock = baskLastRewardBlock;
    }

    // **** View ****

    function pendingRewards(address _user) external view returns (uint256, uint256) {
        return (pendingSushiRewards(_user), pendingBaskRewards(_user));
    }

    function pendingSushiRewards(address _user) public view returns (uint256) {
        (, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) = sushiMasterChef.poolInfo(sushiPID);
        UserInfo memory user = userInfo[_user];

        uint256 lpSupply = stakingToken.balanceOf(address(sushiMasterChef));
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = sushiMasterChef.getMultiplier(lastRewardBlock, block.number);
            uint256 sushiReward =
                multiplier.mul(ISushiswapMasterchef(address(sushiMasterChef)).sushiPerBlock()).mul(allocPoint).div(
                    sushiMasterChef.totalAllocPoint()
                );

            accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        }

        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.sushiRewardDebt);
    }

    function pendingBaskRewards(address _user) public view returns (uint256) {
        (, uint256 allocPoint, uint256 lastRewardBlock, uint256 accBasketPerShare) =
            basketdaoMasterChef.poolInfo(baskPID);
        UserInfo memory user = userInfo[_user];

        uint256 lpSupply = mintableToken.balanceOf(address(basketdaoMasterChef));
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = basketdaoMasterChef.getMultiplier(lastRewardBlock, block.number);
            uint256 basketReward =
                multiplier.mul(basketdaoMasterChef.basketPerBlock()).mul(allocPoint).div(
                    basketdaoMasterChef.totalAllocPoint()
                );

            uint256 devAlloc = basketReward.mul(basketdaoMasterChef.devFundRate()).div(basketdaoMasterChef.divRate());
            uint256 treasuryAlloc =
                basketReward.mul(basketdaoMasterChef.treasuryRate()).div(basketdaoMasterChef.divRate());

            uint256 basketWithoutDevAndTreasury = basketReward.sub(devAlloc).sub(treasuryAlloc);

            accBasketPerShare = accBasketPerShare.add(basketWithoutDevAndTreasury.mul(1e12).div(lpSupply));
        }

        return user.amount.mul(accBasketPerShare).div(1e12).sub(user.basketRewardDebt);
    }

    // **** Restricted functions **** //

    function emergencyExecute(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public onlyTimelock returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{ value: value }(callData);
        require(success, "!tx");

        return returnData;
    }

    // **** Internal Functions **** //

    function _safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 maxBal = _token.balanceOf(address(this));
        if (_amount > maxBal) {
            _token.transfer(_to, maxBal);
        } else {
            _token.transfer(_to, _amount);
        }
    }
}