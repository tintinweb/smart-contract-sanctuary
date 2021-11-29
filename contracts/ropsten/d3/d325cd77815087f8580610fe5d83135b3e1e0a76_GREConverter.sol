// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";

contract GREConverter is Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    enum PoolStatus {
        Live,
        Ended
    }

    IERC20 public _rewardsToken;

    uint256 private _rewardsTokenRate;
    uint256 private _rewardsTokenTotalSupply;
    uint256 private _rewardsTokenReminingSupply;
    uint256 private _stakingTotalRecived;
    uint256 private _decimalPlaces = 1000000000000000000;

    address payable private _stakingDestinationAddress;

    PoolStatus private _status;

    struct Staker {
        uint256 Staking;
        uint256 Reward;
    }

    mapping(address => Staker) private _stakeholders;

    constructor(
        address rewardsTokenAddress,
        address payable stakingDestinationAddress,
        uint256 rewardsTokenRate
    ) {
        _stakingDestinationAddress = stakingDestinationAddress;
        _rewardsTokenRate = rewardsTokenRate;
        _rewardsToken = IERC20(rewardsTokenAddress);

        if (rewardsTokenRate <= 0) {
            revert("rewards token rate should be grater then 0");
        }

        _status = PoolStatus.Live;
    }

    function getStakeholder(address account)
        external
        view
        returns (Staker memory)
    {
        return _stakeholders[account];
    }

    function getStakingTokenTotalRecived() external view returns (uint256) {
        return _stakingTotalRecived;
    }

    function getRewardsTokenReminingSupply() external view returns (uint256) {
        return _rewardsTokenReminingSupply;
    }

    function getRewardsTokenTotalSupply() external view returns (uint256) {
        return _rewardsTokenTotalSupply;
    }

    function getRewardsTokenRate() external view returns (uint256) {
        return _rewardsTokenRate;
    }

    function getPoolStatus() external view returns (PoolStatus) {
        return _status;
    }

    function getStakingTokenDestinationAddress()
        external
        view
        returns (address)
    {
        return _stakingDestinationAddress;
    }

    function setRewardsTokenRate(uint256 rewardsTokenRate)
        external
        onlyOwner
    {
        if (rewardsTokenRate <= 0) {
            revert("rewards token rate should be grater then 0");
        }
        _rewardsTokenRate = rewardsTokenRate;
    }

    function setStakingDestinationAddress(
        address payable stakingDestinationAddress
    ) external onlyOwner {
        _stakingDestinationAddress = stakingDestinationAddress;
    }

    function addRewardsTokenSupply(uint256 rewardsTokenSupply)
        external
        onlyOwner
    {
        if (rewardsTokenSupply <= 0) {
            revert("rewards token supply should be grater then 0");
        }

        bool transferFromStatus = _rewardsToken.transferFrom(
            msg.sender,
            address(this),
            rewardsTokenSupply
        );

        if (transferFromStatus) {
            _rewardsTokenTotalSupply = _rewardsTokenTotalSupply.add(
                rewardsTokenSupply
            );

            _rewardsTokenReminingSupply = _rewardsTokenReminingSupply.add(
                rewardsTokenSupply
            );
        }
    }

    function setLive() external onlyOwner {
        if (_status == PoolStatus.Live) {
            revert("Staking already live");
        }

        _status = PoolStatus.Live;
    }

    function setEnd() external onlyOwner {
        if (_status == PoolStatus.Ended) {
            revert("Staking already Ended");
        }

        if (_rewardsTokenReminingSupply > 0) {
                bool transferStatus = _rewardsToken.transfer(
                    owner(),
                    _rewardsTokenReminingSupply
                );

                if (transferStatus) {
                    _rewardsTokenReminingSupply = _rewardsTokenReminingSupply
                        .sub(_rewardsTokenReminingSupply);
                    _status = PoolStatus.Ended;
                }
            } else {
                _status = PoolStatus.Ended;
            }
    }

    function stake() external payable {
        if (_status != PoolStatus.Live) {
            revert("Staking is ended");
        }

        if (msg.value <= 0) {
            revert("stake amount should be grater then 0");
        }

        uint256 rewards = msg.value.div(_rewardsTokenRate);
        rewards = rewards.mul(_decimalPlaces);

        if (_rewardsTokenReminingSupply < rewards) {
            revert("Amount is excced the staking");
        }

        _stakingDestinationAddress.transfer(msg.value);

        _rewardsToken.transfer(
                    msg.sender,
                    rewards
                );

        _stakeholders[msg.sender].Staking = _stakeholders[msg.sender]
            .Staking
            .add(msg.value);
        _stakeholders[msg.sender].Reward = _stakeholders[msg.sender].Reward.add(
            rewards
        );
        _stakingTotalRecived = _stakingTotalRecived.add(msg.value);
        _rewardsTokenReminingSupply = _rewardsTokenReminingSupply.sub(rewards);
    }


    function stakeCal(uint256 amount) external view returns (uint256) {
        if (_status != PoolStatus.Live) {
            revert("Staking is ended");
        }

        if (amount <= 0) {
            revert("stake amount should be grater then 0");
        }

        uint256 rewards = amount.div(_rewardsTokenRate);
        rewards = rewards.mul(1000000000000000000);

        if (_rewardsTokenReminingSupply < rewards) {
            revert("Amount is excced the staking");
        }

        return rewards;
    }
 }