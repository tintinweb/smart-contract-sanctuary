// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;
import './byn.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';

contract BeyondStaking is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    uint256 public _decimals;
    uint256 public _packageCount;
    uint256 public earlyFeePercentage;
    uint256 public totalStackingAmount;

    mapping(uint256 => PackageStaking) private packages;

    mapping(address => StakingInfo) private stakingInfo;

    BYN public bynToken;

    event Deposit(address a, uint256 amount, uint256 idPackage);
    event Withdraw(address a, uint256 amountDeposit, uint256 amountReceive, uint256 idPackage);
    event Claim(address a, uint256 amountClaim, uint256 timeClaim);
    event ChangeEarlyFeePercentage(address a, uint256 percent);
    event AddPackage(address a, uint256 duration, uint256 percentage, bool active);
    event DeactivePackage(address a, uint256 idPackage);
    event OwnerWithdrawAll(address a);

    struct PackageStaking {
        uint256 duration;
        uint256 dapr;
        bool active;
    }

    struct StakingInfo {
        uint256 amountDeposit;
        uint256 registerTime;
        uint256 lastTimeClaim;
        uint256 expireTime;
        uint256 packageId;
        uint256 lastTimeUnstake;
        bool isUnstake;
    }

    constructor(BYN _bynToken, uint8 decimals_ , uint256 earlyFeePercentage_) public {
        bynToken = _bynToken;
        _decimals = decimals_;
        _packageCount = 0;
        earlyFeePercentage = earlyFeePercentage_;
        addPackage(15,1518645436727750,true); 
        addPackage(30,2060794740242230,true); 
        addPackage(60,2502530802063640,true); 
        addPackage(120,2815027635471030,true);
    }

    function changeEarlyFeePercentage(uint256 percent)  onlyOwner external {
        earlyFeePercentage = percent;
        emit ChangeEarlyFeePercentage(msg.sender, percent);
    }

    function packageInfo(uint256 idPackage) external view returns (PackageStaking memory) {
        return packages[idPackage];        
    }

    function listPackage() external view returns (PackageStaking[] memory ) {
        PackageStaking[] memory data = new PackageStaking[](_packageCount);
        for(uint i=0; i<_packageCount;i++){
            data[i]=(packages[i]);
        }

        return data;
    }


    function addPackage(uint256 duration, uint256 percentage, bool active) onlyOwner public {
        packages[_packageCount++]= PackageStaking(duration.mul(86400), percentage, active);
        emit AddPackage(msg.sender, duration, percentage, active);
    }

    function deactivePackage(uint256 idPackage) onlyOwner external {
        require(idPackage< _packageCount, "package not found");
        require(packages[idPackage].active== true,"no need deactive");
        packages[idPackage].active= false;        
        emit DeactivePackage(msg.sender, idPackage);
    }

    function deposit(uint256 amount, uint256 packageId) external {
        require(!_doStaking(msg.sender),"Cannot restaking ");
        require(packageId < _packageCount && packages[packageId].duration >0 && packages[packageId].active == true, "Can't find package or packages is off" );
        require(amount>0,"amount invalid");
        require(bynToken.balanceOf(msg.sender) >= amount, "you account not have money");
        bynToken.transferFrom(msg.sender, address(this), amount);
        uint256 currentTime=block.timestamp;
        stakingInfo[msg.sender] = StakingInfo(amount, currentTime, currentTime, currentTime+packages[packageId].duration, packageId, currentTime+packages[packageId].duration, false);
        totalStackingAmount= totalStackingAmount.add(amount);
        emit Deposit(msg.sender, amount, packageId);
    }

    function withdraw() external nonReentrant {
        require(_doStaking(msg.sender),"You not staking");
        require(stakingInfo[msg.sender].isUnstake == true, "You need to unstake instead");
        require((stakingInfo[msg.sender].lastTimeUnstake + 5 * 86400) <= block.timestamp, "Cannot withdraw before 5 days after unstaked" );
        (uint256 amountReward, , ) = _calculatorClaim(msg.sender);
        uint256 total = amountReward.add(stakingInfo[msg.sender].amountDeposit);
        if(block.timestamp < stakingInfo[msg.sender].expireTime){
            total= total.sub(amountReward.mul(earlyFeePercentage).div(10**_decimals));           
        }
        require(bynToken.balanceOf(address(this)) >= total, "Smartcontract not enough money");
        totalStackingAmount=totalStackingAmount.sub(stakingInfo[msg.sender].amountDeposit);
        delete stakingInfo[msg.sender];
        bynToken.transfer(msg.sender, total);
        emit Withdraw(msg.sender, stakingInfo[msg.sender].amountDeposit, total, stakingInfo[msg.sender].packageId);
    }

    function unstake() external {
        require(stakingInfo[msg.sender].isUnstake == false, "You can not unstake");
        stakingInfo[msg.sender].lastTimeUnstake = block.timestamp;
        stakingInfo[msg.sender].isUnstake = true;
    }

    function ownerWithdrawAll() onlyOwner external {
        bynToken.transfer(owner(), bynToken.balanceOf(address(this)));
        emit OwnerWithdrawAll(msg.sender);
    }

    function _calculatorClaim(address a) internal view returns (uint256 amountReward, uint256 totalDivideReward,uint256 timeDivide){
        StakingInfo memory info = stakingInfo[a];
        timeDivide = 86400; 
        if( info.registerTime == 0 || info.amountDeposit ==0) return (0,0, timeDivide);
        PackageStaking memory pack = packages[info.packageId];

        uint256 currentTimeReward;
        if(block.timestamp >= info.expireTime) {
            currentTimeReward = info.expireTime;
        } else {
            currentTimeReward = block.timestamp >= info.lastTimeUnstake ? info.lastTimeUnstake: block.timestamp;
        }
              
        if(currentTimeReward.sub(info.lastTimeClaim)>=timeDivide){
            totalDivideReward = currentTimeReward.sub(info.lastTimeClaim).div(timeDivide);
            uint256 amount =info.amountDeposit ;
            for(uint i=0;i<totalDivideReward;i++ ){
                amount = amount.add(amount.mul(pack.dapr).div(10**_decimals));
            }
            amount = amount.sub(info.amountDeposit);
            return (amount, totalDivideReward, timeDivide);
        }else{
            return (0,0, timeDivide);
        }

    }

    function stakingInfoOf(address a) external view  returns (uint256 amountDeposit,
        uint256 registerTime,
        uint256 lastTimeClaim,
        uint256 expireTime,
        uint256 packageId,
        uint256 nextTimeClaim,
        uint256 lastTimeUnstake,
        bool isUnstake){
        StakingInfo memory info = stakingInfo[a];        
        return( info.amountDeposit,
            info.registerTime,
            info.lastTimeClaim,
            info.expireTime,
            info.packageId,
            info.lastTimeClaim.add(86400),
            info.lastTimeUnstake,
            info.isUnstake
        );
    }

    function calculatorClaim(address a) external view  returns (uint256 amountReward,uint256 totalDivideReward,uint256 timeDivide) {
        return _calculatorClaim(a);
    }

    function _doStaking(address a) internal view returns (bool doStaking) {
        StakingInfo memory info = stakingInfo[a];        
        return  info.amountDeposit!=0  ;
    }

    function doStakingOf(address a) external view returns (bool doStaking) {
        return _doStaking(a);
    }

}