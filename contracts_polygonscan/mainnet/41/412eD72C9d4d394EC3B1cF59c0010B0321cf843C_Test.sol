//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PolygonTradingHub.sol";
import "./Library.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Test is Ownable, PolygonTradingHub {



    constructor()
    {
        transferOwnership(msg.sender);
    }

    function deposit() external payable 
    {

    }

    function getPrices() view external returns(PolygonTradeForecastABICompatible[] memory)
    {
        PolygonTradeForecast[] memory forecasts = _polygonTradingHubGetAllForcasts(kPolygonToken.usdc, kPolygonToken.wmatic, 10000);

        PolygonTradeForecastABICompatible[] memory compatibleForecasts = new PolygonTradeForecastABICompatible[](forecasts.length);

        for (uint256 i = 0; i < forecasts.length; i++)
        {
            compatibleForecasts[i] = _polygonTradingHubConvertForecastToABICompatible(forecasts[i]);
        }

        return compatibleForecasts;
    }

    function getBalance() view external returns(uint256)
    {
        return address(this).balance;
    }

    function getUSDCBalance() view external returns(uint256)
    {
        return IERC20(PolygonTokens.usdc).balanceOf(address(this));
    }

    function getWMATICBalance() view external returns(uint256)
    {
        return IERC20(PolygonTokens.wmatic).balanceOf(address(this));
    }

    function swap(uint256 _amount) external onlyOwner
    {
        // _quickSwapSwapToken(kPolygonToken.wmatic, kPolygonToken.usdc, _amount);
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

import "./Library.sol";
import "./trader/QuickSwapTrader.sol";
import "./trader/CafeSwapTrader.sol";
import "./trader/JetSwapTrader.sol";

contract PolygonTradingHub is QuickSwapTrader, CafeSwapTrader, JetSwapTrader {

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

    kPolygonExchange[] availableExchanges = [kPolygonExchange.quickSwap, kPolygonExchange.cafeSwap, kPolygonExchange.jetSwap];

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

    function _polygonTradingHubGetForcast(kPolygonExchange _exchange, kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal view returns(PolygonTradeForecast memory)
    {
        PolygonTradeForecast memory forecast;

        forecast.exchange = _exchange;
        forecast.tokenIn = _tokenIn;
        forecast.tokenOut = _tokenOut;
        forecast.tokenInAmount = _amount;

        if (_exchange == kPolygonExchange.quickSwap)
        {
            forecast.tokenOutAmount = _quickSwapGetAmountOut(_tokenIn, _tokenOut, _amount);

            return forecast;
        }

        if (_exchange == kPolygonExchange.cafeSwap)
        {
            forecast.tokenOutAmount = _cafeSwapGetAmountOut(_tokenIn, _tokenOut, _amount);

            return forecast;
        }

        if (_exchange == kPolygonExchange.jetSwap)
        {
            forecast.tokenOutAmount = _jetSwapGetAmountOut(_tokenIn, _tokenOut, _amount);

            return forecast;
        }

        revert("The exchange is unkown.");
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

enum kPolygonToken
{
    wmatic,
    usdc
}


function _calculateOnePercent(uint amount) pure returns(uint)
{
    // Return 1% of amount
    uint _100 = 100e18;
    uint _1 = 1e18;

    return ((amount * _1) / _100);
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

library PolygonTokens {

    address constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

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

        revert("The name of the token provided is unkown.");
    }

}

library PolygonContracts {

    address constant quickSwapV2Router02 = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant cafeSwapV2Router02 = 0x9055682E58C74fc8DdBFC55Ad2428aB1F96098Fc;
    address constant jetSwapV2Router02 = 0x5C6EC38fb0e2609672BDf628B1fD605A523E5923;
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

        revert("The name of the exchange provided is unkown.");
    }

}

enum kPolygonExchange
{
    quickSwap,
    cafeSwap,
    jetSwap
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

import "../interfaces/IUniSwapV2Router02.sol";
import "../Library.sol";
import "./UniSwapV2Trader.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract QuickSwapTrader is UniSwapV2Trader {

    mapping(address => TradingToken) private tokens;

    IUniSwapV2Router02 private tradingRouter = IUniSwapV2Router02(PolygonContracts.quickSwapV2Router02);


    function _quickSwapSwapToken(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal
    {
        _uniSwapV2RouterSwapToken(tradingRouter, _tokenIn, _tokenOut, _amount);
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CafeSwapTrader is UniSwapV2Trader {

    mapping(address => TradingToken) private tokens;

    IUniSwapV2Router02 private tradingRouter = IUniSwapV2Router02(PolygonContracts.cafeSwapV2Router02);

    function _cafeSwapSwapToken(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal
    {
        _uniSwapV2RouterSwapToken(tradingRouter, _tokenIn, _tokenOut, _amount);
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract JetSwapTrader is UniSwapV2Trader {

    IUniSwapV2Router02 private tradingRouter = IUniSwapV2Router02(PolygonContracts.jetSwapV2Router02);


    function _jetSwapSwapToken(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal
    {
        _uniSwapV2RouterSwapToken(tradingRouter, _tokenIn, _tokenOut, _amount);
    }

    function _jetSwapGetAmountOut(kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal view returns(uint256)
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

    mapping(address => TradingToken) private tokens;

    constructor()
    {
        
    }

    function _uniSwapV2RouterSwapToken(IUniSwapV2Router02 _router, kPolygonToken _tokenIn, kPolygonToken _tokenOut, uint256 _amount) internal
    {
        _uniSwapV2RouterSwapTokenByAddress(_router, PolygonTokens.getTokenAddress(_tokenIn), PolygonTokens.getTokenAddress(_tokenOut), _amount);
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
        uint256[] memory amountsOut = _router.getAmountsOut(
            _amount,
            _path
        );

        return amountsOut[1];
    }



    function _uniSwapV2RouterSwapTokenByAddress(IUniSwapV2Router02 _router, address _tokenInAddress, address _tokenOutAddress, uint256 _amount) private
    {
        if (_amount == 0)
        {
            return;
        }

        _uniSwapV2RouterApproveSpending(_router, _tokenInAddress);

        uint256 _inBalance = IERC20(_tokenInAddress).balanceOf(address(this));

        require(_inBalance >= _amount, "Not enough tokens available for swap");

        address[] memory path = _createAddressPath(_tokenInAddress, _tokenOutAddress);

        uint256 amountOut = _uniSwapV2RouterGetAmountOutByPath(_router, path, _amount);

        // 1% slippage
        uint256 minAmount = amountOut - _calculateOnePercent(amountOut); 
        address receiver = address(this);

        _router.swapExactTokensForTokens(
            _amount,
            minAmount,
            path,
            receiver,
            block.timestamp
        );
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