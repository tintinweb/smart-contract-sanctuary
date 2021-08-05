pragma solidity 0.6.4;

interface IAaveAToken {
    function redeem(uint256 _amount) external;
}

pragma solidity 0.6.4;

interface IAaveLendingPool {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external;
}

pragma solidity 0.6.4;

import "./UniswapV2BalRecipe.sol";

import "../interfaces/IAaveLendingPool.sol";
import "../interfaces/IAaveLendingPoolAddressProvider.sol";
import "../interfaces/ICompoundCToken.sol";
import "../interfaces/IERC20.sol";

import "./SafeMath.sol";

contract InterestingRecipe is UniswapV2BalRecipe {
    using SafeMath for uint256;
    // IDEA: current token supports are hard coded.
    // Use calldata to create a more generalized protocol

    // map A/C token to underlying asset
    mapping(address => address) public wrappedToUnderlying;
    // map underlying asset to A/C token.

    // map to Aave LendingPoolAddressesProvider
    // map to Compound comptroller (not being used in contract)
    mapping(address => address) public wrappedToProtocol;

    // map Aave lendingpool to aave.protocol
    // map Compound comptroller to compound.protocol
    mapping(address => bytes32) public protocolIdentifier;

    function updateProtocolIdentifier(address _protocol, bytes32 _identifier)
        external
        onlyOwner
    {
        protocolIdentifier[_protocol] = _identifier;
    }

    function updateMapping(
        address[] calldata _wrapped,
        address[] calldata _underlying,
        address[] calldata _protocol
    ) external onlyOwner {
        require(_wrapped.length == _underlying.length, "UNEQUAL_LENGTH");
        require(_wrapped.length == _protocol.length, "UNEQUAL_LENGTH");
        for (uint256 i = 0; i < _wrapped.length; i++) {
            wrappedToUnderlying[_wrapped[i]] = _underlying[i];
            wrappedToProtocol[_wrapped[i]] = _protocol[i];
        }
    }

    function _swapToToken(
        address _wrapped,
        uint256 _amount,
        address _pie
    ) internal override {
        address underlying = wrappedToUnderlying[_wrapped];
        address protocol = wrappedToProtocol[_wrapped];
        bytes32 identifier = protocolIdentifier[protocol];

        if (identifier == keccak256("aave.protocol")) {
            // Aave is 1 to 1 exchange rate
            IAaveLendingPoolAddressesProvider aaveProvider = IAaveLendingPoolAddressesProvider(protocol);

            super._swapToToken(underlying, _amount, address(aaveProvider.getLendingPoolCore()));
            IAaveLendingPool aave = IAaveLendingPool(
                aaveProvider.getLendingPool()
            );
            aave.deposit(underlying, _amount, 0);

            IERC20(_wrapped).safeApprove(_pie, _amount);
        } else if (identifier == keccak256("compound.protocol")) {
            ICompoundCToken cToken = ICompoundCToken(_wrapped);
            uint256 exchangeRate = cToken.exchangeRateCurrent(); // wrapped to underlying
            uint256 underlyingAmount = _amount.mul(exchangeRate).div(10**18).add(1);

            super._swapToToken(underlying, underlyingAmount, address(cToken));
            // https://compound.finance/docs/ctokens#mint
            assert(cToken.mint(underlyingAmount) == 0);

            IERC20(_wrapped).safeApprove(_pie, _amount);
        } else {
            super._swapToToken(_wrapped, _amount, _pie);
        }
    }

    function calcEthAmount(address _wrapped, uint256 _buyAmount)
        internal
        override
        returns (uint256)
    {
        address underlying = wrappedToUnderlying[_wrapped];
        address protocol = wrappedToProtocol[_wrapped];
        bytes32 identifier = protocolIdentifier[protocol];

        if (identifier == keccak256("aave.protocol")) {
            // Aave: 1 to 1
            return super.calcEthAmount(underlying, _buyAmount);
        } else if (identifier == keccak256("compound.protocol")) {
            // convert _buyAmount of comp to underlying token
            // convert get price of underlying token with uni/bpool

            ICompoundCToken cToken = ICompoundCToken(_wrapped);
            uint256 exchangeRate = cToken.exchangeRateCurrent(); // wrapped to underlying
            uint256 underlyingAmount = _buyAmount.mul(exchangeRate).div(10**18).add(1);
            return super.calcEthAmount(underlying, underlyingAmount);
        } else {
            return super.calcEthAmount(_wrapped, _buyAmount);
        }
    }

    function calcToPie(address _pie, uint256 _poolAmount)
        public
        override
        returns (uint256)
    {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmount);

        uint256 totalEth = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (wrappedToUnderlying[tokens[i]] != address(0)) {
                totalEth += calcEthAmount(tokens[i], amounts[i]);
            } else if (tokenToBPool[tokens[i]] != address(0)) {
                totalEth += calcEthAmount(tokens[i], amounts[i]);
            } else if (registry.inRegistry(tokens[i])) {
                totalEth += calcToPie(tokens[i], amounts[i]);
            } else {
                // (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                //     address(uniswapFactory),
                //     address(WETH),
                //     tokens[i]
                // );
                // totalEth += UniLib.getAmountIn(amounts[i], reserveA, reserveB);
                totalEth += super.calcEthAmount(tokens[i], amounts[i]);
            }
        }

        return totalEth;
    }
}

