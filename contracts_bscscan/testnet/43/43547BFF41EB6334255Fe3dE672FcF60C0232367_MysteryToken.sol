// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./SafeMath.sol";


//TODO: Revisar las interfaces factory y router.


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    //function feeTo() external view returns (address);
    //function feeToSetter() external view returns (address);

    //function getPair(address tokenA, address tokenB) external view returns (address pair);
    //function allPairs(uint) external view returns (address pair);
    //function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    //function setFeeTo(address) external;
    //function setFeeToSetter(address) external;
}


interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}






contract MysteryToken is Ownable {

  using SafeMath for uint256;

  uint8 private _decimals;
  string private _symbol;
  string private _name;

  mapping (address => uint256) private _rOwned;
  mapping (address => uint256) private _tOwned;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => bool) private _isExcludedFromFee;

  mapping (address => bool) private _isExcluded; //se utiliza en balanceOf()
  address[] private _excluded; //se utiliza en _getCurrentSupply()

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal;
  uint256 private _rTotal;
  uint256 private _tFeeTotal;

  uint256 private _taxFee = 1;
  uint256 private _previousTaxFee = _taxFee;

  uint256 private _liquidityFee = 2;
  uint256 private _previousLiquidityFee = _liquidityFee;
  uint256 private _numTokensSellToAddToLiquidity = 50; //TODO: minimo acumulado para añadir a liquidez
  bool private _inSwapAndLiquify;
  bool private _swapAndLiquifyEnabled = false;

  uint256 public _burnFee = 1;
  uint256 private _previousBurnFee = _burnFee;
  //0x000000000000000000000000000000000000dEaD
  address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

  uint256 private _marketingFee = 1;
  uint256 private _previousMarketingFee = _marketingFee;
  //address payable private _marketingWallet = payable(0x6E2b272C312B237aD936060d6c43278C45cCA592);
  address private _marketingWallet = 0x6E2b272C312B237aD936060d6c43278C45cCA592;

  mapping (address => bool) private _isTxLimitExempt;

  uint256 private _maxTxAmount;
  uint256 private _maxWalletToken;

  IPancakeRouter02 public immutable pancakeswapV2Router;
  address public  pancakeswapV2Pair;


  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );

  modifier lockTheSwap {
    _inSwapAndLiquify = true;
    _;
    _inSwapAndLiquify = false;
  }


  constructor(string memory token_name, string memory short_symbol, uint8 token_decimals, uint256 token_totalSupply){
    _name = token_name;
    _symbol = short_symbol;
    _decimals = token_decimals;
    _tTotal = token_totalSupply;
    _rTotal = (MAX - (MAX % _tTotal));

    //max tx amount 1.5%
    _maxTxAmount = _tTotal.mul(3).div(2).div(100);
    _isTxLimitExempt[_msgSender()] = true;

    //max wallet token 3%
    _maxWalletToken = _tTotal.mul(3).div(100);


    //falta añdir la inicializacion del router y del pair.
    IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);//router testnet
    
    //Create a uniswap pair for this new token
    pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
      .createPair(address(this), _pancakeswapV2Router.WETH());

    pancakeswapV2Router = _pancakeswapV2Router;

    // Add all the tokens created to the creator of the token
    _rOwned[_msgSender()] = _rTotal;

    //exclude owner and this contract from fee
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;

    // Emit an Transfer event to notify the blockchain that an Transfer has occured
    emit Transfer(address(0), _msgSender(), _tTotal);
  }


  /*BEP20 interface
  functions: totalSupply, decimals, symbol, name, getOwner, balanceOf, transfer, allowance, approve, transferFrom
  events: Transfer, Approval
  */

  //Transfer event is a event that notify the blockchain that a transfer of assets has taken place
  event Transfer(address indexed from, address indexed to, uint256 value);

  //Approval is emitted when a new Spender is approved to spend Tokens on the Owners account
  event Approval(address indexed owner, address indexed spender, uint256 value);

  //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}

  function totalSupply() external view returns (uint256) {
    return _tTotal;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function getOwner() external view returns (address) {
    return owner();
  }

  function balanceOf(address account) public view returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return _tokenFromReflection(_rOwned[account]);
  }

  function allowance(address owner, address spender) external view returns(uint256) {
    return _allowances[owner][spender];
  }

  function increaseAllowance(address spender, uint256 amount) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(amount));
    return true;
  }

  function decreaseAllowance(address spender, uint256 amount) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(amount));
    return true;
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "MysteryToken: approve cannot be done from zero address");
    require(spender != address(0), "MysteryToken: approve cannot be to zero address");
    // Set the allowance of the spender address at the Owner mapping over accounts to the amount
    _allowances[owner][spender] = amount;

    emit Approval(owner,spender,amount);
  }

  // function burn(address account, uint256 amount) public onlyOwner returns(bool) {
  //   _burn(account, amount);
  //   return true;
  // }

  // function _burn(address account, uint256 amount) internal {
  //   require(account != address(0), "MysteryToken: cannot burn from zero address");

  //   // Remove the amount from the account balance
  //   _balances[account] = _balances[account].sub(amount, "MysteryToken: burn amount exceeds balance");
  //   // Decrease totalSupply
  //   _totalSupply = _totalSupply.sub(amount);
  //   // Emit event, use zero address as reciever
  //   emit Transfer(account, address(0), amount);
  // }


  //TODO: FUNCION _transfer EN DESARROLLO y pendiente de revisar.

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(address spender, address recipient, uint256 amount) external returns(bool){
    // Make sure spender is allowed the amount
    require(_allowances[spender][_msgSender()] >= amount, "MysteryToken: You cannot spend that much on this account");
    // Transfer first
    _transfer(spender, recipient, amount);
    // Reduce current allowance so a user cannot respend
    _approve(spender, _msgSender(), _allowances[spender][_msgSender()].sub(amount, "MysteryToken: transfer amount exceeds allowance"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "MysteryToken: transfer from zero address");
    require(recipient != address(0), "MysteryToken: transfer to zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    //require(_balances[sender] >= amount, "MysteryToken: cant transfer more than your account holds");


    uint256 contractTokenBalance = balanceOf(address(this));

    //mirar antes si contractTokenBalance es mayor que maxTxAmount para ajustar.

    bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
      if (
          overMinTokenBalance &&
          !_inSwapAndLiquify &&
          sender != pancakeswapV2Pair &&
          _swapAndLiquifyEnabled
      ) {
          contractTokenBalance = _numTokensSellToAddToLiquidity;
          //add liquidity
          swapAndLiquify(contractTokenBalance);
      }




    bool takeFee = true;
    //if any account belongs to _isExcludedFromFee account then remove the fee
    if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
      takeFee = false;
    }

    _tokenTransfer(sender,recipient,amount,takeFee);

    emit Transfer(sender, recipient, amount);
  }


  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    // split the contract balance into halves
    uint256 half = contractTokenBalance.div(2);
    uint256 otherHalf = contractTokenBalance.sub(half);

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance.sub(initialBalance);

    // add liquidity to pancake
    addLiquidity(otherHalf, newBalance);
    
    emit SwapAndLiquify(half, newBalance, otherHalf);
  }


  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeswapV2Router.WETH();

    _approve(address(this), address(pancakeswapV2Router), tokenAmount);

    // make the swap
    pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  //TODO: cuando añada liquidez comprobar que rOwned y tOwned del contrato se reduce.
  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(pancakeswapV2Router), tokenAmount);

    // add the liquidity
    pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner(),
      block.timestamp
    );
  }


  function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
    if(!takeFee)
      removeAllFee();

    uint256 burnAmount = _calculateBurnFee(amount);
    uint256 marketingAmount = _calculateMarketingFee(amount);

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount.sub(burnAmount).sub(marketingAmount));
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, amount.sub(burnAmount).sub(marketingAmount));
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, amount.sub(burnAmount).sub(marketingAmount));
    } else {
      _transferStandard(sender, recipient, amount.sub(burnAmount).sub(marketingAmount));
    }


    _transferBurnAndMarketingFee(sender, burnAmount, marketingAmount);
    

    if(!takeFee)
      restoreAllFee();
  }

  function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
    //uint256 currentRate =  _getRate();
    //uint256 tBurn,
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,, uint256 tLiquidity) = _getValues(tAmount);
    //uint256 rBurn =  tBurn.mul(currentRate);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    //rFee, rBurn, tFee, tBurn
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
    //uint256 currentRate =  _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,, uint256 tLiquidity) = _getValues(tAmount);
    //uint256 rBurn =  tBurn.mul(currentRate);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    //rFee, rBurn, tFee, tBurn
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
    //uint256 currentRate =  _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,, uint256 tLiquidity) = _getValues(tAmount);
    //uint256 rBurn =  tBurn.mul(currentRate);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    //rFee, rBurn, tFee, tBurn
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferStandard(address sender, address recipient, uint256 tAmount) private {
    //uint256 currentRate =  _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,, uint256 tLiquidity) = _getValues(tAmount);
    //uint256 rBurn =  tBurn.mul(currentRate);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferBurnAndMarketingFee(address sender, uint256 burnAmount, uint256 marketingAmount) private {

    removeTaxAndLiquidityFee();

    if (_isExcluded[sender]) {
      _transferBothExcluded(sender, deadAddress, burnAmount);
      _transferFromExcluded(sender, _marketingWallet, marketingAmount);
    } else {
      _transferToExcluded(sender, deadAddress, burnAmount);
      _transferStandard(sender, _marketingWallet, marketingAmount);
    }

    restoreTaxAndLiquidityFee();
  }


  // Section transactions limit
  function getTxLimit() external view returns (uint256) {
    return _maxTxAmount;
  }

  function _checkTxLimit(address sender, uint256 amount) internal view {
    require(amount <= _maxTxAmount || _isTxLimitExempt[sender], "TX Limit Exceeded");
  }


  // Section max wallet token
  function getMaxWalletToken() external view returns (uint256) {
    return _maxWalletToken;
  }



  //Section Reflections

  function isExcludedFromFee(address account) public view returns(bool) {
    return _isExcludedFromFee[account];
  }

  function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
    return _tokenFromReflection(rAmount);
  }

  function _tokenFromReflection(uint256 rAmount) private view returns(uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    uint256 currentRate =  _getRate();
    return rAmount.div(currentRate);
  }

  function _getRate() private view returns(uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns(uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;      
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _takeLiquidity(uint256 tLiquidity) private {
    uint256 currentRate =  _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if(_isExcluded[address(this)])
      _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }

//TODO: incluir la funcionalidad de burn o liquidity en las siguientes funciones:
//_reflectFee, _getValues, _getTValues, _getRValues
//uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn
  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee); //.sub(rBurn);
    _tFeeTotal = _tFeeTotal.add(tFee);
    //_tBurnTotal = _tBurnTotal.add(tBurn);
    //_tTotal = _tTotal.sub(tBurn);
  }

  function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
    (uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getTValues(tAmount);
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, tLiquidity, _getRate());
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tLiquidity);
  }

  function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
    uint256 tFee = _calculateTaxFee(tAmount);
    uint256 tBurn = _calculateBurnFee(tAmount);
    uint256 tLiquidity = _calculateLiquidityFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn).sub(tLiquidity);
    return (tTransferAmount, tFee, tBurn, tLiquidity);
  }

  function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rBurn = tBurn.mul(currentRate);
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rLiquidity);
    return (rAmount, rTransferAmount, rFee);
  }

  function _calculateTaxFee(uint256 amount) private view returns (uint256) {
    return amount.mul(_taxFee).div(100);
  }

  function _calculateBurnFee(uint256 amount) private view returns (uint256) {
    return amount.mul(_burnFee).div(100);
  }

  function _calculateLiquidityFee(uint256 amount) private view returns (uint256) {
    return amount.mul(_liquidityFee).div(100);
  }

  function _calculateMarketingFee(uint256 amount) private view returns (uint256) {
    return amount.mul(_marketingFee).div(100);
  }

  function removeAllFee() private {
    if(_taxFee == 0 && _marketingFee == 0 && _liquidityFee == 0 && _burnFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousMarketingFee = _marketingFee;
    _previousBurnFee = _burnFee;
    _previousLiquidityFee = _liquidityFee;

    _taxFee = 0;
    _marketingFee = 0;
    _burnFee = 0;
    _liquidityFee = 0;
  }

  function restoreAllFee() private {
    _taxFee = _previousTaxFee;
    _marketingFee = _previousMarketingFee;
    _burnFee = _previousBurnFee;
    _liquidityFee = _previousLiquidityFee;
  }

  function removeTaxAndLiquidityFee() private {
    if(_taxFee == 0 && _liquidityFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;

    _taxFee = 0;
    _liquidityFee = 0;
  }

  function restoreTaxAndLiquidityFee() private {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
  }







  //OWNER SETTINGS

  function setTxLimit(uint256 amount) external onlyOwner {
    _maxTxAmount = amount;
  }

  function setMaxWalletToken(uint256 amount) external onlyOwner {
    _maxWalletToken = amount;
  }

  function excludeFromReward(address account) public onlyOwner() {
    //TODO: check pancakerouter address
    //require(account != 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F, 'We can not exclude Pancake router.');
    require(!_isExcluded[account], "Account is already excluded");
    if(_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeInReward(address account) external onlyOwner() {
    require(_isExcluded[account], "Account is already excluded");
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }
  
  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function setTaxFee(uint256 taxFee) external onlyOwner() {
    _taxFee = taxFee;
  }

  function setMarketingWallet(address newWallet) external onlyOwner() {
    _marketingWallet = newWallet;
  }

  function setMarketingFee(uint256 marketingFee) external onlyOwner() {
    _marketingFee = marketingFee;
  }

  //habilitar esta funcion para activar liquidez automatica
  function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
    _swapAndLiquifyEnabled = enabled;
    emit SwapAndLiquifyEnabledUpdated(enabled);
  }

}