/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

/*
     _                    _                               ___
    / \   _ __ ___   __ _| |_ ___ _ __ __ _ ___ _   _    |_ _|_ __  _   _
   / _ \ | '_ ` _ \ / _` | __/ _ \ '__/ _` / __| | | |    | || '_ \| | | |
  / ___ \| | | | | | (_| | ||  __/ | | (_| \__ \ |_| |    | || | | | |_| |
 /_/   \_\_| |_| |_|\__,_|\__\___|_|  \__,_|___/\__,_|   |___|_| |_|\__,_|

   Amaterasu Inu $OKAMI

   Ōkami Amaterasu the sun goddess has bestothed on the world an arcane son Amaterasu Inu $OKAMI and with the might and power of all the Inu's will lead the way in creating a decentralised reserve currency for all gods.

   No team tokens, no presale 100% community driven. Marketing driven by the community for the community. Taxes to be used for development of Ōkami Amaterasu's vision of a decentralised god currency.

-  Telegram: https://t.me/AmaterasuInu

*/

//SPDX-License-Identifier: UNLICENSED

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

contract AmaterasuInu is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => uint256) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _maxTxAmount = _tTotal;
    uint256 private openBlock;
    uint256 private _swapTokensAtAmount = 100 * 10**9; // 100 tokens
    uint256 private _maxWalletAmount = _tTotal;
    uint256 private _feeAddr1;
    uint256 private _feeAddr2;
    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;

    string private constant _name = "Amaterasu Inu";
    string private constant _symbol = "OKAMI";
    uint8 private constant _decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable addr1, address payable addr2, address payable addr3) {
        _feeAddrWallet1 = addr1;
        _feeAddrWallet2 = addr2;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet1] = true;
        _isExcludedFromFee[_feeAddrWallet2] = true;
        _isExcludedFromFee[addr3] = true;
        emit Transfer(
            address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B),
            _msgSender(),
            _tTotal
        );
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

    function setCooldownEnabled(bool onoff) external onlyOwner {
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


        _feeAddr1 = 2;
        _feeAddr2 = 8;
        if (from != owner() && to != owner() && from != address(this) && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {


            require(!bots[from] && !bots[to]);
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to] &&
                cooldownEnabled
            ) {

                // Not over max tx amount
                require(amount <= _maxTxAmount, "Over max transaction amount.");
                // Cooldown
                require(cooldown[to] < block.timestamp, "Cooldown enforced.");
                // Max wallet
                require(balanceOf(to) + amount <= _maxWalletAmount, "Over max wallet amount.");
                cooldown[to] = block.timestamp + (30 seconds);
            }

            if (
                to == uniswapV2Pair &&
                from != address(uniswapV2Router) &&
                !_isExcludedFromFee[from]
            ) {
                _feeAddr1 = 2;
                _feeAddr2 = 8;
            }

            if (openBlock + 4 >= block.number && from == uniswapV2Pair) {
                _feeAddr1 = 1;
                _feeAddr2 = 99;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled) {

                swapTokensForEth(contractTokenBalance);
//                uint256 contractETHBalance = address(this).balance;
            //    if (contractETHBalance > 0) {
            //        sendETHToFee(address(this).balance);
          //      }
            }
        } else {
            // Only if it's not from or to owner or from contract address.
            _feeAddr1 = 0;
            _feeAddr2 = 0;
        }

        _tokenTransfer(from, to, amount);
    }

    function swapAndLiquifyEnabled(bool enabled) public onlyOwner {
        inSwap = enabled;
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
        _feeAddrWallet1.transfer(amount.div(2));
        _feeAddrWallet2.transfer(amount.div(2));
    }

    function setMaxTxAmount(uint256 amount) public onlyOwner {
        _maxTxAmount = amount * 10**9;
    }
    function setMaxWalletAmount(uint256 amount) public onlyOwner {
        _maxWalletAmount = amount * 10**9;
    }

    function whitelist(address payable adr1) external onlyOwner {
    _isExcludedFromFee[adr1] = true;
  }
  function unwhitelist(address payable adr2) external onlyOwner {
  _isExcludedFromFee[adr2] = false;
}

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
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
        cooldownEnabled = true;
        // .5%
        _maxTxAmount = 1000000000000 * 10**9;
        _maxWalletAmount = 2000000000000 * 10**9;
        tradingOpen = true;
        openBlock = block.number;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    function addBot(address theBot) public onlyOwner {
        bots[theBot] = true;
    }

    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function setSwapTokens(uint256 swaptokens) public onlyOwner {
        _swapTokensAtAmount = swaptokens;
    }


    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _transferStandard(sender, recipient, amount);
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

    function manualSwap() external {
          uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

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
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(
            tAmount,
            _feeAddr1,
            _feeAddr2
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tTeam,
            currentRate
        );
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
}