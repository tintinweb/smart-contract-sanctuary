pragma solidity ^0.8.0;

import "./interface/IBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

/*
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░██████╗░██╗░░░██╗██╗░█████╗░██╗░░██╗██████╗░██████╗░░█████╗░░██╗░░░░░░░██╗░
░██╔═══██╗██║░░░██║██║██╔══██╗██║░██╔╝██╔══██╗██╔══██╗██╔══██╗░██║░░██╗░░██║░
░██║██╗██║██║░░░██║██║██║░░╚═╝█████═╝░██║░░██║██████╔╝███████║░╚██╗████╗██╔╝░
░╚██████╔╝██║░░░██║██║██║░░██╗██╔═██╗░██║░░██║██╔══██╗██╔══██║░░████╔═████║░░
░░╚═██╔═╝░╚██████╔╝██║╚█████╔╝██║░╚██╗██████╔╝██║░░██║██║░░██║░░╚██╔╝░╚██╔╝░░
░░░░╚═╝░░░░╚═════╝░╚═╝░╚════╝░╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░.            ░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░     ░.  &░░░░░░░/  ,░░░░░  ░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░    ░.  ░░       *░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░. ░░░░░░░░    *░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░* ░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░,               ░░░░░░░░░
░░░░░░░░░░░░░░(  ░░░(░░░░░░░░░░░░░░░░░░░░░░░░/                          ░░░░░
░░░░░░░░░░░  ░░░░░░░░░░░░░░░░░░░░░░░░░░░&                                  ░░
░░░░░░░░& ░░░░░░░░░#░░░░░░░░░░░░░░░░░                                       ░
░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░#&                                         .░░
░░░░░░ ░░░░░░░░░░░░          #.                        &░░░░░░░░░░░░░░░░░░░░░
░░░░░ ░░░░░░░░░░░░░░*      ░                  *░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░ ░░░░░░░░░░░░░░░░░░░(              &░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░*.░░░░░░░░░░░░░░░░           *░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░ %░░░░░░░░░░░░         ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░.&░░░░#       &░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░


                               WELCOME COWBOYS

                GRAB A WHISKY, TAKE A SEAT, AND ENJOY THE RIDE

*/

