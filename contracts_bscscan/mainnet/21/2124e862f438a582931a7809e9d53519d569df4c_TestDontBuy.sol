//Mainnet contract testing, liquidity will be pulled.
//Do not buy, you will get rekt.
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";


contract TestDontBuy is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    bool public canChangeFees = true;
    bool public canChangeMarketingWallet = true;
    bool public canBlacklist = true;

    DontBuyDividendTracker public dividendTracker;

    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public constant DontBuy = address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47); //DontBuy

    uint256 public constant swapTokensAtAmount = 2000000 * (10**18);

    mapping(address => bool) public isBlacklisted;

    uint256 public DontBuyRewardsFee = 8;
    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 5;
    uint256 public totalFees = DontBuyRewardsFee.add(liquidityFee).add(marketingFee);

    address public _marketingWalletAddress = 0xA51B67084e8dfdb0f0993F275C6627c6d64E2c30;

    uint256 public blacklistDeadline = 0;
    bool public tradingReady = false;


    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event PrepForLaunch(uint256 blocktime);

    event DisabledFeeChanging(bool disabled);
    event DisabledBlacklistAbility(bool disabled);
    event DisabledMarketingWalletChanges(bool disabled);

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

    constructor() public ERC20("DontBuy", "DontBuy") {


        dividendTracker = new DontBuyDividendTracker();


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
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
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);
    }

    function prepForLaunch() public onlyOwner {
        require(!tradingReady, "DontBuy: Contract has already been prepped for trading.");

        tradingReady = true; //once set to true, this function can never be called again.
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
        blacklistDeadline = now + 1 hours; //A maximum of 1 hour is given to blacklist snipers/flashbots

        //Init list of known frontrunner & flashbots for blacklisting
        // List of bots from t.me/FairLaunchCalls
        blacklistAddress(address(0xA39C50bf86e15391180240938F469a7bF4fDAe9a), true);
        blacklistAddress(address(0xFFFFF6E70842330948Ca47254F2bE673B1cb0dB7), true);
        blacklistAddress(address(0xD334C5392eD4863C81576422B968C6FB90EE9f79), true);
        blacklistAddress(address(0x20f6fCd6B8813c4f98c0fFbD88C87c0255040Aa3), true);
        blacklistAddress(address(0xC6bF34596f74eb22e066a878848DfB9fC1CF4C65), true);
        blacklistAddress(address(0x231DC6af3C66741f6Cf618884B953DF0e83C1A2A), true);
        blacklistAddress(address(0x00000000003b3cc22aF3aE1EAc0440BcEe416B40), true);
        blacklistAddress(address(0x42d4C197036BD9984cA652303e07dD29fA6bdB37), true);
        blacklistAddress(address(0x22246F9BCa9921Bfa9A3f8df5baBc5Bc8ee73850), true);
        blacklistAddress(address(0xbCb05a3F85d34f0194C70d5914d5C4E28f11Cc02), true);
        blacklistAddress(address(0x5B83A351500B631cc2a20a665ee17f0dC66e3dB7), true);
        blacklistAddress(address(0x39608b6f20704889C51C0Ae28b1FCA8F36A5239b), true);
        blacklistAddress(address(0x136F4B5b6A306091b280E3F251fa0E21b1280Cd5), true);
        blacklistAddress(address(0x4aEB32e16DcaC00B092596ADc6CD4955EfdEE290), true);
        blacklistAddress(address(0xe986d48EfeE9ec1B8F66CD0b0aE8e3D18F091bDF), true);
        blacklistAddress(address(0x59341Bc6b4f3Ace878574b05914f43309dd678c7), true);
        blacklistAddress(address(0xc496D84215d5018f6F53E7F6f12E45c9b5e8e8A9), true);
        blacklistAddress(address(0x39608b6f20704889C51C0Ae28b1FCA8F36A5239b), true);
        blacklistAddress(address(0xfe9d99ef02E905127239E85A611c29ad32c31c2F), true);
        blacklistAddress(address(0x9eDD647D7d6Eceae6bB61D7785Ef66c5055A9bEE), true);
        blacklistAddress(address(0x72b30cDc1583224381132D379A052A6B10725415), true);
        blacklistAddress(address(0x7100e690554B1c2FD01E8648db88bE235C1E6514), true);
        blacklistAddress(address(0x000000917de6037d52b1F0a306eeCD208405f7cd), true);
        blacklistAddress(address(0x59903993Ae67Bf48F10832E9BE28935FEE04d6F6), true);
        blacklistAddress(address(0x00000000000003441d59DdE9A90BFfb1CD3fABf1), true);
        blacklistAddress(address(0x0000000000007673393729D5618DC555FD13f9aA), true);
        blacklistAddress(address(0xA3b0e79935815730d942A444A84d4Bd14A339553), true);
        blacklistAddress(address(0x000000005804B22091aa9830E50459A15E7C9241), true);
        blacklistAddress(address(0x323b7F37d382A68B0195b873aF17CeA5B67cd595), true);
        blacklistAddress(address(0x6dA4bEa09C3aA0761b09b19837D9105a52254303), true);
        blacklistAddress(address(0x000000000000084e91743124a982076C59f10084), true);
        blacklistAddress(address(0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d), true);
        blacklistAddress(address(0xfad95B6089c53A0D1d861eabFaadd8901b0F8533), true);
        blacklistAddress(address(0x9282dc5c422FA91Ff2F6fF3a0b45B7BF97CF78E7), true);
        blacklistAddress(address(0x45fD07C63e5c316540F14b2002B085aEE78E3881), true);
        blacklistAddress(address(0xDC81a3450817A58D00f45C86d0368290088db848), true);
        blacklistAddress(address(0xFe76f05dc59fEC04184fA0245AD0C3CF9a57b964), true);
        blacklistAddress(address(0xd7d3EE77D35D0a56F91542D4905b1a2b1CD7cF95), true);
        blacklistAddress(address(0xa1ceC245c456dD1bd9F2815a6955fEf44Eb4191b), true);
        blacklistAddress(address(0xe516bDeE55b0b4e9bAcaF6285130De15589B1345), true);
        blacklistAddress(address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce), true);
        blacklistAddress(address(0x65A67DF75CCbF57828185c7C050e34De64d859d0), true);
        blacklistAddress(address(0xe516bDeE55b0b4e9bAcaF6285130De15589B1345), true);
        blacklistAddress(address(0x7589319ED0fD750017159fb4E4d96C63966173C1), true);
        blacklistAddress(address(0x0000000099cB7fC48a935BcEb9f05BbaE54e8987), true);
        blacklistAddress(address(0x03BB05BBa541842400541142d20e9C128Ba3d17c), true);

        emit PrepForLaunch(now);
    }

    receive() external payable {

    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "DontBuy: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        require(wallet != address(0), "DontBuy: Marketing wallet cannot be 0!");
        require(wallet != deadWallet, "DontBuy: Marketing wallet cannot be the dead wallet!");
        require(canChangeMarketingWallet == true, "DontBuy: The ability change the marketing wallet has been disabled.");
        _marketingWalletAddress = wallet;
    }

    function setDontBuyRewardsFee(uint256 value) external onlyOwner{
        require(value <= 10, "DontBuy: Maximum DontBuy Reward fee is 10%");
        require(canChangeFees == true, "DontBuy: The ability to update or change fees has been disabled.");
        DontBuyRewardsFee = value;
        totalFees = DontBuyRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setLiquidityFee(uint256 value) external onlyOwner{
        require(value <= 4, "DontBuy: Maximum Liquidity fee is 4%");
        require(canChangeFees == true, "DontBuy: The ability to update or change fees has been disabled.");
        liquidityFee = value;
        totalFees = DontBuyRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        require(value <= 5, "DontBuy: Maximum Marketing fee is 5%");
        require(canChangeFees == true, "DontBuy: The ability to update or change fees has been disabled.");
        marketingFee = value;
        totalFees = DontBuyRewardsFee.add(liquidityFee).add(marketingFee);
    }


    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "DontBuy: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value) public onlyOwner{
        require(canBlacklist == true, "DontBuy: The ability to blacklist / amnesty accounts has been disabled.");
        if (value) {
            require(now < blacklistDeadline, "DontBuy: The ability to blacklist accounts has been disabled.");
        }
        isBlacklisted[account] = value;
    }

    function disableBlacklist() external onlyOwner {
        canBlacklist = false;
        emit DisabledBlacklistAbility(true);
    }

    function disableFeeChanging() external onlyOwner {
        canChangeFees = false;
        emit DisabledFeeChanging(true);
    }

    function disableWalletChanging() external onlyOwner {
        canChangeMarketingWallet = false;
        emit DisabledMarketingWalletChanges(true);
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "DontBuy: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "DontBuy: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "DontBuy: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
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

    function dividendTokenBalanceOf(address account) external view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
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
        dividendTracker.processAccount(msg.sender, false);
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isBlacklisted[from] && !isBlacklisted[to], 'Blacklisted address');

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToFee(marketingTokens);

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);
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
            catch {

            }
        }
    }

    function swapAndSendToFee(uint256 tokens) private  {

        uint256 initialDontBuyBalance = IERC20(DontBuy).balanceOf(address(this));

        swapTokensForDontBuy(tokens);
        uint256 newBalance = (IERC20(DontBuy).balanceOf(address(this))).sub(initialDontBuyBalance);
        IERC20(DontBuy).transfer(_marketingWalletAddress, newBalance);
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

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        if (newBalance > 0) {
            addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
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

    function swapTokensForDontBuy(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = DontBuy;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
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
            address(0),
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForDontBuy(tokens);
        uint256 dividends = IERC20(DontBuy).balanceOf(address(this));
        bool success = IERC20(DontBuy).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeDontBuyDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}

contract DontBuyDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("DontBuyDvt", "DontBuyDvt") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "DontBuy_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "DontBuy_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main DontBuy contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "DontBuy_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "DontBuy_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }



    function getAccount(address _account)
    public view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableDividends,
        uint256 totalDividends,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilStartOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                0;


                iterationsUntilProcessed = index.add(int256(processesUntilStartOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
        lastClaimTime.add(claimWait) :
        0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
        nextClaimTime.sub(block.timestamp) :
        0;
    }

    function getAccountAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
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

        processAccount(account, true);
    }

    function process(uint256 gas) external returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}