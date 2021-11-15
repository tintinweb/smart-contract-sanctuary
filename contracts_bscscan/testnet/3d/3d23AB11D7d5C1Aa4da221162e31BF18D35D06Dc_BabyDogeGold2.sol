pragma solidity ^0.8.0;

import "./contractHelper.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.

 
 */
contract BabyDogeGold2 is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private exchangePairs; //if exchangePair[address] = true then its a pair

    mapping(address => bool) private exchangeRouters; //if exchangeRouter[address] = true then its a router

    mapping(address => bool) private _isExcludedFromFee; // Excluded from fee

    address private BuyBackAddress = 0xc748673057861a797275CD8A068AbB95A902e8de;

    //need to write functions to be able to change these
    //Where marketing tax goes
    address private taxAddress;
    //where burn address goes
    address private burnAddress = 0x000000000000000000000000000000000000dEaD;
    //need to set up reflection address where all the reflections are going to be re-routed if they are not going to be reflected from here
    address private reflectionAddress;

    string private _name = "GoldTest2";
    string private _symbol = "Test2";
    uint8 private _decimals = 9;

    uint256 private _totalSupply = 100_000_000_000_000 * 10**_decimals;

    uint256 private _taxFee; // reflection
    uint256 private _liquidityFee; // liquidity
    uint256 private _burnFee; // burn
    uint256 private _buyBackFee; //buybackAddress tokens are bought

    //set Buy Fees
    uint256 private taxFeeBuySet; // reflection
    uint256 private liquidityFeeBuySet; // liquidity
    uint256 private buyBackFeeBuySet; //buybackAddress tokens are bought
    //set Sell Fees
    uint256 private taxFeeSellSet; // reflection
    uint256 private liquidityFeeSellSet; // liquidity
    uint256 private buyBackFeeSellSet; //buybackAddress tokens are bought

    bool noFeeTransfers = false;
    // pancakeswap
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Lock time after purchase.
    uint256 private timeLockAfterPurchase = 365 days;

    // Transaction Data tracker.
    struct TransactionLockData {
        uint256 time;
        uint256 amount;
    }
    uint256 private buyLockPercentage = 950;
    mapping(address => TransactionLockData) public transactionslock;

    //might not need if we send to a new contract
    bool public swapLiquifyEnabled = true;

    // Reentrancy, swap & liquify
    bool internal locked = false;
    // Reentrancy guard
    modifier noReentrant() {
        locked = true;
        _;
        locked = false;
    }

    address private _lpAddress;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[_msgSender()] = true;
        taxAddress = _msgSender();
        _lpAddress = _msgSender();

        emit Transfer(address(0), _msgSender(), _totalSupply);

        setBuyFees(100, 100, 100);
        setSellFees(500, 500, 4000);
    }

    /**
     * @dev creates the liquidity pool on pancakeswap (we are most likely going to change this to our own liquidity pool on our dex).
     *
     */
    function createlp() public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            // 0x10ED43C718714eb63d5aA57B78B54704E256024E // pancakeswap router mainnet
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1 // pancakeswap router testnet
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        addOrRemovePair(uniswapV2Pair, true);
        addOrRemoveRouter(address(uniswapV2Router), true);
    }

    /**
     * @dev Changes the token that will be bought back. (by default set to BabyDogeGold
     *
     * - `_token` is the address of the token address that we want to buyBack.
     */
    function changeBuyBackToken(address _token)
        public
        onlyOwner
        returns (address)
    {
        return BuyBackAddress = _token;
    }

    /**
     * @dev sets buyFees.
     */
    function buyFees() private {
        _taxFee = taxFeeBuySet;
        _liquidityFee = liquidityFeeBuySet;
        _burnFee = buyBackFeeBuySet;
        _buyBackFee = 0;
    }

    /**
     * @dev sets sellFees.
     *
     * - '_sender' is the senders address so that we can calculate the burnFee based on how much time/fee is left on the senders locked tokens.
     */
    function sellFees(address _sender) private {
        _taxFee = taxFeeSellSet;
        _liquidityFee = liquidityFeeSellSet;
        _buyBackFee = buyBackFeeSellSet;
        _burnFee = getVariableBurn(
            _taxFee,
            _liquidityFee,
            _buyBackFee,
            _sender
        );
    }

    /**
     * @dev Allows the owner to set buyFees percentages for 1% input 100
     *
     * - '_taxFeeSet' is the senders address so that we can calculate the burnFee based on how much time/fee is left on the senders locked tokens.
     * - '_liquidityFeeSet'
     * - '_buyBackFeeSet'
     *
     */
    function setBuyFees(
        uint256 _taxFeeSet,
        uint256 _liquidityFeeSet,
        uint256 _buyBackFeeSet
    ) public onlyOwner {
        taxFeeBuySet = _taxFeeSet;
        liquidityFeeBuySet = _liquidityFeeSet;
        buyBackFeeBuySet = _buyBackFeeSet;
    }

    /**
     * @dev Allows the owner to set sellFees percentages for 1% input 100
     *
     * - '_taxFeeSet' is the senders address so that we can calculate the burnFee based on how much time/fee is left on the senders locked tokens.
     * - '_liquidityFeeSet'
     * - '_buyBackFeeSet'
     *
     */
    function setSellFees(
        uint256 _taxFeeSet,
        uint256 _liquidityFeeSet,
        uint256 _buyBackFeeSet
    ) public onlyOwner {
        taxFeeSellSet = _taxFeeSet;
        liquidityFeeSellSet = _liquidityFeeSet;
        buyBackFeeSellSet = _buyBackFeeSet;
    }

    /**
     * @dev removes all fees.
     */

    function removeAllFee() private {
        if (
            _taxFee == 0 &&
            _liquidityFee == 0 &&
            _burnFee == 0 &&
            _buyBackFee == 0
        ) return;

        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
        _buyBackFee = 0;
    }

    /**
     * @dev Turns on and off fees from and to normal wallets
     */
    function setNoTransferFees(bool _option) public onlyOwner returns (bool) {
        return noFeeTransfers = _option;
    }

    /**
     * @dev Adds or removes a Router from the mapping of Pair Addresses
     *
     * - '_routerAddress' The address we would like to label as a router
     * - '_option' True would set the address as a router and false would remove it from the list of routers
     */
    function addOrRemovePair(address _pairAddress, bool _option)
        public
        onlyOwner
        returns (bool)
    {
        return exchangePairs[_pairAddress] = _option;
    }

    /**
     * @dev Adds or removes a Router from the mapping of Router Addresses
     *
     * - '_routerAddress' The address we would like to label as a router
     * - '_option' True would set the address as a router and false would remove it from the list of routers
     */
    function addOrRemoveRouter(address _routerAddress, bool _option)
        public
        onlyOwner
        returns (bool)
    {
        return exchangeRouters[_routerAddress] = _option;
    }

    /**
     * @dev Calculates the burn fee by taking the total fee remaining for the specific sender and subtracting the _taxFee, _liquidityFee, _buyBackFee, .
     *
     * - '_sender' is the senders address so that we can calculate the burnFee based on how much time/fee is left on the senders locked tokens.
     * - '_taxFee' is the current taxFee. (portion of fee that goes to Dev wallet)
     * - '_buyBackFee' is the current buy back fee. (portion of fee that goes to buying back tokens)
     * - '_liquidityFee' is the current liquidity fee. (portion of fee that goes to liquidity pool)
     */

    function getVariableBurn(
        uint256 _taxFee,
        uint256 _liquidityFee,
        uint256 _buyBackFee,
        address _sender
    ) private view returns (uint256) {
        TransactionLockData storage transactionlocked = transactionslock[
            _sender
        ];

        uint256 coolDownRemaining = transactionlocked.time.sub(block.timestamp);

        return
            coolDownRemaining.sub(_taxFee).sub(_liquidityFee).sub(_buyBackFee);
    }

    /**
     * @dev turns off and on fees for address
     *
     * - 'account' is address that is going to be effected.
     * - 'excluded' is the bool that will set the fees to be on or off.
     */
    function setExcludeFromFee(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = excluded;
    }

    /**
     * @dev Sets the timer/fee whenever theres a new purchase for each recipient
     *
     * - 'recipient' is address that is going to be effected.
     * - 'amount' is the amount being purchased
     */
    function purchaseCoolDown(address recipient, uint256 amount) internal {
        TransactionLockData storage transactionlocked = transactionslock[
            recipient
        ];
        // Check if wallet has prior transactions if
        if (transactionlocked.time == 0) {
            transactionlocked.time = block.timestamp.add(timeLockAfterPurchase);
            transactionlocked.amount = amount.mul(buyLockPercentage).div(10000);
        }
        // If wallet has prior transactions
        else {
            // Calculate how much time and lock is left
            uint256 coolDownRemaining = transactionlocked.time -
                block.timestamp;
            // If there is no cooldown, reset balance.
            if (coolDownRemaining == 0) {
                delete transactionslock[recipient];
            }
            // If there is cooldown calculate remainig locked.
            else {
                uint256 remainingPercentage = coolDownRemaining
                    .mul(10**9)
                    .div(timeLockAfterPurchase)
                    .mul(10000)
                    .div(10**9);

                transactionlocked.amount = transactionlocked
                    .amount
                    .mul(remainingPercentage)
                    .div(10000);
            }

            transactionlocked.time = block.timestamp.add(timeLockAfterPurchase);
            transactionlocked.amount = transactionlocked.amount.add(
                amount.mul(buyLockPercentage).div(10000)
            );
        }
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance.sub(amount));
        }

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(
                _msgSender(),
                spender,
                currentAllowance.sub(subtractedValue)
            );
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            _balances[sender] >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        _beforeTokenTransfer(sender, recipient, amount);
    }

    //take amount is tokens for lp fee + buybackBabyDoge Fee
    function swapAndLiquify(uint256 buyBackFee, uint256 liquidityFee)
        private
        noReentrant
    {
        uint256 toLiquify = liquidityFee;
        uint256 toBuyBack = buyBackFee;

        // Split the Token balance into halves

        uint256 halfForTokenLP = toLiquify.div(2);

        uint256 ethBalanceBeforeSwap = address(this).balance;

        // half of token Lp should be 1/16th the buyback amount
        uint256 totalToSwap = toBuyBack.add(halfForTokenLP);
        // Swap tokens for ETH
        swapTokensForEth(totalToSwap);

        // Get new ETH Balance
        uint256 ethRecivedFromSwap = address(this).balance.sub(
            ethBalanceBeforeSwap
        );
        uint256 ethToLiquidity = ethRecivedFromSwap.div(16);
        uint256 ethToBuyBack = ethRecivedFromSwap.sub(ethToLiquidity);
        // Add liquidity to Uniswap
        addLiquidity(halfForTokenLP, ethRecivedFromSwap);

        //with ethToBuyBack buy back some babydoge coin tokens
        if (buyBackFee > 0) swapEthForBabyDoge(ethToBuyBack);

        emit SwapAndLiquify(halfForTokenLP, ethRecivedFromSwap, halfForTokenLP);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the Uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapEthForBabyDoge(uint256 ethAmount) private {
        // Generate the Uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = BuyBackAddress;

        _approve(address(this), address(uniswapV2Router), ethAmount);

        // Swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens(
            0,
            path,
            reflectionAddress,
            block.timestamp
        );
    }

    /** 
    @dev Will add liquidity to the liquidity pool from the BNB recieved after liquifiying tokens
     */
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _lpAddress,
            block.timestamp
        );
    }

    //Checks for included/excluded addresses
    //needs to also check if address is a smart contract

    // research Eliminate Contract from eliminating fees

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(
            _balances[from] >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (exchangePairs[to]) sellFees(from);
        if (exchangePairs[from]) {
            buyFees();
            purchaseCoolDown(to, amount);
        }
        if (exchangeRouters[to]) removeAllFee();
        if (exchangeRouters[from]) removeAllFee();

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            _transferStandard(from, to, amount); //no fees are taken out
        } else if (exchangePairs[from]) {
            _transferExchange(from, to, amount); //buy from to exchange - (take out small percent)
        } else if (exchangePairs[to]) {
            _transferExchange(from, to, amount); //sell to exchange - (take out large percent)
        } else {
            //check noFeeTransfers
            if (noFeeTransfers) {
                _transferStandard(from, to, amount);
            } else {
                sellFees(from);
                _transferExchange(from, to, amount);
            }
        }
    }

    /**
     * @dev This is the transfer that is being used between all wallets and exchanges
     */
    function _transferExchange(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (
            uint256 _taxFee,
            uint256 _liquidityFee,
            uint256 _buyBackFee,
            uint256 _burnFee,
            uint256 totalFees
        ) = getFeeValues(amount);

        amount = amount.sub(totalFees);
        _balances[sender] = _balances[sender].sub(amount);

        _balances[taxAddress] = _balances[taxAddress].add(_taxFee);
        _balances[burnAddress] = _balances[burnAddress].add(_burnFee);
        _balances[recipient] = _balances[recipient].add(amount);

        //buyback and liquidity Fee
        swapAndLiquify(_buyBackFee, _liquidityFee);

        emit Transfer(sender, taxAddress, _taxFee);
        emit Transfer(sender, burnAddress, _burnFee);
        emit Transfer(sender, recipient, amount);
        //get buy fees then do transfer
    }

    /**
     * @dev This is the transfer that is being used for normal transactions between users and exlcuded wallets
     */
    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 senderBalance = _balances[sender];

        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function getFeeValues(uint256 amount)
        private
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _taxFee = amount.mul(_taxFee).div(10000);
        uint256 _liquidityFee = amount.mul(_liquidityFee).div(10000);
        uint256 _buyBackFee = amount.mul(_buyBackFee).div(10000);
        uint256 _burnFee = amount.mul(_burnFee).div(10000);

        uint256 _totalFees = _taxFee.add(_liquidityFee).add(_buyBackFee).add(
            _burnFee
        );

        return (_taxFee, _liquidityFee, _buyBackFee, _burnFee, _totalFees);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

