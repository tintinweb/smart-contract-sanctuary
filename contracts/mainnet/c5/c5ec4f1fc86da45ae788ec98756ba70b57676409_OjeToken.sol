// SPDX-License-Identifier: MIT



pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";


contract OjeToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;
    bool private reinvesting;
    uint256 private maxPurchaseEnd;

    OjeDividendTracker public dividendTracker;

    address payable public marketingAddress = 0x7558d0076FbCfb2Ae4998DE1b92572540b112091;
    
    address payable public teamAddress1 = 0xAc41A27cea2001eDD15CD9821166B023c78B3a1D;
    address payable public teamAddress2 = 0x3643d9aCB9d0F47b956a5F4E33760411e51125e4; 
    address payable public teamAddress3 = 0xEaf8C5a7232FC02BcF22a3D93D04F65bd9f829Ee;
    
    address payable public deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    // unlock time for team tokens (420 years after launch)
    uint256 public lockEnd;
    
    // once set to true can never be set false again
    bool public tradingOpen = false;
    
    uint256 public launchTime;

    uint256 constant feePercentage = 14; // 14 percent total tax. Tax split: 4% marketing, 7% eth redistribution, 3% buyback
    uint256 constant marketingFee = 4;
    uint256 constant dividendsFee = 7;
    uint256 constant buybackFee = 3;
    
    uint256 minimumTokenBalanceForDividends = 42000 * (10**18);

    //maximum purchase amount for initial launch
    uint256 maxPurchaseAmount;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    
    mapping (address => bool) public isSniper;
    
    mapping (address => bool) public isLocked;
    
    
    // the last time an address transferred
    // used to detect if an account can be reinvest inactive funds to the vault
    mapping (address => uint256) public lastTransfer;
    
    
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SendDividends(uint256 amount);
    event DividendClaimed(uint256 ethAmount, uint256 tokenAmount, address account);

    constructor() public ERC20("OJE Token", "OJE") {
        
        dividendTracker = new OjeDividendTracker();
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        dividendTracker.excludeFromDividends(address(deadAddress));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        
        //lock team tokens
        isLocked[marketingAddress] = true;
        isLocked[teamAddress1] = true;
        isLocked[teamAddress2] = true;
        isLocked[teamAddress3] = true;
        
        _mint(owner(), 42000000000 * (10**18));
    }

    receive() external payable {

    }
    
    
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "OjeToken: The dividend tracker already has that address");

        OjeDividendTracker newDividendTracker = OjeDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "OjeToken: The new dividend tracker must be owned by the OjeToken contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "OjeToken: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "OjeToken: Account is already the value of 'excluded'");
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
        require(pair != uniswapV2Pair, "OjeToken: The UniSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "OjeToken: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
   
    function setMaxPurchaseAmount(uint256 newAmount) public onlyOwner {
        maxPurchaseAmount = newAmount;
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

    function reinvestInactive(address payable account) public onlyOwner {
        uint256 tokenBalance = dividendTracker.balanceOf(account);
        require(tokenBalance <= minimumTokenBalanceForDividends, "OjeToken: Account balance must be less then minimum token balance for dividends");

        uint256 _lastTransfer = lastTransfer[account];
        require(block.timestamp.sub(_lastTransfer) > 12 weeks, "OjeToken: Account must have been inactive for at least 12 weeks");
                
        dividendTracker.processAccount(account, address(this));
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
            emit SendDividends(dividends);
            try dividendTracker.setBalance(account, 0) {} catch {}        
        }
    }

    function claim(bool reinvest, uint256 minTokens) external {
        _claim(msg.sender, reinvest, minTokens);
    }
    
    function _claim(address payable account, bool reinvest, uint256 minTokens) private {
        uint256 withdrawableAmount = dividendTracker.withdrawableDividendOf(account);
        require(withdrawableAmount > 0, "OjeToken: Claimer has no withdrawable dividend");

        if (!reinvest) {
            uint256 ethAmount = dividendTracker.processAccount(account, account);
            if (ethAmount > 0) {
                emit DividendClaimed(ethAmount, 0, account);
            }
            return;
        }
        
        uint256 ethAmount = dividendTracker.processAccount(account, address(this));
    
        if (ethAmount > 0) {
            reinvesting = true;
            uint256 tokenAmount = swapEthForTokens(ethAmount, minTokens, account);
            reinvesting = false;
            emit DividendClaimed(ethAmount, tokenAmount, account);
        }
    }
    
    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function getAccount(address _account)
        public view returns (
            uint256 withdrawableDividends,
            uint256 withdrawnDividends,
            uint256 balance
            ) {
        (withdrawableDividends, withdrawnDividends) = dividendTracker.getAccount(_account);
        return (withdrawableDividends, withdrawnDividends, balanceOf(_account));
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require (!isSniper[from] && !isSniper[to], "Ops");
        if (block.timestamp < lockEnd) require (!isLocked[from]);

        // only owner can transfer before openTrading
        if(!tradingOpen) {
            require(from == owner() || to == owner());
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        // make sure amount does not exceed max on a purchase
        if (block.timestamp < maxPurchaseEnd && automatedMarketMakerPairs[from] && to!=owner()) {
            require(amount <= maxPurchaseAmount, "OjeToken: Exceeds max purchase amount");
        }
        
        //blacklist block 0 snipers
        if (block.timestamp == launchTime) {
            isSniper[to] = true;
            dividendTracker.excludeFromDividends(to);
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance > 0;

        if(
            canSwap &&
            !swapping &&
            !reinvesting &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapAndDistribute();
            swapping = false;
        }


        bool takeFee = !swapping && !reinvesting;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        // don't take a fee unless it's a buy / sell
        if((_isExcludedFromFees[from] || _isExcludedFromFees[to]) || (!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to])) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount.mul(feePercentage).div(100);
            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}        
        
        lastTransfer[from] = block.timestamp;
        lastTransfer[to] = block.timestamp;
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
    
    function swapEthForTokens(uint256 ethAmount, uint256 minTokens, address account) internal returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        uint256 balanceBefore = balanceOf(account);
        
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            minTokens,
            path,
            account,
            block.timestamp
        );
        
        uint256 tokenAmount = balanceOf(account).sub(balanceBefore);
        return tokenAmount;
    }
    
    function swapAndDistribute() private {
        
        uint256 initialBalance = address(this).balance;
        
        uint256 tokenBalance = balanceOf(address(this));
        swapTokensForEth(tokenBalance);
        
        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        
        uint256 marketingPortion = transferredBalance.mul(marketingFee).div(feePercentage);
        sendETHtoMarketing(marketingPortion);

        uint256 dividends = transferredBalance.mul(dividendsFee).div(feePercentage);
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
            emit SendDividends(dividends);
        }
    }
    
    
    function sendETHtoMarketing(uint256 amount) private {
        marketingAddress.transfer(amount);
    }
    
    function buyBackTokens(uint256 amount) public {
        require(_msgSender() == marketingAddress, 'only marketingAddress can call this function');
        require (amount <= address(this).balance, 'amount exceeds contract ETH balance');
        if (amount > 0) {
            swapETHForTokens(amount);
        }
    }
    
    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );
    }
    
    function updatemarketingAddress(address payable newAddress) public onlyOwner {
        marketingAddress = newAddress;
    }
    
    function updateTeamAddress1(address payable newAddress) public onlyOwner {
        teamAddress1 = newAddress;
    }
    
    function updateTeamAddress2(address payable newAddress) public onlyOwner {
        teamAddress2 = newAddress;
    }
    
    function updateTeamAddress3(address payable newAddress) public onlyOwner {
        teamAddress3 = newAddress;
    }
    
    function openTrading() external onlyOwner {
        tradingOpen = true;
        launchTime = block.timestamp;
        maxPurchaseAmount = 210000000 * (10**18); //maxPurchaseAmount = 1% supply;
        maxPurchaseEnd = block.timestamp + 2 minutes;
        lockEnd = block.timestamp + (420 * (365 days));
    }
}

contract OjeDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    mapping (address => bool) public excludedFromDividends;

    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);

    constructor() public DividendPayingToken("OJE_Dividend_Tracker", "OJE_Dividend_Tracker") {
        minimumTokenBalanceForDividends = 42000 * (10**18); //must hold 42000+ tokens
    }

    function _approve(address, address, uint256) internal override {
        require(false, "Oje_Dividend_Tracker: No approvals allowed");
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "Oje_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "Oje_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main OjeToken contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
    }

    function processAccount(address payable account, address payable toAccount) public onlyOwner returns (uint256) {
        uint256 amount = _withdrawDividendOfUser(account, toAccount);
        return amount;
    }
   
}