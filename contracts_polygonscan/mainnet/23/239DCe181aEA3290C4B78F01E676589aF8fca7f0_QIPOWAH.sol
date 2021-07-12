/**
 *Submitted for verification at Etherscan.io on 2020-09-12
*/

pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IMasterChef {
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pending(uint256 nr, address who) external view returns (uint256);
}

contract QIPOWAH {
  using SafeMath for uint256;
  
  function name() public pure returns(string memory) { return "QIPOWAH"; }
  function symbol() public pure returns(string memory) { return "QIPOWAH"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
//    IPair pair = IPair(0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397);
  // no xQi yet IBar bar = IBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IERC20 qi = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);// qidao erc20
//    (uint256 lp_totalQi, , ) = pair.getReserves();
    uint256 qi_totalQi = qi.totalSupply().mul(4); /// x 4 because boost in eQi

    return qi_totalQi;//lp_totalQi.add(qi_totalQi);
  }
  
  function calculateBalanceInPair(address pair_addr, IERC20 token, address user) public view returns (uint256){
   
    IPair pair = IPair(pair_addr);

    uint256 lp_totalQi = token.balanceOf(address(pair));
    uint256 lp_balance = pair.balanceOf(user);
   
   if(lp_balance>0){
       return lp_totalQi.mul(lp_balance).div(pair.totalSupply());
   }else{
       return 0;
   }
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0x574Fe4E8120C4Da1741b5Fd45584de7A5b521F0F); // rewards contract
    IPair QSpair = IPair(0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397); // Qi-miMatic QS pair
    
  // no xQi yet  IBar bar = IBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IERC20 qi = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);// qidao erc20

    IERC20 qix = IERC20(0xe1cA10e6a10c0F72B74dF6b7339912BaBfB1f8B5);// qix erc20

    IERC20 eqi = IERC20(0x880DeCADe22aD9c58A8A4202EF143c4F305100B3);// eqi erc20

    uint256 qi_powah = qi.balanceOf(owner).add(qix.balanceOf(owner));

    uint256 lp_totalQi = qi.balanceOf(address(QSpair));
    uint256 lp_balance = QSpair.balanceOf(owner);
    
    // Add staked balance
    (uint256 lp_stakedBalance, ) = chef.userInfo(2, owner);
    lp_balance = lp_balance.add(lp_stakedBalance);
    
    uint256 lp_powah =0;
    
    if( lp_balance>0 ){
        lp_powah= lp_totalQi.mul(lp_balance).div(QSpair.totalSupply());
        // all Qi in lp * user_lp_balance / total_lp_balance
    }
    
    // add any unharvested Qi from the qi-mimatic staked pool
    qi_powah = qi_powah.add(chef.pending(0, owner));
    qi_powah = qi_powah.add(chef.pending(1, owner));
    qi_powah = qi_powah.add(chef.pending(2, owner));
    
    // need to add nonincentivized farms as well
    // qi-wmatic QS pair
    qi_powah = qi_powah.add(calculateBalanceInPair(0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397, qi, owner));
    // USDC-Qi pair
    qi_powah = qi_powah.add(calculateBalanceInPair(0x1dBba57B3d9719c007900D21e8541e90bC6933EC, qi, owner));
    
    // sushi pairs
    // wmatic-qi
    qi_powah = qi_powah.add(calculateBalanceInPair(0xCe00673a5a3023EBE47E3D46e4D59292e921dc7c, qi, owner));

    // mimatic-qi
    qi_powah = qi_powah.add(calculateBalanceInPair(0x96f72333A043a623D6869954B6A50AB7Be883EbC, qi, owner));

    // add eQi
    qi_powah = qi_powah.add(eqi.balanceOf(owner));

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