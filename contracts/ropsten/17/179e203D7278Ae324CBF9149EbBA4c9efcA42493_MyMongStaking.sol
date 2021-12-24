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
    uint256 public totalStackingAmount;

    mapping(uint256 => PackageStaking) private packages;

    mapping(address => StakingInfo) private stakingInfo;

    event Deposit(address a, uint256 amount, uint256 idPackage);
    event Withdraw(address a, uint256 amountDeposit, uint256 amountReceive, uint256 idPackage);
    event Claim(address a, uint256 amountClaim, uint256 timeClaim);

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
    }

    constructor(address tokenAddress, uint8 decimals_ , uint256 earlyFeePercentage_) {
        tokenStaking = IERC20(tokenAddress);
        
        _decimals = decimals_;
        _packageCount = 0;
        earlyFeePercentage = earlyFeePercentage_;
        addPackage(15,862867233567544,true);
        addPackage(30,1288510593391520,true);
        addPackage(60,1887078676226620,true);
        addPackage(120,2502530802063640,true);
    }

    function changeEarlyFeePercentage(uint256 percent)  onlyOwner public {
        earlyFeePercentage = percent;
    }

    function packageInfo(uint256 idPackage) public view returns (PackageStaking memory) {
        return packages[idPackage];        
    }

    function listPackage() public view returns (PackageStaking[] memory ) {
        PackageStaking[] memory data = new PackageStaking[](_packageCount);
        for(uint i=0; i<_packageCount;i++){
            data[i]=(packages[i]);
        }

        return data;
    }


    function addPackage(uint256 duration, uint256 percentage, bool active) onlyOwner public {
        packages[_packageCount++]= PackageStaking(duration.mul(120), percentage, active);
    }

    function deactivePackage(uint256 idPackage) onlyOwner public {
        require(idPackage< _packageCount);
        require(packages[idPackage].active== true,"no need deactive");
        packages[idPackage].active= false;        
    }

    function deposit(uint256 amount, uint256 packageId) public {
        require(!_doStaking(msg.sender),"Cannot restaking ");
        require(packageId < _packageCount && packages[packageId].duration >0 || packages[packageId].active == true, "Can't find package or packages is off" );
        require(amount>0,"amount invalid");
        require(tokenStaking.balanceOf(msg.sender) >= amount, "you account not have money");
        tokenStaking.transferFrom(msg.sender, address(this), amount);
        uint256 currentTime=block.timestamp;
        stakingInfo[msg.sender] = StakingInfo(amount, currentTime, currentTime, currentTime+packages[packageId].duration, packageId, currentTime+packages[packageId].duration);
        totalStackingAmount= totalStackingAmount.add(amount);
        emit Deposit(msg.sender, amount, packageId);
    }

    function withdraw() public {
        require(_doStaking(msg.sender),"You not staking");
        require(stakingInfo[msg.sender].lastTimeUnstake > 0, "You need to unstake instead");
        require((stakingInfo[msg.sender].lastTimeUnstake + 600) <= block.timestamp, "Cannot withdraw before 5 days after unstaked" );
        (uint256 amountReward, , ) = _calculatorClaim(msg.sender);
        uint256 total=0;
        if(block.timestamp >= stakingInfo[msg.sender].expireTime){
            total = amountReward.add(stakingInfo[msg.sender].amountDeposit);
            require(tokenStaking.balanceOf(address(this)) >= total, "Smartcontract not enough money");
            tokenStaking.transfer(msg.sender, total);
        }else{
            total = amountReward.add(stakingInfo[msg.sender].amountDeposit);
            total= total.sub(amountReward.mul(earlyFeePercentage).div(10**_decimals));
            require(tokenStaking.balanceOf(address(this)) >= total, "Smartcontract not enough money");
            tokenStaking.transfer(msg.sender, total);
        }
        totalStackingAmount=totalStackingAmount.sub(stakingInfo[msg.sender].amountDeposit);
        emit Withdraw(msg.sender, stakingInfo[msg.sender].amountDeposit, total, stakingInfo[msg.sender].packageId);
        _clear(msg.sender);
    }

    function unstake() public {
        require(block.timestamp <= stakingInfo[msg.sender].lastTimeUnstake, "You can not unstake");
        stakingInfo[msg.sender].lastTimeUnstake = block.timestamp;
    }

    function _clear(address a) internal {
        stakingInfo[a].amountDeposit = 0;
        stakingInfo[a].registerTime = 0;
        stakingInfo[a].lastTimeClaim = 0;
        stakingInfo[a].packageId = 0;
        stakingInfo[a].expireTime = 0;
        stakingInfo[a].lastTimeUnstake = 0;
    }

    function ownerWithdrawAll() onlyOwner public {
        tokenStaking.transfer(owner(), tokenStaking.balanceOf(address(this)));
    }

    function _calculatorClaim(address a) internal view returns (uint256 amountReward, uint256 totalDivideReward,uint256 timeDivide){
        StakingInfo memory info = stakingInfo[a];
        timeDivide = 120; 
        if( info.registerTime == 0 || info.amountDeposit ==0) return (0,0, timeDivide);
        PackageStaking memory pack = packages[info.packageId];
        
        uint256 currentTimeReward = block.timestamp >= info.lastTimeUnstake ? info.lastTimeUnstake: block.timestamp;
        
        
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

    function stakingInfoOf(address a) public view  returns (uint256 amountDeposit,
        uint256 registerTime,
        uint256 lastTimeClaim,
        uint256 expireTime,
        uint256 packageId,
        uint256 nextTimeClaim,
        uint256 lastTimeUnstake){
        StakingInfo memory info = stakingInfo[a];        
        return( info.amountDeposit,
            info.registerTime,
            info.lastTimeClaim,
            info.expireTime,
            info.packageId,
            info.lastTimeClaim.add(86400),
            info.lastTimeUnstake
        );
    }

    function calculatorClaim(address a) public view  returns (uint256 amountReward,uint256 totalDivideReward,uint256 timeDivide) {
        return _calculatorClaim(a);
    }

    function _doStaking(address a) internal view returns (bool doStaking) {
        StakingInfo memory info = stakingInfo[a];        
        return  info.amountDeposit!=0  ;
    }

    function doStakingOf(address a) public view returns (bool doStaking) {
        return _doStaking(a);
    }

}