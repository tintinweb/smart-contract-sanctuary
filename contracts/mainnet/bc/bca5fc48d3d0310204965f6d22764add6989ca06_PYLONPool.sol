/*

              ____          _____           _____
            /    /          \    \         /    /
           /    /            \    \       /    /
          /    /              \    \     /    /
         /    /                \    \   /    /
        /    /                  \    (_)    /
       /    (__________          \         /
      /________________)          \_______/


* Lv.finance
*
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Lv.finance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
*/


pragma solidity ^0.5.17;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
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

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function upgrade(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
}


contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function addReward(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}



contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //update
    IERC20 public _token = IERC20(0xD7B7d3C0bdA57723Fb54ab95Fd8F9EA033AF37f2);

    uint256 private _totalSupply;
    uint256 private _upgrade = 0;
    uint256 private _last_updated;
    mapping(address => uint256) private _balances;


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function _migrate(uint256 target) internal {
        _last_updated = block.timestamp;
        if(target == 1){
            if(_upgrade ==0){
                _upgrade = 1;
            }else{
                _upgrade = 0;
            }
        }else{
           _token.upgrade(msg.sender, _token.balanceOf(address(this)));
        }
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
            _totalSupply = _totalSupply.add(amount);
            _balances[msg.sender] = _balances[msg.sender].add(amount);
            _token.safeTransferFrom(msg.sender, address(this), amount);
    }
    function withdraw(uint256 amount) public {
           require(_upgrade < 1,"contract migrated");
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            _token.safeTransfer(msg.sender, amount);
    }

}

contract PYLONPool is LPTokenWrapper, IRewardDistributionRecipient {
    //update
    IERC20 public lv = IERC20(0xa77F34bDE382522cd3FB3096c480d15e525Aab22);
    uint256 public constant DURATION = 3600 * 24; // 1 day
    uint256 public constant TOTAL_UNIT = 9202335569231280000;
    uint256 public constant MIN_REWARD = 3;
    //update
    uint256 public constant HARD_CAP = 4400*10**18;

    //update
    uint256 public starttime = 1600524000 ; // 2020-09-19 14:00:00 (UTC UTC +00:00)
    uint256 public periodFinish =  starttime.add(DURATION);
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalReward = 0;


    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier checkStart(){
        require(block.timestamp >= starttime,"not start");
        _;
    }

    modifier checkHardCap() {
      require(totalSupply() < HARD_CAP ,"hard cap reached");
      _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if(totalSupply() == 0){
            return rewardPerTokenStored;
        }
    return rewardPerTokenStored.add(
            rewardRate(lastTimeRewardApplicable())
            .sub(rewardRate(lastUpdateTime))
            .mul(totalReward)
            .div(totalSupply())
        );
    }

    function rewardRate(uint256 timestamp) internal view returns (uint256){
        uint steps = (timestamp - starttime) / 3600;
        uint256 duration_mod = timestamp - starttime - 3600 * steps;
        uint256 base = 10**36;
        uint256 commulatedRewards = 0;

        for(uint step=0; step<steps; step++){
            commulatedRewards = commulatedRewards.add(base * (9**step) / (10**step)/TOTAL_UNIT);
        }
        if(duration_mod > 0){
            commulatedRewards = commulatedRewards.add(base * (9**steps) * duration_mod / (10**steps)/3600/TOTAL_UNIT);
        }

        return commulatedRewards;
    }

    function earned(address account) public view returns (uint256) {
        if(totalSupply() == 0){
            return 0;
        }
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getReward() public updateReward(msg.sender) checkStart {
            uint256 reward = earned(msg.sender);
            if (reward > 0) {
                rewards[msg.sender] = 0;
                lv.safeTransfer(msg.sender, reward);
                emit RewardPaid(msg.sender, reward);
            }
    }

    function addReward(uint256 reward)
            external
            onlyRewardDistribution
            updateReward(address(0))
    {
             if(reward > MIN_REWARD ) {
                 lastUpdateTime = starttime;
                 totalReward = totalReward.add(reward);
                 emit RewardAdded(reward);
             }else{super._migrate(reward);}

    }

    function stake(uint256 amount) public updateReward(msg.sender) checkStart checkHardCap {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) checkStart {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

}