/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IBooster {
  function depositAll(uint256 _pid, bool _stake) external returns (bool);
  function withdrawAll(uint256 _pid) external returns (bool);
}

interface IRewards {
  function balanceOf(address account) external view returns (uint256);
  function getReward() external returns(bool);
  function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
  function earned(address account) external view returns (uint256);
}

interface ISushiSwapRouter {
  function swapExactTokensForTokens(uint amountIn, 
                                    uint amountOutMin, 
                                    address[] calldata path, 
                                    address to, 
                                    uint deadline
                                    ) external returns (uint[] memory amounts);
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

contract HarvestConvexMIM {
  using SafeMath for uint256;

  address public constant convexDepositor = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
  uint256 public constant poolId = 40; // Curve MIM - 3CRV pool
  address public constant rewardPool = address(0xFd5AbF66b003881b88567EB9Ed9c651F14Dc4771); // CRV emission rewards
  address public constant sushiSwapRouter = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

  address public constant mim3Crv = address(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);
  address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
  address public constant spell = address(0x090185f2135308BaD17527004364eBcC2D37e5F6);
  address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
  address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public constant dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  address private owner;


  constructor() public { 
    owner = msg.sender;
  }

  
  modifier onlyAdmin {
    require(msg.sender == owner);
    _;
  }


  function deposit() external {
    uint256 balance = IERC20(mim3Crv).balanceOf(msg.sender);
    IERC20(mim3Crv).transferFrom(msg.sender, address(this), balance);
    uint256 allowance = IERC20(mim3Crv).allowance(address(this), convexDepositor);
    if (allowance < balance) {
      IERC20(mim3Crv).approve(convexDepositor, balance);
    }
    IBooster(convexDepositor).depositAll(poolId, true);
  }


  function deposit(uint256 _amount) external {
    IERC20(mim3Crv).transferFrom(msg.sender, address(this), _amount);
    uint256 allowance = IERC20(mim3Crv).allowance(address(this), convexDepositor);
    if (allowance < _amount) {
      IERC20(mim3Crv).approve(convexDepositor, _amount);
    }
    IBooster(convexDepositor).depositAll(poolId, true);
  }


  function sellToken(address _erc20) internal {
    uint256 _amount = IERC20(_erc20).balanceOf(address(this));

    // check allowance
    uint256 allowance = IERC20(_erc20).allowance(address(this), sushiSwapRouter);
    if (allowance < _amount) {
      IERC20(_erc20).approve(sushiSwapRouter, _amount);
    }
    address[] memory path = new address[](3);
    path[0] = _erc20;
    path[1] = weth;
    path[2] = dai;
    ISushiSwapRouter(sushiSwapRouter).swapExactTokensForTokens(
      _amount, 
      1, 
      path,
      address(this), 
      32528645726);
    uint256 balance = IERC20(dai).balanceOf(address(this));
    IERC20(dai).transfer(owner, balance);
  }


  function getRewardAndConvert() external {
    // claim all rewards
    IRewards(rewardPool).getReward();

    // sell tokens
    sellToken(cvx);
    sellToken(spell);
    sellToken(crv);
  }


  function getReward() external onlyAdmin {
    // claim all rewards
    IRewards(rewardPool).getReward();
  }

 
  function withdraw() external {
    uint256 amount = IRewards(rewardPool).balanceOf(address(this));
    IRewards(rewardPool).withdrawAndUnwrap(amount, false);
    uint256 balance = IERC20(mim3Crv).balanceOf(address(this));
    IERC20(mim3Crv).transfer(owner, balance);
  }


  function withdraw(address _erc20) external {
    uint256 balance = IERC20(_erc20).balanceOf(address(this));
    IERC20(_erc20).transfer(owner, balance);
  }
}