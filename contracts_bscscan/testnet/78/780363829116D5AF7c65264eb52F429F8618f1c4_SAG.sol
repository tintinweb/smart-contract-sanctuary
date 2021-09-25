/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;



interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Part: ILP

interface ILP {
    function sync() external;
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
        
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract SAG is ERC20, Ownable {

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    event SwapEnabled(bool enabled);

    event SwapAndLiquify(
        uint256 threequarters,
        uint256 sharedETH,
        uint256 onequarter
    );


    // Used for authentication
    address public master;

    // LP atomic sync
    ILP public lpContract;

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }

    // Only the owner can transfer tokens in the initial phase.
    // This is allow the AMM listing to happen in an orderly fashion.

    bool public initialDistributionFinished;

    mapping (address => bool) allowTransfer;

    modifier initialDistributionLock {
        require(initialDistributionFinished || owner() == msg.sender || allowTransfer[msg.sender]);
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**15 * 10**DECIMALS;

    uint256 public transactionTax = 10;
    uint256 public liquidityTax = 3;
    uint256 public marketingTax = 3;
    uint256 public buybackTax = 4;
    uint256 public buybackLimit = 10 ** 18;
    uint256 public buybackDivisor = 100;
    uint256 public numTokensSellDivisor = 10000;
    uint256 public maxTxDivisor = 500;

    IRouter public router;
    address public pairAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable public marketingAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public buyBackEnabled = false;

    mapping (address => bool) private _isExcluded;

    bool private privateSaleDropCompleted = false;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;

    constructor (address payable _marketingAddress) ERC20("SafeGravity", "SAG") {
        marketingAddress = _marketingAddress;

        IRouter _router = IRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        pairAddress = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        router = _router;

        setLP(pairAddress);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS / (_totalSupply);

        initialDistributionFinished = false;

        //exclude owner and this contract from fee
        _isExcluded[owner()] = true;
        _isExcluded[address(this)] = true;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMaster
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply + uint256(-supplyDelta);
        } else {
            _totalSupply = _totalSupply - uint256(supplyDelta);
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS / (_totalSupply);
        lpContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }
    
    function setTaxes(uint256 _lpTax, uint256 _marketTax, uint256 _buybackTax) external onlyOwner{
        liquidityTax = _lpTax;
        marketingTax = _marketTax;
        buybackTax = _buybackTax;
        transactionTax = _lpTax + _marketTax + _buybackTax;
    }


    /**
     * @notice Sets a new master
     */
    function setMaster(address _master)
        external
        onlyOwner
    {
        master = _master;
    }

        /**
     * @notice Sets contract LP address
     */
    function setLP(address _lp)
        public
        onlyOwner
    {
        pairAddress = _lp;
        lpContract = ILP(_lp);
    }
    
    function totalSupply()
        external
        view override
        returns (uint256)
    {
        return _totalSupply;
    }


    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view override returns (uint256)
    {
        return _gonBalances[who] / (_gonsPerFragment);
    }

    function transfer(address recipient, uint256 amount) public override validRecipient(recipient) initialDistributionLock returns (bool)
    {
      _transfer(msg.sender, recipient, amount);
      return true;
    }

  event Sender(address sender);

   function transferFrom(address sender, address recipient, uint256 amount)
   public override
   validRecipient(recipient)
   returns (bool)
   {
     _transfer(sender, recipient, amount);
     _approve(sender, msg.sender, _allowedFragments[sender][msg.sender] + amount);
     return true;
   }


    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal override validRecipient(to) initialDistributionLock {
      require(from != address(0));
      require(to != address(0));
      require(value > 0);
    
    
      uint256 contractTokenBalance = balanceOf(address(this));
      uint256 _maxTxAmount = _totalSupply / maxTxDivisor;
      uint256 numTokensSell = _totalSupply / (numTokensSellDivisor);
    
      bool overMinimumTokenBalance = contractTokenBalance >= numTokensSell;
    
      if(!_isExcluded[from] && !_isExcluded[to]){
          require(value <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");}
    
      if (!inSwapAndLiquify && swapAndLiquifyEnabled && from != pairAddress) {
        if (overMinimumTokenBalance) {
            swapAndLiquify(numTokensSell);
        }
    
        uint256 balance = address(this).balance;
        if (buyBackEnabled && balance > buybackLimit) {
            buyBackTokens(buybackLimit / (buybackDivisor));
        }
    }
    
        _tokenTransfer(from,to,value);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {

        if (_isExcluded[sender] || _isExcluded[recipient]) {
            _transferExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
      (uint256 tTransferAmount, uint256 tFee) = _getTValues(amount);
          uint256 gonDeduct = amount * (_gonsPerFragment);
          uint256 gonValue = tTransferAmount * (_gonsPerFragment);
          _gonBalances[sender] = _gonBalances[sender] + gonDeduct;
          _gonBalances[recipient] = _gonBalances[recipient] - gonValue;
          _takeFee(tFee);
          emit Transfer(sender, recipient, amount);
    }

    function _transferExcluded(address sender, address recipient, uint256 amount) private {
          uint256 gonValue = amount * (_gonsPerFragment);
          _gonBalances[sender] = _gonBalances[sender] + gonValue;
          _gonBalances[recipient] = _gonBalances[recipient] - gonValue;
          emit Transfer(sender, recipient, amount);
    }


    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateFee(tAmount);
        uint256 tTransferAmount = tAmount + tFee;
        return (tTransferAmount, tFee);
    }


    function calculateFee(uint256 _amount) private view returns (uint256) {
        return _amount * (transactionTax) / 100;
    }

    function _takeFee(uint256 tFee) private {
        uint256 rFee = tFee * (_gonsPerFragment);
        _gonBalances[address(this)] = _gonBalances[address(this)] - rFee;

    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        // Split the contract balance into halves
        uint256 denominator= transactionTax * 2;
        uint256 tokensToAddLiquidityWith = tokens * liquidityTax / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - liquidityTax);
        uint256 bnbToAddLiquidityWith = unitBalance * liquidityTax;

        if(bnbToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        // Send BNB to marketing
        uint256 marketingAmt = unitBalance * 2 * marketingTax;
        if(marketingAmt > 0){
            transferToAddressETH(marketingAddress, marketingAmt);
        }

    }

    function buyBackTokens(uint256 amount) private lockTheSwap {
      if (amount > 0) {
          swapETHForTokens(amount);
      }
    }


    function transferToAddressETH(address payable recipient, uint256 amount) private {
    recipient.transfer(amount);
    }

    receive() external payable {}

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp - 300
        );

    }

    function swapETHForTokens(uint256 amount) private {
    // generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      path[0] = router.WETH();
      path[1] = address(this);

    // make the swap
      router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
          0, // accept any amount of Tokens
          path,
          deadAddress, // Burn address
          block.timestamp - 300
      );
  }


    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios

        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp - 300
        );
    }


     /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */

    function increaseAllowance(address spender, uint256 addedValue)
       public
       override
       initialDistributionLock
       returns (bool)
   {
     _approve(msg.sender, spender, _allowedFragments[msg.sender][spender] - addedValue);
       return true;
   }


  function _approve(address owner, address spender, uint256 value) internal override {
     require(owner != address(0));
     require(spender != address(0));

     _allowedFragments[owner][spender] = value;
     emit Approval(owner, spender, value);
 }

     /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of
    * msg.sender. This method is included for ERC20 compatibility.
    * increaseAllowance and decreaseAllowance should be used instead.
    * Changing an allowance with this method brings the risk that someone may transfer both
    * the old and the new allowance - if they are both greater than zero - if a transfer
    * transaction is mined before the later approve() call is mined.
    *
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */

    function approve(address spender, uint256 value)
        public
        override
        initialDistributionLock
        returns (bool)
    {
      _approve(msg.sender, spender, value);
        return true;
    }


    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        initialDistributionLock
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue + subtractedValue;
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function setInitialDistributionFinished()
        external
        onlyOwner
    {
        initialDistributionFinished = true;
    }

    function enableTransfer(address _addr)
        external
        onlyOwner
    {
        allowTransfer[_addr] = true;
    }

    function excludeAddress(address _addr)
        external
        onlyOwner
    {
      _isExcluded[_addr] = true;
        }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
    buyBackEnabled = _enabled;
  }

  function setBuyBackLimit(uint256 _buybackLimit) public onlyOwner {
  buybackLimit = _buybackLimit;}

  function setBuyBackDivisor(uint256 _buybackDivisor) public onlyOwner {
  buybackDivisor = _buybackDivisor;}

  function setnumTokensSellDivisor(uint256 _numTokensSellDivisor) public onlyOwner {
  numTokensSellDivisor = _numTokensSellDivisor;
  }
  
  function setMaxTxDivisor(uint256 _maxTxDivisor) external onlyOwner{
      maxTxDivisor = _maxTxDivisor;
  }

  function rescueBNB() external onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }
  
  function setMarketingWallet(address payable newWallet) external onlyOwner{
      marketingAddress = newWallet;
  }

}