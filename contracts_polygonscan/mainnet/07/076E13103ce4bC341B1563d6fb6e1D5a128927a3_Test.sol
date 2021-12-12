//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PolygonArbitrageBot.sol";
import "./Library.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Test is Ownable, PolygonArbitrageBot {



    constructor()
    {
        transferOwnership(msg.sender);
    }


    function getBalanceWMATIC() view external returns(uint256)
    {
        return PolygonTokens.getBalance(kPolygonToken.wmatic);
    }

    function getBalanceUSDC() view external returns(uint256)
    {
        return PolygonTokens.getBalance(kPolygonToken.usdc);
    }

    function getBalancePBREW() view external returns(uint256)
    {
        return PolygonTokens.getBalance(kPolygonToken.pbrew);
    }

    function getBalanceELON() view external returns(uint256)
    {
        return PolygonTokens.getBalance(kPolygonToken.elon);
    }

    function smashIt(uint256 _amount) external
    {
        _polygonArbitrageBotSmashIt(_amount);
        // bool success = _polygonArbitrageBotPerformSwapIfValuable(kPolygonToken.wmatic, kPolygonToken.pbrew, _amount);

        // if (success == false)
        // {
        //     revert("No arbitrage trade could be made");
        // }
    
    }

    function getBestOption(uint256 _amount) view external returns(PolygonArbitrageOptionABICompatible memory)
    {
        PolygonArbitrageOption memory option = _polygonArbitrageBotGetBestOption(_amount);

        return _polygonArbitrageBotConvertOptionToABICompatible(option);
    }






    function renounceOwnership() override public pure
    {

    }

    function withdraw() external onlyOwner
    {
        payable(owner()).transfer(address(this).balance);
    }

    function transferTokens(address _tokenAddress) external onlyOwner
    {
        // Used for "rescue" tokens
        IERC20(_tokenAddress).transfer(owner(), IERC20(_tokenAddress).balanceOf(address(this)));
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PolygonTradingHub.sol";
import "./Library.sol";

contract PolygonArbitrageBot is PolygonTradingHub {


    struct PolygonAbitrageIntent {
        kPolygonToken tokenA;
        kPolygonToken tokenB;
    }

    struct PolygonArbitrageOption {
        PolygonTradeForecast min;
        PolygonTradeForecast max;
        uint256 tokenAmountDifference;
        uint256 tokenAmountDifferencePercentage1000;
        bool isValid;
    }

    struct PolygonArbitrageOptionABICompatible {
        PolygonTradeForecastABICompatible min;
        PolygonTradeForecastABICompatible max;
        string tokenAmountDifference;
        string tokenAmountDifferencePercentage1000;
        string isValid;
    }

    uint256 constant minPercentage1000ForTrade = 100;

    mapping(uint256 => PolygonAbitrageIntent) abitrageIntents;
    uint256 constant abitrageIntentsLength = 8;

    constructor()
    {
        abitrageIntents[0].tokenA = kPolygonToken.wmatic;
        abitrageIntents[0].tokenB = kPolygonToken.pbrew;

        abitrageIntents[1].tokenA = kPolygonToken.wmatic;
        abitrageIntents[1].tokenB = kPolygonToken.usdc;

        abitrageIntents[2].tokenA = kPolygonToken.wmatic;
        abitrageIntents[2].tokenB = kPolygonToken.elon;

        abitrageIntents[3].tokenA = kPolygonToken.wmatic;
        abitrageIntents[3].tokenB = kPolygonToken.qidao;

        abitrageIntents[4].tokenA = kPolygonToken.wmatic;
        abitrageIntents[4].tokenB = kPolygonToken.pnt;

        abitrageIntents[5].tokenA = kPolygonToken.wmatic;
        abitrageIntents[5].tokenB = kPolygonToken.klima;

        abitrageIntents[6].tokenA = kPolygonToken.wmatic;
        abitrageIntents[6].tokenB = kPolygonToken.hbar;

        abitrageIntents[7].tokenA = kPolygonToken.wmatic;
        abitrageIntents[7].tokenB = kPolygonToken.clam2;

    }

    function _polygonArbitrageBotConvertOptionToABICompatible(PolygonArbitrageOption memory _option) internal pure returns(PolygonArbitrageOptionABICompatible memory)
    {
        PolygonArbitrageOptionABICompatible memory option;

        option.min = _polygonTradingHubConvertForecastToABICompatible(_option.min);
        option.max = _polygonTradingHubConvertForecastToABICompatible(_option.max);
        option.tokenAmountDifference = _uintToString(_option.tokenAmountDifference);
        option.tokenAmountDifferencePercentage1000 = _uintToString(_option.tokenAmountDifferencePercentage1000);
        option.isValid = _option.isValid ? "valid" : "invalid";

        return option;
    }

    function _polygonArbitrageBotGetBestOption(uint256 _amount) internal view returns(PolygonArbitrageOption memory)
    {
        PolygonArbitrageOption memory bestOption;

        for (uint256 i = 0; i < abitrageIntentsLength; i++)
        {
            PolygonAbitrageIntent memory fiIntent = abitrageIntents[i];

            PolygonArbitrageOption memory fiOption = _polygonArbitrageBotFindOption(fiIntent.tokenA, fiIntent.tokenB, _amount);

            if (fiOption.isValid && fiOption.tokenAmountDifferencePercentage1000 > bestOption.tokenAmountDifferencePercentage1000)
            {
                bestOption = fiOption;
            }
        }

        return bestOption;
    }

    function _polygonArbitrageBotSmashIt(uint256 _amount) internal returns(bool)
    {
        PolygonArbitrageOption memory bestOption = _polygonArbitrageBotGetBestOption(_amount);

        return _polygonArbitrageBotPerformSwapIfValuable(bestOption, _amount);
    }


    function _polygonArbitrageBotPerformSwapIfValuable(PolygonArbitrageOption memory _option, uint256 _amount) internal returns(bool)
    {
        if (_option.isValid == false)
        {
            return false;
        }

        if (_option.tokenAmountDifferencePercentage1000 < minPercentage1000ForTrade)
        {
            return false;
        }

        uint256 initialBalanceA = PolygonTokens.getBalance(_option.max.tokenIn);
        uint256 initialBalanceB = PolygonTokens.getBalance(_option.max.tokenOut);

        _polygonTradingHubSwapToken(_option.max.exchange, _option.max.tokenIn, _option.max.tokenOut, _amount);

        uint256 newBalanceB = PolygonTokens.getBalance(_option.max.tokenOut);

        _polygonTradingHubSwapToken(_option.min.exchange, _option.max.tokenOut, _option.max.tokenIn, newBalanceB - initialBalanceB);

        uint256 newBalanceA = PolygonTokens.getBalance(_option.max.tokenIn);

        if (newBalanceA < initialBalanceA)
        {
            revert("Arbitrage trade was unsuccessful.");
        }
        
        return true;
    }

    function _polygonArbitrageBotFindOption(kPolygonToken _tokenA, kPolygonToken _tokenB, uint256 _amount) internal view returns(PolygonArbitrageOption memory)
    {
        PolygonTradeForecast[] memory forecasts = _polygonTradingHubGetAllForcasts(_tokenA, _tokenB, _amount);
        PolygonArbitrageOption memory option;

        for (uint256 i = 0; i < forecasts.length; i++)
        {
            PolygonTradeForecast memory fiForecast = forecasts[i];

            if (fiForecast.tokenOutAmount != 0)
            {
                option.min = fiForecast;
                option.max = fiForecast;
                break;
            }
        }

        for (uint256 i = 0; i < forecasts.length; i++)
        {
            PolygonTradeForecast memory fiForecast = forecasts[i];

            if (fiForecast.tokenOutAmount != 0)
            {
                if (fiForecast.tokenOutAmount > option.max.tokenOutAmount)
                {
                    option.max = fiForecast;
                }
                else if (fiForecast.tokenOutAmount < option.min.tokenOutAmount)
                {
                    option.min = fiForecast;
                }
            }
        }

        option.tokenAmountDifference = 0;
        option.tokenAmountDifferencePercentage1000 = 0;

        if (option.min.tokenOutAmount != 0 && option.min.tokenOutAmount != option.max.tokenOutAmount)
        {
            option.isValid = true;
            option.tokenAmountDifference = option.max.tokenOutAmount - option.min.tokenOutAmount;
            option.tokenAmountDifferencePercentage1000 = (option.tokenAmountDifference * 1000 * 100) / option.min.tokenOutAmount;
        }

        return option;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

uint256 constant MAX_INT = type(uint256).max;

enum kNetwork
{
    polygon
}

struct TradingToken {
    IERC20 token;
    address tokenAddress;
    bool spendingIsApproved;
    kNetwork network;
}

function _calculatePercentage1000PriceImpact(int256 _amountPerMille, int256 _amount) pure returns(int256)
{
    int256 amountThatShouldBe = _amountPerMille * 1000;
    int256 tokenDifference = amountThatShouldBe - _amount;

    if (tokenDifference < 0)
    {
        return 0;
    }

    int256 result = (tokenDifference * 1000 * 100) / _amount;

    return result;
}

function _calculatePercent(uint amount, uint percentage) pure returns(uint)
{
    // Return 1% of amount
    uint _100 = 100e18;
    uint _1 = 1e18;

    return ((amount * _1 * percentage) / _100);
}

function _createAddressPath(address _addressA, address _addressB) pure returns(address[] memory)
{
    address[] memory path = new address[](2);
    path[0] = _addressA;
    path[1] = _addressB;

    return path;
}

function _uintToString(uint _i) pure returns (string memory)
{
    if (_i == 0)
    {
        return "0";
    }

    uint j = _i;
    uint len;

    while (j != 0)
    {
        len++;
        j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint k = len;

    while (_i != 0)
    {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }

    return string(bstr);
}


enum kPolygonToken
{
    wmatic,
    usdc,
    pbrew,
    elon,
    qidao,
    pnt,
    klima,
    hbar,
    clam2
}

library PolygonTokens {

    address constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant pbrew = 0xb5106A3277718eCaD2F20aB6b86Ce0Fee7A21F09;
    address constant elon = 0xE0339c80fFDE91F3e20494Df88d4206D86024cdF;
    address constant qidao = 0x580A84C73811E1839F75d86d75d88cCa0c241fF4;
    address constant pnt = 0xB6bcae6468760bc0CDFb9C8ef4Ee75C9dd23e1Ed;
    address constant klima = 0x4e78011Ce80ee02d2c3e649Fb657E45898257815;
    address constant hbar = 0x1646C835d70F76D9030DF6BaAeec8f65c250353d;
    address constant clam2 = 0xC250e9987A032ACAC293d838726C511E6E1C029d;

    function getTokenAddress(kPolygonToken token) internal pure returns(address)
    {
        if (token == kPolygonToken.wmatic)
        {
            return wmatic;
        }
        if (token == kPolygonToken.usdc)
        {
            return usdc;
        }
        if (token == kPolygonToken.pbrew)
        {
            return pbrew;
        }
        if (token == kPolygonToken.elon)
        {
            return elon;
        }
        if (token == kPolygonToken.qidao)
        {
            return qidao;
        }
        if (token == kPolygonToken.pnt)
        {
            return pnt;
        }
        if (token == kPolygonToken.klima)
        {
            return klima;
        }
        if (token == kPolygonToken.hbar)
        {
            return hbar;
        }
        if (token == kPolygonToken.clam2)
        {
            return clam2;
        }

        revert("The address of the token provided is unkown.");
    }

    function getTokenName(kPolygonToken token) internal pure returns(string memory)
    {
        if (token == kPolygonToken.wmatic)
        {
            return "WMATIC";
        }
        if (token == kPolygonToken.usdc)
        {
            return "USDC";
        }
        if (token == kPolygonToken.pbrew)
        {
            return "pBREW";
        }
        if (token == kPolygonToken.elon)
        {
            return "Dogelon";
        }
        if (token == kPolygonToken.qidao)
        {
            return "Qi Dao";
        }
        if (token == kPolygonToken.pnt)
        {
            return "pNetwork";
        }
        if (token == kPolygonToken.klima)
        {
            return "Klima Dao";
        }
        if (token == kPolygonToken.hbar)
        {
            return "Hedera";
        }
        if (token == kPolygonToken.clam2)
        {
            return "Otter Clam";
        }

        revert("The name of the token provided is unkown.");
    }

    function getBalance(kPolygonToken token) internal view returns(uint256)
    {
        return IERC20(getTokenAddress(token)).balanceOf(address(this));
    }

}

library PolygonContracts {

    address constant quickSwapV2Router02 = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant cafeSwapV2Router02 = 0x9055682E58C74fc8DdBFC55Ad2428aB1F96098Fc;
    address constant jetSwapV2Router02 = 0x5C6EC38fb0e2609672BDf628B1fD605A523E5923;
    address constant sushiSwapV2Router02 = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
}

library PolygonExchanges {

    function getExchangeName(kPolygonExchange exchange) internal pure returns(string memory)
    {
        if (exchange == kPolygonExchange.quickSwap)
        {
            return "QuickSwap";
        }
        if (exchange == kPolygonExchange.cafeSwap)
        {
            return "CafeSwap";
        }
        if (exchange == kPolygonExchange.jetSwap)
        {
            return "JetSwap";
        }
        if (exchange == kPolygonExchange.sushiSwap)
        {
            return "Sushi Swap";
        }

        revert("The name of the exchange provided is unkown.");
    }

}

enum kPolygonExchange
{
    quickSwap,
    cafeSwap,
    jetSwap,
    sushiSwap
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Library.sol";
import "./trader/QuickSwapTrader.sol";
import "./trader/CafeSwapTrader.sol";
import "./trader/JetSwapTrader.sol";
import "./trader/SushiSwapTrader.sol";

contract PolygonTradingHub is QuickSwapTrader, CafeSwapTrader, JetSwapTrader, SushiSwapTrader {

    int256 constant MAX_PRICE_IMPACT_PERCENTAGE_1000 = 105000;

    struct PolygonTradeForecast {
        kPolygonExchange exchange;
        kPolygonToken tokenIn;
        kPolygonToken tokenOut;
        uint256 tokenInAmount;
        uint256 tokenOutAmount;
    }

    struct PolygonTradeForecastABICompatible {
        string exchange;
        string tokenIn;
        string tokenOut;
        string tokenInAmount;
        string tokenOutAmount;
    }

    kPolygonExchange[] availableExchanges = [kPolygonExchange.quickSwap, kPolygonExchange.cafeSwap, kPolygonExchange.jetSwap, kPolygonExchange.sushiSwap];

    function _polygonTradingHubConvertForecastToABICompatible(PolygonTradeForecast memory _forecast) internal pure returns(PolygonTradeForecastABICompatible memory)
    {
        PolygonTradeForecastABICompatible memory forecast;

        forecast.exchange = PolygonExchanges.getExchangeName(_forecast.exchange);
        forecast.tokenIn = PolygonTokens.getTokenName(_forecast.tokenIn);
        forecast.tokenOut = PolygonTokens.getTokenName(_forecast.tokenOut);
        forecast.tokenInAmount = _uintToString(_forecast.tokenInAmount);
        forecast.tokenOutAmount = _uintToString(_forecast.tokenOutAmount);

        return forecast;
    }

    function _polygonTradingHubGetAllForcasts(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal view returns(PolygonTradeForecast[] memory)
    {
        PolygonTradeForecast[] memory forecasts = new PolygonTradeForecast[](availableExchanges.length);

        for (uint256 i = 0; i < availableExchanges.length; i++)
        {
            forecasts[i] = _polygonTradingHubGetForcast(availableExchanges[i], _tokenIn, _tokenOut, _amount);
        }

        return forecasts;
    }

    function _polygonTradingHubSwapToken(kPolygonExchange _exchange, kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal returns(bool)
    {
        if (_exchange == kPolygonExchange.quickSwap)
        {
            return _quickSwapSwapToken(_tokenIn, _tokenOut, _amount);
        }

        if (_exchange == kPolygonExchange.cafeSwap)
        {
            return _cafeSwapSwapToken(_tokenIn, _tokenOut, _amount);
        }

        if (_exchange == kPolygonExchange.jetSwap)
        {
            return _jetSwapSwapToken(_tokenIn, _tokenOut, _amount);
        }

        if (_exchange == kPolygonExchange.sushiSwap)
        {
            return _sushiSwapSwapToken(_tokenIn, _tokenOut, _amount);
        }

        revert("The exchange is unkown.");
    }

    function _polygonTradingHubGetForcast(kPolygonExchange _exchange, kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal view returns(PolygonTradeForecast memory)
    {
        PolygonTradeForecast memory forecast;

        forecast.exchange = _exchange;
        forecast.tokenIn = _tokenIn;
        forecast.tokenOut = _tokenOut;
        forecast.tokenInAmount = _amount;
        uint256 tokenPerMille;

        if (_exchange == kPolygonExchange.quickSwap)
        {
            tokenPerMille = _quickSwapGetAmountOut(_tokenIn, _tokenOut, _amount / 1000);
            forecast.tokenOutAmount = _quickSwapGetAmountOut(_tokenIn, _tokenOut, _amount);
        }
        else if (_exchange == kPolygonExchange.cafeSwap)
        {
            tokenPerMille = _cafeSwapGetAmountOut(_tokenIn, _tokenOut, _amount / 1000);
            forecast.tokenOutAmount = _cafeSwapGetAmountOut(_tokenIn, _tokenOut, _amount);
        }
        else if (_exchange == kPolygonExchange.jetSwap)
        {
            tokenPerMille = _jetSwapGetAmountOut(_tokenIn, _tokenOut, _amount / 1000);
            forecast.tokenOutAmount = _jetSwapGetAmountOut(_tokenIn, _tokenOut, _amount);
        }
        else if (_exchange == kPolygonExchange.sushiSwap)
        {
            tokenPerMille = _sushiSwapGetAmountOut(_tokenIn, _tokenOut, _amount / 1000);
            forecast.tokenOutAmount = _sushiSwapGetAmountOut(_tokenIn, _tokenOut, _amount);
        }
        else
        {
            revert("The exchange is unkown.");
        }

        if (_calculatePercentage1000PriceImpact(int256(tokenPerMille), int256(forecast.tokenOutAmount)) < MAX_PRICE_IMPACT_PERCENTAGE_1000)
        {
            // ignoring result;
            forecast.tokenOutAmount = 0;
        }

        return forecast;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../interfaces/IUniSwapV2Router02.sol";
import "../Library.sol";
import "./UniSwapV2Trader.sol";

contract QuickSwapTrader is UniSwapV2Trader {

    IUniSwapV2Router02 private tradingRouter = IUniSwapV2Router02(PolygonContracts.quickSwapV2Router02);


    function _quickSwapSwapToken(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal returns(bool)
    {
        return _uniSwapV2RouterSwapToken(tradingRouter, _tokenIn, _tokenOut, _amount);
    }

    function _quickSwapGetAmountOut(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal view returns(uint256)
    {
        return _uniSwapV2RouterGetAmountOut(tradingRouter, _tokenIn, _tokenOut, _amount);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../interfaces/IUniSwapV2Router02.sol";
import "../Library.sol";
import "./UniSwapV2Trader.sol";

contract CafeSwapTrader is UniSwapV2Trader {

    IUniSwapV2Router02 private tradingRouter = IUniSwapV2Router02(PolygonContracts.cafeSwapV2Router02);

    function _cafeSwapSwapToken(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal returns(bool)
    {
        return _uniSwapV2RouterSwapToken(tradingRouter, _tokenIn, _tokenOut, _amount);
    }

    function _cafeSwapGetAmountOut(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal view returns(uint256)
    {
        return _uniSwapV2RouterGetAmountOut(tradingRouter, _tokenIn, _tokenOut, _amount);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../interfaces/IUniSwapV2Router02.sol";
import "../Library.sol";
import "./UniSwapV2Trader.sol";

contract JetSwapTrader is UniSwapV2Trader {

    IUniSwapV2Router02 private tradingRouter = IUniSwapV2Router02(PolygonContracts.jetSwapV2Router02);


    function _jetSwapSwapToken(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal returns(bool)
    {
        return _uniSwapV2RouterSwapToken(tradingRouter, _tokenIn, _tokenOut, _amount);
    }

    function _jetSwapGetAmountOut(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal view returns(uint256)
    {
        return _uniSwapV2RouterGetAmountOut(tradingRouter, _tokenIn, _tokenOut, _amount);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../interfaces/IUniSwapV2Router02.sol";
import "../Library.sol";
import "./UniSwapV2Trader.sol";

contract SushiSwapTrader is UniSwapV2Trader {

    IUniSwapV2Router02 private tradingRouter = IUniSwapV2Router02(PolygonContracts.sushiSwapV2Router02);


    function _sushiSwapSwapToken(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal returns(bool)
    {
        return _uniSwapV2RouterSwapToken(tradingRouter, _tokenIn, _tokenOut, _amount);
    }

    function _sushiSwapGetAmountOut(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal view returns(uint256)
    {
        return _uniSwapV2RouterGetAmountOut(tradingRouter, _tokenIn, _tokenOut, _amount);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUniSwapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../interfaces/IUniSwapV2Router02.sol";
import "../Library.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniSwapV2Trader {

    uint constant MAX_SLIPPAGE = 50;

    constructor()
    {
        
    }

    function _uniSwapV2RouterSwapToken(IUniSwapV2Router02 _router, kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal returns(bool)
    {
        return _uniSwapV2RouterSwapTokenByAddress(_router, PolygonTokens.getTokenAddress(_tokenIn), PolygonTokens.getTokenAddress(_tokenOut), _amount);
    }

    function _uniSwapV2RouterGetAmountOut(IUniSwapV2Router02 _router, kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal view returns(uint256)
    {
        return _uniSwapV2RouterGetAmountOutByAddress(_router, PolygonTokens.getTokenAddress(_tokenIn), PolygonTokens.getTokenAddress(_tokenOut), _amount);
    }

    function _uniSwapV2RouterGetAmountOutByAddress(IUniSwapV2Router02 _router, address _tokenInAddress, address _tokenOutAddress, uint256 _amount) private view returns(uint256)
    {
        return _uniSwapV2RouterGetAmountOutByPath(_router, _createAddressPath(_tokenInAddress, _tokenOutAddress), _amount);
    }

    function _uniSwapV2RouterGetAmountOutByPath(IUniSwapV2Router02 _router, address[] memory _path, uint256 _amount) private view returns(uint256)
    {
        try _router.getAmountsOut(_amount, _path) returns(uint256[] memory _amountsOut)
        {
            return _amountsOut[1];
        }
        catch (bytes memory)
        {

        }

        return 0;
    }



    function _uniSwapV2RouterSwapTokenByAddress(IUniSwapV2Router02 _router, address _tokenInAddress, address _tokenOutAddress, uint256 _amount) private returns(bool)
    {
        if (_amount == 0)
        {
            return false;
        }


        _uniSwapV2RouterApproveSpending(_router, _tokenInAddress);

        uint256 _inBalance = IERC20(_tokenInAddress).balanceOf(address(this));

        require(_inBalance >= _amount, "Not enough tokens available for swap");

        address[] memory path = _createAddressPath(_tokenInAddress, _tokenOutAddress);

        uint256 amountOut = _uniSwapV2RouterGetAmountOutByPath(_router, path, _amount);

        // slippage
        uint256 minAmount = amountOut - _calculatePercent(amountOut, MAX_SLIPPAGE); 
        address receiver = address(this);

        try _router.swapExactTokensForTokens(_amount, minAmount, path, receiver, block.timestamp) returns(uint256[] memory _amountsOut)
        {
            return _amountsOut[1] != 0;
        }
        catch (bytes memory)
        {

        }

        return false;
    }


    function _uniSwapV2RouterApproveSpending(IUniSwapV2Router02 _router, address _tokenAddress) private
    {
        IERC20(_tokenAddress).approve(address(_router), MAX_INT);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}