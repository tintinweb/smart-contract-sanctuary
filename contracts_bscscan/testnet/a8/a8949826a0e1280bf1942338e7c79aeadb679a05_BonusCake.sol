// SPDX-License-Identifier: MIT


pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IERC20.sol";


interface ILP {
    function sync() external;
}


contract BonusCake is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    event SwapEnabled(bool enabled);


    // Used for authentication
    address public master;

    // LP atomic sync
    address public lp;
    ILP public lpContract;

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }

    // Only the owner can transfer tokens in the initial phase.
    // This is allow the AMM listing to happen in an orderly fashion.

    bool public initialDistributionFinished;

    mapping (address => bool) allowTransfer;

    // modifier initialDistributionLock {
    //     require(initialDistributionFinished || owner() || allowTransfer[msg.sender]);
    //     _;
    // }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }
    
    
    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**15 * 10**DECIMALS;
    
    
    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;
    

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    IERC20 WBNB = IERC20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
    address public immutable CAKE = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd); //CAKE

    bool private swapping;

    BonusCakeDividendTracker public dividendTracker;

    uint256 public swapTokensAtAmount = 20000000 * (10**18);
    uint256 public luckTokensAtAmount = 10**15;
    uint256 public _maxTxAmount = 50000000 * (10**18);
    uint256 public minLuckHold = 5000000 * (10**18);

    uint256 public _fees = 15;
    uint256 public _buyFees = 15;

    uint256 public _CAKEReward = 40;
    uint256 public _project = 40;
    uint256 public _liquidity = 5;

    address payable public  _projectAddress = 0x059E8918969a7FDE4921a1889a357C397D461593;
    address payable public liquidityWallet = 0xa89c75e94440A826b1F9ba13090fF98215662801;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    struct LuckRecord {
        address addr;
        uint256 amount;
    }
    mapping(uint256 => LuckRecord) public luckRecord;
    uint256 public nextLuckId;

    mapping (address => bool) public blacklist;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event FixedSaleEarlyParticipantsAdded(address[] participants);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event FixedSaleBuy(address indexed account, uint256 indexed amount, bool indexed earlyParticipant, uint256 numberOfBuyers);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendLuck(
        address luckAddress,
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

    constructor() public ERC20("Bonus Cake", "BonusCake") {
        dividendTracker = new BonusCakeDividendTracker();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        
        setLP(_uniswapV2Pair);
        
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        initialDistributionFinished = false;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        
        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {
    }
    
     /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMaster
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        lpContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }


    /**
     * @notice Sets a new master
     */
    function setMaster(address _master)
        external
        onlyOwner
        returns (uint256)
    {
        master = _master;
    }

        /**
     * @notice Sets contract LP address
     */
    function setLP(address _lp)
        public
        onlyOwner
        returns (uint256)
    {
        lp = _lp;
        lpContract = ILP(_lp);
    }

    
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BonusCake: The dividend tracker already has that address");

        BonusCakeDividendTracker newDividendTracker = BonusCakeDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BonusCake: The new dividend tracker must be owned by the BonusCake token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BonusCake: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BonusCake: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function BonusCakeexcludeFromDividends(address addr) public onlyOwner {
        dividendTracker.excludeFromDividends(addr);
    }
    
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BonusCake: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BonusCake: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateLiquidityWallet(address payable newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "BonusCake: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BonusCake: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BonusCake: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function updateL(uint256 l) public onlyOwner {
        luckTokensAtAmount = l;
    }

    function updateS(uint256 s) public onlyOwner {
        swapTokensAtAmount = s;
    }

    function updateM(uint256 m) public onlyOwner {
        _maxTxAmount = m;
    }
    
    function updateLUCKHODL(uint256 LUCKHODL) public onlyOwner {
        minLuckHold = LUCKHODL;
    }

    function updateSellFees(uint256 sellFees) public onlyOwner {
        _fees = sellFees;
    }

    function updateBuyFees(uint256 buyFees) public onlyOwner {
        _buyFees = buyFees;
    }

    function updateCAKEReward(uint256 CAKEReward) public onlyOwner {
        _CAKEReward = CAKEReward;
    }

    function updateProject(uint256 project) public onlyOwner {
        _project = project;
    }

    function updateLiquidity(uint256 liquidity) public onlyOwner {
        _liquidity = liquidity;
    }

    function setAddress(address payable projectAddress) public onlyOwner {
        _projectAddress = projectAddress;
    }

    function setAddress(address addr, bool isBlack) public onlyOwner {
        blacklist[addr] = isBlack;
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
        dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function contractInfo() external view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 total = dividendTracker.totalDividendsDistributed();
        return (WBNB.balanceOf(uniswapV2Pair), balanceOf(address(uniswapV2Pair)), msg.sender.balance, balanceOf(msg.sender),  address(this).balance, balanceOf(address(this)),  total);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        require(!blacklist[from], "BonusCake: from in blacklist");
        require(!blacklist[to], "BonusCake: to in blacklist");
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;

            uint256 swapTokens = contractTokenBalance.mul(_liquidity).div(100);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }

        sendLuckBonus();

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            uint256 fees;
            if(automatedMarketMakerPairs[from]) {
                fees = amount.mul(_buyFees).div(100);
            }else{
                fees = amount.mul(_fees).div(100);
            }
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
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

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
    
    function swapTokensForCake(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = CAKE;

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
            liquidityWallet,
            block.timestamp
        );
        
    }

    function swapAndSendDividends(uint256 tokens) private {
        uint256 initialBalance = IERC20(CAKE).balanceOf(address(this));
        swapTokensForCake(tokens);
        uint256 newBalance = IERC20(CAKE).balanceOf(address(this)).sub(initialBalance);
        
        uint256 h8 = newBalance.mul(_project).div(95);
        IERC20(CAKE).transfer(_projectAddress, h8);

        h8 = newBalance.mul(_CAKEReward).div(95);
        bool success = IERC20(CAKE).transfer(address(dividendTracker), h8);
        if (success) {
            dividendTracker.distributeCAKEDividends(h8);
            emit SendDividends(tokens, newBalance);
        }
    }
    
        function setInitialDistributionFinished()
        external
        onlyOwner
    {
        initialDistributionFinished = true;
    }

    function enableTransfer(address _addr)
        external
        onlyOwner
    {
        allowTransfer[_addr] = true;
    }
    

    function sendLuckBonus() private {
        uint256 luckAmount = luckTokensAtAmount;
        if (IERC20(CAKE).balanceOf(address(this)) >= luckAmount){
            address luckAddress = dividendTracker.getLuckAddress();
            if(balanceOf(address(luckAddress)) >= minLuckHold){
                bool success = IERC20(CAKE).transfer(luckAddress, luckAmount);
                if (success) {
                    uint256 id = nextLuckId;
                    luckRecord[id].addr = luckAddress;
                    luckRecord[id].amount = luckAmount;
                    nextLuckId++;
                    emit SendLuck(luckAddress, luckAmount);
                }
            }
        }
    }
}

contract BonusCakeDividendTracker is Ownable, DividendPayingToken {
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

    constructor() public DividendPayingToken("BonusCake_Dividend_Tracker", "BonusCake_Dividend_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "BonusCake_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "BonusCake_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BonusCake contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "BonusCake_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BonusCake_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getLuckAddress() public view onlyOwner returns(address) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
        uint256 rand = _randomByModulus(numberOfTokenHolders);
        return tokenHoldersMap.getKeyAtIndex(rand);
    }

    function _randomByModulus(uint256 numberOfTokenHolders) private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))).mod(numberOfTokenHolders);
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
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
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

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();   // remaining gas

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