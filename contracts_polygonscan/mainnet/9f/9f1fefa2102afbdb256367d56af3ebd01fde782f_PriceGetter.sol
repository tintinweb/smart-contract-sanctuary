/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

/*
Join us at PolyCrystal.Finance!
█▀▀█ █▀▀█ █░░ █░░█ █▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░█ █░░█ █░░ █▄▄█ █░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
█▀▀▀ ▀▀▀▀ ▀▀▀ ▄▄▄█ ▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/

pragma solidity ^0.8.6;

/*
This library provides an initial framework for optimized routing and 
functions to manage data specific to UniswapV2-compatible AMMs. The pure
functions inline to constants at compile time, so we can deploy
strategies involving AMMs other than ApeSwap with minimal need to refactor.

Tested with AMMs that implement the standard UniswapV2 swap logic. Not tested with fee on 
transfer tokens. Not likely to work with Firebird, Curve, or DMM without extension.
*/


enum AmmData { APE, QUICK, SUSHI, DFYN, JET, NULL }

/*
To retrieve stats, use for example:

    using UniV2AMMData for AmmData; 

    function exampleFunc() internal {
        AmmData _amm = AmmData.APE;
        _amm.factory();
        _amm.pairCodeHash();
        _amm.fee();
    }
*/

library AMMData {
    
    uint constant internal NUM_AMMS = 5;
    
    address constant private APE_FACTORY = 0xCf083Be4164828f00cAE704EC15a36D711491284;
    address constant private QUICK_FACTORY = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    address constant private SUSHI_FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address constant private DFYN_FACTORY = 0xE7Fb3e833eFE5F9c441105EB65Ef8b261266423B;
    address constant private JET_FACTORY = 0x668ad0ed2622C62E24f0d5ab6B6Ac1b9D2cD4AC7;
    
    //used for internally locating a pair without an external call to the factory
    bytes32 constant private APE_PAIRCODEHASH = hex'511f0f358fe530cda0859ec20becf391718fdf5a329be02f4c95361f3d6a42d8';
    bytes32 constant private QUICK_PAIRCODEHASH = hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f';
    bytes32 constant private SUSHI_PAIRCODEHASH = hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303';
    bytes32 constant private DFYN_PAIRCODEHASH = hex'f187ed688403aa4f7acfada758d8d53698753b998a3071b06f1b777f4330eaf3';
    bytes32 constant private JET_PAIRCODEHASH = hex'505c843b83f01afef714149e8b174427d552e1aca4834b4f9b4b525f426ff3c6';

    // Fees are in increments of 10 basis points (0.10%)
    uint constant private APE_FEE = 2; 
    uint constant private QUICK_FEE = 3;
    uint constant private SUSHI_FEE = 3;
    uint constant private DFYN_FEE = 3;
    uint constant private JET_FEE = 0;
    
    function factoryToAmm(address _factory) internal pure returns(AmmData amm) {
        if (_factory == APE_FACTORY) return AmmData.APE;
        if (_factory == QUICK_FACTORY) return AmmData.QUICK;
        if (_factory == SUSHI_FACTORY) return AmmData.SUSHI;
        if (_factory == DFYN_FACTORY) return AmmData.DFYN;
        if (_factory == JET_FACTORY) return AmmData.JET;
        revert("");
    }

    function factory(AmmData _amm) internal pure returns(address) {
        if (_amm == AmmData.APE) return APE_FACTORY;
        if (_amm == AmmData.QUICK) return QUICK_FACTORY;
        if (_amm == AmmData.SUSHI) return SUSHI_FACTORY;
        if (_amm == AmmData.DFYN) return DFYN_FACTORY;
        if (_amm == AmmData.JET) return JET_FACTORY;        
        revert(); //should never happen
    }

    function pairCodeHash(AmmData _amm) internal pure returns(bytes32) {
        if (_amm == AmmData.APE) return APE_PAIRCODEHASH;
        if (_amm == AmmData.QUICK) return QUICK_PAIRCODEHASH;
        if (_amm == AmmData.SUSHI) return SUSHI_PAIRCODEHASH;
        if (_amm == AmmData.DFYN) return DFYN_PAIRCODEHASH;
        if (_amm == AmmData.JET) return JET_PAIRCODEHASH;
        revert();
    }
    
    function fee(AmmData _amm) internal pure returns (uint) {
        if (_amm == AmmData.APE) return APE_FEE;
        if (_amm == AmmData.QUICK) return QUICK_FEE;
        if (_amm == AmmData.SUSHI) return SUSHI_FEE;
        if (_amm == AmmData.DFYN) return DFYN_FEE;
        if (_amm == AmmData.JET) return JET_FEE;        
        revert();
    }
    
}

pragma solidity ^0.8.6;

