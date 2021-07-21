// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./ERC20.sol";
import "./IUniswapV2Router02.sol";

contract Flydoge is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address devAddress;

    bool private swapping;
    bool public swapEnabled;

    uint256 public swapTokensAtAmount = 200000 * (10 ** 18);

    uint256 public immutable liquidityFee;
    uint256 public immutable burnFee;
    uint256 public immutable devFee;
    uint256 public clamTime = 30 seconds;


    uint256 public immutable tradingEnabledTimestamp = 1623967200; //June 17, 22:00 UTC, 2021

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint) public sellRecord;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(address _devAddress) public ERC20("Xinxin", "Xx") {

        liquidityFee = 2;
        burnFee = 5;
        devFee = 3;

        devAddress = _devAddress;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        _mint(owner(), 100000000000000 * (10 ** 9));
    }

    receive() external payable {

    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function setClamTime(uint _clamTime) external onlyOwner {
        clamTime = _clamTime;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        if (swapping) {
            super._transfer(from, to, amount);
            return;
        }

        bool inGovern = _isExcludedFromFees[from] || _isExcludedFromFees[to];
        bool tradingIsEnabled = getTradingIsEnabled();
        if (!tradingIsEnabled) {
            require(inGovern, "This account cannot send tokens until trading is enabled");
        }

        if (to == uniswapV2Pair) {
            uint nextSellTime = sellRecord[from];
            if (!inGovern) {
                if (nextSellTime > 0) {
                    require(block.timestamp >= nextSellTime, "claim time!");
                }
                sellRecord[from] = block.timestamp + clamTime;
            }
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            tradingIsEnabled &&
            swapEnabled &&
            canSwap &&
            !swapping &&
            automatedMarketMakerPairs[to]
        ) {
            swapping = true;
            swapAndLiquify(swapTokensAtAmount);
            swapping = false;
        }

        bool takeFee = tradingIsEnabled && !swapping && !inGovern && from != address(this) && from != address(uniswapV2Router) && to != address(uniswapV2Router);

        amount = takeFee ? _takeFee(from, amount) : amount;

        super._transfer(from, to, amount);

    }

    function _takeFee(
        address from,
        uint256 amount
    ) private returns (uint) {
        uint _liquidityFee = amount.mul(liquidityFee).div(100);
        super._transfer(from, address(this), _liquidityFee);

        uint _burnFee = amount.mul(burnFee).div(100);
        super._transfer(from, DEAD, _burnFee);

        uint _devFee = amount.mul(devFee).div(100);
        super._transfer(from, devAddress, _devFee);

        uint256 fees = _liquidityFee.add(_burnFee).add(_devFee);
        return amount.sub(fees);
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);
        // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

    }

}