/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
ECODOGE
Website https://ecodogecoin.net/
https://twitter.com/DogeCoinEco

Total supply 1_000_000_000_000_000

Tokenomics

Rewards 6%
Auto Liquidity 5%
Burn 1%
Marketing 5%
Charity 1%

Anti whale/bot

Max tx 1%
Max wallet 1%
Sell delay after buy 30 seconds

*/
/**
 * @dev Interface BEP standard.
 */
interface IBEP20 {
    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX: Unlicensed
interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
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

// SPDX: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
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

// SPDX: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX: MIT
contract EcoDoge is IBEP20, Context, Ownable {
    mapping(address => uint256) private tokenOwned;
    mapping(address => uint256) private reflectionOwned;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromReward;
    address[] private excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply = 1_000_000_000_000_000 * 10**9;
    uint256 private reflectedSupply = (MAX - (MAX % _totalSupply));

    string private constant _name = 'EcoDoge';
    string private constant _symbol = 'ECODOGE';
    uint8 private _decimals = 9;
    struct taxRatesData {
        uint256 rfi;
        uint256 liquidity;
        uint256 burn;
        uint256 marketing;
        uint256 charity;
    }

    taxRatesData taxRates = taxRatesData({rfi: 6, liquidity: 2, burn: 1, marketing: 5, charity: 1});

    uint16 internal constant FEE_DIV = 10**2;

    uint256 maxTxPercent = 1;
    uint256 maxWalletPercent = 1;

    uint256 maxTxAmount = (_totalSupply * maxTxPercent) / 10**2;
    uint256 maxWalletAmount = (_totalSupply * maxWalletPercent) / 10**2;

    uint256 swapTokensThreshold = (_totalSupply * maxTxAmount) / 10**3; //0.1%

    //anti bot & snipe
    uint256 launchedAt;
    uint256 constant txDelay = 30; //seconds
    mapping(address => uint256) lastTx;
    bool antiSnipe = true;

    IDexRouter pancakeV2Router;
    address pancakeV2Pair;

    bool inSwapAndLiquify;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    address immutable marketingWallet = 0x79B21DAB376A2aCAeaa21D12B5a6616E886176Ba;
    //Binance Charity Wallet
    address immutable charityWallet = 0x8B99F3660622e21f2910ECCA7fBe51d654a1517D;
    address immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    // Return vals
    struct valuesFrom {
        uint256 tTransferAmount;
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 tRfi;
        uint256 tLiquidity;
        uint256 tBurn;
        uint256 tMarketing;
        uint256 tCharity;
        uint256 rRfi;
        uint256 rLiquidity;
        uint256 rBurn;
        uint256 rMarketing;
        uint256 rCharity;
    }

    constructor() {
        reflectionOwned[_msgSender()] = reflectedSupply;

        // PancakeSwap V2 Router address
        // (BSC testnet) 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // (BSC mainnet) 0x10ED43C718714eb63d5aA57B78B54704E256024E
        pancakeV2Router = IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakeV2Pair = IDexFactory(pancakeV2Router.factory()).createPair(address(this), pancakeV2Router.WETH());

        //exclude from fee
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[deadAddress] = true;
        isExcludedFromFee[marketingWallet] = true;
        isExcludedFromFee[charityWallet] = true;

        // exclude from rewards
        _exclude(owner());
        _exclude(address(this));
        _exclude(pancakeV2Pair);
        _exclude(charityWallet);
        _exclude(marketingWallet);
        _exclude(deadAddress);

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function __tokenInfo()
        public
        view
        returns (
            bool Launched,
            uint256 Launched_At,
            uint256 Max_Tx_Percent,
            uint256 Max_Wallet_Percent,
            uint256 Sell_Delay_Sec,
            uint256 Contract_Token_Balance,
            address Pancake_LP_Pair,
            address Marketing_Wallet,
            address Charity_Wallet
        )
    {
        return (
            launched(),
            launchedAt,
            maxTxPercent,
            maxWalletPercent,
            txDelay,
            balanceOf(address(this)),
            pancakeV2Pair,
            marketingWallet,
            charityWallet
        );
    }

    function __tokenFees()
        public
        view
        returns (
            uint256 Rfi_Tax,
            uint256 Liquidity_Tax,
            uint256 Burn_Tax,
            uint256 Marketing_Tax,
            uint256 Charity_Tax
        )
    {
        return (taxRates.rfi, taxRates.liquidity, taxRates.burn, taxRates.marketing, taxRates.charity);
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (isExcludedFromReward[account]) return tokenOwned[account];
        return tokenFromReflection(reflectionOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, 'Transfer amount exceeds allowance');
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(!isExcludedFromReward[sender], 'Excluded addresses cannot call this function');

        valuesFrom memory v = getValues(tAmount, true);

        reflectionOwned[sender] -= v.rAmount;
        reflectedSupply -= v.rAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
        require(tAmount <= _totalSupply, 'Amount must be less than supply');

        valuesFrom memory v = getValues(tAmount, true);

        if (!deductTransferFee) {
            return v.rAmount;
        } else {
            return v.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= reflectedSupply, 'Amount must be less than total reflections');
        uint256 currentRate = getCurrentRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!isExcludedFromReward[account], 'Account is already excluded');
        _exclude(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(isExcludedFromReward[account], 'Account is not excluded');

        for (uint256 i = 0; i < excluded.length; i++) {
            if (excluded[i] == account) {
                excluded[i] = excluded[excluded.length - 1];
                tokenOwned[account] = 0;

                isExcludedFromReward[account] = false;
                excluded.pop();
                break;
            }
        }
    }

    function _exclude(address account) internal {
        if (reflectionOwned[account] > 0) {
            tokenOwned[account] = tokenFromReflection(reflectionOwned[account]);
        }
        isExcludedFromReward[account] = true;
        excluded.push(account);
    }

    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function getValues(uint256 amount, bool takeFee) private view returns (valuesFrom memory) {
        uint256 currentRate = getCurrentRate();
        valuesFrom memory v;
        v.rAmount = amount * currentRate;

        if (!takeFee) {
            v.tTransferAmount = amount;
            v.rTransferAmount = v.rAmount;
            return v;
        }

        v.tRfi = calculateFee(amount, taxRates.rfi);
        v.tLiquidity = calculateFee(amount, taxRates.liquidity);
        v.tBurn = calculateFee(amount, taxRates.burn);
        v.tMarketing = calculateFee(amount, taxRates.marketing);
        v.tCharity = calculateFee(amount, taxRates.charity);

        v.rRfi = v.tRfi * currentRate;
        v.rLiquidity = v.tLiquidity * currentRate;
        v.rBurn = v.tBurn * currentRate;
        v.rMarketing = v.tMarketing * currentRate;
        v.rCharity = v.tCharity * currentRate;

        v.tTransferAmount = amount - v.tRfi - v.tLiquidity - v.tBurn - v.tMarketing - v.tCharity;
        v.rTransferAmount = v.rAmount - v.rRfi - v.rLiquidity - v.rBurn - v.rMarketing - v.rCharity;

        return v;
    }

    function getCurrentRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply / tSupply;
    }

    function getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = reflectedSupply;
        uint256 tSupply = _totalSupply;

        for (uint256 i = 0; i < excluded.length; i++) {
            if (reflectionOwned[excluded[i]] > rSupply || tokenOwned[excluded[i]] > tSupply)
                return (reflectedSupply, _totalSupply);
            rSupply -= reflectionOwned[excluded[i]];
            tSupply -= tokenOwned[excluded[i]];
        }
        if (rSupply < (reflectedSupply / _totalSupply)) return (reflectedSupply, _totalSupply);
        return (rSupply, tSupply);
    }

