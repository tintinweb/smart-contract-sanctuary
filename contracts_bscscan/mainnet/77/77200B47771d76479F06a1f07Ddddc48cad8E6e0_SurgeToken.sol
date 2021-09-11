//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./ReentrantGuard.sol";
import "./IERC20.sol";
import "./INativeSurge.sol";
/**
 * Contract: Surge Token
 * Developed By: Markymark (aka DeFi Mark)
 *
 * Liquidity-less Token, DEX built into Contract
 * Send BNB to contract and it mints Surge Token to your receive Address
 * Sell this token by interacting with contract directly
 * Price is calculated as a ratio between Total Supply and underlying asset in Contract
 *
 */
contract SurgeToken is IERC20, ReentrancyGuard, INativeSurge {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    // token data
    string public _name = "SurgeToken";
    string public _symbol = "S_Ticker";
    uint8 public _decimals = 0;
    
    // 1 Billion Total Supply
    uint256 _totalSupply = 1 * 10**9;
    
    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Fees
    uint256 public sellFee;
    uint256 public buyFee;
    uint256 public transferFee;
    
    // Emergency Mode Only
    bool public emergencyModeEnabled = false;
    
    // Pegged Asset
    address public immutable _token;
    
    // PCS Router
    IUniswapV2Router02 public router; 

    // Surge Fund Data
    bool public allowFunding = true;
    uint256 public fundingBuySellDenominator = 100;
    uint256 public fundingTransferDenominator = 4;
    address public surgeFund = 0x95c8eE08b40107f5bd70c28c4Fd96341c8eaD9c7;
    
    // Garbage Collector
    uint256 garbageCollectorThreshold = 10**10;
    
    // path from BNB -> _token
    address[] path;
    
    // paths for checking balances
    address[] tokenToBNB;
    address[] bnbToBusd;
    
    // owner
    address _owner;
    
    // Activates Surge Token Trading
    bool Surge_Token_Activated;
    
    // number of token holders
    uint256 public _holderCount;
    
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Only Owner Function');
        _;
    }

    // initialize some stuff
    constructor ( address peggedToken, string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, uint256 _buyFee, uint256 _sellFee, uint256 _transferFee
    ) {
        // ensure arguments meet criteria
        require(_buyFee <= 100 && _sellFee <= 100 && _transferFee <= 100 && _buyFee >= 50 && _sellFee >= 50 && _transferFee >= 50, 'Invalid Fees, Must Range From 50 - 100');
        require(peggedToken != address(0), 'cannot peg to zero address');
        // underlying asset
        _token = peggedToken;
        // token stats
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        // fees
        buyFee = _buyFee;
        sellFee = _sellFee;
        transferFee = _transferFee;
        // initialize Pancakeswap Router
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // ownership
        _owner = msg.sender;
        // initialize pcs path for swapping
        path = new address[](2);
        path[0] = router.WETH();
        path[1] = peggedToken;
        // initalize other paths for balance checking
        tokenToBNB = new address[](2);
        bnbToBusd = new address[](2);
        tokenToBNB[0] = peggedToken;
        tokenToBNB[1] = router.WETH();
        bnbToBusd[0] = router.WETH();
        bnbToBusd[1] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        // allot starting 1 billion to contract to be Garbage Collected
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
  
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender == msg.sender);
        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_balances[sender] == amount) {
            if (_balances[recipient] != 0 && recipient != address(this)) _holderCount--;
        } else {
            if (_balances[recipient] == 0 && recipient != address(this)) _holderCount++;
        }
        // track price change
        uint256 oldPrice = calculatePrice();
        // subtract form sender, give to receiver, burn the fee
        uint256 tAmount = amount.mul(transferFee).div(10**2);
        uint256 tax = amount.sub(tAmount);
        // subtract from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        // give reduced amount to receiver
        _balances[recipient] = _balances[recipient].add(tAmount);
        
        if (allowFunding && sender != surgeFund && recipient != surgeFund) {
            // allocate percentage of the tax for Surge Fund
            uint256 allocation = tax.div(fundingTransferDenominator);
            // how much are we removing from total supply
            tax = tax.sub(allocation);
            // allocate funding to Surge Fund
            _balances[surgeFund] = _balances[surgeFund].add(allocation);
            // Emit Donation To Surge Fund
            emit Transfer(sender, surgeFund, allocation);
        }
        // burn the tax
        _totalSupply = _totalSupply.sub(tax);
        // Price difference
        uint256 currentPrice = calculatePrice();
        // Require Current Price >= Last Price
        require(currentPrice >= oldPrice, 'Price Must Rise For Transaction To Conclude');
        // Transfer Event
        emit Transfer(sender, recipient, tAmount);
        // Emit The Price Change
        emit PriceChange(oldPrice, currentPrice, _totalSupply);
        return true;
    }
    
    /** Purchases SURGE Tokens and Deposits Them in Sender's Address */
    function purchase() private nonReentrant returns (bool) {
        // make sure emergency mode is disabled
        require((!emergencyModeEnabled && Surge_Token_Activated) || _owner == msg.sender, 'EMERGENCY MODE ENABLED');
        // increment holder count
        if (_balances[msg.sender] == 0) _holderCount++;
        // calculate price change
        uint256 oldPrice = calculatePrice();
        // previous amount of Tokens before we received any
        uint256 prevTokenAmount = IERC20(_token).balanceOf(address(this));
        // minimum output amount, 1% maximum slippage
        uint256 minOut = router.getAmountsOut(msg.value, path)[1].mul(99).div(100);
        // buy Token with the BNB received
        try router.swapExactETHForTokens{value: msg.value}(
            minOut,
            path,
            address(this),
            block.timestamp.add(30)
        ) {} catch {revert('Failure On Token Purchase');}
        // balance of tokens after swap
        uint256 currentTokenAmount = IERC20(_token).balanceOf(address(this));
        // number of Tokens we have purchased
        uint256 difference = currentTokenAmount.sub(prevTokenAmount);
        // if this is the first purchase, use new amount
        prevTokenAmount = prevTokenAmount == 0 ? currentTokenAmount : prevTokenAmount;
        // make sure total supply is greater than zero
        uint256 calculatedTotalSupply = _totalSupply == 0 ? _totalSupply.add(1) : _totalSupply;
        // find the number of tokens we should mint to keep up with the current price
        uint256 nShouldPurchase = calculatedTotalSupply.mul(difference).div(prevTokenAmount);
        // apply our spread to tokens to inflate price relative to total supply
        uint256 tokensToSend = nShouldPurchase.mul(buyFee).div(10**2);
        // revert if under 1
        require(tokensToSend > 0, 'Must Purchase At Least One Surge');

        if (allowFunding && msg.sender != surgeFund) {
            // allocate tokens to go to the Surge Fund
            uint256 allocation = tokensToSend.div(fundingBuySellDenominator);
            // the rest go to purchaser
            tokensToSend = tokensToSend.sub(allocation);
            // mint to Fund
            mint(surgeFund, allocation);
            // Tell Blockchain
            emit Transfer(address(this), surgeFund, allocation);
        }
        
        // mint to Buyer
        mint(msg.sender, tokensToSend);
        // Calculate Price After Transaction
        uint256 currentPrice = calculatePrice();
        // Require Current Price >= Last Price
        require(currentPrice >= oldPrice, 'Price Must Rise For Transaction To Conclude');
        // Emit Transfer
        emit Transfer(address(this), msg.sender, tokensToSend);
        // Emit The Price Change
        emit PriceChange(oldPrice, currentPrice, _totalSupply);
        return true;
    }
    
    /** Sells SURGE Tokens And Deposits the Underlying Asset into Seller's Address */
    function sell(uint256 tokenAmount) external nonReentrant override {
        
        // make sure seller has this balance
        require(_balances[msg.sender] >= tokenAmount, 'cannot sell above token amount');
        // decrement holder count
        if (_balances[msg.sender] == tokenAmount) _holderCount--;
        // calculate price change
        uint256 oldPrice = calculatePrice();
        // calculate the sell fee from this transaction
        uint256 tokensToSwap = tokenAmount.mul(sellFee).div(10**2);
        // subtract full amount from sender
        _balances[msg.sender] = _balances[msg.sender].sub(tokenAmount, 'sender does not have this amount to sell');
        // number of underlying asset tokens to claim
        uint256 amountToken;

        if (allowFunding && msg.sender != surgeFund) {
            // allocate percentage to Surge Fund
            uint256 allocation = tokensToSwap.div(fundingBuySellDenominator);
            // subtract allocation from tokensToSwap
            tokensToSwap = tokensToSwap.sub(allocation);
            // burn tokenAmount - allocation
            tokenAmount = tokenAmount.sub(allocation);
            // Allocate Tokens To Surge Fund
            _balances[surgeFund] = _balances[surgeFund].add(allocation);
            // Tell Blockchain
            emit Transfer(msg.sender, surgeFund, allocation);
        }
        
        // how many Tokens are these tokens worth?
        amountToken = tokensToSwap.mul(calculatePrice());
        // Remove tokens from supply
        _totalSupply = _totalSupply.sub(tokenAmount);
        // send Tokens to Seller
        bool successful = IERC20(_token).transfer(msg.sender, amountToken);
        // ensure Tokens were delivered
        require(successful, 'Unable to Complete Transfer of Tokens');
        // get current price
        uint256 currentPrice = calculatePrice();
        // Require Current Price >= Last Price
        require(currentPrice >= oldPrice, 'Price Must Rise For Transaction To Conclude');
        // Emit Transfer
        emit Transfer(msg.sender, address(this), tokenAmount);
        // Emit The Price Change
        emit PriceChange(oldPrice, currentPrice, _totalSupply);
    }
    
    /** Returns the Current Price of the Token */
    function calculatePrice() public view returns (uint256) {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        return tokenBalance.div(_totalSupply);
    }

    /** Calculates the price of this token in relation to its underlying asset */
    function calculatePriceInUnderlyingAsset() public view returns(uint256) {
        return calculatePrice();
    }

    /** Returns the value of your holdings before the sell fee */
    function getValueOfHoldings(address holder) public view returns(uint256) {
        return _balances[holder].mul(calculatePrice());
    }

    /** Returns the value of your holdings after the sell fee */
    function getValueOfHoldingsAfterTax(address holder) public view returns(uint256) {
        uint256 holdings = _balances[holder].mul(calculatePrice());
        return holdings.mul(sellFee).div(10**2);
    }
    
    /** List all fees */
    function getFees() public view returns(uint256, uint256, uint256) {
        return (buyFee,sellFee,transferFee);
    }

    /** Returns The Address of the Underlying Asset */
    function getUnderlyingAsset() external override view returns(address) {
        return _token;
    }

    /** Returns Value of Holdings in USD */
    function getValueOfHoldingsInUSD(address holder) public view returns(uint256) {
        if (_balances[holder] == 0) return 0;
        uint256 assetInBNB = router.getAmountsOut(_balances[holder].mul(calculatePrice()), tokenToBNB)[1];
        return router.getAmountsOut(assetInBNB, bnbToBusd)[1]; 
    }
    
    /** Allows A User To Erase Their Holdings From Supply */
    function eraseHoldings() external {
        // get balance of caller
        uint256 bal = _balances[msg.sender];
        // require balance is greater than zero
        require(bal > 0, 'cannot erase zero holdings');
        // Track Change In Price
        uint256 oldPrice = calculatePrice();
        // remove tokens from sender
        _balances[msg.sender] = 0;
        // decrement holder count
        _holderCount--;
        // remove tokens from supply
        _totalSupply = _totalSupply.sub(bal, 'total supply cannot be negative');
        // Emit Price Difference
        emit PriceChange(oldPrice, calculatePrice(), _totalSupply);
        // Emit Call
        emit ErasedHoldings(msg.sender, bal);
    }
    
    /** Enables Trading For This Surge Token, This Action Cannot be Undone */
    function ActivateSurgeToken() external onlyOwner {
        Surge_Token_Activated = true;
        emit SurgeTokenActivated();
    }
    
   /*
    * Fail Safe Incase Withdrawal is Absolutely Necessary
    * Allows Users To Withdraw 100% Of The Underlying Asset
    * This will disable the ability to purchase Surge Tokens
    * This Action Cannot Be Undone
    */
    function enableEmergencyMode() external onlyOwner {
        require(!emergencyModeEnabled, 'Emergency Mode Already Enabled');
        // disable fees
        sellFee = 0;
        transferFee = 0;
        buyFee = 0;
        // disable purchases
        emergencyModeEnabled = true;
        // Let Everyone Know
        emit EmergencyModeEnabled();
    }
    
    /** Incase Pancakeswap Upgrades To V3 */
    function changePancakeswapRouterAddress(address newPCSAddress) external onlyOwner {
        router = IUniswapV2Router02(newPCSAddress);
        path[0] = router.WETH();
        tokenToBNB[1] = router.WETH();
        bnbToBusd[0] = router.WETH();
        emit PancakeswapRouterUpdated(newPCSAddress);
    }

    /** Disables The Surge Relief Funds - only to be called once the damages have been repaid */
    function disableFunding() external onlyOwner {
        require(allowFunding, 'Funding already disabled');
        allowFunding = false;
        emit FundingDisabled();
    }
    
    /** Disables The Surge Relief Funds - only to be called once the damages have been repaid */
    function enableFunding() external onlyOwner {
        require(!allowFunding, 'Funding already enabled');
        allowFunding = true;
        emit FundingEnabled();
    }
    
    /** Changes The Fees Associated With Funding */
    function changeFundingValues(uint256 newBuySellDenominator, uint256 newTransferDenominator) external onlyOwner {
        require(newBuySellDenominator >= 80, 'BuySell Tax Too High!!');
        require(newTransferDenominator >= 3, 'Transfer Tax Too High!!');
        fundingBuySellDenominator = newBuySellDenominator;
        fundingTransferDenominator = newTransferDenominator;
        emit FundingValuesChanged(newBuySellDenominator, newTransferDenominator);
    }

    /** Change The Address For The Charity or Fund That Surge Allocates Funding Tax To */
    function swapFundAddress(address newFundReceiver) external onlyOwner {
        surgeFund = newFundReceiver;
        emit SwappedFundReceiver(newFundReceiver);
    }
    
    /** Updates The Threshold To Trigger The Garbage Collector */
    function changeGarbageCollectorThreshold(uint256 garbageThreshold) external onlyOwner {
        require(garbageThreshold > 0 && garbageThreshold <= 10**12, 'invalid threshold');
        garbageCollectorThreshold = garbageThreshold;
        emit UpdatedGarbageCollectorThreshold(garbageThreshold);
    }
    
    /** Mints Tokens to the Receivers Address */
    function mint(address receiver, uint amount) private {
        _balances[receiver] = _balances[receiver].add(amount);
        _totalSupply = _totalSupply.add(amount);
    }

    /** Make Sure there's no Native Tokens in contract */
    function checkGarbageCollector() internal {
        uint256 bal = _balances[address(this)];
        if (bal >= garbageCollectorThreshold) {
            // Track Change In Price
            uint256 oldPrice = calculatePrice();
            // destroy token balance inside contract
            _balances[address(this)] = 0;
            // remove tokens from supply
            _totalSupply = _totalSupply.sub(bal, 'total supply cannot be negative');
            // Emit Call
            emit GarbageCollected(bal);
            // Emit Price Difference
            emit PriceChange(oldPrice, calculatePrice(), _totalSupply);
        }
    }
    
    /** Transfers Ownership To Another User */
    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
        emit TransferOwnership(newOwner);
    }
    
    /** Transfers Ownership To Zero Address */
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        emit TransferOwnership(address(0));
    }
    
    /** Mint Tokens to Buyer */
    receive() external payable {
        checkGarbageCollector();
        purchase();
    }
    
    // EVENTS
    event PriceChange(uint256 previousPrice, uint256 currentPrice, uint256 totalSupply);
    event FundingValuesChanged(uint256 buySellDenominator, uint256 transferDenominator);
    event ErasedHoldings(address who, uint256 amountTokensErased);
    event UpdatedGarbageCollectorThreshold(uint256 newThreshold);
    event GarbageCollected(uint256 amountTokensErased);
    event SwappedFundReceiver(address newFundReceiver);
    event PancakeswapRouterUpdated(address newRouter);
    event TransferOwnership(address newOwner);
    event EmergencyModeEnabled();
    event SurgeTokenActivated();
    event FundingDisabled();
    event FundingEnabled();
    
}