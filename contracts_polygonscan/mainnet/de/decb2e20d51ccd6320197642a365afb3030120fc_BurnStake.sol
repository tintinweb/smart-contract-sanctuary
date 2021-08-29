/**
 *Submitted for verification at polygonscan.com on 2021-08-29
*/

/**
 *Submitted for verification at polygonscan.com on 2021-08-22
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

contract BurnStake {
    using SafeMath for uint256;
    
    IERC20 public immutable arabella = IERC20(0x93810fe228Fa8C69B08C2D8df3Ec05357C00C625);
    IERC20 public immutable USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    
    IUniswapV2Router02 public immutable Quickswap = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    
    struct UserStruct {
        uint256 stakeAmount;
        uint256 pendingRewards;
    }
    mapping(address => UserStruct) private User;
    mapping(address => bool) private isUser;
    address[] private users;
    uint256 private totalStake;
    uint256 private usdcBalance;
    uint256 private usdcDistributed;
    
    // Carrying over user data for the contract redeployment
    constructor() {
        User[0xc781196AbE064A21171045732e674121533d338C].stakeAmount = 54 ether;
        User[0x8537Cc6499889DEfbe7e3847218cb61392fAE0De].stakeAmount = 610.6 ether;
        User[0x3D2B5e9E320Cf4Bd201CaEEFE677E147cB8b4DC0].stakeAmount = 34 ether;
        User[0xD2086532379dac81E4fCB2fDEC9fe06380c26A9D].stakeAmount = 76 ether;
        User[0x35c52CEcabAfa6c91Ad88Cea416d9444c1A28cE8].stakeAmount = 31 ether;
        User[0xB3fdbE311660c4a1015dc1FFf029117757274aC3].stakeAmount = 9 ether;
        User[0x909C24D5BC36f95abf618810f1Eea48BAe94596A].stakeAmount = 5 ether;
        User[0x06cf0093B369F15832062c3251fDAc41bE05606a].stakeAmount = 216 ether;
        User[0x7a120D3150530a1Cb538711eF04623aA8D90fF4E].stakeAmount = 23.76 ether;
        User[0xAEBa49deB2F2fC7a3208E2571F7a94C2458d7707].stakeAmount = 36.968 ether;
        User[0x02D7846C479837fE3eAC99eD48D6E584E3DA9343].stakeAmount = 14 ether;
        User[0xa8172A3a34fdb1ef39aB4EbCfc8af096D7b583A4].stakeAmount = 85 ether;
        User[0xfA48692A651dEe40ECc556D75a707De20e14d004].stakeAmount = 81 ether;
        User[0xe7f45f9bc459105443B9D01d15371A27DbCE49E2].stakeAmount = 12 ether;
        User[0x8F798D2EB360004fA2e172EfB6b42fC46911F0f8].stakeAmount = 43 ether;
        User[0x4A29367c5Ae9F84eF03E447D1f7deE8e6b16229D].stakeAmount = 25 ether;
        User[0x38D2dFC2F67Ce4a9dAEfE6C2F2E3882042f5E439].stakeAmount = 7.78 ether;
        User[0x57C6812178d233246c3ae3A9e746B3443EF3DF16].stakeAmount = 39.5 ether;
        User[0x75Cdf3388535D347B60Cdc6939898bcbE769a8E0].stakeAmount = 269 ether;
        User[0x52b8ef4b1EBDAe928d1d97EF0080492f1771f584].stakeAmount = 134 ether;
        User[0x219f71Ed2F08FC5e86a61A10c0C7908f6a4D28D5].stakeAmount = 13 ether;
        User[0x2A14Bf63d2924a9A57ecb8ce4FE5C5f61857C210].stakeAmount = 106 ether;
        User[0xe550Eb934C2291D9A4C9913336409117936f80A0].stakeAmount = 535 ether;
        User[0x9CC3f4bfF8756EeAb0441515347F8d1B02012bDE].stakeAmount = 10 ether;
        User[0x9306746b60ccBC1EbF22c4c373F6c040710844A1].stakeAmount = 4 ether;
        User[0x258D61cBf3757A0c1E8BdCae43dad497BF669735].stakeAmount = 0.475 ether;
        User[0xfE5a0963409609243a819A28034505567418b32c].stakeAmount = 20 ether;
        
        users.push() = 0xc781196AbE064A21171045732e674121533d338C;
        users.push() = 0x8537Cc6499889DEfbe7e3847218cb61392fAE0De;
        users.push() = 0x3D2B5e9E320Cf4Bd201CaEEFE677E147cB8b4DC0;
        users.push() = 0xD2086532379dac81E4fCB2fDEC9fe06380c26A9D;
        users.push() = 0x35c52CEcabAfa6c91Ad88Cea416d9444c1A28cE8;
        users.push() = 0xB3fdbE311660c4a1015dc1FFf029117757274aC3;
        users.push() = 0x909C24D5BC36f95abf618810f1Eea48BAe94596A;
        users.push() = 0x06cf0093B369F15832062c3251fDAc41bE05606a;
        users.push() = 0x7a120D3150530a1Cb538711eF04623aA8D90fF4E;
        users.push() = 0xAEBa49deB2F2fC7a3208E2571F7a94C2458d7707;
        users.push() = 0x02D7846C479837fE3eAC99eD48D6E584E3DA9343;
        users.push() = 0xa8172A3a34fdb1ef39aB4EbCfc8af096D7b583A4;
        users.push() = 0xfA48692A651dEe40ECc556D75a707De20e14d004;
        users.push() = 0xe7f45f9bc459105443B9D01d15371A27DbCE49E2;
        users.push() = 0x8F798D2EB360004fA2e172EfB6b42fC46911F0f8;
        users.push() = 0x4A29367c5Ae9F84eF03E447D1f7deE8e6b16229D;
        users.push() = 0x38D2dFC2F67Ce4a9dAEfE6C2F2E3882042f5E439;
        users.push() = 0x57C6812178d233246c3ae3A9e746B3443EF3DF16;
        users.push() = 0x75Cdf3388535D347B60Cdc6939898bcbE769a8E0;
        users.push() = 0x52b8ef4b1EBDAe928d1d97EF0080492f1771f584;
        users.push() = 0x219f71Ed2F08FC5e86a61A10c0C7908f6a4D28D5;
        users.push() = 0x2A14Bf63d2924a9A57ecb8ce4FE5C5f61857C210;
        users.push() = 0xe550Eb934C2291D9A4C9913336409117936f80A0;
        users.push() = 0x9CC3f4bfF8756EeAb0441515347F8d1B02012bDE;
        users.push() = 0x9306746b60ccBC1EbF22c4c373F6c040710844A1;
        users.push() = 0x258D61cBf3757A0c1E8BdCae43dad497BF669735;
        users.push() = 0xfE5a0963409609243a819A28034505567418b32c;
        
        isUser[0xc781196AbE064A21171045732e674121533d338C] = true;
        isUser[0x8537Cc6499889DEfbe7e3847218cb61392fAE0De] = true;
        isUser[0x3D2B5e9E320Cf4Bd201CaEEFE677E147cB8b4DC0] = true;
        isUser[0xD2086532379dac81E4fCB2fDEC9fe06380c26A9D] = true;
        isUser[0x35c52CEcabAfa6c91Ad88Cea416d9444c1A28cE8] = true;
        isUser[0xB3fdbE311660c4a1015dc1FFf029117757274aC3] = true;
        isUser[0x909C24D5BC36f95abf618810f1Eea48BAe94596A] = true;
        isUser[0x06cf0093B369F15832062c3251fDAc41bE05606a] = true;
        isUser[0x7a120D3150530a1Cb538711eF04623aA8D90fF4E] = true;
        isUser[0xAEBa49deB2F2fC7a3208E2571F7a94C2458d7707] = true;
        isUser[0x02D7846C479837fE3eAC99eD48D6E584E3DA9343] = true;
        isUser[0xa8172A3a34fdb1ef39aB4EbCfc8af096D7b583A4] = true;
        isUser[0xfA48692A651dEe40ECc556D75a707De20e14d004] = true;
        isUser[0xe7f45f9bc459105443B9D01d15371A27DbCE49E2] = true;
        isUser[0x8F798D2EB360004fA2e172EfB6b42fC46911F0f8] = true;
        isUser[0x4A29367c5Ae9F84eF03E447D1f7deE8e6b16229D] = true;
        isUser[0x38D2dFC2F67Ce4a9dAEfE6C2F2E3882042f5E439] = true;
        isUser[0x57C6812178d233246c3ae3A9e746B3443EF3DF16] = true;
        isUser[0x75Cdf3388535D347B60Cdc6939898bcbE769a8E0] = true;
        isUser[0x52b8ef4b1EBDAe928d1d97EF0080492f1771f584] = true;
        isUser[0x219f71Ed2F08FC5e86a61A10c0C7908f6a4D28D5] = true;
        isUser[0x2A14Bf63d2924a9A57ecb8ce4FE5C5f61857C210] = true;
        isUser[0xe550Eb934C2291D9A4C9913336409117936f80A0] = true;
        isUser[0x9CC3f4bfF8756EeAb0441515347F8d1B02012bDE] = true;
        isUser[0x9306746b60ccBC1EbF22c4c373F6c040710844A1] = true;
        isUser[0x258D61cBf3757A0c1E8BdCae43dad497BF669735] = true;
        isUser[0xfE5a0963409609243a819A28034505567418b32c] = true;
        
    }
    
    function stake(uint256 amount) public {
        
        arabella.transferFrom(msg.sender, address(this), amount);
        
        uint arabellaBalance = arabella.balanceOf(address(this));
        arabella.transfer(0x000000000000000000000000000000000000dEaD, arabellaBalance.mul(45).div(100));
        arabella.transfer(0xbF5DE398e4e4F6e6cBe7C9D0b5EC0d131E2c3789, arabellaBalance.mul(10).div(100));
        swapArabellaForUSDC();
        
        if (totalStake > 0) {
            for (uint i=0; i < users.length; i++) {
                User[users[i]].pendingRewards += ((USDC.balanceOf(address(this))).sub(usdcBalance)).mul(User[users[i]].stakeAmount).div(totalStake);
            }            
        }
        
        if (totalStake > 0) {
            usdcBalance = USDC.balanceOf(address(this));
        }
        

        
        if (isUser[msg.sender] == false) {
            users.push() = address(msg.sender);
            isUser[msg.sender] = true;
        }
        
        User[msg.sender].stakeAmount += amount;
        totalStake += amount;
        
    }
    
    function claim() public {
        
        require(User[msg.sender].pendingRewards > 0);
        
        uint claimAmount = User[msg.sender].pendingRewards;
        usdcDistributed += claimAmount;
        User[msg.sender].pendingRewards = 0;
        USDC.transfer(msg.sender, claimAmount);
        usdcBalance = USDC.balanceOf(address(this));
        
    }
    
    function swapArabellaForUSDC() private {
        
        address[] memory path = new address[](2);
        path[0] = address(arabella);
        path[1] = address(USDC);

        arabella.approve(address(Quickswap), arabella.balanceOf(address(this)));

        // make the swap
        Quickswap.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            arabella.balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    // View functions below for frontend
    
    function viewUSDCDistributed() public view returns(uint256) {
        return usdcDistributed;
    }
    
    function viewPendingRewards(address user) public view returns (uint256) {
        return User[user].pendingRewards;
    }
    
    function viewStakeAmount(address user) public view returns (uint256) {
        return User[user].stakeAmount;
    }
    
    function viewTotalStake() public view returns (uint256) {
        return totalStake;
    }
}