/**
 *Submitted for verification at BscScan.com on 2021-03-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

//    Interfaces   

import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

//**********************************//
//             BaseToken 
//**********************************//

abstract contract BaseToken  is ERC20, Ownable {

    address public            contingencyFundsVault;
    address public            projectFundsVault;
    address internal          liquidityWallet;
    address internal          _swapRouterAddress;
    address internal constant wicksellReserves       = 0x1054571817646156391262428003302280744722;
    address internal constant goldenBonus            = 0x1618033988749894848204586834365638117720;
    address internal constant loyaltyRewards         = 0x2414213562373095048801688724209698078569;
    address internal constant corporateAssets        = 0x5772156649015328606065120900824024310421; 
    address internal constant regulatoryFunds        = 0x1324717957244746025960908854478097340734;


    uint48  internal constant _baseSupply            = 1500000000;  
    uint8   internal constant _decimals              = 9;
    bool    internal          isBurnable             = true;
    uint16  internal constant tenK                   = 10000;
    uint16  internal constant bonusFee               = 450;
    uint16  internal constant liquidityFee           = 300;
    uint16  internal constant projectFee             = 200;                     
    uint16  internal constant contingencyFee         = 50;
    uint16  internal constant maxDynamicFee          = 500;
    uint16  internal constant minDynamicFee          = 50;
    uint16  public            efficiencyFactor;                      // Must be calibrated between 150 and 250 
    uint16  internal          reducedLiquidityFee;                   // Initially 1%            (Depends on efficiencyFactor)
    uint16  internal          reducedBonusFee;                       // Initially 2%            (Depends on efficiencyFactor)
    uint16  internal          reducedProjectFee;                     // Initially 1%            (Depends on efficiencyFactor)
    uint256 internal          _liquidityThreshold;            	     // 0.05% of Tokens Suplly  (Depends on efficiencyFactor)

    uint256 internal          _tokensSupply          = (_baseSupply     )  * 10**_decimals;
    uint256 internal constant _maxWalletBalance      = (_baseSupply / 100) * 10**_decimals; 	 // 1% of the total supply
    uint256 internal constant _maxTokensPerTx        = (_baseSupply / 200) * 10**_decimals;      // 0.5% of  Tokens Supply
  
    struct AccountInfo {uint256 balance; uint48 lastTxn; uint48 nextMilestone; uint48 headFrozenAssets;
                        bool isInternal; bool isTaxFree; bool isNonBonus; bool isLocked; bool isUnrewardable; }

    struct AssetsInfo {uint256 balance; uint48 releaseTime;}
	        
    mapping (address => AccountInfo) internal Wallet;
    mapping (address => mapping (uint48 => AssetsInfo)) internal frozenAssets;

//   ======================================
//             Constructor Function             
//   ======================================

    constructor (address _projectFundsVault,
                 address _contingencyFundsVault, 
                 address _liquidityWallet, 
                 address swapRouterAddress)  {

        contingencyFundsVault = _contingencyFundsVault;
        projectFundsVault     = _projectFundsVault;
        liquidityWallet       = _liquidityWallet;
        _swapRouterAddress    = swapRouterAddress;

    }

    function _tokenTransfer(address, address, uint256, bool) internal virtual {}

//   ======================================
//          IERC20 Functions                
//   ======================================

    function decimals()    public pure override returns (uint8)   { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _tokensSupply; }

}
//**********************************//
//     M A N A G E A B L E 
//**********************************//

abstract contract Manageable is AccessControl {
    
    uint8 constant Contract_Manager     = 1;
    uint8 constant Financial_Controller = 11;
    uint8 constant Compliance_Auditor   = 12;
    uint8 constant Distributor_Agent    = 13;
    uint8 constant Treasury_Analyst     = 111;

    constructor() {
       _setupRole(Contract_Manager,     _msgSender());
       _setupRole(Financial_Controller, _msgSender());
       _setupRole(Compliance_Auditor,   _msgSender());
       _setupRole(Treasury_Analyst,     _msgSender());
       _setupRole(Distributor_Agent,    _msgSender());

       _setRoleAdmin(Contract_Manager,     Contract_Manager);
       _setRoleAdmin(Financial_Controller, Contract_Manager);
       _setRoleAdmin(Distributor_Agent,    Contract_Manager);
       _setRoleAdmin(Compliance_Auditor,   Contract_Manager);
       _setRoleAdmin(Treasury_Analyst,     Financial_Controller);
    }
}
//**********************************//
//        A D J U S T A B L E   
//**********************************//

