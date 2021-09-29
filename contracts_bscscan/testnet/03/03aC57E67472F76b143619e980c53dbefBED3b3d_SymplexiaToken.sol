/**
 *Submitted for verification at BscScan.com on 2021-03-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "ERC20.sol";
import "Ownable.sol";
import "Context.sol";
import "Address.sol";
import "SafeMath.sol";
import "Manageable.sol";

//    Interfaces   

import "IERC20.sol";
import "IERC20Metadata.sol";
import "IUniswapV2Router01.sol";
import "IUniswapV2Router02.sol";
import "IUniswapV2Factory.sol";
import "IUniswapV2Pair.sol";

//**********************************//
//             BaseToken 
//**********************************//

abstract contract BaseToken  is ERC20, Ownable {
    
    using SafeMath for uint256;

    address private _previousOwner;
    uint256 private _lockTime;
    
    address internal _securityWalletAddress;     	 
    address internal _projectWalletAddress;
    address internal _residueWalletAddress;
    uint8   internal _swapNet;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant _totalSupply = 100000000 * 10**9;
    uint256 internal _reflectedSupply = (MAX - (MAX % _totalSupply));

    uint8   internal constant _decimals = 9;

    uint256 internal _maxTokensPerTx = 500000 * 10**9;
    uint256 internal _numTokensToLiquidity = 50000 * 10**9;   

    uint256 public _bonusFee;
    uint256 public _liquidityFee;
    uint256 public _fundsFee;
    uint256 public _totalFees;

    event NumTokensToLiquidityUpdated(uint256 _numTokensToLiquidity);
    event MaxTokensPerTxUpdated(uint256 _maxTokensPerTx);

//   ======================================
//             Constructor Function             
//   ======================================

    constructor (string memory tokenName, string memory tokenSymbol, 
                 uint256 bonusFee, uint256 liquidityFee, uint256 fundsFee, 
                 address securityWallet, address projectWallet, 
                 uint8 swapNet)  ERC20(tokenName, tokenSymbol)    {
                     
        _bonusFee    = bonusFee.div(10**2);
        _liquidityFee = liquidityFee.div(10**2);
        _fundsFee     = fundsFee.div(10**2);
        _totalFees     = _bonusFee + _liquidityFee +_fundsFee ;

        _securityWalletAddress = securityWallet;          	 
        _projectWalletAddress  = projectWallet;
        _residueWalletAddress = projectWallet;
        _swapNet = swapNet;

    }

//   ======================================
//          ERC20 Overriden Functions              
//   ======================================

    function decimals() public view virtual override returns (uint8) {
        return  _decimals;
    }
    
//   ======================================
//      Ownership Adjustments Functions           
//   ======================================

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = owner();
        _lockTime = block.timestamp + time;
         renounceOwnership();
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "Only the previous Owner can resume onwership");
        require(block.timestamp > _lockTime , "The contract is still time locked");
       _transferOwnership(_previousOwner);
    }

//   ======================================
//            onlyOwner() Functions                    
//   ======================================

    function setBonusFee(uint256 bonusFee) external onlyOwner() {
        _bonusFee = bonusFee.div(10**2);
        _totalFees = _bonusFee + _liquidityFee +_fundsFee ;
    }
    
    function setLiquidityFee(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee.div(10**2);
        _totalFees = _bonusFee + _liquidityFee +_fundsFee ;
    }

    function setFundsFee(uint256 fundsFee) external onlyOwner() {
        _fundsFee = fundsFee.div(10**2);
        _totalFees = _bonusFee + _liquidityFee +_fundsFee ;
    }   

    function updateMaxTokensPerTx(uint256 newMaxTokensPerTx) public onlyOwner  {
        _maxTokensPerTx = newMaxTokensPerTx;
        emit MaxTokensPerTxUpdated(_maxTokensPerTx);
    }

     function updateNumTokensToLiquidity(uint128 newNumTokensToLiquidity) public onlyOwner {
        _numTokensToLiquidity = newNumTokensToLiquidity;
        emit NumTokensToLiquidityUpdated(_numTokensToLiquidity);
    }

    function _setFundsWallet(address securityWalletAddress, address projectWalletAddress) external onlyOwner() {
        _securityWalletAddress = securityWalletAddress;
        _projectWalletAddress = projectWalletAddress;
    }

}

//**********************************//
//      Base  P R E S A L E
//**********************************//

abstract contract BasePresale is Manageable {
    bool internal isInPresale;
    function setPreseableEnabled(bool value) external onlyManager {
        isInPresale = value;
    }
}

//**********************************//
//        Base  R   F   I 
//**********************************//