interface IApePair {
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

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.6;

// This library provides simple price calculations for ApeSwap tokens, accounting
// for commonly used pairings. Will break if USDT, BUSD, or DAI goes far off peg.
// Should NOT be used as the sole oracle for sensitive calculations such as 
// liquidation, as it is vulnerable to manipulation by flash loans, etc. BETA
// SOFTWARE, PROVIDED AS IS WITH NO WARRANTIES WHATSOEVER.

// Polygon mainnet version

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

library PriceGetter {
    using AMMData for AmmData;
    
    address public constant FACTORY = 0xCf083Be4164828f00cAE704EC15a36D711491284; //ApeFactory
    bytes32 public constant INITCODEHASH = hex'511f0f358fe530cda0859ec20becf391718fdf5a329be02f4c95361f3d6a42d8'; // for pairs created by ApeFactory
    
    //Returned prices calculated with this precision (18 decimals)
    uint public constant DECIMALS = 18;
    uint private constant PRECISION = 1e18; //1e18 == $1
    
    //Token addresses
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    //Ape LP addresses
    address private constant WMATIC_USDT_PAIR = 0x65D43B64E3B31965Cd5EA367D4c2b94c03084797;
    address private constant WMATIC_DAI_PAIR = 0x84964d9f9480a1dB644c2B2D1022765179A40F68;
    address private constant WMATIC_USDC_PAIR = 0x019011032a7ac3A87eE885B6c08467AC46ad11CD;
    
    address private constant WETH_USDT_PAIR = 0x7B2dD4bab4487a303F716070B192543eA171d3B2;
    address private constant USDC_WETH_PAIR = 0x84964d9f9480a1dB644c2B2D1022765179A40F68;
    address private constant WETH_DAI_PAIR = 0xb724E5C1Aef93e972e2d4b43105521575f4ca855;

    //Normalized to specified number of decimals based on token's decimals and
    //specified number of decimals
    function getPrice(address token, uint _decimals) external view returns (uint) {
        return normalize(getRawPrice(token), token, _decimals);
    }

    function getLPPrice(address token, uint _decimals) external view returns (uint) {
        return normalize(getRawLPPrice(token), token, _decimals);
    }
    function getPrices(address[] calldata tokens, uint _decimals) external view returns (uint[] memory prices) {
        prices = getRawPrices(tokens);
        
        for (uint i; i < prices.length; i++) {
            prices[i] = normalize(prices[i], tokens[i], _decimals);
        }
    }
    function getLPPrices(address[] calldata tokens, uint _decimals) external view returns (uint[] memory prices) {
        prices = getRawLPPrices(tokens);
        
        for (uint i; i < prices.length; i++) {
            prices[i] = normalize(prices[i], tokens[i], _decimals);
        }
    }
    
    //returns the price of any token in USD based on common pairings; zero on failure
    function getRawPrice(address token) internal view returns (uint) {
        uint pegPrice = pegTokenPrice(token);
        if (pegPrice != 0) return pegPrice;
        
        return getRawPrice(token, getMATICPrice(), getETHPrice());
    }
    
    //returns the prices of multiple tokens, zero on failure
    function getRawPrices(address[] calldata tokens) public view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        uint maticPrice = getMATICPrice();
        uint ethPrice = getETHPrice();
        
        for (uint i; i < prices.length; i++) {
            address token = tokens[i];
            
            uint pegPrice = pegTokenPrice(token, maticPrice, ethPrice);
            if (pegPrice != 0) prices[i] = pegPrice;
            else prices[i] = getRawPrice(token, maticPrice, ethPrice);
        }
    }
    
    //returns the value of a LP token if it is one, or the regular price if it isn't LP
    function getRawLPPrice(address token) internal view returns (uint) {
        uint pegPrice = pegTokenPrice(token);
        if (pegPrice != 0) return pegPrice;
        
        return getRawLPPrice(token, getMATICPrice(), getETHPrice());
    }
    //returns the prices of multiple tokens which may or may not be LPs
    function getRawLPPrices(address[] calldata tokens) internal view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        uint maticPrice = getMATICPrice();
        uint ethPrice = getETHPrice();
        
