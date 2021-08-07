/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

/**

BSC_MAINNET: 0x10ED43C718714eb63d5aA57B78B54704E256024E
BSC_TESTNET: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
PCS_SIM: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
ETH_MAIN/TEST: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract TKN4 is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "TKN4";
    string private constant _symbol = "TKN4";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isAdmin;
    mapping(address => bool) private _isBlacklisted;

    address private immutable deadAddress = address(0);

    uint256 private constant _tTotal = 1000000000000 * 1e9;
    uint256 private _totalFee = 0;
    uint256 private _storedTotalFee = _totalFee;

    // For payout calculations
    uint256 public _payoutTeam = 50;
    uint256 public _payoutMarketing = 50;

    address payable private _teamAddress;
    address payable private _marketingAddress;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap;
    bool private swapEnabled;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable teamFunds, address payable marketingFunds) {
        _teamAddress = teamFunds;
        _marketingAddress = marketingFunds;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        _balances[_msgSender()] = _tTotal;
        _isAdmin[owner()] = true;
        _isAdmin[address(this)] = true;
        _isAdmin[_teamAddress] = true;
        _isAdmin[_marketingAddress] = true;

        swapEnabled = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function removeAllFee() private {
        if (_totalFee == 0) return;
        _totalFee = 0;
    }

    function restoreAllFee() private {
        _totalFee = _storedTotalFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee;

        if (!_isAdmin[from] && !_isAdmin[to]) {
            require(tradingOpen);
            takeFee = true;

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && swapEnabled && to == uniswapV2Pair) { // Selling logic
                require(!_isBlacklisted[from], '!Bot');

                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToWallets(address(this).balance);
                }   
            }
        }

        if (_isAdmin[from] || _isAdmin[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function sendETHToWallets(uint256 amount) private {
        uint256 teamCut = amount.mul(_payoutTeam).div(100);
        uint256 marketingCut = amount.mul(_payoutMarketing).div(100);
        _teamAddress.transfer(teamCut);
        _marketingAddress.transfer(marketingCut);
    }
    
    function openTrading(bool trueFalse) public onlyOwner {
        tradingOpen = trueFalse;
    }

    function manualTokenSwap() external {
        require(_msgSender() == owner());
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function recoverEthFromContract() external {
        require(_msgSender() == owner());
        uint256 contractETHBalance = address(this).balance;
        sendETHToWallets(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tTeam) = _getValues(tAmount);
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _takeTeam(tTeam);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        _balances[address(this)] = _balances[address(this)].add(tTeam);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTeam) = _getTValues(tAmount, _totalFee);
        return (tTransferAmount, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 teamFee) private pure returns (uint256, uint256) {
        uint256 tTeam = tAmount.mul(teamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tTeam);
        return (tTransferAmount, tTeam);
    }

    function manualBurn(uint256 amount) external onlyOwner() {
        require(amount <= balanceOf(owner()), "Amount exceeds available tokens balance");
        _tokenTransfer(msg.sender, deadAddress, amount, false);
    }

    function setAddressTeam(address payable newTeamAddress) external onlyOwner() {
        _isAdmin[_teamAddress] = false;
        _teamAddress = newTeamAddress;
        _isAdmin[newTeamAddress] = true;
    }

    function setAddressMarketing(address payable newMarketingAddress) external onlyOwner() {
        _isAdmin[_marketingAddress] = false;
        _marketingAddress = newMarketingAddress;
        _isAdmin[newMarketingAddress] = true;
    }

    function setPayouts(uint256 newTeamPayout, uint256 newMarketingPayout) external onlyOwner {
        require(newTeamPayout + newMarketingPayout == 100, "Values do not equal 100");
        require(newTeamPayout != 0, "!zero");
        require(newMarketingPayout != 0, "!zero");
        _payoutTeam = newTeamPayout;
        _payoutMarketing = newMarketingPayout;
    }

    function modifyAdmins(address[] calldata wallet, bool trueFalse) external onlyOwner {
        for(uint256 i = 0; i < wallet.length; i++) {
            _isAdmin[wallet[i]] = trueFalse;
        }
    }

    function modifyBlacklist(address wallet, bool trueFalse) external onlyOwner {
        _isBlacklisted[wallet] = trueFalse;
    }
}