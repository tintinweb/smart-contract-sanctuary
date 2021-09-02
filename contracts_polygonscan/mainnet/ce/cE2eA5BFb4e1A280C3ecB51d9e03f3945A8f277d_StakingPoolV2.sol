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
import "./lib.sol";

contract StakingPoolV2 is IClaimPool, IUpgradable, ReentrancyGuard
{
    using SafeMath for uint256;
    using CompatibleERC20 for address;
    address public override tokenAddress;

    address public override aTokenAddress;

    uint256 [] public tokenHolderIds;  


    mapping(uint256/*tokenId*/=>uint256) _timestamps; 
    IStakingPoolToken public stakingPoolToken;
    IIns3ProductToken public override productToken;

    uint256 public stakingAmountLimit; 

    uint256 public minStakingAmount; 

	uint256 public capacityLimitPercent; 

    uint256 private _totalStakingAmount; 

    uint256 public _totalStakingTimeAmount; 


    uint256 private _totalNeedPayFromStaking; 

    uint256 private _totalRealPayFromStaking; 

    uint256 private _payAmount; 
    bool public _isClosed;

    bool public override needPayFlag;
    bool public claimEnable; 

    uint256 _totalPremiumsAfterClose;

    uint256 public override stakingWeight;

    uint256 public override stakingLeverageWeight;

    constructor(uint256 stakingAmountLimit_, uint256 minStakingAmount_, uint256 capacityLimitPercent_, address tokenAddress_) public{
        stakingAmountLimit = stakingAmountLimit_;
        minStakingAmount = minStakingAmount_;
        capacityLimitPercent = capacityLimitPercent_;

        tokenAddress = tokenAddress_;

        stakingWeight=10000;
        stakingLeverageWeight=10000;
    }

    function setStakingAmountLimit(uint256 stakingAmountLimit_) onlyOwner public{
        require(stakingAmountLimit_ > _totalStakingAmount);
        stakingAmountLimit=stakingAmountLimit_;
    }

    function setStakingWeight(uint256 stakingWeight_) onlyOwner public{
        stakingWeight=stakingWeight_;
    }

    function setStakingLeverageWeight(uint256 stakingLeverageWeight_) onlyOwner public {
        stakingLeverageWeight=stakingLeverageWeight_;
    }

    function setNeedPayFlag(bool needPay) onlyOwner public{
        require(!_isClosed,"can not set flag");
        needPayFlag =  needPay;
    }

    function startTime() view public returns(uint256){
        return productToken.closureTimestamp();
    }

    function executeTime() view public returns(uint256){
        return productToken.expireTimestamp();
    }

    function totalClaimProductQuantity() view public virtual override returns(uint256){
        return productToken.totalSellQuantity();
    }

    function calculateCapacity() view public override returns(uint256) {
        uint256 activeCovers = productToken.totalSellQuantity().mul(productToken.paid());
        uint256 maxMCRCapacity = _totalStakingAmount.mul(capacityLimitPercent).div(1000);
        uint256 maxCapacity = maxMCRCapacity < stakingAmountLimit ? maxMCRCapacity : stakingAmountLimit;
        uint256 availableCapacity = activeCovers >= maxCapacity ? 0 : maxCapacity.sub(activeCovers);
        return availableCapacity;
    }

    function productTokenRemainingAmount() view public override returns(uint256){ 
        require(address(productToken)!=address(0),"The productToken should not be 0");
        return calculateCapacity();
    }

    function tokenHolderIdLength() view public returns(uint256){
        return tokenHolderIds.length;
    }

    function productTokenExpireTimestamp() view public override returns(uint256){
        require(address(productToken)!=address(0),"The productToken should not be 0");
        return productToken.expireTimestamp();
    }

    function setProductToken(address productTokenAddress) onlyOwner public returns(bool){
		require(address(productToken) == address(0),"The setProductToken() can only be called once");
		productToken = IIns3ProductToken(productTokenAddress);
		return true;
	}

    modifier onlyPoolToken(){
        require(address(stakingPoolToken)==address(_msgSender()));
        _;
    }

    function putTokenHolder(uint256 tokenId,uint256 amount,uint256 timestamp) onlyPoolToken public override {
        require(amount>=minStakingAmount,"amount should > minStakingAmount");
        require(remainingStakingAmount()>=amount,"putTokenHolder - remainingStakingAmount not enough");
        require(_timestamps[tokenId]==0,"putTokenHolder - The tokenId already exists");
        require(timestamp<productToken.closureTimestamp(),"Clouser period, can not staking");
        _totalStakingAmount = _totalStakingAmount.add(amount);
        uint256 period = productToken.expireTimestamp().sub(timestamp);
        _totalStakingTimeAmount = _totalStakingTimeAmount.add(amount.mul(period).mul(period));
        tokenHolderIds.push(tokenId);
        _timestamps[tokenId]=timestamp;

    }

    function takeTokenHolder(uint256 tokenId) onlyPoolToken public override{ 
        require(!_isClosed,"pool has colsed");
        require(_timestamps[tokenId]!=0,"The tokenId does not exist");
        uint256 amount=stakingPoolToken.getTokenHolderAmount(tokenId,address(this));
        uint256 period = productToken.expireTimestamp().sub(_timestamps[tokenId]);
        delete _timestamps[tokenId];
        _totalStakingAmount = _totalStakingAmount.sub(amount);
        _totalStakingTimeAmount = _totalStakingTimeAmount.sub(amount.mul(period).mul(period));
    }

    function remainingStakingAmount() view public returns(uint256){
        return stakingAmountLimit.sub(_totalStakingAmount);
    }

    function updateDependentContractAddress() public override{
        stakingPoolToken=IStakingPoolToken(register.getContract("SKPT"));
        require(address(stakingPoolToken)!=address(0),"updateDependentContractAddress - staking pool token does not init");
    }

    function calcPremiumsRewards(uint256 stakingAmount, uint256 beginTimestamp) view public override returns(uint256){
        (, uint256 toPoolTokenPremiums) = productToken.calcDistributePremiums();
        uint256 timePeriod = productToken.expireTimestamp().sub(beginTimestamp);
        if (_totalStakingTimeAmount == 0) {
            return 0;
        }
        return toPoolTokenPremiums.mul(stakingAmount).mul(timePeriod).mul(timePeriod).div(_totalStakingTimeAmount); 
    }

    function isClosed() view public override returns(bool){
        return _isClosed;
    }

    function isNormalClosed() view public override returns(bool){
        return _isClosed && !productToken.needPay();
    }

    function totalStakingAmount() view public override returns(uint256){
        return _totalStakingAmount;
    }

    function totalNeedPayFromStaking() view public override returns(uint256){
        return _totalNeedPayFromStaking;
    }

    function totalRealPayFromStaking() view public override returns(uint256){
        return _totalRealPayFromStaking;
    }

    function payAmount() view public override returns(uint256){
        return _payAmount;
    }

    function canStake() view public returns(bool){
        return now<productToken.closureTimestamp(); 
    }


    function close(bool needPay, uint256 totalRealPayFromStakingToken) public onlyOwner {
        require(!_isClosed,"Staking pool has been closed");
        _isClosed = true;
        if(needPay){
            require(needPayFlag,"flag error");
            productToken.approvePaid();
        }else{
            require(!needPayFlag,"flag error");
            productToken.rejectPaid();
        }
        uint256 totalSellQuantity = totalClaimProductQuantity();

        if(needPay && totalSellQuantity>0) { 
            uint256 totalPaidAmount = totalSellQuantity.mul(productToken.paid());

            uint256 totalPremiums = tokenAddress.balanceOfERC20(address(this));

            uint256 totalNeedPayAmount = totalPaidAmount.sub(totalPremiums);
            require(totalRealPayFromStakingToken <= totalNeedPayAmount,"please check pay amount");

            _totalNeedPayFromStaking = totalNeedPayAmount;
            _totalRealPayFromStaking = totalRealPayFromStakingToken;
            
            if(_totalRealPayFromStaking>0){
                tokenAddress.transferERC20(address(stakingPoolToken),totalPremiums);
                
                _totalPremiumsAfterClose=totalPremiums;
                stakingPoolToken.bookkeepingFromPool(_totalRealPayFromStaking.add(_totalPremiumsAfterClose));
            }

            updatePayAmount();

        }
    }


    function calcPayAmount(uint256 tokenId, address poolAddr) view public returns(uint256) {
        (,,,,address [] memory poolAddrs) = stakingPoolToken.getTokenHolder(tokenId);
        uint256 totalPayAmount = 0;
        uint256 poolPayAmount = 0;
        for (uint256 i=0;i<poolAddrs.length;++i) {
            IClaimPool pool=IClaimPool(poolAddrs[i]);
            if(pool.needPayFlag()) {
                uint256 totalPaidAmount = pool.totalClaimProductQuantity().mul(pool.productToken().paid());
                uint256 totalNeedPayAmount = totalPaidAmount.sub(pool.productToken().totalPremiums());
                uint256 stakingAmount = stakingPoolToken.getTokenHolderAmount(tokenId, poolAddrs[i]);
                uint256 userPayAmount = stakingAmount.mul(totalNeedPayAmount).div(pool.totalStakingAmount());
                totalPayAmount = totalPayAmount.add(userPayAmount);
                if(poolAddrs[i]==poolAddr){
                    poolPayAmount = userPayAmount;
                }
            }
        }
        if(totalPayAmount==0){
            return 0;
        } else{
            uint256 stakingAmount = stakingPoolToken.getTokenHolderAmount(tokenId, poolAddr);
            uint256 poolPayAmount2 = poolPayAmount.mul(stakingAmount).div(totalPayAmount);
            return Math.min(poolPayAmount2, poolPayAmount);
        }
    }

    function calcPayAmountFromStaking(uint256 beginIndex, uint256 endIndex) public view returns(uint256){
        require(needPayFlag,"pay flag error");
        require(beginIndex <= endIndex,"index error");
        require(endIndex < tokenHolderIds.length,"end index out of range");
        uint256 totalRealPayAmount = 0;

        for(uint256 i=beginIndex; i <= endIndex; ++i) {
            uint256 tokenId=tokenHolderIds[i];
            if (!stakingPoolToken.isTokenExist(tokenId)){
                continue;
            }
            uint256 userRealPayAmount = calcPayAmount(tokenId, address(this));
            if(userRealPayAmount>0){
                totalRealPayAmount = totalRealPayAmount.add(userRealPayAmount);
            }
        }
        return totalRealPayAmount;
    }

    function updatePayAmount() public onlyOwner {
        require(_isClosed,"Pool must be closed");
        require(!claimEnable,"claim already enable");
        uint256 totalAmount = tokenAddress.balanceOfERC20(address(this));
        uint256 totalSellQuantity = totalClaimProductQuantity();
        if(totalSellQuantity>0) {
            _payAmount = totalAmount.add(_totalRealPayFromStaking).add(_totalPremiumsAfterClose).div(totalSellQuantity);
        }else {
            _payAmount = 0;
        }

        if (totalAmount>0){
            _totalPremiumsAfterClose=_totalPremiumsAfterClose.add(totalAmount);
            tokenAddress.transferERC20(address(stakingPoolToken),totalAmount);
            stakingPoolToken.bookkeepingFromPool(totalAmount);
        }
    }

    function setClaimEnable() public onlyOwner{
        require(_isClosed,"Pool must be closed");
        claimEnable = true;
    }

    function queryAndCheckClaimAmount(address userAccount) view external virtual override returns(uint256,uint256/*token balance*/){
        require(claimEnable,"claim not enable");
        require(payAmount()>0,"no money for claim");
        uint256 productTokenQuantity = productToken.balanceOf(userAccount);
        return (productTokenQuantity.mul(payAmount()),productTokenQuantity);
    }

    function returnRemainingAToken(address userAccount) onlyPoolToken nonReentrant whenNotPaused public virtual override {
        
    }

    function getAToken(uint256 userPayAmount, address userAccount) onlyPoolToken nonReentrant whenNotPaused public virtual override {
        
    }
}