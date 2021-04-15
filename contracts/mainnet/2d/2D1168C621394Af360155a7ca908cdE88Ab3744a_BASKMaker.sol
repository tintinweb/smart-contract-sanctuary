// SPDX-License-Identifier: MIT

// P1 - P3: OK
pragma solidity ^0.7.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

import "./IUniswapV2.sol";

import "./BASKMakerHelpers.sol";

// BaskMaker is MasterChef's left hand and kinda a wizard. He can cook up Bask from pretty much anything!
// This contract handles "serving up" rewards for xBask holders by trading tokens collected from fees for Bask.

contract BASKMaker is BASKMakerHelpers, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Factory constant sushiswapFactory = IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    IUniswapV2Factory constant uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    mapping(address => address) internal _bridges;
    mapping(bytes32 => address) internal _factories;

    event LogFactorySet(address indexed fromToken, address indexed toToken, address indexed factory);
    event LogBridgeSet(address indexed token, address indexed bridge);
    event LogConvert(address indexed server, address indexed token0, uint256 amount0, uint256 amountBASK);

    // Roles
    bytes32 public constant MARKET_MAKER = keccak256("baskmaker.access.marketMaker");
    bytes32 public constant MARKET_MAKER_ADMIN = keccak256("baskmaker.access.marketMaker.admin");

    constructor(address _admin) {
        _setRoleAdmin(MARKET_MAKER, MARKET_MAKER_ADMIN);
        _setupRole(MARKET_MAKER_ADMIN, _admin);
        _setupRole(MARKET_MAKER, _admin);
        _setupRole(MARKET_MAKER, msg.sender);

        setFactory(KNC, WETH, address(uniswapFactory));
        setFactory(LRC, WETH, address(uniswapFactory));
        setFactory(BAL, WETH, address(uniswapFactory));
        setFactory(MTA, WETH, address(uniswapFactory));
    }

    // **** Modifiers ****

    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "BaskMaker: must use EOA");
        _;
    }

    modifier authorized() {
        require(hasRole(MARKET_MAKER, msg.sender), "!authorized");
        _;
    }

    // **** Stateless functions ****

    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        if (bridge == address(0)) {
            bridge = WETH;
        }
    }

    function factoryFor(address fromToken, address toToken) public view returns (address factory) {
        bytes32 h = keccak256(abi.encode(fromToken, toToken));
        factory = _factories[h];
        if (factory == address(0)) {
            factory = address(sushiswapFactory);
        }
    }

    // **** Restricted functions ***

    function setBridge(address token, address bridge) external authorized {
        require(token != BASK && token != WETH && token != bridge, "BaskMaker: Invalid bridge");
        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    function setFactory(
        address fromToken,
        address toToken,
        address factory
    ) public authorized {
        require(
            factory == address(sushiswapFactory) || factory == address(uniswapFactory),
            "BaskMaker: Invalid factory"
        );

        // Effects
        _factories[keccak256(abi.encode(fromToken, toToken))] = factory;
        LogFactorySet(fromToken, toToken, factory);
    }

    // Burn BDPI and future baskets
    function burn(address _token) external authorized {
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        (bool success, ) = _token.call(abi.encodeWithSignature("burn(uint256)", _amount));
        require(success, "!success");
    }

    function rescueERC20(address _token) external authorized {
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    // F1 - F10: OK
    // F3: _convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    // F6: There is an exploit to add lots of BASK to the xbask, run convert, then remove the BASK again.
    //     As the size of the BaskBar has grown, this requires large amounts of funds and isn't super profitable anymore
    //     The onlyEOA modifier prevents this being done with a flash loan.
    // C1 - C24: OK
    function convert(address token) external onlyEOA() {
        _convert(token);
    }

    // F1 - F10: OK, see convert
    // C1 - C24: OK
    // C3: Loop is under control of the caller
    function convertMultiple(address[] calldata tokens) external onlyEOA() {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; i++) {
            _convert(tokens[i]);
        }
    }

    // **** Internal functions ****

    // F1 - F10: OK
    // C1- C24: OK
    function _convert(address token) internal {
        address token0 = _toUnderlying(token);
        uint256 amount0 = IERC20(token0).balanceOf(address(this));

        emit LogConvert(msg.sender, token0, amount0, _convertStep(token0, amount0));
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, _swap, _toBASK, _convertStep: X1 - X5: OK
    function _convertStep(address token, uint256 amount) internal returns (uint256) {
        // Final case
        if (token == WETH) {
            return _toBASK(token, amount);
        }

        // Otherwise keep converting
        address bridge = bridgeFor(token);
        uint256 amountOut = _swap(token, bridge, amount, address(this));
        return _convertStep(bridge, amountOut);
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, swap: X1 - X5: OK
    function _swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
    ) internal returns (uint256 amountOut) {
        // Checks
        // X1 - X5: OK
        IUniswapV2Pair pair =
            IUniswapV2Pair(IUniswapV2Factory(factoryFor(fromToken, toToken)).getPair(fromToken, toToken));
        require(address(pair) != address(0), "BaskMaker: Cannot convert");

        // Interactions
        // X1 - X5: OK
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        if (fromToken == pair.token0()) {
            amountOut = amountIn.mul(997).mul(reserve1) / reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, new bytes(0));
            // TODO: Add maximum slippage?
        } else {
            amountOut = amountIn.mul(997).mul(reserve0) / reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, new bytes(0));
            // TODO: Add maximum slippage?
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function _toBASK(address token, uint256 amountIn) internal returns (uint256 amountOut) {
        // X1 - X5: OK
        amountOut = _swap(token, BASK, amountIn, XBASK);
    }
}