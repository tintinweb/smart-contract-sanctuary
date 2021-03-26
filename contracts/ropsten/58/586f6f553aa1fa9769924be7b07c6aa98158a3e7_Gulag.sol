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
        uint256 timestamp;
    }

    event SwapAutoLiquidity(uint256 tokens, uint256 eth);
    event LotteryWinner(Winner winner);
    event Burn(uint256 amount);

    // TODO: remove these debug events
    event SellRestricted(address account, uint256 amount);
    event BuyRestricted(address account, uint256 amount);
    event Buy();
    event Sell();

    mapping (address => uint256) private _prisoners;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name = 'Gulag Finance';
    string private _symbol = 'GULAG';
    uint8 private _decimals = 8;
    uint256 private _totalSupply = 18 * 10**6 * 10**8;

    IUniswapV2Router02 private immutable uniswapV2Router;
    address private _uniswapV2Pair;

    uint256 private _lotteryHold;
    uint256 public nextLotteryDate;
    Winner[] public lotteryWinners;
    EnumerableSet.AddressSet private _lotteryParticipants;
    bool private _lotteryEnabled;
    
    uint256 private _balanceLimit = _totalSupply * 5 / 100;
    uint256 private constant _burnFeePercent = 2;
    uint256 private constant _liquidityFeePercent = 1;
    uint256 private constant _lotteryFeePercent = 4;
    uint256 private constant _feeDecimals = 2;

    address private _liquidityTokenAddress;
    uint256 private _liquidityHold;
    uint256 private _releaseTime;

    bool private _isRunningLottery;
    modifier lockTheLottery {
        _isRunningLottery = true;
        _;
        _lotteryHold = 0;
        _isRunningLottery = false; 
    }

    bool private _isSwappingLiquidity;
    modifier lockTheSwap {
        _isSwappingLiquidity = true;
        _;
        _liquidityHold = 0;
        _isSwappingLiquidity = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        // Uniswap Router Address: https://uniswap.org/docs/v2/smart-contracts/router02/
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        nextLotteryDate = block.timestamp + 1 days;
        _releaseTime = block.timestamp + 180 days;
    }

    // IERC20

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
        require(currentAllowance >= amount, "GULAG: transfer amount exceeds allowance");

        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
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

    // Liquidity

    function liquidityTokenAddress() public view returns (address) {
        return _liquidityTokenAddress;
    }

    function liquidityTokenBalance() public view returns (uint256) {
        return IUniswapV2ERC20(_liquidityTokenAddress).balanceOf(address(this));
    }

    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    function liquidityHold() public view returns (uint256) {
        return _liquidityHold;
    }

    // Lottery

    function lotteryJackpot() public view returns (uint256) {
        return _lotteryHold;
    }

    // External

    receive() external payable {}

    // Internal

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "GULAG: transfer from the zero address");
        require(recipient != address(0), "GULAG: transfer to the zero address");
        require(amount > 0, "GULAG: transfer amount must be greater than zero");

        bool isSellTransaction = recipient == address(_uniswapV2Pair);
        bool isBuyTransaction = sender == address(_uniswapV2Pair);
        uint256 finalAmount = amount;

        // Lottery
        if (block.timestamp >= nextLotteryDate && _lotteryEnabled && !_isRunningLottery) {
            _drawLotteryWinner();
        }

        // Auto liquidity
        if (isSellTransaction || isBuyTransaction) {
            uint256 threshold = _balanceLimit / 5;
            if (_liquidityHold > threshold && !_isSwappingLiquidity) {
                _swapAutoLiquidity();
            }

            uint256 liquidityTokens = _calculateFee(amount, _liquidityFeePercent);
            finalAmount -= liquidityTokens;
            _executeTransfer(sender, address(this), liquidityTokens);
        }

        if (isSellTransaction) {

            emit Sell();
            uint256 freeDate = _prisoners[sender] + 3 days;
            require(block.timestamp >= freeDate, "GULAG: transfer restricted from prisoners");

            uint256 lotteryTokens = _calculateFee(amount, _lotteryFeePercent);
            finalAmount -= lotteryTokens;

            _executeTransfer(sender, address(this), lotteryTokens);
            _sell(sender, recipient, finalAmount);
            _lotteryParticipants.remove(sender);

        } else if (isBuyTransaction) {

            emit Buy();
            uint256 currentBalance = _balances[recipient];
            uint256 tokensToBeBurnt = _calculateFee(amount, _burnFeePercent);
            finalAmount -= tokensToBeBurnt;
            require(currentBalance + finalAmount <= _balanceLimit, "GULAG: transfer restricted from whales. You can't buy more after holding 5%");

            // TODO: remove debug event
            if (currentBalance + finalAmount <= _balanceLimit) {
                emit BuyRestricted(recipient, amount);
            }
            
            _burn(recipient, tokensToBeBurnt);
            _executeTransfer(sender, recipient, finalAmount);

        } else {

            _executeTransfer(sender, recipient, finalAmount);
        }

        if (!isSellTransaction) {
            _prisoners[recipient] = block.timestamp;
            _lotteryParticipants.add(recipient);
        }        
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "GULAG: approve from the zero address");
        require(spender != address(0), "GULAG: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _executeTransfer(address sender, address recipient, uint256 amount) internal {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "GULAG: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _sell(address sender, address recipient, uint256 amount) internal {
        uint256 senderBalance = _balances[sender];
        uint256 dumpThreshold = _totalSupply * 4 / 100;
        if (senderBalance > dumpThreshold) {
            require(amount < senderBalance / 2, "GULAG: whales can sell only 50% of their balance at a time");

            // TODO: remove debug event
            if (amount >= senderBalance / 2) {
                emit SellRestricted(sender, amount);
            }
        }

        require(senderBalance >= amount, "GULAG: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "GULAG: burn from the zero address");
        _totalSupply -= amount;
        emit Burn(amount);
        emit Transfer(account, address(0), amount);
    }

    // Private

    function _drawLotteryWinner() private lockTheLottery returns (address, uint256) {
        require(_lotteryHold <= _balances[address(this)], "GULAG: transfer amount exceeds balance");
        require(_lotteryHold > 0, "GULAG: transfer amount must be greater than zero");

        uint256 randomIndex = _random(_lotteryParticipants.length());
        require(randomIndex < _lotteryParticipants.length(), "GULAG: winner index out of bounds");

        address winnerAddress = _lotteryParticipants.at(randomIndex);
        _lotteryParticipants.remove(winnerAddress);

        _executeTransfer(address(this), winnerAddress, _lotteryHold);
        nextLotteryDate = block.timestamp + 1 days;

        Winner memory lotteryWinner = Winner(winnerAddress, block.timestamp);
        lotteryWinners.push(lotteryWinner);

        emit LotteryWinner(lotteryWinner);
        return (winnerAddress, _lotteryHold);
    }

    function _swapAutoLiquidity() private lockTheSwap {
        require(_liquidityHold > 0, "GULAG: transfer amount must be greater than zero");

        uint256 half = _liquidityHold / 2;
        require(half <= _balances[address(this)], "GULAG: transfer amount exceeds balance");

        uint256 initialEthBalance = address(this).balance;
        _swapGulagForEth(half);
        uint256 newBalance = address(this).balance - initialEthBalance;
        require(newBalance > 0, "GULAG: transfer amount must be greater than zero");

        _addLiquidity(half, newBalance);
        emit SwapAutoLiquidity(half, newBalance);
    }

    function _swapGulagForEth(uint256 amount) private {
        _approve(address(this), address(uniswapV2Router), amount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function _calculateFee(uint256 amount, uint256 percent) private pure returns (uint256) {
        uint256 fee = amount * percent / 10**_feeDecimals;
        return fee;
    }

    function _random(uint256 limit) private view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % limit;
        return random;
    }

    // Maintenance - Lottery

    function toggleLotteryFeature(bool isEnabled) public onlyOwner {
        _lotteryEnabled = isEnabled;
    }

    function removeAddressFromLotteryParticipants(address account) public onlyOwner {
        _lotteryParticipants.remove(account);
    }

    function addAddressToLotteryParticipants(address account) public onlyOwner {
        _lotteryParticipants.add(account);
    }

    function runLottery() public onlyOwner {
        (address recipient, uint256 amount) = _drawLotteryWinner();
        _approve(address(this), recipient, amount);
    }

    // Maintenance - Liquidity

    function setUniswapV2Pair(address pair) public onlyOwner {
        _uniswapV2Pair = pair;
    }

    function setLiquidityTokenAddress(address liquidityTokenAddress_) public onlyOwner {
        _liquidityTokenAddress = liquidityTokenAddress_;
    }

    function swapGulagHoldToLiquidity() public onlyOwner {
        _swapAutoLiquidity();
    }

    function setReleaseTime(uint256 releaseTime_) public onlyOwner {
        require(releaseTime_ > _releaseTime, "GULAG: release time cannot be decreased");
        _releaseTime = releaseTime_;
    }

    function releaseLiquidityTokens() public onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime, "GULAG: current time is before release time");

        IUniswapV2ERC20 liquidityToken = IUniswapV2ERC20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        require(amount > 0, "GULAG: transfer amount must be greater than zero");

        liquidityToken.transfer(owner(), amount);
    }

    function transferAnyERC20TokenExceptLiquidityTokens(address tokenAddress, uint256 amount) public onlyOwner {
        require(amount > 0, "GULAG: transfer amount must be greater than zero");

        IERC20 token_ = IERC20(tokenAddress);
        require(tokenAddress != _liquidityTokenAddress, "GULAG: LiquidityToken withdraw is restricted");

        uint256 contractAmount = token_.balanceOf(address(this));
        require(contractAmount >= amount, "GULAG: transfer amount exceeds balance");
        token_.safeTransfer(owner(), amount);
    }
}