        for (uint i; i < prices.length; i++) {
            address token = tokens[i];
            
            uint pegPrice = pegTokenPrice(token, maticPrice, ethPrice);
            if (pegPrice != 0) prices[i] = pegPrice;
            else prices[i] = getRawLPPrice(token, maticPrice, ethPrice);
        }
    }
    //returns the current USD price of MATIC based on primary stablecoin pairs
    function getMATICPrice() internal view returns (uint) {
        (uint wmaticReserve0, uint usdtReserve,) = IApePair(WMATIC_USDT_PAIR).getReserves();
        (uint wmaticReserve1, uint daiReserve,) = IApePair(WMATIC_DAI_PAIR).getReserves();
        (uint wmaticReserve2, uint usdcReserve,) = IApePair(WMATIC_USDC_PAIR).getReserves();
        uint wmaticTotal = wmaticReserve0 + wmaticReserve1 + wmaticReserve2;
        uint usdTotal = daiReserve + (usdcReserve + usdtReserve)*1e12; // 1e18 USDC/T == 1e30 DAI
        
        return usdTotal * PRECISION / wmaticTotal; 
    }
    
    //returns the current USD price of MATIC based on primary stablecoin pairs
    function getETHPrice() internal view returns (uint) {
        (uint wethReserve0, uint usdtReserve,) = IApePair(WETH_USDT_PAIR).getReserves();
        (uint usdcReserve, uint wethReserve1,) = IApePair(USDC_WETH_PAIR).getReserves();
        (uint wethReserve2, uint daiReserve,) = IApePair(WETH_DAI_PAIR).getReserves();
        uint wethTotal = wethReserve0 + wethReserve1 + wethReserve2;
        uint usdTotal = daiReserve + (usdcReserve + usdtReserve)*1e12; // 1e18 USDC/T == 1e30 DAI
        
        return usdTotal * PRECISION / wethTotal; 
    }
    
    //Calculate LP token value in USD. Generally compatible with any UniswapV2 pair but will always price underlying
    //tokens using ape prices. If the provided token is not a LP, it will attempt to price the token as a
    //standard token. This is useful for MasterChef farms which stake both single tokens and pairs
    function getRawLPPrice(address lp, uint maticPrice, uint ethPrice) internal view returns (uint) {
        
        //if not a LP, handle as a standard token
        try IApePair(lp).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
            
            address token0 = IApePair(lp).token0();
            address token1 = IApePair(lp).token1();
            uint totalSupply = IApePair(lp).totalSupply();
            
            //price0*reserve0+price1*reserve1
            uint totalValue = normalize(getRawPrice(token0, maticPrice, ethPrice), token0, DECIMALS) * reserve0 
                + normalize(getRawPrice(token1, maticPrice, ethPrice), token1, DECIMALS) * reserve1;
            
            return totalValue / totalSupply;
            
        } catch {
            return getRawPrice(lp, maticPrice, ethPrice);
        }
    }

    // checks for primary tokens and returns the correct predetermined price if possible, otherwise calculates price
    function getRawPrice(address token, uint maticPrice, uint ethPrice) internal view returns (uint rawPrice) {
        uint pegPrice = pegTokenPrice(token, maticPrice, ethPrice);
        if (pegPrice != 0) return pegPrice;

        uint numTokens;
        uint pairedValue;
        
        uint lpTokens;
        uint lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, WMATIC);
        numTokens += lpTokens;
        pairedValue += lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, WETH);
        numTokens += lpTokens;
        pairedValue += lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, DAI);
        numTokens += lpTokens;
        pairedValue += lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, USDC);
        numTokens += lpTokens;
        pairedValue += lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, USDT);
        numTokens += lpTokens;
        pairedValue += lpValue;
        
        if (numTokens > 0) return pairedValue / numTokens;
    }
    //if one of the peg tokens, returns that price, otherwise zero
    function pegTokenPrice(address token, uint maticPrice, uint ethPrice) private pure returns (uint) {
        if (token == USDT || token == USDC) return PRECISION*1e12;
        if (token == WMATIC) return maticPrice;
        if (token == WETH) return ethPrice;
        if (token == DAI) return PRECISION;
        return 0;
    }
    function pegTokenPrice(address token) private view returns (uint) {
        if (token == USDT || token == USDC) return PRECISION*1e12;
        if (token == WMATIC) return getMATICPrice();
        if (token == WETH) return getETHPrice();
        if (token == DAI) return PRECISION;
        return 0;
    }

    //returns the number of tokens and the USD value within a single LP. peg is one of the listed primary, pegPrice is the predetermined USD value of this token
    function pairTokensAndValue(address token, address peg, address factory, bytes32 initcodehash) private view returns (uint tokenNum, uint pegValue) {

        address tokenPegPair = pairFor(token, peg, factory, initcodehash);
        
        // if the address has no contract deployed, the pair doesn't exist
        uint256 size;
        assembly { size := extcodesize(tokenPegPair) }
        if (size == 0) return (0,0);
        
        try IApePair(tokenPegPair).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
            uint reservePeg;
            (tokenNum, reservePeg) = token < peg ? (reserve0, reserve1) : (reserve1, reserve0);
            pegValue = reservePeg * pegTokenPrice(peg);
        } catch {
            return (0,0);
        }

    }
    
    function pairTokensAndValueMulti(address token, address peg) private view returns (uint tokenNum, uint pegValue) {
        
        //across all AMMs in AMMData library
        for (AmmData amm = AmmData.APE; uint8(amm) < AMMData.NUM_AMMS; amm = AmmData(uint(amm) + 1)) {
            (uint tokenNumLocal, uint pegValueLocal) = pairTokensAndValue(token, peg, amm.factory(), amm.pairCodeHash());
            tokenNum += tokenNumLocal;
            pegValue += pegValueLocal;
        }
    }
    
    //normalize a token price to a specified number of decimals
    function normalize(uint price, address token, uint _decimals) private view returns (uint) {
        uint tokenDecimals;
        
        try IERC20Metadata(token).decimals() returns (uint8 dec) {
            tokenDecimals = dec;
        } catch {
            tokenDecimals = 18;
        }

        if (tokenDecimals + _decimals <= 2*DECIMALS) return price / 10**(2*DECIMALS - tokenDecimals - _decimals);
        else return price * 10**(_decimals + tokenDecimals - 2*DECIMALS);
    
    }
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB, address factory, bytes32 initcodehash) private pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                initcodehash
        )))));
    }
    
    
}