abstract contract Adjustable  is Pausable, Manageable, BaseToken {

    bool      public   allowSecurityPause = true;
    address[] internal _noBonus;

    event NumTokensToLiquidityUpdated(address authorizer, uint256 _liquidityThreshold);
    event MaxTokensPerTxUpdated(address authorizer, uint256 _maxTokensPerTx);
    event LiquidityWalletUpdated(address authorizer, address liquidityWallet);
    event ContingencyFundsVaultUpdated(address authorizer, address _contingencyFundsVault);
    event ProjectFundsVaultUpdated(address authorizer, address _projectFundsVault);
    event EfficiencyFactorUpdated (address authorizer, uint16 _newValue);

    function _addInternalStatus (address account, bool isLocked) internal {
        Wallet[account].isInternal     = true;
        Wallet[account].isTaxFree      = true;
        Wallet[account].isLocked       = isLocked;
        Wallet[account].isNonBonus     = true;
        Wallet[account].isUnrewardable = true;
        _noBonus.push(account);
    }

    function _removeInternalStatus (address account) internal {
        Wallet[account].isInternal = false;
        Wallet[account].isTaxFree  = false;
        Wallet[account].isLocked   = false;
    }

    function _setEfficiencyFactor (uint16 _newFactor) internal {
        efficiencyFactor       = _newFactor;
        reducedLiquidityFee    = efficiencyFactor/2;      
        reducedBonusFee        = efficiencyFactor;
        reducedProjectFee      = efficiencyFactor/2;              
        _liquidityThreshold    = _tokensSupply / (efficiencyFactor*10); 	 
    }
//   ======================================
//           Parameters Functions                    
//   ======================================

    function setEfficiencyFactor (uint16 _newValue) external onlyRole(Financial_Controller) {
        require (_newValue >= 150 && _newValue <= 250, "Out of thresholds");
        _setEfficiencyFactor (_newValue);
        emit EfficiencyFactorUpdated (_msgSender(), _newValue);
    }

    function setLiquidityWallet(address _liquidityWallet) external onlyRole(Financial_Controller) {
        require ( Wallet[_liquidityWallet].balance == 0, "New account is not empty");
        _addInternalStatus (_liquidityWallet, false);
        _removeInternalStatus (liquidityWallet);                // NOTE: The previous account remains without receiving bonus 
        liquidityWallet = _liquidityWallet;
        emit LiquidityWalletUpdated(_msgSender(), liquidityWallet);
    }

    function setContingencyFundsVault(address _contingencyFundsVault) external onlyRole(Financial_Controller) {
        require ( Wallet[_contingencyFundsVault].balance == 0, "New account is not empty");
        _addInternalStatus (_contingencyFundsVault, false);
        _removeInternalStatus (contingencyFundsVault);          // NOTE: The previous account remains without receiving bonus 
        contingencyFundsVault = _contingencyFundsVault;
        emit ContingencyFundsVaultUpdated(_msgSender(), contingencyFundsVault);
    }

    function setProjectFundsVault(address _projectFundsVault) external onlyRole(Financial_Controller) {
        require ( Wallet[_projectFundsVault].balance == 0, "New account is not empty");
        _addInternalStatus (_projectFundsVault, false);
        _removeInternalStatus (projectFundsVault);              // NOTE: The previous account remains without receiving bonus 
        projectFundsVault = _projectFundsVault;
        emit ProjectFundsVaultUpdated(_msgSender(), projectFundsVault);
    }

//   ======================================
//           Contingency Functions                    
//   ======================================

  // Called by the Compliance Auditor on emergency, allow begin or end an emergency stop
    function setSecurityPause(bool isPause) external onlyRole(Compliance_Auditor) {
        if (isPause)  {
            require(  allowSecurityPause, "Contingency pauses not allowed." );
            _pause();
        } else {
            require( paused(), "Contingency pause is not active.");
            _unpause();  
        }
    }
    
  // Called by the Financial Controller to disable ability to begin or end an emergency stop
    function disableContingencyFeature() external onlyRole(Financial_Controller)  {
        allowSecurityPause = false;
    }

}
//**********************************//
//    F L O W - F L E X I B L E
//**********************************//
abstract contract  FlowFlexible is Manageable, BaseToken {

    uint48 internal constant _sellRange    = 30  minutes;
    uint48 internal constant _loyaltyRange = 180 days;
    uint48 internal constant _burnRange    = 90  days;

    event AddedToBlockList (address authorizer, address _user);
    event RemovedFromBlockList (address authorizer, address _user);
    event TookUnfitEarnings (address authorizer, address unfitTrader, uint256 _balance);
    event WicksellReservesBurned (address authorizer, uint256 burnAmount);
   
    function _getDynamicFee (address account, uint256 sellAmount) internal returns (uint256) {
        
        uint256 reduceFee;
        uint256 sellQuocient; 
        uint256 reduceFactor;

        uint256 dynamicFee = Wallet[account].balance * maxDynamicFee * efficiencyFactor / _tokensSupply;
       
        if (dynamicFee > maxDynamicFee) {dynamicFee = maxDynamicFee;}
        if (dynamicFee < minDynamicFee) {dynamicFee = minDynamicFee;}
        
        if (Wallet[account].lastTxn + _sellRange < block.timestamp) {
            sellQuocient = (sellAmount * tenK) / Wallet[account].balance;
            reduceFactor = (sellQuocient > 1000) ? 0 : (1000 - sellQuocient);
            reduceFee    = (reduceFactor * 30) / 100;
            dynamicFee  -= reduceFee;
        }

        Wallet[account].lastTxn = uint48(block.timestamp);
        return dynamicFee;
    }

    function setNextMilestone (address account, uint256 txAmount) internal {
        uint256 elapsedTime  = _loyaltyRange + block.timestamp - Wallet[account].nextMilestone;
        uint256 adjustedTime = ( elapsedTime * Wallet[account].balance) / ( Wallet[account].balance + txAmount ); 
        Wallet[account].nextMilestone = uint48(block.timestamp + _loyaltyRange - adjustedTime);
        Wallet[account].lastTxn = uint48(block.timestamp);
    }

    function WicksellReserves () external view returns (uint256) {
        return balanceOf(wicksellReserves) / (10**_decimals);
    }

    function CorporateAssetsAvailable () external view returns (uint256) {
        return Wallet[corporateAssets].balance / (10**_decimals);
    }

    function RegulatoryFundsAvailable () external view returns (uint256) {
        return Wallet[regulatoryFunds].balance / (10**_decimals);
    }

//   ======================================
//            Manageable Functions                    
//   ======================================

    function addToBlockList (address _markedAccount) external onlyRole(Treasury_Analyst) {
        require (!Wallet[_markedAccount].isInternal, "Internal Account is immutable"); 
        Wallet[_markedAccount].isLocked = true;
        emit AddedToBlockList(_msgSender(), _markedAccount);
    }

    function removeFromBlockList (address _clearedAccount) external onlyRole(Compliance_Auditor) {
        require (!Wallet[_clearedAccount].isInternal, "Internal Account is immutable"); 
        Wallet[_clearedAccount].isLocked = false;
        emit RemovedFromBlockList(_msgSender(), _clearedAccount);
    }
    
    function wicksellBurn () external onlyRole(Treasury_Analyst) {
        require (Wallet[wicksellReserves].lastTxn + 30 days < block.timestamp, "Time elapsed too short");
        uint256 elapsedTime  = _burnRange + block.timestamp - Wallet[wicksellReserves].nextMilestone;
        uint256 burnAmount;
       
        if ( elapsedTime > _burnRange) { 
             burnAmount = Wallet[wicksellReserves].balance;                                // Balance without the part reffering to bonus
             Wallet[wicksellReserves].nextMilestone = uint48(block.timestamp + _burnRange);
        } else {
             burnAmount = (Wallet[wicksellReserves].balance * elapsedTime) / _burnRange;
        }

        Wallet[wicksellReserves].balance -= burnAmount;                                     // Burn only the raw balance, without the bonus
        _tokensSupply                    -= burnAmount;

        emit WicksellReservesBurned (_msgSender(), burnAmount);
    }
}
//**********************************//
//   A U T O L I Q U I D I T Y
//**********************************//

