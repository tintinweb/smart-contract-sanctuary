// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Context.sol";

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/*
* Tokenomics
*
*  Name  - StrikeX
*  Symbol - STRX 
*  MAX Supply -  1 billion
*  Selling tax 3%  - only applicable for 6 months (0% thereafter)
*  3% selling tax distribution
    - 1.5% to liquidity pool 
    - 1% to team wallet (sent as BNB)
    - 0.5% to ‘buyback’ wallet (sent as BNB)
    - Anti-dump Max Sell no more than 0.5% of supply (5M) over 24 hours – only applicable for 6 months (0% thereafter)
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Context.sol";
import "./Ownable.sol";
import "./library/SafeMath.sol";
import "./library/IBEP20.sol";

import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Router02.sol";

contract StrikeX is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping(address => bool) private _isExcludedFromFee; // wallets excluded from fee
  mapping (address => uint256) private _tokenSold;

  mapping (address => uint256) private _startTime;
  mapping (address => uint256) private _blockTime;

  uint256 public _maxSoldAmount;
  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;  
  uint256 public _taxFee;
  uint256 public _minBalance;

  address public uniswapV2Pair;
  address payable public _teamWallet;
  address payable public _buybackWallet;

  bool public inSwap = false;
  bool public swapEnabled = true;

  IUniswapV2Router02 public uniswapV2Router; // pancakeswap v2 router

  modifier lockTheSwap {
    inSwap = true;
    _;
    inSwap = false;
  }

  /**
   * @dev Initialize params for tokenomics
   */

  constructor() {
    _name = unicode"StrikeX";
    _symbol = "STRX";
    _decimals = 18;
    _totalSupply = 10**9 * 10**18;
    _balances[msg.sender] = _totalSupply;    
    _taxFee = 300;
    _minBalance = 10 * 10**18;
    _maxSoldAmount = 5 * 10**6 * 10**18;

    _teamWallet = payable(0x7e16BA3D0E01d3d61BC0DC236f31263Ce7C65755); 
    _buybackWallet = payable(0xFBffa3D8F8ed0723EFE07E539752847a51e63e7B);

    // BSC TestNet router
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;

    // BSC MainNet router
    //0x10ED43C718714eb63d5aA57B78B54704E256024E

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_teamWallet] = true;
    _isExcludedFromFee[_buybackWallet] = true;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */

  function getOwner() external override view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */

  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */

  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */

  function name() external override view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */

  //function balanceOf(address account) external override view returns (uint256) {
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }
  
  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
   
  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */

  function _transfer(address from, address to, uint256 amount) internal {

    require(from != address(0), "BEP20: transfer from the zero address");
    require(to != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    if (from != owner() && to != owner()) {
 
      if (!inSwap && swapEnabled && to == uniswapV2Pair && from != address(this)) {

        // limit max sold
        if(_tokenSold[from] == 0){
          _startTime[from] = block.timestamp;
        }

        _tokenSold[from] = _tokenSold[from] + amount;

        if( block.timestamp < _startTime[from] + (1 days)){
            require(_tokenSold[from] <= _maxSoldAmount, "Sold amount exceeds the maxTxAmount.");
        }else{
            _startTime[from] = block.timestamp;
            _tokenSold[from] = 0;
        }

        // transfer tokens
        uint256 strikeBalance = balanceOf(address(this));
        if(strikeBalance > _minBalance){                    
          transferTokens(strikeBalance);
        }
      }
    }

    bool takeFee = true;
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
        takeFee = false;
    }
    _tokenTransfer(from, to, amount, takeFee);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.   
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
    * @dev transfer tokens to liqudity, team wallet and buyback wallet.
   */

  function transferTokens(uint256 tokenBalance) private lockTheSwap {
    uint256 liquidityTokens = tokenBalance.div(4); // 0.75%
    uint256 otherBNBTokens = tokenBalance - liquidityTokens; // 2.25%

    uint256 initialBalance = address(this).balance;
    swapTokensForEth(otherBNBTokens);

    uint256 newBalance = address(this).balance.sub(initialBalance);
    uint256 liquidityCapacity = newBalance.div(3);
    addLiqudity(liquidityTokens, liquidityCapacity);

    uint256 teamCapacity = newBalance - liquidityCapacity;    
    uint256 teamBNB = teamCapacity.mul(2).div(3);
    _teamWallet.transfer(teamBNB);

    uint256 buybackBNB = teamCapacity - teamBNB;
    _buybackWallet.transfer(buybackBNB);
  }

  /**
    * @dev Swap tokens from strike to bnb
   */

  function swapTokensForEth(uint256 tokenAmount) private{
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
  }

  /**
    * @dev Add strike token and bnb as same ratio on pancakeswap router
   */

  function addLiqudity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add amount to contract
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
        address(this),
        tokenAmount,
        0, // slippage is unavoidable
        0, // slippage is unavoidable
        owner(),
        block.timestamp
    );
  }

  /**
    * @dev the Owner can swap regarding the strike token's amount of contract balance
    * this is for manual function
   */

  function contractBalanceSwap() external onlyOwner{
      uint256 contractBalance = balanceOf(address(this));
      swapTokensForEth(contractBalance);
  }

  /**
    * @dev the Owner can send regarding the strike token's amount of contract balance
    * this is for manual function
    * we need to remain 0.1BNB in contract balance for swap and transfer fees.
   */

  function contractBalanceSend(uint256 amount, address payable _destAddr) external onlyOwner{
    uint256 contractETHBalance = address(this).balance - 1 * 10**17;
    if(contractETHBalance > amount){
      _destAddr.transfer(amount);
    }
  }

  /**
    * @dev remove all fees
   */

  function removeAllFee() private {
    if (_taxFee == 0) return;
    _taxFee = 0;
  }

  /**
    * @dev set all fees
   */

  function restoreAllFee() private {
    _taxFee = 300;
  }

  /**
    * @dev transfer tokens with amount 
   */

  function _tokenTransfer(address sender, address recipient, uint256 amount, bool isTakeFee) private {
    if (!isTakeFee) removeAllFee();
    _transferStandard(sender, recipient, amount);
    if (!isTakeFee) restoreAllFee();
  }

  /**
    * @dev transferStandard tokens with taxFee
   */

  function _transferStandard(address sender, address recipient, uint256 amount) private {    
    uint256 fee = amount.mul(_taxFee).div(10000); // for 3% fee
    //_beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    uint256 amountnew = amount - fee;
    _balances[recipient] += (amountnew);

    if (fee>0) {
      _balances[address(this)] += (fee);
      emit Transfer(sender, address(this), fee);
    }

    emit Transfer(sender, recipient, amountnew);
  }

  /**
    * @dev set Max sold amount
   */

  function _setMaxSoldAmount(uint256 maxvalue) external onlyOwner {
      _maxSoldAmount = maxvalue;
  }

  /**
    * @dev set min balance for transferring
   */

  function _setMinBalance(uint256 minValue) external onlyOwner {
    _minBalance = minValue;
  }

  /**
    * @dev determine whether we apply tax fee or not
   */

  function _setApplyContractFee(bool isFee) external onlyOwner {
    if(isFee) {
        _taxFee = 300;
    } else {
        _taxFee = 0;
    }
  }

  function _setTeamWalletAddress(address teamWalletAddr) external onlyOwner {
    _teamWallet = payable(teamWalletAddr);
  }

  function _setBuybackWalletAddress(address buybackWalletAddr) external onlyOwner {
    _buybackWallet = payable(buybackWalletAddr);
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity ^0.8.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

