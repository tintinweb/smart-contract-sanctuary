// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Events.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract PoolReward is ReentrancyGuard, DataStorage, Events, Ownable, Pausable {
    using SafeMath for uint256;
    /**
     * @dev Constructor function
     */
    constructor() public {
        pools[1] = Pool(
            1,
            1637575200,
            1640167200,
            1000000*10**18,
            0x71B317d396a4f042217D52d711f0CA5166430ADE,
            0
        );
    }

    function deposit(uint8 poolId) external nonReentrant whenNotPaused {
        require(poolId != 0, "Invalid plan");
        Pool memory pool = pools[poolId];
        require(pool.fromTime <= block.timestamp, "Pool not start");
        require(block.timestamp <= pool.toTime, "Pool stopped");
        _deposit(poolId, _msgSender());
    }

    function _deposit(
        uint8 poolId,
        address userAddress
    ) internal {
        UserInfo storage user = userInfos[poolId][_msgSender()];
        require(user.registerTime == 0, "already register");
        Pool storage pool = pools[poolId];
        uint256 currentTime = block.timestamp;
        user.registerTime = currentTime;
        pool.totalRegister = pool.totalRegister.add(1);
        emit NewRegister(userAddress, poolId);
    }

    function unStake(uint256 poolId) external nonReentrant whenNotPaused {
        uint256 feeUnlock = 0;
        UserInfo storage user = userInfos[poolId][_msgSender()];
        Pool storage pool = pools[poolId];
        require(block.timestamp >= pool.toTime, "pool not ended");
        require(!user.isUnStake,"already recevied reward");
        user.isUnStake = true;
        uint256 currentDividends = getUserDividends(pool.totalAmount, pool.totalRegister);
        IERC20(pool.tokenAddress).transfer(
                _msgSender(),
                currentDividends
            );
        emit UnStake(_msgSender(), poolId, currentDividends);

    }

    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) external onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IERC20(coinAddress).transfer(to, value);
    }

    function updatePoolInfo(Pool memory pool) external onlyOwner {
        pools[pool.poolId] = pool;
    }

    function addPool(Pool memory pool) external onlyOwner {
        pools[pool.poolId] = pool;
        totalPool = totalPool.add(1);
    }

    function getUserInfo(address userAddress, uint256 poolId)
        external
        view
        returns (
            UserInfo memory user
        )
    {
        user = userInfos[poolId][userAddress];
    }

    function getAllUser(uint256 fromRegisterTime, uint256 toRegisterTime)
        external
        view
        returns (UserInfo[] memory)
    {
        UserInfo[] memory allUser = new UserInfo[](totalUser.length);
        uint256 count = 0;
        for (uint256 index = 0; index < totalUser.length; index++) {
            if (
                totalUser[index].registerTime >= fromRegisterTime &&
                totalUser[index].registerTime <= toRegisterTime
            ) {
                allUser[count] = totalUser[index];
                ++count;
            }
        }
        return allUser;
    }

    function getUserDividends(uint256 poolTotalAmount, uint256 poolTotalRegister)
        internal
        view
        returns (uint256)
    {
        uint256 totalAmount = poolTotalAmount.div(poolTotalRegister);

        return totalAmount;
    }
}