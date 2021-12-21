// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BEP20.sol";
import "./IUniswapV2Router02.sol";

// UFGrainToken
contract UFGrainToken is BEP20 {
    //Initial capped at 300K
    uint256 private initialCap = 300000 * 10**18;
    // Supply capped at 10MM
    uint256 public cap = 10000000 * 10**18; //INMUTABLE

    // The operator is NOT the owner, is the operator of the machine
    address private _operator;

    // Addresses excluded from fees
    mapping (address => bool) private _isExcludedFromFee;

    // Addresses that are excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;

    // In swap and liquify
    bool private _inSwapAndLiquify;

    // Max holding rate in basis point. (default is 1% of total supply)
    // Transfers cannot result in a balance higher than the maxholdingrate*total supply
    // Except if the owner (masterchef) is interacting. Users would not be able to harvest rewards in edge cases
    // such as if an user has more than maxholding to harvest without this exception.
    // Addresses in the antiwhale exclude list can receive more too. This is for the liquidity pools and the token itself
    uint16 public maxHoldingRate = 100; // INMUTABLE 

    // Transfer tax rate in basis points. (default 3%)
    uint16 public transferTaxRate = 300; // INMUTABLE

    // Treasury rate % of transfer tax. (default 3% x 93% = 2.79% of total amount).
    uint16 public liquifyRate = 93; // INMUTABLE

    // UFGRAIN dev Fee address
    address public devAddress;

    // Min amount to liquify. (default 100 UFGRAIN)
    uint256 public minAmountToLiquify = 100 * 10**18; // INMUTABLE

    // PCS LP Token Address
    address public lpToken; // ONLY ONCE!

    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = true; // INMUTABLE

    // PCS Router Address
    IUniswapV2Router02 private PCSRouter; // INMUTABLE

    // Trading bool
    bool private tradingOpen; // ONLY ONCE!

    // Enable MaxHolding mechanism
    bool private _maxHoldingEnable = true; // INMUTABLE

    // Cooldown user mapping
    // mapping (address => User) private cooldown;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD; // INMUTABLE

    // User Struct, data of cooldown mapping
    struct User {
        uint256 lastTx;
        bool exists;
    }

    // Events before Governance
    event MaxHoldingRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event LPTokenTransferred(address indexed previousLpToken, address indexed newLpToken);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SwapAndLiquifyEnabledUpdated(address indexed operator, bool enabled);
    event UpdateDevAddress(address indexed devAddress);
    event MaxHoldingEnableUpdated(address indexed operator, bool enabled);
    event PCSRouterTransferred(address indexed oldPCSRouter, address indexed newPCSRouter);

    // Operator CAN do modifier
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    // Lock the swap on SwapAndLiquify
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    // Nulled Transfer Fee while SwapAndLiquify
    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    /// @dev Apply antiwhale only if the owner (masterchef) isn't interacting.
    /// If the receiver isn't excluded from antiwhale,
    /// check if it's balance is over the max Holding otherwise the second condition would end up with an underflow
    /// and that it's balance + the amount to receive doesn't exceed the maxholding. This doesn't account for transfer tax.
    /// if any of those two condition apply, the transfer will be rejected with the correct error message
    modifier antiWhale(address sender, address recipient, uint256 amount) {
        // Is maxHolding enabled?
        if(_maxHoldingEnable) {
            if (maxHolding() > 0 && sender != owner() && recipient != owner()) {
                if ( _excludedFromAntiWhale[recipient] == false ) {
                    require(amount <= maxHolding() - balanceOf(recipient) && balanceOf(recipient) <= maxHolding(), "UFGRAIN::antiWhale: Transfer amount would result in a balance bigger than the maxHoldingRate");
                }
            }
        }
        
        _;
    }

    /**z
     * @notice Constructs the UFGRAIN token contract.
     */
    constructor(address _PCSRouter, address _devAddress) public BEP20("United Farmers GRAIN", "UFGRAIN") {
        require(_devAddress != address(0), "UFGRAIN: dev address is zero");
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        devAddress = _devAddress;
        PCSRouter = IUniswapV2Router02(_PCSRouter);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(ufgrainSupply().add(_amount) <= cap, "UFGRAIN: cap exceeded");
        _mint(_to, _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of UFGRAIN
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        // Pre-flight checks
        require(amount > 0, "Transfer amount must be greater than zero");

        // swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(PCSRouter) != address(0)
            && lpToken != address(0)
            && sender != lpToken
            && sender != owner()
        ) {
            if (msg.sender == address(PCSRouter) && recipient == lpToken) {
                uint256 ethRouterBalance = address(PCSRouter).balance;
                if (ethRouterBalance == 0 && tradingOpen) {
                    swapAndLiquify();
                }
            }
        }

        if (sender == owner() || recipient == owner() || transferTaxRate == 0 || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient] && recipient != lpToken) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 ethRouterBalance = address(PCSRouter).balance;
            require(tradingOpen == true || recipient == lpToken && ethRouterBalance > 0, "Trading not yet open.");

            // default tax is 8% of every transfer
            uint256 taxAmount = amount.mul(transferTaxRate).div(10000);
            uint256 liquidityAmount = taxAmount.mul(liquifyRate).div(100);
            uint256 devAmount = taxAmount.sub(liquidityAmount);
            require(taxAmount == devAmount.add(liquidityAmount), "UFGRAIN::transfer: TreasuryAmount or LiquidityAmount value invalid");
            // default % of transfer sent to recipient
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount.add(taxAmount), "UFGRAIN::transfer: Tax value invalid");

            // Distributing UFGRAINs (Liquify, Recipient)
            super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, devAddress, devAmount);
            super._transfer(sender, recipient, sendAmount);     
        }
    }

    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap transferTaxFree {
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (contractTokenBalance >= minAmountToLiquify) {
            // only min amount to liquify
            uint256 liquifyAmount = minAmountToLiquify;

            // split the liquify amount into halves
            uint256 half = liquifyAmount.div(2);
            uint256 otherHalf = liquifyAmount.sub(half);
        
            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for BNB
            swapTokensForEth(half);

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);
            
            // add liquidity
            addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the UFGRAIN pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PCSRouter.WETH();

        _approve(address(this), address(PCSRouter), tokenAmount);

        // make the swap
        PCSRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Swap tokens for eth
    // function swapEthForTokens(uint256 tokenAmount) private {
    //     // generate the UFF pair path of token -> weth
    //     address[] memory path = new address[](2);
    //     path[0] = PCSRouter.WETH();
    //     path[1] = uffToken; 

    //     // make the swap
    //     PCSRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: tokenAmount}(
    //         0, // accept any amount of uff
    //         path,
    //         address(this),
    //         block.timestamp
    //     );
    // }

    /// @dev Add liquidity
    // function addLiquidity(address tokenAddress, uint256 tokenAmount, uint256 ethAmount) private {
    //     // approve token transfer to cover all possible scenarios
    //     IBEP20(tokenAddress).approve(address(PCSRouter), tokenAmount);

    //     // add the liquidity
    //     PCSRouter.addLiquidityETH{value: ethAmount}(
    //         tokenAddress,
    //         tokenAmount,
    //         0, // slippage is unavoidable
    //         0, // slippage is unavoidable
    //         operator(),
    //         block.timestamp
    //     );
    // }

        /// @dev Add liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(PCSRouter), tokenAmount);

        // add the liquidity
        PCSRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            operator(),
            block.timestamp
        );
    }

    /**
     * @dev Returns the max holding amount.
     */
    function maxHolding() public view returns (uint256) {
        return cap.mul(maxHoldingRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /** NO NEED TO CHANGE PCS ROUTER
     * @dev Transfers PCSRouter of the contract to a new address (`newPCSRouter`).
     * Can only be called by the current operator.
     */
    function transferPCSRouter(address newPCSRouter) public onlyOperator {
        require(newPCSRouter != address(0), "UFGRAIN::transferPCSRouter: new PCSRouter is the zero address");
        emit PCSRouterTransferred(address(PCSRouter), newPCSRouter);
        PCSRouter = IUniswapV2Router02(newPCSRouter);
    }

    /** 
     * @dev Update the swapAndLiquifyEnabled.
     * Can only be called by the current operator.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOperator {
        emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
        swapAndLiquifyEnabled = _enabled;
    }

    /** 
     * @dev Update the dev Address.
     * Can only be called by the current operator.
     */
    function updateDevAddress(address _devAddress) public onlyOperator {
        require(_devAddress != address(0), "UFGRAIN: dev address is zero");
        emit UpdateDevAddress(msg.sender);
        devAddress = _devAddress;
    }

    /** NO NEED TO CHANGE MAX_HOLDING_RATE
     * @dev Update the max holding rate.
     * Can only be called by the current operator.
     */
    // function updateMaxHoldingRate(uint16 _maxHoldingRate) public onlyOperator {
    //     require(_maxHoldingRate >= 100, "UFF::updateMaxHoldingRate: Max holding rate must not be below the minimum rate.");
    //     emit MaxHoldingRateUpdated(msg.sender, _maxHoldingRate, _maxHoldingRate);
    //     maxHoldingRate = _maxHoldingRate;
    // }

    /** 
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account) public onlyOperator {
        _excludedFromAntiWhale[_account] = true;
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    // /**
    //  * @dev Returns the bep token owner.
    //  */
    // function getOwner() external override view returns (address) {
    //     return owner();
    // }

    // Return actual supply of rice
    function ufgrainSupply() public view returns (uint256) {
        return totalSupply().sub(balanceOf(BURN_ADDRESS));
    }

    /**
     * @dev Transfers/Sets lpToken address to a new address (`newLpToken`).
     * Can only be called by the current operator.
     */
    function transferLpToken(address newLpToken) public onlyOperator {
        // Can transfer LP only once!
        require(lpToken == address(0), "UFGRAIN: LP Token Transfer can be only be set once");
        emit LPTokenTransferred(lpToken, newLpToken);
        lpToken = newLpToken;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "UFGRAIN::transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }
    
    /**
     * @dev Open trading (PCS) onlyOperator
     */
    function openTrading(bool bOpen) public onlyOperator {
        // Can open trading only once!
        tradingOpen = bOpen;
    }

    /**
     * @dev Add to exclude from fee.
     * Can only be called by the current operator.
     */
    function setExcludeFromFee(address _account, bool _trueOrFalse) public onlyOperator {
        _isExcludedFromFee[_account] = _trueOrFalse;
    }

    // To receive BNB from SwapRouter when swapping
    receive() external payable {}
}