// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract Momento is IERC20Metadata, Ownable {
  struct User {
    uint256 buy;
    uint256 sell;
  }

  address public marketingAddress = 0x07c013fba1bB7CA3a3eb1dc0666De5bB0bF8D7d9;
  address public teamAddress = 0x6aEC062a363e4cFCC6A369Df2981Dc66cf4Bb8Ed;
  address public constant deadAddress =
    0x000000000000000000000000000000000000dEaD;

  uint256 private _rTeamLock;

  uint256 public teamUnlockTime;
  uint8 public teamUnlockCount;
  uint8 private _rTeamUnlockMonths;
  uint256 private _rTeamUnlockTokenCount;

  uint256 private _rBurnLock;

  uint256 private _rBuyBackTokenCount;
  uint256 private _buyBackETHCount;

  mapping(address => User) private _cooldown;

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private _isUniswapV2Pair;

  mapping(address => bool) private _isExcluded;
  address[] private _excluded;

  uint256 private _holderCount;
  uint256 private _lastMaxHolderCount = 99;

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal = 1000000000000 * 10**9;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;

  string private _name = 'Momento';
  string private _symbol = 'MOMENTO';

  uint256 public _taxFee = 4;
  uint256 private _previousTaxFee = _taxFee;

  uint256 public _liquidityFee = 3;
  uint256 private _previousLiquidityFee = _liquidityFee;

  uint256 public _marketingFee = 1;
  uint256 private _previousMarketingFee = _marketingFee;

  uint256 public _buyBackFee = 4;
  uint256 private _previousBuyBackFee = _buyBackFee;

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public uniswapV2Pair;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  uint256 public _maxTxAmount = 5000000000 * 10**9;
  uint256 private numTokensSellToAddToLiquidity = 500000000 * 10**9;

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );
  event SwapETHForTokens(uint256 amountIn, address[] path);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor() {
    // 1% of total reflection supply
    uint256 onePercentR = _rTotal / 100;
    // 1% of total t supply
    // uint256 onePercentT = _tTotal / 100;

    // add 60% of tokens to owner(for adding to liquidity pool)
    _rOwned[_msgSender()] = onePercentR * 60;
    // add 5% of tokens to marketing address
    _rOwned[marketingAddress] = onePercentR * 5;
    // lock 10% of tokens for burning further
    _rBurnLock = onePercentR * 10;
    // lock 3% of tokens for team for 6 months and vested over 18 months
    _rTeamLock = onePercentR * 3;
    _rOwned[address(0)] = _rBurnLock + _rTeamLock;

    _rTeamUnlockMonths = 18;
    _rTeamUnlockTokenCount = _rTeamLock / _rTeamUnlockMonths;

    teamUnlockTime = block.timestamp + 180 days;

    // burning 22% of totalsupply
    _rOwned[deadAddress] = onePercentR * 22;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    // Create a uniswap pair for this new token
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    // set the rest of the contract variables
    uniswapV2Router = _uniswapV2Router;

    _holderCount = 3;

    _isUniswapV2Pair[uniswapV2Pair] = true;

    emit Transfer(
      address(0),
      _msgSender(),
      tokenFromReflection(_rOwned[_msgSender()])
    );
    emit Transfer(
      address(0),
      marketingAddress,
      tokenFromReflection(_rOwned[marketingAddress])
    );
    emit Transfer(
      address(0),
      address(0),
      tokenFromReflection(_rOwned[address(0)])
    );
    emit Transfer(
      address(0),
      deadAddress,
      tokenFromReflection(_rOwned[deadAddress])
    );
  }

  function unlockTeam() public {
    require(
      _msgSender() == teamAddress,
      'Function can be called only with team address'
    );
    require(
      block.timestamp > teamUnlockTime,
      'Fucntion can be called only if teamUnlockTime has passed'
    );
    require(
      teamUnlockCount < _rTeamUnlockMonths,
      'You are already unlocked all tokens'
    );
    uint256 difference = block.timestamp - teamUnlockTime;
    uint256 monthCount = difference / 30 days;
    uint8 remainingMonths = _rTeamUnlockMonths - teamUnlockCount;
    if (monthCount > remainingMonths) monthCount = remainingMonths;
    uint256 amountToTransfer = monthCount * _rTeamUnlockTokenCount;
    _rOwned[address(0)] -= amountToTransfer;
    _rOwned[teamAddress] += amountToTransfer;
    teamUnlockCount += uint8(monthCount);
    teamUnlockTime += monthCount * 30 days;
    emit Transfer(
      address(0),
      teamAddress,
      tokenFromReflection(amountToTransfer)
    );
  }

  function setMarketingAddress(address _markeingAddress) public onlyOwner {
    marketingAddress = _markeingAddress;
  }

  function setTeamAddress(address _teamAddress) public onlyOwner {
    teamAddress = _teamAddress;
  }

  function _burnTenPercent() private {
    if (_rBurnLock != 0) {
      uint256 rBurnCount = _rBurnLock / 10;
      if (rBurnCount == 0) {
        rBurnCount = _rBurnLock;
      }
      _rBurnLock -= rBurnCount;
      _rOwned[address(0)] -= rBurnCount;
      _rOwned[deadAddress] += rBurnCount;
      emit Transfer(address(0), deadAddress, tokenFromReflection(rBurnCount));
    }
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function decimals() public pure override returns (uint8) {
    return 9;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] - subtractedValue
    );
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
    require(
      !_isExcluded[sender],
      'Excluded addresses cannot call this function'
    );
    uint256 rAmount = tAmount * _getRate();
    _rOwned[sender] -= rAmount;
    _rTotal -= rAmount;
    _tFeeTotal += tAmount;
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    public
    view
    returns (uint256)
  {
    require(tAmount <= _tTotal, 'Amount must be less than supply');
    uint256 currentRate = _getRate();
    if (!deductTransferFee) {
      return tAmount * currentRate;
    } else {
      uint256[5] memory tValues = _getTValues(tAmount);
      return tValues[0] * currentRate;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, 'Amount must be less than total reflections');
    uint256 currentRate = _getRate();
    return rAmount / currentRate;
  }

  function excludeFromReward(address account) public onlyOwner {
    // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
    require(!_isExcluded[account], 'Account is already excluded');
    require(account != marketingAddress, 'marketingAddress cannot be excluded');
    require(account != deadAddress, 'deadAddress cannot be excluded');
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeInReward(address account) external onlyOwner {
    require(_isExcluded[account], 'Account is already excluded');
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

  function addUniswapV2PairAddress(address account) public onlyOwner {
    _isUniswapV2Pair[account] = true;
  }

  function removeUniswapV2PairAddress(address account) public onlyOwner {
    _isUniswapV2Pair[account] = false;
  }

  function setTaxFeePercent(uint256 taxFee) external onlyOwner {
    _taxFee = taxFee;
  }

  function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
    _liquidityFee = liquidityFee;
  }

  function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
    _maxTxAmount = (_tTotal * maxTxPercent) / 100;
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}

  function _reflectFee(uint256 tFee, uint256 rFee) private {
    _rTotal -= rFee;
    _tFeeTotal += tFee;
  }

  function _getTValues(uint256 tAmount)
    private
    view
    returns (uint256[5] memory)
  {
    uint256[5] memory tValues;
    tValues[1] = calculateTaxFee(tAmount); // tFee
    tValues[2] = calculateLiquidityFee(tAmount); // tLiquidity
    tValues[3] = calculateMarketingFee(tAmount); // tMarketing
    tValues[4] = calculateBuyBackFee(tAmount); // tBuyBack
    tValues[0] = tAmount - tValues[1] - tValues[2] - tValues[3] - tValues[4]; // tTrasnferAmount
    return tValues;
  }

  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply / tSupply;
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
        return (_rTotal, _tTotal);
      rSupply -= _rOwned[_excluded[i]];
      tSupply -= _tOwned[_excluded[i]];
    }
    if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _takeLiquidity(uint256 tLiquidity, uint256 rLiquidity) private {
    _rOwned[address(this)] += rLiquidity;
    if (_isExcluded[address(this)]) {
      _tOwned[address(this)] += tLiquidity;
    }
  }

  function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    return (_amount * _taxFee) / 100;
  }

  function calculateLiquidityFee(uint256 _amount)
    private
    view
    returns (uint256)
  {
    return (_amount * _liquidityFee) / 100;
  }

  function calculateMarketingFee(uint256 _amount)
    private
    view
    returns (uint256)
  {
    return (_amount * _marketingFee) / 100;
  }

  function calculateBuyBackFee(uint256 _amount) private view returns (uint256) {
    return (_amount * _buyBackFee) / 100;
  }

  function removeAllFee() private {
    if (
      _taxFee == 0 &&
      _liquidityFee == 0 &&
      _marketingFee == 0 &&
      _buyBackFee == 0
    ) return;

    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;
    _previousMarketingFee = _marketingFee;
    _previousBuyBackFee = _buyBackFee;

    _taxFee = 0;
    _liquidityFee = 0;
    _marketingFee = 0;
    _buyBackFee = 0;
  }

  function restoreAllFee() private {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
    _marketingFee = _previousMarketingFee;
    _buyBackFee = _previousBuyBackFee;
  }

  function isUniswapV2PairAddress(address account) public view returns (bool) {
    return _isUniswapV2Pair[account];
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');
    require(amount > 0, 'Transfer amount must be greater than zero');
    if (from != owner() && to != owner()) {
      require(
        amount <= _maxTxAmount,
        'Transfer amount exceeds the maxTxAmount.'
      );
    }

    // if balance of recipient is 0 then holder count is increased
    // and if sender balance is equal to amount then holder count decreased
    if (balanceOf(to) == 0) _holderCount++;
    if (balanceOf(from) == amount) _holderCount--;

    // indicates if fee should be deducted from transfer
    bool takeFee;

    // take fee only in buying or selling operation
    if (from != address(this) && to != address(this)) {
      // buy
      if (_isUniswapV2Pair[from] && to != address(uniswapV2Router)) {
        takeFee = true;
        uint256 timestamp = block.timestamp;
        require(
          _cooldown[from].buy < timestamp,
          'You can transfer tokens once in 15 seconds'
        );
        _cooldown[from].buy = timestamp + 30;
      }
      // sell
      else {
        // if holderCount increases by 100 then 10% of
        // burnlock tokens burned
        if (_holderCount > _lastMaxHolderCount) {
          _burnTenPercent();
          _lastMaxHolderCount += 100;
        }
        if (_isUniswapV2Pair[to]) {
          takeFee = true;
          // if ETH from buy back is more or equal than 0.2 ether
          // then we buyBack tokens and burn
          if (_buyBackETHCount >= 0.2 ether) {
            _buyBackAndBurn(_buyBackETHCount);
            _buyBackETHCount = 0;
          }
          uint256 timestamp = block.timestamp;
          require(
            _cooldown[to].sell < timestamp,
            'You can transfer tokens once in 15 seconds'
          );
          _cooldown[to].sell = timestamp + 30;

          // is the token balance of this contract address over the min number of
          // tokens that we need to initiate a swap + liquidity lock?
          // also, don't get caught in a circular liquidity event.
          // also, don't swap & liquify if sender is uniswap pair.
          uint256 contractTokenBalance = balanceOf(address(this));

          if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
          }
          bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
          if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !_isUniswapV2Pair[from] &&
            swapAndLiquifyEnabled
          ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            // add liquidity
            swapAndLiquify(contractTokenBalance);
          }
        }
      }
    }

    // if sender is owner or recipient is owner or recipient is deadAddress
    // then fee does not taken
    if (from == owner() || to == owner() || to == deadAddress) {
      takeFee = false;
    }

    // transfer amount, it will take tax, burn, liquidity, marketing fee
    _tokenTransfer(from, to, amount, takeFee);
  }

  function _buyBackAndBurn(uint256 amount) private lockTheSwap {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = address(this);

    // make the swap
    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
      value: amount
    }(
      0, // accept any amount of Tokens
      path,
      deadAddress, // Burn address
      block.timestamp
    );

    emit SwapETHForTokens(amount, path);

    // burn
    uint256 balance = balanceOf(deadAddress);
    if (balance > 0) {
      _rTotal -= _rOwned[deadAddress];
      _tTotal -= balance;
      _rOwned[deadAddress] = 0;
      emit Transfer(deadAddress, address(0), balance);
    }
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    // split the contract balance into halves
    uint256 half = contractTokenBalance / 2;
    uint256 otherHalf = contractTokenBalance - half;

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance - initialBalance;

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
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner(),
      block.timestamp
    );
  }

  //this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 tAmount,
    bool takeFee
  ) private {
    if (!takeFee) {
      removeAllFee();
    }

    // tValues[0] -> tTransferAmount -> transfer amount
    // tValues[1] -> tFee -> holders fee amount
    // tValues[2] -> tLiquidity -> liquidity fee amount
    // tValues[3] -> tMarketing -> marketing fee amount
    // tValues[4] -> tBuyBack -> buyBack fee amount
    uint256[5] memory tValues = _getTValues(tAmount);
    uint256 currentRate = _getRate();
    if (takeFee) {
      _rBuyBackTokenCount += (tValues[4] * currentRate);
      if (!_isUniswapV2Pair[sender] && _rBuyBackTokenCount > 0) {
        uint256 _tBuyBackTokenCount = _rBuyBackTokenCount / currentRate;
        address contractAddress = address(this);
        _rOwned[contractAddress] += _rBuyBackTokenCount;
        emit Transfer(sender, contractAddress, _tBuyBackTokenCount);
        uint256 balanceBefore = contractAddress.balance;
        swapTokensForEth(_tBuyBackTokenCount);
        uint256 balanceAfter = contractAddress.balance;
        _buyBackETHCount += balanceAfter - balanceBefore;
        _rBuyBackTokenCount = 0;
      }
      _rOwned[marketingAddress] += (tValues[3] * currentRate);
      _takeLiquidity(tValues[2], tValues[2] * currentRate);
      _reflectFee(tValues[1], tValues[1] * currentRate);
      emit Transfer(sender, marketingAddress, tValues[3]);
    }
    _rOwned[sender] -= (tAmount * currentRate);
    _rOwned[recipient] += (tValues[0] * currentRate);
    if (_isExcluded[sender]) {
      _tOwned[sender] -= tAmount;
    }
    if (_isExcluded[recipient]) {
      _tOwned[recipient] += tValues[0];
    }
    emit Transfer(sender, recipient, tValues[0]);

    if (!takeFee) {
      restoreAllFee();
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

