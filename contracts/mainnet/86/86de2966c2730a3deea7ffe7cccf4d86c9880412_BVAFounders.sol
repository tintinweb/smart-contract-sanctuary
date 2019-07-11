/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.0;

// File: ERC20Interface.sol

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
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
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: BVAFounders.sol

contract BVAFounders {
    using SafeMath for uint;

    ERC20Interface erc20Contract;
    address payable owner;


    modifier isOwner() {
        require(msg.sender == owner, "must be contract owner");
        _;
    }


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(ERC20Interface ctr) public {
        erc20Contract = ctr;
        owner         = msg.sender;
    }


    // ------------------------------------------------------------------------
    // Unlock Tokens
    // ------------------------------------------------------------------------
    function unlockTokens(address to) external isOwner {
        // Total Allocation : 1,260,000 BVA (4.5% of total supply)
        // 1. 25% - 2020/12/01 (315,000 BVA) - timestamp 1606752000
        // 2. 25% - 2021/12/01 (315,000 BVA) - timestamp 1638288000
        // 3. 15% - 2022/12/01 (189,000 BVA) - timestamp 1669824000
        // 4. 15% - 2023/12/01 (189,000 BVA) - timestamp 1701360000
        // 5. 10% - 2024/12/01 (126,000 BVA) - timestamp 1732982400
        // 6. 10% - 2025/12/01 (126,000 BVA) - timestamp 1764518400

        require(now >= 1606752000, "locked");

        uint balance = erc20Contract.balanceOf(address(this));
        uint amount;
        uint remain;

        if (now < 1638288000) {
            // 1st unlock : before balance must have at least 1,260,000 BVA
            require(balance >= 1260000e18, "checkpoint 1 balance error");
            remain = 945000e18;
            amount = balance.sub(remain);
        } else if (now < 1669824000) {
            // 2nd unlock : before balance must have at least 945,000 BVA
            require(balance >= 945000e18, "checkpoint 2 balance error");
            remain = 630000e18;
            amount = balance.sub(remain);
        } else if (now < 1701360000) {
            // 3rd unlock : before balance must have at least 630,000 BVA
            require(balance >= 630000e18, "checkpoint 3 balance error");
            remain = 441000e18;
            amount = balance.sub(remain);
        } else if (now < 1732982400) {
            // 4th unlock : before balance must have at least 441,000 BVA
            require(balance >= 441000e18, "checkpoint 4 balance error");
            remain = 252000e18;
            amount = balance.sub(remain);
        } else if (now < 1764518400) {
            // 5th unlock : before balance must have at least 252,000 BVA
            require(balance >= 252000e18, "checkpoint 5 balance error");
            remain = 126000e18;
            amount = balance.sub(remain);
        } else {
            // 6th unlock : before balance must have at least 126,000 BVA
            amount = balance;
        }

        if (amount > 0) {
            erc20Contract.transfer(to, amount);
        }
    }


    // ------------------------------------------------------------------------
    // Withdraw ETH from this contract to `owner`
    // ------------------------------------------------------------------------
    function withdrawEther(uint _amount) external isOwner {
        owner.transfer(_amount);
    }


    // ------------------------------------------------------------------------
    // accept ETH
    // ------------------------------------------------------------------------
    function () external payable {
    }
}