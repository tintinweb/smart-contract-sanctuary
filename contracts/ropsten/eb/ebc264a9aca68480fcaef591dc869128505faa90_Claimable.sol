// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";


/**
 * @title Crowdloan
 * @dev Implements Crowdloan for Kusama auction
 */
contract Claimable is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    IERC20 public token;

    mapping (address => User) private users;
    mapping (address => bool) private adminAddresses;
    uint256 private REWARD_UNIT = 60; // 1 minute
    uint256 private claimedDuration;
    uint256 private lockedDuration;
    uint256 private startedAt;
    uint256 private claimStartedAt;
    uint256 private claimFinishedAt;

    modifier onlyAdmin() {
        require(adminAddresses[msg.sender], "only Admin can do this action");
        _;
    }

    constructor(address _token, uint256 _claimedDuration, uint256 _lockedDuration) {
        owner = msg.sender;
        token = IERC20(_token);
        adminAddresses[msg.sender] = true;
        claimedDuration = _claimedDuration;
        lockedDuration = _lockedDuration;
        startedAt = block.timestamp;
        claimStartedAt = startedAt.add(lockedDuration);
        claimFinishedAt = claimStartedAt.add(claimedDuration);
    }

    struct User {
        address account;
        uint256 claimed;
        uint256 total;
        bool existed;
    }

    fallback() external payable {}

    function initUsers(address[] memory userAddress, uint256[] memory pkf) public onlyAdmin {
        require(userAddress.length > 0, "Users are required");
        require(userAddress.length == pkf.length, "Users and Amount of token must have the same length");

        for (uint256 index = 0; index < userAddress.length; index++) {
            _contributeFrom(userAddress[index], pkf[index]);
        }
    }

    function addUser(address userAddress, uint256 pkf) public onlyAdmin {
        _contributeFrom(userAddress, pkf);
    }

    function clearUser(address userAddress) public onlyAdmin {
        User storage user = users[userAddress];
        user.account = userAddress;
        user.total = 0;
        user.claimed = 0;
        user.existed = false;
    }

    function info(address userAddress) public view returns (uint256, uint256, uint256) {
        if (block.timestamp < claimStartedAt) {
            return (0, 0, 0);
        }

        User memory user = users[userAddress];
        if (!user.existed) {
            return (0, 0, 0);
        }

        return (user.total, user.claimed, _calculateClaimed(userAddress));
    }

    function claim(uint256 amount) public payable whenNotPaused nonReentrant {
        require(amount > 0, "The amount shoule be larger zero.");
        require(block.timestamp >= claimStartedAt, "The current time is in locked duration. Please try again later.");
        require(amount <= _calculateClaimed(msg.sender), "The amount of token is exceeded your claimable token.");
        User storage user = users[msg.sender];
        if (!user.existed) {
            return;
        }

        require(user.claimed.add(amount) <= user.total, "The amount of token is exceeded your available token.");

        user.claimed = user.claimed.add(amount);
        token.transfer(msg.sender, amount);
        return;
    }

    function startClaimedAt() public view returns (uint256) {
        return claimStartedAt;
    }

    function lockTime() public view returns (uint256) {
        return lockedDuration;
    }

    function claimTime() public view returns (uint256) {
        return claimedDuration;
    }

    function withdrawAll() public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setClaimDuration(uint256 _duraion) public onlyOwner {
        claimedDuration = _duraion;
        claimFinishedAt = claimStartedAt.add(claimedDuration);
    }

    function setLockedDuration(uint256 _duration) public onlyOwner {
        lockedDuration = _duration;
        claimStartedAt = startedAt.add(lockedDuration);
        claimFinishedAt = claimStartedAt.add(claimedDuration);
    }

    function setStarted(uint256 _startedAt) public onlyOwner {
        startedAt = _startedAt;
        claimStartedAt = startedAt.add(lockedDuration);
        claimFinishedAt = claimStartedAt.add(claimedDuration);
    }

    function setRewardUnit(uint256 _rewardUnit) public onlyOwner {
        REWARD_UNIT = _rewardUnit;
    }

    function setTokenAddress(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function addAdmin(address admin) public onlyOwner {
        adminAddresses[admin] = true;
    }

    function _calculateClaimed(address userAddress) private view returns (uint256) {
        User memory user = users[userAddress];
        require(user.existed, "You are not in list");
        uint256 claimedAt = block.timestamp;

        if (claimedAt >= claimFinishedAt) {
            return user.total.sub(user.claimed);
        }

        uint256 period = claimedAt.sub(claimStartedAt).div(REWARD_UNIT);
        uint256 claimedPerPeriod = user.total.mul(REWARD_UNIT).div(lockedDuration);
        uint256 claimable = claimedPerPeriod.mul(period);
        if (claimable <= user.claimed || claimable > user.total) {
            return 0;
        }

        return claimable.sub(user.claimed);
    }

    function _contributeFrom(address userAddress, uint256 pkf) private {
        User storage user = users[userAddress];
        if (user.existed) {
            user.total = user.total.add(pkf);
            return;
        }

        user.account = userAddress;
        user.total = pkf;
        user.claimed = 0;
        user.existed = true;
    }
}