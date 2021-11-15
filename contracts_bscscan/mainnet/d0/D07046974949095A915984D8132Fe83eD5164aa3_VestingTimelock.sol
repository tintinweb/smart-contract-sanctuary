// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VestingTimelock {
    using SafeMath for uint256;

    address payable public devAddress; // address of contract dev

    IERC20 public token; // token that will be claimed
    uint256 public tokenDecimals; // token decimals

    mapping(address => uint256) public allocations; // total wei allocated per address
    mapping(address => uint256) public claimed;
    mapping(uint256 => uint256) public claimPercentages; //% of claim quantity for every specific batches

    uint256 public startRedeemTime; // start redeem token time

    uint256 public claimCycle;
    uint256 public totalClaimCount;

    bool public claimAllowed = false; // if true, investor can claim tokens.

    string public vestingPurpose;

    constructor(
        address _devAddress,
        address _tokenAddress,
        uint256 _tokenDecimals,
        uint256 _claimCycle,
        uint256 _totalClaimCount,
        uint256[] memory _claimPercentageWei,
        address[] memory _beneficiaryAddresses,
        uint256[] memory _allocations,
        string memory _vestingPurpose
    ) public {
        require(_devAddress != address(0), "Wrong dev address");
        require(_tokenAddress != address(0), "Wrong token address");
        require(_tokenDecimals > 0, "Wrong token decimals");
        require(_claimCycle > 0, "Wrong token claim cycle");
        require(_totalClaimCount > 0, "Wrong token total claim count");
        require(_claimPercentageWei.length == _totalClaimCount, "Incorrect claim percentage number");
        require(_beneficiaryAddresses.length == _allocations.length, "Allocations length do not match");

        devAddress = payable(_devAddress);
        token = IERC20(_tokenAddress);
        tokenDecimals = _tokenDecimals;
        claimCycle = _claimCycle;
        totalClaimCount = _totalClaimCount;

        for (uint256 i = 0; i < _claimPercentageWei.length; i++) {
            claimPercentages[(i+1)] = _claimPercentageWei[i];
        }

        for (uint256 i = 0; i < _beneficiaryAddresses.length; i++) {
            allocations[_beneficiaryAddresses[i]] = _allocations[i];
        }

        vestingPurpose = _vestingPurpose;
    }

    modifier onlyDev() {
        require(devAddress == msg.sender);
        _;
    }

    modifier onlyClaimAllowed() {
        require(claimAllowed, "Claim is disallowed");
        _;
    }

    modifier isValidClaimPeriod(address _investorAddress) {
        uint256 currentPeriod = 0;
        for (uint256 i = 0; i < totalClaimCount; i++) {
            if (now >= startRedeemTime + claimCycle * i) {
                currentPeriod = (i + 1);
            }
        }
        require(startRedeemTime > 0, "Claim not started");
        require(currentPeriod > 0, "Still on vesting period");
        require(currentPeriod < totalClaimCount, "Token has been all claimed");
        require(
            claimed[_investorAddress] < currentPeriod,
            "Already claimed"
        );
        _;
    }

    function getClaimWeiAmount(uint256 _totalAllocationAmountWei, uint256 _percentageWei)
    internal
    view
    returns (uint256)
    {
        return _totalAllocationAmountWei.mul(10 ** tokenDecimals).div(1e18).mul(_percentageWei).div(1e20);
    }

    function allowClaim(uint256 _startRedeemTime) external onlyDev {
        require(_startRedeemTime > 0);
        require(!claimAllowed, "Claim time already set, cannot be changed");

        claimAllowed = true;
        startRedeemTime = _startRedeemTime;
    }

    function distributeTokens(address _investorAddress)
    external
    isValidClaimPeriod(_investorAddress)
    onlyClaimAllowed
    {
        require(allocations[_investorAddress] > 0, "Not an investor");

        claimed[_investorAddress] = claimed[_investorAddress].add(1); // make sure this goes first before transfer to prevent reentrancy
        token.transfer(
            _investorAddress,
            getClaimWeiAmount(allocations[_investorAddress], claimPercentages[claimed[_investorAddress]])
        );
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