abstract contract BaseRFI is BaseToken, BasePresale {

    using SafeMath for uint256;
    using Address for address;
     
    mapping (address => uint256) internal _reflectedBalances;
    mapping (address => uint256) internal _rawBalances;


    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcludedFromBonus;
    address[] private _noBonus;

    uint256 internal _tBonusBalance;
  
    event FeesTransfered(uint256 tokensLiquidity, uint256 tokensSecurityFunds,  uint256 tokensProjectFunds);

//   ======================================
//             Constructor Function             
//   ====================================== 
    constructor () {
        	
        _reflectedBalances[_msgSender()] = _reflectedSupply;

        // Exclude Owner , Funds and this Contract from fee

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_securityWalletAddress] = true;
        _isExcludedFromFee[_projectWalletAddress] = true;

        // Exclude the Owner and this Contract from Bonus
        
        _excludeFromBonus(owner());
        _excludeFromBonus(address(this));
        _excludeFromBonus(_securityWalletAddress);
        _excludeFromBonus(_projectWalletAddress);
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
 
//   ======================================
//        IERC20 Functions (OVERRIDE)              
//   ======================================

    function _balanceRFI(address account) internal view returns (uint256) {
        if (_isExcludedFromBonus[account]) return _rawBalances[account];
        return tokenFromReflection(_reflectedBalances[account]);
    }
 
//   ======================================
//          BEGIN Function _transferRFI   
//   ======================================

    function _transferRFI( address sender, address recipient, uint256 amount ) internal {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
      
        //     (** ESTUDAR -  Incluir contas de fundos**)

        if (sender != owner() && recipient != owner())   
            require(amount <= _maxTokensPerTx, "Transfer amount exceeds the maximum limit.");       

        //  Indicates that all fees should be deducted from transfer

        bool applyFee = true;
        
       // If any account belongs to _isExcludedFromFee then no fee will be applied. 

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])  {    applyFee = false;    }
        
        uint256 contractTokenBalance = _balanceRFI(address(this));

        _tokenLiquify(sender, contractTokenBalance);
        _tokenTransfer(sender, recipient, amount, applyFee);    	 
    
      }
//   ======================================
//      BEGIN Function _tokenTransfer                   
//   ======================================

//   This Function is responsible for taking all fee, if applyFee is true

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool applyFee) private {
        
     
         (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 currentRate) = _getValues(tAmount, applyFee);
       
         //   Sender's and Recipient's reflected balances must be always updated regardless of
         //   whether they are excluded from Bonus or not.
   
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rTransferAmount);

         // Update the raw balances for excluded accounts

        if (_isExcludedFromBonus[sender]) { _rawBalances[sender] = _rawBalances[sender].sub(tAmount); }
        if (_isExcludedFromBonus[recipient] ){ _rawBalances[recipient] = _rawBalances[recipient].add(tTransferAmount); }
       
        // Take all fees

        if (applyFee) {  
            _collectFees(tAmount, currentRate); 
            _shareBonus(tAmount, currentRate);
       }

        emit Transfer(sender, recipient, tTransferAmount);

    }

//   ======================================
//      Transfer Support Functions               
//   ======================================

    function _collectFees(uint256 tAmount, uint256 currentRate) private { 

         uint256 tLiquidityFee = tAmount.mul(_liquidityFee); 
         uint256 tFundsFee = tAmount.mul(_fundsFee); 
         uint256 tSecurityFee = tFundsFee.div(2);
         uint256 tProjectFee = tFundsFee.sub(tSecurityFee);

       _sendAssets(address(this), tLiquidityFee, currentRate); 
       _sendAssets(_securityWalletAddress, tSecurityFee, currentRate); 
       _sendAssets(_projectWalletAddress, tProjectFee, currentRate) ;

        emit FeesTransfered(tLiquidityFee, tSecurityFee, tProjectFee);
    }

    function _sendAssets(address recipient, uint256 tAssets, uint256 currentRate) private {

        uint256 rAssets = tAssets.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAssets);

        if(_isExcludedFromBonus[recipient])  _rawBalances[recipient] = _rawBalances[recipient].add(tAssets);
    
    }

//   ======================================
//    Hook Function  _tokenLiquify             
//   ======================================

   function _tokenLiquify(address sender, uint256 contractTokenBalance ) internal virtual;
  
