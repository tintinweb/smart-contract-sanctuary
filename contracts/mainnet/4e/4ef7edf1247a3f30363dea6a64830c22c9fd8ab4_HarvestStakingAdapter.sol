/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface ERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

abstract contract Ownable {

    modifier onlyOwner {
        require(msg.sender == owner, "O: onlyOwner function!");
        _;
    }

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Initializes owner variable with msg.sender address.
     */
    constructor() internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @notice Transfers ownership to the desired address.
     * The function is callable only by the owner.
     */
    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "O: new owner is the zero address!");
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }
}



/**
 * @title Protocol adapter interface.
 * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.
 * @author Igor Sobolev <[email protected]>
 */
interface ProtocolAdapter {

    /**
     * @dev MUST return "Asset" or "Debt".
     * SHOULD be implemented by the public constant state variable.
     */
    function adapterType() external pure returns (string memory);

    /**
     * @dev MUST return token type (default is "ERC20").
     * SHOULD be implemented by the public constant state variable.
     */
    function tokenType() external pure returns (string memory);

    /**
     * @dev MUST return amount of the given token locked on the protocol by the given account.
     */
    function getBalance(address token, address account) external view returns (uint256);
}


struct Pool {
    address poolAddress;
    address stakingToken;
    address rewardToken;
}


/**
 * @dev StakingRewards contract interface.
 * Only the functions required for YearnStakingV1Adapter contract are added.
 * The StakingRewards contract is available here
 * github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol.
 */
interface StakingRewards {
    function earned(address) external view returns (uint256);
}


/**
 * @title Adapter for Harvest protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
contract HarvestStakingAdapter is ProtocolAdapter, Ownable {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    // Returns if the pool is enabled
    mapping(address => bool) internal isEnabledPool_;
    // Returns the list of pools where the given token is a staking token
    mapping(address => address[]) internal stakingPools_;
    // Returns the list of pools where the given token is a reward token
    mapping(address => address[]) internal rewardPools_;

    event PoolAdded(
        address indexed poolAddress,
        address indexed stakingToken,
        address indexed rewardToken
    );

    function addPools(Pool[] calldata pools) external onlyOwner {
        uint256 length = pools.length;

        for (uint256 i = 0; i < length; i++) {
            addPool(pools[i]);
        }
    }

    function setIsEnabledPools(
        address[] calldata poolAddresses,
        bool[] calldata isEnabledPools
    )
        external
        onlyOwner
    {
        uint256 length = poolAddresses.length;
        require(isEnabledPools.length == length, "HSA: inconsistent arrays");

        for (uint256 i = 0; i < length; i++) {
            setIsEnabledPool(poolAddresses[i], isEnabledPools[i]);
        }
    }

    /**
     * @return Amount of staked tokens / rewards earned after staking for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        address[] memory stakingPools = stakingPools_[token];
        address[] memory rewardPools = rewardPools_[token];

        uint256 length;
        uint256 totalBalance = 0;

        length = stakingPools.length;
        for (uint256 i = 0; i < length; i++) {
            totalBalance += getStakingBalance(stakingPools[i], account);
        }

        length = rewardPools.length;
        for (uint256 i = 0; i < length; i++) {
            totalBalance += getRewardBalance(rewardPools[i], account);
        }

        return totalBalance;
    }

    function getRewardPools(address token) external view returns (address[] memory) {
        return rewardPools_[token];
    }

    function getStakingPools(address token) external view returns (address[] memory) {
        return stakingPools_[token];
    }

    function addPool(Pool memory pool) internal {
        stakingPools_[pool.stakingToken].push(pool.poolAddress);
        rewardPools_[pool.rewardToken].push(pool.poolAddress);
        setIsEnabledPool(pool.poolAddress, true);

        emit PoolAdded(pool.poolAddress, pool.stakingToken, pool.rewardToken);
    }

    function setIsEnabledPool(address poolAddress, bool isEnabledPool) internal {
        isEnabledPool_[poolAddress] = isEnabledPool;
    }

    function getRewardBalance(
        address poolAddress,
        address account
    )
        internal
        view
        returns (uint256)
    {
        return isEnabledPool_[poolAddress] ? StakingRewards(poolAddress).earned(account) : 0;
    }

    function getStakingBalance(
        address poolAddress,
        address account
    )
        internal
        view
        returns (uint256)
    {
        return isEnabledPool_[poolAddress] ? ERC20(poolAddress).balanceOf(account) : 0;
    }
}