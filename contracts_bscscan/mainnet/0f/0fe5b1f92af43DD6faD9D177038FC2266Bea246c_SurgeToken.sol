//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrantGuard.sol";
import "./IERC20.sol";
import "./IStakableSurge.sol";
import "./IUselessBypass.sol";

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
contract SurgeToken is ReentrancyGuard, IStakableSurge {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    // token data
    string public _name = "SurgeToken";
    string public _symbol = "S_Ticker";
    uint8 public constant _decimals = 0;
    
    // 1 Billion Total Supply
    uint256 public _totalSupply = 1 * 10**9;
    
    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Fees
    uint256 public sellFee;
    uint256 public buyFee;
    uint256 public transferFee;
    uint256 public stakeFee;
    
    // Emergency Mode Only
    bool public emergencyModeEnabled;
    
    // Pegged Asset
    address public immutable _token;
    
    // swapper contract for Useless
    IUselessBypass public immutable _uselessSwapper;

    // Garbage Collector
    uint256 garbageCollectorThreshold = 10**10;
    
    // owner
    address _owner;
    
    // Activates Surge Token Trading
    bool Surge_Token_Activated;

    // launch time
    bool _allowStaking;
    
    // disables the use of the Useless Bypass
    bool _useUselessBypass;
    
    // surge fund data 
    bool allowFunding;
    address _surgeFund;
    uint256 _fundingBuyFeeDenominator;
    uint256 _fundingTransferFeeDenominator;
    
    // LP Management
    mapping (address => bool) approvedLP;

    modifier onlyOwner() {
        require(msg.sender == _owner, 'Only Owner Function');
        _;
    }

    // initialize some stuff
    constructor ( address peggedToken, string memory tokenName, string memory tokenSymbol, uint256 _buyFee, uint256 _sellFee, uint256 _transferFee
    ) {
        // ensure arguments meet criteria
        require(_buyFee <= 100 && _sellFee <= 100 && _transferFee <= 100 && _buyFee >= 50 && _sellFee >= 50 && _transferFee >= 50, 'Invalid Fees, Must Range From 50 - 100');
        require(peggedToken != address(0), 'cannot peg to zero address');
        // underlying asset
        _token = peggedToken;
        // token stats
        _name = tokenName;
        _symbol = tokenSymbol;
        // fees
        buyFee = _buyFee;
        sellFee = _sellFee;
        transferFee = _transferFee;
        stakeFee = 94125;
        // Swaps + Funding
        _surgeFund = 0x95c8eE08b40107f5bd70c28c4Fd96341c8eaD9c7;
        _fundingBuyFeeDenominator = 200;
        _fundingTransferFeeDenominator = 4;
        _uselessSwapper = IUselessBypass(payable(0xca103724A986e76B64B2bbbb896a0bc3b689661C));
        _useUselessBypass = true;
        // Approved LPs
        approvedLP[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
        // ownership
        _owner = msg.sender;
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

    function decimals() public pure override returns (uint8) {
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
        if (approvedLP[msg.sender]) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, 'Insufficient Allowance');
        } else {
            require(sender == msg.sender, 'Only Owner Can Move Tokens');
        }
        
        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0) && sender != address(0), "Transfer To Zero Address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // track price change
        uint256 oldPrice = calculatePrice();
        // subtract form sender, give to receiver, burn the fee
        uint256 tAmount = amount.mul(transferFee).div(10**2);
        uint256 tax = amount.sub(tAmount);
        // subtract from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        // give reduced amount to receiver
        _balances[recipient] = _balances[recipient].add(tAmount);
        
        if (allowFunding && sender != _surgeFund && recipient != _surgeFund) {
            // allocate percentage of the tax for Surge Fund
            uint256 allocation = tax.div(_fundingTransferFeeDenominator);
            // how much are we removing from total supply
            tax = tax.sub(allocation);
            // allocate funding to Surge Fund
            _balances[_surgeFund] = _balances[_surgeFund].add(allocation);
            // Emit Donation To Surge Fund
            emit Transfer(sender, _surgeFund, allocation);
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
        // calculate price change
        uint256 oldPrice = calculatePrice();
        // previous amount of Tokens before we received any
        uint256 prevTokenAmount = IERC20(_token).balanceOf(address(this));
        // buy useless with bnb
        (bool success,) = payable(address(_uselessSwapper)).call{value: msg.value}("");
        require(success, 'Failure on Useless Purchase');
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

        if (allowFunding && msg.sender != _surgeFund) {
            // allocate tokens to go to the Surge Fund
            uint256 allocation = tokensToSend.div(_fundingBuyFeeDenominator);
            // the rest go to purchaser
            tokensToSend = tokensToSend.sub(allocation);
            // mint to Fund
            mint(_surgeFund, allocation);
            // Tell Blockchain
            emit Transfer(address(this), _surgeFund, allocation);
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
    
    /** Stake Tokens and Deposits Surge in Sender's Address, Must Have Prior Approval */
    function stakeUnderlyingAsset(uint256 numTokens) external nonReentrant override returns (bool) {
        // make sure emergency mode is disabled
        require((!emergencyModeEnabled && Surge_Token_Activated && _allowStaking) || _owner == msg.sender, 'STAKING NOT ENABLED');
        // users token balance
        uint256 userTokenBalance = IERC20(_token).balanceOf(msg.sender);
        // ensure user has enough to send
        require(userTokenBalance > 0 && numTokens <= userTokenBalance, 'Insufficient Balance');
        // calculate price change
        uint256 oldPrice = calculatePrice();
        // previous amount of Tokens before any are received
        uint256 prevTokenAmount = IERC20(_token).balanceOf(address(this));
        // move asset into Surge Token
        bool success = IERC20(_token).transferFrom(msg.sender, address(this), numTokens);
        // balance of tokens after transfer
        uint256 currentTokenAmount = IERC20(_token).balanceOf(address(this));
        // number of Tokens we have purchased
        uint256 difference = currentTokenAmount.sub(prevTokenAmount);
        // ensure nothing unexpected happened
        require(difference <= numTokens, 'Failure on Token Evaluation');
        // ensure a successful transfer
        require(success, 'Failure On Token Transfer');
        // if this is the first purchase, use new amount
        prevTokenAmount = prevTokenAmount == 0 ? currentTokenAmount : prevTokenAmount;
        // make sure total supply is greater than zero
        uint256 calculatedTotalSupply = _totalSupply == 0 ? _totalSupply.add(1) : _totalSupply;
        // find the number of tokens we should mint to keep up with the current price
        uint256 nShouldPurchase = calculatedTotalSupply.mul(difference).div(prevTokenAmount);
        // apply our spread to tokens to inflate price relative to total supply
        uint256 tokensToSend = nShouldPurchase.mul(stakeFee).div(10**5);
        // revert if under 1
        require(tokensToSend > 0, 'Must Purchase At Least One Surge');

        if (allowFunding && msg.sender != _surgeFund) {
            // less fee for staking 
            uint256 denom = _fundingBuyFeeDenominator.mul(4);
            // allocate tokens to go to the Surge Fund
            uint256 allocation = tokensToSend.div(denom);
            // the rest go to purchaser
            tokensToSend = tokensToSend.sub(allocation);
            // mint to Fund
            mint(_surgeFund, allocation);
            // Tell Blockchain
            emit Transfer(address(this), _surgeFund, allocation);
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
        // Emit Staked Event
        emit TokenStaked(difference);
        return true;
    }
    
    /** Sells SURGE Tokens And Deposits the Underlying Asset into Seller's Address */
    function sell(uint256 tokenAmount) external nonReentrant override {
        // calculate price change
        uint256 oldPrice = calculatePrice();
        // calculate the sell fee from this transaction
        uint256 tokensToSwap = tokenAmount.mul(sellFee).div(10**2);
        // subtract full amount from sender
        _balances[msg.sender] = _balances[msg.sender].sub(tokenAmount, 'Insufficient Balance');

        if (allowFunding && msg.sender != _surgeFund) {
            // allocate percentage to Surge Fund
            uint256 allocation = tokensToSwap.div(_fundingBuyFeeDenominator);
            // subtract allocation from tokensToSwap
            tokensToSwap = tokensToSwap.sub(allocation);
            // burn tokenAmount - allocation
            tokenAmount = tokenAmount.sub(allocation);
            // Allocate Tokens To Surge Fund
            _balances[_surgeFund] = _balances[_surgeFund].add(allocation);
            // Tell Blockchain
            emit Transfer(msg.sender, _surgeFund, allocation);
        }
        
        // how many Tokens are these tokens worth?
        uint256 amountToken = tokensToSwap.mul(calculatePrice());
        // Remove tokens from supply
        _totalSupply = _totalSupply.sub(tokenAmount);
        // transfer success
        bool successful;
        // send Tokens to Seller
        if (_useUselessBypass) {
            // approve of bypass
            IERC20(_token).approve(address(_uselessSwapper), amountToken);
            successful = _uselessSwapper.uselessBypass(msg.sender, amountToken);
        } else {
            successful = IERC20(_token).transfer(msg.sender, amountToken);
        }
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
        // remove tokens from supply
        _totalSupply = _totalSupply.sub(bal, 'total supply cannot be negative');
        // Emit Price Difference
        emit PriceChange(oldPrice, calculatePrice(), _totalSupply);
        // Emit Call
        emit ErasedHoldings(msg.sender, bal);
    }
    
    
    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
    
    
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
    
    
    ///////////////////////////////////
    //////    READ FUNCTIONS    ///////
    ///////////////////////////////////
    
    
    /** Returns true if manager is a registered xTokenManager */
    function isApprovedLP(address manager) external view returns (bool) {
        return approvedLP[manager];
    }
    
    /** Returns the Current Price of the Token */
    function calculatePrice() public view returns (uint256) {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        return _totalSupply == 0 ? tokenBalance : tokenBalance.div(_totalSupply);
    }

    /** Returns the value of your holdings before the sell fee */
    function getValueOfHoldings(address holder) public view returns(uint256) {
        return _balances[holder].mul(calculatePrice());
    }

    /** Returns the value of your holdings after the sell fee */
    function getValueOfHoldingsAfterTax(address holder) external view returns(uint256) {
        return getValueOfHoldings(holder).mul(sellFee).div(10**2);
    }

    /** Returns The Address of the Underlying Asset */
    function getUnderlyingAsset() external override view returns(address) {
        return _token;
    }
    
    
    ///////////////////////////////////
    //////   OWNER FUNCTIONS    ///////
    ///////////////////////////////////
    
    
    /** Enables Trading For This Surge Token, This Action Cannot be Undone */
    function ActivateSurgeToken() external onlyOwner {
        require(!Surge_Token_Activated, 'Already Activated Token');
        Surge_Token_Activated = true;
        allowFunding = true;
        emit SurgeTokenActivated();
    }
    
    /*
    * Fail Safe Incase Withdrawal is Absolutely Necessary
    * Allows Users To Withdraw 100% Of Their Share Of The Underlying Asset
    * This will disable the ability to purchase or stake Surge Tokens
    * THIS ACTION CANNOT BE UNDONE
    */
    function enableEmergencyMode() external override onlyOwner {
        require(!emergencyModeEnabled, 'Emergency Mode Already Enabled');
        // disable fees
        sellFee = 100;
        transferFee = 100;
        buyFee = 0;
        stakeFee = 0;
        // disable purchases
        emergencyModeEnabled = true;
        // disable funding
        allowFunding = false;
        // Let Everyone Know
        emit EmergencyModeEnabled();
    }
    
    /** Allows Users To Stake Underlying Asset Into Surge */
    function setAllowSurgeStaking(bool allow) external onlyOwner {
        _allowStaking = allow;
        emit UpdatedAllowSurgeStaking(allow);
    }
    
    /** Updates The Buy/Sell/Stake and Transfer Fee Allocated Toward Funding */
    function updateFundingValues(bool allowSurgeFunding, uint256 transferDenom, uint256 buySellDenom) external onlyOwner {
        require(transferDenom >= 2 && buySellDenom >= 50, 'Fees Too High');
        allowFunding = allowSurgeFunding;
        _fundingTransferFeeDenominator = transferDenom;
        _fundingBuyFeeDenominator = buySellDenom;
        emit UpdatedFundingValues(allowSurgeFunding, transferDenom, buySellDenom);
    }
    
    /** Updates The Address Of The SurgeFund */
    function updateSurgeFundAddress(address newSurgeFund) external onlyOwner {
        _surgeFund = newSurgeFund;
        emit UpdatedSurgeFundAddress(newSurgeFund);
    }
    
    /** Sets an Address To Be An Approved Liquidity Pool */
    function setIsApprovedLP(address LP, bool isLP) external onlyOwner {
        approvedLP[LP] = isLP;
        emit SetApprovedLP(LP, isLP);
    }
    
    /** Whether or Not Contract Uses the Useless Bypass to Transfer Tokens */
    function updateUseOfUselessBypass(bool useBypass) external onlyOwner {
        _useUselessBypass = useBypass;
        emit UpdatedUseUselessBypass(useBypass);
    }

    /** Updates The Threshold To Trigger The Garbage Collector */
    function changeGarbageCollectorThreshold(uint256 garbageThreshold) external onlyOwner {
        require(garbageThreshold > 0 && garbageThreshold <= 10**12, 'invalid threshold');
        garbageCollectorThreshold = garbageThreshold;
        emit UpdatedGarbageCollectorThreshold(garbageThreshold);
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
    
    
    ///////////////////////////////////
    //////        EVENTS        ///////
    ///////////////////////////////////
    
    event UpdatedFundingValues(bool allowSurgeFunding, uint256 transferDenom, uint256 buySellDenom);
    event PriceChange(uint256 previousPrice, uint256 currentPrice, uint256 totalSupply);
    event ErasedHoldings(address who, uint256 amountTokensErased);
    event UpdatedGarbageCollectorThreshold(uint256 newThreshold);
    event UpdatedSurgeFundAddress(address newSurgeFund);
    event GarbageCollected(uint256 amountTokensErased);
    event UpdatedUseUselessBypass(bool canUseBypass);
    event UpgradeSurgeDatabase(address newDatabase);
    event UpdatedAllowFunding(bool _allowFunding);
    event SetApprovedLP(address LP, bool isLP);
    event UpdatedAllowSurgeStaking(bool allow);
    event TransferOwnership(address newOwner);
    event TokenStaked(uint256 numTokens);
    event EmergencyModeEnabled();
    event SurgeTokenActivated();
    
}