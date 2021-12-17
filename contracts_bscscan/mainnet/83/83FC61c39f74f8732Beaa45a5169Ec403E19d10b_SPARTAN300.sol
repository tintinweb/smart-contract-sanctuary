/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

//   _____ _____        _____ _______       _   _     ____   ___   ___  
//  / ____|  __ \ /\   |  __ \__   __|/\   | \ | |   |___ \ / _ \ / _ \ 
// | (___ | |__) /  \  | |__) | | |  /  \  |  \| |    __) | | | | | | |
//  \___ \|  ___/ /\ \ |  _  /  | | / /\ \ | . ` |   |__ <| | | | | | |
//  ____) | |  / ____ \| | \ \  | |/ ____ \| |\  |   ___) | |_| | |_| |
// |_____/|_| /_/    \_\_|  \_\ |_/_/    \_\_| \_|   |____/ \___/ \___/  

// \o/
// Never let the FOMO go down. We are the FOMO. You are the FOMO.  
pragma solidity ^0.8.10;
//interfaces
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
// contracts
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }   
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
contract SPARTAN300 is ERC20, Ownable {
//custom
    IUniswapV2Router02 public uniswapV2Router;
//bool
    bool public swapAndLiquifyEnabled = true;
    bool public sendToMarketing = true;
    bool public sendToDev = true;
    bool public sendToTeam = true;
    bool public marketActive = true;
    bool public blockMultiBuys = true;
    bool public limitSells = false;
    bool public limitBuys = false;
    bool public feeStatus = true;
    bool public buyFeeStatus = true;
    bool public sellFeeStatus = true;
    bool private isInternalTransaction = false;
//address
    address public uniswapV2Pair;
    address public marketingAddress = 0xF41ea20AF540d126601cEeEc540B30e2eCBFfE51;
    address public teamAddress = 0xe70a0194d2E92727dbbb1C613A1e8fbC697dC5C5;
    address public devAddress = 0x2a94920A75Ad736d9F2636c8b8682C2d7F65b23a;
//uint
    uint public minimumWeiForTokenomics = 1 * 10**16; // 0.01 BNB
    uint public buyMarketingFee = 6;
    uint public sellMarketingFee = 6;
    uint public buyDevFee = 2;
    uint public sellDevFee = 2;
    uint public buyTeamFee = 2;
    uint public sellTeamFee = 2;
    uint public totalBuyFee = buyMarketingFee + buyDevFee + buyTeamFee;
    uint public totalSellFee = sellMarketingFee + sellDevFee + sellTeamFee;
    uint public maxBuyTxAmount; // 1% of tot supply 
    uint public maxSellTxAmount;// 1% of tot supply 
    uint public minimumTokensBeforeSwap = 2000000 * 10 ** decimals();
    uint public tokensToSwap = 2000000 * 10 ** decimals();
    uint public intervalSecondsForSwap = 60;
    uint private startTimeForSwap;
    uint private marketActiveAt;
//struct
    struct userData {uint lastBuyTime;}
//mapping
    mapping (address => bool) public premarketUser;
    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => userData) public userLastTradeData;
// constructor
    constructor() ERC20("SPARTAN300", "SPT300") {
                            
        uint total_supply = 1000000000000 * 10 ** decimals();
        // set gvars 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        maxSellTxAmount = total_supply / 100; // 1% supply
        maxBuyTxAmount = total_supply / 100; // 1% supply
        //spawn pair
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        // mappings
        excludedFromFees[address(this)] = true;
        excludedFromFees[owner()] = true;
        excludedFromFees[devAddress] = true;
        excludedFromFees[teamAddress] = true;
        excludedFromFees[marketingAddress] = true;
        premarketUser[owner()] = true;
        automatedMarketMakerPairs[uniswapV2Pair] = true;
        _mint(msg.sender, total_supply); // mint is used only here
    }
    // accept bnb for autoswap
    receive() external payable {}
// utility functions
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }
    function transferForeignToken(address _token, address _to, uint _value) external onlyOwner returns(bool _sent){
        if(_value == 0) {
            _value = IERC20(_token).balanceOf(address(this));
        } 
        _sent = IERC20(_token).transfer(_to, _value);
    }
    function sweep() external onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
//switch functions
    function switchMarketActive(bool _state) external onlyOwner {
        marketActive = _state;
        if(_state) {
            marketActiveAt = block.timestamp;
        }
    }
    function switchBlockMultiBuys(bool _state) external onlyOwner {
        blockMultiBuys = _state;
    }
    function switchLimitSells(bool _state) external onlyOwner {
        limitSells = _state;
    }
    function switchLimitBuys(bool _state) external onlyOwner {
        limitBuys = _state;
    }