//   ======================================
//               RFI Functions                  
//   ======================================

    /**
     * NOTE: The function "_shareBonus" redistributes the specified amount of Bonus among the current holders via 
     * the reflect.finance algorithm, i.e. by updating the _reflectedSupply (_rSupply) which ultimately adjusts the
     * current rate used by `tokenFromReflection` and, in turn, the value returns from `balanceOf`, thus 
     * allows RFI to share the Bonus fee without having to iterate through all holders. 
     */

    function _shareBonus(uint256 tAmount, uint256 currentRate) private {
          uint256 tBonus = tAmount.mul(_bonusFee);
          uint256 rBonus = tBonus.mul(currentRate);
        _reflectedSupply = _reflectedSupply.sub(rBonus);
        _tBonusBalance = _tBonusBalance.add(tBonus);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = _totalSupply;      
        for (uint256 i = 0; i < _noBonus.length; i++) {
            if (_reflectedBalances[_noBonus[i]] > rSupply || _rawBalances[_noBonus[i]] > tSupply) return (_reflectedSupply, _totalSupply);
            rSupply = rSupply.sub(_reflectedBalances[_noBonus[i]]);
            tSupply = tSupply.sub(_rawBalances[_noBonus[i]]);
        }
        if (rSupply < _reflectedSupply.div(_totalSupply)) return (_reflectedSupply, _totalSupply);
        return (rSupply, tSupply);
    }

    function _getValues(uint256 tAmount, bool applyFee) internal view returns (uint256, uint256, uint256, uint256) {

        uint256 currentRate = _getRate(); 
           
        uint256 tTotalFees = 0;
        if (applyFee) tTotalFees = tAmount.mul(_totalFees);

        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);
        
        return (rAmount, rTransferAmount, tTransferAmount, currentRate);
    }


    /**
     * Calculates and returns the amount of tokens corresponding to the given reflected amount.
     */

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _reflectedSupply, "Amount must be less than Total Reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    /**
     * @dev Calculates and returns the reflected amount for the given amount of Tokens with or without 
     * with or without the transfer fees (deductTransferFee true/false)
     */

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _totalSupply, "Amount must be less than Total Supply");

        (,uint256 rTransferAmount,,) = _getValues(tAmount, deductTransferFee);
         return rTransferAmount;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromBonus(address account) public view returns (bool) {
        return _isExcludedFromBonus[account];
    }

    function BonusBalance() public view returns (uint256) {
        return _tBonusBalance;
    }

//   ======================================
//            onlyOwner() Functions                    
//   ======================================

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
  
    function excludeFromBonus(address account) public onlyOwner() {
        require(!_isExcludedFromBonus[account], "Account is already no-bonus");
        _excludeFromBonus(account);
    }
    
    function _excludeFromBonus(address account) internal {
        if(_reflectedBalances[account] > 0) {
            _rawBalances[account] = tokenFromReflection(_reflectedBalances[account]);
        }
        _isExcludedFromBonus[account] = true;
        _noBonus.push(account);
    }

    function includeInBonus(address account) external onlyOwner() {
        require(_isExcludedFromBonus[account], "Account is not no-bonus");
        for (uint256 i = 0; i < _noBonus.length; i++) {
            if (_noBonus[i] == account) {
                _noBonus[i] = _noBonus[_noBonus.length - 1];
                _rawBalances[account] = 0;
                _isExcludedFromBonus[account] = false;
                _noBonus.pop();
                break;
            }
        }
    }
 
}
    
//**********************************//
//        BaseLiquidity
//**********************************//

abstract contract BaseLiquidity is BaseToken, Manageable {

    using SafeMath for uint256;

    //  PancakeSwap Routers
    address private _mainnetRouterAddress = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    address private _testnetRouterAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    IUniswapV2Router02 public immutable swapRouter;
    address public immutable swapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 private _CoinBalance;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 coinsReceived, uint256 tokensIntoLiquidity);    
    event ResidueCoinsTaken(uint256 residueCoins);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


//   ======================================
//             Constructor Function             
//   ======================================  
    constructor () {

       address _swapRouterAddress = _testnetRouterAddress;
       
       if (_swapNet == 99) { _swapRouterAddress = _mainnetRouterAddress;}

       
        IUniswapV2Router02 _swapRouter = IUniswapV2Router02(_swapRouterAddress);    	//DEX Swap's Address
        
        // Create a uniswap pair for this new Token

        swapPair = IUniswapV2Factory(_swapRouter.factory())
            .createPair(address(this),_swapRouter.WETH());

        // set the rest of the contract variables
         swapRouter =_swapRouter;

    }

//   ======================================
//         To receive Coins from swapRouter           
//   ======================================

    receive() external payable {}                      			

//   ======================================
//     BEGIN Function  _initLiquify     
//   ======================================

      function _initLiquify( address sender, uint256 contractTokenBalance ) internal {    
        
      if (contractTokenBalance >= _maxTokensPerTx)  { contractTokenBalance = _maxTokensPerTx;}
        
        bool overMinTokenBalance = ( contractTokenBalance >= _numTokensToLiquidity );

            // Check if the "( sender != swapPair)" is necessary because that basically
            // stops swap and liquify for all "buy" transactions   *** ESTUDAR  **

        if ( overMinTokenBalance &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            sender != swapPair ) 
           {
              contractTokenBalance = _numTokensToLiquidity;
              swapAndLiquify(contractTokenBalance);		 				//*** Add Liquidity  ***
           }

     }

