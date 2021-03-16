/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity 0.6.12;

library SafeMath {
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MathTest{
    using SafeMath for uint256;
    
    uint256 public startBlock;
    
    // 奖励发放多少个周期
    uint256 public constant rewardEpoch = 12;
    // 周期区块数量
    uint256 public constant epochPeriod = 10;
    
    
    function result(uint256 a, uint256 b) pure public returns(uint256){
        return 2**a.sub(b);
    }
    
    
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256 multiplier)
    {
        // 奖励结束块号
        uint256 bonusEndBlock = startBlock.add(epochPeriod.mul(rewardEpoch));

        // 如果 from块号 >= 奖励结束块号
        if (_from >= bonusEndBlock) {
            // 返回to块号 - from块号
            multiplier = _to.sub(_from);
        // 否则
        } else {
            // from所在的周期 = from距离开始时间过了多少个区块 / 周期区块数量  (取整)
            uint256 fromEpoch = _from.sub(startBlock).div(epochPeriod);
            // to之前的周期 = to距离开始时间过了多少个区块 / 周期区块数量  (取整)
            uint256 toEpoch = _to.sub(startBlock).div(epochPeriod);
            // 如果 to之前的周期 > from所在的周期 说明from和to不在同一个周期内
            if(toEpoch > fromEpoch){
                // from所在的周期内还剩多少个区块 = 周期区块数量 - from距离开始时间过了多少个区块 % 周期区块数量
                uint256 fromEpochBlock = epochPeriod.sub(_from.sub(startBlock).mod(epochPeriod));
                // to剩余的区块 = (to - 开始的区块号) % 周期区块数量
                uint256 toEpochBlock = _to.sub(startBlock).mod(epochPeriod);
                // 乘数 = from所在的周期内还剩多少个区块 * 2 ** (奖励发放的周期数量 - from所在的周期)
                multiplier = fromEpochBlock.mul(2**rewardEpoch.sub(fromEpoch));
                // 从to所在的周期向from所在的周期递减循环
                for (uint256 i = toEpoch; i > fromEpoch; i--) {
                    // 幂 = 如果 i >= 奖励发放的周期数量 ? 0 : 奖励发放的周期数量 - i
                    uint256 pow = i > rewardEpoch ? 0 : rewardEpoch.sub(i);
                    // 乘数 = 乘数 + 每个周期的区块数量 * 2 ** 幂
                    multiplier = multiplier.add(epochPeriod.mul(2**pow));
                }
                // 如果 to之前的周期 < 奖励结束块号
                if (toEpoch < rewardEpoch) {
                    // 乘数 = 乘数 + to剩余的区块 * 2 ** (奖励发放的周期数量 - to之前的周期 )
                    multiplier = multiplier.add(
                        toEpochBlock.mul(2**rewardEpoch.sub(toEpoch))
                    );
                } else {
                    // 乘数 = 乘数 + to剩余的区块
                    multiplier = multiplier.add(toEpochBlock);
                }
            // 否则from和to在同一个周期内
            }else{
                // 乘数 = (to - from) * 2 ** (奖励发放的周期数量 - to之前的周期)
                multiplier = _to.sub(_from).mul(2**(rewardEpoch.sub(toEpoch)));
            }
        }
    }
}