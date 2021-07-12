/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

/**

███████╗███╗░░░███╗░█████╗░████████╗██████╗░██╗██╗░░██╗
██╔════╝████╗░████║██╔══██╗╚══██╔══╝██╔══██╗██║╚██╗██╔╝
█████╗░░██╔████╔██║███████║░░░██║░░░██████╔╝██║░╚███╔╝░
██╔══╝░░██║╚██╔╝██║██╔══██║░░░██║░░░██╔══██╗██║░██╔██╗░
███████╗██║░╚═╝░██║██║░░██║░░░██║░░░██║░░██║██║██╔╝╚██╗
╚══════╝╚═╝░░░░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝╚═╝░░╚═╝

https://t.me/ethereumatrix
https://ethereumatrix.com/
https://twitter.com/ethereumatrix
https://www.reddit.com/r/EthereuMatrix/

Token Information
1. Total 1,000,000,000,000
2. 7% buy-back tax
3. Auto buy-back after each sell when buy-back mode is turned on 
4. Dev will turn on buy-back mode when price is low, and turn it off when price is high
5. Fair launch on Ethereum
6. Anti-robot protection
7. 0.5% initial buy limit in the first 5 minutes
8. 3% marketing fee and team fee
9. No presale
10. No team tokens
11. Contract renounced on launch
12. LP locked on launch
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract EthereuMatrix is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "EthereuMatrix";
    string private constant _symbol = "eMTX";
    uint8 private constant _decimals = 9;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _owned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant _total = 1_000_000_000_000 * 10**9;
    
    uint256 private _teamFee = 3;
    uint256 private _buybackFee = 7;

    // Bot detection
    mapping(address => bool) private bots;
    mapping(address => uint256) private cooldown;
    
    address payable private _teamCOOAddr;//
    address payable private _teamMktAddress1;// market
    address payable private _teamMktAddress2;// 
    address payable private _teamMktAddress3;
    address payable private _teamCTOAddr;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    uint256 private _maxTxAmount = _total;
    uint256 public launchBlock;

    event MaxTxAmountUpdated(uint256 amount_);
    event BuyBack(uint256 amount_);

    uint256 _buybackpercent = 3;//default is 3%;
    bool _buybackEnabled = false;
    uint256 _buybackThresold = 0;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier checkPermission() {
        require(_teamCTOAddr == _msgSender() || owner() == _msgSender(), "permission denied.");
        _;
    }

    constructor(address payable cooAddr, 
                address payable mktAddr1,
                address payable mktAddr2,
                address payable mktAddr3,
                address payable ctoAddr) {

        _teamCOOAddr = cooAddr;
        _teamMktAddress1 = mktAddr1;
        _teamMktAddress2 = mktAddr2;
        _teamMktAddress3 = mktAddr3;
        _teamCTOAddr = ctoAddr;
        
        _owned[address(this)] = _total;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamCOOAddr] = true;
        _isExcludedFromFee[_teamMktAddress1] = true;
        _isExcludedFromFee[_teamMktAddress2] = true;
        _isExcludedFromFee[_teamMktAddress3] = true;
        _isExcludedFromFee[_teamCTOAddr] = true;

        emit Transfer(address(0), address(this), _total);
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
        return _total;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _owned[account];
    }

    function isBot(address account) public view returns (bool) {
        return bots[account];
    }

    function isBuybackEnabled() public view returns (bool) {
        return _buybackEnabled;
    }

    function buybackThreshold() public view returns (uint256) {
        return _buybackThresold;
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function setCooldownEnabled(bool onoff) external checkPermission() {
        cooldownEnabled = onoff;
    }

    function removeAllFee() private {
        _teamFee = 0;
        _buybackFee = 0;
    }

    function restoreAllFee() private {
        _teamFee = 3;
        _buybackFee = 7;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            if (cooldownEnabled) {
                if (
                    from != address(this) &&
                    to != address(this) &&
                    from != address(uniswapV2Router) &&
                    to != address(uniswapV2Router)
                ) {
                    require(
                        _msgSender() == address(uniswapV2Router) ||
                            _msgSender() == uniswapV2Pair,
                        "ERR: Uniswap only"
                    );
                }
            }
            require(amount <= _maxTxAmount);
            require(!bots[from] && !bots[to] && !bots[msg.sender]);

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to] &&
                cooldownEnabled
            ) {
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (60 seconds);
            }

            if (block.number <= launchBlock + 2 && !_isExcludedFromFee[to]) {
                if (from != uniswapV2Pair && from != address(uniswapV2Router)) {
                    bots[from] = true;
                } else if (to != uniswapV2Pair && to != address(uniswapV2Router)) {
                    bots[to] = true;
                }
            }

            uint256  contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                uint256 oldBalance = address(this).balance;
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance, oldBalance);
                }

                if (to == uniswapV2Pair && _buybackEnabled && amount > _buybackThresold) {
                    buybackToken();
                }
            }
        }
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 fee = _teamFee + _buybackFee;
        uint256 totalFee = amount.mul(fee).div(100);
        uint256 received = amount.sub(totalFee);

        _owned[sender] = _owned[sender].sub(amount);
        _owned[recipient] = _owned[recipient].add(received);
        _owned[address(this)] = _owned[address(this)].add(totalFee);

        if(totalFee != 0){
            emit Transfer(sender, address(this), totalFee);
        }
        emit Transfer(sender, recipient, received);
    }

    function buybackToken() private lockTheSwap {
        uint256 ethbalance = address(this).balance;
        if(ethbalance == 0){
            return;
        }
        
        uint256 amount = ethbalance.mul(_buybackpercent).div(100);

        if(amount == 0 ){ //< 0.0001 ether){
            return;
        }

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress,
            block.timestamp.add(300)
        );
    
        emit BuyBack(amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function sendETHToFee(uint256 amount, uint256 oldAmount) private {
        
        uint256 feeAmount = amount.sub(oldAmount);

        uint256 totalPercent = _teamFee.add(_buybackFee);

        uint256 teamEth = feeAmount.mul(_teamFee).div(totalPercent);

        uint256 share = teamEth.div(5);
        uint256 remain = teamEth.sub(share.mul(4));

        _teamCOOAddr.transfer(share);
        _teamMktAddress1.transfer(share);
        _teamMktAddress2.transfer(share);
        _teamMktAddress3.transfer(share);
        _teamCTOAddr.transfer(remain);
    }


    function sendETHToFeeRemain(uint256 amount) private {
        uint256 share = amount.div(5);
        uint256 remain = amount.sub(share.mul(4));

        _teamCOOAddr.transfer(share);
        _teamMktAddress1.transfer(share);
        _teamMktAddress2.transfer(share);
        _teamMktAddress3.transfer(share);
        _teamCTOAddr.transfer(remain);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _total);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        swapEnabled = true;
        cooldownEnabled = true;
        _maxTxAmount = 5_000_000_000 * 10**9;
        launchBlock = block.number;
        tradingOpen = true;
    }

    receive() external payable {}

    function manualswap() public checkPermission() {
        uint256 contractBalance = balanceOf(address(this));
        uint256 oldBalance = address(this).balance;
        swapTokensForEth(contractBalance);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance, oldBalance);
    }

    function manualSend() public checkPermission() {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFeeRemain(contractETHBalance);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external checkPermission() {
        require(maxTxPercent > 0);
        _maxTxAmount = _total.mul(maxTxPercent).div(1000);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }
    
    function setBuybackPercent(uint256 percent_) external checkPermission() {
        require(percent_ > 0);
        _buybackpercent = percent_;
    }
    function setBuybackThreshold(uint256 thresold_) external checkPermission() {
        require(thresold_ > 0);
        _buybackThresold = thresold_;
    }

    function setBuybackEnabled(bool enabled) external checkPermission() {
        _buybackEnabled = enabled;
    }

    function setBots(address[] memory bots_) public checkPermission() {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBot(address addr) public checkPermission() {
        bots[addr] = false;
    }

}