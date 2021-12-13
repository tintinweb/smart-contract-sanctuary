// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

interface IFarmerApes {
    function getUserYield(address _user) external view returns (uint256);
}

contract YieldToken is ERC20("Ape Coin", "APC"), Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;
    mapping(address => bool) public burnList;

    uint256 public stakeStartAt = 1640361615;
    uint256 public stakeEndAt = stakeStartAt + 365 days;

    IFarmerApes public farmerApesContract;

    event RewardPaid(address indexed user, uint256 reward);
    event ValueChanged(string indexed fieldName, uint256 newValue);
    event SetFarmerApesContracts(address indexed newAddress);

    constructor() {}

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev To set FarmerApes smart contract.
     * @param _farmerApe FarmerApes smart contract address
     */
    function setFarmerApesContract(address _farmerApe) external onlyOwner {
        farmerApesContract = IFarmerApes(_farmerApe);
        emit SetFarmerApesContracts(_farmerApe);
    }

    /**
     * @dev set the staking start time
     */
    function setStakingTime(uint256 _stakeStartAt, uint256 _stakeEndAt)
        external
        onlyOwner
    {
        require(_stakeEndAt > _stakeStartAt, "FarmerApe: Invalid time set.");
        require(_stakeStartAt > stakeStartAt, "FarmerApe: Invalid time set.");
        stakeStartAt = _stakeStartAt;
        stakeEndAt = _stakeEndAt;
        emit ValueChanged("stakeStartAt", _stakeStartAt);
        emit ValueChanged("stakeEndAt", _stakeEndAt);
    }

    function setBurnAccess(address _addr, bool _canBurn) external onlyOwner {
        burnList[_addr] = _canBurn;
    }

    function burn(address _from, uint256 _amount) external {
        require(
            burnList[msg.sender],
            "FarmerApe: Only addresses with access can call this function."
        );
        _burn(_from, _amount);
    }

    function getTotalClaimable(address _user) external view returns (uint256) {
        uint256 time = min(block.timestamp, stakeEndAt);
        uint256 pending = farmerApesContract
            .getUserYield(_user)
            .mul(time.sub(lastUpdate[_user]))
            .div(86400);
        return rewards[_user] + pending;
    }

    
    function claimReward(address _to) external {
        require(msg.sender == address(farmerApesContract));
        uint256 reward = rewards[_to];
        if (reward > 0) {
            rewards[_to] = 0;
            _mint(_to, reward);
            emit RewardPaid(_to, reward);
        }
    }

    /**
     * @dev This will be triggered when each Farmer Ape being minted.
     */
    function updateRewardOnMint(address _user) external {
        if (block.timestamp < stakeStartAt) {
            if (lastUpdate[_user] < stakeStartAt)
                lastUpdate[_user] = stakeStartAt;
            return;
        }
        require(
            msg.sender == address(farmerApesContract),
            "FarmerApe: Only Farmer Apes contract can call this function."
        );
        uint256 time = min(block.timestamp, stakeEndAt);
        uint256 timerUser = lastUpdate[_user];

        if (timerUser > 0) {
            if (timerUser < stakeStartAt) timerUser = stakeStartAt;
            rewards[_user] = rewards[_user].add(
                farmerApesContract
                    .getUserYield(_user)
                    .mul((time.sub(timerUser)))
                    .div(86400)
            );
        }
        lastUpdate[_user] = time;
    }

    /**
     * @dev To update the reward of both _from and _to.
     */
    function updateReward(address _from, address _to) external {
        if (block.timestamp < stakeStartAt) return;
        require(msg.sender == address(farmerApesContract));
        uint256 time = min(block.timestamp, stakeEndAt);
        uint256 timerFrom = lastUpdate[_from];

        if (timerFrom != stakeEndAt) {
            if (timerFrom < stakeStartAt) timerFrom = stakeStartAt;
            rewards[_from] += rewards[_from].add(
                farmerApesContract
                    .getUserYield(_from)
                    .mul((time.sub(timerFrom)))
                    .div(86400)
            );
            lastUpdate[_from] = time;
        }

        if (_to != address(0)) {
            uint256 timerTo = lastUpdate[_to];

            if (timerTo == stakeEndAt) return;

            if (timerTo > 0)
                if (timerTo < stakeStartAt) timerTo = stakeStartAt;
            rewards[_to] = rewards[_to].add(
                farmerApesContract
                    .getUserYield(_to)
                    .mul((time.sub(timerTo)))
                    .div(86400)
            );
            if (timerTo != stakeEndAt) lastUpdate[_to] = time;
        }
    }


 
}