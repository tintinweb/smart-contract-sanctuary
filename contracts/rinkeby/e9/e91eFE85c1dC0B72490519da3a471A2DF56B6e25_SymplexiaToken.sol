/**
 *Submitted for verification at BscScan.com on 2021-03-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./Manageable.sol";

//    Interfaces   

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

//**********************************//
//             BaseToken 
//**********************************//

abstract contract BaseToken  is ERC20, Ownable {
    
    using SafeMath for uint256;
    uint256 internal constant _NOT_ENABLED = 0;
    uint256 internal constant _ENABLED     = 1;
    
    address internal _securityWalletAddress;     	 
    address internal _projectWalletAddress;
    address internal _liquidityWalletAddress;
    address internal _warpAddress = 0x3141592653589793238462643383279502884197;
    
    uint8   internal _swapNet;

    uint8   internal constant _decimals = 9;
    uint256 internal constant _tokensSupply = 1000000000 * 10**_decimals;

    uint256 internal _maxTokensPerTx = _tokensSupply.div(2 * 10 **2);  	            // 0.5% of  Tokens Supply
    //uint256 internal _numTokensToLiquidity =  _tokensSupply.div(2 * 10 **3);   	// 0.05% of Tokens Suplly
    uint256 internal _numTokensToLiquidity =   100000 * 10**_decimals; 	            // Provisório só para teste
    uint256 internal _maxWalletBalance = _tokensSupply.div(10 **2); 	            // 1% of the total supply
    
    uint256 public constant baseFactor = ~uint192(0);
    uint256 public _storeFactor = (baseFactor - (baseFactor % _tokensSupply))/_tokensSupply;

    
    uint256 internal _bonusFeeRef;
    uint256 internal _liquidityFeeRef;
    uint256 internal _fundsFeeRef;
    uint256 public   _bonusFee;
    uint256 public   _liquidityFee;
    uint256 public   _fundsFee;
    uint256 internal _sumOfFees;

    event NumTokensToLiquidityUpdated(uint256 _numTokensToLiquidity);
    event MaxTokensPerTxUpdated(uint256 _maxTokensPerTx);
    event SecurityWalletUpdated(address _securityWalletAddress);
    event ProjectWalletUpdated(address _projectWalletAddress);
    event ResidueWalletUpdated(address _liquidityWalletAddress);
    event AllFeesUpdated(uint256 _bonusFee, uint256 _liquidityFee, uint256 _fundsFee);


//   ======================================
//             Constructor Function             
//   ======================================

    constructor (uint256 bonusFee, uint256 liquidityFee, uint256 fundsFee, 
                 address securityWallet, address projectWallet, address liquidityWallet, 
                 uint8 swapNet)  {
                     
        _bonusFee         = bonusFee;
        _bonusFeeRef      = bonusFee;
        _liquidityFee     = liquidityFee;
        _liquidityFeeRef  = liquidityFee;
        _fundsFee         = fundsFee;
        _fundsFeeRef      = fundsFee;

        _securityWalletAddress  = securityWallet;          	 
        _projectWalletAddress   = projectWallet;
        _liquidityWalletAddress = liquidityWallet;
        _swapNet = swapNet;

    }

//   ======================================
//          ERC20 Functions (OVERRIDE)               
//   ======================================

    function decimals() public view virtual override returns (uint8) {
        return  _decimals;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return  _tokensSupply;
    }

//   ======================================
//            onlyOwner() Functions                    
//   ======================================

    function setAllFees(uint256 bonusFee, uint256 liquidityFee,uint256 fundsFee ) external onlyOwner() {
        require (bonusFee       >=  _bonusFeeRef.mul(9).div(10**2)         && 
                 bonusFee       <=  _bonusFeeRef.mul(11).div(10**2)        &&
                 liquidityFee   >=  _liquidityFeeRef.mul(9).div(10**2)     && 
                 liquidityFee   <=  _liquidityFeeRef.mul(11).div(10**2)    && 
                 fundsFee       >=  _fundsFeeRef.mul(9).div(10**2)         && 
                 fundsFee       <=  _fundsFeeRef.mul(11).div(10**2), 
                 "At most 10% variation permited");

        _bonusFee       = bonusFee;
        _liquidityFee   = liquidityFee;
        _fundsFee       = fundsFee;

        emit AllFeesUpdated(_bonusFee, _liquidityFee, _fundsFee);
    }
 
    function setMaxTokensPerTx(uint256 MaxTokensPerTx) public onlyOwner  {
        _maxTokensPerTx = MaxTokensPerTx.mul(10**_decimals);
        emit MaxTokensPerTxUpdated(_maxTokensPerTx);
    }

    function showParams() public view returns (uint256, uint256, uint256){
       return ( _maxTokensPerTx.div(10**_decimals),
                _numTokensToLiquidity.div(10**_decimals),
                _maxWalletBalance.div(10**_decimals) ); 
    }

     function setNumTokensToLiquidity(uint256 NumTokensToLiquidity) public onlyOwner {
        _numTokensToLiquidity = NumTokensToLiquidity.mul(10**_decimals);
        emit NumTokensToLiquidityUpdated(_numTokensToLiquidity);
    }

    function setSecurityWallet(address securityWalletAddress) external onlyOwner() {
        _securityWalletAddress = securityWalletAddress;
         emit SecurityWalletUpdated( _securityWalletAddress);
    }

    function setProjectWallet(address projectWalletAddress) external onlyOwner() {
        _projectWalletAddress = projectWalletAddress;
        emit ProjectWalletUpdated( _projectWalletAddress);
    }

    function setResidueWallet(address residueWalletAddress) external onlyOwner() {
        _liquidityWalletAddress = residueWalletAddress;
        emit ResidueWalletUpdated( _liquidityWalletAddress);
    }

}

