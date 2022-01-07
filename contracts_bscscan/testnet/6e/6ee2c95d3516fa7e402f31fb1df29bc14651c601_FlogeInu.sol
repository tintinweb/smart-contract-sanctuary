pragma solidity ^0.8.11;
  // SPDX-License-Identifier: Unlicensed
  
  import "./Context.sol";
  import "./IERC20.sol";
  import "./Ownable.sol";
  import "./SafeMath.sol";
  import "./Address.sol";
  import "./IUniswapV2Router02.sol";
  import "./IUniswapV2Factory.sol";
  import "./IUniswapV2Pair.sol";

  contract FlogeInu is Context, IERC20, Ownable {
      using SafeMath for uint256;
      using Address for address;
  
      mapping (address => uint256) private _rOwned;
      mapping (address => uint256) private _tOwned;
      mapping (address => mapping (address => uint256)) private _allowances;
  
      mapping (address => bool) private _isExcludedFromFee;
  
      mapping (address => bool) private _isExcluded;
      address[] private _excluded;
     
      uint256 private constant MAX = ~uint256(0);
      uint256 private _tTotal = 100000000 * 10**6 * 10**9;
      uint256 private _rTotal = (MAX - (MAX % _tTotal));
      uint256 private _tFeeTotal;
  
      string private _name = "FlogeInu";
      string private _symbol = "FLG";
      uint8 private _decimals = 9;
      
      uint256 public _taxFee = 5;
      uint256 private _previousTaxFee = _taxFee;
      
      uint256 public _liquidityFee = 5;
      uint256 private _previousLiquidityFee = _liquidityFee;
  
      IUniswapV2Router02 public immutable uniswapV2Router;
      address public immutable uniswapV2Pair;
      
      bool inSwapAndLiquify;
      bool public swapAndLiquifyEnabled = true;
      
      uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
      uint256 private numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;
      
      //DEV WALLETS

      //address public constant routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
      //address public constant airdropWallet = 0xDbF264b8DE514A567A7ac3E680415CA54d959A23;
      //address public constant charityWallet = 0x84a3214a86DC5dDd3A01792C81a1F6523523d79b;
      //address public constant marketingWallet = 0xBcCE0642821c34835aBbc01AEc1BDA82B14670dd;
      address public constant routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
      address public constant airdropWallet = 0xc5c5567E8893aDc1bd89eA255aC7dF0dE34E812D;
      address public constant charityWallet = 0x43f2D9916c65F4efCfeA00F2776f93965576B93E;
      address public constant marketingWallet = 0x680f51C80DDC4B176F0755372b83CC0ADD973E4F;


      //AIRDROP DATA

      uint256 public airdropLockDuration = 10 minutes;

      struct AirdropData {
          uint256 amount;
          uint256 releaseTime;
      }

      mapping (address => AirdropData) private _airdropLog;
      mapping (address => bool) private _airdropped;
      
      event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
      event SwapAndLiquifyEnabledUpdated(bool enabled);
      event SwapAndLiquify(
          uint256 tokensSwapped,
          uint256 ethReceived,
          uint256 tokensIntoLiqudity
      );
      
      modifier lockTheSwap {
          inSwapAndLiquify = true;
          _;
          inSwapAndLiquify = false;
      }

      modifier onlyAirdropper {
          require(_msgSender() == airdropWallet);
          _;
      }
      
      constructor () {
          _rOwned[_msgSender()] = _rTotal;
          
          IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
           // Create a uniswap pair for this new token
          uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
              .createPair(address(this), _uniswapV2Router.WETH());
  
          // set the rest of the contract variables
          uniswapV2Router = _uniswapV2Router;
          
          //exclude owner, this contract and other wallets from fee
          _isExcludedFromFee[owner()] = true;
          _isExcludedFromFee[address(this)] = true;
          _isExcludedFromFee[airdropWallet] = true;
          _isExcludedFromFee[charityWallet] = true;
          _isExcludedFromFee[marketingWallet] = true;
          
          emit Transfer(address(0), _msgSender(), _tTotal);
          _transfer(_msgSender(), marketingWallet, 10000000 * 10**6 * 10**9);
          _transfer(_msgSender(), airdropWallet, 10000000 * 10**6 * 10**9);
          _transfer(_msgSender(), charityWallet, 5000000 * 10**6 * 10**9);
      }
  
      function name() public view returns (string memory) {
          return _name;
      }
  
      function symbol() public view returns (string memory) {
          return _symbol;
      }
  
      function decimals() public view returns (uint8) {
          return _decimals;
      }
  
      function totalSupply() public view override returns (uint256) {
          return _tTotal;
      }
  
      function balanceOf(address account) public view override returns (uint256) {
          if (_isExcluded[account]) return _tOwned[account];
          return tokenFromReflection(_rOwned[account]);
      }
  
      function transfer(address recipient, uint256 amount) public override returns (bool) {
          _transfer(_msgSender(), recipient, amount);
          return true;
      }
  
      function allowance(address owner, address spender) public view override returns (uint256) {
          return _allowances[owner][spender];
      }
  
      function approve(address spender, uint256 amount) public override returns (bool) {
          _approve(_msgSender(), spender, amount);
          return true;
      }
  
      function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
          _transfer(sender, recipient, amount);
          _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
          return true;
      }
  
      function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
          _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
          return true;
      }
  
      function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
          _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
          return true;
      }
  
      function isExcludedFromReward(address account) public view returns (bool) {
          return _isExcluded[account];
      }
  
      function totalFees() public view returns (uint256) {
          return _tFeeTotal;
      }
  
      function deliver(uint256 tAmount) public {
          address sender = _msgSender();
          require(!_isExcluded[sender], "Excluded addresses cannot call this function");
          (uint256 rAmount,,,,,) = _getValues(tAmount);
          _rOwned[sender] = _rOwned[sender].sub(rAmount);
          _rTotal = _rTotal.sub(rAmount);
          _tFeeTotal = _tFeeTotal.add(tAmount);
      }
  
      function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
          require(tAmount <= _tTotal, "Amount must be less than supply");
          if (!deductTransferFee) {
              (uint256 rAmount,,,,,) = _getValues(tAmount);
              return rAmount;
          } else {
              (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
              return rTransferAmount;
          }
      }
  
      function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
          require(rAmount <= _rTotal, "Amount must be less than total reflections");
          uint256 currentRate =  _getRate();
          return rAmount.div(currentRate);
      }
  
      function excludeFromReward(address account) public onlyOwner() {
          // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
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
          function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
          (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
          _tOwned[sender] = _tOwned[sender].sub(tAmount);
          _rOwned[sender] = _rOwned[sender].sub(rAmount);
          _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
          _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
          _takeLiquidity(tLiquidity);
          _reflectFee(rFee, tFee);
          emit Transfer(sender, recipient, tTransferAmount);
      }
      
          function excludeFromFee(address account) public onlyOwner {
          _isExcludedFromFee[account] = true;
      }
      
      function includeInFee(address account) public onlyOwner {
          _isExcludedFromFee[account] = false;
      }
      
      function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
          _taxFee = taxFee;
          require(_taxFee+_liquidityFee < 26, "Sum of taxes must be under 26%");
      }
      
      function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
          _liquidityFee = liquidityFee;
          require(_taxFee+_liquidityFee < 26, "Sum of taxes must be under 26%");
      }
     
      function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
          //maxtx divisor is 10000 thus 100 is 1% and so on
          require(maxTxPercent >= 5, "maxTxPercent should be greater than or equal to 0.05%");
          _maxTxAmount = _tTotal.mul(maxTxPercent).div(
              10**4
          );
      }
  
      function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
          swapAndLiquifyEnabled = _enabled;
          emit SwapAndLiquifyEnabledUpdated(_enabled);
      }
      
       //to recieve ETH from uniswapV2Router when swaping
      receive() external payable {}
  
      function _reflectFee(uint256 rFee, uint256 tFee) private {
          _rTotal = _rTotal.sub(rFee);
          _tFeeTotal = _tFeeTotal.add(tFee);
      }
  
      function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
          (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
          (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
          return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
      }
  
      function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
          uint256 tFee = calculateTaxFee(tAmount);
          uint256 tLiquidity = calculateLiquidityFee(tAmount);
          uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
          return (tTransferAmount, tFee, tLiquidity);
      }
  
      function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
          uint256 rAmount = tAmount.mul(currentRate);
          uint256 rFee = tFee.mul(currentRate);
          uint256 rLiquidity = tLiquidity.mul(currentRate);
          uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
          return (rAmount, rTransferAmount, rFee);
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
      
      function calculateTaxFee(uint256 _amount) private view returns (uint256) {
          return _amount.mul(_taxFee).div(
              10**2
          );
      }
  
      function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
          return _amount.mul(_liquidityFee).div(
              10**2
          );
      }
      
      function removeAllFee() private {
          if(_taxFee == 0 && _liquidityFee == 0) return;
          
          _previousTaxFee = _taxFee;
          _previousLiquidityFee = _liquidityFee;
          
          _taxFee = 0;
          _liquidityFee = 0;
      }
      
      function restoreAllFee() private {
          _taxFee = _previousTaxFee;
          _liquidityFee = _previousLiquidityFee;
      }
      
      function isExcludedFromFee(address account) public view returns(bool) {
          return _isExcludedFromFee[account];
      }
  
      function _approve(address owner, address spender, uint256 amount) private {
          require(owner != address(0), "ERC20: approve from the zero address");
          require(spender != address(0), "ERC20: approve to the zero address");
  
          _allowances[owner][spender] = amount;
          emit Approval(owner, spender, amount);
      }
  
      function _transfer(
          address from,
          address to,
          uint256 amount
      ) private {
          require(from != address(0), "ERC20: transfer from the zero address");
          require(to != address(0), "ERC20: transfer to the zero address");
          require(amount > 0, "Transfer amount must be greater than zero");
          if (from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

          //AirdropLock check
          if (_airdropped[from] && _airdropLog[from].releaseTime > block.timestamp)
            require(balanceOf(from).sub(amount) >= _airdropLog[from].amount, "Cannot sell airdropped tokens: still locked.");
  
          // is the token balance of this contract address over the min number of
          // tokens that we need to initiate a swap + liquidity lock?
          // also, don't get caught in a circular liquidity event.
          // also, don't swap & liquify if sender is uniswap pair.
          uint256 contractTokenBalance = balanceOf(address(this));
          
          if(contractTokenBalance >= _maxTxAmount)
          {
              contractTokenBalance = _maxTxAmount;
          }
          
          bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
          if (
              overMinTokenBalance &&
              !inSwapAndLiquify &&
              from != uniswapV2Pair &&
              swapAndLiquifyEnabled
          ) {
              contractTokenBalance = numTokensSellToAddToLiquidity;
              //add liquidity
              swapAndLiquify(contractTokenBalance);
          }
          
          //indicates if fee should be deducted from transfer
          bool takeFee = true;
          
          //if any account belongs to _isExcludedFromFee account then remove the fee
          if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
              takeFee = false;
          }
          
          //transfer amount, it will take tax, burn, liquidity fee
          _tokenTransfer(from,to,amount,takeFee);
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
  
          // add liquidity to uniswap
          addLiquidity(otherHalf, newBalance);
          
          emit SwapAndLiquify(half, newBalance, otherHalf);
      }
  
      function swapTokensForEth(uint256 tokenAmount) private {
          // generate the uniswap pair path of token -> weth
          address[] memory path = new address[](2);
          path[0] = address(this);
          path[1] = uniswapV2Router.WETH();
  
          _approve(address(this), address(uniswapV2Router), tokenAmount);
  
          // make the swap
          uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
              tokenAmount,
              0, // accept any amount of ETH
              path,
              address(this),
              block.timestamp
          );
      }
  
      function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
          // approve token transfer to cover all possible scenarios
          _approve(address(this), address(uniswapV2Router), tokenAmount);
  
          // add the liquidity
          uniswapV2Router.addLiquidityETH{value: ethAmount}(
              address(this),
              tokenAmount,
              0, // slippage is unavoidable
              0, // slippage is unavoidable
              owner(),
              block.timestamp
          );
      }
  
      //this method is responsible for taking all fee, if takeFee is true
      function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
          if(!takeFee)
              removeAllFee();
          
          if (_isExcluded[sender] && !_isExcluded[recipient]) {
              _transferFromExcluded(sender, recipient, amount);
          } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
              _transferToExcluded(sender, recipient, amount);
          } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
              _transferStandard(sender, recipient, amount);
          } else if (_isExcluded[sender] && _isExcluded[recipient]) {
              _transferBothExcluded(sender, recipient, amount);
          } else {
              _transferStandard(sender, recipient, amount);
          }
          
          if(!takeFee)
              restoreAllFee();
      }
  
      function _transferStandard(address sender, address recipient, uint256 tAmount) private {
          (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
          _rOwned[sender] = _rOwned[sender].sub(rAmount);
          _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
          _takeLiquidity(tLiquidity);
          _reflectFee(rFee, tFee);
          emit Transfer(sender, recipient, tTransferAmount);
      }
  
      function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
          (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
          _rOwned[sender] = _rOwned[sender].sub(rAmount);
          _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
          _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
          _takeLiquidity(tLiquidity);
          _reflectFee(rFee, tFee);
          emit Transfer(sender, recipient, tTransferAmount);
      }
  
      function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
          (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
          _tOwned[sender] = _tOwned[sender].sub(tAmount);
          _rOwned[sender] = _rOwned[sender].sub(rAmount);
          _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
          _takeLiquidity(tLiquidity);
          _reflectFee(rFee, tFee);
          emit Transfer(sender, recipient, tTransferAmount);
      }
  
    
      function sendAirdrop (address[] calldata receivers, uint256 amount) external onlyAirdropper returns (bool) {
          for (uint i = 0; i < receivers.length; i++) {
              require(!_airdropped[receivers[i]], "Cannot airdrop to addresses already airdropped");
              _transfer(_msgSender(), receivers[i], amount);
              _airdropLog[receivers[i]] = AirdropData(amount, block.timestamp + airdropLockDuration);
              _airdropped[receivers[i]] = true;
          }
          return true;
      }

      function getAirdropLog(address addr) external returns (AirdropData memory) {
          return _airdropLog[addr];
      }
      
  
  }