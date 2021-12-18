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
    uint256 public _packageCount; // số package hiện có
    uint256 public earlyFeePercentage; // % phí rút trước hạn staking tính theo decimal;

    mapping(uint256 => PackageStaking) private packages; //danh sách gói

    mapping(address => StakingInfo) private stakingInfo; //  address taking

    //struct của gói staking
    struct PackageStaking{
        uint256 duration;// thời hạn của gói tính bằng giây, yêu cầu thấp nhất là 1 ngày, 
        uint256 dapr; // lãi suất kép hàng ngày
        bool active; // có được xóa staking hay không
    }

    //struct thông tin address stacking
    struct StakingInfo {
        uint256 amountDeposit;
        uint256 registerTime;
        uint256 lastTimeClaim;
        uint256 expireTime;
        uint256 packageId;
    }

    //tokenAddress địa chỉ đồng token erc20
    //owner_ địa chỉ chủ sở hữu sc
    //decimals decimal của token, cũng là decimal của toàn bộ tỉ lệ đc tính
    //earlyFeePercentage_ phí rút sớm tính theo decimals, vd 5% với decimal là 8 thì sẽ là 5 000 000 ( 100% = 1 00 000 000  - 8 số 0)
    constructor(address tokenAddress, uint8 decimals_ , uint256 earlyFeePercentage_) {
        tokenStaking = IERC20(tokenAddress);
        
        _decimals = decimals_;
        _packageCount = 0;
        earlyFeePercentage = earlyFeePercentage_;
        addPackage(10,261157876067841,true);
        addPackage(15,499635890955700,true);
        addPackage(20,719064607110243,true);
        addPackage(25,922266770860825,true);


    }

    //thông tin các gói stacking
    function packageInfo(uint256 idPackage) public view returns (PackageStaking memory) {
        return packages[idPackage];        
    }

    //thêm package, duration tính bằng ngày
    function addPackage(uint256 duration, uint256 percentage, bool active) onlyOwner public  {
        // packages[_packageCount++]= PackageStaking(duration.mul(86400), percentage, active);       
        packages[_packageCount++]= PackageStaking(duration.mul(120), percentage, active);        // dung de test 
    }

    //edit package, không khuyến khích sử dụng
    function editPackage(uint256 idPackage,uint256 duration, uint256 percentage, bool active)  onlyOwner public {
        require(idPackage< _packageCount);
        packages[_packageCount++]= PackageStaking(duration.mul(86400), percentage, active);        
    }


    //người call phải approve money cho address của smartcontract trước.
    function deposit(uint256 amount, uint256 packageId) public {
        require(!_doStaking(msg.sender),"Cannot restaking ");
        require(packageId < _packageCount && packages[packageId].duration >0 || packages[packageId].active == true, "Can't find package or packages is off" );
        require(amount>0,"amount invalid");
        require(tokenStaking.balanceOf(msg.sender) > amount, "you account not have money");
        tokenStaking.transferFrom(msg.sender, address(this), amount);
        uint256 currentTime=block.timestamp; // test  thì thêm cái -86400 (1 ngày) vào 
        stakingInfo[msg.sender] = StakingInfo(amount, currentTime, currentTime, currentTime+packages[packageId].duration, packageId);
    }

    //claim hàng ngày luôn nhé
    function claim() public{
        require(_doStaking(msg.sender),"You not staking");
        // require((stakingInfo[msg.sender].lastTimeClaim + 86400) < block.timestamp, "Cannot claim before 24h" );
        (uint256 amountReward, uint256 totalDivideReward, uint256 timeDivide) = _calculatorClaim(msg.sender);
        require(amountReward > 0 ,"no reward");
        require(tokenStaking.balanceOf(address(this)) >= amountReward, "Smartcontract not enough money" );
        tokenStaking.transfer(msg.sender, amountReward);
        stakingInfo[msg.sender].lastTimeClaim= stakingInfo[msg.sender].lastTimeClaim.add(totalDivideReward.mul(timeDivide) );
    }

    //rút hết cả vốn lẫn lãi
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

    //setup lại sau khi withdraw
    function _clear(address a) internal {
        stakingInfo[a].amountDeposit = 0;
        stakingInfo[a].registerTime=0;
        stakingInfo[a].lastTimeClaim=0;
        stakingInfo[a].packageId=0;
        stakingInfo[a].expireTime=0;
    }

    //owner lấy hết tiền của sc
    function ownerWithdrawAll() onlyOwner public {
        tokenStaking.transfer(owner(), tokenStaking.balanceOf(address(this)));
    }


    //tính lãi dựa trên chênh lệch thời gian, chính xác theo timeDivide
    //totalDivideReward: tổng các khoảng tính thưởng ( số chu kỳ lãi)
    //timeDivide: lượng thời gian cần thiết để cập nhập thưởng staking 
    function _calculatorClaim(address a) internal view returns (uint256 amountReward, uint256 totalDivideReward,uint256 timeDivide){
        StakingInfo memory info = stakingInfo[a];
        //thay đổi khoảng thấp nhất để tính ( hiện tại là từng ngày một ~ 86400)
        timeDivide = 120; // 1 ngay = 2 phut, dung de test
        if( info.registerTime == 0 || info.amountDeposit ==0) return (0,0, timeDivide);
        PackageStaking memory pack = packages[info.packageId];
        
        uint256 currentTimeReward = block.timestamp > info.expireTime ? info.expireTime: block.timestamp;
        
        
        if(currentTimeReward.sub(info.lastTimeClaim)>=timeDivide){
            totalDivideReward = currentTimeReward.sub(info.lastTimeClaim).div(timeDivide);
            //tính thời gian của khoảng divide gần sát nhất
            // uint256 amount = P*(1 + r)^n - P;
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


    //thông tin staking của một địa chỉ
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

    //tính toán claim của địa chỉ hiện tại
    function calculatorClaim() public view  returns (uint256 amountReward,uint256 totalDivideReward,uint256 timeDivide) {
        return _calculatorClaim(msg.sender);
    }

    function _doStaking(address a) internal view returns (bool doStaking) {
        StakingInfo memory info = stakingInfo[a];        
        
        return  info.amountDeposit!=0  ;
    }

    // kiểm tra đã staking chưa
    function doStakingOf(address a) public view returns (bool doStaking) {
        return _doStaking(a);
    }


    


}