// File: contracts\ClaimPool.sol

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.
pragma solidity >=0.6.0 <0.7.0;
import "./StakingPoolV2.sol";

contract ClaimPool is StakingPoolV2
{
    mapping(address => uint256) public userClaimMap;

    uint256 private _totalClaimProductQuantity;

    uint256 public claimRate;


    uint256 public aTokenRate;

    constructor(uint256 stakingAmountLimit_, uint256 minStakingAmount_, uint256 capacityLimitPercent_, 
                uint256 claimRate_, uint256 aTokenRate_, address tokenAddress_, 
                address aTokenAddress_) StakingPoolV2(stakingAmountLimit_, minStakingAmount_, capacityLimitPercent_, tokenAddress_) public{
        claimRate = claimRate_;
        aTokenRate = aTokenRate_;
        aTokenAddress = aTokenAddress_;
    }

    function totalClaimProductQuantity() view public virtual override returns(uint256){
        return _totalClaimProductQuantity;
    }

    function queryAndCheckClaimAmount(address userAccount) view external virtual override returns(uint256,uint256/*token balance*/){
        require(claimEnable,"claim not enable");
        require(payAmount()>0,"no money for claim");
        uint256 productTokenQuantity = userClaimMap[userAccount];
        return (productTokenQuantity.mul(payAmount()),productTokenQuantity);
    }

    function setClaimRate(uint256 claimRate_) onlyOwner public{
        require(claimRate_>0 && claimRate_<=100,"claim rate error");
        require(now < startTime(),"can not set rate");
        claimRate = claimRate_;
	}

    function setATokenRate(uint256 aTokenRate_) onlyOwner public{
        require(now < startTime(),"can not set rate");
        aTokenRate =  aTokenRate_;
    }

    function setATokenAddress(address aTokenAddress_) onlyOwner public{
        require(now < startTime(),"can not set atoken address");
        aTokenAddress =  aTokenAddress_;
    }
    function claimStandardReached() view public returns(bool) {
        return _totalClaimProductQuantity.mul(100).div(productToken.totalSellQuantity())>=claimRate;
    }

    function redeemFromClaim() nonReentrant whenNotPaused external {
        require(!needPayFlag,"can not redeemFromClaim");
        require(!_isClosed || !productToken.needPay(),"can not redeemFromClaim");

        uint256 productQuantity = userClaimMap[_msgSender()];
        if(productQuantity > 0) {
            uint256 aTokenAmount = calcATokenAmount(productQuantity.mul(productToken.paid())); //TODO
            aTokenAddress.transferERC20(_msgSender(), aTokenAmount);
            productToken.transfer(_msgSender(), productQuantity);
            _totalClaimProductQuantity = _totalClaimProductQuantity.sub(productQuantity);
            userClaimMap[_msgSender()] = 0;
        }
    }

    function calcATokenAmount(uint256 totalPaidAmount) view public returns(uint256) {
        return totalPaidAmount.mul(aTokenRate).div(1e18);
    }

    function pledgeForClaim(uint256 productQuantity, uint256 aTokenAmount) nonReentrant whenNotPaused external {
        require(!_isClosed,"Staking pool has been closed");
        require(now >= startTime(),"It hasn't started");
        require(now < executeTime(),"can not pledge");

        uint256 checkAmount = calcATokenAmount(productQuantity.mul(productToken.paid()));
        require(checkAmount == aTokenAmount,"invalid cover amount");
        aTokenAddress.transferFromERC20(_msgSender(), address(this), aTokenAmount);
        productToken.transferFrom(_msgSender(), address(this), productQuantity);
        userClaimMap[_msgSender()] = userClaimMap[_msgSender()].add(productQuantity);
        _totalClaimProductQuantity = _totalClaimProductQuantity.add(productQuantity);
    }

    function returnRemainingAToken(address userAccount) onlyPoolToken nonReentrant whenNotPaused public virtual override {
        uint256 totalRealPayAmount = _totalClaimProductQuantity.mul(payAmount());
        uint256 totalNeedPayAmount = _totalClaimProductQuantity.mul(productToken.paid());
        if(totalRealPayAmount < totalNeedPayAmount) {
            uint256 totalLeftATokenAmount = calcATokenAmount(totalNeedPayAmount.sub(totalRealPayAmount));
            uint256 claimQuantity = userClaimMap[userAccount];
            uint256 aTokenAmount = totalLeftATokenAmount.mul(claimQuantity).div(_totalClaimProductQuantity);
            if(aTokenAmount>0){
                aTokenAddress.transferERC20(userAccount, aTokenAmount);
            }
        }
        userClaimMap[userAccount] = 0;
    }

    function getAToken(uint256 userPayAmount, address userAccount) onlyPoolToken nonReentrant whenNotPaused public virtual override {
        uint256 totalPayAmount = totalRealPayFromStaking();
        uint256 totalATokenAmount = calcATokenAmount(_totalClaimProductQuantity.mul(payAmount()));
        uint256 aTokenAmount = totalATokenAmount.mul(userPayAmount).div(totalPayAmount);
        if(aTokenAmount>0){
            aTokenAddress.transferERC20(userAccount, aTokenAmount);
        }
    }

}