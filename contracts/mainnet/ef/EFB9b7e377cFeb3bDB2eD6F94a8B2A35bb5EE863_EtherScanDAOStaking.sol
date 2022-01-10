// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./Ownable.sol";

contract EtherScanDAOStaking is ERC20("vbESD", "vbESD"), Ownable {
    using SafeERC20 for IERC20;
    using SafeCast for int256;
    using SafeCast for uint256;

    struct Config {
        // Timestamp in seconds is small enough to fit into uint64
        uint64 periodFinish;
        uint64 periodStart;

        // Staking incentive rewards to distribute in a steady rate
        uint128 totalReward;
    }

    IERC20 public esd;
    Config public config;

    /*
     * Construct an EtherscanDAOStaking contract.
     *
     * @param _esd the contract address of ESD token
     * @param _periodStart the initial start time of rewards period
     * @param _rewardsDuration the duration of rewards in seconds
     */
    constructor(IERC20 _esd, uint64 _periodStart, uint64 _rewardsDuration) {
        require(address(_esd) != address(0), "EtherscanDAOStaking: _esd cannot be the zero address");
        esd = _esd;
        setPeriod(_periodStart, _rewardsDuration);
    }

    /*
     * Add ESD tokens to the reward pool.
     *
     * @param _esdAmount the amount of ESD tokens to add to the reward pool
     */
    function addRewardESD(uint256 _esdAmount) external {
        Config memory cfg = config;
        require(block.timestamp < cfg.periodFinish, "EtherscanDAOStaking: Adding rewards is forbidden");

        esd.safeTransferFrom(msg.sender, address(this), _esdAmount);
        cfg.totalReward += _esdAmount.toUint128();
        config = cfg;
    }

    /*
     * Set the reward peroid. If only possible to set the reward period after last rewards have been
     * expired.
     *
     * @param _periodStart timestamp of reward starting time
     * @param _rewardsDuration the duration of rewards in seconds
     */
    function setPeriod(uint64 _periodStart, uint64 _rewardsDuration) public onlyOwner {
        require(_periodStart >= block.timestamp, "EtherscanDAOStaking: _periodStart shouldn't be in the past");
        require(_rewardsDuration > 0, "EtherscanDAOStaking: Invalid rewards duration");

        Config memory cfg = config;
        require(cfg.periodFinish < block.timestamp, "EtherscanDAOStaking: The last reward period should be finished before setting a new one");

        uint64 _periodFinish = _periodStart + _rewardsDuration;
        config.periodStart = _periodStart;
        config.periodFinish = _periodFinish;
        config.totalReward = 0;
    }

    /*
     * Returns the staked esd + release rewards
     *
     * @returns amount of available esd
     */
    function getESDPool() public view returns(uint256) {
        return esd.balanceOf(address(this)) - frozenRewards();
    }

    /*
     * Returns the frozen rewards
     *
     * @returns amount of frozen rewards
     */
    function frozenRewards() public view returns(uint256) {
        Config memory cfg = config;

        uint256 time = block.timestamp;
        uint256 remainingTime;
        uint256 duration = uint256(cfg.periodFinish) - uint256(cfg.periodStart);

        if (time <= cfg.periodStart) {
            remainingTime = duration;
        } else if (time >= cfg.periodFinish) {
            remainingTime = 0;
        } else {
            remainingTime = cfg.periodFinish - time;
        }

        return remainingTime * uint256(cfg.totalReward) / duration;
    }

    /*
     * Staking specific amount of ESD token and get corresponding amount of vbESD
     * as the user's share in the pool
     *
     * @param _esdAmount
     */
    function enter(uint256 _esdAmount) external {
        require(_esdAmount > 0, "EtherscanDAOStaking: Should at least stake something");

        uint256 totalESD = getESDPool();
        uint256 totalShares = totalSupply();

        esd.safeTransferFrom(msg.sender, address(this), _esdAmount);

        if (totalShares == 0 || totalESD == 0) {
            _mint(msg.sender, _esdAmount);
        } else {
            uint256 _share = _esdAmount * totalShares / totalESD;
            _mint(msg.sender, _share);
        }
    }

    /*
     * Redeem specific amount of vbESD to ESD tokens according to the user's share in the pool.
     * vbESD will be burnt.
     *
     * @param _share
     */
    function leave(uint256 _share) external {
        require(_share > 0, "EtherscanDAOStaking: Should at least unstake something");

        uint256 totalESD = getESDPool();
        uint256 totalShares = totalSupply();

        _burn(msg.sender, _share);

        uint256 _esdAmount = _share * totalESD / totalShares;
        esd.safeTransfer(msg.sender, _esdAmount);
    }
}