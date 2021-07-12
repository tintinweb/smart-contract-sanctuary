/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

/*

- ✔️ Supply Name: Pearl of the Orient Seas - Creating a better life for everyone
- ✔️ Symbol: PEARL
- ✔️ Anti-Whale System (3% Sell Price Impact)
- ✔️ Anti-Serial Selling System (Anti-Dump)
- ✔️ Manual Burning and Buyback capability
- ✔️ Send to Buyback Wallet per transaction: 2% (Sent on ETH)
- ✔️ Send to Marketing Wallet per transaction: 1% (Sent on ETH)
- ✔️ Send to Team Wallet per transaction: 5% (Sent on ETH)
- ✔️ Send to Charity Wallet per transaction: 2% (Sent on ETH)
- ✔️ Implemented Dynamic Sell Logic (Anti-Bot)

       
    Developed by Yiannos Christou     
    Debugged, and Tested by Jay Pingul   
    Team: Angelica Tresvalles, Leonard Bangco, Kriz Resurreccion, Edward Nguyen, and the one and only TITA MORIN  
    
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * It also provides the functionality to store the contract in VøidSwap's Cosmic Vault
 * using {storeInCosmicVault}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

contract CVOwnable is Context {
    address private _owner;
    uint256 private _unlockTime;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "CVOwnable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    
    /**
     * @dev Returns the address of the previous owner.
     */
    function previousOwner() public view returns(address) {
        return _previousOwner;
    }
    
    /**
     * @dev Returns the unlock time of the contracted stored in the Cosmic Vault.
     */
    function getUnlockTime() public view returns(uint256){
        return _unlockTime;
    }


    /**
     * @dev Transfers ownership of the contract to the Cosmic Vault (`cosmicVault`) and
     * sets the time (`unlockTime`) at which the now stored contract can be transferred back to
     * the previous owner.

     * NOTE Can only be called by the current owner.
     */
    function storeInCosmicVault(address cosmicVault, uint256 unlockTime) public virtual onlyOwner {
        require(cosmicVault != address(0), "CVOwnable: new owner is the zero address");
        _previousOwner = _owner;
        _unlockTime = unlockTime;
        emit OwnershipTransferred(_previousOwner, cosmicVault);
        _owner = cosmicVault;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * NOTE Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "CVOwnable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        _previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(_previousOwner, newOwner);
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

contract PEARL is Context, IERC20, CVOwnable { // Nominal name
    using SafeMath for uint256;

    string private constant _name = "Pearl of the Orient Seas"; // Token Name
    string private constant _symbol = "PEARL";   // Token symbol
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant _tTotal = 100000000000 * 10**9; // Total supply
    uint256 public _teamFee = 10;
    uint256 public _storedTeamFee = _teamFee;

    uint256 public _teamCutPct = 5; // 5% cut to team
    uint256 public _marketingCutPct = 1; //  1% cut to marketing funds
    uint256 public _charityCutPct = 2; // 2% cut to Project Pearls
    uint256 public _liquidityCutPct = 2; // 2% Buyback cut

    mapping(address => uint256) private sellCooldown;
    mapping(address => uint256) private firstSell;
    mapping(address => uint256) private sellNumber;

    address payable private _teamAddress;
    address payable private _marketingAddress;
    address payable private _charityAddress;
    address payable private _liquidityAddress;
    uint256 public minimumContractTokenBalanceToSwap = 10000000 * 10**9;   // 0.06% of total supply for both LQ and ETH distribution
    uint256 public minimumContractEthBalanceToSwap = 3 * 10**16;
    mapping(address => bool) private _isAdmin;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private _maxTxAmount = _tTotal;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable teamFunds, address payable marketingFunds, address payable charityFunds, address payable liquidityFunds) {
        _teamAddress = teamFunds;
        _marketingAddress = marketingFunds;
        _charityAddress = charityFunds;
        _liquidityAddress = liquidityFunds;
        _balances[_msgSender()] = _tTotal;

        _isExcludedFromFee[owner()] = true;
        _isAdmin[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isAdmin[address(this)] = true;
        _isExcludedFromFee[_teamAddress] = true;
        _isAdmin[_teamAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isAdmin[_marketingAddress] = true;
        _isExcludedFromFee[_charityAddress] = true;
        _isAdmin[_charityAddress] = true;
        _isExcludedFromFee[_liquidityAddress] = true;
        _isAdmin[_liquidityAddress] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
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
        if (_teamFee == 0) return;
        _teamFee = 0;
    }

    function restoreAllFee() private {
        _teamFee = _storedTeamFee;
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

        uint256 contractTokenBalance = balanceOf(address(this)); // Get Token contract balance
        bool overMinTokenBalance = contractTokenBalance >= minimumContractTokenBalanceToSwap;
        uint256 contractETHBalance = address(this).balance; // Get ETH contract balance
        bool overMinEthBalance = contractETHBalance >= minimumContractEthBalanceToSwap;

        if (!_isAdmin[from] && !_isAdmin[from]) {
            
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) { // Buying
                require(tradingOpen);
                _teamFee = 10; // BUYING 2% Charity, 2% Liquidity Fee, 1% Marketing, 5% Team Fee = 10
            }

            if (!inSwap && swapEnabled && to == uniswapV2Pair) { // Dynamic Selling Logic
                require(amount <= balanceOf(uniswapV2Pair).mul(3).div(100) && amount <= _maxTxAmount);
                require(sellCooldown[from] < block.timestamp);
                if(firstSell[from] + (4 hours) < block.timestamp) {
                    sellNumber[from] = 0;
                }
                if (sellNumber[from] == 0) { // Cooldown Timings
                    _teamFee = 10; // BUYING 2% Charity, 2% Liquidity Fee, 1% Marketing, 5% Team Fee = 10
                    sellNumber[from]++;
                    firstSell[from] = block.timestamp;
                    sellCooldown[from] = block.timestamp + (60 seconds); //from initial buy 60 seconds
                }
                else if (sellNumber[from] == 1) {
                    _teamFee = 13; // BUYING 2% Charity, 4% Liquidity Fee, 1% Marketing, 6% Team Fee = 13
                    sellNumber[from]++;
                    sellCooldown[from] = block.timestamp + (30 minutes); //from 1st buy 30 minutes
                }
                else if (sellNumber[from] == 2) {
                    _teamFee = 16; // BUYING 2% Charity, 6% Liquidity Fee, 1% Marketing, 7% Team Fee = 16
                    sellNumber[from]++;
                    sellCooldown[from] = block.timestamp + (2 hours); //from 2nd buy 2 hours
                }
                else if (sellNumber[from] == 3) {
                    _teamFee = 19; // BUYING 2% Charity, 8% Liquidity Fee, 1% Marketing, 8% Team Fee = 19
                    sellNumber[from]++;
                    sellCooldown[from] = firstSell[from] + (4 hours); //from initial buy, 4 hours then resets to 60 seconds
                }
            }

            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                if (overMinTokenBalance) {
                    swapTokensForEth(contractTokenBalance);
                }

                if (overMinEthBalance) {
                    sendETHToFee(contractETHBalance);
                } 
            }

        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
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
        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function sendETHToFee(uint256 beforeSplit) private {
        uint256 teamCut = beforeSplit.mul(50).div(100);
        uint256 marketingCut = beforeSplit.mul(10).div(100);
        uint256 charityCut = beforeSplit.mul(20).div(100);
        uint256 liquidityCut = beforeSplit.mul(20).div(100);
        _teamAddress.transfer(teamCut);
        _marketingAddress.transfer(marketingCut);
        _charityAddress.transfer(charityCut);
        _liquidityAddress.transfer(liquidityCut);
    }
    
    function openTrading() public onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }

    function addInitialLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Nominal router.
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, address(this), block.timestamp);
        swapEnabled = true;
        liquidityAdded = true;
        _maxTxAmount = 30000000 * 10**9; // 0.3%
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }

    function manualTokenSwap() external {
        require(_msgSender() == owner());
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function recoverEthFromContract() external {
        require(_msgSender() == owner());
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        ( uint256 tTransferAmount, uint256 tTeam) = _getValues(tAmount);
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
        (uint256 tTransferAmount, uint256 tTeam) = _getTValues(tAmount, _teamFee);
        return (tTransferAmount, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 teamFee) private pure returns (uint256, uint256) {
        uint256 tTeam = tAmount.mul(teamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tTeam);
        return (tTransferAmount, tTeam);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function manualBurn (uint256 amount) external onlyOwner() {
        require(amount <= balanceOf(owner()), "Amount exceeds available tokens.");
        _tokenTransfer(msg.sender, deadAddress, amount, false);
    }

    function setRouterAddress(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }

    function setTeamCutFee (uint256 _teamCut) external onlyOwner() {
        _teamCutPct = _teamCut;
        _teamFee = _teamCut.add(_marketingCutPct).add(_charityCutPct).add(_liquidityCutPct);
        _storedTeamFee = _teamFee;
    }

    function setMarketingCutFee (uint256 _marketingCut) external onlyOwner() {
        _marketingCutPct = _marketingCut;
        _teamFee = _teamCutPct.add(_marketingCut).add(_charityCutPct).add(_liquidityCutPct);
        _storedTeamFee = _teamFee;
    }
    function setCharityCutFee (uint256 _charityCut) external onlyOwner() {
        _charityCutPct = _charityCut;
        _teamFee = _teamCutPct.add(_marketingCutPct).add(_charityCut).add(_liquidityCutPct);
        _storedTeamFee = _teamFee;
    }
    function setLiquidityCutFee (uint256 _liquidityCut) external onlyOwner() {
        _liquidityCutPct = _liquidityCut;
        _teamFee = _teamCutPct.add(_marketingCutPct).add(_charityCutPct).add(_liquidityCut);
        _storedTeamFee = _teamFee;
    }
}