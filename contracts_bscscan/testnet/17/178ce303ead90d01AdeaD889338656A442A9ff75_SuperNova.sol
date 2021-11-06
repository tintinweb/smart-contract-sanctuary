// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

library Address {

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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface IUniswapV2Factory {
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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;




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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;
import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./OwnableUpgradeable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract SuperNova is OwnableUpgradeable {
    using Address for address;
    using SafeMath for uint256;

    // nexus total supply
    uint256 private totalSupply;
    uint256 private constant maxPercent = 100;
    // burn wallet address
    address private constant _burnWallet =
        0x000000000000000000000000000000000000dEaD;
    // address of NEXUS Smart Contract
    address private _nexusAddr;

    // address of wrapped bnb
    address private _baseToken;
    // nexus liquidity pool address
    address private _nexusLP;
    // Initialize Pancakeswap Router
    IUniswapV2Router02 private uniswapV2Router;

    // 0.1 bnb
    uint256 public minumumBNBBalance;
    // 8,000
    uint256 public minumumNexusBalance;

    // 5 bnb
    uint256 public maxBNBTransaction;
    // 50,000
    uint256 public maxNexusTransaction;
    // 5%
    uint256 public maxPercentLiquidityAdjust;
    // liquidity operations
    bool public canSwapAndLiquify;
    bool public canBuyAndLiquify;
    bool public canPullLiquidity;

    /** Expressed as 100 / x */
    uint256 public pullLiquidityRange;

    uint256 public goldyLocks;

    /** Expressed as 100 / x */
    uint256 public addLiquidityRange;

    bool lockTransactions;

    address private _oracleAddress;

    event PullLiquidity(uint256 liquidity);
    event AddLiquidity(uint256 liquidity);
    event BuyBack(uint256 amountBought);
    event Liquidate(uint256 amountLiquidated);
    event UpdateOracle(address oracle);

    modifier isAutomating() {
        require(!lockTransactions, "Mid Automation!");
        _;
    }

    modifier onlyOracle() {
        require(
            owner() == _msgSender() || _oracleAddress == _msgSender(),
            "Ownable: caller is not the owner or oracle"
        );
        _;
    }

    function initialize(
        IUniswapV2Router02 router,
        address base,
        address nexus,
        address oracle
    ) public initializer {
        __Ownable_init();

        require(owner() != address(0), "Owner must be set");
        uniswapV2Router = router;
        _baseToken = base;
        _nexusAddr = nexus;
        _oracleAddress = oracle;

        uniswapV2Router = IUniswapV2Router02(router);

        _nexusLP = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            _nexusAddr,
            _baseToken
        );

        totalSupply = IERC20(nexus).totalSupply();

        minumumBNBBalance = 10**17;
        minumumNexusBalance = 8 * 10**3 * 10**9;
        maxBNBTransaction = 5 * 10**18;
        maxNexusTransaction = 25 * 10**3 * 10**9;
        maxPercentLiquidityAdjust = 5;
        canSwapAndLiquify = true;
        canBuyAndLiquify = true;
        canPullLiquidity = true;
        pullLiquidityRange = 8;
        goldyLocks = 10;
        addLiquidityRange = 12;
    }
function nexusAddr() view external returns(address){
    return _nexusAddr;
}
function baseToken() view external returns(address){
    return _baseToken;
}
function nexusLP() view external returns(address){
    return _nexusLP;
}
function uniswap() view external returns(address){
    return address(uniswapV2Router);
}
    function setOracle(address oracle) public onlyOwner {
        require(owner() != oracle, "Owner must be different from oracle");
        _oracleAddress = oracle;
        emit UpdateOracle(oracle);
    }

    function triggerPullLiquidity(uint256 percent)
        external
        isAutomating
        onlyOwner
    {
        pullLiquidity(percent);
    }

    function triggerAddLiquidity(uint256 bnbAmount)
        external
        isAutomating
        onlyOwner
    {
        addLiquidity(bnbAmount);
    }

    function triggerRegulateLiquidity() external onlyOracle {
        regulateLiquidity();
    }

    function recoverTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
    }

    function withdraw(uint256 amount)
        external
        onlyOwner
        returns (bytes memory)
    {
        (bool sent, bytes memory data) = payable(address(msg.sender)).call{
            value: amount
        }("");
        require(sent, "Failed to send bnb");
        return data;
    }

    function regulateLiquidity() private isAutomating {
        (uint256 liqHealth, uint256 diff) = determineLPHealth();
        liqHealth = clamp(liqHealth, 1, 100);
        diff = clamp(diff, 0, maxPercentLiquidityAdjust);

        if (liqHealth <= pullLiquidityRange && canPullLiquidity) {
            pullLiquidity(diff);
        } else if (addLiquidityRange <= pullLiquidityRange) {
            uint256 bnbBalance = address(this).balance;
            uint256 nexusBalance = IERC20(_nexusAddr).balanceOf(address(this));

            uint256 nexusToAdd = IERC20(_nexusAddr)
                .balanceOf(_nexusLP)
                .mul(diff)
                .div(100);

            nexusToAdd = clamp(nexusToAdd, 0, maxNexusTransaction);
            uint256 nexusToAddValue = getTokenInToken(
                _nexusAddr,
                _baseToken,
                nexusToAdd
            );
            if (
                bnbBalance >= nexusToAddValue + minumumBNBBalance &&
                nexusBalance >= nexusToAdd + minumumNexusBalance
            ) {
                addLiquidity(nexusToAddValue);
            } else if (
                bnbBalance >= nexusToAddValue + minumumBNBBalance &&
                nexusBalance < nexusToAdd + minumumNexusBalance &&
                canBuyAndLiquify
            ) {
                // buyback
                uint256 toBuy = (nexusToAdd +
                    minumumNexusBalance -
                    nexusBalance).div(2);

                buyBack(toBuy);
                addLiquidity(address(this).balance.sub(minumumBNBBalance));
            } else if (
                bnbBalance < nexusToAddValue + minumumBNBBalance &&
                nexusBalance >= nexusToAdd + minumumNexusBalance &&
                canSwapAndLiquify
            ) {
                // sell
                uint256 toSell = (nexusToAddValue +
                    minumumBNBBalance -
                    bnbBalance).div(2);
                liquidate(toSell);
                addLiquidity(address(this).balance.sub(minumumBNBBalance));
            }
        }
    }

    /** Clamps a variable between a min and a max */
    function clamp(
        uint256 variable,
        uint256 min,
        uint256 max
    ) private pure returns (uint256) {
        if (variable < min) {
            return min;
        } else if (variable > max) {
            return max;
        } else {
            return variable;
        }
    }

    function getTokenInToken(
        address tokenOne,
        address tokenTwo,
        uint256 amtTokenOne
    ) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenOne;
        path[1] = tokenTwo;

        return uniswapV2Router.getAmountsOut(amtTokenOne, path)[1];
    }

    /**
     * Returns the health of the LP, more specifically circulatingSupply / sizeof(lp)
     */
    function checkLPHealth() public view returns (uint256, uint256) {
        return determineLPHealth();
    }

    /**
     * Determines the Health of the LP
     * returns the percentage of the Circulating Supply that is in the LP
     */
    function determineLPHealth() private view returns (uint256, uint256) {
        // Find the balance of NEXUS in the liquidity pool
        uint256 lpBalance = IERC20(_nexusAddr).balanceOf(_nexusLP);
        // Circulating supply is total supply - burned supply
        uint256 circSupply = totalSupply.sub(
            IERC20(_nexusAddr).balanceOf(_burnWallet)
        );

        if (lpBalance < 1) {
            return (goldyLocks, 0);
        } else {
            uint256 lpHealth = circSupply.div(lpBalance);
            uint256 diff = 0;
            if (lpHealth < goldyLocks) {
                // Remove Liquidity
                diff = 1 - (lpHealth.div(goldyLocks)).mul(100);
            } else if (lpHealth > goldyLocks) {
                // Add Liquidity
                diff = (lpHealth.div(goldyLocks) - 1).mul(100);
            }

            return (lpHealth, diff);
        }
    }

    function addLiquidity(uint256 bnbAmount) private returns (bool) {
        uint256 iLiquidity = IERC20(_nexusLP).balanceOf(address(this));

        uint256 nexusAmount = getTokenInToken(
            _baseToken,
            _nexusAddr,
            bnbAmount
        );

        IERC20(_nexusAddr).approve(address(uniswapV2Router), nexusAmount);
        // add the liquidity
        try
            uniswapV2Router.addLiquidityETH{value: bnbAmount}(
                _nexusAddr,
                nexusAmount,
                0,
                0,
                address(this),
                block.timestamp.add(30)
            )
        {} catch {
            return false;
        }
        uint256 fLiquidity = IERC20(_nexusLP).balanceOf(address(this));
        emit AddLiquidity(fLiquidity.sub(iLiquidity));
        return true;
    }

    /**
     * Removes Liquidity from the pool and stores the BNB and NEXUS in the contract
     */
    function pullLiquidity(uint256 percentLiquidity) private returns (bool) {
        // Percent of our LP Tokens
        uint256 pLiquidity = IERC20(_nexusLP)
            .balanceOf(address(this))
            .mul(percentLiquidity)
            .div(10**2);
        // Approve Router
        IERC20(_nexusLP).approve(
            address(uniswapV2Router),
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
        // remove the liquidity
        try
            uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
                _nexusAddr,
                pLiquidity,
                0,
                0,
                address(this),
                block.timestamp.add(30)
            )
        {} catch {
            return false;
        }
        emit PullLiquidity(pLiquidity);
        return true;
    }

    function buyBack(uint256 amount) private {
        // calculate the amount being transfered

        // Uniswap pair path for BNB -> NEXUS
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = _nexusAddr;

        // Swap BNB for NEXUS
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of NEXUS
            path,
            address(this), // Store in Contract
            block.timestamp.add(30)
        );

        emit BuyBack(amount);
    }

    function liquidate(uint256 amount) private {
        // calculate the amount being transfered

        // Uniswap pair path for BNB -> NEXUS
        IERC20(_nexusAddr).approve(
            address(uniswapV2Router),
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
        address[] memory path = new address[](2);
        path[0] = _nexusAddr;
        path[1] = uniswapV2Router.WETH();

        // Swap BNB for NEXUS
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,// accept any amount of BNB
            0, 
            path,
            address(this), // Store in Contract
            block.timestamp.add(30)
        );

        emit Liquidate(amount);
    }

    function triggerLiquidate(uint256 amount) external isAutomating onlyOracle {
        require(amount <= maxNexusTransaction, "Transaction too big");
        liquidate(amount);
    }

    function triggerBuyBack(uint256 amount) external isAutomating onlyOracle {
        require(amount <= maxBNBTransaction, "Transaction too big");
        buyBack(amount);
    }
}