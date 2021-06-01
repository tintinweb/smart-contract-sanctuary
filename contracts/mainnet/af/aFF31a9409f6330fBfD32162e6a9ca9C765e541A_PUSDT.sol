/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
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

interface IERC20 {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external ;
    function decimals() external view returns (uint8);
}

contract PUSDT {
    using SafeMath for uint256;
    string public name     = "PairX Tether USD";
    string public symbol   = "PUSDT";
    uint8  public decimals = 6;

    uint256 public totalPUSDT = 0;
    uint256 public usedUSDT = 0;
    address public investAddr;
    address public managerAddr;

    bool public reEntrancyMutex = false;//Mutexes that prevent reentrant attacks
    bool public canDeposit = true;//Allow to deposit.
    IERC20 usdt;

    event  Approval(address indexed src, address indexed guy, uint256 wad);
    event  Transfer(address indexed src, address indexed dst, uint256 wad);
    event  Deposit(address indexed dst, uint256 wad);
    event  Refund(address indexed src, uint256 principle);
    event  Withdrawal(address indexed src, uint256 wad);
    event  Invest(address indexed src, uint256 wad);
    event  ChangeIvAddr(address indexed src, address indexed newAddr);
    event  ChangeMngAddr(address indexed src, address indexed newAddr);
    event  ChangeDeposit(address indexed src, bool canDeposit);

    mapping (address => uint256)                       public  balanceOf;
    mapping (address => mapping (address => uint256))  public  allowance;

    constructor(address _investAddr,address _managerAddr,IERC20 _usdt) public {
        investAddr = _investAddr;
        managerAddr = _managerAddr;
        usdt = _usdt;
    }

    function deposit(uint256 wad) public {
        require(canDeposit);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(wad);
        totalPUSDT = totalPUSDT.add(wad);
        emit Transfer(address(0), msg.sender, wad);
        usdt.transferFrom(msg.sender, address(this), wad);
        emit Deposit(msg.sender, wad);
    }
    function refund(uint256 principle) public {
        usedUSDT = usedUSDT.sub(principle);
        usdt.transferFrom(msg.sender, address(this), principle);
        emit Refund(msg.sender, principle);
    }
    function withdraw(uint256 wad) public {
        require(!reEntrancyMutex);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(wad);
        totalPUSDT = totalPUSDT.sub(wad);

        reEntrancyMutex = true;
        usdt.transfer(msg.sender, wad);
        emit Transfer(msg.sender, address(0), wad);
        emit Withdrawal(msg.sender, wad);
        reEntrancyMutex = false;
    }
    function invest(uint256 wad) public {
        usedUSDT = usedUSDT.add(wad);
        usdt.transfer(investAddr, wad);
        emit Invest(msg.sender, wad);
    }
    function changeIvAddr(address newAddr) public {
        require(msg.sender == investAddr, "Only investAddr can change Invest Address.");
        investAddr = newAddr;
        emit ChangeIvAddr(msg.sender, newAddr);
    }
    function changeMngAddr(address newAddr) public {
        require(msg.sender == managerAddr, "Only managerAddr can change manager Address.");
        managerAddr = newAddr;
        emit ChangeMngAddr(msg.sender, newAddr);
    }
    function changeDeposit(bool _canDeposit) public {
        require(msg.sender == managerAddr, "Only managerAddr can change Deposit State.");
        canDeposit = _canDeposit;
        emit ChangeDeposit(msg.sender, _canDeposit);
    }

    function totalSupply() public view returns (uint256) {
        return totalPUSDT;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] = allowance[src][msg.sender].sub(wad);
        }

        balanceOf[src] = balanceOf[src].sub(wad);
        balanceOf[dst] = balanceOf[dst].add(wad);

        emit Transfer(src, dst, wad);

        return true;
    }
}