abstract contract AutoLiquidity is BaseToken, Adjustable {

    uint256 private _coinBalance;

    IUniswapV2Router02 internal _swapRouter;
    address public liquidityPair;
 
    bool    public   autoLiquidity = true;
    bool    internal inLiquidityProcess; 

    modifier nonReentrant {
        inLiquidityProcess = true;
        _;
        inLiquidityProcess = false;
    }
    
    event LiquidityIncreased(uint256 tokensSwapped, uint256 coinsReceived, uint256 tokensIntoLiquidity);    
    event CoinsTransferred(address recipient, uint256 amountCoins);
    event LiquidityResidueTaken(uint256 residueCoins);
    event AutoLiquiditySet (address authorizer, bool _status);

//   ======================================
//             Constructor Function             
//   ======================================  
    constructor () {

        IUniswapV2Router02 swapRouter = IUniswapV2Router02(_swapRouterAddress);    	//DEX Swap's Address
        
        // Create a Uniswap/Pancakeswap pair for this new Token
        liquidityPair = IUniswapV2Factory(swapRouter.factory()).createPair(address(this),swapRouter.WETH());

        // set the rest of the contract variables
        _swapRouter = swapRouter;
    }
//   ======================================
//     To receive Coins from swapRouter           
//   ======================================

    receive() external payable {}                      			

//   ======================================
//      BEGIN Function swapAndLiquify  
//   ======================================

    function increaseLiquidity(uint256 numTokensToLiquidity) internal nonReentrant {

        // **** Split the 'numTokensToLiquidity' into halves  ***
        uint256 swapAmount      = numTokensToLiquidity / 2;
        uint256 liquidityAmount = numTokensToLiquidity - swapAmount;

        // NOTE: Capture the contract's current Coins balance,  
        // thus we can know exactly how much Coins the swap 
        // creates, and not make recent events include any Coin  
        // that has been manually sent to the contract. 
        uint256 initialCoinBalance = address(this).balance;

        // Swap tokens for Coins (01)
        swapProcess(swapAmount);

        // Calculate how much Coins was swapped
        uint256 swappedCoins = address(this).balance - initialCoinBalance;

        // Add liquidity to DEX  (02)
        liquidityProcess(liquidityAmount, swappedCoins);

        emit LiquidityIncreased(swapAmount, swappedCoins, liquidityAmount);

        /** NOTE:  ***  Take Remaining Balance  (03)   ***
        *   For every "swapAndLiquify" function call, a small amount of Coins remains in the contract. 
        *   So we provide a method to withdraw automatically these funds, otherwise those coins would 
        *   be locked in the contract forever.
        */
        uint256 residueCoins =  address(this).balance - initialCoinBalance;   

        if (residueCoins > 0) { payable(liquidityWallet).transfer(residueCoins); }

        _coinBalance = address(this).balance;
       
        emit LiquidityResidueTaken(residueCoins);
    }
//   ======================================
//          Special Functions                    
//   ======================================  

    function swapProcess (uint256 swapAmount) private {
        address[] memory path = new address[](2);                       // Generate the DEX pair path of token -> weth
        path[0] = address(this);
        path[1] = _swapRouter.WETH();

        _approve(address(this), address(_swapRouter), swapAmount);

        // Make the Swap
         _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0, 				// Accept any amount of Coins
            path,
            address(this),  // Recipient of the ETH/BNB 
            block.timestamp
        );
    }

    function liquidityProcess(uint256 liquidityAmount, uint256 swappedCoins) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(_swapRouter), liquidityAmount);   

        // Add the liquidity
        _swapRouter.addLiquidityETH{value: swappedCoins}(
            address(this),
            liquidityAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,                      // Recipient of the liquidity tokens.
            block.timestamp  );
    }

    function TransferCoins (address recipient) external onlyRole(Treasury_Analyst) {
        require(Wallet[recipient].isInternal, "Recipient not allowed");
        require(_coinBalance > 0, "The Balance must be greater than 0");

        // Prevent re-entrancy attacks. The balance will only be updated again
        // the next time the  "increaseLiquidity" method is called. 
        uint256 amountToTransfer = _coinBalance;
        _coinBalance = 0;			

        payable(recipient).transfer(amountToTransfer);
        emit CoinsTransferred(recipient, amountToTransfer);
    }

    function setAutoLiquidity (bool _status) external onlyRole(Treasury_Analyst) {
        autoLiquidity = _status;
        emit AutoLiquiditySet (_msgSender(), _status);
    }
}
//**********************************//
//   T   A   X   A   B   L   E 
//**********************************//