import "./UniswapV2Recipe.sol";
import "../interfaces/IBPool.sol";

contract UniswapV2BalRecipe is UniswapV2Recipe {
    mapping(address => address) public tokenToBPool;

    function setBPool(address _token, address _bPool) external onlyOwner {
        tokenToBPool[_token] = _bPool;
    }

    function _swapToToken(
        address _token,
        uint256 _amount,
        address _pie
    ) internal virtual override {
        if (tokenToBPool[_token] != address(0)) {
            IBPool bPool = IBPool(tokenToBPool[_token]);
            uint256 ethAmount = calcEthAmount(_token, _amount);
            IERC20(WETH).safeApprove(address(bPool), ethAmount);
            IERC20(_token).safeApprove(_pie, _amount);
            bPool.swapExactAmountOut(
                address(WETH),
                ethAmount,
                _token,
                _amount,
                uint256(-1)
            );
        } else {
            // no bPool swap regularly
            super._swapToToken(_token, _amount, _pie);
        }
    }

    function calcToPie(address _pie, uint256 _poolAmount)
        public
        virtual
        override
        returns (uint256)
    {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmount);

        uint256 totalEth = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenToBPool[tokens[i]] != address(0)) {
                totalEth += calcEthAmount(tokens[i], amounts[i]);
            } else if (registry.inRegistry(tokens[i])) {
                totalEth += calcToPie(tokens[i], amounts[i]);
            } else {
                (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                    address(uniswapFactory),
                    address(WETH),
                    tokens[i]
                );
                totalEth += UniLib.getAmountIn(amounts[i], reserveA, reserveB);
            }
        }

        return totalEth;
    }

    function calcEthAmount(address _token, uint256 _buyAmount)
        internal
        virtual
        override
        returns (uint256)
    {
        if (tokenToBPool[_token] != address(0)) {
            IBPool bPool = IBPool(tokenToBPool[_token]);

            uint256 wethBalance = bPool.getBalance(address(WETH));
            uint256 tokenBalance = bPool.getBalance(_token);

            uint256 wethWeight = bPool.getDenormalizedWeight(address(WETH));
            uint256 tokenWeight = bPool.getDenormalizedWeight(_token);

            uint256 swapFee = bPool.getSwapFee();

            return
                bPool.calcInGivenOut(
                    wethBalance,
                    wethWeight,
                    tokenBalance,
                    tokenWeight,
                    _buyAmount,
                    swapFee
                );
        } else {
            // no bPool calc regularly
            return super.calcEthAmount(_token, _buyAmount);
        }
    }
}

pragma solidity 0.6.4;

