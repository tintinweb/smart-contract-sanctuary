import './SafeMath.sol';
import './IER20.sol';
import './IUniswapV2Factory.sol';
import './Context.sol';
import './Ownable.sol';

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

//  TheMaker Token Summary
//  No fee, no tax
contract TheMaker is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // contract info
    uint8 private _decimals = 9;
    string private _name = "The Maker";
    string private _symbol = "MAKER";
    uint256 private _tTotal = 1000 * 10**9 * 10**uint256(_decimals);

    uint256 private _maxTxAmount = _tTotal.div(50); //20 billion
    bool private _inSwapAndSend;
    bool private _swapAndSendEnabled = true;

    IUniswapV2Router02 private immutable uniswapV2Router;
    address private immutable _uniswapV2Pair;

    mapping (address => mapping (address => uint256)) private _allowances;
    event SwapAndSendEnabledUpdated(bool enabled);

    modifier lockTheSwap {
        _inSwapAndSend = true;
        _;
        _inSwapAndSend = false;
    }

    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Create a uniswap pair for this new token
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
       return account.balance;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        transfer(sender, recipient, amount);
        approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function maxTransactionAmount() public view returns (uint256) {
        return _maxTxAmount;
    }

    //To recieve ETH when swaping
    receive() external payable {}

    function approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner()){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        tokenTransfer(from,to,amount);
    }

    function swapAndSend(uint256 contractTokenBalance) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        approve(address(this), address(uniswapV2Router), contractTokenBalance);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function tokenTransfer(address sender, address recipient, uint256 amount) private {
        transferStandard(sender, recipient, amount);
    }

    function transferStandard(address sender, address recipient, uint256 tAmount) private {
        emit Transfer(sender, recipient, tAmount);
    }

    function setMaxTxAmount(uint256 maxTxAmount) private {
        _maxTxAmount = maxTxAmount;
    }
}