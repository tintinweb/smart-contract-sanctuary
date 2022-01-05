pragma solidity >=0.8.0;

import "./MuzikToken.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
// Contract will calculate buy/sell price based on total supply

/*
All sales transactions via the treasury will levy a 10% burn. 
If someone wants to sell 100 tokens back to treasury, 90 of them will kept in circulation and 10 will be burned forever
*/
contract Treasury is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    // price ı total token ile belirlemeliyiz
    MuzikToken public token;
    IPangolinRouter public router;
    mapping(address => bool) public spendingTokens;
    IERC20 public stableCoin; // fiyat belirlemede kullanılacak ana stable coin

    uint256 public currentTreasuryBalance = 0; // instead of using balanceof, it is much more safe.

    uint256 public tokenSoldAmount = 0; // dinamik token satış miktarı, fiyat hesaplamasında kullanılacak.
    uint256 public maxTokenAmount = 500_000_000 ether;

    uint256 public minAVAX = 0.001 ether; // min avax must be paid in order to buy tokens via native token.

    event BoughtWithERC20(address indexed buyyer, uint256 amount, IERC20 token, uint256 paidAmount);
    event ERC20Swap(IERC20 tokenSold, IERC20 tokenBought, uint256 paidAmount, uint256 received);
    event NativeSwap(uint256 paidAmount, IERC20 tokenBought, uint256 received);
    event BoughtWithNative(address indexed buyyer, uint256 paidAVAX, uint256 amount);

    event Console(string str, uint256 a1, uint256 a2, uint256 a3, uint256 a4, uint256 a5); // test için kullanılan event sonradan kaldırılmalı

    constructor(MuzikToken _token, IPangolinRouter _router, IERC20 _stableCoin) {
        token = _token;
        router = _router;
        stableCoin = _stableCoin;
        spendingTokens[address(_stableCoin)] = true;
    }

    // User Interactions

    // min-max buy limitleri eklenecek.
    function buyERC20(IERC20 _spendingToken, uint256 _amount) public { // ERC20 fallback çalışmadığı için reentrancy guard eklemeyeceğiz.
        // alırken her hangi bir fee yok. Sadece exclude edilmez ise transfer fee olacak.
        require(address(_spendingToken) != address(0), "spending token zero");
        require(tokenSoldAmount.add(_amount) <= maxTokenAmount, "Max tokens reached.");
        require(spendingTokens[address(_spendingToken)] == true, "spending token not allowed");
        require(_amount <= token.balanceOf(address(this)),"Token amount exceeds contract balance");

        uint256 avgPrice = getPriceFromCalculation(tokenSoldAmount, tokenSoldAmount.add(_amount)); // how much dai must user pay for get 1 MUZIK
        emit Console("avgPrice",avgPrice,0,0,0,0);

        uint256 spendingPrice = getDAIPerToken(_spendingToken); // 1 DAI = ?? spending Token -- testnet results : 1 DAI = 34,1094 AVAX
        emit Console("spendingPrice",spendingPrice,0,0,0,0);

        uint256 cost = avgPrice.mul(_amount).div(1 ether); // total amount of DAI user has to pay.
        emit Console("cost",cost,0,0,0,0);

        uint256 costToken = spendingPrice.mul(cost).div(1 ether);
        emit Console("costToken",costToken,0,0,0,0);

        _spendingToken.transferFrom(msg.sender, address(this), costToken); // lets get user tokens

        tokenSoldAmount = tokenSoldAmount.add(_amount);

        token.transfer(msg.sender, _amount); // send muziks to user.

        emit BoughtWithERC20(msg.sender, _amount, _spendingToken, costToken);

        if(_spendingToken != stableCoin) { // swapda gelen miktar eksik oluyor.
            // şimdi aldığımız erc20 tokeni DAI formatında swaplayacağız.
            address[] memory buyPath = pathMaker(_spendingToken, stableCoin);
            uint256 stableBalanceBefore = stableCoin.balanceOf(address(this));
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(costToken, 0, buyPath, address(this), block.timestamp); // tüm spending tokenlerı DAI'ye swaplayalım, slippage sınırsız kabul ettik.
            uint256 stableBalanceAfter = stableCoin.balanceOf(address(this));
            uint256 netAmountReceived = stableBalanceAfter.sub(stableBalanceBefore);
            // değişimde gelen miktar biraz az.
            emit ERC20Swap(_spendingToken, stableCoin, costToken, netAmountReceived);
        }

    }

    function buyWithAVAX(uint256 _amount) public payable {
        // kullanıcı avax ile ödeme yapacağı için burada girdiği amount değeri ödediğine oranla eşit veya daha düşük olmalı. Hatta gerekirse slippage eklenebilir.
        require(msg.sender != address(0),"sender address zero");
        require(_amount >= 0, "min amount");
        uint256 userPaidAmount = msg.value;
        require(userPaidAmount >= minAVAX, "value too low");
        address WAVAX = router.WAVAX();
        // öncelikle aldığımız avaxları swaplayalım ve ne kadar dai aldığımıza bakalım
        uint256 stableBefore = stableCoin.balanceOf(address(this));

        address[] memory sellPath = pathMaker(IERC20(WAVAX), stableCoin);

        router.swapExactAVAXForTokens{value : userPaidAmount}(0, sellPath, address(this), block.timestamp);

        uint256 stableAfter = stableCoin.balanceOf(address(this));
        uint256 netAmount = stableAfter.sub(stableBefore); // amount of DAI we got from swap

        emit NativeSwap(userPaidAmount,stableCoin,netAmount);

        // şimdi aldığımız dai miktarına göre kullanıcıya muzik token verelim.
        uint256 avgPrice = getPriceFromCalculation(tokenSoldAmount, tokenSoldAmount.add(_amount));
        emit Console("avgPrice",avgPrice,0,0,0,0);

        uint256 cost = avgPrice.mul(_amount).div(1 ether); // cost of DAI needed
        emit Console("cost-netamount",avgPrice,netAmount,0,0,0);

        require(cost <= netAmount, "Not enough AVAX paid.");

        token.transfer(msg.sender, _amount); // send tokens to user.
    
        emit BoughtWithNative(msg.sender,msg.value, _amount);

    }

    // View Functions

    function getCurrentPrice(IERC20 _spendingToken) public view returns(uint256) {
        // returns current price with amount of spending token required spend to own 1 MUZIK token
        require(address(_spendingToken) != address(0), "Spending token address zero.");
        require(spendingTokens[address(_spendingToken)] == true, "Spending token not allowed.");
        uint256 currPrice = getPriceFromCalculation(currentTreasuryBalance, currentTreasuryBalance.add(1 ether));
        if(address(_spendingToken) == address(stableCoin)) {
            // zaten dai seçilmiş fiyat hesaplaması normal olacak.
            return currPrice;
        } else {
            // gönderilen tokenin dai cinsinden fiyatı bulunmalı.
            uint256 spendingTokenPrice = getSpendingTokenPrice(_spendingToken); // 1 dai için kaç token gönderilmeli.

            return currPrice.mul(1 ether).div(spendingTokenPrice);
        }
    }

    function getSpendingTokenPrice(IERC20 _spendingToken) public view returns(uint256) {
        // buradan dönecek değer 1 tane spending tokenin DAI karşılığı
        require(address(_spendingToken) != address(0),"spending address zero."); // type check zaten parametrede yapıldı. gas optimizasyonu yaparken bu requirelar kaldırılacak.
        if(address(_spendingToken) == address(stableCoin)) {
            return 1 ether; // eğer stable coin gönderildi ise zaten hesaplama yapmaya gerek yok 1:1 oranı olacaktır.
        }
        address[] memory path = pathMaker(_spendingToken, stableCoin);
        uint256[] memory amounts = router.getAmountsOut(1 ether, path);
        return amounts[1];
    }

    function getDAIPerToken(IERC20 _spendingToken) public view returns(uint256) {
        if(address(_spendingToken) == address(stableCoin)) {
            return 1 ether;
        }
        address[] memory path = pathMaker(stableCoin, _spendingToken);
        uint256[] memory amounts = router.getAmountsOut(1 ether, path);
        return amounts[1];
    }

    function sigmoidCalculation(uint256 x) public pure returns(uint256) {
        int256 a = 5 ether;
        int256 b = 250000000 ether;
        int256 c = 5325000000000000 ether;
        int256 upper = int256(x) - b;
        
        int256 innerSqrt = c + ((upper * upper) / 1 ether);

        int256 denominator = int256(sqrt(uint256(innerSqrt * 1 ether)));
        
        int256 calc1 = (upper * 1 ether) / (denominator);
        int256 calc2 = calc1 + 1 ether;
        return uint256(a * calc2) / 1 ether; 
    }

    function getPriceFromCalculation(uint256 start, uint256 end) public pure returns(uint256) {
        uint256 startPrice = sigmoidCalculation(start);
        uint256 endPrice = sigmoidCalculation(end);

        return (endPrice + startPrice) / 2;
    }

    function pathMaker(IERC20 _f, IERC20 _s) internal pure returns(address[] memory) {
        address[] memory path;
        path = new address[](2);
        path[0] = address(_f);
        path[1] = address(_s);
        return path;
    }


    // Admin Functions
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function setSpendingToken(IERC20 _token, bool _value) public onlyOwner {
        spendingTokens[address(_token)] = _value;
        _token.approve(address(router), ~uint256(0));

    }
}