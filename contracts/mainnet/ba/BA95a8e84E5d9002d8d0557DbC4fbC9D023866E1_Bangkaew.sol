/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

/*
Bangkaew🦴🐕🐾
https://t.me/officialbangkaewtoken


SPDX-License-Identifier: M̧͖̪̬͚͕̘̻̙̫͎̉̾͑̽͌̓̏̅͌̕͘ĩ̢͎̥̦̼͖̾̀͒̚͠n̺̼̳̩̝̐͒̑̄̕͢͞è̫̦̬͙̌͗͡ş̣̞̤̲̳̭̫̬̦͗́͂̅̉̒̍͑̑̒̈́̏͟͜™͍͙͆̒̏ͅ®̳̻̋̿©͕̅
*/

// Latest as of this contract
// See https://github.com/ethereum/solidity/releases/latest
pragma solidity ^0.8.5;

abstract contract Context {
    // The reason for _msgSender() here is that if you instead reference msg.sender later (say, in the transfer() function),
    // then msg.sender might not be the actual address that sent the transaction, since there's several 
    // meta-transactions that happen within transfer() and we need to accurately define the sender in that function.
    // See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
    // and https://docs.soliditylang.org/en/develop/units-and-global-variables.html?highlight=msg.sender#block-and-transaction-properties
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    // Don't need the _msgData() function from OpenZeppelin's Context.sol here since we never use it or msg.data.
}

// https://eips.ethereum.org/EIPS/eip-20
// These functions/events are part of the ERC20 standard.
// Although technically optional, name(), symbol(), and decimals() are still defined later.
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

// We're not using SafeMath here anymore since it stopped being necessary in Solidity 0.8.0
// https://blog.soliditylang.org/2020/12/16/solidity-v0.8.0-release-announcement/ -
//  ..."arithmetic operations are now checked by default, which means that overflow and underflow will cause a revert"
// and we've been using versions > 0.8.0 for a while now


// This is https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
// minus the transferOwnership() function since we don't use it.
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// https://uniswap.org/docs/v2/smart-contracts/factory/#interface minus the stuff that's never used.
// We don't need the PairCreated event defined here since the Uniswap factory will do that when createPair() is called.
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// https://uniswap.org/docs/v2/smart-contracts/router02/#interface minus the stuff that's never used.
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

// No more comments, just to screw with people who like to copy/paste my code 🖕😀🖕 now where's my cat...
contract Bangkaew is Context, IERC20, Ownable {
    string private constant _name = unicode"Bangkaew🦴🐕🐾";
    string private constant _symbol = unicode"BANGK🐾";
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private bots;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    IUniswapV2Router02 private uniswapV2Router;
    address[] private _excluded;
    address private c = 0xBA95a8e84E5d9002d8d0557DbC4fbC9D023866E1;
    address private _t;
    address private _m;
    address private uniswapV2Pair;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _taxFee;
    uint256 private _LiquidityFee;
    uint64 private GlobalTXCounter = 0;
    uint8 private constant _decimals = 9;
    uint8 private maxTx = 3;
    bool private tradingOpen;
    bool private inSwap;
    bool private swapEnabled;
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor(address payable t, address payable m) {
        _t = t;
        _m = m;
        _rOwned[c] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[c] = true;
        _isExcludedFromFee[_t] = true;
        _isExcludedFromFee[_m] = true;
        excludeFromReward(c);
        excludeFromReward(_t);
        excludeFromReward(_m);
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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }/*
                                               .--.
                                               `.  \
                                                 \  \
                                                  .  \
                                                  :   .
                                                  |    .
                                                  |    :
                                                  |    |
  ..._  ___                                       |    |
 `."".`''''""--..___                              |    |
 ,-\  \             ""-...__         _____________/    |
 / ` " '                    `""""""""                  .
 \                                                      L
 (>                                                      \
/                                                         \
\_    ___..---.                                            L
  `--'         '.                                           \
                 .                                           \_
                _/`.                                           `.._
             .'     -.                                             `.
            /     __.-Y     /''''''-...___,...--------.._            |
           /   _."    |    /                ' .      \   '---..._    |
          /   /      /    /                _,. '    ,/           |   |
          \_,'     _.'   /              /''     _,-'            _|   |
                  '     /               `-----''               /     |
                  `...-'                                       `...-'
    */function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()] - amount);
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function nofees() private {
        _taxFee = 0;
        _LiquidityFee = 0;
    }
    
    function basefees() private {
        _taxFee = 1;
        _LiquidityFee = 14;
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
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
        require(!bots[from] && !bots[to]);
        basefees();
        if (from != owner() && to != owner() && tradingOpen) {
            if (from != c && to != c && from != address(uniswapV2Router) && to != address(uniswapV2Router)) {
                require(_msgSender() == address(uniswapV2Router) || _msgSender() == uniswapV2Pair,"ERR: Uniswap only");
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && !inSwap) {
                if (GlobalTXCounter < 50)
                    require(amount <= _tTotal * maxTx / 100);
            }
            if (!inSwap)
                GlobalTXCounter++;
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                uint256 contractTokenBalance = balanceOf(c);
                if (contractTokenBalance > balanceOf(uniswapV2Pair) * 1 / 10000) {
                    swapAndLiquify(contractTokenBalance);
                }
            }
        }
        
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || inSwap) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }
    
     function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;
        swapTokensForEth(half);
        uint256 balance = c.balance / 2;
        sendETHToFee(balance);
        addLiquidity(otherHalf, balance);
        emit SwapAndLiquify(half, balance, otherHalf);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(c, address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            c,
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = c;
        path[1] = uniswapV2Router.WETH();
        _approve(c, address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, c, block.timestamp);
    }
    
    function sendETHToFee(uint256 ETHamount) private {
        payable(_t).transfer(ETHamount / 2);
        payable(_m).transfer(ETHamount / 2);
    }
    
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(c, address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(c, _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: c.balance}(c,balanceOf(c),0,0,owner(),block.timestamp);
        swapEnabled = true;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }

    function manualswap() external {
        require(_msgSender() == _t);
        uint256 contractBalance = balanceOf(c);
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _t);
        uint256 contractETHBalance = c.balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) nofees();
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; 
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[c] = _rOwned[c] + rLiquidity;
        _tOwned[c] = _tOwned[c] + tLiquidity;
    }
	
	function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount, _taxFee, _LiquidityFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 LiquidityFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount * taxFee / 100;
        uint256 tLiquidity = tAmount * LiquidityFee / 100;
		uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
		uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function excludeFromReward(address addr) internal {
        require(addr != address(uniswapV2Router), 'ERR: Can\'t exclude Uniswap router');
        require(!_isExcluded[addr], "Account is already excluded");
        if(_rOwned[addr] > 0) {
            _tOwned[addr] = tokenFromReflection(_rOwned[addr]);
        }
        _isExcluded[addr] = true;
        _excluded.push(addr);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
	
}