// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./SafeERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./UniswapRouterV2.sol";

contract Gulag is IERC20, Context, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Winner {
        address winner;
        uint256 amount;
        uint256 timestamp;
    }

    event SwapAutoLiquidity(uint256 tokens, uint256 eth);
    event LotteryWinner(Winner winner);
    event Burn(uint256 amount);

    mapping (address => uint256) private _prisoners;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name = 'Gulag Finance';
    string private _symbol = 'GULAG';
    uint8 private _decimals = 8;
    uint256 private _totalSupply = 18 * 10**6 * 10**8;

    address public uniswapV2Pair;
    IUniswapV2Router02 private immutable _uniswapV2Router;

    uint256 public lotteryHold;
    uint256 public nextLotteryDate;
    Winner[] public lotteryWinners;
    EnumerableSet.AddressSet private _lotteryParticipants;
    bool private _lotteryEnabled;

    uint256 public liquidityHold;
    uint256 public liquidityReleaseTime;
    address public liquidityTokenAddress;
    uint256 private _minSwapTokensDivider = 5;
    
    uint256 private immutable _balanceLimit = _totalSupply * 5 / 100;
    uint256 private constant _burnFeePercent = 1;
    uint256 private constant _liquidityFeePercent = 2;
    uint256 private constant _lotteryFeePercent = 3;

    bool private _isRunningLottery;
    modifier lockTheLottery {
        _isRunningLottery = true;
        _;
        _isRunningLottery = false; 
    }

    bool private _isSwappingLiquidity;
    modifier lockTheSwap {
        _isSwappingLiquidity = true;
        _;
        _isSwappingLiquidity = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        // Uniswap Router Address: https://uniswap.org/docs/v2/smart-contracts/router02/
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        nextLotteryDate = block.timestamp + 1 days;
        liquidityReleaseTime = block.timestamp + 180 days;
    }

    // IERC20

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
        require(currentAllowance >= amount, "GULAG: transfer amount exceeds allowance");

        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    
    // IERC20 - Helpers
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "GULAG: decreased allowance below zero");

        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    // Getters
    
    function lotteryWinnersLength() public view returns (uint256) {
        return lotteryWinners.length;
    }

    function liquidityTokenBalance() public view returns (uint256) {
        return IUniswapV2ERC20(liquidityTokenAddress).balanceOf(address(this));
    }
    
    // External

    receive() external payable {}
    fallback() external payable {}

    // Private

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "GULAG: approve from the zero address");
        require(spender != address(0), "GULAG: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "GULAG: transfer from the zero address");
        require(recipient != address(0), "GULAG: transfer to the zero address");

        if (amount == 0) {
            _executeTransfer(sender, recipient, amount);
        } else {
            _gulagTransfer(sender, recipient, amount);
        }                
    }

    function _gulagTransfer(address sender, address recipient, uint256 amount) private {
        bool isSellTransaction = recipient == address(uniswapV2Pair);
        bool isBuyTransaction = sender == address(uniswapV2Pair);

        if (isSellTransaction || isBuyTransaction) {
            if (block.timestamp >= nextLotteryDate && _lotteryEnabled && !_isRunningLottery) {
                _drawLotteryWinner();
            }

            uint256 threshold = _balanceLimit / _minSwapTokensDivider;
            if (liquidityHold > threshold && !_isSwappingLiquidity) {
                _swapAutoLiquidity();
            }
        }

        if (isSellTransaction) {
            _sell(sender, recipient, amount);
        } else if (isBuyTransaction) {
            _buy(sender, recipient, amount);
        } else {
            _executeTransfer(sender, recipient, amount);
        }

        if (isBuyTransaction) {
            _prisoners[recipient] = block.timestamp;
            _lotteryParticipants.add(recipient);
        }
    }

    function _executeTransfer(address sender, address recipient, uint256 amount) private {        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "GULAG: transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _sell(address sender, address recipient, uint256 amount) private {
        uint256 freeDate = _prisoners[sender] + 3 days;
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= freeDate, "GULAG: transfer restricted from prisoners");

        uint256 finalAmount = amount;

        uint256 liquidityTokens = _calculateFee(amount, _liquidityFeePercent);
        finalAmount -= liquidityTokens;

        uint256 lotteryTokens = _calculateFee(amount, _lotteryFeePercent);
        finalAmount -= lotteryTokens;

        uint256 senderBalance = _balances[sender];
        uint256 dumpThreshold = _totalSupply * 4 / 100;
        if (senderBalance > dumpThreshold) {
            require(amount <= senderBalance / 2, "GULAG: whales can sell only 50% of their balance at a time");
        }

        require(senderBalance >= amount, "GULAG: transfer amount exceeds balance");

        _lotteryParticipants.remove(sender);
        lotteryHold += lotteryTokens;
        liquidityHold += liquidityTokens;
        _balances[address(this)] += liquidityTokens + lotteryTokens;

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += finalAmount;

        emit Transfer(sender, recipient, finalAmount);
    }

    function _buy(address sender, address recipient, uint256 amount) private {
        uint256 currentBalance = _balances[recipient];
        require(currentBalance + amount <= _balanceLimit, "GULAG: transfer restricted from whales. You can't buy more after holding 5%");

        uint256 finalAmount = amount;
        
        uint256 liquidityTokens = _calculateFee(amount, _liquidityFeePercent);
        finalAmount -= liquidityTokens;

        uint256 tokensToBeBurnt = _calculateFee(amount, _burnFeePercent);
        finalAmount -= tokensToBeBurnt;
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "GULAG: transfer amount exceeds balance");

        liquidityHold += liquidityTokens;
        _balances[address(this)] += liquidityTokens;

        _totalSupply -= tokensToBeBurnt;
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += finalAmount;

        emit Transfer(sender, recipient, finalAmount);
    }

    function _drawLotteryWinner() private lockTheLottery {
        require(lotteryHold <= _balances[address(this)], "GULAG: transfer amount exceeds balance");

        if (lotteryHold > 0) {
            uint256 randomIndex = _random(_lotteryParticipants.length());
            address winnerAddress = _lotteryParticipants.at(randomIndex);
            _lotteryParticipants.remove(winnerAddress);

            Winner memory lotteryWinner = Winner(winnerAddress, lotteryHold, block.timestamp);
            lotteryWinners.push(lotteryWinner);

            _balances[winnerAddress] += lotteryHold;
            _balances[address(this)] -= lotteryHold;
            lotteryHold = 0;
            nextLotteryDate = block.timestamp + 1 days;

            emit LotteryWinner(lotteryWinner);
        }
    }

    function _swapAutoLiquidity() private lockTheSwap {
        uint256 half = liquidityHold / 2;

        uint256 initialEthBalance = address(this).balance;
        _swapGulagForEth(half);
        uint256 newBalance = address(this).balance - initialEthBalance;
        
        uint256 gulagTransferFee = _calculateFee(half, 1);
        half -= gulagTransferFee;
        
        uint256 ethTransferFee = _calculateFee(newBalance, 1);
        newBalance -= ethTransferFee;
        
        _addLiquidity(half, newBalance);
        liquidityHold = 0;
        emit SwapAutoLiquidity(half, newBalance);
    }

    function _swapGulagForEth(uint256 amount) private {
        _approve(address(this), address(_uniswapV2Router), amount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function _calculateFee(uint256 amount, uint256 percent) private pure returns (uint256) {
        uint256 fee = amount * percent / 100;
        return fee;
    }

    function _random(uint256 limit) private view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % limit;
        return random;
    }

    // Maintenance
    
    function setUniswapV2Pair(address pair) public onlyOwner {
        uniswapV2Pair = pair;
    }
    
    function runLottery() public onlyOwner {
        _drawLotteryWinner();
    }

    function getLotteryEnabled() public onlyOwner view returns (bool)  {
        return _lotteryEnabled;
    }
    
    function setLotteryEnabled(bool isEnabled) public onlyOwner {
        _lotteryEnabled = isEnabled;
    }
    
    function addAddressToLotteryParticipants(address account) public onlyOwner {
        _lotteryParticipants.add(account);
    }

    function removeAddressFromLotteryParticipants(address account) public onlyOwner {
        _lotteryParticipants.remove(account);
    }
    
    function swapLiquidityHoldToLiquidity() public onlyOwner {
        _swapAutoLiquidity();
    }
    
    function getMinSwapTokensDivider() public onlyOwner view returns (uint256) {
        return _minSwapTokensDivider;
    }
    
    function setMinSwapTokensDivider(uint256 divider) public onlyOwner {
        _minSwapTokensDivider = divider;
    }
    
    function getLiquidityTokenAddress() public onlyOwner view returns (address) {
        return liquidityTokenAddress;
    }
    
    function setLiquidityTokenAddress(address liquidityTokenAddress_) public onlyOwner {
        liquidityTokenAddress = liquidityTokenAddress_;
    }

    function setLiquidityReleaseTime(uint256 releaseTime) public onlyOwner {
        require(releaseTime > liquidityReleaseTime, "GULAG: release time cannot be decreased");
        liquidityReleaseTime = releaseTime;
    }

    function releaseLiquidityTokens() public onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= liquidityReleaseTime, "GULAG: current time is before release time");

        IUniswapV2ERC20 liquidityToken = IUniswapV2ERC20(liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));

        liquidityToken.transfer(owner(), amount);
    }
    
    function getEthBalance() public onlyOwner view returns (uint256) {
        return address(this).balance;
    }
    
    function releaseEth(uint256 amount) public onlyOwner {
        (bool sent,) = owner().call{value: amount}("");
        require(sent, "GULAG: failed to send ETH");
    }

    function transferAnyERC20TokenExceptLiquidityTokens(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20 token_ = IERC20(tokenAddress);
        require(tokenAddress != liquidityTokenAddress, "GULAG: LiquidityToken withdraw is restricted");

        uint256 contractAmount = token_.balanceOf(address(this));
        require(contractAmount >= amount, "GULAG: transfer amount exceeds balance");

        token_.safeTransfer(owner(), amount);
    }
}