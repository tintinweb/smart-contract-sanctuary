/**
 *Submitted for verification at Etherscan.io on 2020-07-07
*/

pragma solidity ^0.6.4;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract BondingCurve is DSMath {
    uint256 public currentSupply;
    mapping (address => uint256) public ledger;

    uint256 public exponent;
    uint256 public coefficient;
    uint256 public reserveRatio;
    uint256 public exitVar;
    
    uint256 public constant precision = 1000000000000000000;

    event NewPrice(uint256 buy, uint256 sell);

    string internal constant INSUFFICIENT_ETH = 'Insufficient Ether';
    string internal constant INSUFFICIENT_TOKENS = 'Request exceeds token balance';
    string internal constant INVALID_ADDRESS = 'Wallet does not exist';
    string internal constant ZERO_AMOUNT = "Amount must be nonzero";
    string internal constant TOKENS_LOCKED = "Vesting period for this stake has not elapsed";

    constructor()
    public {
        exponent = 2;
        coefficient = 100000000;
        reserveRatio = 1;
        currentSupply = 1;
        exitVar = 1;

        emit NewPrice(calcMintPrice(1), calcBurnReward(1));
    }

    function buyPriceInWei(uint256 amount)
    public returns (uint256) {
        uint256 price = calcMintPrice(amount);
        return price;
    }
    
    function buy(uint256 amount)
    external payable {
        uint256 price = calcMintPrice(amount);
        require(msg.value >= price, INSUFFICIENT_ETH);
        uint256 refund = msg.value - price;
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
        ledger[msg.sender] = add(ledger[msg.sender], amount);
        currentSupply = add(currentSupply, amount);
        uint256 newBuyPrice = calcMintPrice(1);
        uint256 newSellPrice = calcBurnReward(1);
        emit NewPrice(newBuyPrice, newSellPrice);
    }

    function sell(uint256 amount)
    external {
        require(amount <= ledger[msg.sender], INSUFFICIENT_TOKENS);
        uint256 exitValue = calcBurnReward(amount);
        msg.sender.transfer(exitValue);
        exitVar = exitValue;
        ledger[msg.sender] = sub(ledger[msg.sender], amount);
        currentSupply = sub(currentSupply, amount);
    }


    function integrate(uint256 limitA, uint256 limitB, uint256 multiplier)
    internal returns (uint256) {
        uint256 raiseExp = exponent + 1;
        uint256 _coefficient = wmul(coefficient, multiplier);
        uint256 upper = wdiv((limitB ** raiseExp), raiseExp);
        uint256 lower = wdiv((limitA ** raiseExp), raiseExp);
        return wmul(_coefficient, (sub(upper, lower)));
    }
    
    function calcMintPrice(uint256 amount)
    internal returns (uint256) {
        uint256 newSupply = add(currentSupply, amount);
        uint256 result = integrate(currentSupply, newSupply, precision);
        return result;
    }

    function calcBurnReward(uint256 amount)
    internal returns (uint256) {
        uint256 newSupply = sub(currentSupply, amount);
        uint256 result = integrate(newSupply, currentSupply, precision);
        return result;
    }

}