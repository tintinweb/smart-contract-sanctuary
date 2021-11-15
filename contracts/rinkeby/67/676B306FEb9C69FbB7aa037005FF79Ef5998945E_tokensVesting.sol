pragma solidity 0.6.12;

// SPDX-License-Identifier: BSD-3-Clause

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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface LegacyIERC20 {
    function transfer(address, uint) external;
}


interface iPcsRouter {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);



    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) external returns (uint[] memory amounts);

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


contract tokensVesting is Ownable {
    using SafeMath for uint;

    // ------- Contract Variables -------

    // Addresses Here
    address public constant TOKEN_ADDRESS = 0x5A0fDD515a4dA3aa5705261D546cD22152d93f26;




    uint public constant ONE_MINUTE = 1 minutes;

    uint public constant ONE_WEEK = 1 minutes;

    // If there are any Tokens left in the contract
    // After this below time, admin can claim them.
    uint public constant ADMIN_CAN_CLAIM_AFTER = 6 * ONE_WEEK;

    uint public constant ECOSYSTEM_CAN_CLAIM_AFTER = 4 * ONE_WEEK;


    address public constant admin_wallet_1      =  0x838F5de74f7aCEad668366b97b08Dd1dd2f86dEc; // DevA
    address public constant admin_wallet_2      =  0xcaDAfdDBf7E4076b54f422f9Ba275f0EB6B3A146; // DevM
    address public constant admin_wallet_3      =  0x7E8dd0cA8A48b0EEAe53b72f3C0dB1343932530a; // Design
    address public constant admin_wallet_4      =  0x25291108F608B54eE99BBd09fE0a105D72d31051; // Ecosystem



    // ------- END Contract Variables -------

    IERC20 public constant Token = IERC20(TOKEN_ADDRESS);




    uint public rewardTimes = 0;

    uint public contractStartTime;
    uint public lastClaimTime;

    uint public balanceToken;

    constructor() public {
        contractStartTime = now;
        lastClaimTime = contractStartTime;
    }


    function distributeAdminRewards() public {
        require(rewardTimes < 4, "distributeAdminRewards has already been called 4 times!");

        if (rewardTimes == 0) {
            require(now > lastClaimTime.add(ONE_MINUTE));
        } else {
            require(now > lastClaimTime.add(ONE_WEEK));
        }

        if (rewardTimes == 0) {

            require(Token.transfer(admin_wallet_1,     100e18), "Could not transfer to admin_wallet_1!");
            require(Token.transfer(admin_wallet_2,     100e18), "Could not transfer to admin_wallet_2!");
            require(Token.transfer(admin_wallet_3,     200e18), "Could not transfer to admin_wallet_3!");



        } else if (rewardTimes == 1) {


            require(Token.transfer(admin_wallet_1,     100e18), "Could not transfer to admin_wallet_1!");
            require(Token.transfer(admin_wallet_2,     200e18), "Could not transfer to admin_wallet_2!");
            require(Token.transfer(admin_wallet_3,     100e18), "Could not transfer to admin_wallet_3!");


        } else if (rewardTimes == 2) {


            require(Token.transfer(admin_wallet_1,     14000e18), "Could not transfer to admin_wallet_1!");
            require(Token.transfer(admin_wallet_2,     14000e18), "Could not transfer to admin_wallet_2!");
            require(Token.transfer(admin_wallet_3,      3000e18), "Could not transfer to admin_wallet_3!");


        } else if (rewardTimes == 3) {


            require(Token.transfer(admin_wallet_1,     14000e18), "Could not transfer to admin_wallet_1!");
            require(Token.transfer(admin_wallet_2,     14000e18), "Could not transfer to admin_wallet_2!");
            require(Token.transfer(admin_wallet_3,      2000e18), "Could not transfer to admin_wallet_3!");




        }

        lastClaimTime = now;
        rewardTimes = rewardTimes.add(1);
    }

    receive() external payable {}




    function transferAnyERC20Token(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        require(_tokenAddress != TOKEN_ADDRESS || now > contractStartTime.add(ADMIN_CAN_CLAIM_AFTER), "Cannot Transfer out Tokens yet!");

        require(IERC20(_tokenAddress).transfer(_to, _amount), "Could not transfer Tokens!");
    }

    function transferAnyOldERC20Token(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        require(_tokenAddress != TOKEN_ADDRESS || now > contractStartTime.add(ADMIN_CAN_CLAIM_AFTER), "Cannot Transfer out Tokens yet!");

        LegacyIERC20(_tokenAddress).transfer(_to, _amount);
    }
}