abstract contract Taxable is FlowFlexible, AutoLiquidity {
    using Address  for address;
    
    uint256 private _supplyDeviation;
    bool    private isAdjustable = true;

    struct AmountInfo {
           uint256 Inflow;
           uint256 Outflow;
    }

    struct BonusInfo {
           uint256 Balance;
           uint256 Inflow;
           uint256 Outflow;
    }
     
    struct FeesInfo {
           uint256 Liquidity;
           uint256 Funds;
           uint256 Bonus;
           uint256 Burn;
           uint256 WicksellReserves;
           uint256 LoyaltyRewards;
           uint256 Project;
           uint256 Contingency;
    }

    event FeesTransfered(uint256 Liquidity, uint256 Contingency, uint256 Project, uint256 Bonus, uint256 LoyaltyRewards, uint256 WicksellReserves, uint256 Burn );
    event SetExcludedFromBonus (address authorizer, address account, bool status);
    event SetTaxableStatus (address authorizer, address account, bool status);
    event TokensBurnt (address account, uint256 burnAmount);
    event RewardsClaimed (address account, uint256 amountRewards);  
    event AssetsSentAndFrozen (address _recipient, uint64 _freezeDuration, uint256 _amountToFreeze);
    event AssetsUnfrozen (address _recipient, uint256 _amountReleased);
    event LongTermAssetsShared (address authorizer, address beneficiary, uint256 amount);

//   ======================================
//             Constructor Function             
//   ====================================== 
    constructor () {

        Wallet[corporateAssets].balance = _maxWalletBalance * 5;
        Wallet[regulatoryFunds].balance = _maxWalletBalance * 5;
        Wallet[_msgSender()].balance    = _tokensSupply - Wallet[corporateAssets].balance - Wallet[regulatoryFunds].balance;

        _addInternalStatus (owner(), false);
        _addInternalStatus (address(this), false);
        _addInternalStatus (projectFundsVault, false);
        _addInternalStatus (contingencyFundsVault, false);
        _addInternalStatus (liquidityWallet, false);
        _addInternalStatus (wicksellReserves, true);
        _addInternalStatus (goldenBonus, true);
        _addInternalStatus (loyaltyRewards, true);
        _addInternalStatus (corporateAssets, true);
        _addInternalStatus (regulatoryFunds, true);

        _includeInBonus(wicksellReserves);
 
        // Exclude liquidityPair from Bonus

        Wallet[liquidityPair].isNonBonus = true;
        _noBonus.push(liquidityPair);

        // This factor calibrates the contract performance and the values of reduced fees 

        _setEfficiencyFactor (200);
        
        emit Transfer(address(0), _msgSender(), _tokensSupply);
    }
//  =======================================
//        IERC20 Functions (OVERRIDE)              
//   ======================================

    function balanceOf(address account) public view override returns (uint256) {
        return Wallet[account].balance + _getBonus(account);
    }
//   ======================================
//          BEGIN Function _transfer   
//   ======================================

    function _transfer( address sender, address recipient, uint256 amount ) internal override whenNotPaused {
        require(!Wallet[sender].isLocked, "This address can not send");  
        require(sender != address(0) && sender != address(0), "This address is blocked");
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(sender) >= amount, "Insufficient balance to transfer"); 
    
        if (!Wallet[sender].isInternal  && !Wallet[recipient].isInternal) {  
            require(amount <= _maxTokensPerTx, "Transfer exceeds the maximum limit."); 
        }

        if ( !Wallet[sender].isInternal && 
             !Wallet[recipient].isInternal &&
             recipient != liquidityPair )  {

             require( balanceOf(recipient) + amount <= _maxWalletBalance, "Wallet balance exceed the limit");
        }      

        //  Indicates that all fees should be deducted from transfer
        bool applyFee = (Wallet[sender].isTaxFree || Wallet[recipient].isTaxFree) ? false:true;
        uint256 tokenToLiquidity = Wallet[address(this)].balance;

        if (autoLiquidity && !inLiquidityProcess  && 
            sender != liquidityPair && tokenToLiquidity >= _liquidityThreshold) { 
            increaseLiquidity (tokenToLiquidity);
        }

        _tokenTransfer(sender, recipient, amount, applyFee); 
  
        _afterTokenTransfer(sender, recipient, amount);

      }
