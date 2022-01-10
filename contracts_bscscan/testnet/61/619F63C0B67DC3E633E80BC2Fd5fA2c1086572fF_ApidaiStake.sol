/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract ApidaiStake is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    IBEP20 public ApidaiToken;
    IBEP20 public BUSD;
    uint256 public stakeLimit;
    uint256 public currentStakeID;
    uint256 public rewardDeposit;

    struct PlanInfo {
        uint256 planID;
        uint256 planDays;
        uint256 planPercentage;
    }

    struct UserInfo {
        address staker;
        uint256 stakeID;
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 unstakeTime;
        uint256 rewardAmount;
    }
    
    struct userID{
        uint256[] stakeIDs;
    }

    struct TotalAmount{
        uint256 totalStakeAmount;
        uint256 totalRewardAmount;
    }

    mapping (uint256 => PlanInfo) public planDetails;
    mapping(address => mapping(uint256 => UserInfo)) public userDetails;
    mapping(address => userID) internal userIDs;
    mapping(address => TotalAmount) internal userTotalBalance;

    event emergencySafe(address indexed receiver, address tokenAddressss, uint256 TokenAmount);
    event stakeing(address indexed staker, uint256 stakeID, uint256 stakeAmount, uint256 stakeTime);
    event unstakeing(address indexed staker, uint256 stakeID, uint256 UnstakeTime);
    event setApidaiToken(address indexed owner, address ApidaiToken);
    event setBUSDToken(address indexed owner, address BUSDToken);
    event ClaimReward(address indexed staker, uint256 rewardAmount);
    event SetPlan(address indexed owner, uint256 planID, uint256 plandays, uint256 PlanPercentage);
    event setMaxTokenStake(address indexed owner, uint256 maxStakeToken);
    event adminDeposits(address indexed owner, uint256 RewardDepositamount);

    constructor (uint256 _maxTokenStake, address _apidaiAddress, address _BUSD) {
        stakeLimit = _maxTokenStake;
        ApidaiToken = IBEP20(_apidaiAddress);
        BUSD = IBEP20(_BUSD);

        planDetails[1] = PlanInfo({planID: 1, planDays: 30, planPercentage: 250});
        planDetails[2] = PlanInfo({planID: 2, planDays: 60, planPercentage: 330});
        planDetails[3] = PlanInfo({planID: 3, planDays: 90, planPercentage: 400});
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function userTotalStakedBalance(address _account) external view returns(TotalAmount memory stakeAmount){
        return userTotalBalance[_account];
    }

    function viewPlan(uint256 _planID) external view returns(PlanInfo memory){
        require(_planID > 0 && _planID < 4,"Invalid ID");
        return planDetails[_planID];
    }

    function updatePlan(uint256 _planID, uint256 _planDays, uint256 _planPercent) external onlyOwner {
        require(_planID > 0 && _planID < 4,"Invalid ID");
        PlanInfo storage plan = planDetails[_planID];
        plan.planDays = _planDays;
        plan.planPercentage = _planPercent;

        emit SetPlan(msg.sender, _planID, _planDays, _planPercent);

    }

    function userStakeIDs(address _account) external view returns(uint256[] memory stakeIDs){
        return userIDs[_account].stakeIDs;
    }

    function updateMaxTokenStake(uint256 _maxTokenStake) external onlyOwner whenNotPaused {
        stakeLimit = _maxTokenStake;
        emit setMaxTokenStake(msg.sender, _maxTokenStake);
    }

    function updateApidaiToken(address _apidaiToken) external onlyOwner whenNotPaused {
        require(_apidaiToken != address(0x0),"apidai is not a zero address");
        ApidaiToken = IBEP20(_apidaiToken);
        emit setApidaiToken(msg.sender, _apidaiToken);
    }

    function updateBUSDToken(address _BUSDToken) external onlyOwner whenNotPaused {
        require(_BUSDToken != address(0x0),"apidai is not a zero address");
        BUSD = IBEP20(_BUSDToken);
        emit setBUSDToken(msg.sender, _BUSDToken);
    }

    function stakeApidai(uint256 _tokenAmount) external nonReentrant whenNotPaused {
        currentStakeID++;
        require( _tokenAmount > 0 && _tokenAmount < stakeLimit,"incorrect token amount");

        UserInfo storage user = userDetails[msg.sender][currentStakeID];
        user.staker = msg.sender;
        user.stakeID = currentStakeID;
        user.stakeAmount = _tokenAmount;
        user.stakeTime = block.timestamp;
        userIDs[msg.sender].stakeIDs.push(currentStakeID);
        userTotalBalance[msg.sender].totalStakeAmount += _tokenAmount;

        ApidaiToken.transferFrom(msg.sender, address(this), _tokenAmount);
        emit stakeing(msg.sender, currentStakeID, _tokenAmount, block.timestamp);
    }

    function unstakeApidai(uint256 _stakeID) external nonReentrant whenNotPaused {
        UserInfo storage user = userDetails[msg.sender][_stakeID];
        require(user.stakeTime > 0 , "Invalid stake ID");
        require(user.unstakeTime == 0, "user already claim this ID");
        user.unstakeTime = block.timestamp;
        userTotalBalance[msg.sender].totalStakeAmount -= user.stakeAmount;
        claimReward(_stakeID, msg.sender);
        ApidaiToken.transfer(msg.sender, user.stakeAmount);
        
        emit unstakeing(msg.sender, _stakeID,  block.timestamp);
    }

    function claimReward(uint256 _stakeID, address _caller) internal {
        UserInfo storage user = userDetails[_caller][_stakeID];
        uint256 stakingTime = block.timestamp.sub(user.stakeTime).div(86400);
        uint256 rewardAmount;
        if(planDetails[3].planDays <= stakingTime ){
            rewardAmount = user.stakeAmount.mul(planDetails[3].planPercentage).div(100);
        } else if(planDetails[2].planDays <= stakingTime ) {
            rewardAmount = user.stakeAmount.mul(planDetails[2].planPercentage).div(100);
        } else if(planDetails[1].planDays <= stakingTime ) {
            rewardAmount = user.stakeAmount.mul(planDetails[1].planPercentage).div(100);
        }
        userTotalBalance[msg.sender].totalRewardAmount += rewardAmount;
        user.rewardAmount = rewardAmount;
        rewardDeposit = rewardDeposit.sub(rewardAmount,"reward amount exceed");
        BUSD.transfer(_caller, rewardAmount);

        emit ClaimReward(_caller, rewardAmount);
    }

    function pendingReward(uint256 _stakeID, address _staker) public view returns(uint256 rewardAmount) {
        UserInfo storage user = userDetails[_staker][_stakeID];
        uint256 stakingTime = block.timestamp.sub(user.stakeTime).div(86400);
        if(user.unstakeTime > 0) {
            rewardAmount = 0;
        }else if(planDetails[3].planDays <= stakingTime ){
            rewardAmount = user.stakeAmount.mul(planDetails[3].planPercentage).div(1000);
        } else if(planDetails[2].planDays <= stakingTime ) {
            rewardAmount = user.stakeAmount.mul(planDetails[2].planPercentage).div(1000);
        } else if(planDetails[1].planDays <= stakingTime ) {
            rewardAmount = user.stakeAmount.mul(planDetails[1].planPercentage).div(1000);
        }
    }

    function adminDeposit(uint256 _tokenAmount) external onlyOwner {
        rewardDeposit = rewardDeposit.add(_tokenAmount);
        BUSD.transferFrom(msg.sender, address(this), _tokenAmount);

        emit adminDeposits(msg.sender, _tokenAmount);
    }

    function emergenecy(address token, address to, uint256 amount)external onlyOwner{
        if(token == address(0x0)){
            payable(to).transfer(amount);
        } else  {
            IBEP20(token).transfer(to, amount);
        }
        emit emergencySafe(to, token, amount);
    }
}