contract QuickDraw is IBEP20, Ownable {

    using Address for address;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 BNBReceived,
        uint256 tokensIntoLiqudity
    );
    event MarketingWalletPaid(uint256 tokensSwapped);
    event QuickDrawPayout(address indexed recipient, uint256 bnbAmount, uint256 bidAmount);
    event GoldRushTriggered(uint256 indexed id, uint256 minBuy, uint256 goldRushHoldings, uint8 iterations);
    event GoldRushEnded(uint256 indexed id);
    event GoldRushPayout(uint256 indexed id, address indexed recipient, uint256 amount);

    mapping (address => uint256) public goldRushWinningsPerAccount;

    mapping (address => uint256) public quickDrawWinningsPerAccount;

    mapping (address => uint256) private _rOwned;

    mapping (address => uint256) private _tOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcludedFromMaxHold;

    mapping (address => bool) private _isExcluded;

    mapping (address => uint256) private _lastGoldRushPerAccount;

    address[] private _excluded;

    // Max 256 bit integer
    uint256 private constant MAX = ~uint256(0);

    // The total supply of tokens
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;

    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;

    string private _name = "DontApe";
    string private _symbol = "DAPE";
    uint8 private _decimals = 9;

    address private immutable _owner;

    uint256 private _reflectionFee = 4;
    uint256 private _liquidityFee = 2;
    uint256 private _marketingFee = 2;
    uint256 private _quickDrawfee = 5;
    uint256 private _goldRushFee = 2;

    uint256 public goldRushHoldings = 0;
    uint8 public goldRushIterations;
    uint8 public goldRushIterationsLeft;
    uint256 public minGoldRushBuy;
    uint256 public currentGoldRush = 0;
    uint256 public goldRushCutPerUser;
    bool public goldRushTriggered = false;

    bool public quickDrawEnabled = true;

    address private _marketingWallet;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    uint256 public _maxTxAmount = 1000000 * 10**6 * 10**9;
    uint256 public _maxHoldAmount = 15000000 * 10**6 * 10**9;

    address private _highestBidder;
    uint256 private _highestBid = 0;

    uint256 private _numTokensSellToAddToLiquidity = 100000 * 10**6 * 10**9;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address _uniswapV2RouterAddr, address marketingWallet) {

        _marketingWallet = marketingWallet;

        _owner = msg.sender;
        _rOwned[msg.sender] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddr);

         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // Eclude functional accounts from max hold
        _isExcludedFromMaxHold[owner()] = true;
        _isExcludedFromMaxHold[address(this)] = true;
        _isExcludedFromMaxHold[address(0)] = true;

        // The contract shouldn't earn reflections
        _isExcluded[address(this)] = true;

        emit Transfer(address(0), msg.sender, _tTotal);

    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function getOwner() public view virtual override returns (address) {
        return _owner;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    /**
     * @notice Update the marketing wallet (in case of a breach)
     *
     * @param wallet The address of the new marketing wallet
     */
    function updateMarketingWallet(address wallet) external onlyOwner() {
        _marketingWallet = wallet;
        _isExcludedFromMaxHold[wallet] = true;
    }

    /**
     * @notice Trigger a gold rush event
     *
     * @param _minGoldRushBuy The minimum amount of tokens a user has to buy to get a cut of the gold rush pot
     * @param iterations The number of users to receive a cut of the gold rush pot
     */
    function triggerGoldRush(uint256 _minGoldRushBuy, uint8 iterations) external onlyOwner() {

        require(!goldRushTriggered, "Gold rush already triggered!");
        require(goldRushHoldings > 0, "No gold rush rewards!");

        currentGoldRush++;
        goldRushTriggered = true;
        minGoldRushBuy = _minGoldRushBuy;
        goldRushCutPerUser = goldRushHoldings / iterations;

        goldRushIterationsLeft = iterations;
        goldRushIterations = iterations;

        emit GoldRushTriggered(currentGoldRush, minGoldRushBuy, goldRushHoldings, iterations);

    }

    /**
     * @notice Exclude an account from the max hold restriction
     *
     * @param account The address of the account to exclude
     */
    function excludeFromMaxHold(address account) external onlyOwner() {
        _isExcludedFromMaxHold[account] = true;
    }

    /**
     * @notice Toggles the gold rush feature (in case of an error)
     *
     * @param value A boolean representing if gold rush is enabled or not
     */
    function setGoldRushEnabled(bool value) external onlyOwner() {
        goldRushTriggered = value;
    }

    /**
     * @notice Toggles the quick draw feature (in case of an error)
     *
     * @param value A boolean representing if quick draw is enabled or not
     */
    function setQuickDrawEnabled(bool value) external onlyOwner() {
        quickDrawEnabled = value;
    }

    /**
     * @notice Calculates how many standard tokens a specified amount of reflection tokens are worth
     *
     * @param rAmount the amount of reflection tokens
     *
     * @return the value of rAmount in standard tokens
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {

        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;

    }

    /**
     * @notice Exclude an address from reflection (Can only be executed by the contract owner)
     * @dev Excludes the address from reflection and converts their reflection tokens into standard tokens
     *
     * @param account the address of the account to exclude
     */
    function excludeFromReward(address account) public onlyOwner() {

        if (_rOwned[account] > 0)
            _tOwned[account] = tokenFromReflection(_rOwned[account]);

        _isExcluded[account] = true;
        _excluded.push(account);

    }

    /**
     * @notice Include an address in reflection (Can only be executed by the contract owner)
     * @dev Includes the address in reflection, sets their standard tokens to 0
     *
     * @param account the address of the account to include
     */
    function includeInReward(address account) external onlyOwner() {

        require(account != address(this));

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                // Let the last person in the list take their place and pop them off the end to avoid dupes
                _excluded[i] = _excluded[_excluded.length - 1];
                _excluded.pop();

                // Remove standard tokens (As these are only used for excluded accounts)
                _tOwned[account] = 0;

                _isExcluded[account] = false;
                break;
            }
        }

    }

    /**
     * @notice Exclude an address from transaction fees (Can only be executed by the contract owner)
     *
     * @param account the address of the account to exclude
     */
    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    /**
     * @notice Include an address in transaction fees (Can only be executed by the contract owner)
     *
     * @param account the address of the account to include
     */
    function includeInFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @notice Toggle liquidity generation
     *
     * @param value A boolean representing if liquidity generation is enabled or not
     */
    function setSwapAndLiquifyEnabled(bool value) public onlyOwner() {
        swapAndLiquifyEnabled = value;
        emit SwapAndLiquifyEnabledUpdated(value);
    }

    /**
     * @notice Exclude an account from taxes
     *
     * @param account The account to exclude from taxes
     */
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

     //to recieve BNB from uniswapV2Router when swaping
    receive() external payable {}

    function _getValues(uint256 tAmount, uint256 tFee) private view returns (uint256, uint256, uint256) {

        uint256 currentRate = _getRate();

        uint256 tTransferAmount = tAmount - tFee; // The amount of standard tokens the recipient will recieve
        uint256 rTransferAmount = tTransferAmount * currentRate; // The amount of reflection tokens the recipient will recieve
        uint256 rAmount = tAmount * currentRate; // The amount of reflection tokens the recipient is sending

        return (rAmount, rTransferAmount, tTransferAmount);

    }

    /**
     * @notice Calculates the amount of reflection tokens in supply per token in supply
     *
     * @return The conversion rate of reflection tokens to standard tokens
     */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {

        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }

        if (rSupply < (_rTotal / _tTotal)) return (_rTotal, _tTotal);

        return (rSupply, tSupply);

    }

    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    /**
     * @notice Calculate a percentage cut of an amount
     *
     * @param amount The amount of tokensSwapped
     * @param fee The fee in % i.e. 5% would be 5
     * @return The percentage amount of the tokens
     */
    function _calculateFee(uint256 amount, uint256 fee) internal pure returns (uint256) {
        return (amount * fee) / 100;
    }

    /**
     * @notice Transfer tokens between accounts, and triger a liquidity generation event if the threshold is met
     *
     * @param from The account sending tokens
     * @param to The acount receiving tokens
     * @param amount The amount of tokens being sent
     */
    function _transfer(address from, address to, uint256 amount) private {

        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = 0;
        if(goldRushHoldings <= balanceOf(address(this))) {
            contractTokenBalance = balanceOf(address(this)) - goldRushHoldings;
        }

        if (contractTokenBalance >= _maxTxAmount)
            contractTokenBalance = _maxTxAmount;

        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;

        if (overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            //add liquidity
            _swapAndLiquify(contractTokenBalance);
        }

        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount);

    }

    /**
     * @notice Sell tokens into BNB and pair with quickdraw for liquidity and pay marketing wallet
     *
     * @param contractTokenBalance the amount of stadnard tokens to be used for liquidity
     */
    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        uint256 liquidityCut = (_liquidityFee * contractTokenBalance) / (_liquidityFee + _marketingFee);
        uint256 marketingCut = contractTokenBalance - liquidityCut;

        // split the contract balance into halves
        uint256 half = liquidityCut / 2;
        uint256 otherHalf = liquidityCut - half;

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB for liquidity
        _swapTokensForBNB(half, address(this));

        // Send marketing share to the wallet
        _swapTokensForBNB(marketingCut, _marketingWallet);

        emit MarketingWalletPaid(marketingCut);

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);

    }

    /**
     * @notice Sell tokens into BNB and send to a specified address
     *
     * @param tokenAmount The amount of qdraw to sell
     * @param to The address of the recipient
     */
    function _swapTokensForBNB(uint256 tokenAmount, address to) private {

        // generate the uniswap pair path of token -> wBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            to,
            block.timestamp
        );

    }

    /**
     * @notice Add liquidity to the token on pancake swap
     *
     * @param tokenAmount The amount of qdraw to pair
     * @param BNBAmount The amount of BNB to pair
     */
    function _addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

    }

    /**
     * @notice Transfers qdraw from sender to recipient and takes the relevant taxes
     *
     * @param sender The sender of the currency
     * @param recipient The recipient of the currency
     * @param amount the amount of stadnard tokens to be transferred
     */
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {

        // if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = !(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]);

        uint256 liquidityFee = 0;
        uint256 reflectionFee = 0;
        uint256 quickDrawFee = 0;
        uint256 marketingFee = 0;
        uint256 goldRushFee = 0;

        uint256 goldRushWinnings = 0;

        if (takeFee) {

            // Flat fees on every transaction
            liquidityFee = _calculateFee(amount, _liquidityFee);
            reflectionFee = _calculateFee(amount, _reflectionFee);
            marketingFee = _calculateFee(amount, _marketingFee);

            // If we're not in a gold rush, take a gold rush tax
            if (!goldRushTriggered) {
                goldRushFee = _calculateFee(amount, _goldRushFee);
                _takeGoldRushFee(goldRushFee);
            }

            // Check if this is a sell and if so, transfer 5% to the previous highest buyer since the last sell
            if (recipient == uniswapV2Pair && _highestBidder != address(0) && quickDrawEnabled) {
                quickDrawFee = _calculateFee(amount, _quickDrawfee);
                _quickDraw(quickDrawFee);
            }

            _takeLiquidityAndMarketing(liquidityFee + marketingFee);
            _reflectFee(reflectionFee);

        }

        // Check if the transaction is a buy (make sure the recipient isn't excluded from rewards)
        if (sender == uniswapV2Pair && !_isExcluded[recipient]) {

            // If the gold rush is triggered and the user is buying above the set threshold and they have not participated in the current goldrush
            if (goldRushTriggered && _lastGoldRushPerAccount[recipient] != currentGoldRush && amount > minGoldRushBuy) {
                goldRushWinnings = _payGoldRushWinnings(recipient);
            }

            //  If the buy is larger than or equal to the previous buy since the last sell
            if (amount >= _highestBid) {
                _highestBidder = recipient;
                _highestBid = amount;
            }

        }

        // Transfer logic

        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount) = _getValues(
            amount,
            liquidityFee + reflectionFee + quickDrawFee + marketingFee + goldRushFee
        );

        // Enforce max hold
        require(!(!_isExcludedFromMaxHold[recipient] && (balanceOf(recipient) + tTransferAmount)  > _maxHoldAmount), "Account balance over maximum hold!");

        if (_isExcluded[sender])
            _tOwned[sender] -= amount;

        if (_isExcluded[recipient])
            _tOwned[recipient] += tTransferAmount + goldRushWinnings;

        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount + (goldRushWinnings * _getRate());

        emit Transfer(sender, recipient, tTransferAmount);

    }

    /**
     * @notice Reduce the total of reflection tokens by the fee in stanard tokens converted into reflection tokens and increase the _tFeeTotal count by the relative amount in standard tokens
     *
     * @param fee the amount of stadnard tokens to be burned
     */
    function _reflectFee(uint256 fee) private {
        _rTotal -= fee * _getRate();
        _tFeeTotal += fee;
    }

    /**
     * @notice Add the taxed liquidity to this contract
     *
     * @param tFee the amount of stadnard tokens to be be added to the contract
     */
    function _takeLiquidityAndMarketing(uint256 tFee) private {
        _rOwned[address(this)] += tFee * _getRate();
        _tOwned[address(this)] += tFee;
    }

    /**
     * @notice Sends BNB to the account who bought the highest amount of tokens since the last sell
     *
     * @dev lockTheSwap is used to stop the bnb sell of qdraw triggering liq gen and selling the qdraw tokens
     *
     * @param quickDrawFee the amount of stadnard tokens to be sold into BNB and sent to the highest bidder
     */
    function _quickDraw(uint256 quickDrawFee) private lockTheSwap {

        // Take tax, sell into bnb and transfer to the highest bidder since the last sell

        // Transfer the taxed tokens to this contract
        _rOwned[address(this)] += quickDrawFee * _getRate();
        _tOwned[address(this)] += quickDrawFee;

        uint256 balanceBefore = _highestBidder.balance;

        // Sell tokens into bnb and transfer to the winner
        _swapTokensForBNB(quickDrawFee, _highestBidder);

        quickDrawWinningsPerAccount[_highestBidder] += quickDrawFee;

        emit QuickDrawPayout(_highestBidder, _highestBidder.balance - balanceBefore, _highestBid);

        _highestBid = 0;

    }

    /**
     * @notice Add the gold rush fee to the contract's balance
     *
     * @param goldRushFee the amount of stadnard tokens to be added to the contract's balance
     */
    function _takeGoldRushFee(uint256 goldRushFee) private {
        goldRushHoldings += goldRushFee;
        // Transfer the taxed tokens to this contract
        _rOwned[address(this)] += goldRushFee * _getRate();
        _tOwned[address(this)] += goldRushFee;
    }

    /**
     * @notice Calculate the amount of gold rush tokens the recipient has earned
     *
     * @param recipient The winner of the gold rush
     * @return goldRushWinnings The amount of standard tokens the recipient has won
     */
    function _payGoldRushWinnings(address recipient) private returns (uint256) {

        // Make sure the recipient can't win the same gold rush again
        _lastGoldRushPerAccount[recipient] = currentGoldRush;

        // Subtract the tokens from the contract's wallet
        _rOwned[address(this)] -= goldRushCutPerUser * _getRate();
        _tOwned[address(this)] -= goldRushCutPerUser;

        goldRushIterationsLeft--;

        if (goldRushCutPerUser > goldRushHoldings) {
            goldRushCutPerUser = goldRushHoldings;
        }

        goldRushHoldings -= goldRushCutPerUser;

        goldRushWinningsPerAccount[recipient] += goldRushCutPerUser;

        emit GoldRushPayout(currentGoldRush, recipient, goldRushCutPerUser);

        // When we've sent out all of the winnings, disable the goldrush
        if (goldRushIterationsLeft == 0 || goldRushHoldings == 0) {
            goldRushTriggered = false;
            goldRushIterationsLeft = 0;

            emit GoldRushEnded(currentGoldRush);
        }

        return goldRushCutPerUser;

    }

}

pragma solidity ^0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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