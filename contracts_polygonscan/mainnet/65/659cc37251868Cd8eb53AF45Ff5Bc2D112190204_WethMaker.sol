// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./Unwindooor.sol";
import "./interfaces/IUniV2Factory.sol";

/// @notice Contract for selling received tokens into weth. Deploy on secondary networks.
contract WethMaker is Unwindooor {

    event SetBridge(address indexed token, address bridge);

    address public immutable weth;
    IUniV2Factory public immutable factory;

    mapping(address => address) public bridges;

    constructor(address _owner, address _user, address _factory, address _weth) Unwindooor(_owner, _user) {
        factory = IUniV2Factory(_factory);
        weth = _weth;
    }

    function setAllowedBridge(address _token, address _bridge) external onlyOwner {
        bridges[_token] = _bridge;
        emit SetBridge(_token, _bridge);
    }

    /// @dev we buy Weth or a bridge token (which will be sold for eth on the next call).
    function buyWeth(
        address[] calldata tokens,
        uint256[] calldata amountsIn,
        uint256[] calldata minimumOuts
    ) external onlyTrusted {
        for (uint256 i = 0; i < tokens.length; i++) {

            address tokenIn = tokens[i];
            address outToken = bridges[tokenIn] == address(0) ? weth : bridges[tokenIn];
            if (_swap(tokenIn, outToken, amountsIn[i], address(this)) < minimumOuts[i]) revert SlippageProtection();
            
        }
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to
    ) internal returns (uint256 outAmount) {
        
        IUniV2 pair = IUniV2(factory.getPair(tokenIn, tokenOut));
        IERC20(tokenIn).transfer(address(pair), amountIn);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        if (tokenIn < tokenOut) {

            outAmount = _getAmountOut(amountIn, reserve0, reserve1);
            pair.swap(0, outAmount, to, "");

        } else {

            outAmount = _getAmountOut(amountIn, reserve1, reserve0);
            pair.swap(outAmount, 0, to, "");

        }

    }

    // Alow owner to withdraw the funds and bridge them to mainnet.
    function doAction(address _to, uint256 _value, bytes memory _data) onlyOwner virtual external {
        (bool success, ) = _to.call{value: _value}(_data);
        require(success);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./Auth.sol";
import "./interfaces/IUniV2.sol";

/// @notice Contract for withdrawing LP positions.
/// @dev Calling unwindPairs() withdraws the LP position into one of the two tokens
contract Unwindooor is Auth {

    error SlippageProtection();
    error TransferFailed();

    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    constructor(address _owner, address _user) Auth(_owner, _user) {}

    function unwindPairs(
        IUniV2[] calldata lpTokens,
        uint256[] calldata amounts,
        uint256[] calldata minimumOuts,
        bool[] calldata keepToken0
    ) external onlyTrusted {
        for (uint256 i = 0; i < lpTokens.length; i++) {
            if (_unwindPair(lpTokens[i], amounts[i], keepToken0[i]) < minimumOuts[i]) revert SlippageProtection();
        }
    }

    function _unwindPair(
        IUniV2 pair,
        uint256 amount,
        bool keepToken0
    ) private returns (uint256 amountOut) {

        pair.transfer(address(pair), amount);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        if (keepToken0) {
            _safeTransfer(pair.token1(), address(pair), amount1);
            amountOut = _getAmountOut(amount1, uint256(reserve1), uint256(reserve0));
            pair.swap(amountOut, 0, address(this), "");
            amountOut += amount0;
        } else {
            _safeTransfer(pair.token0(), address(pair), amount0);
            amountOut = _getAmountOut(amount0, uint256(reserve0), uint256(reserve1));
            pair.swap(0, amountOut, address(this), "");
            amountOut += amount1;
        }
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }

    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

/* 
    // helper functions
    
    function easySlippageCalc(
        IUniV2[] memory lpTokens,
        uint256 slippage,
        address[] memory preferTokens
    ) external view returns (uint256[] memory amounts, uint256[] memory minimumOuts, bool[] memory keepToken0) {
        for (uint256 i = 0; i < lpTokens.length; i++) {

            IUniV2 pool = lpTokens[i];
            
            uint256 amount = pool.balanceOf(address(this));
            
            if (_included(preferTokens, pool.token0())) keepToken0[i] = true;
            
            amounts[i] = amount;
            
            minimumOuts[i] = _easySlippage(pool, amount, keepToken0[i]) * slippage / 1e3;
        }
    }

    function _easySlippage(
        IUniV2 pool,
        uint256 amount,
        bool keepToken0
    ) private view returns (uint256 minimumOut) {

        uint256 totalSupply = pool.totalSupply();
        (uint112 reserve0, uint112 reserve1,) = pool.getReserves();
        uint256 amount0 = reserve0 * amount / totalSupply;
        uint256 amount1 = reserve1 * amount / totalSupply;

        reserve0 -= uint112(amount0);
        reserve1 -= uint112(amount1);

        if (keepToken0) {
            minimumOut = amount0 + _getAmountOut(amount1, uint256(reserve1), uint256(reserve0));
        } else {
            minimumOut = amount1 + _getAmountOut(amount0, uint256(reserve0), uint256(reserve1));
        }
    }

    function _included(address[] memory tokens, address token) internal pure returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) return true;
        }
        return false;
    }
 */
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IUniV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

abstract contract Auth {

    event SetOwner(address indexed owner);
    event SetTrusted(address indexed user, bool isTrusted);

    address public owner;

    mapping(address => bool) isTrusted;

    error OnlyOwner();
    error OnlyTrusted();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyTrusted() {
        if (!isTrusted[msg.sender]) revert OnlyTrusted();
        _;
    }

    constructor(address _owner, address _trusted) {
        owner = _owner;
        isTrusted[_trusted] = true;

        emit SetOwner(owner);
        emit SetTrusted(_trusted, true);
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit SetOwner(owner);
    }

    function setTrusted(address _user, bool _isTrusted) external onlyOwner {
        isTrusted[_user] = _isTrusted;
        emit SetTrusted(_user, _isTrusted);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

import "./IERC20.sol";

interface IUniV2 is IERC20 {
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address addy) external view returns (uint256);
}