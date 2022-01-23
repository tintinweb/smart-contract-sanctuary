// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Context.sol";
import "./IERC20Metadata.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./interfaces.sol";

contract MOONMOON is Context, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    address public marketingAddress;
    address public lotteryAddress; 
    address public NFTAppAddress;
    address public uniswapV2Pair;
    address[] private _excludedFromReward;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 150_000_000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public swapTokensAtAmount = 100_000 * 10**9;

    string private constant _name = "Moon Moon INU";
    string private constant _symbol = "MOON";
    uint8 private constant _decimals = 9;

    bool private swapping;
    bool public swapEnabled;

    IUniswapV2Router02 public uniswapV2Router;

    struct feeRateStruct {
        uint256 reflection;
        uint256 liquidity;
        uint256 marketing;
        uint256 lottery;
        uint256 nftApp;
    }

    feeRateStruct public feeRates = feeRateStruct(
        {
            reflection: 200,
            liquidity: 300,
            marketing: 400,
            lottery: 200,
            nftApp: 200
        }
    );

    struct TotFeesPaidStruct{
        uint256 reflection;
        uint256 liquidity;
        uint256 marketing;
        uint256 lottery;
        uint256 nftApp;
    }

    TotFeesPaidStruct public totalFeesPaid;

    struct valuesFromGetValues{
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflection;
        uint256 rLiquidity;
        uint256 rMarketing;
        uint256 rLottery;
        uint256 rNFTApp;
        uint256 tTransferAmount;
        uint256 tReflection;
        uint256 tLiquidity;
        uint256 tMarketing;
        uint256 tLottery;
        uint256 tNFTApp;
    }

    event FeesChanged();

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 9. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address _router, address _marketingAddress, address _lotteryAddress, address _NFTAppAddress) {
        _rOwned[_msgSender()] = _rTotal;

        uniswapV2Router = IUniswapV2Router02(_router);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        marketingAddress = _marketingAddress;
        lotteryAddress = _lotteryAddress; 
        NFTAppAddress= _NFTAppAddress;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }


    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
    function allowance(address account, address spender) public view virtual override returns (uint256) {
        return _allowances[account][spender];
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
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `account` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address account, address spender, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender),"ERC20: transfer amount exceeds balance");


        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(!swapping && swapEnabled && canSwap && sender != uniswapV2Pair && balanceOf(uniswapV2Pair) > 0) {
            swapAndLiquify(swapTokensAtAmount);
        } 
        
        _tokenTransfer(sender, recipient, amount, !(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]));
    }

    /**
     * @dev Sets Marketing Address
     */
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    /**
     * @dev Sets Lottery Address
     */
    function setLotteryAddress(address _lotteryAddress) external onlyOwner {
        lotteryAddress = _lotteryAddress;
    }

    /**
     * @dev Sets NFT and App Distribution Contract Address
     */
    function setNFTAppAddress(address _NFTAppAddress) external onlyOwner {
        NFTAppAddress = _NFTAppAddress;
    }

    /**
     * @dev Calculates percentage with two decimal support.
     */    
    function percent(uint256 amount, uint256 fraction) public virtual pure returns(uint256) {
        return ((amount).mul(fraction)).div(10000);
    }

    /**
     * @dev Setting account as excluded from fee.
     */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    /**
     * @dev Setting account as included in fee.
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @dev Returns account is excluded from fee or not.
     */
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    /**
     * @dev Returns account is excluded from reward or not.
     */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    /**
     * @dev Setting fee rates
     * Total tax should be below or equal to 14%
     */
    function setFeeRates(
        uint256 _reflection, 
        uint256 _liquidity, 
        uint256 _marketing, 
        uint256 _lottery, 
        uint256 _nftApp
        ) external onlyOwner {
        require(_reflection.add(_liquidity).add(_marketing).add(_lottery).add(_nftApp) <= 1400, 
            "Tax above 14%");
        feeRates.reflection = _reflection;
        feeRates.liquidity = _liquidity;
        feeRates.marketing = _marketing;
        feeRates.lottery = _lottery;
        feeRates.nftApp = _nftApp;

        emit FeesChanged();
    }

    /**
     * @dev Setting token amount as which swap will happen
     */
    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) external onlyOwner {
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    /**
     * @dev Enabling/Disabling swapping
     */
    function changeSwapStatus(bool status) external onlyOwner {
        swapEnabled = status;
    }

    /**
     * @dev Setting account as excluded from reward.
     */
    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    /**
     * @dev Setting account as included in reward.
     */
    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is not excluded");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Changes token/reflected token ratio
     */
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
        valuesFromGetValues memory values = _getValues(tAmount, true);
        _rOwned[sender] = _rOwned[sender].sub(values.rAmount);
        _rTotal = _rTotal.sub(values.rAmount);
        totalFeesPaid.reflection = totalFeesPaid.reflection.add(tAmount);
    }

    /**
     * @dev Return rAmount of tAmount with or without fees
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        valuesFromGetValues memory values = _getValues(tAmount, true);
        if (!deductTransferFee) {
            return values.rAmount;
        } else {
            return values.rTransferAmount;
        }
    }

    /**
     * @dev Return tAmount of rAmount
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    /**
     * @dev transfers tokens from sender to recipient with or without fees
     */
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        valuesFromGetValues memory values = _getValues(amount, takeFee);

        if (_isExcludedFromReward[sender]) {  //from excluded
                _tOwned[sender] = _tOwned[sender].sub(amount);
        }
        if (_isExcludedFromReward[recipient]) {  //to excluded
                _tOwned[recipient] = _tOwned[recipient].add(values.tTransferAmount);
        }

        _rOwned[sender] = _rOwned[sender].sub(values.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(values.rTransferAmount);
        _reflectFee(values.rReflection, values.tReflection);
        _takeLiquidity(values.rLiquidity, values.tLiquidity);
        _takeMarketing(values.rMarketing, values.tMarketing);
        _takeLottery(values.rLottery, values.tLottery);
        _takeNFTApp(values.rNFTApp, values.tNFTApp);

        emit Transfer(sender, recipient, values.tTransferAmount);
        emit Transfer(sender, address(this), values.tLiquidity.add(values.tMarketing).add(values.tLottery));
        emit Transfer(sender, NFTAppAddress, values.tNFTApp);

    }

    /**
     * @dev Returns tAmount and rAmount with or without fees
     */
    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory values) {
        values = _getTValues(tAmount, takeFee);
        values = _getRValues(values, tAmount, takeFee, _getRate());
        
        return values;
    }

    /**
     * @dev Returns tAmount with or without fees
     */
    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory values) {
        if(!takeFee) {
          values.tTransferAmount = tAmount;
        } else {
            values.tReflection = percent(tAmount, feeRates.reflection);
            values.tLiquidity = percent(tAmount, feeRates.liquidity);
            values.tMarketing = percent(tAmount, feeRates.marketing);
            values.tLottery = percent(tAmount, feeRates.lottery);
            values.tNFTApp = percent(tAmount, feeRates.nftApp);
            values.tTransferAmount = tAmount
                                        .sub(values.tReflection)
                                        .sub(values.tLiquidity)
                                        .sub(values.tMarketing)
                                        .sub(values.tLottery)
                                        .sub(values.tNFTApp);
        }
        return values;
    }

    /**
     * @dev Returns rAmount with or without fees
     */
    function _getRValues(valuesFromGetValues memory values, uint256 tAmount, bool takeFee, uint256 currentRate) 
    private pure returns (valuesFromGetValues memory returnValues) {
        returnValues = values;
        returnValues.rAmount = tAmount.mul(currentRate);

        if(!takeFee) {
            returnValues.rTransferAmount = tAmount.mul(currentRate);
            return returnValues;
        }

        returnValues.rReflection = values.tReflection.mul(currentRate);
        returnValues.rLiquidity = values.tLiquidity.mul(currentRate);
        returnValues.rMarketing = values.tMarketing.mul(currentRate);
        returnValues.rLottery = values.tLottery.mul(currentRate);
        returnValues.rNFTApp = values.tNFTApp.mul(currentRate);
        returnValues.rTransferAmount =  returnValues.rAmount
                            .sub(returnValues.rReflection)
                            .sub(returnValues.rLiquidity)
                            .sub(returnValues.rMarketing)
                            .sub(returnValues.rLottery)
                            .sub(returnValues.rNFTApp);

        return returnValues;
    }

    /**
     * @dev Returns current rate or ratio of reflected tokens over tokens
     */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /**
     * @dev Returns current rSupply and tSupply
     */
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /**
     * @dev Taking/reflecting reflection fees
     */
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        totalFeesPaid.reflection += tFee;
    }

    /**
     * @dev Taking liquidity fees
     */
    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totalFeesPaid.liquidity += tLiquidity;

        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcludedFromReward[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        }
    }

    /**
     * @dev Taking marketing fees
     */
    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totalFeesPaid.marketing += tMarketing;

        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
        if (_isExcludedFromReward[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tMarketing);
        }
    }

    /**
     * @dev Taking lottery fees
     */
    function _takeLottery(uint256 rLottery, uint256 tLottery) private {
        totalFeesPaid.lottery += tLottery;

        _rOwned[address(this)] = _rOwned[address(this)].add(rLottery);
        if (_isExcludedFromReward[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tLottery);
        }
    }

    /**
     * @dev Taking NFT holders and Application Users fees
     */
    function _takeNFTApp(uint256 rNFTApp, uint256 tNFTApp) private {
        totalFeesPaid.nftApp += tNFTApp;

        _rOwned[NFTAppAddress] = _rOwned[NFTAppAddress].add(rNFTApp);
        if (_isExcludedFromReward[NFTAppAddress]) {
            _tOwned[NFTAppAddress] = _tOwned[NFTAppAddress].add(tNFTApp);
        }
    }

    /**
     * @dev Adding liquidity while swap and liquify
     */
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

    /**
     * @dev Converting tokens to BNB while swap and liquify
     */
    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Swapping and adding liquidity
     */
    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 denominator= (feeRates.liquidity.add(feeRates.marketing).add(feeRates.lottery)).mul(2);
        uint256 tokensToAddLiquidityWith = (tokens.mul(feeRates.liquidity)).div(denominator);
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance = deltaBalance.div(denominator.sub(feeRates.liquidity));
        uint256 bnbToAddLiquidityWith = unitBalance.mul(feeRates.liquidity);

        if (bnbToAddLiquidityWith > 0) {
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        // Send BNB to Marketing Address
        uint256 marketingAmount = unitBalance.mul(2).mul(feeRates.marketing);
        if (marketingAmount > 0) {
            (bool sent1, ) = payable(marketingAddress).call{value: marketingAmount}("");
            require(sent1, "Failed to send BNB to Marketing");
        }

        // Send BNB to Lottery Address
        uint256 lotteryAmount = unitBalance.mul(2).mul(feeRates.lottery);
        if (lotteryAmount > 0) {
            (bool sent2, ) = payable(lotteryAddress).call{value: lotteryAmount}("");
            require(sent2, "Failed to send BNB to Lottery");
        }
    }

    /**
     * @dev Update router address in case of pancakeswap migration
     */
    function setRouterAddress(address newRouter) external onlyOwner {
        require(newRouter != address(uniswapV2Router));
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            uniswapV2Pair = get_pair;
        }
        uniswapV2Router = _newRouter;
    }

    /**
     * @dev Withdraw BNB Dust
     */
    function withdrawDust(uint256 weiAmount, address to) external onlyOwner {
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        (bool sent, ) = payable(to).call{value: weiAmount}("");
        require(sent, "Failed to withdraw");
    }

    /**
     * @dev to recieve BNB from uniswapV2Router when swaping
     */
    receive() external payable {}
}