//**********************************//
//     P R E S A L E A B L E 
//**********************************//

abstract contract Presaleable is Manageable {
    bool internal isSpecialOffering;
    function setSpecialOffering(bool value) external onlyManager {
        isSpecialOffering = value;
    }
}

//**********************************//
//      A D J U S T A B L E 
//**********************************//

abstract contract Adjustable  is Pausable, Manageable {
    bool public  allowSecurityPause = true;

  // Called by the Manager on emergency, triggers stopped state
    function initSecurityPause() external onlyManager {
      require(  allowSecurityPause, "Contingency pauses not allowed." );
      _pause();
    }

  // Called by the Manager on end of emergency, returns to normal state
   function finishSecurityPause() external onlyManager {
      require( paused(), "Contingency pause is not active.");
      _unpause();
    }

  // Called by the Owner to disable ability to begin or end an emergency stop
    function disableContingencyFeature() external onlyOwner {
      allowSecurityPause = false;
    }
}

//**********************************//
//    A  N  T  I  W  H  A  L  E
//**********************************//
abstract contract AntiWhale is Manageable {

    /**
     * NOTE: Currently this is just a placeholder. The parameters passed to this function are the
     *       sender's token balance and the transfer amount. An *antiwhale* mechanics can use these 
     *       values to adjust the fees total for each tx
     */
   
    function _getAntiwhaleFees(uint256, uint256) internal view returns (uint256){
        return 0;
    }
}

//**********************************//
//   A U T O L I Q U I D I T Y
//**********************************//

abstract contract AutoLiquidity is  Adjustable, BaseToken {

    using SafeMath for uint256;

    //  PancakeSwap Routers
 
    address private _BSC_Testnet           = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; 	// BSC Testnet for PancakeSwap
    address private _BSC_Mainnet           = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F; 	// BSC Mainnet for PancakeSwap
    address private _UniswapV2Router02     = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 	// Ethereum Mainnet, and the Ropsten, Rinkeby, Görli, and Kovan Testnets.


    IUniswapV2Router02 public _swapRouter;
    address public liquidityPair;
    
    bool public autoLiquidity = true;
    uint256 private _coinBalance;

    uint256 private inSwapAndLiquify;
    modifier nonReentrant {
        inSwapAndLiquify = _ENABLED;
        _;
        inSwapAndLiquify = _NOT_ENABLED;
    }
    
    event AutoLiquidityStatus(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 coinsReceived, uint256 tokensIntoLiquidity);    
    event RemainingBalanceTaken(address recipient, uint256 amountCoins);
    event LiquidityResidueTaken(uint256 residueCoins);
    event SwapRouterUpdated(address indexed router);

//   ======================================
//             Constructor Function             
//   ======================================  
    constructor () {

       address _swapRouterAddress = _BSC_Testnet;

       if (_swapNet == 88) { _swapRouterAddress = _BSC_Mainnet;}
       else 
       if (_swapNet == 99) { _swapRouterAddress = _UniswapV2Router02;}

       _setSwapRouter (_swapRouterAddress);

    }

//   ======================================
//     To receive Coins from swapRouter           
//   ======================================

    receive() external payable {}                      			

//   ======================================
//     Function _setSwapRouter            
//   ======================================

    function _setSwapRouter (address swapRouterAddress) private {

        IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouterAddress);    	//DEX Swap's Address
        
        // Create a Uniswap/Pancakeswap pair for this new Token

        liquidityPair = IUniswapV2Factory(swapRouter.factory()).createPair(address(this),swapRouter.WETH());

        // set the rest of the contract variables
        _swapRouter = swapRouter;

        emit SwapRouterUpdated(swapRouterAddress);
    }

