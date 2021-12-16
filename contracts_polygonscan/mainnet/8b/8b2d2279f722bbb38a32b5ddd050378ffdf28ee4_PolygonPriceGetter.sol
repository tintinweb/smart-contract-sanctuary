/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: _PRICE_GETTER/pricegetter/contracts/BasePriceGetter.sol


pragma solidity ^0.8.4;




abstract contract BasePriceGetter is Ownable {
    
    function getGasPrice() internal virtual view returns (uint);
    function getETHPrice() internal virtual view returns (uint);

    address immutable WNATIVE;
    address immutable USDT;
    address immutable USDC;
    address immutable WETH;
    address immutable DAI;

    address public datafile;

    //Returned prices calculated with this precision (18 decimals)
    uint public constant DECIMALS = 18;
    uint constant PRECISION = 1e18; //1e18 == $1
    
    event SetDatafile(address data);

    constructor(address _data, address _wnative, address _weth, address _usdt, address _usdc, address _dai) {
        datafile = _data;

        WNATIVE = _wnative;
        USDT = _usdt;
        USDC = _usdc;
        WETH = _weth;
        DAI = _dai;
    }

    function setData(address _data) external onlyOwner {
        datafile = _data;
        emit SetDatafile(_data);
    }

    // Normalized to specified number of decimals based on token's decimals and
    // specified number of decimals
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
        
        return getRawPrice(token, getGasPrice(), getETHPrice());
    }


    //returns the value of a LP token if it is one, or the regular price if it isn't LP
    function getRawLPPrice(address token) internal view returns (uint) {
        uint pegPrice = pegTokenPrice(token);
        if (pegPrice != 0) return pegPrice;
        
        return getRawLPPrice(token, getGasPrice(), getETHPrice());
    }
    //returns the prices of multiple tokens which may or may not be LPs
    function getRawLPPrices(address[] calldata tokens) internal view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        uint gasPrice = getGasPrice();
        uint ethPrice = getETHPrice();
        
        for (uint i; i < prices.length; i++) {
            address token = tokens[i];
            
            uint pegPrice = pegTokenPrice(token, gasPrice, ethPrice);
            if (pegPrice != 0) prices[i] = pegPrice;
            else prices[i] = getRawLPPrice(token, gasPrice, ethPrice);
        }
    }

        //normalize a token price to a specified number of decimals
    function normalize(uint price, address token, uint _decimals) internal view returns (uint) {
        uint tokenDecimals;
        
        try IERC20Metadata(token).decimals() returns (uint8 dec) {
            tokenDecimals = dec;
        } catch {
            tokenDecimals = 18;
        }

        if (tokenDecimals + _decimals <= 2*DECIMALS) return price / 10**(2*DECIMALS - tokenDecimals - _decimals);
        else return price * 10**(_decimals + tokenDecimals - 2*DECIMALS);
    
    }

    //returns the prices of multiple tokens, zero on failure
    function getRawPrices(address[] calldata tokens) public view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        uint gasPrice = getGasPrice();
        uint ethPrice = getETHPrice();
        
        for (uint i; i < prices.length; i++) {
            address token = tokens[i];
            
            uint pegPrice = pegTokenPrice(token, gasPrice, ethPrice);
            if (pegPrice != 0) prices[i] = pegPrice;
            else prices[i] = getRawPrice(token, gasPrice, ethPrice);
        }
    }

    //if one of the peg tokens, returns that price, otherwise zero
    function pegTokenPrice(address token, uint gasPrice, uint ethPrice) internal virtual view returns (uint) {
        if (token == USDT || token == USDC) return PRECISION*1e12;
        if (token == WNATIVE) return gasPrice;
        if (token == WETH) return ethPrice;
        if (token == DAI) return PRECISION;
        return 0;
    }
    function pegTokenPrice(address token) internal virtual view returns (uint) {
        if (token == USDT || token == USDC) return PRECISION*1e12;
        if (token == WNATIVE) return getGasPrice();
        if (token == WETH) return getETHPrice();
        if (token == DAI) return PRECISION;
        return 0;
    }

    // checks for primary tokens and returns the correct predetermined price if possible, otherwise calculates price
    function getRawPrice(address token, uint gasPrice, uint ethPrice) internal view returns (uint rawPrice) {
        uint pegPrice = pegTokenPrice(token, gasPrice, ethPrice);
        if (pegPrice != 0) return pegPrice;

        uint numTokens;
        uint pairedValue;
        
        uint lpTokens;
        uint lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, WNATIVE);
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

    //returns the number of tokens and the USD value within a single LP. peg is one of the listed primary, pegPrice is the predetermined USD value of this token
    function pairTokensAndValue(address token, address peg, address factory, bytes32 initcodehash) internal view returns (uint tokenNum, uint pegValue) {

        address tokenPegPair = pairFor(token, peg, factory, initcodehash);
        
        // if the address has no contract deployed, the pair doesn't exist
        uint256 size;
        assembly { size := extcodesize(tokenPegPair) }
        if (size == 0) return (0,0);
        
        try IUniPair(tokenPegPair).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
            uint reservePeg;
            (tokenNum, reservePeg) = token < peg ? (reserve0, reserve1) : (reserve1, reserve0);
            pegValue = reservePeg * pegTokenPrice(peg);
        } catch {
            return (0,0);
        }

    }

    function pairTokensAndValueMulti(address token, address peg) private view returns (uint tokenNum, uint pegValue) {
        
        AmmInfo[] memory amms = IAMMInfo(datafile).getAmmList();
        //across all AMMs in AMMData library
        for (uint i; i < amms.length; i++) {
            (uint tokenNumLocal, uint pegValueLocal) = pairTokensAndValue(token, peg, amms[i].factory, amms[i].paircodehash);
            tokenNum += tokenNumLocal;
            pegValue += pegValueLocal;
        }
    }

    //Calculate LP token value in USD. Generally compatible with any UniswapV2 pair but will always price underlying
    //tokens using Crodex prices. If the provided token is not a LP, it will attempt to price the token as a
    //standard token. This is useful for MasterChef farms which stake both single tokens and pairs
    function getRawLPPrice(address lp, uint gasPrice, uint ethPrice) internal view returns (uint) {
        
        //if not a LP, handle as a standard token
        try IUniPair(lp).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
            
            address token0 = IUniPair(lp).token0();
            address token1 = IUniPair(lp).token1();
            uint totalSupply = IUniPair(lp).totalSupply();
            
            //price0*reserve0+price1*reserve1
            uint totalValue = getRawPrice(token0, gasPrice, ethPrice) * reserve0 
                + getRawPrice(token1, gasPrice, ethPrice) * reserve1;
            
            return totalValue / totalSupply;
            
        } catch {
            return getRawPrice(lp, gasPrice, ethPrice);
        }
    }

}
// File: _PRICE_GETTER/pricegetter/contracts/libs/IUniPair.sol



