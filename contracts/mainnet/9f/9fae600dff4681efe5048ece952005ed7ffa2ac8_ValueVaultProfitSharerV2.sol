// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

interface ITokenInterface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function burn(uint amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /** VALUE, YFV, vUSD, vETH has minters **/
    function minters(address account) external view returns (bool);
    function mint(address _to, uint _amount) external;

    /** YFV <-> VALUE **/
    function deposit(uint _amount) external;
    function withdraw(uint _amount) external;
    function cap() external returns (uint);
    function yfvLockedBalance() external returns (uint);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ValueVaultProfitSharerV2 {
    using SafeMath for uint256;

    address public governance;

    ITokenInterface public valueToken;
    ITokenInterface public yfvToken;

    address public govVault = 0xceC03a960Ea678A2B6EA350fe0DbD1807B22D875; // VALUE -> VALUE and 6.7% profit from Value Vaults
    address public insuranceFund = 0xb7b2Ea8A1198368f950834875047aA7294A2bDAa; // set to Governance Multisig at start
    address public performanceReward = 0x7Be4D5A99c903C437EC77A20CB6d0688cBB73c7f; // set to deploy wallet at start

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public insuranceFee = 0; // 0% at start and can be set by governance decision
    uint256 public performanceFee = 0; // 0% at start and can be set by governance decision
    uint256 public burnFee = 0; // 0% at start and can be set by governance decision

    uint256 public distributeCap = 100 ether; // Maximum of Value to distribute each time
    uint256 public distributeCooldownPeriod = 0; // Cool-down period for each time distribution
    uint256 public distributeLasttime = 0;

    constructor(ITokenInterface _valueToken, ITokenInterface _yfvToken) public {
        valueToken = _valueToken;
        yfvToken = _yfvToken;
        yfvToken.approve(address(valueToken), type(uint256).max);
        governance = tx.origin;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setGovVault(address _govVault) public {
        require(msg.sender == governance, "!governance");
        govVault = _govVault;
    }

    function setInsuranceFund(address _insuranceFund) public {
        require(msg.sender == governance, "!governance");
        insuranceFund = _insuranceFund;
    }

    function setPerformanceReward(address _performanceReward) public {
        require(msg.sender == governance, "!governance");
        performanceReward = _performanceReward;
    }

    function setInsuranceFee(uint256 _insuranceFee) public {
        require(msg.sender == governance, "!governance");
        insuranceFee = _insuranceFee;
    }

    function setPerformanceFee(uint256 _performanceFee) public {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }

    function setBurnFee(uint256 _burnFee) public {
        require(msg.sender == governance, "!governance");
        burnFee = _burnFee;
    }

    function setDistributeCap(uint256 _distributeCap) public {
        require(msg.sender == governance, "!governance");
        distributeCap = _distributeCap;
    }

    function setDistributeCooldownPeriod(uint256 _distributeCooldownPeriod) public {
        require(msg.sender == governance, "!governance");
        distributeCooldownPeriod = _distributeCooldownPeriod;
    }

    function shareProfit() public returns (uint256 profit) {
        if (distributeCap > 0 && govVault != address(0) && distributeLasttime.add(distributeCooldownPeriod) <= block.timestamp) {
            profit = yfvToken.balanceOf(address(this));
            if (profit > 0) {
                valueToken.deposit(profit);
            }
            profit = valueToken.balanceOf(address(this));
            if (profit > 0) {
                if (performanceFee > 0 && performanceReward != address(0)) {
                    valueToken.transfer(performanceReward, profit.mul(performanceFee).div(FEE_DENOMINATOR));
                }
                if (insuranceFee > 0 && insuranceFund != address(0)) {
                    valueToken.transfer(insuranceFund, profit.mul(insuranceFee).div(FEE_DENOMINATOR));
                }
                if (burnFee > 0) {
                    valueToken.burn(profit.mul(burnFee).div(FEE_DENOMINATOR));
                }
                uint256 _valueBal = valueToken.balanceOf(address(this));
                valueToken.transfer(govVault, (_valueBal <= distributeCap) ? _valueBal : distributeCap);
                distributeLasttime = block.timestamp;
            }
        }
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract.
     * This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these.
     * It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(ITokenInterface _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(to, amount);
    }
}