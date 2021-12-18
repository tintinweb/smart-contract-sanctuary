// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './ERC20.sol';
import './IERC20.sol';
import './Ownable.sol';
import './SafeMath.sol';

contract MyMongStaking is Ownable {
    using SafeMath for uint256;
    IERC20 public tokenStaking;
    uint256 public _decimals;
    uint256 public _packageCount;
    uint256 public earlyFeePercentage;

    mapping(uint256 => PackageStaking) private packages;

    mapping(address => StakingInfo) private stakingInfo;

    struct PackageStaking{
        uint256 duration;
        uint256 percentage;
        bool active;
    }

    struct StakingInfo {
        uint256 amountDeposit;
        uint256 registerTime;
        uint256 lastTimeClaim;
        uint256 expireTime;
        uint256 packageId;
    }

    // constructor
    constructor(address tokenAddress, uint8 decimals_ , uint256 earlyFeePercentage_) {
        tokenStaking = IERC20(tokenAddress);
        
        _decimals = decimals_;
        _packageCount = 0;
        earlyFeePercentage = earlyFeePercentage_;
        addPackage(10,100000000000000000,true);
        addPackage(15,200000000000000000,true);
        addPackage(20,300000000000000000,true);
        addPackage(25,400000000000000000,true);
    }

    // package info
    function packageInfo(uint256 idPackage) public view returns (PackageStaking memory) {
        return packages[idPackage];        
    }

    // add package
    function addPackage(uint256 duration, uint256 percentage, bool active) onlyOwner public  {
        packages[_packageCount++]= PackageStaking(duration.mul(86400), percentage, active);        
    }

    // edit package
    function editPackage(uint256 idPackage,uint256 duration, uint256 percentage, bool active)  onlyOwner public {
        require(idPackage< _packageCount);
        packages[_packageCount++]= PackageStaking(duration.mul(86400), percentage, active);        
    }


    // deposit
    function deposit(uint256 amount, uint256 packageId) public {
        require(!_doStaking(msg.sender),"Cannot restaking ");
        require(packageId < _packageCount && packages[packageId].duration >0 || packages[packageId].active == true, "Can't find package or packages is off" );
        require(amount>0,"amount invalid");
        require(tokenStaking.balanceOf(msg.sender) > amount, "you account not have money");
        tokenStaking.transferFrom(msg.sender, address(this), amount);
        uint256 currentTime = block.timestamp;
        stakingInfo[msg.sender] = StakingInfo(amount, currentTime, currentTime, currentTime+packages[packageId].duration, packageId);
    }

    // daily claim
    function claim() public{
        require(_doStaking(msg.sender),"You not staking");
        require((stakingInfo[msg.sender].lastTimeClaim + 60) < block.timestamp, "Cannot claim before 24h" );
        (uint256 amountReward, uint256 totalDivideReward, uint256 timeDivide) = _calculatorClaim(msg.sender);
        require(amountReward > 0 ,"Nothing staking");
        require(tokenStaking.balanceOf(address(this)) >= amountReward, "Smartcontract not enough money" );
        tokenStaking.transfer(msg.sender, amountReward);
        stakingInfo[msg.sender].lastTimeClaim= stakingInfo[msg.sender].lastTimeClaim.add(totalDivideReward.mul(timeDivide) );
    }

    // withdraw
    function withdraw() public {
        require(_doStaking(msg.sender),"You not staking");
        (uint256 amountReward, , ) = _calculatorClaim(msg.sender);
        if(block.timestamp >= stakingInfo[msg.sender].expireTime){
            uint256 total = amountReward.add(stakingInfo[msg.sender].amountDeposit);
            require(tokenStaking.balanceOf(msg.sender) >= total, "Smartcontract not enough money");
            tokenStaking.transfer(msg.sender, total);
        }else{
            uint256 total = amountReward.add(stakingInfo[msg.sender].amountDeposit);
            total= total.sub(total.mul(earlyFeePercentage).div(10**_decimals));
            require(tokenStaking.balanceOf(msg.sender) >= total, "Smartcontract not enough money");
            tokenStaking.transfer(msg.sender, total);
        }
        _clear(msg.sender);
    }

    // clear
    function _clear(address a) internal {
        stakingInfo[a].amountDeposit = 0;
        stakingInfo[a].registerTime=0;
        stakingInfo[a].lastTimeClaim=0;
        stakingInfo[a].packageId=0;
        stakingInfo[a].expireTime=0;
    }

    // withdraw to owner
    function ownerWithdrawAll() onlyOwner public {
        tokenStaking.transfer(owner(), tokenStaking.balanceOf(address(this)));
    }


    // calculate claim
    function _calculatorClaim(address a) internal view returns (uint256 amountReward, uint256 totalDivideReward,uint256 timeDivide){
        StakingInfo memory info = stakingInfo[a];
        timeDivide = 60;
        if( info.registerTime == 0 || info.amountDeposit ==0) return (0,0, timeDivide);
        PackageStaking memory pack = packages[info.packageId];
        
        uint256 currentTimeReward = block.timestamp > info.expireTime ? info.expireTime: block.timestamp;
        
        
        if(currentTimeReward.sub(info.lastTimeClaim)>=timeDivide){
            totalDivideReward = currentTimeReward.sub(info.lastTimeClaim).div(timeDivide);
            uint256 timeEarnReward = info.lastTimeClaim.add(totalDivideReward.mul(timeDivide));
            uint256 amount =(info.amountDeposit.mul(pack.percentage).mul(timeEarnReward.sub(info.lastTimeClaim)).div(pack.duration)).div(10**_decimals);
            return (amount, totalDivideReward, timeDivide);
        }else{
            return (0,0, timeDivide);
        }
    }

    // address staking info
    function stakingInfoOf(address a) public view  returns (uint256 amountDeposit,
        uint256 registerTime,
        uint256 lastTimeClaim,
        uint256 expireTime,
        uint256 packageId,
        uint256 nextTimeClaim){
        StakingInfo memory info = stakingInfo[a];        
        return( info.amountDeposit,
            info.registerTime,
            info.lastTimeClaim,
            info.expireTime,
            info.packageId,
            info.lastTimeClaim.add(60) //
        );
    }

    // pending claim
    function calculatorClaim() public view  returns (uint256 amountReward,uint256 totalDivideReward,uint256 timeDivide) {
        return _calculatorClaim(msg.sender);
    }

    function _doStaking(address a) internal view returns (bool doStaking) {
        StakingInfo memory info = stakingInfo[a];        
        
        return  info.amountDeposit!=0;
    }

    // check staking
    function doStakingOf(address a) public view returns (bool doStaking) {
        return _doStaking(a);
    }

}