/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// File: contracts/IUniswapV2Router02.sol


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

// File: contracts/IUniswapV2Factory.sol


pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// File: contracts/IBEP20.sol


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

// File: contracts/SafeMath.sol


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

// File: contracts/Context.sol


pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// File: contracts/Ownable.sol


pragma solidity ^0.8.4;


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

// File: contracts/Solidium.sol


/** SOLIDIUM Features

 SYMBOL:     $SOLIDIUM
 
 TOT SUPPLY: 1,000,000,000
 
 TAX SETUP:
 -  SELLING: 3%
 -  BUYING:  2%
 
 BUYING TAX DISTRIBUTION:
 -  DEV WALLET:      0.5%
 -  LIQUIDITY POOL:  1.5%
   INFO:
   -  DURATION: FOREVER
   -  IS % VARIABLE: YES
      - HOW:
        -  DEV WALLET:           0% - 0.5%
        -  LIQUIDITY POOL:       0% - 2%
        TOTAL MAX COMBINED TAX:  2%
   -  SWICHED: NO

 SELLING TAX DISTRIBUTION:
 -  DEV WALLET:      1%
 -  BUYBACK WALLET:  1%
 -  LIQUIDITY POOL:  1%
   INFO:
   -  DURATION: FOREVER
   -  IS % VARIABLE: YES
      - HOW:
        -  DEV WALLET:           0% - 1%
        -  BUYBACK WALLET:       0% - 1%
        -  LIQUIDITY POOL:       1% - 2%
        TOTAL MAX COMBINED TAX:  3%
   -  SWICHED: NO

 MAX SELL AMOUNT: TOT SUPPLY / 0.25%
 - INTERVAL: 24 HOURS
 - DURATION: 9 MONTHS
 - IS % AMOUNT VARIABLE: NO
 - KILL SWICHED: YES
   - HOW: CAN BE SWITCHED OFF ONLY, ONCE TURNED OFF CAN NEVER BE TURNED BACK ON

*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract SOLIDIUM is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _tokenSold;

    mapping (address => uint256) private _startTime;
    mapping (address => uint256) private _blockTime;

    uint256 public _maxSoldAmount;
    uint256 private _tTotal;
    uint8 private _decimals;
    string private _symbol;
    string private _name;  
    uint256 public _taxFee;
    uint256 public _buyTax;
    uint256 public _sellTax;
    uint256 public _minTaxWalletBalance;
    uint256 public _maxTaxWalletBalance;

    address public uniswapV2Pair;

    // Debug (temp)
    string public _DEBUG;

    // Allocation
    address payable public _rewardsWallet;
    address payable public _marketMakerWallet;
    
    // Business
    address payable public _teamWallet;
    address payable public _developmentWallet;
    address payable public _marketingWallet;
    address payable public _operationsWallet;
    address payable public _legalWallet;
    address payable public _buybackWallet;

    bool public inSwap = false;
    bool public swapEnabled = false;

    IUniswapV2Router02 public uniswapV2Router;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    /**
    * @dev Initialize params for tokenomics
    */

    constructor() {
        _name = unicode"SOLIDIUM";
        _symbol = "SDM";
        _decimals = 18;
        _tTotal = 1000000000 * 10**18;
        _balances[msg.sender] = _tTotal;    
        _taxFee = 300;
        _sellTax = 300;
        _buyTax = 200;
        _minTaxWalletBalance = 10 * 10**18;
        _maxTaxWalletBalance = 20 * 10**18;
        _maxSoldAmount = 2.5 * 10**6 * 10**18;
        _DEBUG = "foo";

        // Allocation
        _rewardsWallet = payable(0x62240f61DAFe242B4c8394f2aBA7da400E786435);
        _marketMakerWallet = payable(0xd5264E6f382dE2865697364aca7e237bD0365f0F);
        
        // Project Wallets
        _teamWallet = payable(0x6aD90B159E61380bc5071fefCe735A59928e493C);
        _developmentWallet = payable(0xA1aDb86E6a64f702aF79877d7FF33DfC6aA2dfa7);
        _marketingWallet = payable(0x1A13D7F288350661d907D40CA90c5FF78bE2b46E);
        _operationsWallet = payable(0x9fe25Ea769C6F119441466FDCf8Bb6347b466121);
        _legalWallet = payable(0x643F5b61bd58dA24C9c5e6fA9a6C7acf5b715380);
        _buybackWallet = payable(0x5Da6Ec38831F43d287Ab7FE5127077bf666b0a3d);


        // BSC MainNet router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;


        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamWallet] = true;
        _isExcludedFromFee[_developmentWallet] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[_operationsWallet] = true;
        _isExcludedFromFee[_legalWallet] = true;
        _isExcludedFromFee[_buybackWallet] = true;
        _isExcludedFromFee[_rewardsWallet] = true;
        _isExcludedFromFee[_marketMakerWallet] = true;

        emit Transfer(address(0), msg.sender, _tTotal);
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
    * @dev Returns debug string.
    */

    function debug_string() public view returns (string memory) {
        return _DEBUG;
    }

    /**
    * @dev See {BEP20-totalSupply}.
    */

    function totalSupply() external override view returns (uint256) {
        return _tTotal;
    }

    /**
    * @dev See {BEP20-balanceOf}.
    */

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

    function _transfer(
          address from, 
          address to, 
          uint256 amount
    ) internal {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (!inSwap && swapEnabled){
            // SELLS
            if (to == uniswapV2Pair){

                _DEBUG = "sell";
                
                // Set Taxes
                setTaxFee(_sellTax);
                
                // Anti dumping feature
                //antiDump(from, amount);

                if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                    setTaxFee(0);
                }
            // BUYS
            } else if (from == uniswapV2Pair){
                _DEBUG = "buy";

                // Set Taxes
                setTaxFee(_buyTax);
                
                if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                    setTaxFee(0);
                }
            } else {
                _DEBUG = "else";
                setTaxFee(0);
            }
            // Send taxes to pool and dev
            taxDistributor();
            
            // Carrout the swap/transfer
            _transferStandard(from, to, amount);
        }
    }
    
    /*
    Once swap is activated it cannot be turned off. This will allow 
    team to setup pool without price flux

    */
    function activateSwap() external onlyOwner {
        swapEnabled = true;
    }

    function setTaxFee(uint256 fee) private {
        require(fee <= 300, "Tax fee too high");
        _taxFee = fee;
    }

    function setBuyTax(uint256 fee) external onlyOwner {
        require(fee <= 200, "Tax fee too high");
        _buyTax = fee;
    }

    function setSellTax(uint256 fee) external onlyOwner {
        require(fee <= 300, "Tax fee too high");
        _sellTax = fee;
    }

    function antiDump(address from, uint256 amount) private {
        // Anti dumping feature
        if(_tokenSold[from] == 0){
            _startTime[from] = block.timestamp;
        }
        
        // How many tokens have you sold before, plus the amount you want to sell?
        _tokenSold[from] = _tokenSold[from] + amount;

        if( block.timestamp < _startTime[from] + (1 days)){
            require(_tokenSold[from] <= _maxSoldAmount, "Sold amount exceeds the maxTxAmount.");
        } else {
            _startTime[from] = block.timestamp;
            _tokenSold[from] = 0;
        }
    
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

    function taxDistributor() private lockTheSwap {
        /** On each trade empty the tax wallet and distribute
        *
        */
        // Check if tax wallet has at least the minimum allowable send balance
        uint256 initialBalance = balanceOf(address(this));
        if(initialBalance > _minTaxWalletBalance){
            // Tokens for the pool
            uint256 liquidityTokens = initialBalance.div(4); 
            // Tokens for the dev team wallets
            uint256 devTokens = initialBalance - liquidityTokens; // 2.25%

            // Swap tokens for BNB and credit tax wallet 
            swapTokensForEth(devTokens);

            // Get new balance of tax wallet
            uint256 newBalance = balanceOf(address(this));
            uint256 diffBalance = newBalance - initialBalance;

            // Calculate BNB amount for liquidity pool
            uint256 liquidityCapacity = diffBalance.div(3);

            // Send TOKEN and BNB to the pool
            addLiqudity(liquidityTokens, liquidityCapacity);

            // Move BNB from tax wallet to dev wallets 
            uint256 teamCapacity = diffBalance - liquidityCapacity;    
            uint256 teamBNB = teamCapacity.mul(2).div(3);
            _teamWallet.transfer(teamBNB);
            uint256 buybackBNB = teamCapacity - teamBNB;
            _buybackWallet.transfer(buybackBNB);
        }
    }

    /**
    * @dev Swap tokens to bnb
    */

    function swapTokensForEth(uint256 tokenAmount) private{
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    /**
    * @dev Add SOLIDIUM token and bnb as same ratio on pancakeswap router
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

    /** Moving tokens from wallet to wallet
    *
    */
    function _transferStandard(address sender, address recipient, uint256 amount) private {
        // Calculate fee from amount
        uint256 fee = amount.mul(_taxFee).div(10000);
        
        // Get the senders wallet balance for this token
        uint256 senderBalance = _balances[sender];
        
        // Check user has correct amount of funds to make transaction
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        
        // Update sender balance
        _balances[sender] = senderBalance - amount;
        
        // Remove fee from the amount to be transfered
        uint256 amountnew = amount - fee;
        
        // Update recipient balance
        _balances[recipient] += (amountnew);
        
        // Events
        // Send fee to contract address
        if (fee>0) {
            _balances[address(this)] += (fee);
            emit Transfer(sender, address(this), fee);
        }
        
        // Send remaining amount to recipient
        emit Transfer(sender, recipient, amountnew);
    }

    /**
    * @dev set Max sold amount
    */

    function _setMaxSoldAmount(uint256 maxvalue) external onlyOwner {
        _maxSoldAmount = maxvalue;
    }

    /**
    * @dev set min or max balance for transferring from tax wallet to pool
           required to avoid front run of bots.
    */

    function _setMinBalance(uint256 minValue) external onlyOwner {
        _minTaxWalletBalance = minValue;
    }
    function _setMaxBalance(uint256 maxValue) external onlyOwner {
        _maxTaxWalletBalance = maxValue;
    }

        receive() external payable {}
}