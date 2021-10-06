// SPDX-License-Identifier: MIT

//
// $DHNETWORK proposes an innovative feature in its contract.
//
// 📱 Telegram: https://t.me/Diamondhandsnetwork
// 🌎 Website: https://diamondhandsnetwork.app
// 🌐 Twitter: https://twitter.com/D_H_Network
//

pragma solidity ^0.6.2;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract DiamondHandsNetworkToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    bool public projectWalletsFounded;

    address public constant DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant TOTAL_SUPPLY = 1000000 * (10**18);

    uint256 public _minBalanceToEmptyWallet = 500 * (10**18);

    uint256 public _swapTokensAtAmount = 2500 * (10**18);

    mapping(address => bool) public _isBlacklisted;

    mapping(address => bool) public _isSniperBot;

    uint256 public _maxDailyTxPercentage = 10;

    uint256 public liquidityFee = 10;
    uint256 public marketingFee = 5;
    uint256 public totalFees = liquidityFee.add(marketingFee);

    uint256 private launchedAt;

    //multisig marketing wallet
    address payable public _marketingWalletAddress = payable(0xDEC550DFE34a56E0804B733fFE3b09CE7Bed1e9F);

    //multisig treasury wallet
    address payable public _treasuryWalletAddress = payable(0x56819053E939F264bdFEE89F7E3bE95BA54175Dc);

    address[] public _teamWallets =  [
        0xBB2B9D571ffec7Fcd71E6c238bCAE508EC649274,
        0x57145d2c11F6c49e1D5AeBcd18B557a367a0748d,
        0xf7A085f84ba6dAa4d49c7a6Fe71AE1EB245af7BB,
        0x3B00203adc45B35Afd3354ad5185119e6d1840bC,
        0xAf34AA18cdaaD85300c310C58C16498aaD3F4A59,
        0xcbcAA9865386663Ad9da3fBdb3F5EA5A638EaAD4,
        0xb064ac78c21096f69dE062c64dAbe768c20B28d3
    ];


    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) private _isExcludedFromTransferLimits;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 private constant TOKENS_MKT = 200000 * (10**18);

    uint256 public _sellWait = 86400;

    uint256 public _maxWalletSize = 15000 * (10**18);
    uint256 public _maxTxAmount = 1000 * (10**18);

    uint256 public lockPeriod = 7889238;

    struct SellsHistory {
        uint256 sellTime;
        uint256 salesAmount;
    }

    mapping (address => SellsHistory) public _sellsHistoryPerAddress;

    mapping (address => uint256) public _teamWalletsLockTime;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event ExcludeFromTransferLimits(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SellWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor() public ERC20("Diamond Hands Network", "$DHN") {

        //Pancakeswap bsc mainnet
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // Create a uniswap pair for this new token
        IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        address _uniswapV2Pair = _uniswapV2Factory.createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);


        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(_treasuryWalletAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0), true);
        //excludeFromFees(address(_uniswapV2Router), true);

        excludeFromTransferLimits(address(this), true);
        excludeFromTransferLimits(owner(), true);
        excludeFromTransferLimits(address(0), true);
        excludeFromTransferLimits(DEAD_WALLET, true);
        excludeFromTransferLimits(_marketingWalletAddress, true);
        excludeFromTransferLimits(_treasuryWalletAddress, true);
        excludeFromTransferLimits(address(_uniswapV2Router), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */

        _mint(owner(), TOTAL_SUPPLY);
        fundAndLockTeamAndMarketingWallets();
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "DHNET#1");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            excludeFromTransferLimits(pair, true);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromTransferLimits(address account) public view returns(bool) {
        return _isExcludedFromTransferLimits[account];
    }

    function _canSell(address from, uint256 amount) external view returns(bool){
        return canSell(from, amount);
    }


    function canSell(address from, uint256 amount) private view returns(bool){
        // If address is excluded from fees or is the owner of the contract or is the contract we allow all transfers to avoid probles with liquidity or dividends
        if (_isExcludedFromFees[from]){
            return true;
        }

        uint256 walletBalance = balanceOf(from);
        // If walletBalance <=  _minBalanceToEmptyWallet tokens let them sell all.
        if(walletBalance <= _minBalanceToEmptyWallet && _sellsHistoryPerAddress[from].sellTime.add(_sellWait) < block.timestamp){
            return true;
        }
        // If wallet is trying to sell more than 10% of it's balance we won't allow the transfer
        if(walletBalance > 0 && amount > walletBalance.mul(_maxDailyTxPercentage).div(100)){
            return false;
        }
        // If time of last sell plus waiting time is greater than actual time we need to check if addres is trying to sell more than 10%
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) >= block.timestamp){
            uint256 maxSell = walletBalance.add(_sellsHistoryPerAddress[from].salesAmount).mul(_maxDailyTxPercentage).div(100);
            return _sellsHistoryPerAddress[from].salesAmount.add(amount) < maxSell;
        }
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) < block.timestamp){
            return true;
        }
        return false;
    }

    function getTimeUntilNextTransfer(address from) external view returns(uint256){
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) > block.timestamp){
            return _sellsHistoryPerAddress[from].sellTime.add(_sellWait).sub(block.timestamp);
        }
        return 0;
    }

    function updateAddressLastSellData(address from, uint256 amount) private {
        // If tiem of last sell plus waiting time is lower than the actual time is either a first sale or waiting time has expired
        // We can reset all struct values for this address
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) < block.timestamp){
            _sellsHistoryPerAddress[from].salesAmount = amount;
            _sellsHistoryPerAddress[from].sellTime = block.timestamp;
            return;
        }
        _sellsHistoryPerAddress[from].salesAmount += amount;
    }

    // This should limit the wallet tokens to _maxWalletSize
    function _maxWalletReached(address to) external view returns (bool) {
        return maxWalletReached(to, 0);
    }

    // This should limit the wallet tokens to _maxWalletSize
    function maxWalletReached(address to, uint256 amount) private view returns (bool) {
        if(_isExcludedFromTransferLimits[to]){
            return false;
        }
        uint256 amountToBuy = amount;
        if (!_isExcludedFromFees[to] && amount != 0){
        	uint256 fees = amount.mul(totalFees).div(100);
            amountToBuy = amount.sub(fees);
        }
        return balanceOf(to).add(amountToBuy) >= _maxWalletSize;
    }

    function _isTeamWalletLocked(address who) external view returns (bool){
        return isTeamWalletLocked(who);
    }

    function isTeamWalletLocked(address who) private view returns (bool){
        bool isTeamWallet = false;
        for (uint i = 0; i < _teamWallets.length; i++){
            if(_teamWallets[i] == who){
                isTeamWallet = true;
                break;
            }
        }
        return isTeamWallet && _teamWalletsLockTime[who] > block.timestamp;
    }

    function cloneSellDataToTransferWallet(address to, address from) private {
        _sellsHistoryPerAddress[to].salesAmount = _sellsHistoryPerAddress[from].salesAmount;
        _sellsHistoryPerAddress[to].sellTime = _sellsHistoryPerAddress[from].sellTime;

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "DHNET#4");
        require(to != address(0), "DHNET#5");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "DHNET#6");
        require(!isTeamWalletLocked(to) && !isTeamWalletLocked(from), "DHNET#7");
        require(!_isSniperBot[from], "DHNET#7");

        if(launchedAt == 0 && from == owner() && automatedMarketMakerPairs[to]) {
			launchedAt = block.number;
		}

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

	    uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

        bool isTransferBetweenWallets = to != address(this) && from != address(this) && !automatedMarketMakerPairs[to]
            && !automatedMarketMakerPairs[from] && to != owner() && from != owner();

        if (isTransferBetweenWallets){
            cloneSellDataToTransferWallet(to, from);
            super._transfer(from, to, amount);
            return;
        }

        bool removingLiq = ( automatedMarketMakerPairs[from] && to == address(uniswapV2Router) )
            || ( to == owner() && from == address(uniswapV2Router) );

        bool addingLiq = (automatedMarketMakerPairs[to] && from == owner());

        if(!_isExcludedFromFees[to] && !_isExcludedFromFees[from] && !addingLiq && !removingLiq ) {
            require(amount <= _maxTxAmount, "DHNET#8");
        }

        if (automatedMarketMakerPairs[from]){
            require(!maxWalletReached(to, amount), "DHNET#9");
        }

        if(automatedMarketMakerPairs[to] && !_isExcludedFromTransferLimits[from]){
            require(canSell(from, amount), "DHNET#10");
            updateAddressLastSellData(from, amount);
        }


        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner() &&
            from != _marketingWalletAddress &&
            to != _marketingWalletAddress &&
            from != _treasuryWalletAddress &&
            to != _treasuryWalletAddress &&
            !removingLiq
        ) {

            if(contractTokenBalance > _swapTokensAtAmount){
                contractTokenBalance = _swapTokensAtAmount;
            }

            swapTokensForFees(contractTokenBalance);

        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFees account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || addingLiq || removingLiq) {
            takeFee = false;
        }

        if(takeFee) {


        	if(block.number <= (launchedAt + 10) && automatedMarketMakerPairs[from] && to != address(uniswapV2Router) && to != address(this) && to != owner()) {
        	    totalFees += 45;
        	    _isSniperBot[to] = true;
        	}else if (_isSniperBot[to]){
        	    totalFees += 45;
        	}

        	uint256 fees = amount.mul(totalFees).div(100);
        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);


        }

        super._transfer(from, to, amount);


    }


    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(_swapTokensAtAmount != newAmount, "DHNET#20");
        _swapTokensAtAmount = newAmount;
    }

    function swapTokensForFees() public onlyOwner{
        uint256 contractTokenBalance = balanceOf(address(this));
        swapTokensForFees(contractTokenBalance);
    }


    function swapTokensForFees(uint256 contractTokenBalance) private{

        swapping = true;

        uint256 tokensForMarketing = contractTokenBalance.mul(marketingFee).div(totalFees);
        uint256 tokensForLiquidity = contractTokenBalance.mul(liquidityFee).div(totalFees);

        uint256 halfLiq = tokensForLiquidity.div(2);

        uint256 tokensForSwap = contractTokenBalance.sub(halfLiq);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // swap tokens for ETH
        swapTokensForEth(tokensForSwap, path);

        uint[] memory mktAmounts = uniswapV2Router.getAmountsOut(tokensForMarketing, path);
        _marketingWalletAddress.transfer(mktAmounts[1]);


        uint[] memory liqAmounts = uniswapV2Router.getAmountsOut(halfLiq, path);
        addLiquidity(halfLiq, liqAmounts[1]);

        swapping = false;

    }

    function swapTokensForEth(uint256 tokenAmount, address[] memory path)  private{

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
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            //address(0),
	        owner(),
            block.timestamp
        );

    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(_maxTxAmount != maxTxAmount, "DHNET#23");
        _maxTxAmount = maxTxAmount;
    }

    function updateMinBalanceToEmptyWallet(uint256 newAmount) external onlyOwner {
        require(_minBalanceToEmptyWallet != newAmount, "DHNET#11");
        _minBalanceToEmptyWallet = newAmount;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "DHNET#11");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function fundAndLockTeamAndMarketingWallets() private {
        require(!projectWalletsFounded, "DHNET#13");
        super._transfer(owner(), address(_marketingWalletAddress), TOKENS_MKT);
        super._transfer(owner(), address(_treasuryWalletAddress), TOKENS_MKT);
        uint256 lockUntil = block.timestamp.add(lockPeriod);
        uint256 balance = _maxWalletSize;
        for (uint i = 0; i < _teamWallets.length; i++){
            excludeFromFees(_teamWallets[i], true);
            if(i > 4){
                balance = _maxWalletSize.div(2);
            }
            super._transfer(owner(), _teamWallets[i], balance);
            _teamWalletsLockTime[_teamWallets[i]] = lockUntil;
            excludeFromFees(_teamWallets[i], false);
        }
        projectWalletsFounded = true;
    }

    receive() external payable {

  	}


    function updateSellWait(uint256 newSellWait) external onlyOwner {
        require(newSellWait != _sellWait, "DHNET#14");
        emit SellWaitUpdated(newSellWait, _sellWait);
        _sellWait = newSellWait;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "DHNET#17");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        excludeFromTransferLimits(address(_uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "DHNET#18");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromTransferLimits(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromTransferLimits[account] != excluded, "DHNET#19");
        _isExcludedFromTransferLimits[account] = excluded;

        emit ExcludeFromTransferLimits(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        require(_marketingWalletAddress != wallet, "DHNET#24");
        excludeFromFees(_marketingWalletAddress, false);
        excludeFromTransferLimits(_marketingWalletAddress, false);
        _marketingWalletAddress = wallet;
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromTransferLimits(_marketingWalletAddress, true);
    }

    function setTreasuryWallet(address payable wallet) external onlyOwner{
        require(_treasuryWalletAddress != wallet, "DHNET#25");
        excludeFromFees(_treasuryWalletAddress, false);
        excludeFromTransferLimits(_treasuryWalletAddress, false);
        _treasuryWalletAddress = wallet;
        excludeFromFees(_treasuryWalletAddress, true);
        excludeFromTransferLimits(_treasuryWalletAddress, true);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        require(liquidityFee != value && liquidityFee < 15, "DHNET#29");
        liquidityFee = value;
        totalFees = liquidityFee.add(marketingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        require(marketingFee != value && liquidityFee < 10, "DHNET#30");
        marketingFee = value;
        totalFees = liquidityFee.add(marketingFee);

    }

    function blacklistAddress(address account, bool value) external onlyOwner{
        require(_isBlacklisted[account] != value, "DHNET#31");
        _isBlacklisted[account] = value;
    }
}