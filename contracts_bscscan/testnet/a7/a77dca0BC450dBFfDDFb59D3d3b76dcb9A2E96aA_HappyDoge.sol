// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.2;

import './Context.sol';
import './IERC20.sol';
import './Ownable.sol';
import './SafeMath.sol';
import './Address.sol';
import './ERC20.sol';
import './IUniswapV2Router.sol';
import './IUniswapV2Factory.sol';

//[email protected]
contract HappyDoge is ERC20, Ownable {
    using SafeMath for uint256;

    bool private swapping;

    address public liquidityWallet;
    address payable public marketingWallet;
    address public WETH;
    address payable private devWallet;
    address public usdt;

    uint256 public maxSellTransactionAmount = 1000000 * (10 ** 18);
    uint256 public swapTokensAtAmount = 200000 * (10 ** 18);
    uint256 public minBuyValue = 6000000000000000000;

    uint256 public happyFee;
    uint256 public BNBRewardsFee;
    uint256 public liquidityFee;
    uint256 public totalFees;
    uint256 private marketingDivisor = 4;
    uint256 private devDivisor = 6;

    uint256 public immutable tradingEnabledTimestamp = 1623967200; //June 17, 22:00 UTC, 2021

    struct BuyHistory {
        address user;
        uint256 time;
    }

    BuyHistory[] public _buyHistories;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private canTransferBeforeTradingIsEnabled;

    mapping(address => bool) public fixedSaleEarlyParticipants;

    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public automatedMarketMakers;
    mapping(address => address) public amm;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    constructor(address payable _devWallet, address _router,address _usdt) public ERC20("HAPPY DOGE", "HAPPY DOGE") {

        uint256 _happyFee = 10;
        uint256 _BNBRewardsFee = 10;
        uint256  _liquidityFee = 2;

        devWallet = _devWallet;
        usdt = _usdt;

        happyFee = _happyFee;
        BNBRewardsFee = _BNBRewardsFee;
        liquidityFee = _liquidityFee;
        totalFees = _happyFee.add(_BNBRewardsFee).add(_liquidityFee);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        address _WETH = _uniswapV2Router.WETH();
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _WETH);

        WETH = _WETH;
        setAmmAndPair(_router, _uniswapV2Pair);

        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);

        addCanTransferBeforeTradingIsEnabled(owner(),true);
        addCanTransferBeforeTradingIsEnabled(devWallet,true);

        _mint(owner(), 1000000000 * (10 ** 18));
    }

    receive() external payable {

    }

    function addCanTransferBeforeTradingIsEnabled(address account, bool enabled) public onlyOwner {
        require(canTransferBeforeTradingIsEnabled[account] != enabled, "Account is already the value of 'enabled'");
        canTransferBeforeTradingIsEnabled[account] = enabled;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAmmAndPair(address router, address pair) public onlyOwner {
        require(automatedMarketMakerPairs[pair] != true, "Automated market maker pair is already exist");
        require(automatedMarketMakers[router] != true, "Automated market maker is already exist");
        automatedMarketMakerPairs[pair] = true;
        automatedMarketMakers[router] = true;
        amm[pair] = router;
        amm[router] = pair;
    }

    function updateMarketingWallet( address payable newMarketingWallet) public onlyOwner {
        require(newMarketingWallet != marketingWallet, "The marketing wallet is already this address");
        excludeFromFees(marketingWallet, true);
        marketingWallet = newMarketingWallet;
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBuy(address from, address to) private view returns (bool){
        return automatedMarketMakerPairs[from] && !automatedMarketMakers[to];
    }

    function isSell(address to) private view returns (bool){
        return automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[_msgSender()];
    }

    function getBuyValue(address _router, uint256 amount) public view returns (uint value){
        value = 0;
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = WETH;
        path[2] = usdt;
        uint[] memory amounts = IUniswapV2Router02(_router).getAmountsOut(amount, path);
        if (amounts.length > 0) {
            value = amounts[amounts.length - 1];
        }
    }

    event Log(address from,address to,string  c);

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        bool tradingIsEnabled = getTradingIsEnabled();

        if (!tradingIsEnabled) {
            require(canTransferBeforeTradingIsEnabled[from] || canTransferBeforeTradingIsEnabled[to], "This account cannot send tokens until trading is enabled");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // bool isSale = isSell(to);

        // if (
        //     !swapping &&
        // tradingIsEnabled &&
        // isSale &&
        // !_isExcludedFromFees[from] //no max for those excluded from fees
        // ) {
        //     require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        // }
        bool _isBuy = isBuy(from,to);
        bool _isSell = isSell(to);

        emit Log(from,to,_isBuy ? 'isBuy':'');

        emit Log(from,to,_isSell ? 'sell':'');


        // if (!swapping && isBuy(from, to) && getBuyValue(amm[from], amount) >= minBuyValue) {
        //     //add buy history
        //     _buyHistories.push(BuyHistory(to, block.timestamp));
        // }

        // bool takeFee = tradingIsEnabled && !swapping && isSale;

        // if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
        //     takeFee = false;
        // }

        // if (takeFee) {
        //     uint256 fees = amount.mul(totalFees).div(100);
        //     amount = amount.sub(fees);
        //     super._transfer(from, address(this), fees);
        //     //lotto
        //     uint happyFees = fees.mul(happyFee.div(totalFees));
        //     swapTokensAndTakeHappy(happyFees);
        // }

        super._transfer(from, to, amount);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number)));
    }

    function swapTokensAndTakeHappy(uint256 contractTokenBalance) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        uint marketingFees = transferredBalance.mul(marketingDivisor).div(100);
        uint devFees = transferredBalance.mul(marketingDivisor).div(100);
        // Send to Marketing address
        transferToAddressETH(marketingWallet, marketingFees);
        transferToAddressETH(devWallet, devFees);
        transferredBalance = transferredBalance.sub(marketingFees).sub(devFees);

        //take happy
        uint256 randomNumber = random().mod(_buyHistories.length);
        BuyHistory memory buyHistory = _buyHistories[randomNumber];
        payable(buyHistory.user).transfer(transferredBalance);
        removeBuyHistory(randomNumber);
    }

    function removeBuyHistory(uint index) private {
        if (index >= _buyHistories.length) return;

        for (uint i = index; i < _buyHistories.length - 1; i++) {
            _buyHistories[i] = _buyHistories[i + 1];
        }
        _buyHistories.pop();
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        _approve(address(this), address(_msgSender()), tokenAmount);

        // make the swap
        IUniswapV2Router02(_msgSender()).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
}