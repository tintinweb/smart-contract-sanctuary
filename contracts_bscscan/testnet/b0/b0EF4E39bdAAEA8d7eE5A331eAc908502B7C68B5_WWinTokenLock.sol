//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract WWinTokenLock is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant _precisions = 1e24;
    uint256 public constant _rate_precision = 1e2;
    // uint256 public constant _period = 30 days;
    uint256 public constant _period = 1 minutes;

    struct LockInfo{
        uint256 initialAmount;
        uint256 firstReleaseTime;
        uint256 firstReleaseRate;
        uint256 periodReleaseRate;

        uint256 claimAmount;
    }

    mapping(address => LockInfo) public _locks;
    IERC20 public token;

    uint256 public totalValueLock;

    event UserWithdraw(address indexed user, uint256 amount);
    event OwnerWithdraw(address indexed user, uint256 amount);

    constructor(IERC20 _token){
        token = _token;
    }

    // NOTE: Set Lock

    function setLock(address user, uint256 amount, uint256 firstReleaseTime, uint256 firstReleaseRate, uint256 periodReleaseRate) public onlyOwner{
        require(amount > 0, "Amount > 0");
        require(firstReleaseTime > block.timestamp, "Time must be future");
        require(
            (firstReleaseRate < 10000 && periodReleaseRate > 0) || 
            (firstReleaseRate == 10000 && periodReleaseRate == 0), 
            "Invalid release ratio"
        );
        _locks[user].initialAmount = amount;
        _locks[user].firstReleaseTime = firstReleaseTime;
        _locks[user].firstReleaseRate = firstReleaseRate;
        _locks[user].periodReleaseRate = periodReleaseRate;

        _locks[user].claimAmount = 0;

        totalValueLock = totalValueLock.add(amount);
    }

    function setLockBatch(address[] memory users, uint256[] memory amounts, uint256 firstReleaseTime, uint256 firstReleaseRate, uint256 periodReleaseRate) external onlyOwner{
        require(users.length == amounts.length, "Array shape not match");
        for(uint256 i=0;i<users.length;i++){
            setLock(users[i], amounts[i], firstReleaseTime, firstReleaseRate, periodReleaseRate);
        }
    }

    // NOTE: Method getters

    function getPeriodSinceFirstRelease(address _user) internal view returns(uint256){
        return block.timestamp.sub(_locks[_user].firstReleaseTime).div(_period);
    }

    function _getClaimableAmount(address _user) internal view returns(uint256){
        uint256 period = getPeriodSinceFirstRelease(_user);
        if(block.timestamp < _locks[_user].firstReleaseTime)return 0;
        uint256 amount = 0;
        if(block.timestamp >= _locks[_user].firstReleaseTime){
            amount = amount.add(_locks[_user].initialAmount.mul(_locks[_user].firstReleaseRate).div(100).div(_rate_precision));
        }
        if(period > 0){
            amount = amount.add(_locks[_user].initialAmount.mul(_locks[_user].periodReleaseRate).mul(period).div(100).div(_rate_precision));
        }
        return amount;
    }

    function getClaimableAmount(address _user) public view returns(uint256){
        uint256 amount = _getClaimableAmount(_user);
        if(amount == 0)return 0;
        if(amount > _locks[_user].initialAmount)
            amount = _locks[_user].initialAmount;
        return amount.sub(_locks[_user].claimAmount);
    }

    // NOTE: Withdrawal

    function withdraw() external nonReentrant {
        require(block.timestamp > _locks[msg.sender].firstReleaseTime, "Time Locked.");
        uint256 amount = getClaimableAmount(msg.sender);
        require(amount > 0, "No remaining amount for withdraw.");

        token.safeTransfer(msg.sender, amount);
        // Clear record
        _locks[msg.sender].claimAmount = _locks[msg.sender].claimAmount.add(amount);
        totalValueLock = totalValueLock.sub(amount);
        emit UserWithdraw(msg.sender, amount);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner{
        require(amount > 0, "Amount > 0");
        token.safeTransfer(msg.sender, amount);
        emit OwnerWithdraw(msg.sender, amount);
    }

}