interface IAaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address _pool) external;

    function getLendingPoolCore() external view returns (address payable);

    function setLendingPoolCoreImpl(address _lendingPoolCore) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address _configurator) external;

    function getLendingPoolDataProvider() external view returns (address);

    function setLendingPoolDataProviderImpl(address _provider) external;

    function getLendingPoolParametersProvider() external view returns (address);

    function setLendingPoolParametersProviderImpl(address _parametersProvider)
        external;

    function getTokenDistributor() external view returns (address);

    function setTokenDistributor(address _tokenDistributor) external;

    function getFeeProvider() external view returns (address);

    function setFeeProviderImpl(address _feeProvider) external;

    function getLendingPoolLiquidationManager() external view returns (address);

    function setLendingPoolLiquidationManager(address _manager) external;

    function getLendingPoolManager() external view returns (address);

    function setLendingPoolManager(address _lendingPoolManager) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address _priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address _lendingRateOracle) external;
}

pragma solidity 0.6.4;

interface ICompoundCToken {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);
}

pragma solidity ^0.6.4;

interface IERC20 {
    event Approval(address indexed _src, address indexed _dst, uint _amount);
    event Transfer(address indexed _src, address indexed _dst, uint _amount);

    function totalSupply() external view returns (uint);
    function balanceOf(address _whom) external view returns (uint);
    function allowance(address _src, address _dst) external view returns (uint);

    function approve(address _dst, uint _amount) external returns (bool);
    function transfer(address _dst, uint _amount) external returns (bool);
    function transferFrom(
        address _src, address _dst, uint _amount
    ) external returns (bool);
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "ds-math-div-zero");
        uint256 c = a / b;
        return c;
    }
}

pragma solidity 0.6.4;

import "../interfaces/IWETH.sol";
import {UniswapV2Library as UniLib} from "./UniswapV2Library.sol";
import "./LibSafeApproval.sol";
import "../interfaces/IPSmartPool.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Exchange.sol";
import "../interfaces/ISmartPoolRegistry.sol";
import "../Ownable.sol";
import "@emilianobonassi/gas-saver/ChiGasSaver.sol";

