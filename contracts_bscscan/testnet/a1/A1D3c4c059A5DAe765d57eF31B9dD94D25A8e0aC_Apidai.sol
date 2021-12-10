/**
 *Submitted for verification at BscScan.com on 2021-12-10
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

contract Apidai is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    uint256 public APYpercentage;
    IBEP20 public ApidaiToken;
    IBEP20 public BUSD;
    uint256 public stakeDays = 365;
    uint256 public stakeLimit;
    uint256 public totalStakedToken;
    uint256 public currentStakeID;
    uint256 public rewardDeposit;

    struct UserInfo {
        address staker;
        uint256 stakeID;
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 unstakeTime;
        uint256 stakingDays;
        uint256 APY_percentage;
        uint256 rewardAmount;
        bool unstaked;
    }
    
    struct userID{
        uint256[] stakeIDs;
    }

    mapping(address => mapping(uint256 => UserInfo)) public userDetails;
    mapping(address => userID) internal userIDs;
    mapping(address => uint256) internal userTotalBalance;

    event emergencySafe(address indexed receiver, address tokenAddressss, uint256 TokenAmount);
    event stakeing(address indexed staker, uint256 stakeID, uint256 stakeAmount, uint256 stakeTime);
    event unstakeing(address indexed staker, uint256 stakeID, uint256 rewardAmount, uint256 UnstakeTime);
    event setAPYPercentage(address indexed owner, uint256 newPercentage);
    event setApidaiToken(address indexed owner, address ApidaiToken);
    event setBUSDToken(address indexed owner, address BUSDToken);
    event setMaxTokenStake(address indexed owner, uint256 maxStakeToken);
    event adminDeposits(address indexed owner, uint256 RewardDepositamount);

    constructor ( uint256 _APYPcent, uint256 _maxTokenStake, address _apidaiAddress, address _BUSD) {
        APYpercentage = _APYPcent;
        stakeLimit = _maxTokenStake;
        ApidaiToken = IBEP20(_apidaiAddress);
        BUSD = IBEP20(_BUSD);
    }

    function userTotalStakedBalance(address _account) external view returns(uint256 stakeAmount){
        return userTotalBalance[_account];
    }

    function userStakeIDs(address _account) external view returns(uint256[] memory stakeIDs){
        return userIDs[_account].stakeIDs;
    }

    function updateAPYpercentage(uint256 _newPercenrtage) external onlyOwner whenNotPaused {
        APYpercentage = _newPercenrtage;
        emit setAPYPercentage(msg.sender , _newPercenrtage);
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
        user.APY_percentage = APYpercentage;
        totalStakedToken = totalStakedToken.add(_tokenAmount);
        userIDs[msg.sender].stakeIDs.push(currentStakeID);

        ApidaiToken.transferFrom(msg.sender, address(this), _tokenAmount);
        emit stakeing(msg.sender, currentStakeID, _tokenAmount, block.timestamp);
    }

    function unstakeApidai(uint256 _stakeID) external nonReentrant whenNotPaused {
        UserInfo storage user = userDetails[msg.sender][_stakeID];
        require(user.stakeTime > 0 , "Invalid stake ID");
        require(!user.unstaked, "user already claim this ID");
        user.unstakeTime = block.timestamp;
        user.unstaked = true;
        totalStakedToken = totalStakedToken.sub(user.stakeAmount);
        user.stakingDays = (block.timestamp.sub(user.stakeTime).div(86400));
        uint256 rewardAmount = pendingReward(_stakeID, msg.sender);
        user.rewardAmount = rewardAmount;
        rewardDeposit = rewardDeposit.sub(rewardAmount);
        ApidaiToken.transfer(msg.sender, user.stakeAmount);
        BUSD.transfer(msg.sender, rewardAmount);

        emit unstakeing(msg.sender, _stakeID, rewardAmount, block.timestamp);
    }

    function pendingReward(uint256 _stakeID, address staker) public view returns(uint256 Reward) {
        UserInfo storage user = userDetails[staker][_stakeID];
        require(user.unstakeTime == 0, "User already unstaked");
        if(365 <= (block.timestamp).sub(user.stakeTime).div(86400)){
            Reward = user.stakeAmount.mul(user.APY_percentage).div(100);
        }   else {
            uint256[3] memory localVar;
            localVar[0] = (block.timestamp).sub(user.stakeTime);
            localVar[1] = (user.APY_percentage).mul(1e16).div(stakeDays);
            Reward = user.stakeAmount.mul(localVar[0]).mul(localVar[1]).div(100).div(1e16).div(86400);
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