//   ======================================
//     BEGIN Function  _tokenLiquify     
//   ======================================

    function _tokenLiquify(address sender) internal {    
        
        if ( inSwapAndLiquify == _NOT_ENABLED) {
            uint256 contractTokenBalance = balanceOf(address(this));

            if (contractTokenBalance >= _maxTokensPerTx)  { contractTokenBalance = _maxTokensPerTx;}
        
            bool overMinTokenBalance = ( contractTokenBalance >= _numTokensToLiquidity );

            // The condition "sender != liquidityPair" stops "swapAndLiquify" for all "buy" transactions, of course!!!

            if ( overMinTokenBalance && autoLiquidity &&  sender != liquidityPair ) { 
             swapAndLiquify ( contractTokenBalance );                                   //*** Add Liquidity  *** 
            }	

        }

    }

//   ======================================
//         BEGIN Function swapAndLiquify  
//   ======================================

    function swapAndLiquify(uint256 numTokensToLiquidity) private nonReentrant {

        // **** Split the 'numTokensToLiquidity' into halves  ***

        uint256 swapAmount = numTokensToLiquidity.div(2);
        uint256 liquidityAmount = numTokensToLiquidity.sub(swapAmount);

        // NOTE: Capture the contract's current Coins balance,  
        // thus we can know exactly how much Coins the swap 
        // creates, and not make recent events include any Coin that 
        // has been manually sent to the contract. 

        uint256 initialCoinBalance = address(this).balance;

        // Swap tokens for Coins
        swapTokensForCoins(swapAmount); 						 // First Transaction (Swap)

        // How much Coins did we just Swap into?
        uint256 swappedCoins = address(this).balance.sub(initialCoinBalance);

        // Add liquidity to DEX
          _addLiquidity(liquidityAmount, swappedCoins);
        
        emit SwapAndLiquify(swapAmount, swappedCoins, liquidityAmount);

         /**
         * NOTE:For every "swapAndLiquify" function call, a small amount of Coins remains in the contract. 
         * So we provide a method to withdraw automatically these funds, otherwise those coins would be locked in 
         * the contract forever.
         */

          uint256 residueCoins =  address(this).balance.sub(initialCoinBalance);   

          if (residueCoins > 0) _transferCoins(_liquidityWalletAddress, residueCoins); 		// Third Transaction (Residue)

          _coinBalance = address(this).balance;
          emit LiquidityResidueTaken(residueCoins);
    }

//   ========================================
//   BEGIN Function swapTokensForCoins  (01)   
//   ========================================

    function swapTokensForCoins(uint256 tokenAmount) private {

        // Generate the DEX pair path of token -> weth

        address[] memory path = new address[](2);  //An array of token addresses
        path[0] = address(this);
        path[1] = _swapRouter.WETH();

        _approve(address(this), address(_swapRouter), tokenAmount);

        // Make the Swap

         _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 				// Accept any amount of Coins
            path,
            address(this),  // Recipient of the ETH/BNB 
            block.timestamp
        );

    }

//   ======================================
//     BEGIN Function _addLiquidity  (02)    
//   ======================================

    function _addLiquidity(uint256 tokenAmount, uint256 coinAmount) private {

        // approve token transfer to cover all possible scenarios

        _approve(address(this), address(_swapRouter), tokenAmount);

        // add the liquidity
         _swapRouter.addLiquidityETH{value: coinAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityWalletAddress,                        // Recipient of the liquidity tokens.
            block.timestamp
        );

    }