contract UniswapV2Recipe is Ownable, ChiGasSaver {
    using LibSafeApprove for IERC20;

    IWETH public constant WETH = IWETH(
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    );
    IUniswapV2Factory constant uniswapFactory = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );
    ISmartPoolRegistry public constant registry = ISmartPoolRegistry(
        0x412a5d5eC35fF185D6BfF32a367a985e1FB7c296
    );
    address payable
        public constant gasSponsor = 0x3bFdA5285416eB06Ebc8bc0aBf7d105813af06d0;
    bool private isPaused = false;

    // Pauzer
    modifier revertIfPaused {
        if (isPaused) {
            revert("[UniswapV2Recipe] is Paused");
        } else {
            _;
        }
    }

    function togglePause() public onlyOwner {
        isPaused = !isPaused;
    }

    constructor() public {
        _setOwner(msg.sender);
    }

    // Max eth amount enforced by msg.value
    function toPie(address _pie, uint256 _poolAmount)
        external
        payable
        revertIfPaused
        saveGas(gasSponsor)
    {
        require(registry.inRegistry(_pie), "Not a Pie");
        uint256 totalEth = calcToPie(_pie, _poolAmount);
        require(msg.value >= totalEth, "Amount ETH too low");

        WETH.deposit{value: totalEth}();

        _toPie(_pie, _poolAmount);

        // return excess ETH
        if (address(this).balance != 0) {
            // Send any excess ETH back
            msg.sender.transfer(address(this).balance);
        }

        // Transfer pool tokens to msg.sender
        IERC20 pie = IERC20(_pie);

        IERC20(pie).transfer(msg.sender, pie.balanceOf(address(this)));
    }

    function _toPie(address _pie, uint256 _poolAmount) internal {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmount);

        for (uint256 i = 0; i < tokens.length; i++) {
            _swapToToken(tokens[i], amounts[i], _pie);
        }

        IPSmartPool pie = IPSmartPool(_pie);
        pie.joinPool(_poolAmount);
    }

    function _swapToToken(
        address _token,
        uint256 _amount,
        address _pie
    ) internal virtual {
        
        if(_token == address(WETH)) {
            IERC20(address(WETH)).safeApprove(_pie, _amount);
            return;
        }


        if (registry.inRegistry(_token)) {
            _toPie(_token, _amount);
        } else {
            IUniswapV2Exchange pair = IUniswapV2Exchange(
                UniLib.pairFor(address(uniswapFactory), _token, address(WETH))
            );

            (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                address(uniswapFactory),
                address(WETH),
                _token
            );
            uint256 amountIn = UniLib.getAmountIn(_amount, reserveA, reserveB);

            // UniswapV2 does not pull the token
            WETH.transfer(address(pair), amountIn);

            if (token0Or1(address(WETH), _token) == 0) {
                pair.swap(_amount, 0, address(this), new bytes(0));
            } else {
                pair.swap(0, _amount, address(this), new bytes(0));
            }
        }

        IERC20(_token).safeApprove(_pie, _amount);
    }

    function calcToPie(address _pie, uint256 _poolAmount)
        public
        virtual
        returns (uint256)
    {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmount);

        uint256 totalEth = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            if(tokens[i] == address(WETH)) {
                totalEth += amounts[i];
            }
            else if (registry.inRegistry(tokens[i])) {
                totalEth += calcToPie(tokens[i], amounts[i]);
            } else {
                (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                    address(uniswapFactory),
                    address(WETH),
                    tokens[i]
                );
                totalEth += UniLib.getAmountIn(amounts[i], reserveA, reserveB);
            }
        }

        return totalEth;
    }

    function calcEthAmount(address _token, uint256 _buyAmount)
        internal
        virtual
        returns (uint256)
    {   
        if(_token == address(WETH)) {
            return _buyAmount;
        }

        if (registry.inRegistry(_token)) {
            return calcToPie(_token, _buyAmount);
        } else {
            (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                address(uniswapFactory),
                address(WETH),
                _token
            );
            return UniLib.getAmountIn(_buyAmount, reserveA, reserveB);
        }
    }

    // TODO recursive exit
    function toEth(
        address _pie,
        uint256 _poolAmount,
        uint256 _minEthAmount
    ) external revertIfPaused saveGas(gasSponsor) {
        uint256 totalEth = calcToPie(_pie, _poolAmount);
        require(_minEthAmount <= totalEth, "Output ETH amount too low");
        IPSmartPool pie = IPSmartPool(_pie);

        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmount);
        pie.transferFrom(msg.sender, address(this), _poolAmount);
        pie.exitPool(_poolAmount);

        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                address(uniswapFactory),
                tokens[i],
                address(WETH)
            );
            uint256 wethAmountOut = UniLib.getAmountOut(
                amounts[i],
                reserveA,
                reserveB
            );
            IUniswapV2Exchange pair = IUniswapV2Exchange(
                UniLib.pairFor(
                    address(uniswapFactory),
                    tokens[i],
                    address(WETH)
                )
            );

            // Uniswap V2 does not pull the token
            IERC20(tokens[i]).transfer(address(pair), amounts[i]);

            if (token0Or1(address(WETH), tokens[i]) == 0) {
                pair.swap(0, wethAmountOut, address(this), new bytes(0));
            } else {
                pair.swap(wethAmountOut, 0, address(this), new bytes(0));
            }
        }

        WETH.withdraw(totalEth);
        msg.sender.transfer(address(this).balance);
    }

    function calcToEth(address _pie, uint256 _poolAmountOut)
        external
        view
        returns (uint256)
    {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmountOut);

        uint256 totalEth = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                address(uniswapFactory),
                tokens[i],
                address(WETH)
            );
            totalEth += UniLib.getAmountOut(amounts[i], reserveA, reserveB);
        }

        return totalEth;
    }

    function token0Or1(address tokenA, address tokenB)
        internal
        view
        returns (uint256)
    {
        (address token0, address token1) = UniLib.sortTokens(tokenA, tokenB);

        if (token0 == tokenB) {
            return 0;
        }

        return 1;
    }

    function saveEth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function saveToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.4;

