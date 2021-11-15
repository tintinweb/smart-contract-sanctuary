// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./common/SafeMath.sol";
import "./common/Ownable.sol";
import "./common/CalculateSwap.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IHyperswapPair.sol";
import "./interfaces/IHyperswapRouter02.sol";
import "./interfaces/IHyperPlanet.sol";

contract Zapper is Ownable {
    using SafeMath for uint256;
    
    address wrapped_native_token;
    address router_address;
    uint256 router_deadline;
    
    function configureWrappedNativeToken(address _wrapped_native_token) external onlyOwner {
        wrapped_native_token = _wrapped_native_token;
    }
    
    function configureRouter(address _router_address, uint256 _router_deadline) external onlyOwner {
        router_address = _router_address;
        router_deadline = _router_deadline;
    }    
    
    function calculateOptimalSwapAmount(
        uint256 amountA,
        uint256 amountB,
        uint256 reserveA,
        uint256 reserveB,
        uint256 swap_fee_numerator,
        uint256 swap_fee_denominator
    ) public pure returns (uint256) {
        return CalculateSwap.calculateOptimalSwapAmount(amountA, amountB, reserveA, reserveB, swap_fee_numerator, swap_fee_denominator);
    }
    
    function swapTokenForNative(address token, uint256 amount, address destination) public returns (uint256 nativeAmount) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = wrapped_native_token;
        IBEP20(token).approve(router_address, amount);
        uint[] memory amounts = IHyperswapRouter02(router_address).swapExactTokensForBNB(amount, 0, path, destination, block.timestamp + router_deadline);
        return amounts[amounts.length - 1];
    }

    function swapNativeForToken(address token, uint256 nativeAmount, address destination) public returns (uint256 amount) {
        address[] memory path = new address[](2);
        path[0] = wrapped_native_token;
        path[1] = token;
        uint[] memory amounts = IHyperswapRouter02(router_address).swapExactBNBForTokens{value: nativeAmount}(0, path, destination, block.timestamp + router_deadline);
        return amounts[amounts.length - 1];        
    }
    
    function swapNativetoLP(address lpToken, uint256 nativeAmount, address destination) public {
        IHyperswapPair pair = IHyperswapPair(lpToken);
        address token0 = pair.token0();
        address token1 = pair.token1();
        
        uint swapValue = nativeAmount.div(2);
        swapNativeForToken(token0, swapValue, address(this));
        swapNativeForToken(token1, nativeAmount.sub(swapValue), address(this));

        uint token0Amount = IBEP20(token0).balanceOf(address(this));
        uint token1Amount = IBEP20(token1).balanceOf(address(this));

        IHyperswapRouter02(router_address).addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, destination, block.timestamp + router_deadline);
    }
    
    function zapTokenToLP(address inputToken, address outputToken, uint256 inputAmount) external {
        IBEP20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
        uint256 nativeAmount = swapTokenForNative(inputToken, inputAmount, address(this));
        swapNativetoLP(outputToken, nativeAmount, msg.sender);
    }

    function zapTokenIntoFarm(address inputToken, uint256 inputAmount, address farm, uint256 pool_index) external {        
        IBEP20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
        uint256 nativeAmount = swapTokenForNative(inputToken, inputAmount, address(this));
        IHyperPlanet.PoolInfo memory poolInfo = IHyperPlanet(farm).poolInfo(pool_index);
        swapNativetoLP(poolInfo.lpToken, nativeAmount, address(this));
        uint256 lp_amount = IBEP20(poolInfo.lpToken).balanceOf(address(this));
        IBEP20(poolInfo.lpToken).approve(farm, lp_amount);
        IHyperPlanet(farm).deposit(pool_index, lp_amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
import "./Context.sol";
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.3;

import "./Math.sol";
import "./SafeMath.sol";

library CalculateSwap {
    using SafeMath for uint256;
    
    function calculateOptimalSwapAmount(
        uint256 amountA,
        uint256 amountB,
        uint256 reserveA,
        uint256 reserveB,
        uint256 swap_fee_numerator,
        uint256 swap_fee_denominator
    ) public pure returns (uint256) {
        require(amountA.mul(reserveB) >= amountB.mul(reserveA), "Expected amountA*reserveB value to be greater than amountB*reserveA value");
        uint256 double_non_fee_part = uint256(swap_fee_denominator.sub(swap_fee_numerator)).mul(2);
        uint256 reserve_amounts_delta = (amountA.mul(reserveB)).sub(amountB.mul(reserveA));
        uint256 ratio = reserve_amounts_delta.mul(swap_fee_denominator).div(amountB.add(reserveB)).mul(reserveA);
        uint256 delta = double_non_fee_part.mul(ratio).mul(2);
        uint256 base = uint256(double_non_fee_part.add(swap_fee_numerator)).mul(reserveA);
        uint256 distance = Math.sqrt(base.mul(base).add(delta));
        return uint256(distance.sub(base)).div(double_non_fee_part);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;
interface IBEP20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

interface IHyperswapPair {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.2;

import "./IHyperswapRouter01.sol";

interface IHyperswapRouter02 is IHyperswapRouter01 {
    function removeLiquidityFTMSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external returns (uint amountFTM);
    function removeLiquidityFTMWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountFTM);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactFTMForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForFTMSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

interface IHyperPlanet {
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ORI
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accOrilliumPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accOrilliumPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ORI to distribute per block.
        uint256 lastRewardTime;  // Last timestamp that ORI distribution occurs.
        uint256 accOrilliumPerShare; // Accumulated ORI per share, times 1e12. See below.
    }

    // Hyper Tokens
    function ori() external view
        returns (address ori_address);
    function mechs() external view
        returns (address mechs_address);
    
    // farm parameters
    function devAddr() external view
        returns (address dev_address);
    function lpFeeAddr() external view
        returns (address lp_fee_address);
    function oriPerSecond() external view
        returns (uint256 ori_per_second);
    function BONUS_MULTIPLIER() external pure
        returns (uint256 bonus_multiplier);

    // Info of each pool.
    function poolInfo(uint256 pool_index) external view
        returns (PoolInfo memory pool_info);
    // Info of each user that stakes LP tokens.
    function userInfo(uint256 pool_index, address user_address) external view
        returns (UserInfo memory user_info);
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    function totalAllocPoint() external view
        returns (uint256 total_alloc_points);
    // The block number when ORI mining starts.
    function startTime() external view
        returns (uint256 start_time);

    function updateMultiplier(uint256 multiplier_number) external; // onlyOwner

    function poolLength() external view
        returns (uint256 pool_length);

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 alloc_point, address lp_token_address, bool with_update) external; // onlyOwner

    // Update the given pool's ORI allocation point. Can only be called by the owner.
    function set(uint256 pool_index, uint256 alloc_point, bool with_update) external; // onlyOwner

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 from_block, uint256 to_block) external view
        returns (uint256 multiplier);

    // View function to see pending ORI on frontend.
    function pendingOrillium(uint256 pool_index, address user_address) external view
        returns (uint256 pending_orrilium);

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external;

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 pool_index) external;

    // Deposit LP tokens to HyperPlanet for ORI allocation.
    function deposit(uint256 pool_index, uint256 amount) external;

    // Withdraw LP tokens from HyperPlanet.
    function withdraw(uint256 pool_index, uint256 amount) external;

    // Stake ORI tokens to HyperPlanet
    function enterMechs(uint256 amount) external;

    // Withdraw ORI tokens from STAKING.
    function leaveMechs(uint256 amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;

    // Update dev address
    function dev(address dev_address) external; // onlyOwner

    // Update LP Fee Address
    function lpFeeAddress(address lp_fee_address) external; // onlyOwner
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.3;

// a library for performing various math operations
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.2;

interface IHyperswapRouter01 {
    function factory() external pure returns (address);
    function WBNB() external pure returns (address);

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
    function addLiquidityBNB(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountBNB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityBNB(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountBNB);
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
    function removeLiquidityBNBWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountBNB);
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
    function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactBNB(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForBNB(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapBNBForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

