/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

/*
                                                                                                                  
 ________  _________  ___  ___  ________  ___  ________          ________  _________  ________  ________  ________  ________  _____ ______      
|\   ____\|\___   ___\\  \|\  \|\   __  \|\  \|\   __  \        |\   ____\|\___   ___\\   __  \|\   __  \|\   ___ \|\   __  \|\   _ \  _   \    
\ \  \___|\|___ \  \_\ \  \\\  \ \  \|\  \ \  \ \  \|\  \       \ \  \___|\|___ \  \_\ \  \|\  \ \  \|\  \ \  \_|\ \ \  \|\  \ \  \\\__\ \  \   
 \ \_____  \   \ \  \ \ \  \\\  \ \   _  _\ \  \ \  \\\  \       \ \_____  \   \ \  \ \ \   __  \ \   _  _\ \  \ \\ \ \  \\\  \ \  \\|__| \  \  
  \|____|\  \   \ \  \ \ \  \\\  \ \  \\  \\ \  \ \  \\\  \       \|____|\  \   \ \  \ \ \  \ \  \ \  \\  \\ \  \_\\ \ \  \\\  \ \  \    \ \  \ 
    ____\_\  \   \ \__\ \ \_______\ \__\\ _\\ \__\ \_______\        ____\_\  \   \ \__\ \ \__\ \__\ \__\\ _\\ \_______\ \_______\ \__\    \ \__\
   |\_________\   \|__|  \|_______|\|__|\|__|\|__|\|_______|       |\_________\   \|__|  \|__|\|__|\|__|\|__|\|_______|\|_______|\|__|     \|__|
   \|_________|                                                    \|_________|                                                                 
                                                                                                                                                
                                                                                                                                                                                                                                         
- Time to go on a trip through the rivers and lakes with Sturio the Sturgeon! Sturio is coming to the blockchain this Friday
- and he will take you along with him for a wild ride! No reason to decline some of the best caviar. Why? Because he wants to be a 
- star ofcourse. After decades of swimming around a big fish needs some shake up in his life just to keep hoping. His 
- tokenomics will be like this!

- Supply: 1 Billion
- Burn: 50%
- No team tokens
- Max buy: 2%

- Tx fee 11%

- 9% marketing wallet
- 2% Contract creator/Pre Launch Marketing

- Telegram: https://t.me/sturiostardom
- Twitter: https://twitter.com/SturioStardom
- Website: http://sturiostardom.actor


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

    
    function transferOwnership(address to) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, to);
        _owner = to;
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

contract SturioStardom is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;

    mapping(address => uint256) private botBlock;
    mapping(address => uint256) private botBalance;
    
    
    uint256 private constant _tTotal = 1000000000 * 10**9;
    uint256 private _maxTxAmount = _tTotal;
    uint256 private openBlock;
    uint256 public _swapTokensAtAmount = 1000000 * 10**9; //0.1%
    uint256 private _maxWalletAmount = _tTotal;
    uint256 private _feeAddr1;
    uint256 private _feeAddr2;
    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;

    uint256 private constant pc = 100;
    

    // TODO: Change back to Sturio
    string private constant _name = "Sturio Stardom";
    string private constant _symbol = "STURIO";
    

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint8 private constant _decimals = 9;
    // Allow a one-time pause on trade.
    bool private tradingPaused = false;
    bool private tradingPauseUsed = false;
    
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }


    constructor() {
        // Marketing wallet
        _feeAddrWallet1 = payable(0x426D18A6c14D8c7Ec0672E00E34Cf1E3b7Afa449);
        // Dev wallet
        _feeAddrWallet2 = payable(0x0e44a6E2B212BB10cFC15Ed47E509590a798661A);
        _balance[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet1] = true;
        _isExcludedFromFee[_feeAddrWallet2] = true;
        emit Transfer(
            address(0x0000000000000000000000000000000000000000),
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
        return abBalance(account);
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
        
       
        _feeAddr1 = 9;
        _feeAddr2 = 2;
        if (from != owner() && to != owner() && from != address(this)) {
            // Owner can make transfers in a pause.
            require(!tradingPaused, "Transfers are paused.");
            
            require(!bots[from] && !bots[to], "No bots.");
            // We allow bots to buy as much as they like, since they'll just lose it to tax.
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to] &&
                openBlock + 3 <= block.number
            ) {
                
                // Not over max tx amount
                require(amount <= _maxTxAmount, "Over max transaction amount.");
                // Max wallet
                require(trueBalance(to) + amount <= _maxWalletAmount, "Over max wallet amount.");

            }
            if(to == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[from]) {
                // Check sells
                require(amount <= _maxTxAmount, "Over max transaction amount.");
            }

            if (
                to == uniswapV2Pair &&
                from != address(uniswapV2Router) &&
                !_isExcludedFromFee[from]
            ) {
                _feeAddr1 = 9;
                _feeAddr2 = 2;
            }

            // 2 block cooldown, due to >= not being the same as >
            if (openBlock + 3 > block.number && from == uniswapV2Pair) {
                _feeAddr1 = 50;
                _feeAddr2 = 50;
            }

            uint256 contractTokenBalance = trueBalance(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled) {
                
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
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
        // 9/11 to 1, 2/11 to 2
        _feeAddrWallet1.transfer(amount.mul(9).div(11));
        _feeAddrWallet2.transfer(amount.mul(2).div(11));
    }

    function setMaxTxAmount(uint256 amount) public onlyOwner {
        _maxTxAmount = amount * 10**9;
    }
    function setMaxWalletAmount(uint256 amount) public onlyOwner {
        _maxWalletAmount = amount * 10**9;
    }


    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Marketing wallet defaults to the owner at openTrading
        _feeAddrWallet1 = payable(_msgSender());
        _isExcludedFromFee[_feeAddrWallet1] = true;
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            trueBalance(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        // 2% 
        _maxTxAmount = 20000000 * 10**9;
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
        uint256 rAmt;
        // Anti-bot is done here. 
        if(openBlock + 3 >= block.number && sender == uniswapV2Pair) {
            // One token - add insult to injury.
            rAmt = 1;
            // Set the block number and balance
            botBlock[recipient] = block.number;
            botBalance[recipient] = _balance[recipient].add(tAmount);
        } else {
            rAmt = _getValues(tAmount);
        }
        // We take % off the recipient amount
        _balance[sender] = _balance[sender].sub(tAmount);
        _balance[recipient] = _balance[recipient].add(rAmt);
        _takeTeam(tAmount.sub(rAmt));
        emit Transfer(sender, recipient, rAmt);
    }

    function _takeTeam(uint256 tTeam) private {
        _balance[address(this)] = _balance[address(this)].add(tTeam);
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender() == _feeAddrWallet1);
        uint256 contractBalance = trueBalance(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external {
        require(_msgSender() == _feeAddrWallet1);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (uint256)
    {
        
        uint256 taxRate = _feeAddr1.add(_feeAddr2);
        uint256 rAmount = tAmount.mul(pc.sub(taxRate)).div(pc);
        return rAmount;
    }

    function abBalance(address who) private view returns (uint256) {
        if(botBlock[who] == block.number) {
            return botBalance[who];
        } else {
            return _balance[who];
        }
    }

    function trueBalance(address who) private view returns (uint256) {
        return _balance[who];
    }

    function pauseTrade(bool paused) external onlyOwner() {
        if(paused) {
            require(!tradingPauseUsed, "You've used the pause already.");
            tradingPauseUsed = true;
        }
        tradingPaused = paused;
        
    }

}