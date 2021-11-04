// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "./IPancakeRouter02.sol";

contract PancakeHunter is Ownable {
    using SafeMath for uint256;

    IPancakeRouter02 public router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IBEP20 public wbnb = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IPancakeFactory public factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    uint256 public stop;
    uint256 public profit;
    uint256 public maxFeeBP = 1700; // al sat sonrası ödenecek max fee

    address public operator;

    address public profitFeeAddress;
    uint256 public profitFeeBP = 2500;

    uint256 public tokenSwapTestAmount = 10000000000000;
    uint256 public minLiquidity = 20 ether;
    uint256 public maxLiquidity = 75 ether;

    uint256 public minBuy = 0.3 ether;
    uint256 public maxBuy = 0.5 ether;

    uint256 public feeLowerLevelBP = 500; // fee bu miktardan düşükse farklı bi kar marjı.
    uint256 public feeLowerLevelMultiplier = 2;

    mapping(address => bool) public tokenList;
    mapping(address => Transaction) public transactions;

    enum TransactionStatus { INITIALIZED, WAITING, PROFIT, STOP }

    struct Transaction {
        uint256 paidWBNB;
        uint256 netTokenReceived;
        uint256 transferFee; // Base Point
        TransactionStatus status;
    }

    constructor(uint256 _stop, uint256 _profit, address fee, address op) {
        stop = _stop;
        profit = _profit;
        wbnb.approve(address(router), ~uint256(0));
        profitFeeAddress = fee;
        operator = op;
    }

    function addToken(IBEP20 token) public onlyOwner returns(uint256) {
        address tokenAddress = address(token);

        require(tokenAddress != address(0), "Token address cant be zero.");
        require(tokenList[tokenAddress] == false , "Token already added.");
        // testten sonra bakiye dene
        tokenList[tokenAddress] = true;
        //uint256 buyAmount = getTokenBuyAmount(token); // ayrıca likidite kontrolünüde yapıyor.
        (uint256 tokenReceived, uint256 bnbAmount) = swapWBNBForToken(token);

        emit TransactionInitialized(address(token), bnbAmount, tokenReceived);

        return tokenReceived;
    }

    function sellToken(IBEP20 token) public onlyOwner returns(bool) {
        require(address(token) != address(0), "Address cant be zero.");

        Transaction memory transaction = transactions[address(token)];

        uint256 received = sellTokenForWBNB(token);
        transaction.status = TransactionStatus.STOP;

        emit TransactionDone(address(token), TransactionStatus.STOP, transaction.paidWBNB, received);

        return true;
    }

    function isProfitOrLoss(IBEP20 token) public view returns(bool) {
        require(address(token) != address(0), "Token address zero.");
        require(tokenList[address(token)] == true , "Token is not added.");
        bool isProfit = isProfitable(token);
        if(isProfit) {
            return true;
        }
        bool isLoss = isStop(token);
        if(isLoss) {
            return true;
        }

        return false;
    }


    ////// INTERNAL FUNCTIONS

    function sellTokenForWBNB(IBEP20 token)  public onlyOwner returns(uint256) {
        address[] memory path = pathMaker(address(token),address(wbnb));
        Transaction memory transaction = transactions[address(token)];
        uint256 wbnbPaid = transaction.paidWBNB;

        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 beforeBNB = wbnb.balanceOf(address(this));
        uint256 deadline = deadlineCalculator();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenBalance, 0, path, address(this), deadline);

        uint256 afterBNB = wbnb.balanceOf(address(this));
        uint256 netBNBReceived = afterBNB.sub(beforeBNB);
        if(netBNBReceived > wbnbPaid) {
            // karlı işlem fee gönder
            uint256 netKaar = netBNBReceived.sub(wbnbPaid);
            uint256 kaarFee = netKaar.mul(profitFeeBP).div(10000);
            wbnb.transfer(profitFeeAddress, kaarFee);
        }

        emit TokenSold(address(token), tokenBalance, netBNBReceived);

        return netBNBReceived;
    }

    // alınan tokenin net miktarını döndürecek.
    function swapWBNBForToken(IBEP20 token)  public onlyOwner returns(uint256,uint256) {
        uint256 feeBP = netWBNBDiff(tokenSwapTestAmount, token); // burada wbnb harcadık.
        require(feeBP <= maxFeeBP, "This token has too much transfer fee");

        address[] memory path = pathMaker(address(wbnb),address(token));

        uint256 deadline = deadlineCalculator();
        uint256 tokenBalanceBefore = token.balanceOf(address(this)); // testten kalan küsürat token olabilir.
        uint256 amount = getTokenBuyAmount(token); // wbnb amount will we gonna buy tokens with.
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(this), deadline);

        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 netTokenBought = tokenBalance.sub(tokenBalanceBefore);

        emit TokenBought(address(token), amount, netTokenBought);

        Transaction storage transaction = transactions[address(token)];
        transaction.paidWBNB = amount;
        transaction.netTokenReceived = netTokenBought;
        transaction.transferFee = feeBP;

        return (netTokenBought, amount);
    }

    function netWBNBDiff(uint256 wbnbAmount, IBEP20 token) public onlyOwner returns(uint256) {
        uint256 balance = wbnb.balanceOf(address(this));

        require(wbnbAmount <= balance, "wbnbAmount is higher");

        address[] memory path = pathMaker(address(wbnb),address(token));
        address[] memory pathSale = pathMaker(address(token),address(wbnb));
        //uint256[] memory tokensOut = router.getAmountsOut(wbnbAmount, path);
        //uint256 tokenOut = tokensOut[1];

        uint256 deadline = deadlineCalculator();
        uint256 beforeBalance = token.balanceOf(address(this));

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(wbnbAmount, 0, path, address(this), deadline);
        token.approve(address(router), ~uint256(0));
        uint256 afterBalance = token.balanceOf(address(this));
        uint256 afterBuyWBNB = wbnb.balanceOf(address(this));
        uint256 netTokenBought = afterBalance.sub(beforeBalance);

        emit TokenBought(address(token), wbnbAmount, netTokenBought);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(afterBalance, 0, pathSale, address(this), deadline);

        uint256 afterSaleWBNBBalance = wbnb.balanceOf(address(this));
        uint256 netFeePaid = balance.sub(afterSaleWBNBBalance);
        uint256 saleDiffWBNB = afterSaleWBNBBalance.sub(afterBuyWBNB);

        emit TokenSold(address(token), afterBalance, saleDiffWBNB);

        if(netFeePaid > 0) {
            uint256 netLostBP = netFeePaid.mul(10000).div(wbnbAmount);
            emit TokenTransferFeeFound(address(token),netLostBP);
            return netLostBP;
        } else {
            emit TokenTransferFeeFound(address(token),0);
            return 0;
        }
    }

    function swapTokenForTest(uint256 wbnbAmount, IBEP20 token, uint256 deadline) public onlyOwner returns(uint256){
        uint256 balance = wbnb.balanceOf(address(this));

        require(wbnbAmount <= balance, "wbnbAmount is higher");

        address[] memory path = pathMaker(address(wbnb),address(token));
        address[] memory pathSale = pathMaker(address(token),address(wbnb));

        uint256 beforeBalance = token.balanceOf(address(this));

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(wbnbAmount, 0, path, address(this), deadline);
    }

    function proxySwap(uint256 wbnbamount, uint256 amountMin, address[] calldata path, uint256 deadline) public onlyOwner {
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(wbnbamount, amountMin, path, address(this), deadline);
    }

    function swapTwice(uint256 wbnbamount, uint256 amountMin, address[] calldata path, address[] calldata pathReverse, uint256 deadline, IBEP20 token) public onlyOwner {
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(wbnbamount, amountMin, path, address(this), deadline);
        uint256 afterBalance = token.balanceOf(address(this));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(afterBalance, amountMin, pathReverse, address(this), deadline);
    }

    function approveToken(IBEP20 token) public onlyOwner {
        token.approve(address(router),  ~uint256(0));
    }

    //testten sonra çalışacağı için tokenGape ihtiyacımız yok
    function getTokenBuyAmount(IBEP20 token) public view returns(uint256) {
        uint256 contractBalance = wbnb.balanceOf(address(this));
        require(address(token) != address(0), "Token address zero.");
        require(contractBalance >= minBuy, "Contract balance is not enough.");


        address pairAddress = factory.getPair(address(wbnb), address(token));
        require(pairAddress != address(0), "Token pair not found.");

        uint256 pairBNB = wbnb.balanceOf(pairAddress);
        require(pairBNB >= minLiquidity, "Token pair liquidity is low.");
        require(pairBNB <= maxLiquidity, "Token pair liquidity is too high.");

        if(contractBalance >= maxBuy) {
            return maxBuy;
        } else {
            return contractBalance;
        }
    }


    function pathMaker(address token1, address token2) public pure returns(address[] memory) {
        address[] memory path;
        path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        return path;
    }

    function deadlineCalculator() public view returns(uint256) {
        uint256 currTime = block.timestamp.add(2 hours);
        return currTime;
    }

    ////// OWNER FUNCTIONS
    function withdrawBalance() public onlyOwner {
        uint256 balance = wbnb.balanceOf(address(this));
        wbnb.transfer(msg.sender, balance);
        emit BalanceWithdrawal(msg.sender, balance);
    }

    function withdrawPartialBalance(uint256 amount) public onlyOwner {
        uint256 balance = wbnb.balanceOf(address(this));
        require(balance < amount, "Contract has not enough wbnb.");
        wbnb.transfer(msg.sender, amount);
    }

    function withdrawToken(IBEP20 token, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if(balance < amount) {
            token.transfer(msg.sender, balance);
        } else {
            token.transfer(msg.sender, amount);
        }
    }

    function setBuyValues(uint256 _min, uint256 _max) public onlyOwner {
        minBuy = _min;
        maxBuy = _max;

        emit BuyValuesChanged(minBuy,maxBuy);
    }

    function setTargetValues(uint256 _stop, uint256 _profit) public onlyOwner {
        stop = _stop;
        profit = _profit;
    }

    function setMaximumFee(uint256 fee) public onlyOwner {
        maxFeeBP = fee;

        emit MaximumFeeChanged(fee);
    }

    function setTestTokenAmount(uint256 amount) public onlyOwner {
        tokenSwapTestAmount = amount;

        emit TestAmountChanged(amount);
    }

    function setLiquidity(uint256 min, uint256 max) public onlyOwner {
        require(min < max , "Davar misin amk");
        minLiquidity = min;
        maxLiquidity = max;

        emit LiquidityValuesChanged(min,max);
    }

    function setProfitFee(uint256 newfee) public onlyOperator {
        require(newfee < 10000 , "New fee cant be 10000");

        profitFeeBP = newfee;

        emit ProfitFeeChanged(newfee);
    }

    function setProfitFeeAddress(address newAddress) public onlyOperator {
        require(newAddress != address(0), "new address zero");

        profitFeeAddress = newAddress;

        emit ProfitFeeAddressChanged(newAddress);

    }

    function setFeeLowerLevels(uint256 multiplier, uint256 lowerLevel) public onlyOwner {
        feeLowerLevelBP = lowerLevel; // fee bu miktardan düşükse farklı bi kar marjı.
        feeLowerLevelMultiplier = multiplier;
    }

    function setOperator(address newop) public onlyOperator {
        require(newop != address(0), "new op addres zero.");
        operator = newop;
    }

    ////// VIEW FUNCTIONS
    function isProfitable(IBEP20 token) public view returns(bool) {
        // wbnb çarparak bul
        Transaction memory transaction = transactions[address(token)]; // transaction

        uint256 netWBNBPaid = transaction.paidWBNB;

        uint256 newProfitBP = profit;
        if(transaction.transferFee <= feeLowerLevelBP) {
            newProfitBP = newProfitBP.mul(feeLowerLevelMultiplier);
        }

        uint256 feeDiff = netWBNBPaid.mul(transaction.transferFee).div(10000);
        uint256 targetDiff = netWBNBPaid.mul(newProfitBP).div(10000);

        uint256 wbnbTarget = netWBNBPaid.add(targetDiff).add(feeDiff);
        uint256 tokenBalance = token.balanceOf(address(this));

        address[] memory path = pathMaker(address(token), address(wbnb));
        uint256[] memory amountsOut = router.getAmountsOut(tokenBalance,path);

        uint256 maxBNBOut = amountsOut[1]; // pancakeswaptan gelebilecek max wbnb miktarı transfer fee falan düşülmüş değil bu miktarı targetle kıyaslayacağız.

        if(wbnbTarget >= maxBNBOut) {
            return false;
        } else {
            return true;
        }
    }

    function isStop(IBEP20 token) public view returns(bool) {
        Transaction memory transaction = transactions[address(token)];

        uint256 netWBNBPaid = transaction.paidWBNB;
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 feeDiff = netWBNBPaid.mul(transaction.transferFee).div(10000);
        uint256 stopDiff = netWBNBPaid.mul(stop).div(10000);
        uint256 totalDiff = feeDiff.add(stopDiff);
        if(totalDiff >= netWBNBPaid) {
            return true;
        }
        uint256 wbnbStop = netWBNBPaid.sub(totalDiff);

        address[] memory path = pathMaker(address(token), address(wbnb));
        uint256[] memory amountsOut = router.getAmountsOut(tokenBalance, path);

        uint256 maxBNBOut = amountsOut[1];

        if(maxBNBOut <= wbnbStop) {
            return true;
        } else {
            return false;
        }
    }
    
    function getContractBNB() public view returns(uint256) {
        uint256 balance = wbnb.balanceOf(address(this));
        return balance;
    }

    modifier newToken(address token) {
        require(tokenList[token] == false, "This token is handled before.");
        _;
    }

    modifier onlyOperator {
        require(msg.sender == operator, "only operator");
        _;
    }

    event BalanceWithdrawal(address indexed withdrawer, uint256 amount);
    event TokenBought(address indexed token, uint256 wbnbPaid, uint256 netTokenBought);
    event TokenSold(address indexed token, uint256 tokenPaid, uint256 netWbnbBought);
    event TransactionDone(address indexed token, TransactionStatus result, uint256 firstBNB, uint256 lastBNB);
    event TransactionInitialized(address indexed token, uint256 wbnbBought, uint256 tokenReceived);
    event BuyValuesChanged(uint256 minBuy, uint256 maxBuy);
    event MaximumFeeChanged(uint256 fee);
    event TestAmountChanged(uint256 amount);
    event TokenTransferFeeFound(address indexed token, uint256 feeBP);
    event LiquidityValuesChanged(uint256 min, uint256 max);
    event ProfitFeeChanged(uint256 newfee);
    event ProfitFeeAddressChanged(address indexed newAddress);
}