//   ======================================
//      BEGIN Function _tokenTransfer                   
//   ======================================

//   This Function is responsible for taking all fee, if 'applyFee' is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool applyFee) internal override {

        BonusInfo  memory bonus;
        FeesInfo   memory fees;
        AmountInfo memory amount;

        uint256 totalFees;
        uint256 deflatFee;
        uint256 WicksellReservesFee;
        uint256 loyaltyRewardsFee;
        uint256 dynamicFee;

        if (applyFee) {
            if (sender == liquidityPair) {
               fees.Bonus          = (tAmount * bonusFee) / tenK;
               fees.Project        = (tAmount * projectFee) / tenK;
               totalFees           = fees.Bonus + fees.Project;

               (fees, totalFees) = _calcFees (tAmount, 0, 0, 0, 0, 0, bonusFee, projectFee); 

            } else if (recipient == liquidityPair) {
               dynamicFee = _getDynamicFee(sender, tAmount);

               if (isBurnable) {
                      loyaltyRewardsFee  = dynamicFee < (2 * minDynamicFee) ? dynamicFee : (2 * minDynamicFee);
                      dynamicFee        -= loyaltyRewardsFee;
                      deflatFee        = dynamicFee / 3;
                      WicksellReservesFee    = dynamicFee - deflatFee;
               } else {loyaltyRewardsFee = dynamicFee;}

                (fees, totalFees) = _calcFees (tAmount, liquidityFee, deflatFee, WicksellReservesFee, loyaltyRewardsFee,
                                               contingencyFee, reducedBonusFee, reducedProjectFee); 
            } else {

                (fees, totalFees) = _calcFees (tAmount, reducedLiquidityFee, 0, 0, minDynamicFee,
                                               contingencyFee, reducedBonusFee, reducedProjectFee); 
            }
        }

        uint256 transferAmount = tAmount - totalFees;

        // All calculations must be done before updating any balance. 
        (bonus.Inflow, amount.Inflow) = (Wallet[recipient].isNonBonus) ? (0, transferAmount) : _shareAmount(transferAmount);

        bonus.Balance  = _getBonus(sender);
        bonus.Outflow  = bonus.Balance > 0 ? (bonus.Balance * tAmount) / balanceOf(sender) : 0;

        amount.Outflow = tAmount - bonus.Outflow;

       // Update of sender and recipient balances 
        if (!Wallet[recipient].isLocked) {setNextMilestone(recipient, amount.Inflow);}

        Wallet[sender].balance    -= amount.Outflow;
        Wallet[recipient].balance += amount.Inflow;

         // Update the Bonus Shares 
        Wallet[goldenBonus].balance =  Wallet[goldenBonus].balance + bonus.Inflow - bonus.Outflow; 

        emit Transfer(sender, recipient, tAmount);

        // Collect all Fees and Bonus    
        if ( applyFee ) {
            Wallet[address(this)].balance          +=  fees.Liquidity; 
            Wallet[contingencyFundsVault].balance  +=  fees.Contingency;
            Wallet[projectFundsVault].balance      +=  fees.Project;
            Wallet[goldenBonus].balance            +=  fees.Bonus;
            Wallet[loyaltyRewards].balance         +=  fees.LoyaltyRewards;
            if (isBurnable) {
                Wallet[wicksellReserves].balance   +=  fees.WicksellReserves; 
                _tokensSupply                      -=  fees.Burn;
                if (_tokensSupply - Wallet[wicksellReserves].balance <= ( _baseSupply * (10 ** _decimals) / 3) ) {
                   isBurnable = false;
                }
            }  
            emit FeesTransfered(fees.Liquidity, fees.Contingency, fees.Project, fees.Bonus, fees.LoyaltyRewards, fees.WicksellReserves, fees.Burn );
        }
    }
//   ==========================================
//     BEGIN Function  __afterTokenTransfer     
//   ==========================================

    function _afterTokenTransfer(address sender, address recipient, uint256 amount) internal {    

        if ( autoLiquidity &&  isAdjustable ) {

            if      (sender    == liquidityPair) {_supplyDeviation += amount;}
            else if (recipient == liquidityPair) {_supplyDeviation -= amount;}
            else return;

            if ((_supplyDeviation > (Wallet[liquidityPair].balance  * 90)/100) && isAdjustable) {

                if (Wallet[regulatoryFunds].balance >= _supplyDeviation) {
                    Wallet[regulatoryFunds].balance -= _supplyDeviation;      
                    Wallet[address(this)].balance   += _supplyDeviation;
                    _supplyDeviation                -= 0;
                }
                else {
                    Wallet[wicksellReserves].balance += Wallet[regulatoryFunds].balance;
                    Wallet[regulatoryFunds].balance   = 0;
                    isAdjustable  = false;
                }
            }
        }
    }
