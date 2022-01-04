pragma solidity >=0.8.0;

import "./MuzikToken.sol";
import "./IERC20.sol";
// Contract will calculate buy/sell price based on total supply

/*
All sales transactions via the treasury will levy a 10% burn. 
If someone wants to sell 100 tokens back to treasury, 90 of them will kept in circulation and 10 will be burned forever
*/
contract Treasury is Ownable {
    using SafeMath for uint256;
    // price ı total token ile belirlemeliyiz
    MuzikToken public token;
    IPangolinRouter public router;
    mapping(address => bool) public spendingTokens;
    IERC20 public stableCoin; // fiyat belirlemede kullanılacak ana stable coin

    uint256 public bondStart;
    uint256 public bondMax; // maximum price when all tokens sold. Bu miktar stable coin cinsinden olmalı.

    uint256 public currentTreasuryBalance = 0; // instead of using balanceof, it is much more safe.

    constructor(MuzikToken _token, IPangolinRouter _router, IERC20 _stableCoin) {
        token = _token;
        router = _router;
        stableCoin = _stableCoin;
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
            return currPrice.mul(spendingTokenPrice);
        }
    }

    function getSpendingTokenPrice(IERC20 _spendingToken) public view returns(uint256) {
        // buradan dönecek değer 1 tane spending tokenin DAI karşılığı
        require(address(_spendingToken) != address(0),"spending address zero.");
        address[] memory path = pathMaker(_spendingToken);
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

    function pathMaker(IERC20 _spendingToken) internal view returns(address[] memory) {
        address[] memory path;
        path = new address[](2);
        path[0] = address(stableCoin);
        path[1] = address(_spendingToken);
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
    function setSpendingToken(address _token, bool _value) public onlyOwner {
        spendingTokens[_token] = _value;
    }
}