pragma solidity >=0.6.12;

interface IUniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
    function factory() external view returns (address);
}
// File: _PRICE_GETTER/pricegetter/contracts/libs/IUniRouter.sol


pragma solidity ^0.8.4;

interface IUniRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniRouter02 is IUniRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
interface IUniFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: _PRICE_GETTER/pricegetter/contracts/libs/IAMMInfo.sol


pragma solidity ^0.8.4;

/*
Join us at Crystl.Finance!
█▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/



// calculates the CREATE2 address for a pair without making any external calls
function pairFor(address tokenA, address tokenB, address factory, bytes32 initcodehash) pure returns (address pair) {
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    pair = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            initcodehash
    )))));
}

struct AmmInfo {
    string name;
    address router;
    address factory;
    uint8 fee;
    bytes32 paircodehash;
}

interface IAMMInfo {

    function getAmmList() external pure returns (AmmInfo[] memory list);

}
// File: _PRICE_GETTER/pricegetter/contracts/PolygonPriceGetter.sol


pragma solidity ^0.8.6;



// This library provides simple price calculations for ApeSwap tokens, accounting
// for commonly used pairings. Will break if USDT, BUSD, or DAI goes far off peg.
// Should NOT be used as the sole oracle for sensitive calculations such as 
// liquidation, as it is vulnerable to manipulation by flash loans, etc. BETA
// SOFTWARE, PROVIDED AS IS WITH NO WARRANTIES WHATSOEVER.

// Polygon mainnet version

contract PolygonPriceGetter is BasePriceGetter {

    //Ape LP addresses
    address private constant WMATIC_USDT_PAIR = 0x65D43B64E3B31965Cd5EA367D4c2b94c03084797;
    address private constant WMATIC_DAI_PAIR = 0x84964d9f9480a1dB644c2B2D1022765179A40F68;
    address private constant WMATIC_USDC_PAIR = 0x019011032a7ac3A87eE885B6c08467AC46ad11CD;
    
    address private constant WETH_USDT_PAIR = 0x7B2dD4bab4487a303F716070B192543eA171d3B2;
    address private constant USDC_WETH_PAIR = 0x84964d9f9480a1dB644c2B2D1022765179A40F68;
    address private constant WETH_DAI_PAIR = 0xb724E5C1Aef93e972e2d4b43105521575f4ca855;

    constructor(address _data) BasePriceGetter(
        _data,
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, //wnative
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, //weth
        0xc2132D05D31c914a87C6611C10748AEb04B58e8F, //usdt
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, //usdc
        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063 //dai
    ) {}

    //returns the current USD price of MATIC based on primary stablecoin pairs
    function getGasPrice() internal override view returns (uint) {
        (uint wmaticReserve0, uint usdtReserve,) = IUniPair(WMATIC_USDT_PAIR).getReserves();
        (uint wmaticReserve1, uint daiReserve,) = IUniPair(WMATIC_DAI_PAIR).getReserves();
        (uint wmaticReserve2, uint usdcReserve,) = IUniPair(WMATIC_USDC_PAIR).getReserves();
        uint wmaticTotal = wmaticReserve0 + wmaticReserve1 + wmaticReserve2;
        uint usdTotal = daiReserve + (usdcReserve + usdtReserve)*1e12; // 1e18 USDC/T == 1e30 DAI
        
        return usdTotal * PRECISION / wmaticTotal; 
    }
    
    //returns the current USD price of MATIC based on primary stablecoin pairs
    function getETHPrice() internal override view returns (uint) {
        (uint wethReserve0, uint usdtReserve,) = IUniPair(WETH_USDT_PAIR).getReserves();
        (uint usdcReserve, uint wethReserve1,) = IUniPair(USDC_WETH_PAIR).getReserves();
        (uint wethReserve2, uint daiReserve,) = IUniPair(WETH_DAI_PAIR).getReserves();
        uint wethTotal = wethReserve0 + wethReserve1 + wethReserve2;
        uint usdTotal = daiReserve + (usdcReserve + usdtReserve)*1e12; // 1e18 USDC/T == 1e30 DAI
        
        return usdTotal * PRECISION / wethTotal; 
    }
    
}