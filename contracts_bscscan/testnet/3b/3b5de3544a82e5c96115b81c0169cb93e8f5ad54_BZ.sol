// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter.sol";
import "./Ownable.sol";

contract BZ is ERC20, Ownable {
    // Fees.
    uint256 public constant MARKETING_FEE = 5;
    uint256 public constant LIQUIDITY_FEE = 2;
    uint256 public constant BURN_FEE = 1;
    uint256 public constant POT_FEE = 2;
    uint256 public constant TOTAL_FEE = MARKETING_FEE + LIQUIDITY_FEE + BURN_FEE + POT_FEE;
    uint256 public constant INORGANIC_FEE = 90;

    // PancakeSwap router address.
    address public constant ROUTER_ADDR = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    // PancakeSwap objects.
    IPancakeRouter02 public dexRouter;
    address public immutable dexPair;
    mapping(address => bool) public automatedMarketMakerPairs;

    // Tax beneficiaries.
    address public liquidityWallet;
    address public marketingWallet;
    address public potWallet;

    // Liquidate tokens for BNB when the contract accumulates 100 tokens by default.
    uint256 public liquidateTokensAtQty = 100 * (10 ** 18);

    // Whether the token can already be traded.
    bool public tradingEnabled;

    // Block number at which the contract was activated.
    uint256 public activatedBlockNumber;

    // Number of inorganic blocks after activation.
    uint256 public organicBlockOffset = 0;

    // Exclude eligible accounts from fees.
    mapping(address => bool) public excludedFromFees;

    // Allow eligible accounts to transfer before trading enabled.
    mapping(address => bool) public canTransferBeforeTrading;

    // Whether the transfer is currently in liquidation mode.
    bool private _liquidating;

    constructor() ERC20("BZ", "BZ!") {
        assert(TOTAL_FEE == 10);

        liquidityWallet = owner();
        marketingWallet = owner();
        potWallet = owner();

        // Create a PancakeSwap pair for this new token.
        IPancakeRouter02 _dexRouter = IPancakeRouter02(ROUTER_ADDR);
        address _dexPair = IPancakeFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());

        dexRouter = _dexRouter;
        dexPair = _dexPair;

        _setAutomatedMarketMakerPair(_dexPair, true);

        // Exclude from paying fees.
        excludeFromFees(liquidityWallet);
        excludeFromFees(marketingWallet);
        excludeFromFees(potWallet);
        excludeFromFees(address(this));

        // Enable owner wallet to transfer tokens before trading enabled.
        allowTransferBeforeTrading(owner());

        /*
            _mint is an internal function in ERC20.sol that is only called here, and CANNOT be called ever again.
        */
        _mint(owner(), 1000000 * (10 ** 18));
    }

    receive() external payable {}

    function activate() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        activatedBlockNumber = block.number;
    }

    function addAutomatedMarketMakerPair(address pair) external onlyOwner {
        require(pair != dexPair, "This AMM pair cannot be modified");
        _setAutomatedMarketMakerPair(pair, true);
    }

    function removeAutomatedMarketMakerPair(address pair) external onlyOwner {
        require(pair != dexPair, "This AMM pair cannot be modified");
        _setAutomatedMarketMakerPair(pair, false);
    }

    function updateLiquidityWallet(address wallet) external onlyOwner {
        require(wallet != liquidityWallet, "This change has no effect");
        excludeFromFees(wallet);
        emit LiquidityWalletUpdated(wallet, liquidityWallet);
        liquidityWallet = wallet;
    }

    function updateMarketingWallet(address wallet) external onlyOwner {
        require(wallet != marketingWallet, "This change has no effect");
        excludeFromFees(wallet);
        emit MarketingWalletUpdated(wallet, marketingWallet);
        marketingWallet = wallet;
    }

    function updatePotWallet(address wallet) external onlyOwner {
        require(wallet != potWallet, "This change has no effect");
        excludeFromFees(wallet);
        emit PotWalletUpdated(wallet, potWallet);
        potWallet = wallet;
    }

    function updateLiquidationThreshold(uint256 qty) external onlyOwner {
        require(qty <= 500 * (10 ** 18), "Threshold is too high");
        require(qty != liquidateTokensAtQty, "This change has no effect");
        emit LiquidationThresholdUpdated(qty, liquidateTokensAtQty);
        liquidateTokensAtQty = qty;
    }

    function updateOrganicBlockOffset(uint256 offset) external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        require(offset <= 5, "Offset is too large");
        require(offset != organicBlockOffset, "This change has no effect");
        emit OrganicBlockOffsetUpdated(offset, organicBlockOffset);
        organicBlockOffset = offset;
    }

    function excludeFromFees(address account) public onlyOwner {
        excludedFromFees[account] = true;
    }

    function unexcludeFromFees(address account) public onlyOwner {
        excludedFromFees[account] = false;
    }

    function allowTransferBeforeTrading(address account) public onlyOwner {
        canTransferBeforeTrading[account] = true;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");

        // Only whitelisted addresses can make transfers before trading enabled.
        if (!tradingEnabled) {
            require(canTransferBeforeTrading[from], "Cannot transfer before trading");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canLiquidate = contractTokenBalance >= liquidateTokensAtQty;

        if (
            tradingEnabled &&
            canLiquidate &&
            !_liquidating &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet &&
            from != potWallet &&
            to != potWallet
        ) {
            _liquidating = true;

            // Send tokens to liquidity wallet.
            uint256 swapTokens = contractTokenBalance * LIQUIDITY_FEE / TOTAL_FEE;
            _swapAndLiquidate(swapTokens);

            // Send tokens to pot.
            uint256 potTokens = contractTokenBalance * POT_FEE / TOTAL_FEE;
            super._transfer(address(this), potWallet, potTokens);

            // Send tokens to marketing wallet.
            uint256 marketingTokens = contractTokenBalance * MARKETING_FEE / TOTAL_FEE;
            super._transfer(address(this), marketingWallet, marketingTokens);

            // Burn remaining tokens.
            _burn(address(this), contractTokenBalance - swapTokens - potTokens - marketingTokens);

            _liquidating = false;
        }

        bool takeFee = tradingEnabled && !_liquidating;

        // Remove fees if either account is whitelisted.
        if (excludedFromFees[from] || excludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = amount * (_isOrganic(block.number) ? TOTAL_FEE : INORGANIC_FEE) / 100;
            super._transfer(from, address(this), fees);
            super._transfer(from, to, amount - fees);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function _swapAndLiquidate(uint256 tokens) private {
        // Split the contract balance into halves.
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        // Capture the contract's current BNB balance.
        // This is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract.
        uint256 initialBalance = address(this).balance;

        // Swap tokens for BNB.
        _swapTokensForBnb(half);

        // How much BNB did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // Add liquidity to PancakeSwap.
        _addLiquidity(otherHalf, newBalance);

        emit Liquidated(half, newBalance, otherHalf);
    }

    function _swapTokensForBnb(uint256 tokenAmount) private {
        // Generate the PancakeSwap pair path of token -> BNB.
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // Make the swap.
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB.
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // Approve token transfer to cover all possible scenarios.
        _approve(address(this), address(dexRouter), tokenAmount);

        // Add the liquidity.
        dexRouter.addLiquidityETH{value : bnbAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable.
            0, // Slippage is unavoidable.
            liquidityWallet,
            block.timestamp
        );
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "This change has no effect");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _isOrganic(uint256 blockNumber) private view returns (bool) {
        require(tradingEnabled, "Trading is not yet enabled");
        assert(activatedBlockNumber != 0);
        return activatedBlockNumber + organicBlockOffset < blockNumber;
    }

    // Events.
    event Liquidated(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);

    event LiquidationThresholdUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event LiquidityWalletUpdated(address indexed newValue, address indexed oldValue);

    event MarketingWalletUpdated(address indexed newValue, address indexed oldValue);

    event OrganicBlockOffsetUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event PotWalletUpdated(address indexed newValue, address indexed oldValue);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
}