/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

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
        return 18;
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

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
}

interface IPrivateInvestors{
    function distributeTokens(uint256 amount) external;
}


contract iWin is ERC20, Ownable{
    using Address for address payable;
    
    IRouter public router;
    address public pair;
    
    bool private _liquidityMutex = false;
    bool public providingLiquidity = false;
    
    uint256 public tokenLiquidityThreshold = 200_000 * 10e18;
    uint256 public maxTxLimit = 500_000 * 10**18;
    uint256 public maxWalletLimit = 20_000_000 * 10**18;
    
    uint256 public minTokensToQualify;
    uint256 private _nonce;
    uint256 public winningNumber;
    uint256 public prizePercentage = 50;
    
    struct LotteryInfo {
        address lastWinner;
        uint256 lastPrize;
        uint256 lastWinTimestamp;
        uint256 lastRoll;
        uint256 lotteryThresholdAmt;
        bool enabled;
    }
    
    LotteryInfo public lotteryInfo;

    uint256 public genesis_block;
    
    address public marketingWallet = 0x8948473B44D02b7Db7BeD73547a6Fc22Df572753;
    address public devWallet = 0xB205fB92Fc27870EA54c3A28c9Bb0B546dC3A0Ea;
    address public privateInvestorsWallet = 0xAD017dAefDb8477B407d5819e5a7c36a68971BBD;
    address public lotteryWallet;
    address public NFTWallet = 0x31fD21d8C28c9595DE0683e5b678dfA1203aF7D1;
    
    struct Taxes {
        uint256 marketing;
        uint256 liquidity; 
        uint256 lottery;
        uint256 dev;
        uint256 privateInvestors;
        uint256 nft;
    }
    
    Taxes public taxes = Taxes(70, 10, 18, 12, 10, 0);
    Taxes public sellTaxes = Taxes(70, 10, 18, 12, 10, 0);
    
    mapping (address => bool) public exemptFee;
    mapping (address => bool) public isBlacklisted;
    mapping (address => bool) public allowedTransfer;
    
    modifier antiBot(address account){
        require(block.number > genesis_block + 2 || allowedTransfer[account], "Trading not enabled yet");
        _;
    }
    
    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }
    
    event LotteryAward(address winner, uint256 amount, uint time);
    
    constructor() ERC20("iWin", "iWin") {
        _mint(msg.sender, 1e9 * 10 ** decimals());
        exemptFee[msg.sender] = true;

        IRouter _router = IRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a koffeeSwap pair for this new token
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        lotteryWallet = address(this);
        exemptFee[address(this)] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[devWallet] = true;
        exemptFee[lotteryWallet] = true;
        exemptFee[NFTWallet] = true;
        exemptFee[privateInvestorsWallet] = true;
        
        allowedTransfer[address(this)] = true;
        allowedTransfer[pair] = true;
        allowedTransfer[marketingWallet] = true;
        allowedTransfer[devWallet] = true;
        allowedTransfer[lotteryWallet] = true;
        allowedTransfer[NFTWallet] = true;
        allowedTransfer[privateInvestorsWallet] = true;
        
        _approve(address(this), privateInvestorsWallet, totalSupply());
    }
    
    function approve(address spender, uint256 amount) public  override antiBot(msg.sender) returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override antiBot(sender) returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override antiBot(msg.sender) returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override antiBot(msg.sender) returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override antiBot(msg.sender) returns (bool)
    { 
      _transfer(msg.sender, recipient, amount);
      return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlacklisted[sender] && !isBlacklisted[recipient], "You can't transfer tokens");
        
        if(recipient == pair && genesis_block == 0) genesis_block = block.number;
        
        
        if(!exemptFee[sender] && !exemptFee[recipient] && !_liquidityMutex){
            require(amount <= maxTxLimit, "You are exceeding maxTxLimit");
            if(recipient != pair){
                require(balanceOf(recipient) + amount <= maxWalletLimit, "You are exceeding maxWalletLimit");
            }
        }
        
         ////////////////
        //   LOTTERY  //
       ////////////////
       
       if(!exemptFee[recipient] && lotteryInfo.enabled && amount >= lotteryInfo.lotteryThresholdAmt && sender == pair && block.timestamp >= lotteryInfo.lastWinTimestamp + 1 days){
           lottery(recipient);
       }
        uint256 feeswap;
        uint256 feesum;
        Taxes memory currentTaxes;

        if(!exemptFee[sender] && !exemptFee[recipient] && block.number <= genesis_block + 2) feesum = 990;
        
        //calculate fee
        else if(recipient == pair){
            feeswap = sellTaxes.liquidity + sellTaxes.marketing + sellTaxes.dev;
            feesum = feeswap + sellTaxes.nft + sellTaxes.lottery + sellTaxes.privateInvestors;
            currentTaxes = sellTaxes;
        }
        else{
            feeswap =  taxes.liquidity + taxes.marketing + taxes.dev;
            feesum = feeswap + taxes.nft + taxes.lottery + taxes.privateInvestors;
            currentTaxes = taxes;
        }
        uint256 fee = amount * feesum / 1000;

        //set fee to zero if fees in contract are handled or exempted
        if (_liquidityMutex || exemptFee[sender] || exemptFee[recipient]) fee = 0;

        //send fees if threshold has been reached
        //don't do this on buys, breaks swap
        if (providingLiquidity && sender != pair) handle_fees(feeswap, currentTaxes);

        //rest to recipient
        super._transfer(sender, recipient, amount - fee);

        //send the fee to the contract
        if (feeswap > 0) {
            uint256 feeAmount = amount * feeswap / 1000;
            _balances[address(this)] += feeAmount;
        }
        if (currentTaxes.privateInvestors > 0){
           IPrivateInvestors(privateInvestorsWallet).distributeTokens(amount * currentTaxes.privateInvestors / 1000);
        }
        if(currentTaxes.lottery > 0){
            _balances[lotteryWallet] += amount * currentTaxes.lottery / 1000;
        }
        if(currentTaxes.nft > 0){
            _balances[NFTWallet] += amount * currentTaxes.nft / 1000;
        }

    }

    function handle_fees(uint256 feeswap, Taxes memory swapTaxes) private mutexLock {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= tokenLiquidityThreshold) {
            if(tokenLiquidityThreshold > 1){
                contractBalance = tokenLiquidityThreshold;
            }

            // Split the contract balance into halves
            uint256 denominator = feeswap * 2;
            uint256 tokensToAddLiquidityWith = contractBalance * swapTaxes.liquidity / denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;
    
            uint256 initialBalance = address(this).balance;
    
            swapTokensForBNB(toSwap);
    
            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance= deltaBalance / (denominator - swapTaxes.liquidity);
            uint256 bnbToAddLiquidityWith = unitBalance * swapTaxes.liquidity;
    
            if(bnbToAddLiquidityWith > 0){
                // Add liquidity to pancake
                addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
            }
    
            uint256 marketingAmt = unitBalance * 2 * swapTaxes.marketing;
            if(marketingAmt > 0){
                payable(marketingWallet).sendValue(marketingAmt);
            }
            
            uint256 devAmt = unitBalance * 2 * swapTaxes.dev;
            if(devAmt > 0){
                payable(devWallet).sendValue(devAmt);
            }
        }
    }


    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);

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
            owner(),
            block.timestamp
        );
    }
    
    function getLotteryPool() external view returns(uint256){
        return balanceOf(lotteryWallet);
    }

    function updateLiquidityProvide(bool state) external onlyOwner {
        //update liquidity providing state
        providingLiquidity = state;
    }

    function updateLiquidityTreshhold(uint256 new_amount) external onlyOwner {
        //update the treshhold
        tokenLiquidityThreshold = new_amount;
    }

    function updateTaxes(Taxes memory newTaxes) external onlyOwner{
        taxes = newTaxes;
    }
    
    function updateSellTaxes(Taxes memory newSellTaxes) external onlyOwner{
        sellTaxes = newSellTaxes;
    }
    
    function updateMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet = newWallet;
    }
    
    function updateDevWallet(address newWallet) external onlyOwner{
        devWallet = newWallet;
    }
    
    function updateNFTWallet(address newWallet) external onlyOwner{
        NFTWallet = newWallet;
    }
    
    function updateLotteryWallet(address newWallet) external onlyOwner{
        lotteryWallet = newWallet;
    }
    
    function updatePrivateInvestorsWallet(address newWallet) external onlyOwner{
        privateInvestorsWallet = newWallet;
    }
    
    function updateMinTokensToQualify(uint256 amount) external onlyOwner{
        minTokensToQualify = amount * 10**18;
    }
    
    function updateIsBlacklisted(address account, bool state) external onlyOwner{
        isBlacklisted[account] = state;
    }
    
    function updateAllowedTransfer(address account, bool state) external onlyOwner{
        allowedTransfer[account] = state;
    }
    
    function updateLotteryEnabled(bool state) external onlyOwner{
        lotteryInfo.enabled = state;
    }

    function updateExemptFee(address _address, bool state) external onlyOwner {
        exemptFee[_address] = state;
    }
    
    function updateMaxTxLimit(uint256 amount) external onlyOwner{
        maxTxLimit = amount * 10**18;
    }
    
    function updatePrizePercentage(uint256 amount) external onlyOwner{
        prizePercentage = amount;
    }
    
    function updateLotteryThresholdAmt(uint256 amount) external onlyOwner{
        lotteryInfo.lotteryThresholdAmt = amount * 10**18;
    }
    
    function updateMaxWalletlimit(uint256 amount) external onlyOwner{
        maxWalletLimit = amount * 10**18;
    }
    
    function updateWinningnumber(uint256 amount) external onlyOwner{
        winningNumber = amount;
    }


    // fallbacks
    receive() external payable {}
    
    function random() private returns (uint) {
        uint r = uint(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce))) % winningNumber);
        r = r + 1;
        _nonce++;
        return r;
    }
    
    function lottery(address account) private returns(bool){
        uint256 _random = random();
        lotteryInfo.lastRoll = _random;
        
        if(_random != winningNumber) return false;
        else{
            lotteryInfo.lastWinTimestamp = block.timestamp;
            lotteryInfo.lastWinner = account;
                
            uint256 _lotteryAmount = _balances[lotteryWallet] * prizePercentage / 100;
    
            _balances[account] += _lotteryAmount; 
            _balances[lotteryWallet] -= _lotteryAmount;
            lotteryInfo.lastPrize = _lotteryAmount;
            
            emit LotteryAward(account, _lotteryAmount, block.timestamp);
            emit Transfer(lotteryWallet, account, _lotteryAmount);
            return true;
        }
    }
    
}