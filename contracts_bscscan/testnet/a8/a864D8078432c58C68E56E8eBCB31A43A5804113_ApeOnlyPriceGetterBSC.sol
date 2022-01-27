/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


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

// File: polycrystal-on-chain-stats/contracts/interfaces/IApePair.sol

//SPDX-License-Identifier: GPL v3.0

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
// File: polycrystal-on-chain-stats/contracts/libraries/ApeOnlyPriceGetterBSC.sol



pragma solidity ^0.8.6;



// This library provides simple price calculations for ApeSwap tokens, accounting

// for commonly used pairings. Will break if USDT, BUSD, or DAI goes far off peg.

// Should NOT be used as the sole oracle for sensitive calculations such as 

// liquidation, as it is vulnerable to manipulation by flash loans, etc. BETA

// SOFTWARE, PROVIDED AS IS WITH NO WARRANTIES WHATSOEVER.



// BSC ApeSwap only version



//import "./AMMData.sol";





library ApeOnlyPriceGetterBSC {

//    using AMMData for AmmData;

    

    address public constant FACTORY = 0x627cD259eD93CE73CfB86a2a58CBc861f999D2B7; //ApeFactory

    bytes32 public constant INITCODEHASH = hex'198c20ba5ff63060d9c8d1e64058565b03aae4afda4954355fe5bf0d647bed6b'; // for pairs created by ApeFactory

    

    //All returned prices calculated with this precision (18 decimals)

    uint private constant PRECISION = 10**DECIMALS; //1e18 == $1

    uint public constant DECIMALS = 18;

    

    //Token addresses

    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    address constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;

    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;

    

    //Token value constants

    uint private constant BUSD_RAW_PRICE = 1e18;

    

    //Ape LP addresses

    address constant BUSD_WBNB_PAIR = 0x51e6D27FA57373d8d4C256231241053a70Cb1d93; // busd is token1

    address constant DAI_WBNB_PAIR = 0xf3010261B58B2874639Ca2e860E9005E3Be5DE0b;  // dai is token0

    address constant USDT_WBNB_PAIR = 0x20bCC3b8a0091dDac2d0BC30F68E6CBb97de59Cd; // usdt is token0



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

    function getRawPrice(address token) public view returns (uint) {

        uint pegPrice = pegTokenPrice(token);

        if (pegPrice != 0) return pegPrice;

        

        return getRawPrice(token, getBNBPrice());

    }

    

    //returns the prices of multiple tokens, zero on failure

    function getRawPrices(address[] calldata tokens) public view returns (uint[] memory prices) {

        prices = new uint[](tokens.length);

        uint bnbPrice = getBNBPrice();

        

        for (uint i; i < prices.length; i++) {

            address token = tokens[i];

            

            uint pegPrice = pegTokenPrice(token, bnbPrice);

            if (pegPrice != 0) prices[i] = pegPrice;

            else prices[i] = getRawPrice(token, bnbPrice);

        }

    }

    

    //returns the value of a LP token if it is one, or the regular price if it isn't LP

    function getRawLPPrice(address token) internal view returns (uint) {

        uint pegPrice = pegTokenPrice(token);

        if (pegPrice != 0) return pegPrice;

        

        return getRawLPPrice(token, getBNBPrice());

    }

    //returns the prices of multiple tokens which may or may not be LPs

    function getRawLPPrices(address[] calldata tokens) internal view returns (uint[] memory prices) {

        prices = new uint[](tokens.length);

        uint bnbPrice = getBNBPrice();

        

        for (uint i; i < prices.length; i++) {

            address token = tokens[i];

            

            uint pegPrice = pegTokenPrice(token, bnbPrice);

            if (pegPrice != 0) prices[i] = pegPrice;

            else prices[i] = getRawLPPrice(token, bnbPrice);

        }

    }

    //returns the current USD price of BNB based on primary stablecoin pairs

    function getBNBPrice() public view returns (uint) {

        (uint daiReserve, uint wbnbReserve0,) = IApePair(DAI_WBNB_PAIR).getReserves();

        (uint wbnbReserve1, uint busdReserve,) = IApePair(BUSD_WBNB_PAIR).getReserves();

        (uint usdtReserve, uint wbnbReserve2,) = IApePair(USDT_WBNB_PAIR).getReserves();

        uint wbnbTotal = wbnbReserve0 + wbnbReserve1 + wbnbReserve2;

        uint usdTotal = daiReserve + busdReserve + usdtReserve;

        

        return usdTotal * PRECISION / wbnbTotal; 

    }

    

    //Calculate LP token value in USD. Generally compatible with any UniswapV2 pair but will always price underlying

    //tokens using ape prices. If the provided token is not a LP, it will attempt to price the token as a

    //standard token. This is useful for MasterChef farms which stake both single tokens and pairs

    function getRawLPPrice(address lp, uint bnbPrice) internal view returns (uint) {

        

        //if not a LP, handle as a standard token

        try IApePair(lp).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {

            

            address token0 = IApePair(lp).token0();

            address token1 = IApePair(lp).token1();

            uint totalSupply = IApePair(lp).totalSupply();

            

            //price0*reserve0+price1*reserve1

            uint totalValue = getRawPrice(token0, bnbPrice) * reserve0 

                + getRawPrice(token1, bnbPrice) * reserve1;

            

            return totalValue / totalSupply;

            

        } catch {

            return getRawPrice(lp, bnbPrice);

        }

    }



    // checks for primary tokens and returns the correct predetermined price if possible, otherwise calculates price

    function getRawPrice(address token, uint bnbPrice) internal view returns (uint rawPrice) {

        uint pegPrice = pegTokenPrice(token, bnbPrice);

        if (pegPrice != 0) return pegPrice;



        uint numTokens;

        uint pairedValue;

        

        uint lpTokens;

        uint lpValue;

        

        (lpTokens, lpValue) = pairTokensAndValue(token, WBNB);

        numTokens += lpTokens;

        pairedValue += lpValue;

        

        (lpTokens, lpValue) = pairTokensAndValue(token, DAI);

        numTokens += lpTokens;

        pairedValue += lpValue;

        

        (lpTokens, lpValue) = pairTokensAndValue(token, BUSD);

        numTokens += lpTokens;

        pairedValue += lpValue;

        

        (lpTokens, lpValue) = pairTokensAndValue(token, USDT);

        numTokens += lpTokens;

        pairedValue += lpValue;

        

        if (numTokens > 0) return pairedValue / numTokens;

    }

    //if one of the peg tokens, returns that price, otherwise zero

    function pegTokenPrice(address token, uint bnbPrice) private pure returns (uint) {

        if (token == USDT || token == BUSD || token == DAI) return PRECISION;

        if (token == WBNB) return bnbPrice;

        return 0;

    }

    function pegTokenPrice(address token) private view returns (uint) {

        if (token == USDT || token == BUSD || token == DAI) return PRECISION;

        if (token == WBNB) return getBNBPrice();

        return 0;

    }



    //returns the number of tokens and the USD value within a single LP. peg is one of the listed primary, pegPrice is the predetermined USD value of this token

    function pairTokensAndValue(address token, address peg) private view returns (uint tokenNum, uint pegValue) {



        address tokenPegPair = pairFor(token, peg);

        

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

    function pairFor(address tokenA, address tokenB) private pure returns (address pair) {

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        pair = address(uint160(uint(keccak256(abi.encodePacked(

                hex'ff',

                FACTORY,

                keccak256(abi.encodePacked(token0, token1)),

                INITCODEHASH

        )))));

    }

    

    

}