/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-21
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

interface IERC20 {
    
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

contract IglooxStaking is Ownable, Pausable,ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public IGLX;
    uint256 stakingID;

    struct UserInfo{
        address user;
        uint256 stakingTime;
        uint256 stakingAmount;
        uint256 lastClaim;
        uint256 unstakeTime;
        uint256 planID;
        bool unstake;
    }

    struct plansInfo{
        uint256 planID;
        uint256 planTime;
        uint256 planAmount;
        uint256 planReward;
        uint256 planMembers;
    }

    struct userID{
        uint256[] stakeIDs;
    }

    mapping (address => userID) userIDs;
    mapping (uint256 => plansInfo) public planDetails;
    mapping (address => mapping (uint256 => UserInfo)) public userDetails;

    event Staking(address indexed staker, uint256 plan, uint256 stakingTime);
    event SetPlan(address indexed owner, uint256 PlanID, uint256 PlanstakeAmount, uint256 PlanReward);
    event RewardClaim(address indexed caller, uint256 stakeID, uint256 rewardAmount, uint256 rewardingTime);
    event Unstaking(address indexed staker, uint256 stakeID, uint256 UnstakeTime);
    event Emergency(address indexed owner, address receiver, address tokenAddress, uint256 tokenAmount);
    event SetIGLX(address indexed owner, address newIGLX);

    constructor(address IGLXToken) {
        IGLX = IERC20(IGLXToken);
        planDetails[1] = plansInfo({planID: 1, planTime:86400, planAmount: 20000e18, planReward:1e17, planMembers:0 });
        planDetails[2] = plansInfo({planID: 2, planTime:86400 * 7, planAmount: 10000e18, planReward:1e17, planMembers:0 });
        planDetails[3] = plansInfo({planID: 3, planTime:86400 * 30, planAmount: 5000e18, planReward:1e18, planMembers:0 });
    }

    receive() payable external {}

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function updatePlan(uint256 _planID, uint256 _planAmount, uint256 _planReward) external onlyOwner {
        require(_planID > 0 && _planID < 4,"invalid ");
        plansInfo storage plan = planDetails[_planID];
        plan.planAmount = _planAmount;
        plan.planReward = _planReward;
        emit SetPlan(_msgSender(), _planID, _planAmount, _planReward);
    }

    function updateIGLX(address _newIGLX) external onlyOwner {
        IGLX = IERC20(_newIGLX);
        emit SetIGLX(msg.sender, _newIGLX);
    }

    function getIDs(address _account) external view returns(uint[] memory){
        return userIDs[_account].stakeIDs;
    }

    function stakingIGLX(uint256 _tokenAmount) external whenNotPaused returns(bool){
        stakingID++;
        if(planDetails[1].planAmount == _tokenAmount){
            setPlan(1,stakingID);
        } else if(planDetails[2].planAmount == _tokenAmount){
            setPlan(2,stakingID);
        } else if(planDetails[3].planAmount == _tokenAmount){
            setPlan(3,stakingID);
        }else {
            revert("Invalid Amount");
        }
        return true;
    }

    function setPlan(uint256 _planID, uint256 _stakeID)internal {
        plansInfo storage plan = planDetails[_planID];
        UserInfo storage  user = userDetails[_msgSender()][_stakeID];
        user.user = _msgSender();
        user.planID = _planID;
        user.stakingAmount = plan.planAmount;
        user.stakingTime = block.timestamp;
        user.lastClaim = block.timestamp;
        userIDs[_msgSender()].stakeIDs.push(_stakeID);
        plan.planMembers++;

        IGLX.transferFrom(_msgSender(), address(this), user.stakingAmount);
        emit Staking(_msgSender(), _planID, user.stakingTime);
    }

    function claimReward(uint256 _stakeID) external whenNotPaused nonReentrant {
        UserInfo storage  user = userDetails[_msgSender()][_stakeID];
        plansInfo storage plan = planDetails[user.planID];
        require(user.stakingTime > 0,"user not found");
        (uint256 reward, uint256 count) = viewRewards(user.user,_stakeID);
        user.lastClaim += plan.planTime.mul(count);
        require(payable(user.user).send(reward),"Reward transaction failed");

        emit RewardClaim(_msgSender(), _stakeID, reward, block.timestamp);
    }

    function viewRewards(address _account,uint256 _stakeID) public view returns(uint256 reward,uint256 uncalimTime) {
        UserInfo storage  user = userDetails[_account][_stakeID];
        plansInfo storage plan = planDetails[user.planID];
        require(!user.unstake,"user already unstake");
        if(user.lastClaim.add(plan.planTime) <= block.timestamp){
            uncalimTime = block.timestamp.sub(user.lastClaim).div(plan.planTime);
            reward = (plan.planReward).mul(uncalimTime);
        } else{
            uncalimTime = 0;
            reward = 0;
        }
    }

    function unStake(uint256 _stakeID) external whenNotPaused nonReentrant {
        UserInfo storage  user = userDetails[_msgSender()][_stakeID];
        plansInfo storage plan = planDetails[user.planID];
        require(user.stakingTime > 0,"user not found");
        require(!user.unstake,"user already unstaked");
        user.unstake = true;
        plan.planMembers--;
        IGLX.transfer(_msgSender(), user.stakingAmount);

        emit Unstaking(_msgSender(), _stakeID, block.timestamp);
    }

    function emergency(address _tokenAddress, address _to, uint256 _tokenAmount) external onlyOwner {
        if(_tokenAddress == address(0x0)){
            require(payable(_to).send(_tokenAmount),"send Amount Failed");
        } else {
            IERC20(_tokenAddress).transfer(_to, _tokenAmount);
        }
        emit Emergency(msg.sender, _to, _tokenAddress, _tokenAmount);
    }
}