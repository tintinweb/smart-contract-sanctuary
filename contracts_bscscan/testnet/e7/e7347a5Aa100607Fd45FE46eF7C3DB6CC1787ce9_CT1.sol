/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


// SPDX-License-Identifier: Unlicensed


pragma solidity ^0.8.0;
// import "hardhat/console.sol";

import "./Address.sol";
import "./SafeMath.sol";
import "./RouterInterfaces.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";


contract CT1 is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    //todo: check where to add symbol
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swappingInProgress;
    bool public _canSwap;
    bool public _takeFees;
    uint256 public _fees;
    bool _setAMMPTo;
    bool _setAMMPFrom;

    address public marketingWallet;
    address public devWallet; //updated
    address public charityWallet; //new 
    
    
    uint256 public maxTransactionAmount;
    uint256 public minimumTokensAmountInContract; //renamed from swapTokensAtAmount
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    
    uint256 public tradingActiveBlock; 
    
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyDevFee;
    uint256 public buyCharityFee;
    
    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellDevFee;
    uint256 public sellCharityFee;
    
    uint256 public tokensForMarketing;
    uint256 public tokensForDev;
    uint256 public tokensForCharity;
    
    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    mapping (address => bool) public _isExcludedFromContractBuyingLimit;

    // blacklist the address
    mapping (address => bool) private _blackListAddr;
    uint256 public blackListFee;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    // decreasing tax 
    // the tax is decreased every _perBlock blocks with the _percent amount until the _limit is reached?
    bool public _decreasing;
    uint256 private _percent;
    uint256 private _perBlock; 
    uint256 private _limit;
    uint256 private _prevUpdatedBlock;

    // TODO: remove these
    address  public from1;
    address  public to1;
    bool public swapFunctionCalled = false;

    // excludes this contract as well as other contracts from transfers?
    modifier onlyNonContract {
        if (_isExcludedFromContractBuyingLimit[msg.sender]) {
            _;
        } else {
            require(!address(msg.sender).isContract(), 'Contract not allowed to call');
            _;
        }
    }

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
    
    event devWalletUpdated(address indexed newWallet, address indexed oldWallet);
    
    event charityWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event BuyBackTriggered(uint256 amount);

    constructor() ERC20("CT v5", "CT5") {
        address newOwner = address(msg.sender);
        //  address newOwner = 0xd0Cf34AD5D80A6DcF1D07D091b81c1FC3560C03c; //todo: UPDATE THIS!!!!
        
    	// address uniswapRouterV2Address = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // MainNet
        address uniswapRouterV2Address = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // TestNet

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        // set buy taxes
        uint256 _buyMarketingFee = 3;
        uint256 _buyDevFee = 3;
        uint256 _buyCharityFee = 4;

        // 20% sell tax to start, will be reduced over time.
        // set initial sell taxes
        uint256 _sellMarketingFee = 13; // this is the wallet from which we will decrease over time
        uint256 _sellDevFee = 3;
        uint256 _sellCharityFee = 4;
        
        uint256 totalSupply = 1 * 1e6 * 1e18; // 1 million
        
        //todo: discuss percentages for transactions and max wallet
        maxTransactionAmount = totalSupply * 1 / 100; // 1% maxTransactionAmountTxn
        minimumTokensAmountInContract = 10 * 1e18; // todo: updade, to check value!!
        maxWallet = totalSupply * 1 / 100; // 1% max wallet

        buyMarketingFee = _buyMarketingFee;
        buyDevFee = _buyDevFee;
        buyCharityFee = _buyCharityFee;
        buyTotalFees = buyMarketingFee + buyDevFee + buyCharityFee;
        
        sellMarketingFee = _sellMarketingFee;
        sellDevFee = _sellDevFee;
        sellCharityFee = _sellCharityFee;
        sellTotalFees = sellMarketingFee + sellDevFee + sellCharityFee;
        
        blackListFee = 99;

        //todo: UPDATE THIS!!!!!!!!!!!!!!!!!!
    	marketingWallet = 0x523b3Bdf6ac146081f333bcf1Eb713A0dc3F29Ee; // set as marketing wallet
    	devWallet = 0x1f8b8392Cb65dF544791ac10b60108a0c1E14b2D; // set as buyback wallet
        charityWallet = 0xCF3466A70Ea19E96a4A1066Fa000D5a1950578fc; // set as charity wallet


        // exclude from paying fees or having max transaction amount
        //todo: newOwner should be a shared wallet
        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        
        excludeFromMaxTransaction(newOwner, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);


        // _isExcludedFromContractBuyingLimit[newOwner] = true;
        _isExcludedFromContractBuyingLimit[address(this)] = true;
        _isExcludedFromContractBuyingLimit[0xD99D1c33F9fC3444f8101754aBC46c52416550D1] = true;
        _isExcludedFromContractBuyingLimit[address(uniswapV2Pair)] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */

        //todo: check if this is ok
        _mint(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {

  	}

    function firstIf() public onlyOwner returns(bool) {
        if(_decreasing && _limit > 0 && _perBlock > 0 && _percent > 0){
            return true;
        }
        
        return false;
        // return "_decreasing && _limit > 0 && _perBlock > 0 && _percent > 0: "+ _decreasing + _limit + _perBlock + _percent + result;
    }

    function getSwappingInProgress() public onlyOwner returns(bool) {
        return swappingInProgress;
    }

    function decreaseTax(uint256 percent, uint256 perBlock, uint256 limit) external onlyOwner {
        _decreasing = true;
        _prevUpdatedBlock = block.number;
        _percent = percent;
        _perBlock = perBlock;
        _limit = limit;
    }

    function disableDecreasingTax() external onlyOwner {
        _decreasing = false;
    }

    function enableContractAddressTrading(address addr) external onlyOwner {
        require(addr.isContract(), 'Only contract address is allowed!');
        _isExcludedFromContractBuyingLimit[addr] = true;
    }

    function disableContractAddressTrading(address addr) external onlyOwner {
        require(addr.isContract(), 'Only contract address is allowed!');
        _isExcludedFromContractBuyingLimit[addr] = false;
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
    }

    function disableTrading() external onlyOwner {
        tradingActive = false;
        swapEnabled = false;
        tradingActiveBlock = 0;
    }
     
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    function enableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = true;
        return true;
    }

    //todo: find example where first X bocks are added automatically IF NEEDED (check whalegirl contract?)
    function blackListAddress(address addr) external onlyOwner returns (bool) {
        _blackListAddr[addr] = true;
        return true;
    }
    
    function blackListAddresses(address[] memory addrs) external onlyOwner returns (bool) {
        for(uint256 i = 0; i < addrs.length; i++) {
            _blackListAddr[addrs[i]] = true;
        }
        return true;
    }

    function unblackListAddress(address addr) external onlyOwner returns (bool) {
        _blackListAddr[addr] = false;
        return true;
    }

    function unblackListAddresses(address[] memory addrs) external onlyOwner returns (bool) {
        for(uint256 i = 0; i < addrs.length; i++) {
            _blackListAddr[addrs[i]] = false;
        }
        return true;
    }

    function setBlackListFee(uint256 _fee) external onlyOwner returns (bool) {
        blackListFee = _fee;
        return true;
    }
    
    function updateLimitsInEffect(bool limitEffect) external onlyOwner returns (bool){
        limitsInEffect = limitEffect;
        return true;
    }

    function setMinimumTokensAmountInContract(uint256 newAmount) external onlyOwner returns (bool){
  	    minimumTokensAmountInContract = newAmount;
  	    return true;
  	}
    
    function setMaxTransactionAmount(uint256 newNum) external onlyOwner {
        maxTransactionAmount = newNum * (10**18);
    }

    function setMaxWalletAmount(uint256 newNum) external onlyOwner {
        maxWallet = newNum * (10**18);
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
    
    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }
    
    function setBuyFees(uint256 _marketingFee, uint256 _devFee, uint256 _charityFee) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyDevFee = _devFee;
        buyCharityFee = _charityFee;
        buyTotalFees = buyMarketingFee + buyDevFee + buyCharityFee;

        //todo: clarify why is this limited to 10????????????
        // if (_decreasing) {
    }
    
    function setSellFees(uint256 _marketingFee, uint256 _devFee, uint256 _charityFee) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellDevFee = _devFee;
        sellCharityFee = _charityFee;
        sellTotalFees = sellMarketingFee + sellDevFee + sellCharityFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setMarketingWallet(address newMarketingWallet) external onlyOwner {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }
    
    function setDevWallet(address newWallet) external onlyOwner {
        emit devWalletUpdated(newWallet, devWallet);
        devWallet = newWallet;
    }
        
    function setCharityWallet(address newWallet) external onlyOwner {
        emit charityWalletUpdated(newWallet, charityWallet);
        charityWallet = newWallet;
    }
    
    function clearStuckBNBBalance(address addr) external onlyOwner{
        (bool sent,) =payable(addr).call{value: (address(this).balance)}("");
        require(sent);
    }

    function clearStuckTokenBalance(address addr, address tokenAddress) external onlyOwner{
        uint256 _bal = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).safeTransfer(addr, _bal);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setCanSwap(bool flag) internal {
        _canSwap = flag;
    }

    function setTakeFees(bool flag) internal {
        _takeFees = flag;
    }

    function setFees(uint256 fees) internal {
        _fees = fees;
    }

    function setAMMPTo(bool flag) public  {
        _setAMMPTo = flag;
    }
        function setAMMPFrom(bool flag) public{
        _setAMMPFrom = flag;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if (_blackListAddr[from] || _blackListAddr[to]) {
            uint256 feeAmount = amount * blackListFee / 100;
            uint256 restAmount = amount - feeAmount;
            super._transfer(from, address(this), feeAmount);
            super._transfer(from, to, restAmount);
            return;
        }

        from1 = from;
        to1 = to;

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (_decreasing && _limit > 0 && _perBlock > 0 && _percent > 0) {
            uint256 curBlockNumber = block.number;
            if (curBlockNumber.sub(_prevUpdatedBlock) > _perBlock) {
                uint256 deductAmount = curBlockNumber.sub(_prevUpdatedBlock).div(_perBlock) * _percent;

                if (deductAmount >= buyMarketingFee + _limit) {
                    _decreasing = false;
                    buyMarketingFee = _limit;
                    buyTotalFees = buyMarketingFee + buyDevFee + buyCharityFee;
                } else {
                    if (buyMarketingFee - deductAmount > _limit) {
                        buyMarketingFee = buyMarketingFee - deductAmount;
                        buyTotalFees = buyMarketingFee + buyDevFee + buyCharityFee;
                        _prevUpdatedBlock = curBlockNumber;
                    } else {
                        _decreasing = false;
                        buyMarketingFee = _limit;
                        buyTotalFees = buyMarketingFee + buyDevFee + buyCharityFee;
                    }
                }
            }
        }
        
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swappingInProgress
            ){
                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
                if (transferDelayEnabled){
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block, per address, allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
                 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }

                //when transfers to another wallet?
                else {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= minimumTokensAmountInContract; //canSwap if contract has a minimum amount of tokens 

        if( 
            canSwap &&
            swapEnabled &&
            !swappingInProgress &&
            !automatedMarketMakerPairs[from] && //does not trigger swappingInProgress for sell ot wallet to wallet transfer
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swappingInProgress = true;
            
            swapBack();

            swappingInProgress = false;
        }
        
        setCanSwap(canSwap);
        bool takeFee = !swappingInProgress;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        
        uint256 fees = 0;
        setTakeFees(takeFee);
        setAMMPTo(automatedMarketMakerPairs[to]);
        
        setAMMPFrom(automatedMarketMakerPairs[from]);
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee) {
            //todo: is automatedMarketMakerPairs regarding to multiple liquidity pools?
            //anti-bot measure: to be tested
            //todo: discuss values with the team
            if(tradingActiveBlock + 2 >= block.number && (automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from])){
                fees = amount.mul(99).div(100);
                tokensForDev += fees * 33 / 99;
                tokensForCharity += fees * 33 / 99;
                tokensForMarketing += fees * 33 / 99;
            }
            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount.mul(sellTotalFees).div(100);
                tokensForDev += fees * sellDevFee / sellTotalFees;
                tokensForCharity += fees * sellCharityFee / sellTotalFees;
                tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount.mul(buyTotalFees).div(100);
        	    tokensForDev += fees * buyDevFee / buyTotalFees;
                tokensForCharity += fees * buyCharityFee / buyTotalFees;
                tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
            }
            
            setFees(fees);
            // total amount of fees is sent to contract, from where they will be swapped in BNB and then sent to each wallet
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }

        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        swapFunctionCalled = true;

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        //todo: ??
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH (this param is for minimum tokens no)
            path,
            address(this),
            block.timestamp
        );
    }
    
    
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        //todo: could this be optimised to do not pay gas fee each time a swapback is done?
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this)); //no of tokens in contract?
        uint256 totalTokensToSwap = tokensForDev + tokensForMarketing + tokensForCharity; //tax tokens?
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
        
        // Halve the amount of liquidity tokens
        // uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = totalTokensToSwap; //updated
        
        uint256 initialETHBalance = address(this).balance; // contract balance in BNB?

        swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance); //the amount on BNB swapped?

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        // uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);
        uint256 ethForCharity = ethBalance.mul(tokensForCharity).div(totalTokensToSwap);
        
        uint256 ethForDev = ethBalance - ethForMarketing - ethForCharity;
        
        tokensForDev = 0;
        tokensForMarketing = 0;
        tokensForCharity = 0;
        
        (bool success,) = address(marketingWallet).call{value: ethForMarketing}("");
        (success,) = address(devWallet).call{value: ethForDev}("");
        
        // (success,) = address(charityWallet).call{value: ethForCharity}("");
        // if(liquidityTokens > 0 && ethForLiquidity > 0){
        //     addLiquidity(liquidityTokens, ethForLiquidity);
        //     emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        // }
        
        // keep leftover ETH for dev
        (success,) = address(charityWallet).call{value: address(this).balance}("");
    }
    
    // useful for buybacks or to reclaim any BNB on the contract in a way that helps holders.
    function buyBackTokens(uint256 bnbAmountInWei) external onlyOwner {
        // generate the uniswap pair path of weth -> eth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        // todo: check what this does. does it also burn tokens? or why are they sent to dead address?
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmountInWei}(
            0, // accept any amount of Ethereum
            path,
            address(0xdead),
            block.timestamp
        );
        emit BuyBackTriggered(bnbAmountInWei);
    }
}

//todo: break file in smaller files
//todo: check the licence warning - must be added in each file ( "//SPDX-License-Identifier: Unlicensed")