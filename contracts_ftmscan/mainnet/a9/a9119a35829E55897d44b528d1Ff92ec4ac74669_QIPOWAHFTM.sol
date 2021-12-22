//SPDX-License-Identifier: Unlicense
pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IMasterChef {
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pending(uint256 nr, address who) external view returns (uint256);
}

interface BalancerVault {
  function getPoolTokenInfo(bytes32, address) external view returns (uint256, uint256, uint256, address);
  function getPool(bytes32) external view returns (address, uint8);
}


contract QIPOWAHFTM {
    using SafeMath for uint256;
    BalancerVault vault = BalancerVault(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce);

    function name() public pure returns(string memory) { return "QIPOWAHFTM"; }
    function symbol() public pure returns(string memory) { return "QIPOWAHFTM"; }
    function decimals() public pure returns(uint8) { return 18; }


    function totalSupply() public view returns (uint256) {
        IERC20 qi = IERC20(0x68Aa691a8819B07988B18923F712F3f4C8d36346);// qidao erc20
        uint256 qi_totalQi = qi.totalSupply().mul(4); /// x 4 because boost in eQi

        return qi_totalQi;//lp_totalQi.add(qi_totalQi);
    }

    function calculateBalancerPoolTokenSupply(bytes32 poolId, IERC20 token) public view returns (uint256){
        (uint256 poolTokenBalance, , , ) = vault.getPoolTokenInfo(poolId, address(token));
        return poolTokenBalance;
    }

    function balanceOf(address owner) public view returns (uint256) {
        IMasterChef chef = IMasterChef(0x230917f8a262bF9f2C3959eC495b11D1B7E1aFfC); // rewards/staking contract
        IERC20 beetsPair = IERC20(0x7aE6A223cde3A17E0B95626ef71A2DB5F03F540A); //Qi-miMatic beets pair
        bytes32 beetsPoolId = 0x7ae6a223cde3a17e0b95626ef71a2db5f03f540a00020000000000000000008a;
        IERC20 qi = IERC20(0x68Aa691a8819B07988B18923F712F3f4C8d36346);// qidao erc20

        // Get Qi balance of user on Fantom
        uint256 qi_powah = qi.balanceOf(owner);

        // Total Qi held in beets pair
        uint256 lp_totalQi = calculateBalancerPoolTokenSupply(beetsPoolId, qi);
        // Beets pair tokens held by owner
        uint256 lp_balance = beetsPair.balanceOf(owner);

        // Get staked balance of owner
        (uint256 lp_stakedBalanceOne, ) = chef.userInfo(1, owner); //Qi-WFTM Farmed Bal
        lp_balance = lp_balance.add(lp_stakedBalanceOne);

        uint256 lp_powah = 0;
        if (lp_balance > 0) {
            // QI Balance of the beets pair * (the staked + non staked LP balance of the owner) / all the lp tokens for the pair
            lp_powah = lp_totalQi.mul(lp_balance).div(beetsPair.totalSupply());
        }

        qi_powah = qi_powah.add(chef.pending(0, owner)); // Unclaimed reward Qi from USDC-miMatic
        qi_powah = qi_powah.add(chef.pending(1, owner)); // Unclaimed reward Qi from WFTM-Qi

        // Add and return staked QI 
        return lp_powah.add(qi_powah);
    }

    function allowance(address, address) public pure returns (uint256) { return 0; }
    function transfer(address, uint256) public pure returns (bool) { return false; }
    function approve(address, uint256) public pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}