/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getOwner() external view returns (address);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract USxD_Staking is Ownable {

    uint256 BASE_AMT = 300; // 300 BUSD
    uint256 REWARD_APY = 25; // 0.25 %
    uint256 NETWORK_APY = 3; // 0.03 %
    uint256 constant PERCENT_DIV = 10000;
    uint256 constant REWARD_DIV = 1 days;

    IERC20 token;
    constructor(){
        token = IERC20(0xB6DE30cEA4e8AF670C84B893bBd83A2a24312fD9);
    }
    
    struct UserDetails{
        Stake[] stakes;
        
    }

    struct Stake {
        uint256 totalStaked;
        uint256 timeStaked;
        uint256 duration;
        uint256 totalRevived;
        uint256 totalWithdrawn; // xxx
        uint256 lastRevived;
    }

    struct RetirementWallet{
        uint256 retireFund;
        uint256 expiryTime;
    }

    mapping(address => Stake) public stakeDetails; // need an array for all packages
    mapping(address => uint256) public referalPlan;
    mapping(address => RetirementWallet) public retireWallet;

    event STAKED(address user, uint256 amount);
    event REVIVED(address user, uint256 amount);
    event LOCKED(address user, uint256 amount);
    event REFBONUS(address user, uint256 amount);
    event Base_Amount_Changed(uint256 oldAmount, uint256 newAMount);
    event Reward_Apy_Changed(uint256 oldAmount, uint256 newAMount);
    event TokenUpdated(address OldTokenAdd, address NewTokenAdd);
    event REFERAL_PLAN_ADDED(address userAddress, uint256 plan);

    function stake(address userAddress, uint256 duration,  uint256 tokenAmount) external returns(bool){
        
        require(tokenAmount % BASE_AMT == 0, "USxD: Amount not valid");
        require(token.allowance(userAddress, address(this)) > tokenAmount, "USxD: allowance not enough");
        token.transferFrom(userAddress, address(this), tokenAmount);

        Stake storage _user = stakeDetails[userAddress];
        _user.totalStaked += tokenAmount;
        _user.timeStaked = block.timestamp;
        _user.duration = REWARD_DIV * duration; // xxx
        _user.lastRevived = block.timestamp;
        emit STAKED(userAddress, tokenAmount);
        return true;
    }

    function setReferalPlan(address userAddress, uint256 plan) external returns(bool){
        require(plan > 0 && plan < 4, "setReferalPlan: Invalid input");
        referalPlan[userAddress] = plan;
        emit REFERAL_PLAN_ADDED(userAddress, plan);
        return true;
    }

    function claim(address userAddress) external returns(bool){
        uint256 amt = calculateReward(userAddress);
        require(amt > 0, "Nothing to claim");

        Stake storage _user = stakeDetails[userAddress];
        _user.totalRevived += amt*7/10;
        _user.lastRevived = block.timestamp;

        // send to RetirementWallet
        retireWallet[userAddress].retireFund += amt*3/10;

        // token.transfer(userAddress, amt);

        emit REVIVED(userAddress, amt*7/10);
        emit LOCKED(userAddress, amt*3/10);
        return true;
    }

    function calculateReward(address userAddress) public view returns(uint256){
        uint256 reward = (block.timestamp-stakeDetails[userAddress].lastRevived)/ REWARD_DIV;
        if(referalPlan[userAddress]>0){

        }
        return reward * REWARD_APY/PERCENT_DIV;
    }

    function claimLockup() external pure returns(uint256){
        return (uint256(1628342139)+10 days);
    }

    function updateBaseAmt(uint256 newAmt) external onlyOwner returns(bool){
        require(BASE_AMT != newAmt, "Invalid Amount");
        emit Base_Amount_Changed(BASE_AMT, newAmt);
        BASE_AMT = newAmt;
        return true;
    }

    function updateRewardApy(uint256 newAmt) external onlyOwner returns(bool){
        require(REWARD_APY != newAmt, "Invalid Amount");
        emit Reward_Apy_Changed(REWARD_APY, newAmt);
        REWARD_APY = newAmt;
        return true;
    }

    function updateToken(address _newToken) external onlyOwner returns(bool){
        require(address(token)!= _newToken, "Invalid Input");
        emit TokenUpdated(address(token), _newToken);
        token = IERC20(_newToken);
        return true;
    }
}