//   ======================================
//     BEGIN Function _takeRemainingBalance    (03)    
//   ======================================

     function _transferCoins (address recipient, uint256 amountCoins) private {

       require(amountCoins > 0, "The Balance must be greater than 0");
       payable(recipient).transfer(amountCoins);

    }
 
//   ======================================
//          onlyManager() Functions                    
//   ======================================  

    function setSwapRouter(address router) external onlyManager() {
        _setSwapRouter(router);
    }

    function setAutoLiquidity(bool _enabled) public onlyManager {
        autoLiquidity = _enabled;
        emit AutoLiquidityStatus(_enabled);
    }

    function TransferRemainingBalance (address recipient) external onlyManager {

        require(recipient != address(0), "Cannot transfer coins to address(0)");
        require(_coinBalance > 0, "The Balance must be greater than 0");

        // prevent re-entrancy attacks
        uint256 amountToTransfer = _coinBalance;
        _coinBalance = 0;			// This balance will only be updated again the next time the  "swapAndLiquify" method is called. 

       _transferCoins(recipient, amountToTransfer);
       emit RemainingBalanceTaken(recipient, amountToTransfer);
    }

}

//**********************************//
//   T   A   X   A   B   L   E 
//**********************************//

abstract contract Taxable is Presaleable, AntiWhale, AutoLiquidity {

    using SafeMath for uint256;
    using Address  for address;
    
    struct AmountInfo {
           uint256 Inflow;
           uint256 Outflow;
    }
   
    struct BonusInfo {
           uint256 Balance;
           uint256 Inflow;
           uint256 Outflow;
           uint256 Store;
    }
     
    struct FeesInfo {
           uint256 Liquidity;
           uint256 Funds;
           uint256 Bonus;
           uint256 Project;
           uint256 Security;
    }
           
    mapping (address => uint256) internal _rawBalance;

    mapping (address => bool) internal _isUnrestrictedAccount;
    mapping (address => bool) internal _isBlacklistedAccount;
    mapping (address => bool) internal _isNonTaxable;
    mapping (address => bool) internal _isExcludedFromBonus;
    address[] private _noBonus;

    uint256 internal _totalBonusDue;

    event FeesTransfered(uint256 tokensLiquidity, uint256 tokensSecurityFunds,  uint256 tokensProjectFunds);

//   ======================================
//             Constructor Function             
//   ====================================== 
    constructor () {
        	
        _rawBalance[_msgSender()] = _tokensSupply;

        // Include Owner , Funds and Residue as Special Accounts

        _isUnrestrictedAccount[owner()] = true;
        _isUnrestrictedAccount[_securityWalletAddress] = true;
        _isUnrestrictedAccount[_projectWalletAddress] = true;
        _isUnrestrictedAccount[_liquidityWalletAddress] = true;

        // Exclude Owner , Funds and this Contract from fee

        _isNonTaxable[owner()] = true;
        _isNonTaxable[address(this)] = true;  
        _isNonTaxable[_securityWalletAddress] = true;
        _isNonTaxable[_projectWalletAddress] = true;
        _isNonTaxable[_liquidityWalletAddress] = true;

        // Exclude the Owner and this Contract from Bonus
        
        _excludeFromBonus(owner());
        _excludeFromBonus(address(this)); 
        _excludeFromBonus(_liquidityWalletAddress);
        _excludeFromBonus(liquidityPair);            
        
        emit Transfer(address(0), _msgSender(), _tokensSupply);
    }
 
//  ==============================
//        IERC20 Functions (OVERRIDE)              
//   ======================================

    function balanceOf(address account) public view override returns (uint256) {
           return _rawBalance[account].add(_getBonus(account));
    }

 //   ======================================
//          BEGIN Function _transfer   
//   ======================================

    function _transfer( address sender, address recipient, uint256 amount ) internal override whenNotPaused {

        require(sender != address(0), "Cannot transfer from  address(0)");
        require(recipient != address(0), "Cannot transfer to address(0)");
        require(sender != address(_warpAddress), "Cannot transfer from Warp address");
        require(amount > 0, "Amount must be greater than zero");
//      require(balanceOf(sender) >= amount, "Insufficient balance to transfer"); 
    
        if (!_isUnrestrictedAccount[sender]  && !_isUnrestrictedAccount[recipient]) {  
            require(amount <= _maxTokensPerTx, "Transfer exceeds the maximum limit."); 
        }

        if (  !_isUnrestrictedAccount[sender] && 
              !_isUnrestrictedAccount[recipient] &&
              recipient != liquidityPair )  {

               uint256  storedTokens = balanceOf(recipient);
               require( storedTokens + amount <= _maxWalletBalance, "Wallet balance exceed the limit");
        }      

        //  Indicates that all fees should be deducted from transfer

        uint256 applyFee = _ENABLED;
        
       // If any account belongs to "_isNonTaxable" then no fee will be applied. 

        if (_isNonTaxable[sender] || _isNonTaxable[recipient])  applyFee = _NOT_ENABLED; 
        
        _tokenLiquify(sender);
        _tokenTransfer(sender, recipient, amount, applyFee);   

      }

//   ======================================
//      BEGIN Function _tokenTransfer                   
//   ======================================

//   This Function is responsible for taking all fee, if 'applyFee' is _Enabled

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, uint256 applyFee) private {
        
        BonusInfo  memory bonus;
        FeesInfo   memory fees;
        AmountInfo memory amount;

        fees.Liquidity  = tAmount.mul(_liquidityFee).mul(applyFee).div(10**2); 
        fees.Funds      = tAmount.mul(_fundsFee).mul(applyFee).div(10**2);
        fees.Bonus      = tAmount.mul(_bonusFee).mul(applyFee).div(10**2);                                
        
        uint256 transferAmount = tAmount.sub(fees.Liquidity).sub(fees.Funds).sub(fees.Bonus);

        // All calculations must be done before updating any balance. 

        (bonus.Inflow, amount.Inflow) = _shareAmount(transferAmount);

        bonus.Balance = _getBonus(sender);
        if (bonus.Balance > 0)
            bonus.Outflow = bonus.Balance.mul(tAmount).div( _rawBalance[sender].add(bonus.Balance) );
        else
            bonus.Outflow = 0;

        amount.Outflow = tAmount.sub(bonus.Outflow);

       // Update of sender and recipient balances and their bonus shares 

        bonus.Store = bonus.Outflow.mul(_storeFactor);
        _rawBalance[sender] = _rawBalance[sender].sub(bonus.Store);
        _totalBonusDue =  _totalBonusDue.sub(bonus.Store); 

        bonus.Store = bonus.Inflow.mul(_storeFactor);   
        _rawBalance[recipient] =  _rawBalance[recipient].add(bonus.Store);
        _totalBonusDue =  _totalBonusDue.add(bonus.Store); 

        emit Transfer(sender, recipient, tAmount);

        // Collect all Fees and Bonus    

        if (applyFee == _ENABLED) {
        
            fees.Security   = fees.Funds.div(2);
            fees.Project    = fees.Funds.sub(fees.Security);

            _rawBalance[address(this)]          = _rawBalance[address(this)].add(fees.Liquidity); 
            _rawBalance[_securityWalletAddress] = _rawBalance[_securityWalletAddress].add(fees.Security);
            _rawBalance[_projectWalletAddress]  = _rawBalance[_projectWalletAddress].add(fees.Project);

            bonus.Store    = fees.Bonus.mul(_storeFactor);
            _totalBonusDue =  _totalBonusDue.add(bonus.Store);
  
            emit FeesTransfered(fees.Liquidity, fees.Security, fees.Project);
        }

    }