    function transferBurn(
        address sender,
        uint256 tBurn,
        uint256 rBurn
    ) internal {
        //soft burn
        reflectionOwned[deadAddress] += rBurn;
        if (isExcludedFromReward[deadAddress]) tokenOwned[deadAddress] += tBurn;

        //Emit burn address balance update
        emit Transfer(sender, deadAddress, tBurn);
    }

    function manualBurn(uint256 amount) external {
        address sender = _msgSender();
        require(sender != address(0), 'Burn from 0 address');
        require(sender != address(deadAddress), 'NO Burn');

        uint256 balance = balanceOf(sender);
        require(balance >= amount, 'Burn amount exceeds balance');

        uint256 rAmount = amount * getCurrentRate();

        // remove from sender balance
        reflectionOwned[sender] -= rAmount;
        if (isExcludedFromReward[sender]) tokenOwned[sender] -= amount;

        transferBurn(sender, amount, rAmount);
    }

    function calculateFee(uint256 amount, uint256 tax) private pure returns (uint256) {
        return (amount * tax) / FEE_DIV;
    }

    function distributeFees(valuesFrom memory vals) private {
        distributeRfi(vals.rRfi);

        distributeFee(vals.tLiquidity, vals.rLiquidity);
        distributeFee(vals.tMarketing, vals.rMarketing);
        distributeFee(vals.tCharity, vals.rCharity);
        distributeFee(vals.tBurn, vals.rBurn, deadAddress);

        //Emit burn address balance update
        emit Transfer(address(this), deadAddress, vals.tBurn);
    }

    function distributeRfi(uint256 rFee) private {
        reflectedSupply -= rFee;
    }