//   ======================================
//     BEGIN Function  _calcFees     
//   ======================================
    function _calcFees (uint256 _tAmount, uint256 _liquidityFee, 
                        uint256 _deflatFee, uint256 _wicksellFee, 
                        uint256 _loyaltyRewardsFee, uint256 _contingencyFee, 
                        uint256 _bonusFee, uint256 _projectFee) private pure returns (FeesInfo memory, uint256) {
               
        FeesInfo memory fees;
        uint256 totalFees;

        fees.Liquidity            = (_tAmount * _liquidityFee) / tenK;
        fees.Burn                 = (_tAmount * _deflatFee) / tenK;
        fees.WicksellReserves     = (_tAmount * _wicksellFee) / tenK;
        fees.LoyaltyRewards       = (_tAmount * _loyaltyRewardsFee) / tenK;
        fees.Contingency          = (_tAmount * _contingencyFee) / tenK;
        fees.Bonus                = (_tAmount * _bonusFee) / tenK;
        fees.Project              = (_tAmount * _projectFee) / tenK;
        totalFees                 = fees.Liquidity + fees.Burn + fees.WicksellReserves + fees.LoyaltyRewards + 
                                    fees.Contingency + fees.Bonus + fees.Project;
        return (fees, totalFees);
    }
//   ======================================
//               RFI Functions                  
//   ======================================

    /** NOTE:
     *  The "_getBonus", "_shareAmount" and "_bonusBalances" functions help to redistribute 
     *  the specified  amount of Bonus among the current holders via an special algorithm  
     *  that eliminates the need for interaction with all holders account. 
     */
    function _shareAmount (uint256 tAmount) private view returns (uint256, uint256) {
        if (Wallet[goldenBonus].balance == 0) return (0, tAmount);
        uint256 _bonusStock   = Wallet[goldenBonus].balance;
        uint256 _bonusAmount  = (tAmount * _bonusStock) / (_bonusBalances() + _bonusStock);
        uint256 _rawAmount    = tAmount - _bonusAmount; 
        return (_bonusAmount, _rawAmount);
    }

    function _getBonus (address account) internal view returns (uint256) {
        if ( Wallet[account].isNonBonus || Wallet[goldenBonus].balance == 0 || Wallet[account].balance == 0 ){
            return 0;
        } else {
            uint256 shareBonus = (Wallet[goldenBonus].balance * Wallet[account].balance) / _bonusBalances();
            return  shareBonus;
        }
    }

    function _bonusBalances () private view returns (uint256) {
        uint256 expurgedBalance;
        for (uint256 i=0; i < _noBonus.length; i++){
            expurgedBalance += Wallet[_noBonus[i]].balance;
        }
        return  _tokensSupply- expurgedBalance;                 
    }

    function isNonTaxable(address account) external view returns(bool) {
        return Wallet[account].isTaxFree;
    }

    function isExcludedFromBonus(address account) external view returns (bool) {
        return Wallet[account].isNonBonus;
    }

    function TotalBonusCredited() external view returns (uint256) {
        return Wallet[goldenBonus].balance / (10**_decimals);
    }

    function AccruedLoyaltyRewards() external view returns (uint256) {
        return Wallet[loyaltyRewards].balance / (10**_decimals);
    }

    function _excludeFromBonus(address account) internal {
        uint256 _bonus = _getBonus(account); 
        Wallet[account].balance     += _bonus;
        Wallet[goldenBonus].balance -= _bonus;
        Wallet[account].isNonBonus   = true;
        _noBonus.push(account);
    }

    function _includeInBonus(address account) internal {
        (uint256 _adjustedBonus, uint256 _adjustedBalance) = _shareAmount(Wallet[account].balance);
        for (uint256 i = 0; i < _noBonus.length; i++) {
            if (_noBonus[i] == account) {
                _noBonus[i] = _noBonus[_noBonus.length - 1];
                Wallet[account].isNonBonus   = false;
                Wallet[account].balance      = _adjustedBalance;
                Wallet[goldenBonus].balance += _adjustedBonus;
                _noBonus.pop();
                break;
            }
        }
    }

    function _freezeAssets(address _recipient, uint256 _amountToFreeze, uint64 _freezeDuration) internal {
        uint48 _currentRelease;                                                                                               
        uint48 _freezeTime = uint48((block.timestamp + _freezeDuration * 86400) / 86400);     
        uint48 _nextRelease = Wallet [_recipient].headFrozenAssets;

        if (_nextRelease == 0 || _freezeTime < _nextRelease ) { 
           Wallet [_recipient].headFrozenAssets               = _freezeTime;
           frozenAssets [_recipient][_freezeTime].balance     = _amountToFreeze;
           frozenAssets [_recipient][_freezeTime].releaseTime = _nextRelease;
           return; 
        }

        while (_nextRelease != 0 && _freezeTime > _nextRelease ) {
            _currentRelease    = _nextRelease;
            _nextRelease = frozenAssets [_recipient][_currentRelease].releaseTime;
        }

        if (_freezeTime == _nextRelease) {
            frozenAssets [_recipient][_nextRelease].balance += _amountToFreeze; 
            return;
        }

        frozenAssets [_recipient][_currentRelease].releaseTime = _freezeTime;
        frozenAssets [_recipient][_freezeTime].balance         = _amountToFreeze;
        frozenAssets [_recipient][_freezeTime].releaseTime     = _nextRelease;
    }
