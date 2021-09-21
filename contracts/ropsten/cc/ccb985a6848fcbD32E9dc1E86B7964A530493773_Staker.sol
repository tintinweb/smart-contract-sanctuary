/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

/*                 _     _  _____ _        _        
     /\        | |   (_)/ ____| |      | |       
    /  \   _ __| |__  _| (___ | |_ __ _| | _____ 
   / /\ \ | '__| '_ \| |\___ \| __/ _` | |/ / _ \
  / ____ \| |  | |_) | |____) | || (_| |   <  __/
 /_/    \_\_|  |_.__/|_|_____/ \__\__,_|_|\_\___|
       
        Gamified High Performance Yield                        

https://arbistake.com                                                 
https://t.me/arbistake                            
https://twitter.com/arbistake                  */


pragma solidity 0.6.12;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     * // importANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library UniswapV2Library {
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
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}
}

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Uniswap{
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function WETH() external pure returns (address);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

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

contract Deployer {
    
    address payable internal _deployer;
 
    function deployer() public view returns (address) {
        return _deployer;
    }
    
    modifier onlyDeployer() {
        require(msg.sender == deployer(), "Caller is not deployer");
        _;
    }
}

contract UniswapV2AddLiquidityHelperV1 {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

        
    address internal UNIROUTER;
    address internal FACTORY;
    address internal WETHAddress;

    // Add as more ether and tokenB as possible to a Uniswap pair.
    // The ratio between ether and tokenB can be any.
    // Approve enough amount of tokenB to this contract before calling this function.
    // Uniswap pair WETH-tokenB must exist.
    // gas cost: ~320000
    function swapAndAddLiquidityEthAndToken(
        address tokenAddressB,
        uint256 amountB,
        uint256 minLiquidityOut,
        address to,
        uint256 deadline
    ) internal returns(uint liquidity) {
        require(deadline >= block.timestamp, 'EXPIRED');

        uint amountA = msg.value;
        address tokenAddressA = WETHAddress;

        require(amountA > 0 || amountB > 0, "amounts can not be both 0");
        // require(amountA < 2**112, "amount of ETH must be < 2**112");

        // convert ETH to WETH
        IWETH(WETHAddress).deposit{value: amountA}();
        // transfer user's tokenB to this contract
        if (amountB > 0) {
            _receiveToken(tokenAddressB, amountB);
        }

        return _swapAndAddLiquidity(
            tokenAddressA,
            tokenAddressB,
            amountA,
            uint(amountB),
            uint(minLiquidityOut),
            to
        );
    }

 function _swapAndAddLiquidity(
        address tokenAddressA,
        address tokenAddressB,
        uint amountA,
        uint amountB,
        uint minLiquidityOut,
        address to
    ) internal returns(uint liquidity) {
        (uint amountAToAdd, uint amountBToAdd) = _swapToSyncRatio(
            tokenAddressA,
            tokenAddressB,
            amountA,
            amountB
        );

        _approveTokenToRouterIfNecessary(tokenAddressA, amountAToAdd);
        _approveTokenToRouterIfNecessary(tokenAddressB, amountBToAdd);
        (, , liquidity) = Uniswap(UNIROUTER).addLiquidity(
            tokenAddressA, // address tokenA,
            tokenAddressB, // address tokenB,
            amountAToAdd, // uint amountADesired,
            amountBToAdd, // uint amountBDesired,
            1, // uint amountAMin,
            1, // uint amountBMin,
            to, // address to,
            2**256-1 // uint deadline
        );

        require(liquidity >= minLiquidityOut, "minted liquidity not enough");
        
        uint _tokenABalance = IERC20(tokenAddressA).balanceOf(address(this));
        uint _tokenBBalance = IERC20(tokenAddressB).balanceOf(address(this));
        if (_tokenABalance >0){
            IERC20(tokenAddressA).safeTransfer(msg.sender,_tokenABalance);
        }
        if (_tokenBBalance >0){
            IERC20(tokenAddressB).safeTransfer(msg.sender,_tokenBBalance);
        }
    }

     // swap tokens to make newAmountA / newAmountB ~= newReserveA / newReserveB
    function _swapToSyncRatio(
        address tokenAddressA,
        address tokenAddressB,
        uint amountA,
        uint amountB
    ) internal returns(
        uint newAmountA,
        uint newAmountB
    ) {
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(FACTORY, tokenAddressA, tokenAddressB);

        bool isSwitched = false;
        // swap A and B s.t. amountA * reserveB >= reserveA * amountB
        if (amountA * reserveB < reserveA * amountB) {
            (tokenAddressA, tokenAddressB) = (tokenAddressB, tokenAddressA);
            (reserveA, reserveB) = (reserveB, reserveA);
            (amountA, amountB) = (amountB, amountA);
            isSwitched = true;
        }

        uint amountAToSwap = calcAmountAToSwap(reserveA, reserveB, amountA, amountB);
        require(amountAToSwap <= amountA, "bugs in calcAmountAToSwap cause amountAToSwap > amountA");
        if (amountAToSwap > 0) {
            address[] memory path = new address[](2);
            path[0] = tokenAddressA;
            path[1] = tokenAddressB;

            _approveTokenToRouterIfNecessary(tokenAddressA, amountAToSwap);
            uint[] memory swapOutAmounts = Uniswap(UNIROUTER).swapExactTokensForTokens(
                amountAToSwap, // uint amountIn,
                1, // uint amountOutMin,
                path, // address[] calldata path,
                address(this), // address to,
                2**256-1 // uint deadline
            );

            amountA -= amountAToSwap;
            amountB += swapOutAmounts[swapOutAmounts.length - 1];
        }

        return isSwitched ? (amountB, amountA) : (amountA, amountB);
    }

    function calcAmountAToSwap(
        uint reserveA,
        uint reserveB,
        uint amountA,
        uint amountB
    ) internal pure returns(
        uint amountAToSwap
    ) {
        require(reserveA > 0 && reserveB > 0, "reserves can't be empty");
        require(reserveA < 2**112 && reserveB < 2**112, "reserves must be < 2**112");
        require(amountA < 2**112 && amountB < 2**112, "amounts must be < 2**112");
        require(amountA * reserveB >= reserveA * amountB, "require amountA / amountB >= reserveA / reserveB");

        return ((Math.sqrt(reserveA) * Math.sqrt(reserveA * (3988009 * reserveB + 9 * amountB) + 3988000 * reserveB * amountA) / Math.sqrt(reserveB + amountB)).sub(1997 * reserveA)) / 1994;
    }

    function _approveTokenToRouterIfNecessary(address tokenAddress, uint amount) internal {
        uint currentAllowance = IERC20(tokenAddress).allowance(address(this), UNIROUTER);
        if (currentAllowance < amount) {
            IERC20(tokenAddress).safeIncreaseAllowance(UNIROUTER, 2**256 - 1 - currentAllowance);
        }
    }
    
    function _receiveToken(address tokenAddress, uint amount) internal {
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
    }
}

contract Staker is Deployer, UniswapV2AddLiquidityHelperV1 {
    
    using SafeMath for uint256;
    
    constructor (address router, address factory, address wethAddress, address payable FeeWallet) public {
        UNIROUTER = router;
        FACTORY = factory;
        _deployer = msg.sender;
        feeWallet = FeeWallet;
        WETHAddress = wethAddress;

    }

    
    uint constant internal DECIMAL = 10**18;
    uint constant internal INF = 33136721748;

    uint private _ETHRewardValue = 10**21;
    uint private _tokenRewardValue = 3*10**20; //30% of lp staking

    uint public LockedLP;
    
    mapping (address => uint256) public  timePooled1;
    mapping (address => uint256) public  timePooled2; //second time counter for Token Staking
    mapping (address => uint256) private internalTime1;
    mapping (address => uint256) private internalTime2; //second time counter for Token Staking
    mapping (address => uint256) private LPTokenBalance;
    mapping (address => uint256) private LockedLPTokenBalance;
    mapping (address => uint256) private rewardsFromETH;
    mapping (address => uint256) private rewardsFromToken;

    address public arbiStakeAddress;
    address payable private feeWallet;

    bool private _unchangeable = false;
    bool private _tokenAddressGiven = false;
    bool public priceCapped = true;
    
    receive() external payable {
        
       if(msg.sender != UNIROUTER){
           stake();
       }
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{ value: amount }(""); 
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    //If true, no changes can be made
    function unchangeable() public view returns (bool){
        return _unchangeable;
    }
    
    function rewardValue() public view returns (uint){
        return _ETHRewardValue;
    }

    function rewardValue2() public view returns (uint){
        return _tokenRewardValue;
    }

    
    //THE ONLY ADMIN FUNCTIONS vvvv
    //After this is called, no changes can be made
    function makeUnchangeable() public onlyDeployer{
        _unchangeable = true;
    }
    
    //Can only be called once to set token address
    function setTokenAddress(address input) public onlyDeployer{
        require(!_tokenAddressGiven, "Function was already called");
        _tokenAddressGiven = true;
        arbiStakeAddress = input;
    }
    
    //Set reward value that has high APY, can't be called if makeUnchangeable() was called
    function updateETHRewardValue(uint input) public onlyDeployer {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        _ETHRewardValue = input;
    }

    function updateTokenRewardValue(uint input) public onlyDeployer {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        _tokenRewardValue = input;
    }

    //Cap token price at 1 eth, can't be called if makeUnchangeable() was called
    function capPrice(bool input) public onlyDeployer {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        priceCapped = input;
    }
    //THE ONLY ADMIN FUNCTIONS ^^^^
    
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
  
    function stake() public payable{
        address staker = msg.sender;
        
        address poolAddress = Uniswap(FACTORY).getPair(arbiStakeAddress, WETHAddress);
        
        if(price() >= (1.05 * 10**18) && priceCapped){
           
            uint t = IERC20(arbiStakeAddress).balanceOf(poolAddress); //token in uniswap
            uint a = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
            uint x = (sqrt(9*t*t + 3988000*a*t) - 1997*t)/1994;
            
            IERC20(arbiStakeAddress).mint(address(this), x);
            
            address[] memory path = new address[](2);
            path[0] = arbiStakeAddress;
            path[1] = WETHAddress;
            IERC20(arbiStakeAddress).approve(UNIROUTER, x);
            Uniswap(UNIROUTER).swapExactTokensForETH(x, 1, path, feeWallet, INF);
        }
        
        sendValue(feeWallet, address(this).balance/2);
        
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint tokenAmount = IERC20(arbiStakeAddress).balanceOf(poolAddress); //token in uniswap
      
        uint toMint = (address(this).balance.mul(tokenAmount)).div(ethAmount);
        IERC20(arbiStakeAddress).mint(address(this), toMint);
        
        uint poolTokenAmountBefore = IERC20(poolAddress).balanceOf(address(this));
        
        uint amountTokenDesired = IERC20(arbiStakeAddress).balanceOf(address(this));
        IERC20(arbiStakeAddress).approve(UNIROUTER, amountTokenDesired ); //allow pool to get tokens
        Uniswap(UNIROUTER).addLiquidityETH{ value: address(this).balance }(arbiStakeAddress, amountTokenDesired, 1, 1, address(this), INF);
        
        uint poolTokenAmountAfter = IERC20(poolAddress).balanceOf(address(this));
        uint poolTokenGot = poolTokenAmountAfter.sub(poolTokenAmountBefore);
        
        rewardsFromETH[staker] = rewardsFromETH[staker].add(viewRecentRewardTokenAmountFromETH(staker));
        timePooled1[staker] = now;
        internalTime1[staker] = now;
        LPTokenBalance[staker] = LPTokenBalance[staker].add(poolTokenGot);
    }

    function stakeToken(uint256 amount) public {
        address staker = msg.sender;
        address poolAddress = Uniswap(FACTORY).getPair(arbiStakeAddress, WETHAddress);
        

        uint poolTokenAmountBefore = IERC20(poolAddress).balanceOf(address(this));
        swapAndAddLiquidityEthAndToken(arbiStakeAddress, amount, 1, address(this), INF);
        uint poolTokenAmountAfter = IERC20(poolAddress).balanceOf(address(this));
        uint poolTokenGot = poolTokenAmountAfter.sub(poolTokenAmountBefore);

        rewardsFromToken[staker] = rewardsFromToken[staker].add(viewRecentRewardTokenAmountFromToken(staker));
        timePooled2[staker] = now;
        internalTime2[staker] = now;
        LockedLPTokenBalance[staker] = LockedLPTokenBalance[staker].add(poolTokenGot);
        LockedLP = LockedLP.add(poolTokenGot); // keep track of total locked LPs to calculate token yield
        
        IERC20(poolAddress).transfer(0x0000000000000000000000000000000000000000, poolTokenGot); // permanently locks the token lp
    }

    function withdrawLPTokens() public {
        require(timePooled1[msg.sender] + 1 days <= now, "It has not been 1 day since you staked yet");
        
        rewardsFromETH[msg.sender] = rewardsFromETH[msg.sender].add(viewRecentRewardTokenAmountFromETH(msg.sender));
        uint256 withdrawAmount = LPTokenBalance[msg.sender];
        LPTokenBalance[msg.sender] = 0;
        internalTime1[msg.sender] = now;
         
        address poolAddress = Uniswap(FACTORY).getPair(arbiStakeAddress, WETHAddress);
        IERC20(poolAddress).transfer(msg.sender, withdrawAmount);
        
    }
    
    function withdrawRewardTokensFromStakingETH() public {
        require(timePooled1[msg.sender] + 1 days <= now, "It has not been 1 day since you staked yet");
        
        rewardsFromETH[msg.sender] = rewardsFromETH[msg.sender].add(viewRecentRewardTokenAmountFromETH(msg.sender));
        internalTime1[msg.sender] = now;
        
        uint rewardAmount = earnCalc(rewardsFromETH[msg.sender]);
        rewardsFromETH[msg.sender] = 0;
       
        IERC20(arbiStakeAddress).mint(msg.sender, rewardAmount);
    }

    function withdrawRewardTokensFromStakingToken() public {
        require(timePooled2[msg.sender] + 1 days <= now, "It has not been 1 day since you staked yet");
        
        rewardsFromToken[msg.sender] = rewardsFromToken[msg.sender].add(viewRecentRewardTokenAmountFromToken(msg.sender));
        internalTime2[msg.sender] = now;
        
        uint rewardAmount = earnCalc2(rewardsFromToken[msg.sender]);
        rewardsFromToken[msg.sender] = 0;
       
        IERC20(arbiStakeAddress).mint(msg.sender, rewardAmount);
    }
    
    function viewRecentRewardTokenAmountFromETH(address who) internal view returns (uint){
        return (viewLPTokenAmount(who).mul( now.sub(internalTime1[who]) ));
    }

    function viewRecentRewardTokenAmountFromToken(address who) internal view returns (uint){
        return (viewLockedLPTokenAmount(who).mul( now.sub(internalTime2[who]) ));
    }
    
    function viewRewardTokenAmountFromETH(address who) public view returns (uint){
        return earnCalc( rewardsFromETH[who].add(viewRecentRewardTokenAmountFromETH(who)) );
    }

    function viewRewardTokenAmountFromToken(address who) public view returns (uint) {
        return earnCalc2( rewardsFromToken[who].add(viewRecentRewardTokenAmountFromToken(who)) );
    } 

    
    function viewLPTokenAmount(address who) public view returns (uint){
        return LPTokenBalance[who];
    }
    
    function viewLockedLPTokenAmount(address who) public view returns (uint){
        return LockedLPTokenBalance[who];
    }

    function viewPooledEthAmount(address who) public view returns (uint){
      
        address poolAddress = Uniswap(FACTORY).getPair(arbiStakeAddress, WETHAddress);
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        
        return (ethAmount.mul(viewLPTokenAmount(who))).div(IERC20(poolAddress).totalSupply());
    }
    
    function viewPooledTokenAmount(address who) public view returns (uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(arbiStakeAddress, WETHAddress);
        uint tokenAmount = IERC20(arbiStakeAddress).balanceOf(poolAddress); //token in uniswap
        
        return (tokenAmount.mul(viewLPTokenAmount(who))).div(IERC20(poolAddress).totalSupply());
    }
    
    function price() public view returns (uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(arbiStakeAddress, WETHAddress);
        
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint tokenAmount = IERC20(arbiStakeAddress).balanceOf(poolAddress); //token in uniswap
        
        return (DECIMAL.mul(ethAmount)).div(tokenAmount);
    }
    
    function ethEarnCalc(uint eth, uint time) public view returns(uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(arbiStakeAddress, WETHAddress);
        uint totalEth = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint totalLP = IERC20(poolAddress).totalSupply();
        
        uint LP = ((eth/2)*totalLP)/totalEth;
        
        return earnCalc(LP * time);
    }

    function tokenEarnCalc(uint token, uint time) public view returns(uint) {
        address poolAddress = Uniswap(FACTORY).getPair(arbiStakeAddress, WETHAddress);
        uint totalLP = IERC20(poolAddress).totalSupply();
        uint fracToken = IERC20(arbiStakeAddress).balanceOf(poolAddress).mul(LockedLP).div(totalLP); //Total token value of the locked LPs
        
        uint LP = ((token/2)*LockedLP)/fracToken;
        
        return earnCalc2(LP * time);
    }

    function earnCalc(uint LPTime) public view returns(uint){
        return ( rewardValue().mul(LPTime)  ) / ( 31557600 * DECIMAL );
    }

    function earnCalc2(uint LPTime) public view returns(uint){
        return ( rewardValue2().mul(LPTime)  ) / ( 31557600 * DECIMAL );
    }

}