//   ======================================
//               RFI Functions                  
//   ======================================

    /**
     *  NOTE: The "_calcBonus" and "_getFactorRFI" functions help to redistribute the specified 
     *        amount of Bonus among the current holders via an special algorithm that eliminates 
     *        the need for interaction with all account holders. 
     */
    
    function _shareAmount (uint256 tAmount) private view returns (uint256, uint256) {
        if (_totalBonusDue == 0) return (0, tAmount);
        uint256 _bonusStock   = _totalBonusDue.div(_storeFactor);
        uint256 _bonusAmount  = tAmount.mul(_bonusStock).div(_bonusBalances().add(_bonusStock));
        uint256 _rawAmount    = tAmount.sub(_bonusAmount); 
        return (_bonusAmount, _rawAmount);
    }

    function _getBonus (address account) private view returns (uint256) {
        if ( _isExcludedFromBonus[account] || _totalBonusDue == 0 || _rawBalance[account] == 0 ){
            return 0;
        } else {
            uint256 shareBonus = _totalBonusDue.mul(_rawBalance[account]).div(_bonusBalances());
            return  shareBonus.div(_storeFactor);
        }
    }

    function _bonusBalances () private view returns (uint256) {

        uint256 expurgedBalance = 0;
        for (uint256 i=0; i < _noBonus.length; i++){
            expurgedBalance = expurgedBalance.add(_rawBalance[_noBonus[i]]);
        }
        return  _tokensSupply.sub(expurgedBalance).sub(_totalBonusDue.div(_storeFactor));                 
    }

    function isNonTaxable(address account) public view returns(bool) {
        return _isNonTaxable[account];
    }

    function isExcludedFromBonus(address account) public view returns (bool) {
        return _isExcludedFromBonus[account];
    }

    function AccruedBonus() public view returns (uint256) {
        return _totalBonusDue.div(_storeFactor * 10**_decimals);
    }

    function _excludeFromBonus(address account) internal {
         uint256 _bonus = _getBonus(account); 
        _rawBalance[account] = _rawBalance[account].add(_bonus);
        _totalBonusDue = _totalBonusDue.sub(_bonus);
        _isExcludedFromBonus[account] = true;
        _noBonus.push(account);
    }

