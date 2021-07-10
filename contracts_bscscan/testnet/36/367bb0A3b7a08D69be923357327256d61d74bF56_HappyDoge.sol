// SPDX-License-Identifier: Unlicensed
pragma solidity ^ 0.6.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";


contract HappyDoge is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private swapping;
    bool public canSwap = true;

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable private devWallet;
    address payable public marketingWallet;
    address USDT = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;

    uint256 public maxSellTransactionAmount = 5000 * 10 ** 9 * (10 ** 18);
    uint256 public swapTokensAtAmount = 1000 * 10 ** 9 * (10 ** 18);

    uint256 public buyFee = 10;
    uint256 public sellFee = 13;

    uint public tradingEnabledTimestamp = 100;
    uint private devDivisor = 10;
    uint public marketingDivisor = 4;
    uint256 public bigLottoAmount = 2 * 10 ** 17;
    uint256 public _minBuyUsdt = 1 * 10 ** 18;
    uint public numTokensSell = 50000 * 10 ** 18;
    uint public bigLottoPercent = 100;
    uint public bigLottoUsdt = 1 * 10 ** 18;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxSellTransactionAmount;
    mapping(address => bool) public canTradingBefore;
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _AddressExists;
    address[] private _addressList;
    address[] public _buyHistories;

    event CanSwapUpdated(bool enabled);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxSellTransactionAmount(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event TakeHappy(address user, uint ethReceived);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    event BigLotto(address winner, uint recived);

    constructor(address payable _marketingWallet, address payable _devWallet) public ERC20("HappyDoge", "HappyDoge") {
        devWallet = _devWallet;
        marketingWallet = _marketingWallet;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        excludeFromFees(address(_uniswapV2Router), true);
        excludeFromFees(devWallet, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(owner(), true);

        updateMaxSellTransactionAmount(owner(), true);
        updateMaxSellTransactionAmount(devWallet, true);
        updateMaxSellTransactionAmount(marketingWallet, true);
        updateMaxSellTransactionAmount(address(this), true);
        updateMaxSellTransactionAmount(address(_uniswapV2Router), true);

        addCanTradingBefore(owner(), true);
        addCanTradingBefore(devWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000 * 10 ** 9 * (10 ** 18));
    }

    receive() external payable {
    }

    function setBigLottoPercent(uint percent) public onlyOwner {
        require(percent > 0 && percent <= 100, "invalid big lotto percent");
        bigLottoPercent = percent;
    }

    function setBigLottoAmount(uint amount) public onlyOwner {
        bigLottoAmount = amount;
    }

    function setMinBuyUsdt(uint buyValue) public onlyOwner {
        _minBuyUsdt = buyValue;
    }

    function setBigLottoUsdt(uint value) public onlyOwner {
        bigLottoUsdt = value;
    }

    function setCanSwap(bool _enabled) public onlyOwner {
        canSwap = _enabled;
        emit CanSwapUpdated(_enabled);
    }

    function addCanTradingBefore(address user, bool enabled) public onlyOwner {
        require(canTradingBefore[user] != enabled, "canTradingBefore user is already set 'enabled'");
        canTradingBefore[user] = enabled;
    }

    function updateMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        maxSellTransactionAmount = totalSupply().mul(maxTxPercent).div(
            10 ** 2
        );
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function SweepTokens() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        super.transfer(owner(), balance);
    }

    function setMarketingDivisor(uint256 divisor) external onlyOwner {
        marketingDivisor = divisor;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingWallet = payable(_marketingAddress);
    }

    function setDevDivisor(uint256 divisor) external onlyOwner {
        devDivisor = divisor;
    }

    function setDevAddress(address _marketingAddress) external onlyOwner {
        devWallet = payable(_marketingAddress);
    }

    function setUsdtAddress(address _usdt) external onlyOwner {
        USDT = _usdt;
    }

    function updateMaxSellTransactionAmount(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxSellTransactionAmount[updAds] = isEx;
        emit ExcludedMaxSellTransactionAmount(updAds, isEx);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), " The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, " Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setSellFee(uint256 _sellFee) public onlyOwner {
        sellFee = _sellFee;
    }

    function setBuyFee(uint256 _buyFee) public onlyOwner {
        buyFee = _buyFee;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    function canJoin(uint256 amount, uint usdtValue) public view returns (bool can){
        can = false;
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = USDT;
        uint[] memory amounts = uniswapV2Router.getAmountsOut(amount, path);
        if (amounts.length > 0) {
            can = amounts[amounts.length - 1] >= usdtValue;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool tradingIsEnabled = getTradingIsEnabled();

        //time lock
        if (!tradingIsEnabled) {
            require(canTradingBefore[from] || canTradingBefore[to], "This account cannot send tokens until trading is enabled");
        }

        //any action
        if (!swapping && !(from == address(uniswapV2Router) || to == address(uniswapV2Router))) {
            if (!_isExcludedMaxSellTransactionAmount[from] && !_isExcludedMaxSellTransactionAmount[to]) {
                require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            }
        }

        addAddress(from);
        addAddress(to);

        //add buy info
        if (automatedMarketMakerPairs[from] && to != address(uniswapV2Router) && canJoin(amount, _minBuyUsdt)) {
            _buyHistories.push(to);
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSell;
        if (
            canSwap &&
            !swapping &&
            overMinTokenBalance &&
            automatedMarketMakerPairs[to]
        ) {
            swapping = true;
            swapTokens(contractTokenBalance);
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            //sell
            if (automatedMarketMakerPairs[to]) {
                swapping = true;
                uint256 fees = amount.mul(sellFee).div(100);
                amount = amount.sub(fees);
                super._transfer(from, address(this), fees);
                //draw lotto
                _takeHappy(fees);
                swapping = false;
            }
            //buy
            if (automatedMarketMakerPairs[from]) {
                uint256 fees = amount.mul(buyFee).div(100);
                amount = amount.sub(fees);
                super._transfer(from, address(this), fees);
            }
        }
        super._transfer(from, to, amount);

        if (!swapping) settleBigLotto();
    }

    function settleBigLotto() private {
        uint balance = address(this).balance;
        if (balance >= bigLottoAmount) {
            uint randomNumber = random().mod(_addressList.length);
            address winner = _addressList[randomNumber];
            if (!canJoin(balanceOf(winner), bigLottoUsdt)) {
                winner = devWallet;
            }
            balance = balance.mul(bigLottoPercent).div(100);
            transferToAddressETH(payable(winner), balance);
            emit BigLotto(winner, balance);
        }
    }

    function swapTokens(uint256 contractTokenBalance) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        // Send to Marketing address
        transferToAddressETH(marketingWallet, transferredBalance.mul(marketingDivisor).div(100));
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        uint256 initialBalance = address(this).balance;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        uint256 newBalance = address(this).balance.sub(initialBalance);
        transferToAddressETH(devWallet, newBalance.mul(devDivisor).div(100));
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number)));
    }

    function _takeHappy(uint256 happyFees) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(happyFees);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        address winner;
        if (_buyHistories.length > 0) {
            uint randomNumber = random().mod(_buyHistories.length);
            winner = _buyHistories[randomNumber];
        } else {
            winner = devWallet;
        }
        delete _buyHistories;
        transferToAddressETH(payable(winner), newBalance);
        emit TakeHappy(winner, newBalance);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function addAddress(address adr) private {
        if (adr.isContract() ||
        adr == uniswapV2Pair ||
        adr == address(uniswapV2Router) ||
        adr == address(this) ||
        adr == deadAddress ||
            adr == address(0)
        ) return;
        if (_AddressExists[adr])
            return;
        _AddressExists[adr] = true;
        _addressList.push(adr);
    }
}