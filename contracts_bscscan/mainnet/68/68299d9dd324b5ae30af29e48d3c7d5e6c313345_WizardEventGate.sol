// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./IGatedERC20.sol";

import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IERC31337.sol";
import "./IAxBNB.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./TokensRecoverableUpg.sol";


contract WizardEventGate is Initializable, OwnableUpgradeable, TokensRecoverableUpg
{
    using SafeMathUpgradeable for uint256;

    uint256 slippage; // 10%

    address public wizardToken;
    uint256 public MIN_WIZARD;

    mapping(address=>uint256) public balanceLocked; // for each holder how much balance is locked
    uint256 public totalLockedWizard; // total Wizard that is still unclaimed (of total Wizard contract once had and was swapped to Wizard) 

    bool public allowClaimByHolder;
    bool public enabledGate;

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

    address[] public Admins;
    mapping(address => bool) public AdminByAddress;
    uint256 public FEE_PERCENT_LOCKED;// this fees is locked on contract and not claimaable => If fees_locked = 3000 (3%) => 97% of User's Wizard is claimable

    event SetAdmins(address[] Admins);
    event WizardLocked(address holder, uint256 WizardAmountIn, uint256 WizardAmountClaimable);
    event Claimed(address holder, uint256 wizardReceived);
    event FeesForLockSet(uint FEE_PERCENT_LOCKED);
    event SlippageSet(uint slippage);
    event TokenAddressSet(address wizardToken);
    event ZapParamsSet( uint startZapTime, uint startingZapFeePercent, uint totalEventGateTime, uint reductionSector, uint reductionRate);

    function initialize(address _wizardToken)  public initializer  {

        __Ownable_init_unchained();
        
        AdminByAddress[msg.sender] = true; // owner is also admin by default

        require(_wizardToken != address(0), "WizardEventGate: _wizardToken cannot be zero address");

        wizardToken = _wizardToken;

        zapParams.startZapTime = block.timestamp + 60; // time from which this will start
        zapParams.startingZapFeePercent = 90000; // starting base, 90% fee from startTime => will reduce gradually every sector
        zapParams.totalEventGateTime = 288000; // 80 hrs this reduction will happen, after that no zapping/adding liquidity mechanism
        zapParams.reductionSector = 18000; // will change fee% every 5 hrs
        zapParams.reductionRate = 5000; //will reduce fee% by 5% every sector on current fee
        
        slippage = 99000;
        MIN_WIZARD = 1 ether; // 1 Wizard

        totalLockedWizard = 0; // total Wizard that is still unclaimed

        allowClaimByHolder = false; // only owner can claim
        totalHolders = 0;
        enabledGate = true;
        FEE_PERCENT_LOCKED = 1500; //1.5%    
    }

    function setMinimumAmountToTransfer(uint256 min_wizard_amt) external onlyOwner{
        MIN_WIZARD = min_wizard_amt;
    }

    // Wizard token address
    function setTokenAddresses(address _wizardToken) external onlyOwner{
        require(_wizardToken != address(0), "WizardEventGate: _wizardToken cannot be zero address");
        wizardToken = _wizardToken;
        emit TokenAddressSet(wizardToken);

    }

    function setFeesForLock(uint256 fee_percent_locked) external onlyOwner{
        FEE_PERCENT_LOCKED = fee_percent_locked;
        emit FeesForLockSet(FEE_PERCENT_LOCKED);
    }

    function setSlippage(uint256 _slippage) external onlyAdmin{
        slippage = _slippage;
        emit SlippageSet(slippage);
    }

    // _startZapTime = unix timestamp from when to start => 1221223
    // _startingZapFeePercent = 90% => 90000
    // _totalEventGateTime (x)= overall time for which this will apply in seconds, 12 hrs => 60*60*12 => owner responsible to set this correct!
    // _reductionSector (y) = reduce x every y seconds, 15 minutes => 60*15
    // _reductionRate = 15% => 15000
    function setZapParams(uint256 _startZapTime, uint256 _startingZapFeePercent, uint256 _totalEventGateTime, uint256 _reductionSector, 
                            uint256 _reductionRate) external onlyOwner{

        uint256 powerPercent = _totalEventGateTime.div(_reductionSector);
        uint256 reductionFeeMultiplier = SafeMath.sub(100000, _reductionRate);

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

    function enableGate(bool allow) external onlyOwner {
        enabledGate = allow;
    }

    function lockWizard(address sender, address recipient, uint256 amount) public returns(uint256)
    {
        require(msg.sender == wizardToken, "Only Wizard token can call this while eventgate mechanisms are active");
        uint256 remAmount = amount;
        if(enabledGate){
            uint256 currTime = block.timestamp;
            if (zapParams.startZapTime <= currTime &&  zapParams.startZapTime + zapParams.totalEventGateTime > currTime) {
                require(amount >= MIN_WIZARD,"Wizard amount is less than MIN_Wizard amount to be bought"); // so that no micro txns occur

                uint256 totalZapFactor = getCurrentFee();
                uint256 totalLockForZap = amount.mul(totalZapFactor).div(100000);
                remAmount = amount.sub(totalLockForZap);

                uint256 claimableWizardByUserAfterFeeFactor = SafeMath.sub(100000, FEE_PERCENT_LOCKED);
                uint256 claimableWorthWizard = totalLockForZap.mul(claimableWizardByUserAfterFeeFactor).div(100000);

                // adding totalLockForZap Wizard to this contract!
                // but claimableWorthWizard is less
                balanceLocked[recipient] = balanceLocked[recipient].add(claimableWorthWizard);
                totalLockedWizard = totalLockedWizard.add(claimableWorthWizard);

                
                // so that holder is added to indexing only once
                if(!isHolderAddress[recipient]){
                    holdersAddresses[totalHolders] = recipient; // take note of address who should receive wizard later for Wizard locked   
                    totalHolders+=1;
                    isHolderAddress[recipient]=true;
                }
                emit WizardLocked(recipient,totalLockForZap,claimableWorthWizard);

            }
        }

        IERC31337(wizardToken).transfer(recipient,remAmount);
        return remAmount;
    }


    // holder can claim wizard tokens
    function setAllowClaimableByHolder(bool allow) external onlyAdmin{
        allowClaimByHolder = allow;
    }

 
    // balanceLocked[holder] -> 5% of user's balance only claimed...
    // only owner calls this function => claims Wizard for all holders
    // 5%  = 5000, 90% = 90000
    function claimWizardForAllHoldersByPercent(uint256 percent) external onlyAdmin{

        for(uint i=0; i<totalHolders;i++){
            if(balanceLocked[holdersAddresses[i]]>0)
                claimWizard(holdersAddresses[i],balanceLocked[holdersAddresses[i]].mul(percent).div(100000));
        }
    }


    // only owner calls this function => claims all Wizard for all holders
    function claimWizardForAllHolders() external onlyAdmin{

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
    function claimWizardForHolder(address holder) external returns(bool){

        if(allowClaimByHolder) require(msg.sender == holder || msg.sender == owner(),"Only holder/owner is allowed to claim");
        else require(AdminByAddress[msg.sender], "Only owner is allowed to claim");

        require(balanceLocked[holder]>0,"Cannot claim from zero balance of holder");

        claimWizard(holder,balanceLocked[holder]);        
        return true;
    }


    // internal function called by claimWizardForAllHolders() & claimWizardForHolder(address holder)
    function claimWizard(address holder, uint256 amount) internal{
        
        uint256 WizardLockedOfHolder = balanceLocked[holder];
        require(WizardLockedOfHolder>=amount,"Balance locked by user is lesser");

        IERC31337(wizardToken).transfer(holder, amount);
        
        totalLockedWizard = totalLockedWizard.sub(amount);
        balanceLocked[holder] = balanceLocked[holder].sub(amount);

        emit Claimed(holder,amount);
    }


    function availableWizardInContract() public view returns(uint256){
        return IERC31337(wizardToken).balanceOf(address(this));
    }

    // owner calls to get extra Wizard out of the contract
    function ejectAllWizardFee() external onlyOwner{
        uint256 totalWizardInContract = availableWizardInContract();
        IERC31337(wizardToken).transfer(owner(),totalWizardInContract.sub(totalLockedWizard));
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



}