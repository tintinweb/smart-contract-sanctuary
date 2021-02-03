/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender) + value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender) - value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ISushiswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;
}

interface IComptroller {
    function enterMarkets(address[] memory cTokens) external;
    function getAllMarkets() external view returns (address[] memory);
}

interface cyToken {
    function borrow(uint) external;
    function mint(uint) external;
    function redeem(uint) external;
    function redeemUnderlying(uint) external;
    function repayBorrow(uint) external;
    function underlying() external view returns (address);
}

contract xVault {
    using SafeERC20 for IERC20;
    
    address owner;
    
    IComptroller constant COMPTROLLER = IComptroller(0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258);
    address constant FACTORY = address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                FACTORY,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            )))));
    }
    
    function enterMarkets() public {
        COMPTROLLER.enterMarkets(COMPTROLLER.getAllMarkets());
    }
    
    function approveMarkets() public {
        address[] memory _markets = COMPTROLLER.getAllMarkets();
        for (uint i = 0; i < _markets.length; i++) {
            address _underlying = cyToken(_markets[i]).underlying();
            IERC20(_underlying).safeApprove(_markets[i], uint(-1));
        }
    }
    
    constructor() {
        owner = msg.sender;
        enterMarkets();
        //approveMarkets();
    }
    
    function withdraw(address token, uint amount) external {
        require(owner == msg.sender);
        IERC20(token).safeTransfer(msg.sender, amount);
    }
    
    function open(address cylong, address long, uint lamt, address cyshort, address short, uint samt, address cymargin, uint mamt) external {
        require(owner == msg.sender);
        IERC20(cymargin).safeTransferFrom(msg.sender, address(this), mamt);
        _borrow(cylong, long, lamt, cyshort, short, samt);
    }
    
    function close(address cyrepay, address repay, uint ramt, address cywithdraw, address uwithdraw, uint wamt) external {
        require(owner == msg.sender);
        address tokenB = repay == WETH ? uwithdraw : WETH;
        ISushiswapV2Pair _pairFrom = ISushiswapV2Pair(pairFor(repay, tokenB));
        (uint amount0, uint amount1) = repay < tokenB ? (ramt, uint(0)) : (uint(0), ramt);
        _pairFrom.swap(amount0, amount1, address(this), abi.encode(cyrepay, repay, ramt, address(_pairFrom), cywithdraw, uwithdraw, wamt, false));
    }
    
    function _borrow(address cylong, address long, uint lamt, address cyshort, address short, uint samt) internal {
        (uint amount0, uint amount1) = long < WETH ? (lamt, uint(0)) : (uint(0), lamt);
        address tokenB = long == WETH ? short : WETH;
        ISushiswapV2Pair _pairFrom = ISushiswapV2Pair(pairFor(long, tokenB));
        _pairFrom.swap(amount0, amount1, address(this), abi.encode(cylong, long, lamt, address(_pairFrom), cyshort, short, samt, true));
    }
    
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        require(sender == address(this));
        (address _cylong, address _long, uint _lamt, address _pairFrom, address _cyshort, address _short, uint _samt, bool _pos) = abi.decode(data, (address, address, uint, address, address, address, uint, bool));
        if (_pos) {
            _open(_cylong, _lamt, _pairFrom, amount0, _short, _long, _samt, _cyshort);
        } else {
            _close(_cylong, _lamt, _pairFrom, amount0, _short, _long, _samt, _cyshort);
        }
    }
    
    function _close(address _cyrepay, uint _ramt, address _pairFrom, uint _amount0, address _withdraw, address _repay, uint _wamt, address _cywithdraw) internal {
        IERC20(_repay).safeApprove(_cyrepay, 0);
        IERC20(_repay).safeApprove(_cyrepay, uint(-1));
        cyToken(_cyrepay).repayBorrow(_ramt);
        
        (uint reserve0, uint reserve1,) = ISushiswapV2Pair(_pairFrom).getReserves();
        (uint reserveIn, uint reserveOut) = _amount0 > 0 ? (reserve1, reserve0) : (reserve0, reserve1);
        
        uint _minRepay = _getAmountIn(_ramt, reserveIn, reserveOut);
        
        if (_withdraw == WETH || _repay == WETH) {
            require(_minRepay <= _wamt);
            cyToken(_cywithdraw).redeemUnderlying(_minRepay);
            IERC20(_withdraw).safeTransfer(address(_pairFrom), _minRepay);
        } else {
            _crossClose(_withdraw, _minRepay, _wamt, _cywithdraw, address(_pairFrom));
        }
    }
    
    function _open(address _cylong, uint _lamt, address _pairFrom, uint _amount0, address _short, address _long, uint _samt, address _cyshort) internal {
        IERC20(_long).safeApprove(_cylong, 0);
        IERC20(_long).safeApprove(_cylong, uint(-1));
        cyToken(_cylong).mint(_lamt);
        
        (uint reserve0, uint reserve1,) = ISushiswapV2Pair(_pairFrom).getReserves();
        (uint reserveIn, uint reserveOut) = _amount0 > 0 ? (reserve1, reserve0) : (reserve0, reserve1);
        
        uint _minRepay = _getAmountIn(_lamt, reserveIn, reserveOut);
        
        if (_short == WETH || _long == WETH) {
            require(_minRepay <= _samt);
            cyToken(_cyshort).borrow(_minRepay);
            IERC20(_short).safeTransfer(address(_pairFrom), _minRepay);
        } else {
            _cross(_short, _minRepay, _samt, _cyshort, address(_pairFrom));
        }
    }
    
    function _getShortFall(address _short, ISushiswapV2Pair _pairTo, uint _minWETHRepay) internal view returns (address, uint) {
        (address token0,) = _short < WETH ? (_short, WETH) : (WETH, _short);
        (uint reserve0, uint reserve1,) = _pairTo.getReserves();
        (uint reserveIn, uint reserveOut) = token0 == _short ? (reserve0, reserve1) : (reserve1, reserve0);
        return (token0, _getAmountIn(_minWETHRepay, reserveIn, reserveOut));
    }
    
    function _cross(address _short, uint _minWETHRepay, uint _samt, address _cyshort, address _pairFrom) internal {
        ISushiswapV2Pair _pairTo = ISushiswapV2Pair(pairFor(_short, WETH));
        (address token0, uint _shortPay) = _getShortFall(_short, _pairTo, _minWETHRepay);
        require(_shortPay <= _samt);
        cyToken(_cyshort).borrow(_shortPay);
        (uint amount0, uint amount1) = token0 == _short ? (uint(0), _minWETHRepay) : (_minWETHRepay, uint(0));
        IERC20(_short).safeTransfer(address(_pairTo), _shortPay);
        _pairTo.swap(amount0, amount1, _pairFrom, new bytes(0));
    }
    
    function _crossClose(address _withdraw, uint _minWETHRepay, uint _wamt, address _cywithdraw, address _pairFrom) internal {
        ISushiswapV2Pair _pairTo = ISushiswapV2Pair(pairFor(_withdraw, WETH));
        (address token0, uint _shortPay) = _getShortFall(_withdraw, _pairTo, _minWETHRepay);
        require(_shortPay <= _wamt);
        cyToken(_cywithdraw).redeemUnderlying(_shortPay);
        (uint amount0, uint amount1) = token0 == _withdraw ? (uint(0), _minWETHRepay) : (_minWETHRepay, uint(0));
        IERC20(_withdraw).safeTransfer(address(_pairTo), _shortPay);
        _pairTo.swap(amount0, amount1, _pairFrom, new bytes(0));
    }
    
    function execute(address to, uint value, bytes calldata data) external returns (bool, bytes memory) {
        require(owner == msg.sender);
        (bool success, bytes memory result) = to.call{value:value}(data);
        
        return (success, result);
    }

    function _getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }
    
    
}