// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./IMagicTransferGate.sol";
import "./IGatedERC20.sol";

import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IERC31337.sol";
import "./IAxBNB.sol";
import "./IMagic.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./TokensRecoverableUpg.sol";


contract MagicEventGate is Initializable, OwnableUpgradeable, TokensRecoverableUpg
{
    using SafeMathUpgradeable for uint256;

    IMagicTransferGate public transferGate;
    address public LPAddress; // axBNB <-> Magic UniV2 LP token address
    uint256 public slippage; // 10%
    bool public enabledGate;

    address public axBNBToken;
    address public magicToken;
    address public wizardToken;
    uint256 public MIN_MAGIC;

    uint256 public FEE_PERCENT_LOCKED;// this fees is locked on contract and not claimaable => If fees_locked = 3000 (3%) => 97% of User's magic is claimable

    mapping(address=>uint256) public balanceLocked; // for each holder how much balance is locked
    uint256 public totalLockedMagic; // total Magic that is still unclaimed (of total Magic contract once had and was swapped to Wizard) 
    uint256 public totalAvailableWizard; // how much Wizard is available after swaps
    uint256 public totalSwappedMagic; // how much Magic is swapped

    bool public allowClaimByHolder;

    mapping(uint256 => address) public holdersAddresses;    
    mapping(address => bool) public isHolderAddress;    

    uint256 public totalHolders;

    struct ZapParameters{
        uint256 startZapTime;
        uint256 startingZapFeePercent;
        uint256 totalEventGateTime;
        uint256 reductionSector;
        uint256 reductionRate;
    }

    ZapParameters public zapParams;
    IUniswapV2Router02 private uniswapV2Router; 
    IUniswapV2Factory private uniswapV2Factory; 

    address[] public Admins;
    mapping(address => bool) public AdminByAddress;

    event SetAdmins(address[] Admins);
    event MagicLockedForWizard(address holder, uint256 MagicAmountIn, uint256 MagicAmountClaimable);
    event WizardBuy(uint256 magicAmt, uint256 wizardAmt);
    event Claimed(address holder, uint256 MagicAmount, uint256 wizardReceived);
    event SlippageSet(uint slippage);
    event FeesForLockSet(uint FEE_PERCENT_LOCKED);
    event TokenAddressesSet(address axBNBToken, address wizardToken, address magicToken, address transferGate);
    event ZapParamsSet( uint startZapTime, uint startingZapFeePercent, uint totalEventGateTime, uint reductionSector, uint reductionRate);

    function initialize(address _axBNBToken, address _wizardToken, address _magicToken, IMagicTransferGate _transferGate)  public initializer  {

        __Ownable_init_unchained();
        
        require(_axBNBToken != address(0), "MagicEventGate: _axBNBToken cannot be zero address");
        require(_wizardToken != address(0), "MagicEventGate: _wizardToken cannot be zero address");
        require(_magicToken != address(0), "MagicEventGate: _magicToken cannot be zero address");
        require(address(_transferGate) != address(0), "MagicEventGate: _transferGate cannot be zero address");

        AdminByAddress[msg.sender] = true; // owner is also admin by default

        axBNBToken = _axBNBToken;
        wizardToken = _wizardToken;
        magicToken = _magicToken;
        transferGate = _transferGate;

        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Factory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

        LPAddress = uniswapV2Factory.getPair(axBNBToken, magicToken);
        
        zapParams.startZapTime = block.timestamp + 60; // time from which this will start
        zapParams.startingZapFeePercent = 90000; // starting base, 90% fee from startTime => will reduce gradually every sector
        zapParams.totalEventGateTime = 288000; // 80 hrs this reduction will happen, after that no zapping/adding liquidity mechanism
        zapParams.reductionSector = 18000; // will change fee% every 5 hrs
        zapParams.reductionRate = 5000; //will reduce fee% by 5% every sector on current fee

        slippage = 99000;
        MIN_MAGIC = 1 ether; // 1 Magic
        FEE_PERCENT_LOCKED = 3000; // 3% Fee locked, non claimable by user for worth of Wizard token

        totalLockedMagic = 0; // total Magic that is still unclaimed (of total Magic contract once had and was swapped to Wizard) 
        totalAvailableWizard = 0; // how much Wizard is available after swaps
        totalSwappedMagic = 0; // how much Magic is swapped

        allowClaimByHolder = false; // only owner can claim
        totalHolders = 0;
        enabledGate = true;


        IAxBNB(axBNBToken).approve(address(_transferGate), uint256(-1));
        IMagic(magicToken).approve(address(_transferGate), uint256(-1));
        IMagic(magicToken).approve(LPAddress, uint256(-1));
        IAxBNB(axBNBToken).approve(LPAddress, uint256(-1));
 
        IERC20(LPAddress).approve(_wizardToken, uint256(-1));

        // approve Routers
        IAxBNB(axBNBToken).approve(0x10ED43C718714eb63d5aA57B78B54704E256024E, uint256(-1));
        IMagic(magicToken).approve(0x10ED43C718714eb63d5aA57B78B54704E256024E, uint256(-1));
        
    }


    function availableMagicToBuyWizard() public view returns(uint256){
        return IMagic(magicToken).balanceOf(address(this));
    }


    function setSlippage(uint256 _slippage) external onlyAdmin{
        slippage = _slippage;
        emit SlippageSet(slippage);
    }

    function setMinimumAmountToTransfer(uint256 min_magic_amt) external onlyOwner{
        MIN_MAGIC = min_magic_amt;
    }

    function setFeesForLock(uint256 fee_percent_locked) external onlyOwner{
        FEE_PERCENT_LOCKED = fee_percent_locked;
        emit FeesForLockSet(FEE_PERCENT_LOCKED);
    }

    // Wizard token address & axBNB token address
    function setTokenAddresses(address _axBNBToken, address _wizardToken, address _magicToken, IMagicTransferGate _transferGate) external onlyOwner{
        require(_axBNBToken != address(0), "MagicEventGate: _axBNBToken cannot be zero address");
        require(_wizardToken != address(0), "MagicEventGate: _wizardToken cannot be zero address");
        require(_magicToken != address(0), "MagicEventGate: _magicToken cannot be zero address");
        require(address(_transferGate) != address(0), "MagicEventGate: _transferGate cannot be zero address");
 
        axBNBToken = _axBNBToken;
        wizardToken = _wizardToken;
        magicToken = _magicToken;
        transferGate = _transferGate;
        emit TokenAddressesSet(axBNBToken, wizardToken, magicToken, address(transferGate));
    }

    // _startZapTime = unix timestamp from when to start => 1221223
    // _startingZapFeePercent = 90% => 90000
    // _totalEventGateTime (x)= overall time for which this will apply in seconds, 12 hrs => 60*60*12 => owner responsible to set this correct!
    // _reductionSector (y) = reduce x every y seconds, 15 minutes => 60*15
    // _reductionRate = 85% => 85000
    function setZapParams(uint256 _startZapTime, uint256 _startingZapFeePercent, uint256 _totalEventGateTime, uint256 _reductionSector, 
                            uint256 _reductionRate) external onlyOwner{

        uint256 powerPercent = _totalEventGateTime.div(_reductionSector);
        uint256 reductionFeeMultiplier = SafeMath.sub(100000,_reductionRate);

        uint256 factor = reductionFeeMultiplier;
        uint256 prevFactor = reductionFeeMultiplier;
        for(uint256 i=1;i<=powerPercent;i++){
            factor = prevFactor.mul(reductionFeeMultiplier).div(100000);
            prevFactor = factor;
        }

        uint256 totalZapFactor = _startingZapFeePercent.mul(factor).div(100000);
        
        require(totalZapFactor>=0,"Fees will go less than 0% in given _totalEventGateTime");
        
        zapParams.startZapTime = _startZapTime;
        zapParams.startingZapFeePercent = _startingZapFeePercent;
        zapParams.totalEventGateTime = _totalEventGateTime;
        zapParams.reductionSector = _reductionSector;
        zapParams.reductionRate = _reductionRate;

        emit ZapParamsSet( _startZapTime, _startingZapFeePercent, _totalEventGateTime, _reductionSector, _reductionRate);
    }


     function getCurrentFee() public view returns(uint256){
        uint256 currTime = block.timestamp;
        if (zapParams.startZapTime <= currTime &&  zapParams.startZapTime + zapParams.totalEventGateTime > currTime) {
            // uint256 powerPercent = (currTime.sub(zapParams.startZapTime)).div(zapParams.reductionSector);
            // uint256 reductionFeeMultiplier = 100000 - zapParams.reductionRate;
            // uint256 totalZapFactor = zapParams.startingZapFeePercent.mul(((reductionFeeMultiplier.div(1000)) ** powerPercent).mul(100000).div(100 ** powerPercent)).div(100000);
            // // uint256 totalZap = amount.mul(totalZapFactor).div(100000);

            uint256 powerPercent = (currTime.sub(zapParams.startZapTime)).div(zapParams.reductionSector);
            uint256 reductionFeeMultiplier = SafeMath.sub(100000, zapParams.reductionRate);

            uint256 factor = reductionFeeMultiplier;
            uint256 prevFactor = reductionFeeMultiplier;
            for(uint256 i=1;i<=powerPercent;i++){
                factor = prevFactor.mul(reductionFeeMultiplier).div(100000);
                prevFactor = factor;
            }

            uint256 totalZapFactor = zapParams.startingZapFeePercent.mul(factor).div(100000);



            return totalZapFactor;
        }
        return 0;
    }

    function enableGate(bool allow) external onlyOwner{
        enabledGate = allow;
    }


    function handleZap(address sender, address recipient, uint256 amount) public returns(uint256)
    {
        require(msg.sender == magicToken, "Only Magic token can call this while eventgate mechanisms are active");

        uint256 remAmount = amount;
        if(enabledGate){
            uint256 currTime = block.timestamp;
            if (zapParams.startZapTime <= currTime &&  zapParams.startZapTime + zapParams.totalEventGateTime > currTime) {
        
                require(amount >= MIN_MAGIC,"Magic amount is less than MIN_MAGIC amount to be bought"); // so that no micro txns occur

                uint256 totalZapFactor = getCurrentFee();

                uint256 totalLockForZap = amount.mul(totalZapFactor).div(100000);
                remAmount = amount.sub(totalLockForZap);

                uint256 claimableMagicByUserAfterFeeFactor = SafeMath.sub(100000, FEE_PERCENT_LOCKED);
                uint256 claimableWorthMagic = totalLockForZap.mul(claimableMagicByUserAfterFeeFactor).div(100000);

                // adding totalLockForZap Magic to this contract, so that contract can buy wizard!
                // but claimableWorthMagic is less
                balanceLocked[recipient] = balanceLocked[recipient].add(claimableWorthMagic);
                totalLockedMagic = totalLockedMagic.add(claimableWorthMagic);
                
                // so that holder is added to indexing only once
                if(!isHolderAddress[recipient]){
                    holdersAddresses[totalHolders] = recipient; // take note of address who should receive wizard later for Magic locked   
                    totalHolders=totalHolders.add(1);
                    isHolderAddress[recipient]=true;
                }
                emit MagicLockedForWizard(recipient, totalLockForZap, claimableWorthMagic);
            }
        }

        IMagic(magicToken).transfer(recipient,remAmount);
        return remAmount;
    }


    // holder can claim wizard tokens
    function setAllowClaimableByHolder(bool allow) external onlyAdmin{
        allowClaimByHolder = allow;
    }

    // swap only allowed by owner
    function buyWizardFromAllMagic() external onlyAdmin{
        uint256 magicInContract = availableMagicToBuyWizard();
        buyWizardFromMagic(magicInContract);
    }


    // swap only some % allowed by owner
    // also say x% of all.. 
    // 5%  = 5000, 90% = 90000
    function buyWizardFromPercentMagic(uint256 percent) external onlyAdmin{
        uint256 magicInContract = availableMagicToBuyWizard();
        uint256 magicToSwap = percent.mul(magicInContract).div(100000);
        buyWizardFromMagic(magicToSwap);
    }


    // swap only allowed by owner
    // x amount of Magic  => Wizard token
    function buyWizardFromMagic(uint256 amount) public onlyAdmin{

        uint256 prevAXBNBAmount = IAxBNB(axBNBToken).balanceOf(address(this)); 
        uint256 prevMagicAmount = IMagic(magicToken).balanceOf(address(this)); 

        //swap half magic to axBNB   
        uint256 magicForBuy = amount.div(2);

        address[] memory path = new address[](2);
        path[0] = magicToken;
        path[1] = axBNBToken; 

        uint slippageFactor=(SafeMathUpgradeable.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default
        (uint256[] memory amounts) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), magicForBuy, path);
        
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(magicForBuy, amounts[1].mul(slippageFactor).div(100), path, address(this), block.timestamp);

        uint256 axBNBAmount = IAxBNB(axBNBToken).balanceOf(address(this)).sub(prevAXBNBAmount);

        (, ,  uint256 LPtokens) = transferGate.safeAddLiquidity(IUniswapV2Router02(uniswapV2Router), IERC20(axBNBToken), axBNBAmount, magicForBuy);
    
        uint256 prevWizAmt = IERC31337(wizardToken).balanceOf(address(this));
        IERC31337(wizardToken).depositTokens(LPAddress, LPtokens); 
        uint256 currWizAmt = IERC31337(wizardToken).balanceOf(address(this));
        
        uint256 wizardReceived = currWizAmt.sub(prevWizAmt);
        totalAvailableWizard = totalAvailableWizard.add(wizardReceived);

        uint256 currMagicAmount = IMagic(magicToken).balanceOf(address(this)); 
        totalSwappedMagic = totalSwappedMagic.add(prevMagicAmount.sub(currMagicAmount));

        emit WizardBuy(wizardReceived, amount);
    }


    // balanceLocked[holder] -> 5% of user's balance only claimed...
    // only owner calls this function => claims Wizard for all holders
    // 5%  = 5000, 90% = 90000
    function claimWizardForAllHoldersByPercent(uint256 percent) external onlyAdmin{

        uint256 totalMagicToClaimForAll = 0;
        for(uint i=0; i<totalHolders;i++){
            if(balanceLocked[holdersAddresses[i]]>0){
                uint balLocked = balanceLocked[holdersAddresses[i]].mul(percent).div(100000);
                totalMagicToClaimForAll = totalMagicToClaimForAll.add(balLocked);
            }
        }

        require(totalSwappedMagic>=totalMagicToClaimForAll,"Cannot claim for all users, totalAvailableWizard < asked to claim ");

        for(uint i=0; i<totalHolders;i++){
            if(balanceLocked[holdersAddresses[i]]>0)
                claimWizard(holdersAddresses[i],balanceLocked[holdersAddresses[i]].mul(percent).div(100000));
        }
    }


    // only owner calls this function => claims all Wizard for all holders
    function claimWizardForAllHolders() external onlyAdmin{

        uint256 totalMagicToClaimForAll = 0;
        for(uint i=0; i<totalHolders;i++){
            if(balanceLocked[holdersAddresses[i]]>0)
                totalMagicToClaimForAll = totalMagicToClaimForAll.add(balanceLocked[holdersAddresses[i]]);
        }

        require(totalSwappedMagic>=totalMagicToClaimForAll,"Cannot claim for all users, totalAvailableWizard < asked to claim ");

        for(uint i=0; i<totalHolders;i++){
            if(balanceLocked[holdersAddresses[i]]>0)
                claimWizard(holdersAddresses[i],balanceLocked[holdersAddresses[i]]);
        }
    }

    // only owner calls this function => claims Wizard for x holders
    // if maxHolders = 11, means for first 11 holders, wizard will be claimed 
    // next time => need to claim say maxHolders = 22, as first 11 holders should have zero claims
    function claimWizardForHoldersByIndex(uint256 maxHolders) external onlyAdmin{
        for(uint i=0; i<maxHolders;i++){
            if(balanceLocked[holdersAddresses[i]]>0)
                claimWizard(holdersAddresses[i], balanceLocked[holdersAddresses[i]]);
        }
    }

    // holder can claim if allowClaimByHolder = true 
    // else only owner can claim
    // not anyone can claim, reason - function calculates "wizardPerMagic" which depends on when it is called
    function claimWizardForHolder(address holder) external returns(bool){

        if(allowClaimByHolder) require(msg.sender == holder || msg.sender == owner(),"Only holder/owner is allowed to claim");
        else require(AdminByAddress[msg.sender] == true, "Only owner is allowed to claim");

        require(balanceLocked[holder]>0,"Cannot claim from zero balance of holder");
        require(balanceLocked[holder]<=totalSwappedMagic,"Total swapped magic is less than required swap for holder");

        claimWizard(holder,balanceLocked[holder]);        
        return true;
    }


    // this might be case for last holder as residue might remain
    // MAYBE send residue to this address??

    function emergencyClaimWizard(address holder) external onlyOwner{
        
        uint256 magicLockedOfHolder = balanceLocked[holder];
        // uint256 wizardPerMagic = totalAvailableWizard.div(totalSwappedMagic);
        // uint256 wizardToTransfer = magicLockedOfHolder.mul(wizardPerMagic);
        uint256 wizardToTransfer = magicLockedOfHolder.mul(totalAvailableWizard).div(totalSwappedMagic);
        uint256 prevAvailableWizard = totalAvailableWizard;

        // Total swapped magic are less than required swap for holder
        if(magicLockedOfHolder>totalSwappedMagic){
            totalSwappedMagic = 0;

            if(totalAvailableWizard<wizardToTransfer) {
                IERC31337(wizardToken).transfer(holder, totalAvailableWizard);
                totalAvailableWizard = 0;
            }
            else{
                totalAvailableWizard = totalAvailableWizard.sub(wizardToTransfer);
                IERC31337(wizardToken).transfer(holder, wizardToTransfer);
            }

            totalLockedMagic = totalLockedMagic.sub(magicLockedOfHolder);
            balanceLocked[holder] = 0;    
            emit Claimed(holder,magicLockedOfHolder, prevAvailableWizard);
        }
        else 
            claimWizard(holder, balanceLocked[holder]);

    }


    // internal function called by claimWizardForAllHolders() & claimWizardForHolder(address holder)
    function claimWizard(address holder, uint256 amount) internal{
        
        uint256 magicLockedOfHolder = balanceLocked[holder];
        require(magicLockedOfHolder>=amount,"Balance locked by user is lesser");
        uint256 wizardToTransfer = amount.mul(totalAvailableWizard).div(totalSwappedMagic);

        IERC31337(wizardToken).transfer(holder, wizardToTransfer);
        
        totalSwappedMagic = totalSwappedMagic.sub(amount);
        totalLockedMagic = totalLockedMagic.sub(amount);
        balanceLocked[holder] = balanceLocked[holder].sub(amount);
        totalAvailableWizard = totalAvailableWizard.sub(wizardToTransfer);

        emit Claimed(holder,amount,wizardToTransfer);
    }


    // owner calls to get residue axBNB stuck in contract if any due to swaps/adding liquidity
    function getAllDust() external onlyOwner{
        uint256 balanceAxBNB = IAxBNB(axBNBToken).balanceOf(address(this));
        IAxBNB(axBNBToken).transfer(owner(),balanceAxBNB);
    }

    // owner calls to get extra Magic out of the contract
    function ejectAllMagicFee() external onlyOwner{
        uint256 totalMagicInContract = availableMagicToBuyWizard();
        IMagic(magicToken).transfer(owner(),totalMagicInContract.sub(totalLockedMagic));
    }

    // Multi Admins functionality

    modifier onlyAdmin() {
        require(AdminByAddress[msg.sender]);
        _;
    }

  
    /**
     * @dev Function to set Admins addresses
     */
    function setAdmins(address[] memory _Admins) public onlyOwner {
        _setAdmins(_Admins);

    }

    function _setAdmins(address[] memory _Admins) internal {
        for(uint256 i = 0; i < Admins.length; i++) {
            AdminByAddress[Admins[i]] = false;
        }


        for(uint256 j = 0; j < _Admins.length; j++) {
            AdminByAddress[_Admins[j]] = true;
        }
        Admins = _Admins;
        emit SetAdmins(_Admins);
    }

    function getAdmins() public  view returns (address[] memory) {
        return Admins;
    }


    // remove later
    function approveRouters() external onlyOwner{
        // approve Routers
        IAxBNB(axBNBToken).approve(0x10ED43C718714eb63d5aA57B78B54704E256024E, uint256(-1));
        IMagic(magicToken).approve(0x10ED43C718714eb63d5aA57B78B54704E256024E, uint256(-1));

    }

}