//set functions
    function setsendFee(bool marketing, bool dev, bool team) external onlyOwner {
        sendToMarketing = marketing;
        sendToTeam = team;
        sendToDev = dev;
    }
    function setminimumWeiForTokenomics(uint _value) external onlyOwner {
        minimumWeiForTokenomics = _value;
    }
    function setFeesAddress(address marketing, address dev, address team) external onlyOwner {
        marketingAddress = marketing;
        devAddress = dev;
        teamAddress = team;
    }
    function setMaxSellTxAmount(uint _value) external onlyOwner {
        maxSellTxAmount = _value;
    }
    function setMaxBuyTxAmount(uint _value) external onlyOwner {
        maxBuyTxAmount = _value;
    }
    function setFee(bool is_buy, uint marketing, uint dev, uint team) external onlyOwner {
        if(is_buy) {
            buyDevFee = dev;
            buyMarketingFee = marketing;
            buyTeamFee = team;
            totalBuyFee = buyMarketingFee + buyDevFee + buyTeamFee;
        } else {
            sellDevFee = dev;
            sellMarketingFee = marketing;
            sellTeamFee = team;
            totalSellFee = sellMarketingFee + sellDevFee + sellTeamFee;
        }
    }
    function setFeeStatus(bool buy, bool sell, bool _state) external onlyOwner {
        feeStatus = _state;
        buyFeeStatus = buy;
        sellFeeStatus = sell;
    }
    function setSwapAndLiquify(bool _state, uint _intervalSecondsForSwap, uint _minimumTokensBeforeSwap, uint _tokensToSwap) external onlyOwner {
        swapAndLiquifyEnabled = _state;
        intervalSecondsForSwap = _intervalSecondsForSwap;
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
        tokensToSwap = _tokensToSwap;
    }
// mappings functions
    function editPremarketUser(address _target, bool _status) external onlyOwner {
        premarketUser[_target] = _status;
    }
    function editExcludedFromFees(address _target, bool _status) external onlyOwner {
        excludedFromFees[_target] = _status;
    }
    function editAutomatedMarketMakerPairs(address _target, bool _status) external onlyOwner {
        automatedMarketMakerPairs[_target] = _status;
    }
// operational functions
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function swapTokens(uint256 contractTokenBalance) private {
        isInternalTransaction = true;
        swapTokensForEth(contractTokenBalance);
        isInternalTransaction = false;
    }
    function _transfer(address from, address to, uint256 amount) internal override {
        uint trade_type = 0;
        bool overMinimumTokenBalance = balanceOf(address(this)) >= minimumTokensBeforeSwap;
    // market status flag
        if(!marketActive) {
            require(premarketUser[from],"cannot trade before the market opening");
        }
    // normal transaction
        if(!isInternalTransaction) {
        // tx limits
            //buy
            if(automatedMarketMakerPairs[from]) {
                trade_type = 1;
                // limits
                if(!excludedFromFees[to]) {
                    // tx limit
                    if(limitBuys) {
                        require(amount <= maxBuyTxAmount, "maxBuyTxAmount Limit Exceeded");
                    }
                    // multi-buy limit
                    if(blockMultiBuys) {
                        require(marketActiveAt + 3 < block.timestamp,"Launch delay protection revert.");
                        require(userLastTradeData[to].lastBuyTime + 3 <= block.timestamp,"Multi-buy orders disabled.");
                        userLastTradeData[to].lastBuyTime = block.timestamp;
                    }
                }
            }
            //sell
            else if(automatedMarketMakerPairs[to]) {
                trade_type = 2;
                // marketing auto-bnb
                if (swapAndLiquifyEnabled && balanceOf(uniswapV2Pair) > 0) {
                    if (overMinimumTokenBalance && startTimeForSwap + intervalSecondsForSwap <= block.timestamp) {
                        startTimeForSwap = block.timestamp;
                        // sell to bnb
                        swapTokens(tokensToSwap);
                    }
                }
                // limits
                if(!excludedFromFees[from]) {
                    // tx limit
                    if(limitSells) {
                    require(amount <= maxSellTxAmount, "maxSellTxAmount Limit Exceeded");
                    }
                }
            }

            // fees redistribution
            if(address(this).balance > minimumWeiForTokenomics) {
                //marketing
                if(sendToMarketing) {
                    uint256 marketingTokens = minimumWeiForTokenomics * sellMarketingFee / totalSellFee;
                    (bool success,) = address(marketingAddress).call{value: marketingTokens}("");
                }
                //dev
                if(sendToDev) {
                    uint256 devTokens = minimumWeiForTokenomics * sellDevFee / totalSellFee;
                    (bool success,) = address(devAddress).call{value: devTokens}("");
                }
                //team
                if(sendToTeam) {
                    uint256 teamTokens = minimumWeiForTokenomics * sellTeamFee / totalSellFee;
                    (bool success,) = address(teamAddress).call{value: teamTokens}("");
                }
            }
        // fees management
            if(feeStatus) {
                // buy
                if(trade_type == 1 && buyFeeStatus && !excludedFromFees[to]) {
                	uint txFees = amount * totalBuyFee / 100;
                	amount -= txFees;
                    super._transfer(from, address(this), txFees);
                }
                //sell
                if(trade_type == 2 && sellFeeStatus && !excludedFromFees[from]) {
                	uint txFees = amount * totalSellFee / 100;
                	amount -= txFees;
                    super._transfer(from, address(this), txFees);
                }
                // no wallet to wallet tax
            }
        }
        // transfer tokens
        super._transfer(from, to, amount);
    }
    //heheboi.gif
}