interface IBPool {
    function isBound(address token) external view returns(bool);
    function getBalance(address token) external view returns (uint);
    function rebind(address token, uint balance, uint denorm) external;
    function setSwapFee(uint swapFee) external;
    function setPublicSwap(bool _public) external;
    function bind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getCurrentTokens() external view returns(address[] memory);
    function setController(address manager) external;
    function isPublicSwap() external view returns(bool);
    function getSwapFee() external view returns (uint256);
    function gulp(address token) external;

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        external pure
        returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        external pure
        returns (uint poolAmountIn);

    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    )
        external
        returns (uint tokenAmountIn, uint spotPriceAfter);
}

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

import "../interfaces/IERC20.sol";

library LibSafeApprove {
    function safeApprove(IERC20 _token, address _spender, uint256 _amount) internal {
        uint256 currentAllowance = _token.allowance(address(this), _spender);

        // Do nothing if allowance is already set to this value
        if(currentAllowance == _amount) {
            return;
        }

        // If approval is not zero reset it to zero first
        if(currentAllowance != 0) {
            _token.approve(_spender, 0);
        }

        // do the actual approval
        _token.approve(_spender, _amount);
    }
}

pragma solidity ^0.6.4;

import "./IERC20.sol";
interface IPSmartPool is IERC20 {
    function joinPool(uint256 _amount) external;
    function exitPool(uint256 _amount) external;
    function getController() external view returns(address);
    function getTokens() external view returns(address[] memory);
    function calcTokensForAmount(uint256 _amount) external view  returns(address[] memory tokens, uint256[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Exchange {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

pragma solidity 0.6.4;

interface ISmartPoolRegistry {
    function inRegistry(address _pool) external view returns(bool);
    function entries(uint256 _index) external view returns(address);
    function addSmartPool(address _smartPool) external;
    function removeSmartPool(uint256 _index) external;
}

pragma solidity 0.6.4;

// TODO move this generic contract to a seperate repo with all generic smart contracts

contract Ownable {

    bytes32 constant public oSlot = keccak256("Ownable.storage.location");

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    // Ownable struct
    struct os {
        address owner;
    }

    modifier onlyOwner(){
        require(msg.sender == los().owner, "Ownable.onlyOwner: msg.sender not owner");
        _;
    }

    /**
        @notice Transfer ownership to a new address
        @param _newOwner Address of the new owner
    */
    function transferOwnership(address _newOwner) onlyOwner external {
        _setOwner(_newOwner);
    }

    /**
        @notice Internal method to set the owner
        @param _newOwner Address of the new owner
    */
    function _setOwner(address _newOwner) internal {
        emit OwnerChanged(los().owner, _newOwner);
        los().owner = _newOwner;
    }

    /**
        @notice Load ownable storage
        @return s Storage pointer to the Ownable storage struct
    */
    function los() internal pure returns (os storage s) {
        bytes32 loc = oSlot;
        assembly {
            s_slot := loc
        }
    }

}

pragma solidity ^0.6.0;

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}

contract ChiGasSaver {

    modifier saveGas(address payable sponsor) {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

        IFreeFromUpTo chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
        chi.freeFromUpTo(sponsor, (gasSpent + 14154) / 41947);
    }
}

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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity 0.6.4;

import "./PUniswapPoolRecipe.sol";
import "../Ownable.sol";
import "../interfaces/IKyberNetwork.sol";

contract PUniswapKyberPoolRecipe is PUniswapPoolRecipe, Ownable {

    bytes32 constant public ukprSlot = keccak256("PUniswapKyberPoolRecipe.storage.location");

    // Uniswap pool recipe struct
    struct ukprs {
        mapping(address => bool) swapOnKyber;
        IKyberNetwork kyber;
        address feeReceiver;
    }

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    function init(address, address) public override {
        require(false, "not enabled");
    }

    // Use seperate init function
    function initUK(address _pool, address _uniswapFactory, address _kyber, address[] memory _swapOnKyber, address _feeReciever) public {
        // UnsiwapRecipe enforces that init can only be called once
        ukprs storage s = lukprs();

        PUniswapPoolRecipe.init(_pool, _uniswapFactory);
        s.kyber = IKyberNetwork(_kyber);
        s.feeReceiver = _feeReciever;

        _setOwner(msg.sender);

        for(uint256 i = 0; i < _swapOnKyber.length; i ++) {
            s.swapOnKyber[_swapOnKyber[i]] = true;
        }
    }

    function setKyberSwap(address _token, bool _value) external onlyOwner {
        ukprs storage s = lukprs();
        s.swapOnKyber[_token] = _value;
    }

    function _ethToToken(address _token, uint256 _tokens_bought) internal override returns (uint256) {
        ukprs storage s = lukprs();
        if(!s.swapOnKyber[_token]) {
            return super._ethToToken(_token, _tokens_bought);
        }

        uint256 ethBefore = address(this).balance;
        s.kyber.trade{value: address(this).balance}(ETH, address(this).balance, _token, address(this), _tokens_bought, 1, s.feeReceiver);
        uint256 ethAfter = address(this).balance;

        // return amount of ETH spend
        return ethBefore - ethAfter;
    }

    function _tokenToEth(IERC20 _token, uint256 _tokens_sold, address _recipient) internal override returns (uint256 eth_bought) {
        ukprs storage s = lukprs();
        if(!s.swapOnKyber[address(_token)]) {
            return super._tokenToEth(_token, _tokens_sold, _recipient);
        }

        uint256 ethBefore = address(this).balance;
        _token.approve(address(s.kyber), uint256(-1));
        s.kyber.trade(address(_token), _tokens_sold, ETH, address(this), uint256(-1), 1, s.feeReceiver);
        uint256 ethAfter = address(this).balance;

        // return amount of ETH received
        return ethAfter - ethBefore;
    }

    // Load uniswap pool recipe
    function lukprs() internal pure returns (ukprs storage s) {
        bytes32 loc = ukprSlot;
        assembly {
            s_slot := loc
        }
    }

}

pragma solidity 0.6.4;

import "../interfaces/IERC20.sol";
import "../interfaces/IPSmartPool.sol";
import "../interfaces/IUniswapFactory.sol";
import "../interfaces/IUniswapExchange.sol";

// Takes ETH and mints smart pool tokens
contract PUniswapPoolRecipe {
    
    bytes32 constant public uprSlot = keccak256("PUniswapPoolRecipe.storage.location");

    // Uniswap pool recipe struct
    struct uprs {
        IPSmartPool pool;
        IUniswapFactory uniswapFactory;
    }

    function init(address _pool, address _uniswapFactory) public virtual {
        uprs storage s = luprs();
        require(address(s.pool) == address(0), "already initialised");
        s.pool = IPSmartPool(_pool);
        s.uniswapFactory = IUniswapFactory(_uniswapFactory);
    }

    // Using same interface as Uniswap for compatibility
    function ethToTokenTransferOutput(uint256 _tokens_bought, uint256 _deadline, address _recipient) public payable returns (uint256  eth_sold) {
        uprs storage s = luprs();
        require(_deadline >= block.timestamp);
        (address[] memory tokens, uint256[] memory amounts) = s.pool.calcTokensForAmount(_tokens_bought);

        eth_sold = 0;
        // Buy and approve tokens
        for(uint256 i = 0; i < tokens.length; i ++) {
            eth_sold += _ethToToken(tokens[i], amounts[i]);
            IERC20(tokens[i]).approve(address(s.pool), uint256(-1));
        }

        // Calculate amount of eth sold
        eth_sold = msg.value - address(this).balance;
        // Send back excess eth
        msg.sender.transfer(address(this).balance);

        // Join pool
        s.pool.joinPool(_tokens_bought);

        // Send pool tokens to receiver
        s.pool.transfer(_recipient, s.pool.balanceOf(address(this)));
        return eth_sold;
    }

    function ethToTokenSwapOutput(uint256 _tokens_bought, uint256 _deadline) external payable returns (uint256 eth_sold) {
        return ethToTokenTransferOutput(_tokens_bought, _deadline, msg.sender);
    }

    function _ethToToken(address _token, uint256 _tokens_bought) internal virtual returns (uint256) {
        uprs storage s = luprs();
        IUniswapExchange exchange = IUniswapExchange(s.uniswapFactory.getExchange(_token));
        return exchange.ethToTokenSwapOutput{value: address(this).balance}(_tokens_bought, uint256(-1));
    }

    function getEthToTokenOutputPrice(uint256 _tokens_bought) external view virtual returns (uint256 eth_sold) {
        uprs storage s = luprs();
        (address[] memory tokens, uint256[] memory amounts) = s.pool.calcTokensForAmount(_tokens_bought);

        eth_sold = 0;

        for(uint256 i = 0; i < tokens.length; i ++) {
            IUniswapExchange exchange = IUniswapExchange(s.uniswapFactory.getExchange(tokens[i]));
            eth_sold += exchange.getEthToTokenOutputPrice(amounts[i]);
        }

        return eth_sold;
    }

    function tokenToEthTransferInput(uint256 _tokens_sold, uint256 _min_eth, uint256 _deadline, address _recipient) public returns (uint256 eth_bought) {
        uprs storage s = luprs();
        require(_deadline >= block.timestamp);
        require(s.pool.transferFrom(msg.sender, address(this), _tokens_sold), "PUniswapPoolRecipe.tokenToEthTransferInput: transferFrom failed");

        s.pool.exitPool(_tokens_sold);

        address[] memory tokens = s.pool.getTokens();

        uint256 ethAmount = 0;

        for(uint256 i = 0; i < tokens.length; i ++) {
            IERC20 token = IERC20(tokens[i]);
            
            uint256 balance = token.balanceOf(address(this));
           
            // Exchange for ETH
            ethAmount += _tokenToEth(token, balance, _recipient);
        }

        require(ethAmount > _min_eth, "PUniswapPoolRecipe.tokenToEthTransferInput: not enough ETH");
        return ethAmount;
    }

    function tokenToEthSwapInput(uint256 _tokens_sold, uint256 _min_eth, uint256 _deadline) external returns (uint256 eth_bought) {
        return tokenToEthTransferInput(_tokens_sold, _min_eth, _deadline, msg.sender);
    }

    function _tokenToEth(IERC20 _token, uint256 _tokens_sold, address _recipient) internal virtual returns (uint256 eth_bought) {
        uprs storage s = luprs();
        IUniswapExchange exchange = IUniswapExchange(s.uniswapFactory.getExchange(address(_token)));
        _token.approve(address(exchange), _tokens_sold);
        // Exchange for ETH
        return exchange.tokenToEthTransferInput(_tokens_sold, 1, uint256(-1), _recipient);
    }

    function getTokenToEthInputPrice(uint256 _tokens_sold) external view virtual returns (uint256 eth_bought) {
        uprs storage s = luprs();
        (address[] memory tokens, uint256[] memory amounts) = s.pool.calcTokensForAmount(_tokens_sold);

        eth_bought = 0;

        for(uint256 i = 0; i < tokens.length; i ++) {
            IUniswapExchange exchange = IUniswapExchange(s.uniswapFactory.getExchange(address(tokens[i])));
            eth_bought += exchange.getTokenToEthInputPrice(amounts[i]);
        }

        return eth_bought;
    }

    function pool() external view returns (address) {
        return address(luprs().pool);
    }

    receive() external payable {

    }

    // Load uniswap pool recipe
    function luprs() internal pure returns (uprs storage s) {
        bytes32 loc = uprSlot;
        assembly {
            s_slot := loc
        }
    }
}

pragma solidity ^0.6.4;

interface IKyberNetwork {

    function trade(
        address src,
        uint srcAmount,
        address dest,
        address payable destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    ) external payable returns(uint256);
}

pragma solidity ^0.6.4;

interface IUniswapFactory {
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}

pragma solidity ^0.6.4;

interface IUniswapExchange {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    // bytes32 public name;
    // bytes32 public symbol;
    // uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}