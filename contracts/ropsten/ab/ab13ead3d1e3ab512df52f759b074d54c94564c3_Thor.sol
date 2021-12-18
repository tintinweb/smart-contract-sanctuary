// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./NODERewardManagement.sol";
import "./PaymentSplitter.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IJoeFactory.sol";
import "./ERC20.sol";
import "./IJoeRouter02.sol";
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0, "toInt256Safe: B LESS THAN ZERO");
        return b;
    }
}

pragma solidity ^0.8.0;
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256),"mul: A B C combi values invalid with MIN_INT256");
        require((b == 0) || (c / b == a), "mul: A B C combi values invalid");
        return c;
    }


    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256, "div: b == 1 OR A == MIN_INT256");
        return a / b;
    }


    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a),"sub: A B C combi values invalid");
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a),"add: A B C combi values invalid");
        return c;
    }
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256, "abs: A EQUAL MIN INT256");
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0, "toUint256Safe: A LESS THAN ZERO");
        return uint256(a);
    }
}


pragma solidity ^0.8.0;

contract Thor is ERC20, Ownable, PaymentSplitter {
    using SafeMath for uint256;

    NODERewardManagement public nodeRewardManager;

    IJoeRouter02 public uniswapV2Router;

    address public uniswapV2Pair;
    address public futurUsePool;
    address public distributionPool;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public futurFee;
    uint256 public totalFees;

    uint256 public cashoutFee;

    uint256 public rwSwap;
    bool public swapping = false;
    bool public swapLiquify = true;
    uint256 public swapTokensAmount;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity
    );

    constructor(address[] memory payees, uint256[] memory shares, address[] memory addresses, uint256[] memory balances,
        uint256[] memory fees, uint256 swapAmount,address uniV2Router) ERC20("Versus", "$Versus") PaymentSplitter(payees, shares) {

        futurUsePool = addresses[4];
        distributionPool = addresses[5];

        require(futurUsePool != address(0) && distributionPool != address(0), "F&RAZ");

        require(uniV2Router != address(0), "RZ");
        IJoeRouter02 _uniswapV2Router = IJoeRouter02(uniV2Router);

        address _uniswapV2Pair = IJoeFactory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WAVAX());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        require(fees[0] != 0 && fees[1] != 0 && fees[2] != 0 && fees[3] != 0,"F0");
        futurFee = fees[0];
        rewardsFee = fees[1];
        liquidityPoolFee = fees[2];
        cashoutFee = fees[3];
        rwSwap = fees[4];

        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);

        require(addresses.length > 0 && balances.length > 0, "ALZ");
        require(addresses.length == balances.length, "ALU");

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], balances[i] * (10**18));
        }
        require(totalSupply() == 20456743e18, "TE20");
        require(swapAmount > 0, "SAI");
        swapTokensAmount = swapAmount * (10**18);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)public onlyOwner
    {
        require(pair != uniswapV2Pair,"PAA");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "AAS");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateFuturWall(address payable wall) external onlyOwner {
        futurUsePool = wall;
    }

    function updateRewardsWall(address payable wall) external onlyOwner {
        distributionPool = wall;
    }

    function updateRewardsFee(uint256 value) external onlyOwner {
        rewardsFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateLiquiditFee(uint256 value) external onlyOwner {
        liquidityPoolFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateFuturFee(uint256 value) external onlyOwner {
        futurFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateCashoutFee(uint256 value) external onlyOwner {
        cashoutFee = value;
    }

    function updateRwSwapFee(uint256 value) external onlyOwner {
        rwSwap = value;
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        payable(destination).transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WAVAX();
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,0, path, address(this),block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityAVAX{value: ethAmount}(
            address(this),tokenAmount, 0,0,address(0),block.timestamp
        );
    }

    function setNodeManagement(address nodeManagement) external onlyOwner {
        nodeRewardManager = NODERewardManagement(nodeManagement);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "RHA");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IJoeRouter02(newAddress);
        address _uniswapV2Pair = IJoeFactory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WAVAX());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function blacklistMalicious(address account, bool value)external onlyOwner
    {
        _isBlacklisted[account] = value;
    }


    function _transfer(address from, address to,uint256 amount) internal override {
        require(from != address(0), "TFZ");
        require(to != address(0), "TTZ");
        require(!_isBlacklisted[from] && !_isBlacklisted[to],"Blacklisted address");

        super._transfer(from, to, amount);
    }

    function createNodeWithTokens(string memory name) public {
        require(bytes(name).length > 3 && bytes(name).length < 32, "NSI");
        address sender = _msgSender();
        require(sender != address(0),"CFZ");
        require(!_isBlacklisted[sender], "BA");
        require(sender != futurUsePool && sender != distributionPool,"FRCCN");
        uint256 nodePrice = nodeRewardManager.nodePrice();
        require(balanceOf(sender) >= nodePrice,"BTL");
        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapAmountOk && swapLiquify &&!swapping &&sender != owner() &&!automatedMarketMakerPairs[sender]
        ) {
            swapping = true;
            uint256 futurTokens = contractTokenBalance.mul(futurFee).div(100);
            swapAndSendToFee(futurUsePool, futurTokens);
            uint256 rewardsPoolTokens = contractTokenBalance.mul(rewardsFee).div(100);
            uint256 rewardsTokenstoSwap = rewardsPoolTokens.mul(rwSwap).div(100);
            swapAndSendToFee(distributionPool, rewardsTokenstoSwap);
            super._transfer(address(this), distributionPool, rewardsPoolTokens.sub(rewardsTokenstoSwap));
            uint256 swapTokens = contractTokenBalance.mul(liquidityPoolFee).div(100);
            swapAndLiquify(swapTokens);
            swapTokensForEth(balanceOf(address(this)));
            swapping = false;
        }
        super._transfer(sender, address(this), nodePrice);
        nodeRewardManager.createNode(sender, name);
    }


}