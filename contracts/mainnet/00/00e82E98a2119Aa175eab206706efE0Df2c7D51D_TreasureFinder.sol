// SPDX-License-Identifier: MIT
// P1 - P3: OK
pragma solidity 0.6.12;
import "./libraries/BoringMath.sol";
import "./libraries/BoringERC20.sol";

import "./uniswapv2/interfaces/IUniswapV2ERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";

import "./BoringOwnable.sol";

// TreasureFinder is TopDog's left hand and kinda a wizard. He can cook up Bone from pretty much anything!
// This contract handles "serving up" rewards for xShib, xLeash, tBone holders by trading tokens collected from fees into the corresponding form.

// T1 - T4: OK
contract TreasureFinder is BoringOwnable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    // V1 - V5: OK
    IUniswapV2Factory public immutable factory;
    //0xabcd...
    // V1 - V5: OK
    address public immutable buryBone;
    //0xabcd..
    // V1 - V5: OK
    address public immutable buryLeash;
    //0xabcd..
    // V1 - V5: OK
    address public immutable buryShib;
    //0xabcd..
    // V1 - V5: OK
    address private immutable bone;
    //0xabcd...
    // V1 - V5: OK
    address private immutable shib;
    //0xabcd...
    // V1 - V5: OK
    address private immutable leash;
    //0xabcd...
    // V1 - V5: OK
    address private immutable weth;
    //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

    address public topCoinDestination;

    // V1 - V5: OK
    mapping(address => address) internal _bridges;

    // E1: OK
    event LogBridgeSet(address indexed token, address indexed bridge);
    // E1: OK
    event LogConvert(
        address indexed server,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 amountBONE
    );
    event TopCoinDestination(address indexed user, address indexed destination);

    constructor (
        address _factory,
        address _swapRewardDistributor,
        address _buryBone,
        address _buryLeash,
        address _buryShib,
        address _bone,
        address _shib,
        address _leash,
        address _weth
    ) public {
        require(address(_factory) != address(0), "_factory is a zero address");
        require(address(_bone) != address(0), "_bone is a zero address");
        require(address(_shib) != address(0), "_shib is a zero address");
        require(address(_leash) != address(0), "_leash is a zero address");
        require(address(_weth) != address(0), "_weth is a zero address");
        factory = IUniswapV2Factory(_factory);
        buryBone = _buryBone;
        buryLeash = _buryLeash;
        buryShib = _buryShib;
        bone = _bone;
        shib = _shib;
        leash = _leash;
        weth = _weth;
        topCoinDestination = _swapRewardDistributor;
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        if (bridge == address(0)) {
            bridge = weth;
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(
            token != bone && token != weth && token != bridge,
            "TreasureFinder: Invalid bridge"
        );

        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    // M1 - M5: OK
    // C1 - C24: OK
    // C6: It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "TreasureFinder: must use EOA");
        _;
    }

    // F1 - F10: OK
    // F3: _convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    // F6: There is an exploit to add lots of BONE to the bar, run convert, then remove the BONE again.
    //     As the size of the BuryBone has grown, this requires large amounts of funds and isn't super profitable anymore
    //     The onlyEOA modifier prevents this being done with a flash loan.
    // C1 - C24: OK
    function convert(address token0, address token1) external onlyEOA() {
        uint amountBONE = _convert(token0, token1);
        buryTokens(amountBONE);
    }

    // F1 - F10: OK, see convert
    // C1 - C24: OK
    // C3: Loop is under control of the caller
    function convertMultiple(
        address[] calldata token0,
        address[] calldata token1
    ) external onlyEOA() {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = token0.length;
        uint amountBONE;
        for(uint256 i=0; i < len; i++) {
            amountBONE = amountBONE.add(_convert(token0[i], token1[i]));
        }
        buryTokens(amountBONE);
    }

    function buryTokens(uint amountBONE) internal {
        if(amountBONE == 0) {
            return;
        }

        uint amountBONEtoBury = amountBONE / 3;
        uint amountBONEtoSwap = amountBONE.sub(amountBONEtoBury);

        uint ethToSwap = _swap(bone, weth, amountBONEtoSwap, address(this));
        uint ethForShib = ethToSwap / 2;
        uint ethForLeash = ethToSwap.sub(ethForShib);

        uint amountSHIBtoBury = _swap(weth, shib, ethForShib, buryShib);
        uint amountLEASHtoBury = _swap(weth, leash, ethForLeash, buryLeash);

        IERC20(bone).safeTransfer(buryBone, amountBONEtoBury);
    }

    // F1 - F10: OK
    // C1- C24: OK
    function _convert(address token0, address token1) internal returns(uint256) {
        // Interactions
        // S1 - S4: OK
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        require(address(pair) != address(0), "TreasureFinder: Invalid pair");
        // balanceOf: S1 - S4: OK
        // transfer: X1 - X5: OK
        IERC20(address(pair)).safeTransfer(
            address(pair),
            pair.balanceOf(address(this))
        );
        // X1 - X5: OK
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        if (token0 != pair.token0()) {
            (amount0, amount1) = (amount1, amount0);
        }

        uint amountBONE;
        if (!_convertTopCoins(token0, token1, amount0, amount1)) {
            // convert amount0, amount1 to BONE
            amountBONE = _convertStep(token0, token1, amount0, amount1);
            emit LogConvert(
                msg.sender,
                token0,
                token1,
                amount0,
                amount1,
                amountBONE
            );
        }
        return amountBONE;
    }

    function _convertTopCoins(
        address token0,
        address token1,
        uint amount0,
        uint amount1
    ) internal returns(bool) {

        bool isTop0 = factory.topCoins(token0);
        bool isTop1 = factory.topCoins(token1);

        if (isTop0 && isTop1) {
            IERC20(token0).safeTransfer(topCoinDestination, amount0);
            IERC20(token1).safeTransfer(topCoinDestination, amount1);
        }
        else if (isTop0) {
            IERC20(token0).safeTransfer(topCoinDestination, _swap(token1, token0, amount1, address(this)).add(amount0));
        } else if (isTop1) {
            IERC20(token1).safeTransfer(topCoinDestination, _swap(token0, token1, amount0, address(this)).add(amount1));
        } else {
            return false;
        }
        return true;
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, _swap, _toBONE, _convertStep: X1 - X5: OK
    function _convertStep(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) internal returns(uint256 boneOut) {
        // Interactions
        if (token0 == token1) {
            uint256 amount = amount0.add(amount1);
            if (token0 == bone) {
                boneOut = amount;
            } else if (token0 == weth) {
                boneOut = _toBONE(weth, amount);
            } else {
                address bridge = bridgeFor(token0);
                amount = _swap(token0, bridge, amount, address(this));
                boneOut = _convertStep(bridge, bridge, amount, 0);
            }
        } else if (token0 == bone) {
            // eg. BONE - ETH
            boneOut = _toBONE(token1, amount1).add(amount0);
        } else if (token1 == bone) {
            // eg. USDT - BONE
            boneOut = _toBONE(token0, amount0).add(amount1);
        } else if (token0 == weth) {
            // eg. ETH - USDC
            boneOut = _toBONE(
                weth,
                _swap(token1, weth, amount1, address(this)).add(amount0)
            );
        } else if (token1 == weth) {
            // eg. USDT - ETH
            boneOut = _toBONE(
                weth,
                _swap(token0, weth, amount0, address(this)).add(amount1)
            );
        } else {
            // eg. MIC - USDT
            address bridge0 = bridgeFor(token0);
            address bridge1 = bridgeFor(token1);
            if (bridge0 == token1) {
                // eg. MIC - USDT - and bridgeFor(MIC) = USDT
                boneOut = _convertStep(
                    bridge0,
                    token1,
                    _swap(token0, bridge0, amount0, address(this)),
                    amount1
                );
            } else if (bridge1 == token0) {
                // eg. WBTC - DSD - and bridgeFor(DSD) = WBTC
                boneOut = _convertStep(
                    token0,
                    bridge1,
                    amount0,
                    _swap(token1, bridge1, amount1, address(this))
                );
            } else {
                // eg. USDT - DSD - and bridgeFor(DSD) = WBTC
                boneOut = _convertStep(
                    bridge0,
                    bridge1,
                    _swap(token0, bridge0, amount0, address(this)),
                    _swap(token1, bridge1, amount1, address(this))
                );
            }
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, swap: X1 - X5: OK
    function _swap(address fromToken, address toToken, uint256 amountIn, address to) internal returns (uint256 amountOut) {

        if(amountIn == 0) {
            return 0;
        }
        // Checks
        // X1 - X5: OK
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(fromToken, toToken));
        require(address(pair) != address(0), "TreasureFinder: Cannot convert");

        // Interactions
        // X1 - X5: OK
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(uint(1000).sub(pair.totalFee()));
        if (fromToken == pair.token0()) {
            amountOut = amountInWithFee.mul(reserve1) / reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, new bytes(0));
            // TODO: Add maximum slippage?
        } else {
            amountOut = amountInWithFee.mul(reserve0) / reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, new bytes(0));
            // TODO: Add maximum slippage?
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function _toBONE(address token, uint256 amountIn) internal returns(uint256 amountOut) {
        // X1 - X5: OK
        amountOut = _swap(token, bone, amountIn, address(this));
    }

    function setTopCoinDestination(address _destination) external onlyOwner {
        topCoinDestination = _destination;
        emit TopCoinDestination(msg.sender, _destination);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";

library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    
    function totalFee() external view returns (uint);
    function alpha() external view returns (uint);
    function beta() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, uint, uint, uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function totalFeeTopCoin() external view returns (uint);
    function alphaTopCoin() external view returns (uint);
    function betaTopCoin() external view returns (uint);
    function totalFeeRegular() external view returns (uint);
    function alphaRegular() external view returns (uint);
    function betaRegular() external view returns (uint);

    function topCoins(address token) external view returns (bool isTopCoin);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract BoringOwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract BoringOwnable is BoringOwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        
        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

