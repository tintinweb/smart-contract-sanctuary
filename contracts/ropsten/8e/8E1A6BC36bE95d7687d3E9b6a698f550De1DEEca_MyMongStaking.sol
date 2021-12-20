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
    uint256 public _packageCount; // total number package
    uint256 public earlyFeePercentage; // % fee early withdraw  ;
    uint256 public totalStackingAmount; //  total amount token staking 

    mapping(uint256 => PackageStaking) private packages; // list package 

    mapping(address => StakingInfo) private stakingInfo; //  address staking 

    event Deposit(address a, uint256 amount, uint256 idPackage);
    event Withdraw(address a, uint256 amountDeposit, uint256 amountReceive, uint256 idPackage);
    event Claim(address a, uint256 amountClaim, uint256 timeClaim);


    //struct staking package
    struct PackageStaking{
        uint256 duration;// package duration in seconds, minimum request is 1 day,
        uint256 dapr; // compound interest daily
        bool active; // Is it possible to staking?
    }

    //struct address staking
    struct StakingInfo {
        uint256 amountDeposit;
        uint256 registerTime;
        uint256 lastTimeClaim;
        uint256 expireTime;
        uint256 packageId;
    }

    // erc20 address
    // decimals of erc20 token
    // earlyFeePercentage_: fee early withdraw, calculator with decimals, example with decimal = 8 => 5% = 0.05*(10^8) = 5 000 000
    constructor(address tokenAddress, uint8 decimals_ , uint256 earlyFeePercentage_) {
        tokenStaking = IERC20(tokenAddress);
        
        _decimals = decimals_;
        _packageCount = 0;
        earlyFeePercentage = earlyFeePercentage_;
        addPackage(15,862867233567544,true);
        addPackage(30,1288510593391520,true);
        addPackage(60,1887078676226620,true);
        addPackage(120,2502530802063640,true);

        addPackage(15,862867233567544,true);
        addPackage(30,1288510593391520,true);
        addPackage(60,1887078676226620,true);
        addPackage(120,2502530802063640,true);

        addPackage(15,862867233567544,true);
        addPackage(30,1288510593391520,true);
        addPackage(60,1887078676226620,true);
        addPackage(120,2502530802063640,true);

    }

    //update fee early withdraw
    function changeEarlyFeePercentage(uint256 percent)  onlyOwner public {
        earlyFeePercentage=   percent;
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


    //add package, duration in days
    function addPackage(uint256 duration, uint256 percentage, bool active) onlyOwner public  {
        // packages[_packageCount++]= PackageStaking(duration.mul(86400), percentage, active);       
        packages[_packageCount++]= PackageStaking(duration.mul(120), percentage, active);//using for test
    }

    //deactive package
    function deactivePackage(uint256 idPackage)  onlyOwner public {
        require(idPackage< _packageCount);
        require(packages[idPackage].active== true,"no need deactive");
        packages[idPackage].active= false;        
    }


    //The caller must approve the token for the smart contract's address first.
    function deposit(uint256 amount, uint256 packageId) public {
        require(!_doStaking(msg.sender),"Cannot restaking ");
        require(packageId < _packageCount && packages[packageId].duration >0 || packages[packageId].active == true, "Can't find package or packages is off" );
        require(amount>0,"amount invalid");
        require(tokenStaking.balanceOf(msg.sender) > amount, "you account not have money");
        tokenStaking.transferFrom(msg.sender, address(this), amount);
        uint256 currentTime=block.timestamp;
        stakingInfo[msg.sender] = StakingInfo(amount, currentTime, currentTime, currentTime+packages[packageId].duration, packageId);
        totalStackingAmount= totalStackingAmount.add(amount);
        emit Deposit(msg.sender, amount, packageId);
    }

    //claim 
    function claim() public{
        require(_doStaking(msg.sender),"You not staking");
        require((stakingInfo[msg.sender].lastTimeClaim + 86400) < block.timestamp, "Cannot claim before 24h" );
        (uint256 amountReward, uint256 totalDivideReward, uint256 timeDivide) = _calculatorClaim(msg.sender);
        require(amountReward > 0 ,"no reward");
        require(tokenStaking.balanceOf(address(this)) >= amountReward, "Smartcontract not enough money" );
        tokenStaking.transfer(msg.sender, amountReward);
        stakingInfo[msg.sender].lastTimeClaim= stakingInfo[msg.sender].lastTimeClaim.add(totalDivideReward.mul(timeDivide) );
        emit Claim(msg.sender, amountReward, block.timestamp);
    }

    //withdraw all amount deposit and claim available
    function withdraw() public {
        require(_doStaking(msg.sender),"You not staking");
        (uint256 amountReward, , ) = _calculatorClaim(msg.sender);
        uint256 total=0;
        if(block.timestamp >= stakingInfo[msg.sender].expireTime){
            total = amountReward.add(stakingInfo[msg.sender].amountDeposit);
            require(tokenStaking.balanceOf(address(this)) >= total, "Smartcontract not enough money");
            tokenStaking.transfer(msg.sender, total);
        }else{
            total = amountReward.add(stakingInfo[msg.sender].amountDeposit);
            total= total.sub(total.mul(earlyFeePercentage).div(10**_decimals));
            require(tokenStaking.balanceOf(address(this)) >= total, "Smartcontract not enough money");
            tokenStaking.transfer(msg.sender, total);
        }
        totalStackingAmount=totalStackingAmount.sub(stakingInfo[msg.sender].amountDeposit);
        emit Withdraw(msg.sender, stakingInfo[msg.sender].amountDeposit, total, stakingInfo[msg.sender].packageId);
        _clear(msg.sender);
    }

    //setup lại sau khi withdraw
    function _clear(address a) internal {
        stakingInfo[a].amountDeposit = 0;
        stakingInfo[a].registerTime=0;
        stakingInfo[a].lastTimeClaim=0;
        stakingInfo[a].packageId=0;
        stakingInfo[a].expireTime=0;
    }

    //owner withdraw all token of smartcontract
    function ownerWithdrawAll() onlyOwner public {
        tokenStaking.transfer(owner(), tokenStaking.balanceOf(address(this)));
    }


    //calculate interest based on cycles with timeDivide
    //totalDivideReward: total cycle
    //timeDivide: duration of a cycle
    function _calculatorClaim(address a) internal view returns (uint256 amountReward, uint256 totalDivideReward,uint256 timeDivide){
        StakingInfo memory info = stakingInfo[a];
        timeDivide = 120; // 1 ngay = 2 phut, dung de test
        if( info.registerTime == 0 || info.amountDeposit ==0) return (0,0, timeDivide);
        PackageStaking memory pack = packages[info.packageId];
        
        uint256 currentTimeReward = block.timestamp > info.expireTime ? info.expireTime: block.timestamp;
        
        
        if(currentTimeReward.sub(info.lastTimeClaim)>=timeDivide){
            totalDivideReward = currentTimeReward.sub(info.lastTimeClaim).div(timeDivide);
            //  amount = P*(1 + r)^n - P;
            //((10^8+0.026116%*10^8)^3 )/10^24 - (1+0.026116%)^3 = 0
            //10000*10^8*( (26116+10^8)^10   )/10^80-10000*10^8
            // uint256 amount = info.amountDeposit.mul(pack.dapr.add(10**_decimals)**totalDivideReward).div(10**(_decimals.mul(totalDivideReward) )).sub(info.amountDeposit) ;
            // uint256 amount = (info.amountDeposit.add( info.amountDeposit.mul(pack.dapr).div(10**_decimals)  )**totalDivideReward ).div( info.amountDeposit**(totalDivideReward-1)).sub(info.amountDeposit);
            uint256 amount =info.amountDeposit ;
            // uint256 loop = totalDivideReward.div(2);
            for(uint i=0;i<totalDivideReward;i++ ){
                amount = amount.add(amount.mul(pack.dapr).div(10**_decimals));
                // amount = amount.add(amount.mul(pack.dapr).div(10**_decimals));
            }
            // if(totalDivideReward.mod(2)==1){
            //     amount = amount.add(amount.mul(pack.dapr).div(10**_decimals));
            // }
            amount = amount.sub(info.amountDeposit);
            return (amount, totalDivideReward, timeDivide);
        }else{
            return (0,0, timeDivide);
        }



    }


    //staking infomation of address 
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
            info.lastTimeClaim.add(86400)
        );
    }

    //calcula claim amount
    function calculatorClaim(address a) public view  returns (uint256 amountReward,uint256 totalDivideReward,uint256 timeDivide) {
        return _calculatorClaim(a);
    }

    function _doStaking(address a) internal view returns (bool doStaking) {
        StakingInfo memory info = stakingInfo[a];        
        
        return  info.amountDeposit!=0  ;
    }

    // checking do staking
    function doStakingOf(address a) public view returns (bool doStaking) {
        return _doStaking(a);
    }


    


}