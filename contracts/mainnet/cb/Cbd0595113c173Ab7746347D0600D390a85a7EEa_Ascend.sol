pragma solidity ^0.8.4;

// SPDX-License-Identifier: Apache-2.0

import "./SafeMath.sol";
import "./Address.sol";
import "./RewardsToken.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IRewardsTracker.sol";

contract Ascend is RewardsToken {
    using SafeMath for uint256;
    using Address for address;
    
    // Supply, limits and fees
    uint256 private constant REWARDS_TRACKER_IDENTIFIER = 0;
    uint256 private constant TOTAL_SUPPLY = 100000000000000 * (10**9);
    uint256 public maxTxAmount = TOTAL_SUPPLY.mul(5).div(1000); // 0.5%

    uint256 public devFee = 4;
    uint256 private _previousDevFee = devFee;
    
    uint256 public rewardsFee = 8;
    uint256 private _previousRewardsFee = rewardsFee;

    address payable private _devWalletAddress =
        payable(0x5E0EB60467bEbb9438545b63f9adB51A526d029c);

    IRewardsTracker private _rewardsTracker;
    
    // Exclusions
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTx;
    
    // Token -> ETH swap support
    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;

    bool currentlySwapping;
    bool public swapAndRedirectEthFeesEnabled = true;

    uint256 private minTokensBeforeSwap = 2000000000 * 10**9;

    // Events and modifiers
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndRedirectEthFeesUpdated(bool enabled);
    event OnSwapAndRedirectEthFees(
        uint256 tokensSwapped,
        uint256 ethToDevWallet
    );
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    event ExcludeFromFees(address wallet);
    event IncludeInFees(address wallet);
    event DevWalletUpdated(address newDevWallet);
    event RewardsTrackerUpdated(address newRewardsTracker);
    event RouterUpdated(address newRouterAddress);
    event FeesChanged(uint256 newDevFee, uint256 newRewardsFee);

    modifier lockTheSwap() {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }

    constructor() ERC20("Ascend", "ACE") {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        // mint supply
        _mint(owner(), TOTAL_SUPPLY);

        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        // internal exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        
        // exclude from rewards
        excludeFromRewards(address(this));
        excludeFromRewards(address(0xdead));
        excludeFromRewards(uniswapV2Pair);

        emit Transfer(address(0), _msgSender(), TOTAL_SUPPLY);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (
            !_isExcludedFromMaxTx[from] &&
            !_isExcludedFromMaxTx[to] // by default false
        ) {
            require(
                amount <= maxTxAmount,
                "Transfer amount exceeds the maxTxAmount"
            );
        }

        // start swap to ETH
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
        if (
            overMinTokenBalance &&
            !currentlySwapping &&
            from != uniswapV2Pair &&
            swapAndRedirectEthFeesEnabled
        ) {
            // add dev fee
            swapAndRedirectEthFees(contractTokenBalance);
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            removeAllFee();
        }

        (uint256 tTransferAmount, uint256 tFee) = _getValues(amount);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(tTransferAmount);
        _takeFee(tFee);

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            restoreAllFee();
        }

        emit Transfer(from, to, tTransferAmount);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 tFee = calculateFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _takeFee(uint256 fee) private {
        _balances[address(this)] = _balances[address(this)].add(fee);
    }

    function calculateFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        uint256 totalFee = devFee.add(rewardsFee);
        return _amount.mul(totalFee).div(100);
    }

    function removeAllFee() private {
        if (devFee == 0 || rewardsFee == 0) return;

        _previousDevFee = devFee;
        _previousRewardsFee = rewardsFee;

        devFee = 0;
        rewardsFee = 0;
    }

    function restoreAllFee() private {
        devFee = _previousDevFee;
        rewardsFee = _previousRewardsFee;
    }

    function swapAndRedirectEthFees(uint256 contractTokenBalance)
        private
        lockTheSwap
    {
        uint256 totalRedirectFee = devFee.add(rewardsFee);
        if (totalRedirectFee == 0) return;
        
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the fee events include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(contractTokenBalance);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        if (newBalance > 0) {
            //
            // send to rewards wallet
            //
            uint256 rewardsBalance = newBalance.mul(rewardsFee).div(totalRedirectFee);
            if (rewardsBalance > 0 && address(_rewardsTracker) != address(0)) {
                try _rewardsTracker.addAllocation{value: rewardsBalance}(REWARDS_TRACKER_IDENTIFIER) {} catch {}
            }
            
            //
            // send to dev wallet
            //
            uint256 devBalance = newBalance.mul(devFee).div(totalRedirectFee);
            sendEthToWallet(_devWalletAddress, devBalance);

            emit OnSwapAndRedirectEthFees(contractTokenBalance, newBalance);
        }
    }

    function sendEthToWallet(address wallet, uint256 amount) private {
        if (amount > 0) {
            payable(wallet).transfer(amount);
        }
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
    
    // for 0.5% input 5, for 1% input 10
    function setMaxTxPercent(uint256 newMaxTx) public onlyOwner {
        require(newMaxTx >= 5, "Max TX should be above 0.5%");
        maxTxAmount = TOTAL_SUPPLY.mul(newMaxTx).div(1000);
        emit MaxTxAmountUpdated(maxTxAmount);
    }
    
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFees(account);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFees(account);
    }

    function setFees(uint256 newDevFee, uint256 newRewardsFee) external onlyOwner {
        require(newDevFee <= 10 && newRewardsFee <= 10, "Fees exceed maximum allowed value");
        devFee = newDevFee;
        rewardsFee = newRewardsFee;
        emit FeesChanged(newDevFee, newRewardsFee);
    }

    function _setDevWallet(address payable newDevWallet)
        external
        onlyOwner
    {
        _devWalletAddress = newDevWallet;
        emit DevWalletUpdated(newDevWallet);
    }
    
    function _setRewardsTracker(address payable newRewardsTracker)
        external
        onlyOwner
    {
        _rewardsTracker = IRewardsTracker(newRewardsTracker);
        emit RewardsTrackerUpdated(newRewardsTracker);
    }

    function setRouterAddress(address newRouter) external onlyOwner {
        IUniswapV2Router _newUniswapRouter = IUniswapV2Router(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newUniswapRouter.factory())
            .createPair(address(this), _newUniswapRouter.WETH());
        uniswapV2Router = _newUniswapRouter;
        emit RouterUpdated(newRouter);
    }

    function setSwapAndRedirectEthFeesEnabled(bool enabled) external onlyOwner {
        swapAndRedirectEthFeesEnabled = enabled;
        emit SwapAndRedirectEthFeesUpdated(enabled);
    }

    function setMinTokensBeforeSwap(uint256 minTokens) external onlyOwner {
        minTokensBeforeSwap = minTokens * 10**9;
        emit MinTokensBeforeSwapUpdated(minTokens);
    }
    
    // emergency claim functions
    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external onlyOwner {
        uint256 contractEthBalance = address(this).balance;
        sendEthToWallet(_devWalletAddress, contractEthBalance);
    }
}