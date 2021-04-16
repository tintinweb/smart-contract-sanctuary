// SPDX-License-Identifier: MIT

// P1 - P3: OK
pragma solidity ^0.7.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

import "./IUniswapV2.sol";

import "./FeeDistributorHelpers.sol";


contract FeeDistributor is FeeDistributorHelpers, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Fees, their respective recipients, and the target asset
    // Should be xBASK - 30%, BDPI - 70%
    uint256[] public fees; // Should add up to 1e18
    address[] public feeRecipients;
    address[] public feeRecipientAssets;

    // Mappings
    mapping(address => address) internal _bridges;
    mapping(bytes32 => address) internal _factories;

    // Events
    event LogFactorySet(address indexed fromToken, address indexed toToken, address indexed factory);
    event LogBridgeSet(address indexed token, address indexed bridge);
    event LogConverted(
        address indexed server,
        address indexed token0,
        address indexed token1,
        address recipient,
        uint256 amount0,
        uint256 amount1
    );

    // Constants
    IUniswapV2Factory constant sushiswapFactory = IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    IUniswapV2Factory constant uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    // Roles
    bytes32 public constant MARKET_MAKER = keccak256("baskmaker.access.marketMaker");
    bytes32 public constant MARKET_MAKER_ADMIN = keccak256("baskmaker.access.marketMaker.admin");

    bytes32 public constant TIMELOCK = keccak256("baskmaker.access.marketMaker");
    bytes32 public constant TIMELOCK_ADMIN = keccak256("baskmaker.access.marketMaker.admin");

    constructor(
        address _timelock,
        address _admin,
        uint256[] memory _fees,
        address[] memory _feeRecipients,
        address[] memory _feeRecipientAssets
    ) {
        _setRoleAdmin(TIMELOCK, TIMELOCK_ADMIN);
        _setupRole(TIMELOCK_ADMIN, _timelock);
        _setupRole(TIMELOCK, _timelock);

        _setRoleAdmin(MARKET_MAKER, MARKET_MAKER_ADMIN);
        _setupRole(MARKET_MAKER_ADMIN, _admin);
        _setupRole(MARKET_MAKER, _admin);
        _setupRole(MARKET_MAKER, msg.sender);

        fees = _fees;
        feeRecipients = _feeRecipients;
        feeRecipientAssets = _feeRecipientAssets;
        _assertFees();

        setFactory(KNC, WETH, address(uniswapFactory));
        setFactory(LRC, WETH, address(uniswapFactory));
        setFactory(BAL, WETH, address(uniswapFactory));
        setFactory(MTA, WETH, address(uniswapFactory));
    }

    // **** Modifiers ****

    modifier authorized(bytes32 role) {
        require(hasRole(role, msg.sender), "!authorized");
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

    function setFees(
        uint256[] memory _fees,
        address[] memory _feeRecipients,
        address[] memory _feeRecipientAssets
    ) external authorized(TIMELOCK) {
        fees = _fees;
        feeRecipients = _feeRecipients;
        feeRecipientAssets = _feeRecipientAssets;
        _assertFees();
    }

    function setBridge(address token, address bridge) external authorized(MARKET_MAKER) {
        require(token != BASK && token != WETH && token != bridge, "BaskMaker: Invalid bridge");
        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    function setFactory(
        address fromToken,
        address toToken,
        address factory
    ) public authorized(MARKET_MAKER) {
        require(
            factory == address(sushiswapFactory) || factory == address(uniswapFactory),
            "BaskMaker: Invalid factory"
        );

        // Effects
        _factories[keccak256(abi.encode(fromToken, toToken))] = factory;
        LogFactorySet(fromToken, toToken, factory);
    }

    function rescueERC20(address _token) public authorized(MARKET_MAKER) {
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function rescueERC20s(address[] memory _tokens) external authorized(MARKET_MAKER) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            rescueERC20(_tokens[i]);
        }
    }

    function convert(address token) external authorized(MARKET_MAKER) {
        _convert(token);
    }

    function convertMultiple(address[] calldata tokens) external authorized(MARKET_MAKER) {
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; i++) {
            _convert(tokens[i]);
        }
    }

    // **** Internal functions ****

    function _convert(address token) internal {
        address token0 = _toUnderlying(token);
        uint256 amount0 = IERC20(token0).balanceOf(address(this));

        _convertStep(token0, amount0);
    }

    function _convertStep(address token, uint256 amount) internal {
        // Final case
        if (token == WETH) {
            uint256 wethAllocAmount;
            address wantedAsset;
            for (uint256 i = 0; i < fees.length; i++) {
                wethAllocAmount = amount.mul(fees[i]).div(1e18);
                wantedAsset = feeRecipientAssets[i];
                if (wantedAsset == token) {
                    IERC20(token).safeTransfer(feeRecipients[i], wethAllocAmount);
                } else {
                    _swap(token, feeRecipientAssets[i], wethAllocAmount, feeRecipients[i]);
                }
            }
            return;
        }

        // Otherwise keep converting
        address bridge = bridgeFor(token);
        uint256 amountOut = _swap(token, bridge, amount, address(this));
        _convertStep(bridge, amountOut);
    }

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
        emit LogConverted(msg.sender, fromToken, toToken, to, amountIn, amountOut);
    }

    function _assertFees() internal view {
        require(fees.length == feeRecipients.length, "!invalid-recipient-length");
        require(fees.length == feeRecipientAssets.length, "!invalid-asset-length");

        uint256 total = 0;
        for (uint256 i = 0; i < fees.length; i++) {
            total = total.add(fees[i]);
        }

        require(total == 1e18, "!valid-fees");
    }
}