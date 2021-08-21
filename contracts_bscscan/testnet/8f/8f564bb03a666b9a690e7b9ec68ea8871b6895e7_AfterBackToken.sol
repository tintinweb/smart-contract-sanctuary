//SPDX-License-Identifier:  MIT

pragma solidity ^0.8.4;

/*
Name: AfterBackToken.Com
Symbol: AFTRBCK
Supply: 100 Million
Decimals: 9

8% for Dividends in ETH
3% to Dev Wallet in Tokens
4% to Dev Wallet in ETH

15% Total Fees
Whale Protection: 1%
*/

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

import "./AfterBackDividendTracker.sol";
import "./IterableMapping.sol";

contract AfterBackToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "AfterBackToken.Com";
    string private _symbol = "AFTRBCK";
    uint8 private _decimals = 18;
    uint256 private  _totalSupply = 1e8 * 1e18;

    uint256 public ETHRewardsFee = 8;
    uint256 public devETHFee = 4;
    uint256 public devTokenFee = 3;
    uint256 public totalFees = ETHRewardsFee + devETHFee + devTokenFee; // 15%

    uint256 public maxSellTransactionAmount = 1e6 * 1e18; // (1mill)
    uint256 public swapTokensAtAmount = 1e5 * 1e18; // (100k)

    AfterBackDividendTracker public dividendTracker;

    address payable public devWallet;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    // exclude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;


    bool private swapping;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event DevWalletUpdated(address indexed newDevWallet, address indexed oldDevWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );


    constructor() ERC20(_name, _symbol) {

        dividendTracker = new AfterBackDividendTracker();

        devWallet = payable(0x5C1232C335c963a052F86A7949e6369dEacF9AdC);

        // Initial Dex Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        // Create a Dex pair for this new token on this Router
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(devWallet));
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        excludeFromFees(devWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(),  _totalSupply);
    }

    receive() external payable { }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "AFTRBCK: The dividend tracker already has that address");

        AfterBackDividendTracker newDividendTracker = AfterBackDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "AFTRBCK: The new dividend tracker must be owned by the AFTRBCK token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        dividendTracker = newDividendTracker;

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

    }

    function setNewRouterAddress(address _newRouterAddress) external onlyOwner {
        require(_newRouterAddress != address(0), "AFTRBCK: Router can not be the zero address");
        require(_newRouterAddress != address(uniswapV2Router), "AFTRBCK: This is the current router");

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_newRouterAddress);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .getPair(address(this), _uniswapV2Router.WETH());

        // If the pair doesn't exist on the new dex, create it.
        if(uniswapV2Pair == address(0))
        {
            // create the new pair for the new router
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        }

        emit UpdateUniswapV2Router(_newRouterAddress, address(uniswapV2Router));

    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "AFTRBCK: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "AFTRBCK: The UniSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "AFTRBCK: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateDevWallet(address newDevWallet) public onlyOwner {
        require(newDevWallet != devWallet, "AFTRBCK: The development wallet is already this address");
        require(newDevWallet != address(0), "AFTRBCK: The development wallet can not be the zero address");
        excludeFromFees(newDevWallet, true);
        devWallet = payable(newDevWallet);
        emit DevWalletUpdated(newDevWallet, devWallet);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000, "AFTRBCK: gasForProcessing must be more than 200,000");
        require(newValue != gasForProcessing, "AFTRBCK: Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;

        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "AFTRBCK: transfer from the zero address");
        require(to != address(0), "AFTRBCK: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(
            !swapping &&
        automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
        !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != devWallet &&
            to != devWallet
        ) {
            contractTokenBalance = swapTokensAtAmount;

            uint256 ETHForRewards = contractTokenBalance.mul(calculateFees(ETHRewardsFee)).div(1e2); // 53.33%
            uint256 tokensForDev = contractTokenBalance.mul(calculateFees(devTokenFee)).div(1e2); // 20%
            uint256 ETHForDev = contractTokenBalance.mul(calculateFees(devETHFee)).div(1e2); // 26.67%

            swapping = true;

            // ETH for development
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(ETHForDev);
            uint256 swappedBalance = address(this).balance.sub(initialBalance);
            transferToAddressETH(devWallet, swappedBalance);

            // Transfer tokens for Development
            super._transfer(address(this), devWallet, tokensForDev);

            // Send ETH Dividends
            swapAndSendDividends(ETHForRewards);

            swapping = false;
        }


        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount.mul(totalFees).div(1e2);

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch { }
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

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
            emit SendDividends(tokens, dividends);
        }
    }

    function calculateFees(uint256 fee) private view returns (uint256){
        return fee.mul(1e2).div(totalFees);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function setMaxSellTransactionAmount(uint256 TransactionAmount) external onlyOwner {
        maxSellTransactionAmount = TransactionAmount * 1e18;
    }

    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) external onlyOwner {
        swapTokensAtAmount = _swapTokensAtAmount * 1e18;
    }

    function setDevelopmentWallet(address _developmentWallet) external onlyOwner {
        devWallet = payable(_developmentWallet);
    }

    function setDevelopmentTokensFee(uint256 developmentTokensFee) external onlyOwner {
        devTokenFee = developmentTokensFee;
    }

    function setDevelopmentETHFee(uint256 developmentETHFee) external onlyOwner {
        devETHFee = developmentETHFee;
    }

    function prepareForILO() external onlyOwner {
        ETHRewardsFee = 0;
        devETHFee = 0;
        devTokenFee = 0;
        totalFees = 0;
        maxSellTransactionAmount = 1e8 * 1e18;
    }

    function afterILO() external onlyOwner {
        ETHRewardsFee = 8;
        devETHFee = 4;
        devTokenFee = 3;
        totalFees = ETHRewardsFee + devETHFee + devTokenFee;
        maxSellTransactionAmount = 1e6 * 1e18;
    }

}