//   ======================================
//            Manageable Functions                    
//   ======================================

    function shareLongTermAssets (address _beneficiary, uint256 _amount) external  onlyRole(Contract_Manager) {
        require (!Wallet[_beneficiary].isInternal && !Wallet[_beneficiary].isLocked 
                 && Wallet[_beneficiary].balance == 0, "Does not fit the requisites");
        uint256 _sharedAssets = _amount * (10**_decimals);
        require (_sharedAssets <= (_maxTokensPerTx / 10), "Amount above limit" );
        require (_sharedAssets <= Wallet[corporateAssets].balance, "Corporate Assets insufficient");

        _freezeAssets (_beneficiary, _sharedAssets, 720);  

        Wallet[corporateAssets].balance -= _sharedAssets;
        emit LongTermAssetsShared (_msgSender(), _beneficiary, _amount);
    }

    function freezeUnfitEarnings (address unfitTrader) external onlyRole(Financial_Controller) {  
        require(Wallet[unfitTrader].isLocked, "Account is not Blocked");
        require(!Wallet[unfitTrader].isNonBonus, "Account without Bonus");
        uint256 _bonusUnfit = _getBonus(unfitTrader);
        require(_bonusUnfit > 0, "There are no Earnings");
          
        _excludeFromBonus(unfitTrader);               // Exclude the account from future Bonus
        Wallet[unfitTrader].isLocked = false;         // Release the account for Financial movement 
        Wallet[unfitTrader].balance -= _bonusUnfit;
 
        // Half of unfit earnings is frozen and the other half is redistributed to holders
        uint256 _bonusHalf           = _bonusUnfit / 2;
        uint256 _freezeHalf          = _bonusUnfit - _bonusHalf;
        Wallet[goldenBonus].balance += _bonusHalf;                      // Share half of the unfit earnings

        _freezeAssets (unfitTrader, _freezeHalf, 1095);                 // Freeze the other half for 3 years
 
        emit TookUnfitEarnings(_msgSender(), unfitTrader, _bonusUnfit);
    }

    function adjustLiquiditySupply() external onlyRole(Treasury_Analyst) {
        uint256 tokenToLiquidity = Wallet[address(this)].balance;
        require (autoLiquidity && !inLiquidityProcess && 
                 tokenToLiquidity >= _liquidityThreshold, "Adjust not allowed at the moment");
        increaseLiquidity (tokenToLiquidity);                                             
    }
    
    function excludeFromBonus(address account) external onlyRole(Treasury_Analyst) {
        require(!Wallet[account].isNonBonus, "Account already non-bonus");
        require(account != wicksellReserves,"The Account can not be excluded");
        _excludeFromBonus(account);
        emit SetExcludedFromBonus (_msgSender(), account, true);
    }
    
    function includeInBonus(address account) external onlyRole(Compliance_Auditor) {
        require(Wallet[account].isNonBonus, "Account already receive bonus");
        require( (!Wallet[account].isInternal && account != liquidityPair), "Account can not receive bonus");
        _includeInBonus(account);
        emit SetExcludedFromBonus (_msgSender(), account, false);
    }

    function setTaxable (address account) external onlyRole(Treasury_Analyst) {
        require (!Wallet[account].isInternal,"Account can not be taxable");
        Wallet[account].isTaxFree = true;
        emit SetTaxableStatus (_msgSender(), account, true);
    }
    
    function setNonTaxable(address account) external onlyRole(Compliance_Auditor) {
        require (!Wallet[account].isInternal,"Account already non taxable");
        Wallet[account].isTaxFree = false;
        emit SetTaxableStatus (_msgSender(), account, false);
    }
//   ======================================
//      Ownable Functions  (OVERRIDE)             
//   ======================================

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Owner can not be burn-address");

        address oldOwner = owner();
        _transferOwnership(newOwner);

        Wallet[oldOwner].isInternal = false;
        Wallet[oldOwner].isTaxFree  = false;
        _includeInBonus(oldOwner);
        Wallet[newOwner].isInternal = true;
        Wallet[newOwner].isTaxFree  = true;
        _excludeFromBonus(newOwner);
    }
