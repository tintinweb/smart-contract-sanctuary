// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./WethMaker.sol";

/// @notice Contract for selling weth to sushi. Deploy on mainnet.
contract SushiMaker is WethMaker {

    event Serve(uint256 amount);

    address public immutable sushi;
    address public immutable xSushi;

    constructor(
        address owner,
        address user,
        address factory,
        address weth,
        address _sushi,
        address _xSushi
    ) WethMaker(owner, user, factory, weth) {
        sushi = _sushi;
        xSushi = _xSushi;
    }

    function buySushi(uint256 amountIn, uint256 minOutAmount) external onlyTrusted returns (uint256 amountOut) {
        amountOut = _swap(weth, sushi, amountIn, xSushi);
        if (amountOut < minOutAmount) revert SlippageProtection();
        emit Serve(amountOut);
    }

    function sweep(uint256 amount) external onlyTrusted {
        IERC20(sushi).transfer(xSushi, amount);
        emit Serve(amount);
    }

    // In case we receive any unwrapped ethereum we can call this.
    function wrapEth() external {
        weth.call{value: address(this).balance}("");
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./Unwindooor.sol";

/// @notice Contract for selling received tokens into weth. Deploy on secondary networks.
contract WethMaker is Unwindooor {

    event SetBridge(address indexed token, address bridge);

    address public immutable weth;

    mapping(address => address) public bridges;

    constructor(
        address owner,
        address user,
        address factory,
        address _weth
    ) Unwindooor(owner, user, factory) {
        weth = _weth;
    }

    function setBridge(address token, address bridge) external onlyOwner {
        bridges[token] = bridge;
        emit SetBridge(token, bridge);
    }

    // Exchange token for weth or its bridge token (which gets converted into weth in subsequent transactions).
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

        IUniV2 pair = IUniV2(_pairFor(tokenIn, tokenOut));
        _safeTransfer(tokenIn, address(pair), amountIn);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        if (tokenIn < tokenOut) {

            outAmount = _getAmountOut(amountIn, reserve0, reserve1);
            pair.swap(0, outAmount, to, "");

        } else {

            outAmount = _getAmountOut(amountIn, reserve1, reserve0);
            pair.swap(outAmount, 0, to, "");

        }

    }

    // Allow the owner to withdraw the funds and bridge them to mainnet.
    function withdraw(address token, address to, uint256 _value) onlyOwner external {
        if (token != address(0)) {
            _safeTransfer(token, to, _value);
        } else {
            (bool success, ) = to.call{value: _value}("");
            require(success);
        }
    }

    function doAction(address to, uint256 _value, bytes memory data) onlyOwner external {
        (bool success, ) = to.call{value: _value}(data);
        require(success);
    }

    receive() external payable {}

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./Auth.sol";
import "./interfaces/IUniV2.sol";
import "./interfaces/IUniV2Factory.sol";

/// @notice Contract for withdrawing LP positions.
/// @dev Calling unwindPairs() withdraws the LP position into one of the two tokens
contract Unwindooor is Auth {

    error SlippageProtection();
    error TransferFailed();

    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    IUniV2Factory public immutable factory;

    constructor(
        address owner,
        address user,
        address factoryAddress
    ) Auth(owner, user) {
        factory = IUniV2Factory(factoryAddress);
    }

    // We remove liquidity and sell tokensB[i] for tokensA[i].
    function unwindPairs(
        address[] calldata tokensA,
        address[] calldata tokensB,
        uint256[] calldata amounts,
        uint256[] calldata minimumOuts
    ) external onlyTrusted {
        for (uint256 i = 0; i < tokensA.length; i++) {
            
            address tokenA = tokensA[i];
            address tokenB = tokensB[i];
            bool keepToken0 = tokenA < tokenB;
            address pair = _pairFor(tokenA, tokenB);

            if (_unwindPair(IUniV2(pair), amounts[i], keepToken0, tokenB) < minimumOuts[i]) revert SlippageProtection();
        }
    }

    // Burn liquidity and sell one of the tokens for the other.
    function _unwindPair(
        IUniV2 pair,
        uint256 amount,
        bool keepToken0,
        address tokenToSell
    ) private returns (uint256 amountOut) {

        pair.transfer(address(pair), amount);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        if (keepToken0) {
            _safeTransfer(tokenToSell, address(pair), amount1);
            amountOut = _getAmountOut(amount1, uint256(reserve1), uint256(reserve0));
            pair.swap(amountOut, 0, address(this), "");
            amountOut += amount0;
        } else {
            _safeTransfer(tokenToSell, address(pair), amount0);
            amountOut = _getAmountOut(amount0, uint256(reserve0), uint256(reserve1));
            pair.swap(0, amountOut, address(this), "");
            amountOut += amount1;
        }
    }

    // In case we don't want to sell one of the tokens for the other.
    function burnPairs(
        IUniV2[] calldata lpTokens,
        uint256[] calldata amounts,
        uint256[] calldata minimumOut0,
        uint256[] calldata minimumOut1
    ) external onlyTrusted {
        for (uint256 i = 0; i < lpTokens.length; i++) {
            IUniV2 pair = lpTokens[i];
            pair.transfer(address(pair), amounts[i]);
            (uint256 amount0, uint256 amount1) = pair.burn(address(this));
            if (amount0 < minimumOut0[i] || amount1 < minimumOut1[i]) revert SlippageProtection();
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

    function _pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
        )))));
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

abstract contract Auth {

    event SetOwner(address indexed owner);
    event SetTrusted(address indexed user, bool isTrusted);

    address public owner;

    mapping(address => bool) public trusted;

    error OnlyOwner();
    error OnlyTrusted();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyTrusted() {
        if (!trusted[msg.sender]) revert OnlyTrusted();
        _;
    }

    constructor(address newOwner, address trustedUser) {
        owner = newOwner;
        trusted[trustedUser] = true;

        emit SetOwner(owner);
        emit SetTrusted(trustedUser, true);
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit SetOwner(newOwner);
    }

    function setTrusted(address user, bool isTrusted) external onlyOwner {
        trusted[user] = isTrusted;
        emit SetTrusted(user, isTrusted);
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

interface IUniV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address addy) external view returns (uint256);
}