//   ======================================
//            onlyOwner() Functions                    
//   ======================================

   /**
    * For the holder rewards to be distributed properly, contract owner should follow these steps after the contract deployment:
    *  1 - Exclude the token contract address  (constructor)
    *  2 - Exclude the contract owner address (constructor)
    *  3 - Exclude the pool address where the initial liquidity is provided (More Studies)
    *  4 - Provide the initial liquidity to an AMM-exchange
    */

    function excludeFromBonus(address account) public onlyOwner() {
        require(!_isExcludedFromBonus[account], "Account is already non-bonus");
        _excludeFromBonus(account);
    }
    
    function includeInBonus(address account) public onlyOwner() {
        require(_isExcludedFromBonus[account], "Account is not non-bonus");
        (uint256 _adjustedBonus, uint256 _adjustedBalance) = _shareAmount(_rawBalance[account]);
 
        for (uint256 i = 0; i < _noBonus.length; i++) {
            if (_noBonus[i] == account) {
                _noBonus[i] = _noBonus[_noBonus.length - 1];
                _isExcludedFromBonus[account] = false;
                _rawBalance[account] =_adjustedBalance;
                _totalBonusDue = _totalBonusDue.add(_adjustedBonus.mul(_storeFactor));
               _noBonus.pop();
                break;
            }
        }
    }

    function setTaxable(address account) public onlyOwner {
        _isNonTaxable[account] = true;
    }
    
    function setNonTaxable(address account) public onlyOwner {
        _isNonTaxable[account] = false;
    }

//   ======================================
//          Ownable Functions  (OVERRIDE)             
//   ======================================

    function transferOwnership(address newOwner) public virtual override onlyOwner {
         require(newOwner != address(0), "Owner cannot be address(0)");

         address oldOwner = owner();
        _transferOwnership(newOwner);

        _isUnrestrictedAccount[oldOwner] = false;
        _isNonTaxable[oldOwner] = false;
         includeInBonus(oldOwner);
        _isUnrestrictedAccount[newOwner] = true;
        _isNonTaxable[newOwner] = true;
        _excludeFromBonus(newOwner);
    }
 
}
 
//**********************************//
//     S Y M P L E X I A  CONTRACT
//**********************************//
contract SymplexiaToken is  Taxable {

    using SafeMath for uint256;       

 
  //   constructor (string memory tokenName, string memory tokenSymbol, 
  //                uint256 bonusFee, uint256 liquidityFee, uint256 fundsFee, 
  //                address securityWallet, address projectWallet, 
  //                uint8 swapNet) { }
  //

    constructor () ERC20 ("DEBUG58", "DBG58") BaseToken (5, 5, 5, 
                                     0x9dc83Ab4f953B78ddcEEd5f7c1c879cd890B43Ac, 
                                     0xB2019936b9ea80e3fAC12007597495794C9b749d, 
		                             0xbB53A39B7FA4c00f576a729aa82c4D43D57b5924,
                                     99) {}


}