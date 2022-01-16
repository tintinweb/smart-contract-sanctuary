/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// SPDX-License-Identifier: Unlicensed
 
pragma solidity ^0.8.9;
 
 
///////// Libraries \\\\\\\\\\
 
/**
 * BEP20 standard interface
 */
 
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
/**
 * Basic access control mechanism
 */
 
abstract contract Ownable {
    address internal owner;
    address private _previousOwner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor(address _owner) {
        owner = _owner;
    }
 
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownable: caller is not the owner"); _;
    }
 
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
 
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}
 
/**
 * Router Interfaces
 */
 
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
interface IDEXRouter {
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
 
/**
 * Contract Code
 */
 
contract TokenContract is IBEP20, Ownable {
 
    // Basic Contract Info
    string private constant _name = "NAME";
    string private constant _symbol = "SYMBOL";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100_000_000_000_000*10**_decimals; // 100 Trillions
 
    // Boolean variables
    bool private _tradingEnabled;
    bool private _inSwap;
    bool public swapEnabled;
 
    // Events
    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
    event StuckBalanceSent(uint256 amountBNB, address recipient);
    event ForeignTokenTransfer(address tokenAddress, uint256 quantity);
    event OwnerSetLimits(uint256 maxSell,uint256 maxWallet);
    event OwnerUpdateTaxes(uint8 buyTax,uint8 sellTax);
    event OwnerUpdateSecondaryTaxes(uint8 liquidity,uint8 rewards,uint8 marketing);
    event OwnerUpdateSwapThreshold(bool enabled, uint256 minSwapSize, uint256 maxSwapSize);
    event OwnerEnableTrading(uint256 timestamp);
    event OwnerUpdateBuyTaxes(uint256 liquidity, uint256 marketing, uint256 team);
    event OwnerUpdateSellTaxes(uint256 liquidity, uint256 marketing, uint256 team);
    event SetProtectionSettings(bool limits, bool antiGas, bool sameBlock, bool sniperProtection);
    event GasLimitSet(uint256 gas);
    event SniperCaught(address sniperAddress);
    event RemovedSniper(address notsniper);
    event ExcludeFromFee(address Address, bool Excluded);
    event ExcludeFromLimits(address Address, bool Excluded);
    event PresaleAddress(address Address);
    event SetFeeReceivers(address marketing, address team);
 
    // Mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isSniper;
    mapping(address => uint256) private lastTrade;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
 
    // Structs
    BuyTax private _buyTax;
    SellTax private _sellTax;
    Limit private _limit;
    AntiBot private _antibot;
    struct Limit {
        // Tax limits
        uint8 maxBuyTax;
        uint8 maxSellTax;
        // Swap variables
        uint256 maxSwapThreshold;
        uint256 swapThreshold;
        // Transaction limits
        uint256 maxWalletSize;
        uint256 maxSellSize;
    }
    struct BuyTax {
        uint8 total;
        uint8 liquidity;
        uint8 team;
        uint8 marketing;
    }
    struct SellTax {
        uint8 total;
        uint8 liquidity;
        uint8 team;
        uint8 marketing;
    }
    struct AntiBot {
        bool limitsInEffect;           // Control every AntiBot function
        bool sniperProtection;        // If this function is active the snipers will be blacklisted
        bool sameBlockActive;        // Only one transaction per user per block is allowed
        bool gasLimitActive;        // Any transaction above the specified gas will be reverted
        uint256 tradingActiveBlock;// Launch block
        uint256 snipeBlocks;      // Number of blocks for the antisnipe function, any buy transaction in these blocks will be automatically blacklisted    
        uint256 gasPriceLimit;   // Max gas allowed to buy or sell
        uint256 snipersPenaltyEnd;
    }
 
    // Addresses (Router, Marketing)
    IDEXRouter private router;
    address public _pancakeRouterAddress=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address public pair;
 
    address private marketingWallet=0x0000000000000000000000000000000000000000;
    address private teamWallet=0x0000000000000000000000000000000000000000;
 
   modifier LockTheSwap {
        _inSwap=true;
        _;
        _inSwap=false;
    }
 
    constructor () Ownable(msg.sender) {
        // Initialize Pancake Pair
        router=IDEXRouter(_pancakeRouterAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        // Exempt owner
        address _owner = owner;
        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;
        // Mint _totalSupply to owner address
        _updateBalance(_owner,_totalSupply);
        emit Transfer(address(0),_owner,_totalSupply);
        // Set initial taxes
        _buyTax.liquidity=1;
        _buyTax.team=2;
        _buyTax.marketing=2;
        _buyTax.total=_buyTax.liquidity+_buyTax.team+_buyTax.marketing;
        _sellTax.liquidity=3;
        _sellTax.team=3;
        _sellTax.marketing=3;
        _sellTax.total=_sellTax.liquidity+_sellTax.team+_sellTax.marketing;
        _limit.maxBuyTax=20;
        _limit.maxSellTax=33;
        _limit.swapThreshold=_totalSupply/1000;
        _limit.maxSwapThreshold=_totalSupply/100;
        // Set transaction limits
        _limit.maxWalletSize=_totalSupply*3/100; // 3%
        _limit.maxSellSize=_totalSupply/100; // 1 %
        // Set initial antibot settings
        _antibot.snipeBlocks = 2;
        _antibot.gasPriceLimit = 150 * 1 gwei;
    }
 
///////// Transfer Functions \\\\\\\\\
    function _transfer(address sender, address recipient, uint256 amount) internal {
        bool isBuy=sender==pair;
        bool isSell=recipient==pair;
        bool caughtSniper=isSniper[sender]&& _antibot.snipersPenaltyEnd <= block.number;
        bool isExcluded=isFeeExempt[sender]||isFeeExempt[recipient]||_inSwap;
 
        if(isExcluded)_transferExcluded(sender,recipient,amount);
        else {
            require(_tradingEnabled);
            if(caughtSniper)_sniperSellTokens(sender,recipient,amount);
            else if(isBuy)_buyTokens(sender,recipient,amount);
            else if(isSell) {
                if(_shouldSwapBack())swapBack();
                _sellTokens(sender,recipient,amount);
            } else {
                require(isTxLimitExempt[recipient]||_balances[recipient]+amount<=_limit.maxWalletSize);
                _transferExcluded(sender,recipient,amount);
            }
        }
    }
    function _buyTokens(address sender,address recipient,uint256 amount) private {
        require(_balances[recipient]+amount<=_limit.maxWalletSize);
        uint256 tokenTax=amount*_buyTax.total/100;
        if(_antibot.limitsInEffect){
            // If SniperProtection is active, apply penalty to snipers
            if(_antibot.sniperProtection && block.number - _antibot.tradingActiveBlock < _antibot.snipeBlocks){
                isSniper[recipient] = true;
                emit SniperCaught(recipient);
                }
            // If GasLimit function is active, check used gas for this transaction
            if (_antibot.gasLimitActive) {
                require(tx.gasprice <= _antibot.gasPriceLimit, "Gas price exceeds limit.");
                }
            // If SameBlock function is active, only one transaction per user per block is allowed
            if (_antibot.sameBlockActive) {
                    require(lastTrade[recipient] != block.number);
                    lastTrade[recipient] = block.number;}
        }
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
    function _sellTokens(address sender,address recipient,uint256 amount) private {
        require(amount<=_limit.maxSellSize);
        uint256 tokenTax=amount*_sellTax.total/100;
        if(_antibot.limitsInEffect){
            // If GasLimit function is active, check used gas for this transaction
            if (_antibot.gasLimitActive) {
                require(tx.gasprice <= _antibot.gasPriceLimit, "Gas price exceeds limit.");
                }
            // If SameBlock function is active, only one transaction per user per block is allowed
            if (_antibot.sameBlockActive) {
                    require(lastTrade[sender] != block.number);
                    lastTrade[sender] = block.number;}
        }
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
    function _sniperSellTokens(address sender,address recipient,uint256 amount) private {
        require(amount<=_limit.maxSellSize);
        uint256 tokenTax=amount*_sellTax.total*3/100;
        if(_antibot.limitsInEffect){
            // If GasLimit function is active, check used gas for this transaction
            if (_antibot.gasLimitActive) {
                require(tx.gasprice <= _antibot.gasPriceLimit, "Gas price exceeds limit.");
                }
            // If SameBlock function is active, only one transaction per user per block is allowed
            if (_antibot.sameBlockActive) {
                    require(lastTrade[sender] != block.number);
                    lastTrade[sender] = block.number;}
        }
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
 
    function _transferExcluded(address sender,address recipient,uint256 amount) private {
        _updateBalance(sender,_balances[sender]-amount);
        _updateBalance(recipient,_balances[recipient]+amount);
        emit Transfer(sender,recipient,amount);
    }
 
    function _transferIncluded(address sender,address recipient,uint256 amount,uint256 tokenTax) private {
        uint256 newAmount=amount-tokenTax;
        _updateBalance(sender,_balances[sender]-amount);
        _updateBalance(address(this),_balances[address(this)]+tokenTax);
        _updateBalance(recipient,_balances[recipient]+newAmount);
        emit Transfer(sender,recipient,newAmount);
    }
 
    function _updateBalance(address account,uint256 newBalance) private {
        _balances[account]=newBalance;
    }
 
    function swapBack() internal LockTheSwap {
        uint256 contractTokenBalance=_balances[address(this)];
        uint256 tokensToSell;
        if(contractTokenBalance >= _limit.maxSwapThreshold){
            tokensToSell = _limit.maxSwapThreshold;            
        }
        else{
            tokensToSell = contractTokenBalance;
        }
        uint256 totalLPTokens=tokensToSell*(_buyTax.liquidity+_sellTax.liquidity)/(_sellTax.total+_buyTax.total);
        uint256 tokensLeft=tokensToSell-totalLPTokens;
        uint256 LPTokens=totalLPTokens/2;
        uint256 LPBNBTokens=totalLPTokens-LPTokens;
        tokensToSell=tokensLeft+LPBNBTokens;
        uint256 oldBNB=address(this).balance;
        _swapTokensForBNB(tokensToSell);
        uint256 newBNB=address(this).balance-oldBNB;
        uint256 LPBNB=(newBNB*LPBNBTokens)/tokensToSell;
        _addLiquidity(LPTokens,LPBNB);
        uint256 remainingBNB=address(this).balance-oldBNB;
        _distributeBNB(remainingBNB);
    }
 
///////// Internal Functions \\\\\\\\\
    function _distributeBNB(uint256 amountWei) private {
        uint256 marketingBNB=amountWei*(_buyTax.marketing+_sellTax.marketing)/(_sellTax.total+_buyTax.total);
        uint256 teamBNB=amountWei-marketingBNB;
 
        (bool marketingSuccess, /* bytes memory data */) = payable(marketingWallet).call{value: marketingBNB, gas: 30000}("");
        require(marketingSuccess, "receiver rejected ETH transfer");
        (bool teamSuccess, /* bytes memory data */) = payable(teamWallet).call{value: teamBNB, gas: 30000}("");
        require(teamSuccess, "receiver rejected ETH transfer");
    }
 
    function _shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !_inSwap
        && swapEnabled
        && _balances[address(this)] >= _limit.swapThreshold;
    }
 
    function _swapTokensForBNB(uint256 amount) private {
        address[] memory path=new address[](2);
        path[0]=address(this);
        path[1]=router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
 
    function _addLiquidity(uint256 amountTokens,uint256 amountBNB) private {
        router.addLiquidityETH{value: amountBNB}(
            address(this),
            amountTokens,
            0,
            0,
            marketingWallet,
            block.timestamp
        );
        emit AutoLiquify(amountTokens,amountBNB);
    }
 
///////// Owner Functions \\\\\\\\\
    function ownerSetLimits(uint256 maxSell_base1000,uint256 maxWallet_base1000) public onlyOwner{
        require(maxSell_base1000 * (_totalSupply / 1000) >= _totalSupply / 100, "Can't set lower MaxWallet than 1%");
        require(maxWallet_base1000 * (_totalSupply / 1000) >= _totalSupply / 200, "Can't set lower MaxSell than 0.5%");
        _limit.maxSellSize = maxSell_base1000 * (_totalSupply / 1000);
        _limit.maxWalletSize = maxWallet_base1000 * (_totalSupply / 1000);
        emit OwnerSetLimits(maxSell_base1000,maxWallet_base1000);
    }
    function ownerEnableTrading() public onlyOwner{
        require(!_tradingEnabled, "Trading already enabled");
        _tradingEnabled=true;
        _antibot.tradingActiveBlock = block.number;
        _antibot.limitsInEffect = true;
        _antibot.sniperProtection = true;
        _antibot.gasLimitActive = true;
        _antibot.sameBlockActive = true;
        _antibot.snipersPenaltyEnd = block.timestamp + 72 hours;
        emit OwnerEnableTrading(block.timestamp);
    }
    function ownerUpdateBuyTaxes(uint8 liquidity,uint8 team,uint8 marketing) public onlyOwner {
        uint256 total=liquidity+marketing+team;
        require(total<=_limit.maxBuyTax);
        _buyTax.liquidity=liquidity;
        _buyTax.marketing=marketing;
        _buyTax.team=team;
        _buyTax.total=liquidity+marketing+team;
        emit OwnerUpdateBuyTaxes(liquidity,marketing,team);
    }
    function ownerUpdateSellTaxes(uint8 liquidity,uint8 team,uint8 marketing) public onlyOwner {
        uint256 total=liquidity+marketing+team;
        require(total<=_limit.maxSellTax);
        _sellTax.liquidity=liquidity;
        _sellTax.marketing=marketing;
        _sellTax.team=team;
        _sellTax.total=liquidity+marketing+team;
        emit OwnerUpdateSellTaxes(liquidity,marketing,team);
    }
    function ownerUpdateSwapThreshold(bool _enabled,uint256 swapThreshold_Base1000,uint256 maxSwapThreshold_Base1000) public onlyOwner {
        swapEnabled=_enabled;
        _limit.swapThreshold=_totalSupply*swapThreshold_Base1000/1000;
        _limit.maxSwapThreshold=_totalSupply*maxSwapThreshold_Base1000/1000;
        emit OwnerUpdateSwapThreshold(_enabled,swapThreshold_Base1000,maxSwapThreshold_Base1000);
    }
    // Set excluded from fee wallets
    function excludeFromFee(address account, bool exempt) external onlyOwner {
        isFeeExempt[account] = exempt;
        emit ExcludeFromFee(account, exempt);
    }
    // Set excluded from limits wallets
    function excludeFromLimits(address account, bool exempt) external onlyOwner {
        isTxLimitExempt[account] = exempt;
        emit ExcludeFromLimits(account, exempt);
    }
    // Set presale address, exempt from limits and fees
    function presaleAddress(address account) external onlyOwner {
        isFeeExempt[account] = true;
        isTxLimitExempt[account] = true;
        emit PresaleAddress(account);
    }
    // Set receivers
    function setFeeReceiver(address marketing, address team) external onlyOwner {
        marketingWallet = marketing;
        teamWallet = team;
        emit SetFeeReceivers(marketing, team);
    }
    // Use this function to remove wallets from sniper list
    function removeSniper(address account) external onlyOwner {
        isSniper[account] = false;
        emit RemovedSniper(account);
    }
    // AntiBot functions, the owner can activate or deactivate them if necessary
    function setProtectionSettings(bool limits, bool antiGas, bool sameBlock, bool sniperProtect) external onlyOwner() {
        _antibot.limitsInEffect = limits;            // Every antibot function is controlled by this variable
        _antibot.gasLimitActive = antiGas;          // Any transaction above the specified gas will be reverted
        _antibot.sameBlockActive = sameBlock;      // Only one transaction per user per block is allowed
        _antibot.sniperProtection = sniperProtect;// If this function is active the snipers will be blacklisted
        emit SetProtectionSettings(limits, antiGas, sameBlock, sniperProtect);
    }
    // Maximum gas allowed for a transaction
    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 75); // Set between 75 - 200
        _antibot.gasPriceLimit = gas * 1 gwei;
        emit GasLimitSet(gas);
    }
 
    // Stuck Balance Functions
    function ClearStuckBalance() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(owner).transfer(contractBalance);
        emit StuckBalanceSent(contractBalance, owner);
    }
 
    function transferForeignToken(address _token) public onlyOwner {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(owner).transfer(_contractBalance);
        emit ForeignTokenTransfer(_token, _contractBalance);
    }
 
///////// IBEP20 \\\\\\\\\
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
 
    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }
 
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }
 
    receive() external payable { }
}