    function distributeFee(uint256 tFee, uint256 rFee) private {
        distributeFee(tFee, rFee, address(this));
    }

    function distributeFee(
        uint256 tFee,
        uint256 rFee,
        address addr
    ) private {
        reflectionOwned[addr] += rFee;
        if (isExcludedFromReward[addr]) tokenOwned[addr] += tFee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), 'Approve from the zero address');
        require(spender != address(0), 'Approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), 'Transfer from the zero address');
        require(to != address(0), 'Transfer to the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');

        if (!launched() && from != owner() && to != owner()) revert('Not launched yet');

        if (from != owner() && to != owner())
            require(amount <= maxTxAmount, 'Transfer amount exceeds the maxTxAmount.');

        if (from != owner() && to != owner() && to != deadAddress && to != pancakeV2Pair)
            require(balanceOf(to) + amount <= maxWalletAmount, 'New balance would exceed maximum wallet token amount');

        if (from == pancakeV2Pair && to != owner()) {
            //save buy
            lastTx[from] = block.timestamp;
        }

        if (to == pancakeV2Pair && from != owner()) {
            //check sell
            require(lastTx[to] + txDelay <= block.timestamp, 'Please wait some delay to sell');
        }

        if (antiSnipe && launchedAt + 10 > block.number) revert('Too soon boi');

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        bool isOver = contractTokenBalance >= swapTokensThreshold;

        if (isOver && !inSwapAndLiquify && (from != pancakeV2Pair)) {
            contractTokenBalance = swapTokensThreshold;
            swapAndLiquify(contractTokenBalance);
        }

        //transfer amount, it will take tax, burn, liquidity fee
        tokenTransfer(from, to, amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 totalTaxToBnb = taxRates.liquidity + taxRates.marketing + taxRates.charity;
        uint256 liquidityTokens = (contractTokenBalance * taxRates.liquidity) / totalTaxToBnb;
        // split
        uint256 half = liquidityTokens / 2;
        uint256 otherHalf = liquidityTokens - half;
        // contract current BNB balance.
        uint256 initialBalanceBNB = address(this).balance;
        // swap tokens for BNB
        swapTokensForBNB(half);
        // how much BNB did we just swap
        uint256 liquidityBNB = address(this).balance - initialBalanceBNB;
        // add liquidity to pancake
        addLiquidity(otherHalf, liquidityBNB);
        emit SwapAndLiquify(half, liquidityBNB, otherHalf);

        // set again
        initialBalanceBNB = address(this).balance;
        // swap rest of tokens for BNB
        swapTokensForBNB(contractTokenBalance - liquidityTokens);
        // how much BNB did we just swap
        uint256 remainingBNB = address(this).balance - initialBalanceBNB;

        totalTaxToBnb -= taxRates.liquidity;

        uint256 marketingBNB = (remainingBNB * taxRates.marketing) / totalTaxToBnb;
        uint256 charityBNB = (remainingBNB * taxRates.charity) / totalTaxToBnb;

        if (marketingBNB > 0) {
            payable(marketingWallet).transfer(marketingBNB);
        }
        if (charityBNB > 0) {
            payable(charityWallet).transfer(charityBNB);
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();

        _approve(address(this), address(pancakeV2Router), tokenAmount);

        // make the swap
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeV2Router), tokenAmount);

        // add the liquidity
        pancakeV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }

    //this method is responsible for taking all fees
    function tokenTransfer(
        address from,
        address to,
        uint256 amount
    ) private {
        bool takeFee = true;
        if (isExcludedFromFee[from] || isExcludedFromFee[to]) takeFee = false;

        valuesFrom memory vals = getValues(amount, takeFee);

        reflectionOwned[from] -= vals.rAmount;
        reflectionOwned[to] += vals.rTransferAmount;

        if (isExcludedFromReward[from]) tokenOwned[from] -= amount;

        if (isExcludedFromReward[to]) tokenOwned[to] += vals.tTransferAmount;

        if (takeFee) distributeFees(vals);

        emit Transfer(from, to, vals.tTransferAmount);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() external onlyOwner {
        require(launchedAt == 0, 'Already launched');
        launchedAt = block.number;
    }

    function defuseAntisnipe() external onlyOwner {
        antiSnipe = false;
    }

    // rescue BNB
    function rescueBNBFromContract(address payable recipient) external onlyOwner {
        require(recipient != address(0), 'Cannot withdraw the balance to 0 address');
        require(address(this).balance > 0, 'The balance must be > 0');

        recipient.transfer(address(this).balance);
    }

    function rescueToken(address _token, address _to) external onlyOwner {
        require(_token != address(this), "Can't take native tokens");
        IBEP20(_token).transfer(_to, IBEP20(_token).balanceOf(address(this)));
    }

    receive() external payable {}
}