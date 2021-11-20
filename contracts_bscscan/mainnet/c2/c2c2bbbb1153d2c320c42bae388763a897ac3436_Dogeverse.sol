// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Authorizable.sol";
import "./ERC20.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter.sol";
import "./SafeMath.sol";

contract Dogeverse is ERC20, Authorizable {
    using SafeMath for uint256;

    IPancakeRouter02 public dexRouter;
    address public immutable dexPair;

    bool private liquidating;
    address public liquidityWallet;

    // PancakeSwap router.
    address public constant ROUTER_ADDR = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // Marketing wallet.
    address public constant MARKETING_ADDR = 0xb35f36066aE1cB75307a2B33342dD130Bf9DE963;

    uint256 public constant MARKETING_FEE = 6;
    uint256 public constant LIQUIDITY_FEE = 2;
    uint256 public constant TOTAL_FEE = MARKETING_FEE + LIQUIDITY_FEE;

    // Liquidate tokens for BNB when the contract accumulates 100k tokens by default.
    uint256 public liquidateTokensAtAmount = 100000 * (10 ** 18);

    // Whether the token can already be traded.
    bool public tradingEnabled;

    function activate() public onlyAuthorized {
        require(!tradingEnabled, "Dogeverse: Trading is already enabled");
        tradingEnabled = true;
        activatedBlockNumber = block.number;
    }

    // Exclude eligible accounts from fees.
    mapping(address => bool) public excludedFromFees;

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event LiquidationThresholdUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Liquidated(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);

    constructor() ERC20("DOGEVERSE", "DOGEVERSE") {
        assert(TOTAL_FEE == 8);

        liquidityWallet = owner();

        // Create a PancakeSwap pair for this new token.
        IPancakeRouter02 _dexRouter = IPancakeRouter02(ROUTER_ADDR);
        address _dexPair = IPancakeFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());

        dexRouter = _dexRouter;
        dexPair = _dexPair;

        // Exclude from paying fees.
        excludeFromFees(liquidityWallet);
        excludeFromFees(address(this));

        // Enable owner wallet to transfer tokens before go-live.
        authorize(owner());

        /*
            _mint is an internal function in ERC20.sol that is only called here, and CANNOT be called ever again.
        */
        _mint(owner(), 1000000000 * (10 ** 18));
    }

    receive() external payable {}

    function excludeFromFees(address account) public onlyOwner {
        require(!excludedFromFees[account], "Dogeverse: Account is already fee exempt");
        excludedFromFees[account] = true;
    }

    function unexcludeFromFees(address account) public onlyOwner {
        require(excludedFromFees[account], "Dogeverse: Account is not fee exempt");
        excludedFromFees[account] = false;
    }

    function updateLiquidityWallet(address wallet) public onlyOwner {
        require(wallet != liquidityWallet, "Dogeverse: The liquidity wallet is already this address");
        excludeFromFees(wallet);
        emit LiquidityWalletUpdated(wallet, liquidityWallet);
        liquidityWallet = wallet;
    }

    function updateLiquidationThreshold(uint256 newValue) external onlyOwner {
        require(newValue <= 200000 * (10 ** 18), "Dogeverse: liquidateTokensAtAmount must be less than 200,000");
        require(newValue != liquidateTokensAtAmount, "Dogeverse: Cannot update liquidateTokensAtAmount to same value");
        emit LiquidationThresholdUpdated(newValue, liquidateTokensAtAmount);
        liquidateTokensAtAmount = newValue;
    }

    function whitelisted(address account) public view returns (bool) {
        return authorized(account) || excludedFromFees[account];
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // Only authorized addresses can make transfers before go-live.
        if (!tradingEnabled) {
            require(whitelisted(from), "Dogeverse: This account cannot send tokens until trading is enabled");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canLiquidate = contractTokenBalance >= liquidateTokensAtAmount;

        if (
            tradingEnabled &&
            canLiquidate &&
            !liquidating &&
            from != dexPair &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            liquidating = true;

            // Send tokens to liquidity wallet.
            uint256 swapTokens = contractTokenBalance.mul(LIQUIDITY_FEE).div(TOTAL_FEE);
            swapAndLiquidate(swapTokens);

            // Send remaining tokens to marketing wallet.
            super._transfer(address(this), MARKETING_ADDR, contractTokenBalance.sub(swapTokens));

            liquidating = false;
        }

        bool takeFee = tradingEnabled && !liquidating;

        // Remove fees if either account is whitelisted.
        if (whitelisted(from) || whitelisted(to)) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = amount.mul(isOrganic(block.number) ? TOTAL_FEE : INORGANIC_FEE).div(100);
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }

    function swapAndLiquidate(uint256 tokens) private {
        // Split the contract balance into halves.
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // Capture the contract's current BNB balance.
        // This is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract.
        uint256 initialBalance = address(this).balance;

        // Swap tokens for BNB.
        swapTokensForBnb(half);

        // How much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // Add liquidity to PancakeSwap.
        addLiquidity(otherHalf, newBalance);

        emit Liquidated(half, newBalance, otherHalf);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
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

    uint256 public constant INORGANIC_FEE = 60;
    uint256 public activatedBlockNumber;
    uint256 public organicBlockOffset = 0;

    event OrganicBlockOffsetUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    function isOrganic(uint256 blockNumber) private view returns (bool) {
        require(tradingEnabled, "Dogeverse: Trading is not yet enabled");
        assert(activatedBlockNumber != 0);
        return activatedBlockNumber + organicBlockOffset < blockNumber;
    }

    function updateOrganicBlockOffset(uint256 newValue) external onlyAuthorized {
        require(!tradingEnabled, "Dogeverse: Cannot update organic block offset once trading is enabled");
        require(newValue != organicBlockOffset, "Dogeverse: Cannot update organicBlockOffset to same value");
        emit OrganicBlockOffsetUpdated(newValue, organicBlockOffset);
        organicBlockOffset = newValue;
    }
}