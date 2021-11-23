//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

/**
 * Contract: ACHAPE Token
 * Contract Developed By: Chibo
 *
 * ACHAPE is a project aimed to create revolutionary blockchain products built
 * Around the exchange of luxury assets in both the metaverse and physical world
 * Exlusive only to $ACHAPE Token Holders
 */
contract ACHAPE is IERC20 {
    
    using SafeMath for uint256;
    using Address for address;

    // token data
    string constant _name = "Achape";
    string constant _symbol = "ACHAPE";
    uint8 constant _decimals = 9;

    // 1 Billion Starting Supply
    uint256 _totalSupply = 10**9 * 10**_decimals;
    
    // Bot Prevention
    uint256 maxTransfer;
    bool maxTransferCheckEnabled;
    
    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Fees
    uint256 public fee = 3; // 3% transfer fee
    
    // fee exemption for staking / utility
    mapping ( address => bool ) public isFeeExempt;

    // Uniswap Router
    IUniswapV2Router02 _router; 
    
    // ETH -> Token
    address[] path;
    
    // Tokens -> ETH
    address[] sellPath;
    
    // owner
    address _owner;
    
    // multisignature wallet
    address _developmentFund;
    
    // Auto Swapper Enabled
    bool swapEnabled;

    modifier onlyOwner() {
        require(msg.sender == _owner, 'Only Owner Function');
        _;
    }

    // initialize some stuff
    constructor () {
        
        // router
        _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        // ETH -> Token
        path = new address[](2);
        path[0] = _router.WETH();
        path[1] = address(this);
        
        // Token -> ETH
        sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = _router.WETH();
        
        // Dev Fund
        _developmentFund = 0xFfE01c5E5bCC694d82d0eEC853a2B21E25E2274A;
        
        // Enable Auto Swapper
        swapEnabled = true;
        
        // Anti-Bot Prevention
        maxTransfer = _totalSupply.div(100);
        maxTransferCheckEnabled = true;

        // fee exempt fund + owner + router for LP injection
        isFeeExempt[msg.sender] = true;
        isFeeExempt[_developmentFund] = true;
        isFeeExempt[address(this)] = true;
        
        // allocate tokens to owner
        _balances[msg.sender] = _totalSupply;

        // ownership
        _owner = msg.sender;
        
        // emit allocations
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
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
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, 'Insufficient Allowance');
        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0) && sender != address(0), "Transfer To Zero Address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // check anti-bot
        if (maxTransferCheckEnabled && msg.sender != _owner) {
            require(amount <= maxTransfer, 'Maximum Transfer Threshold Reached');
        }
        
        // subtract full amount from sender
        _balances[sender] = _balances[sender].sub(amount, 'Insufficient Balance');
        
        // fee exempt
        bool takeFee = !( isFeeExempt[sender] || isFeeExempt[recipient] );
        
        // calculate taxed amount
        uint256 taxAmount = takeFee ? amount.mul(fee).div(10**2) : 0;
        
        // amount to give to recipient (amount - tax)
        uint256 receiveAmount = amount.sub(taxAmount);
        
        // give potentially reduced amount to recipient
        _balances[recipient] = _balances[recipient].add(receiveAmount);
        emit Transfer(sender, recipient, receiveAmount);
        
        // allocate to marketing
        if (taxAmount > 0) {
            _balances[_developmentFund] = _balances[_developmentFund].add(taxAmount);
            emit Transfer(sender, _developmentFund, taxAmount);
        }
        return true;
    }
    
    function burnTokens(uint256 numTokens) external {
        _burnTokens(numTokens * 10**_decimals);
    }
    
    function burnAllTokens() external {
        _burnTokens(_balances[msg.sender]);
    }
    
    function burnTokensIncludingDecimals(uint256 numTokens) external {
        _burnTokens(numTokens);
    }
    
    function purchaseTokenForAddress(address receiver) external payable {
        require(msg.value >= 10**4, 'Amount Too Few');
        _purchaseToken(receiver);
    }
    
    function sellTokensForETH(address receiver, uint256 numTokens) external {
        _sellTokensForETH(receiver, numTokens);
    }
    
    function sellTokensForETH(uint256 numTokens) external {
        _sellTokensForETH(msg.sender, numTokens);
    }
    
    function sellTokensForETHWholeTokenAmounts(uint256 numTokens) external {
        _sellTokensForETH(msg.sender, numTokens*10**_decimals);
    }
    

    ///////////////////////////////////
    //////   OWNER FUNCTIONS    ///////
    ///////////////////////////////////
    
    function setUniswapRouterAddress(address router) external onlyOwner {
        _router = IUniswapV2Router02(router);
        emit SetUniswapRouterAddress(router);
    }
    
    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
        emit SetSwapEnabled(enabled);
    }
    
    /** Withdraws Tokens Mistakingly Sent To Contract */
    function withdrawTokens(address token) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, 'Zero Balance');
        IERC20(token).transfer(msg.sender, bal);
    }
    
    /** Sets Maximum Transaction Data */
    function setMaxTransactionData(bool checkEnabled, uint256 transferThreshold) external onlyOwner {
        if (checkEnabled) {
            require(transferThreshold >= _totalSupply.div(1000), 'Threshold Too Few');   
        }
        maxTransferCheckEnabled = checkEnabled;
        maxTransfer = transferThreshold;
        emit MaxTransactionDataSet(checkEnabled, transferThreshold);
    }
    
    /** Updates The Address Of The Development Fund Receiver */
    function updateDevelopmentFundingAddress(address newFund) external onlyOwner {
        _developmentFund = newFund;
        emit UpdatedDevelopmentFundingAddress(newFund);
    }
    
    /** Excludes Contract From Fees */
    function setFeeExemption(address wallet, bool exempt) external onlyOwner {
        require(wallet != address(0));
        isFeeExempt[wallet] = exempt;
        emit SetFeeExemption(wallet, exempt);
    }
    
    /** Sets Transfer Fees */
    function setFee(uint256 newFee) external onlyOwner {
        require(newFee <= 10, 'Fee Too High');
        fee = newFee;
        emit SetFee(newFee);
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
    
    
    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
    
    
    function _sellTokensForETH(address receiver, uint256 numberTokens) internal {

        // checks
        require(_balances[msg.sender] >= numberTokens, 'Insufficient Balance');
        require(receiver != address(this) && receiver != address(0), 'Insufficient Destination');
        require(swapEnabled, 'Swapping Disabled');
        
        // transfer in tokens
        _balances[msg.sender] = _balances[msg.sender].sub(numberTokens, 'Insufficient Balance');
        
        // divvy up amount
        uint256 tax = isFeeExempt[msg.sender] ? 0 : numberTokens.mul(fee).div(10**2);
        
        // amount to send to recipient
        uint256 sendAmount = numberTokens.sub(tax);
        require(sendAmount > 0, 'Zero Tokens To Send');
        
        // Allocate To Contract
        _balances[address(this)] = _balances[address(this)].add(sendAmount);
        emit Transfer(msg.sender, address(this), sendAmount);
        
        // Allocate Tax
        if (tax > 0) {
            _balances[_developmentFund] = _balances[_developmentFund].add(tax);
            emit Transfer(msg.sender, _developmentFund, tax);
        }
        
        // Approve Of Router To Move Tokens
        _allowances[address(this)][address(_router)] = sendAmount;
        
        // make the swap
        _router.swapExactTokensForETH(
            sendAmount,
            0,
            sellPath,
            receiver,
            block.timestamp + 30
        );
    
    }
    
    function _purchaseToken(address receiver) internal {
        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            receiver,
            block.timestamp + 30
        );
    }
    
    function _burnTokens(uint256 numTokens) internal {
        require(_balances[msg.sender] >= numTokens && numTokens > 0, 'Insufficient Balance');
        // remove from balance and supply
        _balances[msg.sender] = _balances[msg.sender].sub(numTokens, 'Insufficient Balance');
        _totalSupply = _totalSupply.sub(numTokens, 'Insufficient Supply');
        // emit transfer to zero
        emit Transfer(msg.sender, address(0), numTokens);
    }
    
    /** Purchase Tokens For Holder */
    receive() external payable {
        _purchaseToken(msg.sender);
    }
    
    
    ///////////////////////////////////
    //////        EVENTS        ///////
    ///////////////////////////////////
    
    event UpdatedDevelopmentFundingAddress(address newFund);
    event TransferOwnership(address newOwner);
    event SetSwapEnabled(bool enabled);
    event SetFee(uint256 newFee);
    event SetUniswapRouterAddress(address router);
    event SetFeeExemption(address Contract, bool exempt);
    event MaxTransactionDataSet(bool checkEnabled, uint256 transferThreshold);
}