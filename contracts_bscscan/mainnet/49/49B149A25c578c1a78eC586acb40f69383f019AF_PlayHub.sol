// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./ERC20Dividends.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract PlayHub is ERC20Dividends, Pausable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) public _isAllowedDuringDisabled;
    mapping(address => bool) public _isIgnoredAddress;

    // Anti-bot and anti-whale mappings and variables for launch
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public ammPairs;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // to track last sell to reduce sell penalty over time by 10% per week the holder sells *no* tokens.
    mapping (address => uint256) public _holderLastSellDate;

    uint256 public maxSellTransactionAmount; /// MAX TRANSACTION that can be sold

    uint256 public _maxSellPercent = 99; // Set the maximum percent allowed on sale per a single transaction

    uint256 public _sellFeeLiquidity = 2; // in percent
    uint256 public _sellFeeDividends = 3; // in percent
    uint256 public _sellFeeOperations = 3; // in percent
    uint256 public _sellFeeBurn = 2; // in percent

    uint256 public _buyFeeLiquidity = 2; // in percent
    uint256 public _buyFeeDividends = 4; // in percent
    uint256 public _buyFeeOperations = 4; // in percent
    uint256 public _buyFeeBurn = 0; // in percent

    // trackers for contract Tokens
    uint256 public tokensLiquidity = 0;
    uint256 public tokensOperations = 0;
    uint256 public ethOperations = 0;

    address public liquidityWallet;
    address public operationsWallet;

    bool public isOperationsETH = false;
    bool public isETHCollecting = false;
    uint256 public minETHToTransfer = 10**17; // 0.1 BNB

    bool private processing = false;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event OperationsWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event BuyFeesUpdated(uint256 newLiquidityFee, uint256 newDividendsFee, uint256 newOperationsFee, uint256 newBurnFee);
    event SellFeesUpdated(uint256 newLiquidityFee, uint256 newDividendsFee, uint256 newOperationsFee, uint256 newBurnFee);

    event BurnFeeUpdated(uint256 newFee, uint256 oldFee);

    event Received(address indexed sender, uint256 value);

    event TradeAttemptOnInitialLocked(address indexed from, address indexed to, uint256 amount);

    // event ProcessLiquidity(
    //     uint256 tokensSwapped,
    //     uint256 ethReceived,
    //     uint256 tokensIntoLiqudity
    // );

    // event ProcessOperations(
    //     uint256 tokensSwapped,
    //     uint256 ethReceived,
    //     uint256 tokensIntoLiqudity
    // );

    constructor() ERC20("PlayHub", "PLH") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(MODERATOR_ROLE, _msgSender());

        liquidityWallet = _msgSender();
        operationsWallet = _msgSender();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet 
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Testnet 

         // Create a uniswap pair for this new token
        // address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //     .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        // uniswapV2Pair = _uniswapV2Pair;

        // _setEnabledAMMPair(_uniswapV2Pair, true);

        _dividendsClaimWait = 3600;

        // exclude from receiving dividends
        super._excludeFromDividends(address(this));
        super._excludeFromDividends(liquidityWallet);
        super._excludeFromDividends(address(0x000000000000000000000000000000000000dEaD)); // dead address should NOT take tokens!!!
        super._excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(_msgSender(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(liquidityWallet), true);
        excludeFromFees(address(operationsWallet), true);
        
        _isAllowedDuringDisabled[address(this)] = true;
        _isAllowedDuringDisabled[_msgSender()] = true;
        _isAllowedDuringDisabled[liquidityWallet] = true;
        _isAllowedDuringDisabled[address(uniswapV2Router)] = true;

        _mint(msg.sender, 1 * 10 ** 9 * 10 ** decimals());

        _minimumBalanceForDividends = totalSupply() / 100000;
        maxSellTransactionAmount = totalSupply() / 1000;

        _pause();
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        super._transfer(account, address(0), amount);
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    // @dev ADMIN start -------------------------------------
    
    // remove transfer delay after launch
    function disableTransferDelay() external onlyRole(ADMIN_ROLE) {
        transferDelayEnabled = false;
    }
    
    // updates the maximum amount of tokens that can be bought or sold by holders
    function updateMaxTxn(uint256 maxTxnAmount) external onlyRole(ADMIN_ROLE) {
        maxSellTransactionAmount = maxTxnAmount;
    }

    // updates the default router for selling tokens
    function updateUniswapV2Router(address newAddress) external onlyRole(ADMIN_ROLE) {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    // excludes wallets from max txn and fees.
    function excludeFromFees(address account, bool excluded) public onlyRole(MODERATOR_ROLE) {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // allows multiple exclusions at once
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyRole(MODERATOR_ROLE) {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    
    function addToWhitelist(address wallet, bool status) external onlyRole(MODERATOR_ROLE) {
        _isAllowedDuringDisabled[wallet] = status;
    }
    
    function setIsBot(address wallet, bool status) external onlyRole(MODERATOR_ROLE) {
        _isIgnoredAddress[wallet] = status;
    }
    
    // allow adding additional AMM pairs to the list
    function setEnabledAMMPair(address pair, bool value) external onlyRole(ADMIN_ROLE) {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from market maker pairs");
        _setEnabledAMMPair(pair, value);
    }
    
    // sets the wallet that receives LP tokens to lock
    function updateLiquidityWallet(address newLiquidityWallet) external onlyRole(ADMIN_ROLE) {
        require(newLiquidityWallet != liquidityWallet, "The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }
    
    // updates the operations wallet (marketing, charity, etc.)
    function updateOperationsWallet(address newOperationsWallet) external onlyRole(ADMIN_ROLE) {
        require(newOperationsWallet != operationsWallet, "The operations wallet is already this address");
        excludeFromFees(newOperationsWallet, true);
        emit OperationsWalletUpdated(newOperationsWallet, operationsWallet);
        operationsWallet = newOperationsWallet;
    }
    
    // rebalance Buy fees
    function updateBuyFees(uint256 liquidityPrc, uint256 dividendsPrc, uint256 operationsPrc, uint256 burnPrc) external onlyRole(ADMIN_ROLE) {
        require(liquidityPrc <= 5, "Liquidity fee must be under 5%");
        require(dividendsPrc <= 5, "Dividends fee must be under 5%");
        require(operationsPrc <= 5, "Operations fee must be under 5%");
        require(burnPrc <= 5, "Burn fee must be under 5%");
        emit BuyFeesUpdated(liquidityPrc, dividendsPrc, operationsPrc, burnPrc);
        _buyFeeLiquidity = liquidityPrc;
        _buyFeeDividends = dividendsPrc;
        _buyFeeOperations = operationsPrc;
        _buyFeeBurn = burnPrc;
    }

    // rebalance Sell fees
    function updateSellFees(uint256 liquidityPrc, uint256 dividendsPrc, uint256 operationsPrc, uint256 burnPrc) external onlyRole(ADMIN_ROLE) {
        require(liquidityPrc <= 5, "Liquidity fee must be under 5%");
        require(dividendsPrc <= 5, "Dividends fee must be under 5%");
        require(operationsPrc <= 5, "Operations fee must be under 5%");
        require(burnPrc <= 5, "Burn fee must be under 5%");
        emit BuyFeesUpdated(liquidityPrc, dividendsPrc, operationsPrc, burnPrc);
        _sellFeeLiquidity = liquidityPrc;
        _sellFeeDividends = dividendsPrc;
        _sellFeeOperations = operationsPrc;
        _sellFeeBurn = burnPrc;
    }

    function setMaxSellPercent(uint256 maxSellPercent) public onlyRole(ADMIN_ROLE) {
        require(maxSellPercent < 100, "Max sell percent must be under 100%");
        _maxSellPercent = maxSellPercent;
    }

    function setOperationsInBNB(bool operationsInBNB) public onlyRole(ADMIN_ROLE) {
        require(operationsInBNB != isOperationsETH, "Already set to same value.");
        isOperationsETH = operationsInBNB;
    }

    function setOperationsBNBCollecting(bool operationsCollectingBNB) public onlyRole(ADMIN_ROLE) {
        require(operationsCollectingBNB != isETHCollecting, "Already set to same value.");
        isETHCollecting = operationsCollectingBNB;
    }

    function updateOperationsMinBNB(uint256 minBNB) external onlyRole(ADMIN_ROLE) {
        require(minBNB != minETHToTransfer, "Already set to same value.");
        minETHToTransfer = minBNB;
    }

    // @dev VIEWS ------------------------------------
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    // function getNumberOfDividendTokenHolders() external view returns(uint256) {
    //     // TODO: requires implementation
    // }
    
    function getDividendsMinimum() external view returns (uint256) {
        return _minimumBalanceForDividends;
    }
    
    function getDividendsClaimWait() external view returns(uint256) {
        return _dividendsClaimWait;
    }

    function getTotalDividends() external view returns (uint256) {
        return totalDividends;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return _withdrawableDividendOf(account);
    }

    function dividendsPaidTo(address account) public view returns(uint256) {
        return paidDividendsTo[account];
    }

    function withdrawDividends(address account) public {
        maybeProcessDividendsFor(account);
    }

    /// EXTERNAL STUFF

    function excludeFromDividends(address holder) external onlyRole(MODERATOR_ROLE) {
        super._excludeFromDividends(holder);
    }

    function includeInDividends(address holder) external onlyRole(MODERATOR_ROLE) {
        super._includeInDividends(holder);
    }

    function updateDividendsClaimWait(uint256 newClaimWait) external onlyRole(ADMIN_ROLE) {
        super._updateDividendsClaimWait(newClaimWait);
    }

    function updateDividendsMinimum(uint256 minimumToEarnDivs) external onlyRole(ADMIN_ROLE) {
        super._updateDividendsMinimum(minimumToEarnDivs);
    }

    // Liquidity utils

    function addLiquidityBNB() external payable whenNotPaused {
        uint256 ethHalf = msg.value / 2;
        uint256 otherHalf = msg.value - ethHalf;

        uint256 tokensBefore = balanceOf(_msgSender());

        bool origFeeStatus = _isExcludedFromFees[_msgSender()];
        _isExcludedFromFees[_msgSender()] = true;

        swapEthForTokens(ethHalf);

        _isExcludedFromFees[_msgSender()] = origFeeStatus;

        uint256 tokensAfter = balanceOf(_msgSender());

        uint256 tokensAmount = tokensAfter - tokensBefore;
        super._transfer(_msgSender(), address(this), tokensAmount);


        uint256 liqTokens;
        uint256 liqETH;
        uint256 liq;
        (liqTokens, liqETH, liq) = addUserLiquidity(tokensAmount, otherHalf);

        uint256 remainingETH = msg.value - ethHalf - liqETH;
        uint256 remainingTokens = tokensAmount - liqTokens;

        if (remainingTokens > 0) {
            super._transfer(address(this), _msgSender(), remainingTokens);
        }

        if (remainingETH > 0) {
            (bool success,) = _msgSender().call{value:remainingETH}(new bytes(0));
            require(success, "ETH Transfer Failed");
        }
    }

    // Token Functions

    function _setEnabledAMMPair(address pair, bool value) private {
        require(ammPairs[pair] != value, "Automated market maker pair is already set to that value");
        ammPairs[pair] = value;

        if(value) {
            super._excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!_isIgnoredAddress[to] || !_isIgnoredAddress[from], "To/from address is ignored");

        if(paused()) {
            if (!_isAllowedDuringDisabled[from] && !_isAllowedDuringDisabled[to]) {
                emit TradeAttemptOnInitialLocked(from, to, amount);
            }

            require(_isAllowedDuringDisabled[to] || _isAllowedDuringDisabled[from], "Trading is currently disabled");

            if(ammPairs[to] && _isAllowedDuringDisabled[from]) {
                require((hasRole(ADMIN_ROLE, from) || hasRole(ADMIN_ROLE, to)) || _isAllowedDuringDisabled[from], "Only dev can trade against PCS during migration");
            }
        }

        // early exit with no other logic if transfering 0 (to prevent 0 transfers from triggering other logic)
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // Prevent buying more than 1 txn per block at launch. Bot killer. Will be removed shortly after launch.
        if (transferDelayEnabled) {
            if (!hasRole(ADMIN_ROLE, to) && to != address(uniswapV2Router) && to != address(uniswapV2Pair) && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]){
                require(_holderLastTransferTimestamp[to] < block.timestamp, "_transfer: Transfer Delay enabled.  Please try again later.");
                _holderLastTransferTimestamp[to] = block.timestamp;
            }
        }

        // set last sell date to first purchase date for new wallet
        if(!isContract(to) && !_isExcludedFromFees[to]){
            if(_holderLastSellDate[to] == 0){
                _holderLastSellDate[to] == block.timestamp;
            }
        }
        
        // update sell date on buys to prevent gaming the decaying sell tax feature.  
        // Every buy moves the sell date up 1/3rd of the difference between last sale date and current timestamp
        if(!isContract(to) && ammPairs[from] && !_isExcludedFromFees[to]){
            if(_holderLastSellDate[to] >= block.timestamp){
                _holderLastSellDate[to] = _holderLastSellDate[to] + ((block.timestamp - _holderLastSellDate[to]) / 3);
            }
        }
        
        if(ammPairs[to]){
            if(!_isExcludedFromFees[from]) {
                require(amount <= maxSellTransactionAmount, "Max Tx amount exceeded");
                uint256 maxPermittedAmount = balanceOf(from) * _maxSellPercent / 100; // Maximum sell % per one single transaction, to ensure some loose change is left in the holders wallet .
                if (amount > maxPermittedAmount) {
                    amount = maxPermittedAmount;
                }
            }
        }

        // maybe pay dividends to both parties
        maybeProcessDividendsFor(from);
        maybeProcessDividendsFor(to);

        bool takeFee = (ammPairs[from] || ammPairs[to]); // tax only buy and sell
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || from == address(this)) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 liquidityAmount = 0;
            uint256 dividendsAmount = 0;
            uint256 operationsAmount = 0;
            uint256 burnAmount = 0;

            // if sell, multiply by holderSellFactor (decaying sell penalty by 10% every 2 weeks without selling)
            if(ammPairs[to]) {
                liquidityAmount = amount * _sellFeeLiquidity / 100;
                dividendsAmount = amount * _sellFeeDividends / 100;
                operationsAmount = amount * _sellFeeOperations / 100;
                burnAmount = amount * _sellFeeBurn / 100;

                _holderLastSellDate[from] = block.timestamp; // update last sale time              
            }
            else if (ammPairs[from]) {
                liquidityAmount = amount * _buyFeeLiquidity / 100;
                dividendsAmount = amount * _buyFeeDividends / 100;
                operationsAmount = amount * _buyFeeOperations / 100;
                burnAmount = amount * _buyFeeBurn / 100;
            }

            uint256 feesAmount = liquidityAmount + dividendsAmount + operationsAmount + burnAmount;
            amount = amount - feesAmount;

            super._transfer(from, address(this), feesAmount);

            addDividends(dividendsAmount);

            tokensLiquidity += liquidityAmount;
            tokensOperations += operationsAmount;
            if (!ammPairs[from] && !processing) {
                processing = true;
                processLiquidity();
                processOperations();
                processing = false;
            }
            
            if (burnAmount > 0) {
                _burn(address(this), burnAmount);
            }
        }

        super._transfer(from, to, amount);
        
        updateDividendability(from);
        updateDividendability(to);
    }

    function processLiquidity() private {
        uint256 tokens = tokensLiquidity;
        uint256 halfTokensForSwap = tokens / 2;
        uint256 otherHalf = tokens - halfTokensForSwap;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(halfTokensForSwap);

        uint256 addedBalance = address(this).balance - initialBalance;

        addLiquidity(otherHalf, addedBalance);
        
        tokensLiquidity -= tokens;
        // emit ProcessLiquidity(halfTokensForSwap, addedBalance, otherHalf);
    }

    function processOperations() private {
        uint256 tokenAmount = tokensOperations;
        if (isOperationsETH) {
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(tokenAmount);
            uint256 addedBalance = address(this).balance - initialBalance;

            if (isETHCollecting) {
                ethOperations += addedBalance;
                if (ethOperations >= minETHToTransfer) {
                    bool success;
                    (success,) = payable(operationsWallet).call{value: ethOperations}("");
                    require(success, "processOperations: Unable to send BNB to Operations Wallet");
                    ethOperations = 0;
                }
            }
            else {
                bool success;
                (success,) = payable(operationsWallet).call{value: addedBalance}("");
                require(success, "processOperations: Unable to send BNB to Operations Wallet");
            }
        }
        else {
            super._transfer(address(this), operationsWallet, tokenAmount);
        }
        tokensOperations -= tokenAmount;
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

    function swapEthForTokens(uint256 ethAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of tokens
            path,
            _msgSender(),
            block.timestamp
        );     
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function addUserLiquidity(uint256 tokenAmount, uint256 ethAmount) private returns(uint256 liqTokens, uint256 liqETH, uint256 liq) {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        (liqTokens, liqETH, liq) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _msgSender(),
            block.timestamp
        );
    }

    function recoverContractBNB(uint256 recoverRate) public onlyRole(ADMIN_ROLE){
        uint256 bnbAmount = address(this).balance;
        if(bnbAmount > 0){
            sendToOperationsWallet(bnbAmount * recoverRate / 100);
        }
    }

    function recoverContractTokens(uint256 recoverRate) public onlyRole(ADMIN_ROLE){
        uint256 tokenAmount = balanceOf(address(this));
        if(tokenAmount > 0){
            super._transfer(address(this), operationsWallet, tokenAmount * recoverRate / 100);
        }
    }

	function sendToOperationsWallet(uint256 amount) private {
        payable(operationsWallet).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

abstract contract ERC20Dividends is ERC20 {
    uint256 private magnifier = 10**18;

    uint256 internal _minimumBalanceForDividends;

    uint256 internal totalDividends = 0; // only increase
    uint256 private unpaid = 0;
    uint256 private totalDividendable = 0; // sum of balances with minimum for Dividends

    // mapping(address => bool) private isDividendable;
    mapping(address => uint256) private dividendableBalance;
    mapping(address => uint256) private snapTotalForLastPay;

    mapping (address => bool) public isDividendsExcluded;
    mapping (address => uint256) public dividedsLastClaimTime;

    mapping (address => uint256) public paidDividendsTo;

    uint256 internal _dividendsClaimWait;

    /// EVENTS
    event ExcludeFromDividends(address indexed holder);
    event IncludeInDividends(address indexed holder);
    event DividendsClaimWaitUpdated(uint256 newValue, uint256 oldValue);
    event DividendsClaim(address indexed account, uint256 amount);

    function addDividends(uint256 dividendsAmount) internal {
        totalDividends += dividendsAmount;
        unpaid += dividendsAmount;
    }

    function maybeProcessDividendsFor(address holder) internal {
        if (isDividendable(holder) && totalDividends > snapTotalForLastPay[holder]) {
            uint256 deltaDividends = totalDividends - snapTotalForLastPay[holder];

            uint256 dividendsPerTokenMagnified = deltaDividends * magnifier / totalDividendable;
            uint256 dividends = balanceOf(holder) * dividendsPerTokenMagnified / magnifier;

            snapTotalForLastPay[holder] = totalDividends;
            unpaid -= dividends;
            paidDividendsTo[holder] += dividends;

            super._transfer(address(this), holder, dividends); 
        }
    }

    function updateDividendability(address holder) internal {
        if (isDividendsExcluded[holder]) {
            if (isDividendable(holder)) {
                totalDividendable -= dividendableBalance[holder];
                dividendableBalance[holder] = 0;
            }
        }
        else {
            bool shouldReceiveDividends = (balanceOf(holder) >= _minimumBalanceForDividends);
            if (shouldReceiveDividends) { 
                if (isDividendable(holder)) {
                    totalDividendable = totalDividendable + balanceOf(holder) - dividendableBalance[holder];
                    dividendableBalance[holder] = balanceOf(holder);
                }
                else {
                    totalDividendable += balanceOf(holder);
                    dividendableBalance[holder] = balanceOf(holder);
                    snapTotalForLastPay[holder] = totalDividends;
                }
            }
            else { 
                if (isDividendable(holder)) {
                    totalDividendable -= dividendableBalance[holder];
                    dividendableBalance[holder] = 0;
                }
            }
        }

    }

    function isDividendable(address holder) view public returns (bool) {
        return (dividendableBalance[holder] > 0);
    }

    function claimDividends(address holder) internal {
        require(!isDividendsExcluded[holder], "Account excluded from dividends");
        require(isDividendable(holder), "Condition for dividends NOT met");
        require(totalDividends > snapTotalForLastPay[holder], "All dividends already paid");

        maybeProcessDividendsFor(holder);
    }

    function _excludeFromDividends(address holder) internal {
        require(!isDividendsExcluded[holder]);
        isDividendsExcluded[holder] = true;

        if (isDividendable(holder)) {
            totalDividendable -= dividendableBalance[holder];
            dividendableBalance[holder] = 0;
        }

        emit ExcludeFromDividends(holder);
    }

    function _includeInDividends(address holder) internal {
        require(isDividendsExcluded[holder]);
        isDividendsExcluded[holder] = false;
        emit IncludeInDividends(holder);
    }

    function _updateDividendsClaimWait(uint256 newDividendsClaimWait) internal {
        require(newDividendsClaimWait >= 3600 && newDividendsClaimWait <= 86400, "dividendsClaimWait must be between 1 and 24 hours");
        require(newDividendsClaimWait != _dividendsClaimWait, "Cannot update dividendsClaimWait to same value");
        emit DividendsClaimWaitUpdated(newDividendsClaimWait, _dividendsClaimWait);
        _dividendsClaimWait = newDividendsClaimWait;
    }

    function _updateDividendsMinimum(uint256 minimumToEarnDivs) internal {
        require(minimumToEarnDivs != _minimumBalanceForDividends, "Cannot update DividendsMinimum to same value");
        _minimumBalanceForDividends = minimumToEarnDivs;
    }

    function _withdrawableDividendOf(address holder) internal view returns(uint256) {
        uint256 dividends = 0;
        if (isDividendable(holder) && totalDividends > snapTotalForLastPay[holder]) {
            uint256 deltaDividends = totalDividends - snapTotalForLastPay[holder];
            uint256 dividendsPerTokenMagnified = deltaDividends * magnifier / totalDividendable;
            dividends = balanceOf(holder) * dividendsPerTokenMagnified / magnifier;
        }

        return dividends;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        // require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

// SPDX-License-Identifier: MIT
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