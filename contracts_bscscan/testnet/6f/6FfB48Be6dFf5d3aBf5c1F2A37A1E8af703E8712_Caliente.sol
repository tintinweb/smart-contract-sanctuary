// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract Caliente is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    mapping (address => bool) public automatedMarketMakerPairs;

    bool private inSwapAndLiquify = false;
    bool public swapAndLiquifyEnabled = false;

    bool public feesEnabled = false;
    bool private increaseFeeMode = false;
    uint256 private increaseFeeFactor = 11;
    uint256 public rewardsFee = 4;
    uint256 private previousRewardsFee = rewardsFee;
    uint256 public marketingFee = 2;
    uint256 private previousMarketingFee = marketingFee;
    uint256 public liquidityFee = 4;
    uint256 private previousLiquidityFee = liquidityFee;

    mapping (address => bool) private _isExcludedFromFees;
    address[] private _excluded;

    address public liquidityWallet;
    address public marketingWallet = 0xB7eED73436BFbEA10A47BB7488De4b6Be54c2f88;
    address public platformMaintenanceWallet = 0x7dE827750E4729FD83b7000105e883B22101fD3E;

    uint8 private tokenDecimals = 9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * (10**tokenDecimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBlacklisted;

    uint256 public maxSellTransactionAmount = 2500000 * (10**tokenDecimals);
    uint256 public maxHoldingAmount = 20000000 * (10**tokenDecimals);
    uint256 public swapTokensAtAmount = 180000 * (10**tokenDecimals);

    //Anti-Sniper Protection (ASP)
    uint256 private ASPMaxTransactionAmount = 0;
    bool private ASPEnabled = false;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event IncludeInBlacklist(address indexed account, bool isIncluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event MaxHoldingAmountUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxSellTransactionAmountUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event ASPMaxTransactionAmountUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SwapAndSendToMarketingWallet(uint256 tokensSent, uint256 ethSent);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event FeesEnabledUpdated(bool enabled);
    event TokensBurned(uint256 amount);
    event ASPEnabledUpdated(bool enabled);

    constructor() ERC20("Caliente", "CAL") {
        liquidityWallet = owner();

    	//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //MAINNET
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //TESTNET
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        excludeFromRewards(_uniswapV2Pair);
        excludeFromRewards(address(uniswapV2Router));
        excludeFromRewards(address(this));
        excludeFromRewards(marketingWallet);
        excludeFromRewards(platformMaintenanceWallet);

        excludeFromFees(marketingWallet, true);
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(platformMaintenanceWallet, true);
        excludeFromFees(address(this), true);

        _rOwned[owner()] = _rTotal;
        emit Transfer(address(0), owner(), _tTotal);
    }

    receive() external payable {}

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if(_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        uniswapV2Router = IUniswapV2Router02(newAddress);
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) _isExcludedFromFees[accounts[i]] = excluded;
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateLiquidityWallet(address newLiquidityWallet) external onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        liquidityWallet = newLiquidityWallet;
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
    }

    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != marketingWallet, "The marketing wallet is already this address");
        excludeFromFees(newMarketingWallet, true);
        excludeFromRewards(newMarketingWallet);
        marketingWallet = newMarketingWallet;
        emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
    }

    function updateMaxHoldingAmount(uint256 newValue) external onlyOwner {
        uint256 newAmount = newValue * (10**tokenDecimals);
        require(newAmount >= (totalSupply() / 1000) && newAmount <= totalSupply(), "maxHoldingAmount must between 0.1% and 100% of total supply.");
        require(newAmount != maxHoldingAmount, "Cannot update maxHoldingAmount to same value");
        maxHoldingAmount = newAmount;
        emit MaxHoldingAmountUpdated(newAmount, maxHoldingAmount);
    }

    function updateASPMaxTransactionAmount(uint256 newValue) external onlyOwner {
        uint256 newAmount = newValue * (10**tokenDecimals);
        require(newAmount >= 0 && newAmount <= totalSupply(), "ASPMaxTransactionAmount must between 0% and 100% of total supply.");
        require(newAmount != ASPMaxTransactionAmount, "Cannot update ASPMaxTransactionAmount to same value");
        ASPMaxTransactionAmount = newAmount;
        emit ASPMaxTransactionAmountUpdated(newAmount, ASPMaxTransactionAmount);
    }

    function updateMaxSellTransactionAmount(uint256 newValue) external onlyOwner {
        uint256 newAmount = newValue * (10**tokenDecimals);
        require(newAmount >= (totalSupply() / 1000) && newAmount <= totalSupply(), "maxSellTransactionAmount must between 0.1% and 100% of total supply.");
        require(newAmount != maxSellTransactionAmount, "Cannot update maxSellTransactionAmount to same value");
        maxSellTransactionAmount = newAmount;
        emit MaxSellTransactionAmountUpdated(newAmount, maxSellTransactionAmount);
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setFeesEnabled(bool _enabled) external onlyOwner {
        feesEnabled = _enabled;
        emit FeesEnabledUpdated(_enabled);
    }

    function burn(uint256 value) external onlyOwner {
        uint256 burnAmount = value * (10**tokenDecimals);
        _tTotal = _tTotal.sub(burnAmount);
        _tokenTransfer(_msgSender(), address(0), burnAmount, false, false);
        emit TokensBurned(burnAmount);
    }

    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length > 0, "Recipients are not specified.");
        require(recipients.length == amounts.length, "Arrays lengths does not match.");

        for(uint i = 0; i < amounts.length; i++) {
            _tokenTransfer(_msgSender(), recipients[i], amounts[i] * (10**tokenDecimals), false, false);
        }
    }

    function enableASP(bool enabled) external onlyOwner {
        require(ASPEnabled != enabled, "ASPEnabled is already set to that value");
        ASPEnabled = enabled;
        increaseFeeFactor = enabled ? 95 : 11;
        emit ASPEnabledUpdated(enabled);
    }

    function includeInBlacklist(address account, bool included) external onlyOwner() {
        require(_isBlacklisted[account] != included, "Account is already the value of 'included'");
        _isBlacklisted[account] = included;
        emit IncludeInBlacklist(account, included);
    }

    function isBlacklisted(address account) external view returns(bool) {
        return _isBlacklisted[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromRewards(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInRewards(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for(uint256 i = 0; i < _excluded.length; i++) {
            if(_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function totalRewardsDistributed() external view returns (uint256) {
        return _tFeeTotal;
    }

    function isASPEnabled() external view onlyOwner returns (bool) {
        return ASPEnabled;
    }

    function ASPCurrentTransactionAmount() external view onlyOwner returns (uint256) {
        return ASPMaxTransactionAmount.div(10**tokenDecimals);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[from], "Sender address is blacklisted");
        require(!_isBlacklisted[to], "Recipient address is blacklisted");

        //if ASP enabled and tx sent not from excluded address then check is transaction amount less than maximum ASP amount limit
        if(
            ASPEnabled &&
            !_isExcludedFromFees[from]
        ) require(amount <= ASPMaxTransactionAmount, "Transfer amount exceeds the ASPMaxTransactionAmount.");

        //check is sell transaction amount less than maximum sell amount limit
        if(
            !_isExcludedFromFees[from] && //address is not excluded from fees
        	!inSwapAndLiquify && //transaction is sent not from tokenomics functions
            automatedMarketMakerPairs[to] && //transaction is sent to uniswap pair
        	from != address(uniswapV2Router) //transaction is sent not from uniswap router
        ) require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");

        //check if address holds less than maximum wallet balance limit
        if(
            !_isExcludedFromFees[to] && //address is not excluded from fees
            !automatedMarketMakerPairs[to] //transaction is sent not to uniswap pair
        ) require(balanceOf(to).add(amount) <= maxHoldingAmount, "Recipient balance is exceeding maxHoldingAmount.");

        //capture contract's current token balance
		uint256 contractTokenBalance = balanceOf(address(this));

        //can we proceed to call tokenomics functions?
        bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;

        if(
            overMinTokenBalance &&
            swapAndLiquifyEnabled &&
            !ASPEnabled &&
            !inSwapAndLiquify &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet &&
            from != marketingWallet &&
            to != marketingWallet
        ) {
            inSwapAndLiquify = true;

            contractTokenBalance = swapTokensAtAmount;

            uint totalFees = marketingFee.add(liquidityFee);

            uint256 liquidityTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(liquidityTokens);

            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToMarketingWallet(marketingTokens);

            inSwapAndLiquify = false;
        }

        bool takeFee = !inSwapAndLiquify && feesEnabled;
        
        //if ASP enabled then take fee
        if(ASPEnabled) takeFee = true;

        //if any account belongs to _isExcludedFromFees account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) takeFee = false;
        
        bool increaseFee = false;

        //if sell transaction then increase fee
        if(takeFee && automatedMarketMakerPairs[to]) increaseFee = true;

        //if ASP enabled and tx sent not from excluded address then increase fee
        if(ASPEnabled && takeFee && !_isExcludedFromFees[from]) increaseFee = true;

        //transfer tokens
        _tokenTransfer(from, to, amount, takeFee, increaseFee);
    }

    function swapAndLiquify(uint256 tokens) private {
        //split amount into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        //capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        //swap tokens for ETH
        swapTokensForEth(half);

        //how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        //add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapAndSendToMarketingWallet(uint256 tokens) private {
        //split the amount into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        //capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        //swap tokens for ETH
        swapTokensForEth(half);

        //how much ETH did we just swap into?
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        //send ETH to marketing address
        payable(marketingWallet).transfer(transferredBalance);

        //send tokens to marketing address
        _tokenTransfer(address(this), marketingWallet, otherHalf, false, false);

        emit SwapAndSendToMarketingWallet(otherHalf, transferredBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // approve token transfer to cover all possible scenarios
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
        //approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        //add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, //slippage is unavoidable
            0, //slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function _calculateRewardsFee(uint256 amount) private view returns (uint256) {
        uint256 _rewardsFee = increaseFeeMode ? rewardsFee.mul(increaseFeeFactor) : rewardsFee.mul(10);
        return amount.mul(_rewardsFee).div(1000);
    }

    function _calculateLiquidityFee(uint256 amount) private view returns (uint256) {
        uint256 _liquidityFee = increaseFeeMode ? liquidityFee.mul(increaseFeeFactor) : liquidityFee.mul(10);
        return amount.mul(_liquidityFee).div(1000);
    }

    function _calculateMarketingFee(uint256 amount) private view returns (uint256) {
        uint256 _marketingFee = increaseFeeMode ? marketingFee.mul(increaseFeeFactor) : marketingFee.mul(10);
        return amount.mul(_marketingFee).div(1000);
    }
    
    function _removeAllFee() private {
        if(rewardsFee == 0 && liquidityFee == 0 && marketingFee == 0) return;
        
        previousRewardsFee = rewardsFee;
        previousLiquidityFee = liquidityFee;
        previousMarketingFee = marketingFee;
        
        rewardsFee = 0;
        liquidityFee = 0;
        marketingFee = 0;
    }
    
    function _restoreAllFee() private {
        rewardsFee = previousRewardsFee;
        liquidityFee = previousLiquidityFee;
        marketingFee = previousMarketingFee;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        for(uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if(rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _reflectRewards(uint256 rRewards, uint256 tRewards) private {
        _rTotal = _rTotal.sub(rRewards);
        _tFeeTotal = _tFeeTotal.add(tRewards);
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        emit Transfer(sender, address(this), tLiquidity);
    }

    function _takeMarketing(address sender, uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
        if(_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(tMarketing);
        emit Transfer(sender, address(this), tMarketing);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tRewards, uint256 tLiquidity, uint256 tMarketing) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewards) = _getRValues(tAmount, tRewards, tLiquidity, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rRewards, tTransferAmount, tRewards, tLiquidity, tMarketing);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tRewards = _calculateRewardsFee(tAmount);
        uint256 tLiquidity = _calculateLiquidityFee(tAmount);
        uint256 tMarketing = _calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tRewards).sub(tLiquidity).sub(tMarketing);
        return (tTransferAmount, tRewards, tLiquidity, tMarketing);
    }

    function _getRValues(uint256 tAmount, uint256 tRewards, uint256 tLiquidity, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rRewards = tRewards.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rRewards).sub(rLiquidity).sub(rMarketing);
        return (rAmount, rTransferAmount, rRewards);
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool increaseFee) private {
        if(!takeFee) _removeAllFee();
        increaseFeeMode = increaseFee;

        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewards, uint256 tTransferAmount, uint256 tRewards, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        if(_isExcluded[sender] && !_isExcluded[recipient]) {
            //transfer from excluded
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        } else if(!_isExcluded[sender] && _isExcluded[recipient]) {
            //transfer to excluded
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        } else if(_isExcluded[sender] && _isExcluded[recipient]) {
            //transfer both excluded
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }

        _takeLiquidity(sender, tLiquidity);
        _takeMarketing(sender, tMarketing);
        _reflectRewards(rRewards, tRewards);
        
        if(!takeFee) _restoreAllFee();
        increaseFeeMode = false;

        emit Transfer(sender, recipient, tTransferAmount);
    }
}