//   ======================================
//          INVESTOR Functions                   
//   ======================================

    function investorBurn (uint256 burnAmount) external { 
        require(isBurnable, "It is not allowed to burn anymore");
        require(!Wallet[_msgSender()].isInternal, "Internal Address can not burn");
        burnAmount = burnAmount * (10**_decimals);
        require(burnAmount <= balanceOf(_msgSender()), "Burn amount exceeds balance");
        
        // Balance without the part reffering to bonus (Bonus is never burned!!)
        if (burnAmount > Wallet[_msgSender()].balance) {burnAmount = Wallet[_msgSender()].balance; }   
        
        uint256 rewardsAmount = burnAmount / 3;
        uint256 deadAmount    = burnAmount - rewardsAmount;

        Wallet[_msgSender()].balance     -= burnAmount;
        Wallet[loyaltyRewards].balance   += rewardsAmount;
        Wallet[wicksellReserves].balance += deadAmount;

        emit TokensBurnt (_msgSender(), burnAmount);  
    }
    
    function claimLoyaltyRewards () external { 
        require (!Wallet[_msgSender()].isNonBonus && !Wallet[_msgSender()].isLocked &&
                 !Wallet[_msgSender()].isUnrewardable,"Not eligible for rewards");
        require (Wallet[_msgSender()].nextMilestone <= block.timestamp, "Rewards are not available yet"); 

        uint256 releasedRewards = (_getBonus(_msgSender()) * Wallet[loyaltyRewards].balance) / Wallet[goldenBonus].balance;
        (uint256 bonusSlice, uint256 balanceSlice) = _shareAmount(releasedRewards);

        Wallet[_msgSender()].balance       +=  balanceSlice;
        Wallet[goldenBonus].balance        +=  bonusSlice;

        Wallet[loyaltyRewards].balance     -= releasedRewards;
        Wallet[_msgSender()].isUnrewardable = true;

        emit RewardsClaimed (_msgSender(), releasedRewards);  
    }

    function LoyaltyRewardsAvailable (address account) external view returns (uint256) { 
     
        if (Wallet[account].isNonBonus || Wallet[account].isLocked || 
            Wallet[account].isUnrewardable || Wallet[account].nextMilestone > block.timestamp) {return 0;} 

        uint256 availableRewards = (_getBonus(account) * Wallet[loyaltyRewards].balance) / Wallet[goldenBonus].balance;
        return availableRewards;
    }

    function sendAndFreeze(address _recipient, uint256 _amountToFreeze, uint64 _freezeDuration) external {
        _amountToFreeze = _amountToFreeze * (10  **_decimals);
        
        require(!Wallet[_msgSender()].isLocked, "Wallet is locked");
        require(balanceOf(_msgSender()) >= _amountToFreeze, "Balance insufficient");
        require(!Wallet[_recipient].isInternal, "Recipient cannot be Internal");
        require(_freezeDuration >= 180 && _freezeDuration <= 1095, "Freeze duration invalid");

        _freezeAssets (_recipient, _amountToFreeze, _freezeDuration);                                                                                                

        (uint256 bonusSlice, uint256 balanceSlice) = _shareAmount(_amountToFreeze);
        Wallet[_msgSender()].balance              -=  balanceSlice;
        Wallet[goldenBonus].balance               -=  bonusSlice;

        emit  AssetsSentAndFrozen(_recipient, _freezeDuration, _amountToFreeze);
    }

    function unfrozenAssets() external {
        uint256 _frozenAmount;
        uint48  _nextRelease = Wallet [_msgSender()].headFrozenAssets;
        uint48  _currentTime = uint48(block.timestamp/86400);
        uint48  _currentNode;
        require(_nextRelease != 0, "There are no frozen assets");
        require(_currentTime > _nextRelease, "No assets to release");   

        while (_nextRelease != 0 && _currentTime > _nextRelease) {
               _frozenAmount += frozenAssets [_msgSender()][_nextRelease].balance;
               _currentNode   = _nextRelease;
               _nextRelease   = frozenAssets [_msgSender()][_currentNode].releaseTime;
                delete frozenAssets [_msgSender()][_currentNode];
         }

        Wallet [_msgSender()].headFrozenAssets = _nextRelease;

        (uint256 bonusSlice, uint256 balanceSlice) = _shareAmount(_frozenAmount);
        Wallet[_msgSender()].balance               +=  balanceSlice;
        Wallet[goldenBonus].balance                +=  bonusSlice;

        emit AssetsUnfrozen(_msgSender(),_frozenAmount);
    }

    function FrozenAssetsAvailable(address _recipient) external view returns (uint256 _frozenAmount) {
        uint48 _currentTime = uint48(block.timestamp/86400);    
        uint48 _nextRelease = Wallet [_recipient].headFrozenAssets;
        uint48 _currentNode;

        while (_nextRelease != 0 && _currentTime > _nextRelease) {
              _frozenAmount += frozenAssets [_recipient][_nextRelease].balance;
              _currentNode   = _nextRelease;
              _nextRelease   = frozenAssets  [_recipient][_currentNode].releaseTime;
        }
        
        _frozenAmount = _frozenAmount / (10 ** _decimals);
    }

    function FrozenAssetsBalance(address _recipient) external view returns (uint256 _frozenAmount) {
        uint48 _nextRelease = Wallet [_recipient].headFrozenAssets;
        uint48 _currentNode;

        while (_nextRelease != 0 ) {
              _frozenAmount += frozenAssets [_recipient][_nextRelease].balance;
              _currentNode   = _nextRelease;
              _nextRelease   = frozenAssets  [_recipient][_currentNode].releaseTime;
        }
        
        _frozenAmount = _frozenAmount / (10 ** _decimals);
    }

    function FrozenAssetsNextRelease(address _recipient) external view returns (uint48 _daysToRelease) {
        uint48 _nextRelease = Wallet [_recipient].headFrozenAssets * 86400;
        require (_nextRelease > 0, "There are no frozen assets" ); 
        require (block.timestamp < _nextRelease, "Already has releasable assets"); 
        
        _daysToRelease = uint48((_nextRelease - block.timestamp) / 86400);
    }
}
//**********************************//
//     S Y M P L E X I A  CONTRACT
//**********************************//
contract SymplexiaToken is  Taxable {

  //   constructor (string memory tokenName, string memory tokenSymbol, 
  //                address projectFundsVault, 
  //                address _contingencyVault,  
  //                address _liquidityWallet,
  //                address swapRouterAddress) { }
  //

    constructor ()  ERC20("BETA29", "BTG29") BaseToken ( 
                                     0xE0674e01Fef1Da05b10BC09cEF93e5d9C38eCfef,   
                                     0xa39d7Ca2e433164bf54Aad3Ed8d76E794746F3DA, 
                                     0xbB53A39B7FA4c00f576a729aa82c4D43D57b5924,
                                     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) 
                                     { 	}

}