//   ======================================
//         BEGIN Function swapAndLiquify  
//   ======================================

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        // **** Split the Contract Balance into halves  ***

        uint256 swapAmount = contractTokenBalance.div(2);
        uint256 liquidityAmount = contractTokenBalance.sub(swapAmount);

       // NOTE: Capture the contract's current Coins balance,  
       // thus we can know exactly how much Coins the swap 
       // creates, and not make recent events include any Coin that 
       // has been manually sent to the contract. 

        uint256 initialCoinBalance = address(this).balance;

        // Swap tokens for Coins
        swapTokensForCoins(swapAmount); 						                // First Transaction (Swap)

        // How much Coins did we just Swap into?
        uint256 swappedCoins = address(this).balance.sub(initialCoinBalance);

        // Add liquidity to DEX
        _addLiquidity(liquidityAmount, swappedCoins);					       // Second Transaction (Liquidity)
        
         emit SwapAndLiquify(swapAmount, swappedCoins, liquidityAmount);

         /**
         * NOTE:For every "swapAndLiquify" function call, a small amount of Coins remains in the contract. 
         * So we must have a method to withdraw these funds, otherwise those coins will be locked in 
         * the contract forever.
         */

          _CoinBalance = address(this).balance;                     

          uint256 residueCoins =  _CoinBalance.sub(initialCoinBalance);   

         if (residueCoins > 0) _takeResidue(_residueWalletAddress, residueCoins); 		// Third Transaction (Residue)
    }

//   ========================================
//   BEGIN Function swapTokensForCoins  (01)   
//   ========================================

    function swapTokensForCoins(uint256 tokenAmount) private {

        // Generate the DEX pair path of token -> weth

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        _approve(address(this), address(swapRouter), tokenAmount);

        // Make the swap

         swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 				// accept any amount of Coins
            path,
            address(this),
            block.timestamp
        );

    }

//   ======================================
//     BEGIN Function _addLiquidity  (02)    
//   ======================================

    function _addLiquidity(uint256 tokenAmount, uint256 coinAmount) private {

        // approve token transfer to cover all possible scenarios

        _approve(address(this), address(swapRouter), tokenAmount);

        // add the liquidity
         swapRouter.addLiquidityETH{value: coinAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

    }

//   ======================================
//     BEGIN Function takeResidue    (03)    
//   ======================================

    function _takeResidue(address recipient, uint256 amountCoins) private {

       require(amountCoins > 0, "The Coin balance must be greater than 0");
 
       payable(recipient).transfer(amountCoins);

       emit ResidueCoinsTaken(amountCoins);
    }

 
//   ======================================
//          onlyManager() Functions                    
//   ======================================  

   function setSwapAndLiquifyEnabled(bool _enabled) public onlyManager {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }


   function residueTransfer(address recipient) external onlyManager {

        require(recipient != address(0), "Cannot transfer the residue Coins to the zero address");
        require(_CoinBalance > 0, "The Coin Balance must be greater than 0");

        // prevent re-entrancy attacks
        uint256 amountToTransfer = _CoinBalance;
        _CoinBalance = 0;

       _takeResidue(recipient, amountToTransfer);
    }

}

//**********************************//
//    A  N  T  I  W  H  A  L  E
//**********************************//
abstract contract AntiWhale is BaseToken {

    /**
     * NOTE: Currently this is just a placeholder. The parameters passed to this function are the
     *      sender's token balance and the transfer amount. An *antiwhale* mechanics can use these 
     *      values to adjust the fees total for each tx
     */
   
    function _getAntiwhaleFees(uint256, uint256) internal view returns (uint256){
        return 0;
    }
}

//**********************************//
//     S Y M P L E X I A  CONTRACT
//**********************************//


   
contract SymplexiaToken is  AntiWhale,  BaseLiquidity,  BaseRFI {

    using SafeMath for uint256;       

 
  //   constructor (string memory tokenName, string memory tokenSymbol, 
  //                uint256 bonusFee, uint256 liquidityFee, uint256 fundsFee, 
  //                address securityWallet, address projectWallet, 
  //                uint8 swapNet) { }
  //
  
    constructor () BaseToken ( "DEBUG15", "DBG15", 5, 5, 5, 
                                     0x5194A443a4Ec5478821e16Fd7B009FDAa847e837, 
                                     0x83Fd4F9256e02D2029B4f3E0E985fE83a01E1B8b, 0 ) {}

    function _tokenLiquify(address sender, uint256 contractTokenBalance ) internal override {
              _initLiquify(sender, contractTokenBalance);                   
    }

    function balanceOf(address account) public view override returns (uint256) {
            return _balanceRFI(account);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferRFI(_msgSender(), recipient, amount);
        return true;
    }

}