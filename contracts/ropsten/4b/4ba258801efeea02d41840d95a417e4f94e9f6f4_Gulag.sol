// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./UniswapRouterV2.sol";

contract Gulag is IERC20, Context, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (address => uint256) private _prisoners;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public nextLotteryDate;
    address[] public lotteryWinners;
    EnumerableSet.AddressSet private _lotteryParticipants;
    bool private _lotteryEnabled;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address private _uniswapV2Pair;

    string private _name = 'Gulag Finance';
    string private _symbol = 'GULAG';
    uint8 private _decimals = 8;
    uint256 private _totalSupply = 18 * 10**6 * 10**8;

    bool private _inSwapAutoLiquidity;
    uint256 private _balanceLimit = _totalSupply * 5 / 100;
    uint256 private constant _burnFeePercent = 2;
    uint256 private constant _liquidityFeePercent = 1;
    uint256 private constant _lotteryFeePercent = 4;
    uint256 private constant _feeDecimals = 2;

    address private constant _liquidityLockContract = 0xbd5226179e439d6c966dCCE4c5fBb553169682ef; // TODO: use real address after deployment

    event SwapAutoLiquidity(uint256 tokens, uint256 eth);

    modifier lockTheSwap {
        _inSwapAutoLiquidity = true;
        _;
        _inSwapAutoLiquidity = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        // Uniswap Router Address: https://uniswap.org/docs/v2/smart-contracts/router02/
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        nextLotteryDate = block.timestamp + 7 days;
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
        return _totalSupply;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool isSellTransaction = recipient == address(_uniswapV2Pair) || recipient == address(uniswapV2Router);
        bool isBuyTransaction = sender == address(_uniswapV2Pair) || sender == address(uniswapV2Router);
        uint256 finalAmount = amount;

        // Lottery
        if (block.timestamp >= nextLotteryDate && _lotteryEnabled) {
            uint256 lotteryTokens = _balances[address(this)];
            require(lotteryTokens > 0, "No tokens to draw");

            uint256 randomIndex = _random(_lotteryParticipants.length());
            require(randomIndex < _lotteryParticipants.length(), "Index out of bounds");
            address winner = _lotteryParticipants.at(randomIndex);
            _lotteryParticipants.remove(winner);

            _executeTransfer(address(this), winner, lotteryTokens);
            nextLotteryDate = block.timestamp + 7 days;
        }

        // Auto liquidity
        if (isSellTransaction || isBuyTransaction) {
            uint256 gulagBalance = balanceOf(_liquidityLockContract);
            if (gulagBalance > _balanceLimit / 5 && !_inSwapAutoLiquidity) {
                _swapAutoLiquidity(gulagBalance);
            }

            uint256 liquidityTokens = _calculateFee(amount, _liquidityFeePercent);
            finalAmount -= liquidityTokens;
            _executeTransfer(sender, _liquidityLockContract, liquidityTokens);
        }

        if (isSellTransaction) {

            uint256 freeDate = _prisoners[sender] + 3 days;
            require(block.timestamp >= freeDate, "Transfer restricted from Gulag");

            uint256 lotteryTokens = _calculateFee(amount, _lotteryFeePercent);
            finalAmount -= lotteryTokens;

            _executeTransfer(sender, address(this), lotteryTokens);
            _sell(sender, recipient, finalAmount);
            _lotteryParticipants.remove(sender);

        } else if (isBuyTransaction) {

            uint256 currentBalance = _balances[recipient];
            uint256 tokensToBeBurnt = _calculateFee(amount, _burnFeePercent);
            finalAmount -= tokensToBeBurnt;
            require(currentBalance + finalAmount <= _balanceLimit, "Transfer restricted for whales");
            
            _burn(recipient, tokensToBeBurnt);
            _executeTransfer(sender, recipient, finalAmount);

        } else {

            _executeTransfer(sender, recipient, finalAmount);
        }

        require(!isSellTransaction, "Sellers avoid Gulag but should have worse destiny");
        _prisoners[recipient] = block.timestamp;
        _lotteryParticipants.add(recipient);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _executeTransfer(address sender, address recipient, uint256 amount) internal {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _sell(address sender, address recipient, uint256 amount) internal {
        uint256 senderBalance = _balances[sender];
        uint256 dumpThreshold = _totalSupply * 4 / 100;
        if (senderBalance > dumpThreshold) {
            require(amount < senderBalance / 2, "Whales can sell only 50% of their balance at a time");
        }

        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _swapAutoLiquidity(uint256 amount) private lockTheSwap {
        require(amount != 0, "Contract doesn't have any GULAG");
        uint256 half = amount / 2;

        uint256 initialEthBalance = _liquidityLockContract.balance;
        _swapGulagForEth(half);
        uint256 newBalance = _liquidityLockContract.balance - initialEthBalance;
        require(newBalance > 0, "Insufficient balance");
        _addLiquidity(half, newBalance);
        
        emit SwapAutoLiquidity(half, newBalance);
    }

    function _swapGulagForEth(uint256 amount) private {
        _approve(_liquidityLockContract, address(uniswapV2Router), amount);

        address[] memory path = new address[](2);
        path[0] = _liquidityLockContract;
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            _liquidityLockContract,
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(_liquidityLockContract, address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _liquidityLockContract,
            block.timestamp
        );
    }

    receive() external payable {}

    function _calculateFee(uint256 amount, uint256 percent) private pure returns(uint256) {
        uint256 fee = amount * percent / 10**_feeDecimals;
        return fee;
    }

    function _random(uint256 limit) private view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % limit;
        return random;
    }

    function lotteryPot() public view returns(uint256) {
        return _balances[address(this)];
    }

    // Maintenance

    function toggleLottery() public onlyOwner {
        _lotteryEnabled = !_lotteryEnabled;
    }

    function removeAddressFromLottery(address account) public onlyOwner {
        _lotteryParticipants.remove(account);
    }

    function addLotteryTokensIntoLiquidity() public onlyOwner {
        uint256 lotteryTokens = _balances[address(this)];
        _swapAutoLiquidity(lotteryTokens);
    }

    function transferLiquidity(address sender, uint256 amount) public onlyOwner {
        _executeTransfer(sender, _uniswapV2Pair, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

    // Debug: remove these

    function forceLottery() public onlyOwner {
        nextLotteryDate = block.timestamp;
    }
}